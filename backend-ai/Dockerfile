# One image for the API now, and for Celery workers later (only the command differs).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /code

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app ./app

# Don't run as root inside the container
RUN useradd --create-home --uid 1000 remori
USER remori

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
