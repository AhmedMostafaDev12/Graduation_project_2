"""Photo review: Gemini Flash vision, paid tier (spec §7.4, D20, D29; phase 8.3).

Implements the `VisionReviewer` interface (app/ai/interfaces.py): one call per photo returns
keep/discard, category, tags, reason, other people, the document (type, text, fields) and the
memory fields (room, objects, actions). The answer is parsed leniently into `ReviewResult`;
`review_contract.normalize_*` coerces what is stored, so an unexpected answer never fails
the job (D29 rule 4). Faces of people who aren't enrolled are blurred by the caller before
this call (D20). Never log the photo or the answer (AI_LAYER.md rule 8).
"""

import base64
import io
import json

from PIL import Image
from pydantic import ValidationError

from app.ai.clients.llm import MODEL, LLMError, generate
from app.ai.memory.extract import load_prompt
from app.ai.review_contract import ReviewResult
from app.config import settings

PROMPT = "vision_review.v1"
MAX_SIDE = 1600  # pixels; enough to read a label, and fewer image tokens

_TEXT = {"type": "string"}
_NULLABLE_TEXT = {"type": ["string", "null"]}
_MONEY = {
    "type": ["object", "null"],
    "properties": {"amount": {"type": "number"}, "currency": _TEXT},
}
REVIEW_SCHEMA = {
    "type": "object",
    "properties": {
        "keep": {"type": "boolean"},
        "category": {
            "type": "string",
            "enum": ["notable_moment", "document", "person", "place", "other"],
        },
        "tags": {"type": "array", "items": _TEXT},
        "reason": _NULLABLE_TEXT,
        "contains_other_people": {"type": ["boolean", "null"]},
        "document": {
            "type": ["object", "null"],
            "properties": {
                "document_type": {
                    "type": "string",
                    "enum": ["receipt", "bill", "medication_label", "other"],
                },
                "ocr_text": _TEXT,
                # every key a known type may carry, plus the "other" layout (D29)
                "fields": {
                    "type": "object",
                    "properties": {
                        "merchant": _NULLABLE_TEXT,
                        "issuer": _NULLABLE_TEXT,
                        "total": _MONEY,
                        "date": _NULLABLE_TEXT,
                        "due_date": _NULLABLE_TEXT,
                        "items": {"type": "array", "items": _TEXT},
                        "medication_name": _NULLABLE_TEXT,
                        "strength": _NULLABLE_TEXT,
                        "instructions": _NULLABLE_TEXT,
                        "expiry_date": _NULLABLE_TEXT,
                        "title": _NULLABLE_TEXT,
                        "fields": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {"label": _TEXT, "value": _TEXT},
                                "required": ["label", "value"],
                            },
                        },
                    },
                },
            },
            "required": ["document_type", "ocr_text", "fields"],
        },
        "room": _NULLABLE_TEXT,
        "objects": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {"name": _TEXT, "state": _NULLABLE_TEXT},
                "required": ["name"],
            },
        },
        "actions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "verb": _TEXT,
                    "object": _NULLABLE_TEXT,
                    "quantity": {"type": ["number", "null"]},
                    "unit": _NULLABLE_TEXT,
                },
                "required": ["verb"],
            },
        },
    },
    "required": [
        "keep",
        "category",
        "tags",
        "contains_other_people",
        "objects",
        "actions",
    ],
}
LANGUAGE_NAMES = {"ar": "Arabic (Egyptian)", "en": "English"}


class VisionError(LLMError):
    """A permanent failure (bad request, blocked photo, unreadable answer): not retried."""


def to_jpeg(image: bytes | Image.Image) -> bytes:
    """The photo as a JPEG whose longest side is at most MAX_SIDE pixels."""
    photo = image if isinstance(image, Image.Image) else Image.open(io.BytesIO(image))
    photo = photo.convert("RGB")
    photo.thumbnail((MAX_SIDE, MAX_SIDE))
    out = io.BytesIO()
    photo.save(out, "JPEG", quality=88)
    return out.getvalue()


def _trim(data: dict) -> dict:
    """Cut lists to the contract's limits instead of rejecting the whole answer."""
    for key, limit in (("tags", 10), ("objects", 20), ("actions", 10)):
        if isinstance(data.get(key), list):
            data[key] = data[key][:limit]
    for key in ("reason", "room"):
        if isinstance(data.get(key), str):
            data[key] = data[key][: 300 if key == "reason" else 60]
    return data


def parse_review(raw: str) -> ReviewResult:
    try:
        data = json.loads(raw)
    except ValueError as exc:
        raise VisionError("the review answer is not JSON") from exc
    if not isinstance(data, dict):
        raise VisionError("the review answer is not a JSON object")
    try:
        return ReviewResult.model_validate(_trim(data))
    except ValidationError as exc:
        raise VisionError("the review answer doesn't match the contract") from exc


class GeminiVisionReviewer:
    model_id = f"{MODEL}/{PROMPT}"

    def __init__(self, api_key: str | None = None, timeout_s: float = 90.0):
        self.api_key = api_key if api_key is not None else settings.gemini_api_key
        if not self.api_key:
            raise VisionError(
                "GEMINI_API_KEY is not set (backend-ai/.env locally, the server's env file in production)"
            )
        self.timeout_s = timeout_s

    def review(self, image: bytes, language: str) -> ReviewResult:
        body = {
            "systemInstruction": {"parts": [{"text": load_prompt(PROMPT)}]},
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {
                            "inlineData": {
                                "mimeType": "image/jpeg",
                                "data": base64.b64encode(to_jpeg(image)).decode(
                                    "ascii"
                                ),
                            }
                        },
                        {
                            "text": "The patient's language: "
                            + LANGUAGE_NAMES.get(language, language)
                        },
                    ],
                }
            ],
            "generationConfig": {
                "temperature": 0.0,
                "responseMimeType": "application/json",
                "responseJsonSchema": REVIEW_SCHEMA,
            },
        }
        return parse_review(generate(self.api_key, body, self.timeout_s))
