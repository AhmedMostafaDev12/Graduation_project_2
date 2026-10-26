"""Phase 7.5: consolidation from speech: facts, intentions, entity index (spec §7.3 step 5, D40).

Gemini is mocked with respx, and the service uses a scripted LLM that returns fixed JSON:
tests never call a real AI API (AI_LAYER.md rule 9)."""

import json
import uuid
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

import httpx
import pytest
import respx
from sqlalchemy import select, update

from app.ai import fakes
from app.ai.clients.llm import GEMINI_URL, GeminiLLM, LLMError
from app.ai.memory import extract
from app.ai.registry import ProviderNotAvailable, build
from app.errors import TransientError
from app.models import (
    ConsentRecord,
    EnrolledPerson,
    Event,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
)
from app.services import memory_service
from app.workers.tasks import memory as memory_tasks
from tests.conftest import create_patient, register_and_login

NOW = datetime(2026, 10, 20, 9, 0, tzinfo=UTC)  # 12:00 in Cairo (UTC+3)
CAIRO = ZoneInfo("Africa/Cairo")


# ----- the Gemini client -----


def _gemini_reply(text):
    return {
        "candidates": [{"content": {"parts": [{"text": text}]}, "finishReason": "STOP"}]
    }


@respx.mock
def test_gemini_sends_system_roles_and_the_schema():
    route = respx.post(GEMINI_URL).mock(
        return_value=httpx.Response(200, json=_gemini_reply('{"facts": []}'))
    )
    answer = GeminiLLM(api_key="test-key").complete(
        [
            {"role": "system", "content": "rules"},
            {"role": "user", "content": "مرحبا"},
            {"role": "assistant", "content": "ok"},
        ],
        json_schema={"type": "object"},
    )
    assert answer == '{"facts": []}'
    request = route.calls.last.request
    assert request.headers["x-goog-api-key"] == "test-key"
    body = json.loads(request.content)
    assert body["systemInstruction"] == {"parts": [{"text": "rules"}]}
    assert [c["role"] for c in body["contents"]] == ["user", "model"]
    assert body["generationConfig"]["responseMimeType"] == "application/json"
    assert body["generationConfig"]["responseJsonSchema"] == {"type": "object"}


@pytest.mark.parametrize("status", [429, 500, 503])
@respx.mock
def test_gemini_rate_limits_and_server_errors_are_retried(status):
    respx.post(GEMINI_URL).mock(return_value=httpx.Response(status))
    with pytest.raises(TransientError):
        GeminiLLM(api_key="k").complete([{"role": "user", "content": "x"}])


@respx.mock
def test_gemini_timeout_is_retried():
    respx.post(GEMINI_URL).mock(side_effect=httpx.ReadTimeout("slow"))
    with pytest.raises(TransientError):
        GeminiLLM(api_key="k").complete([{"role": "user", "content": "x"}])


@respx.mock
def test_gemini_bad_request_or_blocked_answer_is_not_retried():
    respx.post(GEMINI_URL).mock(return_value=httpx.Response(400, json={"error": {}}))
    with pytest.raises(LLMError, match="400"):
        GeminiLLM(api_key="k").complete([{"role": "user", "content": "x"}])
    respx.post(GEMINI_URL).mock(
        return_value=httpx.Response(200, json={"candidates": []})
    )
    with pytest.raises(LLMError, match="no answer"):
        GeminiLLM(api_key="k").complete([{"role": "user", "content": "x"}])
    respx.post(GEMINI_URL).mock(
        return_value=httpx.Response(
            200, json={"candidates": [{"finishReason": "SAFETY"}]}
        )
    )
    with pytest.raises(LLMError, match="SAFETY"):
        GeminiLLM(api_key="k").complete([{"role": "user", "content": "x"}])


def test_gemini_needs_a_key(monkeypatch):
    with pytest.raises(LLMError, match="GEMINI_API_KEY"):
        GeminiLLM(api_key="")
    monkeypatch.setattr("app.ai.clients.llm.settings.gemini_api_key", None)
    with pytest.raises(ProviderNotAvailable, match="couldn't start: GEMINI_API_KEY"):
        build("stub", {"llm": "gemini-flash"})


# ----- validation of the LLM's answer (no database) -----

