"""Speech-to-text with speaker labels: Deepgram Nova-3 (spec §7.3, D36, docs/MODELS_CHOICE.md).

Implements the `SpeechToText` interface (app/ai/interfaces.py), so services never touch
Deepgram directly and the provider can be swapped by profile.

One pre-recorded request per audio segment: Egyptian Arabic by default (`ar-EG`), with
diarization and utterances, so every segment comes back with times and a speaker label.
Temporary failures (timeout, 429, 5xx) raise TransientError, which Celery retries.
Never log the transcript (AI_LAYER.md rule 8).
"""

import re

import httpx

from app.ai.interfaces import Transcript, TranscriptSegment
from app.config import settings
from app.errors import TransientError

DEEPGRAM_URL = "https://api.deepgram.com/v1/listen"

# our language hint -> Deepgram BCP-47 code. Patients are Egyptian, so Arabic means ar-EG.
LANGUAGE_CODES = {"ar": "ar-EG", "en": "en"}
DEFAULT_LANGUAGE = "ar"

LATIN = re.compile(r"[A-Za-z]")


class SpeechToTextError(Exception):
    """A permanent failure (bad audio, bad key, unsupported request): not retried."""


def speaker_label(index: int | None) -> str | None:
    """Deepgram numbers speakers 0, 1, 2 …; the journal shows them as A, B, C …"""
    if index is None:
        return None
    return chr(ord("A") + index) if index < 26 else f"S{index}"


def detect_language(text: str, hint: str) -> str:
    """'mixed' when an Arabic transcript also contains Latin words (code-switching)."""
    if hint == "ar" and LATIN.search(text):
        return "mixed"
    return hint


class DeepgramSpeechToText:
    model_id = "deepgram-nova-3"

    def __init__(self, api_key: str | None = None, timeout_s: float = 60.0):
        self.api_key = api_key if api_key is not None else settings.deepgram_api_key
        if not self.api_key:
            raise SpeechToTextError(
                "DEEPGRAM_API_KEY is not set (backend-ai/.env locally, the server's env file in production)"
            )
        self.timeout_s = timeout_s

    def transcribe(
        self, audio: bytes, content_type: str, language_hint: str | None = None
    ) -> Transcript:
        language = (
            language_hint if language_hint in LANGUAGE_CODES else DEFAULT_LANGUAGE
        )
        params = {
            "model": "nova-3",
            "language": LANGUAGE_CODES[language],
            "diarize": "true",
            "utterances": "true",
            "punctuate": "true",
            "smart_format": "true",
        }
        headers = {
            "Authorization": f"Token {self.api_key}",
            "Content-Type": content_type,
        }
        try:
            response = httpx.post(
                DEEPGRAM_URL,
                params=params,
                headers=headers,
                content=audio,
                timeout=self.timeout_s,
            )
        except (httpx.TimeoutException, httpx.TransportError) as exc:
            raise TransientError(f"Deepgram unreachable: {type(exc).__name__}") from exc

        if response.status_code == 429 or response.status_code >= 500:
            raise TransientError(f"Deepgram returned {response.status_code}")
        if response.status_code >= 400:
            # the body is Deepgram's error message, never our audio or transcript
            raise SpeechToTextError(
                f"Deepgram rejected the request ({response.status_code}): {response.text[:200]}"
            )
        return self._parse(response.json(), language)

    def _parse(self, body: dict, language: str) -> Transcript:
        results = body.get("results") or {}
        channels = results.get("channels") or [{}]
        alternatives = channels[0].get("alternatives") or [{}]
        text = (alternatives[0].get("transcript") or "").strip()

        segments = [
            TranscriptSegment(
                start_s=float(u.get("start", 0.0)),
                end_s=float(u.get("end", 0.0)),
                text=(u.get("transcript") or "").strip(),
                speaker=speaker_label(u.get("speaker")),
            )
            for u in results.get("utterances") or []
            if (u.get("transcript") or "").strip()
        ]
        if not text and segments:
            text = " ".join(s.text for s in segments)
        return Transcript(
            text=text,
            language=detect_language(text, language),
            model_id=self.model_id,
            segments=segments,
        )
