"""Previews for uploaded photos and videos (queue `cpu`).

media.make_thumbnail: queued by uploads/{id}/complete, after its commit.
media.backfill_thumbnails: every 10 minutes (Beat), re-queues items from the last day that
still have no preview (e.g. Redis was down at upload time, or a task gave up).
"""

import logging
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.models import MediaAsset
from app.services import thumbnail_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE

logger = logging.getLogger(__name__)

BACKFILL_WINDOW = timedelta(hours=24)
BACKFILL_MIN_AGE = timedelta(minutes=2)  # leave fresh uploads to their own task


@celery_app.task(
    name="media.make_thumbnail",
    autoretry_for=RETRYABLE,
    retry_backoff=True,
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=120,
    time_limit=150,
)
def make_thumbnail(media_id: str) -> str | None:
    # rule 5: key = task name + entity id
    with locks.task_lock(f"media.make_thumbnail:{media_id}", ttl_seconds=180) as got:
        if not got:
            return None
        with db.make_session() as session:
            return thumbnail_service.make_for_media(session, uuid.UUID(media_id))


@celery_app.task(name="media.backfill_thumbnails", soft_time_limit=60, time_limit=90)
def backfill_thumbnails() -> int:
    now = datetime.now(UTC)
    with db.make_session() as session:
        ids = session.scalars(
            select(MediaAsset.id)
            .where(
                MediaAsset.thumbnail_key.is_(None),
                MediaAsset.deleted_at.is_(None),
                MediaAsset.created_at > now - BACKFILL_WINDOW,
                MediaAsset.created_at < now - BACKFILL_MIN_AGE,
            )
            .limit(100)
        ).all()
    for media_id in ids:
        make_thumbnail.delay(str(media_id))
    if ids:
        logger.info("re-queued %d previews", len(ids))
    return len(ids)
