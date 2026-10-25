"""Event -> sentence rendering for RAG (track R2). Pure functions: no database needed.

All data is synthetic.
"""

import re
from datetime import UTC, datetime, timedelta

import pytest

from app.ai.rag.render import (
    MAX_QUOTE_CHARS,
    PHRASES,
    RENDERERS,
    PersonRef,
    RenderInput,
    render_event,
)
from app.models.journal import Event

EVENT_TYPES = Event.__table__.c.event_type.type.enums
CAIRO = "Africa/Cairo"
# January: Cairo is UTC+2 (no summer time), so 07:15 UTC -> 09:15 local
T0 = datetime(2026, 1, 15, 7, 15, tzinfo=UTC)

AHMED = PersonRef("أحمد", "ابن")
MONA = PersonRef("منى", "بنت")
SARA = PersonRef("Sara", "nurse")

DIACRITICS = re.compile("[ً-ْٰ]")
ARABIC = re.compile("[؀-ۿ]")
LATIN = re.compile("[A-Za-z]")


def make(event_type: str, lang: str = "en", **kw) -> RenderInput:
    kw.setdefault("occurred_at", T0)
    return RenderInput(
        event_type=event_type,
        patient_language=lang,
        patient_timezone=CAIRO,
        **kw,
    )


def assert_clean(sentence: str) -> None:
    assert sentence
    assert "None" not in sentence
    assert "{" not in sentence and "}" not in sentence
    assert "  " not in sentence
    assert sentence == sentence.strip()
    assert not sentence.endswith((":", ",", "،"))
    assert '""' not in sentence and "()" not in sentence


# ----- coverage of the enum -----


def test_every_event_type_has_a_renderer():
    assert set(RENDERERS) == set(EVENT_TYPES)
    assert len(EVENT_TYPES) == 11


@pytest.mark.parametrize("lang", ["ar", "en"])
@pytest.mark.parametrize("event_type", EVENT_TYPES)
def test_every_event_type_renders_in_both_languages(event_type, lang):
    sentence = render_event(make(event_type, lang))
    assert_clean(sentence)
    assert sentence.startswith("09:15")
    if lang == "ar":
        assert not LATIN.search(sentence)
        assert not DIACRITICS.search(sentence)
    else:
        assert not ARABIC.search(sentence)


def test_phrase_tables_have_the_same_keys():
    assert PHRASES["ar"].keys() == PHRASES["en"].keys()


def test_unknown_event_type_raises():
    with pytest.raises(ValueError):
        render_event(make("dancing"))


# ----- language rule -----


@pytest.mark.parametrize(
    ("event_language", "patient_language", "expected"),
    [
        ("ar", "en", "09:15 قابلت حد مش معروف"),
        ("en", "ar", "09:15 met someone unknown"),
        ("mixed", "ar", "09:15 قابلت حد مش معروف"),
        ("mixed", "en", "09:15 met someone unknown"),
        (None, "ar", "09:15 قابلت حد مش معروف"),
        (None, "en", "09:15 met someone unknown"),
    ],
)
def test_language_rule(event_language, patient_language, expected):
    inp = make("encounter", patient_language, event_language=event_language)
    assert render_event(inp) == expected


# ----- time -----


def test_utc_renders_as_cairo_local_time():
    assert render_event(make("memory_paused")).startswith("09:15 ")


def test_cairo_summer_time():
    summer = datetime(2026, 7, 1, 6, 0, tzinfo=UTC)  # Cairo UTC+3 in summer
    assert render_event(make("memory_paused", occurred_at=summer)).startswith("09:00 ")


def test_span_format():
    inp = make("encounter", person=SARA, ended_at=T0 + timedelta(minutes=25))
    assert render_event(inp) == "09:15–09:40 met Sara (nurse)"


def test_span_within_one_minute_collapses():
    inp = make("encounter", person=SARA, ended_at=T0 + timedelta(seconds=20))
    assert render_event(inp) == "09:15 met Sara (nurse)"


def test_no_span_for_point_events():
    inp = make("memory_paused", ended_at=T0 + timedelta(minutes=5))
    assert render_event(inp) == "09:15 memory recording paused"


def test_naive_datetime_raises():
    with pytest.raises(ValueError):
        render_event(make("memory_paused", occurred_at=datetime(2026, 1, 15, 7, 15)))


