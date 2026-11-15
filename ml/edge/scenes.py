"""Scene segments (spec D41, tier 1): consecutive frames cut into runs of similar frames, at
most 30 s each, with 3 representative frame vectors (first, middle, most different).

A segment ends when a frame's vector moves away from the segment's first frame (cosine below
`cut`, the embedding novelty rule of D33) or when 30 s have passed. The "most different"
frame is the one least like the segment's mean; a segment of one or two frames sends fewer
vectors, never the same frame twice.
"""

from dataclasses import dataclass

import numpy as np

MAX_S = 30.0
CUT = 0.85  # DRAFT: cosine to the segment's first frame below which a new scene starts


@dataclass(frozen=True)
class Segment:
    first: int  # index of the first frame
    last: int  # index of the last frame (inclusive)
    roles: dict[str, int]  # role → frame index


def _roles(vectors: np.ndarray, first: int, last: int) -> dict[str, int]:
    roles = {"first": first}
    if last == first:
        return roles
    middle = (first + last + 1) // 2
    if middle != first:
        roles["middle"] = middle
    inside = vectors[first : last + 1]
    mean = inside.mean(axis=0)
    order = np.argsort(inside @ mean)  # least like the segment first
    for i in order:
        index = first + int(i)
        if index not in roles.values():
            roles["most_different"] = index
            break
    return roles


def segment(
    seconds: list[float], vectors: np.ndarray, cut: float = CUT, max_s: float = MAX_S
) -> list[Segment]:
    """seconds: each frame's time, ascending; vectors: (n, dim), unit length."""
    out, start = [], 0
    for i in range(1, len(seconds) + 1):
        if i < len(seconds):
            same_scene = float(vectors[i] @ vectors[start]) >= cut
            if same_scene and seconds[i] - seconds[start] < max_s:
                continue
        out.append(Segment(start, i - 1, _roles(vectors, start, i - 1)))
        start = i
    return out
