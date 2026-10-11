"""Consent records and the audit log (spec D24)."""

import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    Enum,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    fk,
    pk,
    ts,
)


class ConsentRecord(Base):
    __tablename__ = "consent_records"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    subject_person_id: Mapped[uuid.UUID | None] = fk(
        "enrolled_people.id", nullable=True
    )
    consent_type: Mapped[str] = mapped_column(
        Enum(
            "face_enrollment",
            "ambient_audio_household",
            "cloud_processing",
            "media_retention",
            name="consent_type",
        )
    )
    given_by: Mapped[uuid.UUID] = fk("users.id")
    given_at: Mapped[datetime] = ts()
    revoked_at: Mapped[datetime | None] = ts(nullable=True)


class AuditLog(Base):
    __tablename__ = "audit_log"

    id: Mapped[uuid.UUID] = pk()
    actor_user_id: Mapped[uuid.UUID] = fk("users.id")
    action: Mapped[str] = mapped_column(Text)
    entity_type: Mapped[str] = mapped_column(Text)
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
