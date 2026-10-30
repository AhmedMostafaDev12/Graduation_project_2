"""Unknown faces → clusters → the caregiver is asked at 3 different days (spec D23, D35; 8.4).

Run by the `cluster.unknown_faces` sweep. For each encounter the glasses marked unknown
(`person_id` null) whose event carries `metadata.unknown_embedding`, oldest first:

1. A face this close to an enrolled person is that person: the encounter gets `person_id`.
2. Otherwise it joins the nearest cluster of the same patient (not promoted ones: their
   person is enrolled now), or starts a new one. A dismissed cluster still absorbs its
   stranger, so the caregiver isn't asked about them again.
3. The cluster's centroid, counts and distinct days (in the patient's timezone) are updated;
   its first photo becomes the sample shown in C6/C7.
4. An open cluster reaching `settings.unknown_face_days` different days moves to
   `awaiting_caregiver` and every linked caregiver gets one alert.

The raw per-encounter vector is then removed from the event (it lives on only inside the
cluster's centroid, D35). One sweep at a time (the task's lock), so clusters never race.
Never logs face vectors (AI_LAYER.md rule 8).
"""

import logging
import uuid
from dataclasses import dataclass

import numpy as np
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.ai import clustering
from app.ai.inference import face
from app.config import settings
from app.models import (
    FACE_DIM,
    Encounter,
    EnrolledPerson,
    Event,
    FaceEmbedding,
    MediaAsset,
    PatientProfile,
    UnknownFaceCluster,
)
from app.services import alert_service

logger = logging.getLogger(__name__)

EMBEDDING_KEY = "unknown_embedding"
INVALID_KEY = "unknown_embedding_invalid"
BATCH = 500  # encounters per sweep; the next sweep continues


@dataclass
class _Patient:
    """What one sweep needs about a patient, loaded once."""

    timezone: str
    people: list[uuid.UUID]
    people_vectors: np.ndarray
    clusters: list[UnknownFaceCluster]
    centroids: np.ndarray


def _load_patient(db: Session, patient_id: uuid.UUID) -> _Patient:
    profile = db.get(PatientProfile, patient_id)
    rows = db.execute(
        select(FaceEmbedding.person_id, FaceEmbedding.embedding)
        .join(EnrolledPerson, EnrolledPerson.id == FaceEmbedding.person_id)
        .where(
            EnrolledPerson.patient_id == patient_id,
            EnrolledPerson.status == "active",
            EnrolledPerson.deleted_at.is_(None),
            # the glasses' model: compare like with like (stub rows are ignored)
            FaceEmbedding.model_version == face.EDGE_MODEL_VERSION,
        )
    ).all()
    clusters = list(
        db.scalars(
            select(UnknownFaceCluster)
            .where(
                UnknownFaceCluster.patient_id == patient_id,
                UnknownFaceCluster.status != "promoted",
            )
            .order_by(UnknownFaceCluster.first_seen_at)
        )
    )
    return _Patient(
        timezone=profile.timezone if profile else "Africa/Cairo",
        people=[person_id for person_id, _ in rows],
        people_vectors=_matrix([v for _, v in rows]),
        clusters=clusters,
        centroids=_matrix([c.centroid for c in clusters]),
    )


def _matrix(vectors) -> np.ndarray:
    if not len(vectors):
        return np.zeros((0, FACE_DIM), dtype=np.float32)
    return np.array([list(v) for v in vectors], dtype=np.float32)


def pending(db: Session, limit: int = BATCH) -> list[tuple[Encounter, Event]]:
    """Unknown encounters not clustered yet, with the event that carries their vector."""
    return list(
        db.execute(
            select(Encounter, Event)
            .join(Event, Event.encounter_id == Encounter.id)
            .where(
                Encounter.person_id.is_(None),
                Encounter.cluster_id.is_(None),
                Event.metadata_.has_key(EMBEDDING_KEY),
                ~Event.metadata_.has_key(INVALID_KEY),
                Event.deleted_at.is_(None),
            )
            .order_by(Encounter.started_at)
            .limit(limit)
        ).all()
    )


