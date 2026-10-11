"""Seed the database with the UI board's sample data (docs/UI_SCREENS_BRIEF.md §6).

Run from backend-ai/:
    python -m scripts.seed            # local database (ENVIRONMENT=local)
    python -m scripts.seed --reset    # local only: wipe all data, then seed again (moves "today")

IDs are fixed and readable (docs/SEED_DATA.md), so Flutter mocks and the real API share them.
Inserts use ON CONFLICT DO NOTHING: running the seed twice changes nothing.
Times are built around *today* in Africa/Cairo, so the Today screens have data.

Safety: outside ENVIRONMENT=local the script refuses to run unless --allow-remote is given,
SEED_PASSWORD and SEED_DEVICE_TOKEN must be set (no known default passwords in production),
and --reset is never allowed.
"""

import argparse
import hashlib
import math
import os
import random
import sys
import uuid
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import text, update
from sqlalchemy.dialects.postgresql import insert

from app import models as m
from app.config import settings
from app.database import SessionLocal
from app.utils import hash_password

CAIRO = ZoneInfo("Africa/Cairo")


def sid(kind: int, n: int) -> uuid.UUID:
    """Readable fixed IDs: kind in the first block, number in the last."""
    return uuid.UUID(f"{kind:08d}-0000-4000-8000-{n:012d}")


# ----- fixed IDs (keep in sync with docs/SEED_DATA.md) -----
FATMA, AHMED_CG, MONA_CG = sid(1, 1), sid(1, 2), sid(1, 3)
P_AHMED, P_SARA, P_HANY, P_MONA = sid(2, 1), sid(2, 2), sid(2, 3), sid(2, 4)
DEVICE = sid(3, 1)
HOME, AHMED_HOUSE, CLINIC = sid(4, 1), sid(4, 2), sid(4, 3)
R_PILL, R_DOCTOR, R_WATER = sid(5, 1), sid(5, 2), sid(5, 3)
LOG_PILL_TODAY, LOG_WATER_NOON, LOG_WATER_4PM, LOG_PILL_YESTERDAY = (
    sid(6, 1),
    sid(6, 2),
    sid(6, 3),
    sid(6, 4),
)
ENC_AHMED = sid(10, 1)
CLUSTER = sid(11, 1)


def at(day: date, hour: int, minute: int = 0, second: int = 0) -> datetime:
    """A wall-clock time in Cairo on `day`, as an aware datetime."""
    return datetime.combine(day, time(hour, minute, second), tzinfo=CAIRO)


def unit_vector(dim: int, seed: int) -> list[float]:
    rng = random.Random(seed)
    v = [rng.gauss(0, 1) for _ in range(dim)]
    norm = math.sqrt(sum(x * x for x in v))
    return [x / norm for x in v]


def upsert(db, model, rows: list[dict], key: str = "id") -> None:
    # One row per statement: rows leave out different optional columns,
    # so the database fills in each row's own defaults.
    for row in rows:
        db.execute(
            insert(model).values(row).on_conflict_do_nothing(index_elements=[key])
        )


