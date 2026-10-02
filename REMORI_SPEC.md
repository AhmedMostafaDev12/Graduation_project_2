# Remori — Technical Specification v1 (Pre-Development)

AI memory assistant smart glasses for Alzheimer's care. This document is the single source of truth for what we're building, how the pieces talk to each other, and who owns what. It's written to be handed to Claude Code as the first prompt for the monorepo.

Status: **pre-code, v1**. All gaps found in the v0 review ([`docs/SPEC_REVIEW.md`](docs/SPEC_REVIEW.md)) are resolved by the decision log in §0. The only open item is team assignment (§11). Diagrams: [`docs/diagrams/`](docs/diagrams/README.md).

---

## 0. Decision log

Decisions taken in the 2026-10-03 design session. **P** = product decision by the team lead. **T** = technical default (override by editing this table).

| # | Decision | By |
|---|---|---|
| D1 | **Ambient memory is the core feature.** The glasses listen all day. Speech segments (Silero VAD) are compressed and queued, then transcribed in the cloud into the journal. | P |
| D2 | **Remembering ≠ answering.** The assistant only *responds* when addressed: **button now**, wake word "يا ريموري / Remori" later. | P |
| D3 | **Transcription:** cloud STT (Whisper-large-v3-class API), batched via the phone. Nothing is transcribed on the Pi. | P |
| D4 | **Raw audio is deleted** right after successful transcription. Only transcripts are kept. | P |
| D5 | **Cloud:** small AWS footprint (FastAPI + worker + Postgres/pgvector + S3). STT, LLM and vision are external pay-per-use APIs. Nothing GPU-bound is self-hosted. | P |
| D6 | **Reminders:** the phone expands the schedule and syncs each day's occurrences to the glasses. **Both fire on their own clocks at the same time:** the phone shows a notification + the app's Reminders section, and the glasses speak it (ESP32 clock), so it's spoken even if the phone is away or asleep. Both share the same `log_id`, so a confirmation on either side ("taken" by voice, app tap, or caregiver) syncs and silences the other. | P |
| D7 | **Pi Zero 2W owns all data links** (BLE to phone, Wi-Fi bursts for video). The **ESP32-S3 is the power/IO controller**: button, battery gauge, status LED, Pi power-gating, timekeeping. Pi↔ESP32 over **UART**. | P |
| D8 | **Cross-platform app, Android relay.** One Flutter codebase for Android + iOS. Caregiver Mode is fully supported on both. Patient Mode UI runs on both, but the **glasses relay role** (background BLE, uploads, GPS) is officially supported on **Android** via a foreground service: the patient uses a dedicated Android phone. iOS relay is a stretch goal (§10). | P |
| D9 | **`where_am_i`** is answered from the **phone's GPS** + caregiver-saved places ("Home", "Ahmed's house"). Works offline. | P |
| D10 | **Retention:** photos of other people auto-expire after **30 days** unless pinned. Requested clips, documents and the patient's own moments are kept indefinitely (§8). | P |
| D11 | **Name: Remori.** | P |
| D12 | **AR overlay is a trial / stretch goal.** Voice is the guaranteed channel. | P |
| D13 | **Encounters, not per-frame recognitions.** Announce once per encounter, with a 10-min per-person cooldown (configurable). One keyframe per encounter. | T |
| D14 | **Face model pinned:** MobileFaceNet (InsightFace `w600k_mbf`, 512-d, INT8 on device). Multiple embeddings per person. One shared, versioned face pipeline used by both glasses and backend. | T |
| D15 | **Text embeddings:** OpenAI `text-embedding-3-small` (1536-d, multilingual). Changing it means re-embedding everything. | T |
| D16 | **TTS:** Piper (Arabic + English voices) on the Pi. The LLM is asked to output **diacritized** Arabic. espeak-ng is a fallback only. | T |
| D17 | **Fixed intents:** a small on-device intent classifier (log-mel + small CNN), run only on the push-to-talk utterance. Trained on team-recorded Egyptian Arabic + English samples. | T |
| D18 | **Transfer:** BLE carries JSON control, keyframes and Opus audio. **Video** goes over an on-demand Wi-Fi burst (Pi soft-AP, phone joins via `WifiNetworkSpecifier`). To be validated in the hardware spike. | T |
| D19 | **Worker:** Celery + Redis as broker (jobs, retries, routing) + Celery Beat (cron) + Flower (monitoring). Industry standard, chosen over ARQ for team familiarity and career value. **Push:** Firebase Cloud Messaging. **Phone DB:** drift. **Vector store:** pgvector only (Chroma dropped). | T |
| D20 | **Smart review and OCR are one vision-model call** (Tesseract dropped). Non-enrolled faces are blurred before sending. | T |
| D21 | **Sync:** client-generated UUIDs, idempotent batch upload, delta pull via `updated_at` / `deleted_at`. | T |
| D22 | **RAG is hybrid:** SQL time-window filter first, then pgvector similarity over rendered event sentences. | T |
| D23 | **Unknown faces** are clustered in the cloud. The caregiver is asked once a cluster is seen on **≥3 different days** (configurable). | T |
| D24 | **Privacy controls:** a visible listening LED, a "pause memory" button gesture, household consent, BLE bonding, encryption at rest on the glasses, an audit log (§9). | T |

---

## 1. Product overview

Remori helps a person living with Alzheimer's recognize the people around them, recall their day, and stay independent, without taking control away from them. Core principle: **support, don't take over**.

- **Artificial memory.** The glasses listen throughout the day (D1). What is said becomes a searchable journal: *"What did Ahmed tell me this morning?"*
- **Recognition.** Enrolled people are recognized in real time, fully offline, and announced once per encounter by voice (D13). Unknown is a valid outcome. The glasses never guess.
- **Assistant.** The patient presses the button and asks. Fixed questions (who is this, what time/day is it, did I take my medicine, where am I) are answered locally. Anything else goes through the cloud and comes back as speech on the glasses.
- **Intelligent capture.** About 1 frame/sec passes through a generous on-device gate (face, document, or salience). The cloud makes the final keep/discard/tag call. The patient can also explicitly record a short clip ("remember this").
- **Companion app (Flutter, Android + iOS).** Patient Mode: today, reminders, journal recall, mind games. Caregiver Mode: enrollment, reminders, places, monitoring, alerts, and (Phase 2) AI summaries.
- AR visual overlay is a trial only (D12).

