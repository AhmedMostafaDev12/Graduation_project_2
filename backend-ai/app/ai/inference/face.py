"""Server-side face embedder used at enrollment (spec D14, docs/AI_LAYER.md).

STUB (Phase 5): returns a deterministic unit vector derived from the image bytes, so the
API, database and sync work end to end. The real embedder loads the exported MobileFaceNet
(`w600k_mbf`) from ml/ with the shared preprocessing and must match the glasses (D14).
Rows written by the stub carry MODEL_VERSION = "stub-0" so they can be found and re-embedded.
"""

import base64
import hashlib
import math
import random
import struct

from app.models import FACE_DIM

MODEL_VERSION = "stub-0"
# embeddings computed on the glasses (unknown-face clusters)
EDGE_MODEL_VERSION = "w600k_mbf"

JPEG_MAGIC = b"\xff\xd8\xff"
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def looks_like_image(data: bytes) -> bool:
    return data.startswith((JPEG_MAGIC, PNG_MAGIC))


def embed_face(image: bytes) -> list[float]:
    rng = random.Random(hashlib.sha256(image).digest())
    vector = [rng.gauss(0.0, 1.0) for _ in range(FACE_DIM)]
    norm = math.sqrt(sum(x * x for x in vector))
    return [x / norm for x in vector]


def to_base64_f16(vector: list[float]) -> str:
    """Compact wire format for the glasses' people cache (spec §7.1: base64 float16)."""
    return base64.b64encode(struct.pack(f"<{len(vector)}e", *vector)).decode("ascii")
