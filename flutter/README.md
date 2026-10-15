# Remori companion app

Flutter app for Android and iOS. Dart package: `remori`. Application identifier:
`org.AI.remori`. Display name: Remori.

Read `AGENTS.md` and `docs/ARCHITECTURE.md` before making changes. Screen references
are in `design/screens/`; preserve those exports.

The app includes the native projects, application entry point, shared theme, and reusable controls.
Foundations include GoRouter, ApiClient, drift/outbox, and Arabic/English localization. A0 Splash is implemented; authentication integration and the remaining screens follow separately.

From this folder:

```sh
flutter pub get
flutter run
dart format .
flutter analyze
flutter test
```

Use the Dart SDK bundled with Flutter. iOS build validation requires macOS and
Xcode; device installation also requires the signing setup described in the spec.
## Shared UI foundation

`lib/core/theme/` holds the exported design colors, caregiver/patient themes,
buttons, cards, chips, inputs, logo, background painters, and four-destination
notched navigation bar. The shell will choose the mode, language, labels, icons,
and callbacks. Components do not fetch data or choose routes.

Fonts are bundled from Google Fonts (`ofl/dmsans`, `ofl/manrope`, and
`ofl/readexpro` in https://github.com/google/fonts), with their OFL licenses in
`assets/fonts/`. The logo is copied from the design export and contains vector
outlines for its wordmark; no separate Cherry Bomb One font is needed.

Patient body text uses at least 22sp, titles 32sp, and buttons at least 64dp.
Navigation height expands for larger accessibility text. System bars are handled
by `SafeArea`. Localized strings belong to future screens; components accept
labels from their callers.

Review previews (test fixtures, not app screens):

- [Caregiver components](test/goldens/caregiver_components.png)
- [Patient components, Arabic RTL](test/goldens/patient_components.png)

Regenerate previews with:

```sh
flutter test test/theme_widgets_test.dart --update-goldens
```

Regular tests check interactions, semantics, RTL, large text, and rendering.
Preview images are exported on demand rather than compared across Windows/Linux
rasterizers. Native device builds and full-screen comparisons follow when the
individual screens are implemented.

## Routing foundation

`lib/core/router/` registers routes by exported screen ID (`/a0`, `/c1`, `/p1`,
etc.) in GoRouter, with separate Caregiver and Patient `ShellRoute`s. The app
starts in a Riverpod `ProviderScope` and uses `MaterialApp.router`.

- `routeAccessProvider`: future authentication supplies caregiver/device access
  after secure credential restoration. The optional `entryMode` is the selected
  mode; the router does not guess which credential should take priority.
- Caregiver screens and A4-A6 require caregiver authentication. Patient screens
  require a paired device credential. Unauthorized navigation goes to A2,
  matching the caregiver setup entry in the export. API authorization remains
  the server's responsibility.
- `screenBuildersProvider`: future feature PRs supply screen body builders.
  The router and shells own Scaffold, backgrounds, SafeArea, and shell navigation.
  Unimplemented screens are empty slots, with no mock records or success flows.
- Shell labels come from generated Arabic/English ARB resources. The optional
  `shellLabelsProvider` override is used by routing tests; production navigation
  uses localized labels and direction.
- Caregiver destinations: C1, C3, C8, C18; center action pushes C9. Patient
  destinations: P1, P2, P4, P7; center action pushes P6. Detail screens omit the
  navigation bar, as in the HTML, and pushed routes retain the back destination.
- D1-D3 represent OS notifications, and D4-D6 are existing-screen variants.
  They are not standalone routes. D7 is an entry-flow route.

Router tests override the access, screen-builder, and shell-label providers.
They verify entry/deep links, separate credential guards, both navigation bars,
back behavior, RTL typography, and access revocation without recreating GoRouter.
The app intentionally still shows no finished screens; authentication and actual
feature content are separate planned PRs. Shell labels are localized.

## ApiClient foundation

`lib/core/api/` provides dio transport, build configuration, secure credential
storage, and typed Remori error mapping. Repositories will access it through
`apiClientProvider`; widgets still read repository providers and drift.

Supply the API base URL when running or building:

```sh
flutter run --dart-define=REMORI_API_BASE_URL=https://remori-ai.duckdns.org/api/v1
```

There is no source-code default. Configuration is validated lazily when the client
is used. Release configuration requires HTTPS; debug/test configuration may use
the development URLs in the API contract. Native cleartext permissions, if needed
for a debug backend, are separate platform setup.

Every request explicitly selects `ApiCredential.none`, `caregiver`, or `device`.
Use `none` for register/login/refresh/logout. Login sends form data with `username`
and `password` using `Headers.formUrlEncodedContentType`; most endpoints use JSON.
Tokens are acquired by future auth/pairing repositories, not build configuration.

Caregiver access/refresh tokens are saved together in one secure-storage value.
Device credentials use a separate key. The auth interceptor coordinates concurrent
401 TOKEN_EXPIRED responses, saves the rotated pair before replaying the original
request once, and handles delayed responses referring to the old token.
Multipart forms are cloned for replay; one-shot streams are not retried. Logout
or another login during refresh prevents restoration of the previous session.
Transient refresh errors retain credentials. Invalid refresh/device credentials
clear only the affected credential and signal `credentialsInvalidatedProvider`;
the auth integration PR must connect that signal to route access/login.

`ApiFailure` preserves the server code and field errors for localized presentation.
Network, timeout, cancellation, malformed-response, and storage failures have
separate kinds. Exception strings omit raw messages, request payloads, and tokens.
There are no request or token loggers.

The API transport rejects absolute/external URLs and traversal, and does not follow
redirects. Upload presigned S3 URLs with a separate unauthenticated transport and
exactly the headers returned by the API. Never use this client to PUT S3 bytes.

Tests use dio adapter doubles and secure-storage mocks; they do not access the
live API. Real auth screens, secure-storage device validation, API smoke tests,
and native Android/iOS build validation remain for their integration PRs.

## Drift and outbox foundation

`databaseProvider` lazily opens schema version 5 in the private application-support
folder (`remori.sqlite`) using drift's background native executor. SQL logging is
disabled. Tests override the executor with in-memory SQLite or a temporary file.
Tokens remain exclusively in secure storage.

This skeleton includes local reminder logs and a patient-scoped transactional
outbox. Other entity-cache tables arrive with their feature PRs. It does not create
or change any backend table, field, or endpoint.

C1 adds the approved caregiver-scoped patients, devices, alerts and latest daily
statistics read caches. The v1→v2 migration retains reminder logs and outbox writes.

- `saveReminderLog` generates a UUID v4 for a new occurrence, or retains a supplied
  occurrence UUID for changes. Local data and its API snapshot commit together.
- Merge rules match D6: completed wins, otherwise newer `at` wins. UTC timestamps
  are stored as integer microseconds so close updates retain their ordering.
- `writeAndEnqueue` lets future repositories persist their typed local entity and
  immutable JSON upload snapshot in one transaction. Outbox kinds cover events,
  encounters, reminder logs, and game sessions, the specified client-ID writes.
- Each queued snapshot has an operation UUID and a monotonically increasing local
  sequence. These are local transport metadata, not fields sent to the API. The
  payload retains the record's stable API UUID.
- Reads, pending counts, and acknowledgement deletion are patient-scoped. Batches
  are ordered and limited to 500. Acknowledgement removes only captured operation
  UUIDs, so receipts cannot discard newer updates or cached records.

The sync engine is a later integration: build the contracted request arrays, map
accepted/duplicate record IDs back to the captured operation IDs, and acknowledge
only successful receipts. Keep rejected or failed writes for explicit handling;
never treat an HTTP 200 batch response as accepting every item. This PR performs
no uploads or delta pulls. Reminder scheduling, remote-to-cache ingestion, other
cache tables, logout/cache lifecycle, and native device validation also follow
separately. Server-ID caregiver creates are not placed in this UUID batch outbox.

Generated drift code is committed so existing CI checks can run without an extra
code-generation step. After changing tables, regenerate it and run the checks:

```sh
dart run build_runner build
dart format .
flutter analyze
flutter test
```

## Arabic/English localization foundation

`lib/core/l10n/app_en.arb` and `app_ar.arb` are the string sources. Flutter gen-l10n
produces the typed `AppLocalizations` API; screens access strings through
`AppLocalizations.of(context)`. Add every new user-facing string to both files.
The foundation currently includes shell destination and center-action labels;
individual screen strings are added in their feature PRs.

MaterialApp registers Arabic and English delegates, including localized Flutter
controls and layout direction. `appLocaleProvider` defaults to the device locale,
with English fallback for unsupported languages. `patientLocaleProvider` defaults
to Arabic and provides the integration point for the synced patient profile's
preferred_language. Both providers may be overridden by profile/auth integration;
no persisted app preference or new settings screen is introduced.

Patient shells override their locale independently of the caregiver/app locale.
Arabic uses RTL and Readex Pro; English uses LTR and DM Sans/Manrope. Patient text
and control sizes remain large in either language. Locale changes do not recreate
the router or reset the current destination.

Generated localization files are committed for inspection. They are also generated
by Flutter's normal build/pub workflow because pubspec enables generate. After
editing ARBs, run:

```sh
flutter gen-l10n
dart format .
flutter analyze
flutter test
```

Tests check matching translation keys, both caregiver languages, Arabic-first and
English patient shells, accessibility action labels, fonts/direction, unsupported
locale fallback, and preservation of routing when the locale changes. Native
Android/iOS validation and complete screen comparisons remain integration work.

## A0 Splash

The signed-out entry now renders A0 from its PNG/HTML reference: exported logo,
cream curves, centered two-line tagline, Get Started pill with its exact arrow,
and support caption. All text and accessibility labels come from the Arabic and
English ARBs. System bars are native; SafeArea reserves their space.

The 390 x 844 layout matches the reference metrics. Short/narrow screens or larger
text can scroll to keep the action reachable. Get Started opens the existing A1
route, which now renders Mode Select. A0 calls no
API endpoint and has no repository/data model.

Review artifacts:

- [English reference-size render](test/goldens/a0_en.png)
- [Arabic reference-size render](test/goldens/a0_ar.png)
- [Pixel 9a Android emulator capture](test/goldens/a0_android.png)

Run from this folder with a booted emulator:

```sh
flutter run -d emulator-5554 --dart-define=REMORI_API_BASE_URL=https://remori-ai.duckdns.org/api/v1
```

To regenerate widget review captures:

```sh
flutter test test/a0_splash_test.dart --update-goldens
```

The screen is tested in both languages, for A1 navigation, native safe-area
reservation, and scrolling with 2x text on a 320 x 480 viewport. Android debug APK
build, installation, and the running screen were validated on Pixel 9a. iOS
validation remains pending.

If the local debugger reports a DDS/service-protocol connection error, add
`--no-dds` to the run command. That workaround was validated on this emulator.

## A1 Mode Select

A1 renders the exported 210dp logo, introduction, and two 52dp pill buttons
with the HTML spacing. Arabic and English copy comes from the ARBs; the router
owns the onboarding background and native safe area. Both choices open A2 Login
as the design specifies. A2 now renders caregiver login.

A1 has no API calls or stored mode selection. The existing router continues to
handle authenticated mode entry. Short screens and enlarged text can scroll to
both actions. Tests cover both links, Arabic RTL, safe areas, and 2x text in both
languages on a 320 x 480 viewport.

Review captures: [English](test/goldens/a1_en.png),
[Arabic](test/goldens/a1_ar.png). Native A1 validation remains pending because
Pixel 9a was offline in ADB during this change.
Regenerate the widget captures with
`flutter test test/a1_mode_select_test.dart --update-goldens`.
## A2 Caregiver Login

A2 follows the exported PNG/HTML, with Arabic and English strings, password
visibility, autofill, native safe areas, and scrolling for enlarged text and the
keyboard. The field and provider SVGs are copied from the design export.

The repository calls `POST /auth/login` anonymously using URL-encoded `username`
and `password`. Both tokens are saved in secure storage before route access is
granted. Authentication never uses drift or the outbox. The normal login opens
C1; the patient setup login opens A4. Sign up opens A3. A3 and A4 are implemented; C1 remains a route slot.

Stored caregiver credentials are checked using `GET /auth/me` on startup, with
the existing ApiClient handling token refresh. Invalidated credentials revoke
caregiver route access. A failed network check retains stored tokens and keeps
online route access closed. Device-token restoration and paired patient entry
remain part of the pairing integration.

As approved for this PR, Google, Facebook, and Forgot password remain visible
and disabled: social backend endpoints are postponed, and password reset has no
contract. Errors use local translations, never raw server messages. Duplicate
submission is blocked; password fields are cleared after successful navigation.

Review captures: [English](test/goldens/a2_en.png) and
[Arabic](test/goldens/a2_ar.png). Regenerate with
`flutter test test/a2_login_test.dart --update-goldens`.
Native A2 validation remains pending; emulator launch permission was declined.
Live credential-based smoke testing and iOS validation remain pending.
## A3 Caregiver Sign up

A3 follows its exported PNG/HTML: 120dp logo, four fields, 11dp spacing,
sign-up pill, provider controls, and Log in link. Arabic and English copy uses
ARBs; native safe areas and scrolling keep enlarged text and keyboard layouts
usable. The phone field is optional; name/email are required, and passwords
must be 8–128 characters. Server validation details highlight their fields
with local translations rather than raw messages.

The repository sends anonymous JSON to `POST /auth/register`. Registration
returns an account without storing tokens. The controller then calls the existing
`POST /auth/login` flow and opens A4 only after secure token persistence succeeds.
If login fails after account creation, registration is disabled and the user is
directed to the existing Log in link. Duplicate emails also offer login.
No authentication payload enters drift or the outbox.

Google and Facebook remain visible and disabled under the existing auth-screen
approval, while their backend integration is postponed. Email verification policy
is unchanged; the app uses the current backend contract.

Review captures: [English](test/goldens/a3_en.png) and
[Arabic](test/goldens/a3_ar.png). Regenerate with
`flutter test test/a3_signup_test.dart --update-goldens`.
A4 now renders patient profile and consent. Native Android/iOS and live registration smoke testing
remain pending; no emulator was connected during this change.
## A4 Patient Profile and Consent

A4 uses its exported PNG/HTML layout with one approved addition: the required
“Your relationship to the patient” text field, because `POST /patients` requires
it. The design export stays untouched. Name and relationship are required;
birth date is optional, uses DD / MM / YYYY, accepts Arabic digits, and rejects
calendar rollover. English is initially selected as in the design; timezone
starts with the API's Africa/Cairo default. Empty timezone uses the server default.

Consent starts unchecked. The JSON sends `ambient_audio_household` and
`cloud_processing` only when their respective boxes are checked. The UI does not
require either consent to create a profile, matching the API's empty-consent
default. Conversation capture still depends on backend consent and memory rules.

The repository calls authenticated `POST /patients`. Continue opens A5 only after
a valid server-issued patient UUID is returned, passing that ID in route state.
A5 now provides the approved QR/API association stage. Duplicate in-flight submits are blocked; there is no
background retry or offline queue for this non-idempotent identity-creation call.
No server profile data is rendered by A4; local profile caching/sync belongs to
the profile-reading screens. The next pairing screen must consume this patient ID;
resuming an interrupted setup after app restart remains integration work.

Every string uses Arabic/English ARBs. Field validation is translated locally,
and raw server messages are never displayed. The form, language chips, and
consent controls scroll with enlarged text and keyboard. The header returns to
A2 as specified by the design.

Review captures: [English](test/goldens/a4_en.png) and
[Arabic](test/goldens/a4_ar.png). Regenerate with
`flutter test test/a4_patient_profile_test.dart --update-goldens`.
Native Android/iOS and live patient-creation smoke testing remain pending;
no emulator was connected during this change.
## A5 Pair Glasses — approved QR/API stage

A5 follows the exported pairing screen, using the approved mobile_scanner package
for Android/iOS camera QR scanning. Camera starts only on Scan QR code. The
package owns camera lifecycle/disposal; no images are returned, uploaded, or
logged. QR content is a plain glasses-case serial; URL/JSON wrappers and other
barcode formats are ignored. No manual serial-entry feature is added.

The repository calls caregiver-authenticated `POST /devices/pair` with the serial
and the patient UUID supplied by A4. It validates the response’s device UUID,
patient/serial match, and nonempty token, then saves the device token in existing
secure storage. Presentation receives only safe metadata. Continue remains
disabled until association and storage succeed, then opens A6 with the patient ID.
A6 now provides the approved staged permission setup. Missing patient context blocks scanning/Continue.

If secure storage fails after pairing, Retry pairing reuses the received grant
in memory without posting again and rotating the token. This recovery does not
survive process termination; interrupted setup/recovery remains integration work.
Duplicate scanner callbacks and concurrent pairing requests are guarded.

As explicitly approved, BLE bonding, GATT connection, encryption-key provisioning,
and relay startup remain pending. Step 2 and successful status say Bluetooth is
pending. Backend association does not grant Patient Mode route access or claim a
Bluetooth connection. Both Continue guidance and device status distinguish linking
from full hardware pairing. Backend conflict errors are translated locally.

A4 pushes A5 while retaining the completed form. Back returns to that form, whose
created fields/consents are locked; Continue reuses the patient ID rather than
posting another patient. New setup after app restart still requires integration.

Android declares camera and internet permissions; camera hardware is optional so
permission/unavailable states can be shown. iOS includes camera usage text and
English/Arabic InfoPlist.strings registered as localized Xcode resources.

Review captures: [English](test/goldens/a5_en.png), [Arabic](test/goldens/a5_ar.png),
[linked English](test/goldens/a5_linked_en.png), and
[linked Arabic](test/goldens/a5_linked_ar.png). Regenerate with
`flutter test test/a5_pair_glasses_test.dart --update-goldens`.
Android debug APK build passed. Actual camera/device scans, live pairing smoke
tests, and iOS build/runtime validation remain pending.
## A6 Permissions — approved staged setup

A6 follows its PNG/HTML layout while reading real OS permission status. The board's
sample Granted badges are not hard-coded. Checking, granted, denied, limited,
blocked, and restricted states come from the permission service; limited/blocked
access opens app settings. No permission is requested automatically on entry.
Returning from system settings refreshes status, and failed checks clear stale
grants rather than displaying raw platform exceptions.

The approved permission_handler package checks/requests Android Bluetooth Scan and
Connect (legacy Bluetooth on API <=30), notifications, and foreground location.
Background activity opens Android's battery-optimization settings, falling back
to app settings on devices without that screen. Its status reflects the OS battery
exemption flag. It does not request background/Always location or a battery-exemption
permission, and it does not start a foreground service. Android compile SDK is 37
as required by the permission plugin; minimum and target SDK stay at Flutter defaults.

As approved, iOS shows notifications and caregiver continuation only. Android
shows the four rows and handover card. D31 enables handover when the successfully
paired glasses connection is ready (see below). Permission grants alone never enable Patient Mode.
Caregiver continuation opens C1 regardless of optional permission denial; C1 is
still a route slot. A6 calls no REST endpoint and stores no fake permission state.

A5 pushes A6 while keeping its linked state. Back returns to A5 without a new
pairing request or device-token rotation; patient context is preserved. Both
languages and 2x text are supported, including the Arabic arrow font fallback.

Review captures (mocked OS status fixtures):
[Android English](test/goldens/a6_android_en.png),
[Android Arabic](test/goldens/a6_android_ar.png),
[iOS English](test/goldens/a6_ios_en.png),
[iOS Arabic](test/goldens/a6_ios_ar.png).
Regenerate with `flutter test test/a6_permissions_test.dart --update-goldens`.

All 135 tests and analysis pass; the Android debug APK builds successfully.
Real-device permission dialogs/battery settings and iOS build/runtime validation
remain pending. BLE connection, key provisioning, and relay startup remain pending
under the previously approved staged pairing scope.
## Glasses connection foundation (D31)

All control messages use the typed §7.1 models in core/relay/glasses_message.dart.
glassesConnectionProvider owns one disposable connection. It selects the fake
only in non-release builds with --dart-define=REMORI_FAKE_GLASSES=true; default
and release builds select the explicitly unimplemented BLE transport. No real
BLE dependency, bonding, bulk transfer, relay service or screen wiring is added.

The fake emits connecting → connected and hello with the supplied serial. The
consumer must send time_sync immediately after hello: timers start only after
that handshake. Telemetry arrives every 60 seconds; battery starts at 76 and
falls one point every five minutes. Every three minutes it queues an unknown
encounter (no embedding), and every four minutes a completed reminder state.
UUIDs identify the encounter and reminder log; session and telemetry messages
retain the spec's ID-free shapes. These are simulated fixtures, not API records
or a substitute for real people/reminder synchronization.

Unacknowledged items are retried unchanged each minute and after reconnecting.
ack.ids removes queued items; ack.refs independently releases keyframe references.
Changing serial while items/references remain pending is rejected to avoid
replaying one device's data for another. Disconnect stops timers and preserves
the in-memory queue; disposal closes streams and cancels timers. The queue is
not persisted across process restarts. No message contents are logged.

debugGlassesDisconnectProvider supplies a disconnect callback only when the
active connection is fake in a non-release build. It supports tests and a future
debug toggle without adding any screen controls in this foundation PR.
A5/A6 behavior is unchanged. A6 patient handover is the next separate PR.

Run flutter test test/glasses_connection_test.dart for protocol round trips,
fake timers, acknowledgement/retry, lifecycle, debug hooks and release selection.
## A6 patient handover (D31)

On Android, A6 prepares the connection for the serial successfully paired on A5.
The development fake connects immediately when REMORI_FAKE_GLASSES=true in a
non-release build; the BLE placeholder leaves the existing pending text and
disabled handover button. iOS remains caregiver-only. A6 sends time_sync after
hello in UTC; profile timezone synchronization belongs to the full relay.

Handover verifies A5's saved device token using GET /patients/{id}/devices and
matches patient ID, device ID and serial. It records secure local session context,
clears caregiver credentials and opens the existing P1 Patient shell. Patient
routes use the device token; caregiver requests, late responses and token refresh
are blocked in Patient Mode. Caregiver/setup/login routes redirect to P1, and
handover replaces the onboarding stack. A5 still requires real API association;
fake BLE never fabricates a device token or bypasses pairing.

Patient session context is restored from secure storage with the saved device
token, allowing offline re-entry after restart. Device-token 401s clear the context
and revoke access. Losing the glasses connection disables A6 handover but does not
sign out a patient who has already handed over. P1 content, complete relay,
message persistence/upload, real BLE and caregiver re-entry are later work.

For Android development:
    flutter run -d emulator-5554 --dart-define=REMORI_API_BASE_URL=https://remori-ai.duckdns.org/api/v1 --dart-define=REMORI_FAKE_GLASSES=true

Pair a fresh plain-serial QR on A5, then open A6. Reusing a serial assigned to
another patient is rejected by the API. No passwords or device tokens belong in
build flags, screenshots, logs or this repository.

Connected review captures:
[English](test/goldens/a6_connected_en.png),
[Arabic](test/goldens/a6_connected_ar.png).
Regenerate with flutter test test/a6_handover_test.dart --update-goldens.
Runtime validation on a real Android device remains pending.

## C1 caregiver Home

C1 follows the exported layout with a patient switcher, glasses card, Today
statistics, three recent alerts for the selected patient, and the Phase 2 card.
Both languages, Arabic names in English mode, RTL count ordering, and 2x text
on narrow screens are supported. The approved initials avatar uses the API name;
there is no fabricated photo or name transliteration. Phase 2 summary text and
Read more remain unavailable, as approved.

Widgets observe Riverpod and SQLite only. HomeRepository refreshes GET /patients,
GET /patients/{id}/devices, GET /patients/{id}/journal,
GET /patients/{id}/reminder-logs?date= and GET /caregivers/me/alerts.
The verified /auth/me caregiver ID scopes every cache read/write. Identity reload
hides previous-account data and refresh disposal cancels pending requests.
The journal supplies the backend's patient-local day; reminder logs use that
exact date, even if refresh crosses midnight. People met counts distinct known
person IDs in encounter entries, excluding unknown people and other event types.
Only aggregate statistics are cached: no journal transcripts, embeddings,
photos or signed URLs enter these Home tables.

Schema v2 adds the approved four read-cache tables. Refresh commits atomically
and failures retain cached data with an offline/date notice. Removed patient
links remove that caregiver's related caches. The existing startup policy still
verifies caregiver authentication online; this PR supports cached Home reads
within an authenticated session, without changing that authentication policy.

Android's selected serial uses glassesConnectionProvider for hello/time_sync
(with the patient timezone) and telemetry. A live link overrides heartbeat status,
including forced disconnects. Without a supported local link, API online status
and the last-five-minutes heartbeat are used. Missing battery/last-seen values
stay unknown. Memory: Capturing requires live telemetry, while the API master
switch alone shows Memory: Enabled or Off. Real BLE remains unimplemented;
the approved non-release REMORI_FAKE_GLASSES=true option exercises the dev link.
No pairing tokens or fake events are uploaded by Home.

The glasses and journal links open C16/C12; See all opens C2. Viewer accounts have no Add reminder
action. The summary preview makes no Phase 2 request or invented AI output.
Refresh runs on entry/resume and supports pull to refresh and error retry.

Review captures: [English](test/goldens/c1_en.png), [Arabic](test/goldens/c1_ar.png).
Regenerate with flutter test test/c1_home_test.dart --update-goldens.
Checks: dart format ., flutter analyze (clean), flutter test (181 passed).
C1 tests cover cache ownership, atomic rollback, removed links, alert pagination,
v1 migration, revoked-link cache removal, patient switching, viewer access, offline/empty/error states,
telemetry/disconnect, identity changes, RTL and large text.
Live-account Android/iOS runtime validation remains pending.

## C3 People

C3 uses C1's selected patient and verified caregiver identity. It shows the
exported two-column person grid, Active count / Archived filters, and a banner
for distinct unknown-face clusters awaiting caregiver review. Names and custom
relationships come from the API; Son/Daughter/Doctor/Nurse labels are localized.
Only managers see Add person; viewers retain read navigation.

The approved scoped Drift cache uses schema v3: known people and a review-count
snapshot, keyed by caregiver and patient. The v2 upgrade preserves dashboard,
reminder log and outbox data. Active people, archived people and unknown faces
are fetched together through GET /patients/{id}/people?status=active|archived
and GET /patients/{id}/unknown-faces, then committed atomically. The widget reads
only SQLite. Switching filters needs no network request; switching patient or
account resets the filter and changes cache scope. Empty/error/offline states
use real cached data. Cold C3 entry without patient context uses the existing
Home patient-selection bootstrap; refresh also runs on resume/pull/retry.

As approved, cached_network_image 4.0.4 handles the API's signed photo_url
thumbnail. Disk and memory keys use caregiver/patient/person IDs plus updated_at,
so URL rotation preserves caching and changed photos get a new content key.
UI keys hash the URL to restart the image stream on refreshed URLs without
putting signed URLs into widget diagnostics. Native HTTP 403 evicts the scoped
file and memory image and refreshes the list once per person/version; manual
refresh/resume permits another attempt. Repeated errors cannot create a refresh
loop. All other errors/missing photos show a neutral placeholder. Cache logging
is disabled; no API bearer token is sent to photo hosts.

Archived people have no retained photo URL; observed archive/removal/content
changes evict old photos. PATIENT_NOT_FOUND purges that scope's metadata and
images, including Home's patient context. Home link removal also clears related
C3 metadata. No embeddings or unknown-face images are cached by C3.

Add person opens C4 with the patient ID, person cards open C5 with patient/person
IDs, and the review banner opens C6 with patient context. C4 is implemented below;
C5 and C6 are implemented below. No create/archive/promote endpoint is
called from C3.

Review captures: [English](test/goldens/c3_en.png), [Arabic](test/goldens/c3_ar.png).
The captures use exported design portraits as test fixtures only; runtime people
and photos always come from the API. No demo portraits are bundled in the app.
Regenerate with flutter test test/c3_people_test.dart --update-goldens.

Validation: dart format ., flutter analyze (clean), flutter test (201 passed,
20 new C3 tests), Android debug APK build (successful).
Tests cover both filters, cache scope, rollback, archived-photo eviction,
revoked access, photo key/URL rotation and bounded 403 recovery, navigation
context, viewer permissions, account/patient changes, v2 migration, late image
callbacks, RTL and 2x text at 320dp.
Live-account image loading on a real Android/iOS device and iOS build validation
remain pending.

## C4 Add person

C4 follows the exported design with five photo slots, name, relationship,
explicit recognition consent, and Save person. Name hints use instructions
rather than sample names. Both English and Arabic are supported, with scrolling
for the keyboard and enlarged text. Only managers of the current patient can
edit; the route's patient context must match the selected patient. Changing
account/patient clears the form and ignores late picker/upload results.

Ahmed approved image_picker (1.2.4) for camera/gallery and the online enrollment
exception: POST /patients/{id}/people generates a server ID and has no queued
creation/idempotency contract. C4 sends repeated photos multipart fields,
trimmed name/relationship and consent_given=true, then inserts the response into
the existing caregiver/patient-scoped Drift People cache. No table or outbox kind
is added. C3 refresh obtains the thumbnail, which is absent from the 201 response.

Consent starts unchecked. Require 1–5 JPEG/PNG photos, at most 4 MB each, a name
of 1–80 characters and relationship of 1–40. The server remains authoritative for
image validity; structured body.photos.<index> errors outline the relevant slots
without displaying server text. Face inference is currently a backend stub, so
C4 does not claim local face detection or fabricate the design's example error.

Selected image bytes stay in the form, not Drift/outbox; previews are evicted
when removed/replaced or the form closes. image_picker uses system temporary
files; C4 makes no persistent copy. Android lost-picker results are recovered
only into a currently authenticated manager's form, with consent still required.
iOS camera/library purpose strings are localized; no microphone permission is
added. Native picker permission failures leave the form intact.

Duplicate taps are blocked. A known successful enrollment followed by a cache
failure retains its result: retry only writes the cache, never creates another
person. An uncertain network/response failure instructs the caregiver to check
People before retrying; there is no automatic retry of enrollment.

Review captures: [English](test/goldens/c4_en.png), [Arabic](test/goldens/c4_ar.png).
Regenerate with flutter test test/c4_add_person_test.dart --update-goldens.
Tests cover multipart fields/photo limits, consent, cache scope, server slot
errors, cache retry, duplicate taps, late scope changes, viewer restrictions,
camera cancellation, gallery selection/removal, navigation and enlarged RTL.
Real-device camera/gallery, live-account enrollment and an iOS build require
device validation; no account or face data was created for automated checks.

Validation: dart format ., flutter analyze (clean), flutter test (215 passed,
14 new C4 tests), Android debug APK build (successful).

## C5 Person detail

C5 opens from a C3 card using its patient/person IDs and reads only from Drift.
It shows the person's actual name, relationship, enrollment caregiver (when the
API supplies one), first full photo, and enrolled-photo thumbnails. The existing
cached_network_image package uses account/patient/person/photo IDs as keys, with
separate full/thumbnail entries; signed-URL changes replace the image stream.
Native HTTP 403 evicts and refreshes once per photo until an explicit refresh.
There are no per-photo API requests or sample runtime portraits.

