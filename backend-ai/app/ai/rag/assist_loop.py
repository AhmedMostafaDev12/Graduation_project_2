"""The /assist agent: a bounded search-then-answer loop over the patient's memories (track R3).

Provider-neutral: no native tool calling. Every turn the model returns one JSON object
(`action_schema`): either a search (RawSearchArgs) or an answer with the ids of the results
it used. Code drives the loop:

- turn 1 is always a search; an answer on turn 1 is ignored and fallback_plan is searched;
- every search goes through planner.validate_args, and its note codes go back to the model
  with the results ("id | local time | text"); a search with no results also tells the
  model which filters were set (names only) and how many searches are left, so the model
  can loosen them (code never retries on its own);
- after max_searches, or when the search budget is short, one answer-only turn
  (`final=True`);
- the budget (search_budget_s) is SOFT and only for searching: no model-chosen search turn
  starts with less than ANSWER_RESERVE_S + SEARCH_TURN_S left, and a search-turn call is cut
  at remaining - ANSWER_RESERVE_S. The answer-only turn is never cut by the budget (it waits
  for the LLM client's own timeout): a late answer is better than none. over_budget says
  the whole loop took longer than the budget;
- any LLM failure on a search turn (exception, timeout, bad JSON, wrong shape): one fallback
  search (if none ran yet), then the answer-only turn. That turn is retried once after a
  TransientError or LLMError; when both attempts fail, or the reply is unusable, the result
  is degraded with no answer. A failing search backend also ends degraded. Nothing is raised
  to the caller except ValueError for a naive asked_at or an unknown timezone (programming
  errors);
- used_event_ids not among the results the model saw are dropped;
- the answer language comes from the question's letters (question_language) and is passed
  to the prompt as {{answer_language}} (v1 does not use it).

The retriever (SearchBackend) comes in R4. Privacy: nothing here is logged; the trace is
returned in memory only and holds no question or result text.
"""

import asyncio
import json
import re
from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from functools import cache
from pathlib import Path
from time import monotonic
from typing import Literal, Protocol
from zoneinfo import ZoneInfo

from pydantic import BaseModel, ConfigDict

from app.ai.clients.llm import LLMError
from app.ai.interfaces import LLM
from app.ai.rag.planner import (
    MAX_LOOKBACK_DAYS,
    QueryPlan,
    RawSearchArgs,
    fallback_plan,
    search_args_schema,
    validate_args,
)
from app.errors import TransientError

PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"
ASSIST_PROMPT = "assist_agent.v1"

TOP_K = 8  # results per search the model sees
MAX_EVIDENCE_TEXT = 400  # characters of one result's text
SEARCH_BUDGET_S = 15.0  # soft: seconds for searching; the answer turn may run past it
ANSWER_RESERVE_S = 5.0  # DRAFT: seconds kept for the answer-only turn
SEARCH_TURN_S = 3.0  # DRAFT: least time a search turn needs, on top of the reserve
CALENDAR_DAYS = 14

WEEKDAYS_EN = (
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
)
WEEKDAYS_AR = ("الاتنين", "التلات", "الأربع", "الخميس", "الجمعة", "السبت", "الحد")
RELATIVE_AR = ("النهارده", "امبارح", "أول امبارح")
PLACEHOLDER = re.compile(r"\{\{(\w+)\}\}")
ARABIC_LETTERS = re.compile(r"[\u0600-\u06ff\u0750-\u077f\ufb50-\ufdff\ufe70-\ufeff]")


# ----- inputs and outputs -----


@dataclass(frozen=True)
class Person:
    """Someone the patient knows; name_en only when the profile has one."""

    id: str
    name: str
    relation: str
    name_en: str | None = None


@dataclass(frozen=True)
class Evidence:
    """One search result as the model sees it."""

    event_id: str
    occurred_at: str  # local time, "YYYY-MM-DD HH:MM"
    text: str


class SearchBackend(Protocol):
    async def search(self, plan: QueryPlan) -> list[Evidence]:
        """At most TOP_K results, best first. The patient is bound by the backend."""
        ...


