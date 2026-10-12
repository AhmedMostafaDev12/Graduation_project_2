from fastapi import Depends, FastAPI
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.errors import DatabaseUnavailable, register_error_handlers
from app.routers import (
    activity,
    assist,
    auth,
    consents,
    devices,
    journal,
    media,
    patients,
    people,
    places,
    reminders,
    sync,
)

API_PREFIX = "/api/v1"

app = FastAPI(title="Remori API", version="0.1.0")
register_error_handlers(app)

app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(patients.router, prefix=API_PREFIX)
app.include_router(devices.router, prefix=API_PREFIX)
app.include_router(consents.router, prefix=API_PREFIX)
app.include_router(sync.router, prefix=API_PREFIX)
app.include_router(people.router, prefix=API_PREFIX)
app.include_router(reminders.router, prefix=API_PREFIX)
app.include_router(places.router, prefix=API_PREFIX)
app.include_router(journal.router, prefix=API_PREFIX)
app.include_router(media.router, prefix=API_PREFIX)
app.include_router(assist.router, prefix=API_PREFIX)
app.include_router(activity.router, prefix=API_PREFIX)


@app.get("/health", tags=["health"])
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        raise DatabaseUnavailable("The database is not reachable.") from exc
    return {"status": "ok", "database": "ok"}
