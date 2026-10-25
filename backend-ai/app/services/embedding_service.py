"""Journal events → one sentence + its embedding, for RAG (spec §7.3 step 4, D15, D22; phase 7.3).

For each event: load what the sentence needs (patient language and timezone, people, place,
reminder, game, document, media tags), render it with `ai/rag/render.py` (track R2), embed
the sentences in batches with the configured `TextEmbedder`, and store `rendered_text`,
`embedding` and which model made it (`metadata.embedding_model`, AI_LAYER.md §6.3).

Idempotent: only events without an embedding are processed. Never logs sentences or names.
"""

import logging
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai.rag.render import PersonRef, RenderInput, render_event
from app.ai.registry import get_ai
from app.models import (
    CapturedDocument,
    EnrolledPerson,
    Event,
    MediaAsset,
    MindGameSession,
    PatientProfile,
    Place,
    Reminder,
    ReminderLog,
)

logger = logging.getLogger(__name__)

BATCH = 100  # sentences per embedding call (the provider's limit)


def _uuid(value) -> uuid.UUID | None:
    try:
        return uuid.UUID(str(value))
    except (TypeError, ValueError):
        return None


def _person(db: Session, person_id) -> PersonRef | None:
    person = db.get(EnrolledPerson, person_id) if person_id else None
    return PersonRef(person.name, person.relationship) if person else None


def render_input(db: Session, event: Event, profile: PatientProfile) -> RenderInput:
    meta = event.metadata_ or {}
    fields: dict = {}

    present = []
    for pid in meta.get("present_person_ids") or []:
        ref = _person(db, _uuid(pid))
        if ref:
            present.append(ref)

    place_id = _uuid(meta.get("place_id"))
    place = db.get(Place, place_id) if place_id else None

    if event.reminder_log_id:
        log = db.get(ReminderLog, event.reminder_log_id)
        reminder = db.get(Reminder, log.reminder_id) if log else None
        if log and reminder:
            fields.update(
                reminder_title=reminder.title,
                reminder_type=reminder.type,
                reminder_status=log.status,
                reminder_confirmed_via=log.confirmed_via,
            )

    if event.mind_game_session_id:
        game = db.get(MindGameSession, event.mind_game_session_id)
        if game:
            fields.update(game_type=game.game_type, game_score=game.score)

    document = db.scalars(
        select(CapturedDocument).where(CapturedDocument.event_id == event.id).limit(1)
    ).first()
    if document:
        fields.update(
            document_type=document.document_type,
            document_fields=document.extracted_fields or {},
        )

    media = db.scalars(
        select(MediaAsset)
        .where(MediaAsset.event_id == event.id, MediaAsset.deleted_at.is_(None))
        .order_by(MediaAsset.created_at)
        .limit(1)
    ).first()
    if media:
        tags = (media.ai_tags or {}).get("tags") or []
        fields.update(
            media_type=media.asset_type,
            media_duration_seconds=media.duration_seconds,
            media_tags=tuple(str(t) for t in tags),
        )

    return RenderInput(
        event_type=event.event_type,
        occurred_at=event.occurred_at,
        ended_at=event.ended_at,
        transcript_text=event.transcript_text,
        event_language=event.language,
        patient_language=profile.preferred_language,
        patient_timezone=profile.timezone,
        person=_person(db, event.person_id),
        present_people=tuple(present),
        place_name=place.name if place else None,
        query_answer=meta.get("answer"),
        **fields,
    )


def pending_event_ids(db: Session, limit: int) -> list[uuid.UUID]:
    """Oldest events that still have no embedding."""
    return list(
        db.scalars(
            select(Event.id)
            .where(Event.embedding.is_(None), Event.deleted_at.is_(None))
            .order_by(Event.created_at)
            .limit(limit)
        )
    )


def embed_events(db: Session, event_ids: list[uuid.UUID]) -> int:
    """Render + embed the given events that have no embedding yet; returns how many were stored."""
    events = list(
        db.scalars(
            select(Event).where(
                Event.id.in_(event_ids),
                Event.embedding.is_(None),
                Event.deleted_at.is_(None),
            )
        )
    )
    profiles: dict[uuid.UUID, PatientProfile | None] = {}
    ready: list[tuple[Event, str]] = []
    for event in events:
        if event.patient_id not in profiles:
            profiles[event.patient_id] = db.get(PatientProfile, event.patient_id)
        profile = profiles[event.patient_id]
        if profile is None:
            continue
        try:
            ready.append((event, render_event(render_input(db, event, profile))))
        except ValueError:  # an event type the renderer doesn't know: a bug, not data
            logger.warning("cannot render event %s (%s)", event.id, event.event_type)

    embedder = get_ai().text_embedder
    stored = 0
    for start in range(0, len(ready), BATCH):
        chunk = ready[start : start + BATCH]
        vectors = embedder.embed([sentence for _, sentence in chunk])
        for (event, sentence), vector in zip(chunk, vectors, strict=True):
            event.rendered_text = sentence
            event.embedding = vector
            # a new dict, so SQLAlchemy sees the JSONB change
            event.metadata_ = {
                **(event.metadata_ or {}),
                "embedding_model": embedder.model_id,
            }
            stored += 1
        db.commit()  # per batch: a later failure keeps the work already done
    return stored
