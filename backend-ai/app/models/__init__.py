"""Database tables: exactly REMORI_SPEC.md §6, one module per domain.

Conventions (spec §6): UUID primary keys (records made offline keep the client's UUID),
TIMESTAMPTZ in UTC, `updated_at` + `deleted_at` (soft delete) on tables the phone syncs.

Import from here (`from app import models` / `from app.models import User`): importing this
package registers every table on Base.metadata, which Alembic relies on.
"""

from app.database import Base
from app.models._columns import FACE_DIM, TEXT_DIM
from app.models.accounts import (
    CaregiverPatientLink,
    Device,
    PatientProfile,
    PushToken,
    RefreshToken,
    User,
)
from app.models.activity import CaregiverAlert, DailySummary, MindGameSession
from app.models.journal import AudioSegment, Event
from app.models.media import CapturedDocument, MediaAsset
from app.models.people import (
    Encounter,
    EnrolledPerson,
    FaceEmbedding,
    UnknownFaceCluster,
)
from app.models.places import Place
from app.models.privacy import AuditLog, ConsentRecord
from app.models.reminders import Reminder, ReminderLog

__all__ = [
    "FACE_DIM",
    "TEXT_DIM",
    "AudioSegment",
    "AuditLog",
    "Base",
    "CapturedDocument",
    "CaregiverAlert",
    "CaregiverPatientLink",
    "ConsentRecord",
    "DailySummary",
    "Device",
    "Encounter",
    "EnrolledPerson",
    "Event",
    "FaceEmbedding",
    "MediaAsset",
    "MindGameSession",
    "PatientProfile",
    "Place",
    "PushToken",
    "RefreshToken",
    "Reminder",
    "ReminderLog",
    "UnknownFaceCluster",
    "User",
]
