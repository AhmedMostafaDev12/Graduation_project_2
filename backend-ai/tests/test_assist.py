"""Phase 9.1: /assist answers from the patient's memories (spec D22, D39, D40).

The retriever runs on the test database with the fake embedder; the agent loop runs with a
scripted LLM that searches once and answers from what it saw. No real AI API is called
(AI_LAYER.md rule 9)."""

import json
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select, update

from app.ai import fakes
from app.ai.rag import answer as answer_module
from app.ai.rag.planner import QueryPlan
from app.ai.rag.retriever import MemorySearch, fuse, words
from app.models import (
    ConsentRecord,
    Encounter,
    EnrolledPerson,
    Event,
    MediaAsset,
    MemoryAction,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
    ObjectSighting,
)
from tests.conftest import API, create_patient, pair_device, register_and_login

NOW = datetime.now(UTC).replace(microsecond=0)
EMBED = fakes.FakeTextEmbedder()


# ----- small pieces -----


def test_words_and_fusion():
    assert words("Where are my KEYS? فين المفاتيح؟ ok") == [
        "where",
        "are",
        "keys",
        "فين",
        "المفاتيح",
    ]
    a, b, c = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    # c is second in both lists, a first in one: c wins on the sum
    assert fuse([([a, c], 1.0), ([b, c], 1.0)])[0] == c
    assert fuse([([a], 2.0), ([b], 1.0)]) == [a, b]


# ----- a patient with memories -----


def _memories(client, worker_session):
    manager = register_and_login(client)
    patient_id = uuid.UUID(create_patient(client, manager)["id"])
    device_id = uuid.UUID(pair_device(client, manager, str(patient_id))["device_id"])
    ids = {}
    with worker_session() as db:
        sara = EnrolledPerson(
            patient_id=patient_id,
            name="Sara",
            relationship="daughter",
            added_by="caregiver_manual",
            status="active",
        )
        db.add(sara)
        db.flush()

        def event(key, hours_ago, event_type, text, **fields):
            e = Event(
                id=uuid.uuid4(),
                patient_id=patient_id,
                source="glasses",
                event_type=event_type,
                occurred_at=NOW - timedelta(hours=hours_ago),
                rendered_text=text,
                embedding=EMBED.embed([text])[0],
                **fields,
            )
            db.add(e)
            db.flush()
            ids[key] = e.id
            return e

        event(
            "talk",
            2,
            "conversation_segment",
            "talked with Sara: I put the brown shawl in the big wardrobe",
            transcript_text="I put the brown shawl in the big wardrobe",
            metadata_={"present_person_ids": [str(sara.id)]},
        )
        visit = Encounter(
            id=uuid.uuid4(),
            patient_id=patient_id,
            device_id=device_id,
            person_id=sara.id,
            started_at=NOW - timedelta(hours=3),
            ended_at=NOW - timedelta(hours=2),
            best_confidence=0.9,
        )
        db.add(visit)
        db.flush()
        event("visit", 3, "encounter", "Sara visited", encounter_id=visit.id)
        event("pill", 5, "reminder", "blood pressure pill confirmed")
        event("old", 24 * 10, "manual_note", "the brown shawl was washed")
        photo = event("photo", 1, "notable_moment_captured", "a photo in the kitchen")

        media = MediaAsset(
            id=uuid.uuid4(),
            patient_id=patient_id,
            event_id=photo.id,
            asset_type="image",
            storage_key="k",
            trigger="salient_frame",
            status="confirmed",
        )
        keys = MemoryEntity(
            patient_id=patient_id,
            kind="object",
            name="keys",
            first_seen_at=NOW,
            last_seen_at=NOW,
        )
        db.add_all([media, keys])
        db.flush()
        db.add(
            ObjectSighting(
                patient_id=patient_id,
                entity_id=keys.id,
                state="on the table",
                room="kitchen",
                seen_at=photo.occurred_at,
                media_asset_id=media.id,
                model_id="m",
            )
        )
        db.add(
            MemoryFact(
                patient_id=patient_id,
                event_id=ids["talk"],
                quote="the dose is 5 mg",
                language="en",
                values=[{"kind": "dose", "value": 5, "unit": "mg", "text": "5 mg"}],
                said_at=NOW - timedelta(hours=2),
                model_id="m",
            )
        )
        db.add(
            MemoryIntention(
                patient_id=patient_id,
                holder="patient",
                description="call the doctor",
                quote="I'll call the doctor",
                source_event_id=ids["pill"],
                stated_at=NOW - timedelta(hours=5),
                model_id="m",
            )
        )
        db.commit()
        ids["sara"] = sara.id
    return manager, patient_id, ids