Ahmed approved two scoped read caches: PersonDetailStates (enrolled-by name and
refresh timestamp) and CachedPersonPhotos (IDs, signed URLs and order). Schema v4
adds these without changing existing People, dashboard, reminder or outbox data.
Detail refresh atomically updates these and the C3 person row. C3 clears stale
details after observed archive/removal/content changes; Home clears detail
metadata when a patient link is removed or revoked. Removed/archived photos are
evicted from the detail image cache. Archived details never display photos.

Ahmed approved focused dialogs and online C5 writes followed by local cache
updates. Edit changes name/relationship through PATCH /people/{id}; Add photos
uses the existing approved image_picker and POST /people/{id}/photos (1–5
JPEG/PNG files per request, at most 4 MB each, at most 20 enrolled total). Tap an
enrolled thumbnail to remove it with confirmation; the last photo cannot be
removed. Archive requires confirmation and calls DELETE /people/{id}; it removes
face metadata locally and returns to C3, retaining the historical name.
Viewers and archived people have no write controls. Account/patient changes hide
dialog data and ignore late callbacks. Both languages and enlarged layouts are
supported, and structured photo errors mark their corresponding slots.

There is no automatic retry of an uncertain upload. A confirmed write followed
by a cache/refresh failure blocks further writes and offers refresh/cache retry
without sending the write again. While that update is pending, photos are
hidden. Selected new photo bytes are ephemeral and previews are evicted when
the dialog closes. No embeddings or photo bytes are stored in Drift/outbox.

