import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/credential_store.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/enrollment/domain/patient_draft.dart';
import 'package:remori/features/enrollment/data/patient_repository.dart';
import 'package:remori/features/enrollment/presentation/a4_patient_profile_screen.dart';
import 'package:remori/features/enrollment/presentation/patient_setup_providers.dart';

const patientId = '00000001-0000-4000-8000-000000000001';

class TestPatientRepository extends PatientRepository {
  TestPatientRepository()
    : super(
        ApiClient(
          config: ApiConfig('https://example.test/api/v1'),
          credentials: SecureCredentialStore(),
          onCredentialsInvalidated: (_) {},
        ),
      );
  int calls = 0;
  PatientDraft? submitted;
  Completer<void>? pending;
  ApiFailure? failure;
  @override
  Future<String> create(PatientDraft draft) async {
    calls++;
    submitted = draft;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    return patientId;
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  TestPatientRepository repository, {
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
        routeAccessProvider.overrideWithValue(
          const RouteAccess(caregiverAuthenticated: true),
        ),
        patientRepositoryProvider.overrideWithValue(repository),
      ],
      child: const RepaintBoundary(key: Key('a4-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.a4.name);
  await tester.pumpAndSettle();
  return container;
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'Test Patient');
  await tester.enterText(find.byType(TextField).at(1), 'daughter');
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();
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
  testWidgets(
    'defaults do not silently grant consent; creation passes ID to A5',
    (tester) async {
      final repository = TestPatientRepository()..pending = Completer<void>();
      final container = await mount(tester, repository);
      await fill(tester);
      await submit(tester);
      expect(repository.calls, 1);
      expect(repository.submitted!.language, 'en');
      expect(repository.submitted!.timezone, 'Africa/Cairo');
      expect(repository.submitted!.toJson()['consents'], isEmpty);
      await container
          .read(patientSetupProvider.notifier)
          .create(repository.submitted!);
      expect(repository.calls, 1);
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/a4',
      );
      repository.pending!.complete();
      await tester.pumpAndSettle();
      final router = container.read(remoriRouterProvider);
      expect(router.routeInformationProvider.value.uri.path, '/a5');
      expect(router.routerDelegate.currentConfiguration.extra, patientId);
    },
  );
  testWidgets('chosen language, consent, and calendar date reach the request', (
    tester,
  ) async {
    final repository = TestPatientRepository();
    await mount(tester, repository);
    await fill(tester);
    await tester.enterText(find.byType(TextField).at(2), '١٢ / ٠٣ / ١٩٥٤');
    await tester.ensureVisible(find.text('العربية Arabic'));
    await tester.tap(find.text('العربية Arabic'));
    await tester.ensureVisible(find.text('Conversation memory'));
    await tester.tap(find.text('Conversation memory'));
    await submit(tester);
    await tester.pumpAndSettle();
    expect(repository.submitted!.language, 'ar');
    expect(repository.submitted!.dateOfBirth, '1954-03-12');
    expect(repository.submitted!.toJson()['consents'], [
      'ambient_audio_household',
    ]);
  });
  testWidgets(
    'name and approved relationship are required; invalid dates stay on A4',
    (tester) async {
      final repository = TestPatientRepository();
      await mount(tester, repository);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text('This field is required'), findsNWidgets(2));
      await fill(tester);
      await tester.enterText(find.byType(TextField).at(2), '31/02/1954');
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid date as DD / MM / YYYY'), findsOneWidget);
      expect(repository.calls, 0);
    },
  );
  testWidgets(
    'server timezone validation highlights the field without raw messages',
    (tester) async {
      final repository = TestPatientRepository()
        ..failure = ApiFailure(
          ApiFailureKind.server,
          code: 'VALIDATION_ERROR',
          message: 'PRIVATE',
          details: [
            const ApiFieldError(
              field: 'body.timezone',
              message: 'PRIVATE FIELD',
            ),
          ],
        );
      final container = await mount(tester, repository);
      await fill(tester);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Check this field'), findsOneWidget);
      expect(find.text('PRIVATE'), findsNothing);
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
  testWidgets('header returns to A2 as exported', (tester) async {
    final container = await mount(tester, TestPatientRepository());
    await tester.tap(find.text('New patient'));
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
  testWidgets('checkboxes can independently grant and revoke cloud consent', (
    tester,
  ) async {
    final repository = TestPatientRepository();
    await mount(tester, repository);
    await fill(tester);
    final cloud = find.byType(Checkbox).at(1);
    await tester.ensureVisible(cloud);
    await tester.tap(cloud);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(cloud).value, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
    await tester.tap(cloud);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(cloud).value, isFalse);
    await tester.tap(cloud);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(repository.submitted!.toJson()['consents'], ['cloud_processing']);
  });
  for (final language in ['en', 'ar']) {
    testWidgets(
      'A4 $language keeps actions reachable with keyboard and enlarged text',
      (tester) async {
        await mount(
          tester,
          TestPatientRepository(),
          language: language,
          size: const Size(320, 480),
          scale: 2,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(language == 'en' ? 'Continue' : 'متابعة'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('A4 $language reference capture and RTL', (tester) async {
      final shadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      try {
        await mount(tester, TestPatientRepository(), language: language);
        expect(
          Directionality.of(
            tester.element(find.byType(A4PatientProfileScreen)),
          ),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.getTopLeft(find.byType(A4PatientProfileScreen)).dy, 47);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('a4-preview')),
            matchesGoldenFile('goldens/a4_$language.png'),
          );
        }
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
