# API contract: how the backend and the Flutter app talk

The Flutter app and the backend are built in parallel by different people. They meet in one place: the REST API. This file is **the contract**: where the API lives, the rules both sides follow, every endpoint that's live today with its exact request and response, and the error codes.

Last updated: 12 Oct 2026, after Phase 4 (backend deployed).

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
| 404 | `NOT_FOUND` | the URL doesn't exist | bug in the app |
| 409 | `EMAIL_TAKEN` | registering an email that already has an account | offer login instead |
| 409 | `ALREADY_LINKED` | that caregiver is already linked to the patient | show as already added |
| 409 | `DEVICE_ALREADY_PAIRED` | these glasses belong to another patient | "These glasses are paired with someone else" |
| 422 | `VALIDATION_ERROR` | a field is missing or wrong; see `details` | highlight the fields |
| 503 | `DATABASE_UNAVAILABLE` | the server can't reach the database | "Try again in a moment" |

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

---

## 6. Endpoints not built yet ⏳ (agreed in spec §7.2)

These are being built in Phase 5 (`backend-ai/docs/DEVELOPMENT_PLAN.md`) and move to §5 as they go live. Flutter always calls the live API: if a screen needs an endpoint that isn't live yet, ask the lead.

| Endpoint | For screens | Phase |
|---|---|---|
| `GET/POST /patients/{id}/people`, `POST /people/{id}/photos`, `PATCH/DELETE /people/{id}` | C3, C4, C5, D6 | 5.1 |
| reminders CRUD, `POST /patients/{id}/reminder-logs:batch` | C8, C9, P2, P3 | 5.2 |
| places CRUD | C10, C11 | 5.3 |
| `GET /patients/{id}/sync?since=` (delta pull) | relay, offline | 5.4 |
| `POST /patients/{id}/events:batch`, `GET /patients/{id}/journal?date=` | C12, P4, D4 | 5.5 |
| `POST /patients/{id}/uploads`, `POST /uploads/{id}/complete`, `GET /patients/{id}/media/{media_id}`, `POST /media/{id}/pin`, `DELETE /media/{id}` | C13, P5 | 5.6 |
| `GET /patients/{id}/documents` | C14, C15 | 5.7 |
| `GET /caregivers/me/alerts`, `POST /alerts/{id}/read`, `POST /me/push-token`, `POST /patients/{id}/mind-game-sessions`, unknown-faces list / promote / dismiss | C1, C2, C6, C7, P7–P9 | 5.8 |
| `POST /patients/{id}/assist` (fixed answers first), `GET /patients/{id}/daily-summary` | P6, C17 | 5.9 → real in 9.1 / 9.2 |
| `POST /auth/google`, `POST /auth/facebook`, `GET /auth/identities`, `POST/DELETE /auth/link/{provider}` | A2, A3, C20, D7 | Phase 3 social sign-in (postponed) |

**Proposed, not in the spec yet** (waiting for the lead's decision): `GET /patients` (list my patients, for the C1 patient switcher) and `GET /auth/me` (the logged-in caregiver).

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
