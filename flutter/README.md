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

`databaseProvider` lazily opens schema version 1 in the private application-support
folder (`remori.sqlite`) using drift's background native executor. SQL logging is
disabled. Tests override the executor with in-memory SQLite or a temporary file.
Tokens remain exclusively in secure storage.

This skeleton includes local reminder logs and a patient-scoped transactional
outbox. Other entity-cache tables arrive with their feature PRs. It does not create
or change any backend table, field, or endpoint.

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
shows the four rows and handover card, but patient handover remains disabled until
BLE/relay integration is ready. Permission grants alone never enable Patient Mode.
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