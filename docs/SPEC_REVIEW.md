# Remori — Spec Review (v0, pre-code)

Review of [`REMORI_SPEC.md`](../REMORI_SPEC.md) against itself, the [`README.md`](../README.md), and the hardware/cloud constraints it commits to.
Severity: 🔴 **critical** (will break the system or the demo if not resolved before coding) · 🟠 **major** (real rework later) · 🟡 **minor** (cleanup / consistency).

Diagrams are in [`docs/diagrams/`](diagrams/README.md).

---

## ✅ Resolution status (design session 2026-10-03, spec v1)

Every item below was resolved in [`REMORI_SPEC.md` v1](../REMORI_SPEC.md). `D#` refers to the spec's §0 decision log. The original findings are kept below the table for the record.

| Item | Resolution |
|---|---|
| C1 always-on listening | **Re-framed.** Listening all day *is* the product (artificial memory, D1). Speech is captured for memory, but the assistant **only answers when addressed** by button, with a wake word later (D2). Raw audio is deleted after STT (D4). Legal/privacy controls in spec §9 |
| C2 1 fps announcements | Encounters + 10-min cooldown (D13), `encounters` table |
| C3 free-tier hosting | External STT/LLM/vision APIs, small AWS footprint (D5) |
| C4 reminders | Phone syncs 48 h of occurrences. Phone notification + app section, and the glasses fire independently from their own clock. Confirmations merge (completed wins) (D6). New BLE messages `sync_reminders`, `reminder_state`, `reminder_update` |
| C5 hardware gaps | I²S mic + amp + speaker, LED, power board added. Pi owns links, ESP32 = power/IO/timekeeping over UART (D7). Power and thermal are measured in the week-1 spike |
| C6 video over BLE | Wi-Fi burst for video (D18). Android relay uses `WifiNetworkSpecifier`, a future iOS relay would use `NEHotspotConfiguration` (D8) |
| C7 relay phone | Cross-platform Flutter app (Android + iOS). The relay role is supported on a dedicated Android phone (foreground service), iOS relay is a stretch goal behind one `RelayService` interface (D8) |
| M1–M3 face model | `face_embeddings` (many per person), pinned `w600k_mbf` 512-d, shared `ml/` pipeline + parity test (D14) |
| M4–M5 vectors | pgvector only, `text-embedding-3-small` 1536-d (D15, D19) |
| M6–M11 data model | Client UUIDs + idempotent batch, `media_assets.event_id`, enums aligned, domain FKs on events, timezone/dtstart, `updated_at`/`deleted_at` everywhere (D21) |
| M12 unknown faces | `unknown_face_clusters`, caregiver asked at ≥3 distinct days (D23) |
| M13–M14 auth + tables | `devices.token_hash`, QR pairing, refresh/push tokens, profiles, consent, audit log, places, audio_segments |
| M15–M18 API | Full endpoint list in spec §7.2: delta sync, presigned uploads, worker-only internals, patient-link authorization, FCM |
| M19–M20 infra | Celery + Redis worker, Celery Beat for cron, Flower, private S3 (D19) |
| M21 RAG | Hybrid time filter + vector over `rendered_text` (D22) |
| M22 TTS | Piper + diacritized LLM output (D16) |
| M23 Arabic KWS | Push-to-talk intent classifier on team-recorded data (D17) |
| M24 capture gate | Heuristics first, MobileNetV3 later (spec §3) |
| M25 OCR | Same vision call does review + OCR (D20) |
| M26 thresholds/eval | Assigned to AI/ML track (FAR/FRR evaluation, spec §11) |
| M27–M28 privacy/security | Face blur before vision API, 30-day expiry, BLE bonding, encryption at rest, audit log (D10, D24) |
| m1–m13 | Fixed in spec v1 + README (name Remori, 8 members, AR stretch, BOM aligned, numbering, enums). **Folder rename `backend&AI` → `backend-ai` is still to do** (build step 1) |
| `where_am_i` | Phone GPS + caregiver-saved places (D9) |
| Team mapping | **Still open:** proposed 8-person split in spec §11, names to be assigned |

