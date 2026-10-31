"""Phase 8.3: photo review: blur strangers → one vision call → keep/discard, documents,
retention (spec §7.4, §8, D10, D20, D29).

Gemini is mocked with respx; the service uses a scripted vision reviewer that records the
photo it was sent; tests never call a real AI API (AI_LAYER.md rule 9)."""

import base64
import io
import json
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import httpx
import numpy as np
import pytest
import respx
from PIL import Image
from sqlalchemy import select, update

from app.ai import fakes
from app.ai.clients.llm import GEMINI_URL, LLMError
from app.ai.clients.vision import (
    GeminiVisionReviewer,
    VisionError,
    parse_review,
    to_jpeg,
)
from app.ai.inference import face_onnx
from app.ai.interfaces import Face
from app.ai.review_contract import DocumentResult, ReviewResult, SeenAction, SeenObject
from app.errors import TransientError
from app.models import (
    CapturedDocument,
    ConsentRecord,
    Event,
    MediaAsset,
    MemoryAction,
    MemoryEntity,
    ObjectSighting,
    Place,
)
from app.services import retention_service, review_service
from app.workers.tasks import review as review_tasks
from tests.conftest import create_patient, image_bytes, register_and_login

DATA = Path(__file__).parent / "data"
HAVE_MODELS = all(
    (Path(face_onnx.settings.face_models_dir) / name).exists()
    for name in (face_onnx.DETECTOR_FILE, face_onnx.EMBEDDER_FILE)
)


def _jpeg(image: Image.Image) -> bytes:
    out = io.BytesIO()
    image.save(out, "JPEG", quality=95)
    return out.getvalue()


# ----- the Gemini vision client -----


def _gemini_reply(answer: dict):
    text = json.dumps(answer)
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


KEEP_RECEIPT = {
    "keep": True,
    "category": "document",
    "tags": ["فاتورة"],
    "reason": "فاتورة صيدلية",
    "contains_other_people": False,
    "document": {
        "document_type": "receipt",
        "ocr_text": "NILE PHARMACY TOTAL 145",
        "fields": {
            "merchant": "NILE PHARMACY",
            "total": {"amount": 145, "currency": "EGP"},
        },
    },
    "room": None,
    "objects": [{"name": "receipt"}],
    "actions": [],
}


@respx.mock
def test_gemini_reviewer_sends_a_small_jpeg_the_language_and_the_schema():
    route = respx.post(GEMINI_URL).mock(
        return_value=httpx.Response(200, json=_gemini_reply(KEEP_RECEIPT))
    )
    big = image_bytes(size=(4000, 3000))
    result = GeminiVisionReviewer(api_key="k").review(big, "ar")
    assert result.keep and result.document.fields["merchant"] == "NILE PHARMACY"

    body = json.loads(route.calls.last.request.content)
    parts = body["contents"][0]["parts"]
    sent = Image.open(io.BytesIO(base64.b64decode(parts[0]["inlineData"]["data"])))
    assert parts[0]["inlineData"]["mimeType"] == "image/jpeg"
    assert max(sent.size) == 1600  # shrunk before sending
    assert "Arabic" in parts[1]["text"]
    assert body["generationConfig"]["responseJsonSchema"]["required"][0] == "keep"
    assert "never try to" in body["systemInstruction"]["parts"][0]["text"]


@respx.mock
def test_gemini_reviewer_errors():
    respx.post(GEMINI_URL).mock(return_value=httpx.Response(503))
    with pytest.raises(TransientError):
        GeminiVisionReviewer(api_key="k").review(image_bytes(), "en")
    respx.post(GEMINI_URL).mock(return_value=httpx.Response(400, json={}))
    with pytest.raises(LLMError):
        GeminiVisionReviewer(api_key="k").review(image_bytes(), "en")
    with pytest.raises(VisionError, match="GEMINI_API_KEY"):
        GeminiVisionReviewer(api_key="")


