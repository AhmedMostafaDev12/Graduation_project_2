"""Validate the arguments of the /assist agent's `search_memory` tool (track R3, slice 1).

The /assist agent is a bounded tool-calling loop: the model may call one tool, search_memory,
a few times before answering. This module is the code-side guard for that tool's arguments.
The model sends RawSearchArgs (strings, local time); validate_args turns them into a
QueryPlan the retriever (R4) can trust, plus short notes saying what was changed so the tool
result can tell the model. fallback_plan is used when the whole loop fails.

Rules:
- Times from the model are LOCAL, naive, in the patient's timezone ("YYYY-MM-DDTHH:MM", or a
  bare date "YYYY-MM-DD" meaning the whole day). Code converts them with zoneinfo (Egypt has
  summer time; no hard-coded offsets). QueryPlan holds aware UTC datetimes.
- The window is half-open: [window_start, window_end). The SQL in R4 must use the same
  semantics (occurred_at >= window_start AND occurred_at < window_end).
- The window never ends after asked_at (memory can't contain the future) and never starts
  more than MAX_LOOKBACK_DAYS before it.
- person_ids are people who were PRESENT (encounter person_id, conversation
  present_person_ids). People who are only mentioned ("when is my appointment with Dr. Hany")
  go in search_text, never in person_ids: a hard person filter would lose those events.
- day_part narrows the window to those hours of its date (the part's hours replace the
  window's), and only when the window covers a single date. Night runs past midnight.
- The plan has no patient_id: the tool binds it from the session, never from the model.
- Privacy: nothing here is logged (question, arguments, names and ids are all private).
  Notes are fixed codes without ids, names or text.
"""

from collections.abc import Collection
from datetime import UTC, date, datetime, time, timedelta
from typing import Annotated, Literal, get_args
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, WithJsonSchema

# Same values as Event.event_type in app/models/journal.py (a test keeps them in sync).
EventType = Literal[
    "encounter",
    "conversation_segment",
    "voice_query",
    "reminder",
    "mind_game_session",
    "manual_note",
    "user_requested_recording",
    "document_captured",
    "notable_moment_captured",
    "memory_paused",
    "memory_resumed",
]
EVENT_TYPES: tuple[str, ...] = get_args(EventType)

# DRAFT (R3 time understanding, not decided): local hours of each part of the day.
# An end before the start means the next day (night runs into the early morning).
# ml/rag_eval/evaluate_smoke.py uses the same morning window.
DAY_PARTS: dict[str, tuple[str, str]] = {
    "morning": ("05:00", "12:00"),  # الصبح
    "noon": ("12:00", "15:00"),  # الضهر
    "evening": ("15:00", "20:00"),  # العصر / المغرب
    "night": ("20:00", "05:00"),  # بالليل
}

MAX_LOOKBACK_DAYS = 90  # DRAFT
FALLBACK_DAYS = 30
MAX_SEARCH_TEXT = 300  # same cap as quotes in render.py


# ----- what the model sends -----


class RawSearchArgs(BaseModel):
    """The model's search_memory arguments. Lenient on purpose: a bad value is dropped with
    a note by validate_args instead of failing the whole call."""

    model_config = ConfigDict(extra="ignore")

    window_start: str | None = Field(
        default=None,
        description=(
            "Start of the time window, LOCAL time of the patient, no timezone: "
            "'YYYY-MM-DDTHH:MM', or a bare date 'YYYY-MM-DD' (from the start of that day). "
            "null = as far back as memory goes."
        ),
    )
    window_end: str | None = Field(
        default=None,
        description=(
            "End of the time window (exclusive), LOCAL time, no timezone: "
            "'YYYY-MM-DDTHH:MM', or a bare date 'YYYY-MM-DD' (includes the whole day). "
            "null = now."
        ),
    )
    day_part: Annotated[
        str | None,
        WithJsonSchema(
            {"anyOf": [{"type": "string", "enum": list(DAY_PARTS)}, {"type": "null"}]}
        ),
    ] = Field(
        default=None,
        description=(
            "Part of the day to keep, e.g. 'morning' for 'الصبح'. Only works when the "
            "window covers a single date; with no window it applies to today."
        ),
    )
    person_ids: list[str] = Field(
        default_factory=list,
        description=(
            "Ids of people who were PRESENT (met, talked with). People who are only "
            "mentioned go in search_text instead. Empty = no person filter."
        ),
    )
    event_types: Annotated[
        list[str] | None,
        WithJsonSchema(
            {
                "anyOf": [
                    {
                        "type": "array",
                        "items": {"type": "string", "enum": list(EVENT_TYPES)},
                    },
                    {"type": "null"},
                ]
            }
        ),
    ] = Field(default=None, description="Kinds of events to keep. null = all kinds.")
    search_text: str = Field(
        default="",
        description=(
            "What to look for, in the patient's words, including the names of people or "
            "things that are only mentioned."
        ),
    )


def search_args_schema() -> dict:
    """JSON schema of the search_memory arguments, for the tool declaration."""
    return RawSearchArgs.model_json_schema()


# ----- what the retriever gets -----


class QueryPlan(BaseModel):
    """Validated search_memory arguments. Window is half-open [start, end), in UTC."""

    model_config = ConfigDict(frozen=True)

    window_start: AwareDatetime | None
    window_end: AwareDatetime | None
    person_ids: list[str]
    event_types: list[EventType] | None
    search_text: str


# ----- helpers -----


def _zone(tz: str) -> ZoneInfo:
    try:
        return ZoneInfo(tz)
    except (ZoneInfoNotFoundError, ValueError) as exc:
        raise ValueError("Unknown timezone") from exc


