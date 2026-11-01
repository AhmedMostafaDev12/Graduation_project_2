"""Text embeddings: Voyage `voyage-4`, 1024-d (spec D15, docs/MODELS_CHOICE.md §5).

Implements the `TextEmbedder` interface (app/ai/interfaces.py). One request embeds a batch of
sentences. Two providers, both asked for TEXT_DIM dimensions so they fit the same columns:

- `VoyageTextEmbedder` (production): free allowance of 200M tokens, data not used for
  training once opted out in the Voyage dashboard. Sentences are embedded as "document",
  questions and search texts (/assist, phase 9.1) as "query".
- `OpenAITextEmbedder`: `text-embedding-3-small` shortened to TEXT_DIM, kept as an alternative.

Vectors from different models can't be compared: changing provider means re-embedding
everything. Temporary failures (timeout, 429, 5xx) raise TransientError, which Celery
retries. Never log the texts (AI_LAYER.md rule 8).
"""

import httpx

from app.config import settings
from app.errors import TransientError
from app.models import TEXT_DIM

VOYAGE_EMBEDDINGS_URL = "https://api.voyageai.com/v1/embeddings"
OPENAI_EMBEDDINGS_URL = "https://api.openai.com/v1/embeddings"
MAX_BATCH = 100  # inputs per request; the service sends at most this many


class EmbeddingError(Exception):
    """A permanent failure (bad key, bad request): not retried."""


def _key(value: str | None, variable: str) -> str:
    if not value:
        raise EmbeddingError(
            f"{variable} is not set (backend-ai/.env locally, the server's env file in production)"
        )
    return value


def _post(
    provider: str, url: str, api_key: str, body: dict, count: int, timeout_s: float
) -> list[list[float]]:
    """One embeddings request (both providers use the same response shape)."""
    try:
        response = httpx.post(
            url,
            headers={"Authorization": f"Bearer {api_key}"},
            json=body,
            timeout=timeout_s,
        )
    except (httpx.TimeoutException, httpx.TransportError) as exc:
        raise TransientError(f"{provider} unreachable: {type(exc).__name__}") from exc

    if response.status_code == 429 or response.status_code >= 500:
        raise TransientError(f"{provider} returned {response.status_code}")
    if response.status_code >= 400:
        # the body is the provider's error message, never our texts
        raise EmbeddingError(
            f"{provider} rejected the request ({response.status_code}): {response.text[:200]}"
        )

    data = sorted(response.json()["data"], key=lambda item: item["index"])
    vectors = [item["embedding"] for item in data]
    if len(vectors) != count or any(len(v) != TEXT_DIM for v in vectors):
        raise EmbeddingError(
            f"{provider} returned an unexpected number or size of vectors"
        )
    return vectors


def _check(texts: list[str]) -> None:
    if len(texts) > MAX_BATCH:
        raise EmbeddingError(f"at most {MAX_BATCH} texts per call")


class VoyageTextEmbedder:
    model_id = "voyage-4"
    dim = TEXT_DIM

    def __init__(self, api_key: str | None = None, timeout_s: float = 30.0):
        self.api_key = _key(
            api_key if api_key is not None else settings.voyage_api_key,
            "VOYAGE_API_KEY",
        )
        self.timeout_s = timeout_s

    def embed(self, texts: list[str]) -> list[list[float]]:
        return self._embed(texts, "document")

    def embed_query(self, text: str) -> list[float]:
        """Questions use Voyage's "query" side, matched against stored "document" vectors."""
        return self._embed([text], "query")[0]

    def _embed(self, texts: list[str], input_type: str) -> list[list[float]]:
        if not texts:
            return []
        _check(texts)
        body = {
            "model": self.model_id,
            "input": texts,
            "input_type": input_type,
            "output_dimension": self.dim,
        }
        return _post(
            "Voyage",
            VOYAGE_EMBEDDINGS_URL,
            self.api_key,
            body,
            len(texts),
            self.timeout_s,
        )


class OpenAITextEmbedder:
    model_id = "openai-text-embedding-3-small"
    dim = TEXT_DIM

    def __init__(self, api_key: str | None = None, timeout_s: float = 30.0):
        self.api_key = _key(
            api_key if api_key is not None else settings.openai_api_key,
            "OPENAI_API_KEY",
        )
        self.timeout_s = timeout_s

    def embed_query(self, text: str) -> list[float]:
        return self.embed([text])[0]  # OpenAI has one side for both

    def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        _check(texts)
        body = {
            "model": "text-embedding-3-small",
            "input": texts,
            "dimensions": self.dim,
        }
        return _post(
            "OpenAI",
            OPENAI_EMBEDDINGS_URL,
            self.api_key,
            body,
            len(texts),
            self.timeout_s,
        )
