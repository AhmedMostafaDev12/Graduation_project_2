from fastapi import Depends, FastAPI
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.errors import DatabaseUnavailable, register_error_handlers

app = FastAPI(title="Remori API", version="0.1.0")
register_error_handlers(app)


@app.get("/health", tags=["health"])
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        raise DatabaseUnavailable("The database is not reachable.") from exc
    return {"status": "ok", "database": "ok"}
