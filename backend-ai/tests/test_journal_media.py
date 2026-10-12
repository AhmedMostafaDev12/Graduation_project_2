"""Events batch, journal, uploads, media and documents (Phase 5)."""

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import AuditLog, CapturedDocument
from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    pair_device,
    register_and_login,
)

DAY = "2026-10-12"
AT = "2026-10-12T10:00:00+03:00"


def _setup(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    phone = pair_device(client, manager, patient["id"])
    return manager, patient, phone, f"{API}/patients/{patient['id']}"


def _event(event_type="notable_moment_captured", **extra):
    return {
        "id": str(uuid.uuid4()),
        "event_type": event_type,
        "occurred_at": AT,
        **extra,
    }


def test_events_batch_is_idempotent_and_shows_in_the_journal(client):
    manager, _, phone, base = _setup(client)
    encounter = {
        "id": str(uuid.uuid4()),
        "started_at": AT,
        "ended_at": "2026-10-12T10:02:00+03:00",
        "best_confidence": 0.91,
        "announced": True,
    }
    meet = _event(
        "encounter", encounter_id=encounter["id"], metadata={"unknown_embedding": "AAA"}
    )
    batch = {"encounters": [encounter], "events": [meet, _event()]}

    first = client.post(
        f"{base}/events:batch", json=batch, headers=phone["headers"]
    ).json()
    assert len(first["accepted"]) == 3 and first["duplicates"] == []
    again = client.post(
        f"{base}/events:batch", json=batch, headers=phone["headers"]
    ).json()
    assert again["accepted"] == [] and len(again["duplicates"]) == 3

    journal = client.get(
        f"{base}/journal", params={"date": DAY}, headers=manager["headers"]
    )
    assert journal.status_code == 200
    body = journal.json()
    assert body["timezone"] == "Africa/Cairo" and len(body["entries"]) == 2
    assert "unknown_embedding" not in body["entries"][0]["metadata"]
    other_day = client.get(
        f"{base}/journal", params={"date": "2026-10-13"}, headers=phone["headers"]
    )
    assert other_day.json()["entries"] == []


def test_events_pointing_at_someone_elses_data_are_rejected(client):
    _, _, phone, base = _setup(client)
    _, _, other_phone, other_base = _setup(client)
    foreign = _event()
    client.post(
        f"{other_base}/events:batch",
        json={"events": [foreign]},
        headers=other_phone["headers"],
    )

    result = client.post(
        f"{base}/events:batch",
        json={"events": [foreign, _event("encounter", encounter_id=str(uuid.uuid4()))]},
        headers=phone["headers"],
    ).json()
    assert len(result["rejected"]) == 2 and result["accepted"] == []


def test_viewer_cannot_write_events(client):
    manager, patient, _, base = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    response = client.post(
        f"{base}/events:batch", json={"events": []}, headers=viewer["headers"]
    )
    assert response.status_code == 403


def _upload(client, base, phone, event_id, trigger="salient_frame"):
    media_id = str(uuid.uuid4())
    ticket = client.post(
        f"{base}/uploads",
        json={"id": media_id, "kind": "media", "content_type": "image/jpeg"},
        headers=phone["headers"],
    )
    assert ticket.status_code == 201, ticket.text
    return media_id, ticket.json()


def test_upload_flow_view_pin_and_delete(client, fake_s3, migrated_engine):
    manager, patient, phone, base = _setup(client)
    moment = _event()
    client.post(
        f"{base}/events:batch", json={"events": [moment]}, headers=phone["headers"]
    )
    media_id, ticket = _upload(client, base, phone, moment["id"])
    assert ticket["key"] == f"patients/{patient['id']}/media/{media_id}.jpg"
    assert ticket["headers"] == {"Content-Type": "image/jpeg"}

    done_body = {
        "patient_id": patient["id"],
        "kind": "media",
        "content_type": "image/jpeg",
        "event_id": moment["id"],
        "trigger": "salient_frame",
    }
    early = client.post(
        f"{API}/uploads/{media_id}/complete", json=done_body, headers=phone["headers"]
    )
    assert (
        early.status_code == 409 and early.json()["error"]["code"] == "UPLOAD_MISSING"
    )

    fake_s3.put_bytes(ticket["key"], b"\xff\xd8\xff", "image/jpeg")  # the phone's PUT
    done = client.post(
        f"{API}/uploads/{media_id}/complete", json=done_body, headers=phone["headers"]
    )
    assert done.status_code == 200 and done.json()["status"] == "pending_review"
    twice = client.post(
        f"{API}/uploads/{media_id}/complete", json=done_body, headers=phone["headers"]
    )
    assert twice.status_code == 200

    viewed = client.get(f"{base}/media/{media_id}", headers=manager["headers"])
    assert viewed.status_code == 200 and viewed.json()["url"].startswith("https://")
    pinned = client.post(f"{API}/media/{media_id}/pin", headers=manager["headers"])
    assert pinned.json()["retention_policy"] == "keep_indefinitely"
    assert (
        client.post(f"{API}/media/{media_id}/pin", headers=phone["headers"]).status_code
        == 403
    )

    journal = client.get(
        f"{base}/journal", params={"date": DAY}, headers=manager["headers"]
    ).json()
    assert journal["entries"][0]["media"][0]["id"] == media_id
    assert journal["entries"][0]["media"][0]["url"].startswith("https://")

    assert (
        client.delete(f"{API}/media/{media_id}", headers=phone["headers"]).status_code
        == 204
    )
    assert fake_s3.objects == {}
    assert (
        client.get(f"{base}/media/{media_id}", headers=manager["headers"]).status_code
        == 404
    )
    with Session(migrated_engine) as db:
        actions = db.scalars(
            select(AuditLog.action).where(AuditLog.entity_id == uuid.UUID(media_id))
        ).all()
    # one view from GET media, one from the journal handing out a signed URL
    assert sorted(actions) == ["media.delete", "media.view", "media.view"]


def test_user_requested_clip_skips_review(client, fake_s3):
    _, patient, phone, base = _setup(client)
    clip = _event("user_requested_recording")
    client.post(
        f"{base}/events:batch", json={"events": [clip]}, headers=phone["headers"]
    )
    media_id = str(uuid.uuid4())
    ticket = client.post(
        f"{base}/uploads",
        json={"id": media_id, "kind": "media", "content_type": "video/mp4"},
        headers=phone["headers"],
    ).json()
    fake_s3.put_bytes(ticket["key"], b"mp4", "video/mp4")
    done = client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "video/mp4",
            "event_id": clip["id"],
            "trigger": "user_requested",
            "duration_seconds": 12,
        },
        headers=phone["headers"],
    )
    assert done.json()["status"] == "confirmed"


