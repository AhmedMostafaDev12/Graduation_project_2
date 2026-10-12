"""Which failures a task retries (CELERY_REDIS.md rule 6): temporary ones only.
A bad input or a bug is never retried."""

from sqlalchemy.exc import OperationalError

from app.errors import StorageUnavailable, TransientError

# TransientError: AI API timeouts/429/5xx · StorageUnavailable: S3 hiccup ·
# OperationalError: the database connection dropped
RETRYABLE = (TransientError, StorageUnavailable, OperationalError)
