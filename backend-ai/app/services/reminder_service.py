"""Reminders (spec D6). Caregivers write the rules; the phone expands them into occurrences,
fires them through the glasses, and reports each occurrence back as a reminder log."""

import uuid
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import NotFound
from app.models import PatientProfile, Reminder, ReminderLog, User
from app.schemas.common import BatchResult
from app.schemas.reminders import (
    ReminderCreate,
    ReminderLogIn,
    ReminderLogOut,
    ReminderUpdate,
)


def list_reminders(db: Session, patient_id: uuid.UUID) -> list[Reminder]:
    return list(
        db.scalars(
            select(Reminder)
            .where(Reminder.patient_id == patient_id, Reminder.deleted_at.is_(None))
            .order_by(Reminder.dtstart)
        )
    )


def get_reminder(
    db: Session, patient_id: uuid.UUID, reminder_id: uuid.UUID
) -> Reminder:
    reminder = db.get(Reminder, reminder_id)
    if (
        reminder is None
        or reminder.patient_id != patient_id
        or reminder.deleted_at is not None
    ):
        raise NotFound("Reminder not found.", code="REMINDER_NOT_FOUND")
    return reminder


def create_reminder(
    db: Session, patient_id: uuid.UUID, caregiver: User, data: ReminderCreate
) -> Reminder:
    reminder = Reminder(
        patient_id=patient_id, created_by=caregiver.id, **data.model_dump()
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder


def update_reminder(
    db: Session, patient_id: uuid.UUID, reminder_id: uuid.UUID, data: ReminderUpdate
) -> Reminder:
    reminder = get_reminder(db, patient_id, reminder_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        if (
            value is not None or field == "spoken_text"
        ):  # spoken_text null = "say the title"
            setattr(reminder, field, value)
    db.commit()
    db.refresh(reminder)
    return reminder


def delete_reminder(db: Session, patient_id: uuid.UUID, reminder_id: uuid.UUID) -> None:
    reminder = get_reminder(db, patient_id, reminder_id)
    # soft delete, so the phone learns through /sync
    reminder.deleted_at = datetime.now(UTC)
    reminder.active = False
    db.commit()


def _incoming_wins(existing: ReminderLog, incoming: ReminderLogIn) -> bool:
    """Merge rule (spec §7.1): 'completed' always wins; otherwise the latest change wins."""
    if existing.status == "completed":
        return False
    if incoming.status == "completed":
        return True
    return (incoming.at or datetime.now(UTC)) > existing.updated_at


def upsert_logs(
    db: Session, patient_id: uuid.UUID, logs: list[ReminderLogIn]
) -> BatchResult:
    """Idempotent: the phone may resend the same batch after a lost response."""
    own_reminders = set(
        db.scalars(
            select(Reminder.id).where(
                Reminder.id.in_({log.reminder_id for log in logs}),
                Reminder.patient_id == patient_id,
            )
        )
    )
    existing = {
        row.id: row
        for row in db.scalars(
            select(ReminderLog).where(ReminderLog.id.in_([log.id for log in logs]))
        )
    }

    result = BatchResult(accepted=[], duplicates=[], rejected=[])
    for log in logs:
        if log.reminder_id not in own_reminders:
            result.rejected.append(log.id)
            continue
        fields = log.model_dump(exclude={"id", "at"})
        row = existing.get(log.id)
        if row is None:
            row = ReminderLog(id=log.id, **fields)
            db.add(row)
            existing[log.id] = row
            result.accepted.append(log.id)
        elif row.reminder_id != log.reminder_id:
            result.rejected.append(log.id)  # an id can't move to another reminder
        elif _incoming_wins(row, log):
            for field, value in fields.items():
                setattr(row, field, value)
            result.accepted.append(log.id)
        else:
            result.duplicates.append(log.id)
    db.commit()
    return result


def list_logs(
    db: Session, patient_id: uuid.UUID, day: date | None
) -> list[ReminderLogOut]:
    """One day's occurrences in the patient's timezone (C1 "1/3 done", C8 Today), by time."""
    tz = ZoneInfo(db.get(PatientProfile, patient_id).timezone)
    day = day or datetime.now(tz).date()
    start = datetime.combine(day, time.min, tzinfo=tz)
    rows = db.execute(
        select(ReminderLog, Reminder.title, Reminder.type)
        .join(Reminder, Reminder.id == ReminderLog.reminder_id)
        .where(
            Reminder.patient_id == patient_id,
            ReminderLog.scheduled_at >= start,
            ReminderLog.scheduled_at < start + timedelta(days=1),
        )
        .order_by(ReminderLog.scheduled_at)
    )
    return [
        ReminderLogOut.model_validate(log).model_copy(
            update={"title": title, "type": kind}
        )
        for log, title, kind in rows
    ]
