"""search_memory argument validation (track R3, slice 1). Pure functions: no database.

Synthetic ids only. Cairo is UTC+2 in winter and UTC+3 in summer (2026: 24 Apr - 29 Oct).
"""

from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

import pydantic
import pytest

from app.ai.rag.planner import (
    DAY_PARTS,
    EVENT_TYPES,
    FALLBACK_DAYS,
    MAX_LOOKBACK_DAYS,
    MAX_SEARCH_TEXT,
    QueryPlan,
    RawSearchArgs,
    fallback_plan,
    search_args_schema,
    validate_args,
)
from app.models.journal import Event

CAIRO = "Africa/Cairo"
PEOPLE = {"p-ahmed", "p-mona"}
QUESTION = "منى قالتلي إيه الصبح؟"


def cairo(text: str) -> datetime:
    return datetime.fromisoformat(text).replace(tzinfo=ZoneInfo(CAIRO))


def utc(text: str) -> datetime:
    return datetime.fromisoformat(text).replace(tzinfo=UTC)


ASKED = cairo("2026-01-15T21:00")  # 19:00 UTC
# lookback is exact elapsed time (UTC arithmetic): wall-clock 90 days back in Cairo would
# cross summer time (Oct 2025) and be an hour off
ASKED_UTC = ASKED.astimezone(UTC)


def check(asked_at=ASKED, **args):
    return validate_args(
        RawSearchArgs(**args),
        asked_at=asked_at,
        tz=CAIRO,
        allowed_person_ids=PEOPLE,
        question=QUESTION,
    )


# ----- the happy path -----


def test_good_args_pass_unchanged():
    plan, notes = check(
        window_start="2026-01-15T09:00",
        window_end="2026-01-15T12:00",
        person_ids=["p-mona"],
        event_types=["conversation_segment"],
        search_text="الضغط",
    )
    assert notes == []
    assert plan == QueryPlan(
        window_start=utc("2026-01-15T07:00"),
        window_end=utc("2026-01-15T10:00"),
        person_ids=["p-mona"],
        event_types=["conversation_segment"],
        search_text="الضغط",
    )


def test_no_window_means_lookback_to_now():
    plan, notes = check(search_text="x")
    assert notes == []
    assert plan.window_end == ASKED
    assert plan.window_start == ASKED_UTC - timedelta(days=MAX_LOOKBACK_DAYS)
    assert plan.person_ids == [] and plan.event_types is None


# ----- people -----


def test_hallucinated_person_id_is_dropped_with_a_note():
    plan, notes = check(person_ids=["p-ahmed", "p-ghost", "p-ahmed"], search_text="x")
    assert plan.person_ids == ["p-ahmed"]
    assert notes == ["dropped_person_id"]
    assert not any("ghost" in n for n in notes)  # notes never carry ids


# ----- window -----


def test_end_after_asked_at_is_clamped():
    plan, notes = check(window_end="2026-01-16T10:00", search_text="x")
    assert plan.window_end == ASKED
    assert notes == ["clamped_end"]


def test_today_as_a_bare_date_is_clamped_silently():
    plan, notes = check(
        window_start="2026-01-15", window_end="2026-01-15", search_text="x"
    )
    assert plan.window_start == utc("2026-01-14T22:00")
    assert plan.window_end == ASKED
    assert notes == []


def test_bare_end_date_includes_the_whole_day():
    plan, _ = check(window_start="2026-01-10", window_end="2026-01-10", search_text="x")
    assert plan.window_start == utc("2026-01-09T22:00")
    assert plan.window_end == utc("2026-01-10T22:00")  # local midnight of the 11th


def test_start_after_end_drops_the_start():
    plan, notes = check(
        window_start="2026-01-15T12:00", window_end="2026-01-15T09:00", search_text="x"
    )
    assert plan.window_start == ASKED_UTC - timedelta(days=MAX_LOOKBACK_DAYS)
    assert plan.window_end == utc("2026-01-15T07:00")
    assert notes == ["dropped_start"]


def test_lookback_is_limited():
    plan, notes = check(window_start="2025-01-01", search_text="x")
    assert plan.window_start == ASKED_UTC - timedelta(days=MAX_LOOKBACK_DAYS)
    assert notes == ["clamped_start"]


def test_window_entirely_beyond_lookback_matches_nothing():
    plan, notes = check(
        window_start="2025-06-01", window_end="2025-06-02", search_text="x"
    )
    assert plan.window_start == plan.window_end  # empty half-open window
    assert "beyond_lookback" in notes


@pytest.mark.parametrize(
    "bad", ["yesterday", "2026-13-01", "2026-01-15T09:00+02:00", "2026-01-15T09:00Z"]
)
def test_unparseable_or_offset_times_are_dropped(bad):
    plan, notes = check(window_start=bad, window_end=bad, search_text="x")
    assert notes == ["bad_window_start", "bad_window_end"]
    assert plan.window_end == ASKED


# ----- day parts -----


def test_morning_on_a_winter_date():
    plan, notes = check(
        window_start="2026-01-14", window_end="2026-01-14", day_part="morning"
    )
    assert (plan.window_start, plan.window_end) == (
        utc("2026-01-14T03:00"),  # 05:00 at UTC+2
        utc("2026-01-14T10:00"),  # 12:00 at UTC+2
    )
    assert "empty_search_text" in notes


