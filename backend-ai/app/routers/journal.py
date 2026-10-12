from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.oauth2 import PatientAccess, require_editor, require_patient_link
from app.schemas.common import BatchResult
from app.schemas.journal import EventsBatch, JournalOut
from app.services import journal_service

router = APIRouter(prefix="/patients/{patient_id}", tags=["Journal"])


@router.post("/events:batch", response_model=BatchResult)
def upload_events(
    data: EventsBatch,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    """The phone forwards what the glasses recorded; a managing caregiver may add notes."""
    require_editor(access, allow_device=True)
    return journal_service.upload_batch(db, access, data)


@router.get("/journal", response_model=JournalOut)
def get_journal(
    day: date | None = Query(
        default=None,
        alias="date",
        description="YYYY-MM-DD; today in the patient's timezone",
    ),
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return journal_service.journal(db, access.patient_id, day)
