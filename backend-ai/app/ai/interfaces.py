"""One interface per AI capability the server uses (spec D37, D38, docs/AI_LAYER.md §6).

Services depend on these Protocols, never on a provider SDK, so a model can be swapped by
changing the profile (registry.py) instead of the code. Every implementation exposes
`model_id`, and whatever it produces is stored with that id.

Edge models (gate rules, frame embedder, audio events) run on the glasses and live in
ml/edge/, not here.
"""

from dataclasses import dataclass, field
from typing import Protocol

from app.ai.review_contract import ReviewResult


@dataclass(frozen=True)
class TranscriptSegment:
    start_s: float
    end_s: float
    text: str
    speaker: str | None = None  # diarization label, e.g. "A" (spec D36)


@dataclass(frozen=True)
class Face:
    box: tuple[float, float, float, float]  # x1, y1, x2, y2 in the photo's pixels
    score: float  # detector confidence
    landmarks: tuple[tuple[float, float], ...]  # 5 points: eyes, nose, mouth corners
    embedding: list[float]  # unit length, FACE_DIM


@dataclass(frozen=True)
class Transcript:
    text: str
    language: str  # "ar" | "en" | "mixed"
    model_id: str
    segments: list[TranscriptSegment] = field(default_factory=list)


class SpeechToText(Protocol):
    model_id: str

    def transcribe(
        self, audio: bytes, content_type: str, language_hint: str | None = None
    ) -> Transcript: ...


class TextEmbedder(Protocol):
    model_id: str
    dim: int

    def embed(self, texts: list[str]) -> list[list[float]]: ...


class VisionReviewer(Protocol):
    model_id: str

    def review(self, image: bytes, language: str) -> ReviewResult: ...


class Captioner(Protocol):
    model_id: str

    def caption(self, images: list[bytes], transcript: str, language: str) -> str: ...


class LLM(Protocol):
    model_id: str

    def complete(
        self, messages: list[dict[str, str]], json_schema: dict | None = None
    ) -> str: ...


class FaceEmbedder(Protocol):
    model_id: str
    dim: int

    def faces(self, image: bytes) -> list[Face]:
        """Every face in the photo, most confident first, each embedded (8.2, 8.3)."""
        ...

    def embed_face(self, image: bytes) -> list[float]:
        """The embedding of the most confident face."""
        ...
