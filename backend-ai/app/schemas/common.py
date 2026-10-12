"""Shapes shared by several domains."""

import uuid

from pydantic import BaseModel, Field


class BatchResult(BaseModel):
    """Same shape for every :batch endpoint (spec §7.2)."""

    accepted: list[uuid.UUID]
    duplicates: list[uuid.UUID] = Field(
        description="Not applied: already stored, or older than what the server has"
    )
    rejected: list[uuid.UUID] = Field(
        default_factory=list, description="Refer to something this patient doesn't have"
    )
