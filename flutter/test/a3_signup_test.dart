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
import 'package:remori/core/api/credential_store.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/auth/data/auth_repository.dart';
import 'package:remori/features/auth/presentation/a3_signup_screen.dart';
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
  int registrations = 0;
  ApiFailure? registerFailure;
  String? registeredPhone;
  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    registrations++;
    registeredPhone = phone;
    if (pending != null) await pending!.future;
    if (registerFailure != null) throw registerFailure!;
  }

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
      child: const RepaintBoundary(key: Key('a3-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.a3.name);
  await tester.pumpAndSettle();
  return container;
}

Future<void> fill(WidgetTester tester, {String phone = ''}) async {
  await tester.enterText(find.byType(TextField).at(0), 'Test Carer');
  await tester.enterText(find.byType(TextField).at(1), 'carer@example.test');
  await tester.enterText(find.byType(TextField).at(2), phone);
  await tester.enterText(find.byType(TextField).at(3), 'password');
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sign up'));
  await tester.tap(find.text('Sign up'));
  await tester.pump();
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
  testWidgets(
    'registration and login finish before opening A4; phone is optional',
    (tester) async {
      final repository = TestAuthRepository()..pending = Completer<void>();
      final container = await mount(tester, repository);
      await fill(tester);
      await submit(tester);
      expect(repository.registrations, 1);
      expect(repository.calls, 0);
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isFalse,
      );
      await container
          .read(signUpControllerProvider.notifier)
          .signUp(name: 'ignored', email: 'ignored', password: 'ignored');
      expect(repository.registrations, 1);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      expect(repository.registeredPhone, '');
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
        '/a4',
      );
    },
  );
  testWidgets('required fields and password length prevent requests', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    await mount(tester, repository);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsNWidgets(3));
    await fill(tester);
    await tester.enterText(find.byType(TextField).at(3), 'short');
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Use 8–128 characters'), findsOneWidget);
    expect(repository.registrations, 0);
  });
  testWidgets('duplicate email offers existing login without granting access', (
    tester,
  ) async {
    final repository = TestAuthRepository()
      ..registerFailure = ApiFailure(
        ApiFailureKind.server,
        code: 'EMAIL_TAKEN',
        message: 'PRIVATE COPY',
      );
    final container = await mount(tester, repository);
    await fill(tester, phone: '+201000000000');
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('An account with this email already exists. Please log in.'),
      findsOneWidget,
    );
    expect(find.text('PRIVATE COPY'), findsNothing);
    expect(repository.calls, 0);
    expect(container.read(routeAccessProvider).caregiverAuthenticated, isFalse);
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
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
  });
  testWidgets(
    'login failure after account creation cannot submit registration twice',
    (tester) async {
      final repository = TestAuthRepository()
        ..failure = ApiFailure(ApiFailureKind.network);
      final container = await mount(tester, repository);
      await fill(tester);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Your account was created. Please log in to continue.'),
        findsOneWidget,
      );
      await container
          .read(signUpControllerProvider.notifier)
          .signUp(name: 'ignored', email: 'ignored', password: 'ignored');
      expect(repository.registrations, 1);
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isFalse,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'server field errors are translated and password visibility works',
    (tester) async {
      final repository = TestAuthRepository()
        ..registerFailure = ApiFailure(
          ApiFailureKind.server,
          code: 'VALIDATION_ERROR',
          details: [
            const ApiFieldError(field: 'body.email', message: 'PRIVATE FIELD'),
          ],
        );
      await mount(tester, repository);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
        isFalse,
      );
      await fill(tester);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Check this field'), findsOneWidget);
      expect(find.text('PRIVATE FIELD'), findsNothing);
      for (final button in tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      )) {
        expect(button.onPressed, isNull);
      }
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('A3 $language scrolls with keyboard and enlarged text', (
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
      final login = find.text(language == 'en' ? 'Log in' : 'تسجيل الدخول');
      await tester.ensureVisible(login);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.byType(A3SignupScreen), findsNothing);
    });
    testWidgets('A3 $language reference capture, RTL, and native safe area', (
      tester,
    ) async {
      final shadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      try {
        await mount(tester, TestAuthRepository(), language: language);
        expect(
          Directionality.of(tester.element(find.byType(A3SignupScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.getTopLeft(find.byType(A3SignupScreen)).dy, 47);
        expect(find.text('9:41'), findsNothing);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('a3-preview')),
            matchesGoldenFile('goldens/a3_$language.png'),
          );
        }
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
