"""Mind games, daily summaries, caregiver alerts and push tokens (screens P5, C12-C17)."""

import uuid
from datetime import UTC, date, datetime
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound
from app.models import (
    CaregiverAlert,
    DailySummary,
    Event,
    MindGameSession,
    PatientProfile,
    PushToken,
    User,
)
from app.oauth2 import PatientAccess
from app.schemas.activity import MindGameIn


def log_game(db: Session, access: PatientAccess, data: MindGameIn) -> MindGameSession:
    """Idempotent by id. Also writes a journal event so the game shows on the day's timeline."""
    session = db.get(MindGameSession, data.id)
    if session is not None:
        if session.patient_id != access.patient_id:
            raise Conflict("This id is already used.", code="ID_IN_USE")
        return session
    session = MindGameSession(patient_id=access.patient_id, **data.model_dump())
    db.add(session)
    db.flush()
    device = access.principal.device
    db.add(
        Event(
            id=uuid.uuid5(session.id, "event"),
            patient_id=access.patient_id,
            device_id=device.id if device else None,
            source="app",
            event_type="mind_game_session",
            mind_game_session_id=session.id,
            occurred_at=data.completed_at,
            metadata_={"game_type": data.game_type, "score": data.score},
        )
    )
    db.commit()
    db.refresh(session)
    return session


def daily_summary(db: Session, patient_id: uuid.UUID, day: date | None) -> DailySummary:
    if day is None:
        tz = ZoneInfo(db.get(PatientProfile, patient_id).timezone)
        day = datetime.now(tz).date()
    summary = db.scalar(
        select(DailySummary).where(
            DailySummary.patient_id == patient_id, DailySummary.summary_date == day
        )
    )
    if summary is None:
        raise NotFound("No summary for this day yet.", code="SUMMARY_NOT_READY")
    return summary


def list_alerts(
    db: Session, caregiver: User, unread_only: bool, limit: int, offset: int
) -> list[CaregiverAlert]:
    query = select(CaregiverAlert).where(CaregiverAlert.caregiver_id == caregiver.id)
    if unread_only:
        query = query.where(CaregiverAlert.read_at.is_(None))
    query = query.order_by(CaregiverAlert.created_at.desc()).limit(limit).offset(offset)
    return list(db.scalars(query))


def mark_read(db: Session, caregiver: User, alert_id: uuid.UUID) -> CaregiverAlert:
    alert = db.get(CaregiverAlert, alert_id)
    if alert is None or alert.caregiver_id != caregiver.id:
        raise NotFound("Alert not found.", code="ALERT_NOT_FOUND")
    if alert.read_at is None:
        alert.read_at = datetime.now(UTC)
        db.commit()
        db.refresh(alert)
    return alert


def register_push_token(db: Session, caregiver: User, fcm_token: str) -> None:
    """One row per phone. A token seen before moves to whoever signed in on that phone last."""
    row = db.scalar(select(PushToken).where(PushToken.fcm_token == fcm_token))
    if row is None:
        db.add(PushToken(user_id=caregiver.id, fcm_token=fcm_token))
    else:
        row.user_id = caregiver.id
    db.commit()


def list_games(
    db: Session, patient_id: uuid.UUID, game_type: str | None, limit: int, offset: int
) -> list[MindGameSession]:
    """Past sessions, newest first (P7 last score per game)."""
    query = select(MindGameSession).where(MindGameSession.patient_id == patient_id)
    if game_type:
        query = query.where(MindGameSession.game_type == game_type)
    query = (
        query.order_by(MindGameSession.completed_at.desc()).limit(limit).offset(offset)
    )
    return list(db.scalars(query))
