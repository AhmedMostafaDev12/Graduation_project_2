"""Ambient memory: transcribe one audio segment (queue `ai_io`, phases 7.2 + 7.4, spec §7.3).

transcribe.segment: queued by uploads/{id}/complete for audio, after its commit (7.4); once
the transcript is written it queues embed.events (7.3) and memory.consolidate (7.5).
transcribe.backfill: every 10 minutes (Beat), re-queues segments whose queueing failed (Redis
down at upload time) or whose task died mid-way, until retention removes them at 7 days.
The work is in services/transcription_service.py; tasks only add the lock and the retries.
"""

import logging
import uuid

from kombu.exceptions import OperationalError as KombuOperationalError
from redis.exceptions import RedisError

from app.services import transcription_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE
from app.workers.tasks.embedding import embed_events
from app.workers.tasks.memory import consolidate

logger = logging.getLogger(__name__)

# spec §7.3: up to 3 retries, then `failed` (retention deletes it at 7 days)
MAX_RETRIES = 3


@celery_app.task(
    bind=True,
    name="transcribe.segment",
    autoretry_for=RETRYABLE,
    retry_backoff=True,  # rule 6: back off between retries (API rate limits)
    retry_jitter=True,
    max_retries=MAX_RETRIES,
    soft_time_limit=180,  # download + ffmpeg + one STT call; a segment is seconds long
    time_limit=210,
)
def transcribe_segment(self, segment_id: str) -> str | None:
    # rule 5: key = task name + entity id
    with locks.task_lock(f"transcribe.segment:{segment_id}", ttl_seconds=240) as got:
        if not got:
            return None
        try:
            with db.make_session() as session:
                result = transcription_service.transcribe_segment(
                    session, uuid.UUID(segment_id)
                )
        except RETRYABLE:
            if self.request.retries >= MAX_RETRIES:  # the last attempt also failed
                with db.make_session() as session:
                    transcription_service.mark_failed(session, uuid.UUID(segment_id))
            raise
        if result == "transcribed":
            _enqueue_follow_ups(uuid.UUID(segment_id))
        return result


@celery_app.task(name="transcribe.backfill", soft_time_limit=60, time_limit=90)
def backfill() -> int:
    with db.make_session() as session:
        ids = transcription_service.stuck_segment_ids(session, max_attempts=MAX_RETRIES)
    for segment_id in ids:
        transcribe_segment.delay(str(segment_id))
    if ids:
        logger.info("re-queued %d audio segments", len(ids))
    return len(ids)


def _enqueue_follow_ups(segment_id: uuid.UUID) -> None:
    """Embed the new transcript (phase 7.3) and consolidate it into facts and intentions
    (phase 7.5). Never fails the transcription: if Redis is down, the embed.backfill and
    memory.backfill sweeps pick the event up within 10 minutes."""
    event_id = str(transcription_service.event_id_for(segment_id))
    for task, args in ((embed_events, [[event_id]]), (consolidate, [event_id])):
        try:
            task.apply_async(args)
        except (KombuOperationalError, RedisError):  # broker unavailable
            logger.warning("could not queue %s for segment %s", task.name, segment_id)
