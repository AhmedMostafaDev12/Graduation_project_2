"""Unknown-face clustering: assign a stranger's face vector to the nearest cluster (spec D23).

Pure functions, no database: `services/clustering_service.py` loads the vectors and stores
the result. Face vectors come from the glasses (`w600k_mbf`, the same model as enrollment,
spec D14) as base64 float16 (spec §7.1); all comparisons are cosine similarities of unit
vectors.

Two thresholds, on purpose different:
- ENROLLED_MATCH: a "stranger" this close to an enrolled person is that person (the glasses'
  own threshold was cautious); the same value the photo review uses to decide what to blur.
- SAME_CLUSTER: stricter, because merging two different strangers into one cluster would
  show the caregiver the wrong photos and count the wrong days.
"""

import base64
import binascii

import numpy as np

from app.models import FACE_DIM

ENROLLED_MATCH = 0.40
SAME_CLUSTER = 0.50


class BadEmbedding(ValueError):
    """The glasses sent something that isn't a FACE_DIM float16 vector."""


def decode(value) -> np.ndarray:
    """base64 float16 (spec §7.1) → unit float32 vector."""
    if not isinstance(value, str):
        raise BadEmbedding("not a string")
    try:
        raw = base64.b64decode(value, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise BadEmbedding("not base64") from exc
    if len(raw) != FACE_DIM * 2:
        raise BadEmbedding(f"expected {FACE_DIM} float16 values")
    vector = np.frombuffer(raw, dtype="<f2").astype(np.float32)
    norm = float(np.linalg.norm(vector))
    if not np.isfinite(norm) or norm == 0:
        raise BadEmbedding("empty or invalid vector")
    return vector / norm


def nearest(vector: np.ndarray, matrix: np.ndarray, threshold: float) -> int | None:
    """Row of `matrix` most similar to `vector`, if at least `threshold`; else None."""
    if not len(matrix):
        return None
    scores = matrix @ vector
    best = int(scores.argmax())
    return best if float(scores[best]) >= threshold else None


def add_to_centroid(centroid: np.ndarray, count: int, vector: np.ndarray) -> np.ndarray:
    """The cluster's mean direction after one more sighting (unit length)."""
    total = centroid * count + vector
    return total / float(np.linalg.norm(total))