SEGMENTS = [
    extract.Segment(0, 0.0, "A", "ميعاد الدكتور سمير يوم الخميس الساعة خمسة"),
    extract.Segment(1, 6.0, "B", "الدوا بقى بـ 250 جنيه   والجرعة 5 مجم"),
    extract.Segment(2, 12.0, "A", "هكلم أحمد بكره الصبح"),
]


def test_quotes_must_be_verbatim_and_values_typed():
    raw = json.dumps(
        {
            "facts": [
                {  # kept: the quote is in segment 1 (extra spaces don't matter)
                    "segment_index": 1,
                    "quote": "الدوا بقى بـ 250 جنيه والجرعة 5 مجم",
                    "speaker_is_patient": False,
                    "values": [
                        {
                            "kind": "money",
                            "value": 250,
                            "unit": "EGP",
                            "text": "250 جنيه",
                        },
                        {"kind": "dose", "value": 5, "unit": "mg", "text": "5 مجم"},
                        {
                            "kind": "money",
                            "value": "a lot",
                            "text": "250 جنيه",
                        },  # not a number
                        {
                            "kind": "number",
                            "value": 7,
                            "text": "سبعة",
                        },  # not in the quote
                    ],
                    "about": [{"kind": "object", "name": "الدوا"}],
                },
                {  # dropped: a paraphrase, not what was said
                    "segment_index": 0,
                    "quote": "The doctor's appointment is on Thursday at five",
                    "values": [],
                    "about": [],
                },
                {  # dropped: points at a segment that doesn't exist
                    "segment_index": 9,
                    "quote": "ميعاد الدكتور",
                    "values": [],
                    "about": [],
                },
            ],
            "intentions": [
                {
                    "holder": "patient",
                    "description": "call Ahmed",
                    "segment_index": 2,
                    "quote": "هكلم أحمد بكره الصبح",
                    "due_at": "2026-10-21T09:00",
                    "due_until": "2026-10-20T08:00",  # before due_at: ignored
                },
                {
                    "holder": "nobody",
                    "description": "x",
                    "segment_index": 2,
                    "quote": "هكلم",
                },
            ],
            "entities": [
                {"kind": "person", "name": "  Dr.  Samir "},
                {"kind": "object", "name": "الدوا"},  # also in `about`: stored once
                {"kind": "animal", "name": "cat"},
            ],
        }
    )
    found = extract.parse_extraction(raw, SEGMENTS, CAIRO)

    assert len(found.facts) == 1
    fact = found.facts[0]
    assert fact.segment.index == 1 and fact.speaker_is_patient is False
    assert fact.quote == "الدوا بقى بـ 250 جنيه والجرعة 5 مجم"
    assert [v["kind"] for v in fact.values] == ["money", "dose"]
    assert fact.values[0] == {
        "kind": "money",
        "value": 250,
        "unit": "EGP",
        "text": "250 جنيه",
    }

    assert len(found.intentions) == 1
    plan = found.intentions[0]
    assert plan.due_at == datetime(2026, 10, 21, 6, 0, tzinfo=UTC)  # 09:00 Cairo
    assert plan.due_until is None
    assert found.entities == [
        extract.EntityRef("object", "الدوا"),
        extract.EntityRef("person", "dr. samir"),
    ]


def test_repeated_items_are_kept_once():
    # seen with Qwen3.8 on Groq: one intention returned 26 times in a loop
    plan = {
        "holder": "patient",
        "description": "call Ahmed",
        "segment_index": 2,
        "quote": "هكلم أحمد بكره الصبح",
    }
    fact = {
        "segment_index": 0,
        "quote": "ميعاد الدكتور سمير",
        "values": [],
        "about": [],
    }
    raw = json.dumps({"facts": [fact] * 3, "intentions": [plan] * 26, "entities": []})
    found = extract.parse_extraction(raw, SEGMENTS, CAIRO)
    assert len(found.facts) == 1 and len(found.intentions) == 1


def test_a_non_json_answer_is_a_permanent_failure():
    with pytest.raises(extract.ExtractionError):
        extract.parse_extraction("I could not find anything.", SEGMENTS, CAIRO)
    # an empty object (the stub profile's fake LLM) is simply nothing found
    found = extract.parse_extraction("{}", SEGMENTS, CAIRO)
    assert (found.facts, found.intentions, found.entities) == ([], [], [])


