"""Render one journal event as one sentence for RAG (spec D22, §7.3 step 4; plan track R2).

The sentence is what gets embedded (D15) and ranked after the SQL time/person filter, e.g.
"09:20–09:24 اتكلمت مع أحمد (ابن): "...."". Pure and deterministic: the caller (the `embed`
task, Phase 7.3) loads every related row and passes it in RenderInput. No DB, no network,
no logging.

Rules:
- Language: the event's language if 'ar' or 'en', otherwise the patient's. Every word of the
  sentence comes from that one language; nothing is translated.
- Inserted text (names, relationships, transcript, titles, tags, place) is kept as stored,
  except that Arabic diacritics are removed and whitespace is collapsed to single spaces.
- Time is local to the patient ("HH:MM", spans "HH:MM–HH:MM"); no date (SQL filters dates).
"""

import re
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from typing import Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from app.ai.review_contract import display

# Long transcripts drown the time + person part of the vector; the full text stays in
# events.transcript_text for the answer prompt. 300 chars is about 20-30 s of speech.
MAX_QUOTE_CHARS = 300

_DIACRITICS = re.compile("[ً-ْٰ]")
_SPACES = re.compile(r"\s+")

# Events whose ended_at is shown as a span.
_SPAN_TYPES = {"encounter", "conversation_segment"}


@dataclass(frozen=True, slots=True)
class PersonRef:
    name: str
    relationship: str


@dataclass(frozen=True, slots=True, kw_only=True)
class RenderInput:
    # events row
    event_type: str
    occurred_at: datetime
    ended_at: datetime | None = None
    transcript_text: str | None = None  # conversation_segment, voice_query, manual_note
    event_language: Literal["ar", "en", "mixed"] | None = None
    # patient
    patient_language: Literal["ar", "en"]
    patient_timezone: str
    # people: events.person_id and metadata.present_person_ids
    person: PersonRef | None = None
    present_people: tuple[PersonRef, ...] = ()
    # metadata.place_id -> places.name
    place_name: str | None = None
    # voice_query: metadata.answer
    query_answer: str | None = None
    # reminder: reminder_logs + reminders
    reminder_title: str | None = None
    reminder_type: Literal["medication", "appointment", "task"] | None = None
    reminder_status: Literal["pending", "completed", "snoozed", "missed"] | None = None
    reminder_confirmed_via: Literal["voice", "app", "caregiver"] | None = None
    # mind_game_session
    game_type: str | None = None
    game_score: int | None = None
    # document_captured: captured_documents
    document_type: Literal["receipt", "bill", "medication_label", "other"] | None = None
    document_fields: Mapping | None = None
    # media_assets of the event
    media_type: Literal["image", "video"] | None = None
    media_duration_seconds: int | None = None
    media_tags: tuple[str, ...] = ()


# ----- phrases per language -----

_AR = {
    "comma": "، ",
    "someone": "حد",
    "place": " في {}",
    "encounter": "{t} قابلت {who}{place}",
    "encounter_unknown": "{t} قابلت حد مش معروف{place}",
    "conversation": "{t} اتكلمت مع {who}{place}",
    "query": '{t} سألت "{q}"',
    "query_answer": ' واتقالي "{a}"',
    "query_empty": "{t} سألت سؤال",
    "med": {
        "completed": "{t} خدت الدوا",
        "missed": "{t} فات ميعاد الدوا من غير تأكيد",
        "snoozed": "{t} أجلت الدوا",
        "pending": "{t} ميعاد الدوا لسه ما اتأكدش",
        None: "{t} تذكير الدوا",
    },
    "reminder": {
        "appointment": "{t} تذكير الميعاد",
        "task": "{t} تذكير",
        None: "{t} تذكير",
    },
    "reminder_status": {
        "completed": "اتعمل",
        "missed": "ما اتعملش",
        "snoozed": "اتأجل",
        "pending": "لسه ما اتعملش",
    },
    "via": {
        "voice": " (اتأكد بالصوت)",
        "app": " (اتأكد من الموبايل)",
        "caregiver": " (اتأكد من المرافق)",
    },
    "game": "{t} لعبت {game}",
    "game_score": "النتيجة {}",
    "game_unknown": "لعبة ذاكرة",
    "games": {
        "card_match": "لعبة الكروت",
        "picture_naming": "لعبة الصور",
        "word_recall": "لعبة الكلمات",
        "face_match": "لعبة الوشوش",
    },
    "note": '{t} ملاحظة: "{text}"',
    "note_empty": "{t} كتبت ملاحظة",
    "video": "{t} سجلت فيديو{length}{place}",
    "seconds": " {} ثانية",
    "minutes": " {} دقيقة",
    "photo": "{t} صورت صورة{place}",
    "clip": "{t} سجلت مقطع{place}",
    "document": "{t} تصوير {doc}",
    "docs": {
        "receipt": "إيصال",
        "bill": "فاتورة",
        "medication_label": "علبة دوا",
        "other": "ورقة",
    },
    "moment": "{t} تصوير لحظة مهمة{place}",
    "memory_paused": "{t} إيقاف تسجيل الذاكرة",
    "memory_resumed": "{t} استئناف تسجيل الذاكرة",
}

