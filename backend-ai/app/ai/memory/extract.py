"""Facts, intentions and entities from one transcript: prompts, schemas, validation (spec D40).

Pure functions, no database: `services/memory_service.py` calls the LLM with these messages
and schemas and stores what survives validation. The LLM's answer is never trusted as is:

- every quote must appear verbatim in the segment it names (whitespace aside), or the item is
  dropped: a paraphrase is never stored as what someone said (AI_LAYER.md §6.4);
- every typed value must have the right type and its words must be inside the quote;
- local due times are read in the patient's timezone and stored in UTC.

Prompts are versioned files in app/ai/prompts/; the version is part of the stored model_id.
"""

import json
import re
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, tzinfo
from functools import cache
from pathlib import Path

PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"
EXTRACT_PROMPT = "memory_extract.v1"
SETTLE_PROMPT = "memory_settle.v1"

ENTITY_KINDS = ("person", "object", "place")
VALUE_KINDS = ("number", "money", "date", "time", "dose")
NUMERIC_KINDS = ("number", "money", "dose")
MAX_NAME = 80  # characters; a label, not a sentence
TIME_RE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


class ExtractionError(Exception):
    """The LLM's answer isn't JSON of the expected shape: permanent, not retried."""


# ----- inputs -----


@dataclass(frozen=True)
class Segment:
    index: int
    start_s: float
    speaker: str | None
    text: str


def segments_from(metadata: dict | None, transcript_text: str) -> list[Segment]:
    """The speaker-labelled segments of a conversation event, or the whole text as one."""
    segments = [
        Segment(
            i, float(s.get("start_s") or 0.0), s.get("speaker"), s.get("text") or ""
        )
        for i, s in enumerate((metadata or {}).get("segments") or [])
    ]
    if any(s.text.strip() for s in segments):
        return segments
    return [Segment(0, 0.0, None, transcript_text)]


def transcript_block(segments: list[Segment]) -> str:
    return "\n".join(f"[{s.index}] {s.speaker or '?'}: {s.text}" for s in segments)


@cache
def load_prompt(name: str) -> str:
    return (PROMPTS_DIR / f"{name}.txt").read_text(encoding="utf-8")


def _now_line(now_local: datetime) -> str:
    return f"Current local date and time: {now_local:%A %Y-%m-%d %H:%M}."


def extract_messages(segments: list[Segment], now_local: datetime) -> list[dict]:
    return [
        {"role": "system", "content": load_prompt(EXTRACT_PROMPT)},
        {
            "role": "user",
            "content": f"{_now_line(now_local)}\n\nTranscript:\n{transcript_block(segments)}",
        },
    ]


@dataclass(frozen=True)
class OpenPlan:
    description: str
    quote: str
    stated_at_local: datetime


def settle_messages(
    plans: list[OpenPlan], segments: list[Segment], now_local: datetime
) -> list[dict]:
    listed = "\n".join(
        f'{n}. {p.description} (said {p.stated_at_local:%A %Y-%m-%d %H:%M}: "{p.quote}")'
        for n, p in enumerate(plans, start=1)
    )
    return [
        {"role": "system", "content": load_prompt(SETTLE_PROMPT)},
        {
            "role": "user",
            "content": f"{_now_line(now_local)}\n\nOpen plans:\n{listed}\n\n"
            f"New transcript:\n{transcript_block(segments)}",
        },
    ]


# ----- output schemas (JSON Schema, sent as Gemini's responseJsonSchema) -----

_ENTITY = {
    "type": "object",
    "properties": {
        "kind": {"type": "string", "enum": list(ENTITY_KINDS)},
        "name": {"type": "string"},
    },
    "required": ["kind", "name"],
}
_VALUE = {
    "type": "object",
    "properties": {
        "kind": {"type": "string", "enum": list(VALUE_KINDS)},
        "value": {"type": ["number", "string"]},
        "unit": {"type": ["string", "null"]},
        "text": {"type": "string"},
    },
    "required": ["kind", "value", "text"],
}
EXTRACT_SCHEMA = {
    "type": "object",
    "properties": {
        "facts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "segment_index": {"type": "integer"},
                    "quote": {"type": "string"},
                    "speaker_is_patient": {"type": ["boolean", "null"]},
                    "values": {"type": "array", "items": _VALUE},
                    "about": {"type": "array", "items": _ENTITY},
                },
                "required": ["segment_index", "quote", "values", "about"],
            },
        },
        "intentions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "holder": {"type": "string", "enum": ["patient", "other"]},
                    "description": {"type": "string"},
                    "segment_index": {"type": "integer"},
                    "quote": {"type": "string"},
                    "due_at": {"type": ["string", "null"]},
                    "due_until": {"type": ["string", "null"]},
                },
                "required": ["holder", "description", "segment_index", "quote"],
            },
        },
        "entities": {"type": "array", "items": _ENTITY},
    },
    "required": ["facts", "intentions", "entities"],
}
SETTLE_SCHEMA = {
    "type": "object",
    "properties": {
        "settled": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "plan": {"type": "integer"},
                    "status": {"type": "string", "enum": ["done", "not_done"]},
                    "segment_index": {"type": "integer"},
                    "quote": {"type": "string"},
                },
                "required": ["plan", "status", "segment_index", "quote"],
            },
        }
    },
    "required": ["settled"],
}


# ----- validated results -----


@dataclass(frozen=True)
class EntityRef:
    kind: str
    name: str