def test_settlements_need_a_known_plan_and_a_verbatim_quote():
    raw = json.dumps(
        {
            "settled": [
                {"plan": 1, "status": "done", "segment_index": 2, "quote": "هكلم أحمد"},
                {
                    "plan": 1,
                    "status": "not_done",
                    "segment_index": 2,
                    "quote": "هكلم",
                },  # 2nd
                {
                    "plan": 5,
                    "status": "done",
                    "segment_index": 2,
                    "quote": "هكلم",
                },  # no plan 5
                {"plan": 2, "status": "done", "segment_index": 0, "quote": "made up"},
            ]
        }
    )
    settled = extract.parse_settlements(raw, SEGMENTS, n_plans=2)
    assert [(s.plan, s.status) for s in settled] == [(0, "done")]


def test_events_without_segments_use_the_whole_transcript():
    segments = extract.segments_from({"present_person_ids": []}, "كلام")
    assert segments == [extract.Segment(0, 0.0, None, "كلام")]


# ----- the service and tasks (database) -----


class ScriptedLLM:
    """Answers the extraction prompt and the settle prompt with fixed JSON."""

    model_id = "scripted-llm"

    def __init__(self, extraction=None, settled=None):
        self.extraction = extraction or {"facts": [], "intentions": [], "entities": []}
        self.settled = settled or []
        self.calls = []

    def complete(self, messages, json_schema=None):
        self.calls.append(messages)
        if json_schema is extract.SETTLE_SCHEMA:
            return json.dumps({"settled": self.settled})
        return json.dumps(self.extraction)


@pytest.fixture
def llm(monkeypatch):
    scripted = ScriptedLLM()

    class Models:
        pass

    models = Models()
    models.llm = scripted
    models.text_embedder = fakes.FakeTextEmbedder()
    monkeypatch.setattr(memory_service, "get_ai", lambda: models)
    return scripted


def _patient(client, worker_session):
    manager = register_and_login(client)
    patient_id = uuid.UUID(
        create_patient(client, manager)["id"]
    )  # cloud_processing given
    with worker_session() as db:
        ahmed = EnrolledPerson(
            patient_id=patient_id,
            name="Ahmed Mostafa",
            relationship="son",
            added_by="caregiver_manual",
            status="active",
        )
        db.add(ahmed)
        db.commit()
        return patient_id, ahmed.id


def _conversation(worker_session, patient_id, segments, at=NOW, present=()):
    with worker_session() as db:
        event = Event(
            id=uuid.uuid4(),
            patient_id=patient_id,
            source="glasses",
            event_type="conversation_segment",
            occurred_at=at,
            ended_at=at + timedelta(seconds=30),
            transcript_text=" ".join(text for _, _, text in segments),
            language="ar",
            metadata_={
                "present_person_ids": [str(p) for p in present],
                "segments": [
                    {
                        "start_s": start,
                        "end_s": start + 5,
                        "speaker": speaker,
                        "text": text,
                    }
                    for start, speaker, text in segments
                ],
            },
        )
        db.add(event)
        db.commit()
        return event.id


