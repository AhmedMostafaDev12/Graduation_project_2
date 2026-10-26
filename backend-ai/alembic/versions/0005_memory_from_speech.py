"""memory from speech: entity index, facts, intentions (spec D40, D41 §6; phase 7.5)

Layer 2 of memory, built from conversation transcripts by the consolidation job. Every row
links to the event it came from and the model that extracted it. Object sightings and the
action log (from photos) come with phase 8.5. Same roles, grants and RLS as every table
(docs/DATABASE.md §2).

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-25 08:49:48

"""

from collections.abc import Sequence

import pgvector.sqlalchemy
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0005"
down_revision: str | Sequence[str] | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = ["memory_entities", "memory_facts", "memory_intentions"]
NEW_ENUMS = ["memory_entity_kind", "intention_holder", "intention_status"]


def upgrade() -> None:
    op.create_table(
        "memory_entities",
        sa.Column(
            "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column(
            "kind",
            sa.Enum("person", "object", "place", name="memory_entity_kind"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column(
            "aliases",
            postgresql.ARRAY(sa.Text()),
            server_default=sa.text("'{}'::text[]"),
            nullable=False,
        ),
        sa.Column("person_id", sa.UUID(), nullable=True),
        sa.Column("place_id", sa.UUID(), nullable=True),
        sa.Column(
            "name_embedding", pgvector.sqlalchemy.Vector(dim=1536), nullable=True
        ),
        sa.Column("first_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "mention_count", sa.Integer(), server_default=sa.text("1"), nullable=False
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["person_id"], ["enrolled_people.id"]),
        sa.ForeignKeyConstraint(["place_id"], ["places.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("patient_id", "kind", "name"),
    )
    op.create_index(
        op.f("ix_memory_entities_patient_id"), "memory_entities", ["patient_id"]
    )
    op.create_index(
        op.f("ix_memory_entities_person_id"), "memory_entities", ["person_id"]
    )
    op.create_index(
        op.f("ix_memory_entities_place_id"), "memory_entities", ["place_id"]
    )
    op.create_index(
        op.f("ix_memory_entities_updated_at"), "memory_entities", ["updated_at"]
    )

    op.create_table(
        "memory_facts",
        sa.Column(
            "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("event_id", sa.UUID(), nullable=False),
        sa.Column("segment_index", sa.Integer(), nullable=True),
        sa.Column("speaker_label", sa.Text(), nullable=True),
        sa.Column("speaker_person_id", sa.UUID(), nullable=True),
        sa.Column("quote", sa.Text(), nullable=False),
        sa.Column(
            "language",
            # the type already exists (events.language): reuse it, don't create it
            postgresql.ENUM(
                "ar", "en", "mixed", name="transcript_language", create_type=False
            ),
            nullable=False,
        ),
        sa.Column(
            "about_entity_ids",
            postgresql.ARRAY(sa.UUID()),
            server_default=sa.text("'{}'::uuid[]"),
            nullable=False,
        ),
        sa.Column(
            "values",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[]'::jsonb"),
            nullable=False,
        ),
        sa.Column("said_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("model_id", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["event_id"], ["events.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["speaker_person_id"], ["enrolled_people.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_memory_facts_event_id"), "memory_facts", ["event_id"])
    op.create_index(op.f("ix_memory_facts_patient_id"), "memory_facts", ["patient_id"])
    op.create_index(
        "ix_memory_facts_patient_said", "memory_facts", ["patient_id", "said_at"]
    )
    op.create_index(
        op.f("ix_memory_facts_speaker_person_id"), "memory_facts", ["speaker_person_id"]
    )

    op.create_table(
        "memory_intentions",
        sa.Column(
            "id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False
        ),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column(
            "holder",
            sa.Enum("patient", "other", name="intention_holder"),
            nullable=False,
        ),
        sa.Column("holder_person_id", sa.UUID(), nullable=True),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("quote", sa.Text(), nullable=False),
        sa.Column("source_event_id", sa.UUID(), nullable=False),
        sa.Column("stated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("due_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "status",
            sa.Enum("open", "done", "not_done", "unknown", name="intention_status"),
            server_default="open",
            nullable=False,
        ),
        sa.Column(
            "settled_by_event_ids",
            postgresql.ARRAY(sa.UUID()),
            server_default=sa.text("'{}'::uuid[]"),
            nullable=False,
        ),
        sa.Column("settled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("model_id", sa.Text(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["holder_person_id"], ["enrolled_people.id"]),
        sa.ForeignKeyConstraint(["patient_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["source_event_id"], ["events.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_memory_intentions_holder_person_id"),
        "memory_intentions",
        ["holder_person_id"],
    )
    op.create_index(
        op.f("ix_memory_intentions_patient_id"), "memory_intentions", ["patient_id"]
    )
    op.create_index(
        "ix_memory_intentions_patient_status",
        "memory_intentions",
        ["patient_id", "status"],
    )
    op.create_index(
        op.f("ix_memory_intentions_source_event_id"),
        "memory_intentions",
        ["source_event_id"],
    )
    op.create_index(
        op.f("ix_memory_intentions_updated_at"), "memory_intentions", ["updated_at"]
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
    for enum_type in NEW_ENUMS:
        op.execute(f"DROP TYPE IF EXISTS {enum_type}")
