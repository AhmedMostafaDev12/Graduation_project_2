"""Groq (OpenAI-compatible): Qwen3.6-27B for text and photo review (MODELS_CHOICE.md §3, §4).

Implements the `LLM` and `VisionReviewer` interfaces with one Groq model (GROQ_MODEL, default
`qwen/qwen3.6-27b`, which reads images). Groq doesn't train on inputs or outputs and keeps no
inference data by default; turn on Zero Data Retention in the console's Data Controls before
real data (spec §9).

- JSON answers use Groq's `json_schema` mode; a model that refuses the schema gets JSON mode
  with the schema written in the prompt instead. The caller still validates every field.
- The model's own reasoning is hidden (`reasoning_format: hidden`); any `<think>` block that
  slips through is removed.
- Photos are shrunk to 1024 px (image tokens are billed).

Temporary failures (timeout, 429, 5xx) raise TransientError, which Celery retries. Never log
the messages, the photo or the reply (AI_LAYER.md rule 8).
"""

import base64
import json
import re

import httpx

from app.ai.clients.llm import LLMError
from app.ai.clients.vision import LANGUAGE_NAMES, REVIEW_SCHEMA, parse_review, to_jpeg
from app.ai.clients.vision import PROMPT as REVIEW_PROMPT
from app.ai.memory.extract import load_prompt
from app.ai.review_contract import ReviewResult
from app.config import settings
from app.errors import TransientError

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
PHOTO_SIDE = 1024  # pixels
THINK = re.compile(r"<think>.*?</think>", re.DOTALL)


class GroqError(LLMError):
    """A permanent failure (bad key, bad request, empty reply): not retried."""


def _key(api_key: str | None) -> str:
    key = api_key if api_key is not None else settings.groq_api_key
    if not key:
        raise GroqError(
            "GROQ_API_KEY is not set (backend-ai/.env locally, the server's env file in production)"
        )
    return key


def _schema_refused(response: httpx.Response) -> bool:
    return response.status_code == 400 and (
        "response_format" in response.text or "json_schema" in response.text
    )


class _GroqChat:
    provider = "Groq"

    def __init__(self, api_key: str | None = None, timeout_s: float = 60.0):
        self.api_key = _key(api_key)
        self.model = settings.groq_model
        self.url = GROQ_URL
        self.timeout_s = timeout_s

    def _extra(self) -> dict:
        """Provider-specific request fields: Groq hides the model's reasoning."""
        return {"reasoning_format": "hidden"}

    def _chat(self, messages: list[dict], json_schema: dict | None) -> str:
        body: dict = {
            "model": self.model,
            "messages": messages,
            "temperature": 0,
            **self._extra(),
        }
        if json_schema is not None:
            body["response_format"] = {
                "type": "json_schema",
                "json_schema": {"name": "answer", "schema": json_schema},
            }
        response = self._post(body)
        if json_schema is not None and _schema_refused(response):
            # best effort: JSON mode, with the schema spelled out for the model
            body["response_format"] = {"type": "json_object"}
            body["messages"] = [
                {
                    "role": "system",
                    "content": "Answer with one JSON object following this JSON schema:\n"
                    + json.dumps(json_schema),
                },
                *messages,
            ]
            response = self._post(body)
        if response.status_code == 429 or response.status_code >= 500:
            raise TransientError(f"{self.provider} returned {response.status_code}")
        if response.status_code >= 400:
            # the body is the server's error message, never our prompt
            raise GroqError(
                f"{self.provider} rejected the request ({response.status_code}): "
                f"{response.text[:200]}"
            )
        choices = response.json().get("choices") or []
        text = THINK.sub(
            "", (choices[0]["message"].get("content") or "") if choices else ""
        )
        if not text.strip():
            raise GroqError(f"{self.provider} returned an empty answer")
        return text.strip()

    def _post(self, body: dict) -> httpx.Response:
        try:
            return httpx.post(
                self.url,
                headers={"Authorization": f"Bearer {self.api_key}"},
                json=body,
                timeout=self.timeout_s,
            )
        except (httpx.TimeoutException, httpx.TransportError) as exc:
            raise TransientError(
                f"{self.provider} unreachable: {type(exc).__name__}"
            ) from exc


class GroqLLM(_GroqChat):
    """`LLM` on Groq: consolidation, the /assist agent, summaries."""

    @property
    def model_id(self) -> str:
        return f"groq/{self.model}"

    def complete(
        self, messages: list[dict[str, str]], json_schema: dict | None = None
    ) -> str:
        return self._chat(list(messages), json_schema)


class GroqVisionReviewer(_GroqChat):
    """`VisionReviewer` on Groq: the same review prompt and contract as Gemini (D29)."""

    def __init__(self, api_key: str | None = None, timeout_s: float = 90.0):
        super().__init__(api_key, timeout_s)

    @property
    def model_id(self) -> str:
        return f"groq/{self.model}/{REVIEW_PROMPT}"

    def review(self, image: bytes, language: str) -> ReviewResult:
        photo = base64.b64encode(to_jpeg(image, PHOTO_SIDE)).decode("ascii")
        messages = [
            {"role": "system", "content": load_prompt(REVIEW_PROMPT)},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{photo}"},
                    },
                    {
                        "type": "text",
                        "text": "The patient's language: "
                        + LANGUAGE_NAMES.get(language, language),
                    },
                ],
            },
        ]
        return parse_review(self._chat(messages, REVIEW_SCHEMA))


# ----- the same model served by our own vLLM (e.g. on Lightning AI; ml/replay/LIGHTNING.md) -----


class _SelfHosted:
    """Point the Groq client at an OpenAI-compatible vLLM server we run ourselves:
    SELFHOSTED_BASE_URL (…/v1), SELFHOSTED_API_KEY (vLLM's --api-key), SELFHOSTED_MODEL.
    Thinking is switched off (Qwen3.6's chat template), which makes photo review faster."""

    provider = "self-hosted vLLM"

    def _configure(self, timeout_s: float) -> None:
        if not settings.selfhosted_base_url:
            raise GroqError(
                "SELFHOSTED_BASE_URL is not set (the vLLM server's …/v1 address)"
            )
        self.api_key = settings.selfhosted_api_key or "none"
        self.model = settings.selfhosted_model
        self.url = settings.selfhosted_base_url.rstrip("/") + "/chat/completions"
        self.timeout_s = timeout_s

    def _extra(self) -> dict:
        return {"chat_template_kwargs": {"enable_thinking": False}}


class SelfHostedLLM(_SelfHosted, GroqLLM):
    def __init__(self, timeout_s: float = 120.0):
        self._configure(timeout_s)

    @property
    def model_id(self) -> str:
        return f"selfhosted/{self.model}"


class SelfHostedVisionReviewer(_SelfHosted, GroqVisionReviewer):
    def __init__(self, timeout_s: float = 180.0):
        self._configure(timeout_s)

    @property
    def model_id(self) -> str:
        return f"selfhosted/{self.model}/{REVIEW_PROMPT}"