def test_a_conversation_becomes_facts_intentions_and_entities(
    client, worker_session, llm
):
    patient_id, ahmed = _patient(client, worker_session)
    event_id = _conversation(
        worker_session,
        patient_id,
        [
            (0.0, "A", "الدكتور قال الجرعة 5 مجم"),
            (8.0, "B", "هعدي عليكي بكره الساعة خمسة"),
        ],
        present=[ahmed],
    )
    llm.extraction = {
        "facts": [
            {
                "segment_index": 0,
                "quote": "الدكتور قال الجرعة 5 مجم",
                "speaker_is_patient": False,
                "values": [{"kind": "dose", "value": 5, "unit": "mg", "text": "5 مجم"}],
                "about": [{"kind": "person", "name": "الدكتور"}],
            }
        ],
        "intentions": [
            {
                "holder": "other",
                "description": "visit the patient",
                "segment_index": 1,
                "quote": "هعدي عليكي بكره الساعة خمسة",
                "due_at": "2026-10-21T17:00",
            }
        ],
        "entities": [
            {"kind": "person", "name": "Ahmed"},
            {"kind": "object", "name": "الدوا"},
        ],
    }

    assert memory_tasks.consolidate.delay(str(event_id)).get() == "consolidated"

    with worker_session() as db:
        fact = db.scalars(
            select(MemoryFact).where(MemoryFact.event_id == event_id)
        ).one()
        assert fact.quote == "الدكتور قال الجرعة 5 مجم" and fact.speaker_label == "A"
        assert fact.speaker_person_id == ahmed  # the only enrolled person present
        assert fact.values == [
            {"kind": "dose", "value": 5, "unit": "mg", "text": "5 مجم"}
        ]
        assert fact.said_at == NOW and fact.model_id == "scripted-llm/memory_extract.v1"

        plan = db.scalars(
            select(MemoryIntention).where(MemoryIntention.source_event_id == event_id)
        ).one()
        assert plan.status == "open" and plan.holder_person_id == ahmed
        assert plan.stated_at == NOW + timedelta(seconds=8)
        assert plan.due_at == datetime(2026, 10, 21, 14, 0, tzinfo=UTC)  # 17:00 Cairo

        entities = {
            e.name: e
            for e in db.scalars(
                select(MemoryEntity).where(MemoryEntity.patient_id == patient_id)
            )
        }
        assert set(entities) == {"الدكتور", "ahmed", "الدوا"}
        assert (
            entities["ahmed"].person_id == ahmed
        )  # "Ahmed" → the enrolled "Ahmed Mostafa"
        assert fact.about_entity_ids == [entities["الدكتور"].id]
        assert all(len(e.name_embedding) == 1536 for e in entities.values())
        assert db.get(Event, event_id).metadata_["memory"] == {
            "status": "done",
            "model": "scripted-llm/memory_extract.v1",
        }
        assert event_id not in memory_service.pending_event_ids(db, 10_000)

    # running again does nothing (one LLM call so far: no open plans to check)
    assert len(llm.calls) == 1
    assert memory_tasks.consolidate.delay(str(event_id)).get() == "done"
    assert len(llm.calls) == 1


def test_later_conversations_settle_plans_and_count_mentions(
    client, worker_session, llm
):
    patient_id, _ = _patient(client, worker_session)
    first = _conversation(worker_session, patient_id, [(0.0, "A", "لازم أكلم الدكتور")])
    llm.extraction = {
        "facts": [],
        "intentions": [
            {
                "holder": "patient",
                "description": "call the doctor",
                "segment_index": 0,
                "quote": "لازم أكلم الدكتور",
            }
        ],
        "entities": [{"kind": "person", "name": "الدكتور"}],
    }
    memory_tasks.consolidate.delay(str(first)).get()

    later = NOW + timedelta(hours=3)
    second = _conversation(
        worker_session, patient_id, [(4.0, "A", "كلمت الدكتور خلاص")], at=later
    )
    llm.extraction = {
        "facts": [],
        "intentions": [],
        "entities": [{"kind": "person", "name": "الدكتور"}],
    }
    llm.settled = [
        {"plan": 1, "status": "done", "segment_index": 0, "quote": "كلمت الدكتور"}
    ]
    assert memory_tasks.consolidate.delay(str(second)).get() == "consolidated"

    # the settle prompt listed the open plan
    assert "call the doctor" in llm.calls[-1][1]["content"]
    with worker_session() as db:
        plan = db.scalars(
            select(MemoryIntention).where(MemoryIntention.source_event_id == first)
        ).one()
        assert plan.status == "done"
        assert plan.settled_by_event_ids == [second]
        assert plan.settled_at == later + timedelta(seconds=4)
        doctor = db.scalars(
            select(MemoryEntity).where(
                MemoryEntity.patient_id == patient_id, MemoryEntity.name == "الدكتور"
            )
        ).one()
        assert doctor.mention_count == 2
        assert (doctor.first_seen_at, doctor.last_seen_at) == (NOW, later)


