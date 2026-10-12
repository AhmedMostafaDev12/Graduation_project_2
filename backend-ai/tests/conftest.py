"""Shared test fixtures.

Database tests need a real Postgres with pgvector (as in the course's tests/database.py):
locally the Docker one from docker-compose.dev.yml, in CI a service container.
Point TEST_DATABASE_URL at an empty database; the tests create and drop the schema.
"""

import os
import subprocess
import sys
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker

from app.database import get_db
from app.main import app

TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg://remori:remori@localhost:5434/remori_test"
)
BACKEND = Path(__file__).resolve().parents[1]
API = "/api/v1"
PASSWORD = "correct-horse-battery"


def _ensure_database(url: str) -> None:
    """Create the test database if it doesn't exist (connects to the server's 'postgres' db)."""
    base, name = url.rsplit("/", 1)
    admin = create_engine(f"{base}/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        exists = conn.execute(
            text("SELECT 1 FROM pg_database WHERE datname = :name"), {"name": name}
        ).scalar()
        if not exists:
            conn.execute(text(f'CREATE DATABASE "{name}"'))
    admin.dispose()


@pytest.fixture(scope="session")
def database_url() -> str:
    try:
        _ensure_database(TEST_DATABASE_URL)
    except OperationalError as exc:  # no database: skip DB tests, keep the rest running
        pytest.skip(f"Test database not reachable: {exc}")
    return TEST_DATABASE_URL


@pytest.fixture(scope="session")
def migrated_engine(database_url):
    """The test database at the latest migration (course: tests/database.py)."""
    env = {**os.environ, "DATABASE_URL": database_url, "ENVIRONMENT": "local"}
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        check=False,
        cwd=BACKEND,
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    engine = create_engine(database_url)
    yield engine
    engine.dispose()


@pytest.fixture
def client(migrated_engine):
    """A TestClient whose requests use the test database (course: conftest.py `client`)."""
    testing_session = sessionmaker(
        bind=migrated_engine, autoflush=False, expire_on_commit=False
    )

    def override_get_db():
        db = testing_session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


class FakeS3:
    """In-memory stand-in for app.integrations.s3, so tests never reach AWS."""

    def __init__(self):
        self.objects: dict[str, bytes] = {}

    def presign_put(self, key, content_type):
        return f"https://fake-s3.test/{key}?op=put"

    def presign_get(self, key):
        return f"https://fake-s3.test/{key}?op=get"

    def put_bytes(self, key, data, content_type):
        self.objects[key] = data

    def get_bytes(self, key, max_bytes):
        data = self.objects[key]
        return None if len(data) > max_bytes else data

    def exists(self, key):
        return key in self.objects

    def delete(self, key):
        self.objects.pop(key, None)

    def list_keys(self, prefix):
        return sorted(k for k in self.objects if k.startswith(prefix))


@pytest.fixture(autouse=True)
def fake_s3(monkeypatch):
    from app.integrations import s3

    fake = FakeS3()
    for name in (
        "presign_put",
        "presign_get",
        "put_bytes",
        "get_bytes",
        "exists",
        "delete",
        "list_keys",
    ):
        monkeypatch.setattr(s3, name, getattr(fake, name))
    return fake


# ----- helpers: every test makes its own fresh accounts, so tests never share data -----


def unique_email(prefix: str = "caregiver") -> str:
    return f"{prefix}-{uuid.uuid4().hex[:10]}@example.com"


def register_and_login(client, email: str | None = None) -> dict:
    """Create a caregiver and return {"email", "id", "tokens", "headers"}."""
    email = email or unique_email()
    created = client.post(
        f"{API}/auth/register",
        json={"full_name": "Test Caregiver", "email": email, "password": PASSWORD},
    )
    assert created.status_code == 201, created.text
    tokens = client.post(
        f"{API}/auth/login", data={"username": email, "password": PASSWORD}
    ).json()
    return {
        "email": email,
        "id": created.json()["id"],
        "tokens": tokens,
        "headers": {"Authorization": f"Bearer {tokens['access_token']}"},
    }


def create_patient(client, caregiver: dict, name: str = "Test Patient") -> dict:
    response = client.post(
        f"{API}/patients",
        json={
            "full_name": name,
            "relationship": "son",
            "consents": ["cloud_processing"],
        },
        headers=caregiver["headers"],
    )
    assert response.status_code == 201, response.text
    return response.json()


def pair_device(client, caregiver: dict, patient_id: str) -> dict:
    """Pair new glasses to the patient; returns the pairing body plus "headers" for the phone."""
    response = client.post(
        f"{API}/devices/pair",
        json={
            "serial_number": f"RMR-T{uuid.uuid4().hex[:6].upper()}",
            "patient_id": patient_id,
        },
        headers=caregiver["headers"],
    )
    assert response.status_code == 201, response.text
    body = response.json()
    body["headers"] = {"Authorization": f"Bearer {body['device_token']}"}
    return body


def add_viewer(client, manager: dict, patient_id: str) -> dict:
    """A second caregiver linked with view-only permission."""
    viewer = register_and_login(client)
    response = client.post(
        f"{API}/patients/{patient_id}/caregivers",
        json={
            "email": viewer["email"],
            "relationship": "nurse",
            "permission": "viewer",
        },
        headers=manager["headers"],
    )
    assert response.status_code == 201, response.text
    return viewer


def image_bytes(fmt: str = "JPEG", color=(200, 120, 80), size=(1200, 900)) -> bytes:
    """A real, decodable photo (enrollment rejects files Pillow can't open)."""
    import io

    from PIL import Image

    out = io.BytesIO()
    Image.new("RGB", size, color).save(out, fmt)
    return out.getvalue()
