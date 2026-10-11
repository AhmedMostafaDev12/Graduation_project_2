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
