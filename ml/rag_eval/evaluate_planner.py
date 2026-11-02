"""Evaluate the /assist loop (track R3) on the dev benchmark with the REAL LLM. Manual only:
never run by CI (it costs money and needs the key). Synthetic data only.

    cd backend-ai
    AI_PROFILE=production .venv/Scripts/python ../ml/rag_eval/evaluate_planner.py
    ... --mode full --runs 1
    ... --slot llm                      # the general LLM instead of assist_llm (default)
    ... --model gemini-2.5-flash        # override, for this process only (no config change)
    ... --prompt assist_agent.v1        # prompt file to evaluate (default: ASSIST_PROMPT)
    ... --out C:/somewhere/outside/the/repo/run.json

Refuses to run when AI_PROFILE=stub (or the LLM is the fake). Only the LLM is built, so the
other providers' keys are not needed. The key is never printed. --slot assist (default)
builds the registry's assist_llm, as /assist does (AI_ASSIST_LLM overrides it); --model
then only swaps the Gemini model in the URL, the slot's other settings (thinking) stay.

--mode plan (default): run_assist(plan_only=True), the first validated search plan per run.
  valid        the model's own plan (no fallback needed)
  correct      every evidence event passes the plan's filters: window half-open
               [start, end) on occurred_at (same as the SQL in R4), person_ids intersect the
               event's people when non-empty, event_types when given. Vacuous ("-") for
               questions without evidence. Not scored ("-") for false-premise questions:
               the first narrow search is the right plan there; widening it is a
               second-search behaviour, measured in full mode.
  person       plan person_ids == expected_plan person_ids (as sets)
  selectivity  how many of the 19 events pass the plan (fewer = narrower)
--mode full: the whole loop over a small in-memory backend (filter by plan, rank by token
  overlap with the rendered sentence, TOP_K). Prints answer, used_event_ids, searches and
  seconds, plus auto-checks; whether the answer is right is read by a human.
  Like app/ai/rag/retriever.py it always returns the top results that pass the filters (no
  relevance threshold) and runs the premise check (D39): an empty search with person_ids
  and a window returns each person's last presence, marked OUTSIDE_WINDOW. It has no memory
  structures (no "[...]" lines): the synthetic days are not consolidated here.
  --person-filter off: the backend ignores person_ids (the model still sends them), which
  also turns the premise check off, since that needs the person filter.
  --budget: run_assist's search_budget_s (soft; loops over it are reported, not failures).
"""

import argparse
import asyncio
import json
import re
import statistics
import sys
import time
from collections import defaultdict
from pathlib import Path
from zoneinfo import ZoneInfo

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path[:0] = [str(HERE), str(REPO / "backend-ai")]
from evaluate_smoke import (
    BENCHMARK_FILE,
    DAYS_FILE,
    load_events,
    local,
    render,
)

import app.ai.clients.llm as llm_client
from app.ai.rag.assist_loop import (
    ASSIST_PROMPT,
    SEARCH_BUDGET_S,
    TOP_K,
    Evidence,
    Person,
    run_assist,
)
from app.ai.rag.planner import QueryPlan
from app.ai.rag.retriever import OUTSIDE_WINDOW
from app.ai.registry import PROVIDERS, choose_providers, overrides_from_settings
from app.config import settings

MAX_FAILS_IN_A_ROW = 3


class AbortRun(Exception):
    pass


# ----- the LLM, timed -----


class TimedLLM:
    """Wraps the real LLM: seconds per call, error class names, consecutive failures.

    Each call is tagged with the run that made it: a search-turn call the loop cuts at its
    budget keeps running in its thread and finishes later, and must not count for the next
    run."""

    def __init__(self, inner):
        self.inner = inner
        self.model_id = inner.model_id
        self.run: tuple | None = None
        self.calls: list[dict] = []  # {"run": ..., "seconds": None while still running}
        self.errors: list[str] = []
        self.fails_in_a_row = 0

    def seconds(self, run: tuple) -> list[float | None]:
        return [c["seconds"] for c in self.calls if c["run"] == run]

    def complete(self, messages, json_schema=None):
        started = time.perf_counter()
        call = {"run": self.run, "seconds": None}
        self.calls.append(call)
        try:
            reply = self.inner.complete(messages, json_schema)
        except Exception as exc:
            self.fails_in_a_row += 1
            self.errors.append(f"{type(exc).__name__}: {str(exc)[:200]}")
            raise
        finally:
            call["seconds"] = time.perf_counter() - started
        self.fails_in_a_row = 0
        return reply


