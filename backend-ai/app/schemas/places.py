"""Schemas for saved places (spec D9, screens C10/C11)."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PlaceCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    radius_m: int = Field(default=100, ge=20, le=2000)


class PlaceUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    radius_m: int | None = Field(default=None, ge=20, le=2000)


class PlaceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    name: str
    latitude: float
    longitude: float
    radius_m: int
    created_by: uuid.UUID
    updated_at: datetime
    deleted_at: datetime | None
