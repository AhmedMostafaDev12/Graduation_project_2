"""The hourly frame-vector file (spec D41, tier 2): every 1 fps frame's vector for one hour, 8-bit.

The glasses write one per hour and upload it on Wi-Fi (`uploads`, kind "frame_vectors"); the
server reads it only inside the minutes the scene segments found. Little-endian bytes:

    header   b"RMFV" · version u8 (1) · dim u16 · count u32 · hour_start unix seconds i64
             · model_id length u8 · model_id UTF-8
    frames   count × (offset_ms u32 since hour_start · scale f32 · dim × i8)

A vector is stored as round(v / scale × 127) with scale = max |v|: 1 byte per value, about
1.9 MB per hour at 512-d, ~30 MB for a 16-hour day.
"""

import struct
from dataclasses import dataclass
from datetime import UTC, datetime

import numpy as np

MAGIC = b"RMFV"
VERSION = 1
MAX_BYTES = 8 * 1024 * 1024  # an hour at 1 fps and 512-d is ~1.9 MB
_HEAD = struct.Struct("<4sBHIqB")
_FRAME = struct.Struct("<If")


class BadFrameVectorFile(ValueError):
    """The bytes aren't a frame-vector file this version can read."""


@dataclass(frozen=True)
class FrameVectors:
    hour_start: datetime
    model_id: str
    seconds: np.ndarray  # (count,) seconds since hour_start
    vectors: np.ndarray  # (count, dim) float32, unit length

    def times(self) -> list[datetime]:
        start = self.hour_start.timestamp()
        return [datetime.fromtimestamp(start + float(s), UTC) for s in self.seconds]


def pack(
    hour_start: datetime, model_id: str, frames: list[tuple[float, list[float]]]
) -> bytes:
    """frames: (seconds since hour_start, vector) in time order."""
    name = model_id.encode("utf-8")
    dim = len(frames[0][1]) if frames else 0
    out = [
        _HEAD.pack(
            MAGIC, VERSION, dim, len(frames), int(hour_start.timestamp()), len(name)
        ),
        name,
    ]
    for seconds, vector in frames:
        v = np.asarray(vector, dtype=np.float32)
        scale = float(np.abs(v).max()) or 1.0
        q = np.clip(np.round(v / scale * 127), -127, 127).astype(np.int8)
        out.append(_FRAME.pack(round(seconds * 1000), scale))
        out.append(q.tobytes())
    return b"".join(out)


def unpack(data: bytes) -> FrameVectors:
    if len(data) < _HEAD.size:
        raise BadFrameVectorFile("too short")
    magic, version, dim, count, hour_unix, name_len = _HEAD.unpack_from(data)
    if magic != MAGIC or version != VERSION:
        raise BadFrameVectorFile(f"not a version-{VERSION} frame-vector file")
    at = _HEAD.size
    model_id = data[at : at + name_len].decode("utf-8")
    at += name_len
    step = _FRAME.size + dim
    if len(data) != at + count * step:
        raise BadFrameVectorFile("size doesn't match the frame count")
    seconds = np.empty(count, dtype=np.float64)
    vectors = np.empty((count, dim), dtype=np.float32)
    for i in range(count):
        offset_ms, scale = _FRAME.unpack_from(data, at)
        q = np.frombuffer(data, dtype=np.int8, count=dim, offset=at + _FRAME.size)
        seconds[i] = offset_ms / 1000
        vectors[i] = q.astype(np.float32) * (scale / 127)
        at += step
    norms = np.linalg.norm(vectors, axis=1, keepdims=True)
    vectors /= np.where(norms == 0, 1, norms)
    return FrameVectors(
        datetime.fromtimestamp(hour_unix, UTC), model_id, seconds, vectors
    )