@dataclass(frozen=True)
class Step:
    """One search: the validated plan, the note codes, how many results, how long the
    turn took (LLM call + search). fallback = the plan is fallback_plan, not the model's."""

    plan: QueryPlan
    notes: tuple[str, ...]
    n_results: int
    seconds: float
    fallback: bool = False


@dataclass(frozen=True)
class AssistResult:
    """seconds: the whole loop; over_budget: seconds > search_budget_s (soft, reported)."""

    answer: str | None
    used_event_ids: list[str]
    trace: list[Step] = field(default_factory=list)
    degraded: bool = False
    seconds: float = 0.0
    over_budget: bool = False


# ----- what the model returns each turn -----


def action_schema(*, final: bool = False) -> dict:
    """JSON schema of one turn. final=True: the answer-only turn."""
    if final:
        action = {"type": "string", "enum": ["answer"]}
        search: dict = {"type": "null"}
        answer: dict = {"type": "string"}
    else:
        action = {"type": "string", "enum": ["search", "answer"]}
        search = {"anyOf": [search_args_schema(), {"type": "null"}]}
        answer = {"anyOf": [{"type": "string"}, {"type": "null"}]}
    return {
        "type": "object",
        "properties": {
            "action": action,
            "search": search,
            "answer": answer,
            "used_event_ids": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["action", "search", "answer", "used_event_ids"],
    }


class _Turn(BaseModel):
    model_config = ConfigDict(extra="ignore")

    action: Literal["search", "answer"]
    search: RawSearchArgs | None = None
    answer: str | None = None
    used_event_ids: list[str] = []


class _BadTurn(Exception):
    """The model's reply has the wrong shape for this turn."""


class _BackendFailed(Exception):
    pass


def _parse_turn(raw: str, *, final: bool) -> _Turn:
    turn = _Turn.model_validate(json.loads(raw))  # ValueError subclasses on bad input
    if turn.action == "search" and (final or turn.search is None):
        raise _BadTurn
    if turn.action == "answer" and not (turn.answer or "").strip():
        raise _BadTurn
    return turn


# ----- the prompt -----


@cache
def load_prompt(name: str = ASSIST_PROMPT) -> str:
    return (PROMPTS_DIR / f"{name}.txt").read_text(encoding="utf-8")


def fill(template: str, values: dict[str, str]) -> str:
    """Replace every {{name}}; a missing value is a programming error (KeyError)."""
    return PLACEHOLDER.sub(lambda m: values[m.group(1)], template)


def _weekday(d: datetime) -> str:
    return f"{WEEKDAYS_EN[d.weekday()]} / {WEEKDAYS_AR[d.weekday()]}"


def calendar_rows(now_local: datetime) -> list[str]:
    rows = []
    for back in range(CALENDAR_DAYS):
        day = (now_local - timedelta(days=back)).date()
        relative = RELATIVE_AR[back] if back < len(RELATIVE_AR) else ""
        rows.append(
            f"{day.isoformat()} | {WEEKDAYS_AR[day.weekday()]} | "
            f"{WEEKDAYS_EN[day.weekday()]} | {relative}".rstrip(" |")
        )
    return rows


def people_table(people: list[Person]) -> str:
    if not people:
        return "(none)"
    with_en = any(p.name_en for p in people)
    header = (
        "id | name | English name | relation" if with_en else "id | name | relation"
    )
    rows = [
        " | ".join(
            [p.id, p.name] + ([p.name_en or ""] if with_en else []) + [p.relation]
        )
        for p in people
    ]
    return "\n".join([header, *rows])


def question_language(question: str) -> str:
    """The answer language: English when the question has more Latin letters than Arabic
    ones, otherwise Egyptian Arabic (also for a tie or no letters: when unsure, Arabic)."""
    arabic = sum(1 for c in question if c.isalpha() and ARABIC_LETTERS.match(c))
    latin = sum(1 for c in question if c.isascii() and c.isalpha())
    return "English" if latin > arabic else "Egyptian Arabic"


def build_messages(
    question: str, asked_at: datetime, tz: str, people: list[Person]
) -> list[dict[str, str]]:
    now_local = asked_at.astimezone(ZoneInfo(tz))
    system = fill(
        load_prompt(),
        {
            "now_local": f"{now_local:%Y-%m-%d %H:%M}, {_weekday(now_local)}",
            "timezone": tz,
            "calendar": "\n".join(calendar_rows(now_local)),
            "people": people_table(people),
            "answer_language": question_language(question),
        },
    )
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": question},
    ]


