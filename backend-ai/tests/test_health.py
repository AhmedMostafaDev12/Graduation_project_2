from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from app.database import get_db
from app.main import app


class _HealthyDB:
    def execute(self, statement):
        return None


class _BrokenDB:
    def execute(self, statement):
        raise OperationalError("SELECT 1", {}, Exception("connection refused"))


def _client_with(db) -> TestClient:
    app.dependency_overrides[get_db] = lambda: db
    return TestClient(app)


def teardown_function():
    app.dependency_overrides.clear()


def test_health_ok():
    response = _client_with(_HealthyDB()).get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}


def test_health_database_down_uses_error_shape():
    response = _client_with(_BrokenDB()).get("/health")

    assert response.status_code == 503
    assert response.json() == {
        "error": {
            "code": "DATABASE_UNAVAILABLE",
            "message": "The database is not reachable.",
        }
    }
