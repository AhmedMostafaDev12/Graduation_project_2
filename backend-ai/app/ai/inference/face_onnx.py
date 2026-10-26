"""Server-side face pipeline: detect → align → embed (spec D14, phase 8.1).

InsightFace `buffalo_s` models, run with onnxruntime on the CPU:
- SCRFD `det_500m`: face boxes + 5 landmarks (eyes, nose, mouth corners);
- MobileFaceNet `w600k_mbf`: a 512-d embedding of the face aligned to 112×112.

This is the **shared, versioned face pipeline** of D14: the glasses must reproduce it exactly
(same models, same preprocessing below) or their embeddings won't match the enrolled ones.
Only numpy and Pillow are used (no OpenCV); the steps mirror InsightFace's reference code.

Model files: downloaded and checked at image build (`scripts/download_face_models.py`), loaded
once per process from FACE_MODELS_DIR. The InsightFace pretrained models are licensed for
non-commercial research use: fine for the graduation project, not for a commercial launch.
Never log images or embeddings (AI_LAYER.md rule 8).
"""

import io
from functools import cache
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

from app.ai.interfaces import Face
from app.config import settings
from app.models import FACE_DIM

MODEL_VERSION = "w600k_mbf"  # the same version string the glasses send (spec §7.1)
DETECTOR_FILE = "det_500m.onnx"
EMBEDDER_FILE = "w600k_mbf.onnx"

DET_SIZE = 640  # the detector sees the photo letterboxed into 640×640
DET_THRESHOLD = 0.5
NMS_IOU = 0.4
STRIDES = (8, 16, 32)
ANCHORS_PER_CELL = 2
MAX_PIXELS = 40_000_000  # refuse decompression bombs before decoding

# where the 5 landmarks go in the 112×112 crop (InsightFace's ArcFace template)
ARCFACE_TEMPLATE = np.array(
    [
        [38.2946, 51.6963],
        [73.5318, 51.5014],
        [56.0252, 71.7366],
        [41.5493, 92.3655],
        [70.7299, 92.2041],
    ],
    dtype=np.float64,
)
CROP = 112


class FaceImageError(Exception):
    """The bytes aren't an image we can read: permanent, not retried."""


class FaceModelMissing(RuntimeError):
    """The model files aren't where FACE_MODELS_DIR points (run the download script)."""


# ----- image -----


def load_image(data: bytes) -> Image.Image:
    """RGB, upright (phone photos store their rotation in EXIF)."""
    try:
        with Image.open(io.BytesIO(data)) as probe:
            if probe.width * probe.height > MAX_PIXELS:
                raise FaceImageError("image too large")
        image = Image.open(io.BytesIO(data))
        return ImageOps.exif_transpose(image).convert("RGB")
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise FaceImageError("not a readable image") from exc


# ----- detection (SCRFD) -----


