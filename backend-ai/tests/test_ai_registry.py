"""Phase 7.0: AI interfaces, fakes and the profile registry (spec D37, D38, AI_LAYER.md §6)."""

import pytest

from app.ai import registry
from app.ai.clients.llm import GeminiFastLLM
from app.ai.inference import face
from app.ai.registry import ProviderNotAvailable, build, choose_providers
from app.ai.review_contract import ReviewResult
from app.models import FACE_DIM, TEXT_DIM


def test_stub_profile_builds_every_capability():
    ai = build("stub")
    for capability in registry.CAPABILITIES:
        assert getattr(ai, capability).model_id


def test_default_profile_is_stub():
    registry.get_ai.cache_clear()
    assert registry.get_ai().llm.model_id == "fake-llm"
    assert registry.get_ai() is registry.get_ai()  # built once per process


def test_fakes_have_the_right_shapes():
    ai = build("stub")

    transcript = ai.stt.transcribe(b"audio", "audio/ogg", language_hint="en")
    assert transcript.language == "en" and transcript.segments[0].speaker == "A"

    vectors = ai.text_embedder.embed(["a", "b", "a"])
    assert len(vectors[0]) == TEXT_DIM == ai.text_embedder.dim
    assert vectors[0] == vectors[2] and vectors[0] != vectors[1]
    assert abs(sum(x * x for x in vectors[0]) - 1.0) < 1e-9

    assert isinstance(ai.vision.review(b"img", "ar"), ReviewResult)
    assert ai.captioner.caption([b"img"], "", "en")
    assert ai.llm.complete([{"role": "user", "content": "hi"}]) == "fake answer"


def test_face_stub_matches_the_enrollment_stub():
    ai = build("stub")
    assert ai.face.model_id == face.MODEL_VERSION
    assert ai.face.embed_face(b"photo") == face.embed_face(b"photo")
    assert len(ai.face.embed_face(b"photo")) == FACE_DIM == ai.face.dim


def test_override_one_capability():
    chosen = choose_providers("production", {"llm": "fake", "stt": None})
    assert chosen["llm"] == "fake"
    assert chosen["stt"] == registry.PROFILES["production"]["stt"]


def test_unknown_profile_and_capability_fail_clearly():
    with pytest.raises(ProviderNotAvailable, match="Unknown AI_PROFILE"):
        choose_providers("turbo")
    with pytest.raises(ProviderNotAvailable, match="Unknown AI capability"):
        choose_providers("stub", {"ocr": "fake"})


def test_unimplemented_provider_names_the_capability(monkeypatch):
    monkeypatch.setattr("app.ai.clients.stt.settings.deepgram_api_key", "test-key")
    monkeypatch.setattr("app.ai.clients.embeddings.settings.voyage_api_key", "test-key")
    monkeypatch.setattr("app.ai.clients.vision.settings.gemini_api_key", "test-key")
    with pytest.raises(ProviderNotAvailable, match="'captioner' isn't implemented yet"):
        build("production")


def test_assist_llm_has_a_30_s_timeout(monkeypatch):
    monkeypatch.setattr("app.ai.clients.llm.settings.gemini_api_key", "test-key")
    ai = build("stub", {"assist_llm": "gemini-flash-fast", "llm": "gemini-flash"})
    assert isinstance(ai.assist_llm, GeminiFastLLM)
    assert ai.assist_llm.timeout_s == registry.ASSIST_LLM_TIMEOUT_S == 30.0
    assert ai.llm.timeout_s == 60.0  # the general LLM keeps the client's default


def test_provider_without_its_key_fails_clearly(monkeypatch):
    monkeypatch.setattr("app.ai.clients.stt.settings.deepgram_api_key", None)
    with pytest.raises(ProviderNotAvailable, match="couldn't start: DEEPGRAM_API_KEY"):
        build("stub", {"stt": "deepgram-nova-3"})
    # with every capability overridden to fakes, production builds
    fakes_only = {c: registry.PROFILES["stub"][c] for c in registry.CAPABILITIES}
    assert build("production", fakes_only).stt.model_id == "fake-stt"
