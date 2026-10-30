"""The /assist agent: a bounded search-then-answer loop over the patient's memories (track R3).

Provider-neutral: no native tool calling. Every turn the model returns one JSON object
(`action_schema`): either a search (RawSearchArgs) or an answer with the ids of the results
it used. Code drives the loop:

- turn 1 is always a search; an answer on turn 1 is ignored and fallback_plan is searched;
- every search goes through planner.validate_args, and its note codes go back to the model
  with the results ("id | local time | text");
- after max_searches, or when the deadline is near, one answer-only turn (`final=True`);
- any LLM failure (exception, timeout, bad JSON, wrong shape): one fallback search (if none
  ran yet), then one answer-only turn; if that fails too, the result is degraded with no
  answer. A failing search backend also ends degraded. Nothing is raised to the caller
  except ValueError for a naive asked_at or an unknown timezone (programming errors);
- used_event_ids not among the results the model saw are dropped.

The retriever (SearchBackend) comes in R4. Privacy: nothing here is logged; the trace is
returned in memory only and holds no question or result text.
"""

import asyncio
import json
import re
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from functools import cache
from pathlib import Path
from typing import Literal, Protocol
from zoneinfo import ZoneInfo

from pydantic import BaseModel, ConfigDict

from app.ai.interfaces import LLM
from app.ai.rag.planner import (
    QueryPlan,
    RawSearchArgs,
    fallback_plan,
    search_args_schema,
    validate_args,
)

PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"
ASSIST_PROMPT = "assist_agent.v1"

TOP_K = 8  # results per search the model sees
MAX_EVIDENCE_TEXT = 400  # characters of one result's text
ANSWER_RESERVE_S = 4.0  # DRAFT: seconds kept for the answer-only turn
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
    answer: str | None
    used_event_ids: list[str]
    trace: list[Step] = field(default_factory=list)
    degraded: bool = False


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
        },
    )
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": question},
    ]


def results_message(notes: list[str], results: list[Evidence]) -> str:
    lines = [f"notes: {', '.join(notes) if notes else 'none'}"]
    if results:
        lines += [
            f"{e.event_id} | {e.occurred_at} | {' '.join(e.text.split())[:MAX_EVIDENCE_TEXT]}"
            for e in results
        ]
    else:
        lines.append("(no results)")
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
    deadline_s: float = 12.0,
    plan_only: bool = False,
) -> AssistResult:
    fallback = fallback_plan(
        question, asked_at, tz
    )  # ValueError: naive asked_at, bad tz
    deadline = time.monotonic() + deadline_s
    messages = build_messages(question, asked_at, tz, people)
    allowed = [p.id for p in people]
    trace: list[Step] = []
    seen: list[str] = []  # result ids the model has seen

    async def ask(*, final: bool) -> _Turn:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError
        raw = await asyncio.wait_for(
            asyncio.to_thread(llm.complete, list(messages), action_schema(final=final)),
            remaining,
        )
        messages.append({"role": "assistant", "content": raw})
        return _parse_turn(raw, final=final)

    async def search(
        plan: QueryPlan, notes: list[str], started: float, *, is_fallback: bool
    ) -> None:
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
                time.monotonic() - started,
                is_fallback,
            )
        )
        _say(messages, results_message(notes, results))

    def done(turn: _Turn) -> AssistResult:
        used = [i for i in dict.fromkeys(turn.used_event_ids) if i in seen]
        return AssistResult(turn.answer.strip(), used, trace)

    def degraded() -> AssistResult:
        return AssistResult(None, [], trace, degraded=True)

    def planned(plan: QueryPlan, notes: list[str], started: float, fb: bool):
        step = Step(plan, tuple(notes), 0, time.monotonic() - started, fb)
        return AssistResult(None, [], [step])

    fell_back = failed = False
    try:
        # searches chosen by the model, until max_searches or the deadline is near
        while len(trace) < max_searches:
            if deadline - time.monotonic() < ANSWER_RESERVE_S:
                break
            started = time.monotonic()
            try:
                turn = await ask(final=False)
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
            started = time.monotonic()
            if plan_only:
                return planned(fallback, [], started, True)
            if failed:
                _say(messages, FALLBACK_SEARCH)
            await search(fallback, [], started, is_fallback=True)

        _say(messages, ANSWER_NOW)
        try:
            return done(await ask(final=True))
        except Exception:  # noqa: BLE001 - same: the answer turn degrades
            return degraded()
    except _BackendFailed:
        return degraded()
