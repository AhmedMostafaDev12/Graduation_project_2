import uuid

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.oauth2 import PatientAccess, require_patient_link, require_patient_manager
from app.schemas.places import PlaceCreate, PlaceOut, PlaceUpdate
from app.services import place_service

router = APIRouter(prefix="/patients/{patient_id}/places", tags=["Places"])


@router.get("", response_model=list[PlaceOut])
def list_places(
    db: Session = Depends(get_db), access: PatientAccess = Depends(require_patient_link)
):
    return place_service.list_places(db, access.patient_id)


@router.post("", status_code=status.HTTP_201_CREATED, response_model=PlaceOut)
def create_place(
    data: PlaceCreate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    return place_service.create_place(
        db, access.patient_id, access.principal.user, data
    )


@router.get("/{place_id}", response_model=PlaceOut)
def get_place(
    place_id: uuid.UUID,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
):
    return place_service.get_place(db, access.patient_id, place_id)


@router.patch("/{place_id}", response_model=PlaceOut)
def update_place(
    place_id: uuid.UUID,
    data: PlaceUpdate,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    return place_service.update_place(db, access.patient_id, place_id, data)


@router.delete("/{place_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_place(
    place_id: uuid.UUID,
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    place_service.delete_place(db, access.patient_id, place_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
