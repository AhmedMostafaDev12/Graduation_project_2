"""The smart-review contract (spec D29): known shapes, the "other" fallback, no crashes."""

import uuid

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.ai.review_contract import display, normalize_ai_tags, normalize_document
from app.models import CapturedDocument, MediaAsset
from tests.conftest import (
    API,
    create_patient,
    image_bytes,
    pair_device,
    register_and_login,
)

# ----- the contract itself -----


def test_receipt_accepts_common_key_variants_and_parses_money():
    kind, fields = normalize_document(
        "receipt",
        {
            "amount": "120 EGP",
            "date": "2026-10-01",
            "items": "Concor 5 mg x1",
            "junk": 1,
        },
    )
    assert kind == "receipt"
    assert fields == {
        "total": {"amount": 120, "currency": "EGP"},
        "date": "2026-10-01",
        "items": ["Concor 5 mg x1"],
    }
    shown = display(kind, fields)
    assert shown["headline"] == "120 EGP"
    assert [(r["key"], r["type"]) for r in shown["fields"]] == [
        ("total", "text"),
        ("date", "date"),
        ("items", "text"),
    ]


def test_medication_label_headline():
    shown = display("medication_label", {"medication_name": "Concor", "dosage": "5 mg"})
    assert shown["title"] == "Concor" and shown["headline"] == "Concor 5 mg"
    assert [r["key"] for r in shown["fields"]] == ["medication_name", "strength"]


def test_an_invented_document_type_is_kept_as_other():
    kind, fields = normalize_document(
        "appointment_card",
        {
            "title": "كارت ميعاد الدكتور",
            "fields": [
                {"label": "الميعاد", "value": "الخميس ٥ م"},
                {"label": "empty", "value": ""},
            ],
        },
    )
    assert kind == "other" and fields["raw_category"] == "appointment_card"
    shown = display(kind, fields)
    assert shown["title"] == "كارت ميعاد الدكتور"
    assert shown["fields"] == [
        {"key": None, "label": "الميعاد", "value": "الخميس ٥ م", "type": "text"}
    ]
    assert shown["headline"] == "الخميس ٥ م"


def test_garbage_never_raises():
    assert normalize_document("receipt", None) == ("receipt", {})
    assert normalize_document("", {"fields": "not a list"})[0] == "other"
    assert display("bill", {"total": "no number here"})["headline"] is None
    assert normalize_ai_tags(None) is None


def test_ai_tags_unknown_category_becomes_other():
    tags = normalize_ai_tags(
        {"category": "birthday", "tags": ["cake", ""], "reason": "a birthday cake"}
    )
    assert tags == {
        "category": "other",
        "tags": ["cake"],
        "reason": "a birthday cake",
        "raw_category": "birthday",
    }
    assert normalize_ai_tags({"tags": ["garden"]})["category"] is None


# ----- the screens -----

AT = "2026-10-01T11:45:00+03:00"


def _document(client, fake_s3, engine, document_type, fields, ai_tags=None):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    phone = pair_device(client, manager, patient["id"])
    base = f"{API}/patients/{patient['id']}"
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "document_captured",
        "occurred_at": AT,
    }
    client.post(
        f"{base}/events:batch", json={"events": [event]}, headers=phone["headers"]
    )
    media_id = str(uuid.uuid4())
    ticket = client.post(
        f"{base}/uploads",
        json={"id": media_id, "kind": "media", "content_type": "image/jpeg"},
        headers=phone["headers"],
    ).json()
    fake_s3.put_bytes(ticket["key"], image_bytes(), "image/jpeg")
    client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient["id"],
            "kind": "media",
            "content_type": "image/jpeg",
            "event_id": event["id"],
            "trigger": "document_signal",
        },
        headers=phone["headers"],
    )
    with Session(engine) as db:  # what the Phase 7 review worker will write
        kind, stored = normalize_document(document_type, fields)
        document = CapturedDocument(
            event_id=uuid.UUID(event["id"]),
            media_asset_id=uuid.UUID(media_id),
            document_type=kind,
            ocr_text="صيدلية العزبي\nConcor 5 mg x1\nالإجمالي 120 ج.م",
            extracted_fields=stored,
        )
        db.add(document)
        if ai_tags is not None:
            db.execute(
                update(MediaAsset)
                .where(MediaAsset.id == uuid.UUID(media_id))
                .values(ai_tags=ai_tags)
            )
        db.commit()
        document_id = str(document.id)
    return manager, base, media_id, document_id


def test_documents_list_and_detail_are_ready_to_show(client, fake_s3, migrated_engine):
    manager, base, _, document_id = _document(
        client,
        fake_s3,
        migrated_engine,
        "receipt",
        {"merchant": "صيدلية العزبي", "total": {"amount": 120, "currency": "EGP"}},
    )
    [card] = client.get(f"{base}/documents", headers=manager["headers"]).json()
    assert card["title"] == "صيدلية العزبي" and card["headline"] == "120 EGP"
    assert card["captured_at"].startswith(
        "2026-10-01T08:45"
    )  # the glasses' time, in UTC
    assert ".thumb.jpg" in card["thumbnail_url"]

    detail = client.get(f"{API}/documents/{document_id}", headers=manager["headers"])
    assert detail.status_code == 200
    assert [f["key"] for f in detail.json()["fields"]] == ["total", "merchant"]

    stranger = register_and_login(client)
    hidden = client.get(f"{API}/documents/{document_id}", headers=stranger["headers"])
    assert hidden.status_code == 404
    assert hidden.json()["error"]["code"] == "DOCUMENT_NOT_FOUND"


def test_other_document_and_unknown_photo_category_reach_the_app(
    client, fake_s3, migrated_engine
):
    manager, base, media_id, _ = _document(
        client,
        fake_s3,
        migrated_engine,
        "appointment_card",
        {
            "title": "كارت ميعاد",
            "fields": [{"label": "الميعاد", "value": "الخميس ٥ م"}],
        },
        ai_tags={
            "category": "appointment",
            "tags": ["paper"],
            "reason": "a doctor's card",
        },
    )
    [card] = client.get(
        f"{base}/documents", params={"type": "other"}, headers=manager["headers"]
    ).json()
    assert card["document_type"] == "other" and card["title"] == "كارت ميعاد"
    assert card["fields"][0]["label"] == "الميعاد"

    journal = client.get(
        f"{base}/journal", params={"date": "2026-10-01"}, headers=manager["headers"]
    ).json()
    [entry] = journal["entries"]
    assert entry["document"]["headline"] == "الخميس ٥ م"
    assert entry["media"][0]["ai_tags"]["category"] == "other"
    assert entry["media"][0]["ai_tags"]["raw_category"] == "appointment"

    photo = client.get(f"{base}/media/{media_id}", headers=manager["headers"]).json()
    assert photo["event"]["event_type"] == "document_captured"
    assert photo["ai_tags"]["reason"] == "a doctor's card"
