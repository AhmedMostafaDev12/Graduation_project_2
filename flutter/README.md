# Remori companion app

Flutter app for Android and iOS. Dart package: `remori`. Application identifier:
`org.AI.remori`. Display name: Remori.

Read `AGENTS.md` and `docs/ARCHITECTURE.md` before making changes. Screen references
are in `design/screens/`; preserve those exports.

The app includes the native projects, application entry point, shared theme, and reusable controls.
GoRouter supplies entry routes and both mode shells. API access, local database, localization, and screens follow separately.

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
- `shellLabelsProvider`: localization will supply the four destination labels,
  center action label, and direction for each mode. Bars are hidden until labels
  are supplied; no production user-facing strings are hard-coded in routing.
- Caregiver destinations: C1, C3, C8, C18; center action pushes C9. Patient
  destinations: P1, P2, P4, P7; center action pushes P6. Detail screens omit the
  navigation bar, as in the HTML, and pushed routes retain the back destination.
- D1-D3 represent OS notifications, and D4-D6 are existing-screen variants.
  They are not standalone routes. D7 is an entry-flow route.

Router tests override the access, screen-builder, and shell-label providers.
They verify entry/deep links, separate credential guards, both navigation bars,
back behavior, RTL typography, and access revocation without recreating GoRouter.
The app intentionally still shows no finished screens; authentication, localized
navigation labels, and actual feature content are separate planned PRs.
