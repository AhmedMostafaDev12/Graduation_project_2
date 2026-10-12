"""Small JPEG previews for lists (spec D28): phones download ~30 KB instead of a full photo.

Runs inside the request for now (enrollment already has the bytes; upload completion reads
the photo back from S3 in the same region). In Phase 6 a Celery task calls `create`.
A failed thumbnail never fails the request: the app falls back to the full photo.
"""

import io
import logging

from PIL import Image, ImageOps, UnidentifiedImageError

from app.errors import StorageUnavailable
from app.integrations import s3

logger = logging.getLogger(__name__)

MAX_SIDE = 320
QUALITY = 75
MAX_SOURCE_BYTES = 15 * 1024 * 1024
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