def seed(db, password: str, device_token: str) -> None:
    today = datetime.now(CAIRO).date()
    yesterday = today - timedelta(days=1)
    now = datetime.now(UTC)

    # ----- accounts -----
    pw = hash_password(password)
    upsert(
        db,
        m.User,
        [
            {
                "id": FATMA,
                "role": "patient",
                "full_name": "فاطمة محمود (Fatma Mahmoud)",
            },
            {
                "id": AHMED_CG,
                "role": "caregiver",
                "full_name": "Ahmed Mostafa",
                "email": "ahmed@example.com",
                "phone": "+201000000001",
                "password_hash": pw,
            },
            {
                "id": MONA_CG,
                "role": "caregiver",
                "full_name": "Mona Ali",
                "email": "mona@example.com",
                "phone": "+201000000002",
                "password_hash": pw,
            },
        ],
    )
    upsert(
        db,
        m.PatientProfile,
        [
            {
                "user_id": FATMA,
                "preferred_language": "ar",
                "timezone": "Africa/Cairo",
                "date_of_birth": date(1954, 3, 12),
            }
        ],
        key="user_id",
    )
    upsert(
        db,
        m.CaregiverPatientLink,
        [
            {
                "id": sid(16, 1),
                "caregiver_id": AHMED_CG,
                "patient_id": FATMA,
                "relationship": "son",
                "is_primary": True,
                "permission": "manager",
            },
            {
                "id": sid(16, 2),
                "caregiver_id": MONA_CG,
                "patient_id": FATMA,
                "relationship": "nurse",
                "is_primary": False,
                "permission": "viewer",
            },
        ],
    )
    upsert(
        db,
        m.Device,
        [
            {
                "id": DEVICE,
                "patient_id": FATMA,
                "serial_number": "RMR-0007",
                "token_hash": hashlib.sha256(device_token.encode()).hexdigest(),
                "firmware_version": "0.3.1",
                "battery_level_pct": 76,
                "last_seen_at": now - timedelta(minutes=5),
                "paired_at": at(today - timedelta(days=10), 18),
            }
        ],
    )

    # ----- people + consent (they reference each other: people first, then consents, then link) -----
    people = [
        (P_AHMED, "Ahmed", "son"),
        (P_SARA, "Sara", "daughter"),
        (P_HANY, "Dr. Hany", "doctor"),
        (P_MONA, "Mona", "nurse"),
    ]
    upsert(
        db,
        m.EnrolledPerson,
        [
            {
                "id": pid,
                "patient_id": FATMA,
                "name": name,
                "relationship": rel,
                "added_by": "caregiver_manual",
            }
            for pid, name, rel in people
        ],
    )
    enrolled_on = at(today - timedelta(days=10), 18, 30)
    consents = [
        {
            "id": sid(12, 1),
            "patient_id": FATMA,
            "consent_type": "ambient_audio_household",
            "given_by": AHMED_CG,
            "given_at": enrolled_on,
        },
        {
            "id": sid(12, 2),
            "patient_id": FATMA,
            "consent_type": "cloud_processing",
            "given_by": AHMED_CG,
            "given_at": enrolled_on,
        },
    ] + [
        {
            "id": sid(12, 10 + i),
            "patient_id": FATMA,
            "subject_person_id": pid,
            "consent_type": "face_enrollment",
            "given_by": AHMED_CG,
            "given_at": enrolled_on,
        }
        for i, (pid, _, _) in enumerate(people, start=1)
    ]
    upsert(db, m.ConsentRecord, consents)
    for i, (pid, _, _) in enumerate(people, start=1):
        db.execute(
            update(m.EnrolledPerson)
            .where(
                m.EnrolledPerson.id == pid, m.EnrolledPerson.consent_record_id.is_(None)
            )
            .values(consent_record_id=sid(12, 10 + i))
        )

    # ----- places -----
    upsert(
        db,
        m.Place,
        [
            {
                "id": HOME,
                "patient_id": FATMA,
                "name": "Home · البيت",
                "latitude": 31.0409,
                "longitude": 31.3785,
                "radius_m": 100,
                "created_by": AHMED_CG,
            },
            {
                "id": AHMED_HOUSE,
                "patient_id": FATMA,
                "name": "بيت أحمد · Ahmed's house",
                "latitude": 31.0450,
                "longitude": 31.3830,
                "radius_m": 150,
                "created_by": AHMED_CG,
            },
            {
                "id": CLINIC,
                "patient_id": FATMA,
                "name": "Clinic",
                "latitude": 31.0370,
                "longitude": 31.3810,
                "radius_m": 80,
                "created_by": AHMED_CG,
            },
        ],
    )

    # ----- reminders + logs -----
    start = at(today - timedelta(days=14), 0)
    upsert(
        db,
        m.Reminder,
        [
            {
                "id": R_PILL,
                "patient_id": FATMA,
                "title": "Blood pressure pill",
                "spoken_text": "ميعاد دواء الضغط",
                "type": "medication",
                "rrule": "FREQ=DAILY;BYHOUR=9;BYMINUTE=0",
                "dtstart": start,
                "created_by": AHMED_CG,
            },
            {
                "id": R_DOCTOR,
                "patient_id": FATMA,
                "title": "Doctor appointment",
                "spoken_text": "ميعاد الدكتور",
                "type": "appointment",
                "rrule": "FREQ=WEEKLY;BYDAY=FR;BYHOUR=17;BYMINUTE=0",
                "dtstart": start,
                "created_by": AHMED_CG,
            },
            {
                "id": R_WATER,
                "patient_id": FATMA,
                "title": "Drink water",
                "spoken_text": "اشرب مية",
                "type": "task",
                "rrule": "FREQ=DAILY;BYHOUR=12,16;BYMINUTE=0",
                "dtstart": start,
                "created_by": AHMED_CG,
            },
        ],
    )
    upsert(
        db,
        m.ReminderLog,
        [
            {
                "id": LOG_PILL_TODAY,
                "reminder_id": R_PILL,
                "scheduled_at": at(today, 9),
                "status": "completed",
                "completed_at": at(today, 9, 2),
                "confirmed_via": "voice",
            },
            {
                "id": LOG_WATER_NOON,
                "reminder_id": R_WATER,
                "scheduled_at": at(today, 12),
                "status": "snoozed",
                "snoozed_until": at(today, 12, 15),
            },
            {
                "id": LOG_WATER_4PM,
                "reminder_id": R_WATER,
                "scheduled_at": at(today, 16),
                "status": "pending",
            },
            {
                "id": LOG_PILL_YESTERDAY,
                "reminder_id": R_PILL,
                "scheduled_at": at(yesterday, 9),
                "status": "missed",
            },
        ],
    )

    # ----- mind games (yesterday) -----
    games = [
        ("card_match", 8, 120),
        ("picture_naming", 6, 150),
        ("word_recall", 5, 180),
    ]
    upsert(
        db,
        m.MindGameSession,
        [
            {
                "id": sid(15, i),
                "patient_id": FATMA,
                "game_type": g,
                "score": s,
                "duration_seconds": d,
                "completed_at": at(yesterday, 17, 10 * i),
            }
            for i, (g, s, d) in enumerate(games, start=1)
        ],
    )

    # ----- unknown face cluster + Ahmed's encounter -----
    upsert(
        db,
        m.UnknownFaceCluster,
        [
            {
                "id": CLUSTER,
                "patient_id": FATMA,
                "centroid": unit_vector(m.FACE_DIM, seed=11),
                "sighting_count": 5,
                "distinct_days": 3,
                "first_seen_at": at(today - timedelta(days=5), 16),
                "last_seen_at": at(today, 11, 2),
                "status": "awaiting_caregiver",
            }
        ],
    )
    upsert(
        db,
        m.Encounter,
        [
            {
                "id": ENC_AHMED,
                "patient_id": FATMA,
                "device_id": DEVICE,
                "person_id": P_AHMED,
                "started_at": at(today, 9, 15),
                "ended_at": at(today, 9, 40),
                "best_confidence": 0.94,
                "announced": True,
            }
        ],
    )

    # ----- the journal: one day (UI board C12 / P4) -----
    E = {
        name: sid(7, i)
        for i, name in enumerate(
            [
                "pill",
                "encounter",
                "talk",
                "question",
                "recording",
                "receipt",
                "moment",
                "paused",
                "label",
                "games",
            ],
            start=1,
        )
    }
    events = [
        {
            "id": E["pill"],
            "source": "app",
            "event_type": "reminder",
            "reminder_log_id": LOG_PILL_TODAY,
            "occurred_at": at(today, 9, 2),
            "rendered_text": "09:02 took the blood pressure pill (confirmed by voice)",
        },
        {
            "id": E["encounter"],
            "source": "glasses",
            "event_type": "encounter",
            "encounter_id": ENC_AHMED,
            "person_id": P_AHMED,
            "device_id": DEVICE,
            "occurred_at": at(today, 9, 15),
            "ended_at": at(today, 9, 40),
            "rendered_text": "09:15-09:40 met Ahmed (son)",
        },
        {
            "id": E["talk"],
            "source": "glasses",
            "event_type": "conversation_segment",
            "device_id": DEVICE,
            "occurred_at": at(today, 9, 20),
            "ended_at": at(today, 9, 24),
            "transcript_text": "أحمد: ماما، ميعاد الدكتور بكره الساعة خمسة، هاجي آخدك.",
            "language": "ar",
            "metadata_": {"present_person_ids": [str(P_AHMED)]},
            "rendered_text": "09:20 talked with Ahmed (son) about tomorrow's doctor appointment at 5",
        },
        {
            "id": E["question"],
            "source": "glasses",
            "event_type": "voice_query",
            "device_id": DEVICE,
            "occurred_at": at(today, 10, 2),
            "transcript_text": "مين ده؟",
            "language": "ar",
            "metadata_": {
                "intent": "who_is_this",
                "answered_locally": True,
                "answer": "ده أحمد، ابنك",
            },
            "rendered_text": "10:02 asked 'who is this?' and was told it was Ahmed (son)",
        },
        {
            "id": E["recording"],
            "source": "glasses",
            "event_type": "user_requested_recording",
            "device_id": DEVICE,
            "occurred_at": at(today, 11, 30),
            "ended_at": at(today, 11, 30, 12),
            "rendered_text": "11:30 recorded a 12-second video",
        },
        {
            "id": E["receipt"],
            "source": "glasses",
            "event_type": "document_captured",
            "device_id": DEVICE,
            "occurred_at": at(today, 11, 45),
            "rendered_text": "11:45 pharmacy receipt, 120 EGP",
        },
        {
            "id": E["moment"],
            "source": "glasses",
            "event_type": "notable_moment_captured",
            "device_id": DEVICE,
            "occurred_at": at(today, 11, 50),
            "rendered_text": "11:50 a moment in the garden",
        },
        {
            "id": E["paused"],
            "source": "glasses",
            "event_type": "memory_paused",
            "device_id": DEVICE,
            "occurred_at": at(today, 12, 5),
            "rendered_text": "12:05 memory paused",
        },
        {
            "id": E["label"],
            "source": "glasses",
            "event_type": "document_captured",
            "device_id": DEVICE,
            "occurred_at": at(today - timedelta(days=3), 19, 10),
            "rendered_text": "medication label: Concor 5 mg",
        },
        {
            "id": E["games"],
            "source": "app",
            "event_type": "mind_game_session",
            "mind_game_session_id": sid(15, 1),
            "occurred_at": at(yesterday, 17, 10),
            "rendered_text": "played card match, score 8",
        },
    ]
    upsert(db, m.Event, [{"patient_id": FATMA, **e} for e in events])

    # ----- media + documents (storage keys are placeholders; no S3 objects yet) -----
    media = [
        (
            sid(8, 1),
            E["encounter"],
            "image",
            "encounter_keyframe",
            True,
            {"tags": ["family", "living room"]},
            "auto_expire",
            now + timedelta(days=23),
            None,
        ),
        (
            sid(8, 2),
            E["recording"],
            "video",
            "user_requested",
            False,
            None,
            "keep_indefinitely",
            None,
            12,
        ),
        (
            sid(8, 3),
            E["receipt"],
            "image",
            "document_signal",
            False,
            {"category": "document"},
            "keep_indefinitely",
            None,
            None,
        ),
        (
            sid(8, 4),
            E["moment"],
            "image",
            "salient_frame",
            False,
            {"category": "notable_moment", "tags": ["garden"]},
            "keep_indefinitely",
            None,
            None,
        ),
        (
            sid(8, 5),
            E["label"],
            "image",
            "document_signal",
            False,
            {"category": "document"},
            "keep_indefinitely",
            None,
            None,
        ),
    ]
    upsert(
        db,
        m.MediaAsset,
        [
            {
                "id": mid,
                "patient_id": FATMA,
                "event_id": eid,
                "asset_type": kind,
                "storage_key": f"seed/{mid}.{'mp4' if kind == 'video' else 'jpg'}",
                "trigger": trig,
                "status": "confirmed",
                "ai_tags": tags,
                "contains_other_people": others,
                "duration_seconds": dur,
                "retention_policy": keep,
                "expires_at": expires,
                "reviewed_at": now,
            }
            for mid, eid, kind, trig, others, tags, keep, expires, dur in media
        ],
    )
    upsert(
        db,
        m.CapturedDocument,
        [
            {
                "id": sid(9, 1),
                "event_id": E["receipt"],
                "media_asset_id": sid(8, 3),
                "document_type": "receipt",
                "ocr_text": "صيدلية\nConcor 5 mg x1\nالإجمالي 120 ج.م",
                "extracted_fields": {
                    "amount": "120 EGP",
                    "date": today.isoformat(),
                    "items": ["Concor 5 mg x1"],
                },
            },
            {
                "id": sid(9, 2),
                "event_id": E["label"],
                "media_asset_id": sid(8, 5),
                "document_type": "medication_label",
                "ocr_text": "Concor 5 mg\nBisoprolol fumarate",
                "extracted_fields": {"medication_name": "Concor", "dosage": "5 mg"},
            },
        ],
    )

    # ----- daily summary (yesterday) + caregiver alerts -----
    upsert(
        db,
        m.DailySummary,
        [
            {
                "id": sid(14, 1),
                "patient_id": FATMA,
                "summary_date": yesterday,
                "summary_text": (
                    "A calm day. Ahmed visited in the morning and they talked about the doctor "
                    "appointment. The blood pressure pill was missed at 09:00."
                ),
                "patterns": {
                    "medication_adherence_pct": 92,
                    "visit_count": 3,
                    "talk_minutes": 140,
                    "routine_change": "Afternoon walk later than usual",
                },
                "generated_at": at(yesterday, 23, 30),
            }
        ],
    )
    alerts = [
        (
            "unknown_person_flagged",
            "A new face has visited on 3 different days.",
            at(today, 11, 2),
            None,
        ),
        ("low_battery", "Glasses battery at 18%.", at(today, 8, 40), None),
        (
            "missed_medication",
            "Blood pressure pill (09:00) was not confirmed.",
            at(yesterday, 10),
            at(yesterday, 10, 30),
        ),
        (
            "device_offline",
            "No contact from the patient's phone for 2 hours.",
            at(yesterday, 15, 20),
            at(yesterday, 16),
        ),
        (
            "daily_summary_ready",
            "Yesterday's summary is ready to read.",
            at(yesterday, 23, 30),
            None,
        ),
    ]
    upsert(
        db,
        m.CaregiverAlert,
        [
            {
                "id": sid(13, i),
                "caregiver_id": AHMED_CG,
                "patient_id": FATMA,
                "alert_type": kind,
                "message": msg,
                "created_at": created,
                "read_at": read,
            }
            for i, (kind, msg, created, read) in enumerate(alerts, start=1)
        ],
    )