def _distinct_days(db: Session, cluster_id: uuid.UUID, timezone: str) -> int:
    local_day = func.date(func.timezone(timezone, Encounter.started_at))
    return db.scalar(
        select(func.count(func.distinct(local_day))).where(
            Encounter.cluster_id == cluster_id
        )
    )


def _sample_media(db: Session, event: Event) -> uuid.UUID | None:
    return db.scalar(
        select(MediaAsset.id)
        .where(MediaAsset.event_id == event.id, MediaAsset.deleted_at.is_(None))
        .order_by(MediaAsset.created_at)
        .limit(1)
    )


def _forget_raw_vector(event: Event, invalid: bool = False) -> None:
    meta = {k: v for k, v in (event.metadata_ or {}).items() if k != EMBEDDING_KEY}
    if invalid:
        meta[INVALID_KEY] = True
    event.metadata_ = meta  # a new dict, so the JSONB change is seen


def _assign(
    db: Session, patient: _Patient, encounter: Encounter, event: Event, vector
) -> str:
    person = clustering.nearest(
        vector, patient.people_vectors, clustering.ENROLLED_MATCH
    )
    if person is not None:
        encounter.person_id = patient.people[person]
        return "person"

    index = clustering.nearest(vector, patient.centroids, clustering.SAME_CLUSTER)
    if index is None:
        cluster = UnknownFaceCluster(
            id=uuid.uuid4(),
            patient_id=encounter.patient_id,
            centroid=vector.tolist(),
            sighting_count=1,
            distinct_days=1,
            first_seen_at=encounter.started_at,
            last_seen_at=encounter.started_at,
            status="open",
        )
        db.add(cluster)
        db.flush()
        patient.clusters.append(cluster)
        patient.centroids = np.vstack([patient.centroids, vector[None, :]])
        outcome = "new_cluster"
    else:
        cluster = patient.clusters[index]
        centroid = clustering.add_to_centroid(
            patient.centroids[index], cluster.sighting_count, vector
        )
        patient.centroids[index] = centroid
        cluster.centroid = centroid.tolist()
        cluster.sighting_count += 1
        cluster.first_seen_at = min(cluster.first_seen_at, encounter.started_at)
        cluster.last_seen_at = max(cluster.last_seen_at, encounter.started_at)
        outcome = "joined"

    encounter.cluster_id = cluster.id
    db.flush()
    cluster.distinct_days = _distinct_days(db, cluster.id, patient.timezone)
    if cluster.sample_media_id is None:
        cluster.sample_media_id = _sample_media(db, event)
    if cluster.status == "open" and cluster.distinct_days >= settings.unknown_face_days:
        cluster.status = "awaiting_caregiver"
        alert_service.flag_unknown_face(
            db, cluster.patient_id, cluster.id, cluster.distinct_days
        )
        outcome = "flagged"
    return outcome


def sweep(db: Session, limit: int = BATCH) -> dict:
    """Cluster every pending unknown encounter; counts per outcome."""
    counts = {"person": 0, "new_cluster": 0, "joined": 0, "flagged": 0, "invalid": 0}
    patients: dict[uuid.UUID, _Patient] = {}
    for encounter, event in pending(db, limit):
        try:
            vector = clustering.decode(event.metadata_[EMBEDDING_KEY])
        except clustering.BadEmbedding:
            _forget_raw_vector(event, invalid=True)
            db.commit()
            counts["invalid"] += 1
            continue
        if encounter.patient_id not in patients:
            patients[encounter.patient_id] = _load_patient(db, encounter.patient_id)
        outcome = _assign(db, patients[encounter.patient_id], encounter, event, vector)
        _forget_raw_vector(event)
        db.commit()  # per encounter: a later failure keeps the work already done
        counts[outcome] += 1
    if any(counts.values()):
        logger.info("unknown faces clustered: %s", counts)  # counts only, never vectors
    return counts
