# API contract: how the backend and the Flutter app talk

The Flutter app and the backend are built in parallel by different people. They meet in one place: the REST API. This file is **the contract**: where the API lives, the rules both sides follow, every endpoint that's live today with its exact request and response, and the error codes.

Last updated: 12 Oct 2026, after Phase 5 was built (Phase 5 deploys together with Phase 6).

---

## 1. Where things are

| What | Where |
|---|---|
| **Production API** | **`https://remori-ai.duckdns.org/api/v1`** |
| **Live, interactive docs** (try every endpoint) | **https://remori-ai.duckdns.org/docs** |
| Machine-readable contract (OpenAPI JSON, for code generation) | https://remori-ai.duckdns.org/openapi.json |
| Health check | https://remori-ai.duckdns.org/health |
| This file | the human guide: rules, examples, error codes, status of every endpoint |
| `REMORI_SPEC.md` §7.2 | the **full planned** endpoint list, including ones not built yet |
| `backend-ai/docs/SEED_DATA.md` | the test accounts and fixed IDs |

**Which one wins?** For endpoints marked ✅ live (§5), the live `/docs` is exactly what the server does. For planned endpoints, spec §7.2 is the agreement until they're built.

**One known gap in `/docs`:** Swagger shows FastAPI's default 422 error format. The server really returns the Remori shape in §4. Trust §4.

