"""Enrolled people (screens C4-C6) and unknown faces (C7), spec D2/D14.

Enrollment photos live in S3 under patients/{patient}/people/{person}/; their embeddings
in face_embeddings. The glasses get both name and embeddings through /sync.
"""

import uuid
from datetime import UTC, datetime

from fastapi import UploadFile
from sqlalchemy import delete, func, select, update
from sqlalchemy.orm import Session

from app.ai.inference import face
from app.errors import Conflict, InvalidInput, NotFound
from app.integrations import s3
from app.models import (
    ConsentRecord,
    Encounter,
    EnrolledPerson,
    FaceEmbedding,
    MediaAsset,
    UnknownFaceCluster,
    User,
)
from app.schemas.people import (
    PersonDetail,
    PersonOut,
    PersonPhoto,
    PersonUpdate,
    PromoteRequest,
    UnknownFaceOut,
)

MAX_PHOTOS_PER_REQUEST = 5
MAX_EMBEDDINGS_PER_PERSON = 20
MAX_PHOTO_BYTES = 4 * 1024 * 1024


def _photo_prefix(person: EnrolledPerson) -> str:
    return f"patients/{person.patient_id}/people/{person.id}/"


def _embedding_count(db: Session, person_id: uuid.UUID) -> int:
    return db.scalar(
        select(func.count())
        .select_from(FaceEmbedding)
        .where(FaceEmbedding.person_id == person_id)
    )


def person_out(db: Session, person: EnrolledPerson) -> PersonOut:
    out = PersonOut.model_validate(person)
    out.embedding_count = _embedding_count(db, person.id)
    return out


def _read_photos(photos: list[UploadFile]) -> list[tuple[bytes, str]]:
    """Validate before touching S3 or the database: 1-5 JPEG/PNG files, 4 MB each."""
    if not 1 <= len(photos) <= MAX_PHOTOS_PER_REQUEST:
        raise InvalidInput(
            f"Send 1 to {MAX_PHOTOS_PER_REQUEST} photos.", code="PHOTO_COUNT"
        )
    result = []
    for photo in photos:
        data = photo.file.read(MAX_PHOTO_BYTES + 1)
        if len(data) > MAX_PHOTO_BYTES:
            raise InvalidInput(
                "Each photo must be 4 MB or smaller.", code="PHOTO_TOO_LARGE"
            )
        if not face.looks_like_image(data):
            raise InvalidInput("Photos must be JPEG or PNG.", code="UNSUPPORTED_PHOTO")
        ext = "png" if data.startswith(face.PNG_MAGIC) else "jpg"
        result.append((data, ext))
    return result


def _store_photos(
    db: Session, person: EnrolledPerson, photos: list[tuple[bytes, str]]
) -> None:
    for data, ext in photos:
        key = f"{_photo_prefix(person)}{uuid.uuid4()}.{ext}"
        s3.put_bytes(key, data, "image/png" if ext == "png" else "image/jpeg")
        db.add(
            FaceEmbedding(
                person_id=person.id,
                embedding=face.embed_face(data),
                model_version=face.MODEL_VERSION,
                storage_key=key,
            )
        )


def _new_person(
    db: Session,
    patient_id: uuid.UUID,
    caregiver: User,
    name: str,
    relationship: str,
    added_by: str,
) -> EnrolledPerson:
    """Person + its face-enrollment consent. The two rows point at each other (spec §6)."""
    person = EnrolledPerson(
        patient_id=patient_id,
        name=name.strip(),
        relationship=relationship.strip(),
        added_by=added_by,
    )
    db.add(person)
    db.flush()
    consent = ConsentRecord(
        patient_id=patient_id,
        subject_person_id=person.id,
        consent_type="face_enrollment",
        given_by=caregiver.id,
        given_at=datetime.now(UTC),
    )
    db.add(consent)
    db.flush()
    person.consent_record_id = consent.id
    return person


def enroll(
    db: Session,
    patient_id: uuid.UUID,
    caregiver: User,
    name: str,
    relationship: str,
    photos: list[UploadFile],
) -> PersonOut:
    files = _read_photos(photos)
    person = _new_person(
        db, patient_id, caregiver, name, relationship, "caregiver_manual"
    )
    _store_photos(db, person, files)
    db.commit()
    db.refresh(person)
    return person_out(db, person)


def add_photos(
    db: Session, person: EnrolledPerson, photos: list[UploadFile]
) -> PersonOut:
    files = _read_photos(photos)
    if _embedding_count(db, person.id) + len(files) > MAX_EMBEDDINGS_PER_PERSON:
        raise Conflict(
            f"A person can have at most {MAX_EMBEDDINGS_PER_PERSON} photos.",
            code="TOO_MANY_PHOTOS",
        )
    _store_photos(db, person, files)
    person.updated_at = func.now()  # so /sync sends the new embeddings to the glasses
    db.commit()
    db.refresh(person)
    return person_out(db, person)