def test_unknown_timezone_raises():
    inp = RenderInput(
        event_type="memory_paused",
        occurred_at=T0,
        patient_language="en",
        patient_timezone="Mars/Olympus",
    )
    with pytest.raises(ValueError):
        render_event(inp)


# ----- missing data -----


def test_conversation_without_people_or_transcript():
    assert render_event(make("conversation_segment", "ar")) == "09:15 اتكلمت مع حد"
    assert render_event(make("conversation_segment")) == "09:15 talked with someone"


def test_conversation_without_transcript():
    inp = make("conversation_segment", "ar", person=AHMED)
    assert render_event(inp) == "09:15 اتكلمت مع أحمد (ابن)"


def test_conversation_people_are_deduplicated_and_joined():
    inp = make(
        "conversation_segment",
        "ar",
        person=AHMED,
        present_people=(AHMED, MONA, SARA),
    )
    assert render_event(inp) == "09:15 اتكلمت مع أحمد (ابن)، منى (بنت) وSara (nurse)"
    inp = make("conversation_segment", present_people=(SARA, PersonRef("Omar", "")))
    assert render_event(inp) == "09:15 talked with Sara (nurse) and Omar"


def test_voice_query_without_answer_or_question():
    assert render_event(make("voice_query", transcript_text="where am I?")) == (
        '09:15 asked "where am I?"'
    )
    assert render_event(make("voice_query", "ar")) == "09:15 سألت سؤال"


def test_reminder_without_details():
    assert render_event(make("reminder")) == "09:15 reminder"
    assert render_event(make("reminder", "ar")) == "09:15 تذكير"


def test_generic_reminder():
    inp = make(
        "reminder",
        reminder_type="appointment",
        reminder_title="Dentist",
        reminder_status="completed",
        reminder_confirmed_via="caregiver",
    )
    assert render_event(inp) == (
        "09:15 appointment reminder: Dentist, done (confirmed by the caregiver)"
    )
    inp = make("reminder", "ar", reminder_type="task", reminder_status="missed")
    assert render_event(inp) == "09:15 تذكير: ما اتعملش"


@pytest.mark.parametrize(
    ("lang", "completed", "missed"),
    [
        (
            "ar",
            "09:15 خدت الدوا: حباية الضغط (اتأكد بالصوت)",
            "09:15 ما خدتش الدوا: حباية الضغط",
        ),
        (
            "en",
            "09:15 took medication: Blood pressure pill (confirmed by voice)",
            "09:15 did not take medication: Blood pressure pill",
        ),
    ],
)
def test_medication_completed_and_missed_differ(lang, completed, missed):
    title = "حباية الضغط" if lang == "ar" else "Blood pressure pill"
    base = {"reminder_type": "medication", "reminder_title": title}
    done = render_event(
        make(
            "reminder",
            lang,
            reminder_status="completed",
            reminder_confirmed_via="voice",
            **base,
        )
    )
    not_done = render_event(make("reminder", lang, reminder_status="missed", **base))
    assert done == completed
    assert not_done == missed
    assert done != not_done


@pytest.mark.parametrize("lang", ["ar", "en"])
def test_medication_statuses_are_all_distinct(lang):
    sentences = {
        render_event(
            make("reminder", lang, reminder_type="medication", reminder_status=s)
        )
        for s in ("completed", "missed", "snoozed", "pending", None)
    }
    assert len(sentences) == 5


def test_mind_game_unknown_type_and_no_score():
    inp = make("mind_game_session", "ar", game_type="tetris_pro")
    assert render_event(inp) == "09:15 لعبت لعبة ذاكرة"
    inp = make("mind_game_session", game_type="word_recall", game_score=0)
    assert render_event(inp) == "09:15 played word recall, score 0"


def test_manual_note():
    assert render_event(make("manual_note", transcript_text="Buy bread")) == (
        '09:15 note: "Buy bread"'
    )
    assert render_event(make("manual_note", "ar")) == "09:15 كتبت ملاحظة"


def test_recording_variants():
    assert render_event(make("user_requested_recording", media_type="image")) == (
        "09:15 took a photo"
    )
    inp = make(
        "user_requested_recording", media_type="video", media_duration_seconds=150
    )
    assert render_event(inp) == "09:15 recorded a 2-minute video"
    inp = make("user_requested_recording", "ar", media_type="video")
    assert render_event(inp) == "09:15 سجلت فيديو"
    assert render_event(make("user_requested_recording")) == "09:15 recorded a clip"