def test_audio_upload_is_phone_only(client, fake_s3):
    manager, patient, phone, base = _setup(client)
    request = {"id": str(uuid.uuid4()), "kind": "audio", "content_type": "audio/ogg"}
    assert (
        client.post(
            f"{base}/uploads", json=request, headers=manager["headers"]
        ).status_code
        == 403
    )
    mismatched = {**request, "content_type": "image/jpeg"}
    assert (
        client.post(
            f"{base}/uploads", json=mismatched, headers=phone["headers"]
        ).status_code
        == 422
    )

    ticket = client.post(
        f"{base}/uploads", json=request, headers=phone["headers"]
    ).json()
    fake_s3.put_bytes(ticket["key"], b"ogg", "audio/ogg")
    done = client.post(
        f"{API}/uploads/{request['id']}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "audio",
            "content_type": "audio/ogg",
            "started_at": AT,
            "ended_at": "2026-10-12T10:00:30+03:00",
        },
        headers=phone["headers"],
    )
    assert done.status_code == 200 and done.json()["status"] == "uploaded"


def test_complete_for_a_patient_you_cant_access_looks_missing(client):
    _, patient, _, _ = _setup(client)
    stranger = register_and_login(client)
    response = client.post(
        f"{API}/uploads/{uuid.uuid4()}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "image/jpeg",
            "event_id": str(uuid.uuid4()),
            "trigger": "salient_frame",
        },
        headers=stranger["headers"],
    )
    assert response.status_code == 404


def test_documents_list(client, fake_s3, migrated_engine):
    manager, patient, phone, base = _setup(client)
    doc_event = _event("document_captured")
    client.post(
        f"{base}/events:batch", json={"events": [doc_event]}, headers=phone["headers"]
    )
    media_id, ticket = _upload(client, base, phone, doc_event["id"])
    fake_s3.put_bytes(ticket["key"], b"\xff\xd8\xff", "image/jpeg")
    client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "image/jpeg",
            "event_id": doc_event["id"],
            "trigger": "document_signal",
        },
        headers=phone["headers"],
    )
    with Session(migrated_engine) as db:  # what the OCR worker will write in Phase 6
        db.add(
            CapturedDocument(
                event_id=uuid.UUID(doc_event["id"]),
                media_asset_id=uuid.UUID(media_id),
                document_type="receipt",
                ocr_text="Total 120 EGP",
                extracted_fields={"total": 120},
            )
        )
        db.commit()

    docs = client.get(f"{base}/documents", headers=manager["headers"]).json()
    assert [d["document_type"] for d in docs] == ["receipt"]
    assert docs[0]["url"].startswith("https://")
    bills = client.get(
        f"{base}/documents", params={"type": "bill"}, headers=manager["headers"]
    )
    assert bills.json() == []


def test_image_upload_gets_an_upright_small_thumbnail(client, fake_s3):
    import io

    from PIL import Image

    from tests.conftest import image_bytes

    _, patient, phone, base = _setup(client)
    moment = _event()
    client.post(
        f"{base}/events:batch", json={"events": [moment]}, headers=phone["headers"]
    )
    media_id, ticket = _upload(client, base, phone, moment["id"])
    fake_s3.put_bytes(ticket["key"], image_bytes(size=(4000, 3000)), "image/jpeg")
    done = client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "image/jpeg",
            "event_id": moment["id"],
            "trigger": "salient_frame",
        },
        headers=phone["headers"],
    )
    assert done.status_code == 200

    thumb_key = ticket["key"].replace(".jpg", ".thumb.jpg")
    with Image.open(io.BytesIO(fake_s3.objects[thumb_key])) as thumb:
        assert max(thumb.size) == 320 and not thumb.getexif()

    journal = client.get(
        f"{base}/journal", params={"date": DAY}, headers=phone["headers"]
    ).json()
    assert thumb_key in journal["entries"][0]["media"][0]["thumbnail_url"]

    client.delete(f"{API}/media/{media_id}", headers=phone["headers"])
    assert fake_s3.objects == {}


def test_broken_image_still_uploads_without_thumbnail(client, fake_s3):
    _, patient, phone, base = _setup(client)
    moment = _event()
    client.post(
        f"{base}/events:batch", json={"events": [moment]}, headers=phone["headers"]
    )
    media_id, ticket = _upload(client, base, phone, moment["id"])
    fake_s3.put_bytes(ticket["key"], b"\xff\xd8\xff not really a jpeg", "image/jpeg")
    done = client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "image/jpeg",
            "event_id": moment["id"],
            "trigger": "salient_frame",
        },
        headers=phone["headers"],
    )
    assert done.status_code == 200
    journal = client.get(
        f"{base}/journal", params={"date": DAY}, headers=phone["headers"]
    ).json()
    assert journal["entries"][0]["media"][0]["thumbnail_url"] is None
