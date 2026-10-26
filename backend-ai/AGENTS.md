# backend-ai — Agent instructions

The Remori backend: a FastAPI REST API, the database (models + Alembic migrations), background workers (Celery + Redis), and **all software that uses AI** (AI API clients, RAG, vector search, local model inference).
Read the root [`AGENTS.md`](../AGENTS.md) first. Its rules apply here too.

Owner: **Ahmed Mostafa** (lead, backend + AI).

---

## 1. How this code is written

The lead learned FastAPI from the freeCodeCamp course *"Python API Development – Comprehensive Course for Beginners"* (Sanjeev Thiyagarajan). **Follow that course's layout, names and style** so the code stays familiar. Only add what the course doesn't cover.

- Course video: https://youtu.be/0sOvCWFmrtA
- **Course source code (reference implementation): https://github.com/Sanjeev-Thiyagarajan/fastapi-course.** When unsure how something is done "the course way" (routers, `oauth2.py`, tests with `conftest.py`, Alembic, Docker, nginx, gunicorn), look there first, then apply the current library versions from §1 below.
- **Production follows the course too:** nginx reverse proxy + certbot (HTTPS) + ufw on the Ubuntu host, and gunicorn with uvicorn workers serving the app. The app runs in Docker, bound to `127.0.0.1:8000`, because Celery + Redis join it later. Steps: [`docs/DEVELOPMENT_PLAN.md`](docs/DEVELOPMENT_PLAN.md) Phase 4.

| From the course (keep as taught) | Added for Remori (course doesn't cover it) |
|---|---|
| `main.py`, `config.py`, `database.py`, `models` + `schemas` (split into folders by domain), `oauth2.py`, `utils.py`, `routers/`, Alembic, pytest, Docker | `services/` (logic shared by routes and workers), `errors.py`, `ai/` (AI as software), `workers/` (Celery), `integrations/` (S3, FCM) |

Use **current library versions**, not the course's 2021 ones: Pydantic v2, SQLAlchemy 2.0 style, PyJWT, pwdlib. Details are in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 2. Topic docs (read the one that matches your task)

| Doc | Read when you… |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | add or change any route, service, schema or model. Includes the folder map and "where does this code go?" |
| [`docs/AI_LAYER.md`](docs/AI_LAYER.md) | touch STT, LLM, vision, embeddings, RAG, vector search or face inference. Includes the boundary between `backend-ai/app/ai/` and `ml/` |
| [`docs/CELERY_REDIS.md`](docs/CELERY_REDIS.md) | write or change a background task, a schedule, or anything with Redis. **Not covered by the course**, so follow it closely |
| [`docs/DATABASE.md`](docs/DATABASE.md) | change a table, write a migration, or connect to local Postgres or Supabase |
| [`docs/MODELS_CHOICE.md`](docs/MODELS_CHOICE.md) | pick or change a cloud AI provider (speech-to-text, LLM, vision, embeddings): options, prices, free tiers, the data rule |

Spec sections you'll need most: §6 (tables), §7.2 (endpoints), §7.3–7.4 (AI pipelines), §8 (retention), §9 (privacy).

---

## 3. Rules

1. **Ask the lead before any decision the spec doesn't make**: new dependency, table, column, endpoint, queue, prompt strategy or AI provider. Propose options; don't pick.
2. **Stay inside `backend-ai/`.** Need something in `ml/` or `flutter/`? Ask.
3. **Routers stay thin. Logic goes in `services/`.** A Celery task and a route that do the same thing call the same service function.
4. **Every `/patients/{patient_id}/…` route uses the `require_patient_link` dependency.** Missing it is a security bug.
5. **Errors:** services raise domain errors from `errors.py`, and `main.py` maps them to the spec §7.5 shape. Never return ad-hoc error JSON.
6. **No secrets in code.** Everything comes from `config.py` (pydantic-settings, `.env` locally).
7. **Never log** transcripts, names, face images, embeddings or tokens.
8. **The lead is still learning Celery.** In worker code, keep it simple, follow [`docs/CELERY_REDIS.md`](docs/CELERY_REDIS.md) exactly, and add a one-line comment on each non-obvious Celery setting explaining why it's there.

---

## 4. Commands (run before every push; CI runs the same)

```bash
cd backend-ai
ruff format .          # formatting (CI: ruff format --check)
ruff check . --fix     # lint
pytest -q              # tests
```

Local stack (once it exists): `docker compose -f docker-compose.dev.yml up` → API at `http://localhost:8000/docs`.

---

## 5. Current step

Plan phases 0–6 are done and **live at `https://remori-ai.duckdns.org`** (see [`docs/DEVELOPMENT_PLAN.md`](docs/DEVELOPMENT_PLAN.md)). Production runs `api`, `worker`, `beat` and `redis` (Supabase at migration `0004`). Deploy procedure: [`README.md`](README.md) → Production.

**Phase 5** (PRs #8, #9): every spec §7.2 endpoint except social sign-in, on the real database, with AI stubs (`ai/rag/answer.py`, `ai/inference/face.py`); D27–D29 filled every screen, added ~320 px previews and the smart-review contract. Report: [`docs/REPORT_PHASE_5.md`](docs/REPORT_PHASE_5.md).

**Phase 6** (PR #10): Redis + one Celery worker + one Beat, tasks `alerts.evaluate`, `retention.expire_media`, `media.make_thumbnail`, `media.backfill_thumbnails`. Copy their pattern for new tasks ([`docs/CELERY_REDIS.md`](docs/CELERY_REDIS.md)).

**Phase 7** (in progress): model interfaces + profiles (7.0, PR #67), the memory contract (7.0b, D41), Deepgram speech-to-text (7.1, PR #71, [`docs/MODELS_CHOICE.md`](docs/MODELS_CHOICE.md)), task `transcribe.segment` (7.2), events rendered + embedded by `embed.events` / `embed.backfill` (7.3), audio uploads start the transcription + `transcribe.backfill` (7.4), facts + intentions + entity index from speech with Gemini Flash (7.5, `memory.*` tasks). Write-up: [`docs/REPORT_PHASE_7.md`](docs/REPORT_PHASE_7.md). **Next:** deploy with the provider keys, then Phase 8. Google/Facebook sign-in (Phase 3 steps 3.0, 3.7–3.9) is postponed.

Every endpoint you add or change must also be updated in [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) §5–§6.
