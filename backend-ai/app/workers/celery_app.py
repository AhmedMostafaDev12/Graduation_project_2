"""The Celery app: settings, queues and the Beat schedule (docs/CELERY_REDIS.md §3).

Run (same Docker image as the API, different command):
    worker: celery -A app.workers.celery_app worker -Q ai_io,cpu,default --concurrency=2
    beat:   celery -A app.workers.celery_app beat   (exactly ONE beat process, rule 10)
"""

from celery import Celery
from celery.schedules import crontab
from kombu import Queue

from app.config import settings

celery_app = Celery(
    "remori",
    broker=settings.redis_url,
    # the modules that define tasks; the worker imports them at start
    include=[
        "app.workers.tasks.alerts",
        "app.workers.tasks.retention",
        "app.workers.tasks.media",
    ],
)

celery_app.conf.update(
    # rule 7: a message leaves Redis only after the task finished, so a crash re-runs it
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    # rule 7: a busy worker process doesn't hoard queued messages
    worker_prefetch_multiplier=1,
    # rule 8: no result backend; job state lives in Postgres rows
    task_ignore_result=True,
    # rule 9: must be longer than the longest task, or Redis re-delivers it mid-run
    broker_transport_options={"visibility_timeout": 3600},
    # rule 9: default limits for every task (each task may set tighter ones)
    task_soft_time_limit=300,
    task_time_limit=360,
    # IDs and simple values only (rule 2); readable when debugging
    task_serializer="json",
    accept_content=["json"],
    # Beat runs in UTC; patient timezones are handled in the services (Egypt DST)
    timezone="UTC",
    enable_utc=True,
    # keep retrying the broker connection on start instead of crashing
    broker_connection_retry_on_startup=True,
    # the three queues; Phase 1 runs one worker consuming all of them
    task_queues=[Queue("ai_io"), Queue("cpu"), Queue("default")],
    task_default_queue="default",
    task_routes={
        "alerts.*": {"queue": "default"},
        "retention.*": {"queue": "default"},
        "media.*": {"queue": "cpu"},  # image/video work is CPU-bound
    },
)

celery_app.conf.beat_schedule = {
    # missed medication, device offline, low battery (spec defaults, CELERY_REDIS.md §3)
    "alerts-evaluate": {"task": "alerts.evaluate", "schedule": crontab(minute="*/5")},
    # expired photos and stale audio (spec §8, §7.3)
    "retention-expire-media": {
        "task": "retention.expire_media",
        "schedule": crontab(minute=7),
    },
    # photos/videos whose preview task never ran (e.g. Redis was down at upload time)
    "media-backfill-thumbnails": {
        "task": "media.backfill_thumbnails",
        "schedule": crontab(minute="*/10"),
    },
    # summaries.generate_due arrives in Phase 9
}
