"""Photo review (queue `ai_io`, phase 8.3, spec §7.4).

review.media: queued by uploads/{id}/complete for a photo the glasses proposed, after its commit.
review.backfill: every 10 minutes (Beat), re-queues photos still pending (the queueing failed
or the task died). The work is in services/review_service.py; tasks only add the lock and the
retries.
"""

import logging
import uuid

from app.services import review_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE

logger = logging.getLogger(__name__)


@celery_app.task(
    name="review.media",
    autoretry_for=RETRYABLE,
    retry_backoff=True,  # rule 6: back off between retries (API rate limits)
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=150,  # S3 download + face models + one vision call
    time_limit=180,
)
def review_media(media_id: str) -> str | None:
    # rule 5: key = task name + entity id
    with locks.task_lock(f"review.media:{media_id}", ttl_seconds=240) as got:
        if not got:
            return None
        with db.make_session() as session:
            return review_service.review_media(session, uuid.UUID(media_id))


@celery_app.task(name="review.backfill", soft_time_limit=60, time_limit=90)
def backfill() -> int:
    with db.make_session() as session:
        ids = review_service.pending_media_ids(session)
    for media_id in ids:
        review_media.delay(str(media_id))
    if ids:
        logger.info("re-queued %d photos for review", len(ids))
    return len(ids)