def test_answers_are_parsed_leniently_but_must_be_json():
    long = dict(KEEP_RECEIPT, tags=[f"t{i}" for i in range(15)], category="banana")
    result = parse_review(json.dumps(long))
    assert (
        len(result.tags) == 10 and result.category == "banana"
    )  # normalized when stored
    with pytest.raises(VisionError):
        parse_review("I see a receipt")
    with pytest.raises(VisionError):
        parse_review(json.dumps({"category": "document"}))  # no keep


def test_to_jpeg_keeps_small_photos_as_they_are():
    small = Image.open(io.BytesIO(to_jpeg(image_bytes(size=(800, 600)))))
    assert small.size == (800, 600)


# ----- blurring -----


def _face_at(box, value):
    vector = np.zeros(512, np.float32)
    vector[value] = 1.0
    return Face(box, 0.9, (), vector.tolist())


def test_strangers_are_pixelated_and_enrolled_faces_are_not():
    photo = Image.new("RGB", (400, 200), (255, 255, 255))
    for x in range(0, 400, 4):  # stripes, so pixelation is visible
        for y in range(200):
            photo.putpixel((x, y), (0, 0, 0))
    stranger = _face_at((40.0, 40.0, 120.0, 120.0), 0)
    friend = _face_at((260.0, 40.0, 340.0, 120.0), 1)
    enrolled = np.array([friend.embedding], np.float32)

    out, strangers = review_service.blur_strangers(photo, [stranger, friend], enrolled)
    assert strangers == 1
    before, after = np.asarray(photo, np.int16), np.asarray(out, np.int16)
    assert np.abs(after[60:100, 60:100] - before[60:100, 60:100]).mean() > 40  # blurred
    assert np.array_equal(
        after[60:100, 280:320], before[60:100, 280:320]
    )  # friend sharp
    assert np.array_equal(after[150:200, :], before[150:200, :])  # rest untouched
    assert np.array_equal(np.asarray(photo), before)  # the original isn't modified


# ----- the review (database) -----


class ScriptedVision:
    model_id = "scripted-vision"

    def __init__(self, result: ReviewResult | Exception):
        self.result, self.sent = result, []

    def review(self, image, language):
        self.sent.append((image, language))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


class Models:
    def __init__(self, vision, face_model=None):
        self.vision = vision
        self.face = face_model or fakes.StubFaceEmbedder()


def _use(monkeypatch, vision, face_model=None):
    models = Models(vision, face_model)
    monkeypatch.setattr(review_service, "get_ai", lambda: models)
    return vision


def _photo(client, worker_session, fake_s3, data=None, created=None):
    manager = register_and_login(client)
    patient_id = uuid.UUID(create_patient(client, manager)["id"])
    media_id, event_id = uuid.uuid4(), uuid.uuid4()
    key = f"patients/{patient_id}/media/{media_id}.jpg"
    fake_s3.put_bytes(key, data or image_bytes(), "image/jpeg")
    fake_s3.put_bytes(key + ".thumb.jpg", b"thumb", "image/jpeg")
    with worker_session() as db:
        db.add(
            Event(
                id=event_id,
                patient_id=patient_id,
                source="glasses",
                event_type="notable_moment_captured",
                occurred_at=datetime.now(UTC),
                rendered_text="old sentence",
                metadata_={"keep": "me"},
            )
        )
        db.flush()
        db.add(
            MediaAsset(
                id=media_id,
                patient_id=patient_id,
                event_id=event_id,
                asset_type="image",
                storage_key=key,
                thumbnail_key=key + ".thumb.jpg",
                trigger="salient_frame",
                status="pending_review",
                **({"created_at": created} if created else {}),
            )
        )
        db.commit()
    return patient_id, event_id, media_id, key


def _result(**fields) -> ReviewResult:
    base = {
        "keep": True,
        "category": "notable_moment",
        "tags": ["lunch"],
        "reason": "family lunch",
    }
    return ReviewResult(**{**base, **fields})


