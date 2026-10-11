"""People: enrolled people, face embeddings, unknown faces, encounters."""

import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    REAL,
    Boolean,
    Enum,
    Index,
    Integer,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    FACE_DIM,
    created_at,
    deleted_at,
    fk,
    pk,
    ts,
    updated_at,
)


class EnrolledPerson(Base):
    __tablename__ = "enrolled_people"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    name: Mapped[str] = mapped_column(Text)
    relationship: Mapped[str] = mapped_column(Text)
    added_by: Mapped[str] = mapped_column(
        Enum("caregiver_manual", "promoted_from_unknown", name="person_added_by")
    )
    # enrolled_people <-> consent_records reference each other; this side is added after both exist
    consent_record_id: Mapped[uuid.UUID | None] = fk(
        "consent_records.id",
        nullable=True,
        use_alter=True,
        name="fk_enrolled_people_consent",
    )
    status: Mapped[str] = mapped_column(
        Enum("active", "archived", name="person_status"), server_default="active"
    )
    created_at: Mapped[datetime] = created_at()
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()


class FaceEmbedding(Base):
    __tablename__ = "face_embeddings"
    __table_args__ = (
        Index(
            "ix_face_embeddings_embedding_hnsw",
            "embedding",
            postgresql_using="hnsw",
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
    )

    id: Mapped[uuid.UUID] = pk()
    person_id: Mapped[uuid.UUID] = fk("enrolled_people.id")
    embedding: Mapped[list[float]] = mapped_column(Vector(FACE_DIM))
    model_version: Mapped[str] = mapped_column(Text)
    source_media_id: Mapped[uuid.UUID | None] = fk("media_assets.id", nullable=True)
    created_at: Mapped[datetime] = created_at()


class UnknownFaceCluster(Base):
    __tablename__ = "unknown_face_clusters"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    centroid: Mapped[list[float]] = mapped_column(Vector(FACE_DIM))
    sighting_count: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    distinct_days: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    first_seen_at: Mapped[datetime] = ts()
    last_seen_at: Mapped[datetime] = ts()
    # Breaks the loop encounters -> clusters -> media_assets -> events -> encounters;
    # this key is added after all four tables exist
    sample_media_id: Mapped[uuid.UUID | None] = fk(
        "media_assets.id",
        nullable=True,
        use_alter=True,
        name="fk_clusters_sample_media",
    )
    status: Mapped[str] = mapped_column(
        Enum(
            "open", "awaiting_caregiver", "promoted", "dismissed", name="cluster_status"
        ),
        server_default="open",
    )
    promoted_person_id: Mapped[uuid.UUID | None] = fk(
        "enrolled_people.id", nullable=True
    )


class Encounter(Base):
    __tablename__ = "encounters"

    id: Mapped[uuid.UUID] = pk()  # generated on the glasses
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    device_id: Mapped[uuid.UUID] = fk("devices.id")
    person_id: Mapped[uuid.UUID | None] = fk("enrolled_people.id", nullable=True)
    cluster_id: Mapped[uuid.UUID | None] = fk("unknown_face_clusters.id", nullable=True)
    started_at: Mapped[datetime] = ts()
    ended_at: Mapped[datetime] = ts()
    best_confidence: Mapped[float] = mapped_column(REAL)
    announced: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))
