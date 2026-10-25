"""Ambient memory: transcribe one audio segment (queue `ai_io`, phase 7.2, spec §7.3).

transcribe.segment: queued after an audio upload is committed (wired in 7.4). The work is in
services/transcription_service.py; this task only adds the lock and the retries.
"""

import uuid

from app.services import transcription_service
from app.workers import db, locks
from app.workers.celery_app import celery_app
from app.workers.retry import RETRYABLE

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
                return transcription_service.transcribe_segment(
                    session, uuid.UUID(segment_id)
                )
        except RETRYABLE:
            if self.request.retries >= MAX_RETRIES:  # the last attempt also failed
                with db.make_session() as session:
                    transcription_service.mark_failed(session, uuid.UUID(segment_id))
            raise
