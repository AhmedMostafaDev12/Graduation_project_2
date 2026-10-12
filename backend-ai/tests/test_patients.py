"""Creating patients, linking caregivers, and the patient-link security check (Phase 3.3, 3.5)."""

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CaregiverPatientLink, ConsentRecord
from tests.conftest import API, create_patient, register_and_login


def test_create_patient_makes_the_caregiver_its_primary_manager(
    client, migrated_engine
):
    caregiver = register_and_login(client)
    patient = create_patient(client, caregiver, name="فاطمة محمود")

    assert patient["full_name"] == "فاطمة محمود"
    assert patient["preferred_language"] == "ar"
    assert patient["timezone"] == "Africa/Cairo"
    assert patient["memory_capture_enabled"] is True

    with Session(migrated_engine) as db:
        link = db.scalar(
            select(CaregiverPatientLink).where(
                CaregiverPatientLink.patient_id == uuid.UUID(patient["id"])
            )
        )
        consents = db.scalars(
            select(ConsentRecord.consent_type).where(
                ConsentRecord.patient_id == uuid.UUID(patient["id"])
            )
        ).all()
    assert str(link.caregiver_id) == caregiver["id"]
    assert link.is_primary is True and link.permission == "manager"
    assert consents == ["cloud_processing"]


def test_unknown_timezone_is_rejected(client):
    caregiver = register_and_login(client)
    response = client.post(
        f"{API}/patients",
        json={"full_name": "P", "relationship": "son", "timezone": "Mars/Olympus"},
        headers=caregiver["headers"],
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_manager_links_another_caregiver_by_email(client):
    manager = register_and_login(client)
    nurse = register_and_login(client)
    patient = create_patient(client, manager)

    url = f"{API}/patients/{patient['id']}/caregivers"
    body = {"email": nurse["email"], "relationship": "nurse", "permission": "viewer"}
    linked = client.post(url, json=body, headers=manager["headers"])
    assert linked.status_code == 201
    assert (
        linked.json()["permission"] == "viewer" and linked.json()["is_primary"] is False
    )

    again = client.post(url, json=body, headers=manager["headers"])
    assert (
        again.status_code == 409 and again.json()["error"]["code"] == "ALREADY_LINKED"
    )


def test_linking_an_unknown_email_is_a_clear_error(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    response = client.post(
        f"{API}/patients/{patient['id']}/caregivers",
        json={"email": "nobody-here@example.com", "relationship": "nurse"},
        headers=manager["headers"],
    )
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "CAREGIVER_NOT_FOUND"


def test_caregiver_a_cannot_touch_patient_b(client):
    """The IDOR test from the plan: another caregiver's patient looks like it doesn't exist."""
    caregiver_a = register_and_login(client)
    caregiver_b = register_and_login(client)
    patient_of_b = create_patient(client, caregiver_b)

    response = client.post(
        f"{API}/patients/{patient_of_b['id']}/caregivers",
        json={
            "email": caregiver_a["email"],
            "relationship": "intruder",
            "permission": "manager",
        },
        headers=caregiver_a["headers"],
    )
    nonexistent = client.post(
        f"{API}/patients/{uuid.uuid4()}/caregivers",
        json={"email": caregiver_a["email"], "relationship": "x"},
        headers=caregiver_a["headers"],
    )
    assert response.status_code == nonexistent.status_code == 404
    assert response.json() == nonexistent.json()
    assert response.json()["error"]["code"] == "PATIENT_NOT_FOUND"


def test_a_viewer_cannot_add_caregivers(client):
    manager = register_and_login(client)
    viewer = register_and_login(client)
    patient = create_patient(client, manager)
    client.post(
        f"{API}/patients/{patient['id']}/caregivers",
        json={
            "email": viewer["email"],
            "relationship": "nurse",
            "permission": "viewer",
        },
        headers=manager["headers"],
    )
    response = client.post(
        f"{API}/patients/{patient['id']}/caregivers",
        json={"email": manager["email"], "relationship": "x"},
        headers=viewer["headers"],
    )
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "MANAGER_ONLY"


def test_list_my_patients_and_me(client):
    from tests.conftest import add_viewer

    manager = register_and_login(client)
    own = create_patient(client, manager, name="Own")
    other_manager = register_and_login(client)
    shared = create_patient(client, other_manager, name="Shared")
    client.post(
        f"{API}/patients/{shared['id']}/caregivers",
        json={"email": manager["email"], "relationship": "nurse"},
        headers=other_manager["headers"],
    )
    create_patient(client, register_and_login(client), name="Not mine")
    add_viewer(client, manager, own["id"])

    listed = client.get(f"{API}/patients", headers=manager["headers"]).json()
    assert [(p["id"], p["permission"], p["is_primary"]) for p in listed] == [
        (own["id"], "manager", True),
        (shared["id"], "viewer", False),
    ]

    me = client.get(f"{API}/auth/me", headers=manager["headers"])
    assert me.status_code == 200 and me.json()["email"] == manager["email"]
    assert "password_hash" not in me.json()
