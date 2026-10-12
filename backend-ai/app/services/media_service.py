"""Photos, clips and audio in the private S3 bucket (spec D5, §7.2-7.4).

Upload flow: POST /patients/{id}/uploads returns a presigned PUT for a key derived from the
patient, kind and id; the phone PUTs the file to S3 directly; POST /uploads/{id}/complete
checks the object is there and creates the database row. Completing twice is harmless.
"""

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, Forbidden, NotFound
from app.integrations import s3
from app.models import AudioSegment, AuditLog, CapturedDocument, Event, MediaAsset, User
from app.oauth2 import PatientAccess
from app.schemas.media import (
    CONTENT_TYPES,
    DocumentOut,
    MediaOut,
    MediaView,
    UploadComplete,
    UploadDone,
    UploadOut,
    UploadRequest,
)


def storage_key(
    patient_id: uuid.UUID, kind: str, upload_id: uuid.UUID, content_type: str
) -> str:
    folder = "media" if kind == "media" else "audio"
    return f"patients/{patient_id}/{folder}/{upload_id}.{CONTENT_TYPES[content_type]}"


def request_upload(access: PatientAccess, data: UploadRequest) -> UploadOut:
    if data.kind == "audio" and access.permission != "device":
        raise Forbidden("Only the patient's phone uploads audio.", code="DEVICE_ONLY")
    key = storage_key(access.patient_id, data.kind, data.id, data.content_type)
    return UploadOut(
        id=data.id,
        key=key,
        upload_url=s3.presign_put(key, data.content_type),
        headers={"Content-Type": data.content_type},
        expires_in=s3.UPLOAD_URL_SECONDS,
    )


def _already_done(db: Session, model, upload_id: uuid.UUID, patient_id: uuid.UUID):
    row = db.get(model, upload_id)
    if row is not None and row.patient_id != patient_id:
        raise Conflict("This id is already used.", code="ID_IN_USE")
    return row


def complete_upload(
    db: Session, access: PatientAccess, upload_id: uuid.UUID, data: UploadComplete
) -> UploadDone:
    patient_id = access.patient_id
    key = storage_key(patient_id, data.kind, upload_id, data.content_type)

    if data.kind == "audio":
        if access.permission != "device":
            raise Forbidden(
                "Only the patient's phone uploads audio.", code="DEVICE_ONLY"
            )
        segment = _already_done(db, AudioSegment, upload_id, patient_id)
        if segment is None:
            if not s3.exists(key):
                raise Conflict(
                    "The file hasn't reached storage yet.", code="UPLOAD_MISSING"
                )
            segment = AudioSegment(
                id=upload_id,
                patient_id=patient_id,
                device_id=access.principal.device.id,
                started_at=data.started_at,
                ended_at=data.ended_at,
                storage_key=key,
                status="uploaded",
            )
            db.add(segment)
            db.commit()
        # Phase 6: enqueue transcribe(segment) on Celery here
        return UploadDone(id=upload_id, kind="audio", status=segment.status)

    asset = _already_done(db, MediaAsset, upload_id, patient_id)
    if asset is None:
        event = db.get(Event, data.event_id)
        if event is None or event.patient_id != patient_id:
            raise NotFound(
                "Event not found. Send it through events:batch first.",
                code="EVENT_NOT_FOUND",
            )
        if not s3.exists(key):
            raise Conflict(
                "The file hasn't reached storage yet.", code="UPLOAD_MISSING"
            )
        requested = data.trigger == "user_requested"
        asset = MediaAsset(
            id=upload_id,
            patient_id=patient_id,
            event_id=data.event_id,
            asset_type="video" if data.content_type.startswith("video/") else "image",
            storage_key=key,
            trigger=data.trigger,
            duration_seconds=data.duration_seconds,
            # the patient asked for it: no review, kept (spec §7.4); the rest waits for review
            status="confirmed" if requested else "pending_review",
            retention_policy="keep_indefinitely" if requested else None,
        )
        db.add(asset)
        db.commit()
        # Phase 6: enqueue review(asset) on Celery here when pending_review
    return UploadDone(id=upload_id, kind="media", status=asset.status)


def _audit(db: Session, access: PatientAccess, action: str, media: MediaAsset) -> None:
    """Who looked at or removed a photo. A phone acts on behalf of its patient."""
    actor = access.principal.user.id if access.principal.user else access.patient_id
    db.add(
        AuditLog(
            actor_user_id=actor, action=action, entity_type="media", entity_id=media.id
        )
    )


def get_media(db: Session, patient_id: uuid.UUID, media_id: uuid.UUID) -> MediaAsset:
    media = db.get(MediaAsset, media_id)
    if media is None or media.patient_id != patient_id or media.deleted_at is not None:
        raise NotFound("Media not found.", code="MEDIA_NOT_FOUND")
    return media


def view(db: Session, access: PatientAccess, media_id: uuid.UUID) -> MediaView:
    media = get_media(db, access.patient_id, media_id)
    url = s3.presign_get(media.storage_key)
    _audit(db, access, "media.view", media)
    db.commit()
    return MediaView(
        **MediaOut.model_validate(media, from_attributes=True).model_dump(),
        url=url,
        url_expires_in=s3.VIEW_URL_SECONDS,
    )


def pin(db: Session, media: MediaAsset, caregiver: User) -> MediaOut:
    """Keep this photo for good (spec D10): no 30-day expiry."""
    media.retention_policy = "keep_indefinitely"
    media.expires_at = None
    media.pinned_by = caregiver.id
    if media.status == "pending_review":
        media.status = "confirmed"
        media.reviewed_at = datetime.now(UTC)
    db.commit()
    db.refresh(media)
    return MediaOut.model_validate(media, from_attributes=True)


def delete(db: Session, access: PatientAccess, media: MediaAsset) -> None:
    s3.delete(media.storage_key)
    media.deleted_at = datetime.now(UTC)
    _audit(db, access, "media.delete", media)
    db.commit()


def documents(
    db: Session,
    patient_id: uuid.UUID,
    document_type: str | None,
    limit: int,
    offset: int,
) -> list[DocumentOut]:
    query = (
        select(CapturedDocument)
        .join(MediaAsset, MediaAsset.id == CapturedDocument.media_asset_id)
        .where(MediaAsset.patient_id == patient_id, MediaAsset.deleted_at.is_(None))
    )
    if document_type:
        query = query.where(CapturedDocument.document_type == document_type)
    rows = db.scalars(
        query.order_by(CapturedDocument.created_at.desc()).limit(limit).offset(offset)
    )
    return [DocumentOut.model_validate(row, from_attributes=True) for row in rows]
