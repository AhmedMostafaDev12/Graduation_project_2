"""Visual memory (spec D34, D39, D41): the hourly frame-vector file, CLIP's tokenizer, and the
two-stage search of what the glasses saw. The search runs on the test database with the fake
visual embedder (a bag of words), so frames are built from words. Tests that need the real
MobileCLIP files run when they're present (scripts/download_visual_models.py)."""

import base64
import json
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import numpy as np
import pytest
from sqlalchemy import select, update

from app.ai import fakes
from app.ai.inference import mobileclip_onnx
from app.ai.inference.clip_tokenizer import ClipTokenizer
from app.ai.memory import frame_vectors
from app.ai.rag.planner import QueryPlan
from app.ai.rag.retriever import MemorySearch
from app.models import Event, FrameVectorFile, MediaAsset, SceneSegment, SceneVector
from app.services import retention_service
from tests.conftest import API, create_patient, pair_device, register_and_login

NOW = datetime.now(UTC).replace(microsecond=0)
CAIRO = ZoneInfo("Africa/Cairo")
EMBED = fakes.FakeTextEmbedder()
VISUAL = fakes.FakeVisualTextEmbedder()

# ----- the hourly file -----


def test_frame_vector_file_round_trip():
    rng = np.random.default_rng(0)
    vectors = rng.normal(size=(5, 512)).astype(np.float32)
    vectors /= np.linalg.norm(vectors, axis=1, keepdims=True)
    hour = datetime(2026, 11, 16, 9, tzinfo=UTC)
    data = frame_vectors.pack(
        hour,
        "mobileclip-s0@1.0",
        [(i * 1.0, v.tolist()) for i, v in enumerate(vectors)],
    )
    assert len(data) == 4 + 1 + 2 + 4 + 8 + 1 + 17 + 5 * (8 + 512)
    found = frame_vectors.unpack(data)
    assert found.hour_start == hour and found.model_id == "mobileclip-s0@1.0"
    assert found.seconds.tolist() == [0.0, 1.0, 2.0, 3.0, 4.0]
    # 8 bits per value keeps the direction: cosine with the original above 0.999
    assert (np.sum(found.vectors * vectors, axis=1) > 0.999).all()
    assert found.times()[2] == hour + timedelta(seconds=2)
    with pytest.raises(frame_vectors.BadFrameVectorFile):
        frame_vectors.unpack(data[:-1])
    with pytest.raises(frame_vectors.BadFrameVectorFile):
        frame_vectors.unpack(b"NOPE" + data[4:])


# ----- the tokenizer -----


def test_clip_tokenizer_on_a_tiny_vocabulary(tmp_path):
    """BPE with CLIP's rules: lower case, words end in </w>, start and end tokens."""
    vocab = {
        "k": 0,
        "e": 1,
        "y": 2,
        "s</w>": 3,
        "ke": 4,
        "key": 5,
        "keys</w>": 6,
        "?</w>": 7,
        "<|startoftext|>": 8,
        "<|endoftext|>": 9,
    }
    path = tmp_path / "tokenizer.json"
    path.write_text(
        json.dumps(
            {
                "model": {
                    "type": "BPE",
                    "vocab": vocab,
                    "merges": ["k e", "ke y", "key s</w>"],
                    "end_of_word_suffix": "</w>",
                    "unk_token": "<|endoftext|>",
                }
            }
        ),
        encoding="utf-8",
    )
    tokenizer = ClipTokenizer(path)
    assert tokenizer.encode("KEYS?") == [8, 6, 7, 9]
    assert tokenizer.encode("keys  keys") == [8, 6, 6, 9]
    assert len(tokenizer.encode("keys " * 100)) == 77  # cut to CLIP's context


VISUAL_FILES = [
    Path(mobileclip_onnx.settings.visual_models_dir) / f
    for f in (mobileclip_onnx.TEXT_FILE, mobileclip_onnx.TOKENIZER_FILE)
]
needs_models = pytest.mark.skipif(
    not all(p.exists() for p in VISUAL_FILES),
    reason="visual models not downloaded (scripts/download_visual_models.py)",
)


