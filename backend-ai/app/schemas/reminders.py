"""Schemas for reminders and their occurrences (spec D6, screens C8/C9/P2/P3)."""

import uuid
from datetime import datetime
from typing import Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from dateutil.rrule import rrulestr
from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, field_validator

ReminderType = Literal["medication", "appointment", "task"]
LogStatus = Literal["pending", "completed", "snoozed", "missed"]


def _check_timezone(value: str | None) -> str | None:
    if value is None:
        return value
    try:
        ZoneInfo(value)
    except (ZoneInfoNotFoundError, ValueError) as exc:
        raise ValueError("Unknown timezone, e.g. use Africa/Cairo") from exc
    return value


def _check_rrule(value: str | None) -> str | None:
    """RFC 5545 rule the phone expands into occurrences (spec D6), e.g. FREQ=DAILY;BYHOUR=9."""
    if value is None:
        return value
    if "DTSTART" in value.upper():
        raise ValueError("Send the start time in dtstart, not inside the rule")
    try:
        rrulestr(value)
    except (ValueError, TypeError) as exc:
        raise ValueError(
            "Invalid recurrence rule, e.g. FREQ=DAILY;BYHOUR=9;BYMINUTE=0"
        ) from exc
    return value


class _ReminderChecks(BaseModel):
    @field_validator("timezone", check_fields=False)
    @classmethod
    def _timezone(cls, value):
        return _check_timezone(value)

    @field_validator("rrule", check_fields=False)
    @classmethod
    def _rrule(cls, value):
        return _check_rrule(value)


class ReminderCreate(_ReminderChecks):
    title: str = Field(min_length=1, max_length=120)
    spoken_text: str | None = Field(
        default=None,
        max_length=200,
        description="What the glasses say. Defaults to title",
    )
    type: ReminderType
    rrule: str = Field(
        min_length=1, max_length=300, examples=["FREQ=DAILY;BYHOUR=9;BYMINUTE=0"]
    )
    dtstart: AwareDatetime
    timezone: str = "Africa/Cairo"
    active: bool = True


class ReminderUpdate(_ReminderChecks):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    spoken_text: str | None = Field(default=None, max_length=200)
    type: ReminderType | None = None
    rrule: str | None = Field(default=None, min_length=1, max_length=300)
    dtstart: AwareDatetime | None = None
    timezone: str | None = None
    active: bool | None = None


class ReminderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    patient_id: uuid.UUID
    title: str
    spoken_text: str | None
    type: str
    rrule: str
    dtstart: datetime
    timezone: str
    active: bool
    created_by: uuid.UUID
    updated_at: datetime
    deleted_at: datetime | None


class ReminderLogIn(BaseModel):
    id: uuid.UUID = Field(description="Generated on the phone")
    reminder_id: uuid.UUID
    scheduled_at: AwareDatetime
    status: LogStatus
    snoozed_until: AwareDatetime | None = None
    completed_at: AwareDatetime | None = None
    confirmed_via: Literal["voice", "app", "caregiver"] | None = None
    at: AwareDatetime | None = Field(
        default=None,
        description="When this state was set on the device (merge rule, spec §7.1)",
    )


class ReminderLogBatch(BaseModel):
    logs: list[ReminderLogIn] = Field(max_length=500)


class ReminderLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    reminder_id: uuid.UUID
    scheduled_at: datetime
    status: str
    snoozed_until: datetime | None
    completed_at: datetime | None
    confirmed_via: str | None
    updated_at: datetime
    title: str | None = Field(default=None, description="The reminder's title")
    type: str | None = None
