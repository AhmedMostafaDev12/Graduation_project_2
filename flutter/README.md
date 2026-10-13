# Remori companion app

Flutter app for Android and iOS. Dart package: `remori`. Application identifier:
`org.AI.remori`. Display name: Remori.

Read `AGENTS.md` and `docs/ARCHITECTURE.md` before making changes. Screen references
are in `design/screens/`; preserve those exports.

This foundation supplies the native projects and application entry point. Theme,
routing, API access, local database, localization, and screens follow separately.

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