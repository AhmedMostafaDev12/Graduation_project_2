"""Enrolled people (screens C4-C6) and unknown faces (C7), spec D2/D14.

Enrollment photos live in S3 under patients/{patient}/people/{person}/; their embeddings
in face_embeddings. The glasses get both name and embeddings through /sync.
"""

import uuid
from datetime import UTC, datetime

from fastapi import UploadFile
from sqlalchemy import delete, func, or_, select, update
from sqlalchemy.orm import Session

from app.ai.inference import face
from app.errors import Conflict, InvalidInput, NotFound
from app.integrations import s3
from app.models import (
    ConsentRecord,
    Encounter,
    EnrolledPerson,
    Event,
    FaceEmbedding,
    MediaAsset,
    UnknownFaceCluster,
    User,
)
from app.oauth2 import PatientAccess
from app.schemas.people import (
    PersonDetail,
    PersonOut,
    PersonPhoto,
    PersonUpdate,
    PromoteRequest,
    SamplePhoto,
    UnknownFaceOut,
)
from app.services import media_service, thumbnail_service

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
    result, problems = [], []
    for index, photo in enumerate(photos):
        data = photo.file.read(MAX_PHOTO_BYTES + 1)
        field = f"body.photos.{index}"  # 0-based, so the app can mark that slot (C4)
        if len(data) > MAX_PHOTO_BYTES:
            problems.append(("PHOTO_TOO_LARGE", field, "Must be 4 MB or smaller."))
        elif not face.looks_like_image(data) or not thumbnail_service.is_decodable(
            data
        ):
            problems.append(
                ("UNSUPPORTED_PHOTO", field, "Must be a JPEG or PNG photo.")
            )
        else:
            ext = "png" if data.startswith(face.PNG_MAGIC) else "jpg"
            result.append((data, ext))
    if problems:
        codes = {code for code, _, _ in problems}
        raise InvalidInput(
            "Some photos can't be used.",
            code=codes.pop() if len(codes) == 1 else "PHOTOS_INVALID",
            details=[{"field": field, "message": msg} for _, field, msg in problems],
        )
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
                thumbnail_key=thumbnail_service.create(key, data),
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
        select(FaceEmbedding.id, FaceEmbedding.storage_key, FaceEmbedding.thumbnail_key)
        .where(
            FaceEmbedding.person_id == person.id, FaceEmbedding.storage_key.is_not(None)
        )
        .order_by(FaceEmbedding.created_at)
    )
    photos = [
        PersonPhoto(
            id=photo_id,
            url=s3.presign_get(key),
            thumbnail_url=s3.presign_get(thumb) if thumb else None,
        )
        for photo_id, key, thumb in rows
    ]
    enrolled_by = None
    if person.consent_record_id:
        enrolled_by = db.scalar(
            select(User.full_name)
            .join(ConsentRecord, ConsentRecord.given_by == User.id)
            .where(ConsentRecord.id == person.consent_record_id)
        )
    return PersonDetail(
        **person_out(db, person).model_dump(),
        photos=photos,
        enrolled_by_name=enrolled_by,
    )


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
    if row.thumbnail_key:
        s3.delete(row.thumbnail_key)
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


MAX_SAMPLES = 3


def _cluster_media(db: Session, clusters: list[UnknownFaceCluster]) -> dict:
    """cluster id -> its photos (sample first, then sighting keyframes, newest first),
    in one query for any number of clusters."""
    if not clusters:
        return {}
    by_cluster = {c.id: [] for c in clusters}
    sample_of = {c.sample_media_id: c.id for c in clusters if c.sample_media_id}
    rows = db.execute(
        select(Encounter.cluster_id, MediaAsset)
        .select_from(MediaAsset)
        .outerjoin(Event, Event.id == MediaAsset.event_id)
        .outerjoin(Encounter, Encounter.id == Event.encounter_id)
        .where(
            MediaAsset.deleted_at.is_(None),
            MediaAsset.asset_type == "image",
            or_(
                Encounter.cluster_id.in_(list(by_cluster)),
                MediaAsset.id.in_(list(sample_of)),
            ),
        )
        .order_by(MediaAsset.created_at.desc())
    )
    for cluster_id, media in rows:
        owner = sample_of.get(media.id, cluster_id)
        photos = by_cluster.get(owner)
        if photos is None or media in photos:
            continue
        if media.id in sample_of:
            photos.insert(0, media)  # the clusterer's chosen sample goes first
        else:
            photos.append(media)
    return by_cluster