def test_a_kept_document_is_confirmed_stored_and_kept_forever(
    client, worker_session, fake_s3, monkeypatch
):
    vision = _use(
        monkeypatch,
        ScriptedVision(
            _result(
                category="document",
                tags=["فاتورة"],
                document=DocumentResult(
                    document_type="receipt",
                    ocr_text="NILE PHARMACY TOTAL 145",
                    fields={"store": "NILE PHARMACY", "amount": "145 EGP"},
                ),
                room="pharmacy",
                objects=[SeenObject(name="receipt")],
                actions=[SeenAction(verb="pay", object="medicine")],
            )
        ),
    )
    _, event_id, media_id, _ = _photo(client, worker_session, fake_s3)

    assert review_tasks.review_media.delay(str(media_id)).get() == "document"
    assert vision.sent[0][1] == "ar"  # the patient's language
    with worker_session() as db:
        media = db.get(MediaAsset, media_id)
        assert media.status == "confirmed" and media.reviewed_at is not None
        assert (
            media.retention_policy == "keep_indefinitely" and media.expires_at is None
        )
        assert media.ai_tags == {
            "category": "document",
            "tags": ["فاتورة"],
            "reason": "family lunch",
        }
        document = db.scalars(
            select(CapturedDocument).where(CapturedDocument.media_asset_id == media_id)
        ).one()
        assert document.document_type == "receipt"
        assert document.extracted_fields == {
            "merchant": "NILE PHARMACY",
            "total": {"amount": 145, "currency": "EGP"},
        }  # aliases normalized (D29)
        event = db.get(Event, event_id)
        assert event.metadata_["keep"] == "me"
        # room, objects, actions became memory rows (phase 8.5), not event metadata
        assert "vision" not in event.metadata_
        sighting = db.scalars(
            select(ObjectSighting).where(ObjectSighting.media_asset_id == media_id)
        ).one()
        assert (sighting.room, sighting.model_id) == ("pharmacy", "scripted-vision")
        action = db.scalars(
            select(MemoryAction).where(MemoryAction.media_asset_id == media_id)
        ).one()
        assert (action.verb, action.source, action.evidence_event_id) == (
            "pay",
            "vision",
            event_id,
        )
        assert (
            event.rendered_text is None and event.embedding is None
        )  # re-embedded later

    # running again changes nothing
    assert review_tasks.review_media.delay(str(media_id)).get() == "done"
    assert len(vision.sent) == 1


def test_photos_with_other_people_expire_after_30_days(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(_result(contains_other_people=True)))
    _, _, media_id, _ = _photo(client, worker_session, fake_s3)
    assert review_tasks.review_media.delay(str(media_id)).get() == "kept"
    with worker_session() as db:
        media = db.get(MediaAsset, media_id)
        assert media.retention_policy == "auto_expire" and media.contains_other_people
        left = media.expires_at - datetime.now(UTC)
        assert timedelta(days=29, hours=23) < left <= timedelta(days=30)


def test_a_discarded_photo_is_deleted_at_once(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(_result(keep=False, category="other")))
    _, _, media_id, key = _photo(client, worker_session, fake_s3)
    assert review_tasks.review_media.delay(str(media_id)).get() == "discarded"
    assert not fake_s3.exists(key) and not fake_s3.exists(key + ".thumb.jpg")
    with worker_session() as db:
        media = db.get(MediaAsset, media_id)
        assert media.status == "discarded" and media.deleted_at is not None


def test_no_cloud_consent_sends_nothing(client, worker_session, fake_s3, monkeypatch):
    vision = _use(monkeypatch, ScriptedVision(_result()))
    patient_id, _, media_id, _ = _photo(client, worker_session, fake_s3)
    with worker_session() as db:
        db.execute(
            update(ConsentRecord)
            .where(ConsentRecord.patient_id == patient_id)
            .values(revoked_at=datetime.now(UTC))
        )
        db.commit()
    assert review_tasks.review_media.delay(str(media_id)).get() == "not_allowed"
    assert vision.sent == []
    with worker_session() as db:
        assert db.get(MediaAsset, media_id).status == "pending_review"
        assert media_id not in review_service.pending_media_ids(db, 10_000)


