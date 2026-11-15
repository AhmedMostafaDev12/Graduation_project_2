"""The 30-second look-back buffer (spec D42): when any gate rule fires, also keep the 3–5 most
different frames of the last 30 s, because the moment worth remembering (keys put down) often
comes seconds before the trigger. Frames are compared by a feature vector (on the glasses: the
frame embedding, D34; in the replay: a stand-in)."""

import numpy as np

WINDOW_S = 30.0


def most_different(
    features: list, k: int, anchor=None, min_distance: float = 0.0
) -> list:
    """Indices of up to k vectors that are farthest apart (greedy farthest-point), starting from the
    one farthest from `anchor` (the trigger frame). Fewer when the buffer is nearly static: a
    candidate closer than `min_distance` (L1) to everything already picked is not taken."""
    if not features or k <= 0:
        return []
    vectors = np.stack(features)
    picked = []
    reference = [np.asarray(anchor)] if anchor is not None else []
    for _ in range(min(k, len(vectors))):
        if reference:
            dist = np.min(
                np.stack([np.abs(vectors - r).sum(1) for r in reference]), axis=0
            )
        else:
            dist = np.abs(vectors - vectors.mean(0)).sum(1)
        dist[picked] = -1
        i = int(dist.argmax())
        if dist[i] < min_distance:
            break
        picked.append(i)
        reference.append(vectors[i])
    return sorted(picked)
