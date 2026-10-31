"""Photo review: blur strangers → one vision call → keep or discard, tags, documents, retention
(spec §7.4, §8, D10, D20, D29; phase 8.3).

Called by the `review.*` tasks for photos the glasses proposed (`pending_review`). For one photo:

1. Check permission: the `cloud_processing` consent (spec §9). Otherwise nothing is sent and
   the photo stays pending for the caregiver.
2. Find every face and compare it with the patient's enrolled people. Faces that match no one
   are pixelated before the photo leaves the server (D20, D35).
3. One vision call (`get_ai().vision`) returns the review contract (D29).
4. Apply it:
   - discard → the files are deleted at once (spec §8);
   - keep → `confirmed` with `ai_tags`; a document gets a `captured_documents` row;
     retention: photos with other people expire after 30 days unless pinned (D10), documents
     and the patient's own moments are kept;
   - the memory fields (room, objects, actions) become object sightings, actions and entities
     in the same commit (phase 8.5, services/vision_memory.py), and the event is re-embedded
     so search sees the new tags.

`reviewed_at` marks a photo as done: a permanent failure leaves it pending (visible to the
caregiver) but isn't retried. Never logs photos, faces or descriptions (AI_LAYER.md rule 8).
"""

import logging
import uuid
from datetime import UTC, datetime, timedelta

import numpy as np
from PIL import Image, ImageFilter
from sqlalchemy import and_, exists, select
from sqlalchemy.orm import Session

from app.ai.clients.llm import LLMError
from app.ai.clients.vision import to_jpeg
from app.ai.inference.face_onnx import FaceImageError, load_image
from app.ai.interfaces import Face
from app.ai.registry import get_ai
from app.ai.review_contract import ReviewResult, normalize_ai_tags, normalize_document
from app.integrations import s3
from app.models import (
    FACE_DIM,
    CapturedDocument,
    ConsentRecord,
    EnrolledPerson,
    Event,
    FaceEmbedding,
    MediaAsset,
    PatientProfile,
)
from app.services import vision_memory
from app.services.memory_service import cloud_allowed

logger = logging.getLogger(__name__)

MAX_PHOTO_BYTES = 15 * 1024 * 1024
# cosine similarity at which a face counts as an enrolled person; below it, it's blurred.
# Set high on purpose: when unsure, blur (privacy first).
MATCH_THRESHOLD = 0.40
BLUR_MARGIN = 0.25  # grow each face box by this share, so hair and chin are covered too
OTHER_PEOPLE_EXPIRY = timedelta(days=30)  # spec §8, D10


# ----- blurring -----


def enrolled_vectors(db: Session, patient_id: uuid.UUID, model_id: str) -> np.ndarray:
    """Every enrolled face vector of the patient's active people, made by this face model."""
    rows = db.scalars(
        select(FaceEmbedding.embedding)
        .join(EnrolledPerson, EnrolledPerson.id == FaceEmbedding.person_id)
        .where(
            EnrolledPerson.patient_id == patient_id,
            EnrolledPerson.status == "active",
            EnrolledPerson.deleted_at.is_(None),
            FaceEmbedding.model_version == model_id,
        )
    ).all()
    if not rows:
        return np.zeros((0, FACE_DIM), dtype=np.float32)
    return np.array([list(v) for v in rows], dtype=np.float32)


def is_enrolled(face: Face, enrolled: np.ndarray) -> bool:
    if not enrolled.size:
        return False
    return (
        float((enrolled @ np.asarray(face.embedding, dtype=np.float32)).max())
        >= MATCH_THRESHOLD
    )


