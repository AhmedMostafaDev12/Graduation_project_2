"""Mind games, daily summaries, caregiver alerts."""

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Date,
    Enum,
    Integer,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    created_at,
    fk,
    pk,
    ts,
)


class MindGameSession(Base):
    __tablename__ = "mind_game_sessions"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    game_type: Mapped[str] = mapped_column(Text)
    score: Mapped[int] = mapped_column(Integer)
    duration_seconds: Mapped[int] = mapped_column(Integer)
    completed_at: Mapped[datetime] = ts()


class DailySummary(Base):
    __tablename__ = "daily_summaries"
    __table_args__ = (UniqueConstraint("patient_id", "summary_date"),)

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    summary_date: Mapped[date] = mapped_column(Date)
    summary_text: Mapped[str] = mapped_column(Text)
    patterns: Mapped[dict] = mapped_column(JSONB, server_default=text("'{}'::jsonb"))
    generated_at: Mapped[datetime] = ts()


class CaregiverAlert(Base):
    __tablename__ = "caregiver_alerts"

    id: Mapped[uuid.UUID] = pk()
    caregiver_id: Mapped[uuid.UUID] = fk("users.id")
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    alert_type: Mapped[str] = mapped_column(
        Enum(
            "missed_medication",
            "unknown_person_flagged",
            "low_battery",
            "device_offline",
            "daily_summary_ready",
            name="alert_type",
        )
    )
    message: Mapped[str] = mapped_column(Text)
    # what the alert is about, so the app can open it (C2)
    entity_type: Mapped[str | None] = mapped_column(Text, nullable=True)
    entity_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    read_at: Mapped[datetime | None] = ts(nullable=True)
    created_at: Mapped[datetime] = created_at()