Review captures: [English](test/goldens/c5_en.png), [Arabic](test/goldens/c5_ar.png).
Regenerate with flutter test test/c5_person_detail_test.dart --update-goldens.
The design portraits in captures are test fixtures only. Automated checks cover
cache atomicity/scope, v3 migration, contract payloads, edit/upload/remove/archive,
last-photo protection, cache/refresh retry, bounded 403 recovery, viewer access,
dialog privacy, archive confirmation, URL rotation, and 2x text at 320dp.
Real-device camera/gallery, live-account person changes, and an iOS build remain
device-validation tasks; automated checks do not create or modify live faces.

Validation: dart format ., flutter analyze (clean), flutter test (243 passed,
28 new C5 tests), Android debug APK build (successful).

## C8 Reminders

C8 reads reminder definitions and recorded daily occurrences from Drift, and
refreshes GET /patients/{id}/reminders plus GET /patients/{id}/reminder-logs with
an explicit patient-local date. It shows completed/voice, snoozed, pending and
missed statuses supplied by the API. Today does not invent pending occurrences:
the backend currently returns recorded logs, so the section may be empty until
the patient phone/glasses relay records activity. Older-day logs are hidden
after midnight even when a fresh request fails; cached definitions remain visible.

Ahmed approved timezone 0.11.2 with bundled IANA data, three caregiver/patient
read caches (CachedReminders, CachedReminderOccurrences, ReminderCacheStates),
and online manager-only active toggles followed by local cache updates. Schema
v5 preserves existing reminder logs, outbox, People and dashboard caches. C8
uses separate caregiver occurrence caches and never changes the patient log
merge rules or writes to the outbox. Home clears C8 metadata on removed/revoked
patient links; known PATIENT_NOT_FOUND clears the affected reminder cache.

