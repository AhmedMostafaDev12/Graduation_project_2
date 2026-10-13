# flutter — Agent instructions

The Remori companion app: **Patient Mode** (Arabic-first, very simple) and **Caregiver Mode**, one Flutter codebase for Android + iOS. On the patient's Android phone it also **relays** for the glasses (BLE, uploads, GPS).
Read the root [`AGENTS.md`](../AGENTS.md) first. Its rules apply here too.

---

## 1. What to build: exactly this, nothing more

| Source | Use it for |
|---|---|
| [`design/screens/`](design/screens/README.md) | **the screens.** Every screen (IDs A0–A6, C1–C20, P1–P9, D1–D7) as HTML + CSS (exact layout, colors, fonts, spacing, text) with a PNG of each and its images. Exported from the UI board (https://claude.ai/artifact/C5jiujr2ASCXQiREpHPCdW), which the lead edits. |
| §1.1–1.3 below | which endpoints each screen calls, the Patient Mode rules, and what never to build |
| [`docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) | how the app talks to the backend: endpoints, auth, error codes, base URLs |
| spec §7.2 | endpoints and JSON shapes |
| spec §7.1 | BLE messages with the glasses (relay) |
| spec §10 | app architecture decisions |

If a screen, field, button or behavior isn't on the board, **don't build it**. Ask the lead.

**Building a screen (agents):** read `design/screens/png/<ID>.png` to see it and `design/screens/<ID>.html` for the exact values. Don't edit those files; design changes go through the lead, who updates the board and re-exports.
The board draws an iPhone status bar at the top of each screen only to show the reserved space: the phone draws the real one, so wrap screens in `SafeArea`.

### 1.1 Endpoints per screen

| Screen | Endpoints |
|---|---|
| A2 Login | `POST /auth/login`, `POST /auth/google`, `POST /auth/facebook` (D26) |
| A3 Sign up | `POST /auth/register`, `POST /auth/google`, `POST /auth/facebook` |
| A4 New patient + consent | `POST /patients` (with consents) |
| A5 Pair glasses | `POST /devices/pair` |
| A6 Permissions | Android / iOS permissions only |
| C1 Home | `GET /patients`, `GET /patients/{id}/devices`, `GET /patients/{id}/reminder-logs?date=`, `GET /patients/{id}/journal`, `GET /caregivers/me/alerts` |
| C2 Alerts | `GET /caregivers/me/alerts`, `POST /alerts/{id}/read` |
| C3 People | `GET /patients/{id}/people?status=active\|archived`, `GET /patients/{id}/unknown-faces` |
| C4 Add person | `POST /patients/{id}/people` |
| C5 Person detail | `GET/PATCH/DELETE /people/{id}`, `POST /people/{id}/photos`, `DELETE /people/{id}/photos/{photo_id}` |
| C6 Unknown faces | `GET /patients/{id}/unknown-faces` |
| C7 Unknown face detail | `POST /unknown-faces/{id}/promote`, `POST /unknown-faces/{id}/dismiss` |
| C8 Reminders | `GET /patients/{id}/reminders`, `GET /patients/{id}/reminder-logs?date=` |
| C9 Add / edit reminder | `POST/PATCH/DELETE /patients/{id}/reminders` |
| C10 Places | `GET /patients/{id}/places` |
| C11 Add / edit place | `POST/PATCH /patients/{id}/places` |
| C12 Journal | `GET /patients/{id}/journal?date=` |
| C13 Media | `GET /patients/{id}/media/{id}`, `POST /media/{id}/pin`, `DELETE /media/{id}` |
| C14 Documents | `GET /patients/{id}/documents` |
| C15 Document detail | `GET /documents/{id}` |
| C16 Device | `GET /patients/{id}/devices`, `PATCH /patients/{id}` (memory switch), `POST /devices/pair`, `DELETE /devices/{id}` |
| C17 Daily summary *(Phase 2)* | `GET /patients/{id}/daily-summary?date=` |
| C18 More | `PATCH /patients/{id}`, `GET /patients/{id}/consents`, `POST /consents/{id}/revoke`, `GET /auth/me`, `POST /auth/logout` |
| C19 Caregivers | `GET /patients/{id}/caregivers`, `POST /patients/{id}/caregivers` |
| C20 Connected accounts | `GET /auth/identities`, `POST/DELETE /auth/link/{provider}` (D26) |
| P1 Today, P2 Reminders, P3 Reminder alert | local drift data (synced reminders + logs) |
| P4 My Day, P5 Memory detail | `GET /patients/{id}/journal` (cached), `DELETE /media/{id}` |
| P6 Ask *(Phase 2)* | `POST /patients/{id}/assist` |
| P7 Games, P9 Result | `GET/POST /patients/{id}/mind-game-sessions` |
| D7 Account exists | `409 ACCOUNT_EXISTS` from A2 (D26) |

Exact paths and JSON: [`API_CONTRACT.md`](../docs/API_CONTRACT.md) and `/docs` on the live API.

### 1.2 Patient Mode rules (people living with dementia)

- Body text ≥ 22sp, titles ≥ 30sp, buttons ≥ 64dp tall.
- One idea per screen, at most 4 items visible. No hidden gestures, no swipe-only actions.
- Arabic first (RTL), high contrast. Never show error codes, IDs or technical words.
- **No editing** of people, reminders, places, consent or settings.
- Missed / offline states are soft, never alarming.

### 1.3 Never build (it would contradict the system)

- Live camera or video stream from the glasses (they never stream).
- Audio playback of conversations (audio is deleted after transcription).
- Live GPS tracking or a patient location map for caregivers.
- Chat, messaging, video or voice calls.
- A password login for the patient (Patient Mode signs in with the paired device).
- Face-recognition thresholds, AI model settings, wake-word setup, AR display settings.
- An iOS glasses-relay setup (the relay is Android-only in v1).
- Social features, sharing, payments, subscriptions, ads, admin panels.

---

## 2. Topic docs

| Doc | Read when you… |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | create a feature, a repository, a provider or a route, or touch offline sync or the relay |

---

## 3. Rules

1. **Ask the lead before any decision the spec doesn't make**: new package, new screen, new field, state-management pattern, navigation change. Propose options; don't pick.
2. **Stay inside `flutter/`.** Backend or contract changes go through the lead ([`API_CONTRACT.md`](../docs/API_CONTRACT.md) §2).
3. **One screen or flow per PR**, with the screen ID in the branch, commit and PR title (`feature/c4-add-person`).
4. **Use the live API.** Every screen talks to the backend at `/api/v1` exactly as [`API_CONTRACT.md`](../docs/API_CONTRACT.md) describes. If a screen needs an endpoint that isn't live yet, ask the lead; don't fake the data in the app.
5. **Offline-first.** The UI reads from the local database (drift), never directly from the network.
6. **Patient Mode rules** (§1.2): body ≥ 22sp, buttons ≥ 64dp, at most 4 items per screen, no editing, Arabic RTL first, no technical words or error codes.
7. **Both languages** (Arabic + English) for every string, through localization files. No hard-coded user-facing text.
8. **Never put secrets, tokens or base URLs in code.** They come from build configuration.

---

## 4. Commands (run before every push; CI runs the same)

```bash
cd flutter
dart format .          # CI: dart format --set-exit-if-changed
flutter analyze        # must be clean
flutter test
```

---

## 5. Current step

App shell, GoRouter with both mode entry points, drift setup, ApiClient, caregiver auth.

**The backend is live** at `https://remori-ai.duckdns.org/api/v1` (try it at `/docs`). Build every screen against it: every endpoint the screens need is live (people, reminders, places, sync, journal, media, documents, alerts, …), and alerts appear by themselves every 5 minutes. The full contract (endpoints, auth, error codes, test accounts): [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md).
