"""Saved places, reminders and reminder logs (Phase 5)."""

import uuid

from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    pair_device,
    register_and_login,
)

REMINDER = {
    "title": "دواء الضغط",
    "type": "medication",
    "rrule": "FREQ=DAILY;BYHOUR=9;BYMINUTE=0",
    "dtstart": "2026-10-01T09:00:00+03:00",
}


def _setup(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    return manager, patient, f"{API}/patients/{patient['id']}"


def test_place_crud_and_soft_delete(client):
    manager, _, base = _setup(client)
    created = client.post(
        f"{base}/places",
        json={"name": "البيت", "latitude": 30.04, "longitude": 31.23},
        headers=manager["headers"],
    )
    assert created.status_code == 201 and created.json()["radius_m"] == 100
    place_id = created.json()["id"]

    renamed = client.patch(
        f"{base}/places/{place_id}", json={"radius_m": 150}, headers=manager["headers"]
    )
    assert renamed.status_code == 200 and renamed.json()["radius_m"] == 150
    assert renamed.json()["name"] == "البيت"

    assert (
        client.delete(
            f"{base}/places/{place_id}", headers=manager["headers"]
        ).status_code
        == 204
    )
    assert client.get(f"{base}/places", headers=manager["headers"]).json() == []
    gone = client.get(f"{base}/places/{place_id}", headers=manager["headers"])
    assert gone.status_code == 404 and gone.json()["error"]["code"] == "PLACE_NOT_FOUND"


def test_place_out_of_range_is_rejected(client):
    manager, _, base = _setup(client)
    bad = client.post(
        f"{base}/places",
        json={"name": "X", "latitude": 91, "longitude": 0},
        headers=manager["headers"],
    )
    assert bad.status_code == 422


def test_viewer_and_device_can_read_but_not_write_places(client):
    manager, patient, base = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    phone = pair_device(client, manager, patient["id"])
    body = {"name": "النادي", "latitude": 30.0, "longitude": 31.0}

    as_viewer = client.post(f"{base}/places", json=body, headers=viewer["headers"])
    assert (
        as_viewer.status_code == 403
        and as_viewer.json()["error"]["code"] == "MANAGER_ONLY"
    )
    assert (
        client.post(f"{base}/places", json=body, headers=phone["headers"]).status_code
        == 403
    )
    assert client.get(f"{base}/places", headers=viewer["headers"]).status_code == 200
    assert client.get(f"{base}/places", headers=phone["headers"]).status_code == 200


def test_another_patients_place_looks_missing(client):
    manager, _, base = _setup(client)
    place = client.post(
        f"{base}/places",
        json={"name": "A", "latitude": 1, "longitude": 1},
        headers=manager["headers"],
    ).json()
    other_manager, _, other_base = _setup(client)
    stolen = client.get(
        f"{other_base}/places/{place['id']}", headers=other_manager["headers"]
    )
    assert stolen.status_code == 404


def test_reminder_crud_and_rrule_validation(client):
    manager, _, base = _setup(client)
    created = client.post(
        f"{base}/reminders", json=REMINDER, headers=manager["headers"]
    )
    assert created.status_code == 201, created.text
    reminder = created.json()
    assert reminder["active"] is True and reminder["timezone"] == "Africa/Cairo"

    bad = client.post(
        f"{base}/reminders",
        json={**REMINDER, "rrule": "EVERY MORNING"},
        headers=manager["headers"],
    )
    assert bad.status_code == 422 and bad.json()["error"]["code"] == "VALIDATION_ERROR"
    naive = client.post(
        f"{base}/reminders",
        json={**REMINDER, "dtstart": "2026-10-01T09:00:00"},
        headers=manager["headers"],
    )
    assert naive.status_code == 422

    paused = client.patch(
        f"{base}/reminders/{reminder['id']}",
        json={"active": False},
        headers=manager["headers"],
    )
    assert paused.status_code == 200 and paused.json()["active"] is False

    deleted = client.delete(
        f"{base}/reminders/{reminder['id']}", headers=manager["headers"]
    )
    assert deleted.status_code == 204
    assert client.get(f"{base}/reminders", headers=manager["headers"]).json() == []


def _log(reminder_id, status, at, log_id=None):
    return {
        "id": log_id or str(uuid.uuid4()),
        "reminder_id": reminder_id,
        "scheduled_at": "2026-10-12T09:00:00+03:00",
        "status": status,
        "at": at,
    }


def test_reminder_logs_batch_is_idempotent_and_completed_wins(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    reminder = client.post(
        f"{base}/reminders", json=REMINDER, headers=manager["headers"]
    ).json()
    url = f"{base}/reminder-logs:batch"

    log_id = str(uuid.uuid4())
    done = _log(reminder["id"], "completed", "2026-10-12T09:01:00+03:00", log_id)
    first = client.post(url, json={"logs": [done]}, headers=phone["headers"])
    assert first.status_code == 200 and first.json()["accepted"] == [log_id]

    again = client.post(url, json={"logs": [done]}, headers=phone["headers"])
    assert again.json()["duplicates"] == [log_id]

    # a later "missed" from a stale phone must not undo "completed"
    late = _log(reminder["id"], "missed", "2030-01-01T00:00:00+00:00", log_id)
    assert client.post(url, json={"logs": [late]}, headers=phone["headers"]).json()[
        "duplicates"
    ] == [log_id]


def test_reminder_logs_for_someone_elses_reminder_are_rejected(client):
    manager, patient, base = _setup(client)
    phone = pair_device(client, manager, patient["id"])
    other_manager, _, other_base = _setup(client)
    foreign = client.post(
        f"{other_base}/reminders", json=REMINDER, headers=other_manager["headers"]
    ).json()
    log = _log(foreign["id"], "completed", "2026-10-12T09:01:00+03:00")
    result = client.post(
        f"{base}/reminder-logs:batch", json={"logs": [log]}, headers=phone["headers"]
    ).json()
    assert result["rejected"] == [log["id"]] and result["accepted"] == []


def test_viewer_cannot_upload_reminder_logs(client):
    manager, patient, base = _setup(client)
    viewer = add_viewer(client, manager, patient["id"])
    response = client.post(
        f"{base}/reminder-logs:batch", json={"logs": []}, headers=viewer["headers"]
    )
    assert response.status_code == 403