def _plan(text="", hours=None, people=(), types=None) -> QueryPlan:
    return QueryPlan(
        window_start=NOW - timedelta(hours=hours) if hours else None,
        window_end=NOW + timedelta(minutes=1),
        person_ids=[str(p) for p in people],
        event_types=types,
        search_text=text,
    )


def _ids(results) -> list[uuid.UUID]:
    return [uuid.UUID(r.event_id) for r in results]


def test_filters_bound_the_candidates(client, worker_session):
    _, patient_id, ids = _memories(client, worker_session)
    with worker_session() as db:
        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED)
        newest = _ids(search.search_now(_plan()))
        assert (
            newest[0] == ids["photo"] and ids["old"] in newest
        )  # no text: newest first
        recent = _ids(search.search_now(_plan(hours=24)))
        assert ids["old"] not in recent
        # present people: the conversation (present_person_ids) and the encounter
        with_sara = set(_ids(search.search_now(_plan(people=[ids["sara"]]))))
        assert with_sara == {ids["talk"], ids["visit"]}
        reminders = _ids(search.search_now(_plan(types=["reminder"])))
        assert reminders == [ids["pill"]]


def test_words_and_structures_rank_and_explain(client, worker_session):
    _, patient_id, ids = _memories(client, worker_session)
    with worker_session() as db:
        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED)
        shawl = search.search_now(_plan("brown shawl", hours=24))
        assert _ids(shawl)[0] == ids["talk"]

        keys = search.search_now(_plan("where are my keys"))
        assert _ids(keys)[0] == ids["photo"]
        assert keys[0].text.startswith(
            "[keys last seen: on the table, kitchen] a photo"
        )

        dose = search.search_now(_plan("what dose did the doctor say"))
        top = {r.event_id: r.text for r in dose}
        assert "said: «the dose is 5 mg» (5 mg)" in top[str(ids["talk"])]
        assert "plan: call the doctor (status: open)" in top[str(ids["pill"])]

        # the local time is in the patient's timezone
        assert keys[0].occurred_at == (
            (NOW - timedelta(hours=1))
            .astimezone(__import__("zoneinfo").ZoneInfo("Africa/Cairo"))
            .strftime("%Y-%m-%d %H:%M")
        )


def test_a_person_absent_in_the_window_comes_back_from_outside_it(
    client, worker_session
):
    _, patient_id, ids = _memories(client, worker_session)
    with worker_session() as db:
        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED)
        # "did Sara come in the last hour?": she didn't, but she was here 2 hours ago
        found = search.search_now(_plan("Sara", hours=1, people=[ids["sara"]]))
        assert len(found) == 1 and uuid.UUID(found[0].event_id) == ids["talk"]
        assert found[0].text.startswith("[outside the time asked:")
        # with results in the window, nothing is added
        inside = search.search_now(_plan("Sara", hours=24, people=[ids["sara"]]))
        assert not any(r.text.startswith("[outside") for r in inside)


def test_plans_bring_their_proof_and_actions_their_count(client, worker_session):
    _, patient_id, ids = _memories(client, worker_session)
    with worker_session() as db:
        # the plan was settled by the later conversation
        plan = db.scalars(
            select(MemoryIntention).where(MemoryIntention.patient_id == patient_id)
        ).one()
        plan.status, plan.settled_at = "done", NOW - timedelta(hours=2)
        plan.settled_by_event_ids = [ids["talk"]]
        # the pill was taken twice, seen on the photo
        pills = MemoryEntity(
            patient_id=patient_id,
            kind="object",
            name="pill box",
            first_seen_at=NOW,
            last_seen_at=NOW,
        )
        db.add(pills)
        db.flush()
        for hours in (5, 1):
            db.add(
                MemoryAction(
                    patient_id=patient_id,
                    verb="take_medication",
                    entity_id=pills.id,
                    quantity=1,
                    unit="pill",
                    occurred_at=NOW - timedelta(hours=hours),
                    source="vision",
                    evidence_event_id=ids["pill" if hours == 5 else "photo"],
                    model_id="m",
                )
            )
        db.commit()

        search = MemorySearch(db, patient_id, "Africa/Cairo", EMBED)
        called = {
            r.event_id: r.text for r in search.search_now(_plan("call the doctor"))
        }
        assert "status: done" in called[str(ids["pill"])]
        assert "settles the plan «call the doctor»: done" in called[str(ids["talk"])]

        # the model narrowed to reminders: the photo's action still counts (window only)
        taken = search.search_now(_plan("take medication pill box", types=["reminder"]))
        texts = {r.event_id: r.text for r in taken}
        assert (
            "count: take medication pill box ×2 in the time searched"
            in texts[str(ids["photo"])]
        )

        # flat memory (the H6 ablation): no structure lines at all
        flat = MemorySearch(db, patient_id, "Africa/Cairo", EMBED, use_structures=False)
        assert not any(r.text.startswith("[") for r in flat.search_now(_plan("keys")))


