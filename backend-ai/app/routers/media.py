import uuid
from typing import Literal

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MediaAsset
from app.oauth2 import (
    PatientAccess,
    Principal,
    check_patient_access,
    get_principal,
    load_for_patient,
    require_editor,
    require_patient_link,
)
from app.schemas.media import (
    DocumentOut,
    MediaOut,
    MediaView,
    UploadComplete,
    UploadDone,
    UploadOut,
    UploadRequest,
)
from app.services import document_service, media_service

router = APIRouter(tags=["Media"])


@router.post(
    "/patients/{patient_id}/uploads",
    status_code=status.HTTP_201_CREATED,
    response_model=UploadOut,
)
def request_upload(
    data: UploadRequest, access: PatientAccess = Depends(require_patient_link)
):
    require_editor(access, allow_device=True)
    return media_service.request_upload(access, data)


@router.post("/uploads/{upload_id}/complete", response_model=UploadDone)
def complete_upload(
    upload_id: uuid.UUID,
    data: UploadComplete,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    access = require_editor(
        check_patient_access(db, principal, data.patient_id), allow_device=True
    )
    return media_service.complete_upload(db, access, upload_id, data)


@router.get("/patients/{patient_id}/media/{media_id}", response_model=MediaView)
def view_media(
    media_id: uuid.UUID,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    """A signed URL valid for 10 minutes. Every view is written to the audit log."""
    return media_service.view(db, access, media_id)


@router.post("/media/{media_id}/pin", response_model=MediaOut)
def pin_media(
    media_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    media, access = load_for_patient(
        db, principal, MediaAsset, media_id, "Media", "MEDIA_NOT_FOUND"
    )
    require_editor(access)
    return media_service.pin(db, media, principal.user)


@router.delete("/media/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_media(
    media_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    media, access = load_for_patient(
        db, principal, MediaAsset, media_id, "Media", "MEDIA_NOT_FOUND"
    )
    require_editor(access, allow_device=True)
    media_service.delete(db, access, media)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/patients/{patient_id}/documents", response_model=list[DocumentOut])
def list_documents(
    document_type: Literal["receipt", "bill", "medication_label", "other"]
    | None = Query(default=None, alias="type"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return document_service.list_documents(db, access, document_type, limit, offset)


@router.get("/documents/{document_id}", response_model=DocumentOut)
def get_document(
    document_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    """C15, also when opened from a link. The photo URL is audit-logged."""
    return document_service.get_document(db, principal, document_id)
