"""Reminders and their occurrences (spec D6)."""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Enum,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    deleted_at,
    fk,
    pk,
    ts,
    updated_at,
)


class Reminder(Base):
    __tablename__ = "reminders"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    title: Mapped[str] = mapped_column(Text)
    spoken_text: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # defaults to title
    type: Mapped[str] = mapped_column(
        Enum("medication", "appointment", "task", name="reminder_type")
    )
    rrule: Mapped[str] = mapped_column(Text)
    dtstart: Mapped[datetime] = ts()
    timezone: Mapped[str] = mapped_column(Text, server_default="Africa/Cairo")
    active: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    created_by: Mapped[uuid.UUID] = fk("users.id")
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class ReminderLog(Base):
    __tablename__ = "reminder_logs"

    id: Mapped[uuid.UUID] = pk()  # client-generated on the phone
    reminder_id: Mapped[uuid.UUID] = fk("reminders.id")
    scheduled_at: Mapped[datetime] = ts()
    status: Mapped[str] = mapped_column(
        Enum("pending", "completed", "snoozed", "missed", name="reminder_log_status"),
        server_default="pending",
    )
    snoozed_until: Mapped[datetime | None] = ts(nullable=True)
    completed_at: Mapped[datetime | None] = ts(nullable=True)
    confirmed_via: Mapped[str | None] = mapped_column(
        Enum("voice", "app", "caregiver", name="confirmation_channel"), nullable=True
    )
    updated_at: Mapped[datetime] = updated_at()
