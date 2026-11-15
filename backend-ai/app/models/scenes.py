"""Visual memory: what the glasses saw, as vectors (spec D34, D41, §6).

The glasses embed every 1 fps frame (MobileCLIP-S0, ml/edge) and keep the photo only when the
gate does. Two tiers:
1. `scene_segments` + `scene_vectors` (here): a run of similar frames, at most 30 s, with 3 real
   frame vectors (first, middle, most different). Searched first.
2. `frame_vector_files`: every frame's vector, one 8-bit file per hour in S3
   (app/ai/memory/frame_vectors.py), read only inside the minutes tier 1 found.
Both are deleted after 90 days (§8).
"""

import uuid
from datetime import datetime

from pgvector.sqlalchemy import HALFVEC
from sqlalchemy import Enum, Index, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import VISUAL_DIM, created_at, fk, pk, ts


class SceneSegment(Base):
    """A run of similar frames, at most 30 s, cut where the novelty rule fires (D41)."""

    __tablename__ = "scene_segments"
    __table_args__ = (
        Index("ix_scene_segments_patient_started", "patient_id", "started_at"),
    )

    id: Mapped[uuid.UUID] = pk()  # generated on the glasses
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID] = fk("devices.id")
    started_at: Mapped[datetime] = ts()
    ended_at: Mapped[datetime] = ts()
    frame_count: Mapped[int] = mapped_column(Integer)
    model_id: Mapped[str] = mapped_column(
        Text
    )  # the edge image embedder, "mobileclip-s0@1.0"
    kept_media_ids: Mapped[list[uuid.UUID]] = mapped_column(
        ARRAY(UUID(as_uuid=True)), default=list, server_default="{}"
    )  # the frames the gate kept inside this segment
    created_at: Mapped[datetime] = created_at()


class SceneVector(Base):
    """Tier 1: one of a segment's 3 real frame vectors, searched first (D41)."""

    __tablename__ = "scene_vectors"
    __table_args__ = (
        Index("ix_scene_vectors_patient_captured", "patient_id", "captured_at"),
    )

    id: Mapped[uuid.UUID] = pk()
    segment_id: Mapped[uuid.UUID] = fk("scene_segments.id", ondelete="CASCADE")
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    captured_at: Mapped[datetime] = ts()  # the frame's own second
    role: Mapped[str] = mapped_column(
        Enum("first", "middle", "most_different", name="scene_vector_role")
    )
    embedding: Mapped[list[float]] = mapped_column(HALFVEC(VISUAL_DIM))


class FrameVectorFile(Base):
    """Tier 2: every frame's vector for one hour, an 8-bit file in S3; never in Postgres."""

    __tablename__ = "frame_vector_files"
    __table_args__ = (UniqueConstraint("patient_id", "device_id", "hour_start"),)

    id: Mapped[uuid.UUID] = pk()  # generated on the glasses
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID] = fk("devices.id")
    hour_start: Mapped[datetime] = ts()
    frame_count: Mapped[int] = mapped_column(Integer)
    model_id: Mapped[str] = mapped_column(Text)
    dim: Mapped[int] = mapped_column(Integer)
    storage_key: Mapped[str] = mapped_column(Text)  # private S3 key
    created_at: Mapped[datetime] = created_at()
