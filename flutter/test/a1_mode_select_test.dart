import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/theme/remori_widgets.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/auth/presentation/a1_mode_select_screen.dart';

Future<void> mount(
  WidgetTester tester, {
  String language = 'en',
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 47);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appLocaleProvider.overrideWithValue(Locale(language))],
      child: const RepaintBoundary(key: Key('a1-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.a1.name);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, file) in [
      ('DM Sans', 'DM-Sans.ttf'),
      ('Manrope', 'Manrope.ttf'),
      ('Readex Pro', 'Readex-Pro.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$file'))).load();
    }
  });

  for (final label in ["I'm a caregiver", "This is the patient's phone"]) {
    testWidgets('$label opens A2 as in the exported design', (tester) async {
      await mount(tester);
      expect(tester.getSize(find.byType(RemoriLogo)).width, 210);
      expect(
        find.text(
          "Memory support for people living with Alzheimer's, and for the people who care for them.",
        ),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(A1ModeSelectScreen)),
      );
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/a2',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Arabic A1 is localized, RTL, and below the native status bar', (
    tester,
  ) async {
    await mount(tester, language: 'ar');
    expect(find.text('أنا مقدم رعاية'), findsOneWidget);
    expect(find.text('هذا هاتف المريض'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(A1ModeSelectScreen))),
      TextDirection.rtl,
    );
    expect(tester.getTopLeft(find.byType(A1ModeSelectScreen)).dy, 47);
    expect(find.text('9:41'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['en', 'ar']) {
    testWidgets(
      'A1 $language enlarged text stays reachable on a small viewport',
      (tester) async {
        await mount(
          tester,
          language: language,
          size: const Size(320, 480),
          scale: 2,
        );
        final action = find.text(
          language == 'en' ? "This is the patient's phone" : 'هذا هاتف المريض',
        );
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(A1ModeSelectScreen), findsNothing);
      },
    );
    testWidgets('A1 $language reference-size rendering', (tester) async {
      final shadows = debugDisableShadows;

      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      await mount(tester, language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('a1-preview')),
          matchesGoldenFile('goldens/a1_$language.png'),
        );
      }
      debugDisableShadows = shadows;
    });
  }
}