def build_llm(model: str | None, slot: str = "assist"):
    """slot "assist": the registry's assist_llm (what /assist runs); "llm": the general LLM."""
    if settings.ai_profile == "stub":
        sys.exit("Refusing to run: AI_PROFILE=stub. Set AI_PROFILE=production.")
    capability = "assist_llm" if slot == "assist" else "llm"
    provider = choose_providers(settings.ai_profile, overrides_from_settings())[
        capability
    ]
    if provider == "fake":
        sys.exit("Refusing to run: the LLM provider is the fake.")
    llm = PROVIDERS[capability][provider]()
    label = f"{llm.model_id} (slot {capability}: {provider})"
    if model:
        # for this process only: generate() reads the module's GEMINI_URL at call time
        llm_client.GEMINI_URL = llm_client.GEMINI_URL.replace(
            f"/models/{llm_client.MODEL}:", f"/models/{model}:"
        )
        llm.model_id = model
        label = f"{model} (override; slot {capability}: {provider})"
    return llm, label


# ----- plans against the synthetic days -----


def passes(e: dict, plan) -> bool:
    t = e["start"]
    if plan.window_start is not None and t < plan.window_start:
        return False
    if plan.window_end is not None and t >= plan.window_end:
        return False
    if plan.person_ids and not set(plan.person_ids) & set(e["person_ids"]):
        return False
    return not (plan.event_types and e["event_type"] not in plan.event_types)


def plan_text(plan, tz) -> str:
    def lt(dt):
        return dt.astimezone(tz).strftime("%m-%d %H:%M") if dt else "-"

    return (
        f"{lt(plan.window_start)} -> {lt(plan.window_end)}, people {plan.person_ids}, "
        f"types {plan.event_types}, text {plan.search_text!r}"
    )


# ----- the in-memory backend (full mode) -----

DIACRITICS = re.compile("[\u064b-\u0652\u0670]")
FOLD = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ة": "ه", "ى": "ي"})


def tokens(text: str) -> set[str]:
    words = re.findall(r"\w+", DIACRITICS.sub("", text).translate(FOLD).lower())
    out = set()
    for w in words:
        if w.startswith("ال") and len(w) > 4:
            w = w[2:]
        if len(w) > 1:
            out.add(w)
    return out


class MemoryBackend:
    def __init__(self, events: dict, sentences: dict, person_filter: str = "hard"):
        self.events = events
        self.sentences = sentences
        self.person_filter = person_filter
        self.returned: set[str] = set()
        self.premise_found: list[str] = []  # ids the premise check returned

    def _evidence(self, e: dict, line: str | None = None) -> Evidence:
        text = self.sentences[e["id"]]
        return Evidence(
            e["id"],
            e["start"].strftime("%Y-%m-%d %H:%M"),
            f"[{line}] {text}" if line else text,
        )

    async def search(self, plan) -> list[Evidence]:
        if self.person_filter == "off":
            plan = plan.model_copy(update={"person_ids": []})
        wanted = tokens(plan.search_text)
        hits = [e for e in self.events.values() if passes(e, plan)]
        hits.sort(
            key=lambda e: (-len(wanted & tokens(self.sentences[e["id"]])), e["start"])
        )
        found = [self._evidence(e) for e in hits[:TOP_K]]
        # as retriever.MemorySearch.search_now (lines 117-118)
        if not found and plan.person_ids and (plan.window_start or plan.window_end):
            found = self._premise(plan)
            self.premise_found += [ev.event_id for ev in found]
        self.returned |= {ev.event_id for ev in found}
        return found

    def _premise(self, plan) -> list[Evidence]:
        """retriever.MemorySearch._premise (lines 121-138): each person's newest presence
        outside the window, with the same event types."""
        found, seen = [], set()
        for person in plan.person_ids:
            outside = QueryPlan(
                window_start=None,
                window_end=plan.window_end if plan.window_start is None else None,
                person_ids=[person],
                event_types=plan.event_types,
                search_text="",
            )
            newest = sorted(
                (e for e in self.events.values() if passes(e, outside)),
                key=lambda e: e["start"],
                reverse=True,
            )
            for e in newest[:1]:
                if e["id"] not in seen:
                    seen.add(e["id"])
                    found.append(self._evidence(e, OUTSIDE_WINDOW))
        return found


