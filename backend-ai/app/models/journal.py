"""The journal: events and transient audio segments."""

import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    DateTime,
    Enum,
    Index,
    Integer,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    TEXT_DIM,
    created_at,
    deleted_at,
    fk,
    pk,
    ts,
    updated_at,
)


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
