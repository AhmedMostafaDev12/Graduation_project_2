# backend-ai — Architecture (course layout + what Remori adds)

Source of truth: [`REMORI_SPEC.md`](../../REMORI_SPEC.md) §5–§7. This file says **where code goes** and **how each layer behaves**.

---

## 1. Folder map

Files marked **[course]** keep the freeCodeCamp course's name and role. Files marked **[added]** cover what the course doesn't.

```
backend-ai/
├── app/
│   ├── main.py            # [course] create app, include routers, CORS, exception handlers (errors.py)
│   ├── config.py          # [course] Settings via pydantic-settings (.env): DATABASE_URL, JWT, Redis, S3, AI keys
│   ├── database.py        # [course] engine, SessionLocal, Base, get_db
│   ├── models/            # [course models.py, split by domain] SQLAlchemy tables, exactly spec §6
│   │   ├── __init__.py    #   re-exports every model: `from app import models` / `from app.models import User`
│   │   ├── _columns.py    #   shared column helpers (pk, fk, timestamps), vector sizes
│   │   └── accounts.py  people.py  places.py  journal.py  media.py  reminders.py  activity.py  privacy.py
│   ├── schemas/           # [course schemas.py, split by domain] Pydantic request/response, exactly spec §7.2
│   │   └── accounts.py  people.py  places.py  journal.py  media.py  reminders.py  activity.py  privacy.py
│   ├── oauth2.py          # [course] JWT create/verify, get_current_user
│   │                      #   + [added] get_current_device (device token), require_patient_link
│   ├── utils.py           # [course] password hashing (pwdlib)
│   ├── routers/           # [course] one file per resource, thin: parse → call service → return schema
│   │   ├── auth.py  patients.py  devices.py  sync.py  people.py  unknown_faces.py
│   │   ├── events.py  uploads.py  media.py  documents.py  journal.py  assist.py
│   │   └── reminders.py  places.py  alerts.py  mind_games.py  summaries.py
│   ├── services/          # [added] business logic + transactions, called by routers AND workers
│   │   └── people_service.py  sync_service.py  reminder_service.py  media_service.py …
│   ├── errors.py          # [added] domain exceptions + handlers → spec §7.5 error shape
│   ├── integrations/      # [added] non-AI external services: s3.py (presigned URLs), fcm.py (push),
│   │                      #   google_auth.py + facebook_auth.py (verify sign-in tokens, spec D26)
│   ├── ai/                # [added] AI as software. See AI_LAYER.md
│   │   ├── clients/       #   external AI APIs: stt.py, llm.py, vision.py, embeddings.py
│   │   ├── inference/     #   local models: face.py (loads exported ONNX from ml/models/)
│   │   ├── rag/           #   render.py (event → sentence), retriever.py (time filter + pgvector), answer.py
│   │   ├── clustering.py  #   unknown-face clustering on embeddings
│   │   └── prompts/       #   prompt templates as versioned text files
│   └── workers/           # [added] Celery. See CELERY_REDIS.md
│       ├── celery_app.py  #   Celery app, config, queues, beat_schedule
│       ├── locks.py · retry.py · db.py  # Redis lock, what to retry, task sessions
│       └── tasks/         #   alerts.py  retention.py  media.py (built) · transcribe.py  review.py  embed.py  cluster.py  summaries.py (Phases 7–9)
├── alembic/               # [course] migrations (first one: CREATE EXTENSION vector)
├── tests/                 # [course] pytest: conftest.py, test database, TestClient
├── requirements.txt       # [course]
├── Dockerfile             # [course] one image, used for api, worker and beat
├── docker-compose.yml     # [course] production: api · worker · beat · redis (DB = Supabase; no flower)
└── docker-compose.dev.yml # [added] local: + postgres (pgvector/pgvector:pg17)
```

The course keeps `models.py` and `schemas.py` as single files. With 22 tables, Remori splits both into packages by domain, with the **same file names in both** (lead decision, 12 Oct 2026). A model and its schemas live in files with the same name: `models/reminders.py` ↔ `schemas/reminders.py`.

