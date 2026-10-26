"""Which LLM extracts memory best? Facts, intentions, settlements, entities (phase 7.5, spec D40).

Runs the backend's real extraction (prompts memory_extract.v1 / memory_settle.v1 and the
validation in app/ai/memory/extract.py) with several models on a synthetic test set with gold
labels (data/extraction_testset.json: fictional people, generated text), and scores them.

    cd backend-ai
    .venv/Scripts/python ../ml/rag_eval/extraction_eval.py                 # default models
    .venv/Scripts/python ../ml/rag_eval/extraction_eval.py groq:qwen/qwen3.8-27b gemini

Models: `groq:<model id>` (GROQ_API_KEY) or `gemini` (GEMINI_API_KEY, the backend client).
Keys come from backend-ai/.env. Synthetic data only, so free tiers are fine here.
Predictions are saved outside the repo (~/.cache/remori/extraction_eval) for inspection.

Scoring (per model, over all 15 conversations):
- facts / intentions: a prediction matches a gold item in the same segment when one quote
  contains the other or they share at least half their words; precision, recall, F1.
- values: kind + value of the values of matched facts (dates and times exact).
- due: of matched intentions with a gold due time, how many have the same local date / time.
- settles: given the gold open plans of earlier conversations, plan + status must match.
- dropped: items the model returned that validation threw away (quote not verbatim, etc.).
- entities: loose (names vary), normalized name + kind.
"""

import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import httpx

BACKEND = Path(__file__).resolve().parents[2] / "backend-ai"
sys.path.insert(0, str(BACKEND))
from app.ai.clients.llm import GeminiLLM
from app.ai.memory import extract
from app.config import settings
from app.errors import TransientError

TESTSET = Path(__file__).resolve().parent / "data" / "extraction_testset.json"
OUT = Path.home() / ".cache" / "remori" / "extraction_eval"
CAIRO = ZoneInfo("Africa/Cairo")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
DEFAULT_MODELS = ["groq:qwen/qwen3.8-27b", "groq:openai/gpt-oss-120b", "gemini"]

THINK = re.compile(r"<think>.*?</think>", re.DOTALL)
DIACRITICS = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")


# ----- models -----


class GroqLLM:
    """Temporary eval client (the production one comes with its own PR)."""

    def __init__(self, model: str):
        self.model_id = f"groq/{model}"
        self.model = model
        self.key = groq_key()
        self.json_schema_ok = True

    def complete(self, messages, json_schema=None):
        body = {"model": self.model, "messages": messages, "temperature": 0}
        if json_schema is not None and self.json_schema_ok:
            body["response_format"] = {
                "type": "json_schema",
                "json_schema": {"name": "memory", "schema": json_schema},
            }
        elif json_schema is not None:
            # best effort: JSON mode, with the schema spelled out in the prompt
            body["response_format"] = {"type": "json_object"}
            body["messages"] = [
                *messages[:-1],
                {
                    "role": "system",
                    "content": "Answer with one JSON object following this JSON schema:\n"
                    + json.dumps(json_schema),
                },
                messages[-1],
            ]
        response = httpx.post(
            GROQ_URL,
            headers={"Authorization": f"Bearer {self.key}"},
            json=body,
            timeout=120,
        )
        schema_refused = (
            "response_format" in response.text or "json_schema" in response.text
        )
        if (
            response.status_code == 400
            and self.json_schema_ok
            and json_schema
            and schema_refused
        ):
            self.json_schema_ok = False
            return self.complete(messages, json_schema)
        if response.status_code == 429 or response.status_code >= 500:
            wait = float(response.headers.get("retry-after", "10") or 10)
            raise TransientError(f"groq {response.status_code}, retry after {wait}s")
        if response.status_code >= 400:
            raise RuntimeError(f"groq {response.status_code}: {response.text[:300]}")
        content = response.json()["choices"][0]["message"].get("content") or ""
        return json_only(content)


def json_only(text: str) -> str:
    """Drop reasoning blocks and anything around the JSON object."""
    text = THINK.sub("", text)
    start, end = text.find("{"), text.rfind("}")
    return text[start : end + 1] if start != -1 and end > start else text