### New risks introduced by D1 (ambient memory), to measure in the spike
- **BLE bandwidth:** Opus at 16 kbps ≈ 2 KB/s of speech, about 30 MB/day at 4 h of speech. Fine for BLE if it drains continuously, but measure it alongside keyframes.
- **Battery:** mic + VAD running all day on the Pi. Measure the current draw.
- **STT cost:** hours of audio per patient per day. Pick the provider by price per hour, and keep VAD strict so silence never uploads.
- **Legal:** recording private conversations (Penal Code Art. 309 bis). Mitigations are in spec §9 and must appear in the report.

---

## 1. Critical flaws 🔴

### C1. No wake word / push-to-talk: every conversation becomes a "free-form query"
§2 says: fixed-intent phrases are answered locally, and "anything else" goes to the cloud. The glasses are listening all day through Silero VAD, so **every sentence the patient (or anyone near them) says that isn't a fixed intent becomes a `free_form_query_audio` uploaded to Whisper + LLM**.
- Privacy: bystanders' conversations get shipped to the cloud.
- Cost: Whisper and LLM calls all day long.
- UX: the glasses would answer things nobody asked.

**Fix:** add an explicit activation step: a wake word ("ريموري" / "Remori") or the ESP32 hardware button as push-to-talk. Only speech after activation is classified as fixed-intent or free-form.

### C2. Recognition at 1 fps with no debounce means announcing the name every second
Nothing in the spec stops the glasses from saying "Ahmed, your son" 3,600 times while Ahmed sits with the patient for an hour, or from logging 3,600 `recognition` events and 3,600 keyframes. The same applies to `unknown_face_flagged` (one flag per second for a stranger).

**Fix:** model an **encounter** (person appears → stays → leaves), not per-frame recognitions. Announce once per encounter, plus a cooldown (e.g. ≥10 min per person) and an on-demand "who is this". Keep one keyframe per encounter. On-device tracking (IoU / embedding similarity across frames) makes this cheap.

### C3. "AWS free tier" cannot host the cloud tier as specified
§3 puts Whisper **large-v3** (≈1.5B params, ~10 GB GPU RAM), a vision-LLM review step, Tesseract, FastAPI, Postgres+pgvector **and** Chroma on a free-tier instance (1 GB RAM, no GPU). That doesn't fit, not even close for Whisper.
Also note that AWS moved new accounts to a credit-based free plan in mid-2025, so check what your account actually gets.

**Fix:** treat STT, LLM and vision review as **external APIs** (e.g. OpenAI/Groq Whisper API, a Haiku/4o-mini-class LLM). Keep only FastAPI + Postgres + a small worker on AWS (or use a managed Postgres like Supabase/Neon free tier), and put media in S3.

### C4. Reminders "work offline on the glasses", but no contract gets them there
§4 says reminders work with zero connectivity on the glasses. But:
- §7.1 has **no `sync_reminders` message** (Phone → Glasses) and no `reminder_fired` / `reminder_acknowledged` message (Glasses → Phone).
- Nobody owns **firing** a reminder: phone local notification, glasses speaker, or both? If both, you get double alerts and duplicate `reminder_logs`.
- How is `medication_taken` detected? Patient voice confirmation? Caregiver tap? The `medication_check` intent ("did I take my pills?") needs the glasses to know today's `reminder_logs` state, which they never receive.

**Fix:** decide one reminder authority (I recommend the **phone** schedules, the **glasses** speak), add the missing BLE messages, and define how "taken" is confirmed.

### C5. Hardware BOM is missing the voice path, and the Pi↔ESP32 split is undefined
- **No microphone, speaker or amplifier** in §3, yet voice is the guaranteed output channel. The Pi Zero 2W has **no audio input** and no proper audio output, so you need I²S parts (e.g. an INMP441 mic and a MAX98357A amp + small speaker, or bone-conduction).
- §3 gives BLE to the ESP32-S3, but the Pi Zero 2W has its own BLE 4.2 + Wi-Fi. **What is the Pi↔ESP32 link (UART? SPI? I²C?), and who talks BLE to the phone?** If media goes Pi → UART → ESP32 → BLE, the UART is a second bottleneck.
- No **RTC**: the Pi has no real-time clock. After an offline reboot, every event timestamp is wrong. The glasses need time-sync from the phone on connect (or the ESP32 keeps time).
- No **power or thermal budget**. Pi Zero 2W + camera + 4 models running continuously inside a glasses frame will throttle and drain a small battery fast. Measure early.

