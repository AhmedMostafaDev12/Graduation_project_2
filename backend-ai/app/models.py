"""Database tables: exactly REMORI_SPEC.md §6.

Conventions (spec §6): UUID primary keys (records made offline keep the client's UUID),
TIMESTAMPTZ in UTC, `updated_at` + `deleted_at` (soft delete) on tables the phone syncs.
"""

import uuid
from datetime import date, datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    REAL,
    Boolean,
    Date,
    DateTime,
    Double,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base

FACE_DIM = 512  # MobileFaceNet w600k_mbf (spec D14)
TEXT_DIM = 1536  # text-embedding-3-small (spec D15)


def pk() -> Mapped[uuid.UUID]:
    """UUID primary key. The client may send its own; otherwise one is generated."""
    return mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )


def fk(target: str, nullable: bool = False, **kwargs) -> Mapped[uuid.UUID]:
    return mapped_column(
        UUID(as_uuid=True), ForeignKey(target, **kwargs), nullable=nullable, index=True
    )


def created_at() -> Mapped[datetime]:
    return mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


def updated_at() -> Mapped[datetime]:
    return mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        index=True,  # delta sync: "what changed since T?"
    )


def deleted_at() -> Mapped[datetime | None]:
    return mapped_column(DateTime(timezone=True), nullable=True)


def ts(nullable: bool = False) -> Mapped[datetime]:
    return mapped_column(DateTime(timezone=True), nullable=nullable)


# ===== Accounts =====


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


# ===== People =====


class EnrolledPerson(Base):
    __tablename__ = "enrolled_people"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    name: Mapped[str] = mapped_column(Text)
    relationship: Mapped[str] = mapped_column(Text)
    added_by: Mapped[str] = mapped_column(
        Enum("caregiver_manual", "promoted_from_unknown", name="person_added_by")
    )
    # enrolled_people <-> consent_records reference each other; this side is added after both exist
    consent_record_id: Mapped[uuid.UUID | None] = fk(
        "consent_records.id",
        nullable=True,
        use_alter=True,
        name="fk_enrolled_people_consent",
    )
    status: Mapped[str] = mapped_column(
        Enum("active", "archived", name="person_status"), server_default="active"
    )
    created_at: Mapped[datetime] = created_at()
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class FaceEmbedding(Base):
    __tablename__ = "face_embeddings"
    __table_args__ = (
        Index(
            "ix_face_embeddings_embedding_hnsw",
            "embedding",
            postgresql_using="hnsw",
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
    )

    id: Mapped[uuid.UUID] = pk()
    person_id: Mapped[uuid.UUID] = fk("enrolled_people.id")
    embedding: Mapped[list[float]] = mapped_column(Vector(FACE_DIM))
    model_version: Mapped[str] = mapped_column(Text)
    source_media_id: Mapped[uuid.UUID | None] = fk("media_assets.id", nullable=True)
    created_at: Mapped[datetime] = created_at()


class UnknownFaceCluster(Base):
    __tablename__ = "unknown_face_clusters"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    centroid: Mapped[list[float]] = mapped_column(Vector(FACE_DIM))
    sighting_count: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    distinct_days: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    first_seen_at: Mapped[datetime] = ts()
    last_seen_at: Mapped[datetime] = ts()
    # Breaks the loop encounters -> clusters -> media_assets -> events -> encounters;
    # this key is added after all four tables exist
    sample_media_id: Mapped[uuid.UUID | None] = fk(
        "media_assets.id",
        nullable=True,
        use_alter=True,
        name="fk_clusters_sample_media",
    )
    status: Mapped[str] = mapped_column(
        Enum(
            "open", "awaiting_caregiver", "promoted", "dismissed", name="cluster_status"
        ),
        server_default="open",
    )
    promoted_person_id: Mapped[uuid.UUID | None] = fk(
        "enrolled_people.id", nullable=True
    )


class Encounter(Base):
    __tablename__ = "encounters"

    id: Mapped[uuid.UUID] = pk()  # generated on the glasses
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID] = fk("devices.id")
    person_id: Mapped[uuid.UUID | None] = fk("enrolled_people.id", nullable=True)
    cluster_id: Mapped[uuid.UUID | None] = fk("unknown_face_clusters.id", nullable=True)
    started_at: Mapped[datetime] = ts()
    ended_at: Mapped[datetime] = ts()
    best_confidence: Mapped[float] = mapped_column(REAL)
    announced: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))


# ===== Places =====


class Place(Base):
    __tablename__ = "places"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    name: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float] = mapped_column(Double)
    longitude: Mapped[float] = mapped_column(Double)
    radius_m: Mapped[int] = mapped_column(Integer, server_default=text("100"))
    created_by: Mapped[uuid.UUID] = fk("users.id")
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


# ===== Journal =====


