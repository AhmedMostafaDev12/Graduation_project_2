import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ConsentRecord
from app.oauth2 import Principal, get_principal, load_for_patient, require_editor
from app.schemas.accounts import ConsentOut
from app.services import patient_service

router = APIRouter(prefix="/consents", tags=["Patients"])


@router.post("/{consent_id}/revoke", response_model=ConsentOut)
def revoke_consent(
    consent_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    """C18. Revoking face enrollment also archives that person."""
    consent, access = load_for_patient(
        db, principal, ConsentRecord, consent_id, "Consent", "CONSENT_NOT_FOUND"
    )
    require_editor(access)
    return patient_service.revoke_consent(db, consent)
