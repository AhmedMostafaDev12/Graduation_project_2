"""Schemas for alerts, push tokens, mind games, daily summaries, assist (Phase 5.8, 5.9)."""

import uuid
from datetime import date, datetime
from typing import Any, Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field


class MindGameIn(BaseModel):
    id: uuid.UUID = Field(
        description="Generated on the phone, so a resend isn't counted twice"
    )
    game_type: str = Field(min_length=1, max_length=40, examples=["face_match"])
    score: int = Field(ge=0, le=100000)
    duration_seconds: int = Field(ge=0, le=4 * 3600)
    completed_at: AwareDatetime


class MindGameOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    game_type: str
    score: int
    duration_seconds: int
    completed_at: datetime


class DailySummaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    patient_id: uuid.UUID
    summary_date: date
    summary_text: str
    patterns: dict[str, Any]
    generated_at: datetime


class AlertOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    alert_type: str
    message: str
    entity_type: str | None = Field(
        description="What to open on tap: reminder_log, unknown_face_cluster, device, daily_summary"
    )
    entity_id: uuid.UUID | None
    read_at: datetime | None
    created_at: datetime


class PushTokenIn(BaseModel):
    fcm_token: str = Field(min_length=1, max_length=4096)


class AssistRequest(BaseModel):
    question: str = Field(min_length=1, max_length=1000)
    language: Literal["ar", "en"] | None = Field(
        default=None, description="Defaults to the patient's preferred language"
    )


class AssistOut(BaseModel):
    answer: str
    language: Literal["ar", "en"]
    source_event_ids: list[uuid.UUID]