# ----- stats -----


def pct(values: list[bool]) -> str:
    return f"{100 * sum(values) / len(values):.0f}%" if values else "-"


def p(values: list[float], q: float) -> str:
    if not values:
        return "-"
    if len(values) == 1:
        return f"{values[0]:.2f}"
    cuts = statistics.quantiles(values, n=100, method="inclusive")
    return f"{cuts[int(q * 100) - 1]:.2f}"


NOT_SCORED_REASON = (
    "the first narrow search (e.g. 'today') is the right plan; widening is a "
    "second-search behaviour, measured in full mode"
)


def summary(rows: list[dict], mode: str) -> None:
    groups = defaultdict(list)
    for r in rows:
        groups["overall"].append(r)
        groups[r["category"]].append(r)
    print(f"\n## Summary ({mode})")
    head = "| group | runs | correct | person match | mean selectivity | fallback | degraded"
    print(head + " | LLM call p50 / p95 s | loop p50 / p95 s |")
    print("|---|---|---|---|---|---|---|---|---|")
    for name, rs in groups.items():
        correct = [r["correct"] for r in rs if r["correct"] is not None]
        person = [r["person_match"] for r in rs]
        sel = [r["selectivity"] for r in rs]
        calls = [s for r in rs for s in r["llm_seconds"]]
        loops = [r["loop_seconds"] for r in rs]
        print(
            f"| {name} | {len(rs)} | {pct(correct)} | {pct(person)} | "
            f"{statistics.mean(sel):.1f} | {pct([r['fallback'] for r in rs])} | "
            f"{sum(r['degraded'] for r in rs)} | {p(calls, 0.5)} / {p(calls, 0.95)} | "
            f"{p(loops, 0.5)} / {p(loops, 0.95)} |"
        )
    unscored = sorted({r["id"] for r in rows if r["not_scored"]})
    if unscored:
        print(
            f"\ncorrect not scored for false-premise {', '.join(unscored)}: "
            f"{NOT_SCORED_REASON}."
        )


# ----- main -----