_EN = {
    "comma": ", ",
    "someone": "someone",
    "place": " at {}",
    "encounter": "{t} met {who}{place}",
    "encounter_unknown": "{t} met someone unknown{place}",
    "conversation": "{t} talked with {who}{place}",
    "query": '{t} asked "{q}"',
    "query_answer": ' and was told "{a}"',
    "query_empty": "{t} asked a question",
    "med": {
        "completed": "{t} took medication",
        "missed": "{t} medication was due, no confirmation it was taken",
        "snoozed": "{t} postponed medication",
        "pending": "{t} medication due, not confirmed yet",
        None: "{t} medication reminder",
    },
    "reminder": {
        "appointment": "{t} appointment reminder",
        "task": "{t} reminder",
        None: "{t} reminder",
    },
    "reminder_status": {
        "completed": "done",
        "missed": "missed",
        "snoozed": "snoozed",
        "pending": "not done yet",
    },
    "via": {
        "voice": " (confirmed by voice)",
        "app": " (confirmed in the app)",
        "caregiver": " (confirmed by the caregiver)",
    },
    "game": "{t} played {game}",
    "game_score": "score {}",
    "game_unknown": "a memory game",
    "games": {
        "card_match": "card match",
        "picture_naming": "picture naming",
        "word_recall": "word recall",
        "face_match": "face match",
    },
    "note": '{t} note: "{text}"',
    "note_empty": "{t} wrote a note",
    "video": "{t} recorded a{length} video{place}",
    "seconds": " {}-second",
    "minutes": " {}-minute",
    "photo": "{t} took a photo{place}",
    "clip": "{t} recorded a clip{place}",
    "document": "{t} took a photo of a {doc}",
    "docs": {
        "receipt": "receipt",
        "bill": "bill",
        "medication_label": "medication label",
        "other": "document",
    },
    "moment": "{t} captured a special moment{place}",
    "memory_paused": "{t} memory recording paused",
    "memory_resumed": "{t} memory recording resumed",
}

PHRASES = {"ar": _AR, "en": _EN}


# ----- helpers -----


def output_language(inp: RenderInput) -> str:
    if inp.event_language in ("ar", "en"):
        return inp.event_language
    return inp.patient_language


def clean(text: str | None) -> str:
    """Stored text without Arabic diacritics, on one line. '' for None."""
    if not text:
        return ""
    return _SPACES.sub(" ", _DIACRITICS.sub("", text)).strip()


def _quote(text: str | None) -> str:
    text = clean(text)
    if len(text) <= MAX_QUOTE_CHARS:
        return text
    cut = text[:MAX_QUOTE_CHARS]
    space = cut.rfind(" ")
    if space > 0:
        cut = cut[:space]
    return cut.rstrip(" ،,.") + "…"


def _local(dt: datetime, tz: ZoneInfo) -> str:
    if dt.tzinfo is None or dt.utcoffset() is None:
        raise ValueError("RenderInput datetimes must be timezone-aware")
    return dt.astimezone(tz).strftime("%H:%M")


def _time(inp: RenderInput) -> str:
    try:
        tz = ZoneInfo(inp.patient_timezone)
    except (ZoneInfoNotFoundError, ValueError) as exc:
        raise ValueError("Unknown patient_timezone") from exc
    start = _local(inp.occurred_at, tz)
    if inp.ended_at is None or inp.event_type not in _SPAN_TYPES:
        return start
    end = _local(inp.ended_at, tz)
    return start if end == start else f"{start}–{end}"


def _person(p: PersonRef) -> str:
    name, relationship = clean(p.name), clean(p.relationship)
    if name and relationship:
        return f"{name} ({relationship})"
    return name or relationship


def _people(inp: RenderInput, lang: str) -> str:
    seen: list[str] = []
    for p in (inp.person, *inp.present_people):
        text = _person(p) if p else ""
        if text and text not in seen:
            seen.append(text)
    if not seen:
        return ""
    if len(seen) == 1:
        return seen[0]
    if lang == "ar":
        return "، ".join(seen[:-1]) + " و" + seen[-1]
    return ", ".join(seen[:-1]) + " and " + seen[-1]


