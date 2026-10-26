"""text vectors 1536 -> 1024: embeddings move to Voyage voyage-4 (spec D15)

Vectors from different models can't be compared, so the old ones are cleared, not converted.
`embed.backfill` re-embeds every event without an embedding within minutes (phase 7.3);
entity names get their vector again the next time a conversation mentions them. The HNSW
index on events is rebuilt for the new size (it can't index vectors above 2,000 dimensions,
which is why 1024 and not 2048).

Revision ID: 0006
Revises: 0005
Create Date: 2026-10-26 03:30:00

"""

from collections.abc import Sequence

from alembic import op

revision: str = "0006"
down_revision: str | Sequence[str] | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# (table, column) holding text vectors (spec §6)
COLUMNS = [("events", "embedding"), ("memory_entities", "name_embedding")]


def _resize(dim: int) -> None:
    op.execute("DROP INDEX IF EXISTS ix_events_embedding_hnsw")
    for table, column in COLUMNS:
        op.execute(
            f"ALTER TABLE {table} ALTER COLUMN {column} TYPE vector({dim}) "
            f"USING NULL::vector({dim})"
        )
    op.execute(
        "CREATE INDEX ix_events_embedding_hnsw ON events "
        "USING hnsw (embedding vector_cosine_ops)"
    )


def upgrade() -> None:
    _resize(1024)


def downgrade() -> None:
    _resize(1536)
