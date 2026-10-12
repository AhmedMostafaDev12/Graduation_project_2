"""face_embeddings.storage_key: the enrollment photo each embedding came from

Enrollment photos are uploaded by caregivers, not captured by the glasses, so they have
no event and can't be media_assets rows. Keeping the photo's S3 key on its embedding lets
the API list photos from the database and remove one photo together with its embedding.
NULL for embeddings that have no photo (e.g. promoted from an unknown-face cluster).

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-12 18:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0002"
down_revision: str | Sequence[str] | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("face_embeddings", sa.Column("storage_key", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("face_embeddings", "storage_key")
