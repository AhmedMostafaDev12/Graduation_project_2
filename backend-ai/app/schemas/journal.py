"""Schemas for the events batch and the day journal (Phase 5.4, 5.5)."""

import uuid
from datetime import date, datetime
from typing import Any, Literal

from pydantic import AwareDatetime, BaseModel, Field

from app.schemas.media import AiTags

# conversation_segment events are written by the transcription worker, never by clients
ClientEventType = Literal[
    "encounter",
    "voice_query",
    "reminder",
    "mind_game_session",
    "manual_note",
    "user_requested_recording",
    "document_captured",
    "notable_moment_captured",
    "memory_paused",
    "memory_resumed",
]


class EncounterIn(BaseModel):
    id: uuid.UUID = Field(description="Generated on the glasses")
    person_id: uuid.UUID | None = Field(default=None, description="null = unknown face")
    started_at: AwareDatetime
    ended_at: AwareDatetime
    best_confidence: float = Field(ge=0, le=1)
    announced: bool = False


class EventIn(BaseModel):
    id: uuid.UUID = Field(description="Generated on the glasses or phone")
    event_type: ClientEventType
    source: Literal["glasses", "app"] = "glasses"
    occurred_at: AwareDatetime
    ended_at: AwareDatetime | None = None
    encounter_id: uuid.UUID | None = None
    person_id: uuid.UUID | None = None
    reminder_log_id: uuid.UUID | None = None
    transcript_text: str | None = Field(default=None, max_length=5000)
    language: Literal["ar", "en", "mixed"] | None = None
    metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="Free-form. For an unknown face, put the glasses' unknown_embedding here",
    )


class EventsBatch(BaseModel):
    encounters: list[EncounterIn] = Field(default_factory=list, max_length=500)
    events: list[EventIn] = Field(default_factory=list, max_length=500)


class JournalPerson(BaseModel):
    id: uuid.UUID
    name: str
    relationship: str


class JournalDocument(BaseModel):
    """C12 "Document (type icon + key field)"; open C15 with id."""

    id: uuid.UUID
    document_type: str
    title: str | None
    headline: str | None


class JournalMedia(BaseModel):
    id: uuid.UUID
    asset_type: str
    trigger: str
    status: str
    duration_seconds: int | None
    expires_at: datetime | None
    ai_tags: AiTags | None = None
    url: str = Field(description="Signed URL (10 min). Cache images by id, not by URL")
    thumbnail_url: str | None = Field(
        default=None, description="~320 px preview for the timeline; null = use url"
    )


class JournalEntry(BaseModel):
    id: uuid.UUID
    event_type: str
    source: str
    occurred_at: datetime
    ended_at: datetime | None
    person: JournalPerson | None
    transcript_text: str | None
    language: str | None
    rendered_text: str | None
    metadata: dict[str, Any]
    media: list[JournalMedia]
    document: JournalDocument | None = None


class JournalOut(BaseModel):
    date: date
    timezone: str
    entries: list[JournalEntry]
