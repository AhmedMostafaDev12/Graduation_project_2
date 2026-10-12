"""Photos, clips and audio in the private S3 bucket (spec D5, §7.2-7.4).

Upload flow: POST /patients/{id}/uploads returns a presigned PUT for a key derived from the
patient, kind and id; the phone PUTs the file to S3 directly; POST /uploads/{id}/complete
checks the object is there and creates the database row. Completing twice is harmless.
"""

import logging
import uuid
from datetime import UTC, datetime

from kombu.exceptions import OperationalError as KombuOperationalError
from redis.exceptions import RedisError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, Forbidden, NotFound
from app.integrations import s3
from app.models import (
    AudioSegment,
    AuditLog,
    Encounter,
    EnrolledPerson,
    Event,
    MediaAsset,
    User,
)
from app.oauth2 import PatientAccess
from app.schemas.media import (
    CONTENT_TYPES,
    MediaEvent,
    MediaEventPerson,
    MediaOut,
    MediaView,
    UploadComplete,
    UploadDone,
    UploadOut,
    UploadRequest,
)

logger = logging.getLogger(__name__)


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
        # Phase 7: enqueue transcribe(segment) here
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
        # rule 1: enqueue only after the commit, so the worker finds the row
        _enqueue_thumbnail(asset.id)
        # Phase 7: enqueue review(asset) here when pending_review
    return UploadDone(id=upload_id, kind="media", status=asset.status)


def _enqueue_thumbnail(media_id: uuid.UUID) -> None:
    """Never fails the upload: if Redis is down, the media.backfill_thumbnails sweep
    picks the item up later."""
    from app.workers.tasks.media import make_thumbnail  # the API only needs it here

    try:
        make_thumbnail.delay(str(media_id))  # IDs only (rule 2)
    except (KombuOperationalError, RedisError):
        logger.warning("thumbnail not queued; the backfill sweep will retry")


def audit(db: Session, access: PatientAccess, action: str, media_ids: list) -> None:
    """Who looked at or removed photos: one row per photo, added in one bulk insert.
    A phone acts on behalf of its patient. The caller commits."""
    actor = access.principal.user.id if access.principal.user else access.patient_id
    db.add_all(
        AuditLog(
            actor_user_id=actor, action=action, entity_type="media", entity_id=media_id
        )
        for media_id in media_ids
    )


def _audit(db: Session, access: PatientAccess, action: str, media: MediaAsset) -> None:
    audit(db, access, action, [media.id])


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
        event=_event_summary(db, media.event_id),
    )


def _event_summary(db: Session, event_id: uuid.UUID) -> MediaEvent | None:
    """C13 "Encounter with Ahmed (son) · Thu 1 Oct 09:15", wherever the photo is opened."""
    event = db.get(Event, event_id)
    if event is None:
        return None
    person_id = event.person_id
    if person_id is None and event.encounter_id:
        person_id = db.scalar(
            select(Encounter.person_id).where(Encounter.id == event.encounter_id)
        )
    person = db.get(EnrolledPerson, person_id) if person_id else None
    return MediaEvent(
        id=event.id,
        event_type=event.event_type,
        occurred_at=event.occurred_at,
        person=MediaEventPerson(
            id=person.id, name=person.name, relationship=person.relationship
        )
        if person
        else None,
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
    if media.thumbnail_key:
        s3.delete(media.thumbnail_key)
    media.deleted_at = datetime.now(UTC)
    _audit(db, access, "media.delete", media)
    db.commit()
