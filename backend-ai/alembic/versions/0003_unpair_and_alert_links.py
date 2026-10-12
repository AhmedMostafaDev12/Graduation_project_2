"""devices.unpaired_at, caregiver_alerts.entity_type / entity_id (spec D28)

- Unpairing keeps the device row (events, encounters and audio point at it) and marks it
  unpaired; its token stops working. The same glasses can then be paired again.
- An alert names the thing it is about, so tapping it opens that screen (C2), e.g.
  entity_type 'reminder_log', 'unknown_face_cluster', 'device', 'daily_summary'.

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-12 20:00:00

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0003"
down_revision: str | Sequence[str] | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "devices", sa.Column("unpaired_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "caregiver_alerts", sa.Column("entity_type", sa.Text(), nullable=True)
    )
    op.add_column(
        "caregiver_alerts",
        sa.Column("entity_id", postgresql.UUID(as_uuid=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("caregiver_alerts", "entity_id")
    op.drop_column("caregiver_alerts", "entity_type")
    op.drop_column("devices", "unpaired_at")
