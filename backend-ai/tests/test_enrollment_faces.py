"""Phase 8.2: enrollment runs the face pipeline (spec D14, screen C4).

A scripted face model decides how many faces a photo has from its colour, so every case is
covered without the model files; tests with the real models run when they're downloaded."""

import uuid
from pathlib import Path

import pytest
from sqlalchemy import select

from app.ai import fakes
from app.ai.inference import face as stub
from app.ai.inference import face_onnx
from app.ai.interfaces import Face
from app.models import FaceEmbedding
from app.services import people_service
from app.workers.tasks import faces as face_tasks
from tests.conftest import API, create_patient, image_bytes, register_and_login

DATA = Path(__file__).parent / "data"
HAVE_MODELS = all(
    (Path(face_onnx.settings.face_models_dir) / name).exists()
    for name in (face_onnx.DETECTOR_FILE, face_onnx.EMBEDDER_FILE)
)

ONE = (200, 120, 80)  # one face
NONE = (10, 10, 10)  # no face
TWO = (20, 200, 20)  # two people side by side
WITH_POSTER = (30, 30, 200)  # one person + a small face on a poster behind


def _face(x1: float, width: float, value: float) -> Face:
    return Face((x1, 100.0, x1 + width, 100.0 + width), 0.9, (), [value] * 512)


class ScriptedFaces:
    model_id = "scripted-faces"
    dim = 512

    def faces(self, image: bytes) -> list[Face]:
        from io import BytesIO

        from PIL import Image

        pixel = Image.open(BytesIO(image)).convert("RGB").getpixel((0, 0))
        script = {
            ONE: [_face(100, 200, 0.1)],
            NONE: [],
            TWO: [_face(100, 200, 0.2), _face(400, 180, 0.3)],
            WITH_POSTER: [_face(100, 200, 0.4), _face(600, 30, 0.5)],
        }
        # JPEG shifts flat colours a little: take the nearest scripted one
        nearest = min(script, key=lambda c: sum((a - b) ** 2 for a, b in zip(c, pixel)))
        return script[nearest]

    def embed_face(self, image: bytes) -> list[float]:
        return self.faces(image)[0].embedding


class Models:
    def __init__(self, face_model):
        self.face = face_model


@pytest.fixture
def scripted(monkeypatch):
    model = ScriptedFaces()
    monkeypatch.setattr(people_service, "get_ai", lambda: Models(model))
    return model


def _enroll(client, caregiver, patient_id, colors):
    return client.post(
        f"{API}/patients/{patient_id}/people",
        data={"name": "Ahmed", "relationship": "son", "consent_given": "true"},
        files=[
            ("photos", (f"p{i}.jpg", image_bytes(color=c), "image/jpeg"))
            for i, c in enumerate(colors)
        ],
        headers=caregiver["headers"],
    )


def _setup(client):
    manager = register_and_login(client)
    return manager, create_patient(client, manager)["id"]


def test_each_photo_must_show_exactly_one_person(client, scripted):
    manager, patient_id = _setup(client)
    response = _enroll(client, manager, patient_id, [ONE, NONE, TWO])
    assert response.status_code == 422
    body = response.json()["error"]
    assert body["code"] == "PHOTOS_INVALID"  # two kinds of problem at once
    assert body["details"] == [
        {"field": "body.photos.1", "message": "No face found. Please retake it."},
        {
            "field": "body.photos.2",
            "message": "More than one person. Use a photo of this person alone.",
        },
    ]

    only_blank = _enroll(client, manager, patient_id, [NONE])
    assert only_blank.json()["error"]["code"] == "NO_FACE"
    only_group = _enroll(client, manager, patient_id, [TWO])
    assert only_group.json()["error"]["code"] == "MULTIPLE_FACES"


def test_background_faces_dont_count_and_embeddings_are_real(
    client, scripted, worker_session
):
    manager, patient_id = _setup(client)
    response = _enroll(client, manager, patient_id, [ONE, WITH_POSTER])
    assert response.status_code == 201, response.text
    person_id = uuid.UUID(response.json()["id"])
    with worker_session() as db:
        rows = list(
            db.scalars(
                select(FaceEmbedding)
                .where(FaceEmbedding.person_id == person_id)
                .order_by(FaceEmbedding.created_at)
            )
        )
    assert [r.model_version for r in rows] == ["scripted-faces"] * 2
    # the main face's embedding, not the poster's
    assert sorted(round(float(r.embedding[0]), 2) for r in rows) == [0.1, 0.4]


def test_photos_added_later_are_checked_too(client, scripted):
    manager, patient_id = _setup(client)
    person = _enroll(client, manager, patient_id, [ONE]).json()
    response = client.post(
        f"{API}/people/{person['id']}/photos",
        files=[("photos", ("p.jpg", image_bytes(color=NONE), "image/jpeg"))],
        headers=manager["headers"],
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "NO_FACE"


def test_stub_photos_are_re_embedded_once_the_real_model_runs(
    client, worker_session, monkeypatch
):
    manager, patient_id = _setup(client)
    # enrolled while the server still ran the stub
    monkeypatch.setattr(
        people_service, "get_ai", lambda: Models(fakes.StubFaceEmbedder())
    )
    good = _enroll(client, manager, patient_id, [ONE]).json()
    blank = _enroll(client, manager, patient_id, [NONE]).json()  # the stub sees a face
    assert face_tasks.reembed_stub.delay().get() == {
        "skipped": "the face model is still the stub"
    }

    monkeypatch.setattr(people_service, "get_ai", lambda: Models(ScriptedFaces()))
    result = face_tasks.reembed_stub.delay().get()
    assert result["updated"] >= 1  # the shared test database may hold other stub rows
    assert blank["id"] in result["people_to_retake"]
    with worker_session() as db:
        versions = {
            r.person_id: r.model_version
            for r in db.scalars(
                select(FaceEmbedding).where(
                    FaceEmbedding.person_id.in_(
                        [uuid.UUID(good["id"]), uuid.UUID(blank["id"])]
                    )
                )
            )
        }
    assert versions[uuid.UUID(good["id"])] == "scripted-faces"
    assert versions[uuid.UUID(blank["id"])] == stub.MODEL_VERSION  # left for a retake


@pytest.mark.skipif(not HAVE_MODELS, reason="face models not downloaded")
def test_real_model_enrolls_a_face_and_refuses_a_blank_photo(client, monkeypatch):
    monkeypatch.setattr(
        people_service, "get_ai", lambda: Models(face_onnx.OnnxFaceEmbedder())
    )
    manager, patient_id = _setup(client)
    response = client.post(
        f"{API}/patients/{patient_id}/people",
        data={"name": "Eileen", "relationship": "friend", "consent_given": "true"},
        files=[
            ("photos", ("a.jpg", (DATA / "astronaut.jpg").read_bytes(), "image/jpeg"))
        ],
        headers=manager["headers"],
    )
    assert response.status_code == 201, response.text
    blank = _enroll(client, manager, patient_id, [NONE])
    assert blank.json()["error"]["code"] == "NO_FACE"
