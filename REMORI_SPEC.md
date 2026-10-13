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
| D25 | **Database on Supabase, everything else on AWS.** Supabase hosts PostgreSQL 17 + pgvector (EU / Frankfurt region), used **only as plain Postgres**: no Supabase Auth, no auto-generated Data API (PostgREST), no Supabase Storage. API, workers, Redis and S3 stay on AWS. Local development uses Docker `pgvector/pgvector:pg17`. Moving to RDS later = dump + restore, no code change. | P |
| D26 | **Caregiver sign-in: Google, Facebook, or email + password (no OTP).** Flutter uses `google_sign_in` and `flutter_facebook_auth`. The backend verifies the provider token itself (Google ID token: Google's public keys, audience = our client IDs, `email_verified`; Facebook access token: Graph API `debug_token` with our app credentials), then issues **Remori's own** JWT + refresh tokens. An existing account is linked automatically only when the provider says the email is verified (Google). A Facebook email matching an existing account is **not** linked: the caregiver signs in the usual way and connects Facebook in Connected accounts (C20). Patients are unchanged (device token). | P |
| D27 | **Phase 5 API additions:** `GET /auth/me`, `GET /patients`, people list/detail, single-photo removal; batch responses add `rejected`; enrollment photo keys stored on `face_embeddings.storage_key`; archiving a person deletes their face data but keeps the row for the journal; a pagination rule for unbounded lists (§7.2). | P |
| D28 | **Every UI-brief screen has its endpoints:** device list + unpair, patient profile edit, linked caregivers, consent list + revoke, one day's reminder logs, past games, archived-people filter, alert links (migration `0003`), ~320 px thumbnails (migration `0004`), and signed URLs inside list responses so a screen needs one request, not one per item (§7.2). | P |
| D29 | **Smart-review contract:** keep/discard is separate from category; fixed shapes for receipt, bill, medication label and `ai_tags`; everything else is `other` with the model's own title, labels or reason (never dropped, never an error); unknown categories kept in `raw_category` and promoted to real ones only by the lead (§7.4). Documents and media responses are ready to show (`title`, `headline`, `fields`, `captured_at`, event summary). | P |
| D30 | **Background jobs (Phase 6):** one Celery worker + one Beat + Redis (AOF) on the API server, no Flower. Caregiver alerts every 5 min: missed medication (marked missed, or pending 60 min after its time), glasses offline 30 min (once per spell), battery <= 20% (at most every 12 h), to every linked caregiver once. Retention hourly: expired unpinned photos, audio untranscribed after 7 days. Upload previews (photos and videos) made by the worker. | P |
| D31 | **Flutter packages, pairing QR, fake glasses.** Approved on top of the §10 stack: `flutter_secure_storage` (auth + device tokens), `flutter_svg`, `mobile_scanner` (A5), `permission_handler` (A6), `flutter_blue_plus` (BLE relay), and `uuid`, `intl`, `path_provider`, `sqlite3` (drift); fonts are bundled as assets. The glasses-case QR holds **only the plain serial** (§7.1). Until the glasses run the §7.1 service, **development builds** use a `FakeGlassesConnection` that sends §7.1 messages, so A6 handover, Patient Mode and every glasses-dependent screen can be built and tested; release builds use real BLE only. | P |

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
| Database | PostgreSQL 17 + pgvector (only vector store), hosted on **Supabase** (D25). Local dev: Docker `pgvector/pgvector:pg17` |
| Object storage | S3, private bucket, presigned URLs |
| Push | Firebase Cloud Messaging |
| Mobile app | Flutter (Dart), **Android + iOS** (relay role Android, D8), Riverpod, GoRouter, dio |
| Phone local DB | drift (SQLite) |
| Glasses↔phone | BLE (control + keyframes + audio), Wi-Fi burst (video) (D18) |
| Phone↔cloud | HTTPS over phone Wi-Fi / cellular |
| Hosting | AWS: one small EC2 (Docker Compose: API, Celery worker, Beat, Flower, Redis) + S3. Database: Supabase (D25) |
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
graduation-project/          # "remori" monorepo. Start at AGENTS.md (orchestrator)
├── AGENTS.md                # orchestrator: repo map, rules for everyone, open decisions
├── flutter/                 # Patient + Caregiver app (Android + iOS; relay on Android). flutter/AGENTS.md
├── backend-ai/              # FastAPI, Postgres/Alembic, Celery + Redis, and AI as software:
│                            # AI API clients, RAG, vector search, local model inference. backend-ai/AGENTS.md
├── ml/                      # low-level ML: training, datasets, notebooks, evaluation, export,
│                            # exported models + model cards, shared face preprocessing. ml/README.md
├── hardware/
│   ├── pi/                  # capture/, inference/, audio/, link/ (BLE + Wi-Fi), store/
│   └── esp32/               # button, battery, LED, UART protocol, timekeeping
├── docs/                    # review, diagrams, API contract, team workflow, study guide
└── .github/workflows/       # CI: pull-request checks per area (docs/TEAM_WORKFLOW.md)
```

**AI split:** `backend-ai/app/ai/` holds everything that *uses* AI (API clients, RAG, vector search, inference wrappers that load exported models). `ml/` holds everything that *makes* models (training, evaluation, export) plus the exported files. The face preprocessing in `ml/face/` is shared by `hardware/pi` and `backend-ai`, and a parity test asserts both produce the same embedding for the same image (D14).

### 5.1 `backend-ai` architecture and conventions

The backend follows the **freeCodeCamp FastAPI course layout** (`main.py`, `config.py`, `database.py`, `models.py`, `schemas.py`, `oauth2.py`, `utils.py`, `routers/`, Alembic, pytest, Docker), using current library versions. It adds only what the course doesn't cover: `services/` (logic shared by routes and Celery tasks), `errors.py`, `integrations/` (S3, FCM), `ai/` and `workers/` (Celery).

The detailed rules live next to the code:

| Topic | Document |
|---|---|
| Folder map, "where does this code go", layer rules, authorization, errors, logging, testing | [`backend-ai/docs/ARCHITECTURE.md`](backend-ai/docs/ARCHITECTURE.md) |
| AI layer (`app/ai/`) and its boundary with `ml/` | [`backend-ai/docs/AI_LAYER.md`](backend-ai/docs/AI_LAYER.md) |
| Celery + Redis best practices: idempotency, retries, queues, Beat | [`backend-ai/docs/CELERY_REDIS.md`](backend-ai/docs/CELERY_REDIS.md) |
| Local Postgres, Supabase (D25), Alembic, column conventions, seed data | [`backend-ai/docs/DATABASE.md`](backend-ai/docs/DATABASE.md) |
| How backend and Flutter share the API contract | [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) |

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

auth_identities (                     -- Google / Facebook sign-in connections (D26)
  id UUID PK,
  user_id UUID FK -> users,
  provider ENUM('google','facebook'),
  provider_subject TEXT,              -- Google 'sub' / Facebook user id
  email TEXT NULLABLE,                -- as reported by the provider
  email_verified BOOLEAN,
  created_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ NULLABLE,
  UNIQUE (provider, provider_subject),
  UNIQUE (user_id, provider)          -- at most one Google and one Facebook per caregiver
)

devices (
  id UUID PK,
  patient_id UUID FK -> users,
  serial_number TEXT UNIQUE,
  token_hash TEXT,                     -- device credential (patient auto-login + glasses identity)
  firmware_version TEXT,
  battery_level_pct INT,
  last_seen_at TIMESTAMPTZ,            -- from phone heartbeat
  paired_at TIMESTAMPTZ,
  unpaired_at TIMESTAMPTZ NULLABLE      -- unpaired: token dead, row kept for history (D28)
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
  storage_key TEXT NULLABLE,            -- S3 key of the enrollment photo; NULL if promoted from a cluster
  thumbnail_key TEXT NULLABLE,          -- ~320 px JPEG preview (D28)
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
  thumbnail_key TEXT NULLABLE,         -- ~320 px JPEG preview, NULL for videos (D28)
  trigger ENUM('encounter_keyframe','document_signal','salient_frame','user_requested'),
  status ENUM('pending_review','confirmed','discarded'),
  ai_tags JSONB NULLABLE,              -- {category, tags[], reason, raw_category?} (D29)
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
  extracted_fields JSONB,              -- per-type keys, or {title, fields[]} for other (D29)
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
  entity_type TEXT NULLABLE, entity_id UUID NULLABLE,  -- what tapping the alert opens (D28)
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
**Pairing QR (D31).** The QR on the glasses case contains only the serial as plain text (e.g. `RMR-0007`): no URL, no JSON. The phone reads it on A5 and sends it to `POST /devices/pair` (§7.2).

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

Base `/api/v1`. Auth: JWT access (15 min) + refresh token for caregivers, who sign in with Google, Facebook or email + password (D26). A device token for the patient's phone, which acts on behalf of its patient. **Every `/patients/{id}/...` route checks that the caller is linked to that patient** (caregiver link, or the device token's patient).

| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/register` | Caregiver sign-up |
| POST | `/auth/google` | Sign in or sign up with a Google ID token → tokens |
| POST | `/auth/facebook` | Sign in or sign up with a Facebook access token → tokens. `409 ACCOUNT_EXISTS` when the email belongs to another account |
| GET | `/auth/identities` | The caregiver's connected Google / Facebook accounts |
| POST / DELETE | `/auth/link/{provider}` | Connect / disconnect Google or Facebook. `409 LAST_SIGN_IN_METHOD` when it would leave no way to sign in |
| POST | `/auth/login` · `/auth/refresh` · `/auth/logout` | Session |
| GET | `/auth/me` | The signed-in caregiver |
| GET | `/patients` | The caregiver's linked patients with their permission (C1 switcher) |
| PATCH | `/patients/{id}` | Patient profile and `memory_capture_enabled` (C16, C18) |
| GET | `/patients/{id}/caregivers` | Linked caregivers (C19) |
| GET | `/patients/{id}/consents` · POST `/consents/{id}/revoke` | Consent records (C18). Revoking face enrollment archives the person |
| POST | `/patients` | Caregiver creates a patient (+ profile) |
| POST | `/patients/{id}/caregivers` | Invite / link another caregiver |
| POST | `/devices/pair` | Pair glasses (serial from QR) to a patient → device token |
| POST | `/devices/{id}/heartbeat` | Battery, firmware, last seen (from phone) |
| GET | `/patients/{id}/devices` | Paired glasses with battery, last seen, `online` (C1, C16) |
| DELETE | `/devices/{id}` | Unpair (C16): the token stops working; the glasses can be paired again |
| GET | `/patients/{id}/sync?since=` | **Delta pull**: people, embeddings, reminders, places, settings changed since T |
| POST | `/patients/{id}/people` | Enroll a person (multipart: 1–5 photos, name, relationship, consent) |
| POST | `/people/{id}/photos` | Add more photos/embeddings |
| GET | `/patients/{id}/people` · `/people/{id}` | List people · one person with signed photo URLs |
| DELETE | `/people/{id}/photos/{photo_id}` | Remove one photo and its embedding (not the last one) |
| PATCH / DELETE | `/people/{id}` | Edit / archive (face data and photos are deleted; the row stays for the journal) |
| GET | `/patients/{id}/unknown-faces` | Clusters awaiting caregiver |
| POST | `/unknown-faces/{id}/promote` · `/dismiss` | Caregiver decision. Dismiss deletes every photo of that face at once (§8) |
| POST | `/patients/{id}/events:batch` | Idempotent batch upload (events + encounters) |
| POST | `/patients/{id}/uploads` | Request presigned S3 URL for media or audio |
| POST | `/uploads/{id}/complete` | Confirm upload → enqueue review (media) or STT (audio). Body carries `patient_id`, `kind` and the row's fields, since the path has no patient |
| GET | `/patients/{id}/media/{media_id}` | Short-lived signed URL (audit-logged) |
| POST | `/media/{id}/pin` · DELETE `/media/{id}` | Pin to keep / delete |
| GET | `/patients/{id}/documents` · `/documents/{id}` | OCR'd documents, ready to show: `title`, `headline`, ordered `fields`, `captured_at` (D29) |
| GET | `/patients/{id}/journal?date=` | Day timeline |
| POST | `/patients/{id}/assist` | Free-form question (audio or text) → `{answer, language, source_event_ids}` (Phase 2) |
| GET/POST/PATCH/DELETE | `/patients/{id}/reminders[/{rid}]` | Reminder CRUD |
| POST | `/patients/{id}/reminder-logs:batch` | Upsert occurrences generated on the phone |
| GET | `/patients/{id}/reminder-logs?date=` | One day's occurrences with reminder title (C1, C8 Today) |
| GET/POST/PATCH/DELETE | `/patients/{id}/places[/{pid}]` | Saved places |
| POST | `/patients/{id}/mind-game-sessions` | Log a game |
| GET | `/patients/{id}/mind-game-sessions` | Past games, newest first (P7 last score) |
| GET | `/patients/{id}/daily-summary?date=` | Phase 2 |
| GET | `/caregivers/me/alerts` · POST `/alerts/{id}/read` | Alert feed |
| POST | `/me/push-token` | Register FCM token |

Smart review, OCR, STT, clustering, retention and summaries are **worker jobs only**. They have no public endpoints.

**One request per screen:** list responses carry the signed URLs their screen shows (people `photo_url`, journal `media[].url`, documents `url`, each with a ~320 px `thumbnail_url` preview made at upload; previews drop EXIF/GPS), so no screen makes a request per item; every URL handed out is audit-logged in one bulk insert. `GET /patients/{id}/people?status=archived` lists archived people (C3 filter).

**Lists and pagination:** unbounded lists (`documents`, `caregivers/me/alerts`, `mind-game-sessions`) take `limit` (default 50, max 200) and `offset`, newest first. Lists bounded by nature (people, places, reminders, unknown faces, my patients) and the journal (one day per call) are not paginated. Batch requests take at most 500 items per array.

**`where_am_i` is answered on the phone**, not the backend: phone GPS → nearest saved place within its radius → "انت في البيت". With no saved place nearby and internet available, it falls back to a reverse-geocoded street/area name. Otherwise: "مش عارف المكان ده بالظبط".

Example — idempotent batch:
```jsonc
// POST /patients/{id}/events:batch
{ "encounters": [ { "id": "uuid", "person_id": "uuid", "started_at": "...", "ended_at": "...", "best_confidence": 0.94, "announced": true } ],
  "events": [ { "id": "uuid", "event_type": "encounter", "encounter_id": "uuid", "occurred_at": "...", "source": "glasses" } ] }
// 200 → { "accepted": ["uuid", ...], "duplicates": ["uuid"], "rejected": ["uuid"] }
// rejected = points at something this patient doesn't have; the rest of the batch is still stored
```

### 7.3 Ambient memory pipeline (cloud)

1. `uploads/{id}/complete` for an audio segment → enqueue `transcribe(segment)`.
2. The worker calls the STT API (language auto-detect, ar/en) and writes a `conversation_segment` event with `transcript_text`, `language`, and `metadata.present_person_ids` (enrolled people whose encounters overlap the segment, so "who was I talking to" works without diarization).
3. On success the worker **deletes the S3 audio** and sets `audio_segments.status = deleted` (D4). On failure it retries up to 3 times. Audio still untranscribed after 7 days is deleted regardless.
4. The event's `rendered_text` (e.g. "09:20–09:24, talking with Ahmed (son): '...'") is embedded for RAG.

Silence and non-speech never leave the glasses: only VAD-positive segments are encoded.

### 7.4 Smart review, OCR, retention

The on-device gate proposes (`pending_review`). The worker blurs faces that don't match an enrolled person, then makes **one vision-model call** that returns: keep/discard, open-ended `ai_tags`, `contains_other_people`, and, for documents, `document_type` + `ocr_text` + `extracted_fields` (D20). `user_requested` media skips review (`confirmed`, `keep_indefinitely`).

**Review contract (D29), shapes in `backend-ai/app/ai/review_contract.py`:**
1. **Importance and category are separate.** `keep` decides whether the photo is saved; the category only decides how the app displays it. Something important that fits no category is kept.
2. **Fixed shapes for the known types:** receipt `{merchant, total{amount, currency}, date, items[]}`, bill `{issuer, total, due_date, date}`, medication label `{medication_name, strength, instructions, expiry_date}`; `ai_tags` = `{category: notable_moment|document|person|place|other, tags[], reason}`.
3. **Anything else is `other` with the model's own words:** a document gets `{title, fields: [{label, value}]}` in the patient's language; a photo gets a `reason`. The app has one generic layout for `other`.
4. **An unexpected answer never fails the job.** An unknown category is stored as `other` with the model's word in `raw_category`; known keys are matched by common variants (`amount` → `total`, `dosage` → `strength`).
5. **Categories grow through the lead.** Frequent `raw_category` values are reviewed; adding one is a spec change, a prompt version bump, a new app layout and a backfill from `raw_category`.
6. **`other` never creates event types or alerts.** It appears in the journal as a notable moment or a document.

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
- **Hosting:** the database is on Supabase (EU region), media in a private S3 bucket, compute on EC2. Supabase's Data API is disabled and RLS is on, so data is reachable only through FastAPI (§5.1).
- **Sign-in (D26):** Google and Facebook tokens are verified on the server (signature, audience = our app, expiry). The client's claimed email is never trusted. Unverified emails are never linked to existing accounts.
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
  - Caregiver → Google / Facebook / email + password (D26) → Caregiver shell (dashboard + alerts, people, unknown-face review, reminders, places, device, activity log + media, documents, AI summaries).
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
1. Scaffold the monorepo (§5). ✅ `backend&AI` renamed to `backend-ai`, CI added, `AGENTS.md` files written.
2. `backend-ai`: schema (§6) via Alembic, FastAPI skeleton, auth + patient-link authorization. ✅ Done (email + password; API live since 12 Oct 2026).
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
