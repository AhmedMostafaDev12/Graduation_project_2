"""Answer a free-form question from the patient's memories (spec §7.2 /assist, D39; phase 9.1).

Runs the /assist agent (`assist_loop.run_assist`, track R3) with the configured LLM and the
hybrid retriever (`retriever.MemorySearch`, R4) over this patient's memories:

- the question is text for now (the phone or glasses transcribe it first);
- the answer is in the question's language, and `source_event_ids` are the events it used
  (the loop drops ids the model never saw);
- when the loop can't produce an answer (the LLM or the search failed, or the reply was
  unusable), the patient hears a kind "I'm not sure" instead of an error;
- the question and the memories go to a cloud model, so the `cloud_processing` consent is
  required (spec §9); without it nothing is sent.

Never logs the question, the answer or what was found (AI_LAYER.md rule 8): only counts.
"""

import asyncio
import logging
import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai.rag.assist_loop import Person, question_language, run_assist
from app.ai.rag.retriever import MemorySearch
from app.ai.registry import get_ai
from app.models import EnrolledPerson, PatientProfile
from app.services.memory_service import cloud_allowed

logger = logging.getLogger(__name__)

NOT_SURE = {
    "ar": "مفيش في ذاكرتي حاجة أكيدة عن ده دلوقتي.",
    "en": "I'm not sure. I can't find that in my memory right now.",
}
NO_CLOUD_CONSENT = {
    "ar": "مقدرش أدور في الذاكرة، لأن المعالجة على السحابة مقفولة.",
    "en": "I can't search my memory: cloud processing is turned off.",
}


def _people(db: Session, patient_id: uuid.UUID) -> list[Person]:
    return [
        Person(id=str(p.id), name=p.name, relation=p.relationship)
        for p in db.scalars(
            select(EnrolledPerson)
            .where(
                EnrolledPerson.patient_id == patient_id,
                EnrolledPerson.status == "active",
                EnrolledPerson.deleted_at.is_(None),
            )
            .order_by(EnrolledPerson.name)
        )
    ]


def answer(
    db: Session,
    patient_id: uuid.UUID,
    question: str,
    asked_at: datetime | None = None,
) -> dict:
    """asked_at: now, unless an evaluation replays a question at its own time."""
    language = "en" if question_language(question) == "English" else "ar"
    if not cloud_allowed(db, patient_id):
        return {
            "answer": NO_CLOUD_CONSENT[language],
            "language": language,
            "source_event_ids": [],
        }

    profile = db.get(PatientProfile, patient_id)
    tz = profile.timezone if profile else "Africa/Cairo"
    ai = get_ai()
    result = asyncio.run(
        run_assist(
            ai.assist_llm,
            MemorySearch(db, patient_id, tz, ai.text_embedder),
            question=question,
            asked_at=asked_at or datetime.now(UTC),
            tz=tz,
            people=_people(db, patient_id),
        )
    )
    # counts and timings only, never the question or what was found
    logger.info(
        "assist: %d searches, %.1fs, degraded=%s, over_budget=%s",
        len(result.trace),
        result.seconds,
        result.degraded,
        result.over_budget,
    )
    if not result.answer:
        return {
            "answer": NOT_SURE[language],
            "language": language,
            "source_event_ids": [],
        }
    return {
        "answer": result.answer,
        "language": language,
        "source_event_ids": result.used_event_ids,
    }
