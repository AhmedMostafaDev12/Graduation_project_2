"""Phase 8.4: unknown faces → clusters → the caregiver is asked at 3 different days (spec D23).

Face vectors are synthetic: "the same stranger" is one direction plus a little noise, a
different person is an unrelated direction. They travel as base64 float16, like the
glasses send them (spec §7.1)."""

import uuid
from datetime import UTC, datetime, timedelta

import numpy as np
import pytest
from sqlalchemy import select

from app.ai import clustering
from app.ai.inference import face
from app.models import (
    CaregiverAlert,
    Encounter,
    EnrolledPerson,
    Event,
    FaceEmbedding,
    MediaAsset,
    UnknownFaceCluster,
)
from app.workers.tasks import clustering as cluster_tasks
from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    pair_device,
    register_and_login,
)

RNG = np.random.default_rng(7)
DAY1 = datetime(2026, 7, 1, 10, 0, tzinfo=UTC)  # Cairo is UTC+3 in July


def _direction() -> np.ndarray:
    v = RNG.normal(size=512).astype(np.float32)
    return v / np.linalg.norm(v)


def _near(v: np.ndarray, noise: float = 0.15) -> np.ndarray:
    w = v + RNG.normal(scale=noise / np.sqrt(512), size=512).astype(np.float32)
    return w / np.linalg.norm(w)


# ----- the math -----


def test_vectors_round_trip_and_bad_ones_are_refused():
    v = _direction()
    decoded = clustering.decode(face.to_base64_f16(v.tolist()))
    assert decoded.shape == (512,) and float(decoded @ v) > 0.999
    for bad in [
        None,
        "not base64!",
        face.to_base64_f16([0.1] * 10),
        face.to_base64_f16([0.0] * 512),
    ]:
        with pytest.raises(clustering.BadEmbedding):
            clustering.decode(bad)


def test_nearest_respects_the_threshold_and_centroids_stay_unit():
    a, b = _direction(), _direction()
    matrix = np.stack([a, b])
    assert clustering.nearest(_near(a), matrix, clustering.SAME_CLUSTER) == 0
    assert clustering.nearest(_direction(), matrix, clustering.SAME_CLUSTER) is None
    assert clustering.nearest(a, np.zeros((0, 512), np.float32), 0.5) is None
    c = clustering.add_to_centroid(a, 3, _near(a))
    assert float(np.linalg.norm(c)) == pytest.approx(1.0) and float(c @ a) > 0.99


# ----- the sweep (database) -----


def _patient(client):
    manager = register_and_login(client)
    patient_id = create_patient(client, manager)["id"]
    viewer = add_viewer(client, manager, patient_id)
    device_id = uuid.UUID(pair_device(client, manager, patient_id)["device_id"])
    return manager, viewer, uuid.UUID(patient_id), device_id


def _sighting(
    worker_session, patient_id, device_id, at, vector, photo=False, embedding=None
):
    with worker_session() as db:
        encounter = Encounter(
            id=uuid.uuid4(),
            patient_id=patient_id,
            device_id=device_id,
            started_at=at,
            ended_at=at + timedelta(minutes=2),
            best_confidence=0.31,
        )
        db.add(encounter)
        db.flush()
        event = Event(
            id=uuid.uuid4(),
            patient_id=patient_id,
            source="glasses",
            event_type="encounter",
            occurred_at=at,
            encounter_id=encounter.id,
            metadata_={
                "unknown_embedding": embedding
                if embedding is not None
                else face.to_base64_f16(vector.tolist()),
                "keyframe_ref": "img-1",
            },
        )
        db.add(event)
        db.flush()
        media_id = None
        if photo:
            media_id = uuid.uuid4()
            db.add(
                MediaAsset(
                    id=media_id,
                    patient_id=patient_id,
                    event_id=event.id,
                    asset_type="image",
                    storage_key=f"patients/{patient_id}/media/{media_id}.jpg",
                    trigger="encounter_keyframe",
                    status="confirmed",
                )
            )
        db.commit()
        return encounter.id, event.id, media_id


def _encounter(worker_session, encounter_id) -> Encounter:
    with worker_session() as db:
        return db.get(Encounter, encounter_id)


def _alerts(worker_session, cluster_id) -> list[CaregiverAlert]:
    with worker_session() as db:
        return list(
            db.scalars(
                select(CaregiverAlert).where(CaregiverAlert.entity_id == cluster_id)
            )
        )


def test_a_stranger_on_three_local_days_is_flagged_once(client, worker_session):
    _, _, patient_id, device_id = _patient(client)
    stranger = _direction()
    first, first_event, photo = _sighting(
        worker_session, patient_id, device_id, DAY1, _near(stranger), photo=True
    )
    # 22:30 UTC on day 1 is already 01:30 on day 2 in Cairo: a second local day
    _sighting(
        worker_session,
        patient_id,
        device_id,
        DAY1 + timedelta(hours=12, minutes=30),
        _near(stranger),
    )
    cluster_tasks.unknown_faces.delay().get()

    cluster_id = _encounter(worker_session, first).cluster_id
    with worker_session() as db:
        cluster = db.get(UnknownFaceCluster, cluster_id)
        assert (cluster.distinct_days, cluster.sighting_count) == (2, 2)
        assert cluster.status == "open" and cluster.sample_media_id == photo
        # the raw vector now lives only in the cluster's centroid (D35)
        assert "unknown_embedding" not in db.get(Event, first_event).metadata_
        assert db.get(Event, first_event).metadata_["keyframe_ref"] == "img-1"
    assert _alerts(worker_session, cluster_id) == []

    _sighting(
        worker_session, patient_id, device_id, DAY1 + timedelta(days=2), _near(stranger)
    )
    cluster_tasks.unknown_faces.delay().get()
    with worker_session() as db:
        cluster = db.get(UnknownFaceCluster, cluster_id)
        assert cluster.distinct_days == 3 and cluster.status == "awaiting_caregiver"
    alerts = _alerts(worker_session, cluster_id)
    assert len(alerts) == 2  # the manager and the viewer, once each
    assert {a.alert_type for a in alerts} == {"unknown_person_flagged"}
    assert {a.entity_type for a in alerts} == {"unknown_face_cluster"}
    assert alerts[0].message == "A new face has visited on 3 different days."

    # a fourth day: counted, but nobody is asked twice
    _sighting(
        worker_session, patient_id, device_id, DAY1 + timedelta(days=3), _near(stranger)
    )
    cluster_tasks.unknown_faces.delay().get()
    with worker_session() as db:
        assert db.get(UnknownFaceCluster, cluster_id).sighting_count == 4
    assert len(_alerts(worker_session, cluster_id)) == 2


