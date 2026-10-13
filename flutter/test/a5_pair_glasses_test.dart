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
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/device_pairing/domain/pairing_info.dart';
import 'package:remori/features/device_pairing/data/pairing_repository.dart';
import 'package:remori/features/device_pairing/presentation/a5_pair_glasses_screen.dart';
import 'package:remori/features/device_pairing/presentation/a6_permissions_screen.dart';
import 'package:remori/features/device_pairing/presentation/pairing_providers.dart';
import 'package:remori/features/device_pairing/presentation/glasses_qr_scanner.dart';

const patientId = '00000001-0000-4000-8000-000000000001';

class TestPairingRepository extends PairingRepository {
  TestPairingRepository()
    : super(
        ApiClient(
          config: ApiConfig('https://example.test/api/v1'),
          credentials: SecureCredentialStore(),
          onCredentialsInvalidated: (_) {},
        ),
        SecureCredentialStore(),
      );
  int calls = 0;
  Completer<void>? pending;
  ApiFailure? failure;
  @override
  Future<PairingInfo> pair(String patient, String serial) async {
    calls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    return PairingInfo(
      deviceId: '00000002-0000-4000-8000-000000000001',
      patientId: patient,
      serial: serial,
    );
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  TestPairingRepository repository, {
  String language = 'en',
  Size size = const Size(390, 844),
  double scale = 1,
  String? patient = patientId,
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
        permissionPlatformProvider.overrideWithValue(
          PermissionPlatform.unsupported,
        ),
        appLocaleProvider.overrideWithValue(Locale(language)),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(caregiverAuthenticated: true),
        ),
        pairingRepositoryProvider.overrideWithValue(repository),
        qrScannerBuilderProvider.overrideWithValue(
          (context, onSerial) => TextButton(
            onPressed: () => onSerial('RMR-0007'),
            child: const Text('Detect test QR'),
          ),
        ),
      ],
      child: const RepaintBoundary(key: Key('a5-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container
      .read(remoriRouterProvider)
      .goNamed(RemoriScreen.a5.name, extra: patient);
  await tester.pumpAndSettle();
  return container;
}

Future<void> scan(WidgetTester tester) async {
  await tester.tap(find.text('Scan QR code'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Detect test QR'));
  await tester.pump();
}

FilledButton continueButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(of: find.text('Continue'), matching: find.byType(FilledButton)),
);
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
    'scan is explicit and Continue waits for secure association; BLE stays pending',
    (tester) async {
      final repository = TestPairingRepository()..pending = Completer<void>();
      final container = await mount(tester, repository);
      expect(find.text('Detect test QR'), findsNothing);
      expect(continueButton(tester).onPressed, isNull);
      await scan(tester);
      expect(repository.calls, 1);
      expect(continueButton(tester).onPressed, isNull);
      await container
          .read(pairingControllerProvider.notifier)
          .pair(patientId, 'RMR-0007');
      expect(repository.calls, 1);
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Glasses linked. Bluetooth connection is still pending.'),
        findsOneWidget,
      );
      expect(container.read(routeAccessProvider).devicePaired, isFalse);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(A6PermissionsScreen), findsOneWidget);
      expect(
        tester
            .widget<A6PermissionsScreen>(find.byType(A6PermissionsScreen))
            .patientId,
        patientId,
      );
    },
  );
  testWidgets('missing patient cannot scan or Continue', (tester) async {
    final repository = TestPairingRepository();
    await mount(tester, repository, patient: null);
    expect(find.text('Return to patient setup to continue.'), findsOneWidget);
    final scanButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Scan QR code'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(scanButton.onPressed, isNull);
    expect(continueButton(tester).onPressed, isNull);
    expect(repository.calls, 0);
  });
  testWidgets('pairing conflict is translated and cannot enable Continue', (
    tester,
  ) async {
    final repository = TestPairingRepository()
      ..failure = ApiFailure(
        ApiFailureKind.server,
        code: 'DEVICE_ALREADY_PAIRED',
        message: 'PRIVATE TOKEN COPY',
      );
    await mount(tester, repository);
    await scan(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('These glasses are paired with someone else.'),
      findsOneWidget,
    );
    expect(find.text('PRIVATE TOKEN COPY'), findsNothing);
    expect(continueButton(tester).onPressed, isNull);
  });
  testWidgets(
    'storage failure retries the received grant instead of opening camera again',
    (tester) async {
      final repository = TestPairingRepository()
        ..failure = ApiFailure(ApiFailureKind.credentials);
      await mount(tester, repository);
      await scan(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The glasses were linked, but saving on this phone failed. Please retry.',
        ),
        findsOneWidget,
      );
      expect(continueButton(tester).onPressed, isNull);
      repository.failure = null;
      await tester.tap(find.text('Retry pairing'));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('Detect test QR'), findsNothing);
      expect(continueButton(tester).onPressed, isNotNull);
    },
  );
  testWidgets('header opens A4 as exported', (tester) async {
    final container = await mount(tester, TestPairingRepository());
    await tester.tap(find.text('Pair glasses'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(remoriRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .path,
      '/a4',
    );
  });
  testWidgets('A6 back preserves linked A5 without another pairing request', (
    tester,
  ) async {
    final repository = TestPairingRepository();
    await mount(tester, repository);
    await scan(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Permissions'));
    await tester.pumpAndSettle();
    expect(find.byType(A5PairGlassesScreen), findsOneWidget);
    expect(
      find.text('Glasses linked. Bluetooth connection is still pending.'),
      findsOneWidget,
    );
    expect(repository.calls, 1);
    expect(continueButton(tester).onPressed, isNotNull);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('A5 $language linked state still shows Bluetooth pending', (
      tester,
    ) async {
      final shadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      try {
        await mount(tester, TestPairingRepository(), language: language);
        await tester.tap(
          find.text(language == 'en' ? 'Scan QR code' : 'مسح رمز QR'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Detect test QR'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == 'en'
                ? 'Glasses linked. Bluetooth connection is still pending.'
                : 'تم ربط النظارة بالمريض. لم يكتمل اتصال البلوتوث بعد.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('RMR-0007'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('a5-preview')),
            matchesGoldenFile('goldens/a5_linked_$language.png'),
          );
        }
      } finally {
        debugDisableShadows = shadows;
      }
    });
    testWidgets('A5 $language scrolls with enlarged text', (tester) async {
      await mount(
        tester,
        TestPairingRepository(),
        language: language,
        size: const Size(320, 480),
        scale: 2,
      );
      await tester.ensureVisible(
        find.text(language == 'en' ? 'Continue' : 'متابعة'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('A5 $language reference capture and safe area', (tester) async {
      final shadows = debugDisableShadows;
      if (autoUpdateGoldenFiles) debugDisableShadows = false;
      try {
        await mount(tester, TestPairingRepository(), language: language);
        expect(
          Directionality.of(tester.element(find.byType(A5PairGlassesScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.getTopLeft(find.byType(A5PairGlassesScreen)).dy, 47);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('a5-preview')),
            matchesGoldenFile('goldens/a5_$language.png'),
          );
        }
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
