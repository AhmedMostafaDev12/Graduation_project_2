"""Register, login, refresh, logout, and how protected routes treat tokens (Phase 3.2)."""

import uuid
from datetime import UTC, datetime, timedelta

import jwt

from app.config import settings
from tests.conftest import API, PASSWORD, register_and_login, unique_email


def test_register_returns_the_user_without_password(client):
    email = unique_email()
    response = client.post(
        f"{API}/auth/register",
        json={
            "full_name": "Ahmed",
            "email": email,
            "password": PASSWORD,
            "phone": "+20100",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["email"] == email
    assert body["role"] == "caregiver"
    assert "password" not in body and "password_hash" not in body


def test_register_same_email_any_case_is_rejected(client):
    caregiver = register_and_login(client)
    response = client.post(
        f"{API}/auth/register",
        json={
            "full_name": "Again",
            "email": caregiver["email"].upper(),
            "password": PASSWORD,
        },
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "EMAIL_TAKEN"


def test_short_password_uses_the_spec_error_shape(client):
    response = client.post(
        f"{API}/auth/register",
        json={"full_name": "A", "email": unique_email(), "password": "short"},
    )
    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "VALIDATION_ERROR"
    assert any(d["field"] == "body.password" for d in error["details"])


def test_login_returns_access_and_refresh_tokens(client):
    caregiver = register_and_login(client)
    tokens = caregiver["tokens"]
    assert tokens["token_type"] == "bearer"
    assert tokens["expires_in"] == settings.access_token_expire_minutes * 60
    claims = jwt.decode(
        tokens["access_token"], settings.jwt_secret, algorithms=["HS256"]
    )
    assert claims["sub"] == caregiver["id"] and claims["role"] == "caregiver"


def test_wrong_password_and_unknown_email_look_the_same(client):
    caregiver = register_and_login(client)
    wrong = client.post(
        f"{API}/auth/login",
        data={"username": caregiver["email"], "password": "nope-nope"},
    )
    unknown = client.post(
        f"{API}/auth/login", data={"username": unique_email(), "password": PASSWORD}
    )
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()
    assert wrong.json()["error"]["code"] == "INVALID_CREDENTIALS"


def test_protected_route_needs_a_valid_token(client):
    body = {"full_name": "P", "relationship": "son"}
    missing = client.post(f"{API}/patients", json=body)
    garbage = client.post(
        f"{API}/patients", json=body, headers={"Authorization": "Bearer not.a.jwt"}
    )
    assert (
        missing.status_code == 401
        and missing.json()["error"]["code"] == "NOT_AUTHENTICATED"
    )
    assert missing.headers["WWW-Authenticate"] == "Bearer"
    assert (
        garbage.status_code == 401
        and garbage.json()["error"]["code"] == "INVALID_TOKEN"
    )


def test_expired_access_token_is_rejected(client):
    caregiver = register_and_login(client)
    expired = jwt.encode(
        {
            "sub": caregiver["id"],
            "role": "caregiver",
            "type": "access",
            "exp": datetime.now(UTC) - timedelta(minutes=1),
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
    response = client.post(
        f"{API}/patients",
        json={"full_name": "P", "relationship": "son"},
        headers={"Authorization": f"Bearer {expired}"},
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "TOKEN_EXPIRED"


def test_token_for_a_user_that_does_not_exist_is_rejected(client):
    forged = jwt.encode(
        {
            "sub": str(uuid.uuid4()),
            "role": "caregiver",
            "type": "access",
            "exp": datetime.now(UTC) + timedelta(minutes=5),
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
    response = client.post(
        f"{API}/patients",
        json={"full_name": "P", "relationship": "son"},
        headers={"Authorization": f"Bearer {forged}"},
    )
    assert response.status_code == 401


def test_refresh_rotates_and_the_old_refresh_token_stops_working(client):
    old = register_and_login(client)["tokens"]["refresh_token"]
    first = client.post(f"{API}/auth/refresh", json={"refresh_token": old})
    assert first.status_code == 200
    assert first.json()["refresh_token"] != old

    reused = client.post(f"{API}/auth/refresh", json={"refresh_token": old})
    assert reused.status_code == 401
    assert reused.json()["error"]["code"] == "INVALID_REFRESH_TOKEN"


def test_logout_revokes_the_refresh_token_and_is_idempotent(client):
    refresh = register_and_login(client)["tokens"]["refresh_token"]
    assert (
        client.post(f"{API}/auth/logout", json={"refresh_token": refresh}).status_code
        == 204
    )
    assert (
        client.post(f"{API}/auth/logout", json={"refresh_token": refresh}).status_code
        == 204
    )
    after = client.post(f"{API}/auth/refresh", json={"refresh_token": refresh})
    assert after.status_code == 401
