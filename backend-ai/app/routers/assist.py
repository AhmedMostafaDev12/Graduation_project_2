from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.ai.rag import answer
from app.database import get_db
from app.models import PatientProfile
from app.oauth2 import PatientAccess, require_patient_link
from app.schemas.activity import AssistOut, AssistRequest

router = APIRouter(prefix="/patients/{patient_id}", tags=["Assist"])


@router.post("/assist", response_model=AssistOut)
def assist(
    data: AssistRequest,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    """Free-form question about the patient's day. STUB until Phase 9.1: fixed answer."""
    language = (
        data.language or db.get(PatientProfile, access.patient_id).preferred_language
    )
    return answer.answer(db, access.patient_id, data.question, language)
