"""What changed for a patient since T (spec D7). The phone keeps a local copy and pulls
deltas; the glasses get people and reminders from the phone over BLE."""

import uuid
from collections import defaultdict
from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.ai.inference.face import to_base64_f16
from app.models import (
    EnrolledPerson,
    FaceEmbedding,
    PatientProfile,
    Place,
    Reminder,
    User,
)
from app.schemas.places import PlaceOut
from app.schemas.reminders import ReminderOut
from app.schemas.sync import (
    PeopleDelta,
    PlacesDelta,
    RemindersDelta,
    SyncOut,
    SyncPerson,
    SyncSettings,
)

# updated_at is the database's now(), i.e. the start of the writing transaction, so a write
# that commits just after a pull can carry an earlier time. Re-sending a short window is
# harmless (upserts and deletes are idempotent) and closes that gap.
OVERLAP = timedelta(seconds=30)


def _changed(db: Session, model, patient_id: uuid.UUID, since: datetime | None) -> list:
    query = select(model).where(model.patient_id == patient_id)
    if since is None:
        query = query.where(model.deleted_at.is_(None))
    else:
        query = query.where(model.updated_at >= since - OVERLAP)
    return list(db.scalars(query.order_by(model.updated_at)))


def _people(db: Session, people: list[EnrolledPerson]) -> PeopleDelta:
    live = [p for p in people if p.deleted_at is None and p.status == "active"]
    vectors = defaultdict(list)
    if live:
        rows = db.execute(
            select(
                FaceEmbedding.person_id,
                FaceEmbedding.embedding,
                FaceEmbedding.model_version,
            )
            .where(FaceEmbedding.person_id.in_([p.id for p in live]))
            .order_by(FaceEmbedding.created_at)
        )
        for person_id, embedding, version in rows:
            vectors[person_id].append((to_base64_f16(list(embedding)), version))
    return PeopleDelta(
        upserts=[
            SyncPerson(
                id=p.id,
                name=p.name,
                relationship=p.relationship,
                embeddings=[e for e, _ in vectors[p.id]],
                model_versions=[v for _, v in vectors[p.id]],
                updated_at=p.updated_at,
            )
            for p in live
        ],
        deletes=[p.id for p in people if p not in live],
    )


def sync(db: Session, patient_id: uuid.UUID, since: datetime | None) -> SyncOut:
    server_time = db.scalar(select(func.now()))
    patient = db.get(User, patient_id)
    profile = db.get(PatientProfile, patient_id)
    reminders = _changed(db, Reminder, patient_id, since)
    places = _changed(db, Place, patient_id, since)
    return SyncOut(
        server_time=server_time,
        full=since is None,
        settings=SyncSettings(
            full_name=patient.full_name,
            preferred_language=profile.preferred_language,
            timezone=profile.timezone,
            memory_capture_enabled=profile.memory_capture_enabled,
        ),
        people=_people(db, _changed(db, EnrolledPerson, patient_id, since)),
        reminders=RemindersDelta(
            upserts=[
                ReminderOut.model_validate(r) for r in reminders if r.deleted_at is None
            ],
            deletes=[r.id for r in reminders if r.deleted_at is not None],
        ),
        places=PlacesDelta(
            upserts=[
                PlaceOut.model_validate(p) for p in places if p.deleted_at is None
            ],
            deletes=[p.id for p in places if p.deleted_at is not None],
        ),
    )
