import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/theme/remori_widgets.dart';
import 'package:remori/features/auth/presentation/a0_splash_screen.dart';

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
      child: const RepaintBoundary(key: Key('a0-preview'), child: RemoriApp()),
    ),
  );
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

  testWidgets('English A0 shows the exported copy and Get Started opens A1', (
    tester,
  ) async {
    await mount(tester);
    expect(
      find.text('A quiet layer of memory\nthat stays with you.'),
      findsOneWidget,
    );
    expect(find.text('Support for everyday moments.'), findsOneWidget);
    expect(tester.getSize(find.byType(RemoriLogo)).width, 250);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(A0SplashScreen)),
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(remoriRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .path,
      '/a1',
    );
    expect(find.byType(A0SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arabic A0 uses localized copy and RTL without a drawn status bar',
    (tester) async {
      await mount(tester, language: 'ar');
      expect(find.text('ابدأ الآن'), findsOneWidget);
      expect(find.text('دعم للحظاتك اليومية.'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(A0SplashScreen))),
        TextDirection.rtl,
      );
      expect(find.text('9:41'), findsNothing);
      expect(tester.getTopLeft(find.byType(A0SplashScreen)).dy, 47);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short narrow screens and enlarged text can scroll to the action',
    (tester) async {
      await mount(tester, size: const Size(320, 480), scale: 2);
      await tester.ensureVisible(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.byType(A0SplashScreen), findsNothing);
    },
  );

  for (final language in ['en', 'ar']) {
    testWidgets('A0 $language reference-size rendering', (tester) async {
      final originalShadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      await mount(tester, language: language);
      expect(tester.takeException(), isNull);
      // On-demand review captures; CI verifies layout without OS-specific raster baselines.
      if (autoUpdateGoldenFiles) {
        final previousShadows = originalShadows;
        try {
          debugDisableShadows = false;
          await tester.pump();
          await expectLater(
            find.byKey(const Key('a0-preview')),
            matchesGoldenFile('goldens/a0_$language.png'),
          );
        } finally {
          debugDisableShadows = previousShadows;
        }
      }
    });
  }
}
