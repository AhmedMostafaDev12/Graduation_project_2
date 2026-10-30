"""memory from photos: object sightings and the action log (spec D40, D41 §6; phase 8.5)

The other two layer-2 structures, filled by the photo review from the same vision call that
keeps or discards the photo (no second call). Every row links to its photo and the model that
saw it. `object_sightings.scene_segment_id` (spec §6) is added with the glasses' scene
segments. Same roles, grants and RLS as every table (docs/DATABASE.md §2).

Revision ID: 0007
Revises: 0006
Create Date: 2026-10-30 09:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0007"
down_revision: str | Sequence[str] | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = ["memory_actions", "object_sightings"]


def _timestamps() -> list[sa.Column]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    ]


def upgrade() -> None:
    op.create_table(
        "memory_actions",
        sa.Column(
            "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("verb", sa.Text(), nullable=False),
        sa.Column("entity_id", sa.UUID(), nullable=True),
        sa.Column("quantity", sa.REAL(), nullable=True),
        sa.Column("unit", sa.Text(), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "source",
            sa.Enum(
                "vision", "speech", "sound", "reminder", name="memory_action_source"
            ),
            nullable=False,
        ),
        sa.Column("evidence_event_id", sa.UUID(), nullable=True),
        sa.Column("media_asset_id", sa.UUID(), nullable=True),
        sa.Column("confidence", sa.REAL(), nullable=True),
        sa.Column("model_id", sa.Text(), nullable=False),
        *_timestamps(),
        sa.ForeignKeyConstraint(["entity_id"], ["memory_entities.id"]),
        sa.ForeignKeyConstraint(["evidence_event_id"], ["events.id"]),
        sa.ForeignKeyConstraint(["media_asset_id"], ["media_assets.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_memory_actions_entity_id"), "memory_actions", ["entity_id"]
    )
    op.create_index(
        op.f("ix_memory_actions_evidence_event_id"),
        "memory_actions",
        ["evidence_event_id"],
    )
    op.create_index(
        op.f("ix_memory_actions_media_asset_id"), "memory_actions", ["media_asset_id"]
    )
    op.create_index(
        op.f("ix_memory_actions_patient_id"), "memory_actions", ["patient_id"]
    )
    op.create_index(
        "ix_memory_actions_patient_occurred",
        "memory_actions",
        ["patient_id", "occurred_at"],
    )

    op.create_table(
        "object_sightings",
        sa.Column(
            "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("entity_id", sa.UUID(), nullable=False),
        sa.Column("state", sa.Text(), nullable=True),
        sa.Column("room", sa.Text(), nullable=True),
        sa.Column("place_id", sa.UUID(), nullable=True),
        sa.Column("seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("media_asset_id", sa.UUID(), nullable=True),
        sa.Column("confidence", sa.REAL(), nullable=True),
        sa.Column("model_id", sa.Text(), nullable=False),
        *_timestamps(),
        sa.ForeignKeyConstraint(["entity_id"], ["memory_entities.id"]),
        sa.ForeignKeyConstraint(["media_asset_id"], ["media_assets.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["place_id"], ["places.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_object_sightings_entity_id"), "object_sightings", ["entity_id"]
    )
    op.create_index(
        "ix_object_sightings_entity_seen", "object_sightings", ["entity_id", "seen_at"]
    )
    op.create_index(
        op.f("ix_object_sightings_media_asset_id"),
        "object_sightings",
        ["media_asset_id"],
    )
    op.create_index(
        op.f("ix_object_sightings_patient_id"), "object_sightings", ["patient_id"]
    )
    op.create_index(
        op.f("ix_object_sightings_place_id"), "object_sightings", ["place_id"]
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
    op.execute("DROP TYPE IF EXISTS memory_action_source")