def _place(inp: RenderInput, ph: dict) -> str:
    place = clean(inp.place_name)
    return ph["place"].format(place) if place else ""


def _join(ph: dict, head: str, *parts: str) -> str:
    """head + ': ' + parts joined by the language's comma (empty parts dropped)."""
    parts = tuple(p for p in parts if p)
    return f"{head}: {ph['comma'].join(parts)}" if parts else head


# ----- one renderer per event type -----


def _encounter(inp, ph, t, lang):
    who = _person(inp.person) if inp.person else ""
    if not who:
        return ph["encounter_unknown"].format(t=t, place=_place(inp, ph))
    return ph["encounter"].format(t=t, who=who, place=_place(inp, ph))


def _conversation(inp, ph, t, lang):
    who = _people(inp, lang) or ph["someone"]
    head = ph["conversation"].format(t=t, who=who, place=_place(inp, ph))
    quote = _quote(inp.transcript_text)
    return f'{head}: "{quote}"' if quote else head


def _voice_query(inp, ph, t, lang):
    question = _quote(inp.transcript_text)
    if not question:
        return ph["query_empty"].format(t=t)
    answer = _quote(inp.query_answer)
    sentence = ph["query"].format(t=t, q=question)
    return sentence + (ph["query_answer"].format(a=answer) if answer else "")


def _reminder(inp, ph, t, lang):
    title = clean(inp.reminder_title)
    via = ph["via"].get(inp.reminder_confirmed_via, "")
    if inp.reminder_type == "medication":
        head = ph["med"].get(inp.reminder_status, ph["med"][None]).format(t=t)
        return _join(ph, head, title) + via
    head = ph["reminder"].get(inp.reminder_type, ph["reminder"][None]).format(t=t)
    status = ph["reminder_status"].get(inp.reminder_status, "")
    return _join(ph, head, title, status) + via


def _mind_game(inp, ph, t, lang):
    game = ph["games"].get(clean(inp.game_type), ph["game_unknown"])
    head = ph["game"].format(t=t, game=game)
    if inp.game_score is None:
        return head
    return head + ph["comma"] + ph["game_score"].format(inp.game_score)


def _manual_note(inp, ph, t, lang):
    text = _quote(inp.transcript_text)
    return ph["note"].format(t=t, text=text) if text else ph["note_empty"].format(t=t)


def _recording(inp, ph, t, lang):
    place = _place(inp, ph)
    if inp.media_type == "image":
        return ph["photo"].format(t=t, place=place)
    seconds = inp.media_duration_seconds
    if seconds is None and inp.ended_at is not None:
        seconds = round((inp.ended_at - inp.occurred_at).total_seconds())
    if inp.media_type is None and seconds is None:
        return ph["clip"].format(t=t, place=place)
    length = ""
    if seconds and seconds > 0:
        length = (
            ph["minutes"].format(seconds // 60)
            if seconds >= 60
            else ph["seconds"].format(seconds)
        )
    return ph["video"].format(t=t, length=length, place=place)


def _document(inp, ph, t, lang):
    doc_type = inp.document_type if inp.document_type in ph["docs"] else "other"
    head = ph["document"].format(t=t, doc=ph["docs"][doc_type])
    shown = display(doc_type, dict(inp.document_fields or {}))
    title, headline = clean(shown["title"]), clean(shown["headline"])
    if title and headline and (title in headline or headline in title):
        title, headline = "", max(title, headline, key=len)
    return _join(ph, head, title, headline)


def _moment(inp, ph, t, lang):
    head = ph["moment"].format(t=t, place=_place(inp, ph))
    tags = [tag for tag in (clean(x) for x in inp.media_tags) if tag][:3]
    return _join(ph, head, *tags)


def _memory_paused(inp, ph, t, lang):
    return ph["memory_paused"].format(t=t)


def _memory_resumed(inp, ph, t, lang):
    return ph["memory_resumed"].format(t=t)


RENDERERS = {
    "encounter": _encounter,
    "conversation_segment": _conversation,
    "voice_query": _voice_query,
    "reminder": _reminder,
    "mind_game_session": _mind_game,
    "manual_note": _manual_note,
    "user_requested_recording": _recording,
    "document_captured": _document,
    "notable_moment_captured": _moment,
    "memory_paused": _memory_paused,
    "memory_resumed": _memory_resumed,
}


def render_event(inp: RenderInput) -> str:
    """One sentence for events.rendered_text. Raises ValueError on programming errors."""
    renderer = RENDERERS.get(inp.event_type)
    if renderer is None:
        raise ValueError(f"Unknown event_type: {inp.event_type!r}")
    lang = output_language(inp)
    return renderer(inp, PHRASES[lang], _time(inp), lang)
