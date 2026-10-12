"""Accounts: users, patient profiles, caregiver links, tokens, devices."""

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    Enum,
    ForeignKey,
    Integer,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    created_at,
    deleted_at,
    fk,
    pk,
    ts,
    updated_at,
)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = pk()
    role: Mapped[str] = mapped_column(Enum("patient", "caregiver", name="user_role"))
    full_name: Mapped[str] = mapped_column(Text)
    email: Mapped[str | None] = mapped_column(Text, unique=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # A4 patient form has no phone
    password_hash: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # caregivers only
    created_at: Mapped[datetime] = created_at()
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True
    )
    preferred_language: Mapped[str] = mapped_column(
        Enum("ar", "en", name="language_code")
    )
    timezone: Mapped[str] = mapped_column(Text, server_default="Africa/Cairo")
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    memory_capture_enabled: Mapped[bool] = mapped_column(
        Boolean, server_default=text("true")
    )
    updated_at: Mapped[datetime] = updated_at()


class CaregiverPatientLink(Base):
    __tablename__ = "caregiver_patient_links"
    __table_args__ = (UniqueConstraint("caregiver_id", "patient_id"),)

    id: Mapped[uuid.UUID] = pk()
    caregiver_id: Mapped[uuid.UUID] = fk("users.id")
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    relationship: Mapped[str] = mapped_column(Text)
    is_primary: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))
    permission: Mapped[str] = mapped_column(
        Enum("viewer", "manager", name="link_permission")
    )
    created_at: Mapped[datetime] = created_at()


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk("users.id")
    token_hash: Mapped[str] = mapped_column(Text, unique=True)
    expires_at: Mapped[datetime] = ts()
    revoked_at: Mapped[datetime | None] = ts(nullable=True)


class PushToken(Base):
    __tablename__ = "push_tokens"

    id: Mapped[uuid.UUID] = pk()
    user_id: Mapped[uuid.UUID] = fk("users.id")
    fcm_token: Mapped[str] = mapped_column(Text, unique=True)
    updated_at: Mapped[datetime] = updated_at()


class Device(Base):
    __tablename__ = "devices"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    serial_number: Mapped[str] = mapped_column(Text, unique=True)
    token_hash: Mapped[str] = mapped_column(Text, unique=True)
    firmware_version: Mapped[str] = mapped_column(Text)
    battery_level_pct: Mapped[int | None] = mapped_column(Integer, nullable=True)
    last_seen_at: Mapped[datetime | None] = ts(nullable=True)
    paired_at: Mapped[datetime] = ts()
    unpaired_at: Mapped[datetime | None] = ts(nullable=True)  # token dead; row kept
