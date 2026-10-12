import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.oauth2 import (
    PatientAccess,
    get_current_user,
    require_editor,
    require_patient_link,
)
from app.schemas.activity import (
    AlertOut,
    DailySummaryOut,
    MindGameIn,
    MindGameOut,
    PushTokenIn,
)
from app.services import activity_service

router = APIRouter(tags=["Activity"])


@router.post(
    "/patients/{patient_id}/mind-game-sessions",
    status_code=status.HTTP_201_CREATED,
    response_model=MindGameOut,
)
def log_mind_game(
    data: MindGameIn,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    require_editor(access, allow_device=True)
    return activity_service.log_game(db, access, data)


@router.get("/patients/{patient_id}/daily-summary", response_model=DailySummaryOut)
def get_daily_summary(
    day: date | None = Query(
        default=None,
        alias="date",
        description="YYYY-MM-DD; today in the patient's timezone",
    ),
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return activity_service.daily_summary(db, access.patient_id, day)


@router.get("/caregivers/me/alerts", response_model=list[AlertOut])
def list_alerts(
    unread_only: bool = False,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    caregiver: User = Depends(get_current_user),
):
    return activity_service.list_alerts(db, caregiver, unread_only, limit, offset)


@router.post("/alerts/{alert_id}/read", response_model=AlertOut)
def mark_alert_read(
    alert_id: uuid.UUID,
    db: Session = Depends(get_db),
    caregiver: User = Depends(get_current_user),
):
    return activity_service.mark_read(db, caregiver, alert_id)


@router.post("/me/push-token", status_code=status.HTTP_204_NO_CONTENT)
def register_push_token(
    data: PushTokenIn,
    db: Session = Depends(get_db),
    caregiver: User = Depends(get_current_user),
):
    activity_service.register_push_token(db, caregiver, data.fcm_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
