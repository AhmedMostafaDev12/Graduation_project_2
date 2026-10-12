from fastapi import APIRouter, Depends, Query
from pydantic import AwareDatetime
from sqlalchemy.orm import Session

from app.database import get_db
from app.oauth2 import PatientAccess, require_patient_link
from app.schemas.sync import SyncOut
from app.services import sync_service

router = APIRouter(prefix="/patients/{patient_id}", tags=["Sync"])


@router.get("/sync", response_model=SyncOut)
def sync(
    since: AwareDatetime | None = Query(
        default=None,
        description="server_time from the previous pull; omit for everything",
    ),
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return sync_service.sync(db, access.patient_id, since)