@needs_models
def test_mobileclip_text_vectors():
    model = mobileclip_onnx.OnnxMobileClipText()
    a, b, c = np.array(
        model.embed_text(
            ["a photo of a pizza box", "a photo of a box of pizza", "a photo of a cat"]
        )
    )
    assert a.shape == (512,) and abs(np.linalg.norm(a) - 1) < 1e-4
    assert a @ b > a @ c  # the same thing in other words is closer than something else


# ----- the search -----


def _seen(client, worker_session, fake_s3, *, keep_photo=True):
    """A kitchen moment with a pizza box (its photo kept) 30 min ago, and the phone on the
    blanket 12 min ago with no photo, only a conversation 40 s later."""
    manager = register_and_login(client)
    patient_id = uuid.UUID(create_patient(client, manager)["id"])
    device_id = uuid.UUID(pair_device(client, manager, str(patient_id))["device_id"])
    ids = {}
    with worker_session() as db:

        def event(key, at, event_type, text):
            e = Event(
                id=uuid.uuid4(),
                patient_id=patient_id,
                source="glasses",
                event_type=event_type,
                occurred_at=at,
                rendered_text=text,
                embedding=EMBED.embed([text])[0],
            )
            db.add(e)
            db.flush()
            ids[key] = e.id
            return e

        kitchen = NOW - timedelta(minutes=30)
        blanket = NOW - timedelta(minutes=12)
        photo = event(
            "photo",
            kitchen + timedelta(seconds=5),
            "notable_moment_captured",
            "a moment",
        )
        event(
            "talk",
            blanket + timedelta(seconds=40),
            "conversation_segment",
            "talked about the game",
        )
        media = MediaAsset(
            id=uuid.uuid4(),
            patient_id=patient_id,
            event_id=photo.id,
            asset_type="image",
            storage_key="k",
            trigger="salient_frame",
            status="confirmed",
        )
        db.add(media)
        db.flush()

        frames = []  # (time, words) every second
        for start, scene, best in (
            (kitchen, "kitchen counter", ("pizza box", 6)),
            (blanket, "blanket floor", ("phone on the blanket", 7)),
        ):
            segment = SceneSegment(
                id=uuid.uuid4(),
                patient_id=patient_id,
                device_id=device_id,
                started_at=start,
                ended_at=start + timedelta(seconds=19),
                frame_count=20,
                model_id=VISUAL.model_id,
                kept_media_ids=[media.id]
                if keep_photo and scene == "kitchen counter"
                else [],
            )
            db.add(segment)
            db.flush()
            for second in range(20):
                text = f"{scene} {best[0]}" if second == best[1] else scene
                frames.append((start + timedelta(seconds=second), text))
            for role, second in (
                ("first", 0),
                ("middle", 10),
                ("most_different", best[1]),
            ):
                text = f"{scene} {best[0]}" if second == best[1] else scene
                db.add(
                    SceneVector(
                        segment_id=segment.id,
                        patient_id=patient_id,
                        captured_at=start + timedelta(seconds=second),
                        role=role,
                        embedding=fakes.fake_visual_vector(text),
                    )
                )
        # tier 2: every frame, one file per hour
        hours: dict[datetime, list] = {}
        for at, text in frames:
            hour = at.replace(minute=0, second=0, microsecond=0)
            hours.setdefault(hour, []).append(
                ((at - hour).total_seconds(), fakes.fake_visual_vector(text))
            )
        for hour, rows in hours.items():
            key = f"frame_vectors/{patient_id}/{hour:%Y%m%d%H}.rmfv"
            fake_s3.objects[key] = frame_vectors.pack(hour, VISUAL.model_id, rows)
            db.add(
                FrameVectorFile(
                    patient_id=patient_id,
                    device_id=device_id,
                    hour_start=hour,
                    frame_count=len(rows),
                    model_id=VISUAL.model_id,
                    dim=512,
                    storage_key=key,
                )
            )
        db.commit()
    return patient_id, ids, kitchen, blanket


