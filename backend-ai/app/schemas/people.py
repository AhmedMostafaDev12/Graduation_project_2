"""Schemas for enrolled people, photos, unknown faces (Phase 5.1, 5.8)."""

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class PersonOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    name: str
    relationship: str
    added_by: str
    status: str
    embedding_count: int = 0
    created_at: datetime
    updated_at: datetime


class PersonPhoto(BaseModel):
    key: str = Field(description="Stable id of the photo")
    url: str = Field(description="Short-lived signed URL (10 minutes)")


class PersonDetail(PersonOut):
    photos: list[PersonPhoto]


class PersonUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    relationship: str | None = Field(default=None, min_length=1, max_length=40)


class UnknownFaceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    sighting_count: int
    distinct_days: int
    first_seen_at: datetime
    last_seen_at: datetime
    status: str
    sample_url: str | None = Field(
        default=None, description="Signed URL of a sample frame"
    )


class PromoteRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    relationship: str = Field(min_length=1, max_length=40)
    consent_given: Literal[True] = Field(
        description="The caregiver confirms this person agreed to face recognition"
    )


class PromoteOut(BaseModel):
    cluster: UnknownFaceOut
    person: PersonOut