### C6. Media transfer over BLE is unrealistic, and the Wi-Fi Direct fallback doesn't exist on iOS
Realistic BLE throughput is tens to a few hundred KB/s. A 12 s video clip (~2–4 MB) takes tens of seconds to minutes, and it competes with the control channel. The spec's fallback, "local Wi-Fi Direct", **is not available to third-party iOS apps**.
**Fix:** BLE for control + metadata + small JPEG keyframes only. For video, use Wi-Fi: the Pi joins the phone's hotspot, or the Pi runs an AP the phone connects to briefly. Or decide Android-only. Make **"Android only?"** an explicit decision.

### C7. Whose phone is the relay? The spec assumes the patient's phone without saying so
The glasses only reach the cloud through a phone that must be **nearby, charged, Bluetooth on, app alive in the background**, so in practice it has to be the **patient's** phone. That means:
- Caregiver Mode runs on a *different* phone, and remote caregivers depend entirely on cloud sync.
- The Flutter app needs an **Android foreground service** (and iOS background BLE modes, which are restrictive) to keep relaying. §9 doesn't mention background execution at all.
- A person with Alzheimer's has to keep a smartphone working. That's a product risk worth naming in the report, together with your mitigation (e.g. a dedicated cheap Android phone in the glasses case).

---

## 2. Major flaws 🟠

### Data model (§6)

| # | Problem | Fix |
|---|---|---|
| M1 | **One `face_embedding` per person.** A single photo gives brittle recognition (angle, lighting, glasses, hijab/niqab, aging). | New table `face_embeddings (id, person_id, embedding, source_photo_url, model_version)` with 3–10 per person. Match against all of them, or against their centroid. |
| M2 | **Embedding dimension and model version are unpinned.** MobileFaceNet is 128-d in the original paper and 512-d in the InsightFace variant. `VECTOR(512)` must match the exact model, and changing the model invalidates every stored embedding. | Pin the exact model file. Store `model_version` with each embedding. |
| M3 | **Where are enrollment embeddings computed?** The caregiver uploads a photo to the backend, so the backend must run *exactly* the same detector + alignment + MobileFaceNet + preprocessing as the Pi. Otherwise cloud-made embeddings won't match glasses-made ones. | One shared, versioned "face pipeline" package used by both `hardware/` and `backend-ai/`, with a parity test. |
| M4 | **Two vector stores.** Chroma *and* pgvector. | Drop Chroma. pgvector is already in Postgres and keeps journal + vectors transactional. |
| M5 | **`VECTOR(1536)` assumes OpenAI `text-embedding-3-small`.** Also, Arabic/English retrieval quality needs a multilingual embedder. | Decide the embedding model first, then size the column. |
| M6 | **No idempotency on sync.** `POST /events` batch retries after a dropped connection produce duplicates. | Client-generated `id` (UUID made on the glasses/phone) + `ON CONFLICT DO NOTHING`. Add `device_id` and `source` (`glasses` / `app` / `server`) to `events`. |
| M7 | **Event ↔ media relation is defined twice and contradicts itself.** `events.media_asset_id` points to media, but the upload API sends `event_id` and `media_assets` has no `event_id`. | Pick one direction. Recommended: `media_assets.event_id` FK, which also allows several media per event. |
| M8 | **Enum mismatch.** The upload API uses `trigger: "event_keyframe"`, but the schema enum is `specific_signal / ai_judged_salient / user_requested`. | Align them. |
| M9 | **Two sources of truth for adherence and games.** `reminder_logs` vs `events(medication_taken/missed)`; `mind_game_sessions` vs `events(mind_game_session)`. | Make the domain table the truth and give the event an FK (`reminder_log_id`, `mind_game_session_id`), or derive the events. |
| M10 | **Reminders have no timezone.** An RRULE without DTSTART/TZID is ambiguous, and Egypt has observed DST again since 2023. | Add `timezone` (patient-level) and `dtstart`. Store logs in UTC. |
| M11 | **No sync metadata.** Offline-first needs `updated_at` + `deleted_at` (soft delete) on every synced table, so the phone can pull "changes since X". Most tables lack both. | Add them to every table the phone mirrors. |
| M12 | **Unknown-face handling is underspecified.** "Recurring" requires **clustering** unknown embeddings across days: who does it, where are clusters stored, and what is the threshold? Today an unknown face goes straight into `enrolled_people` as `pending_review`, mixing strangers into the "people I know" table. | Separate `unknown_face_clusters` table (cloud-side clustering). Promote to `enrolled_people` only on caregiver approval. |
| M13 | **Device auth has nowhere to live.** "Patients auth via paired device" but `devices` has no token / secret / hash, and pairing (how does the phone learn the device id? QR?) is undefined. | `devices.token_hash`, a pairing flow (QR on the glasses case), and token rotation. |
| M14 | **Missing tables:** refresh tokens, push-notification tokens (FCM), consent records, audit log (who viewed/deleted which photo), patient profile (language, timezone, DOB). | Add them. Section 3 of `02-database-erd.md` shows a proposal. |

