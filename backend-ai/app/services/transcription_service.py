"""Ambient memory: turn one uploaded audio segment into a journal transcript (spec §7.3, D4, D36).

Called by the `transcribe.segment` task (phase 7.2). Steps for one segment:

1. Check permission: the caregiver's master switch (`memory_capture_enabled`) is on, and
   household audio + cloud processing consents are given and not revoked (spec §9).
   Otherwise the audio is deleted untranscribed: nothing reaches the speech-to-text provider.
2. Download the audio, boost quiet speech (ffmpeg dynaudnorm + loudnorm, 16 kHz mono;
   measured in MODELS_CHOICE.md §7) and transcribe it with the configured provider.
3. Write a `conversation_segment` event with the transcript, speaker-labelled segments and
   the enrolled people whose encounters overlap the segment (`present_person_ids`).
4. Delete the audio from S3 (spec D4): only the transcript is kept.

Idempotent: the event id is derived from the segment id, and a segment already transcribed
or deleted is not processed again. Never logs transcripts or names (AI_LAYER.md rule 8).
"""

import logging
import subprocess
import uuid
from datetime import UTC, datetime, timedelta

import imageio_ffmpeg
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.ai.clients.stt import SpeechToTextError
from app.ai.registry import get_ai
from app.integrations import s3
from app.models import AudioSegment, ConsentRecord, Encounter, Event, PatientProfile

logger = logging.getLogger(__name__)

MAX_AUDIO_BYTES = 25 * 1024 * 1024  # a speech segment is seconds long; this is generous
FFMPEG_TIMEOUT = 60  # seconds
REQUIRED_CONSENTS = ("ambient_audio_household", "cloud_processing")
# a fixed namespace, so the same segment always gives the same event id (idempotency)
EVENT_NAMESPACE = uuid.UUID("6f1d3c0e-7a52-4c47-9a7e-2b8f6a1d0c11")

# dynaudnorm lifts quiet stretches (a softer or farther speaker) toward the main voice;
# loudnorm then evens out the overall level. 16 kHz mono is plenty for speech.
NORMALIZE_FILTER = "dynaudnorm=f=150:g=15:p=0.9,loudnorm=I=-16:TP=-1.5:LRA=11"


def normalize(audio: bytes) -> bytes | None:
    """Loudness-normalized 16 kHz mono WAV, or None if ffmpeg can't read the audio."""
    try:
        result = subprocess.run(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                "pipe:0",
                "-af",
                NORMALIZE_FILTER,
                "-ac",
                "1",
                "-ar",
                "16000",
                "-f",
                "wav",
                "pipe:1",
            ],
            input=audio,
            capture_output=True,
            check=True,
            timeout=FFMPEG_TIMEOUT,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None
    return result.stdout or None


def event_id_for(segment_id: uuid.UUID) -> uuid.UUID:
    return uuid.uuid5(EVENT_NAMESPACE, str(segment_id))


def capture_allowed(db: Session, patient_id: uuid.UUID) -> bool:
    profile = db.get(PatientProfile, patient_id)
    if profile is None or not profile.memory_capture_enabled:
        return False
    given = set(
        db.scalars(
            select(ConsentRecord.consent_type).where(
                ConsentRecord.patient_id == patient_id,
                ConsentRecord.consent_type.in_(REQUIRED_CONSENTS),
                ConsentRecord.revoked_at.is_(None),
            )
        )
    )
    return given == set(REQUIRED_CONSENTS)


def present_person_ids(db: Session, segment: AudioSegment) -> list[str]:
    """Enrolled people whose encounters overlap the segment ("who was I talking to")."""
    ids = db.scalars(
        select(Encounter.person_id)
        .where(
            Encounter.patient_id == segment.patient_id,
            Encounter.person_id.is_not(None),
            Encounter.started_at <= segment.ended_at,
            Encounter.ended_at >= segment.started_at,
        )
        .distinct()
    )
    return sorted(str(i) for i in ids)