def _cluster_out(
    db: Session,
    access: PatientAccess,
    cluster: UnknownFaceCluster,
    media: dict | None = None,
) -> UnknownFaceOut:
    photos = (_cluster_media(db, [cluster]) if media is None else media).get(
        cluster.id, []
    )
    samples = [
        SamplePhoto(
            id=m.id,
            url=s3.presign_get(m.storage_key),
            thumbnail_url=s3.presign_get(m.thumbnail_key) if m.thumbnail_key else None,
        )
        for m in photos[:MAX_SAMPLES]
    ]
    media_service.audit(db, access, "media.view", [sample.id for sample in samples])
    out = UnknownFaceOut.model_validate(cluster)
    out.samples = samples
    if samples:
        out.sample_url = samples[0].url
        out.sample_thumbnail_url = samples[0].thumbnail_url
    return out


def list_unknown(db: Session, access: PatientAccess) -> list[UnknownFaceOut]:
    """C6. Each face comes with up to 3 sample photos (C7); every URL is audit-logged."""
    clusters = list(
        db.scalars(
            select(UnknownFaceCluster)
            .where(
                UnknownFaceCluster.patient_id == access.patient_id,
                UnknownFaceCluster.status == "awaiting_caregiver",
            )
            .order_by(UnknownFaceCluster.last_seen_at.desc())
        )
    )
    media = _cluster_media(db, clusters)
    out = [_cluster_out(db, access, cluster, media) for cluster in clusters]
    db.commit()  # the audit rows
    return out


def _undecided(cluster: UnknownFaceCluster) -> None:
    if cluster.status not in AWAITING:
        raise Conflict("This face was already decided.", code="ALREADY_DECIDED")


def promote(
    db: Session,
    access: PatientAccess,
    cluster: UnknownFaceCluster,
    data: PromoteRequest,
) -> tuple[UnknownFaceOut, PersonOut]:
    """Turn a recurring unknown face into an enrolled person (spec D2)."""
    _undecided(cluster)
    person = _new_person(
        db,
        cluster.patient_id,
        access.principal.user,
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
    out = _cluster_out(db, access, cluster)
    db.commit()
    return out, person_out(db, person)


def dismiss(
    db: Session, access: PatientAccess, cluster: UnknownFaceCluster
) -> UnknownFaceOut:
    """A stranger: their photos are deleted now (spec §8 retention), not after 30 days.
    The sightings stay in the journal, without the photos."""
    _undecided(cluster)
    photos = _cluster_media(db, [cluster])[cluster.id]
    now = datetime.now(UTC)
    for media in photos:
        s3.delete(media.storage_key)
        if media.thumbnail_key:
            s3.delete(media.thumbnail_key)
        media.deleted_at = now
    media_service.audit(db, access, "media.delete", [m.id for m in photos])
    cluster.status = "dismissed"
    db.commit()
    return _cluster_out(db, access, cluster)


def list_people(db: Session, patient_id: uuid.UUID, status: str) -> list[PersonOut]:
    """C3: three queries in total, however many people (no query per person)."""
    query = select(EnrolledPerson).where(EnrolledPerson.patient_id == patient_id)
    if status == "archived":
        query = query.where(EnrolledPerson.status == "archived")
    else:
        query = query.where(EnrolledPerson.deleted_at.is_(None))
    people = list(db.scalars(query.order_by(EnrolledPerson.name)))
    ids = [p.id for p in people]
    if not ids:
        return []

    counts = dict(
        db.execute(
            select(FaceEmbedding.person_id, func.count())
            .where(FaceEmbedding.person_id.in_(ids))
            .group_by(FaceEmbedding.person_id)
        ).all()
    )
    first_photo = dict(
        db.execute(
            # the small preview when there is one, else the photo itself
            select(
                FaceEmbedding.person_id,
                func.coalesce(FaceEmbedding.thumbnail_key, FaceEmbedding.storage_key),
            )
            .where(
                FaceEmbedding.person_id.in_(ids), FaceEmbedding.storage_key.is_not(None)
            )
            .order_by(FaceEmbedding.person_id, FaceEmbedding.created_at)
            .distinct(FaceEmbedding.person_id)
        ).all()
    )
    return [
        PersonOut.model_validate(person).model_copy(
            update={
                "embedding_count": counts.get(person.id, 0),
                "photo_url": s3.presign_get(first_photo[person.id])
                if person.id in first_photo
                else None,
            }
        )
        for person in people
    ]
