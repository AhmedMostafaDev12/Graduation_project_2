"""Creating patients (screen A4) and linking more caregivers (screen C19)."""

import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound
from app.models import CaregiverPatientLink, ConsentRecord, PatientProfile, User
from app.schemas.accounts import (
    CaregiverLinkCreate,
    CaregiverLinkOut,
    MyPatientOut,
    PatientCreate,
    PatientOut,
)


def _patient_out(patient: User, profile: PatientProfile) -> PatientOut:
    return PatientOut(
        id=patient.id,
        full_name=patient.full_name,
        preferred_language=profile.preferred_language,
        timezone=profile.timezone,
        date_of_birth=profile.date_of_birth,
        memory_capture_enabled=profile.memory_capture_enabled,
        created_at=patient.created_at,
    )


def list_my_patients(db: Session, caregiver: User) -> list[MyPatientOut]:
    rows = db.execute(
        select(User, PatientProfile, CaregiverPatientLink)
        .join(PatientProfile, PatientProfile.user_id == User.id)
        .join(CaregiverPatientLink, CaregiverPatientLink.patient_id == User.id)
        .where(
            CaregiverPatientLink.caregiver_id == caregiver.id, User.deleted_at.is_(None)
        )
        .order_by(CaregiverPatientLink.is_primary.desc(), User.full_name)
    )
    return [
        MyPatientOut(
            **_patient_out(patient, profile).model_dump(),
            relationship=link.relationship,
            permission=link.permission,
            is_primary=link.is_primary,
        )
        for patient, profile, link in rows
    ]


def create_patient(db: Session, caregiver: User, data: PatientCreate) -> PatientOut:
    """The creating caregiver becomes the patient's primary, managing caregiver."""
    now = datetime.now(UTC)
    patient = User(role="patient", full_name=data.full_name.strip())
    db.add(patient)
    db.flush()  # get the patient's id

    profile = PatientProfile(
        user_id=patient.id,
        preferred_language=data.preferred_language,
        timezone=data.timezone,
        date_of_birth=data.date_of_birth,
        memory_capture_enabled=True,
    )
    db.add(profile)
    db.add(
        CaregiverPatientLink(
            caregiver_id=caregiver.id,
            patient_id=patient.id,
            relationship=data.relationship.strip(),
            is_primary=True,
            permission="manager",
        )
    )
    for consent_type in dict.fromkeys(data.consents):  # ignore duplicates
        db.add(
            ConsentRecord(
                patient_id=patient.id,
                consent_type=consent_type,
                given_by=caregiver.id,
                given_at=now,
            )
        )
    db.commit()
    db.refresh(patient)
    db.refresh(profile)
    return _patient_out(patient, profile)


def link_caregiver(
    db: Session, patient_id: uuid.UUID, data: CaregiverLinkCreate
) -> CaregiverLinkOut:
    """Link an existing caregiver account by email. (Sending invitation emails is not in scope.)"""
    caregiver = db.scalar(
        select(User).where(
            func.lower(User.email) == data.email.lower(),
            User.role == "caregiver",
            User.deleted_at.is_(None),
        )
    )
    if caregiver is None:
        raise NotFound(
            "No caregiver account uses this email.", code="CAREGIVER_NOT_FOUND"
        )

    exists = db.scalar(
        select(CaregiverPatientLink).where(
            CaregiverPatientLink.caregiver_id == caregiver.id,
            CaregiverPatientLink.patient_id == patient_id,
        )
    )
    if exists:
        raise Conflict(
            "This caregiver is already linked to the patient.", code="ALREADY_LINKED"
        )

    link = CaregiverPatientLink(
        caregiver_id=caregiver.id,
        patient_id=patient_id,
        relationship=data.relationship.strip(),
        is_primary=False,
        permission=data.permission,
    )
    db.add(link)
    db.commit()
    db.refresh(link)
    return CaregiverLinkOut(
        id=link.id,
        caregiver_id=caregiver.id,
        full_name=caregiver.full_name,
        email=caregiver.email,
        relationship=link.relationship,
        permission=link.permission,
        is_primary=link.is_primary,
    )
