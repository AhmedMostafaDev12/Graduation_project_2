# backend-ai — Background jobs with Celery + Redis (best practices)

The freeCodeCamp course never leaves the request/response cycle, so this file **is** the guide for background work until the lead finishes studying it (`docs/BACKEND_STUDY_GUIDE.md`, Part B). Follow it exactly. Anything not covered here is a lead decision.

**Status: live since 13 Oct 2026** (`app/workers/`, Phase 6). Tasks today: `alerts.evaluate` (every 5 min), `retention.expire_media` (hourly), `media.make_thumbnail` (after each upload) and `media.backfill_thumbnails` (every 10 min). Phase 7: `transcribe.segment` (queue `ai_io`, queued by each audio upload, one audio segment → transcript → audio deleted; up to 3 retries, then `failed`), `transcribe.backfill` (every 10 min: segments whose queueing failed or whose task died), `embed.events` (queue `ai_io`, queued right after a transcript) and `embed.backfill` (every 5 min: any event without an embedding), `memory.consolidate` (queue `ai_io`, queued right after a transcript: facts, intentions, entity index, and settling open intentions), `memory.backfill` (every 10 min: transcripts not consolidated yet) and `memory.expire_intentions` (hourly: open intentions past their window become `unknown`). Phase 8: `faces.reembed_stub` (queue `cpu`, run once by hand after the real face model is deployed: replaces stub embeddings, reports photos to retake), `review.media` (queue `ai_io`, queued by each photo the glasses propose: blur strangers → Gemini → keep/discard, documents, retention) and `review.backfill` (every 10 min). The other AI tasks (`review`, `cluster`, `summaries`) arrive in Phases 8–9 and follow the same pattern.

---

## 1. Mental model

```
Your code:        transcribe.delay(segment_id)      <- "run this later"
Celery:           workers, retries, queues, Beat    <- the task framework
Redis:            the broker                        <- stores and delivers the messages
```

- **Why not FastAPI `BackgroundTasks`?** It runs inside the API process: lost on restart, no retries, no schedule. Never use it for work that must survive.
- **Delivery is at-least-once.** A task can run **twice** (a worker crash after the work but before the ack). Every task must be safe to run twice.

---

## 2. The ten rules

1. **Enqueue after commit.** Commit the DB transaction **first**, then call `.delay()`/`.apply_async()`. Otherwise the worker can run before the row exists.
2. **Pass IDs, not objects.** Task arguments are UUID strings and simple values only. Never ORM objects, file bytes or large payloads.
3. **Tasks are thin.** A task loads by ID and calls a **service** (`app/services/`). The same service is used by routes. No business logic in the task body.
4. **Idempotent by design:**
   - **Check state first:** if `audio_segments.status == 'transcribed'`, return.
   - **Deterministic IDs + upserts:** the transcript event's ID is derived from the segment ID, so a re-run overwrites instead of duplicating.
   - **Side effects last:** delete from S3 or send a push only **after** the state change is committed.
5. **No concurrent duplicates.** Celery doesn't deduplicate by `task_id`. Take a short **Redis lock** before working: `SET <key> <worker> NX EX <ttl>` with key = `task_name:entity_id`. If the lock is taken, return. Idempotency is still the real guarantee; the lock just avoids wasted work.
6. **Retry only temporary failures.** `autoretry_for=(TransientError,)`, `retry_backoff=True`, `retry_jitter=True`, `max_retries=3`. When retries run out, set the row's `status = 'failed'` and log at error level. Never retry validation errors.
7. **Reliable acknowledgement.** `task_acks_late=True`, `task_reject_on_worker_lost=True`, `worker_prefetch_multiplier=1`. The message is removed from Redis only after the task finishes.
8. **No result backend.** `task_ignore_result=True`. Job state lives in Postgres rows, not in Celery results.
9. **Time limits.** Every task has `soft_time_limit` and `time_limit`. The Redis `visibility_timeout` must be **longer** than the longest task, or Redis redelivers it while it's still running.
10. **One Celery Beat only.** Run exactly one Beat process. Two Beats run every schedule twice.

---

## 3. Remori configuration (spec §5.1)

| Setting | Value | Why |
|---|---|---|
| Broker | Redis (`redis://redis:6379/0`), **AOF persistence on** | queued jobs survive a Redis restart |
| `task_acks_late` | `True` | redeliver if the worker dies mid-task |
| `task_reject_on_worker_lost` | `True` | same, for killed worker processes |
| `worker_prefetch_multiplier` | `1` | a worker doesn't hoard messages while busy |
| `task_ignore_result` | `True` | state lives in Postgres |
| `broker_transport_options.visibility_timeout` | longer than the longest task (e.g. 3600 s) | avoid duplicate delivery of slow tasks |
| Serializer | `json` | IDs only, readable in Flower |
| Timezone | `UTC` (Beat), patient timezones handled in code | Egypt DST (spec M10) |

