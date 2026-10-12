"""retention.expire_media: hourly (Beat). The rules live in services/retention_service.py."""

from app.services import retention_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE


@celery_app.task(
    name="retention.expire_media",
    autoretry_for=RETRYABLE,
    retry_backoff=True,
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=600,
    time_limit=660,
)
def expire_media() -> dict:
    with locks.task_lock("retention.expire_media", ttl_seconds=900) as got:
        if not got:
            return {}
        with db.make_session() as session:
            return retention_service.expire_media(session)
