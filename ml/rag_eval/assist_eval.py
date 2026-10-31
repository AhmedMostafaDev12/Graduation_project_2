"""End-to-end /assist check on the synthetic days (tracks R1 + R4, phase 9.1). Real AI calls.

Loads data/synthetic_days.json into a throwaway patient in a LOCAL database (renders every
event with the backend's renderer, embeds the sentences with the configured text embedder),
then asks every question of data/benchmark_v1.json at its own `asked_at` through the real
/assist path (app/ai/rag/answer.py: agent loop + hybrid retriever + LLM), and scores:

- evidence recall: share of the expected evidence events the answer cites (source_event_ids);
- abstention: for questions with no answer, whether it cited nothing;
- time per question.

    docker compose -f docker-compose.dev.yml up -d db       # local Postgres, never Supabase
    cd backend-ai
    DATABASE_URL=postgresql+psycopg://remori:remori@localhost:5434/remori_test \\
      .venv/Scripts/python ../ml/rag_eval/assist_eval.py [question ids...]

Needs GEMINI_API_KEY and VOYAGE_API_KEY in backend-ai/.env (a few cents per run). Synthetic,
fictional data only. Everything it creates is deleted at the end. Answers are printed for
reading next to the reference answers: recall alone doesn't say the wording is right.
"""

import json
import os
import sys
import time
import uuid
from datetime import UTC, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

HERE = Path(__file__).resolve().parent
BACKEND = HERE.parents[1] / "backend-ai"
sys.path[:0] = [str(BACKEND), str(HERE)]

import evaluate_smoke as smoke
from sqlalchemy import delete

from app.ai.rag import answer as answer_module
from app.ai.registry import build
from app.config import settings
from app.database import SessionLocal
from app.models import (
    ConsentRecord,
    EnrolledPerson,
    Event,
    PatientProfile,
    User,
)

NAMESPACE = uuid.UUID("0b8f6c1e-4d3a-4c2b-9a7e-5f1d2c3b4a59")  # eval ids → stable uuids


def seed(db, days: dict, ai) -> tuple[uuid.UUID, uuid.UUID, dict, dict]:
    """A throwaway patient with the synthetic people and events. Returns (patient id,
    caregiver id, eval event id → uuid, uuid → eval event id)."""
    tz = days["timezone"]
    caregiver = User(
        role="caregiver",
        full_name="eval caregiver",
        email=f"eval-{uuid.uuid4()}@example.invalid",
    )
    patient = User(role="patient", full_name=f"{days['patient']['name']} (eval)")
    db.add_all([caregiver, patient])
    db.flush()
    db.add(
        PatientProfile(
            user_id=patient.id,
            preferred_language=days["patient"]["language"],
            timezone=tz,
        )
    )
    db.add(
        ConsentRecord(
            patient_id=patient.id,
            consent_type="cloud_processing",
            given_by=caregiver.id,
            given_at=datetime.now(UTC),
        )
    )
    people = {}
    for p in days["people"]:
        person = EnrolledPerson(
            patient_id=patient.id,
            name=p["name"],
            relationship=p["relationship"],
            added_by="caregiver_manual",
            status="active",
        )
        db.add(person)
        db.flush()
        people[p["id"]] = person.id

    events, refs = smoke.load_events(days, ZoneInfo(tz))
    to_uuid, from_uuid, rows, sentences = {}, {}, [], []
    for eid, e in events.items():
        event_id = uuid.uuid5(NAMESPACE, f"{patient.id}/{eid}")
        to_uuid[eid], from_uuid[str(event_id)] = event_id, eid
        meta = dict(e.get("metadata", {}))
        if meta.get("present_person_ids"):
            meta["present_person_ids"] = [
                str(people[p]) for p in meta["present_person_ids"]
            ]
        sentence = smoke.render(e, days["patient"]["language"], refs, tz)
        rows.append(
            Event(
                id=event_id,
                patient_id=patient.id,
                source="glasses",
                event_type=e["event_type"],
                occurred_at=e["start"].astimezone(UTC),
                ended_at=e["end"].astimezone(UTC),
                person_id=people.get(e.get("person_id")),
                transcript_text=e.get("transcript_text"),
                language=e.get("event_language"),
                rendered_text=sentence,
                metadata_=meta,
            )
        )
        sentences.append(sentence)
    vectors = ai.text_embedder.embed(sentences)
    for row, vector in zip(rows, vectors, strict=True):
        row.embedding = vector
    db.add_all(rows)
    db.commit()
    return patient.id, caregiver.id, to_uuid, from_uuid