---

## 2. Feature set

### Phase 1 — on-device MVP (offline core)
| Feature | Description |
|---|---|
| Face enrollment | Caregiver adds a person (several photos + name + relationship + consent). Or the cloud flags an unknown face recurring on ≥3 days for caregiver review and promotion (D23). |
| Real-time recognition | Detect → embed → match against the local cache → track into an **encounter**. Announce name + relationship once per encounter (D13). |
| Ambient memory capture | VAD speech segments → Opus → queued on glasses → phone → cloud STT → journal. Raw audio deleted after transcription (D1–D4). |
| Voice assistant | **Button** (wake word later) → on-device intent classifier. **Fixed intents** (`who_is_this`, `what_time_is_it`, `medication_check`, `where_am_i`, `record_this`) are answered locally. **Free-form** goes to the cloud RAG (Phase 2), answered by on-device TTS. |
| Reminders | Phone expands + syncs the day's schedule. Phone notification + app Reminders section, and the glasses speak it from their own clock. Confirmed by voice/app/caregiver on either side (D6). |
| Where am I | Phone GPS matched against caregiver-saved places, spoken on the glasses (D9). |
| Daily journal | Encounters, conversation transcripts, reminders, queries, recordings and documents in one timeline, with media inline. |
| Patient Mode (app) | Today overview, reminders, journal recall, mind games. |
| Caregiver Mode (app) | People, unknown-face review, reminders, saved places, device status, alerts, activity log, documents. |
| Offline buffering | Glasses queue → phone (drift/SQLite outbox) → cloud when online. Every tier works without the next. |
| Intelligent capture | On-device gate proposes. Cloud vision call confirms/discards/tags (D20). |
| Document capture | Receipts, bills, medication labels → structured, searchable records (vision-model OCR + field extraction). |
| User-requested recording | Double-press the button or say "record this" to capture a 10–15 s clip, kept indefinitely. |
| Privacy controls | Listening LED, long-press to pause/resume memory, encrypted storage, audit log (D24). |

### Phase 2 — cloud intelligence
| Feature | Description |
|---|---|
| RAG journal Q&A | Arabic + English, hybrid retrieval (D22), over encounters, transcripts, reminders and documents. |
| Daily summarization | LLM summary of the day per patient, generated nightly in the patient's timezone. |
| Pattern detection | Medication adherence, visit frequency, routine and conversation-volume changes. |
| Caregiver insights | Summaries and patterns in the caregiver dashboard, with a push when ready. |

### Trial / stretch — not a dependency
| Feature | Description |
|---|---|
| AR visual overlay | OLED + optical combiner showing the recognized name. Evaluated independently. |
| Wake word | "يا ريموري" / "Remori" as an alternative to the button (D2). |
| iOS relay | Patient phone relay on iPhone (background BLE, location, Wi-Fi) behind the same `RelayService` (D8). |

---

## 3. Tech stack

| Layer | Choice |
|---|---|
| Glasses compute | Raspberry Pi Zero 2W: all inference, BLE + Wi-Fi links (D7) |
| Glasses controller | ESP32-S3 (N16R8): button, battery gauge, status LED, Pi power, timekeeping. UART to Pi |
| Camera | OV5647 5 MP (CSI), sampled ~1 fps |
| Microphone | I²S MEMS mic (e.g. INMP441), 16 kHz |
| Audio out | I²S class-D amp (e.g. MAX98357A) + small speaker, or bone-conduction transducer |
| Indicators | Status LED: listening / paused / recording |
| Power | Li-Po + charger/power-path board, fuel gauge via ESP32 |
| On-device inference | TFLite / ONNX Runtime, INT8 |
| Face detection | Ultra-Light-Fast-Generic-Face-Detector |
| Face embedding | MobileFaceNet, InsightFace `w600k_mbf`, 512-d (D14) |
| Capture gate | Phase 1 heuristics (face present · text-density/edge document detector · frame-difference novelty). A quantized MobileNetV3 replaces them if time allows |
| VAD | Silero VAD |
| Intent classifier | Small log-mel CNN, push-to-talk utterance only (D17) |
| Audio codec | Opus, 16 kbps mono |
| On-device TTS | Piper (Arabic + English), espeak-ng fallback (D16) |
| Cloud STT | Whisper-large-v3-class API (D3) |
| Vision review + OCR | Vision-capable LLM API, single call (D20) |
| LLM | Low-cost tier (Haiku / 4o-mini class) for RAG + summaries |
| Text embeddings | `text-embedding-3-small`, 1536-d (D15) |
| Backend | Python 3.12, FastAPI, Pydantic v2 + pydantic-settings, SQLAlchemy 2.0 (typed `Mapped[]` style) + Alembic, PyJWT, pwdlib, httpx |
| Jobs | Celery + Redis broker, Celery Beat (cron), Flower (monitoring) (D19) |
| Backend testing | pytest, pytest-asyncio, respx (mock external AI APIs) |
| Database | PostgreSQL 16 + pgvector (only vector store) |
| Object storage | S3, private bucket, presigned URLs |
| Push | Firebase Cloud Messaging |
| Mobile app | Flutter (Dart), **Android + iOS** (relay role Android, D8), Riverpod, GoRouter, dio |
| Phone local DB | drift (SQLite) |
| Glasses↔phone | BLE (control + keyframes + audio), Wi-Fi burst (video) (D18) |
| Phone↔cloud | HTTPS over phone Wi-Fi / cellular |
| Hosting | AWS: one small EC2 (Docker: API + worker + Redis), Postgres (RDS or container), S3 |
| Repo | Single GitHub monorepo |

