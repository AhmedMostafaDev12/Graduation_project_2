"""Enrolling people, unknown faces and the phone's delta sync (Phase 5)."""

import base64
import uuid
from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.models import FACE_DIM, Encounter, UnknownFaceCluster
from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    pair_device,
    register_and_login,
)

JPEG = b"\xff\xd8\xff\xe0" + b"fake-jpeg-body"
PNG = b"\x89PNG\r\n\x1a\n" + b"fake-png-body"


def _enroll(client, caregiver, patient_id, photos=(JPEG,), consent="true", name="أحمد"):
    return client.post(
        f"{API}/patients/{patient_id}/people",
        data={"name": name, "relationship": "son", "consent_given": consent},
        files=[
            ("photos", (f"p{i}.jpg", data, "image/jpeg"))
            for i, data in enumerate(photos)
        ],
        headers=caregiver["headers"],
    )


def _setup(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    return manager, patient


def test_enroll_stores_photos_and_embeddings(client, fake_s3):
    manager, patient = _setup(client)
    created = _enroll(client, manager, patient["id"], photos=(JPEG, PNG))
    assert created.status_code == 201, created.text
    person = created.json()
    assert person["embedding_count"] == 2 and person["added_by"] == "caregiver_manual"
    assert (
        len(fake_s3.list_keys(f"patients/{patient['id']}/people/{person['id']}/")) == 2
    )

    detail = client.get(
        f"{API}/people/{person['id']}", headers=manager["headers"]
    ).json()
    assert len(detail["photos"]) == 2 and detail["photos"][0]["url"].startswith(
        "https://"
    )

    more = client.post(
        f"{API}/people/{person['id']}/photos",
        files=[("photos", ("p.jpg", JPEG + b"2", "image/jpeg"))],
        headers=manager["headers"],
    )
    assert more.status_code == 200 and more.json()["embedding_count"] == 3

    listed = client.get(
        f"{API}/patients/{patient['id']}/people", headers=manager["headers"]
    )
    assert [p["id"] for p in listed.json()] == [person["id"]]


def test_enroll_validates_consent_and_files(client, fake_s3):
    manager, patient = _setup(client)
    no_consent = _enroll(client, manager, patient["id"], consent="false")
    assert no_consent.status_code == 422
    assert no_consent.json()["error"]["code"] == "CONSENT_REQUIRED"
    not_image = _enroll(client, manager, patient["id"], photos=(b"%PDF-1.4",))
    assert not_image.json()["error"]["code"] == "UNSUPPORTED_PHOTO"
    too_many = _enroll(client, manager, patient["id"], photos=(JPEG,) * 6)
    assert too_many.json()["error"]["code"] == "PHOTO_COUNT"
    assert fake_s3.objects == {}


def test_viewer_cannot_enroll_but_can_view(client):
    manager, patient = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    assert _enroll(client, viewer, patient["id"]).status_code == 403
    person = _enroll(client, manager, patient["id"]).json()
    viewed = client.get(f"{API}/people/{person['id']}", headers=viewer["headers"])
    assert viewed.status_code == 200
    rename = client.patch(
        f"{API}/people/{person['id']}", json={"name": "X"}, headers=viewer["headers"]
    )
    assert rename.status_code == 403


def test_other_caregivers_person_looks_missing(client):
    manager, patient = _setup(client)
    person = _enroll(client, manager, patient["id"]).json()
    stranger = register_and_login(client)
    response = client.get(f"{API}/people/{person['id']}", headers=stranger["headers"])
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "PERSON_NOT_FOUND"


def test_sync_sends_people_with_embeddings_then_only_changes(client, fake_s3):
    manager, patient = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    person = _enroll(client, manager, patient["id"]).json()
    client.post(
        f"{API}/patients/{patient['id']}/places",
        json={"name": "البيت", "latitude": 30.0, "longitude": 31.0},
        headers=manager["headers"],
    )
    url = f"{API}/patients/{patient['id']}/sync"

    first = client.get(url, headers=phone["headers"])
    assert first.status_code == 200, first.text
    body = first.json()
    assert body["full"] is True and body["settings"]["timezone"] == "Africa/Cairo"
    [synced] = body["people"]["upserts"]
    assert synced["id"] == person["id"]
    assert len(base64.b64decode(synced["embeddings"][0])) == FACE_DIM * 2  # float16
    assert len(body["places"]["upserts"]) == 1

    # archive the person: the next pull carries a delete and the photos are gone
    archived = client.delete(f"{API}/people/{person['id']}", headers=manager["headers"])
    assert archived.status_code == 204
    later = client.get(
        url, params={"since": body["server_time"]}, headers=phone["headers"]
    ).json()
    assert later["full"] is False
    assert later["people"]["deletes"] == [person["id"]]
    assert fake_s3.list_keys(f"patients/{patient['id']}/people/") == []
    gone = client.get(f"{API}/people/{person['id']}", headers=manager["headers"])
    assert gone.status_code == 404


def _cluster(engine, patient_id, device_id):
    with Session(engine) as db:
        now = datetime.now(UTC)
        cluster = UnknownFaceCluster(
            patient_id=uuid.UUID(patient_id),
            centroid=[1.0] + [0.0] * (FACE_DIM - 1),
            sighting_count=4,
            distinct_days=2,
            first_seen_at=now,
            last_seen_at=now,
            status="awaiting_caregiver",
        )
        db.add(cluster)
        db.flush()
        encounter = Encounter(
            patient_id=uuid.UUID(patient_id),
            device_id=uuid.UUID(device_id),
            cluster_id=cluster.id,
            started_at=now,
            ended_at=now,
            best_confidence=0.4,
        )
        db.add(encounter)
        db.commit()
        return str(cluster.id), encounter.id


def test_promote_unknown_face(client, migrated_engine):
    manager, patient = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    cluster_id, encounter_id = _cluster(
        migrated_engine, patient["id"], phone["device_id"]
    )
    faces_url = f"{API}/patients/{patient['id']}/unknown-faces"

    listed = client.get(faces_url, headers=manager["headers"])
    assert [c["id"] for c in listed.json()] == [cluster_id]
    assert client.get(faces_url, headers=phone["headers"]).status_code == 403

    promoted = client.post(
        f"{API}/unknown-faces/{cluster_id}/promote",
        json={"name": "الجارة", "relationship": "neighbour", "consent_given": True},
        headers=manager["headers"],
    )
    assert promoted.status_code == 200, promoted.text
    body = promoted.json()
    assert body["cluster"]["status"] == "promoted"
    assert body["person"]["added_by"] == "promoted_from_unknown"
    assert body["person"]["embedding_count"] == 1
    with Session(migrated_engine) as db:
        assert str(db.get(Encounter, encounter_id).person_id) == body["person"]["id"]

    again = client.post(
        f"{API}/unknown-faces/{cluster_id}/dismiss", headers=manager["headers"]
    )
    assert (
        again.status_code == 409 and again.json()["error"]["code"] == "ALREADY_DECIDED"
    )
