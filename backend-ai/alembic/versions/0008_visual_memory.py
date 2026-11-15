"""visual memory: scene segments, their vectors, hourly frame-vector files (spec D34, D41 §6)

Two tiers of what the glasses saw. Tier 1: scene segments (a run of similar frames, at most
30 s) with 3 real frame vectors each, MobileCLIP-S0, 512-d half precision, searched first.
Tier 2: every frame's vector in one 8-bit file per hour in S3; the row only points at it.
Both are deleted after 90 days (§8). Same roles, grants and RLS as every table
(docs/DATABASE.md §2).

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-16 09:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa
from pgvector.sqlalchemy import HALFVEC
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0008"
down_revision: str | Sequence[str] | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = ["scene_segments", "scene_vectors", "frame_vector_files"]


def _id() -> sa.Column:
    return sa.Column(
        "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
    )


def _created_at() -> sa.Column:
    return sa.Column(
        "created_at",
        sa.DateTime(timezone=True),
        server_default=sa.text("now()"),
        nullable=False,
    )


def upgrade() -> None:
    op.create_table(
        "scene_segments",
        _id(),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("device_id", sa.UUID(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("frame_count", sa.Integer(), nullable=False),
        sa.Column("model_id", sa.Text(), nullable=False),
        sa.Column(
            "kept_media_ids",
            postgresql.ARRAY(sa.UUID()),
            server_default="{}",
            nullable=False,
        ),
        _created_at(),
        sa.ForeignKeyConstraint(["device_id"], ["devices.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_scene_segments_patient_started",
        "scene_segments",
        ["patient_id", "started_at"],
    )
    op.create_index(
        op.f("ix_scene_segments_patient_id"), "scene_segments", ["patient_id"]
    )
    op.create_index(
        op.f("ix_scene_segments_device_id"), "scene_segments", ["device_id"]
    )

    op.create_table(
        "scene_vectors",
        _id(),
        sa.Column("segment_id", sa.UUID(), nullable=False),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "role",
            sa.Enum("first", "middle", "most_different", name="scene_vector_role"),
            nullable=False,
        ),
        sa.Column("embedding", HALFVEC(512), nullable=False),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.ForeignKeyConstraint(
            ["segment_id"], ["scene_segments.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_scene_vectors_patient_captured",
        "scene_vectors",
        ["patient_id", "captured_at"],
    )
    op.create_index(
        op.f("ix_scene_vectors_patient_id"), "scene_vectors", ["patient_id"]
    )
    op.create_index(
        op.f("ix_scene_vectors_segment_id"), "scene_vectors", ["segment_id"]
    )

    op.create_table(
        "frame_vector_files",
        _id(),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("device_id", sa.UUID(), nullable=False),
        sa.Column("hour_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("frame_count", sa.Integer(), nullable=False),
        sa.Column("model_id", sa.Text(), nullable=False),
        sa.Column("dim", sa.Integer(), nullable=False),
        sa.Column("storage_key", sa.Text(), nullable=False),
        _created_at(),
        sa.ForeignKeyConstraint(["device_id"], ["devices.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("patient_id", "device_id", "hour_start"),
    )
    op.create_index(
        op.f("ix_frame_vector_files_patient_id"), "frame_vector_files", ["patient_id"]
    )
    op.create_index(
        op.f("ix_frame_vector_files_device_id"), "frame_vector_files", ["device_id"]
    )

    # the same roles, grants and RLS as every table (0001, docs/DATABASE.md §2)
    for table in TABLES:
        op.execute(f"GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO remori_app")
        op.execute(f"GRANT SELECT ON {table} TO remori_readonly")
        op.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY")
        op.execute(
            f"CREATE POLICY remori_app_all ON {table} FOR ALL TO remori_app "
            "USING (true) WITH CHECK (true)"
        )
        op.execute(
            f"CREATE POLICY remori_readonly_select ON {table} FOR SELECT TO remori_readonly "
            "USING (true)"
        )


def downgrade() -> None:
    for table in reversed(TABLES):
        op.drop_table(table)  # drops its indexes and policies too
    op.execute("DROP TYPE IF EXISTS scene_vector_role")
