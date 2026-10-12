"""Schemas for uploads, media, documents (Phase 5.6, 5.7)."""

import uuid
from datetime import datetime
from typing import Any, Literal

from pydantic import AwareDatetime, BaseModel, Field, model_validator

# content type -> file extension; anything else is refused
CONTENT_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "video/mp4": "mp4",
    "audio/ogg": "ogg",
    "audio/opus": "opus",
}
MEDIA_TYPES = {"image/jpeg", "image/png", "video/mp4"}
AUDIO_TYPES = {"audio/ogg", "audio/opus"}

UploadKind = Literal["media", "audio"]
ContentType = Literal["image/jpeg", "image/png", "video/mp4", "audio/ogg", "audio/opus"]


def _check_kind(kind: str, content_type: str) -> None:
    allowed = MEDIA_TYPES if kind == "media" else AUDIO_TYPES
    if content_type not in allowed:
        raise ValueError(f"{content_type} is not allowed for {kind}")


class UploadRequest(BaseModel):
    id: uuid.UUID = Field(
        description="The media asset or audio segment id, from the glasses"
    )
    kind: UploadKind
    content_type: ContentType

    @model_validator(mode="after")
    def _kind_matches(self):
        _check_kind(self.kind, self.content_type)
        return self


class UploadOut(BaseModel):
    id: uuid.UUID
    key: str
    upload_url: str = Field(description="PUT the file here with the same Content-Type")
    method: Literal["PUT"] = "PUT"
    headers: dict[str, str]
    expires_in: int = Field(description="Seconds")


class UploadComplete(BaseModel):
    patient_id: uuid.UUID
    kind: UploadKind
    content_type: ContentType
    # media
    event_id: uuid.UUID | None = Field(
        default=None, description="Media: the event it belongs to"
    )
    trigger: (
        Literal[
            "encounter_keyframe", "document_signal", "salient_frame", "user_requested"
        ]
        | None
    ) = None
    duration_seconds: int | None = Field(default=None, ge=0, le=3600)
    # audio
    started_at: AwareDatetime | None = None
    ended_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _fields_for_kind(self):
        _check_kind(self.kind, self.content_type)
        if self.kind == "media" and (self.event_id is None or self.trigger is None):
            raise ValueError("media needs event_id and trigger")
        if self.kind == "audio" and (self.started_at is None or self.ended_at is None):
            raise ValueError("audio needs started_at and ended_at")
        return self


class UploadDone(BaseModel):
    id: uuid.UUID
    kind: UploadKind
    status: str = Field(
        description="media: pending_review | confirmed; audio: uploaded"
    )


class MediaOut(BaseModel):
    id: uuid.UUID
    patient_id: uuid.UUID
    event_id: uuid.UUID
    asset_type: str
    trigger: str
    status: str
    ai_tags: dict[str, Any] | None
    contains_other_people: bool | None
    duration_seconds: int | None
    retention_policy: str | None
    expires_at: datetime | None
    pinned_by: uuid.UUID | None
    created_at: datetime


class MediaView(MediaOut):
    url: str = Field(description="Short-lived signed URL")
    url_expires_in: int = Field(description="Seconds")


class DocumentOut(BaseModel):
    id: uuid.UUID
    event_id: uuid.UUID
    media_asset_id: uuid.UUID
    document_type: str
    ocr_text: str
    extracted_fields: dict[str, Any]
    created_at: datetime
    url: str | None = Field(
        default=None, description="Signed URL (10 min) of the photo"
    )
    thumbnail_url: str | None = Field(
        default=None, description="~320 px preview; null = use url"
    )
