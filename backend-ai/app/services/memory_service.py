"""Consolidation from speech: transcripts → facts, intentions, entity index (spec §7.3 step 5, D40).

Called by the `memory.*` tasks (phase 7.5). For one `conversation_segment` event:

1. Check permission: the `cloud_processing` consent is given and not revoked (spec §9).
   Otherwise the event is marked `not_allowed` and nothing is sent to the LLM.
2. Ask the LLM for facts, intentions and entities (`ai/memory/extract.py`) and keep only what
   passes validation: verbatim quotes, typed values.
3. Ask the LLM whether the new transcript settles any of the patient's open intentions (done /
   not done), each with the quote that shows it.
4. Embed the names of new entities, then write everything in one commit together with
   `events.metadata.memory`, which marks the event as consolidated.

Open intentions nobody settled become `unknown` after their window (`expire_intentions`).
Idempotent: an event with `metadata.memory` is not processed again. Temporary LLM failures
raise before anything is written, so a retry starts clean. Never logs transcripts, quotes or
names (AI_LAYER.md rule 8).
"""

import logging
import uuid
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import func, or_, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.ai.clients.llm import LLMError
from app.ai.memory import extract
from app.ai.registry import get_ai
from app.models import (
    ConsentRecord,
    EnrolledPerson,
    Event,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
    PatientProfile,
    Place,
)

logger = logging.getLogger(__name__)

OPEN_PLANS_LIMIT = 20  # most recent open intentions sent with each new transcript
DUE_GRACE = timedelta(days=1)  # after due_at, how long the evidence may still arrive
NO_DUE_WINDOW = timedelta(
    days=7
)  # an intention without a due time stays open this long


def cloud_allowed(db: Session, patient_id: uuid.UUID) -> bool:
    return (
        db.scalar(
            select(ConsentRecord.id)
            .where(
                ConsentRecord.patient_id == patient_id,
                ConsentRecord.consent_type == "cloud_processing",
                ConsentRecord.revoked_at.is_(None),
            )
            .limit(1)
        )
        is not None
    )


def _mark(event: Event, status: str, model: str | None = None) -> None:
    # a new dict, so SQLAlchemy sees the JSONB change
    event.metadata_ = {
        **(event.metadata_ or {}),
        "memory": {"status": status, "model": model},
    }


def _said_at(event: Event, segment: extract.Segment) -> datetime:
    return event.occurred_at + timedelta(seconds=segment.start_s)


def _open_plans(db: Session, event: Event) -> list[MemoryIntention]:
    return list(
        db.scalars(
            select(MemoryIntention)
            .where(
                MemoryIntention.patient_id == event.patient_id,
                MemoryIntention.status == "open",
                MemoryIntention.deleted_at.is_(None),
                MemoryIntention.source_event_id != event.id,
                MemoryIntention.stated_at < event.occurred_at,
            )
            .order_by(MemoryIntention.stated_at.desc())
            .limit(OPEN_PLANS_LIMIT)
        )
    )


def _links(db: Session, patient_id: uuid.UUID, entities: list[extract.EntityRef]):
    """Entity → enrolled person / saved place, when the name matches exactly one."""
    people: dict[str, list[uuid.UUID]] = {}
    for person in db.scalars(
        select(EnrolledPerson).where(
            EnrolledPerson.patient_id == patient_id,
            EnrolledPerson.deleted_at.is_(None),
        )
    ):
        full = extract.entity_name(person.name)
        if full:
            # "Ahmed" in a conversation matches the enrolled "Ahmed Mostafa"
            for key in {full, full.split()[0]}:
                people.setdefault(key, []).append(person.id)
    places: dict[str, list[uuid.UUID]] = {}
    for place in db.scalars(
        select(Place).where(Place.patient_id == patient_id, Place.deleted_at.is_(None))
    ):
        name = extract.entity_name(place.name)
        if name:
            places.setdefault(name, []).append(place.id)

    links = {}
    for entity in entities:
        found = (people if entity.kind == "person" else places).get(entity.name, [])
        if entity.kind != "object" and len(set(found)) == 1:
            links[entity] = found[0]
    return links


def upsert_entities(
    db: Session,
    event: Event,
    entities: list[extract.EntityRef],
    vectors: dict[extract.EntityRef, list[float]],
) -> dict[extract.EntityRef, uuid.UUID]:
    """Insert new entities, count a mention on existing ones (safe if two events race)."""
    links = _links(db, event.patient_id, entities)
    ids = {}
    for entity in entities:
        link = links.get(entity)
        statement = insert(MemoryEntity).values(
            patient_id=event.patient_id,
            kind=entity.kind,
            name=entity.name,
            person_id=link if entity.kind == "person" else None,
            place_id=link if entity.kind == "place" else None,
            name_embedding=vectors.get(entity),
            first_seen_at=event.occurred_at,
            last_seen_at=event.occurred_at,
        )
        table = MemoryEntity.__table__
        statement = statement.on_conflict_do_update(
            index_elements=["patient_id", "kind", "name"],
            set_={
                "mention_count": table.c.mention_count + 1,
                "first_seen_at": func.least(table.c.first_seen_at, event.occurred_at),
                "last_seen_at": func.greatest(table.c.last_seen_at, event.occurred_at),
                "person_id": func.coalesce(
                    table.c.person_id, statement.excluded.person_id
                ),
                "place_id": func.coalesce(
                    table.c.place_id, statement.excluded.place_id
                ),
                "updated_at": func.now(),
            },
        ).returning(table.c.id)
        ids[entity] = db.scalar(statement)
    return ids


