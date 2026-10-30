"""Smoke check of the RAG evaluation set (track R1, first slice). No network, no database.

Loads data/synthetic_days.json + data/benchmark_v1.json, renders every event in Arabic and
English with the backend's real renderer (app/ai/rag/render.py), validates both files and
prints the day overview and the questions with their evidence sentences.

    cd backend-ai
    .venv/Scripts/python ../ml/rag_eval/evaluate_smoke.py

Exits 1 if any check fails.

Times are local Cairo wall-clock strings ("YYYY-MM-DDTHH:MM", as in extraction_eval.py),
turned into aware datetimes with zoneinfo; nothing in the data carries a UTC offset.

expected_plan (what the query planner should produce, scored later):
- window_start / window_end: the time filter (local; window_start null = no lower bound).
  window_end never goes past asked_at: memory can't contain the future.
- person_ids: the people filter ([] = no filter). An event passes when it involves one of
  them (encounter person_id or conversation present_person_ids).
  Rule: person_ids lists only people who were PRESENT (they match present_person_ids or the
  encounter's person_id). A person who is only mentioned ("did Dr. Hany call me?") goes in
  the search text, never in person_ids: the filter would hide where they were talked about.
- event_types: the type filter (null = no filter).
A plan is correct when every evidence event passes all of its filters. Narrower is better
(fewer events to rank), but losing any evidence event is a failure.
"""

import json
import sys
from dataclasses import fields
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

BACKEND = Path(__file__).resolve().parents[2] / "backend-ai"
sys.path.insert(0, str(BACKEND))
from app.ai.rag.render import PersonRef, RenderInput, render_event
from app.models.journal import Event

DATA = Path(__file__).resolve().parent / "data"
DAYS_FILE = DATA / "synthetic_days.json"
BENCHMARK_FILE = DATA / "benchmark_v1.json"

CATEGORIES = {
    "object_location",
    "intent_recall",
    "conversational",
    "timeline",
    "in_context_retrieval",
    "visual_recall",
}
EVENT_TYPES = set(Event.__table__.c.event_type.type.enums)

# DRAFT (R3 not decided): the window "الصبح" (this morning) maps to, local time.
MORNING = ("05:00", "12:00")

# Event keys that are not RenderInput fields (resolved or ignored by this script).
EXTRA_EVENT_KEYS = {"id", "local_datetime", "local_end", "person_id", "metadata"}
RENDER_KEYS = {
    f.name
    for f in fields(RenderInput)
    if f.name not in {"occurred_at", "ended_at", "patient_language", "patient_timezone"}
}
QUESTION_KEYS = {
    "id",
    "session",
    "split",
    "category",
    "question_ar",
    "question_en",
    "language",
    "asked_at",
    "answerable",
    "false_premise",
    "multi_moment",
    "evidence",
    "evidence_event_ids",
    "expected_plan",
    "involves_person",
    "people",
    "reference_open_answer",
    "safety_weight",
    "author",
    "llm_drafted",
    "verified_by",
}

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def local(text: str | None, tz: ZoneInfo) -> datetime | None:
    return datetime.fromisoformat(text).replace(tzinfo=tz) if text else None


def hm(dt: datetime) -> str:
    return dt.strftime("%H:%M")


# ----- events -----


def load_events(days: dict, tz: ZoneInfo) -> tuple[dict, dict]:
    """(events by id, people by id); each event gets 'start', 'end', 'person_ids', 'day'."""
    people = {p["id"]: PersonRef(p["name"], p["relationship"]) for p in days["people"]}
    events: dict[str, dict] = {}
    for day in days["days"]:
        previous = None
        for e in day["events"]:
            eid = e["id"]
            if eid in events:
                fail(f"duplicate event id {eid}")
            unknown = set(e) - RENDER_KEYS - EXTRA_EVENT_KEYS
            if unknown:
                fail(f"{eid}: unknown fields {sorted(unknown)}")
            if e["event_type"] not in EVENT_TYPES:
                fail(f"{eid}: unknown event_type {e['event_type']!r}")
            start, end = local(e["local_datetime"], tz), local(e.get("local_end"), tz)
            if start.date().isoformat() != day["date"]:
                fail(f"{eid}: not on its day {day['date']}")
            if end is not None and end <= start:
                fail(f"{eid}: local_end is not after local_datetime")
            if previous is not None and start < previous:
                fail(f"{eid}: events are not in time order")
            previous = start
            ids = [e["person_id"]] if e.get("person_id") else []
            ids += e.get("metadata", {}).get("present_person_ids", [])
            for pid in ids:
                if pid not in people:
                    fail(f"{eid}: unknown person {pid}")
            events[eid] = {
                **e,
                "start": start,
                "end": end or start,
                "person_ids": ids,
                "day": day["session"],
            }
    return events, people


def render(e: dict, lang: str, people: dict, tz_name: str) -> str:
    kwargs = {k: v for k, v in e.items() if k in RENDER_KEYS}
    for key in ("present_people", "media_tags"):
        kwargs.pop(key, None)
    if e.get("person_id"):
        kwargs["person"] = people.get(e["person_id"])
    present = e.get("metadata", {}).get("present_person_ids", [])
    if present:
        kwargs["present_people"] = tuple(people[p] for p in present if p in people)
    if e.get("media_tags"):
        kwargs["media_tags"] = tuple(e["media_tags"])
    inp = RenderInput(
        occurred_at=e["start"],
        ended_at=local(e.get("local_end"), ZoneInfo(tz_name)),
        patient_language=lang,
        patient_timezone=tz_name,
        **kwargs,
    )
    sentence = render_event(inp)
    if "None" in sentence or "{" in sentence or "  " in sentence or not sentence:
        fail(f"{e['id']} ({lang}): bad sentence {sentence!r}")
    return sentence