def detail(db: Session, person: EnrolledPerson) -> PersonDetail:
    rows = db.execute(
        select(FaceEmbedding.id, FaceEmbedding.storage_key)
        .where(
            FaceEmbedding.person_id == person.id, FaceEmbedding.storage_key.is_not(None)
        )
        .order_by(FaceEmbedding.created_at)
    )
    photos = [
        PersonPhoto(id=photo_id, url=s3.presign_get(key)) for photo_id, key in rows
    ]
    return PersonDetail(**person_out(db, person).model_dump(), photos=photos)


def remove_photo(db: Session, person: EnrolledPerson, photo_id: uuid.UUID) -> PersonOut:
    """Remove one enrollment photo and the embedding made from it."""
    row = db.get(FaceEmbedding, photo_id)
    if row is None or row.person_id != person.id or row.storage_key is None:
        raise NotFound("Photo not found.", code="PHOTO_NOT_FOUND")
    if _embedding_count(db, person.id) == 1:
        raise Conflict(
            "This is the person's last photo. Add another first, or archive the person.",
            code="LAST_PHOTO",
        )
    s3.delete(row.storage_key)
    db.delete(row)
    person.updated_at = func.now()  # /sync resends the person's remaining embeddings
    db.commit()
    db.refresh(person)
    return person_out(db, person)


def update_person(db: Session, person: EnrolledPerson, data: PersonUpdate) -> PersonOut:
    for field, value in data.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(person, field, value.strip())
    db.commit()
    db.refresh(person)
    return person_out(db, person)


def archive(db: Session, person: EnrolledPerson) -> None:
    """The glasses stop recognising this person. Encounters keep pointing at the row so the
    journal still shows the name, but face data is deleted (spec §7.4 retention)."""
    now = datetime.now(UTC)
    for key in s3.list_keys(_photo_prefix(person)):  # by prefix: also catches orphans
        s3.delete(key)
    db.execute(delete(FaceEmbedding).where(FaceEmbedding.person_id == person.id))
    db.execute(
        update(ConsentRecord)
        .where(
            ConsentRecord.subject_person_id == person.id,
            ConsentRecord.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    person.status = "archived"
    person.deleted_at = now
    db.commit()


# ----- unknown faces -----

AWAITING = ("open", "awaiting_caregiver")


def _cluster_out(db: Session, cluster: UnknownFaceCluster) -> UnknownFaceOut:
    out = UnknownFaceOut.model_validate(cluster)
    if cluster.sample_media_id:
        media = db.get(MediaAsset, cluster.sample_media_id)
        if media is not None and media.deleted_at is None:
            out.sample_url = s3.presign_get(media.storage_key)
    return out


def list_unknown(db: Session, patient_id: uuid.UUID) -> list[UnknownFaceOut]:
    clusters = db.scalars(
        select(UnknownFaceCluster)
        .where(
            UnknownFaceCluster.patient_id == patient_id,
            UnknownFaceCluster.status == "awaiting_caregiver",
        )
        .order_by(UnknownFaceCluster.last_seen_at.desc())
    )
    return [_cluster_out(db, cluster) for cluster in clusters]


def _undecided(cluster: UnknownFaceCluster) -> None:
    if cluster.status not in AWAITING:
        raise Conflict("This face was already decided.", code="ALREADY_DECIDED")


def promote(
    db: Session, cluster: UnknownFaceCluster, caregiver: User, data: PromoteRequest
) -> tuple[UnknownFaceOut, PersonOut]:
    """Turn a recurring unknown face into an enrolled person (spec D2)."""
    _undecided(cluster)
    person = _new_person(
        db,
        cluster.patient_id,
        caregiver,
        data.name,
        data.relationship,
        "promoted_from_unknown",
    )
    db.add(
        FaceEmbedding(
            person_id=person.id,
            embedding=list(cluster.centroid),
            model_version=face.EDGE_MODEL_VERSION,
            source_media_id=cluster.sample_media_id,
        )
    )
    # past sightings now belong to the person, so the journal can name them
    db.execute(
        update(Encounter)
        .where(Encounter.cluster_id == cluster.id)
        .values(person_id=person.id)
    )
    cluster.status = "promoted"
    cluster.promoted_person_id = person.id
    db.commit()
    db.refresh(person)
    return _cluster_out(db, cluster), person_out(db, person)


def dismiss(db: Session, cluster: UnknownFaceCluster) -> UnknownFaceOut:
    _undecided(cluster)
    cluster.status = "dismissed"
    db.commit()
    return _cluster_out(db, cluster)


def list_people(db: Session, patient_id: uuid.UUID) -> list[PersonOut]:
    people = db.scalars(
        select(EnrolledPerson)
        .where(
            EnrolledPerson.patient_id == patient_id, EnrolledPerson.deleted_at.is_(None)
        )
        .order_by(EnrolledPerson.name)
    )
    return [person_out(db, person) for person in people]