def filters_set(plan: QueryPlan, asked_at: datetime) -> list[str]:
    """Names of the filters that narrow the plan. The window counts only when it is
    narrower than everything memory covers (MAX_LOOKBACK_DAYS up to asked_at)."""
    # in UTC, as planner.validate_args: a DST change inside the 90 days must not shift it
    asked_at = asked_at.astimezone(UTC)
    floor = asked_at - timedelta(days=MAX_LOOKBACK_DAYS)
    names = []
    if (plan.window_start is not None and plan.window_start > floor) or (
        plan.window_end is not None and plan.window_end < asked_at
    ):
        names.append("window")
    if plan.person_ids:
        names.append("person_ids")
    if plan.event_types:
        names.append("event_types")
    return names


NO_RESULTS_FILTERS = "Filters set: {names}. These filters may have hidden the answer."
NO_RESULTS_NO_FILTERS = "Filters set: none."
SEARCHES_LEFT = "Searches left: {n}."
FEWER_FILTERS = (
    "Search again with fewer filters before concluding that nothing is in memory."
)
OTHER_WORDS = (
    "Search again with other words before concluding that nothing is in memory."
)


def results_message(
    notes: list[str],
    results: list[Evidence],
    *,
    filters: Sequence[str] = (),
    searches_left: int = 0,
) -> str:
    lines = [f"notes: {', '.join(notes) if notes else 'none'}"]
    if results:
        lines += [
            f"{e.event_id} | {e.occurred_at} | {' '.join(e.text.split())[:MAX_EVIDENCE_TEXT]}"
            for e in results
        ]
        return "\n".join(lines)
    lines.append("(no results)")
    advice = [
        NO_RESULTS_FILTERS.format(names=", ".join(filters))
        if filters
        else NO_RESULTS_NO_FILTERS,
        SEARCHES_LEFT.format(n=searches_left),
    ]
    if searches_left > 0:
        advice.append(FEWER_FILTERS if filters else OTHER_WORDS)
    lines.append(" ".join(advice))
    return "\n".join(lines)


def _say(messages: list[dict[str, str]], text: str) -> None:
    """A user message; joined to the last one when that is already the user's."""
    if messages and messages[-1]["role"] == "user":
        messages[-1] = {
            "role": "user",
            "content": f"{messages[-1]['content']}\n\n{text}",
        }
    else:
        messages.append({"role": "user", "content": text})


FIRST_TURN_ANSWER = (
    "Search before answering. A broad search of the last days was run for you instead."
)
FALLBACK_SEARCH = "Your last reply could not be used. A broad search was run instead."
ANSWER_NOW = "No more searches. Answer now, from the results above only."


# ----- the loop -----