### Environments (the base URL is a build setting in Flutter, never hard-coded in screens)
| Environment | Base URL |
|---|---|
| Production (EC2) | `https://remori-ai.duckdns.org/api/v1` |
| Backend dev's laptop (Docker) | `http://localhost:8000/api/v1` |
| Android emulator → that laptop | `http://10.0.2.2:8000/api/v1` |
| Real phone on the same Wi-Fi → that laptop | `http://<laptop LAN IP>:8000/api/v1` (debug builds only, since it's plain HTTP) |

---

## 2. Rules both sides follow

| Rule | Detail |
|---|---|
| **IDs** | UUID strings. Records created offline (events, encounters, reminder logs, media, audio segments, game sessions) get their UUID **on the device**, and the backend accepts it (sending the same one twice is safe) |
| **Time** | ISO-8601 in UTC with `Z`, e.g. `2026-10-01T09:15:00Z`. The app converts to the patient's timezone (usually `Africa/Cairo`) only for display |
| **Names** | JSON fields are `snake_case`, the same as database columns. Enum values are lowercase `snake_case` exactly as spec §6 (`pending_review`, `memory_paused`) |
| **Media** | never in a JSON body: request an upload URL, upload to S3, then call `complete` (planned, spec §7.2) |
| **Empty optional fields** | sent as `null` in responses. In requests they may be left out |

---

## 3. Authentication

### Caregivers: email + password (live)
1. **Register:** `POST /auth/register` (JSON) creates the account. It returns the user, **not** tokens.
2. **Log in:** `POST /auth/login` as **form data**, not JSON (the course's OAuth2 style): `username` = the email, `password`.
3. You get an **access token** (valid 15 min, `expires_in: 900`) and a **refresh token** (valid 30 days).
4. Send the access token on every request: `Authorization: Bearer <access_token>`.
5. When a request returns **401 `TOKEN_EXPIRED`**: call `POST /auth/refresh` with the refresh token, **save both new tokens** (the old refresh token stops working: rotation), and retry the request **once**.
6. If refresh returns **401 `INVALID_REFRESH_TOKEN`**: go to the login screen.
7. **Log out:** `POST /auth/logout` with the refresh token, then delete both tokens from the phone.

Store tokens in the phone's **secure storage**, never in plain preferences or logs.

### The patient's phone: device token (live)
1. During setup (screen A5), the caregiver pairs the glasses: `POST /devices/pair` returns a **`device_token`**, shown **once**.
2. The patient's phone stores it in secure storage and sends it the **same way**: `Authorization: Bearer <device_token>`.
3. It doesn't expire. Pairing the same glasses again issues a new one, and the old one stops working.

### Google / Facebook (decided in spec D26, **not built yet**)
The app will send the Google **ID token** or Facebook **access token** to `/auth/google` or `/auth/facebook` and receive Remori's own tokens, exactly like step 3 above. It never sends a name or email of its own: the backend reads them from the verified token. Until then, use email + password.

### Who can see a patient
- A caregiver sees **only patients they are linked to**. Any other patient returns **404 `PATIENT_NOT_FOUND`**, exactly like a patient that doesn't exist.
- **Manager** caregivers can change things. **Viewers** can read. A viewer trying to change something gets **403 `MANAGER_ONLY`**.
- A device token can only act for **its own patient**.

---

## 4. Errors

Every error, from every endpoint, has this shape (spec §7.5):
```json
{ "error": { "code": "EMAIL_TAKEN", "message": "An account with this email already exists." } }
```
Validation errors add the fields that failed:
```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Some fields are missing or invalid.",
             "details": [ { "field": "body.password", "message": "String should have at least 8 characters" } ] } }
```
**Flutter should switch on `code`**, never on `message` (messages may change wording or language).

| HTTP | `code` | Meaning | App should |
|---|---|---|---|
| 401 | `NOT_AUTHENTICATED` | no token sent | go to login |
| 401 | `INVALID_TOKEN` | token is wrong, forged, or its user no longer exists | go to login |
| 401 | `TOKEN_EXPIRED` | access token older than 15 min | refresh, then retry once |
| 401 | `INVALID_CREDENTIALS` | wrong email or password (never says which) | show "Wrong email or password" |
| 401 | `INVALID_REFRESH_TOKEN` | refresh token used, revoked or expired | go to login |
| 403 | `CAREGIVER_ONLY` | a device token called a caregiver endpoint | bug in the app |
| 403 | `DEVICE_ONLY` | a caregiver token called a device endpoint | bug in the app |
| 403 | `MANAGER_ONLY` | a viewer tried to change something | hide that action for viewers |
| 404 | `PATIENT_NOT_FOUND` | patient doesn't exist **or** isn't yours | treat as gone |
| 404 | `CAREGIVER_NOT_FOUND` | no caregiver account has that email | "Ask them to create an account first" |
| 404 | `DEVICE_NOT_FOUND` | device ID isn't this phone's device | bug in the app |
| 404 | `PERSON_NOT_FOUND` · `PHOTO_NOT_FOUND` · `CONSENT_NOT_FOUND` · `UNKNOWN_FACE_NOT_FOUND` · `PLACE_NOT_FOUND` · `REMINDER_NOT_FOUND` · `MEDIA_NOT_FOUND` · `EVENT_NOT_FOUND` · `ALERT_NOT_FOUND` | doesn't exist, was deleted, **or** isn't yours | treat as gone, refresh the list |
| 404 | `SUMMARY_NOT_READY` | no daily summary for that date yet | "No summary yet" |
| 404 | `NOT_FOUND` | the URL doesn't exist | bug in the app |
| 409 | `EMAIL_TAKEN` | registering an email that already has an account | offer login instead |
| 409 | `ALREADY_LINKED` | that caregiver is already linked to the patient | show as already added |
| 409 | `DEVICE_ALREADY_PAIRED` | these glasses belong to another patient | "These glasses are paired with someone else" |
| 409 | `ALREADY_DECIDED` | that unknown face was already promoted or dismissed | refresh the list |
| 409 | `TOO_MANY_PHOTOS` | a person already has 20 photos | "Remove a photo first" |
| 409 | `ALREADY_REVOKED` | that consent was already revoked | refresh the list |
| 409 | `LAST_PHOTO` | removing the person's only photo | "Add another photo first, or archive the person" |
| 409 | `UPLOAD_MISSING` | `complete` was called before the file reached S3 | retry the PUT, then `complete` |
| 409 | `ID_IN_USE` | a client-generated id already belongs to another patient | generate a new id |
| 422 | `VALIDATION_ERROR` | a field is missing or wrong; see `details` | highlight the fields |
| 422 | `CONSENT_REQUIRED` · `PHOTO_COUNT` · `PHOTO_TOO_LARGE` · `UNSUPPORTED_PHOTO` · `PHOTOS_INVALID` | enrollment: no consent, not 1–5 photos, a photo over 4 MB, not a JPEG/PNG Pillow can open (`PHOTOS_INVALID` = several kinds at once). `details` lists **every** bad photo as `body.photos.<index>` (0-based) | outline those photo slots (C4) |
| 503 | `DATABASE_UNAVAILABLE` | the server can't reach the database | "Try again in a moment" |
| 503 | `STORAGE_UNAVAILABLE` | the server can't reach S3 | "Try again in a moment" |

---

## 5. Endpoints live today ✅

All paths are under `/api/v1` unless shown otherwise. Try any of them at **/docs**.

### `GET /health` (no `/api/v1`, no auth)
`200 {"status": "ok", "database": "ok"}` · `503 DATABASE_UNAVAILABLE`

### `POST /auth/register` (no auth) · screen A3
```json
// request (JSON)
{ "full_name": "Ahmed Mostafa", "email": "ahmed@example.com", "phone": "+201000000001", "password": "at-least-8-chars" }
// 201
{ "id": "00000001-0000-4000-8000-000000000002", "role": "caregiver", "full_name": "Ahmed Mostafa",
  "email": "ahmed@example.com", "phone": "+201000000001", "created_at": "2026-10-12T09:00:00Z" }
```
`phone` is optional. The password is 8–128 characters. Errors: `409 EMAIL_TAKEN` (any capitalisation), `422`.

### `POST /auth/login` (no auth) · screen A2
```
// request (form: application/x-www-form-urlencoded)
username=ahmed@example.com&password=...
```
```json
// 200
{ "access_token": "eyJhbGciOi...", "refresh_token": "N2ZmY...", "token_type": "bearer", "expires_in": 900 }
```
Errors: `401 INVALID_CREDENTIALS`.

### `POST /auth/refresh` (no auth header)
```json
// request
{ "refresh_token": "N2ZmY..." }
// 200: a NEW pair (same shape as login). The old refresh token is now dead.
```
Errors: `401 INVALID_REFRESH_TOKEN`.

### `POST /auth/logout` (no auth header)
```json
{ "refresh_token": "N2ZmY..." }
```
`204` (no body), even if the token was already logged out.

### `GET /auth/me` (caregiver)
`200` with the same fields as register's response. Use it on startup to show who is signed in.

### `GET /patients` (caregiver) · screen C1
```json
// 200: primary patients first, then by name
[ { "id": "…", "full_name": "فاطمة محمود", "preferred_language": "ar", "timezone": "Africa/Cairo",
    "date_of_birth": "1954-03-12", "memory_capture_enabled": true, "created_at": "…",
    "relationship": "son", "permission": "manager", "is_primary": true } ]
```
`relationship` and `permission` are **yours** towards that patient: hide write actions when `permission` is `viewer`.

### `POST /patients` (caregiver) · screen A4
```json
// request
{ "full_name": "فاطمة محمود", "relationship": "son", "preferred_language": "ar",
  "timezone": "Africa/Cairo", "date_of_birth": "1954-03-12",
  "consents": ["ambient_audio_household", "cloud_processing"] }
// 201
{ "id": "…", "full_name": "فاطمة محمود", "preferred_language": "ar", "timezone": "Africa/Cairo",
  "date_of_birth": "1954-03-12", "memory_capture_enabled": true, "created_at": "2026-10-12T09:05:00Z" }
```
Required: `full_name`, `relationship` (**your** relationship to the patient). Defaults: `ar`, `Africa/Cairo`, no consents. The caller becomes the patient's **primary manager**. Errors: `422` (e.g. unknown timezone), `401`, `403 CAREGIVER_ONLY`.

### `POST /patients/{patient_id}/caregivers` (managing caregiver) · screen C19
```json
// request: link an EXISTING caregiver account by email (no invitation emails)
{ "email": "mona@example.com", "relationship": "nurse", "permission": "viewer" }
// 201
{ "id": "…", "caregiver_id": "…", "full_name": "Mona Ali", "email": "mona@example.com",
  "relationship": "nurse", "permission": "viewer", "is_primary": false }
```
`permission`: `viewer` (default) or `manager`. Errors: `404 PATIENT_NOT_FOUND`, `403 MANAGER_ONLY`, `404 CAREGIVER_NOT_FOUND`, `409 ALREADY_LINKED`.

### `POST /devices/pair` (managing caregiver) · screen A5
```json
// request: serial from the QR code on the glasses case
{ "serial_number": "RMR-0007", "patient_id": "…" }
// 201: device_token appears ONLY here
{ "device_id": "…", "serial_number": "RMR-0007", "patient_id": "…",
  "device_token": "QDeTfJ1d…", "paired_at": "2026-10-12T09:10:00Z" }
```
Errors: `404 PATIENT_NOT_FOUND`, `403 MANAGER_ONLY`, `409 DEVICE_ALREADY_PAIRED`.

### `POST /devices/{device_id}/heartbeat` (the patient's phone, device token)
```json
// request: both fields optional; send every few minutes while connected
{ "battery_level_pct": 76, "firmware_version": "0.3.1" }
// 200
{ "id": "…", "patient_id": "…", "serial_number": "RMR-0007", "firmware_version": "0.3.1",
  "battery_level_pct": 76, "last_seen_at": "2026-10-12T09:15:00Z", "paired_at": "2026-10-12T09:10:00Z" }
```
Errors: `403 DEVICE_ONLY`, `404 DEVICE_NOT_FOUND`.

### Phase 5: the patient's data (built, ⏳ not on production yet)

**These endpoints are merged into the code but deploy to `remori-ai.duckdns.org` together with Phase 6.** Until then production returns `404 NOT_FOUND` for them. To build against them now, run the backend locally (`backend-ai/README.md`) and use the laptop base URLs in §1. Everything above this heading is live on production.

**Who can call what.** "Any linked" = linked caregivers (manager or viewer) **and** the patient's phone. "Manager" = managing caregiver only (a viewer gets `403 MANAGER_ONLY`, the phone gets `403 CAREGIVER_ONLY`). "Phone + manager" = the patient's phone or a managing caregiver. Every `{patient_id}` route returns `404 PATIENT_NOT_FOUND` for a patient that isn't yours; every `/{thing}/{id}` route returns that thing's `*_NOT_FOUND` for one that isn't yours.

**Deletes are soft.** A deleted place, reminder or person disappears from lists and returns 404, and the phone learns about it from `/sync` `deletes`.

**Batch endpoints** all answer `200 {"accepted": [ids], "duplicates": [ids], "rejected": [ids]}`. Resending the same batch is safe: everything comes back as `duplicates`. `rejected` = the row points at something this patient doesn't have (another patient's id, an unknown encounter, …); the rest of the batch still goes in. **Ids are generated on the glasses/phone** (UUID v4).

| Endpoint | Who | Screens |
|---|---|---|
| `GET /patients/{id}/sync?since=` | any linked | relay, offline |
| `PATCH /patients/{id}` | manager | C16, C18 |
| `GET /patients/{id}/caregivers` | caregivers | C19 |
| `GET /patients/{id}/consents` | caregivers | C18 |
| `POST /consents/{id}/revoke` | manager | C18 |
| `GET /patients/{id}/devices` | any linked | C1, C16 |
| `DELETE /devices/{id}` | manager | C16 |
| `GET /patients/{id}/people?status=active\|archived` · `GET /people/{id}` | any linked | C3, C4, C5 |
| `POST /patients/{id}/people` (multipart) · `POST /people/{id}/photos` · `DELETE /people/{id}/photos/{photo_id}` · `PATCH /people/{id}` · `DELETE /people/{id}` | manager | C4, C5, D6 |
| `GET /patients/{id}/unknown-faces` | caregivers | C6, C7 |
| `POST /unknown-faces/{id}/promote` · `POST /unknown-faces/{id}/dismiss` | manager | C7 |
| `GET /patients/{id}/reminders[/{rid}]` | any linked | C8, P2 |
| `POST/PATCH/DELETE /patients/{id}/reminders[/{rid}]` | manager | C8, C9 |
| `POST /patients/{id}/reminder-logs:batch` | phone + manager | P2, P3 |
| `GET /patients/{id}/reminder-logs?date=` | any linked | C1, C8 |
| `GET /patients/{id}/places[/{pid}]` | any linked | C10 |
| `POST/PATCH/DELETE /patients/{id}/places[/{pid}]` | manager | C10, C11 |
| `POST /patients/{id}/events:batch` | phone + manager | relay |
| `GET /patients/{id}/journal?date=` | any linked | C12, P4, D4 |
| `POST /patients/{id}/uploads` · `POST /uploads/{id}/complete` | phone + manager (audio: phone only) | relay |
| `GET /patients/{id}/media/{media_id}` | any linked (audit-logged) | C13, P5 |
| `POST /media/{id}/pin` | manager | C13 |
| `DELETE /media/{id}` | phone + manager | C13, P5 |
| `GET /patients/{id}/documents?type=&limit=&offset=` | any linked | C14, C15 |
| `POST /patients/{id}/mind-game-sessions` | phone + manager | P7–P9 |
| `GET /patients/{id}/mind-game-sessions?game_type=&limit=&offset=` | any linked | P7 |
| `GET /patients/{id}/daily-summary?date=` | any linked | C17 |
| `POST /patients/{id}/assist` | any linked | P6 |
| `GET /caregivers/me/alerts?unread_only=&limit=&offset=` · `POST /alerts/{id}/read` | caregiver (own alerts only) | C1, C2 |
| `POST /me/push-token` | caregiver | (startup) |

**AI stubs until later phases:** `/assist` returns a fixed answer in the final shape (real in 9.1). Daily summaries, documents, unknown faces and media review are produced by worker jobs (Phase 6+), so those lists stay empty until then. Enrollment face embeddings are computed by a stub (`model_version: "stub-0"`) until the real face model is wired in; the glasses can't recognise stub embeddings yet.

**Images: one request per screen, cached by id.** Lists already include signed URLs (people `photo_url`, journal `media[].url` + `thumbnail_url`, documents `url` + `thumbnail_url`, unknown faces `sample_url` + `sample_thumbnail_url`), so never call `GET /media/{id}` per thumbnail. **In lists and grids show `thumbnail_url`** (a ~320 px JPEG, ~30 KB); open `url` (full photo) only on the detail screen. `thumbnail_url` is `null` for videos and for photos whose preview couldn't be made: then use `url`. Signed URLs change on every response and expire after 10 minutes: cache images **by the item's id**, not by URL (e.g. `CachedNetworkImage(imageUrl: url, cacheKey: id)`), and re-fetch the list if an image fails with 403 (expired).

#### Patient settings, caregivers, consents, devices · screens C1, C16, C18, C19
- `PATCH /patients/{id}` with any of `{ "full_name", "preferred_language": "ar|en", "timezone", "date_of_birth", "memory_capture_enabled": false }` → the patient (same shape as `POST /patients`). The phone gets the change through `/sync` `settings`.
- `GET /patients/{id}/caregivers` → `[ { "id", "caregiver_id", "full_name", "email", "relationship", "permission", "is_primary" } ]`, primary first.
- `GET /patients/{id}/consents` → `[ { "id", "consent_type", "subject_person_id", "subject_name", "given_by", "given_at", "revoked_at" } ]`, newest first. `POST /consents/{id}/revoke` → that consent with `revoked_at` set. Revoking a `face_enrollment` consent **archives the person** (face data deleted).
- `GET /patients/{id}/devices` → `[ { "id", "patient_id", "serial_number", "firmware_version", "battery_level_pct", "last_seen_at", "paired_at", "online" } ]`. `online` = a heartbeat in the last 5 minutes.
- `DELETE /devices/{id}` → `204`. The phone's device token stops working at once (`401`); pairing the glasses again (`POST /devices/pair`, any patient) issues a new one.

#### `GET /patients/{id}/reminder-logs?date=YYYY-MM-DD` · screens C1, C8
One day (patient's timezone, default today), by time: `[ { "id", "reminder_id", "title", "type", "scheduled_at", "status", "snoozed_until", "completed_at", "confirmed_via", "updated_at" } ]`.

#### `GET /patients/{id}/sync?since=`
```json
// 200. First call: no since → everything ("full": true). Later: since = the last server_time.
{ "server_time": "2026-10-12T09:20:00Z", "full": false,
  "settings": { "full_name": "فاطمة محمود", "preferred_language": "ar", "timezone": "Africa/Cairo", "memory_capture_enabled": true },
  "people":    { "upserts": [ { "id": "…", "name": "أحمد", "relationship": "son",
                                "embeddings": ["base64 (512 × float16, little-endian)", "…"],
                                "model_versions": ["stub-0", "…"], "updated_at": "…" } ],
                 "deletes": ["…"] },
  "reminders": { "upserts": [ /* same shape as GET /reminders items */ ], "deletes": ["…"] },
  "places":    { "upserts": [ /* same shape as GET /places items */ ], "deletes": ["…"] } }
```
The window overlaps by 30 s, so the same row can come twice: apply upserts and deletes by id.

#### `POST /patients/{id}/people` (multipart/form-data) · screen C4
Fields: `name` (1–80), `relationship` (1–40), `consent_given` (`true`), `photos` (1–5 files, JPEG or PNG, ≤ 4 MB each; send the field once per file).
```json
// 201 (same shape for GET list items, PATCH, POST /people/{id}/photos)
{ "id": "…", "patient_id": "…", "name": "أحمد", "relationship": "son", "added_by": "caregiver_manual",
  "status": "active", "embedding_count": 2, "created_at": "…", "updated_at": "…" }
```
List items also carry `"photo_url"` (the first photo's ~320 px preview, signed). `?status=archived` lists archived people. `GET /people/{id}` adds `"photos": [ { "id": "…", "url": "https://…signed, 10 min", "thumbnail_url": "…or null" } ]` and `"enrolled_by_name": "Ahmed Mostafa"` (C5). `DELETE /people/{id}/photos/{photo_id}` removes that photo and its embedding and returns the person (`409 LAST_PHOTO` for the only one). `PATCH` takes `{ "name"?, "relationship"? }`. `DELETE` → `204`: the person is archived, their photos and face data are deleted, and past journal entries keep the name. At most 20 photos per person (`409 TOO_MANY_PHOTOS`).

#### Unknown faces · screen C7
`GET` → `[ { "id", "patient_id", "sighting_count", "distinct_days", "first_seen_at", "last_seen_at", "status": "awaiting_caregiver", "sample_url", "sample_thumbnail_url", "samples": [ { "id", "url", "thumbnail_url" } ] } ]`. `samples` = up to 3 photos of the face (C7), the clusterer's chosen one first; `sample_url` / `sample_thumbnail_url` repeat the first for the C6 card.
`POST /unknown-faces/{id}/promote` with `{ "name": "…", "relationship": "neighbour", "consent_given": true }` → `200 { "cluster": {…, "status": "promoted"}, "person": { person shape } }`. `POST …/dismiss` → the cluster with `"status": "dismissed"` and `"samples": []`: **all photos of that face are deleted at once** (sightings stay in the journal without photos). Deciding twice → `409 ALREADY_DECIDED`.

#### Reminders · screens C8, C9
```json
// POST request (PATCH: any subset; "spoken_text": null means "say the title")
{ "title": "دواء الضغط", "spoken_text": "ميعاد دواء الضغط", "type": "medication",
  "rrule": "FREQ=DAILY;BYHOUR=9;BYMINUTE=0", "dtstart": "2026-10-01T09:00:00+03:00",
  "timezone": "Africa/Cairo", "active": true }
// 201 / items in GET
{ "id": "…", "patient_id": "…", "title": "…", "spoken_text": "…", "type": "medication", "rrule": "…",
  "dtstart": "…", "timezone": "Africa/Cairo", "active": true, "created_by": "…", "updated_at": "…", "deleted_at": null }
```
`type`: `medication | appointment | task`. `rrule` is an RFC 5545 rule **without** DTSTART; `dtstart` must include a UTC offset. `DELETE` → `204`.

#### `POST /patients/{id}/reminder-logs:batch` · screens P2, P3
```json
{ "logs": [ { "id": "…", "reminder_id": "…", "scheduled_at": "2026-10-12T09:00:00+03:00",
              "status": "completed", "snoozed_until": null, "completed_at": "…", "confirmed_via": "voice",
              "at": "2026-10-12T09:01:10+03:00" } ] }
```
`status`: `pending | completed | snoozed | missed`; `confirmed_via`: `voice | app | caregiver`. **Merge rule** (spec §7.1): `completed` always wins; otherwise the newer `at` wins; a log that loses comes back in `duplicates`. Max 500 per call.

#### Places · screens C10, C11
```json
// POST request (PATCH: any subset)
{ "name": "البيت", "latitude": 30.0444, "longitude": 31.2357, "radius_m": 100 }
// 201 / items in GET
{ "id": "…", "patient_id": "…", "name": "البيت", "latitude": 30.0444, "longitude": 31.2357, "radius_m": 100,
  "created_by": "…", "updated_at": "…", "deleted_at": null }
```
`radius_m`: 20–2000, default 100. "Where am I?" is answered **on the phone** from these (spec §7.2).

#### `POST /patients/{id}/events:batch`
```json
{ "encounters": [ { "id": "…", "person_id": "… or null", "started_at": "…", "ended_at": "…",
                    "best_confidence": 0.94, "announced": true } ],
  "events": [ { "id": "…", "event_type": "encounter", "source": "glasses", "occurred_at": "…", "ended_at": null,
                "encounter_id": "…", "person_id": null, "reminder_log_id": null,
                "transcript_text": null, "language": null,
                "metadata": { "unknown_embedding": "base64 float16, only for an unknown face" } } ] }
```
`event_type`: `encounter | voice_query | reminder | mind_game_session | manual_note | user_requested_recording | document_captured | notable_moment_captured | memory_paused | memory_resumed`. Encounters only come from the phone (a caregiver's are `rejected`). Events from a caregiver are stored with `source: "app"`. Max 500 of each per call.

#### `GET /patients/{id}/journal?date=YYYY-MM-DD` · screens C12, P4
The day in the **patient's** timezone (default: today), oldest first.
```json
{ "date": "2026-10-12", "timezone": "Africa/Cairo",
  "entries": [ { "id": "…", "event_type": "encounter", "source": "glasses", "occurred_at": "…", "ended_at": null,
                 "person": { "id": "…", "name": "أحمد", "relationship": "son" },
                 "transcript_text": null, "language": null, "rendered_text": null, "metadata": {},
                 "media": [ { "id": "…", "asset_type": "image", "trigger": "encounter_keyframe", "status": "pending_review",
                              "duration_seconds": null, "expires_at": null, "url": "https://…signed, 10 min",
                              "thumbnail_url": "https://…signed ~320 px preview, or null" } ] } ] }
```

#### Uploads: photos, clips, audio
1. `POST /patients/{id}/uploads` with `{ "id": "<media or audio id>", "kind": "media" | "audio", "content_type": "image/jpeg" }` → `201 { "id", "key", "upload_url", "method": "PUT", "headers": { "Content-Type": "image/jpeg" }, "expires_in": 900 }`.
   Media: `image/jpeg | image/png | video/mp4`. Audio (phone only): `audio/ogg | audio/opus`.
2. `PUT` the file bytes to `upload_url` **with exactly those headers**, straight to S3 (no auth header).
3. `POST /uploads/{id}/complete`:
```json
// media (the event must already be sent through events:batch)
{ "patient_id": "…", "kind": "media", "content_type": "image/jpeg", "event_id": "…",
  "trigger": "encounter_keyframe | document_signal | salient_frame | user_requested", "duration_seconds": null }
// audio
{ "patient_id": "…", "kind": "audio", "content_type": "audio/ogg", "started_at": "…", "ended_at": "…" }
// 200
{ "id": "…", "kind": "media", "status": "pending_review" }
```
`user_requested` media is `confirmed` and kept for good; the rest waits for review (`pending_review`); audio is `uploaded`. Calling `complete` twice is safe. Before the PUT lands: `409 UPLOAD_MISSING`.

#### Media · screens C13, P5
`GET /patients/{id}/media/{media_id}` → the media fields (`id, patient_id, event_id, asset_type, trigger, status, ai_tags, contains_other_people, duration_seconds, retention_policy, expires_at, pinned_by, created_at`) plus `"url"` (signed, 10 min) and `"url_expires_in": 600`. Every view is audit-logged. `POST /media/{id}/pin` → the media fields with `retention_policy: "keep_indefinitely"`. `DELETE /media/{id}` → `204` (the file is removed from S3).

#### `GET /patients/{id}/documents?type=receipt` · screens C14, C15
`[ { "id", "event_id", "media_asset_id", "document_type": "receipt | bill | medication_label | other", "ocr_text", "extracted_fields": {}, "created_at", "url" } ]`, newest first, 50 per page. `url` is the signed photo.

#### `POST /patients/{id}/mind-game-sessions` · screens P7–P9
`{ "id": "…", "game_type": "face_match", "score": 8, "duration_seconds": 240, "completed_at": "…" }` → `201` with the same fields + `patient_id`. Sending the same id again returns the stored session. The game also appears in the journal. `GET` lists past games, newest first (`?game_type=` for one game's last score).

#### `GET /patients/{id}/daily-summary?date=` · screen C17
`200 { "patient_id", "summary_date", "summary_text", "patterns": {}, "generated_at" }` or `404 SUMMARY_NOT_READY`.

#### `POST /patients/{id}/assist` · screen P6
`{ "question": "مين جالي النهارده؟", "language": "ar" }` (`language` optional, defaults to the patient's) → `200 { "answer": "…", "language": "ar", "source_event_ids": [] }`. **Stub**: a fixed answer for now.

#### Alerts and push · screens C1, C2
`GET /caregivers/me/alerts` → `[ { "id", "patient_id", "alert_type": "missed_medication | unknown_person_flagged | low_battery | device_offline | daily_summary_ready", "message", "entity_type", "entity_id", "read_at", "created_at" } ]`. `entity_type` + `entity_id` say what to open on tap (`reminder_log`, `unknown_face_cluster`, `device`, `daily_summary`; may be null), newest first. `POST /alerts/{id}/read` → the alert with `read_at` set. `POST /me/push-token` with `{ "fcm_token": "…" }` → `204`; call it after every login.

---

## 6. Endpoints not built yet ⏳ (agreed in spec §7.2)

Flutter always calls the live API: if a screen needs an endpoint that isn't live yet, ask the lead.

| Endpoint | For screens | Phase |
|---|---|---|
| `POST /auth/google`, `POST /auth/facebook`, `GET /auth/identities`, `POST/DELETE /auth/link/{provider}` | A2, A3, C20, D7 | Phase 3 social sign-in (postponed) |

---

## 7. Changing the contract (contract-first)

1. Whoever needs a change opens a **docs PR editing spec §7.2** (new endpoint, field or enum value) and explains why.
2. **The lead approves it.** No contract change happens without that approval.
3. The backend implements it. `/docs` and `/openapi.json` update automatically on the next deploy.
4. Flutter updates its models and screens.

**Never:** rename or remove a field, change a type, or change an enum value silently. Adding an optional field or a new endpoint is safe. Breaking changes need the lead's approval and a coordinated release.

---

## 8. Test data on production

| What | Value |
|---|---|
| Caregiver (manager) | `ahmed@example.com` |
| Caregiver (viewer) | `mona@example.com` |
| Password for both | `SEED_PASSWORD` from the lead's `backend-ai/.env`: **shared privately, never in git or chat** |
| Patient | Fatma, `00000001-0000-4000-8000-000000000001` |
| Glasses | RMR-0007, `00000003-0000-4000-8000-000000000001`, device token = `SEED_DEVICE_TOKEN` (shared privately) |
| All fixed IDs | `backend-ai/docs/SEED_DATA.md` |

Locally (Docker), the password is `remori-local` and the device token is `local-device-token-RMR-0007`.

---

## 9. Who does what

| Need | Who acts |
|---|---|
| A new field or endpoint for a screen | Flutter dev asks the lead → spec PR → backend implements |
| A backend bug seen from the app | Flutter dev opens an issue with the request, the response, the `code`, and the screen ID |
| A response that differs from this contract | backend bug unless the contract changed: report it, don't work around it in the app |
| BLE message changes (spec §7.1) | lead + hardware + Flutter agree, then a spec PR first |
