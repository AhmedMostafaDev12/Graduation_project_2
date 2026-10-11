# flutter — Agent instructions

The Remori companion app: **Patient Mode** (Arabic-first, very simple) and **Caregiver Mode**, one Flutter codebase for Android + iOS. On the patient's Android phone it also **relays** for the glasses (BLE, uploads, GPS).
Read the root [`AGENTS.md`](../AGENTS.md) first. Its rules apply here too.

---

## 1. What to build: exactly this, nothing more

| Source | Use it for |
|---|---|
| [`docs/UI_SCREENS_BRIEF.md`](../docs/UI_SCREENS_BRIEF.md) | the **40 screens** (IDs A1–A6, C1–C19, P1–P9, D1–D6), their fields, and the "do NOT design" list |
| UI board (clickable wireframes, link from the lead) | layout and flows |
| [`docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) | how the app talks to the backend, mock vs real repositories, base URLs |
| spec §7.2 | endpoints and JSON shapes |
| spec §7.1 | BLE messages with the glasses (relay) |
| spec §10 | app architecture decisions |

If a screen, field, button or behavior isn't in these, **don't build it**. Ask the lead.

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
4. **Mock first.** Every repository has a mock that returns the UI brief's sample data in the exact spec §7.2 JSON shape. Switch to the real API per repository when its endpoint goes live.
5. **Offline-first.** The UI reads from the local database (drift), never directly from the network.
6. **Patient Mode rules** (UI brief §3): body ≥ 22sp, buttons ≥ 64dp, at most 4 items per screen, no editing, Arabic RTL first, no technical words or error codes.
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

Build order (spec §12), step 4: app shell, GoRouter with both mode entry points, drift setup, ApiClient, caregiver auth. All repositories start as mocks.