class Event(Base):
    __tablename__ = "events"
    __table_args__ = (
        Index(
            "ix_events_embedding_hnsw",
            "embedding",
            postgresql_using="hnsw",
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
    )

    id: Mapped[uuid.UUID] = pk()  # client-generated, idempotent
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID | None] = fk("devices.id", nullable=True)
    source: Mapped[str] = mapped_column(
        Enum("glasses", "app", "server", name="event_source")
    )
    event_type: Mapped[str] = mapped_column(
        Enum(
            "encounter",
            "conversation_segment",
            "voice_query",
            "reminder",
            "mind_game_session",
            "manual_note",
            "user_requested_recording",
            "document_captured",
            "notable_moment_captured",
            "memory_paused",
            "memory_resumed",
            name="event_type",
        )
    )
    encounter_id: Mapped[uuid.UUID | None] = fk("encounters.id", nullable=True)
    person_id: Mapped[uuid.UUID | None] = fk("enrolled_people.id", nullable=True)
    reminder_log_id: Mapped[uuid.UUID | None] = fk("reminder_logs.id", nullable=True)
    mind_game_session_id: Mapped[uuid.UUID | None] = fk(
        "mind_game_sessions.id", nullable=True
    )
    occurred_at: Mapped[datetime] = ts()
    ended_at: Mapped[datetime | None] = ts(nullable=True)
    transcript_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[str | None] = mapped_column(
        Enum("ar", "en", "mixed", name="transcript_language"), nullable=True
    )
    rendered_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    embedding: Mapped[list[float] | None] = mapped_column(
        Vector(TEXT_DIM), nullable=True
    )
    # "metadata" is reserved by SQLAlchemy models, so the Python name is metadata_
    metadata_: Mapped[dict] = mapped_column(
        "metadata", JSONB, server_default=text("'{}'::jsonb")
    )
    created_at: Mapped[datetime] = created_at()
    synced_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class AudioSegment(Base):
    __tablename__ = "audio_segments"

    id: Mapped[uuid.UUID] = pk()  # generated on the glasses
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID] = fk("devices.id")
    started_at: Mapped[datetime] = ts()
    ended_at: Mapped[datetime] = ts()
    storage_key: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # NULL once deleted
    status: Mapped[str] = mapped_column(
        Enum(
            "uploaded",
            "transcribing",
            "transcribed",
            "failed",
            "deleted",
            name="audio_status",
        ),
        server_default="uploaded",
    )
    event_id: Mapped[uuid.UUID | None] = fk("events.id", nullable=True)
    attempts: Mapped[int] = mapped_column(Integer, server_default=text("0"))
    created_at: Mapped[datetime] = created_at()


class MediaAsset(Base):
    __tablename__ = "media_assets"

    id: Mapped[uuid.UUID] = pk()  # client-generated
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    event_id: Mapped[uuid.UUID] = fk("events.id")
    asset_type: Mapped[str] = mapped_column(Enum("image", "video", name="asset_type"))
    storage_key: Mapped[str] = mapped_column(Text)  # private S3 key, never a public URL
    trigger: Mapped[str] = mapped_column(
        Enum(
            "encounter_keyframe",
            "document_signal",
            "salient_frame",
            "user_requested",
            name="media_trigger",
        )
    )
    status: Mapped[str] = mapped_column(
        Enum("pending_review", "confirmed", "discarded", name="media_status"),
        server_default="pending_review",
    )
    ai_tags: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    contains_other_people: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    retention_policy: Mapped[str | None] = mapped_column(
        Enum("auto_expire", "keep_indefinitely", name="retention_policy"), nullable=True
    )
    expires_at: Mapped[datetime | None] = ts(nullable=True)
    pinned_by: Mapped[uuid.UUID | None] = fk("users.id", nullable=True)
    reviewed_at: Mapped[datetime | None] = ts(nullable=True)
    created_at: Mapped[datetime] = created_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class CapturedDocument(Base):
    __tablename__ = "captured_documents"

    id: Mapped[uuid.UUID] = pk()
    event_id: Mapped[uuid.UUID] = fk("events.id")
    media_asset_id: Mapped[uuid.UUID] = fk("media_assets.id")
    document_type: Mapped[str] = mapped_column(
        Enum("receipt", "bill", "medication_label", "other", name="document_type")
    )
    ocr_text: Mapped[str] = mapped_column(Text)
    extracted_fields: Mapped[dict] = mapped_column(
        JSONB, server_default=text("'{}'::jsonb")
    )
    created_at: Mapped[datetime] = created_at()


# ===== Reminders =====


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


# ===== Activity / Phase 2 =====


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
    read_at: Mapped[datetime | None] = ts(nullable=True)
    created_at: Mapped[datetime] = created_at()


# ===== Privacy =====


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