def _plan(text, hours=24):
    return QueryPlan(
        window_start=NOW - timedelta(hours=hours),
        window_end=NOW + timedelta(minutes=1),
        person_ids=[],
        event_types=None,
        search_text=text,
    )


def test_a_frame_with_a_kept_photo_points_at_that_photo(
    client, worker_session, fake_s3
):
    patient_id, ids, kitchen, _ = _seen(client, worker_session, fake_s3)
    with worker_session() as db:
        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED, visual=VISUAL)
        found = {r.event_id: r.text for r in search.search_now(_plan("pizza box"))}
    best = kitchen + timedelta(
        seconds=6
    )  # tier 2 found the second, not the segment's start
    assert (
        f"seen around {best.astimezone(CAIRO):%H:%M:%S}: looks like «pizza box»"
        in found[str(ids["photo"])]
    )


def test_a_frame_without_a_photo_points_at_the_closest_moment(
    client, worker_session, fake_s3
):
    patient_id, ids, _, blanket = _seen(client, worker_session, fake_s3)
    with worker_session() as db:
        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED, visual=VISUAL)
        found = {
            r.event_id: r.text for r in search.search_now(_plan("phone on the blanket"))
        }
    best = blanket + timedelta(seconds=7)
    line = f"seen around {best.astimezone(CAIRO):%H:%M:%S}: looks like «phone on the blanket»"
    assert line in found[str(ids["talk"])]  # the conversation 33 s later carries it
    assert all("pizza" not in t for t in found.values())


def test_visual_memory_off_or_outside_the_window_adds_nothing(
    client, worker_session, fake_s3
):
    patient_id, _, _, _ = _seen(client, worker_session, fake_s3)
    with worker_session() as db:
        flat = MemorySearch(db, patient_id, "Africa/Cairo", EMBED)  # visual=None
        assert all(
            "seen around" not in r.text for r in flat.search_now(_plan("pizza box"))
        )
        recent = MemorySearch(db, patient_id, "Africa/Cairo", EMBED, visual=VISUAL)
        last_5_min = recent.search_now(
            QueryPlan(
                window_start=NOW - timedelta(minutes=5),
                window_end=NOW + timedelta(minutes=1),
                person_ids=[],
                event_types=None,
                search_text="pizza box",
            )
        )
        assert all("seen around" not in r.text for r in last_5_min)


# ----- what the glasses send -----


def _segment(start, kept=()):
    def vector(words):
        raw = np.asarray(fakes.fake_visual_vector(words), dtype="<f2").tobytes()
        return base64.b64encode(raw).decode()

    return {
        "id": str(uuid.uuid4()),
        "started_at": start.isoformat(),
        "ended_at": (start + timedelta(seconds=19)).isoformat(),
        "frame_count": 20,
        "model_id": "mobileclip-s0@1.0",
        "kept_media_ids": list(kept),
        "vectors": [
            {
                "role": "first",
                "captured_at": start.isoformat(),
                "embedding": vector("hall"),
            },
            {
                "role": "most_different",
                "captured_at": (start + timedelta(seconds=4)).isoformat(),
                "embedding": vector("hall keys"),
            },
        ],
    }


