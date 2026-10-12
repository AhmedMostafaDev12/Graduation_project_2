"""Authentication and authorization (course: oauth2.py).

Two kinds of callers send `Authorization: Bearer <token>`:
- a caregiver, with a JWT access token from /auth/login (15 minutes);
- a patient's paired phone, with its device token from /devices/pair.
A JWT always has two dots; device tokens never do. That's how the two are told apart.
"""

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Literal

import jwt
from fastapi import Depends
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
    OAuth2PasswordBearer,
)
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.errors import Forbidden, NotFound, Unauthorized
from app.models import CaregiverPatientLink, Device, User
from app.utils import hash_token

# Swagger's "Authorize" button logs in with the caregiver form (as in the course);
# the plain bearer scheme lets you paste a device token too.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)
bearer_scheme = HTTPBearer(auto_error=False, description="Access token or device token")


def create_access_token(user: User) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": str(user.id),
        "role": user.role,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def _decode_access_token(token: str) -> uuid.UUID:
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
    except jwt.ExpiredSignatureError as exc:
        raise Unauthorized("Your session has expired.", code="TOKEN_EXPIRED") from exc
    except jwt.InvalidTokenError as exc:
        raise Unauthorized("Invalid token.", code="INVALID_TOKEN") from exc
    if payload.get("type") != "access":
        raise Unauthorized("Invalid token.", code="INVALID_TOKEN")
    return uuid.UUID(payload["sub"])


@dataclass
class Principal:
    """Who is calling: a caregiver (user) or a patient's paired phone (device)."""

    kind: Literal["caregiver", "device"]
    user: User | None = None
    device: Device | None = None


def get_principal(
    oauth_token: str | None = Depends(oauth2_scheme),
    bearer: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Principal:
    token = oauth_token or (bearer.credentials if bearer else None)
    if not token:
        raise Unauthorized("Sign in to continue.")

    if token.count(".") == 2:  # JWT access token
        user = db.get(User, _decode_access_token(token))
        if user is None or user.deleted_at is not None or user.role != "caregiver":
            raise Unauthorized("Invalid token.", code="INVALID_TOKEN")
        return Principal(kind="caregiver", user=user)

    device = db.scalar(select(Device).where(Device.token_hash == hash_token(token)))
    if device is None:
        raise Unauthorized("Invalid token.", code="INVALID_TOKEN")
    return Principal(kind="device", device=device)


def get_current_user(principal: Principal = Depends(get_principal)) -> User:
    """Caregiver-only routes."""
    if principal.kind != "caregiver":
        raise Forbidden("Only caregivers can do this.", code="CAREGIVER_ONLY")
    return principal.user


def get_current_device(principal: Principal = Depends(get_principal)) -> Device:
    """Routes for the patient's paired phone."""
    if principal.kind != "device":
        raise Forbidden("Only a paired patient phone can do this.", code="DEVICE_ONLY")
    return principal.device


@dataclass
class PatientAccess:
    patient_id: uuid.UUID
    permission: Literal["manager", "viewer", "device"]
    principal: Principal


def check_patient_access(
    db: Session, principal: Principal, patient_id: uuid.UUID
) -> PatientAccess:
    """Is this caller allowed to touch this patient? Unknown and not-linked look the same (404),
    so a caregiver can't discover which patients exist."""
    not_found = NotFound("Patient not found.", code="PATIENT_NOT_FOUND")
    if principal.kind == "device":
        if principal.device.patient_id != patient_id:
            raise not_found
        return PatientAccess(patient_id, "device", principal)

    link = db.scalar(
        select(CaregiverPatientLink)
        .join(User, User.id == CaregiverPatientLink.patient_id)
        .where(
            CaregiverPatientLink.caregiver_id == principal.user.id,
            CaregiverPatientLink.patient_id == patient_id,
            User.deleted_at.is_(None),
        )
    )
    if link is None:
        raise not_found
    return PatientAccess(patient_id, link.permission, principal)


def require_patient_link(
    patient_id: uuid.UUID,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> PatientAccess:
    """Every /patients/{patient_id}/... route depends on this (docs/ARCHITECTURE.md §4)."""
    return check_patient_access(db, principal, patient_id)


def require_patient_manager(
    access: PatientAccess = Depends(require_patient_link),
) -> PatientAccess:
    """Changes to a patient's setup need a caregiver with the 'manager' permission."""
    if access.permission != "manager":
        raise Forbidden("Only a managing caregiver can do this.", code="MANAGER_ONLY")
    return access


def require_editor(access: PatientAccess, allow_device: bool = False) -> PatientAccess:
    """Writes: a managing caregiver, or (where the patient's phone writes) its device."""
    if access.permission == "manager" or (
        allow_device and access.permission == "device"
    ):
        return access
    if access.permission == "device":
        raise Forbidden("Only a caregiver can do this.", code="CAREGIVER_ONLY")
    raise Forbidden("Only a managing caregiver can do this.", code="MANAGER_ONLY")


def load_for_patient(
    db: Session, principal: Principal, model, obj_id, what: str, code: str
):
    """Load a record by its own id (/people/{id}, /media/{id}, ...) and check the caller may
    access the record's patient. A record you can't access looks exactly like a missing one."""
    obj = db.get(model, obj_id)
    not_found = NotFound(f"{what} not found.", code=code)
    if obj is None or getattr(obj, "deleted_at", None) is not None:
        raise not_found
    try:
        access = check_patient_access(db, principal, obj.patient_id)
    except NotFound:
        raise not_found from None
    return obj, access
