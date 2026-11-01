"""Memory from photos: object sightings and the action log (spec D40, §7.4 item 7; phase 8.5).

Called by the photo review (services/review_service.py) inside the same commit, with the room,
objects and actions the one vision call returned: no second call. Objects (and the objects of
actions) also enter the entity index, the same one conversations feed (phase 7.5), so "keys"
from a photo and "المفاتيح" from speech meet there. Every row keeps its photo and the model
that saw it.

`forget_media` applies the retention rule (spec §8): deleting a photo deletes the structure
rows whose only evidence it was. Never logs what is in the photo (AI_LAYER.md rule 8).
"""

import re
import uuid
from datetime import datetime

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.ai.memory.extract import EntityRef, entity_name
from app.ai.review_contract import ReviewResult
from app.models import Event, MediaAsset, MemoryAction, ObjectSighting, Place
from app.services import memory_service

MAX_VERB = 60


def verb_name(verb: str) -> str | None:
    """'Take medication' → 'take_medication' (the action log's normalized verb)."""
    cleaned = re.sub(r"[^a-z0-9]+", "_", (verb or "").lower()).strip("_")
    return cleaned[:MAX_VERB] or None


def _place(db: Session, event: Event) -> uuid.UUID | None:
    """The saved place the phone attached to the event, if it's the patient's."""
    try:
        place_id = uuid.UUID(str((event.metadata_ or {}).get("place_id")))
    except ValueError:
        return None
    place = db.get(Place, place_id)
    if place is None or place.patient_id != event.patient_id or place.deleted_at:
        return None
    return place_id


def store(
    db: Session, media: MediaAsset, event: Event, result: ReviewResult, model_id: str
) -> dict:
    """Write the photo's sightings, actions and entities (the caller commits)."""
    objects = [(entity_name(o.name), o.state) for o in result.objects]
    objects = [(name, state) for name, state in objects if name]
    actions = [
        (verb_name(a.verb), entity_name(a.object) if a.object else None, a)
        for a in result.actions
    ]
    actions = [(verb, obj, a) for verb, obj, a in actions if verb]

    names = dict.fromkeys(
        [name for name, _ in objects] + [obj for _, obj, _ in actions if obj]
    )
    entities = [EntityRef("object", name) for name in names]
    # embeds only names new to the index; a temporary failure retries the whole review
    vectors = memory_service.new_entity_vectors(db, media.patient_id, entities)
    ids = memory_service.upsert_entities(db, event, entities, vectors)

    place_id = _place(db, event)
    room = (result.room or "").strip()[:60] or None
    for name, state in objects:
        db.add(
            ObjectSighting(
                patient_id=media.patient_id,
                entity_id=ids[EntityRef("object", name)],
                state=(state or "").strip()[:300] or None,  # may hold printed text
                room=room,
                place_id=place_id,
                seen_at=event.occurred_at,
                media_asset_id=media.id,
                model_id=model_id,
            )
        )
    for verb, obj, action in actions:
        db.add(
            MemoryAction(
                patient_id=media.patient_id,
                verb=verb,
                entity_id=ids[EntityRef("object", obj)] if obj else None,
                quantity=action.quantity,
                unit=(action.unit or "").strip()[:30] or None,
                occurred_at=event.occurred_at,
                source="vision",
                evidence_event_id=event.id,
                media_asset_id=media.id,
                model_id=model_id,
            )
        )
    return {"objects": len(objects), "actions": len(actions)}


def forget_media(db: Session, media_ids: list[uuid.UUID], now: datetime) -> None:
    """Spec §8: the photo is gone, so are the sightings and actions only it showed (the
    caller commits). Entities stay: other evidence may mention them."""
    if not media_ids:
        return
    for table in (ObjectSighting, MemoryAction):
        db.execute(
            update(table)
            .where(table.media_asset_id.in_(media_ids), table.deleted_at.is_(None))
            .values(deleted_at=now)
            .execution_options(synchronize_session=False)
        )