@dataclass
class Fact:
    segment: Segment
    quote: str
    speaker_is_patient: bool | None
    values: list[dict] = field(default_factory=list)
    about: list[EntityRef] = field(default_factory=list)


@dataclass
class Intention:
    holder: str
    description: str
    segment: Segment
    quote: str
    due_at: datetime | None
    due_until: datetime | None


@dataclass
class Extraction:
    facts: list[Fact]
    intentions: list[Intention]
    entities: list[
        EntityRef
    ]  # every entity mentioned, the facts' `about` included, unique


@dataclass(frozen=True)
class Settlement:
    plan: int  # 0-based index into the plans that were sent
    status: str
    segment: Segment
    quote: str


def _squash(text: str) -> str:
    return " ".join(text.split())


def verbatim(quote, segments: list[Segment], index) -> tuple[Segment, str] | None:
    """(segment, cleaned quote) if the quote is really in that segment, else None."""
    if not isinstance(quote, str) or not isinstance(index, int):
        return None
    if not 0 <= index < len(segments):
        return None
    cleaned = _squash(quote).strip(" \"'«»“”")
    if not cleaned or cleaned not in _squash(segments[index].text):
        return None
    return segments[index], cleaned


def entity_name(name) -> str | None:
    """The stored label: whitespace squashed, case folded (Arabic is unchanged)."""
    if not isinstance(name, str):
        return None
    cleaned = _squash(name).strip(" \"'.,،").casefold()
    return cleaned[:MAX_NAME] or None


def _entity(item) -> EntityRef | None:
    if not isinstance(item, dict) or item.get("kind") not in ENTITY_KINDS:
        return None
    name = entity_name(item.get("name"))
    return EntityRef(item["kind"], name) if name else None


def _value(item, quote: str) -> dict | None:
    if not isinstance(item, dict) or item.get("kind") not in VALUE_KINDS:
        return None
    kind, value, text = item["kind"], item.get("value"), item.get("text")
    if not isinstance(text, str) or _squash(text) not in quote:
        return None
    if kind in NUMERIC_KINDS:
        if isinstance(value, bool) or not isinstance(value, int | float):
            return None
    elif kind == "date":
        try:
            value = date.fromisoformat(str(value)).isoformat()
        except ValueError:
            return None
    elif not (isinstance(value, str) and TIME_RE.match(value)):
        return None
    unit = item.get("unit")
    return {
        "kind": kind,
        "value": value,
        "unit": unit if isinstance(unit, str) and unit else None,
        "text": _squash(text),
    }


def local_to_utc(value, tz: tzinfo) -> datetime | None:
    """'2026-10-26T17:00' in the patient's timezone → UTC; None if missing or unreadable."""
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=tz)
    return parsed.astimezone(UTC)


def _load(raw: str) -> dict:
    try:
        data = json.loads(raw)
    except (TypeError, ValueError) as exc:
        raise ExtractionError("the LLM answer is not JSON") from exc
    if not isinstance(data, dict):
        raise ExtractionError("the LLM answer is not a JSON object")
    return data


def _items(data: dict, key: str) -> list:
    items = data.get(key) or []
    return items if isinstance(items, list) else []


def parse_extraction(raw: str, segments: list[Segment], tz: tzinfo) -> Extraction:
    data = _load(raw)
    entities: dict[EntityRef, None] = {}  # ordered and unique

    facts = []
    for item in _items(data, "facts"):
        if not isinstance(item, dict):
            continue
        found = verbatim(item.get("quote"), segments, item.get("segment_index"))
        if found is None:
            continue
        segment, quote = found
        about = [e for e in map(_entity, item.get("about") or []) if e]
        entities.update(dict.fromkeys(about))
        speaker = item.get("speaker_is_patient")
        facts.append(
            Fact(
                segment=segment,
                quote=quote,
                speaker_is_patient=speaker if isinstance(speaker, bool) else None,
                values=[
                    v for v in (_value(i, quote) for i in item.get("values") or []) if v
                ],
                about=list(dict.fromkeys(about)),
            )
        )

    intentions = []
    for item in _items(data, "intentions"):
        if not isinstance(item, dict) or item.get("holder") not in ("patient", "other"):
            continue
        found = verbatim(item.get("quote"), segments, item.get("segment_index"))
        description = _squash(str(item.get("description") or ""))
        if found is None or not description:
            continue
        due_at = local_to_utc(item.get("due_at"), tz)
        due_until = local_to_utc(item.get("due_until"), tz)
        if due_at and due_until and due_until < due_at:
            due_until = None
        intentions.append(
            Intention(
                holder=item["holder"],
                description=description,
                segment=found[0],
                quote=found[1],
                due_at=due_at,
                due_until=due_until,
            )
        )

    for entity in map(_entity, _items(data, "entities")):
        if entity:
            entities[entity] = None
    return Extraction(facts, intentions, list(entities))


def parse_settlements(
    raw: str, segments: list[Segment], n_plans: int
) -> list[Settlement]:
    settled: dict[int, Settlement] = {}  # one decision per plan: the first one wins
    for item in _items(_load(raw), "settled"):
        if not isinstance(item, dict) or item.get("status") not in ("done", "not_done"):
            continue
        plan = item.get("plan")
        if not isinstance(plan, int) or not 1 <= plan <= n_plans or plan - 1 in settled:
            continue
        found = verbatim(item.get("quote"), segments, item.get("segment_index"))
        if found is None:
            continue
        settled[plan - 1] = Settlement(plan - 1, item["status"], found[0], found[1])
    return list(settled.values())
