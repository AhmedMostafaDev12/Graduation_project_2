"""Documents read from photos: receipts, bills, medication labels (screens C14, C15).

The review worker (Phase 7) stores what the vision model read; this module turns it into
what the screens show (title, headline, ordered rows) through ai/review_contract.py.
"""

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai import review_contract
from app.errors import NotFound
from app.integrations import s3
from app.models import CapturedDocument, Event, MediaAsset
from app.oauth2 import Principal, check_patient_access
from app.schemas.media import DocumentOut
from app.services import media_service


def _base_query():
    return (
        select(CapturedDocument, MediaAsset, Event.occurred_at)
        .join(MediaAsset, MediaAsset.id == CapturedDocument.media_asset_id)
        .join(Event, Event.id == CapturedDocument.event_id)
        .where(MediaAsset.deleted_at.is_(None))
    )


def _out(document: CapturedDocument, media: MediaAsset, captured_at) -> DocumentOut:
    document_type, fields = review_contract.normalize_document(
        document.document_type, document.extracted_fields
    )
    return DocumentOut(
        id=document.id,
        event_id=document.event_id,
        media_asset_id=document.media_asset_id,
        document_type=document_type,
        ocr_text=document.ocr_text,
        extracted_fields=fields,
        created_at=document.created_at,
        captured_at=captured_at,
        url=s3.presign_get(media.storage_key),
        thumbnail_url=s3.presign_get(media.thumbnail_key)
        if media.thumbnail_key
        else None,
        **review_contract.display(document_type, fields),
    )


def list_documents(
    db: Session, access, document_type: str | None, limit: int, offset: int
) -> list[DocumentOut]:
    """Newest capture first. Photo URLs are audit-logged in one insert."""
    query = _base_query().where(MediaAsset.patient_id == access.patient_id)
    if document_type:
        query = query.where(CapturedDocument.document_type == document_type)
    rows = db.execute(
        query.order_by(Event.occurred_at.desc()).limit(limit).offset(offset)
    ).all()
    out = [_out(document, media, captured_at) for document, media, captured_at in rows]
    media_service.audit(db, access, "media.view", [media.id for _, media, _ in rows])
    db.commit()
    return out


def get_document(
    db: Session, principal: Principal, document_id: uuid.UUID
) -> DocumentOut:
    """C15. A document you can't access looks exactly like a missing one."""
    row = db.execute(_base_query().where(CapturedDocument.id == document_id)).first()
    not_found = NotFound("Document not found.", code="DOCUMENT_NOT_FOUND")
    if row is None:
        raise not_found
    document, media, captured_at = row
    try:
        access = check_patient_access(db, principal, media.patient_id)
    except NotFound:
        raise not_found from None
    out = _out(document, media, captured_at)
    media_service.audit(db, access, "media.view", [media.id])
    db.commit()
    return out
