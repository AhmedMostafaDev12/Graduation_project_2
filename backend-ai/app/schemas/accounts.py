"""Schemas for auth, patients, caregivers and devices (spec §7.2, Phase 3)."""

import uuid
from datetime import date, datetime
from typing import Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

# ----- auth -----


class CaregiverCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    phone: str | None = Field(default=None, max_length=30)
    password: str = Field(min_length=8, max_length=128)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    role: str
    full_name: str
    email: str | None
    phone: str | None
    created_at: datetime


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds until the access token expires


class RefreshRequest(BaseModel):
    refresh_token: str


# ----- patients -----

HouseholdConsent = Literal["ambient_audio_household", "cloud_processing"]


class PatientCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    relationship: str = Field(
        min_length=1,
        max_length=60,
        description="Your relationship to the patient, e.g. son",
    )
    preferred_language: Literal["ar", "en"] = "ar"
    timezone: str = "Africa/Cairo"
    date_of_birth: date | None = None
    consents: list[HouseholdConsent] = Field(
        default_factory=list, description="Consents given on screen A4"
    )

    @field_validator("timezone")
    @classmethod
    def _known_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise ValueError("Unknown timezone, e.g. use Africa/Cairo") from exc
        return value


class PatientOut(BaseModel):
    id: uuid.UUID
    full_name: str
    preferred_language: str
    timezone: str
    date_of_birth: date | None
    memory_capture_enabled: bool
    created_at: datetime


class MyPatientOut(PatientOut):
    """A patient as seen by one linked caregiver (screen C1 switcher)."""

    relationship: str = Field(description="Your relationship to the patient")
    permission: str = Field(description="manager or viewer")
    is_primary: bool


class CaregiverLinkCreate(BaseModel):
    email: EmailStr
    relationship: str = Field(min_length=1, max_length=60)
    permission: Literal["viewer", "manager"] = "viewer"


class CaregiverLinkOut(BaseModel):
    id: uuid.UUID
    caregiver_id: uuid.UUID
    full_name: str
    email: str | None
    relationship: str
    permission: str
    is_primary: bool


# ----- devices -----


class DevicePairRequest(BaseModel):
    serial_number: str = Field(
        min_length=1, max_length=40, description="From the QR code"
    )
    patient_id: uuid.UUID


class DevicePairOut(BaseModel):
    device_id: uuid.UUID
    serial_number: str
    patient_id: uuid.UUID
    device_token: str = Field(
        description="Shown once. The patient's phone stores it securely"
    )
    paired_at: datetime


class HeartbeatIn(BaseModel):
    battery_level_pct: int | None = Field(default=None, ge=0, le=100)
    firmware_version: str | None = Field(default=None, max_length=40)


class DeviceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    serial_number: str
    firmware_version: str
    battery_level_pct: int | None
    last_seen_at: datetime | None
    paired_at: datetime