Times and today's date use the patient's timezone, including DST. The clock
checks for day changes every minute and on resume. Daily/weekly rules receive
localized summaries (including multiple times); bounded, interval, monthly,
ordinal, cross-timezone and other complex rules use a generic Scheduled reminder
description. This formatter describes schedules only; it is not a recurrence
engine. Unknown rules are never exposed as technical RRULE text or truncated
into an inaccurate schedule.

Managers can enable/disable reminders through PATCH with active only; viewers
can read but cannot toggle, add or edit. Duplicate taps are blocked. Confirmed
writes that fail to update the cache retain their receipt and retry the cache
only, including across midnight. Stale refresh responses cannot replace newer
day snapshots or newer confirmed definition timestamps. Account/patient changes
clear pending state and stop displaying the previous scope's data.

Header Add, reminder cards and the caregiver center action pass patient/reminder
context to C9's add/edit form.
Both languages follow the C8 design and scroll/reflow for enlarged text at 320dp.
Review captures: [English](test/goldens/c8_en.png), [Arabic](test/goldens/c8_ar.png).
Regenerate with flutter test test/c8_reminders_test.dart --update-goldens.
Reminder names and statuses in captures are test fixtures only; runtime values
come from the live API. Tests cover scoped/atomic caches, DST/day rollover,
stale responses, v4 migration, retries, permissions, navigation and RTL layouts.
Live-account toggle testing on Android/iOS and an iOS build remain pending.

