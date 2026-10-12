"""Short Redis locks so two workers don't do the same job at once (CELERY_REDIS.md rule 5).

Idempotency is still the real guarantee: the lock only avoids wasted work.
"""

import uuid
from collections.abc import Iterator
from contextlib import contextmanager

import redis

from app.config import settings

_client = None


def _redis():
    global _client
    if _client is None:
        _client = redis.Redis.from_url(settings.redis_url)
    return _client


# Deletes the key only if we still own it (a slow task must not free another's lock)
_RELEASE = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) end"


@contextmanager
def task_lock(key: str, ttl_seconds: int) -> Iterator[bool]:
    """`with task_lock("media.thumbnail:<id>", 300) as got:` -> got is False if taken."""
    token = uuid.uuid4().hex
    acquired = bool(_redis().set(f"lock:{key}", token, nx=True, ex=ttl_seconds))
    try:
        yield acquired
    finally:
        if acquired:
            _redis().eval(_RELEASE, 1, f"lock:{key}", token)