**Queues:**

| Queue | Tasks | Worker pool |
|---|---|---|
| `ai_io` | transcribe, review, embed, summaries (waiting on AI APIs) | `--pool=threads --concurrency=8` |
| `cpu` | cluster (and face work if moved to a task) | `--pool=prefork --concurrency=2` |
| `default` | retention, alerts | prefork |

Phase 1 runs **one** worker consuming all three queues, `--concurrency=2 --max-tasks-per-child=100` on the t3.small (2 processes; each recycled after 100 tasks so image work can't grow memory forever). Worker processes use **1 database connection each** (`DB_POOL_SIZE=1`, `DB_MAX_OVERFLOW=0`): API 2×5 + worker 2×1 = 12 connections to Supabase's pooler. Splitting the queues into separate workers is a lead decision, made when load requires it.

**Beat schedule:**

| Task | Every | Notes |
|---|---|---|
| `retention.expire_media` | hour | deletes expired media (spec §8) |
| `alerts.evaluate` | 5 min | missed meds, device offline, low battery |
| `summaries.generate_due` | 30 min | generates each patient's summary once their local time passes 23:30 |

**Task IDs and lock keys:** `transcribe:{segment_id}`, `review:{media_id}`, `embed:{event_id}`, `cluster:{encounter_id}`, `summary:{patient_id}:{date}`.

---

**How Remori applies the rules (the code to copy for new tasks):**

| Rule | Where |
|---|---|
| 1 enqueue after commit | `media_service.complete_upload` commits, then `_enqueue_thumbnail` |
| 2 IDs only | `make_thumbnail.delay(str(media_id))` |
| 3 thin tasks | `workers/tasks/*.py` only lock + open a session + call a service |
| 4 idempotent | services check state first (preview exists, already alerted, already deleted) |
| 5 Redis lock | `workers/locks.py`: `with task_lock(f"media.make_thumbnail:{id}", ttl) as got:` |
| 6 retry only temporary failures | `workers/retry.py`: `TransientError`, `StorageUnavailable`, DB `OperationalError`; anything else fails at once |
| 7–9 acks, prefetch, no results, time limits | `workers/celery_app.py`, one comment per setting |
| 10 one beat | the `beat` service in `docker-compose.yml`, never scaled |

**A queue that can't be reached never fails a request:** if Redis is down at upload time, the upload still succeeds and `media.backfill_thumbnails` re-queues it later. Use the same "sweep" pattern for any future task that a request enqueues.

## 4. Rate limits and cost

- AI providers have rate limits. Cap them with the task's `rate_limit` (e.g. `"60/m"`) and the `ai_io` concurrency, never with ad-hoc sleeps.
- Every AI task logs its duration and outcome (not its content) so cost and failures are visible.

---

## 5. Running it

Same Docker image for everything, different commands (docker-compose):

| Service | Command |
|---|---|
| `worker` | `celery -A app.workers.celery_app worker -Q ai_io,cpu,default --loglevel=info` |
| `beat` | `celery -A app.workers.celery_app beat --loglevel=info` (exactly one) |
| `flower` | **not deployed** (the lead's choice, to save ~80 MB). Use `celery inspect` and the logs (README → Useful commands). If added later: internal only, behind auth |
| `redis` | `redis-server --appendonly yes` |

---

## 6. Testing tasks

- **Unit:** the `worker_session` fixture (`tests/conftest.py`) runs tasks inline (`task_always_eager`), errors propagate, the Redis lock always succeeds, and task sessions use the test database: **CI needs no Redis**. AI APIs are mocked with `respx`. Example: `tests/test_workers.py`.
- **Idempotency:** run every task **twice** with the same ID and assert one result (one event, one deletion, one push).
- **Failure:** make the mocked API return 429/500 and assert `TransientError` is raised. After the final retry, assert the row is `failed`.
- **Integration:** one test with a real worker + Redis (Docker) for the transcribe flow.

---

## 7. Common mistakes to refuse

| Mistake | Why it's wrong |
|---|---|
| `.delay()` before `db.commit()` | the worker can't find the row |
| Passing a model object or file bytes to a task | can't be serialized, or a huge message |
| Retrying on every exception | loops forever on bad data |
| Sending the push before saving the state | a re-run sends a second push |
| Two Beat processes | every schedule runs twice |
| `time.sleep()` to respect rate limits | blocks a worker thread. Use `rate_limit` |
| Business logic inside the task | can't be reused by routes or tested without Celery |
