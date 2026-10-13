# Remori companion app

Flutter app for Android and iOS. Dart package: `remori`. Application identifier:
`org.AI.remori`. Display name: Remori.

Read `AGENTS.md` and `docs/ARCHITECTURE.md` before making changes. Screen references
are in `design/screens/`; preserve those exports.

The app includes the native projects, application entry point, shared theme, and reusable controls.
Routing, API access, local database, localization, and screens follow separately.

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