def pixelate(photo: Image.Image, box: tuple[float, float, float, float]) -> None:
    """Make the face unrecognizable in place: 8×8 blocks, then a blur over the blocks."""
    x1, y1, x2, y2 = box
    grow_x, grow_y = (x2 - x1) * BLUR_MARGIN, (y2 - y1) * BLUR_MARGIN
    area = (
        max(0, int(x1 - grow_x)),
        max(0, int(y1 - grow_y)),
        min(photo.width, int(x2 + grow_x) + 1),
        min(photo.height, int(y2 + grow_y) + 1),
    )
    if area[2] - area[0] < 2 or area[3] - area[1] < 2:
        return
    crop = photo.crop(area)
    blocks = crop.resize((8, 8), Image.Resampling.BILINEAR).resize(
        crop.size, Image.Resampling.NEAREST
    )
    photo.paste(blocks.filter(ImageFilter.GaussianBlur(max(2, crop.width // 16))), area)


def blur_strangers(
    photo: Image.Image, faces: list[Face], enrolled: np.ndarray
) -> tuple[Image.Image, int]:
    """A copy of the photo with every non-enrolled face pixelated, and how many there were."""
    out = photo.copy()
    strangers = [f for f in faces if not is_enrolled(f, enrolled)]
    for face in strangers:
        pixelate(out, face.box)
    return out, len(strangers)


# ----- the review -----


def _apply(
    db: Session, media: MediaAsset, result: ReviewResult, strangers: int, model_id: str
) -> str:
    now = datetime.now(UTC)
    media.reviewed_at = now
    if not result.keep:
        s3.delete(media.storage_key)
        if media.thumbnail_key:
            s3.delete(media.thumbnail_key)
        media.status = "discarded"
        media.deleted_at = now  # discarded media is deleted immediately (spec §8)
        db.commit()
        return "discarded"

    is_document = result.category == "document" or result.document is not None
    others = bool(result.contains_other_people) or strangers > 0
    media.status = "confirmed"
    media.ai_tags = normalize_ai_tags(
        {"category": result.category, "tags": result.tags, "reason": result.reason}
    )
    media.contains_other_people = others
    if media.pinned_by is None:
        if others and not is_document:
            media.retention_policy, media.expires_at = (
                "auto_expire",
                now + OTHER_PEOPLE_EXPIRY,
            )
        else:
            media.retention_policy, media.expires_at = "keep_indefinitely", None

    if result.document is not None and not db.scalar(
        select(exists().where(CapturedDocument.media_asset_id == media.id))
    ):
        document_type, fields = normalize_document(
            result.document.document_type, result.document.fields
        )
        db.add(
            CapturedDocument(
                event_id=media.event_id,
                media_asset_id=media.id,
                document_type=document_type,
                ocr_text=result.document.ocr_text or "",
                extracted_fields=fields,
            )
        )

    event = db.get(Event, media.event_id)
    # room, objects, actions → object sightings, action log, entity index (phase 8.5)
    vision_memory.store(db, media, event, result, model_id)
    # the sentence includes the photo's tags: embed.backfill renders and embeds it again
    event.rendered_text, event.embedding = None, None
    db.commit()
    return "document" if is_document else "kept"


def _give_up(db: Session, media: MediaAsset, why: str) -> str:
    """Permanent failure: stays pending for the caregiver, not retried."""
    media.reviewed_at = datetime.now(UTC)
    db.commit()
    logger.warning("photo review failed permanently for media %s (%s)", media.id, why)
    return "failed"


def review_media(db: Session, media_id: uuid.UUID) -> str:
    """Returns what happened: kept | document | discarded | not_allowed | failed | skipped |
    done | missing."""
    media = db.get(MediaAsset, media_id)
    if media is None or media.deleted_at is not None:
        return "missing"
    if media.status != "pending_review" or media.reviewed_at is not None:
        return "done"
    if media.asset_type != "image":
        return "skipped"  # the glasses propose photos; videos are user requests (no review)
    if not cloud_allowed(db, media.patient_id):
        return "not_allowed"

    if not s3.exists(media.storage_key):
        return _give_up(db, media, "file missing")
    data = s3.get_bytes(media.storage_key, MAX_PHOTO_BYTES)
    if data is None:
        return _give_up(db, media, "too large")
    ai = get_ai()
    try:
        photo = load_image(data)
        faces = ai.face.faces(data)
    except FaceImageError:
        return _give_up(db, media, "unreadable image")

    enrolled = enrolled_vectors(db, media.patient_id, ai.face.model_id)
    blurred, strangers = blur_strangers(photo, faces, enrolled)
    profile = db.get(PatientProfile, media.patient_id)
    try:
        # TransientError (timeout, 429, 5xx) propagates before anything is written: retried
        result = ai.vision.review(
            to_jpeg(blurred), profile.preferred_language if profile else "ar"
        )
    except LLMError:
        return _give_up(db, media, "vision call refused")
    return _apply(db, media, result, strangers, ai.vision.model_id)


def pending_media_ids(db: Session, limit: int = 100) -> list[uuid.UUID]:
    """Photos still waiting for review (the queueing failed, or the task died): older than
    2 minutes, not given up on, and only for patients with the cloud consent."""
    consent = exists().where(
        and_(
            ConsentRecord.patient_id == MediaAsset.patient_id,
            ConsentRecord.consent_type == "cloud_processing",
            ConsentRecord.revoked_at.is_(None),
        )
    )
    return list(
        db.scalars(
            select(MediaAsset.id)
            .where(
                MediaAsset.status == "pending_review",
                MediaAsset.reviewed_at.is_(None),
                MediaAsset.deleted_at.is_(None),
                MediaAsset.asset_type == "image",
                MediaAsset.created_at < datetime.now(UTC) - timedelta(minutes=2),
                consent,
            )
            .order_by(MediaAsset.created_at)
            .limit(limit)
        )
    )