async def evaluate(args) -> int:
    days = json.loads(DAYS_FILE.read_text(encoding="utf-8"))
    bench = json.loads(BENCHMARK_FILE.read_text(encoding="utf-8"))
    tz_name = days["timezone"]
    tz = ZoneInfo(tz_name)
    events, people_refs = load_events(days, tz)
    lang = days["patient"]["language"]
    sentences = {
        eid: render(e, lang, people_refs, tz_name) for eid, e in events.items()
    }
    people = [Person(p["id"], p["name"], p["relationship"]) for p in days["people"]]

    real, label = build_llm(args.model, args.slot)
    llm = TimedLLM(real)
    print(
        f"Model: {label}   prompt: {args.prompt}   mode: {args.mode}   "
        f"runs: {args.runs}   events: {len(events)}   "
        f"person filter: {args.person_filter}   budget: {args.budget:g} s"
    )

    questions = [q for q in bench["questions"] if q["split"] == "dev"]
    rows = []
    for q in questions:
        asked_at = local(q["asked_at"], tz)
        question = q["question_ar"] if q["language"] == "ar" else q["question_en"]
        evidence = q["evidence_event_ids"]
        expected_people = set(q["expected_plan"]["person_ids"])
        print(f"\n### {q['id']} {q['category']} [{q['language']}] {question}")
        print(f"evidence {evidence or 'none'}")
        for n in range(1, args.runs + 1):
            backend = MemoryBackend(events, sentences, args.person_filter)
            llm.run = (q["id"], n)
            started = time.perf_counter()
            result = await run_assist(
                llm,
                backend,
                question=question,
                asked_at=asked_at,
                tz=tz_name,
                people=people,
                search_budget_s=args.budget,
                plan_only=args.mode == "plan",
                prompt_name=args.prompt,
            )
            loop_seconds = time.perf_counter() - started
            if llm.fails_in_a_row >= MAX_FAILS_IN_A_ROW:
                raise AbortRun(llm.errors[-MAX_FAILS_IN_A_ROW:])

            first = result.trace[0] if result.trace else None
            plan = first.plan if first else None
            passing = [e for e in events.values() if plan and passes(e, plan)]
            passing_ids = {e["id"] for e in passing}
            not_scored = args.mode == "plan" and q["false_premise"]
            row = {
                "id": q["id"],
                "category": q["category"],
                "run": n,
                "false_premise": q["false_premise"],
                "has_evidence": bool(evidence),
                "not_scored": not_scored,
                "valid": bool(first and not first.fallback),
                "correct": (
                    (set(evidence) <= passing_ids)
                    if evidence and not not_scored
                    else None
                ),
                "person_match": bool(plan) and set(plan.person_ids) == expected_people,
                "selectivity": len(passing),
                "notes": list(first.notes) if first else [],
                "fallback": any(s.fallback for s in result.trace),
                "degraded": result.degraded,
                "over_budget": result.over_budget,
                "llm_seconds": [],  # filled in before the summary
                "loop_seconds": loop_seconds,
                "plan": plan.model_dump(mode="json") if plan else None,
            }
            # the smoke check also requires an event's END inside the window
            row["span_crosses_end"] = [
                eid
                for eid in evidence
                if eid in passing_ids
                and plan.window_end is not None
                and events[eid]["end"] > plan.window_end
            ]
            correct = (
                "- (false premise, not scored)"
                if not_scored
                else "-"
                if row["correct"] is None
                else ("yes" if row["correct"] else "NO")
            )
            print(
                f"run {n}: valid {'yes' if row['valid'] else 'NO'} | correct {correct} | "
                f"person {'yes' if row['person_match'] else 'NO'} | "
                f"selectivity {row['selectivity']}/{len(events)} | "
                f"notes {row['notes'] or '-'} | "
                "llm "
                + ", ".join(
                    "running" if s is None else f"{s:.2f}" for s in llm.seconds(llm.run)
                )
                + " s"
            )
            if plan:
                print(f"       plan: {plan_text(plan, tz)}")
            if row["span_crosses_end"]:
                print(f"       span crosses window end: {row['span_crosses_end']}")
            if args.mode == "full":
                used = result.used_event_ids
                row |= {
                    "answer": result.answer,
                    "used_event_ids": used,
                    "searches": len(result.trace),
                    "searches_found_all_evidence": set(evidence) <= backend.returned,
                    "used_cover_evidence": set(evidence) <= set(used),
                    "cites_nothing": not used,
                    "premise_found": backend.premise_found,
                    # a fallback after a model search: that search turn was cut by the
                    # budget or its reply was unusable
                    "turns_cut": sum(s.fallback for s in result.trace[1:]),
                    "plans": [
                        (s.plan.model_dump(mode="json"), list(s.notes), s.n_results)
                        for s in result.trace
                    ],
                }
                for i, s in enumerate(result.trace, start=1):
                    print(
                        f"       search {i}{' (fallback)' if s.fallback else ''}: "
                        f"{plan_text(s.plan, tz)} notes {list(s.notes) or '-'} "
                        f"-> {s.n_results}"
                    )
                if backend.premise_found:
                    print(f"       premise check returned {backend.premise_found}")
                print(f"       answer: {result.answer!r}  degraded {result.degraded}")
                print(
                    f"       used {used} | searches {row['searches']} | "
                    f"total {loop_seconds:.2f} s"
                    + (" (over budget)" if result.over_budget else "")
                )
                if evidence:
                    print(
                        f"       searches found all evidence: "
                        f"{'yes' if row['searches_found_all_evidence'] else 'NO'} | "
                        f"used cover evidence: "
                        f"{'yes' if row['used_cover_evidence'] else 'NO'}"
                    )
                    if q["false_premise"]:
                        for eid in evidence:
                            found = "yes" if eid in backend.returned else "NO"
                            print(
                                f"       false premise: searches found {eid}: {found}"
                            )
                else:
                    print(
                        f"       evidence-less, cites nothing: "
                        f"{'yes' if row['cites_nothing'] else 'NO'}"
                    )
            rows.append(row)

    running = 0
    for row in rows:
        times = llm.seconds((row["id"], row["run"]))
        running += times.count(None)
        row["llm_seconds"] = [t for t in times if t is not None]
    summary(rows, args.mode)
    over = [r["over_budget"] for r in rows]
    print(
        f"\nLLM calls: {len(llm.calls)}, still running at the summary (not in the latency "
        f"columns): {running}"
    )
    print(
        f"loops over budget ({args.budget:g} s, soft: still answered, not a "
        f"failure): {sum(over)} of {len(over)} ({pct(over)})"
    )
    if args.mode == "full":
        with_ev = [r for r in rows if r["has_evidence"]]
        without = [r for r in rows if not r["has_evidence"]]
        print(
            f"\nsearches found all evidence {pct([r['searches_found_all_evidence'] for r in with_ev])}"
            f" | used cover evidence {pct([r['used_cover_evidence'] for r in with_ev])}"
            f" | evidence-less cite nothing {pct([r['cites_nothing'] for r in without])}"
        )
        print(
            f"search turns cut or unusable (fallback after a model search): "
            f"{sum(r['turns_cut'] for r in rows)} in "
            f"{sum(r['turns_cut'] > 0 for r in rows)} runs | premise check fired in "
            f"{sum(bool(r['premise_found']) for r in rows)} runs"
        )
        print("\n## Answers (full)")
        print("| id | run | searches | found all evidence | used_event_ids | answer |")
        print("|---|---|---|---|---|---|")
        for r in rows:
            found = (
                ("yes" if r["searches_found_all_evidence"] else "NO")
                if r["has_evidence"]
                else "-"
            )
            answer = "(degraded)" if r["answer"] is None else r["answer"]
            print(
                f"| {r['id']} | {r['run']} | {r['searches']} | {found} | "
                f"{r['used_event_ids']} | {answer} |"
            )
    if llm.errors:
        print(f"\nLLM errors ({len(llm.errors)}):")
        for message in dict.fromkeys(llm.errors):
            print(f"  - {message}")
    if args.out:
        args.out.write_text(
            json.dumps(
                {
                    "model": label,
                    "slot": args.slot,
                    "prompt": args.prompt,
                    "mode": args.mode,
                    "person_filter": args.person_filter,
                    "budget": args.budget,
                    "rows": rows,
                },
                indent=1,
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        print(f"\nwrote {args.out}")
    return 0


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--mode", choices=("plan", "full"), default="plan")
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument(
        "--slot",
        choices=("assist", "llm"),
        default="assist",
        help="assist: the registry's assist_llm, what /assist runs (default); llm: the "
        "general LLM",
    )
    parser.add_argument("--model", help="override the Gemini model for this run only")
    parser.add_argument(
        "--prompt", default=ASSIST_PROMPT, help="prompt file name in app/ai/prompts"
    )
    parser.add_argument(
        "--person-filter",
        choices=("hard", "off"),
        default="hard",
        help="off: the in-memory backend ignores person_ids (no premise check either)",
    )
    parser.add_argument(
        "--budget",
        type=float,
        default=SEARCH_BUDGET_S,
        help="run_assist search_budget_s (soft)",
    )
    parser.add_argument("--out", type=Path, help="JSON dump, outside the repo")
    args = parser.parse_args()
    if args.out is not None:
        args.out = args.out.resolve()
        if args.out.is_relative_to(REPO):
            sys.exit("Refusing to write --out inside the repository.")
    try:
        return asyncio.run(evaluate(args))
    except AbortRun as exc:
        print(f"\nSTOPPED: the LLM failed {MAX_FAILS_IN_A_ROW} times in a row:")
        for message in exc.args[0]:
            print(f"  - {message}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
