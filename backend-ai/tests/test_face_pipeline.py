"""Phase 8.1: the server face pipeline (SCRFD detect → align → MobileFaceNet embed, spec D14).

The math (anchors, decoding, NMS, alignment) is tested on its own. Tests that need the real
model files run when they're present (locally after scripts/download_face_models.py, and in
the Docker image) and are skipped otherwise (CI doesn't download them)."""

import io
from pathlib import Path

import numpy as np
import pytest
from PIL import Image

from app.ai import fakes
from app.ai.inference import face_onnx as F
from app.models import FACE_DIM

DATA = Path(__file__).parent / "data"
HAVE_MODELS = all(
    (Path(F.settings.face_models_dir) / name).exists()
    for name in (F.DETECTOR_FILE, F.EMBEDDER_FILE)
)
needs_models = pytest.mark.skipif(
    not HAVE_MODELS,
    reason="face models not downloaded (scripts/download_face_models.py)",
)


def _jpeg(image: Image.Image, **save) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, "JPEG", **save)
    return buffer.getvalue()


# ----- the math, no models -----


def test_anchor_centers_follow_the_scrfd_layout():
    centers = F.anchor_centers(32)
    assert centers.shape == ((640 // 32) ** 2 * 2, 2)
    # two anchors per cell, cells row by row, (x, y) in pixels
    assert centers[:4].tolist() == [[0, 0], [0, 0], [32, 0], [32, 0]]
    assert centers[2 * 20].tolist() == [0, 32]


def test_decode_turns_distances_into_boxes_and_landmarks():
    outputs = []
    sizes = [(640 // s) ** 2 * 2 for s in F.STRIDES]
    for n in sizes:
        outputs.append(np.zeros((n, 1), np.float32))
    for n in sizes:
        outputs.append(np.zeros((n, 4), np.float32))
    for n in sizes:
        outputs.append(np.zeros((n, 10), np.float32))
    # one confident anchor at stride 32, cell (x=2, y=1) → center (64, 32)
    index = (1 * 20 + 2) * 2
    outputs[2][index] = 0.9
    outputs[5][index] = [1, 0.5, 1, 0.5]  # ×32 → left 32, top 16, right 32, bottom 16
    outputs[8][index] = [0.25] * 10  # every landmark at center + (8, 8)
    scores, boxes, points = F.decode(outputs)
    assert scores.tolist() == pytest.approx([0.9])
    assert boxes[0].tolist() == [32, 16, 96, 48]
    assert points[0].tolist() == [[72, 40]] * 5


def test_nms_keeps_the_best_of_overlapping_boxes():
    boxes = np.array([[0, 0, 10, 10], [1, 1, 11, 11], [50, 50, 60, 60]], np.float64)
    scores = np.array([0.8, 0.9, 0.7])
    assert F.nms(boxes, scores) == [1, 2]


def test_similarity_transform_recovers_rotation_scale_and_shift():
    angle, scale, shift = np.deg2rad(25), 1.7, np.array([12.0, -4.0])
    rotation = np.array(
        [[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]]
    )
    src = F.ARCFACE_TEMPLATE
    dst = (scale * rotation @ src.T).T + shift
    matrix = F.similarity_transform(src, dst)
    assert matrix[:, :2] == pytest.approx(scale * rotation, abs=1e-9)
    assert matrix[:, 2] == pytest.approx(shift, abs=1e-9)


def test_landmarks_on_the_template_give_an_identity_crop():
    image = Image.new("RGB", (112, 112))
    image.putpixel((56, 72), (255, 0, 0))
    crop = F.align(image, F.ARCFACE_TEMPLATE.copy())
    assert crop.size == (112, 112)
    assert crop.getpixel((56, 72))[0] > 200  # the marked pixel stays in place


def test_unreadable_bytes_are_rejected():
    with pytest.raises(F.FaceImageError):
        F.load_image(b"not an image")


def test_phone_rotation_is_applied():
    portrait = Image.new("RGB", (40, 80))
    exif = Image.Exif()
    exif[0x0112] = 6  # "rotate 90° clockwise to view"
    upright = F.load_image(_jpeg(portrait, exif=exif))
    assert upright.size == (80, 40)


def test_the_stub_returns_one_whole_photo_face():
    found = fakes.StubFaceEmbedder().faces(b"photo")
    assert len(found) == 1 and len(found[0].embedding) == FACE_DIM


# ----- with the real models -----


@needs_models
def test_one_face_found_and_embedded():
    found = F.OnnxFaceEmbedder().faces((DATA / "astronaut.jpg").read_bytes())
    assert len(found) == 1
    face = found[0]
    assert face.score > 0.6 and len(face.landmarks) == 5
    x1, y1, x2, y2 = face.box
    assert 150 < x1 < x2 < 300 and 30 < y1 < y2 < 220  # the face, not the whole photo
    assert len(face.embedding) == FACE_DIM
    assert np.linalg.norm(face.embedding) == pytest.approx(1.0, abs=1e-5)


@needs_models
def test_same_person_matches_and_different_people_dont():
    embedder = F.OnnxFaceEmbedder()
    photo = Image.open(DATA / "astronaut.jpg")
    original = embedder.embed_face(_jpeg(photo))
    mirrored = embedder.embed_face(
        _jpeg(photo.transpose(Image.Transpose.FLIP_LEFT_RIGHT))
    )
    rotated = embedder.embed_face(_jpeg(photo.rotate(20, expand=True)))
    other = embedder.embed_face((DATA / "cameraman.jpg").read_bytes())
    assert np.dot(original, mirrored) > 0.8
    assert np.dot(original, rotated) > 0.8
    assert np.dot(original, other) < 0.3


@needs_models
def test_a_photo_without_faces_finds_none():
    embedder = F.OnnxFaceEmbedder()
    assert embedder.faces(_jpeg(Image.new("RGB", (640, 480), (120, 160, 90)))) == []
    with pytest.raises(F.FaceImageError, match="no face"):
        embedder.embed_face(_jpeg(Image.new("RGB", (64, 64))))


def test_missing_model_files_fail_clearly(monkeypatch, tmp_path):
    monkeypatch.setattr(F.settings, "face_models_dir", str(tmp_path))
    F._sessions.cache_clear()
    try:
        with pytest.raises(F.FaceModelMissing, match="download_face_models"):
            F.OnnxFaceEmbedder()
    finally:
        F._sessions.cache_clear()
