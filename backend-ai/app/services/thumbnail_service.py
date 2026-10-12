"""Small JPEG previews for lists (spec D28): phones download ~30 KB instead of a full photo.

Enrollment makes previews inside the request (the bytes are already in memory). Uploaded
photos and videos get theirs from the `media.make_thumbnail` Celery task via
`make_for_media`, so the upload request stays fast. Videos use a frame from 1 s in (ffmpeg
from the imageio-ffmpeg package). A failed preview never fails anything: the app falls back
to the full photo, or a video icon.
"""

import io
import logging
import os
import subprocess
import tempfile
import uuid

import imageio_ffmpeg
from PIL import Image, ImageOps, UnidentifiedImageError
from sqlalchemy.orm import Session

from app.errors import StorageUnavailable
from app.integrations import s3
from app.models import MediaAsset

logger = logging.getLogger(__name__)

MAX_SIDE = 320
QUALITY = 75
MAX_SOURCE_BYTES = 15 * 1024 * 1024
MAX_VIDEO_BYTES = 200 * 1024 * 1024
FFMPEG_TIMEOUT = 60  # seconds
Image.MAX_IMAGE_PIXELS = (
    40_000_000  # refuse decompression bombs (a 12 MP photo is fine)
)


def thumbnail_key(key: str) -> str:
    """patients/p/media/abc.jpg -> patients/p/media/abc.thumb.jpg (same folder, so deleting
    a person's folder also removes their thumbnails)."""
    return f"{key.rsplit('.', 1)[0]}.thumb.jpg"


def is_decodable(data: bytes) -> bool:
    try:
        with Image.open(io.BytesIO(data)) as image:
            image.verify()
        return True
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError, SyntaxError):
        return False


def render(data: bytes) -> bytes | None:
    """Upright, at most 320 px, RGB JPEG. Saving a new JPEG drops EXIF, including GPS."""
    try:
        with Image.open(io.BytesIO(data)) as image:
            image.draft(
                "RGB", (MAX_SIDE * 2, MAX_SIDE * 2)
            )  # fast JPEG downscale on decode
            image = ImageOps.exif_transpose(image)
            image.thumbnail((MAX_SIDE, MAX_SIDE))
            out = io.BytesIO()
            image.convert("RGB").save(
                out, "JPEG", quality=QUALITY, optimize=True, progressive=True
            )
            return out.getvalue()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError, ValueError):
        return None


def create(key: str, data: bytes | None = None) -> str | None:
    """Make and store the thumbnail of the photo at `key`; returns its key or None.
    Pass `data` when the bytes are already in memory, otherwise they're read from S3."""
    try:
        if data is None:
            data = s3.get_bytes(key, MAX_SOURCE_BYTES)
            if data is None:
                return None
        thumb = render(data)
        if thumb is None:
            return None
        thumb_key = thumbnail_key(key)
        s3.put_bytes(thumb_key, thumb, "image/jpeg")
        return thumb_key
    except StorageUnavailable:
        logger.warning(
            "thumbnail skipped: storage unavailable"
        )  # never log keys or names
        return None


def video_frame(path: str) -> bytes | None:
    """One JPEG frame from 1 s in (or the first frame of a shorter clip)."""
    exe = imageio_ffmpeg.get_ffmpeg_exe()
    for seek in ("1", "0"):
        try:
            result = subprocess.run(
                [
                    exe,
                    "-v",
                    "error",
                    "-ss",
                    seek,
                    "-i",
                    path,
                    "-frames:v",
                    "1",
                    "-f",
                    "image2",
                    "-vcodec",
                    "mjpeg",
                    "pipe:1",
                ],
                capture_output=True,
                timeout=FFMPEG_TIMEOUT,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return None
        if result.returncode == 0 and result.stdout:
            return result.stdout
    return None


def make_for_media(db: Session, media_id: uuid.UUID) -> str | None:
    """The Celery task's work. Safe to run twice: a media row that already has a preview,
    or was deleted, is left alone. StorageUnavailable propagates so Celery retries it."""
    media = db.get(MediaAsset, media_id)
    if media is None or media.deleted_at is not None or media.thumbnail_key:
        return media.thumbnail_key if media else None

    if media.asset_type == "image":
        data = s3.get_bytes(media.storage_key, MAX_SOURCE_BYTES)
    else:
        handle, path = tempfile.mkstemp(suffix=".mp4")
        os.close(handle)
        try:
            frame = None
            if s3.download_to(media.storage_key, path, MAX_VIDEO_BYTES):
                frame = video_frame(path)
        finally:
            os.remove(path)
        data = frame
    thumb = render(data) if data else None
    if thumb is None:
        logger.warning("no preview for one media item (unreadable or too large)")
        return None

    key = thumbnail_key(media.storage_key)
    s3.put_bytes(key, thumb, "image/jpeg")
    # re-check: the user may have deleted it while we worked
    db.refresh(media)
    if media.deleted_at is not None:
        s3.delete(key)
        return None
    media.thumbnail_key = key
    db.commit()
    return key
