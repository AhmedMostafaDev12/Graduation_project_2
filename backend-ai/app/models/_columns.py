"""Shared column helpers and vector sizes used by every model module."""

import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

FACE_DIM = 512  # MobileFaceNet w600k_mbf (spec D14)
TEXT_DIM = 1536  # text-embedding-3-small (spec D15)


def pk() -> Mapped[uuid.UUID]:
    """UUID primary key. The client may send its own; otherwise one is generated."""
    return mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )


def fk(target: str, nullable: bool = False, **kwargs) -> Mapped[uuid.UUID]:
    return mapped_column(
        UUID(as_uuid=True), ForeignKey(target, **kwargs), nullable=nullable, index=True
    )


def created_at() -> Mapped[datetime]:
    return mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


def updated_at() -> Mapped[datetime]:
    return mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        index=True,  # delta sync: "what changed since T?"
    )


def deleted_at() -> Mapped[datetime | None]:
    return mapped_column(DateTime(timezone=True), nullable=True)


def ts(nullable: bool = False) -> Mapped[datetime]:
    return mapped_column(DateTime(timezone=True), nullable=nullable)