---

## 4. System architecture

Three tiers, each able to degrade gracefully if the next is unreachable.

```
┌──────────────────────────┐  BLE / Wi-Fi burst  ┌──────────────────────┐  HTTPS   ┌──────────────────────────┐
│ Glasses (edge)            │ ──────────────────> │ Patient's phone       │ ───────> │ Cloud (opportunistic)     │
│ recognition, VAD, intents │ <────────────────── │ phone: relay, buffer, │ <─────── │ FastAPI + Celery worker   │
│ TTS, local queue          │                     │ scheduler, GPS, UI    │          │ Postgres+pgvector, S3     │
└──────────────────────────┘                     └──────────────────────┘          │ → STT / LLM / vision APIs │
                                                                                     └──────────────────────────┘
```

- **Glasses:** never depend on a network. Recognition, fixed intents, TTS, speech segmentation and the queue all work offline. They hold media and audio until the phone acknowledges receipt.
- **Patient's phone (Android, D8):** the resilience layer and time source. It buffers everything, expands and syncs reminder schedules, supplies time and location, uploads when online, and hosts Patient Mode. A **foreground service** keeps BLE and sync alive.
- **Caregiver's phone (Android or iOS):** the same app in Caregiver Mode. It talks only to the cloud, so it has no background requirements.
- **Cloud:** enrichment and long-term memory. Transcription, smart review, OCR, RAG, summaries, alerts, retention.

**Degradation matrix**

| Situation | What still works |
|---|---|
| Glasses alone (phone away) | Recognition + announcements, **reminders spoken from the last synced schedule**, `who_is_this`, `what_time_is_it` (ESP32 clock), `medication_check`, recording. Speech and events are queued. |
| Glasses + phone, no internet | All of the above + phone notifications, `where_am_i`, journal of already-synced data. Uploads queue on the phone. |
| All online | Everything, including free-form questions, transcripts in the journal, summaries and alerts. |

---

## 5. Repository structure

```
graduation-project/          # "remori" monorepo
├── flutter/                 # Patient + Caregiver app (Android + iOS; relay on Android)
├── backend-ai/              # FastAPI, Postgres/Alembic, Celery worker + Beat, RAG, AI API clients
├── ml/                      # Shared face pipeline package, intent classifier, capture gate,
│                            # training / quantization / evaluation notebooks
├── hardware/
│   ├── pi/                  # capture/, inference/, audio/, link/ (BLE + Wi-Fi), store/
│   └── esp32/               # button, battery, LED, UART protocol, timekeeping
└── docs/                    # this spec's companions: review, diagrams, contracts
```

The face pipeline in `ml/` (detector + alignment + MobileFaceNet + preprocessing, versioned) is imported by **both** `hardware/pi` and `backend-ai`. A parity test asserts that both produce the same embedding for the same image (D14).

### 5.1 `backend-ai` architecture and conventions

Study companion: [`docs/BACKEND_STUDY_GUIDE.md`](docs/BACKEND_STUDY_GUIDE.md).

**Layered architecture** (routers → services → models), not logic inside routes. API routes and Celery tasks call the **same services**.

```
backend-ai/
├── app/
│   ├── main.py          # app factory, routers, exception handlers, middleware
│   ├── api/v1/          # routers: thin, HTTP only (parse → call service → respond)
│   ├── services/        # business logic + transactions, shared by routes and tasks (sync SQLAlchemy)
│   ├── repositories/    # optional: shared complex queries (pgvector search, journal windows)
│   ├── models/          # SQLAlchemy 2.0 ORM tables (§6)
│   ├── schemas/         # Pydantic v2 request/response models
│   ├── workers/         # celery_app.py (config, queues, beat_schedule) + tasks/
│   ├── clients/         # wrappers for STT, LLM, vision, embeddings, S3, FCM
│   ├── core/            # config (pydantic-settings), db session, security, errors, logging
│   └── deps.py          # get_db, get_current_user, get_device, require_patient_link
├── alembic/             # migrations (first one: CREATE EXTENSION vector)
├── tests/               # unit (services), api (TestClient), workers (idempotency)
├── Dockerfile           # one image; `api` and `worker` differ only by command
└── docker-compose.yml   # api · worker · beat · flower · redis (AOF on) · postgres (pgvector image)
```

| Layer | Rule |
|---|---|
| Routers | No SQL and no business rules. Validate with schemas, call one service, return a schema |
| Services | Own the transaction. Raise **domain exceptions** (`PersonNotFound`, `NotLinkedToPatient`), never `HTTPException` |
| Tasks | Thin like routers: receive IDs only (never ORM objects or bytes), call services. No logic of their own |
| Clients | Every external call has a timeout. Transient failures (timeout, 429, 5xx) raise a `TransientError` that Celery retries with backoff. Per-provider load is capped with task `rate_limit` and worker concurrency |
| Models | Loaded once per process (`lifespan` for the API, the `worker_process_init` signal for Celery), e.g. the ONNX face pipeline |

**Authorization.** Every `/patients/{id}/…` router includes the `require_patient_link` dependency (caregiver link with sufficient `permission`, or the device token of that patient). A test asserts that caregiver A gets **404** on patient B's resources.