def _check_aware(asked_at: datetime) -> None:
    if asked_at.tzinfo is None or asked_at.utcoffset() is None:
        raise ValueError("asked_at must be timezone-aware")


def _local_to_utc(day: date, at: time, zone: ZoneInfo) -> datetime:
    return datetime.combine(day, at, tzinfo=zone).astimezone(UTC)


def _parse(text: str | None, zone: ZoneInfo, *, is_end: bool) -> datetime | None:
    """Local naive text -> aware UTC. A bare end date includes the whole day.
    Raises ValueError for anything else (including a timezone in the text)."""
    if text is None or not text.strip():
        return None
    text = text.strip()
    if len(text) == 10:
        day = date.fromisoformat(text)
        return _local_to_utc(day + timedelta(days=1) if is_end else day, time(), zone)
    local = datetime.fromisoformat(text)
    if local.tzinfo is not None:
        raise ValueError("window times must be local, without a timezone")
    return local.replace(tzinfo=zone).astimezone(UTC)


def _hm(text: str) -> time:
    hour, minute = text.split(":")
    return time(int(hour), int(minute))


def _single_date(
    start: datetime | None, end: datetime | None, asked_at: datetime, zone: ZoneInfo
) -> date | None:
    """The one local date the window covers, or None when it covers several."""
    dates = set()
    if start is not None:
        dates.add(start.astimezone(zone).date())
    if end is not None:
        dates.add((end - timedelta(microseconds=1)).astimezone(zone).date())
    if not dates:
        dates.add(asked_at.astimezone(zone).date())
    return dates.pop() if len(dates) == 1 else None


def _cap(text: str) -> str:
    return " ".join(text.split())[:MAX_SEARCH_TEXT]


# ----- validation -----


def validate_args(
    raw: RawSearchArgs,
    *,
    asked_at: datetime,
    tz: str,
    allowed_person_ids: Collection[str],
    question: str,
) -> tuple[QueryPlan, list[str]]:
    """(plan, notes). Never raises for bad arguments from the model: it fixes them and adds
    a note code. Raises ValueError only for programming errors (naive asked_at, bad tz)."""
    _check_aware(asked_at)
    zone = _zone(tz)
    asked_at = asked_at.astimezone(UTC)
    notes: list[str] = []

    def note(code: str) -> None:
        if code not in notes:
            notes.append(code)

    # 1. local -> UTC
    try:
        start = _parse(raw.window_start, zone, is_end=False)
    except ValueError:
        start = None
        note("bad_window_start")
    try:
        end = _parse(raw.window_end, zone, is_end=True)
    except ValueError:
        end = None
        note("bad_window_end")

    # 2. day_part: narrow to those hours on the window's single date
    if raw.day_part is not None and raw.day_part.strip():
        part = DAY_PARTS.get(raw.day_part.strip().lower())
        day = _single_date(start, end, asked_at, zone)
        if part is None:
            note("unknown_day_part")
        elif day is None:
            note("ignored_day_part")
        else:
            part_start, part_end = _hm(part[0]), _hm(part[1])
            end_day = day + timedelta(days=1) if part_end <= part_start else day
            # the part's hours replace the window's (a bare-date window ends at midnight,
            # which would cut the night short)
            start = _local_to_utc(day, part_start, zone)
            end = _local_to_utc(end_day, part_end, zone)

    # 3. never after asked_at; the note only when the model asked about a later date
    #    (a window for "today" ending at midnight is clamped silently)
    if end is None:
        end = asked_at
    elif end > asked_at:
        last_day = (end - timedelta(microseconds=1)).astimezone(zone).date()
        if last_day > asked_at.astimezone(zone).date():
            note("clamped_end")
        end = asked_at

    # 4. lookback limit, then an empty window
    floor = asked_at - timedelta(days=MAX_LOOKBACK_DAYS)
    if start is None:
        start = floor
    elif start < floor:
        start = floor
        note("clamped_start")
    if end <= floor:
        start = end = floor  # all of it is older than memory goes back: matches nothing
        note("beyond_lookback")
    elif start >= end:
        start = floor
        note("dropped_start")

    # 5. people: only those the tool offered, once each
    person_ids: list[str] = []
    allowed = set(allowed_person_ids)
    for pid in raw.person_ids:
        if pid not in allowed:
            note("dropped_person_id")
        elif pid not in person_ids:
            person_ids.append(pid)

    # 6. event types: unknown ones dropped; nothing left = no filter
    event_types: list[str] | None = None
    if raw.event_types:
        kept = []
        for t in raw.event_types:
            if t not in EVENT_TYPES:
                note("dropped_event_type")
            elif t not in kept:
                kept.append(t)
        event_types = kept or None

    # 7. search text: the question when the model gave none
    search_text = _cap(raw.search_text)
    if not search_text:
        search_text = _cap(question)
        note("empty_search_text")
    elif len(" ".join(raw.search_text.split())) > MAX_SEARCH_TEXT:
        note("truncated_search_text")

    plan = QueryPlan(
        window_start=start,
        window_end=end,
        person_ids=person_ids,
        event_types=event_types,
        search_text=search_text,
    )
    return plan, notes


def fallback_plan(question: str, asked_at: datetime, tz: str) -> QueryPlan:
    """When the loop fails: the last FALLBACK_DAYS, no person or type filter."""
    _check_aware(asked_at)
    _zone(tz)
    asked_at = asked_at.astimezone(UTC)
    return QueryPlan(
        window_start=asked_at - timedelta(days=FALLBACK_DAYS),
        window_end=asked_at,
        person_ids=[],
        event_types=None,
        search_text=_cap(question),
    )
