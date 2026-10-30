"""Structured memory built from speech (spec D40, D41 §6; phase 7.5).

Layer 2 of memory: extracted by the consolidation job from conversation transcripts, every
row linked to the event it came from and the model that extracted it. Object sightings and the
action log from photos are filled by the photo review (phase 8.5).
"""

import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    REAL,
    Enum,
    Index,
    Integer,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
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


class MemoryEntity(Base):
    """Entity index: every person, object and place seen or mentioned (premise checks)."""

    __tablename__ = "memory_entities"
    __table_args__ = (UniqueConstraint("patient_id", "kind", "name"),)

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    kind: Mapped[str] = mapped_column(
        Enum("person", "object", "place", name="memory_entity_kind")
    )
    name: Mapped[str] = mapped_column(Text)  # normalized, in the patient's language
    aliases: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'::text[]")
    )
    person_id: Mapped[uuid.UUID | None] = fk("enrolled_people.id", nullable=True)
    place_id: Mapped[uuid.UUID | None] = fk("places.id", nullable=True)
    name_embedding: Mapped[list[float] | None] = mapped_column(
        Vector(TEXT_DIM), nullable=True
    )
    first_seen_at: Mapped[datetime] = ts()
    last_seen_at: Mapped[datetime] = ts()
    mention_count: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class MemoryFact(Base):
    """Who said what: an exact quote with typed values (numbers, dates, doses)."""

    __tablename__ = "memory_facts"
    __table_args__ = (Index("ix_memory_facts_patient_said", "patient_id", "said_at"),)

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    event_id: Mapped[uuid.UUID] = fk("events.id")  # the conversation_segment
    segment_index: Mapped[int | None] = mapped_column(Integer, nullable=True)
    speaker_label: Mapped[str | None] = mapped_column(Text, nullable=True)  # "A", "B"
    speaker_person_id: Mapped[uuid.UUID | None] = fk(
        "enrolled_people.id", nullable=True
    )
    quote: Mapped[str] = mapped_column(Text)  # verbatim, never paraphrased
    language: Mapped[str] = mapped_column(
        Enum("ar", "en", "mixed", name="transcript_language")
    )
    about_entity_ids: Mapped[list[uuid.UUID]] = mapped_column(
        ARRAY(UUID(as_uuid=True)), server_default=text("'{}'::uuid[]")
    )
    values: Mapped[list] = mapped_column(JSONB, server_default=text("'[]'::jsonb"))
    said_at: Mapped[datetime] = ts()
    model_id: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = created_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class MemoryIntention(Base):
    """A plan said aloud, and whether later evidence shows it happened."""

    __tablename__ = "memory_intentions"
    __table_args__ = (
        Index("ix_memory_intentions_patient_status", "patient_id", "status"),
    )

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    holder: Mapped[str] = mapped_column(
        Enum("patient", "other", name="intention_holder")
    )
    holder_person_id: Mapped[uuid.UUID | None] = fk("enrolled_people.id", nullable=True)
    description: Mapped[str] = mapped_column(Text)  # normalized: "call the doctor"
    quote: Mapped[str] = mapped_column(Text)  # the words that stated it, verbatim
    source_event_id: Mapped[uuid.UUID] = fk("events.id")
    stated_at: Mapped[datetime] = ts()
    due_at: Mapped[datetime | None] = ts(nullable=True)
    due_until: Mapped[datetime | None] = ts(nullable=True)
    status: Mapped[str] = mapped_column(
        Enum("open", "done", "not_done", "unknown", name="intention_status"),
        server_default="open",
    )
    settled_by_event_ids: Mapped[list[uuid.UUID]] = mapped_column(
        ARRAY(UUID(as_uuid=True)), server_default=text("'{}'::uuid[]")
    )
    settled_at: Mapped[datetime | None] = ts(nullable=True)
    model_id: Mapped[str] = mapped_column(Text)
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class ObjectSighting(Base):
    """Where an object was and in what state (D40), from a reviewed photo (phase 8.5).
    `scene_segment_id` (spec §6) arrives with the glasses' scene segments."""

    __tablename__ = "object_sightings"
    __table_args__ = (
        Index("ix_object_sightings_entity_seen", "entity_id", "seen_at"),
    )

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    entity_id: Mapped[uuid.UUID] = fk("memory_entities.id")
    state: Mapped[str | None] = mapped_column(Text, nullable=True)  # "on", "in the drawer"
    room: Mapped[str | None] = mapped_column(Text, nullable=True)  # from the image
    place_id: Mapped[uuid.UUID | None] = fk("places.id", nullable=True)
    seen_at: Mapped[datetime] = ts()
    media_asset_id: Mapped[uuid.UUID | None] = fk("media_assets.id", nullable=True)
    confidence: Mapped[float | None] = mapped_column(REAL, nullable=True)
    model_id: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = created_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class MemoryAction(Base):
    """One row per action instance, never merged (D40): "took 2 pills", "turned off"."""

    __tablename__ = "memory_actions"
    __table_args__ = (
        Index("ix_memory_actions_patient_occurred", "patient_id", "occurred_at"),
    )

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    verb: Mapped[str] = mapped_column(Text)  # normalized: "take_medication", "turn_off"
    entity_id: Mapped[uuid.UUID | None] = fk("memory_entities.id", nullable=True)
    quantity: Mapped[float | None] = mapped_column(REAL, nullable=True)
    unit: Mapped[str | None] = mapped_column(Text, nullable=True)
    occurred_at: Mapped[datetime] = ts()
    source: Mapped[str] = mapped_column(
        Enum("vision", "speech", "sound", "reminder", name="memory_action_source")
    )
    evidence_event_id: Mapped[uuid.UUID | None] = fk("events.id", nullable=True)
    media_asset_id: Mapped[uuid.UUID | None] = fk("media_assets.id", nullable=True)
    confidence: Mapped[float | None] = mapped_column(REAL, nullable=True)
    model_id: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = created_at()
    deleted_at: Mapped[datetime | None] = deleted_at()