Validation: dart format ., flutter analyze (clean), flutter test (270 passed,
27 new C8 tests), Android debug APK build (successful).

## C9 Add / edit reminder

Open Reminders and choose Add or a reminder card. C9 loads existing definitions,
including spoken text, from the existing caregiver/patient-scoped Drift cache.
Only managers can create, edit or delete. It includes title, optional spoken
text (blank means say the title), type, repeat, weekdays, up to four selected
times, Starts and timezone, with Arabic/English localization and native pickers.

Ahmed approved online POST/PATCH/DELETE followed by updates to that cache and
confirmation before deletion. Deletion removes the definition while retaining
recorded activity. A confirmed write whose cache update fails locks the form;
Retry only updates the cache, never resending the write. Uncertain responses
ask the caregiver to check the list before trying again. Account/patient changes
hide the previous form and ignore late responses. No new packages, database
tables, outbox behavior or API contracts are introduced.

Approved recurrence scope: Once, Daily and Weekly, with 1–4 exact times. Starts
defaults to patient-local today and time selection is explicit. Weekly starts
on the first selected weekday on or after Starts. Once runs every selected time
on its start day. RFC 5545 BYSETPOS prevents mixed hour/minute selections from
creating extra occurrences; COUNT bounds Once to that day's selected times.
Nonexistent start times at a DST change are rejected; overlaps select the first
occurrence. Existing schedules outside this scope remain unchanged, with only
title, spoken text and type editable. Metadata-only edits omit all schedule and
active fields, preserving existing schedules and paused reminders. C8 continues
to use its generic description for rules outside its simple display formatter.

Review captures: [English](test/goldens/c9_en.png), [Arabic](test/goldens/c9_ar.png).
Regenerate with flutter test test/c9_edit_reminder_test.dart --update-goldens.
Capture data is test-only. Tests cover contract writes, scoped cache updates,
retained activity, stale refreshes, exact recurrence pairs, DST, native time
selection, four-time limits, permissions, confirmation, cache-only retries,
account changes and 2x text at 320dp. Daily/Weekly/Once occurrence fixtures were
also independently verified with Python dateutil, used by the backend schema.
Live-account changes on Android/iOS and an iOS build remain device-validation
tasks; automated checks do not modify live reminders.

Validation: dart format ., flutter analyze (clean), flutter test (305 passed,
35 new C9 tests), Android debug APK build (successful).

## C2 Alerts

Home's See all opens C2. It reads all cached alerts for the authenticated
caregiver's currently linked patients, with unread dots/count, patient-local
times and Today/Yesterday/date groups. Refresh fetches every page of
GET /caregivers/me/alerts (unread_only=false, limit=50, offset), then updates
the existing DashboardAlerts cache atomically. Arabic and English descriptions
come from alert_type plus the patient's cached name. The API's English fallback
message is never displayed; absent battery percentages, visit counts and
medication details are not invented or extracted from fallback prose.

Ahmed approved online POST /alerts/{id}/read followed by cache updates. Both
managers and viewers can read their own alerts. Acknowledged reads whose cache
update fails retain a receipt; Retry updates the cache without another POST.
Offline refresh keeps cached cards. Failed unread marking keeps its unread dot;
already-read alerts can open without a write. Duplicate taps are blocked, late
account responses are ignored, and revoked links cannot regain cached alerts
through a late receipt. Full refresh cannot clear confirmed read markers; Home's
partial preview refresh retains C2 history and purges removed patient links.

Approved staged navigation: medication alerts with reminder_log metadata select
their patient and open C8. Unknown-person alerts with unknown_face_cluster metadata
select their patient and open C6. Device alerts select their patient and open C16.
Phase 2 summary cards mark read and show a localized destination
pending message until C17. No empty destination route
is opened. The existing caregiver navigation is retained. No packages, tables,
schema migration, outbox behavior or backend contracts are added.

Review captures: [English](test/goldens/c2_en.png), [Arabic](test/goldens/c2_ar.png).
Regenerate with flutter test test/c2_alerts_test.dart --update-goldens.
Tests cover pagination and atomic failures, cache ownership, stale reads, Home
preview history, missing alerts, revoked links, cache-only retry, viewer access,
navigation, localization, account switches, midnight and cross-timezone grouping,
empty state and 2x text at 320dp. Capture alerts are test fixtures only.
Live-account read marking on Android/iOS and an iOS build remain device-validation
tasks; automated tests do not change live alerts.

Validation: dart format ., flutter analyze (clean), flutter test (331 passed,
26 new C2 tests), Android debug APK build (successful).

## C6 New faces to review

Open C6 through the People review banner or an unknown-person alert in C2.
GET /patients/{id}/unknown-faces refreshes a caregiver/patient-scoped Drift read
cache; the screen reads locally. It displays sighting counts, distinct days,
patient-local first/last seen dates, 72px previews and the design's retention
explanation. D23's three-distinct-day threshold also applies to the C3 badge.
There are no sample runtime faces, guessed names or face-management writes.

Ahmed approved CachedUnknownFaces and UnknownFacesCacheStates metadata tables.
Schema v6 adds these while preserving People, reminders, dashboard and outbox
data. Only IDs, counts, dates and signed URLs are cached: no embeddings or photo
bytes enter Drift. Refresh is atomic and clears removed clusters; mismatched
patients, invalid URLs/counts/dates and inconsistent sample metadata are rejected.
Known revoked/missing patient links purge these caches with the existing scopes.

Approved previews are memory-only and require a successful refresh during this
screen session. The thumbnail (or sample URL fallback) is fetched without
caregiver credentials and without a disk cache. Session entries use account,
patient, cluster and sample IDs. Refresh, route covering/leaving, backgrounding,
scope changes and disposal clear byte references, decoded image-cache entries
and pending image requests. Resume/return requires another successful refresh.
Offline metadata remains visible with placeholders. HTTP 403 refreshes signed
URLs once per sample until an explicit retry; errors never print signed URLs.

Review cards now open C7 with the selected patient and cluster IDs. The former
review-pending notice is removed. Viewers can read C6; they have no editing controls.
Arabic/English layouts, enlarged text and scrolling follow the design and use
the existing caregiver navigation. No packages or backend contracts are added.

