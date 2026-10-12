import uuid

from fastapi import APIRouter, Depends, File, Form, Response, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.errors import InvalidInput
from app.models import EnrolledPerson, UnknownFaceCluster, User
from app.oauth2 import (
    PatientAccess,
    Principal,
    get_current_user,
    get_principal,
    load_for_patient,
    require_editor,
    require_patient_link,
    require_patient_manager,
)
from app.schemas.people import (
    PersonDetail,
    PersonOut,
    PersonUpdate,
    PromoteOut,
    PromoteRequest,
    UnknownFaceOut,
)
from app.services import people_service

router = APIRouter(tags=["People"])


def _person(db: Session, principal: Principal, person_id: uuid.UUID, write: bool):
    person, access = load_for_patient(
        db, principal, EnrolledPerson, person_id, "Person", "PERSON_NOT_FOUND"
    )
    if write:
        require_editor(access)
    return person


def _cluster(db: Session, principal: Principal, cluster_id: uuid.UUID):
    cluster, access = load_for_patient(
        db,
        principal,
        UnknownFaceCluster,
        cluster_id,
        "Unknown face",
        "UNKNOWN_FACE_NOT_FOUND",
    )
    require_editor(access)
    return cluster


@router.get("/patients/{patient_id}/people", response_model=list[PersonOut])
def list_people(
    db: Session = Depends(get_db), access: PatientAccess = Depends(require_patient_link)
):
    return people_service.list_people(db, access.patient_id)


@router.post(
    "/patients/{patient_id}/people",
    status_code=status.HTTP_201_CREATED,
    response_model=PersonOut,
)
def enroll_person(
    name: str = Form(min_length=1, max_length=80),
    relationship: str = Form(min_length=1, max_length=40),
    consent_given: bool = Form(description="The person agreed to face recognition"),
    photos: list[UploadFile] = File(
        description="1 to 5 JPEG/PNG face photos, 4 MB each"
    ),
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_manager),
):
    if not consent_given:
        raise InvalidInput(
            "Face enrollment needs the person's consent.", code="CONSENT_REQUIRED"
        )
    return people_service.enroll(
        db, access.patient_id, access.principal.user, name, relationship, photos
    )


@router.get("/people/{person_id}", response_model=PersonDetail)
def get_person(
    person_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    return people_service.detail(db, _person(db, principal, person_id, write=False))


@router.post("/people/{person_id}/photos", response_model=PersonOut)
def add_photos(
    person_id: uuid.UUID,
    photos: list[UploadFile] = File(
        description="1 to 5 JPEG/PNG face photos, 4 MB each"
    ),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    return people_service.add_photos(
        db, _person(db, principal, person_id, write=True), photos
    )


@router.delete("/people/{person_id}/photos/{photo_id}", response_model=PersonOut)
def remove_photo(
    person_id: uuid.UUID,
    photo_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    return people_service.remove_photo(
        db, _person(db, principal, person_id, write=True), photo_id
    )


@router.patch("/people/{person_id}", response_model=PersonOut)
def update_person(
    person_id: uuid.UUID,
    data: PersonUpdate,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    return people_service.update_person(
        db, _person(db, principal, person_id, write=True), data
    )


@router.delete("/people/{person_id}", status_code=status.HTTP_204_NO_CONTENT)
def archive_person(
    person_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    people_service.archive(db, _person(db, principal, person_id, write=True))
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/patients/{patient_id}/unknown-faces", response_model=list[UnknownFaceOut])
def list_unknown_faces(
    db: Session = Depends(get_db),
    access: PatientAccess = Depends(require_patient_link),
    _caregiver: User = Depends(get_current_user),
):
    return people_service.list_unknown(db, access.patient_id)


@router.post("/unknown-faces/{cluster_id}/promote", response_model=PromoteOut)
def promote_unknown_face(
    cluster_id: uuid.UUID,
    data: PromoteRequest,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    cluster, person = people_service.promote(
        db, _cluster(db, principal, cluster_id), principal.user, data
    )
    return PromoteOut(cluster=cluster, person=person)


@router.post("/unknown-faces/{cluster_id}/dismiss", response_model=UnknownFaceOut)
def dismiss_unknown_face(
    cluster_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    return people_service.dismiss(db, _cluster(db, principal, cluster_id))