---

## 2. Where does my code go?

| You are writing… | Put it in |
|---|---|
| A new endpoint from spec §7.2 | `routers/<resource>.py` (thin) + logic in `services/<resource>_service.py` |
| Validation of request/response JSON | `schemas/<domain>.py` |
| A table or column (spec §6 only) | `models/<domain>.py` + export it in `models/__init__.py` + an Alembic migration. See DATABASE.md |
| "Is this caller allowed to see this patient?" | `oauth2.py` → `require_patient_link` dependency |
| An error the client should see | a domain exception in `errors.py`, raised from a service |
| A call to Whisper / an LLM / a vision model / embeddings | `ai/clients/` |
| Running a local model (face) | `ai/inference/` (model files come from `ml/models/`) |
| Retrieval, prompt building, answering | `ai/rag/` + `ai/prompts/` |
| Training, notebooks, datasets, exporting a model | **not here**, in `ml/` |
| Something slow or unreliable (AI calls, S3 deletes, pushes) | a Celery task in `workers/tasks/` that calls a service |
| Something on a schedule | Celery Beat entry in `workers/celery_app.py` |
| S3 or FCM | `integrations/` |
| Verifying a Google / Facebook sign-in token | `integrations/google_auth.py`, `integrations/facebook_auth.py`. The login rules (find, link or create the caregiver) go in `services/auth_service.py` |

---

## 3. Layer rules

| Layer | Rule |
|---|---|
| **Routers** | No SQL, no business rules. Validate with schemas, call **one** service, return a schema. Use `def` endpoints (sync), as in the course |
| **Services** | Own the transaction (commit/rollback). Raise domain errors, **never** `HTTPException`. Usable from a route and from a Celery task |
| **Tasks** | Thin like routers: receive **IDs only** (never ORM objects or file bytes), call a service |
| **ai/clients** | Every call has a timeout. Temporary failures (timeout, 429, 5xx) raise `TransientError` so Celery can retry |
| **Models in memory** | Loaded **once per process**: FastAPI `lifespan` for the API, Celery's `worker_process_init` signal for workers |

---

## 4. Cross-cutting rules

- **Authorization:** every `/patients/{patient_id}/…` router has `Depends(require_patient_link)`. A caregiver who isn't linked gets **404** (don't reveal that the patient exists). Every router has a test proving caregiver A can't read patient B.
- **Errors:** mapped once in `main.py`. Not found → 404, not linked → 404, validation → 422, conflict → 409. Body: `{"error": {"code", "message"}}`.
- **Idempotent batch writes:** `INSERT … ON CONFLICT (id) DO NOTHING`, response `{"accepted": [...], "duplicates": [...]}`.
- **Logging:** structured logs with a `request_id` per request (middleware), passed into tasks. Never log transcripts, names, images, embeddings or tokens.
- **Config:** only through `config.py`. `.env` locally, GitHub Secrets in CI, IAM role on EC2 for S3. `DATABASE_URL` is the only difference between local and production.

---

## 5. Library versions (the course used 2021 versions)

| Course | Use |
|---|---|
| Pydantic v1 (`orm_mode`, `.dict()`) | Pydantic v2 (`ConfigDict(from_attributes=True)`, `.model_dump()`) |
| SQLAlchemy 1.x (`db.query(...)`) | SQLAlchemy 2.0 (`select()`, `Mapped[]`, `mapped_column()`) |
| `python-jose` | `PyJWT` |
| `passlib` | `pwdlib` |
| `BaseSettings` from pydantic | `pydantic-settings` |

---

## 6. Testing

- pytest with a real Postgres + pgvector test database (Docker), as in the course's test-database setup.
- External AI APIs are mocked with `respx`. Tests never call real AI services.
- Services are tested directly (no HTTP). Routes are tested with `TestClient`.
- Every Celery task has a "run it twice → one result" test. See CELERY_REDIS.md.
