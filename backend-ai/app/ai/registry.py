"""Pick the AI models by profile (spec D37, docs/AI_LAYER.md §6).

    AI_PROFILE=production  cloud models: the product
    AI_PROFILE=small       open models: the research experiments (RESEARCH_PLAN H5)
    AI_PROFILE=stub        deterministic fakes: tests and local work (the default)

One capability can be overridden, e.g. AI_LLM=fake. `get_ai()` builds the models once per
process and caches them (AI_LAYER.md rule 4). Services call get_ai().stt.transcribe(...),
never a provider SDK.

Adding a provider = a class implementing the interface + one entry in PROVIDERS.
"""

from dataclasses import dataclass
from functools import lru_cache

from app.ai import fakes
from app.ai.clients.embeddings import OpenAITextEmbedder, VoyageTextEmbedder
from app.ai.clients.groq import (
    GroqLLM,
    GroqVisionReviewer,
    SelfHostedLLM,
    SelfHostedVisionReviewer,
)
from app.ai.clients.llm import GeminiFastLLM, GeminiLLM
from app.ai.clients.stt import DeepgramSpeechToText
from app.ai.clients.vision import GeminiVisionReviewer
from app.ai.inference.face_onnx import OnnxFaceEmbedder
from app.ai.interfaces import (
    LLM,
    Captioner,
    FaceEmbedder,
    SpeechToText,
    TextEmbedder,
    VisionReviewer,
)
from app.config import settings

CAPABILITIES = (
    "stt",
    "text_embedder",
    "vision",
    "captioner",
    "llm",
    "assist_llm",
    "face",
)

# provider name for every capability, per profile
PROFILES: dict[str, dict[str, str]] = {
    "stub": {
        "stt": "fake",
        "text_embedder": "fake",
        "vision": "fake",
        "captioner": "fake",
        "llm": "fake",
        "assist_llm": "fake",
        "face": "stub",
    },
    "production": {
        "stt": "deepgram-nova-3",
        "text_embedder": "voyage-4",
        "vision": "gemini-flash",
        "captioner": "cloud-vision",
        "llm": "gemini-flash",
        "assist_llm": "gemini-flash-fast",
        "face": "mobilefacenet-onnx",
    },
    "small": {
        "stt": "local-whisperx",
        "text_embedder": "local-multilingual",
        "vision": "local-qwen2.5-vl",
        "captioner": "local-qwen2.5-vl",
        "llm": "local-llm",
        "assist_llm": "local-llm",
        "face": "mobilefacenet-onnx",
    },
}

# the implementations that exist today; real clients are added from Phase 7.1 on
PROVIDERS: dict[str, dict[str, type]] = {
    "stt": {"fake": fakes.FakeSpeechToText, "deepgram-nova-3": DeepgramSpeechToText},
    "text_embedder": {
        "fake": fakes.FakeTextEmbedder,
        "voyage-4": VoyageTextEmbedder,
        "openai-text-embedding-3-small": OpenAITextEmbedder,
    },
    "vision": {
        "fake": fakes.FakeVisionReviewer,
        "gemini-flash": GeminiVisionReviewer,
        "groq-qwen": GroqVisionReviewer,
        "selfhosted-qwen": SelfHostedVisionReviewer,
    },
    "captioner": {"fake": fakes.FakeCaptioner},
    "llm": {
        "fake": fakes.FakeLLM,
        "gemini-flash": GeminiLLM,
        "groq-qwen": GroqLLM,
        "selfhosted-qwen": SelfHostedLLM,
    },
    # the /assist agent: speed matters (the glasses wait at most 20 s, spec D39)
    "assist_llm": {
        "fake": fakes.FakeLLM,
        "gemini-flash": GeminiLLM,
        "gemini-flash-fast": GeminiFastLLM,
        "groq-qwen": GroqLLM,
        "selfhosted-qwen": SelfHostedLLM,
    },
    "face": {"stub": fakes.StubFaceEmbedder, "mobilefacenet-onnx": OnnxFaceEmbedder},
}


class ProviderNotAvailable(RuntimeError):
    """The chosen profile or override names a provider that isn't implemented yet."""


@dataclass(frozen=True)
class AIModels:
    stt: SpeechToText
    text_embedder: TextEmbedder
    vision: VisionReviewer
    captioner: Captioner
    llm: LLM
    assist_llm: LLM
    face: FaceEmbedder


def choose_providers(
    profile: str, overrides: dict[str, str | None] | None = None
) -> dict[str, str]:
    if profile not in PROFILES:
        raise ProviderNotAvailable(
            f"Unknown AI_PROFILE {profile!r}; use one of {sorted(PROFILES)}"
        )
    chosen = dict(PROFILES[profile])
    for capability, provider in (overrides or {}).items():
        if capability not in CAPABILITIES:
            raise ProviderNotAvailable(f"Unknown AI capability {capability!r}")
        if provider:
            chosen[capability] = provider
    return chosen


def build(profile: str, overrides: dict[str, str | None] | None = None) -> AIModels:
    models = {}
    for capability, provider in choose_providers(profile, overrides).items():
        cls = PROVIDERS[capability].get(provider)
        if cls is None:
            raise ProviderNotAvailable(
                f"AI provider {provider!r} for {capability!r} isn't implemented yet. "
                f"Available: {sorted(PROVIDERS[capability])}. "
                "Use AI_PROFILE=stub or override this capability."
            )
        try:
            models[capability] = cls()
        except Exception as exc:  # e.g. a missing API key
            raise ProviderNotAvailable(
                f"AI provider {provider!r} for {capability!r} couldn't start: {exc}"
            ) from exc
    return AIModels(**models)


def overrides_from_settings() -> dict[str, str | None]:
    return {
        "stt": settings.ai_stt,
        "text_embedder": settings.ai_text_embedder,
        "vision": settings.ai_vision,
        "captioner": settings.ai_captioner,
        "llm": settings.ai_llm,
        "assist_llm": settings.ai_assist_llm,
        "face": settings.ai_face,
    }


@lru_cache(maxsize=1)
def get_ai() -> AIModels:
    return build(settings.ai_profile, overrides_from_settings())