def cleanup(db, patient_id, caregiver_id) -> None:
    db.execute(delete(Event).where(Event.patient_id == patient_id))
    db.execute(delete(EnrolledPerson).where(EnrolledPerson.patient_id == patient_id))
    db.execute(delete(ConsentRecord).where(ConsentRecord.patient_id == patient_id))
    db.execute(delete(PatientProfile).where(PatientProfile.user_id == patient_id))
    db.execute(delete(User).where(User.id.in_([patient_id, caregiver_id])))
    db.commit()


def main() -> int:
    if (
        "localhost" not in settings.database_url
        and "127.0.0.1" not in settings.database_url
    ):
        sys.exit("Refusing to run: DATABASE_URL must point at a local database.")
    days = json.loads(
        (HERE / "data" / "synthetic_days.json").read_text(encoding="utf-8")
    )
    bench = json.loads(
        (HERE / "data" / "benchmark_v1.json").read_text(encoding="utf-8")
    )
    wanted = set(sys.argv[1:])
    questions = [q for q in bench["questions"] if not wanted or q["id"] in wanted]

    ai = build(
        "stub",
        {
            "llm": "gemini-flash",
            # ASSIST_LLM=gemini-flash compares the default thinking level
            "assist_llm": os.environ.get("ASSIST_LLM", "gemini-flash-fast"),
            "text_embedder": "voyage-4",
        },
    )
    answer_module.get_ai = lambda: ai  # the real models for this run only
    tz = ZoneInfo(days["timezone"])

    db = SessionLocal()
    patient_id, caregiver_id, _, from_uuid = seed(db, days, ai)
    totals = {"recall": [], "abstain": [], "seconds": []}
    try:
        for q in questions:
            text = q["question_ar"] if q["language"] == "ar" else q["question_en"]
            asked_at = datetime.fromisoformat(q["asked_at"]).replace(tzinfo=tz)
            started = time.perf_counter()
            out = answer_module.answer(db, patient_id, text, asked_at=asked_at)
            seconds = time.perf_counter() - started
            cited = [from_uuid.get(i, "?") for i in out["source_event_ids"]]
            expected = q.get("evidence_event_ids", [])
            totals["seconds"].append(seconds)
            if q["answerable"]:
                hit = (
                    len(set(cited) & set(expected)) / len(expected) if expected else 1.0
                )
                totals["recall"].append(hit)
                score = f"evidence {hit:.0%}"
            else:
                ok = not cited
                totals["abstain"].append(ok)
                score = f"abstained {'yes' if ok else 'NO'}"
            print(f"\n{q['id']} [{q['category']}] {seconds:.1f}s, {score}")
            print(f"  Q: {text}")
            print(f"  A: {out['answer']}")
            print(f"  reference: {q.get('reference_open_answer', '')}")
            print(f"  cited {cited} / expected {expected}")
    finally:
        cleanup(db, patient_id, caregiver_id)
        db.close()

    def mean(xs):
        return sum(xs) / len(xs) if xs else float("nan")

    print(
        f"\n{len(questions)} questions · evidence recall {mean(totals['recall']):.0%} "
        f"({len(totals['recall'])} answerable) · abstention {mean(totals['abstain']):.0%} "
        f"({len(totals['abstain'])} unanswerable) · {mean(totals['seconds']):.1f}s avg, "
        f"{max(totals['seconds'], default=0):.1f}s max"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
