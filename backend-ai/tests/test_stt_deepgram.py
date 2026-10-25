"""Phase 7.1: Deepgram speech-to-text client (spec §7.3, D36). Deepgram is always mocked:
tests never call a real AI API (AI_LAYER.md rule 9)."""

import httpx
import pytest
import respx

from app.ai.clients.stt import (
    DEEPGRAM_URL,
    DeepgramSpeechToText,
    SpeechToTextError,
    detect_language,
    speaker_label,
)
from app.ai.registry import build
from app.errors import TransientError

# trimmed real-shape response: two speakers, Egyptian Arabic
DIARIZED = {
    "metadata": {"request_id": "r1"},
    "results": {
        "channels": [
            {
                "alternatives": [
                    {
                        "transcript": "ميعاد الدكتور بكره الساعة خمسة. تمام هروح.",
                        "confidence": 0.93,
                    }
                ]
            }
        ],
        "utterances": [
            {
                "start": 0.4,
                "end": 2.9,
                "speaker": 0,
                "transcript": "ميعاد الدكتور بكره الساعة خمسة.",
            },
            {"start": 3.1, "end": 4.6, "speaker": 1, "transcript": "تمام هروح."},
            {"start": 4.7, "end": 4.8, "speaker": 1, "transcript": "  "},
        ],
    },
}


@pytest.fixture
def stt():
    return DeepgramSpeechToText(api_key="test-key", timeout_s=5)


@respx.mock
def test_transcribes_egyptian_arabic_with_speaker_labels(stt):
    route = respx.post(DEEPGRAM_URL).mock(
        return_value=httpx.Response(200, json=DIARIZED)
    )

    result = stt.transcribe(b"opus-bytes", "audio/ogg", language_hint="ar")

    assert result.text == "ميعاد الدكتور بكره الساعة خمسة. تمام هروح."
    assert result.language == "ar"
    assert result.model_id == "deepgram-nova-3"
    assert [(s.speaker, s.start_s, s.end_s) for s in result.segments] == [
        ("A", 0.4, 2.9),
        ("B", 3.1, 4.6),
    ]  # the empty utterance is dropped

    request = route.calls.last.request
    assert request.url.params["model"] == "nova-3"
    assert request.url.params["language"] == "ar-EG"
    assert request.url.params["diarize"] == "true"
    assert request.url.params["utterances"] == "true"
    assert request.headers["Authorization"] == "Token test-key"
    assert request.headers["Content-Type"] == "audio/ogg"
    assert request.content == b"opus-bytes"


@respx.mock
def test_language_defaults_to_egyptian_and_english_is_supported(stt):
    route = respx.post(DEEPGRAM_URL).mock(
        return_value=httpx.Response(200, json=DIARIZED)
    )
    stt.transcribe(b"a", "audio/ogg")
    assert route.calls.last.request.url.params["language"] == "ar-EG"
    stt.transcribe(b"a", "audio/ogg", language_hint="en")
    assert route.calls.last.request.url.params["language"] == "en"


@respx.mock
def test_empty_audio_gives_an_empty_transcript(stt):
    respx.post(DEEPGRAM_URL).mock(
        return_value=httpx.Response(
            200, json={"results": {"channels": [{"alternatives": [{}]}]}}
        )
    )
    result = stt.transcribe(b"a", "audio/ogg")
    assert result.text == "" and result.segments == []


@pytest.mark.parametrize("status", [429, 500, 503])
@respx.mock
def test_rate_limits_and_server_errors_are_retried(stt, status):
    respx.post(DEEPGRAM_URL).mock(return_value=httpx.Response(status))
    with pytest.raises(TransientError):
        stt.transcribe(b"a", "audio/ogg")


@respx.mock
def test_timeouts_are_retried(stt):
    respx.post(DEEPGRAM_URL).mock(side_effect=httpx.ReadTimeout("slow"))
    with pytest.raises(TransientError):
        stt.transcribe(b"a", "audio/ogg")


@pytest.mark.parametrize("status", [400, 401, 403])
@respx.mock
def test_bad_requests_are_not_retried(stt, status):
    respx.post(DEEPGRAM_URL).mock(
        return_value=httpx.Response(status, json={"err_msg": "nope"})
    )
    with pytest.raises(SpeechToTextError):
        stt.transcribe(b"a", "audio/ogg")


def test_missing_key_fails_at_start():
    with pytest.raises(SpeechToTextError, match="DEEPGRAM_API_KEY"):
        DeepgramSpeechToText(api_key="")


def test_helpers():
    assert speaker_label(0) == "A" and speaker_label(2) == "C"
    assert speaker_label(None) is None and speaker_label(30) == "S30"
    assert detect_language("ميعاد الـ appointment بكره", "ar") == "mixed"
    assert detect_language("ميعاد بكره", "ar") == "ar"
    assert detect_language("see you tomorrow", "en") == "en"


def test_registry_builds_deepgram_when_chosen(monkeypatch):
    monkeypatch.setattr("app.ai.clients.stt.settings.deepgram_api_key", "test-key")
    ai = build("stub", {"stt": "deepgram-nova-3"})
    assert isinstance(ai.stt, DeepgramSpeechToText)
    assert ai.stt.model_id == "deepgram-nova-3"
