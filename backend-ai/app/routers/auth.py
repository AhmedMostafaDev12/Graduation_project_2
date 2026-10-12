from fastapi import APIRouter, Depends, Response, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.oauth2 import get_current_user
from app.schemas.accounts import CaregiverCreate, RefreshRequest, Token, UserOut
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=UserOut)
def register(data: CaregiverCreate, db: Session = Depends(get_db)):
    return auth_service.register_caregiver(db, data)


@router.post("/login", response_model=Token)
def login(
    credentials: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    """As in the course: form fields `username` (the email) and `password`."""
    return auth_service.login(db, credentials.username, credentials.password)


@router.post("/refresh", response_model=Token)
def refresh(data: RefreshRequest, db: Session = Depends(get_db)):
    return auth_service.refresh(db, data.refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(data: RefreshRequest, db: Session = Depends(get_db)):
    auth_service.logout(db, data.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=UserOut)
def me(caregiver: User = Depends(get_current_user)):
    """The signed-in caregiver."""
    return caregiver
