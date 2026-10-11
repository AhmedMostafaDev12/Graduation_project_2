from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    """An error the client should see. Rendered in the spec §7.5 shape."""

    status_code = 400
    code = "BAD_REQUEST"

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class DatabaseUnavailable(AppError):
    status_code = 503
    code = "DATABASE_UNAVAILABLE"


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message}},
        )
