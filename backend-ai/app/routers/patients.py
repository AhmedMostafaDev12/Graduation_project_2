from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.oauth2 import (
    PatientAccess,
    get_current_user,
    require_patient_link,
    require_patient_manager,
)
from app.schemas.accounts import (
    CaregiverLinkCreate,
    CaregiverLinkOut,
    ConsentOut,
    DeviceOut,
    MyPatientOut,
    PatientCreate,
    PatientOut,
    PatientUpdate,
)
from app.services import device_service, patient_service

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.get("", response_model=list[MyPatientOut])
def list_my_patients(
    db: Session = Depends(get_db), caregiver: User = Depends(get_current_user)
):
    """The patients you are linked to, primary ones first (screen C1)."""
    return patient_service.list_my_patients(db, caregiver)


@router.post("", status_code=status.HTTP_201_CREATED, response_model=PatientOut)
def create_patient(
    data: PatientCreate,
    db: Session = Depends(get_db),
    caregiver: User = Depends(get_current_user),
):
    return patient_service.create_patient(db, caregiver, data)


@router.post(
    "/{patient_id}/caregivers",
    status_code=status.HTTP_201_CREATED,
    response_model=CaregiverLinkOut,
)
def link_caregiver(
    data: CaregiverLinkCreate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    return patient_service.link_caregiver(db, access.patient_id, data)


@router.patch("/{patient_id}", response_model=PatientOut)
def update_patient(
    data: PatientUpdate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    """Profile (C18) and the memory capture switch (C16)."""
    return patient_service.update_patient(db, access.patient_id, data)


@router.get("/{patient_id}/caregivers", response_model=list[CaregiverLinkOut])
def list_caregivers(
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
    _caregiver: User = Depends(get_current_user),
):
    return patient_service.list_caregivers(db, access.patient_id)


@router.get("/{patient_id}/devices", response_model=list[DeviceOut])
def list_devices(
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return device_service.list_devices(db, access.patient_id)


@router.get("/{patient_id}/consents", response_model=list[ConsentOut])
def list_consents(
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
    _caregiver: User = Depends(get_current_user),
):
    return patient_service.list_consents(db, access.patient_id)