def new_entity_vectors(
    db: Session, patient_id: uuid.UUID, entities: list[extract.EntityRef]
) -> dict[extract.EntityRef, list[float]]:
    """Name embeddings for entities not in the index yet ("my glasses" ↔ "النضارة", D15)."""
    if not entities:
        return {}
    existing = {
        (kind, name)
        for kind, name in db.execute(
            select(MemoryEntity.kind, MemoryEntity.name).where(
                MemoryEntity.patient_id == patient_id,
                MemoryEntity.name.in_(sorted({e.name for e in entities})),
            )
        )
    }
    new = [e for e in entities if (e.kind, e.name) not in existing]
    if not new:
        return {}
    vectors = get_ai().text_embedder.embed([e.name for e in new])
    return dict(zip(new, vectors, strict=True))


def consolidate_event(db: Session, event_id: uuid.UUID) -> str:
    """Returns what happened: consolidated | done | not_allowed | failed | skipped | missing."""
    event = db.get(Event, event_id)
    if event is None or event.deleted_at is not None:
        return "missing"
    if event.event_type != "conversation_segment" or not event.transcript_text:
        return "skipped"
    if (event.metadata_ or {}).get("memory"):
        return "done"

    if not cloud_allowed(db, event.patient_id):
        _mark(event, "not_allowed")
        db.commit()
        return "not_allowed"

    profile = db.get(PatientProfile, event.patient_id)
    tz = ZoneInfo(profile.timezone if profile else "Africa/Cairo")
    now_local = event.occurred_at.astimezone(tz)
    segments = extract.segments_from(event.metadata_, event.transcript_text)
    llm = get_ai().llm
    model = f"{llm.model_id}/{extract.EXTRACT_PROMPT}"

    # 1) extraction; TransientError propagates before anything is written (Celery retries)
    try:
        raw = llm.complete(
            extract.extract_messages(segments, now_local), extract.EXTRACT_SCHEMA
        )
        found = extract.parse_extraction(raw, segments, tz)
    except (LLMError, extract.ExtractionError):
        _mark(event, "failed", model)
        db.commit()
        logger.warning("memory extraction failed permanently for event %s", event.id)
        return "failed"

    # 2) does this conversation settle an earlier plan?
    plans = _open_plans(db, event)
    settlements: list[extract.Settlement] = []
    if plans:
        try:
            raw = llm.complete(
                extract.settle_messages(
                    [
                        extract.OpenPlan(
                            p.description, p.quote, p.stated_at.astimezone(tz)
                        )
                        for p in plans
                    ],
                    segments,
                    now_local,
                ),
                extract.SETTLE_SCHEMA,
            )
            settlements = extract.parse_settlements(raw, segments, len(plans))
        except (LLMError, extract.ExtractionError):
            # the extraction is still worth keeping; the plans stay open
            logger.warning("intention check failed permanently for event %s", event.id)

    # 3) write everything in one commit
    entity_ids = upsert_entities(
        db,
        event,
        found.entities,
        new_entity_vectors(db, event.patient_id, found.entities),
    )
    present = (event.metadata_ or {}).get("present_person_ids") or []
    # with a single enrolled person present, "not the patient" can only be them
    other = uuid.UUID(present[0]) if len(present) == 1 else None

    for fact in found.facts:
        db.add(
            MemoryFact(
                patient_id=event.patient_id,
                event_id=event.id,
                segment_index=fact.segment.index,
                speaker_label=fact.segment.speaker,
                speaker_person_id=other if fact.speaker_is_patient is False else None,
                quote=fact.quote,
                language=event.language or "ar",
                about_entity_ids=[entity_ids[e] for e in fact.about],
                values=fact.values,
                said_at=_said_at(event, fact.segment),
                model_id=model,
            )
        )
    for intention in found.intentions:
        db.add(
            MemoryIntention(
                patient_id=event.patient_id,
                holder=intention.holder,
                holder_person_id=other if intention.holder == "other" else None,
                description=intention.description,
                quote=intention.quote,
                source_event_id=event.id,
                stated_at=_said_at(event, intention.segment),
                due_at=intention.due_at,
                due_until=intention.due_until,
                model_id=model,
            )
        )
    for settled in settlements:
        plan = plans[settled.plan]
        plan.status = settled.status
        plan.settled_by_event_ids = [*plan.settled_by_event_ids, event.id]
        plan.settled_at = _said_at(event, settled.segment)

    _mark(event, "done", model)
    db.commit()
    return "consolidated"


def pending_event_ids(db: Session, limit: int) -> list[uuid.UUID]:
    """Transcripts not consolidated yet (the queueing failed, or the task died)."""
    return list(
        db.scalars(
            select(Event.id)
            .where(
                Event.event_type == "conversation_segment",
                Event.transcript_text.is_not(None),
                Event.deleted_at.is_(None),
                or_(Event.metadata_.is_(None), ~Event.metadata_.has_key("memory")),
            )
            .order_by(Event.occurred_at)
            .limit(limit)
        )
    )


def expire_intentions(db: Session, now: datetime | None = None) -> int:
    """Open intentions past their window with no evidence either way become `unknown`."""
    now = now or datetime.now(UTC)
    window_end = func.coalesce(
        MemoryIntention.due_until,
        MemoryIntention.due_at + DUE_GRACE,
        MemoryIntention.stated_at + NO_DUE_WINDOW,
    )
    result = db.execute(
        update(MemoryIntention)
        .where(
            MemoryIntention.status == "open",
            MemoryIntention.deleted_at.is_(None),
            window_end < now,
        )
        .values(status="unknown", settled_at=now)
        .execution_options(synchronize_session=False)
    )
    db.commit()
    return result.rowcount
