"""The first migration and the seed, against a real Postgres + pgvector."""

import os
import subprocess
import sys
from pathlib import Path

import pytest
from sqlalchemy import create_engine, text

BACKEND = Path(__file__).resolve().parents[1]
EXPECTED_TABLES = 27  # + object_sightings, memory_actions (0007)


def _run(args: list[str], database_url: str) -> subprocess.CompletedProcess:
    """Run `python -m <args>` (alembic or the seed) against the test database."""
    env = {**os.environ, "DATABASE_URL": database_url, "ENVIRONMENT": "local"}
    return subprocess.run(
        [sys.executable, "-m", *args],
        check=False,  # callers assert on returncode and show stderr
        cwd=BACKEND,
        env=env,
        capture_output=True,
        text=True,
    )


@pytest.fixture(scope="module")
def migrated(database_url):
    down = _run(["alembic", "downgrade", "base"], database_url)
    assert down.returncode == 0, down.stderr
    up = _run(["alembic", "upgrade", "head"], database_url)
    assert up.returncode == 0, up.stderr
    engine = create_engine(database_url)
    yield engine
    engine.dispose()
    # The last test downgrades to nothing: put the schema back for the test files after this one
    restore = _run(["alembic", "upgrade", "head"], database_url)
    assert restore.returncode == 0, restore.stderr


def _scalar(engine, sql: str):
    with engine.connect() as conn:
        return conn.execute(text(sql)).scalar()


def test_migration_creates_every_spec_table(migrated):
    count = _scalar(
        migrated,
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' "
        "AND table_name <> 'alembic_version'",
    )
    assert count == EXPECTED_TABLES


def test_rls_is_on_for_every_table_with_two_policies_each(migrated):
    without_rls = _scalar(
        migrated,
        "SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
        "WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity",
    )
    policies = _scalar(
        migrated, "SELECT count(*) FROM pg_policies WHERE schemaname = 'public'"
    )
    assert without_rls == 0
    assert policies == EXPECTED_TABLES * 2


def test_vector_indexes_exist(migrated):
    hnsw = _scalar(
        migrated, "SELECT count(*) FROM pg_indexes WHERE indexdef ILIKE '%hnsw%'"
    )
    assert hnsw == 2


def test_models_match_the_migration(database_url, migrated):
    check = _run(["alembic", "check"], database_url)
    assert check.returncode == 0, check.stdout + check.stderr


def test_seed_runs_and_is_idempotent(database_url, migrated):
    first = _run(["scripts.seed"], database_url)
    assert first.returncode == 0, first.stderr
    users_after_first = _scalar(migrated, "SELECT count(*) FROM users")
    events_after_first = _scalar(migrated, "SELECT count(*) FROM events")

    second = _run(["scripts.seed"], database_url)
    assert second.returncode == 0, second.stderr
    assert _scalar(migrated, "SELECT count(*) FROM users") == users_after_first == 3
    assert _scalar(migrated, "SELECT count(*) FROM events") == events_after_first == 10


def test_downgrade_removes_everything(database_url, migrated):
    down = _run(["alembic", "downgrade", "base"], database_url)
    assert down.returncode == 0, down.stderr
    tables = _scalar(
        migrated,
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema = 'public' AND table_name <> 'alembic_version'",
    )
    enums = _scalar(
        migrated,
        "SELECT count(*) FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace "
        "WHERE n.nspname = 'public' AND t.typtype = 'e'",
    )
    assert tables == 0
    assert enums == 0
