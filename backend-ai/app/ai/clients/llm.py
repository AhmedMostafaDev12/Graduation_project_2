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

        try:
            response = httpx.post(
                GEMINI_URL,
                headers={"x-goog-api-key": self.api_key},
                json=body,
                timeout=self.timeout_s,
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
            raise LLMError(
                "Gemini returned no answer (the prompt may have been blocked)"
            )
        candidate = candidates[0]
        parts = (candidate.get("content") or {}).get("parts") or []
        text = "".join(p.get("text", "") for p in parts)
        if not text:
            reason = candidate.get("finishReason", "unknown")
            raise LLMError(f"Gemini returned an empty answer (finishReason {reason})")
        return text
