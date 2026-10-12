"""thumbnail_key on media_assets and face_embeddings (spec D28)

A ~320 px JPEG preview next to each photo, so lists download ~30 KB instead of the full
photo. NULL when there is none yet (videos, older rows, or a failed render): the app then
shows the full photo.

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-12 22:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0004"
down_revision: str | Sequence[str] | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("media_assets", sa.Column("thumbnail_key", sa.Text(), nullable=True))
    op.add_column(
        "face_embeddings", sa.Column("thumbnail_key", sa.Text(), nullable=True)
    )


def downgrade() -> None:
    op.drop_column("face_embeddings", "thumbnail_key")
    op.drop_column("media_assets", "thumbnail_key")
