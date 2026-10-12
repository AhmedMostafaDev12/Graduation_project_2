import uuid

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Device
from app.oauth2 import (
    Principal,
    get_current_device,
    get_current_user,
    get_principal,
    load_for_patient,
    require_editor,
)
from app.schemas.accounts import (
    DeviceOut,
    DevicePairOut,
    DevicePairRequest,
    HeartbeatIn,
)
from app.services import device_service

router = APIRouter(prefix="/devices", tags=["Devices"])


@router.post("/pair", status_code=status.HTTP_201_CREATED, response_model=DevicePairOut)
def pair(
    data: DevicePairRequest,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
    _caregiver=Depends(get_current_user),  # only caregivers pair glasses
):
    return device_service.pair_device(db, principal, data)


@router.post("/{device_id}/heartbeat", response_model=DeviceOut)
def heartbeat(
    device_id: uuid.UUID,
    data: HeartbeatIn,
    db: Session = Depends(get_db),
    device: Device = Depends(get_current_device),
):
    return device_service.heartbeat(db, device, device_id, data)


@router.delete("/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
def unpair(
    device_id: uuid.UUID,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_principal),
):
    """C16 Unpair. The phone's token stops working; the glasses can be paired again."""
    device, access = load_for_patient(
        db, principal, Device, device_id, "Device", "DEVICE_NOT_FOUND"
    )
    require_editor(access)
    if device.unpaired_at is None:  # unpairing twice is harmless
        device_service.unpair(db, device)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