# ----- questions -----


def check_question(q: dict, events: dict, people: dict, tz: ZoneInfo) -> None:
    qid = q.get("id", "?")
    missing = QUESTION_KEYS - set(q)
    if missing:
        fail(f"{qid}: missing keys {sorted(missing)}")
        return
    if q["category"] not in CATEGORIES:
        fail(f"{qid}: unknown category {q['category']!r}")
    if q["split"] != "dev" or q["language"] not in ("ar", "en"):
        fail(f"{qid}: split must be dev and language ar|en")
    if not q["question_ar"] or not q["question_en"]:
        fail(f"{qid}: needs both question_ar and question_en")
    asked = local(q["asked_at"], tz)

    ids = q["evidence_event_ids"]
    if ids != [ev["event_id"] for ev in q["evidence"]]:
        fail(f"{qid}: evidence_event_ids differ from evidence")
    if not q["answerable"] and ids:
        fail(f"{qid}: unanswerable but has evidence")
    if q["answerable"] and not ids:
        fail(f"{qid}: answerable but has no evidence")
    for pid in q["people"]:
        if pid not in people:
            fail(f"{qid}: unknown person {pid}")

    plan = q["expected_plan"]
    start, end = local(plan["window_start"], tz), local(plan["window_end"], tz)
    if end is None or end > asked:
        fail(f"{qid}: expected_plan window_end must be set and not after asked_at")
    if start is not None and end is not None and start >= end:
        fail(f"{qid}: expected_plan window is empty")
    for pid in plan["person_ids"]:
        if pid not in people:
            fail(f"{qid}: expected_plan has unknown person {pid}")
    for t in plan["event_types"] or []:
        if t not in EVENT_TYPES:
            fail(f"{qid}: expected_plan has unknown event_type {t!r}")
    if "الصبح" in q["question_ar"]:
        day = asked.replace(hour=0, minute=0)
        lo, hi = (
            day + timedelta(hours=int(h), minutes=int(m))
            for h, m in (x.split(":") for x in MORNING)
        )
        if start != lo or end != min(hi, asked):
            fail(f"{qid}: 'الصبح' window must be MORNING {MORNING}, ending at asked_at")

    for eid in ids:
        e = events.get(eid)
        if e is None:
            fail(f"{qid}: evidence event {eid} does not exist")
            continue
        if e["end"] > asked:
            fail(f"{qid}: evidence {eid} ends after asked_at")
        if (start is not None and e["start"] < start) or (end and e["end"] > end):
            fail(f"{qid}: plan window loses evidence {eid}")
        if plan["person_ids"] and not set(plan["person_ids"]) & set(e["person_ids"]):
            fail(f"{qid}: plan person filter loses evidence {eid}")
        if plan["event_types"] and e["event_type"] not in plan["event_types"]:
            fail(f"{qid}: plan event_types lose evidence {eid}")


# ----- main -----


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    days = json.loads(DAYS_FILE.read_text(encoding="utf-8"))
    bench = json.loads(BENCHMARK_FILE.read_text(encoding="utf-8"))
    tz_name = days["timezone"]
    tz = ZoneInfo(tz_name)

    events, people = load_events(days, tz)
    sentences = {
        eid: {lang: render(e, lang, people, tz_name) for lang in ("ar", "en")}
        for eid, e in events.items()
    }

    print(f"Patient {days['patient']['name']}, {tz_name}")
    current_day = None
    for eid, e in events.items():
        if e["day"] != current_day:
            current_day = e["day"]
            print(f"\n## {current_day} {e['start'].date()}")
            print("| id | time | event_type | ar | en |")
            print("|---|---|---|---|---|")
        span = hm(e["start"]) + (f"–{hm(e['end'])}" if e.get("local_end") else "")
        s = sentences[eid]
        print(f"| {eid} | {span} | {e['event_type']} | {s['ar']} | {s['en']} |")

    questions = bench["questions"]
    qids = [q.get("id") for q in questions]
    if len(set(qids)) != len(qids):
        fail("duplicate question ids")
    for q in questions:
        check_question(q, events, people, tz)

    print(f"\n## Questions ({len(questions)})")
    for q in questions:
        flags = [name for name in ("false_premise", "multi_moment") if q.get(name)] + (
            [] if q.get("answerable") else ["unanswerable"]
        )
        print(
            f"\n{q['id']}  {q['category']}  [{q['language']}]  asked {q['asked_at']}"
            + (f"  ({', '.join(flags)})" if flags else "")
        )
        print(f"  ar: {q['question_ar']}")
        print(f"  en: {q['question_en']}")
        print(f"  answer: {q['reference_open_answer']}")
        plan = q["expected_plan"]
        print(
            f"  plan: {plan['window_start']} -> {plan['window_end']}, "
            f"people {plan['person_ids']}, types {plan['event_types']}"
        )
        if not q["evidence_event_ids"]:
            print("  evidence: none")
        for eid in q["evidence_event_ids"]:
            sentence = sentences.get(eid, {}).get(q["language"], "(missing)")
            print(f"  evidence {eid}: {sentence}")

    print()
    if errors:
        print(f"FAILED: {len(errors)} problem(s)")
        for message in errors:
            print(f"  - {message}")
        return 1
    print(f"OK: {len(events)} events, {len(questions)} questions, all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
