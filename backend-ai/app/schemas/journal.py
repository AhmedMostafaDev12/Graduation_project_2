"""Schemas for the events batch and the day journal (Phase 5.4, 5.5)."""

import base64
import uuid
from datetime import date, datetime, timedelta
from typing import Any, Literal

from pydantic import AwareDatetime, BaseModel, Field, field_validator, model_validator

from app.models._columns import VISUAL_DIM
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


class SceneVectorIn(BaseModel):
    role: Literal["first", "middle", "most_different"]
    captured_at: AwareDatetime = Field(description="The frame's own second")
    embedding: str = Field(
        description=f"Base64 of {VISUAL_DIM} little-endian float16 values"
    )

    @field_validator("embedding")
    @classmethod
    def _is_a_vector(cls, value: str) -> str:
        try:
            raw = base64.b64decode(value, validate=True)
        except ValueError as exc:
            raise ValueError("embedding is not base64") from exc
        if len(raw) != VISUAL_DIM * 2:
            raise ValueError(f"embedding must hold {VISUAL_DIM} float16 values")
        return value


class SceneSegmentIn(BaseModel):
    """A run of similar frames, at most 30 s, with 3 real frame vectors (spec D34, D41)."""

    id: uuid.UUID = Field(description="Generated on the glasses")
    started_at: AwareDatetime
    ended_at: AwareDatetime
    frame_count: int = Field(ge=1, le=40)
    model_id: str = Field(
        min_length=1, max_length=100, description="e.g. mobileclip-s0@1.0"
    )
    kept_media_ids: list[uuid.UUID] = Field(default_factory=list, max_length=40)
    vectors: list[SceneVectorIn] = Field(min_length=1, max_length=3)

    @model_validator(mode="after")
    def _span(self):
        if not timedelta(0) <= self.ended_at - self.started_at <= timedelta(seconds=31):
            raise ValueError("a scene segment lasts at most 30 s")
        return self


class EventsBatch(BaseModel):
    encounters: list[EncounterIn] = Field(default_factory=list, max_length=500)
    events: list[EventIn] = Field(default_factory=list, max_length=500)
    scene_segments: list[SceneSegmentIn] = Field(default_factory=list, max_length=500)


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
