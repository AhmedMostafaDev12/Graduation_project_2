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

from app.ai.clients.llm import LLMError
from app.ai.rag import assist_loop
from app.ai.rag.assist_loop import (
    ANSWER_NOW,
    MAX_EVIDENCE_TEXT,
    PLACEHOLDER,
    SEARCH_BUDGET_S,
    TOP_K,
    Evidence,
    Person,
    action_schema,
    build_messages,
    calendar_rows,
    filters_set,
    load_prompt,
    people_table,
    question_language,
    results_message,
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


class FakeClock:
    """Replaces assist_loop.monotonic: time moves only when a test moves it."""

    def __init__(self):
        self.now = 1000.0

    def __call__(self):
        return self.now


class ScriptedLLM:
    """Returns the scripted replies in order (dicts as JSON); an Exception is raised.

    takes: fake seconds each call moves the clock by (needs clock). sleeps: real seconds
    each call blocks (for the cut of a search-turn call; keep them short)."""

    model_id = "scripted"

    def __init__(self, *replies, clock=None, takes=(), sleeps=()):
        self.replies = list(replies)
        self.clock = clock
        self.takes = list(takes)
        self.sleeps = list(sleeps)
        self.calls: list[tuple[list[dict], dict | None]] = []

    def complete(self, messages, json_schema=None):
        n = len(self.calls)
        self.calls.append((messages, json_schema))
        reply = self.replies.pop(0)  # before sleeping: a cut call keeps its own reply
        if n < len(self.sleeps):
            time.sleep(self.sleeps[n])
        if n < len(self.takes):
            self.clock.now += self.takes[n]
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


@pytest.fixture
def clock(monkeypatch):
    fake = FakeClock()
    monkeypatch.setattr(assist_loop, "monotonic", fake)
    return fake


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
    assert len(llm.calls) == 2  # an unusable reply is not retried


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


# ----- a search with no results -----

FULL_SEARCH = {
    "window_start": "2026-01-15",
    "window_end": "2026-01-15",
    "person_ids": ["p-ahmed"],
    "event_types": ["conversation_segment"],
    "search_text": "أحمد",
}


def no_results_line(messages):
    lines = last_user(messages).splitlines()
    assert lines[1] == "(no results)"
    return lines[2]


def test_no_results_lists_the_filters_set_by_name_only():
    llm = ScriptedLLM(search(**FULL_SEARCH), answer("مفيش في ذاكرتي.", []))
    run(llm, FakeBackend([]))

    line = no_results_line(llm.calls[1][0])
    assert line == (
        "Filters set: window, person_ids, event_types. These filters may have hidden "
        "the answer. Searches left: 2. Search again with fewer filters before "
        "concluding that nothing is in memory."
    )
    for value in ("p-ahmed", "أحمد", "2026", "conversation_segment"):
        assert value not in line


def test_no_results_names_only_the_filters_that_were_set():
    llm = ScriptedLLM(
        search(person_ids=["p-ahmed"], search_text="x"),
        search(event_types=["reminder"], search_text="x"),
        search(search_text="x"),
        answer("مفيش في ذاكرتي.", []),
    )
    run(llm, FakeBackend([], [], []))

    assert no_results_line(llm.calls[1][0]).startswith("Filters set: person_ids. ")
    assert no_results_line(llm.calls[2][0]).startswith("Filters set: event_types. ")


def test_no_results_without_filters_asks_for_other_words():
    llm = ScriptedLLM(search(search_text="x"), answer("مفيش في ذاكرتي.", []))
    run(llm, FakeBackend([]))
    assert no_results_line(llm.calls[1][0]) == (
        "Filters set: none. Searches left: 2. Search again with other words before "
        "concluding that nothing is in memory."
    )


def test_searches_left_counts_down_to_zero():
    llm = ScriptedLLM(
        search(**FULL_SEARCH),
        search(**FULL_SEARCH),
        search(**FULL_SEARCH),
        answer("مفيش في ذاكرتي.", []),
    )
    run(llm, FakeBackend([], [], []), max_searches=3)

    lines = [no_results_line(llm.calls[i][0]) for i in (1, 2, 3)]
    assert [line.split("Searches left: ")[1][0] for line in lines] == ["2", "1", "0"]
    assert lines[2].endswith("Searches left: 0.")  # no "search again" when none is left
    assert "Search again" not in lines[2]
    assert llm.calls[3][1] == action_schema(final=True)
    assert ANSWER_NOW in last_user(llm.calls[3][0])


def test_results_message_when_there_are_results():
    llm = ScriptedLLM(search(**FULL_SEARCH), answer("ok", ["e1"]))
    run(llm, FakeBackend([E1]))
    message = last_user(llm.calls[1][0])
    assert message.splitlines() == [
        "notes: none",
        'e1 | 2026-01-15 11:20 | 11:20 اتكلمت مع أحمد (ابن): "هعدي عليكي بكره"',
    ]
    for text in ("Filters set", "Searches left", "Search again", "(no results)"):
        assert text not in message


def test_results_message_parts():
    assert results_message([], [], filters=["person_ids"], searches_left=0) == (
        "notes: none\n(no results)\n"
        "Filters set: person_ids. These filters may have hidden the answer. "
        "Searches left: 0."
    )
    assert results_message(["clamped_end"], [], searches_left=0) == (
        "notes: clamped_end\n(no results)\nFilters set: none. Searches left: 0."
    )


def test_the_fallback_plan_counts_as_a_window_filter():
    assert filters_set(fallback_plan(QUESTION, ASKED, CAIRO), ASKED) == ["window"]


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


# ----- the search budget (soft) and the answer-only turn -----


def test_budget_defaults():
    assert SEARCH_BUDGET_S == 15.0
    assert assist_loop.ANSWER_RESERVE_S == 5.0
    assert assist_loop.SEARCH_TURN_S == 3.0


def test_less_than_8_s_left_skips_the_next_search_turn(clock):
    llm = ScriptedLLM(
        search(search_text="x"), answer("ok", ["e1"]), clock=clock, takes=[0.5]
    )
    result = run(llm, FakeBackend([]), search_budget_s=8.4)

    # 8.4 s at the start: one search turn; 7.9 s after it: straight to the answer
    assert len(result.trace) == 1 and not result.trace[0].fallback
    assert llm.calls[1][1] == action_schema(final=True)
    assert "Searches left: 0." in last_user(llm.calls[1][0])
    assert not result.over_budget


def test_8_s_left_allows_a_search_turn(clock):
    llm = ScriptedLLM(search(search_text="x"), answer("ok", ["e1"]), clock=clock)
    run(llm, FakeBackend([E1]), search_budget_s=8.0)
    assert llm.calls[0][1] == action_schema(final=False)


def test_less_than_8_s_at_the_start_searches_once_without_the_llm(clock):
    llm = ScriptedLLM(answer("ok", ["e1"]), clock=clock)
    backend = FakeBackend([E1])
    result = run(llm, backend, search_budget_s=7.9)

    assert backend.plans == [fallback_plan(QUESTION, ASKED, CAIRO)]
    assert llm.calls[0][1] == action_schema(final=True)
    assert result.used_event_ids == ["e1"]


def test_a_slow_answer_turn_still_answers_over_budget(clock):
    # the search turn ends past the budget, the answer turn takes 20 s more: both kept
    llm = ScriptedLLM(
        search(search_text="x"),
        answer("late", ["e1"]),
        clock=clock,
        takes=[16.0, 20.0],
    )
    result = run(llm, FakeBackend([E1]))

    assert result.answer == "late" and result.used_event_ids == ["e1"]
    assert not result.degraded
    assert result.over_budget and result.seconds == pytest.approx(36.0)


def test_a_slow_search_turn_is_cut_and_the_fallback_answers(monkeypatch):
    # real time: the search-turn call may run remaining - ANSWER_RESERVE_S = 0.1 s
    monkeypatch.setattr(assist_loop, "ANSWER_RESERVE_S", 1.9)
    monkeypatch.setattr(assist_loop, "SEARCH_TURN_S", 0.0)
    llm = ScriptedLLM(search(search_text="x"), answer("ok", ["e1"]), sleeps=[0.3])
    backend = FakeBackend([E1])
    result = run(llm, backend, search_budget_s=2.0)

    assert backend.plans == [fallback_plan(QUESTION, ASKED, CAIRO)]
    assert result.trace[0].fallback
    assert llm.calls[1][1] == action_schema(final=True)
    assert result.answer == "ok" and not result.degraded


@pytest.mark.parametrize("error", [TransientError("503"), LLMError("empty answer")])
def test_the_answer_turn_is_retried_once(error):
    llm = ScriptedLLM(search(search_text="x"), error, answer("ok", ["e1"]))
    result = run(llm, FakeBackend([E1]), max_searches=1)  # call 2 = the answer turn

    assert result.answer == "ok" and not result.degraded
    assert len(llm.calls) == 3
    assert llm.calls[1][1] == llm.calls[2][1] == action_schema(final=True)
    assert llm.calls[1][0] == llm.calls[2][0]  # the same messages again


def test_two_failed_answer_turns_are_degraded():
    llm = ScriptedLLM(
        search(search_text="x"), TransientError("503"), LLMError("blocked")
    )
    result = run(llm, FakeBackend([E1]), max_searches=1)

    assert result.degraded and result.answer is None and result.used_event_ids == []
    assert len(llm.calls) == 3
    assert llm.calls[2][1] == action_schema(final=True)


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


@pytest.mark.parametrize(
    ("question", "language"),
    [
        ("أحمد قالي إيه النهارده؟", "Egyptian Arabic"),
        ("Did Dr. Hany call me today?", "English"),
        ("ميعاد Dr. Hany امتى النهارده؟", "Egyptian Arabic"),  # mixed, more Arabic
        ("Did Ahmed say anything about the ميعاد?", "English"),  # mixed, more Latin
        ("ab اب", "Egyptian Arabic"),  # a tie
        ("؟ 123 ٤٥", "Egyptian Arabic"),  # no letters
        ("", "Egyptian Arabic"),
    ],
)
def test_question_language(question, language):
    assert question_language(question) == language


def test_answer_language_is_passed_to_the_prompt(monkeypatch):
    monkeypatch.setattr(assist_loop, "load_prompt", lambda: "[{{answer_language}}]")
    english = build_messages("What did Ahmed say?", ASKED, CAIRO, PEOPLE)
    arabic = build_messages(QUESTION, ASKED, CAIRO, PEOPLE)
    assert english[0]["content"] == "[English]"
    assert arabic[0]["content"] == "[Egyptian Arabic]"


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