Review captures: [English](test/goldens/c6_en.png), [Arabic](test/goldens/c6_ar.png).
Regenerate with flutter test test/c6_unknown_faces_test.dart --update-goldens.
Design portraits are test fixtures only; runtime previews come from the API.
Tests cover migration, ownership/atomicity, eligibility, offline metadata,
native memory-only HTTP loading, safe errors, bounded 403 recovery, lifecycle
and route cleanup, permissions, stale refreshes, account changes, empty state,
Arabic/English at 2x text on 320dp, and C2-to-C6 patient navigation.
Live-account signed-photo validation on Android/iOS and an iOS build remain
device-validation tasks; automated checks do not modify live face data.

Validation: dart format ., flutter analyze (clean), flutter test (352 passed:
20 new C6 tests plus C2 navigation coverage), Android debug APK build (successful).

## C7 Who is this?

Tap a C6 review card to open its scoped detail. C7 reads the existing unknown-face
cache and up to three ordered sample references from the approved
CachedUnknownFaceSamples table. Schema v7 preserves earlier caches and outbox
records; removed patient links also purge sample metadata. No embeddings or image
bytes enter Drift, and no package or backend contract changes are required.

Photos follow C6's memory-only policy, with a separate C7 session so covering C6
cannot clear C7's images. Offline reads show saved counts/dates and placeholders.
Backgrounding, covering/leaving the route and account/patient changes clear
previews; a successful refresh is required to display them again. Signed URL 403
recovery is bounded by sample ID. Runtime never uses the design's sample portraits.

Ahmed approved manager-only online decisions. Promotion sends name, relationship
and explicit consent to POST /unknown-faces/{id}/promote. Consent starts unchecked;
name and relationship limits match the API. Dismissal asks for confirmation before
POST /unknown-faces/{id}/dismiss deletes the stranger's photos. Viewers can inspect
metadata/photos but cannot submit either decision. Both actions return to People
after an atomic local update removes the face/samples, updates the review badge,
and inserts the returned person when promoted.

An acknowledged decision retains a receipt: a local failure offers cache-only
retry and never sends another POST. An uncertain response or ALREADY_DECIDED
requires a successful list refresh before another decision. Duplicate submissions
are blocked, late refreshes cannot resurrect decided faces, and late responses
cannot write into another account/patient scope. API failures are localized without
showing names, signed URLs, server messages or credentials in diagnostic output.

Review captures: [English](test/goldens/c7_en.png), [Arabic](test/goldens/c7_ar.png).
Regenerate with flutter test test/c7_unknown_detail_test.dart --update-goldens.
Tests cover scoped ordered metadata, migration, promotion/dismissal contracts,
consent/length validation, malformed ownership, stale refreshes, confirmation,
cache-only retries, uncertain outcomes, duplicate taps, viewers, offline reads,
background cleanup, account changes, bounded 403 recovery and 2x text at 320dp.
Live-account decisions and iOS validation remain device-validation tasks; automated
tests do not enroll or dismiss real faces.

Validation: dart format --set-exit-if-changed ., flutter analyze (clean),
flutter test (378 passed, including 26 new C7 tests), Android debug APK build.

## C10 Saved places

C10 reads its selected patient's saved places from the approved caregiver/patient-
scoped CachedPlaces and PlacesCacheStates Drift caches. Schema v8 preserves older
caches and pending writes. GET /patients/{id}/places refreshes definitions and
freshness atomically; API names and order are retained, with localized radii.
Coordinates are cached for the existing place contract, without requesting GPS,
displaying a map, or implementing location matching in this screen.

Invalid ownership, duplicate IDs, deleted rows, invalid names, coordinates, radii
or timestamps reject the whole refresh and preserve previous cached data.
Offline reads remain available. Empty refreshes, revoked/missing patient links
and Home's removed-link cleanup purge only the affected scope. Stale refreshes
cannot undo a purge, and changing accounts/patients hides the previous list.

Add and manager-owned place cards now open C11 with their patient/place context.
The former editing-pending notice is removed. Viewers can read places
without editing controls. Only the API's single name is displayed: no translated
name is invented. The existing caregiver navigation and C9 reminder action remain.
C10's normal entry is through C18 More. The C10 route is implemented and
covered by widget tests, including its Back destination.

Review captures: [English](test/goldens/c10_en.png), [Arabic](test/goldens/c10_ar.png).
Regenerate with flutter test test/c10_places_test.dart --update-goldens.
Names in captures are test fixtures; runtime uses saved API places only.
Tests cover contract validation, ownership, atomicity, offline reads, purging,
removed links, migration, delayed responses, permissions, staged controls,
navigation, localization and 2x text at 320dp. No packages, writes, backend changes,
GPS permissions or relay behavior are added. An iOS build and live-account device
validation remain pending on this Windows environment.

Validation: dart format --set-exit-if-changed ., flutter analyze (clean),
flutter test (409 passed, including 31 new C10 tests), Android debug APK built.

## C11 Add/edit place

C11 opens through C10's Add button or a manager's saved-place card. It reads
existing definitions from the scoped C10 cache and refreshes the list to detect
removed places/access. Ahmed approved flutter_map, latlong2 and geolocator, with
OpenStreetMap tiles for the initial project version. Maps show visible attribution
and use the library's native HTTP tile cache, with a Remori User-Agent and no
caregiver credentials. There is no tile prefetch, patient tracking or map on C10.

Existing places use their saved coordinates without asking for GPS. New places
request one foreground fix from the caregiver phone. Denied/disabled location
leaves a world view with no selected point: the caregiver must select a point
before saving. A late location fix cannot overwrite manual selection. The pin
can be dragged, the map can be panned/zoomed and tapping selects a point. Test
maps use deterministic generated tiles; production never substitutes them.

New places default to 100 m, with the design's 50–500 m slider in 10 m steps.
API-valid existing radii outside that range/step are preserved until the slider
is explicitly moved. Names use the API's 80-character limit. Manager-only online
POST/PATCH/DELETE operations update the existing cache after acknowledgement;
Delete asks for confirmation. A confirmed write with a local failure retains a
receipt for cache-only retry. Uncertain writes lock resubmission and ask the
caregiver to return to/refetch Saved places before trying again. Scope changes
ignore late results; known removed places/access purge the affected cached data.
No tables or backend contracts change.

Configure map tiles at build/run time, alongside the existing API configuration:

```powershell
flutter run --dart-define=REMORI_API_BASE_URL=https://remori-ai.duckdns.org/api/v1 '--dart-define=REMORI_MAP_TILE_URL=https://tile.openstreetmap.org/{z}/{x}/{y}.png' --dart-define=REMORI_FAKE_GLASSES=true
```

The tile URL must use the approved HTTPS OpenStreetMap endpoint. Missing or invalid
configuration shows a localized unavailable state. Map failures do not disclose
coordinates or raw exceptions; reopen the editor after restoring connectivity.
The iOS foreground-location purpose is declared in English and Arabic. On macOS,
set the geolocator SPM compile flag for foreground-only location before building:

```sh
BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios --dart-define=REMORI_API_BASE_URL=https://remori-ai.duckdns.org/api/v1 '--dart-define=REMORI_MAP_TILE_URL=https://tile.openstreetmap.org/{z}/{x}/{y}.png'
```

