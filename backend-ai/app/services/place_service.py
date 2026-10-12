"""Saved places for "Where am I?" (spec D9). The phone answers the question itself;
the backend only stores the places and sends them down through /sync."""

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import NotFound
from app.models import Place, User
from app.schemas.places import PlaceCreate, PlaceUpdate


def list_places(db: Session, patient_id: uuid.UUID) -> list[Place]:
    return list(
        db.scalars(
            select(Place)
            .where(Place.patient_id == patient_id, Place.deleted_at.is_(None))
            .order_by(Place.name)
        )
    )


def get_place(db: Session, patient_id: uuid.UUID, place_id: uuid.UUID) -> Place:
    place = db.get(Place, place_id)
    if place is None or place.patient_id != patient_id or place.deleted_at is not None:
        raise NotFound("Place not found.", code="PLACE_NOT_FOUND")
    return place


def create_place(
    db: Session, patient_id: uuid.UUID, caregiver: User, data: PlaceCreate
) -> Place:
    place = Place(patient_id=patient_id, created_by=caregiver.id, **data.model_dump())
    db.add(place)
    db.commit()
    db.refresh(place)
    return place


def update_place(
    db: Session, patient_id: uuid.UUID, place_id: uuid.UUID, data: PlaceUpdate
) -> Place:
    place = get_place(db, patient_id, place_id)
    for field, value in data.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(place, field, value)
    db.commit()
    db.refresh(place)
    return place


def delete_place(db: Session, patient_id: uuid.UUID, place_id: uuid.UUID) -> None:
    place = get_place(db, patient_id, place_id)
    # soft delete, so the phone learns about it through /sync
    place.deleted_at = datetime.now(UTC)
    db.commit()
