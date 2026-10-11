"""Caregiver accounts and sessions: register, login, refresh, logout."""

from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.config import settings
from app.errors import Conflict, Unauthorized
from app.models import RefreshToken, User
from app.oauth2 import create_access_token
from app.schemas.accounts import CaregiverCreate
from app.utils import hash_password, hash_token, new_token, verify_password


def _find_by_email(db: Session, email: str) -> User | None:
    return db.scalar(
        select(User).where(
            func.lower(User.email) == email.lower(), User.deleted_at.is_(None)
        )
    )


def register_caregiver(db: Session, data: CaregiverCreate) -> User:
    if _find_by_email(db, data.email):
        raise Conflict("An account with this email already exists.", code="EMAIL_TAKEN")
    user = User(
        role="caregiver",
        full_name=data.full_name.strip(),
        email=data.email.lower(),
        phone=data.phone,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def issue_tokens(db: Session, user: User) -> dict:
    """A 15-minute access token + a refresh token stored only as a hash."""
    refresh = new_token()
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=hash_token(refresh),
            expires_at=datetime.now(UTC)
            + timedelta(days=settings.refresh_token_expire_days),
        )
    )
    db.commit()
    return {
        "access_token": create_access_token(user),
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": settings.access_token_expire_minutes * 60,
    }


def login(db: Session, email: str, password: str) -> dict:
    user = _find_by_email(db, email)
    password_ok = verify_password(password, user.password_hash if user else None)
    if user is None or not password_ok or user.role != "caregiver":
        # Same message for "no such email" and "wrong password"
        raise Unauthorized("Wrong email or password.", code="INVALID_CREDENTIALS")
    return issue_tokens(db, user)


def _active_refresh_token(db: Session, refresh_token: str) -> RefreshToken | None:
    row = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_token(refresh_token))
    )
    if row is None or row.revoked_at is not None or row.expires_at <= datetime.now(UTC):
        return None
    return row


def refresh(db: Session, refresh_token: str) -> dict:
    """Rotation: the old refresh token stops working and a new pair is issued."""
    row = _active_refresh_token(db, refresh_token)
    user = db.get(User, row.user_id) if row else None
    if row is None or user is None or user.deleted_at is not None:
        raise Unauthorized("Please sign in again.", code="INVALID_REFRESH_TOKEN")
    row.revoked_at = datetime.now(UTC)
    return issue_tokens(db, user)


def logout(db: Session, refresh_token: str) -> None:
    """Idempotent: logging out twice, or with an unknown token, is not an error."""
    row = _active_refresh_token(db, refresh_token)
    if row is not None:
        row.revoked_at = datetime.now(UTC)
        db.commit()