def test_events_batch_stores_scene_segments_once_and_only_from_the_glasses(
    client, worker_session
):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    phone = pair_device(client, manager, patient["id"])
    base = f"{API}/patients/{patient['id']}"
    segment = _segment(NOW - timedelta(minutes=5))
    for answer in ("accepted", "duplicates"):  # a retry is stored once
        r = client.post(
            f"{base}/events:batch",
            json={"scene_segments": [segment]},
            headers=phone["headers"],
        )
        assert r.status_code == 200, r.text
        assert segment["id"] in r.json()[answer]
    with worker_session() as db:
        stored = db.get(SceneSegment, uuid.UUID(segment["id"]))
        assert stored.device_id == uuid.UUID(phone["device_id"])
        vectors = db.scalars(
            select(SceneVector).where(SceneVector.segment_id == stored.id)
        ).all()
        assert sorted(v.role for v in vectors) == ["first", "most_different"]
        keys = next(v for v in vectors if v.role == "most_different")
        assert (
            np.dot(
                np.asarray(keys.embedding, dtype=float),
                fakes.fake_visual_vector("hall keys"),
            )
            > 0.99
        )

    other = _segment(NOW)
    by_hand = client.post(
        f"{base}/events:batch",
        json={"scene_segments": [other]},
        headers=manager["headers"],
    )
    assert other["id"] in by_hand.json()["rejected"]

    broken = _segment(NOW)
    broken["vectors"][0]["embedding"] = base64.b64encode(b"\0" * 10).decode()
    too_long = _segment(NOW)
    too_long["ended_at"] = (NOW + timedelta(minutes=2)).isoformat()
    for bad in (broken, too_long):
        r = client.post(
            f"{base}/events:batch",
            json={"scene_segments": [bad]},
            headers=phone["headers"],
        )
        assert r.status_code == 422


def test_frame_vector_upload_is_checked_and_one_per_hour(
    client, fake_s3, worker_session
):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    phone = pair_device(client, manager, patient["id"])
    base = f"{API}/patients/{patient['id']}"
    hour = NOW.replace(minute=0, second=0) - timedelta(hours=1)
    content = frame_vectors.pack(
        hour,
        "mobileclip-s0@1.0",
        [(s, fakes.fake_visual_vector(f"w{s}")) for s in range(3)],
    )

    def send(data, hour_start=hour, headers=phone["headers"]):
        upload_id = str(uuid.uuid4())
        ticket = client.post(
            f"{base}/uploads",
            json={
                "id": upload_id,
                "kind": "frame_vectors",
                "content_type": "application/octet-stream",
            },
            headers=headers,
        )
        if ticket.status_code != 201:
            return ticket
        assert ticket.json()["key"].endswith(f"/frame_vectors/{upload_id}.rmfv")
        fake_s3.put_bytes(ticket.json()["key"], data, "application/octet-stream")
        return client.post(
            f"{API}/uploads/{upload_id}/complete",
            json={
                "patient_id": patient["id"],
                "kind": "frame_vectors",
                "content_type": "application/octet-stream",
                "hour_start": hour_start.isoformat(),
            },
            headers=headers,
        )

    assert send(content, headers=manager["headers"]).status_code == 403
    assert send(b"not a file").json()["error"]["code"] == "BAD_FILE"
    assert (
        send(content, hour - timedelta(hours=1)).json()["error"]["code"] == "BAD_FILE"
    )
    done = send(content)
    assert done.status_code == 200 and done.json()["status"] == "stored"
    assert send(content).json()["error"]["code"] == "HOUR_STORED"
    with worker_session() as db:
        row = db.get(FrameVectorFile, uuid.UUID(done.json()["id"]))
        assert (row.frame_count, row.dim, row.hour_start) == (3, 512, hour)


def test_scene_memory_expires_after_90_days(client, worker_session, fake_s3):
    patient_id, _, _, _ = _seen(client, worker_session, fake_s3)
    with worker_session() as db:
        db.execute(
            update(SceneSegment)
            .where(SceneSegment.patient_id == patient_id)
            .values(started_at=SceneSegment.started_at - timedelta(days=91))
        )
        db.execute(
            update(FrameVectorFile)
            .where(FrameVectorFile.patient_id == patient_id)
            .values(hour_start=FrameVectorFile.hour_start - timedelta(days=91))
        )
        db.commit()
        keys = db.scalars(
            select(FrameVectorFile.storage_key).where(
                FrameVectorFile.patient_id == patient_id
            )
        ).all()
        retention_service.expire_media(db)
        for model in (SceneSegment, SceneVector, FrameVectorFile):
            assert not db.scalars(
                select(model).where(model.patient_id == patient_id)
            ).all()
    assert not any(k in fake_s3.objects for k in keys)
