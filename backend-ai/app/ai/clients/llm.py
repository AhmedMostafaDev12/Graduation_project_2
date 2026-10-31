"""Text LLM: Google Gemini Flash, paid tier (docs/MODELS_CHOICE.md §4, §8; phase 7.5).

Implements the `LLM` interface (app/ai/interfaces.py). With a JSON schema, Gemini is asked for
JSON that follows it (`responseJsonSchema`), and the caller still validates every field. The
paid tier is required: the free tier may use prompts to improve Google's products, and these
prompts are patients' conversations (spec §9).

Temporary failures (timeout, 429, 5xx) raise TransientError, which Celery retries. Never log
the messages or the reply (AI_LAYER.md rule 8).
"""

import httpx

from app.config import settings
from app.errors import TransientError

MODEL = "gemini-3.8-flash"
GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
)
ROLES = {"user": "user", "assistant": "model"}  # "system" goes to systemInstruction


class LLMError(Exception):
    """A permanent failure (bad key, bad request, blocked or empty reply): not retried."""


class GeminiLLM:
    model_id = MODEL
    thinking_level: str | None = (
        None  # None = the model's default (best for extraction)
    )

    def __init__(self, api_key: str | None = None, timeout_s: float = 60.0):
        self.api_key = api_key if api_key is not None else settings.gemini_api_key
        if not self.api_key:
            raise LLMError(
                "GEMINI_API_KEY is not set (backend-ai/.env locally, the server's env file in production)"
            )
        self.timeout_s = timeout_s

    def complete(
        self, messages: list[dict[str, str]], json_schema: dict | None = None
    ) -> str:
        system = [m["content"] for m in messages if m["role"] == "system"]
        body: dict = {
            "contents": [
                {"role": ROLES[m["role"]], "parts": [{"text": m["content"]}]}
                for m in messages
                if m["role"] != "system"
            ],
            # extraction must be repeatable, not creative
            "generationConfig": {"temperature": 0.0},
        }
        if system:
            body["systemInstruction"] = {"parts": [{"text": "\n\n".join(system)}]}
        if json_schema is not None:
            body["generationConfig"]["responseMimeType"] = "application/json"
            body["generationConfig"]["responseJsonSchema"] = json_schema
        if self.thinking_level:
            body["generationConfig"]["thinkingConfig"] = {
                "thinkingLevel": self.thinking_level
            }

        return generate(self.api_key, body, self.timeout_s)


class GeminiFastLLM(GeminiLLM):
    """The same model, thinking less: for /assist, where the glasses wait at most 20 s
    (spec D39). Measured on an /assist turn: median 7.9 s → 4.0 s per call."""

    model_id = f"{MODEL}/thinking-low"
    thinking_level = "low"


def generate(api_key: str, body: dict, timeout_s: float) -> str:
    """One generateContent call → the answer's text (shared with clients/vision.py)."""
    try:
        response = httpx.post(
            GEMINI_URL,
            headers={"x-goog-api-key": api_key},
            json=body,
            timeout=timeout_s,
        )
    except (httpx.TimeoutException, httpx.TransportError) as exc:
        raise TransientError(f"Gemini unreachable: {type(exc).__name__}") from exc

    if response.status_code == 429 or response.status_code >= 500:
        raise TransientError(f"Gemini returned {response.status_code}")
    if response.status_code >= 400:
        # the body is Google's error message, never our prompt
        raise LLMError(
            f"Gemini rejected the request ({response.status_code}): {response.text[:200]}"
        )

    candidates = response.json().get("candidates") or []
    if not candidates:
        raise LLMError("Gemini returned no answer (the prompt may have been blocked)")
    candidate = candidates[0]
    parts = (candidate.get("content") or {}).get("parts") or []
    text = "".join(p.get("text", "") for p in parts)
    if not text:
        reason = candidate.get("finishReason", "unknown")
        raise LLMError(f"Gemini returned an empty answer (finishReason {reason})")
    return text
