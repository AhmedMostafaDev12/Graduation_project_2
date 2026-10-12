"""Media assets (S3) and documents read from them."""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Enum,
    Integer,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    created_at,
    deleted_at,
    fk,
    pk,
    ts,
)


class MediaAsset(Base):
    __tablename__ = "media_assets"

    id: Mapped[uuid.UUID] = pk()  # client-generated
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    event_id: Mapped[uuid.UUID] = fk("events.id")
    asset_type: Mapped[str] = mapped_column(Enum("image", "video", name="asset_type"))
    storage_key: Mapped[str] = mapped_column(Text)  # private S3 key, never a public URL
    thumbnail_key: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # ~320 px JPEG
    trigger: Mapped[str] = mapped_column(
        Enum(
            "encounter_keyframe",
            "document_signal",
            "salient_frame",
            "user_requested",
            name="media_trigger",
        )
    )
    status: Mapped[str] = mapped_column(
        Enum("pending_review", "confirmed", "discarded", name="media_status"),
        server_default="pending_review",
    )
    ai_tags: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    contains_other_people: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    retention_policy: Mapped[str | None] = mapped_column(
        Enum("auto_expire", "keep_indefinitely", name="retention_policy"), nullable=True
    )
    expires_at: Mapped[datetime | None] = ts(nullable=True)
    pinned_by: Mapped[uuid.UUID | None] = fk("users.id", nullable=True)
    reviewed_at: Mapped[datetime | None] = ts(nullable=True)
    created_at: Mapped[datetime] = created_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class CapturedDocument(Base):
    __tablename__ = "captured_documents"

    id: Mapped[uuid.UUID] = pk()
    event_id: Mapped[uuid.UUID] = fk("events.id")
    media_asset_id: Mapped[uuid.UUID] = fk("media_assets.id")
    document_type: Mapped[str] = mapped_column(
        Enum("receipt", "bill", "medication_label", "other", name="document_type")
    )
    ocr_text: Mapped[str] = mapped_column(Text)
    extracted_fields: Mapped[dict] = mapped_column(
        JSONB, server_default=text("'{}'::jsonb")
    )
    created_at: Mapped[datetime] = created_at()
