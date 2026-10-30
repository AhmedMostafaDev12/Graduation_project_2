"""The /assist loop (track R3): a scripted fake LLM and a fake search backend. No network.

Synthetic ids and text only.
"""

import ast
import asyncio
import json
import time
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest

from app.ai.rag import assist_loop
from app.ai.rag.assist_loop import (
    ANSWER_NOW,
    MAX_EVIDENCE_TEXT,
    PLACEHOLDER,
    TOP_K,
    Evidence,
    Person,
    action_schema,
    build_messages,
    calendar_rows,
    load_prompt,
    people_table,
    run_assist,
)
from app.ai.rag.planner import fallback_plan
from app.errors import TransientError

CAIRO = "Africa/Cairo"
ASKED = datetime(2026, 1, 15, 21, 0, tzinfo=ZoneInfo(CAIRO))  # a Thursday
QUESTION = "أحمد قالي إيه النهارده؟"
PEOPLE = [Person("p-ahmed", "أحمد", "ابن"), Person("p-mona", "منى", "ممرضة")]
E1 = Evidence("e1", "2026-01-15 11:20", '11:20 اتكلمت مع أحمد (ابن): "هعدي عليكي بكره"')
E2 = Evidence("e2", "2026-01-14 18:00", "18:00 قابلت منى (ممرضة)")


class ScriptedLLM:
    """Returns the scripted replies in order (dicts as JSON); an Exception is raised."""

    model_id = "scripted"

    def __init__(self, *replies, delay: float = 0.0):
        self.replies = list(replies)
        self.delay = delay
        self.calls: list[tuple[list[dict], dict | None]] = []

    def complete(self, messages, json_schema=None):
        self.calls.append((messages, json_schema))
        if self.delay:
            time.sleep(self.delay)
        reply = self.replies.pop(0)
        if isinstance(reply, Exception):
            raise reply
        return (
            reply if isinstance(reply, str) else json.dumps(reply, ensure_ascii=False)
        )


class FakeBackend:
    def __init__(self, *batches, fail: bool = False):
        self.batches = list(batches)
        self.fail = fail
        self.plans = []

    async def search(self, plan):
        self.plans.append(plan)
        if self.fail:
            raise RuntimeError("database down")
        return self.batches.pop(0) if self.batches else []


def search(**args):
    return {"action": "search", "search": args, "answer": None, "used_event_ids": []}


def answer(text, ids=()):
    return {
        "action": "answer",
        "search": None,
        "answer": text,
        "used_event_ids": list(ids),
    }


def run(llm, backend, **kwargs):
    kwargs = {
        "question": QUESTION,
        "asked_at": ASKED,
        "tz": CAIRO,
        "people": PEOPLE,
        **kwargs,
    }
    return asyncio.run(run_assist(llm, backend, **kwargs))


def last_user(messages):
    return [m for m in messages if m["role"] == "user"][-1]["content"]


# ----- the normal path -----


def test_search_then_answer():
    llm = ScriptedLLM(
        search(
            window_start="2026-01-15", person_ids=["p-ahmed"], search_text="أحمد قال"
        ),
        answer("أحمد قالك إنه هيعدي عليكي بكره.", ["e1"]),
    )
    backend = FakeBackend([E1])
    result = run(llm, backend)

    assert result.answer == "أحمد قالك إنه هيعدي عليكي بكره."
    assert result.used_event_ids == ["e1"]
    assert not result.degraded
    assert len(result.trace) == 1
    step = result.trace[0]
    assert step.plan == backend.plans[0]
    assert step.plan.person_ids == ["p-ahmed"]
    assert step.notes == () and step.n_results == 1 and not step.fallback
    assert llm.calls[0][1] == action_schema(final=False)
    results = last_user(llm.calls[1][0])
    assert "notes: none" in results
    assert "e1 | 2026-01-15 11:20 | 11:20 اتكلمت مع أحمد" in results


def test_second_search_after_a_bad_first_result():
    llm = ScriptedLLM(
        search(window_start="2026-01-15", person_ids=["p-ahmed"], search_text="x"),
        search(search_text="منى"),
        answer("منى جت امبارح الساعة 6.", ["e2"]),
    )
    backend = FakeBackend([], [E2])
    result = run(llm, backend)

    assert len(result.trace) == 2
    assert [s.n_results for s in result.trace] == [0, 1]
    assert "(no results)" in last_user(llm.calls[1][0])
    assert result.used_event_ids == ["e2"]


def test_notes_go_back_to_the_model():
    llm = ScriptedLLM(
        search(person_ids=["p-ghost"], search_text="x"), answer("مش متأكدة مين.", [])
    )
    result = run(llm, FakeBackend([E1]))
    assert result.trace[0].notes == ("dropped_person_id",)
    assert "notes: dropped_person_id" in last_user(llm.calls[1][0])


