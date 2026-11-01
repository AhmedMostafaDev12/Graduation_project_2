"""The Groq client (Qwen3.6-27B) for text and photo review. HTTP is mocked with respx."""

import base64
import io
import json

import httpx
import pytest
import respx
from PIL import Image

from app.ai.clients.groq import GROQ_URL, GroqError, GroqLLM, GroqVisionReviewer
from app.ai.registry import build
from app.errors import TransientError
from tests.conftest import image_bytes

REVIEW = {
    "keep": True,
    "category": "notable_moment",
    "tags": ["kitchen"],
    "reason": "a kitchen",
    "contains_other_people": False,
    "objects": [{"name": "refrigerator", "state": "closed"}],
    "actions": [],
}


def _reply(text: str) -> dict:
    return {"choices": [{"message": {"content": text}}]}


@respx.mock
def test_text_uses_json_schema_hides_reasoning_and_strips_think_blocks():
    route = respx.post(GROQ_URL).mock(
        return_value=httpx.Response(200, json=_reply('<think>hmm</think>{"ok": true}'))
    )
    out = GroqLLM(api_key="k").complete(
        [{"role": "user", "content": "hi"}], {"type": "object"}
    )
    assert out == '{"ok": true}'
    body = json.loads(route.calls.last.request.content)
    assert route.calls.last.request.headers["Authorization"] == "Bearer k"
    assert body["model"] == "qwen/qwen3.6-27b" and body["temperature"] == 0
    assert body["reasoning_format"] == "hidden"
    assert body["response_format"]["type"] == "json_schema"


@respx.mock
def test_a_refused_schema_falls_back_to_json_mode():
    route = respx.post(GROQ_URL).mock(
        side_effect=[
            httpx.Response(
                400, json={"error": {"message": "json_schema not supported"}}
            ),
            httpx.Response(200, json=_reply('{"ok": true}')),
        ]
    )
    GroqLLM(api_key="k").complete(
        [{"role": "user", "content": "hi"}], {"type": "object"}
    )
    retry = json.loads(route.calls.last.request.content)
    assert retry["response_format"] == {"type": "json_object"}
    assert "JSON schema" in retry["messages"][0]["content"]


@pytest.mark.parametrize("status", [429, 500])
@respx.mock
def test_rate_limits_and_server_errors_are_retried(status):
    respx.post(GROQ_URL).mock(return_value=httpx.Response(status))
    with pytest.raises(TransientError):
        GroqLLM(api_key="k").complete([{"role": "user", "content": "hi"}])


@respx.mock
def test_bad_requests_and_empty_answers_are_not_retried():
    respx.post(GROQ_URL).mock(return_value=httpx.Response(401, json={}))
    with pytest.raises(GroqError, match="401"):
        GroqLLM(api_key="k").complete([{"role": "user", "content": "hi"}])
    respx.post(GROQ_URL).mock(
        return_value=httpx.Response(200, json=_reply("<think>x</think>"))
    )
    with pytest.raises(GroqError, match="empty"):
        GroqLLM(api_key="k").complete([{"role": "user", "content": "hi"}])
    with pytest.raises(GroqError, match="GROQ_API_KEY"):
        GroqLLM(api_key="")


@respx.mock
def test_photo_review_sends_a_small_image_and_parses_the_contract():
    route = respx.post(GROQ_URL).mock(
        return_value=httpx.Response(200, json=_reply(json.dumps(REVIEW)))
    )
    result = GroqVisionReviewer(api_key="k").review(
        image_bytes(size=(3000, 2000)), "en"
    )
    assert result.keep and result.objects[0].name == "refrigerator"
    content = json.loads(route.calls.last.request.content)["messages"][1]["content"]
    url = content[0]["image_url"]["url"]
    sent = Image.open(io.BytesIO(base64.b64decode(url.split(",", 1)[1])))
    assert url.startswith("data:image/jpeg;base64,") and max(sent.size) == 1024
    assert content[1]["text"] == "The patient's language: English"


def test_the_registry_offers_groq(monkeypatch):
    monkeypatch.setattr("app.ai.clients.groq.settings.groq_api_key", "k")
    ai = build(
        "stub", {"llm": "groq-qwen", "assist_llm": "groq-qwen", "vision": "groq-qwen"}
    )
    assert ai.llm.model_id == "groq/qwen/qwen3.6-27b"
    assert ai.vision.model_id == "groq/qwen/qwen3.6-27b/vision_review.v2"


# ----- the same client against our own vLLM server (ml/replay/LIGHTNING.md) -----


@respx.mock
def test_self_hosted_uses_our_address_and_turns_thinking_off(monkeypatch):
    from app.ai.clients.groq import SelfHostedLLM, SelfHostedVisionReviewer

    monkeypatch.setattr(
        "app.ai.clients.groq.settings.selfhosted_base_url", "https://gpu.example/v1/"
    )
    monkeypatch.setattr("app.ai.clients.groq.settings.selfhosted_api_key", "secret")
    route = respx.post("https://gpu.example/v1/chat/completions").mock(
        return_value=httpx.Response(200, json=_reply(json.dumps(REVIEW)))
    )
    llm = SelfHostedLLM()
    assert llm.model_id == "selfhosted/Qwen/Qwen3.6-27B-FP8"
    llm.complete([{"role": "user", "content": "hi"}], {"type": "object"})
    body = json.loads(route.calls.last.request.content)
    assert body["model"] == "Qwen/Qwen3.6-27B-FP8"
    assert body["chat_template_kwargs"] == {"enable_thinking": False}
    assert "reasoning_format" not in body  # a Groq-only field
    assert route.calls.last.request.headers["Authorization"] == "Bearer secret"

    reviewer = SelfHostedVisionReviewer()
    assert reviewer.review(image_bytes(), "en").keep
    assert reviewer.model_id == "selfhosted/Qwen/Qwen3.6-27B-FP8/vision_review.v2"


def test_self_hosted_needs_its_address(monkeypatch):
    from app.ai.clients.groq import SelfHostedLLM

    monkeypatch.setattr("app.ai.clients.groq.settings.selfhosted_base_url", None)
    with pytest.raises(GroqError, match="SELFHOSTED_BASE_URL"):
        SelfHostedLLM()