**Errors.** Domain exceptions are mapped **once** in `main.py` to the §7.5 shape `{"error": {"code", "message"}}`. Status mapping: not found → 404, not linked → 404 (don't reveal existence), validation → 422, conflict → 409.

**Background jobs (Celery + Redis).**
- **Enqueue only after commit.** A task is sent after the DB transaction commits, otherwise the worker can run before the row exists.
- **Delivery is at-least-once, so every task is idempotent:** check state before acting, use deterministic IDs + upserts, and do side effects (S3 delete, FCM push) only after the state commit.
- **Duplicates:** Celery doesn't deduplicate by ID. Tasks use a deterministic `task_id` (`transcribe:{segment_id}`, `review:{media_id}`, `cluster:{encounter_id}`, `summary:{patient_id}:{date}`) for tracing, plus a short Redis lock (`SET NX` with TTL on the same key) so two copies never run at once. Idempotency stays the real guarantee.
- **Reliability settings:** `task_acks_late=True`, `task_reject_on_worker_lost=True`, `worker_prefetch_multiplier=1`. Redis broker `visibility_timeout` > the longest task. Redis persistence (AOF) on.
- **Retries:** `autoretry_for=(TransientError,)`, `retry_backoff=True`, `retry_jitter=True`, `max_retries=3`. When retries are exhausted, the task sets the row's `status = failed` and logs at error level.
- **Results:** `task_ignore_result=True`. State lives in Postgres, so no result backend is needed.
- **Queues:** `ai_io` (STT, vision, LLM, embeddings: I/O-bound, threads pool), `cpu` (face pipeline, clustering: prefork), `default` (retention, alerts). Phase 1 runs one worker consuming all three, and they're split into separate workers if load requires.
- **Celery Beat** (separate process) schedules: retention expiry (hourly), alert rules (every 5 min), daily summaries (every 30 min; each patient's summary is generated once their local time passes 23:30). Exactly **one** Beat instance runs.
- **Flower** dashboard for monitoring (internal only, behind auth).
- FastAPI `BackgroundTasks` is **not** used for anything that must survive a restart.

**Idempotent writes.** Batch endpoints use `INSERT … ON CONFLICT (id) DO NOTHING` and return `accepted` + `duplicates`.

**Logging.** Structured JSON logs. Every request gets a `request_id` (middleware), which is passed into enqueued jobs so one upload can be traced API → Redis → worker. No transcript text, names or embeddings in logs.

**Testing.** pytest with a real Postgres + pgvector test database (Docker). External AI APIs are mocked with `respx`. Every task has a "run it twice → one result" test. Tasks are unit-tested by calling them directly (eager mode), and there's one integration test with a real worker.

**Config.** `pydantic-settings` with `.env` locally, GitHub Secrets in CI, and an **IAM role** on EC2 for S3 (no AWS keys in env files).

---

## 6. Database models (PostgreSQL)

Conventions: every synced table has `updated_at` and `deleted_at` (soft delete) for delta sync (D21). IDs for anything created on the glasses or phone are **client-generated UUIDs**, and inserts are idempotent. All timestamps are UTC `TIMESTAMPTZ`.

```sql
-- ===== Accounts =====
users (
  id UUID PK,
  role ENUM('patient','caregiver'),
  full_name TEXT,
  email TEXT UNIQUE NULLABLE,          -- patients may have none
  phone TEXT,
  password_hash TEXT NULLABLE,         -- caregivers only; patients auth via device token
  created_at, updated_at, deleted_at TIMESTAMPTZ
)

patient_profiles (
  user_id UUID PK FK -> users,
  preferred_language ENUM('ar','en'),
  timezone TEXT,                       -- e.g. 'Africa/Cairo'
  date_of_birth DATE NULLABLE,
  memory_capture_enabled BOOLEAN,      -- caregiver master switch for ambient audio
  updated_at TIMESTAMPTZ
)

caregiver_patient_links (
  id UUID PK,
  caregiver_id UUID FK -> users,
  patient_id UUID FK -> users,
  relationship TEXT,
  is_primary BOOLEAN,
  permission ENUM('viewer','manager'),
  created_at TIMESTAMPTZ,
  UNIQUE (caregiver_id, patient_id)
)

refresh_tokens (id UUID PK, user_id FK -> users, token_hash TEXT, expires_at, revoked_at NULLABLE)
push_tokens    (id UUID PK, user_id FK -> users, fcm_token TEXT, updated_at)

devices (
  id UUID PK,
  patient_id UUID FK -> users,
  serial_number TEXT UNIQUE,
  token_hash TEXT,                     -- device credential (patient auto-login + glasses identity)
  firmware_version TEXT,
  battery_level_pct INT,
  last_seen_at TIMESTAMPTZ,            -- from phone heartbeat
  paired_at TIMESTAMPTZ
)

-- ===== People =====
enrolled_people (
  id UUID PK,
  patient_id UUID FK -> users,
  name TEXT,
  relationship TEXT,
  added_by ENUM('caregiver_manual','promoted_from_unknown'),
  consent_record_id UUID FK -> consent_records NULLABLE,
  status ENUM('active','archived'),
  created_at, updated_at, deleted_at TIMESTAMPTZ
)

face_embeddings (                      -- several per person (D14)
  id UUID PK,
  person_id UUID FK -> enrolled_people,
  embedding VECTOR(512),
  model_version TEXT,                  -- e.g. 'w600k_mbf@1.0'
  source_media_id UUID FK -> media_assets NULLABLE,
  created_at TIMESTAMPTZ
)

unknown_face_clusters (                -- strangers are kept apart from family (D23)
  id UUID PK,
  patient_id UUID FK -> users,
  centroid VECTOR(512),
  sighting_count INT,
  distinct_days INT,
  first_seen_at, last_seen_at TIMESTAMPTZ,
  sample_media_id UUID FK -> media_assets NULLABLE,
  status ENUM('open','awaiting_caregiver','promoted','dismissed'),
  promoted_person_id UUID FK -> enrolled_people NULLABLE
)

encounters (                           -- one per "person in view" period, not per frame (D13)
  id UUID PK,                          -- generated on glasses
  patient_id UUID FK -> users,
  device_id UUID FK -> devices,
  person_id UUID FK -> enrolled_people NULLABLE,
  cluster_id UUID FK -> unknown_face_clusters NULLABLE,
  started_at, ended_at TIMESTAMPTZ,
  best_confidence REAL,
  announced BOOLEAN
)

-- ===== Places (D9) =====
places (
  id UUID PK,
  patient_id UUID FK -> users,
  name TEXT,                           -- "Home", "بيت أحمد"
  latitude DOUBLE PRECISION, longitude DOUBLE PRECISION,
  radius_m INT,
  created_by UUID FK -> users,
  updated_at, deleted_at TIMESTAMPTZ
)

-- ===== Journal =====
events (
  id UUID PK,                          -- client-generated, idempotent
  patient_id UUID FK -> users,
  device_id UUID FK -> devices NULLABLE,
  source ENUM('glasses','app','server'),
  event_type ENUM('encounter','conversation_segment','voice_query','reminder',
                  'mind_game_session','manual_note','user_requested_recording',
                  'document_captured','notable_moment_captured','memory_paused','memory_resumed'),
  encounter_id UUID FK -> encounters NULLABLE,
  person_id UUID FK -> enrolled_people NULLABLE,
  reminder_log_id UUID FK -> reminder_logs NULLABLE,
  mind_game_session_id UUID FK -> mind_game_sessions NULLABLE,
  occurred_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ NULLABLE,       -- for spans (encounters, conversation segments)
  transcript_text TEXT NULLABLE,       -- conversation_segment / voice_query
  language ENUM('ar','en','mixed') NULLABLE,
  rendered_text TEXT NULLABLE,         -- one-sentence rendering for RAG (D22)
  embedding VECTOR(1536) NULLABLE,     -- of rendered_text (D15)
  metadata JSONB,                      -- e.g. {"present_person_ids":[...], "place_id": "..."}
  created_at, synced_at, updated_at, deleted_at TIMESTAMPTZ
)

audio_segments (                       -- transient: deleted after transcription (D4)
  id UUID PK,                          -- generated on glasses
  patient_id UUID FK -> users,
  device_id UUID FK -> devices,
  started_at, ended_at TIMESTAMPTZ,
  storage_key TEXT NULLABLE,           -- S3 key; NULL once deleted
  status ENUM('uploaded','transcribing','transcribed','failed','deleted'),
  event_id UUID FK -> events NULLABLE, -- the resulting conversation_segment
  attempts INT,
  created_at TIMESTAMPTZ
)

media_assets (
  id UUID PK,                          -- client-generated
  patient_id UUID FK -> users,
  event_id UUID FK -> events,          -- media belongs to an event (one event : many media)
  asset_type ENUM('image','video'),
  storage_key TEXT,                    -- private S3 key, never a public URL
  trigger ENUM('encounter_keyframe','document_signal','salient_frame','user_requested'),
  status ENUM('pending_review','confirmed','discarded'),
  ai_tags JSONB NULLABLE,              -- open-ended {"category":"notable_moment","reason":"..."}
  contains_other_people BOOLEAN NULLABLE,
  duration_seconds INT NULLABLE,
  retention_policy ENUM('auto_expire','keep_indefinitely') NULLABLE,  -- set at review (§8)
  expires_at TIMESTAMPTZ NULLABLE,
  pinned_by UUID FK -> users NULLABLE,
  reviewed_at, created_at, deleted_at TIMESTAMPTZ
)

captured_documents (
  id UUID PK,
  event_id UUID FK -> events,
  media_asset_id UUID FK -> media_assets,
  document_type ENUM('receipt','bill','medication_label','other'),
  ocr_text TEXT,
  extracted_fields JSONB,
  created_at TIMESTAMPTZ
)

-- ===== Reminders (D6) =====
reminders (
  id UUID PK,
  patient_id UUID FK -> users,
  title TEXT,
  spoken_text TEXT NULLABLE,           -- what the glasses say; defaults to title
  type ENUM('medication','appointment','task'),
  rrule TEXT,
  dtstart TIMESTAMPTZ,
  timezone TEXT,
  active BOOLEAN,
  created_by UUID FK -> users,
  updated_at, deleted_at TIMESTAMPTZ
)

reminder_logs (
  id UUID PK,                          -- client-generated on the phone
  reminder_id UUID FK -> reminders,
  scheduled_at TIMESTAMPTZ,
  status ENUM('pending','completed','snoozed','missed'),
  snoozed_until TIMESTAMPTZ NULLABLE,
  completed_at TIMESTAMPTZ NULLABLE,
  confirmed_via ENUM('voice','app','caregiver') NULLABLE,
  updated_at TIMESTAMPTZ
)

-- ===== Activity / Phase 2 =====
mind_game_sessions (id UUID PK, patient_id FK -> users, game_type TEXT, score INT,
                    duration_seconds INT, completed_at TIMESTAMPTZ)

daily_summaries (
  id UUID PK,
  patient_id UUID FK -> users,
  summary_date DATE,
  summary_text TEXT,
  patterns JSONB,                      -- {"medication_adherence_pct":92,"visit_count":3,"talk_minutes":140}
  generated_at TIMESTAMPTZ,
  UNIQUE (patient_id, summary_date)
)

caregiver_alerts (
  id UUID PK,
  caregiver_id UUID FK -> users,
  patient_id UUID FK -> users,
  alert_type ENUM('missed_medication','unknown_person_flagged','low_battery',
                  'device_offline','daily_summary_ready'),
  message TEXT,
  read_at TIMESTAMPTZ NULLABLE,
  created_at TIMESTAMPTZ
)

-- ===== Privacy (D24) =====
consent_records (
  id UUID PK,
  patient_id UUID FK -> users,
  subject_person_id UUID FK -> enrolled_people NULLABLE,
  consent_type ENUM('face_enrollment','ambient_audio_household','cloud_processing','media_retention'),
  given_by UUID FK -> users,
  given_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ NULLABLE
)

audit_log (
  id UUID PK,
  actor_user_id UUID FK -> users,
  action TEXT,                         -- 'view_media','delete_media','enroll','export',...
  entity_type TEXT, entity_id UUID,
  at TIMESTAMPTZ
)
```

**Where data lives**

| Data | Cloud (truth) | Phone (drift) | Glasses |
|---|---|---|---|
| People + embeddings | ✅ | cache | cache (id, name, relationship, embeddings) |
| Encounters, events | ✅ | outbox + journal cache | queue until acked |
| Audio segments | until transcribed | queue | queue until acked |
| Media | metadata + S3 | pending uploads | bytes until acked |
| Reminders, logs | ✅ | ✅ scheduler | today's schedule + statuses |
| Places | ✅ | ✅ (GPS matching) | – |

---

## 7. Service contracts

### 7.1 Glasses ↔ Phone (BLE GATT + Wi-Fi burst)

**Transport.** One Remori GATT service on the Pi with two characteristics:
- `control`: UTF-8 JSON messages (write + notify), ≤ 512 B each, with a `type` field.
- `bulk`: binary chunks (notify) for keyframes and audio, requested by reference and acknowledged.

The link uses LE Secure Connections bonding. **Video** goes over a Wi-Fi burst: the glasses start a soft-AP, send `wifi_ready`, and the phone joins via `WifiNetworkSpecifier` and pulls over HTTP (D18).
**Delivery rule:** the glasses delete a queued item only after the phone's `ack`. Every item carries a client-generated UUID, so redelivery is harmless.

```jsonc
// ---------- session ----------
// G->P on connect
{ "type": "hello", "device_serial": "RMR-0007", "firmware_version": "0.3.1", "protocol_version": 1,
  "queue": { "events": 12, "audio_segments": 40, "media": 3 } }
// P->G right after hello (Pi has no RTC; ESP32 keeps time between syncs)
{ "type": "time_sync", "utc": "2026-10-01T09:00:00Z", "timezone": "Africa/Cairo" }
// G->P every 60 s
{ "type": "telemetry", "battery_pct": 76, "temp_c": 61, "memory_paused": false, "storage_free_mb": 2100 }

// ---------- vision ----------
// G->P when an encounter closes (person left view + grace period)
{ "type": "encounter", "id": "uuid", "person_id": "uuid-or-null",
  "started_at": "...", "ended_at": "...", "best_confidence": 0.94, "announced": true,
  "keyframe_ref": "img-456",
  "unknown_embedding": "base64-float16-or-null" }   // only when person_id is null
{ "type": "document_detected", "id": "uuid", "suspected_type": "receipt|bill|medication_label|other",
  "media_ref": "img-458", "at": "..." }
{ "type": "salient_frame_detected", "id": "uuid", "salience_score": 0.78, "media_ref": "img-459", "at": "..." }

// ---------- ambient memory (D1) ----------
{ "type": "audio_segment", "id": "uuid", "started_at": "...", "ended_at": "...",
  "codec": "opus", "bytes": 18432, "audio_ref": "aud-221" }
{ "type": "memory_state", "paused": true, "at": "..." }          // long-press toggled

// ---------- assistant ----------
// G->P fixed intent, already answered locally (journal only)
{ "type": "voice_query", "id": "uuid", "intent": "who_is_this|what_time_is_it|medication_check|record_this",
  "answered_locally": true, "at": "..." }
// G->P the glasses need the phone to answer (where_am_i, or free-form)
{ "type": "assist_request", "id": "uuid", "intent": "where_am_i|free_form",
  "audio_ref": "aud-222-or-null", "at": "..." }
// P->G answer to assist_request or reminder text, spoken by on-device TTS
{ "type": "speak", "request_id": "uuid-or-null", "text": "انت في البيت.", "language": "ar", "priority": "normal|high" }
// If no speak arrives within 20 s (free_form) or 5 s (where_am_i), the glasses speak a fallback.

// G->P patient pressed record (double-press) or said "record this"
{ "type": "user_requested_recording", "id": "uuid", "trigger_source": "voice|button",
  "duration_seconds": 12, "video_ref": "vid-789", "at": "..." }
{ "type": "wifi_ready", "ssid": "REMORI-0007", "psk": "one-time-secret", "host": "192.168.4.1" }

// ---------- reminders (D6) ----------
// P->G the next 48 h of occurrences (sent on connect and whenever anything changes).
// The glasses fire these THEMSELVES from the ESP32 clock: no phone needed at fire time.
{ "type": "sync_reminders", "horizon_until": "2026-10-03T00:00:00Z",
  "items": [ { "log_id": "uuid", "spoken_text": "ميعاد دواء الضغط", "type": "medication",
               "scheduled_at": "...", "status": "pending", "snoozed_until": null } ] }
// G->P every state change the glasses make (spoken, confirmed by voice, snoozed, missed after grace)
{ "type": "reminder_state", "log_id": "uuid", "status": "pending|completed|snoozed|missed",
  "via": "voice|null", "snoozed_until": "...|null", "at": "..." }
// P->G a confirmation/snooze made on the phone or by the caregiver, so the glasses stop prompting
{ "type": "reminder_update", "log_id": "uuid", "status": "completed|snoozed",
  "snoozed_until": "...|null", "at": "..." }

// ---------- people cache ----------
// P->G delta, embeddings as base64 float16
{ "type": "sync_people", "upserts": [ { "id": "...", "name": "...", "relationship": "...",
  "embeddings": ["base64...", "base64..."] } ], "deletes": ["uuid"] }

// ---------- transfer ----------
{ "type": "get", "ref": "img-456", "offset": 0 }   // P->G, bytes arrive on `bulk`
{ "type": "ack", "ids": ["uuid", "uuid"], "refs": ["img-456", "aud-221"] }  // P->G, glasses may delete
```

**Button gestures (ESP32 → Pi over UART):** single press = ask (listen for one utterance), double press = record clip, long press 3 s = pause/resume memory capture. A pause auto-resumes after 2 h (configurable), so a forgotten pause doesn't silently lose a day. LED: soft glow = capturing memory, off = paused, blinking = recording clip.

**Reminder timing defaults:** snooze = 15 min. Grace period before `missed` = 60 min. After speaking a reminder, the glasses listen for a spoken reply ("خدته" / "بعدين") for 10 s without a button press, and repeat the reminder once after 5 min if there was no reply.

**Reminder merge rule (phone ↔ glasses ↔ cloud):** the phone and glasses each fire the same `log_id` independently. When states disagree, **`completed` always wins**. Otherwise the state with the latest `at` wins. `missed` is set by whichever side reaches the grace period first, and a later `completed` still overrides it (late confirmation).

**Glasses-side queue limits:** if storage falls below 500 MB, evict in this order: salient frames → document frames → encounter keyframes (event metadata is kept) → oldest audio. User-requested clips are never evicted automatically.

### 7.2 Phone ↔ Backend (REST, FastAPI)

Base `/api/v1`. Auth: JWT access (15 min) + refresh token for caregivers. A device token for the patient's phone, which acts on behalf of its patient. **Every `/patients/{id}/...` route checks that the caller is linked to that patient** (caregiver link, or the device token's patient).

| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/register` | Caregiver sign-up |
| POST | `/auth/login` · `/auth/refresh` · `/auth/logout` | Session |
| POST | `/patients` | Caregiver creates a patient (+ profile) |
| POST | `/patients/{id}/caregivers` | Invite / link another caregiver |
| POST | `/devices/pair` | Pair glasses (serial from QR) to a patient → device token |
| POST | `/devices/{id}/heartbeat` | Battery, firmware, last seen (from phone) |
| GET | `/patients/{id}/sync?since=` | **Delta pull**: people, embeddings, reminders, places, settings changed since T |
| POST | `/patients/{id}/people` | Enroll a person (multipart: 1–5 photos, name, relationship, consent) |
| POST | `/people/{id}/photos` | Add more photos/embeddings |
| PATCH / DELETE | `/people/{id}` | Edit / archive |
| GET | `/patients/{id}/unknown-faces` | Clusters awaiting caregiver |
| POST | `/unknown-faces/{id}/promote` · `/dismiss` | Caregiver decision |
| POST | `/patients/{id}/events:batch` | Idempotent batch upload (events + encounters) |
| POST | `/patients/{id}/uploads` | Request presigned S3 URL for media or audio |
| POST | `/uploads/{id}/complete` | Confirm upload → enqueue review (media) or STT (audio) |
| GET | `/patients/{id}/media/{media_id}` | Short-lived signed URL (audit-logged) |
| POST | `/media/{id}/pin` · DELETE `/media/{id}` | Pin to keep / delete |
| GET | `/patients/{id}/documents` | OCR'd documents with extracted fields |
| GET | `/patients/{id}/journal?date=` | Day timeline |
| POST | `/patients/{id}/assist` | Free-form question (audio or text) → `{answer, language, source_event_ids}` (Phase 2) |
| GET/POST/PATCH/DELETE | `/patients/{id}/reminders[/{rid}]` | Reminder CRUD |
| POST | `/patients/{id}/reminder-logs:batch` | Upsert occurrences generated on the phone |
| GET/POST/PATCH/DELETE | `/patients/{id}/places[/{pid}]` | Saved places |
| POST | `/patients/{id}/mind-game-sessions` | Log a game |
| GET | `/patients/{id}/daily-summary?date=` | Phase 2 |
| GET | `/caregivers/me/alerts` · POST `/alerts/{id}/read` | Alert feed |
| POST | `/me/push-token` | Register FCM token |

Smart review, OCR, STT, clustering, retention and summaries are **worker jobs only**. They have no public endpoints.

**`where_am_i` is answered on the phone**, not the backend: phone GPS → nearest saved place within its radius → "انت في البيت". With no saved place nearby and internet available, it falls back to a reverse-geocoded street/area name. Otherwise: "مش عارف المكان ده بالظبط".

Example — idempotent batch:
```jsonc
// POST /patients/{id}/events:batch
{ "encounters": [ { "id": "uuid", "person_id": "uuid", "started_at": "...", "ended_at": "...", "best_confidence": 0.94, "announced": true } ],
  "events": [ { "id": "uuid", "event_type": "encounter", "encounter_id": "uuid", "occurred_at": "...", "source": "glasses" } ] }
// 200 → { "accepted": ["uuid", ...], "duplicates": ["uuid"] }
```

### 7.3 Ambient memory pipeline (cloud)

1. `uploads/{id}/complete` for an audio segment → enqueue `transcribe(segment)`.
2. The worker calls the STT API (language auto-detect, ar/en) and writes a `conversation_segment` event with `transcript_text`, `language`, and `metadata.present_person_ids` (enrolled people whose encounters overlap the segment, so "who was I talking to" works without diarization).
3. On success the worker **deletes the S3 audio** and sets `audio_segments.status = deleted` (D4). On failure it retries up to 3 times. Audio still untranscribed after 7 days is deleted regardless.
4. The event's `rendered_text` (e.g. "09:20–09:24, talking with Ahmed (son): '...'") is embedded for RAG.

Silence and non-speech never leave the glasses: only VAD-positive segments are encoded.

### 7.4 Smart review, OCR, retention

The on-device gate proposes (`pending_review`). The worker blurs faces that don't match an enrolled person, then makes **one vision-model call** that returns: keep/discard, open-ended `ai_tags`, `contains_other_people`, and, for documents, `document_type` + `ocr_text` + `extracted_fields` (D20). `user_requested` media skips review (`confirmed`, `keep_indefinitely`).

### 7.5 Error shape (all endpoints)

```json
{ "error": { "code": "PERSON_NOT_FOUND", "message": "..." } }
```

---

## 8. Retention policy (D4, D10)

| Data | Policy |
|---|---|
| Raw ambient audio | Deleted immediately after transcription. Hard cap 7 days if transcription keeps failing |
| Transcripts, journal text, encounters | Kept until the patient or caregiver deletes them |
| Confirmed photos containing other people (encounter keyframes, salient frames) | `auto_expire` after **30 days**, unless a caregiver pins one |
| Unknown-face sample photos | Until the cluster is dismissed (deleted then) or 30 days |
| User-requested clips | `keep_indefinitely` |
| Documents, own notable moments (no other people) | `keep_indefinitely` |
| Discarded media | Deleted immediately |
| Face embeddings | Deleted with the person (hard delete on caregiver request) |

---

## 9. Privacy, consent, security (D24)

Ambient listening is the core feature, so it has to be defensible. Egyptian law protects private conversations (Penal Code Art. 309 bis), and the Personal Data Protection Law (151/2020) treats biometric data as sensitive. Controls:

- **Visible:** status LED shows when memory is capturing. Long-press pauses it, and a spoken confirmation follows ("وقفت التسجيل").
- **Consent:** caregiver records household consent (`ambient_audio_household`) and per-person face consent at enrollment. `memory_capture_enabled` is a caregiver master switch.
- **Minimization:** only speech segments leave the device. Raw audio is deleted after STT. Non-enrolled faces are blurred before any third-party vision call. Bystander photos expire after 30 days.
- **Security:** BLE LE Secure Connections bonding. Glasses storage encrypted (key provisioned at pairing). TLS everywhere. Private S3 with short-lived signed URLs. Every media view/delete goes into `audit_log`. Patient-link authorization on every route.
- **Report:** the graduation report includes an ethics/privacy section built from this list.

---

## 10. UI delivery (Flutter, Android + iOS)

- **Platforms (D8):** one codebase. Everything except the relay layer is shared: screens, Riverpod, drift, ApiClient, sync, FCM.

  | Capability | Android | iOS |
  |---|---|---|
  | Caregiver Mode | ✅ | ✅ |
  | Patient Mode UI (today, reminders, journal, games) | ✅ | ✅ |
  | Reminder notifications | ✅ | ✅ (glasses speak them regardless, D6) |
  | Glasses relay: background BLE, uploads, `where_am_i` | ✅ foreground service | Stretch goal: BLE background mode + state restoration, "Always" location, `NEHotspotConfiguration` for video. Stops if the user force-quits the app |

  Platform code lives behind one interface (`RelayService`) in `core/relay/`, with an `android/` implementation now and an `ios/` one later. The rest of the app never knows which one it's on.
  **iOS builds need a Mac + an Apple Developer account** for device installs. Without a Mac, a CI service (e.g. Codemagic) can build the app, but an account is still needed to install it on an iPhone.
- **State:** Riverpod. **Navigation:** GoRouter, two shells:
  - Caregiver → email/password → Caregiver shell (dashboard + alerts, people, unknown-face review, reminders, places, device, activity log + media, documents, AI summaries).
  - Patient → device-token auto-login → Patient shell (today, reminders, journal recall, ask, mind games). Large type, high contrast, Arabic-first RTL.
- **Background (Android relay):** a **foreground service** (persistent notification "Remori is connected") runs the BLE link, the outbox uploader, reminder sync + local notifications, and GPS for `where_am_i`.
- **Reminders (D6):** the app expands RRULEs into `reminder_logs` for the next 48 h, schedules a local notification for each (with *Taken* / *Later* actions), lists them in the Reminders section, and pushes them to the glasses with `sync_reminders`. The glasses fire independently, and state changes on either side merge by the §7.1 rule.
- **Folder structure:**
  ```
  lib/
    core/            # api client (dio), drift db, relay/ (RelayService + android/ ios/), sync/, theme, router
    features/
      auth/ device_pairing/ enrollment/ unknown_faces/ journal/
      reminders/ places/ assistant/ mind_games/ caregiver_dashboard/
  ```
- **Offline-first:** UI reads only from drift. Writes go to the outbox. The sync engine uploads, then delta-pulls.
- **Design system:** Figma tokens → `ThemeData` + shared widgets for both modes.

---

## 11. Feature ownership (8 members)

⚠ **Only open item:** assign names. Proposed split:

| Track | Owns | Headcount |
|---|---|---|
| Lead (احمد مصطفى) | Architecture, backend core, AI integration (RAG, STT, vision pipeline), cross-track contracts | 1 |
| Hardware / embedded | Pi runtime (capture, audio, BLE/Wi-Fi, store), ESP32 firmware, power/thermal | 2 |
| AI / ML | Shared face pipeline + evaluation (FAR/FRR), intent classifier dataset + model, capture gate, Piper voices | 2 |
| Flutter / mobile | Both modes on Android + iOS, Android relay (BLE + foreground service), sync engine, reminders, places | 2 |
| Backend | FastAPI routes, auth, Alembic, worker jobs, AWS deploy | 1 |

---

## 12. Build order

0. **Hardware spike (week 1, parallel):** Pi Zero 2W at 1 fps with detector + MobileFaceNet (FPS, RAM, °C, mA). Real BLE throughput Pi→Android with a 50 KB JPEG and Opus audio. Wi-Fi burst via `WifiNetworkSpecifier`. I²S mic + speaker + Piper Arabic. **The results may revise D7/D18.**
1. Scaffold the monorepo (§5). Rename `backend&AI` → `backend-ai`.
2. `backend-ai`: schema (§6) via Alembic, FastAPI skeleton, auth + patient-link authorization.
3. `backend-ai`: people/enrollment (shared face pipeline), events batch, reminders, places, delta sync.
4. `flutter`: app shell, GoRouter, drift, ApiClient, caregiver auth.
5. `flutter`: Caregiver Mode: enrollment, reminders, places, device pairing.
6. `hardware`: Pi recognition + encounters, button/LED via ESP32 UART, BLE contract (§7.1), Piper TTS, fixed intents, local reminder firing.
7. `flutter`: Android `RelayService` (foreground service, BLE link, outbox), reminder sync + notifications, `where_am_i`. Smoke-test Caregiver Mode on an iPhone.
8. **End to end:** one person recognized, encounter + keyframe reach the journal. One reminder spoken and confirmed.
9. Ambient memory: VAD segments → phone → STT worker → transcripts in the journal, audio deleted.
10. Media: uploads, smart review + OCR, retention job, unknown-face clustering.
11. Patient Mode UI: journal recall with media and transcripts, mind games.
12. Phase 2: `/assist` RAG, daily summaries, patterns, alerts. Stretch goals: wake word, AR, iOS relay.