def test_a_refused_photo_stays_pending_and_isnt_retried(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(LLMError("blocked")))
    _, _, media_id, _ = _photo(
        client, worker_session, fake_s3, created=datetime.now(UTC) - timedelta(hours=1)
    )
    assert review_tasks.review_media.delay(str(media_id)).get() == "failed"
    with worker_session() as db:
        media = db.get(MediaAsset, media_id)
        assert media.status == "pending_review" and media.reviewed_at is not None
        assert media_id not in review_service.pending_media_ids(db, 10_000)


def test_a_temporary_failure_writes_nothing(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(TransientError("Gemini returned 503")))
    _, _, media_id, _ = _photo(client, worker_session, fake_s3)
    with worker_session() as db, pytest.raises(TransientError):
        review_service.review_media(db, media_id)
    with worker_session() as db:
        media = db.get(MediaAsset, media_id)
        assert media.status == "pending_review" and media.reviewed_at is None


def test_backfill_reviews_photos_left_pending(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(_result()))
    _, _, old, _ = _photo(
        client,
        worker_session,
        fake_s3,
        created=datetime.now(UTC) - timedelta(minutes=5),
    )
    _, _, fresh, _ = _photo(client, worker_session, fake_s3)
    with worker_session() as db:
        pending = review_service.pending_media_ids(db, 10_000)
        assert (
            old in pending and fresh not in pending
        )  # the upload's own task has 2 minutes
    review_tasks.backfill.delay().get()
    with worker_session() as db:
        assert db.get(MediaAsset, old).status == "confirmed"


@pytest.mark.skipif(not HAVE_MODELS, reason="face models not downloaded")
def test_a_strangers_face_is_blurred_before_the_vision_call(
    client, worker_session, fake_s3, monkeypatch
):
    photo = (DATA / "astronaut.jpg").read_bytes()
    vision = _use(monkeypatch, ScriptedVision(_result()), face_onnx.OnnxFaceEmbedder())
    _, _, media_id, _ = _photo(client, worker_session, fake_s3, data=photo)
    assert review_tasks.review_media.delay(str(media_id)).get() == "kept"

    original = np.asarray(Image.open(io.BytesIO(photo)).convert("RGB"), np.int16)
    sent = np.asarray(
        Image.open(io.BytesIO(vision.sent[0][0])).convert("RGB"), np.int16
    )
    face, corner = (slice(80, 160), slice(190, 260)), (slice(420, 500), slice(20, 100))
    assert np.abs(sent[face] - original[face]).mean() > 10  # the face was pixelated
    assert (
        np.abs(sent[corner] - original[corner]).mean() < 6
    )  # elsewhere: only JPEG noise
    with worker_session() as db:
        assert db.get(MediaAsset, media_id).contains_other_people is True


# ----- memory from photos (phase 8.5) -----


def test_objects_and_actions_become_sightings_actions_and_entities(
    client, worker_session, fake_s3, monkeypatch
):
    patient_id, event_id, media_id, _ = _photo(client, worker_session, fake_s3)
    with worker_session() as db:
        home = Place(
            patient_id=patient_id,
            name="Home",
            latitude=30.05,
            longitude=31.33,
            created_by=patient_id,
        )
        db.add(home)
        db.flush()
        event = db.get(Event, event_id)
        event.metadata_ = {**event.metadata_, "place_id": str(home.id)}
        db.commit()
        home_id = home.id
    _use(
        monkeypatch,
        ScriptedVision(
            _result(
                room="Kitchen",
                objects=[
                    SeenObject(name="Keys", state="on the table"),
                    SeenObject(name="Stove", state="off"),
                    SeenObject(name="  "),  # nothing to name: skipped
                ],
                actions=[
                    SeenAction(
                        verb="Take Medication",
                        object="pill box",
                        quantity=2,
                        unit="pills",
                    ),
                    SeenAction(verb="!!!"),  # no verb left: skipped
                ],
            )
        ),
    )
    assert review_tasks.review_media.delay(str(media_id)).get() == "kept"

    with worker_session() as db:
        sightings = {
            db.get(MemoryEntity, s.entity_id).name: s
            for s in db.scalars(
                select(ObjectSighting).where(ObjectSighting.media_asset_id == media_id)
            )
        }
        assert set(sightings) == {"keys", "stove"}
        keys = sightings["keys"]
        assert (keys.state, keys.room, keys.place_id) == (
            "on the table",
            "Kitchen",
            home_id,
        )
        assert keys.seen_at == db.get(Event, event_id).occurred_at
        action = db.scalars(
            select(MemoryAction).where(MemoryAction.media_asset_id == media_id)
        ).one()
        assert (action.verb, action.quantity, action.unit) == (
            "take_medication",
            2.0,
            "pills",
        )
        assert db.get(MemoryEntity, action.entity_id).name == "pill box"
        entity = db.get(MemoryEntity, keys.entity_id)
        assert entity.kind == "object" and len(entity.name_embedding) == 1024


