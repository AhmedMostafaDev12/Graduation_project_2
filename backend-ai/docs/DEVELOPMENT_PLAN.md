# backend-ai — Development plan

The order in which the backend gets built, so that **the database is live first** and **the API is deployed early with seed (mock) data**, letting Flutter and the phone relay integrate from the start instead of at the end.

**Decisions this plan follows (lead, 2026-10-11):**
- **Mock data = seeded database.** CRUD endpoints are real and read/write the live database, filled with the UI board's sample data. Only AI-dependent endpoints return fixed fixture answers ("AI stubs") until the AI layer exists.
- **Real auth from the first deploy:** login, JWT, device token and patient-link authorization.
- **Production as in the course** ([fastapi-course repo](https://github.com/Sanjeev-Thiyagarajan/fastapi-course)): **nginx** reverse proxy + **certbot** (HTTPS) + **ufw** on the Ubuntu host, **gunicorn** with 2 uvicorn workers serving the app. The app runs in Docker bound to `127.0.0.1:8000` (Celery + Redis join it later). Domain: `remori-ai.duckdns.org`.
- **Manual deploy:** SSH into EC2 → `git pull` → `docker compose up -d --build`. CI stays "PR checks only".

Related docs: [ARCHITECTURE.md](ARCHITECTURE.md) · [DATABASE.md](DATABASE.md) · [CELERY_REDIS.md](CELERY_REDIS.md) · [AI_LAYER.md](AI_LAYER.md) · [`docs/API_CONTRACT.md`](../../docs/API_CONTRACT.md) · spec §6 (tables), §7.2 (endpoints).

---

## Overview

| Phase | What | Milestone | Who can integrate after it |
|---|---|---|---|
| 0 | Accounts and infrastructure | | |
| 1 | Project skeleton | CI green, `/health` locally | |
| 2 | **Database live** | **M1: full schema + seed data on Supabase** | anyone can browse the data (dashboard / pgAdmin) |
| 3 | Auth + security core | | |
| 4 | **First deploy** | **M2: API live over HTTPS** | Flutter: real login, real tokens |
| 5 | All CRUD endpoints on seeded data + AI stubs | **M3: every §7.2 endpoint live** | Flutter: every screen on the real API. Phone relay: real sync |
| 6 | Celery + Redis foundation | M4: workers running in production | |
| 7 | Ambient memory pipeline | M5: real transcripts in the journal | |
| 8 | Media AI + face enrollment | M6: real review, OCR, embeddings, clustering | glasses: real enrolled faces |
| 9 | Phase 2 AI: RAG, summaries, push alerts | M7: AI stubs replaced | |
| 10 | Hardening for the demo | M8: demo-ready | |
| R | **RAG track, in parallel: Abdelrahman** | feeds 5.9, 9.1, 9.2 | |

Every phase ends with: PR → CI green → merge → deploy (from Phase 4 on) → tell the team what's new.

---

## Track R — RAG (Abdelrahman, in parallel from day 1)

Abdelrahman builds the RAG pipeline **alongside** Phases 0–8. It needs no backend skeleton: everything runs on synthetic data and a local `pgvector/pgvector:pg17` database. His work plugs into the plan at **5.9** (stub fixtures), **9.1** (real `/assist`) and **9.2** (daily summaries).

| Step | Output | Plugs into |
|---|---|---|
| R1 Evaluation set | `ml/rag_eval/`: a few synthetic journal days based on the UI board's Fatma data + **50–100 questions** in Egyptian Arabic and English, each with its expected answer and the event IDs that prove it. Includes questions that have **no** answer | measures R4, R5 |
| R2 Event → sentence rendering | `backend-ai/app/ai/rag/render.py`: one template per `event_type` (spec §6), Arabic + English, with unit tests | 7.3 |
| R3 Time + person understanding | "الصبح", "امبارح", "الأسبوع اللي فات" → a time window in the patient's timezone. "أحمد" / "ابني" → a person | R4 |
| R4 Hybrid retriever | `rag/retriever.py`: SQL time + person filter first, then pgvector ranking (spec D22). Report retrieval quality on R1 | 9.1 |
| R5 Answer prompt | `ai/prompts/assist_answer.v1.txt` + `rag/answer.py`: short answers for a person with dementia, **diacritized Arabic** for Piper, answers only from retrieved events, "I don't remember that happening" when nothing matches, returns `source_event_ids` | 9.1 |
| R6 `/assist` fixtures | the fixed answers the stub returns, in the exact spec §7.2 shape | 5.9 |
| R7 Daily summary | `ai/prompts/daily_summary.v1.txt` + adherence / visits / talk-time calculations | 9.2 |

**Rules for this track:**
- Works only in `backend-ai/app/ai/rag/`, `backend-ai/app/ai/prompts/` and `ml/rag_eval/`. Own branch and PRs (`docs/TEAM_WORKFLOW.md`).
- Follows [AI_LAYER.md](AI_LAYER.md): versioned prompt files, a timeout on every LLM call, LLM mocked with `respx` in tests, nothing private in logs.
- **Synthetic data only.** No real people's conversations.
- Asks the lead before any decision the spec doesn't make. See the R questions at the end of this plan.

**Done when:** R4 + R5 reach the agreed score on the R1 evaluation set, and `/assist` (9.1) and summaries (9.2) use them on the live API.

---

## Phase 0 — Accounts and infrastructure (once)

> **Status: done (11 Oct 2026).** Supabase: PostgreSQL 17.11, pgvector 0.8.2 available, reached through the IPv4 session pooler `aws-1-eu-central-1.pooler.supabase.com`. AWS (eu-central-1): EC2 `remori-api` (`i-01317efa4cbe06ea0`, t3.small, Ubuntu 24.04, Docker 29 + Compose) at Elastic IP **18.184.27.33**; security group `remori-api-sg` (22 from the lead's IP, 80/443 open); SSH key `remori-ec2` (`~/.ssh/remori-ec2.pem`); S3 bucket `remori-media-090413359449` (private, encrypted); IAM role `remori-ec2-role` (that bucket only) attached. Domain **remori-ai.duckdns.org** → 18.184.27.33. **Still manual:** turning off Supabase's Data API in the dashboard.

| Step | Details |
|---|---|
| 0.1 Supabase project | EU (Frankfurt) region. **Turn off the Data API.** Save the direct / session-pooler connection strings in your password manager, never in git |
| 0.2 AWS EC2 | Ubuntu, a free-tier-eligible size. Elastic IP attached. Security group: 22 from **your IP only**, 80 + 443 from anywhere. Install Docker + the Compose plugin |
| 0.3 DuckDNS | Create e.g. `remori-ai.duckdns.org` → the Elastic IP |
| 0.4 S3 bucket | Private (block all public access). Needed from Phase 5 for photos |
| 0.5 IAM role | Attach a role to the EC2 instance with access to that bucket only, so there are no AWS keys in `.env` |
| 0.6 Local tools | Python 3.12, Docker Desktop, pgAdmin, ruff, the AWS CLI (already installed) |

**Done when:** you can SSH into EC2, the DuckDNS name resolves to it, and you can open the Supabase dashboard.

> Small instances have about 1 GB RAM. That's enough for Phase 4–5 (API + nginx). Before Phase 6 adds Redis and workers, check memory and add a swap file or resize. That's a lead decision at that point.

---

## Phase 1 — Project skeleton

*Course: setup, virtual env, FastAPI basics, routers (0:00–2:21, 6:17).*

| Step | Details |
|---|---|
| 1.1 Folder layout | exactly [ARCHITECTURE.md](ARCHITECTURE.md) §1: `app/main.py`, `config.py`, `database.py`, `routers/`, `services/`, `errors.py`… |
| 1.2 `requirements.txt` | FastAPI, uvicorn, SQLAlchemy 2.0, psycopg, Alembic, pydantic-settings, PyJWT, pwdlib, pgvector, boto3, python-multipart, pytest, httpx, ruff |
| 1.3 `config.py` | pydantic-settings, `.env.example` committed, `.env` gitignored |
| 1.4 `GET /health` | returns `{"status": "ok"}` and checks the DB connection |
| 1.5 `docker-compose.dev.yml` | local Postgres (`pgvector/pgvector:pg17`) + the API with hot reload |
| 1.6 `Dockerfile` | one image (API now, workers later) |
| 1.7 First test | `tests/test_health.py`. CI's backend job now really runs |

**Done when:** `docker compose -f docker-compose.dev.yml up` → `http://localhost:8000/docs` works, and the PR is green.

---

## Phase 2 — Database live (M1)

*Course: databases, SQLAlchemy, Alembic (2:24–5:28, 10:30–11:14) + DATABASE.md.*

The schema in spec §6 is fully designed, so create it **in one go** instead of table by table.

| Step | Details |
|---|---|
| 2.1 `models.py` | all spec §6 tables, SQLAlchemy 2.0 style: UUID PKs, ENUMs, JSONB, `TIMESTAMPTZ`, `VECTOR(512)` / `VECTOR(1536)`, `updated_at` / `deleted_at` |
| 2.2 Migration 001 | `CREATE EXTENSION vector` + every table + indexes (HNSW for the vectors) + **RLS enabled on every table** (DATABASE.md §2). **Read it line by line** before committing |
| 2.3 Apply locally | `alembic upgrade head` against Docker Postgres. Check in pgAdmin |
| 2.4 Seed script | `scripts/seed.py`: the UI board's sample data (Fatma, Ahmed + Mona as caregivers, Ahmed / Sara / Dr. Hany / Mona as people, the 3 reminders with today's logs, 3 places, device RMR-0007, a day of journal events, 1 receipt, 1 unknown-face cluster) + **test accounts**. Use **fixed UUIDs**, so Flutter mocks and the real API share the same IDs |
| 2.5 Apply to Supabase | `alembic upgrade head` with the Supabase URL, then run the seed |
| 2.6 Database users | in Supabase's SQL editor: `remori_app` (read/write, no DDL) and `remori_readonly` (SELECT). The app uses `remori_app` |
| 2.7 Team access | give teammates the readonly connection string or dashboard access |
| 2.8 CI database | add a `pgvector/pgvector:pg17` **service container** to the CI backend job, as in the course's `build-deploy.yml`, plus a test-database fixture in `tests/conftest.py` (course: `tests/database.py` + `conftest.py`), so tests run against a real Postgres |

**Done when (M1):** every §6 table exists on Supabase with seed data, you can see it in pgAdmin and the dashboard, and the app connects as `remori_app`.

---

## Phase 3 — Auth and security core

*Course: users, hashing, JWT, protected routes, relationships (5:50–8:38) + study guide Parts 5 and 7.*

| Step | Endpoints / pieces |
|---|---|
| 3.1 Errors | `errors.py` domain exceptions + handlers → spec §7.5 shape |
| 3.2 Caregiver auth | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`: pwdlib + PyJWT, 15-min access tokens, hashed refresh tokens |
| 3.3 Patients | `POST /patients` (+ profile + consent records), `POST /patients/{id}/caregivers` |
| 3.4 Devices | `POST /devices/pair` → device token (hashed in `devices.token_hash`), `POST /devices/{id}/heartbeat` |
| 3.5 Authorization | `oauth2.py`: `get_current_user`, `get_current_device`, **`require_patient_link`** |
| 3.6 Tests | login and refresh flows, expired token, **caregiver A gets 404 on patient B** |

**Done when:** a seeded caregiver can log in, create a patient and pair a device, and the IDOR test passes.

---

## Phase 4 — First deploy (M2)

*Course: Ubuntu VM deployment (12:05–13:23: gunicorn, nginx, domain, SSL, firewall) + Docker (13:26–14:08). Same production pieces as the course repo (`nginx`, `gunicorn.service`), except the app runs in Docker instead of a systemd venv.*

| Step | Details |
|---|---|
| 4.1 Firewall (ufw) | `sudo ufw allow OpenSSH` → `sudo ufw allow 'Nginx Full'` → `sudo ufw enable`. The AWS security group stays as a second layer |
| 4.2 nginx | `sudo apt install nginx`. Site config = the course's `nginx` file with `server_name remori-ai.duckdns.org;` and `proxy_pass http://127.0.0.1:8000;`, keeping the course's forwarded headers (`X-Real-IP`, `X-Forwarded-For`, `Host`, upgrade) |
| 4.3 HTTPS (certbot) | `sudo apt install certbot python3-certbot-nginx` → `sudo certbot --nginx -d remori-ai.duckdns.org` (also sets HTTP → HTTPS redirect). Renewal runs automatically; check with `sudo certbot renew --dry-run` |
| 4.4 `docker-compose.yml` (production) | `api` built from the Dockerfile, which runs **gunicorn with 2 uvicorn workers** (the course's `gunicorn.service` command). Ports `"127.0.0.1:8000:8000"` only: Docker bypasses ufw for published ports, so the app must never listen publicly. `restart: unless-stopped` (the job systemd does in the course). `env_file: .env` |
| 4.5 Server `.env` | Supabase session-pooler URL (as `remori_app`, `sslmode=require`), JWT secret, S3 bucket name. Created by hand on the server, never committed (the course's `EnvironmentFile`) |
| 4.6 Deploy procedure | `ssh` → `cd ~/remori` → `git pull` → `docker compose up -d --build` → `alembic upgrade head` (inside the api container) → smoke test. Document it in `backend-ai/README.md`. Manual for now, like the course before its CI deploy job |
| 4.7 Smoke test | `https://remori-ai.duckdns.org/health` and `/docs` over HTTPS, `http://` redirects to `https://`, port 8000 is **not** reachable from outside, plus a login with a seeded account |
| 4.8 Hand-over to Flutter | base URL `https://remori-ai.duckdns.org/api/v1`, test accounts, the seed's fixed IDs |

**Done when (M2):** the API answers over HTTPS through nginx. Flutter switches its auth repository to real.

---

## Phase 5 — All CRUD endpoints on seeded data + AI stubs (M3)

Build in the order the Flutter screens need them (spec §12: Caregiver Mode first). **Deploy after every merged group**, so Flutter integrates screen by screen.

| Group | Endpoints (spec §7.2) | Unlocks screens |
|---|---|---|
| 5.1 People | `GET/POST /patients/{id}/people` (multipart photos → S3), `PATCH/DELETE /people/{id}`, `POST /people/{id}/photos` | C3, C4, C5, D6 |
| 5.2 Reminders | reminders CRUD, `POST /patients/{id}/reminder-logs:batch` | C8, C9, P2, P3 |
| 5.3 Places | places CRUD | C10, C11 |
| 5.4 Sync | `GET /patients/{id}/sync?since=` (delta pull with `updated_at` / `deleted_at`) | phone relay, offline mode |
| 5.5 Journal + events | `POST /patients/{id}/events:batch` (idempotent), `GET /patients/{id}/journal?date=` | C12, P4, D4 |
| 5.6 Uploads + media | `POST /patients/{id}/uploads` (presigned URL), `POST /uploads/{id}/complete`, `GET /patients/{id}/media/{id}`, pin, delete | C13, P5 |
| 5.7 Documents | `GET /patients/{id}/documents` (seeded documents) | C14, C15 |
| 5.8 The rest | alerts + read, push token, mind-game sessions, unknown-faces list / promote / dismiss | C1, C2, C6, C7, P7–P9 |
| 5.9 AI stubs | `POST /patients/{id}/assist` → fixed fixture answers (Abdelrahman's R6). `GET /patients/{id}/daily-summary` → seeded summary | P6, C17 |

**Rules while stubbing AI:**
- Stubs return **exactly** the spec §7.2 shape, through the same Pydantic schemas the real version will use.
- Enrollment stores the person and photos. Face embeddings are filled in Phase 8 (a stub can't produce real ones).
- `uploads/{id}/complete` saves the record. The AI job it will trigger arrives in Phases 7–8.

**Done when (M3):** every §7.2 endpoint answers on the deployed API, and Flutter can run every screen against it.

---

## Phase 6 — Celery + Redis foundation (M4)

**Before starting:** finish the study guide Part B and its practice project. Follow [CELERY_REDIS.md](CELERY_REDIS.md) exactly.

| Step | Details |
|---|---|
| 6.1 Compose | add `redis` (AOF on), `worker`, `beat` (exactly one), `flower` (internal only) |
| 6.2 `workers/celery_app.py` | the settings from CELERY_REDIS.md §3, the 3 queues, the Beat schedule |
| 6.3 First real task | `alerts.evaluate` (missed meds, device offline, low battery) on seeded data: simple, with no AI |
| 6.4 Second | `retention.expire_media` (spec §8) |
| 6.5 Tests | idempotency (run twice → one result), failure → retry → `failed` |

**Done when (M4):** workers and Beat run on EC2 and alerts appear in C2 by themselves.

---

## Phase 7 — Ambient memory pipeline (M5)

*Spec §7.3, AI_LAYER.md.*

| Step | Details |
|---|---|
| 7.1 `ai/clients/stt.py` | STT API client with timeout + `TransientError` |
| 7.2 Task `transcribe` | audio from S3 → transcript → `conversation_segment` event with `present_person_ids` → **delete the audio** |
| 7.3 `ai/clients/embeddings.py` + `ai/rag/render.py` | task `embed`: render each event to a sentence and store its embedding |
| 7.4 Wire it | `uploads/{id}/complete` for audio → enqueue `transcribe` (after commit) |

**Done when (M5):** a real recording uploaded from the phone shows up as a transcript in C12 / P4, and the audio is gone from S3.

---

## Phase 8 — Media AI + face enrollment (M6)

| Step | Details |
|---|---|
| 8.1 `ai/inference/face.py` | the server-side face embedder (model file inside backend-ai, per spec D14 compatibility with the edge). Loaded once per process |
| 8.2 Enrollment | `POST /people` now computes embeddings, rejects photos with zero or several faces (C4 error state), and backfills seeded people |
| 8.3 Task `review` | blur non-enrolled faces → `ai/clients/vision.py` → keep/discard/tags/OCR → `captured_documents` + retention (spec §7.4, §8) |
| 8.4 Task `cluster` | unknown encounters → `ai/clustering.py` → caregiver alert at 3 distinct days |

**Done when (M6):** enrolled people sync to the glasses with real embeddings, and photos and documents are reviewed for real.

---

## Phase 9 — Phase 2 AI: replace the stubs (M7)

| Step | Details |
|---|---|
| 9.1 `ai/rag/retriever.py` + `answer.py` | wire in Abdelrahman's R4 + R5: hybrid retrieval (time window + pgvector) → LLM → `POST /assist` becomes real |
| 9.2 Task `summaries.generate_due` | uses Abdelrahman's R7 prompt: nightly summaries + patterns per patient timezone → `GET /daily-summary` becomes real |
| 9.3 FCM | `integrations/fcm.py`: alerts and daily-summary pushes to caregivers |

**Done when (M7):** no AI stubs remain.

---

## Phase 10 — Hardening for the demo (M8)

- Structured logs with `request_id`, carried into tasks. No personal content in logs.
- Rate limits on AI tasks, timeouts everywhere, error alerts visible in Flower and the logs.
- IDOR tests on every patient router. Review that Supabase's Data API is off and RLS is on.
- Backups: `pg_dump` before every demo. Consider Supabase Pro for the evaluation period.
- Freeze: no schema or contract changes in the last week before the demo.

---

## Open questions to settle along the way (ask the lead)

| When | Question |
|---|---|
| Phase 0 | EC2 instance size, and whether to resize or add swap before Phase 6 |
| Phase 5.5 | Pagination for the journal and lists (not in the spec) |
| Phase 8 | How the server's face model file gets onto EC2 (in the image, or downloaded from S3 at startup) |
| Phase 4+ | When to automate deploys (currently manual by choice) |
| R, before start | Which LLM provider Abdelrahman uses for experiments, and a monthly spending cap |
| R3 | Time parsing: hand-written rules for Egyptian Arabic time phrases, or LLM extraction |
| R4, R5 | The interface. Suggested: `retrieve(patient_id, question, now, timezone) → events` and `answer(question, events, language) → {answer, language, source_event_ids}` |
| R4, R5 | The evaluation score that counts as good enough to replace the `/assist` stub |
| R → 9.1 | Whether to move real `/assist` up to right after Phase 7 (it only needs the database and event embeddings) |
