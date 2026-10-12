"""Answer a free-form question from the patient's memories (spec §7.2 /assist).

STUB (Phase 5.9): fixed answers in the exact response shape, so the app and glasses can be
built against it. Phase 9.1 replaces this with Abdelrahman's retriever + answer prompt
(docs/DEVELOPMENT_PLAN.md, track R5): retrieved events only, diacritized Arabic for Piper,
and the ids of the events the answer used.
"""

import uuid

from sqlalchemy.orm import Session

STUB_ANSWERS = {
    "ar": "لِسَّه بَتْعَلِّم أَجَاوِب عَلَى الأَسْئِلَة دِي.",
    "en": "I'm still learning to answer questions like this.",
}


def answer(db: Session, patient_id: uuid.UUID, question: str, language: str) -> dict:
    return {
        "answer": STUB_ANSWERS[language],
        "language": language,
        "source_event_ids": [],
    }