### API (§7.2)
- **M15 – Missing endpoints:** caregiver **register**, create a **patient**, invite/link a second caregiver, token **refresh**/logout, update/delete reminders, delete enrolled people, **create** reminder logs (the phone generates them offline, so `PATCH` alone isn't enough), mark alerts read, register a push token, and a **pull/delta-sync** endpoint (phone → "what changed since T?").
- **M16 – `POST /media/{id}/review` is "internal" but sits on the public API.** Run it as a background worker that writes to the DB directly. Don't expose it.
- **M17 – Authorization is unspecified.** Every `/patients/{id}/…` route needs an "is this caller linked to this patient?" check, or any caregiver can read any patient (IDOR).
- **M18 – Alerts have no push channel.** `GET /caregivers/{id}/alerts` is polling only. Add FCM. Also, the cloud can't tell "glasses offline" from "phone offline", since both look like silence. Base `device_offline` on the phone's heartbeat and say that's what it means.

### Missing infrastructure
- **M19 – No job queue / worker / scheduler**, yet you need: OCR after upload, smart review, retention expiry, daily summaries, missed-medication detection, offline-device alerts. Add a worker (ARQ/Celery/RQ + Redis, or simply APScheduler + Postgres-backed jobs for a grad project).
- **M20 – Object storage isn't chosen.** "Media asset storage" should be **S3 with presigned URLs**. `storage_url` must not be a public link to a photo of a bystander's face.

### AI / ML
- **M21 – RAG over a time-ordered journal ≠ pure vector search.** "What did I do *this morning*?" is a **time filter**, not a semantic one. Recognition events have no text to embed. **Fix:** render each event into a short sentence ("09:15 — recognized Ahmed (son)"), then retrieve **hybrid**: SQL time-window filter first, vector similarity second. LangChain is optional here.
- **M22 – Arabic TTS with espeak-ng will be poor.** It's robotic, and it **needs diacritized text** to pronounce Arabic correctly. LLM answers have no tashkeel. **Piper** (has an Arabic voice, runs on a Pi) is a better default, or ask the LLM to output diacritized text. For a dementia patient, intelligibility is a clinical requirement.
- **M23 – Arabic (Egyptian) keyword spotting has no off-the-shelf model.** You'll need a small custom KWS dataset, or Vosk-small with a restricted grammar. Budget time for this.
- **M24 – The on-device "salience" gate has no definition, dataset, or metric.** As written it's a research project. Start with heuristics (face present, document = text-density/edge detector, scene change = frame differencing) and only train MobileNetV3 if time allows.
- **M25 – Tesseract on angled glasses-camera receipts in Arabic will be weak.** You already call a **vision LLM** for smart review, so have that same call do OCR and field extraction. That's one call instead of two systems.
- **M26 – No recognition thresholds or evaluation plan.** "Never guesses" needs a threshold chosen for a **very low false-accept rate** (announcing the wrong son is harmful) and a test set to measure FAR/FRR. The graduation committee will ask for this.

### Privacy / security
- **M27 – Bystander biometric data goes to a third-party LLM.** Smart review sends photos of non-consenting people to an external vision model. Under Egypt's Personal Data Protection Law (151/2020), biometric data is *sensitive data*. Mitigate: blur non-enrolled faces before cloud review, keep retention short (your §7.4 proposal), and write this up in the report's ethics section.
- **M28 – BLE security unspecified.** Family names + face embeddings travel over BLE. Require LE Secure Connections bonding. Also **encrypt at rest on the glasses' SD card**: lost glasses shouldn't leak the family's faces.

---

## 3. Minor / consistency issues 🟡

| # | Issue |
|---|---|
| m1 | **Project name:** README says *MemoryOS* / `memoryos/`, spec says *Remori* / `remori/`. |
| m2 | **Folder name on disk is `backend&AI`**, spec says `backend-ai/`. `&` breaks shell commands and CI. Rename. `docs/` didn't exist yet. |
| m3 | **Team size:** README lists **8** members, spec §8 says **7**. |
| m4 | **AR overlay:** README puts it in the Semester 1 deliverable. Spec makes it trial-only. Pick one, since the committee will read the README. |
| m5 | **GPS / IMU / touch / mic array** are in the README hardware table but not in the spec BOM. The spec's `where_am_i` gap says "no GPS anywhere", but the README has GPS. Also camera "1080p" vs "OV5647 5MP". |
| m6 | Section numbering jumps from **7.2 → 7.4** (no 7.3). |
| m7 | `weekly_summary_ready` alert type, but summaries are **daily**. |
| m8 | `reminder_logs.status` lacks `pending`, and `snoozed` needs a `snoozed_until`. |
| m9 | Upload example returns `expires_at` (90 days) **before** review and before the retention decision in §7.4 is made. |
| m10 | `sync_enrolled_people` sends 512 floats as JSON per person. Use binary (float16/int8) and deltas over BLE. |
| m11 | `caregiver_patient_links` needs `UNIQUE(caregiver_id, patient_id)` and a permission level (viewer / manager). |
| m12 | §9 leaves "drift/sqflite" open. Pick **drift** (typed, migrations, works well with Riverpod). |
| m13 | `users.role` as a single enum prevents a caregiver who is also a patient (rare, fine). Patients without email/password still need a non-null login path, which is the device token (see M13). |

---

## 4. Build-order concern

§10 puts hardware at **step 6**, but hardware is the **highest-risk** track: BLE throughput, Pi performance with 4 models, battery, thermal, audio. Run a **hardware spike in week 1, in parallel** with backend scaffolding:
1. Pi Zero 2W: camera + face detect + MobileFaceNet at 1 fps. Measure FPS, RAM, temperature, and power draw.
2. Pi ↔ phone BLE: measure real throughput with a 100 KB JPEG.
3. I²S mic + speaker: VAD + Piper/espeak Arabic sample.

If any of those fail, the architecture changes. Better to find out in week 1 than week 10.

---

## 5. Decisions you need to make (blocking)

1. **Activation:** wake word, button push-to-talk, or both? (C1)
2. **Reminder authority:** phone schedules + glasses speak? How is "taken" confirmed? (C4)
3. **Pi ↔ ESP32 split:** which chip owns BLE to the phone, and what's the bus between them? (C5)
4. **Platforms:** Android only, or Android + iOS? This decides the video-transfer path. (C6, C7)
5. **Cloud hosting:** external STT/LLM APIs vs self-hosted. (C3)
6. **Retention policy:** already flagged in spec §7.4.
7. **`where_am_i`:** already flagged in spec §7.1 (and GPS is in the README).
8. **Team mapping:** already flagged in spec §8 (and fix 7 vs 8 members).
9. **Face embedding model + vector size**, and **text embedding model + vector size**. (M2, M5)
