"""Shared test fixtures.

Database tests need a real Postgres with pgvector (as in the course's tests/database.py):
locally the Docker one from docker-compose.dev.yml, in CI a service container.
Point TEST_DATABASE_URL at an empty database; the tests create and drop the schema.
"""

import os

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg://remori:remori@localhost:5434/remori_test"
)


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
