"""Pairing glasses and the phone's heartbeat with a device token (Phase 3.4)."""

import uuid

from tests.conftest import API, create_patient, register_and_login


def _serial() -> str:
    return f"RMR-T{uuid.uuid4().hex[:6].upper()}"


def _pair(client, caregiver, patient_id, serial):
    return client.post(
        f"{API}/devices/pair",
        json={"serial_number": serial, "patient_id": patient_id},
        headers=caregiver["headers"],
    )


def test_pair_returns_a_device_token_that_works_for_heartbeat(client):
    caregiver = register_and_login(client)
    patient = create_patient(client, caregiver)
    paired = _pair(client, caregiver, patient["id"], _serial())
    assert paired.status_code == 201
    device = paired.json()
    assert device["patient_id"] == patient["id"] and device["device_token"]

    beat = client.post(
        f"{API}/devices/{device['device_id']}/heartbeat",
        json={"battery_level_pct": 76, "firmware_version": "0.3.1"},
        headers={"Authorization": f"Bearer {device['device_token']}"},
    )
    assert beat.status_code == 200
    body = beat.json()
    assert body["battery_level_pct"] == 76 and body["firmware_version"] == "0.3.1"
    assert body["last_seen_at"] is not None
    assert "token_hash" not in body


def test_glasses_paired_to_one_patient_cannot_be_taken_by_another(client):
    caregiver = register_and_login(client)
    first, second = create_patient(client, caregiver), create_patient(client, caregiver)
    serial = _serial()
    assert _pair(client, caregiver, first["id"], serial).status_code == 201
    taken = _pair(client, caregiver, second["id"], serial)
    assert taken.status_code == 409
    assert taken.json()["error"]["code"] == "DEVICE_ALREADY_PAIRED"


def test_re_pairing_issues_a_new_token_and_the_old_one_stops_working(client):
    caregiver = register_and_login(client)
    patient = create_patient(client, caregiver)
    serial = _serial()
    old = _pair(client, caregiver, patient["id"], serial).json()
    new = _pair(client, caregiver, patient["id"], serial).json()
    assert (
        old["device_id"] == new["device_id"]
        and old["device_token"] != new["device_token"]
    )

    url = f"{API}/devices/{old['device_id']}/heartbeat"
    stale = client.post(
        url, json={}, headers={"Authorization": f"Bearer {old['device_token']}"}
    )
    fresh = client.post(
        url, json={}, headers={"Authorization": f"Bearer {new['device_token']}"}
    )
    assert stale.status_code == 401 and fresh.status_code == 200


def test_a_device_can_only_report_for_itself(client):
    caregiver = register_and_login(client)
    patient = create_patient(client, caregiver)
    device = _pair(client, caregiver, patient["id"], _serial()).json()
    response = client.post(
        f"{API}/devices/{uuid.uuid4()}/heartbeat",
        json={},
        headers={"Authorization": f"Bearer {device['device_token']}"},
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "DEVICE_NOT_FOUND"


def test_caregiver_and_device_routes_are_kept_apart(client):
    caregiver = register_and_login(client)
    patient = create_patient(client, caregiver)
    device = _pair(client, caregiver, patient["id"], _serial()).json()
    device_headers = {"Authorization": f"Bearer {device['device_token']}"}

    caregiver_on_device_route = client.post(
        f"{API}/devices/{device['device_id']}/heartbeat",
        json={},
        headers=caregiver["headers"],
    )
    device_on_caregiver_route = client.post(
        f"{API}/patients",
        json={"full_name": "P", "relationship": "x"},
        headers=device_headers,
    )
    assert caregiver_on_device_route.status_code == 403
    assert caregiver_on_device_route.json()["error"]["code"] == "DEVICE_ONLY"
    assert device_on_caregiver_route.status_code == 403
    assert device_on_caregiver_route.json()["error"]["code"] == "CAREGIVER_ONLY"


def test_only_a_linked_manager_can_pair(client):
    owner = register_and_login(client)
    stranger = register_and_login(client)
    patient = create_patient(client, owner)
    response = _pair(client, stranger, patient["id"], _serial())
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "PATIENT_NOT_FOUND"
