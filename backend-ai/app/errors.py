"""Errors the client should see, all rendered in the spec §7.5 shape:
{"error": {"code": "...", "message": "..."}}.

Services raise these; they never raise HTTPException (docs/ARCHITECTURE.md §3).
"""

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class AppError(Exception):
    status_code = 400
    code = "BAD_REQUEST"

    def __init__(self, message: str, code: str | None = None):
        super().__init__(message)
        self.message = message
        if code:
            self.code = code


class Unauthorized(AppError):
    status_code = 401
    code = "NOT_AUTHENTICATED"


class Forbidden(AppError):
    status_code = 403
    code = "FORBIDDEN"


class NotFound(AppError):
    status_code = 404
    code = "NOT_FOUND"


class Conflict(AppError):
    status_code = 409
    code = "CONFLICT"


class InvalidInput(AppError):
    """Input that passes field validation but breaks a rule (e.g. an invalid schedule)."""

    status_code = 422
    code = "VALIDATION_ERROR"


class StorageUnavailable(AppError):
    status_code = 503
    code = "STORAGE_UNAVAILABLE"


class DatabaseUnavailable(AppError):
    status_code = 503
    code = "DATABASE_UNAVAILABLE"


def _error(status_code: int, code: str, message: str, **extra) -> JSONResponse:
    headers = {"WWW-Authenticate": "Bearer"} if status_code == 401 else None
    return JSONResponse(
        status_code=status_code,
        content={"error": {"code": code, "message": message, **extra}},
        headers=headers,
    )


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
        return _error(exc.status_code, exc.code, exc.message)

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        details = [
            {"field": ".".join(str(p) for p in err["loc"]), "message": err["msg"]}
            for err in exc.errors()
        ]
        return _error(
            422,
            "VALIDATION_ERROR",
            "Some fields are missing or invalid.",
            details=details,
        )

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_error(
        request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        codes = {404: "NOT_FOUND", 405: "METHOD_NOT_ALLOWED"}
        return _error(
            exc.status_code, codes.get(exc.status_code, "HTTP_ERROR"), str(exc.detail)
        )