def reset(db) -> None:
    tables = ", ".join(t.name for t in m.Base.metadata.sorted_tables)
    db.execute(text(f"TRUNCATE {tables} CASCADE"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed the Remori database with sample data."
    )
    parser.add_argument(
        "--reset", action="store_true", help="local only: wipe data first"
    )
    parser.add_argument(
        "--allow-remote", action="store_true", help="required outside local"
    )
    args = parser.parse_args()

    local = settings.environment == "local"
    if not local and not args.allow_remote:
        print(
            "Refusing to seed a non-local database without --allow-remote.",
            file=sys.stderr,
        )
        return 1
    if args.reset and not local:
        print("--reset is only allowed on a local database.", file=sys.stderr)
        return 1

    password = os.environ.get("SEED_PASSWORD") or ("remori-local" if local else None)
    device_token = os.environ.get("SEED_DEVICE_TOKEN") or (
        "local-device-token-RMR-0007" if local else None
    )
    if not password or not device_token:
        print(
            "Set SEED_PASSWORD and SEED_DEVICE_TOKEN for a non-local seed.",
            file=sys.stderr,
        )
        return 1

    with SessionLocal() as db:
        if args.reset:
            reset(db)
        seed(db, password, device_token)
        db.commit()
    print(f"Seeded ({settings.environment}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