# ----- /assist end to end -----


class ScriptedLLM:
    """Searches once for `search_text`, then answers citing the first result it saw."""

    model_id = "scripted-llm"

    def __init__(self, search_text: str):
        self.search_text, self.turns = search_text, 0

    def complete(self, messages, json_schema=None):
        self.turns += 1
        if self.turns == 1:
            return json.dumps(
                {
                    "action": "search",
                    "search": {
                        "window_start": None,
                        "window_end": None,
                        "day_part": None,
                        "person_ids": [],
                        "event_types": None,
                        "search_text": self.search_text,
                    },
                    "answer": None,
                    "used_event_ids": [],
                }
            )
        results = messages[-1]["content"].splitlines()[1:]
        first = results[0].split(" | ")[0]
        return json.dumps(
            {
                "action": "answer",
                "search": None,
                "answer": "Your keys are on the kitchen table.",
                "used_event_ids": [first, "made-up-id"],
            }
        )


class Models:
    def __init__(self, llm):
        self.assist_llm, self.text_embedder = llm, EMBED


def test_assist_answers_from_memory_with_sources(client, worker_session, monkeypatch):
    manager, patient_id, ids = _memories(client, worker_session)
    monkeypatch.setattr(answer_module, "get_ai", lambda: Models(ScriptedLLM("keys")))
    response = client.post(
        f"{API}/patients/{patient_id}/assist",
        json={"question": "Where are my keys?"},
        headers=manager["headers"],
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["answer"] == "Your keys are on the kitchen table."
    assert body["language"] == "en"
    # the cited photo, and not the id the model made up
    assert body["source_event_ids"] == [str(ids["photo"])]


def test_an_unusable_model_gives_a_kind_not_sure(client, worker_session):
    manager, patient_id, _ = _memories(client, worker_session)
    # the stub profile's fake LLM answers "{}": every turn is unusable
    response = client.post(
        f"{API}/patients/{patient_id}/assist",
        json={"question": "فين المفاتيح؟"},
        headers=manager["headers"],
    )
    assert response.status_code == 200
    body = response.json()
    assert body == {
        "answer": answer_module.NOT_SURE["ar"],
        "language": "ar",
        "source_event_ids": [],
    }


def test_no_cloud_consent_sends_nothing(client, worker_session, monkeypatch):
    manager, patient_id, _ = _memories(client, worker_session)
    llm = ScriptedLLM("keys")
    monkeypatch.setattr(answer_module, "get_ai", lambda: Models(llm))
    with worker_session() as db:
        db.execute(
            update(ConsentRecord)
            .where(ConsentRecord.patient_id == patient_id)
            .values(revoked_at=NOW)
        )
        db.commit()
    response = client.post(
        f"{API}/patients/{patient_id}/assist",
        json={"question": "Where are my keys?"},
        headers=manager["headers"],
    )
    assert response.json()["answer"] == answer_module.NO_CLOUD_CONSENT["en"]
    assert llm.turns == 0


@pytest.mark.parametrize(
    "question,language", [("Who visited?", "en"), ("مين جالي؟", "ar")]
)
def test_the_answer_follows_the_questions_language(
    client, worker_session, question, language
):
    manager, patient_id, _ = _memories(client, worker_session)
    response = client.post(
        f"{API}/patients/{patient_id}/assist",
        json={"question": question, "language": "en" if language == "ar" else "ar"},
        headers=manager["headers"],
    )
    assert response.json()["language"] == language