def letterbox(image: Image.Image) -> tuple[np.ndarray, float]:
    """The photo scaled to fit 640×640 (top-left, black padding) as a 1×3×640×640 blob."""
    scale = DET_SIZE / max(image.width, image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    canvas = Image.new("RGB", (DET_SIZE, DET_SIZE))
    canvas.paste(image.resize(size, Image.Resampling.BILINEAR), (0, 0))
    blob = (np.asarray(canvas, dtype=np.float32) - 127.5) / 128.0
    return blob.transpose(2, 0, 1)[None], scale


def anchor_centers(stride: int) -> np.ndarray:
    cells = DET_SIZE // stride
    grid = np.stack(np.mgrid[:cells, :cells][::-1], axis=-1).astype(np.float32)
    centers = (grid * stride).reshape(-1, 2)
    return np.repeat(centers, ANCHORS_PER_CELL, axis=0)


def decode(outputs: list[np.ndarray], threshold: float = DET_THRESHOLD):
    """SCRFD outputs (scores ×3, box distances ×3, landmark distances ×3) → candidates."""
    scores, boxes, points = [], [], []
    n = len(STRIDES)
    for i, stride in enumerate(STRIDES):
        score = outputs[i].reshape(-1)
        keep = score >= threshold
        if not keep.any():
            continue
        centers = anchor_centers(stride)[keep]
        distance = outputs[i + n].reshape(-1, 4)[keep] * stride
        offsets = outputs[i + 2 * n].reshape(-1, 10)[keep] * stride
        boxes.append(np.hstack([centers - distance[:, :2], centers + distance[:, 2:]]))
        points.append(centers[:, None, :] + offsets.reshape(-1, 5, 2))
        scores.append(score[keep])
    if not scores:
        return np.zeros(0), np.zeros((0, 4)), np.zeros((0, 5, 2))
    return np.concatenate(scores), np.concatenate(boxes), np.concatenate(points)


def nms(boxes: np.ndarray, scores: np.ndarray, iou: float = NMS_IOU) -> list[int]:
    order = scores.argsort()[::-1]
    area = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    kept = []
    while order.size:
        best, rest = order[0], order[1:]
        kept.append(int(best))
        x1 = np.maximum(boxes[best, 0], boxes[rest, 0])
        y1 = np.maximum(boxes[best, 1], boxes[rest, 1])
        x2 = np.minimum(boxes[best, 2], boxes[rest, 2])
        y2 = np.minimum(boxes[best, 3], boxes[rest, 3])
        inter = np.clip(x2 - x1, 0, None) * np.clip(y2 - y1, 0, None)
        overlap = inter / (area[best] + area[rest] - inter)
        order = rest[overlap <= iou]
    return kept


# ----- alignment -----


def similarity_transform(src: np.ndarray, dst: np.ndarray) -> np.ndarray:
    """2×3 matrix of the rotation + uniform scale + shift mapping src onto dst
    (least squares, Umeyama 1991: what skimage's SimilarityTransform estimates)."""
    mu_src, mu_dst = src.mean(axis=0), dst.mean(axis=0)
    s, d = src - mu_src, dst - mu_dst
    u, sigma, vt = np.linalg.svd(d.T @ s / len(src))
    sign = np.eye(2)
    if np.linalg.det(u) * np.linalg.det(vt) < 0:
        sign[1, 1] = -1
    rotation = u @ sign @ vt
    scale = (sigma * np.diag(sign)).sum() / ((s**2).sum() / len(src))
    shift = mu_dst - scale * rotation @ mu_src
    return np.hstack([scale * rotation, shift[:, None]])


def align(image: Image.Image, landmarks: np.ndarray) -> Image.Image:
    """The face warped so its landmarks sit on the ArcFace template, 112×112."""
    matrix = similarity_transform(landmarks.astype(np.float64), ARCFACE_TEMPLATE)
    # Pillow maps each output pixel back to the input, so it needs the inverse
    inverse = np.linalg.inv(matrix[:, :2])
    shift = -inverse @ matrix[:, 2]
    coefficients = (*inverse[0], shift[0], *inverse[1], shift[1])
    return image.transform(
        (CROP, CROP), Image.Transform.AFFINE, coefficients, Image.Resampling.BILINEAR
    )


# ----- the pipeline -----


def _models_dir() -> Path:
    return Path(settings.face_models_dir)


@cache
def _sessions():
    import onnxruntime  # imported here: only processes that touch faces pay for it

    paths = [_models_dir() / DETECTOR_FILE, _models_dir() / EMBEDDER_FILE]
    missing = [p.name for p in paths if not p.exists()]
    if missing:
        raise FaceModelMissing(
            f"face model files missing in {_models_dir()}: {missing}. "
            "Run: python scripts/download_face_models.py"
        )
    options = onnxruntime.SessionOptions()
    options.intra_op_num_threads = 1  # small models; leave the CPU to the other workers
    return tuple(
        onnxruntime.InferenceSession(
            str(p), options, providers=["CPUExecutionProvider"]
        )
        for p in paths
    )


def detect(image: Image.Image) -> list[tuple[np.ndarray, float, np.ndarray]]:
    """(box, score, landmarks) for every face, in the photo's pixels, best first."""
    detector, _ = _sessions()
    blob, scale = letterbox(image)
    outputs = detector.run(None, {detector.get_inputs()[0].name: blob})
    scores, boxes, points = decode(outputs)
    if not len(scores):
        return []
    boxes, points = boxes / scale, points / scale
    return [(boxes[i], float(scores[i]), points[i]) for i in nms(boxes, scores)]


def embed_aligned(crop: Image.Image) -> list[float]:
    _, embedder = _sessions()
    blob = (np.asarray(crop, dtype=np.float32) - 127.5) / 127.5
    output = embedder.run(
        None, {embedder.get_inputs()[0].name: blob.transpose(2, 0, 1)[None]}
    )[0][0]
    return (output / np.linalg.norm(output)).astype(float).tolist()


class OnnxFaceEmbedder:
    """`FaceEmbedder` for the `production` and `small` profiles (registry: mobilefacenet-onnx)."""

    model_id = MODEL_VERSION
    dim = FACE_DIM

    def __init__(self):
        _sessions()  # fail at start if the model files are missing

    def faces(self, image: bytes) -> list[Face]:
        photo = load_image(image)
        found = []
        for box, score, landmarks in detect(photo):
            found.append(
                Face(
                    box=tuple(float(v) for v in box),
                    score=score,
                    landmarks=tuple((float(x), float(y)) for x, y in landmarks),
                    embedding=embed_aligned(align(photo, landmarks)),
                )
            )
        return found

    def embed_face(self, image: bytes) -> list[float]:
        """The embedding of the most confident face; FaceImageError if there is none."""
        found = self.faces(image)
        if not found:
            raise FaceImageError("no face found")
        return found[0].embedding
