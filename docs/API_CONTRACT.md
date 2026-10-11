# API contract: how backend and Flutter work together

The Flutter app and the backend are built in parallel by different people. They meet at one place: the REST API in spec §7.2. This file says how that contract is kept, changed and used.

---

## 1. The contract

| Item | Source |
|---|---|
| Endpoints, methods, paths | spec §7.2 |
| Request/response JSON shapes | spec §7.2 examples + §6 column names; after the API runs, FastAPI's OpenAPI at `/docs` and `/openapi.json` |
| Error shape | spec §7.5: `{"error": {"code": "PERSON_NOT_FOUND", "message": "..."}}` |
| Auth | Caregiver: `Authorization: Bearer <JWT>` (+ refresh token). Patient phone: device token. Spec §7.2 |
| Base path | `/api/v1` |

**Conventions both sides follow:**
- **IDs** are UUID strings. Records created offline (events, encounters, reminder logs, media, audio segments, game sessions) get their UUID **on the device**, and the backend accepts it (idempotent).
- **Timestamps** are ISO-8601 in UTC with `Z` (`2026-10-01T09:15:00Z`). The app converts to the patient's timezone for display.
- **Enum values** are lowercase snake_case, exactly as in spec §6 (`pending_review`, `memory_paused`).
- **JSON field names** are snake_case, the same as the database columns.
- **Media** never goes through the API body: request a presigned URL, upload to S3, then call `complete` (spec §7.2).

---

## 2. Changing the contract (contract-first)

1. Whoever needs the change opens a **docs PR that edits spec §7.2** (new endpoint, field, or enum value) and explains why.
2. **The lead approves it** (backend owner). No contract change happens without that approval.
3. The backend implements it. OpenAPI updates automatically.
4. Flutter updates its models and repositories.

**Never:** rename or remove a field, change a type, or change an enum value silently. Additive changes (a new optional field or a new endpoint) are safe. Breaking changes need the lead's approval and a coordinated release.

---

## 3. Working in parallel before the backend exists

- Flutter builds every repository **twice**: a `Mock…Repository` and a real one. The mock returns the UI brief's sample data (§6 of [`UI_SCREENS_BRIEF.md`](UI_SCREENS_BRIEF.md)) **in the exact JSON shape of spec §7.2**, parsed through the same model classes the real API will use.
- A single switch (provider override or build flag) chooses mock or real. When an endpoint goes live, Flutter flips that repository to real and nothing else changes.
- The backend's seed script loads the **same** sample data (Fatma, Ahmed, the reminders), so the app looks the same against mock and real.

---

## 4. Running both together locally

| What | How |
|---|---|
| Backend | inside `backend-ai/`: Docker Compose dev stack (API + Postgres + Redis), API on `http://localhost:8000`, docs at `/docs` |
| Android emulator → your laptop | base URL `http://10.0.2.2:8000/api/v1` (the emulator's alias for the host machine) |
| Real phone on the same Wi-Fi | base URL `http://<laptop-LAN-IP>:8000/api/v1` |
| Deployed backend | the EC2 URL (HTTPS), given by the lead |

The base URL is a build-time setting in Flutter, never hard-coded in screens.

---

## 5. Who does what

| Need | Who acts |
|---|---|
| A new field or endpoint for a screen | Flutter dev asks the lead → spec PR → backend implements |
| A backend bug seen from the app | Flutter dev opens an issue with the request, response and screen ID. Backend fixes it |
| A response shape that differs from the spec | It's a backend bug unless the spec changed. Report it, don't work around it in the app |
| BLE message changes (spec §7.1) | Lead + hardware + Flutter agree, then spec PR first |
