"""Consolidation from speech (queue `ai_io`, phase 7.5, spec §7.3 step 5, D40).

memory.consolidate: queued after a transcript is written (transcribe.segment).
memory.backfill: every 10 minutes (Beat), consolidates transcripts whose queueing failed (Redis
down) or whose task died mid-way.
memory.expire_intentions: hourly (Beat), open intentions past their window become `unknown`.
The work is in services/memory_service.py; tasks only add the lock and the retries.
"""

import logging
import uuid

from app.services import memory_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE

logger = logging.getLogger(__name__)

BACKFILL_LIMIT = 50  # events per sweep (two LLM calls each); the next sweep continues


@celery_app.task(
    name="memory.consolidate",
    autoretry_for=RETRYABLE,
    retry_backoff=True,  # rule 6: back off between retries (API rate limits)
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=180,  # two LLM calls + one embedding call
    time_limit=210,
)
def consolidate(event_id: str) -> str | None:
    # rule 5: key = task name + entity id
    with locks.task_lock(f"memory.consolidate:{event_id}", ttl_seconds=240) as got:
        if not got:
            return None
        with db.make_session() as session:
            return memory_service.consolidate_event(session, uuid.UUID(event_id))


@celery_app.task(name="memory.backfill", soft_time_limit=60, time_limit=90)
def backfill() -> int:
    with db.make_session() as session:
        ids = memory_service.pending_event_ids(session, BACKFILL_LIMIT)
    for event_id in ids:
        consolidate.delay(str(event_id))
    if ids:
        logger.info("queued %d transcripts for consolidation", len(ids))
    return len(ids)


@celery_app.task(name="memory.expire_intentions", soft_time_limit=60, time_limit=90)
def expire_intentions() -> int:
    with db.make_session() as session:
        return memory_service.expire_intentions(session)
