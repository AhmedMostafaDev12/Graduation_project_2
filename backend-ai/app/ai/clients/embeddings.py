"""Text embeddings: OpenAI text-embedding-3-small, 1536-d (spec D15, docs/MODELS_CHOICE.md §5).

Implements the `TextEmbedder` interface (app/ai/interfaces.py). One request embeds a batch of
sentences. Temporary failures (timeout, 429, 5xx) raise TransientError, which Celery retries.
Never log the texts (AI_LAYER.md rule 8).
"""

import httpx

from app.config import settings
from app.errors import TransientError
from app.models import TEXT_DIM

OPENAI_EMBEDDINGS_URL = "https://api.openai.com/v1/embeddings"
MODEL = "text-embedding-3-small"
MAX_BATCH = 100  # inputs per request; the service sends at most this many


class EmbeddingError(Exception):
    """A permanent failure (bad key, bad request): not retried."""


class OpenAITextEmbedder:
    model_id = "openai-text-embedding-3-small"
    dim = TEXT_DIM

    def __init__(self, api_key: str | None = None, timeout_s: float = 30.0):
        self.api_key = api_key if api_key is not None else settings.openai_api_key
        if not self.api_key:
            raise EmbeddingError(
                "OPENAI_API_KEY is not set (backend-ai/.env locally, the server's env file in production)"
            )
        self.timeout_s = timeout_s

    def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        if len(texts) > MAX_BATCH:
            raise EmbeddingError(f"at most {MAX_BATCH} texts per call")
        try:
            response = httpx.post(
                OPENAI_EMBEDDINGS_URL,
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={"model": MODEL, "input": texts},
                timeout=self.timeout_s,
            )
        except (httpx.TimeoutException, httpx.TransportError) as exc:
            raise TransientError(f"OpenAI unreachable: {type(exc).__name__}") from exc

        if response.status_code == 429 or response.status_code >= 500:
            raise TransientError(f"OpenAI returned {response.status_code}")
        if response.status_code >= 400:
            # the body is OpenAI's error message, never our texts
            raise EmbeddingError(
                f"OpenAI rejected the request ({response.status_code}): {response.text[:200]}"
            )

        data = sorted(response.json()["data"], key=lambda item: item["index"])
        vectors = [item["embedding"] for item in data]
        if len(vectors) != len(texts) or any(len(v) != self.dim for v in vectors):
            raise EmbeddingError(
                "OpenAI returned an unexpected number or size of vectors"
            )
        return vectors