async def run_assist(
    llm: LLM,
    backend: SearchBackend,
    *,
    question: str,
    asked_at: datetime,
    tz: str,
    people: list[Person],
    max_searches: int = 3,
    search_budget_s: float = SEARCH_BUDGET_S,
    plan_only: bool = False,
) -> AssistResult:
    fallback = fallback_plan(
        question, asked_at, tz
    )  # ValueError: naive asked_at, bad tz
    began = monotonic()
    budget_end = began + search_budget_s
    messages = build_messages(question, asked_at, tz, people)
    allowed = [p.id for p in people]
    trace: list[Step] = []
    seen: list[str] = []  # result ids the model has seen

    def remaining() -> float:
        return budget_end - monotonic()

    def can_search() -> bool:
        return remaining() >= ANSWER_RESERVE_S + SEARCH_TURN_S

    # model-chosen searches still allowed (0 = the answer-only turn is next); the
    # no-results message tells the model this number
    searches_left = max_searches if can_search() else 0

    def reply(raw: str, *, final: bool) -> _Turn:
        messages.append({"role": "assistant", "content": raw})
        return _parse_turn(raw, final=final)

    async def ask_search() -> _Turn:
        # cut so that the answer-only turn keeps its reserve
        raw = await asyncio.wait_for(
            asyncio.to_thread(llm.complete, list(messages), action_schema(final=False)),
            remaining() - ANSWER_RESERVE_S,
        )
        return reply(raw, final=False)

    async def ask_answer() -> _Turn:
        # never cut by the budget: waits for the LLM client's own timeout
        raw = await asyncio.to_thread(
            llm.complete, list(messages), action_schema(final=True)
        )
        return reply(raw, final=True)

    async def search(
        plan: QueryPlan,
        notes: list[str],
        started: float,
        *,
        is_fallback: bool,
        last: bool = False,
    ) -> None:
        nonlocal searches_left
        try:
            results = list(await backend.search(plan))[:TOP_K]
        except Exception as exc:
            raise _BackendFailed from exc
        for e in results:
            if e.event_id not in seen:
                seen.append(e.event_id)
        trace.append(
            Step(
                plan,
                tuple(notes),
                len(results),
                monotonic() - started,
                is_fallback,
            )
        )
        searches_left = 0 if last or not can_search() else max_searches - len(trace)
        _say(
            messages,
            results_message(
                notes,
                results,
                filters=filters_set(plan, asked_at),
                searches_left=searches_left,
            ),
        )

    def result(
        answer: str | None, used: list[str], steps: list[Step], *, failed: bool = False
    ) -> AssistResult:
        seconds = monotonic() - began
        return AssistResult(
            answer, used, steps, failed, seconds, seconds > search_budget_s
        )

    def done(turn: _Turn) -> AssistResult:
        used = [i for i in dict.fromkeys(turn.used_event_ids) if i in seen]
        return result(turn.answer.strip(), used, trace)

    def degraded() -> AssistResult:
        return result(None, [], trace, failed=True)

    def planned(plan: QueryPlan, notes: list[str], started: float, fb: bool):
        step = Step(plan, tuple(notes), 0, monotonic() - started, fb)
        return result(None, [], [step])

    async def answer_turn() -> AssistResult:
        """The answer-only turn; retried once after a TransientError or LLMError."""
        for attempt in range(2):
            try:
                return done(await ask_answer())
            except (TransientError, LLMError):
                if attempt:
                    break
            except Exception:  # noqa: BLE001 - an unusable reply is not retried
                break
        return degraded()

    fell_back = failed = False
    try:
        # searches chosen by the model, until max_searches or the budget is short
        while searches_left > 0:
            started = monotonic()
            try:
                turn = await ask_search()
            except Exception:  # noqa: BLE001 - any LLM failure: never raised to the caller
                failed = True
                break
            if turn.action == "answer":
                if trace:
                    return done(turn)
                if plan_only:
                    return planned(fallback, [], started, True)
                _say(messages, FIRST_TURN_ANSWER)
                await search(fallback, [], started, is_fallback=True)
                fell_back = True
                continue
            plan, notes = validate_args(
                turn.search,
                asked_at=asked_at,
                tz=tz,
                allowed_person_ids=allowed,
                question=question,
            )
            if plan_only:
                return planned(plan, notes, started, False)
            await search(plan, notes, started, is_fallback=False)

        # after a failure, or when no search ran at all: one fallback search
        if (failed and not fell_back) or not trace:
            started = monotonic()
            if plan_only:
                return planned(fallback, [], started, True)
            if failed:
                _say(messages, FALLBACK_SEARCH)
            await search(fallback, [], started, is_fallback=True, last=True)

        _say(messages, ANSWER_NOW)
        return await answer_turn()
    except _BackendFailed:
        return degraded()
