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
    photo_url: str | None = Field(
        default=None,
        description="Signed URL (10 min) of the first photo's ~320 px preview; list only",
    )
    created_at: datetime
    updated_at: datetime


class PersonPhoto(BaseModel):
    id: uuid.UUID = Field(description="Use it to remove this photo")
    url: str = Field(description="Short-lived signed URL (10 minutes)")
    thumbnail_url: str | None = Field(
        default=None, description="~320 px preview; null = use url"
    )


class PersonDetail(PersonOut):
    photos: list[PersonPhoto]
    enrolled_by_name: str | None = Field(
        default=None, description="The caregiver who enrolled them (C5)"
    )


class PersonUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    relationship: str | None = Field(default=None, min_length=1, max_length=40)


class SamplePhoto(BaseModel):
    id: uuid.UUID
    url: str = Field(description="Signed URL (10 min)")
    thumbnail_url: str | None = Field(
        default=None, description="~320 px; null = use url"
    )


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
    samples: list[SamplePhoto] = Field(
        default_factory=list, description="Up to 3 photos of this face (C7)"
    )
    sample_thumbnail_url: str | None = Field(
        default=None, description="~320 px preview of the sample; null = use sample_url"
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