def test_no_cloud_consent_sends_nothing_to_the_llm(client, worker_session, llm):
    patient_id, _ = _patient(client, worker_session)
    with worker_session() as db:
        db.execute(
            update(ConsentRecord)
            .where(ConsentRecord.patient_id == patient_id)
            .values(revoked_at=NOW)
        )
        db.commit()
    event_id = _conversation(worker_session, patient_id, [(0.0, "A", "كلام")])

    assert memory_tasks.consolidate.delay(str(event_id)).get() == "not_allowed"
    assert llm.calls == []
    with worker_session() as db:
        assert db.get(Event, event_id).metadata_["memory"]["status"] == "not_allowed"
        assert event_id not in memory_service.pending_event_ids(db, 10_000)


def test_a_temporary_llm_failure_writes_nothing_and_is_retried(
    client, worker_session, llm
):
    patient_id, _ = _patient(client, worker_session)
    event_id = _conversation(worker_session, patient_id, [(0.0, "A", "كلام")])

    def down(messages, json_schema=None):
        raise TransientError("Gemini returned 503")

    llm.complete = down
    # the service raises before writing anything; the task's autoretry re-runs it
    with worker_session() as db, pytest.raises(TransientError):
        memory_service.consolidate_event(db, event_id)
    with worker_session() as db:
        assert "memory" not in db.get(Event, event_id).metadata_
        assert event_id in memory_service.pending_event_ids(db, 10_000)


def test_an_unreadable_answer_marks_the_event_failed(client, worker_session, llm):
    patient_id, _ = _patient(client, worker_session)
    event_id = _conversation(worker_session, patient_id, [(0.0, "A", "كلام")])
    llm.complete = lambda messages, json_schema=None: "not json"

    assert memory_tasks.consolidate.delay(str(event_id)).get() == "failed"
    with worker_session() as db:
        assert db.get(Event, event_id).metadata_["memory"]["status"] == "failed"
        assert event_id not in memory_service.pending_event_ids(db, 10_000)


def test_other_events_are_skipped(client, worker_session, llm):
    patient_id, _ = _patient(client, worker_session)
    with worker_session() as db:
        event = Event(
            id=uuid.uuid4(),
            patient_id=patient_id,
            source="app",
            event_type="memory_paused",
            occurred_at=NOW,
        )
        db.add(event)
        db.commit()
    assert memory_tasks.consolidate.delay(str(event.id)).get() == "skipped"
    assert memory_tasks.consolidate.delay(str(uuid.uuid4())).get() == "missing"


def test_backfill_queues_unconsolidated_transcripts(client, worker_session, llm):
    patient_id, _ = _patient(client, worker_session)
    event_id = _conversation(worker_session, patient_id, [(0.0, "A", "كلام")])
    # the test database is shared, so the sweep may also pick up other tests' events
    memory_tasks.backfill.delay().get()
    with worker_session() as db:
        assert db.get(Event, event_id).metadata_["memory"]["status"] == "done"


def test_unsettled_plans_become_unknown_after_their_window(client, worker_session):
    patient_id, _ = _patient(client, worker_session)
    source = _conversation(worker_session, patient_id, [(0.0, "A", "كلام")])
    now = datetime.now(UTC)
    with worker_session() as db:

        def plan(**times):
            row = MemoryIntention(
                patient_id=patient_id,
                holder="patient",
                description="x",
                quote="كلام",
                source_event_id=source,
                model_id="m",
                **times,
            )
            db.add(row)
            return row

        overdue = plan(
            stated_at=now - timedelta(days=3), due_at=now - timedelta(days=2)
        )
        due_soon = plan(
            stated_at=now - timedelta(days=3), due_at=now - timedelta(hours=2)
        )
        window = plan(
            stated_at=now - timedelta(days=3), due_until=now + timedelta(days=1)
        )
        no_due_old = plan(stated_at=now - timedelta(days=8))
        no_due_new = plan(stated_at=now - timedelta(days=2))
        db.commit()
        ids = [r.id for r in (overdue, due_soon, window, no_due_old, no_due_new)]

    assert memory_tasks.expire_intentions.delay().get() >= 2
    with worker_session() as db:
        statuses = [db.get(MemoryIntention, i).status for i in ids]
        assert statuses == ["unknown", "open", "open", "unknown", "open"]
        assert db.get(MemoryIntention, ids[0]).settled_at is not None
