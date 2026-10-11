import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Device
from app.oauth2 import Principal, get_current_device, get_current_user, get_principal
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