def test_first_turn_answer_is_ignored_and_fallback_searched():
    llm = ScriptedLLM(answer("تخمين", []), answer("أحمد قالك هيعدي بكره.", ["e1"]))
    backend = FakeBackend([E1])
    result = run(llm, backend)

    assert backend.plans == [fallback_plan(QUESTION, ASKED, CAIRO)]
    assert result.trace[0].fallback
    assert result.answer == "أحمد قالك هيعدي بكره."
    assert result.used_event_ids == ["e1"]


def test_max_searches_forces_the_answer_only_schema():
    llm = ScriptedLLM(
        search(search_text="a"), search(search_text="b"), answer("خلاص.", ["e1"])
    )
    backend = FakeBackend([E1], [E2])
    result = run(llm, backend, max_searches=2)

    assert len(backend.plans) == 2
    assert len(llm.calls) == 3
    final_schema = llm.calls[2][1]
    assert final_schema == action_schema(final=True)
    assert final_schema["properties"]["action"]["enum"] == ["answer"]
    assert ANSWER_NOW in last_user(llm.calls[2][0])
    assert result.answer == "خلاص." and result.used_event_ids == ["e1"]


def test_search_on_the_answer_only_turn_is_degraded():
    llm = ScriptedLLM(search(search_text="a"), search(search_text="b"))
    result = run(llm, FakeBackend([E1]), max_searches=1)
    assert result.degraded and result.answer is None and result.used_event_ids == []


def test_invented_used_event_ids_are_dropped():
    llm = ScriptedLLM(search(search_text="x"), answer("تمام.", ["e1", "e-ghost", "e1"]))
    result = run(llm, FakeBackend([E1]))
    assert result.used_event_ids == ["e1"]


def test_results_are_capped():
    long = Evidence("e9", "2026-01-15 10:00", "كلمة " * 200)
    many = [Evidence(f"e{i}", "2026-01-15 10:00", "x") for i in range(TOP_K + 2)]
    llm = ScriptedLLM(search(search_text="x"), search(search_text="y"), answer("ok"))
    result = run(llm, FakeBackend([long], many))

    first = last_user(llm.calls[1][0]).splitlines()[-1]
    assert len(first.split(" | ", 2)[2]) == MAX_EVIDENCE_TEXT
    assert result.trace[1].n_results == TOP_K


# ----- failures -----


@pytest.mark.parametrize(
    "bad",
    [
        "not json",
        '{"action": "dance"}',
        json.dumps({"action": "search", "search": None, "answer": None}),
        json.dumps({"action": "answer", "search": None, "answer": "  "}),
    ],
)
def test_invalid_reply_runs_the_fallback_then_answers(bad):
    llm = ScriptedLLM(bad, answer("أحمد قالك هيعدي بكره.", ["e1"]))
    backend = FakeBackend([E1])
    result = run(llm, backend)

    assert backend.plans == [fallback_plan(QUESTION, ASKED, CAIRO)]
    assert result.trace[0].fallback
    assert llm.calls[1][1] == action_schema(final=True)
    assert result.answer == "أحمد قالك هيعدي بكره." and not result.degraded


def test_llm_exceptions_end_degraded():
    llm = ScriptedLLM(TransientError("429"), RuntimeError("boom"))
    backend = FakeBackend([E1])
    result = run(llm, backend)

    assert result.degraded and result.answer is None and result.used_event_ids == []
    assert len(backend.plans) == 1 and result.trace[0].fallback


def test_failure_after_a_search_still_runs_one_fallback():
    llm = ScriptedLLM(search(search_text="x"), "garbage", answer("ok", ["e2"]))
    backend = FakeBackend([E1], [E2])
    result = run(llm, backend)

    assert [s.fallback for s in result.trace] == [False, True]
    assert result.used_event_ids == ["e2"]


def test_backend_exception_is_degraded():
    llm = ScriptedLLM(search(search_text="x"), answer("ok"))
    result = run(llm, FakeBackend(fail=True))
    assert result.degraded and result.answer is None


# ----- the deadline -----


def test_deadline_near_goes_to_the_answer_only_turn(monkeypatch):
    monkeypatch.setattr(assist_loop, "ANSWER_RESERVE_S", 0.3)
    llm = ScriptedLLM(search(search_text="x"), answer("ok", ["e1"]), delay=0.15)
    result = run(llm, FakeBackend([E1]), deadline_s=0.4)

    assert len(result.trace) == 1
    assert llm.calls[1][1] == action_schema(final=True)
    assert result.answer == "ok"