def test_morning_on_a_summer_date():
    plan, _ = check(
        asked_at=cairo("2026-07-15T21:00"),
        window_start="2026-07-15",
        window_end="2026-07-15",
        day_part="morning",
        search_text="x",
    )
    assert (plan.window_start, plan.window_end) == (
        utc("2026-07-15T02:00"),  # 05:00 at UTC+3
        utc("2026-07-15T09:00"),  # 12:00 at UTC+3
    )


def test_morning_without_window_means_this_morning_up_to_now():
    plan, notes = check(asked_at=cairo("2026-01-15T10:00"), day_part="morning")
    assert plan.window_start == utc("2026-01-15T03:00")
    assert plan.window_end == utc("2026-01-15T08:00")  # asked_at, not 12:00
    assert "clamped_end" not in notes


def test_night_runs_past_midnight():
    plan, _ = check(
        window_start="2026-01-14",
        window_end="2026-01-14",
        day_part="night",
        search_text="x",
    )
    assert plan.window_start == utc("2026-01-14T18:00")  # 20:00 local
    assert plan.window_end == utc("2026-01-15T03:00")  # 05:00 local, next day


def test_day_part_over_several_dates_is_ignored():
    plan, notes = check(
        window_start="2026-01-13",
        window_end="2026-01-14",
        day_part="morning",
        search_text="x",
    )
    assert notes == ["ignored_day_part"]
    assert plan.window_start == utc("2026-01-12T22:00")
    assert plan.window_end == utc("2026-01-14T22:00")


def test_unknown_day_part_gets_a_note():
    _, notes = check(day_part="teatime", search_text="x")
    assert notes == ["unknown_day_part"]


def test_dst_gap_is_pinned():
    # Egypt springs forward at local midnight on 24 Apr 2026 (00:00 -> 01:00), so 00:30 does
    # not exist. zoneinfo (fold=0) reads it with the offset before the change, +02:00:
    # 00:30 -> 22:30 UTC on the 23rd, i.e. 30 minutes AFTER 01:00 local (22:00 UTC).
    # Accepted: only a window edge typed inside that missing hour is affected.
    plan, notes = check(
        asked_at=cairo("2026-04-24T12:00"),
        window_start="2026-04-24T00:30",
        search_text="x",
    )
    assert notes == []
    assert plan.window_start == utc("2026-04-23T22:30")


# ----- event types -----


def test_unknown_event_type_is_dropped():
    plan, notes = check(event_types=["encounter", "sound_detected"], search_text="x")
    assert plan.event_types == ["encounter"]
    assert notes == ["dropped_event_type"]


def test_only_unknown_event_types_means_no_filter():
    plan, notes = check(event_types=["dancing"], search_text="x")
    assert plan.event_types is None
    assert notes == ["dropped_event_type"]


def test_event_types_match_the_model_enum():
    # Fails on purpose when the model's enum changes (e.g. adding sound_detected):
    # update EventType in planner.py, the tool schema follows.
    assert set(EVENT_TYPES) == set(Event.__table__.c.event_type.type.enums)


# ----- search text -----


@pytest.mark.parametrize("empty", ["", "   ", "\n\t"])
def test_empty_search_text_falls_back_to_the_question(empty):
    plan, notes = check(search_text=empty)
    assert plan.search_text == QUESTION
    assert notes == ["empty_search_text"]


def test_long_search_text_is_capped():
    plan, notes = check(search_text="كلمة " * 100)
    assert len(plan.search_text) == MAX_SEARCH_TEXT
    assert notes == ["truncated_search_text"]


# ----- shape -----


def test_query_plan_has_no_patient_id():
    assert "patient_id" not in QueryPlan.model_fields
    assert "patient_id" not in search_args_schema()["properties"]
    plan, _ = check(search_text="x", patient_id="someone-else")  # ignored, not an error
    assert not hasattr(plan, "patient_id")


def test_query_plan_is_frozen():
    plan, _ = check(search_text="x")
    with pytest.raises(pydantic.ValidationError):
        plan.search_text = "y"


def test_schema_documents_the_tool():
    props = search_args_schema()["properties"]
    assert set(props) == {
        "window_start",
        "window_end",
        "day_part",
        "person_ids",
        "event_types",
        "search_text",
    }
    for name, prop in props.items():
        assert prop.get("description"), name
    assert "LOCAL" in props["window_start"]["description"]
    assert "whole day" in props["window_end"]["description"]
    assert "PRESENT" in props["person_ids"]["description"]
    assert "search_text" in props["person_ids"]["description"]
    assert "single date" in props["day_part"]["description"]
    day_enum = props["day_part"]["anyOf"][0]["enum"]
    assert day_enum == list(DAY_PARTS)
    type_enum = props["event_types"]["anyOf"][0]["items"]["enum"]
    assert set(type_enum) == set(EVENT_TYPES)


def test_naive_asked_at_or_bad_timezone_raise():
    with pytest.raises(ValueError):
        check(asked_at=datetime(2026, 1, 15, 21, 0), search_text="x")
    with pytest.raises(ValueError):
        validate_args(
            RawSearchArgs(),
            asked_at=ASKED,
            tz="Mars/Olympus",
            allowed_person_ids=PEOPLE,
            question=QUESTION,
        )


# ----- fallback -----


def test_fallback_plan():
    plan = fallback_plan(QUESTION, ASKED, CAIRO)
    assert plan.window_end == ASKED
    assert plan.window_start == ASKED_UTC - timedelta(days=FALLBACK_DAYS)
    assert plan.person_ids == [] and plan.event_types is None
    assert plan.search_text == QUESTION
    assert plan.window_start.utcoffset() == timedelta(0)
