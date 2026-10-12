"""Pairing the glasses with a patient (screen A5) and the phone's heartbeat."""

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, Forbidden, NotFound
from app.models import Device
from app.oauth2 import Principal, check_patient_access
from app.schemas.accounts import DevicePairOut, DevicePairRequest, HeartbeatIn
from app.utils import hash_token, new_token


def pair_device(
    db: Session, principal: Principal, data: DevicePairRequest
) -> DevicePairOut:
    """A managing caregiver pairs glasses (serial from the QR code) with a patient.

    The device token is returned once and stored only as a hash. Pairing the same glasses
    again with the same patient issues a new token; the old one stops working. Unpaired
    glasses can be paired with any patient.
    """
    access = check_patient_access(db, principal, data.patient_id)
    if access.permission != "manager":
        raise Forbidden(
            "Only a managing caregiver can pair glasses.", code="MANAGER_ONLY"
        )

    serial = data.serial_number.strip().upper()
    token = new_token()
    now = datetime.now(UTC)
    device = db.scalar(select(Device).where(Device.serial_number == serial))
    if (
        device is not None
        and device.patient_id != data.patient_id
        and device.unpaired_at is None
    ):
        raise Conflict(
            "These glasses are paired with another patient.",
            code="DEVICE_ALREADY_PAIRED",
        )
    if device is None:
        device = Device(
            patient_id=data.patient_id,
            serial_number=serial,
            token_hash=hash_token(token),
            firmware_version="unknown",  # the first heartbeat reports the real version
            paired_at=now,
        )
        db.add(device)
    else:
        device.patient_id = data.patient_id
        device.token_hash = hash_token(token)
        device.paired_at = now
        device.unpaired_at = None
    db.commit()
    db.refresh(device)
    return DevicePairOut(
        device_id=device.id,
        serial_number=device.serial_number,
        patient_id=device.patient_id,
        device_token=token,
        paired_at=device.paired_at,
    )


def heartbeat(
    db: Session, device: Device, device_id: uuid.UUID, data: HeartbeatIn
) -> Device:
    """The patient's phone reports battery, firmware and "still alive" (spec §7.2)."""
    if device.id != device_id:
        raise NotFound("Device not found.", code="DEVICE_NOT_FOUND")
    if data.battery_level_pct is not None:
        device.battery_level_pct = data.battery_level_pct
    if data.firmware_version:
        device.firmware_version = data.firmware_version
    device.last_seen_at = datetime.now(UTC)
    db.commit()
    db.refresh(device)
    return device


def list_devices(db: Session, patient_id: uuid.UUID) -> list[Device]:
    """The patient's paired glasses (C1 device card, C16)."""
    return list(
        db.scalars(
            select(Device)
            .where(Device.patient_id == patient_id, Device.unpaired_at.is_(None))
            .order_by(Device.paired_at.desc())
        )
    )


def unpair(db: Session, device: Device) -> None:
    """The row stays (recorded events point at it); the token stops working at once."""
    device.token_hash = hash_token(new_token())  # nobody knows this one
    device.unpaired_at = datetime.now(UTC)
    db.commit()