def test_deadline_passed_during_a_call_is_degraded(monkeypatch):
    monkeypatch.setattr(assist_loop, "ANSWER_RESERVE_S", 0.05)
    llm = ScriptedLLM(search(search_text="x"), answer("late"), delay=0.4)
    backend = FakeBackend([E1])
    result = run(llm, backend, deadline_s=0.2)

    assert result.degraded and result.answer is None
    assert result.trace[0].fallback  # the timed-out turn was replaced by the fallback
    assert len(llm.calls) == 1  # no time left for the answer-only turn


def test_no_time_for_any_turn_still_searches_once_without_the_llm(monkeypatch):
    monkeypatch.setattr(assist_loop, "ANSWER_RESERVE_S", 5.0)
    llm = ScriptedLLM(answer("ok", ["e1"]))
    backend = FakeBackend([E1])
    result = run(llm, backend, deadline_s=4.0)

    assert backend.plans == [fallback_plan(QUESTION, ASKED, CAIRO)]
    assert llm.calls[0][1] == action_schema(final=True)
    assert result.used_event_ids == ["e1"]


# ----- plan_only -----


def test_plan_only_never_calls_the_backend():
    llm = ScriptedLLM(search(window_start="2026-01-15", search_text="أحمد"))
    backend = FakeBackend(fail=True)
    result = run(llm, backend, plan_only=True)

    assert backend.plans == []
    assert len(llm.calls) == 1
    assert result.answer is None and not result.degraded
    assert len(result.trace) == 1 and not result.trace[0].fallback
    assert result.trace[0].plan.search_text == "أحمد"


@pytest.mark.parametrize("first", [answer("تخمين"), "not json"])
def test_plan_only_returns_the_fallback_plan(first):
    backend = FakeBackend(fail=True)
    result = run(ScriptedLLM(first), backend, plan_only=True)
    assert backend.plans == []
    assert result.trace[0].fallback
    assert result.trace[0].plan == fallback_plan(QUESTION, ASKED, CAIRO)


# ----- inputs -----


def test_naive_asked_at_or_bad_timezone_raise():
    with pytest.raises(ValueError):
        run(ScriptedLLM(), FakeBackend(), asked_at=datetime(2026, 1, 15, 21, 0))
    with pytest.raises(ValueError):
        run(ScriptedLLM(), FakeBackend(), tz="Mars/Olympus")


# ----- the prompt -----


def test_prompt_has_no_unfilled_placeholders():
    assert set(PLACEHOLDER.findall(load_prompt())) == {
        "now_local",
        "timezone",
        "calendar",
        "people",
    }
    system = build_messages(QUESTION, ASKED, CAIRO, PEOPLE)[0]["content"]
    assert PLACEHOLDER.findall(system) == []
    assert "2026-01-15 21:00, Thursday / الخميس" in system


def test_calendar_is_14_days_with_arabic_weekdays():
    rows = calendar_rows(ASKED)
    assert len(rows) == 14
    assert rows[0] == "2026-01-15 | الخميس | Thursday | النهارده"
    assert rows[1] == "2026-01-14 | الأربع | Wednesday | امبارح"
    assert rows[2] == "2026-01-13 | التلات | Tuesday | أول امبارح"
    assert rows[13] == "2026-01-02 | الجمعة | Friday"


def test_people_table_drops_the_english_column_when_empty():
    assert (
        people_table(PEOPLE)
        == "id | name | relation\np-ahmed | أحمد | ابن\np-mona | منى | ممرضة"
    )
    with_en = people_table([Person("p-ahmed", "أحمد", "ابن", "Ahmed")])
    assert (
        with_en == "id | name | English name | relation\np-ahmed | أحمد | Ahmed | ابن"
    )
    assert people_table([]) == "(none)"


def test_question_is_the_user_turn():
    messages = build_messages(QUESTION, ASKED, CAIRO, PEOPLE)
    assert [m["role"] for m in messages] == ["system", "user"]
    assert messages[1]["content"] == QUESTION


# ----- shape and privacy -----


def test_no_patient_id_in_any_schema():
    for final in (False, True):
        assert "patient_id" not in json.dumps(action_schema(final=final))


def test_module_does_not_log():
    tree = ast.parse(Path(assist_loop.__file__).read_text(encoding="utf-8"))
    imported = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imported |= {a.name.split(".")[0] for a in node.names}
        elif isinstance(node, ast.ImportFrom):
            imported.add((node.module or "").split(".")[0])
        elif isinstance(node, ast.Call) and getattr(node.func, "id", None) == "print":
            pytest.fail("print() in assist_loop")
    assert "logging" not in imported