def test_different_strangers_get_different_clusters(client, worker_session):
    _, _, patient_id, device_id = _patient(client)
    one, _, _ = _sighting(worker_session, patient_id, device_id, DAY1, _direction())
    two, _, _ = _sighting(worker_session, patient_id, device_id, DAY1, _direction())
    cluster_tasks.unknown_faces.delay().get()
    a, b = _encounter(worker_session, one), _encounter(worker_session, two)
    assert a.cluster_id and b.cluster_id and a.cluster_id != b.cluster_id


def test_a_face_close_to_an_enrolled_person_is_named(client, worker_session):
    _, _, patient_id, device_id = _patient(client)
    sara = _direction()
    with worker_session() as db:
        person = EnrolledPerson(
            patient_id=patient_id,
            name="Sara",
            relationship="daughter",
            added_by="caregiver_manual",
            status="active",
        )
        db.add(person)
        db.flush()
        db.add(
            FaceEmbedding(
                person_id=person.id,
                embedding=sara.tolist(),
                model_version=face.EDGE_MODEL_VERSION,
            )
        )
        db.commit()
        person_id = person.id
    seen, _, _ = _sighting(worker_session, patient_id, device_id, DAY1, _near(sara))
    cluster_tasks.unknown_faces.delay().get()
    encounter = _encounter(worker_session, seen)
    assert encounter.person_id == person_id and encounter.cluster_id is None


def test_a_dismissed_stranger_is_not_asked_about_again(client, worker_session):
    manager, _, patient_id, device_id = _patient(client)
    stranger = _direction()
    for day in range(3):
        first, _, _ = _sighting(
            worker_session,
            patient_id,
            device_id,
            DAY1 + timedelta(days=day),
            _near(stranger),
        )
    cluster_tasks.unknown_faces.delay().get()
    cluster_id = _encounter(worker_session, first).cluster_id
    dismissed = client.post(
        f"{API}/unknown-faces/{cluster_id}/dismiss", headers=manager["headers"]
    )
    assert dismissed.status_code == 200, dismissed.text

    later, _, _ = _sighting(
        worker_session, patient_id, device_id, DAY1 + timedelta(days=9), _near(stranger)
    )
    cluster_tasks.unknown_faces.delay().get()
    assert _encounter(worker_session, later).cluster_id == cluster_id
    with worker_session() as db:
        assert db.get(UnknownFaceCluster, cluster_id).status == "dismissed"
    assert len(_alerts(worker_session, cluster_id)) == 2  # only the first time


def test_a_promoted_stranger_is_recognized_next_time(client, worker_session):
    manager, _, patient_id, device_id = _patient(client)
    neighbour = _direction()
    for day in range(3):
        first, _, _ = _sighting(
            worker_session,
            patient_id,
            device_id,
            DAY1 + timedelta(days=day),
            _near(neighbour),
        )
    cluster_tasks.unknown_faces.delay().get()
    cluster_id = _encounter(worker_session, first).cluster_id
    promoted = client.post(
        f"{API}/unknown-faces/{cluster_id}/promote",
        json={
            "name": "Umm Mohamed",
            "relationship": "neighbour",
            "consent_given": True,
        },
        headers=manager["headers"],
    )
    assert promoted.status_code == 200, promoted.text
    person_id = uuid.UUID(promoted.json()["person"]["id"])

    later, _, _ = _sighting(
        worker_session,
        patient_id,
        device_id,
        DAY1 + timedelta(days=5),
        _near(neighbour),
    )
    cluster_tasks.unknown_faces.delay().get()
    encounter = _encounter(worker_session, later)
    assert encounter.person_id == person_id and encounter.cluster_id is None


def test_a_broken_vector_is_marked_and_skipped(client, worker_session):
    _, _, patient_id, device_id = _patient(client)
    seen, event_id, _ = _sighting(
        worker_session, patient_id, device_id, DAY1, None, embedding="garbage"
    )
    result = cluster_tasks.unknown_faces.delay().get()
    assert result["invalid"] >= 1
    with worker_session() as db:
        meta = db.get(Event, event_id).metadata_
        assert meta.get("unknown_embedding_invalid") is True
        assert "unknown_embedding" not in meta
    assert _encounter(worker_session, seen).cluster_id is None
    # the next sweep doesn't pick it up again
    with worker_session() as db:
        from app.services import clustering_service

        assert seen not in [e.id for e, _ in clustering_service.pending(db, 10_000)]