def test_document_without_fields():
    assert render_event(make("document_captured", document_type="bill")) == (
        "09:15 took a photo of a bill"
    )
    assert render_event(make("document_captured", "ar")) == "09:15 تصوير ورقة"


def test_document_medication_label_avoids_repeating_the_name():
    inp = make(
        "document_captured",
        document_type="medication_label",
        document_fields={"medication_name": "Concor", "strength": "5 mg"},
    )
    assert render_event(inp) == "09:15 took a photo of a medication label: Concor 5 mg"


def test_document_other_uses_model_title():
    inp = make(
        "document_captured",
        "ar",
        document_type="other",
        document_fields={
            "title": "دعوة فرح",
            "fields": [{"label": "المكان", "value": "قاعة النيل"}],
        },
    )
    assert render_event(inp) == "09:15 تصوير ورقة: دعوة فرح، قاعة النيل"


def test_moment_tags():
    inp = make(
        "notable_moment_captured", "ar", media_tags=("ورد", "", "شمس", "قطة", "بحر")
    )
    assert render_event(inp) == "09:15 تصوير لحظة مهمة: ورد، شمس، قطة"


# ----- place -----


@pytest.mark.parametrize(
    ("event_type", "kw", "without", "with_place"),
    [
        (
            "encounter",
            {"person": SARA},
            "09:15 met Sara (nurse)",
            "09:15 met Sara (nurse) at Home",
        ),
        (
            "conversation_segment",
            {"person": SARA, "transcript_text": "hello"},
            '09:15 talked with Sara (nurse): "hello"',
            '09:15 talked with Sara (nurse) at Home: "hello"',
        ),
        (
            "user_requested_recording",
            {"media_type": "video", "media_duration_seconds": 12},
            "09:15 recorded a 12-second video",
            "09:15 recorded a 12-second video at Home",
        ),
        (
            "notable_moment_captured",
            {"media_tags": ("garden",)},
            "09:15 captured a special moment: garden",
            "09:15 captured a special moment at Home: garden",
        ),
    ],
)
def test_place_en(event_type, kw, without, with_place):
    assert render_event(make(event_type, **kw)) == without
    assert render_event(make(event_type, place_name="Home", **kw)) == with_place


def test_place_ar():
    inp = make("encounter", "ar", person=AHMED, place_name="البيت")
    assert render_event(inp) == "09:15 قابلت أحمد (ابن) في البيت"
    inp = make("encounter", "ar", place_name="النادي")
    assert render_event(inp) == "09:15 قابلت حد مش معروف في النادي"


def test_place_ignored_for_other_types():
    inp = make("memory_resumed", place_name="Home")
    assert render_event(inp) == "09:15 memory recording resumed"


# ----- inserted text: verbatim except diacritics -----


def test_names_and_transcript_verbatim():
    transcript = "Ahmed: Mom, the doctor's appointment is tomorrow at 5."
    inp = make(
        "conversation_segment",
        person=PersonRef("Ahmed Mostafa-Ali", "eldest son"),
        transcript_text=transcript,
    )
    sentence = render_event(inp)
    assert "Ahmed Mostafa-Ali (eldest son)" in sentence
    assert f'"{transcript}"' in sentence


def test_whitespace_is_collapsed():
    inp = make("manual_note", transcript_text="  Buy\n bread\tand   milk ")
    assert render_event(inp) == '09:15 note: "Buy bread and milk"'


def test_diacritics_are_stripped_from_inserted_text():
    inp = make(
        "conversation_segment",
        "ar",
        person=PersonRef("أَحْمَد", "اِبْنِي"),
        transcript_text="إِزَّيَّك يَا مَامَا",
        place_name="البَيْت",
    )
    sentence = render_event(inp)
    assert sentence == '09:15 اتكلمت مع أحمد (ابني) في البيت: "إزيك يا ماما"'
    assert not DIACRITICS.search(sentence)


