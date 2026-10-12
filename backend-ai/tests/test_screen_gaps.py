"""Endpoints added so every screen of the UI brief can be built (spec D28)."""

import uuid

from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    image_bytes,
    pair_device,
    register_and_login,
)

JPEG = image_bytes("JPEG")


def _setup(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    return manager, patient, f"{API}/patients/{patient['id']}"


def _enroll(client, manager, base, name="أحمد"):
    response = client.post(
        f"{base}/people",
        data={"name": name, "relationship": "son", "consent_given": "true"},
        files=[
            (
                "photos",
                ("p.jpg", image_bytes(color=(len(name) * 20, 50, 50)), "image/jpeg"),
            )
        ],
        headers=manager["headers"],
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_patch_patient_and_sync_sees_memory_switch(client):
    manager, patient, base = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    phone = pair_device(client, manager, patient["id"])

    changed = client.patch(
        base,
        json={"memory_capture_enabled": False, "timezone": "Europe/London"},
        headers=manager["headers"],
    )
    assert changed.status_code == 200, changed.text
    body = changed.json()
    assert (
        body["memory_capture_enabled"] is False and body["timezone"] == "Europe/London"
    )
    assert body["full_name"] == patient["full_name"]

    as_viewer = client.patch(base, json={"full_name": "X"}, headers=viewer["headers"])
    assert as_viewer.status_code == 403
    bad_tz = client.patch(
        base, json={"timezone": "Mars/Base"}, headers=manager["headers"]
    )
    assert bad_tz.status_code == 422

    settings = client.get(f"{base}/sync", headers=phone["headers"]).json()["settings"]
    assert settings["memory_capture_enabled"] is False


def test_list_caregivers(client):
    manager, patient, base = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    phone = pair_device(client, manager, patient["id"])
    listed = client.get(f"{base}/caregivers", headers=viewer["headers"]).json()
    assert [(c["caregiver_id"], c["is_primary"]) for c in listed] == [
        (manager["id"], True),
        (viewer["id"], False),
    ]
    assert client.get(f"{base}/caregivers", headers=phone["headers"]).status_code == 403


def test_devices_list_unpair_and_repair_elsewhere(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    beat = client.post(
        f"{API}/devices/{phone['device_id']}/heartbeat",
        json={"battery_level_pct": 55},
        headers=phone["headers"],
    )
    assert beat.status_code == 200

    [device] = client.get(f"{base}/devices", headers=manager["headers"]).json()
    assert device["battery_level_pct"] == 55 and device["online"] is True

    unpaired = client.delete(
        f"{API}/devices/{phone['device_id']}", headers=manager["headers"]
    )
    assert unpaired.status_code == 204
    assert client.get(f"{base}/devices", headers=manager["headers"]).json() == []
    dead = client.post(
        f"{API}/devices/{phone['device_id']}/heartbeat",
        json={},
        headers=phone["headers"],
    )
    assert dead.status_code == 401

    other_manager, other_patient, _ = _setup(client)
    repaired = client.post(
        f"{API}/devices/pair",
        json={
            "serial_number": phone["serial_number"],
            "patient_id": other_patient["id"],
        },
        headers=other_manager["headers"],
    )
    assert (
        repaired.status_code == 201
        and repaired.json()["device_id"] == phone["device_id"]
    )


def test_revoking_face_consent_archives_the_person(client):
    manager, _, base = _setup(client)
    person = _enroll(client, manager, base)
    consents = client.get(f"{base}/consents", headers=manager["headers"]).json()
    face = next(c for c in consents if c["consent_type"] == "face_enrollment")
    assert face["subject_name"] == "أحمد" and face["revoked_at"] is None

    revoked = client.post(
        f"{API}/consents/{face['id']}/revoke", headers=manager["headers"]
    )
    assert revoked.status_code == 200 and revoked.json()["revoked_at"] is not None
    assert client.get(f"{base}/people", headers=manager["headers"]).json() == []
    archived = client.get(
        f"{base}/people", params={"status": "archived"}, headers=manager["headers"]
    ).json()
    assert [p["id"] for p in archived] == [person["id"]]

    again = client.post(
        f"{API}/consents/{face['id']}/revoke", headers=manager["headers"]
    )
    assert (
        again.status_code == 409 and again.json()["error"]["code"] == "ALREADY_REVOKED"
    )


def test_people_list_carries_photo_urls(client):
    manager, _, base = _setup(client)
    _enroll(client, manager, base, "أحمد")
    _enroll(client, manager, base, "سارة")
    listed = client.get(f"{base}/people", headers=manager["headers"]).json()
    assert len(listed) == 2
    assert all(
        p["photo_url"].startswith("https://") and p["embedding_count"] == 1
        for p in listed
    )
    assert all(".thumb.jpg" in p["photo_url"] for p in listed)  # the small preview


def test_caregiver_reads_todays_reminder_logs(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    reminder = client.post(
        f"{base}/reminders",
        json={
            "title": "دواء الضغط",
            "type": "medication",
            "rrule": "FREQ=DAILY;BYHOUR=9",
            "dtstart": "2026-10-01T09:00:00+03:00",
        },
        headers=manager["headers"],
    ).json()
    log = {
        "id": str(uuid.uuid4()),
        "reminder_id": reminder["id"],
        "scheduled_at": "2026-10-12T09:00:00+03:00",
        "status": "snoozed",
        "snoozed_until": "2026-10-12T09:15:00+03:00",
    }
    client.post(
        f"{base}/reminder-logs:batch", json={"logs": [log]}, headers=phone["headers"]
    )

    day = client.get(
        f"{base}/reminder-logs",
        params={"date": "2026-10-12"},
        headers=manager["headers"],
    ).json()
    assert [(item["title"], item["status"]) for item in day] == [
        ("دواء الضغط", "snoozed")
    ]
    other_day = client.get(
        f"{base}/reminder-logs",
        params={"date": "2026-10-13"},
        headers=manager["headers"],
    )
    assert other_day.json() == []


def test_list_mind_games(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    for score, at in (
        (5, "2026-10-11T10:00:00+03:00"),
        (9, "2026-10-12T10:00:00+03:00"),
    ):
        client.post(
            f"{base}/mind-game-sessions",
            json={
                "id": str(uuid.uuid4()),
                "game_type": "card_match",
                "score": score,
                "duration_seconds": 120,
                "completed_at": at,
            },
            headers=phone["headers"],
        )
    games = client.get(f"{base}/mind-game-sessions", headers=phone["headers"]).json()
    assert [g["score"] for g in games] == [9, 5]
