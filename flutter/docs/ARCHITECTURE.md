# flutter — Architecture

Source of truth: [`REMORI_SPEC.md`](../../REMORI_SPEC.md) §10 (decisions D6, D8). Diagrams: `docs/diagrams/01-architecture.md` §1.7–1.8.

---

## 1. Stack (decided in the spec)

| Concern | Choice |
|---|---|
| State management | Riverpod |
| Navigation | GoRouter with two shells: Caregiver and Patient |
| HTTP | dio, one `ApiClient` for `/api/v1` |
| Sign-in | `google_sign_in` + `flutter_facebook_auth` (spec D26). The app sends the provider token to the backend and stores only Remori's tokens |
| Local database | drift (SQLite) |
| Push | Firebase Cloud Messaging |
| Platforms | Android + iOS. The glasses relay is Android-only in v1 |
| Secure storage | `flutter_secure_storage`: auth tokens and the patient phone's device token (D31) |
| Camera QR + permissions | `mobile_scanner` (A5), `permission_handler` (A6) (D31) |
| Images + fonts | `flutter_svg`; DM Sans, Manrope and Readex Pro bundled in `assets/fonts` (D31) |
| Glasses link | `flutter_blue_plus` for BLE (spec §7.1), behind `GlassesConnection` (§5) (D31) |
| Utilities | `uuid` (client IDs), `intl`, `path_provider` + `sqlite3` (drift) (D31) |

Adding any other package is a lead decision.

---

## 2. Folder map (feature-first)

```
flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                 # MaterialApp.router, theme, localization
│   ├── core/
│   │   ├── api/                 # ApiClient (dio), auth interceptor, error mapping (spec §7.5)
│   │   ├── db/                  # drift database, tables, outbox
│   │   ├── sync/                # sync engine: upload outbox, delta pull (GET /sync?since=)
│   │   ├── relay/               # RelayService interface + android/ (+ ios/ later): BLE, Wi-Fi burst, GPS
│   │   ├── router/              # GoRouter: entry, caregiver shell, patient shell
│   │   ├── theme/               # ThemeData, status colors, patient vs caregiver scales
│   │   └── l10n/                # Arabic + English strings
│   └── features/
│       ├── auth/  device_pairing/  enrollment/  unknown_faces/  journal/
│       ├── reminders/  places/  assistant/  mind_games/  caregiver_dashboard/
│       └── <feature>/
│           ├── data/            # repositories (live API + local drift), DTOs
│           ├── domain/          # entities (plain Dart), use cases if needed
│           └── presentation/    # screens (named by screen ID), widgets, Riverpod providers
├── test/
└── pubspec.yaml
```

---

## 3. Rules per layer

| Layer | Rule |
|---|---|
| **presentation** | Widgets read Riverpod providers only. No dio, no SQL, no BLE calls in widgets. Screen files carry the UI board's screen ID (`c4_add_person_screen.dart`) |
| **domain** | Plain Dart entities that match spec §6/§7.2 fields. No Flutter imports |
| **data** | Repositories own data access: drift for reads, outbox for writes, ApiClient (the live API) for sync |
| **core/relay** | Everything platform-specific sits behind `RelayService`. The rest of the app never knows whether it's Android or iOS |

---

## 4. Offline-first flow

1. The UI reads **only** from drift.
2. A write goes to drift **and** to the outbox in one transaction, with a **client-generated UUID**.
3. The sync engine uploads the outbox when online (idempotent batch endpoints), then delta-pulls `GET /patients/{id}/sync?since=<last>`.
4. Conflicts follow spec rules (e.g. reminders: `completed` always wins, else latest timestamp).

---

## 5. Relay (patient's Android phone only)

- An Android **foreground service** (persistent notification D1) runs the BLE link, outbox uploads, reminder sync + local notifications, and GPS for "Where am I?".
- BLE messages are exactly spec §7.1. Adding or changing a message is a contract change (lead + hardware + Flutter).
- **All glasses communication goes through one `GlassesConnection` interface**, provided by Riverpod (D31). Screens never know which implementation they get:
  - `FakeGlassesConnection` (**development builds only**, until the glasses run the §7.1 service): sends real §7.1 messages: `hello` with the paired serial, `telemetry` every 60 s, now and then an `encounter` or a reminder state change. It can be switched to "disconnected" to show D5. With it, A6 can hand the phone over to Patient Mode.
  - `BleGlassesConnection` (`flutter_blue_plus`): the real link. Release builds use only this one.
- The pairing QR on the glasses case is the plain serial (spec §7.1). Test codes RMR-0008 … RMR-0015 come from the lead.
- The iOS relay is a stretch goal behind the same `RelayService` interface.

---

## 6. Testing

- Unit tests for repositories and sync logic (a test double for the HTTP client + in-memory drift).
- Widget tests for each screen, with the repositories overridden in Riverpod.
- Patient Mode widget tests check the big-text / big-button rules and RTL layout.
