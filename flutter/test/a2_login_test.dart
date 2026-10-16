import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/features/device_pairing/domain/pairing_info.dart';
import 'package:remori/features/device_pairing/presentation/handover_providers.dart';
import 'package:remori/core/api/credential_store.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/auth/data/auth_repository.dart';
import 'package:remori/features/auth/presentation/a2_login_screen.dart';
import 'package:remori/features/auth/presentation/auth_providers.dart';

class TestAuthRepository extends AuthRepository {
  TestAuthRepository()
    : super(
        ApiClient(
          config: ApiConfig('https://example.test/api/v1'),
          credentials: SecureCredentialStore(),
          onCredentialsInvalidated: (_) {},
        ),
        SecureCredentialStore(),
      );
  int calls = 0;
  ApiFailure? failure;
  Completer<void>? pending;
  @override
  Future<void> login(String email, String password) async {
    calls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  TestAuthRepository repository, {
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
  addTearDown(repository.client.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const RepaintBoundary(key: Key('a2-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.a2.name);
  await tester.pumpAndSettle();
  return container;
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'carer@example.test');
  await tester.enterText(find.byType(TextField).at(1), 'password');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
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
  for (final (label, path) in [
    ('Log In', '/c1'),
    ('Log In and set up for a patient', '/a4'),
  ]) {
    testWidgets('$label authenticates before opening $path', (tester) async {
      final repository = TestAuthRepository()..pending = Completer<void>();
      final container = await mount(tester, repository);
      await fill(tester);
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
      expect(repository.calls, 1);
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isFalse,
      );
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/a2',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      await container
          .read(loginControllerProvider.notifier)
          .login('ignored', 'ignored');
      expect(repository.calls, 1);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isTrue,
      );
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        path,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('successful re-login clears previous account pairing setup', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    final container = await mount(tester, repository);
    container.read(caregiverSessionProvider.notifier).signedIn();
    container
        .read(pairedGlassesProvider.notifier)
        .paired(
          const PairingInfo(
            deviceId: 'old-device',
            patientId: 'old-patient',
            serial: 'OLD',
          ),
        );
    expect(container.read(pairedGlassesProvider), isNotNull);
    expect(
      await container
          .read(loginControllerProvider.notifier)
          .login('carer@example.test', 'password'),
      true,
    );
    await tester.pumpAndSettle();
    expect(container.read(pairedGlassesProvider), isNull);
  });

  testWidgets('empty inputs do not request authentication', (tester) async {
    final repository = TestAuthRepository();
    await mount(tester, repository);
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsNWidgets(2));
    expect(repository.calls, 0);
  });
  testWidgets(
    'incorrect credentials show localized copy without granting access',
    (tester) async {
      final repository = TestAuthRepository()
        ..failure = ApiFailure(
          ApiFailureKind.server,
          code: 'INVALID_CREDENTIALS',
          message: 'PRIVATE SERVER COPY',
        );
      final container = await mount(tester, repository);
      await fill(tester);
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Wrong email or password'), findsOneWidget);
      expect(find.text('PRIVATE SERVER COPY'), findsNothing);
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isFalse,
      );
      expect(find.byType(A2LoginScreen), findsOneWidget);
    },
  );
  testWidgets(
    'password visibility, disabled controls, and sign up work as specified',
    (tester) async {
      final container = await mount(tester, TestAuthRepository());
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
      for (final label in ['Continue with Google', 'Continue with Facebook']) {
        final button = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(button.onPressed, isNull);
      }
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/a3',
      );
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('A2 $language scrolls with keyboard and 2x text', (
      tester,
    ) async {
      await mount(
        tester,
        TestAuthRepository(),
        language: language,
        size: const Size(320, 480),
        scale: 2,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final label = language == 'en' ? 'Sign up' : 'إنشاء حساب';
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(A2LoginScreen), findsNothing);
    });
    testWidgets('A2 $language reference-size capture and safe area', (
      tester,
    ) async {
      final shadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      try {
        await mount(tester, TestAuthRepository(), language: language);
        expect(
          Directionality.of(tester.element(find.byType(A2LoginScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.getTopLeft(find.byType(A2LoginScreen)).dy, 47);
        expect(find.text('9:41'), findsNothing);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('a2-preview')),
            matchesGoldenFile('goldens/a2_$language.png'),
          );
        }
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