def groq_key() -> str:
    for line in (BACKEND / ".env").read_text(encoding="utf-8").splitlines():
        if line.startswith("GROQ_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("GROQ_API_KEY is not set in backend-ai/.env")


def build(name: str):
    if name == "gemini":
        if not settings.gemini_api_key:
            raise SystemExit("GEMINI_API_KEY is not set in backend-ai/.env")
        return GeminiLLM()
    if name.startswith("groq:"):
        return GroqLLM(name.split(":", 1)[1])
    raise SystemExit(f"unknown model {name!r}: use groq:<model> or gemini")


def call(llm, messages, schema) -> tuple[str, float]:
    for attempt in range(6):
        started = time.perf_counter()
        try:
            return llm.complete(messages, schema), time.perf_counter() - started
        except TransientError as exc:
            match = re.search(r"after ([\d.]+)s", str(exc))
            time.sleep(float(match.group(1)) if match else 5 * (attempt + 1))
    raise RuntimeError("still rate-limited after 6 tries")


# ----- matching -----


def norm(text: str) -> str:
    text = DIACRITICS.sub("", text or "")
    text = re.sub("[أإآٱ]", "ا", text).replace("ى", "ي").replace("ة", "ه")
    return " ".join(re.sub(r"[^\w\s]", " ", text.casefold()).split())


def same_quote(a: str, b: str) -> bool:
    a, b = norm(a), norm(b)
    if not a or not b:
        return False
    if a in b or b in a:
        return True
    wa, wb = set(a.split()), set(b.split())
    return len(wa & wb) / len(wa | wb) >= 0.5


def pair(gold: list, pred: list, key) -> list[tuple[int, int]]:
    """Greedy one-to-one matches (gold index, pred index)."""
    used, pairs = set(), []
    for gi, g in enumerate(gold):
        for pi, p in enumerate(pred):
            if pi not in used and key(g, p):
                used.add(pi)
                pairs.append((gi, pi))
                break
    return pairs


def value_key(v: dict) -> tuple:
    value = v.get("value")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        value = round(float(value), 3)
    return (v.get("kind"), str(value))


def local(dt) -> str | None:
    return dt.astimezone(CAIRO).strftime("%Y-%m-%dT%H:%M") if dt else None


def raw_count(raw: str, key: str) -> int:
    try:
        items = json.loads(raw).get(key)
    except (ValueError, AttributeError):
        return 0
    return len(items) if isinstance(items, list) else 0


# ----- one model over the whole set -----


def evaluate(name: str, data: dict) -> dict:
    llm = build(name)
    s = {
        k: 0
        for k in (
            "fact_tp",
            "fact_fp",
            "fact_fn",
            "val_tp",
            "val_fp",
            "val_fn",
            "int_tp",
            "int_fp",
            "int_fn",
            "holder_ok",
            "due_gold",
            "due_date_ok",
            "due_exact_ok",
            "set_tp",
            "set_fp",
            "set_fn",
            "ent_tp",
            "ent_fp",
            "ent_fn",
            "raw_items",
            "dropped",
            "errors",
            "calls",
        )
    }
    latencies, saved = [], []

    for scenario in data["scenarios"]:
        open_plans: list[
            tuple[str, dict, str]
        ] = []  # (conversation id, gold, local time)
        for conv in scenario["conversations"]:
            gold = conv["gold"]
            segments = [
                extract.Segment(seg["index"], 0.0, seg.get("speaker"), seg["text"])
                for seg in sorted(conv["segments"], key=lambda x: x["index"])
            ]
            now_local = datetime.fromisoformat(conv["local_datetime"]).replace(
                tzinfo=CAIRO
            )
            record = {"id": conv["id"]}

            # extraction
            try:
                raw, seconds = call(
                    llm,
                    extract.extract_messages(segments, now_local),
                    extract.EXTRACT_SCHEMA,
                )
                s["calls"] += 1
                latencies.append(seconds)
                found = extract.parse_extraction(raw, segments, CAIRO)
            except Exception as exc:  # noqa: BLE001  a broken answer counts as finding nothing
                s["errors"] += 1
                record["error"] = f"{type(exc).__name__}: {str(exc)[:200]}"
                raw, found = "{}", extract.Extraction([], [], [])
            record["raw"] = raw
            kept = len(found.facts) + len(found.intentions)
            returned = raw_count(raw, "facts") + raw_count(raw, "intentions")
            s["raw_items"] += returned
            s["dropped"] += max(returned - kept, 0)

            # facts and their values
            gf = gold.get("facts", [])
            pairs = pair(
                gf,
                found.facts,
                lambda g, p: (
                    g["segment_index"] == p.segment.index
                    and same_quote(g["quote"], p.quote)
                ),
            )
            s["fact_tp"] += len(pairs)
            s["fact_fp"] += len(found.facts) - len(pairs)
            s["fact_fn"] += len(gf) - len(pairs)
            matched_gold = {gi for gi, _ in pairs}
            for gi, pi in pairs:
                gv = [value_key(v) for v in gf[gi].get("values", [])]
                pv = [value_key(v) for v in found.facts[pi].values]
                hits = sum(min(gv.count(k), pv.count(k)) for k in set(gv))
                s["val_tp"] += hits
                s["val_fp"] += len(pv) - hits
                s["val_fn"] += len(gv) - hits
            for gi, g in enumerate(gf):  # values of missed facts are missed too
                if gi not in matched_gold:
                    s["val_fn"] += len(g.get("values", []))

            # intentions, holder, due time
            gi_list = gold.get("intentions", [])
            pairs = pair(
                gi_list,
                found.intentions,
                lambda g, p: (
                    g["segment_index"] == p.segment.index
                    and same_quote(g["quote"], p.quote)
                ),
            )
            s["int_tp"] += len(pairs)
            s["int_fp"] += len(found.intentions) - len(pairs)
            s["int_fn"] += len(gi_list) - len(pairs)
            for gi, pi in pairs:
                g, p = gi_list[gi], found.intentions[pi]
                s["holder_ok"] += g["holder"] == p.holder
                if g.get("due_at"):
                    s["due_gold"] += 1
                    predicted = local(p.due_at)
                    s["due_date_ok"] += (
                        bool(predicted) and predicted[:10] == g["due_at"][:10]
                    )
                    s["due_exact_ok"] += predicted == g["due_at"][:16]

            # settlements, against the gold open plans so far
            gold_settles = gold.get("settles", [])
            if open_plans:
                plans = [
                    extract.OpenPlan(
                        g["description"],
                        g["quote"],
                        datetime.fromisoformat(said).replace(tzinfo=CAIRO),
                    )
                    for _, g, said in open_plans
                ]
                try:
                    raw_s, seconds = call(
                        llm,
                        extract.settle_messages(plans, segments, now_local),
                        extract.SETTLE_SCHEMA,
                    )
                    s["calls"] += 1
                    latencies.append(seconds)
                    settled = extract.parse_settlements(raw_s, segments, len(plans))
                except Exception as exc:  # noqa: BLE001
                    s["errors"] += 1
                    record["settle_error"] = f"{type(exc).__name__}: {str(exc)[:200]}"
                    raw_s, settled = "{}", []
                record["raw_settle"] = raw_s
                expected = {}
                for gs in gold_settles:
                    for n, (cid, g, _) in enumerate(open_plans):
                        if cid == gs["intention_from"] and norm(
                            g["description"]
                        ) == norm(gs["description"]):
                            expected[n] = gs["status"]
                predicted = {st.plan: st.status for st in settled}
                hits = sum(1 for n, st in predicted.items() if expected.get(n) == st)
                s["set_tp"] += hits
                s["set_fp"] += len(predicted) - hits
                s["set_fn"] += len(expected) - hits
                settled_now = set(expected)
                open_plans = [
                    p for n, p in enumerate(open_plans) if n not in settled_now
                ]
            else:
                s["set_fn"] += len(gold_settles)

            for g in gi_list:
                open_plans.append((conv["id"], g, conv["local_datetime"]))

            # entities (loose)
            ge = {(e["kind"], norm(e["name"])) for e in gold.get("entities", [])}
            pe = {(e.kind, norm(e.name)) for e in found.entities}
            s["ent_tp"] += len(ge & pe)
            s["ent_fp"] += len(pe - ge)
            s["ent_fn"] += len(ge - pe)
            saved.append(record)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name.replace(':', '_').replace('/', '_')}.json").write_text(
        json.dumps(saved, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    s["latency_avg"] = sum(latencies) / len(latencies) if latencies else 0.0
    s["latency_max"] = max(latencies, default=0.0)
    return s


def prf(tp: int, fp: int, fn: int) -> str:
    p = tp / (tp + fp) if tp + fp else 0.0
    r = tp / (tp + fn) if tp + fn else 0.0
    f = 2 * p * r / (p + r) if p + r else 0.0
    return f"P {p:.0%} · R {r:.0%} · F1 {f:.0%}"


def main() -> None:
    models = sys.argv[1:] or DEFAULT_MODELS
    data = json.loads(TESTSET.read_text(encoding="utf-8"))
    for name in models:
        print(f"\n=== {name} ===", flush=True)
        s = evaluate(name, data)
        pct = lambda a, b: f"{a}/{b} ({a / b:.0%})" if b else "n/a"
        print(f"facts       {prf(s['fact_tp'], s['fact_fp'], s['fact_fn'])}")
        print(f"values      {prf(s['val_tp'], s['val_fp'], s['val_fn'])}")
        print(f"intentions  {prf(s['int_tp'], s['int_fp'], s['int_fn'])}")
        print(f"  holder    {pct(s['holder_ok'], s['int_tp'])}")
        print(
            f"  due date  {pct(s['due_date_ok'], s['due_gold'])} · exact time {pct(s['due_exact_ok'], s['due_gold'])}"
        )
        print(f"settles     {prf(s['set_tp'], s['set_fp'], s['set_fn'])}")
        print(f"entities    {prf(s['ent_tp'], s['ent_fp'], s['ent_fn'])}  (loose)")
        print(
            f"dropped     {pct(s['dropped'], s['raw_items'])} of returned facts+intentions failed validation"
        )
        print(f"errors      {s['errors']} of {s['calls'] + s['errors']} calls")
        print(
            f"latency     avg {s['latency_avg']:.1f}s · max {s['latency_max']:.1f}s per call"
        )


if __name__ == "__main__":
    main()
