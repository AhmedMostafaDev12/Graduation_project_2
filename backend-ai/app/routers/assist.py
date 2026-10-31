from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.ai.rag import answer
from app.database import get_db
from app.oauth2 import PatientAccess, require_patient_link
from app.schemas.activity import AssistOut, AssistRequest

router = APIRouter(prefix="/patients/{patient_id}", tags=["Assist"])


@router.post("/assist", response_model=AssistOut)
def assist(
    data: AssistRequest,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    """Free-form question about the patient's memories (spec D39, phase 9.1): the /assist
    agent searches them and answers in the question's language, with the events it used."""
    return answer.answer(db, access.patient_id, data.question)
