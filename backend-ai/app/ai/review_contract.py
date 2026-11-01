"""What the smart-review vision call must return, and how its answer is stored (spec D29).

One vision call per photo (spec §7.4) answers two separate questions:
- keep or discard: decides whether the photo is saved;
- category and fields: only decide how the app *displays* it.
Anything important that fits no category is kept as "other" with the model's own words.
The model's answer is never rejected for an unexpected category or key: `normalize_*`
coerces it, and keeps an unknown category in `raw_category` for the lead to review.

The review task (phase 8.3, services/review_service.py) calls these; the API's display code
reads the stored result.
"""

import re
from typing import Any, Literal

from pydantic import BaseModel, Field

DocumentType = Literal["receipt", "bill", "medication_label", "other"]
MediaCategory = Literal["notable_moment", "document", "person", "place", "other"]

DOCUMENT_TYPES = ("receipt", "bill", "medication_label")
MEDIA_CATEGORIES = ("notable_moment", "document", "person", "place")

# The keys each known type may carry, in display order (stored in extracted_fields).
DOCUMENT_KEYS = {
    "receipt": ("total", "date", "items", "merchant"),
    "bill": ("total", "due_date", "date", "issuer"),
    "medication_label": ("medication_name", "strength", "instructions", "expiry_date"),
}
DATE_KEYS = {"date", "due_date", "expiry_date"}

# Names models (and older seed data) use for the same thing.
ALIASES = {
    "amount": "total",
    "total_amount": "total",
    "store": "merchant",
    "shop": "merchant",
    "company": "issuer",
    "provider": "issuer",
    "name": "medication_name",
    "drug": "medication_name",
    "dosage": "strength",
    "dose": "strength",
    "directions": "instructions",
    "expiry": "expiry_date",
    "expires": "expiry_date",
    "due": "due_date",
}


# ----- the vision model's answer (Phase 7 parses the model output into this) -----


class FreeField(BaseModel):
    label: str = Field(max_length=60, description="In the patient's language")
    value: str = Field(max_length=300)


class DocumentResult(BaseModel):
    document_type: str = Field(description="receipt | bill | medication_label | other")
    ocr_text: str = ""
    fields: dict[str, Any] = Field(
        default_factory=dict,
        description="Known types: the keys in DOCUMENT_KEYS. other: title + fields list",
    )


class SeenObject(BaseModel):
    """An object in the photo and its state (spec §7.4 item 7, D40: object sightings)."""

    name: str = Field(max_length=80)
    state: str | None = Field(
        default=None, max_length=300
    )  # "on", "open", "in the drawer"


class SeenAction(BaseModel):
    """Something being done in the photo (spec §7.4 item 7, D40: action log)."""

    verb: str = Field(max_length=60)  # normalized: "take_medication", "turn_off"
    object: str | None = Field(default=None, max_length=80)
    quantity: float | None = None
    unit: str | None = Field(default=None, max_length=30)


class ReviewResult(BaseModel):
    keep: bool
    category: str = Field(
        description="notable_moment | document | person | place | other"
    )
    tags: list[str] = Field(default_factory=list, max_length=10)
    reason: str | None = Field(default=None, max_length=300)
    contains_other_people: bool | None = None
    document: DocumentResult | None = None
    # memory fields (D40, D41): kept for the vision consolidation (phase 8.5)
    room: str | None = Field(default=None, max_length=60)
    objects: list[SeenObject] = Field(default_factory=list, max_length=20)
    actions: list[SeenAction] = Field(default_factory=list, max_length=10)


# ----- normalizing what is stored -----


def _money(value: Any) -> dict | None:
    """{"amount": 120, "currency": "EGP"} from a dict, a number or text like '120 EGP'."""
    if isinstance(value, dict) and "amount" in value:
        return {"amount": value["amount"], "currency": value.get("currency") or ""}
    if isinstance(value, int | float):
        return {"amount": value, "currency": ""}
    if isinstance(value, str):
        match = re.search(r"\d+(?:[.,]\d+)?", value)
        if match:
            amount = float(match.group().replace(",", "."))
            currency = (value[: match.start()] + value[match.end() :]).strip()
            return {
                "amount": int(amount) if amount.is_integer() else amount,
                "currency": currency,
            }
    return None


def normalize_document(
    document_type: str, fields: dict[str, Any] | None
) -> tuple[str, dict]:
    """(stored document_type, stored extracted_fields). Never raises."""
    fields = dict(fields or {})
    if document_type not in DOCUMENT_TYPES:
        out: dict[str, Any] = {
            "title": str(fields.get("title") or "")[:120] or None,
            "fields": [
                {
                    "label": str(f.get("label", ""))[:60],
                    "value": str(f.get("value", ""))[:300],
                }
                for f in fields.get("fields", [])
                if isinstance(f, dict) and f.get("value")
            ],
        }
        if document_type and document_type != "other":
            out["raw_category"] = str(document_type)[:60]
        return "other", out

    out = {}
    for key, value in fields.items():
        key = ALIASES.get(key, key)
        if key not in DOCUMENT_KEYS[document_type] or value in (None, "", []):
            continue
        if key == "total":
            value = _money(value)
        elif key == "items":
            value = [str(v) for v in value] if isinstance(value, list) else [str(value)]
        else:
            value = str(value)
        if value:
            out[key] = value
    return document_type, out


def normalize_ai_tags(raw: dict[str, Any] | None) -> dict | None:
    """{"category", "tags", "reason"} (+ "raw_category" for an unknown one). Never raises."""
    if not raw:
        return None
    category = raw.get("category")
    out: dict[str, Any] = {
        "category": category
        if category in MEDIA_CATEGORIES
        else ("other" if category else None),
        "tags": [str(t)[:40] for t in raw.get("tags", []) if t][:10],
        "reason": str(raw["reason"])[:300] if raw.get("reason") else None,
    }
    if category and category not in MEDIA_CATEGORIES and category != "other":
        out["raw_category"] = str(category)[:60]
    elif raw.get("raw_category"):
        out["raw_category"] = raw["raw_category"]
    return out


# ----- what the app shows (C12, C14, C15) -----


def _money_text(total: dict) -> str:
    return f"{total['amount']} {total.get('currency', '')}".strip()


def display(document_type: str, fields: dict[str, Any]) -> dict:
    """title, headline and ordered rows. Known types give a `key` the app translates;
    "other" gives the model's own `label`. Dates are ISO (YYYY-MM-DD) for the app to format."""
    document_type, fields = normalize_document(document_type, fields)
    if document_type == "other":
        rows = [
            {"key": None, "label": f["label"], "value": f["value"], "type": "text"}
            for f in fields["fields"]
        ]
        return {
            "title": fields.get("title"),
            "headline": rows[0]["value"] if rows else None,
            "fields": rows,
        }

    rows = []
    for key in DOCUMENT_KEYS[document_type]:
        if key not in fields:
            continue
        value = fields[key]
        if key == "total":
            value = _money_text(value)
        elif key == "items":
            value = ", ".join(value)
        rows.append(
            {
                "key": key,
                "label": None,
                "value": value,
                "type": "date" if key in DATE_KEYS else "text",
            }
        )

    if document_type == "medication_label":
        name = " ".join(
            filter(None, [fields.get("medication_name"), fields.get("strength")])
        )
        return {
            "title": fields.get("medication_name"),
            "headline": name or None,
            "fields": rows,
        }
    issuer = fields.get("merchant") or fields.get("issuer")
    total = fields.get("total")
    return {
        "title": issuer,
        "headline": _money_text(total) if total else None,
        "fields": rows,
    }
