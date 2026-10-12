"""Mind games, daily summary, alerts, push tokens and the /assist stub (Phase 5)."""

import uuid
from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CaregiverAlert, DailySummary, PushToken
from tests.conftest import API, create_patient, pair_device, register_and_login


def _setup(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    return manager, patient, f"{API}/patients/{patient['id']}"


def test_mind_game_is_logged_once_and_appears_in_the_journal(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    game = {
        "id": str(uuid.uuid4()),
        "game_type": "face_match",
        "score": 8,
        "duration_seconds": 240,
        "completed_at": "2026-10-12T11:00:00+03:00",
    }
    first = client.post(
        f"{base}/mind-game-sessions", json=game, headers=phone["headers"]
    )
    assert first.status_code == 201 and first.json()["score"] == 8
    again = client.post(
        f"{base}/mind-game-sessions", json=game, headers=phone["headers"]
    )
    assert again.status_code == 201

    journal = client.get(
        f"{base}/journal", params={"date": "2026-10-12"}, headers=manager["headers"]
    ).json()
    assert [e["event_type"] for e in journal["entries"]] == ["mind_game_session"]


def test_daily_summary_404_until_generated(client, migrated_engine):
    manager, patient, base = _setup(client)
    missing = client.get(
        f"{base}/daily-summary",
        params={"date": "2026-10-11"},
        headers=manager["headers"],
    )
    assert (
        missing.status_code == 404
        and missing.json()["error"]["code"] == "SUMMARY_NOT_READY"
    )

    with Session(migrated_engine) as db:
        db.add(
            DailySummary(
                patient_id=uuid.UUID(patient["id"]),
                summary_date=date(2026, 10, 11),
                summary_text="يوم هادي",
                generated_at=datetime.now(UTC),
            )
        )
        db.commit()
    found = client.get(
        f"{base}/daily-summary",
        params={"date": "2026-10-11"},
        headers=manager["headers"],
    )
    assert found.status_code == 200 and found.json()["summary_text"] == "يوم هادي"


def test_alerts_are_private_to_their_caregiver(client, migrated_engine):
    manager, patient, _ = _setup(client)
    with Session(migrated_engine) as db:
        alert = CaregiverAlert(
            caregiver_id=uuid.UUID(manager["id"]),
            patient_id=uuid.UUID(patient["id"]),
            alert_type="low_battery",
            message="Glasses battery is at 10%",
            entity_type="device",
            entity_id=uuid.uuid4(),
        )
        db.add(alert)
        db.commit()
        alert_id = str(alert.id)

    listed = client.get(
        f"{API}/caregivers/me/alerts", headers=manager["headers"]
    ).json()
    assert [a["id"] for a in listed] == [alert_id] and listed[0]["read_at"] is None
    assert listed[0]["entity_type"] == "device"

    stranger = register_and_login(client)
    stolen = client.post(f"{API}/alerts/{alert_id}/read", headers=stranger["headers"])
    assert stolen.status_code == 404

    read = client.post(f"{API}/alerts/{alert_id}/read", headers=manager["headers"])
    assert read.status_code == 200 and read.json()["read_at"] is not None
    unread = client.get(
        f"{API}/caregivers/me/alerts",
        params={"unread_only": True},
        headers=manager["headers"],
    )
    assert unread.json() == []


def test_push_token_moves_to_the_latest_caregiver(client, migrated_engine):
    first = register_and_login(client)
    second = register_and_login(client)
    token = f"fcm-{uuid.uuid4()}"
    for caregiver in (first, second):
        response = client.post(
            f"{API}/me/push-token",
            json={"fcm_token": token},
            headers=caregiver["headers"],
        )
        assert response.status_code == 204
    with Session(migrated_engine) as db:
        owners = db.scalars(
            select(PushToken.user_id).where(PushToken.fcm_token == token)
        ).all()
    assert [str(o) for o in owners] == [second["id"]]


def test_assist_stub_answers_in_the_patients_language(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    response = client.post(
        f"{base}/assist",
        json={"question": "مين جالي النهارده؟"},
        headers=phone["headers"],
    )
    assert response.status_code == 200
    body = response.json()
    assert (
        body["language"] == "ar" and body["answer"] and body["source_event_ids"] == []
    )
    english = client.post(
        f"{base}/assist",
        json={"question": "Who visited?", "language": "en"},
        headers=phone["headers"],
    )
    assert english.json()["language"] == "en"