def _delete_audio(db: Session, segment: AudioSegment) -> None:
    if segment.storage_key:
        s3.delete(segment.storage_key)
    segment.storage_key = None
    segment.status = "deleted"
    db.commit()


def transcribe_segment(db: Session, segment_id: uuid.UUID) -> str:
    """Returns what happened: transcribed | no_speech | not_allowed | failed | done | missing."""
    segment = db.get(AudioSegment, segment_id)
    if segment is None:
        return "missing"
    if segment.status == "deleted":
        return "done"
    if segment.status == "transcribed":  # a crash between the commit and the delete
        _delete_audio(db, segment)
        return "done"

    if not capture_allowed(db, segment.patient_id):
        _delete_audio(db, segment)
        return "not_allowed"

    segment.status = "transcribing"
    segment.attempts += 1
    db.commit()

    audio = s3.get_bytes(segment.storage_key, MAX_AUDIO_BYTES)
    if audio is None:  # too large to be a speech segment
        segment.status = "failed"
        db.commit()
        return "failed"

    normalized = normalize(audio)
    content_type = "audio/wav" if normalized else "audio/ogg"
    profile = db.get(PatientProfile, segment.patient_id)
    try:
        transcript = get_ai().stt.transcribe(
            normalized or audio, content_type, language_hint=profile.preferred_language
        )
    except SpeechToTextError:
        # permanent (bad audio, bad request): not retried; retention deletes it after 7 days
        segment.status = "failed"
        db.commit()
        logger.warning("transcription failed permanently for segment %s", segment.id)
        return "failed"

    if not transcript.text:
        _delete_audio(db, segment)
        return "no_speech"

    event_id = event_id_for(segment.id)
    if db.get(Event, event_id) is None:
        db.add(
            Event(
                id=event_id,
                patient_id=segment.patient_id,
                device_id=segment.device_id,
                source="glasses",
                event_type="conversation_segment",
                occurred_at=segment.started_at,
                ended_at=segment.ended_at,
                transcript_text=transcript.text,
                language=transcript.language,
                metadata_={
                    "present_person_ids": present_person_ids(db, segment),
                    "segments": [
                        {
                            "start_s": s.start_s,
                            "end_s": s.end_s,
                            "speaker": s.speaker,
                            "text": s.text,
                        }
                        for s in transcript.segments
                    ],
                    "stt_model": transcript.model_id,
                    "audio_segment_id": str(segment.id),
                },
            )
        )
        # write the event before linking it: no ORM relationship orders these two rows
        db.flush()
    segment.event_id = event_id
    segment.status = "transcribed"
    db.commit()

    _delete_audio(db, segment)
    return "transcribed"


def stuck_segment_ids(
    db: Session, max_attempts: int, limit: int = 100
) -> list[uuid.UUID]:
    """Segments to queue again: still `uploaded` after 2 minutes (queueing failed), or
    `transcribing` for over 30 minutes (the task died), within the 7 days before retention
    deletes untranscribed audio (spec §8)."""
    now = datetime.now(UTC)
    return list(
        db.scalars(
            select(AudioSegment.id)
            .where(
                AudioSegment.storage_key.is_not(None),
                AudioSegment.created_at > now - timedelta(days=7),
                or_(
                    and_(
                        AudioSegment.status == "uploaded",
                        AudioSegment.created_at < now - timedelta(minutes=2),
                    ),
                    and_(
                        AudioSegment.status == "transcribing",
                        AudioSegment.created_at < now - timedelta(minutes=30),
                        AudioSegment.attempts <= max_attempts,
                    ),
                ),
            )
            .order_by(AudioSegment.created_at)
            .limit(limit)
        )
    )


def mark_failed(db: Session, segment_id: uuid.UUID) -> None:
    """After the last retry: the audio stays until retention deletes it (7 days, spec §8)."""
    segment = db.get(AudioSegment, segment_id)
    if segment is not None and segment.status == "transcribing":
        segment.status = "failed"
        db.commit()
