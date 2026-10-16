import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/patient_session_provider.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/auth/presentation/a2_login_screen.dart';
import 'package:remori/features/auth/presentation/auth_providers.dart';
import 'package:remori/features/auth/presentation/d7_account_exists_screen.dart';

import 'a2_login_test.dart' as auth;

class EmptySession extends PatientSession {
  @override
  PatientSessionState build() => const PatientSessionState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, file) in [
      ('DM Sans', 'assets/fonts/DM-Sans.ttf'),
      ('Manrope', 'assets/fonts/Manrope.ttf'),
      ('Readex Pro', 'assets/fonts/Readex-Pro.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(file))).load();
    }
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    auth.TestAuthRepository repository,
    String language,
    double scale,
  ) async {
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientSessionProvider.overrideWith(EmptySession.new),
        routeAccessProvider.overrideWithValue(const RouteAccess()),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      repository.client.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('d7-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.d7.name);
    await tester.pumpAndSettle();
    return container;
  }

  for (final language in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'D7 $language at ${scale}x has disabled Google and working email navigation',
        (tester) async {
          final repository = auth.TestAuthRepository();
          final container = await mount(tester, repository, language, scale);
          expect(find.byType(D7AccountExistsScreen), findsOneWidget);
          final google = find.byType(OutlinedButton);
          expect(tester.widget<OutlinedButton>(google).onPressed, isNull);
          await tester.ensureVisible(google);
          await tester.tap(google, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            container
                .read(remoriRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path,
            RemoriScreen.d7.path,
          );
          expect(repository.calls, 0);
          expect(find.byType(TextField), findsNothing);
          expect(find.textContaining('Connected accounts'), findsNothing);
          expect(tester.takeException(), isNull);
          if (autoUpdateGoldenFiles) {
            // Capture the initial view, including the warning and safe-area header.
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, 1200),
            );
            await tester.pumpAndSettle();
            await expectLater(
              find.byKey(const Key('d7-preview')),
              matchesGoldenFile('goldens/d7_${language}_${scale}x.png'),
            );
          }
          final email = find.byType(FilledButton);
          await tester.ensureVisible(email);
          await tester.tap(email);
          await tester.pumpAndSettle();
          expect(find.byType(A2LoginScreen), findsOneWidget);
          expect(repository.calls, 0);
        },
      );
    }
    testWidgets(
      'D7 $language Back goes to login without prior navigation history',
      (tester) async {
        final repository = auth.TestAuthRepository();
        await mount(tester, repository, language, 1);
        await tester.tap(find.byType(BackButtonIcon));
        await tester.pumpAndSettle();
        expect(find.byType(A2LoginScreen), findsOneWidget);
        expect(repository.calls, 0);
      },
    );
  }
}
