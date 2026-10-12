"""Database sessions for tasks. A task opens its own session (it has no request);
tests swap `make_session` for the test database."""

from app.database import SessionLocal


def make_session():
    return SessionLocal()
