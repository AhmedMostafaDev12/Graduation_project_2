"""Journal events → sentence + embedding for RAG (queue `ai_io`, phase 7.3, spec §7.3 step 4).

embed.events: embeds the given events (queued after a transcript is written, from 7.4 on).
embed.backfill: every 5 minutes (Beat), embeds events that still have no embedding, whatever
their source: the phone's events:batch, transcripts, or items a failed task left behind.
The work is in services/embedding_service.py; tasks only add the lock and the retries.
"""

import uuid

from app.services import embedding_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE

BACKFILL_LIMIT = 500  # events per sweep; the next sweep continues


@celery_app.task(
    name="embed.events",
    autoretry_for=RETRYABLE,
    retry_backoff=True,  # rule 6: back off between retries (API rate limits)
    retry_jitter=True,
    max_retries=3,
    soft_time_limit=120,
    time_limit=150,
)
def embed_events(event_ids: list[str]) -> int:
    with db.make_session() as session:
        return embedding_service.embed_events(
            session, [uuid.UUID(i) for i in event_ids]
        )


@celery_app.task(name="embed.backfill", soft_time_limit=240, time_limit=270)
def backfill() -> int:
    # rule 5: one sweep at a time, so two sweeps don't embed the same events twice
    with locks.task_lock("embed.backfill", ttl_seconds=300) as got:
        if not got:
            return 0
        with db.make_session() as session:
            ids = embedding_service.pending_event_ids(session, BACKFILL_LIMIT)
            if not ids:
                return 0
            return embedding_service.embed_events(session, ids)
