"""Deterministic fakes for the `stub` profile: tests and local work without API keys.

They return the right shapes and dimensions and the same output for the same input, so
tests are repeatable. They never call the network.
"""

import hashlib
import json
import math
import random

from app.ai.inference import face
from app.ai.interfaces import Face, Transcript, TranscriptSegment
from app.ai.review_contract import ReviewResult
from app.models import FACE_DIM, TEXT_DIM


def unit_vector(seed: bytes, dim: int) -> list[float]:
    rng = random.Random(hashlib.sha256(seed).digest())
    vector = [rng.gauss(0.0, 1.0) for _ in range(dim)]
    norm = math.sqrt(sum(x * x for x in vector))
    return [x / norm for x in vector]


class FakeSpeechToText:
    model_id = "fake-stt"

    def transcribe(
        self, audio: bytes, content_type: str, language_hint: str | None = None
    ) -> Transcript:
        language = language_hint or "ar"
        text = "كلام تجريبي" if language == "ar" else "test speech"
        return Transcript(
            text=text,
            language=language,
            model_id=self.model_id,
            segments=[TranscriptSegment(0.0, 2.0, text, speaker="A")],
        )


class FakeTextEmbedder:
    model_id = "fake-text-embedder"
    dim = TEXT_DIM

    def embed(self, texts: list[str]) -> list[list[float]]:
        return [unit_vector(t.encode("utf-8"), self.dim) for t in texts]

    def embed_query(self, text: str) -> list[float]:
        return self.embed([text])[0]


VISUAL_DIM = 512


def fake_visual_vector(words: str) -> list[float]:
    """A deterministic bag of words: texts sharing words point the same way, so tests can build
    frame vectors from words ("pizza box on the blanket") and find them by a question."""
    total = [0.0] * VISUAL_DIM
    for word in words.lower().split():
        for i, x in enumerate(unit_vector(word.encode("utf-8"), VISUAL_DIM)):
            total[i] += x
    norm = sum(x * x for x in total) ** 0.5 or 1.0
    return [x / norm for x in total]


class FakeVisualTextEmbedder:
    model_id = "fake-visual"
    dim = VISUAL_DIM

    def embed_text(self, texts: list[str]) -> list[list[float]]:
        return [fake_visual_vector(t) for t in texts]


class FakeVisionReviewer:
    model_id = "fake-vision"

    def review(self, image: bytes, language: str) -> ReviewResult:
        return ReviewResult(
            keep=True, category="notable_moment", tags=["test"], reason="fake review"
        )


class FakeCaptioner:
    model_id = "fake-captioner"

    def caption(self, images: list[bytes], transcript: str, language: str) -> str:
        return "صورة تجريبية" if language == "ar" else f"{len(images)} test frame(s)"


class FakeLLM:
    model_id = "fake-llm"

    def complete(
        self, messages: list[dict[str, str]], json_schema: dict | None = None
    ) -> str:
        if json_schema is not None:
            return json.dumps({})
        return "fake answer"


class StubFaceEmbedder:
    """The existing enrollment stub (inference/face.py), behind the FaceEmbedder interface."""

    model_id = face.MODEL_VERSION
    dim = FACE_DIM

    def faces(self, image: bytes) -> list[Face]:
        # one "face" covering the whole photo: no detection in the stub
        return [Face((0.0, 0.0, 1.0, 1.0), 1.0, (), face.embed_face(image))]

    def embed_face(self, image: bytes) -> list[float]:
        return face.embed_face(image)
