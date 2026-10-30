"""Caregiver alerts made by the `alerts.evaluate` task every 5 minutes (screens C1, C2).

Rules (spec defaults, the lead's choice):
- missed medication: a medication occurrence marked missed, or still pending/snoozed
  60 minutes after its time (the spec's grace period), within the last 24 hours;
- device offline: no heartbeat for 30 minutes (once per offline spell);
- low battery: 20% or less on a connected device (at most once every 12 hours).
Every linked caregiver gets each alert once. Running the evaluation twice creates nothing new.
Occurrences the phone never reported can't be seen here; the offline alert covers that case.
Push notifications (FCM) for these alerts arrive in Phase 9.
"""

from collections import defaultdict
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models import (
    CaregiverAlert,
    CaregiverPatientLink,
    Device,
    PatientProfile,
    Reminder,
    ReminderLog,
    User,
)

GRACE = timedelta(minutes=60)
LOOKBACK = timedelta(hours=24)
OFFLINE_AFTER = timedelta(minutes=30)
LOW_BATTERY_PCT = 20
LOW_BATTERY_REPEAT = timedelta(hours=12)


def _caregivers(db: Session, patient_ids: set) -> dict:
    """patient id -> ids of every linked, active caregiver."""
    out = defaultdict(list)
    if patient_ids:
        rows = db.execute(
            select(CaregiverPatientLink.patient_id, CaregiverPatientLink.caregiver_id)
            .join(User, User.id == CaregiverPatientLink.caregiver_id)
            .where(
                CaregiverPatientLink.patient_id.in_(patient_ids),
                User.deleted_at.is_(None),
            )
        )
        for patient_id, caregiver_id in rows:
            out[patient_id].append(caregiver_id)
    return out


def _patients(db: Session, patient_ids: set) -> dict:
    """patient id -> (first name, timezone) for the alert text."""
    if not patient_ids:
        return {}
    rows = db.execute(
        select(User.id, User.full_name, PatientProfile.timezone)
        .join(PatientProfile, PatientProfile.user_id == User.id)
        .where(User.id.in_(patient_ids))
    )
    return {pid: (name.split()[0], ZoneInfo(tz)) for pid, name, tz in rows}


def _already_sent(db: Session, alert_type: str, entity_ids: list, since=None) -> set:
    """(caregiver id, entity id) pairs that already have this alert (optionally since T)."""
    if not entity_ids:
        return set()
    query = select(CaregiverAlert.caregiver_id, CaregiverAlert.entity_id).where(
        CaregiverAlert.alert_type == alert_type,
        CaregiverAlert.entity_id.in_(entity_ids),
    )
    if since is not None:
        query = query.where(CaregiverAlert.created_at >= since)
    return set(db.execute(query).all())


def _add(
    db, sent, caregivers, patient_id, alert_type, entity_type, entity_id, message
) -> int:
    created = 0
    for caregiver_id in caregivers.get(patient_id, []):
        if (caregiver_id, entity_id) in sent:
            continue
        db.add(
            CaregiverAlert(
                caregiver_id=caregiver_id,
                patient_id=patient_id,
                alert_type=alert_type,
                message=message,
                entity_type=entity_type,
                entity_id=entity_id,
            )
        )
        created += 1
    return created


def _missed_medication(db: Session, now: datetime) -> int:
    rows = db.execute(
        select(ReminderLog, Reminder.title, Reminder.patient_id)
        .join(Reminder, Reminder.id == ReminderLog.reminder_id)
        .where(
            Reminder.type == "medication",
            Reminder.deleted_at.is_(None),
            ReminderLog.scheduled_at >= now - LOOKBACK,
            or_(
                ReminderLog.status == "missed",
                (ReminderLog.status == "pending")
                & (ReminderLog.scheduled_at < now - GRACE),
                (ReminderLog.status == "snoozed")
                & (ReminderLog.snoozed_until < now - GRACE),
            ),
        )
    ).all()
    patient_ids = {patient_id for _, _, patient_id in rows}
    caregivers, patients = _caregivers(db, patient_ids), _patients(db, patient_ids)
    sent = _already_sent(db, "missed_medication", [log.id for log, _, _ in rows])
    created = 0
    for log, title, patient_id in rows:
        name, tz = patients[patient_id]
        at = log.scheduled_at.astimezone(tz).strftime("%H:%M")
        created += _add(
            db,
            sent,
            caregivers,
            patient_id,
            "missed_medication",
            "reminder_log",
            log.id,
            f"{name} missed {title} ({at})",
        )
    return created


def _devices(db: Session, now: datetime) -> int:
    devices = list(
        db.scalars(
            select(Device).where(
                Device.unpaired_at.is_(None), Device.last_seen_at.is_not(None)
            )
        )
    )
    patient_ids = {d.patient_id for d in devices}
    caregivers, patients = _caregivers(db, patient_ids), _patients(db, patient_ids)
    created = 0

    offline = [d for d in devices if d.last_seen_at < now - OFFLINE_AFTER]
    for device in offline:
        # once per offline spell: an alert made after the last heartbeat already covers it
        sent = _already_sent(
            db, "device_offline", [device.id], since=device.last_seen_at
        )
        name, tz = patients[device.patient_id]
        since = device.last_seen_at.astimezone(tz).strftime("%H:%M")
        created += _add(
            db,
            sent,
            caregivers,
            device.patient_id,
            "device_offline",
            "device",
            device.id,
            f"{name}'s glasses have been offline since {since}",
        )

    low = [
        d
        for d in devices
        if d not in offline
        and d.battery_level_pct is not None
        and d.battery_level_pct <= LOW_BATTERY_PCT
    ]
    sent = _already_sent(
        db, "low_battery", [d.id for d in low], since=now - LOW_BATTERY_REPEAT
    )
    for device in low:
        name, _ = patients[device.patient_id]
        created += _add(
            db,
            sent,
            caregivers,
            device.patient_id,
            "low_battery",
            "device",
            device.id,
            f"{name}'s glasses battery is at {device.battery_level_pct}%",
        )
    return created


def evaluate(db: Session, now: datetime | None = None) -> int:
    """Create every alert that is due; returns how many were created."""
    now = now or datetime.now(UTC)
    created = _missed_medication(db, now) + _devices(db, now)
    db.commit()
    return created


def flag_unknown_face(db: Session, patient_id, cluster_id, days: int) -> int:
    """A stranger seen on `days` different days (spec D23): every linked caregiver is
    asked once, and the alert opens the cluster (C7). Called by the clustering sweep;
    the caller commits."""
    caregivers = _caregivers(db, {patient_id})
    sent = _already_sent(db, "unknown_person_flagged", [cluster_id])
    return _add(
        db,
        sent,
        caregivers,
        patient_id,
        "unknown_person_flagged",
        "unknown_face_cluster",
        cluster_id,
        f"A new face has visited on {days} different days.",
    )
