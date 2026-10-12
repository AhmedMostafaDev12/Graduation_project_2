"""The patient's memory timeline: what the glasses and phone recorded (spec D1, §7.2)."""

import uuid
from collections import defaultdict
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.integrations import s3
from app.models import (
    Encounter,
    EnrolledPerson,
    Event,
    MediaAsset,
    PatientProfile,
    Reminder,
    ReminderLog,
)
from app.oauth2 import PatientAccess
from app.schemas.common import BatchResult
from app.schemas.journal import (
    EventsBatch,
    JournalEntry,
    JournalMedia,
    JournalOut,
    JournalPerson,
)
from app.services import media_service


def _owned(db: Session, model, ids: set, patient_id: uuid.UUID) -> set:
    if not ids:
        return set()
    return set(
        db.scalars(
            select(model.id).where(model.id.in_(ids), model.patient_id == patient_id)
        )
    )


def _existing(db: Session, model, ids: list) -> dict:
    """id -> patient_id for rows that already exist (idempotent resend, or someone else's id)."""
    if not ids:
        return {}
    return dict(
        db.execute(select(model.id, model.patient_id).where(model.id.in_(ids))).all()
    )


def upload_batch(db: Session, access: PatientAccess, batch: EventsBatch) -> BatchResult:
    """Idempotent: a resent batch reports its rows as duplicates. A row pointing at something
    this patient doesn't have is rejected without failing the rest of the batch."""
    patient_id = access.patient_id
    device = access.principal.device  # None for a caregiver
    result = BatchResult(accepted=[], duplicates=[], rejected=[])

    people = _owned(
        db,
        EnrolledPerson,
        {e.person_id for e in batch.encounters} | {e.person_id for e in batch.events},
        patient_id,
    )
    people.add(None)

    def sort(row_id, seen: dict) -> bool:
        """True when the row is new; otherwise record it as a duplicate or rejection."""
        if row_id not in seen:
            return True
        (result.duplicates if seen[row_id] == patient_id else result.rejected).append(
            row_id
        )
        return False

    seen = _existing(db, Encounter, [e.id for e in batch.encounters])
    for enc in batch.encounters:
        if not sort(enc.id, seen):
            continue
        if device is None or enc.person_id not in people:
            result.rejected.append(enc.id)  # encounters only come from the glasses
            continue
        db.add(
            Encounter(patient_id=patient_id, device_id=device.id, **enc.model_dump())
        )
        seen[enc.id] = patient_id
        result.accepted.append(enc.id)
    db.flush()  # events may point at the encounters above

    encounters = _owned(
        db, Encounter, {e.encounter_id for e in batch.events}, patient_id
    )
    encounters.add(None)
    log_ids = {e.reminder_log_id for e in batch.events if e.reminder_log_id}
    reminder_logs = (
        set(
            db.scalars(
                select(ReminderLog.id)
                .join(Reminder, Reminder.id == ReminderLog.reminder_id)
                .where(ReminderLog.id.in_(log_ids), Reminder.patient_id == patient_id)
            )
        )
        if log_ids
        else set()
    )
    reminder_logs.add(None)

    seen = _existing(db, Event, [e.id for e in batch.events])
    for ev in batch.events:
        if not sort(ev.id, seen):
            continue
        if (
            ev.person_id not in people
            or ev.encounter_id not in encounters
            or ev.reminder_log_id not in reminder_logs
        ):
            result.rejected.append(ev.id)
            continue
        fields = ev.model_dump(exclude={"metadata", "source"})
        db.add(
            Event(
                patient_id=patient_id,
                device_id=device.id if device else None,
                source=ev.source if device else "app",
                metadata_=ev.metadata,
                **fields,
            )
        )
        seen[ev.id] = patient_id
        result.accepted.append(ev.id)
    db.commit()
    return result


def journal(db: Session, access: PatientAccess, day: date | None) -> JournalOut:
    """One day in the patient's own timezone, oldest first (screens P4, C12). Photos come
    with signed URLs, so the screen needs no request per photo; every URL is audit-logged."""
    patient_id = access.patient_id
    tz_name = db.get(PatientProfile, patient_id).timezone
    tz = ZoneInfo(tz_name)
    day = day or datetime.now(tz).date()
    start = datetime.combine(day, time.min, tzinfo=tz).astimezone(UTC)
    end = datetime.combine(day + timedelta(days=1), time.min, tzinfo=tz).astimezone(UTC)

    events = list(
        db.scalars(
            select(Event)
            .where(
                Event.patient_id == patient_id,
                Event.deleted_at.is_(None),
                Event.occurred_at >= start,
                Event.occurred_at < end,
            )
            .order_by(Event.occurred_at)
        )
    )
    event_ids = [e.id for e in events]

    media = defaultdict(list)
    if event_ids:
        for asset in db.scalars(
            select(MediaAsset).where(
                MediaAsset.event_id.in_(event_ids),
                MediaAsset.deleted_at.is_(None),
                MediaAsset.status != "discarded",
            )
        ):
            media[asset.event_id].append(
                JournalMedia(
                    id=asset.id,
                    asset_type=asset.asset_type,
                    trigger=asset.trigger,
                    status=asset.status,
                    duration_seconds=asset.duration_seconds,
                    expires_at=asset.expires_at,
                    url=s3.presign_get(asset.storage_key),
                )
            )

    # an encounter event may name its person only through the encounter
    encounter_people = {}
    encounter_ids = {e.encounter_id for e in events if e.encounter_id}
    if encounter_ids:
        encounter_people = dict(
            db.execute(
                select(Encounter.id, Encounter.person_id).where(
                    Encounter.id.in_(encounter_ids)
                )
            ).all()
        )
    person_ids = {
        e.person_id or encounter_people.get(e.encounter_id) for e in events
    } - {None}
    people = {}
    if person_ids:
        people = {
            p.id: JournalPerson(id=p.id, name=p.name, relationship=p.relationship)
            for p in db.scalars(
                select(EnrolledPerson).where(EnrolledPerson.id.in_(person_ids))
            )
        }

    entries = [
        JournalEntry(
            id=e.id,
            event_type=e.event_type,
            source=e.source,
            occurred_at=e.occurred_at,
            ended_at=e.ended_at,
            person=people.get(e.person_id or encounter_people.get(e.encounter_id)),
            transcript_text=e.transcript_text,
            language=e.language,
            rendered_text=e.rendered_text,
            # face vectors are for the clustering worker, not for people
            metadata={k: v for k, v in e.metadata_.items() if k != "unknown_embedding"},
            media=media[e.id],
        )
        for e in events
    ]
    media_service.audit(
        db, access, "media.view", [m.id for ms in media.values() for m in ms]
    )
    db.commit()
    return JournalOut(date=day, timezone=tz_name, entries=entries)
