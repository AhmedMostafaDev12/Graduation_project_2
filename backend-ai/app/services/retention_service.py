"""Deleting what the patient's data rules say must go (spec §8, §7.3), hourly via Beat.

- photos with retention `auto_expire` whose `expires_at` has passed and that nobody pinned;
- audio segments still not transcribed after 7 days (raw audio is never kept, spec D4).

Order: the S3 delete first, then the row. S3 deletes are idempotent, so if the row update
fails the next run simply deletes again; the other order could leave a file nobody tracks.
"""

from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.integrations import s3
from app.models import AudioSegment, AuditLog, MediaAsset

AUDIO_MAX_AGE = timedelta(days=7)
BATCH = 200  # per run; the next hourly run continues


def expire_media(db: Session, now: datetime | None = None) -> dict:
    now = now or datetime.now(UTC)
    media = list(
        db.scalars(
            select(MediaAsset)
            .where(
                MediaAsset.retention_policy == "auto_expire",
                MediaAsset.expires_at < now,
                MediaAsset.pinned_by.is_(None),
                MediaAsset.deleted_at.is_(None),
            )
            .order_by(MediaAsset.expires_at)
            .limit(BATCH)
        )
    )
    for asset in media:
        s3.delete(asset.storage_key)
        if asset.thumbnail_key:
            s3.delete(asset.thumbnail_key)
        asset.deleted_at = now
        # the system acts on the patient's behalf (audit_log needs a user)
        db.add(
            AuditLog(
                actor_user_id=asset.patient_id,
                action="retention.delete",
                entity_type="media",
                entity_id=asset.id,
            )
        )
        db.commit()  # per item: a later S3 failure keeps the work already done

    audio = list(
        db.scalars(
            select(AudioSegment)
            .where(
                AudioSegment.status.in_(("uploaded", "transcribing", "failed")),
                AudioSegment.created_at < now - AUDIO_MAX_AGE,
                AudioSegment.storage_key.is_not(None),
            )
            .limit(BATCH)
        )
    )
    for segment in audio:
        s3.delete(segment.storage_key)
        segment.storage_key = None
        segment.status = "deleted"
        db.commit()

    return {"media": len(media), "audio": len(audio)}
