"""Delta pull for the patient's phone (spec §7.2 /sync, D7)."""

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.places import PlaceOut
from app.schemas.reminders import ReminderOut


class SyncPerson(BaseModel):
    id: uuid.UUID
    name: str
    relationship: str
    embeddings: list[str] = Field(
        description="512-d face embeddings, base64 little-endian float16"
    )
    model_versions: list[str]
    updated_at: datetime


class SyncSettings(BaseModel):
    full_name: str
    preferred_language: str
    timezone: str
    memory_capture_enabled: bool


class PeopleDelta(BaseModel):
    upserts: list[SyncPerson]
    deletes: list[uuid.UUID]


class RemindersDelta(BaseModel):
    upserts: list[ReminderOut]
    deletes: list[uuid.UUID]


class PlacesDelta(BaseModel):
    upserts: list[PlaceOut]
    deletes: list[uuid.UUID]


class SyncOut(BaseModel):
    server_time: datetime = Field(description="Send this back as ?since= next time")
    full: bool = Field(
        description="True when no since was given: upserts hold everything"
    )
    settings: SyncSettings
    people: PeopleDelta
    reminders: RemindersDelta
    places: PlacesDelta
