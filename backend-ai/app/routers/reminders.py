import uuid

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.oauth2 import (
    PatientAccess,
    require_editor,
    require_patient_link,
    require_patient_manager,
)
from app.schemas.common import BatchResult
from app.schemas.reminders import (
    ReminderCreate,
    ReminderLogBatch,
    ReminderOut,
    ReminderUpdate,
)
from app.services import reminder_service

router = APIRouter(prefix="/patients/{patient_id}", tags=["Reminders"])


@router.get("/reminders", response_model=list[ReminderOut])
def list_reminders(
    db: Session = Depends(get_db), access: PatientAccess = Depends(require_patient_link)
):
    return reminder_service.list_reminders(db, access.patient_id)


@router.post(
    "/reminders", status_code=status.HTTP_201_CREATED, response_model=ReminderOut
)
def create_reminder(
    data: ReminderCreate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    return reminder_service.create_reminder(
        db, access.patient_id, access.principal.user, data
    )


@router.get("/reminders/{reminder_id}", response_model=ReminderOut)
def get_reminder(
    reminder_id: uuid.UUID,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return reminder_service.get_reminder(db, access.patient_id, reminder_id)


@router.patch("/reminders/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: uuid.UUID,
    data: ReminderUpdate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    return reminder_service.update_reminder(db, access.patient_id, reminder_id, data)


@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reminder(
    reminder_id: uuid.UUID,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    reminder_service.delete_reminder(db, access.patient_id, reminder_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/reminder-logs:batch", response_model=BatchResult)
def upload_reminder_logs(
    data: ReminderLogBatch,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    """The patient's phone reports occurrences; a managing caregiver may also mark one done."""
    require_editor(access, allow_device=True)
    return reminder_service.upsert_logs(db, access.patient_id, data.logs)