def test_the_same_object_in_another_photo_counts_a_mention(
    client, worker_session, fake_s3, monkeypatch
):
    _use(monkeypatch, ScriptedVision(_result(objects=[SeenObject(name="glasses")])))
    patient_id, _, first, _ = _photo(client, worker_session, fake_s3)
    review_tasks.review_media.delay(str(first)).get()
    # a second photo of the same patient
    second_event, second = uuid.uuid4(), uuid.uuid4()
    key = f"patients/{patient_id}/media/{second}.jpg"
    fake_s3.put_bytes(key, image_bytes(), "image/jpeg")
    with worker_session() as db:
        db.add(
            Event(
                id=second_event,
                patient_id=patient_id,
                source="glasses",
                event_type="notable_moment_captured",
                occurred_at=datetime.now(UTC) + timedelta(hours=1),
            )
        )
        db.flush()
        db.add(
            MediaAsset(
                id=second,
                patient_id=patient_id,
                event_id=second_event,
                asset_type="image",
                storage_key=key,
                trigger="salient_frame",
                status="pending_review",
            )
        )
        db.commit()
    review_tasks.review_media.delay(str(second)).get()
    with worker_session() as db:
        glasses = db.scalars(
            select(MemoryEntity).where(
                MemoryEntity.patient_id == patient_id, MemoryEntity.name == "glasses"
            )
        ).one()
        assert glasses.mention_count == 2
        assert (
            len(
                db.scalars(
                    select(ObjectSighting).where(ObjectSighting.entity_id == glasses.id)
                ).all()
            )
            == 2
        )


def test_an_expired_photo_takes_its_sightings_and_actions_with_it(
    client, worker_session, fake_s3, monkeypatch
):
    _use(
        monkeypatch,
        ScriptedVision(
            _result(
                contains_other_people=True,  # → auto_expire after 30 days
                objects=[SeenObject(name="wallet")],
                actions=[SeenAction(verb="pay", object="wallet")],
            )
        ),
    )
    patient_id, _, media_id, _ = _photo(client, worker_session, fake_s3)
    review_tasks.review_media.delay(str(media_id)).get()
    with worker_session() as db:
        db.execute(
            update(MediaAsset)
            .where(MediaAsset.id == media_id)
            .values(expires_at=datetime.now(UTC) - timedelta(minutes=1))
        )
        db.commit()
        retention_service.expire_media(db)

    with worker_session() as db:
        assert db.get(MediaAsset, media_id).deleted_at is not None
        for table in (ObjectSighting, MemoryAction):
            row = db.scalars(
                select(table).where(table.media_asset_id == media_id)
            ).one()
            assert row.deleted_at is not None  # spec §8
        # the entity stays: other evidence may mention it
        assert db.scalars(
            select(MemoryEntity).where(
                MemoryEntity.patient_id == patient_id, MemoryEntity.name == "wallet"
            )
        ).one()


def test_a_discarded_photo_leaves_no_memory(
    client, worker_session, fake_s3, monkeypatch
):
    _use(
        monkeypatch,
        ScriptedVision(_result(keep=False, objects=[SeenObject(name="keys")])),
    )
    _, _, media_id, _ = _photo(client, worker_session, fake_s3)
    review_tasks.review_media.delay(str(media_id)).get()
    with worker_session() as db:
        assert (
            db.scalars(
                select(ObjectSighting).where(ObjectSighting.media_asset_id == media_id)
            ).first()
            is None
        )
