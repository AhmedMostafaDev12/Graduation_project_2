"""alerts.evaluate: every 5 minutes (Beat). The rules live in services/alert_service.py."""

from app.services import alert_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE


@celery_app.task(
    name="alerts.evaluate",
    autoretry_for=RETRYABLE,  # rule 6: only temporary failures
    retry_backoff=True,
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=120,
    time_limit=150,
)
def evaluate() -> int:
    # rule 5: one evaluation at a time; a skipped run is fine, the next comes in 5 minutes
    with locks.task_lock("alerts.evaluate", ttl_seconds=240) as got:
        if not got:
            return 0
        with db.make_session() as session:
            return alert_service.evaluate(session)