def test_diacritics_stripped_everywhere():
    fatha = "َ"
    inputs = [
        make("voice_query", "ar", transcript_text=f"مِين{fatha}", query_answer="دَه"),
        make("reminder", "ar", reminder_type="medication", reminder_title="دَوَا"),
        make(
            "document_captured",
            "ar",
            document_type="receipt",
            document_fields={"merchant": "صَيْدَلِيَّة"},
        ),
        make("notable_moment_captured", "ar", media_tags=("وَرْد",)),
        make("encounter", "ar", person=PersonRef("سٰلْمَى", "أُخْت")),
    ]
    for inp in inputs:
        assert not DIACRITICS.search(render_event(inp))


def test_long_transcript_is_capped_at_a_word_boundary():
    words = ["كلمة"] * 200
    transcript = " ".join(words)
    inp = make("conversation_segment", "ar", person=AHMED, transcript_text=transcript)
    sentence = render_event(inp)
    quoted = sentence.split(': "', 1)[1].rstrip('"')
    assert quoted.endswith("…")
    body = quoted[:-1]
    assert len(body) <= MAX_QUOTE_CHARS
    assert transcript.startswith(body)
    assert not body.endswith(" ")
    assert transcript[len(body)] == " "  # cut between words


def test_short_transcript_is_not_cut():
    text = "x" * MAX_QUOTE_CHARS
    assert render_event(make("manual_note", transcript_text=text)) == (
        f'09:15 note: "{text}"'
    )


# ----- seed-like day (Fatma, Cairo) -----


def at(hour: int, minute: int, second: int = 0) -> datetime:
    """Cairo winter local time as UTC."""
    return datetime(2026, 1, 15, hour - 2, minute, second, tzinfo=UTC)


SEED_LIKE = [
    (
        make(
            "reminder",
            occurred_at=at(9, 2),
            reminder_type="medication",
            reminder_title="Blood pressure pill",
            reminder_status="completed",
            reminder_confirmed_via="voice",
        ),
        "09:02 took medication: Blood pressure pill (confirmed by voice)",
    ),
    (
        make(
            "encounter", "ar", occurred_at=at(9, 15), ended_at=at(9, 40), person=AHMED
        ),
        "09:15–09:40 قابلت أحمد (ابن)",
    ),
    (
        make(
            "conversation_segment",
            "en",
            occurred_at=at(9, 20),
            ended_at=at(9, 24),
            event_language="ar",
            present_people=(AHMED,),
            transcript_text="أحمد: ماما، ميعاد الدكتور بكره الساعة خمسة، هاجي آخدك.",
        ),
        '09:20–09:24 اتكلمت مع أحمد (ابن): "أحمد: ماما، ميعاد الدكتور بكره الساعة خمسة، هاجي آخدك."',
    ),
    (
        make(
            "voice_query",
            "ar",
            occurred_at=at(10, 2),
            event_language="ar",
            transcript_text="مين ده؟",
            query_answer="ده أحمد، ابنك",
        ),
        '10:02 سألت "مين ده؟" واتقالي "ده أحمد، ابنك"',
    ),
    (
        make(
            "user_requested_recording",
            occurred_at=at(11, 30),
            ended_at=at(11, 30, 12),
            media_type="video",
        ),
        "11:30 recorded a 12-second video",
    ),
    (
        make(
            "document_captured",
            occurred_at=at(11, 45),
            document_type="receipt",
            document_fields={
                "merchant": "صيدلية",
                "total": {"amount": 120, "currency": "EGP"},
                "items": ["Concor 5 mg x1"],
            },
        ),
        "11:45 took a photo of a receipt: صيدلية, 120 EGP",
    ),
    (
        make(
            "notable_moment_captured",
            occurred_at=at(11, 50),
            media_tags=("garden",),
        ),
        "11:50 captured a special moment: garden",
    ),
    (
        make("memory_paused", "ar", occurred_at=at(12, 5)),
        "12:05 إيقاف تسجيل الذاكرة",
    ),
    (
        make(
            "mind_game_session",
            occurred_at=at(17, 10),
            game_type="card_match",
            game_score=8,
        ),
        "17:10 played card match, score 8",
    ),
]


@pytest.mark.parametrize(("inp", "expected"), SEED_LIKE)
def test_seed_like_events(inp, expected):
    assert render_event(inp) == expected


def test_render_is_deterministic():
    for inp, _ in SEED_LIKE:
        assert render_event(inp) == render_event(inp)
