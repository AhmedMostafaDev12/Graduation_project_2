# One image for the API, the Celery worker and beat (only the command differs; docker-compose.yml).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=120

WORKDIR /code

COPY requirements.txt .
RUN pip install -r requirements.txt

# Face models pinned by spec D14, checked by SHA-256 (phase 8.1). Before `COPY app`, so the
# ~130 MB download is cached until the script changes.
COPY scripts/download_face_models.py scripts/
RUN python scripts/download_face_models.py /code/models
ENV FACE_MODELS_DIR=/code/models

COPY app ./app

# Don't run as root inside the container
RUN useradd --create-home --uid 1000 remori
USER remori

EXPOSE 8000
# Production: gunicorn managing uvicorn workers, as in the course's gunicorn.service.
# 2 workers fit the t3.small's 2 GB RAM. uvicorn_worker replaces the deprecated uvicorn.workers.
# docker-compose.dev.yml overrides this with `uvicorn --reload` for development.
CMD ["gunicorn", "app.main:app", "--workers", "2", "--worker-class", "uvicorn_worker.UvicornWorker", "--bind", "0.0.0.0:8000"]