No Always/background location permission is requested. iOS compilation and actual
permission dialogs remain device-validation tasks on macOS/iOS. Map setup follows
[flutter_map caching](https://docs.fleaflet.dev/layers/tile-layer/caching) and the
[OSM tile policy](https://operations.osmfoundation.org/policies/tiles/).
C18 More opens Saved places, where managers can add or edit a place.
Review captures: [English](test/goldens/c11_en.png),
[Arabic](test/goldens/c11_ar.png). Regenerate with
flutter test test/c11_edit_place_test.dart --update-goldens.

Validation: dart format --set-exit-if-changed . (clean), flutter analyze (clean),
flutter test (433 passed, including 24 new C11 tests), Android debug APK built
with the configured live API and approved OpenStreetMap tiles. Automated tests
never create, edit or delete live places and never query a real phone location.

## C12 Journal

Open Home → Open journal to view C12. The journal reads its caregiver/patient/day
cache and refreshes it through GET /patients/{id}/journal?date=YYYY-MM-DD. Date
navigation and times use the patient's IANA timezone; entries appear oldest
first. All, People, Talk, Questions, Reminders, Media and Docs filter the saved
events locally. Managers and linked viewers receive the same read-only screen.

Schema v9 adds three scoped caches for allowlisted entry text, media metadata,
and day/refresh metadata. Arbitrary event metadata and embeddings are discarded;
audio and image bytes never enter Drift. Failed refreshes preserve saved text.
Known missing/revoked patients purge all journal days for that caregiver/patient,
including when Home refresh removes the link.

Signed HTTPS previews use a separate client without authorization headers and
are memory-only. They load after a successful journal refresh, prefer thumbnail
URLs, and fall back to image URLs only for images. Videos without thumbnails use
an icon. Leaving the screen, backgrounding, or changing day/account/patient clears
the preview store and Flutter image cache. Retention expiry hides and evicts the
preview without another request; a 403 refreshes the journal once per media ID
until the next manual refresh. Offline entries show photo placeholders.

The API's actual names, relationships, transcript/rendered text, document
summaries and media tags are displayed. Person photos, medication names, reminder
completion details and missing question answers are not invented. Conversations
use initials when a person is provided. Media cards open C13; document cards
open C15 with the selected patient and document IDs.

Review captures: [English](test/goldens/c12_en.png),
[Arabic](test/goldens/c12_ar.png). Regenerate with
`flutter test test/c12_journal_test.dart --update-goldens`. Tests use synthetic
responses and bundled design assets; they do not read or modify live journals.

Validation: formatting and analysis clean; 469 tests passed, including 36 C12
tests. Android debug APK built with the configured live API. iOS compilation and
device-level lifecycle checks remain validation tasks on macOS/iOS.

## C13 Media viewer

Tap a media card in C12 to open C13. The viewer reads a caregiver/patient/media
metadata cache (schema v10), then refreshes it using the audited
`GET /patients/{id}/media/{media_id}`. It displays the API's event/person details,
patient-local capture date/time, tags, `other` reason, and actual retention.
Kept media show “Kept”; an expiry uses the remaining days. No example names,
tags, retention values or images are supplied as runtime data.

Full photos use the existing bare HTTPS memory-only loader, keyed by account,
patient and media ID. They load only after a successful detail refresh. Leaving,
covering, backgrounding or changing accounts/patients clears the photos and
Flutter image cache. Signed-URL expiry and retention expiry hide the image;
offline mode displays saved metadata with a placeholder. One 403 recovery
refresh is allowed until a manual refresh. Video entries show their metadata
and an approved playback-pending placeholder; no player package was added.

Managers can pin or delete online; viewers have read access only. Deletion
requires confirmation. A confirmed write updates the detail cache and all saved
journal media references for the same caregiver/patient. If a local update fails,
Retry applies only that update, without replaying the API action. An uncertain
write outcome requires a successful refresh before another write. An older
journal refresh is invalidated before applying a confirmed media change.
Known missing media remove saved details and journal references; revoked links
clear affected detail/journal caches. No media bytes enter Drift.

Review captures: [English](test/goldens/c13_en.png),
[Arabic](test/goldens/c13_ar.png). Regenerate with
`flutter test test/c13_media_test.dart --update-goldens`. Tests use synthetic API
responses and bundled design assets; they never pin or delete live media.

Validation: formatting and analysis clean; 504 tests passed, including 35 C13
tests. Android debug APK built with the configured live API. iOS compilation
and physical-device lifecycle validation remain pending on macOS/iOS.

## C14 Documents

C14 reads two caregiver/patient/filter-scoped caches (schema v11) for document
cards and pagination/refresh state. It refreshes through
`GET /patients/{id}/documents?limit=50&offset=0`, adding the documented `type`
for Receipts, Bills or Medication labels. Scrolling near the end requests the
next 50-item page. Refresh replaces the selected filter's pages; failed pages
retain their cards and offset for Retry. Repeated IDs across offset pages are
deduplicated, and cards are ordered by newest capture.

Cards use actual API titles, headlines and patient-local capture times. A null
title falls back to the localized document type. Only card metadata is saved:
OCR text, extracted fields and image bytes never enter these tables. Removed
patient links clear the scoped caches. A confirmed C13 media deletion removes
matching document cards and invalidates their offset pagination.

Thumbnails prefer the list's `thumbnail_url`, falling back to `url` for a photo;
no media-detail request is made per thumbnail. The existing bare HTTPS loader
keeps bytes only in memory after a successful list refresh. Leaving, covering,
backgrounding, account/patient/filter changes and expiry clear or hide previews.
Offline cards use placeholders; signed-URL 403 recovery is bounded by item ID.

Document cards open C15. The normal entry is available through C18 More.
The existing C14 route, test captures and screen-builder
override can also be used to review the screen. Managers and linked viewers
can read documents; the existing center reminder action remains manager-only.

Review captures: [English](test/goldens/c14_en.png),
[Arabic](test/goldens/c14_ar.png). Regenerate with
`flutter test test/c14_documents_test.dart --update-goldens`. Tests use synthetic
API responses and render the bundled SVG design assets as in-memory fixtures;
they do not read real documents or mutate live patient data.

Validation: formatting and analysis clean; 536 tests passed, including 32 C14
tests. Android debug APK built with the configured live API. iOS compilation
and physical-device lifecycle validation remain pending on macOS/iOS.

## C15 Document detail

Open a document card in Journal or Documents to see its full photo, ordered
display fields, patient-local capture time and collapsible OCR text. Known field
labels and calendar dates are localized in English and Arabic; other documents
preserve the API's display labels. This screen is read-only for managers and viewers.

Schema v12 adds one caregiver/patient/document-scoped detail cache. It stores
only title, ordered display fields, OCR text, image references and refresh time;
raw extracted fields and image bytes are excluded. Offline mode shows saved
text with a photo placeholder. Patient-link removal and confirmed media deletion
clear the affected detail cache.

Because the detail response has no patient ID, C15 requires an existing scoped
Journal or Documents cache association before its audited `GET /documents/{id}`.
It verifies the returned event/media IDs again before saving. Uncached or
mismatched links show unavailable. A saved detail alone cannot authorize a link.

Full photos use the existing memory-only loader after a successful GET. Leaving,
covering, backgrounding, account/patient/document changes and signed-URL expiry
clear or hide photos. A photo 403 permits one automatic detail refresh until a
manual refresh. No new package or backend contract was introduced.

Review captures: [English](test/goldens/c15_en.png),
[Arabic](test/goldens/c15_ar.png). Regenerate with
`flutter test test/c15_document_detail_test.dart --update-goldens`.
Tests use synthetic responses and bundled design assets, without live document access.

Validation: formatting and analysis clean; 566 tests passed, including 30 C15
tests. Android debug APK built with the configured live API. iOS compilation
and physical-device lifecycle validation remain pending on macOS/iOS.

## C16 Device

Open Device from Home's glasses card or a device-related alert. C16 reads the
existing caregiver-scoped Home cache and refreshes the selected patient's devices
through `GET /patients/{id}/devices`. Schema v13 adds nullable firmware and pairing
timestamps to that cache. Every returned device has its own card; multiple devices
have individual Unpair actions. Missing firmware, battery and last-seen readings
display unavailable rather than example data.

Connected means a successful refreshed heartbeat within five minutes, as defined
by the API. It does not assert a direct Bluetooth connection. Offline mode keeps
saved readings and marks the connection status unavailable. The status ages as
time passes and refreshes when returning from the background.

Managers can change conversation memory online through `PATCH /patients/{id}`
and unpair through `DELETE /devices/{id}` after confirmation. Viewers are read-only.
Confirmed operations update the shared Home cache. A failed local update retries
only local effects, without repeating the API action. Uncertain writes disable
further changes until Home's existing patient/settings refresh reconciles them.
Older device/Home responses cannot restore values changed by a confirmed action.

Unpairing clears a matching locally known pairing grant and disconnects its glasses;
other local grants are preserved. The server immediately revokes the removed device's
token. Re-pair opens the existing A5 → A6 flow. C18 More also opens Device.

Review captures: [English](test/goldens/c16_en.png),
[Arabic](test/goldens/c16_ar.png). Regenerate with
`flutter test test/c16_device_test.dart --update-goldens`.
Tests use synthetic responses and do not change live patient settings or devices.

Validation: formatting and analysis clean; all 597 tests passed, including 31
C16 tests. Android debug APK built. iOS compilation and physical-device lifecycle
validation remain pending on macOS/iOS.

## C18 More and settings

The More tab connects Journal, Saved places, Documents and Device. It shows the
actual cached patient profile and caregiver account, and consent records from
`GET /patients/{id}/consents`. `GET /auth/me` supplies account display data.
Caregivers opens C19 and shows a count from its refreshed scoped cache when available.
Connected accounts remains disabled until C20; social-link status is not invented. Place counts come only
from a refreshed scoped Places cache; absent caches use generic descriptions.

Schema v14 adds a caregiver-account display cache and caregiver/patient-scoped
consent cache. Account names/emails and allowlisted consent metadata are stored;
tokens remain exclusively in secure storage. Offline mode preserves available
display data. Patient-link removal clears the scoped consents, and late responses
cannot recreate a removed link.

Managers can edit patient name, Arabic/English preference and IANA timezone in
the approved dialog. Saves PATCH only changed fields and update the shared Home
cache after acknowledgment. Viewers cannot edit or revoke. Consent revocation
requires an effects confirmation. Face-enrollment revocation archives the person,
invalidates pending People requests, evicts photo caches and deletes enrolled-photo
metadata; the same cleanup applies to revocations discovered during refresh.
Other revocations do not invent changes to the memory switch or delete history.

Confirmed writes with local failures retry only local effects. Uncertain writes
require refresh before another change. Logout sends the refresh token without an
authorization header, then clears only caregiver credentials and invalidates the
session. A secure-storage retry does not repeat an acknowledged logout POST.

Review captures: [English](test/goldens/c18_en.png),
[Arabic](test/goldens/c18_ar.png). Regenerate with
`flutter test test/c18_more_test.dart --update-goldens`.
Tests use synthetic data and do not edit live profiles, revoke real consents or
log out real sessions. No new dependencies or backend changes were introduced.

Validation: formatting and analysis clean; all 640 tests passed, including 43 C18
tests. Android debug APK built. iOS compilation and physical-device lifecycle
validation remain pending on macOS/iOS.

## C19 Caregivers

Open More → Caregivers to view primary/manager/viewer links. C19 reads a
caregiver/patient-scoped cache and refreshes through
`GET /patients/{id}/caregivers`. Schema v15 adds linked-caregiver records and
refresh metadata; C18 uses these for its actual cached count. Cards show the API's
name and relationship, initials avatars, and “you” only for the authenticated
caregiver ID. No caregiver photo URL is available from the contract.

Managers can add an existing account by email, relationship and permission;
Viewer is the default. The approved labels say Add caregiver because
`POST /patients/{id}/caregivers` sends no invitation email. Viewers have no linking
form. No removal or permission-edit actions were added.

A confirmed link updates the cache. If that update fails, Retry applies only the
local receipt, without repeating POST. Uncertain results lock linking until a
successful list refresh. Missing-account and already-linked responses have
localized explanations; an already-linked response also refreshes the list.
Older refreshes cannot erase confirmed links. Patient-link removal purges both
scoped caches, and late responses cannot recreate revoked access.

Review captures: [English](test/goldens/c19_en.png),
[Arabic](test/goldens/c19_ar.png). Regenerate with
`flutter test test/c19_caregivers_test.dart test/c18_more_test.dart --update-goldens`.
Tests use synthetic accounts and never link real users or send email. No new
packages or backend changes were introduced.

Validation: formatting and analysis clean; all 674 tests passed, including 34 C19
tests. Android debug APK built. iOS compilation and physical-device lifecycle
validation remain pending on macOS/iOS.

## P1 Today

Patient Mode opens Today using device credentials and three patient/device-scoped
caches (schema v16): profile/settings, reminder-card metadata and known encounters.
Foreground refresh reads settings from `/sync` without storing its people payload
or advancing a shared sync cursor, then fetches today's reminder logs and journal
using the patient's IANA timezone. The UI reads local data, uses the patient's
language, and displays up to three distinct known people with initials.

The next actual pending/snoozed occurrence supports Done and Later (15 minutes).
Both actions persist atomically with an outbox snapshot before uploading through
the reminder-log batch endpoint. Only captured operations confirmed by the batch
receipt are acknowledged; rejected or uncertain uploads remain queued. Completed
occurrences cannot regress to pending after refresh.

Connection status requires the current device's local handshake. Memory status
uses the master switch and recent telemetry; unavailable status is stated gently.
Ask stays visible and disabled for Phase 2. Recurrence expansion, background
notifications, full BLE delivery, P2 and C20 remain separate work.

Review captures: [English](test/goldens/p1_en.png),
[Arabic](test/goldens/p1_ar.png). Regenerate with
`flutter test test/p1_today_test.dart --update-goldens`.

Validation: formatting and analysis clean; all 691 tests passed, including 17 P1
tests. Android debug APK built. iOS compilation and physical-device integration
remain pending on macOS/iOS.

## P2 Reminders

The Patient Mode Reminders tab now shows today's actual occurrence logs from
P1's existing patient/device-scoped cache, ordered by their original scheduled
time in the patient's timezone. Completed, pending, snoozed and missed states
have localized, calm descriptions. A snoozed card shows its effective later time.
The next pending/snoozed occurrence has Done and Later (15 minutes) actions;
other cards cannot enqueue actions. There are no patient editing controls.

P1 and P2 share the repository, foreground refresh, completion-wins merge and
atomic reminder/outbox writes. Actions remain on P2, work offline, and upload
through the existing device-authenticated batch path. Retry checks connectivity,
uploads pending snapshots, then refreshes. Leaving and returning to P1 shows the
same local result. Ask remains disabled for Phase 2 on both screens.

No new packages, database tables or API contracts were added. Recurrence
expansion, background notifications, full BLE schedule delivery and P3 remain
separate work. The list shows cached actual occurrences, without inventing
reminders from caregiver-only data or generating a recurrence schedule.

Review captures: [English](test/goldens/p2_en.png),
[Arabic](test/goldens/p2_ar.png). Regenerate with
`flutter test test/p2_reminders_test.dart --update-goldens`.

Validation: formatting and analysis clean; all 709 tests passed, including 18 P2
tests. Android debug APK built. iOS compilation and physical-device integration
remain pending on macOS/iOS.

## P3 Reminder Alert

While Patient Today or Reminders is visible and the app is foregrounded, the next
cached pending/snoozed occurrence opens P3 when due. The existing foreground clock
checks once per minute and on screen/resume updates. An in-memory app-session
receipt, scoped by patient, device, occurrence and effective due time, prevents
reopening the same alert across navigation; a new snooze time can alert again.
Other screens and background operation do not open P3.

P3 displays the actual title and patient-local due time, with the design's pill
icon for medication and a generic bell for other/unknown types. Schema v17 adds
one nullable reminder-type column to the existing scoped card cache. Older rows
remain readable with a bell until refreshed. No new table or package was added.

Done and Later (15 minutes) reuse the local reminder/outbox transaction. P3
returns to P2 only after local persistence is verified, without waiting for the
upload; uncertain connectivity leaves the snapshot queued. A failed local save
keeps P3 open with a gentle retry message. Stale due times, completed occurrences,
wrong-device links and non-next occurrences cannot confirm through P3. A remote
completion dismisses the displayed alert. Scope changes immediately hide its
title and actions.

This is the approved foreground stage. Recurrence expansion, OS/background
notifications, foreground relay service and BLE schedule/confirmation delivery
remain separate work. There is no temporary trigger button or invented reminder.

Review captures: [English](test/goldens/p3_en.png),
[Arabic](test/goldens/p3_ar.png). Regenerate with
`flutter test test/p3_reminder_alert_test.dart --update-goldens`.

Validation: formatting and analysis clean; all 735 tests passed, including 26 P3
tests. Android debug APK built. iOS compilation and physical-device lifecycle
validation remain pending on macOS/iOS.

## P4 My Day

Patient Mode's My Day tab reads three patient/device/day-scoped caches (schema
v18): allowlisted journal display data, media references and day/refresh metadata.
Today and Yesterday use the patient's IANA timezone and roll by calendar day at
local midnight. Refresh uses device credentials; caregiver journal caches are
not reused. Raw transcripts, arbitrary metadata, embeddings, audio and image
bytes are excluded from these tables.

Cards use actual API rendered text when supplied, otherwise localized neutral
descriptions with actual times and names. A reminder event does not imply that
medicine was taken. Missing person photos use initials; other missing previews
use icons. P5 links remain disabled with a gentle notice, and Phase 2 Ask is
disabled. No patient editing or deletion controls are added in P4.

Previews load into memory only after a successful refresh, and only if the exact
media reference belongs to that fresh result. They clear on leaving, background,
day/device changes and expiry. Retention and signed-reference deadlines evict
bytes even without a visible image subscriber. Offline mode keeps cached text
with placeholders and does not fetch old signed URLs. A 403 permits one automatic
refresh per media in a refresh cycle; manual Retry starts a new cycle. Requests
to signed image URLs use a separate unauthenticated transport, without redirects.

Review captures: [English](test/goldens/p4_en.png),
[Arabic](test/goldens/p4_ar.png). Regenerate with
`flutter test test/p4_my_day_test.dart --update-goldens`.

Validation: formatting and analysis clean; all 764 tests passed, including 29 P4
tests. Android debug APK built. iOS compilation and physical-device lifecycle
validation remain pending on macOS/iOS.
