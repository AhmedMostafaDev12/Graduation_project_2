"""Saved places for 'Where am I?' (spec D9)."""

import uuid
from datetime import datetime

from sqlalchemy import (
    Double,
    Integer,
    Text,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models._columns import (
    deleted_at,
    fk,
    pk,
    updated_at,
)


class Place(Base):
    __tablename__ = "places"

    id: Mapped[uuid.UUID] = pk()
    patient_id: Mapped[uuid.UUID] = fk("users.id")
    name: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float] = mapped_column(Double)
    longitude: Mapped[float] = mapped_column(Double)
    radius_m: Mapped[int] = mapped_column(Integer, server_default=text("100"))
    created_by: Mapped[uuid.UUID] = fk("users.id")
    updated_at: Mapped[datetime] = updated_at()
    deleted_at: Mapped[datetime | None] = deleted_at()
