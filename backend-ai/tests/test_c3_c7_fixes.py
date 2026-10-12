"""C4-C7 screen fixes: per-photo errors, enrolled-by name, face samples, dismiss deletes."""

import uuid
from datetime import UTC, datetime

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.models import FACE_DIM, Encounter, UnknownFaceCluster
from tests.conftest import (
    API,
    create_patient,
    image_bytes,
    pair_device,
    register_and_login,
)

AT = "2026-10-12T10:00:00+03:00"


def test_enroll_errors_name_each_bad_photo(client, fake_s3):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    files = [
        ("photos", ("a.jpg", image_bytes(), "image/jpeg")),
        ("photos", ("b.jpg", b"\xff\xd8\xff broken", "image/jpeg")),
        ("photos", ("c.jpg", image_bytes(color=(9, 9, 9)), "image/jpeg")),
        ("photos", ("d.pdf", b"%PDF-1.4", "application/pdf")),
    ]
    response = client.post(
        f"{API}/patients/{patient['id']}/people",
        data={"name": "أحمد", "relationship": "son", "consent_given": "true"},
        files=files,
        headers=manager["headers"],
    )
    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "UNSUPPORTED_PHOTO"
    assert [d["field"] for d in error["details"]] == ["body.photos.1", "body.photos.3"]
    assert fake_s3.objects == {}


def test_person_detail_names_who_enrolled_them(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    person = client.post(
        f"{API}/patients/{patient['id']}/people",
        data={"name": "سارة", "relationship": "daughter", "consent_given": "true"},
        files=[("photos", ("a.jpg", image_bytes(), "image/jpeg"))],
        headers=manager["headers"],
    ).json()
    detail = client.get(
        f"{API}/people/{person['id']}", headers=manager["headers"]
    ).json()
    assert detail["enrolled_by_name"] == "Test Caregiver"


def _sightings(client, fake_s3, migrated_engine, count):
    """An unknown face seen `count` times, each sighting with an uploaded keyframe."""
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    phone = pair_device(client, manager, patient["id"])
    base = f"{API}/patients/{patient['id']}"
    media_ids, encounter_ids = [], []
    for i in range(count):
        encounter = {
            "id": str(uuid.uuid4()),
            "started_at": AT,
            "ended_at": AT,
            "best_confidence": 0.4,
        }
        event = {
            "id": str(uuid.uuid4()),
            "event_type": "encounter",
            "encounter_id": encounter["id"],
            "occurred_at": AT,
        }
        client.post(
            f"{base}/events:batch",
            json={"encounters": [encounter], "events": [event]},
            headers=phone["headers"],
        )
        media_id = str(uuid.uuid4())
        ticket = client.post(
            f"{base}/uploads",
            json={"id": media_id, "kind": "media", "content_type": "image/jpeg"},
            headers=phone["headers"],
        ).json()
        fake_s3.put_bytes(
            ticket["key"], image_bytes(color=(i * 40, 0, 0)), "image/jpeg"
        )
        done = client.post(
            f"{API}/uploads/{media_id}/complete",
            json={
                "patient_id": patient["id"],
                "kind": "media",
                "content_type": "image/jpeg",
                "event_id": event["id"],
                "trigger": "encounter_keyframe",
            },
            headers=phone["headers"],
        )
        assert done.status_code == 200, done.text
        media_ids.append(media_id)
        encounter_ids.append(uuid.UUID(encounter["id"]))

    with Session(
        migrated_engine
    ) as db:  # what the clustering worker will do (Phase 6+)
        now = datetime.now(UTC)
        cluster = UnknownFaceCluster(
            patient_id=uuid.UUID(patient["id"]),
            centroid=[1.0] + [0.0] * (FACE_DIM - 1),
            sighting_count=count,
            distinct_days=3,
            first_seen_at=now,
            last_seen_at=now,
            status="awaiting_caregiver",
            sample_media_id=uuid.UUID(media_ids[0]),
        )
        db.add(cluster)
        db.flush()
        db.execute(
            update(Encounter)
            .where(Encounter.id.in_(encounter_ids))
            .values(cluster_id=cluster.id)
        )
        db.commit()
        cluster_id = str(cluster.id)
    return manager, patient, base, media_ids, cluster_id


def test_unknown_face_has_up_to_three_samples_sample_first(
    client, fake_s3, migrated_engine
):
    manager, _, base, media_ids, _ = _sightings(client, fake_s3, migrated_engine, 4)
    [face] = client.get(f"{base}/unknown-faces", headers=manager["headers"]).json()
    assert len(face["samples"]) == 3
    assert face["samples"][0]["id"] == media_ids[0]  # the chosen sample leads
    assert face["sample_thumbnail_url"] == face["samples"][0]["thumbnail_url"]


def test_dismiss_deletes_the_strangers_photos(client, fake_s3, migrated_engine):
    manager, _, base, media_ids, cluster_id = _sightings(
        client, fake_s3, migrated_engine, 2
    )
    assert len(fake_s3.objects) == 4  # 2 keyframes + 2 previews

    dismissed = client.post(
        f"{API}/unknown-faces/{cluster_id}/dismiss", headers=manager["headers"]
    )
    assert dismissed.status_code == 200
    assert (
        dismissed.json()["status"] == "dismissed" and dismissed.json()["samples"] == []
    )
    assert fake_s3.objects == {}
    for media_id in media_ids:
        gone = client.get(f"{base}/media/{media_id}", headers=manager["headers"])
        assert gone.status_code == 404
    journal = client.get(
        f"{base}/journal", params={"date": "2026-10-12"}, headers=manager["headers"]
    ).json()
    assert len(journal["entries"]) == 2  # the sightings stay, without photos
    assert all(entry["media"] == [] for entry in journal["entries"])
