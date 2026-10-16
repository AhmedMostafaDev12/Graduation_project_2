import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/core/api/credential_store.dart';
import 'package:remori/core/api/patient_session_provider.dart';
import 'package:remori/core/api/patient_session_store.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/relay/glasses_connection.dart';
import 'package:remori/core/relay/fake_glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/core/relay/glasses_message.dart';
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/device_pairing/domain/pairing_info.dart';
import 'package:remori/features/device_pairing/presentation/handover_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';

import 'a6_permissions_test.dart' as permissions;

const patient = '00000001-0000-4000-8000-000000000001';
const device = '00000003-0000-4000-8000-000000000008';
const serial = 'RMR-0008';
const contextFixture = PatientDeviceContext(
  patientId: patient,
  deviceId: device,
  serial: serial,
);
const handoverLabel = 'Give phone to patient → patient mode';

class TestCredentials implements CredentialStore {
  CaregiverTokens? caregiver = const CaregiverTokens(
    accessToken: 'test-caregiver',
    refreshToken: 'test-refresh',
  );
  String? token = 'test-device';
  bool clearFails = false;
  @override
  Future<CaregiverTokens?> readCaregiver() async => caregiver;
  @override
  Future<void> saveCaregiver(CaregiverTokens tokens) async =>
      caregiver = tokens;
  @override
  Future<void> clearCaregiver() async {
    if (clearFails) throw StateError('PRIVATE storage error');
    caregiver = null;
  }

  @override
  Future<String?> readDevice() async => token;
  @override
  Future<void> saveDevice(String value) async => token = value;
  @override
  Future<void> clearDevice() async => token = null;
}

class TestSessionStore implements PatientSessionStore {
  PatientDeviceContext? saved;
  bool saveFails = false;
  @override
  Future<PatientDeviceContext?> read() async => saved;
  @override
  Future<void> save(PatientDeviceContext context) async {
    if (saveFails) throw StateError('PRIVATE storage error');
    saved = context;
  }

  @override
  Future<void> clear() async => saved = null;
}

class ControlledGlasses implements GlassesConnection {
  final stateEvents = StreamController<GlassesConnectionState>.broadcast();
  final incoming = StreamController<IncomingGlassesMessage>.broadcast();
  final sent = <OutgoingGlassesMessage>[];
  bool connectWorks = true;
  bool emitHello = true;
  String? reportedSerial;
  Completer<void>? clockPending;
  bool clockFails = false;
  String? connectedSerial;
  @override
  GlassesConnectionState state = GlassesConnectionState.disconnected;
  @override
  Stream<GlassesConnectionState> get states => stateEvents.stream;
  @override
  Stream<IncomingGlassesMessage> get messages => incoming.stream;
  void change(GlassesConnectionState value) {
    state = value;
    stateEvents.add(value);
  }

  @override
  Future<void> connect(String value) async {
    connectedSerial = value;
    change(GlassesConnectionState.connecting);
    change(
      connectWorks
          ? GlassesConnectionState.connected
          : GlassesConnectionState.disconnected,
    );
    if (connectWorks && emitHello) {
      incoming.add(
        Hello(
          deviceSerial: reportedSerial ?? value,
          firmwareVersion: '0.3.1',
          protocolVersion: 1,
          queue: const GlassesQueue(events: 0, audioSegments: 0, media: 0),
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async =>
      change(GlassesConnectionState.disconnected);
  @override
  Future<void> send(OutgoingGlassesMessage message) async {
    sent.add(message);
    if (message is TimeSync) {
      if (clockFails) throw StateError('Synthetic clock failure');
      await clockPending?.future;
    }
  }

  @override
  void dispose() {
    unawaited(stateEvents.close());
    unawaited(incoming.close());
  }
}

class CallbackAdapter implements HttpClientAdapter {
  CallbackAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

class TestAdapter implements HttpClientAdapter {
  final caregiverStarted = Completer<void>();
  Completer<void>? caregiverPending;
  int deviceRequests = 0;
  int caregiverRequests = 0;
  int deviceStatus = 200;
  bool wrongDevice = false;
  String? lastAuthorization;
  Completer<void>? pending;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/me') {
      caregiverRequests++;
      if (!caregiverStarted.isCompleted) caregiverStarted.complete();
      if (caregiverPending != null) await caregiverPending!.future;
      return response(200, {'id': patient, 'role': 'caregiver'});
    }
    deviceRequests++;

    lastAuthorization = options.headers['Authorization'] as String?;
    if (pending != null) await pending!.future;
    return deviceStatus == 200
        ? response(200, [
            {
              'id': wrongDevice ? 'wrong' : device,
              'patient_id': patient,
              'serial_number': serial,
            },
          ])
        : response(deviceStatus, {
            'error': {'code': 'INVALID_TOKEN', 'message': 'PRIVATE error'},
          });
  }

  ResponseBody response(int code, Object data) => ResponseBody.fromString(
    jsonEncode(data),
    code,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  GlassesConnection glasses,
  TestCredentials credentials,
  TestSessionStore sessionStore,
  TestAdapter adapter, {
  PermissionPlatform platform = PermissionPlatform.android,
  bool paired = true,
  String language = 'en',
  bool restore = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 47);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        // Authentication fixtures do not bootstrap Today's database/network.
        patientTodayKeyProvider.overrideWithValue(null),
        credentialStoreProvider.overrideWithValue(credentials),
        // These fixtures test A6 authentication, not Home's cache/bootstrap calls.
        caregiverIdentityProvider.overrideWith((ref) async => null),
        patientSessionStoreProvider.overrideWithValue(sessionStore),
        glassesConnectionProvider.overrideWith((ref) {
          ref.onDispose(glasses.dispose);
          return glasses;
        }),
        apiClientProvider.overrideWith((ref) {
          final client = ApiClient(
            config: ApiConfig('https://example.test/api/v1'),
            credentials: credentials,
            adapter: adapter,
            onCredentialsInvalidated: ref.read(credentialsInvalidatedProvider),
            canUseCaregiver: () => !ref.read(patientSessionProvider).active,
          );
          ref.onDispose(client.close);
          return client;
        }),
        permissionServiceProvider.overrideWithValue(
          permissions.FakePermissions(platform: platform),
        ),
      ],
      child: const RepaintBoundary(
        key: Key('handover-preview'),
        child: RemoriApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  if (paired) {
    container
        .read(pairedGlassesProvider.notifier)
        .paired(
          const PairingInfo(
            deviceId: device,
            patientId: patient,
            serial: serial,
          ),
        );
  }
  if (!restore) {
    container
        .read(remoriRouterProvider)
        .goNamed(RemoriScreen.a6.name, extra: patient);
    await tester.pumpAndSettle();
  }
  return container;
}

FilledButton handover(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text(handoverLabel),
    matching: find.byType(FilledButton),
  ),
);
String route(ProviderContainer container) => container
    .read(remoriRouterProvider)
    .routeInformationProvider
    .value
    .uri
    .path;

void main() {
  test(
    'a late caregiver response is rejected after Patient Mode starts',
    () async {
      final adapter = TestAdapter()..caregiverPending = Completer<void>();
      var caregiverAllowed = true;
      final client = ApiClient(
        config: ApiConfig('https://example.test/api/v1'),
        credentials: TestCredentials(),
        adapter: adapter,
        onCredentialsInvalidated: (_) {},
        canUseCaregiver: () => caregiverAllowed,
      );
      addTearDown(client.close);
      final request = client.request<dynamic>(
        '/auth/me',
        credential: ApiCredential.caregiver,
      );
      await adapter.caregiverStarted.future;
      caregiverAllowed = false;
      adapter.caregiverPending!.complete();
      await expectLater(request, throwsA(isA<ApiFailure>()));
    },
  );

  testWidgets(
    'development fake connects and supports the actual handover flow',
    (tester) async {
      final fake = FakeGlassesConnection();
      final container = await mount(
        tester,
        fake,
        TestCredentials(),
        TestSessionStore(),
        TestAdapter(),
      );
      expect(fake.state, GlassesConnectionState.connected);
      expect(handover(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.text(handoverLabel));
      await tester.tap(find.text(handoverLabel));
      await tester.pumpAndSettle();
      expect(route(container), '/p1');
      expect(container.read(pairedGlassesProvider), isNotNull);
      expect(
        container.read(handoverConnectionProvider).readyFor(patient),
        true,
      );
      // Dispose the provider-owned fake timer before the widget-test timer audit.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(fake.state, GlassesConnectionState.disconnected);
    },
  );

  test('late refresh cannot restore caregiver tokens after handover', () async {
    final credentials = TestCredentials();
    final wire = TestAdapter();
    final started = Completer<void>();
    final finish = Completer<void>();
    var allowed = true;
    final client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: credentials,
      canUseCaregiver: () => allowed,
      onCredentialsInvalidated: (_) {},
      adapter: CallbackAdapter(
        (_) => wire.response(401, {
          'error': {'code': 'TOKEN_EXPIRED', 'message': 'Expired'},
        }),
      ),
      refreshAdapter: CallbackAdapter((_) async {
        started.complete();
        await finish.future;
        return wire.response(200, {
          'access_token': 'rotated-access',
          'refresh_token': 'rotated-refresh',
          'token_type': 'bearer',
        });
      }),
    );
    addTearDown(client.close);
    final request = client.request<dynamic>(
      '/auth/me',
      credential: ApiCredential.caregiver,
    );
    await started.future;
    await credentials.clearCaregiver();
    allowed = false;
    finish.complete();
    await expectLater(request, throwsA(isA<ApiFailure>()));
    expect(credentials.caregiver, isNull);
  });

  test(
    'secure handover context round trips and malformed context is removed',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecurePatientSessionStore();
      await store.save(contextFixture);
      expect((await store.read())!.toJson(), contextFixture.toJson());
      expect(contextFixture.toString(), 'PatientDeviceContext');
      await store.clear();
      expect(await store.read(), isNull);
      for (final value in [
        'invalid-json',
        '{"patient_id":"invalid","device_id":"invalid","serial_number":"RMR-0008"}',
        jsonEncode({
          'patient_id': patient,
          'device_id': device,
          'serial_number': '',
        }),
      ]) {
        FlutterSecureStorage.setMockInitialValues({
          'remori.patient_session': value,
        });
        expect(await store.read(), isNull);
        expect(
          await const FlutterSecureStorage().read(
            key: 'remori.patient_session',
          ),
          isNull,
        );
      }
    },
  );

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
    'connected paired serial hands over with device token and blocks caregiver routes/API',
    (tester) async {
      final glasses = ControlledGlasses();
      final credentials = TestCredentials();
      final saved = TestSessionStore();
      final adapter = TestAdapter();
      final container = await mount(
        tester,
        glasses,
        credentials,
        saved,
        adapter,
      );
      expect(glasses.connectedSerial, serial);
      expect(glasses.sent.single, isA<TimeSync>());
      expect(handover(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.text(handoverLabel));
      await tester.tap(find.text(handoverLabel));
      await tester.pumpAndSettle();
      expect(route(container), '/p1');
      expect(adapter.lastAuthorization, 'Bearer test-device');
      expect(credentials.caregiver, isNull);
      expect(saved.saved!.patientId, patient);
      expect(
        container.read(routeAccessProvider).caregiverAuthenticated,
        isFalse,
      );
      expect(container.read(routeAccessProvider).devicePaired, isTrue);
      expect(container.read(remoriRouterProvider).canPop(), isFalse);
      for (final path in ['/c1', '/a2', '/a6']) {
        container.read(remoriRouterProvider).go(path);
        await tester.pumpAndSettle();
        expect(route(container), '/p1');
      }
      await expectLater(
        container
            .read(apiClientProvider)
            .request<dynamic>('/auth/me', credential: ApiCredential.caregiver),
        throwsA(isA<ApiFailure>()),
      );
      expect(adapter.caregiverRequests, 1);
      await glasses.disconnect();
      await tester.pumpAndSettle();
      expect(route(container), '/p1');
    },
  );

  for (final identity in ['missing', 'wrong']) {
    testWidgets('A6 rejects $identity glasses identity before handover', (
      tester,
    ) async {
      final glasses = ControlledGlasses()
        ..emitHello = identity != 'missing'
        ..reportedSerial = 'OTHER';
      final adapter = TestAdapter();
      final container = await mount(
        tester,
        glasses,
        TestCredentials(),
        TestSessionStore(),
        adapter,
      );
      expect(handover(tester).onPressed, isNull);
      expect(container.read(patientSessionProvider).active, false);
      expect(adapter.deviceRequests, 0);
      expect(glasses.sent.whereType<TimeSync>(), isEmpty);
    });
  }
  testWidgets('A6 waits for clock sync and ignores success after disconnect', (
    tester,
  ) async {
    final glasses = ControlledGlasses()..clockPending = Completer<void>();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
    );
    expect(handover(tester).onPressed, isNull);
    glasses.change(GlassesConnectionState.disconnected);
    glasses.clockPending!.complete();
    await tester.pumpAndSettle();
    expect(handover(tester).onPressed, isNull);
  });

  testWidgets('A6 enables handover only after matching clock sync completes', (
    tester,
  ) async {
    final glasses = ControlledGlasses()..clockPending = Completer<void>();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
    );
    expect(handover(tester).onPressed, isNull);
    glasses.clockPending!.complete();
    await tester.pumpAndSettle();
    expect(handover(tester).onPressed, isNotNull);
  });
  testWidgets(
    'A6 clock-sync failure cannot be overwritten by transport success',
    (tester) async {
      final glasses = ControlledGlasses()..clockFails = true;
      await mount(
        tester,
        glasses,
        TestCredentials(),
        TestSessionStore(),
        TestAdapter(),
      );
      expect(handover(tester).onPressed, isNull);
    },
  );
  testWidgets('A6 ignores the old connection after pairing changes', (
    tester,
  ) async {
    final glasses = ControlledGlasses()..clockPending = Completer<void>();
    final adapter = TestAdapter();
    final container = await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      adapter,
    );
    container
        .read(pairedGlassesProvider.notifier)
        .paired(
          const PairingInfo(
            deviceId: 'new-device',
            patientId: patient,
            serial: 'OTHER',
          ),
        );
    await tester.pumpAndSettle();
    glasses.clockPending!.complete();
    await tester.pumpAndSettle();
    expect(handover(tester).onPressed, isNull);
    expect(container.read(handoverConnectionProvider).context, isNull);
    expect(adapter.deviceRequests, 0);
  });

  testWidgets(
    'A6 can prepare a new pairing while the old clock send is pending',
    (tester) async {
      final oldClock = Completer<void>();
      final glasses = ControlledGlasses()..clockPending = oldClock;
      final container = await mount(
        tester,
        glasses,
        TestCredentials(),
        TestSessionStore(),
        TestAdapter(),
      );
      container
          .read(pairedGlassesProvider.notifier)
          .paired(
            const PairingInfo(
              deviceId: 'new-device',
              patientId: patient,
              serial: 'OTHER',
            ),
          );
      await tester.pumpAndSettle();
      glasses.clockPending = null;
      final pending = container
          .read(handoverConnectionProvider.notifier)
          .prepare(patient);
      await tester.pumpAndSettle();
      await pending;
      expect(
        container.read(handoverConnectionProvider).context?.deviceId,
        'new-device',
      );
      expect(
        container.read(handoverConnectionProvider).readyFor(patient),
        true,
      );
      oldClock.complete();
      await tester.pumpAndSettle();
      expect(
        container.read(handoverConnectionProvider).context?.deviceId,
        'new-device',
      );
      expect(
        container.read(handoverConnectionProvider).readyFor(patient),
        true,
      );
    },
  );

  testWidgets('caregiver logout clears pairing grant and handover readiness', (
    tester,
  ) async {
    final container = await mount(
      tester,
      ControlledGlasses(),
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
    );
    expect(container.read(pairedGlassesProvider), isNotNull);
    container.read(caregiverSessionProvider.notifier).invalidate();
    await tester.pumpAndSettle();
    expect(container.read(pairedGlassesProvider), isNull);
    expect(container.read(handoverConnectionProvider).readyFor(patient), false);
  });

  testWidgets('disconnected link keeps pending text and disabled handover', (
    tester,
  ) async {
    final glasses = ControlledGlasses()..connectWorks = false;
    final adapter = TestAdapter();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      adapter,
    );
    expect(handover(tester).onPressed, isNull);
    expect(
      find.textContaining('Patient handover will be available'),
      findsOneWidget,
    );
    expect(adapter.deviceRequests, 0);
  });

  testWidgets('disconnect after connecting disables handover immediately', (
    tester,
  ) async {
    final glasses = ControlledGlasses();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
    );
    expect(handover(tester).onPressed, isNotNull);
    await glasses.disconnect();
    await tester.pumpAndSettle();
    expect(handover(tester).onPressed, isNull);
  });

  testWidgets('A6 without a successful A5 grant never connects', (
    tester,
  ) async {
    final glasses = ControlledGlasses();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
      paired: false,
    );
    expect(glasses.connectedSerial, isNull);
    expect(handover(tester).onPressed, isNull);
  });

  testWidgets('iOS stays caregiver only and never starts a connection', (
    tester,
  ) async {
    final glasses = ControlledGlasses();
    await mount(
      tester,
      glasses,
      TestCredentials(),
      TestSessionStore(),
      TestAdapter(),
      platform: PermissionPlatform.ios,
    );
    expect(glasses.connectedSerial, isNull);
    expect(find.text(handoverLabel), findsNothing);
  });

  for (final failure in [
    'missing token',
    'revoked token',
    'wrong device',
    'session storage',
    'caregiver storage',
  ]) {
    testWidgets('$failure cannot enable Patient Mode', (tester) async {
      final credentials = TestCredentials();
      final saved = TestSessionStore();
      final adapter = TestAdapter();
      if (failure == 'missing token') credentials.token = null;
      if (failure == 'revoked token') adapter.deviceStatus = 401;
      if (failure == 'wrong device') adapter.wrongDevice = true;
      if (failure == 'session storage') saved.saveFails = true;
      if (failure == 'caregiver storage') credentials.clearFails = true;
      final container = await mount(
        tester,
        ControlledGlasses(),
        credentials,
        saved,
        adapter,
      );
      await tester.ensureVisible(find.text(handoverLabel));
      await tester.tap(find.text(handoverLabel));
      await tester.pumpAndSettle();
      expect(route(container), '/a6');
      expect(container.read(routeAccessProvider).devicePaired, isFalse);
      expect(saved.saved, isNull);
      expect(
        find.textContaining('Unable to enter Patient Mode'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE'), findsNothing);
    });
  }

  testWidgets(
    'duplicate taps make one request and disconnect during validation denies handover',
    (tester) async {
      final glasses = ControlledGlasses();
      final saved = TestSessionStore();
      final adapter = TestAdapter()..pending = Completer<void>();
      final container = await mount(
        tester,
        glasses,
        TestCredentials(),
        saved,
        adapter,
      );
      await tester.ensureVisible(find.text(handoverLabel));
      await tester.tap(find.text(handoverLabel));
      await tester.pump();
      expect(handover(tester).onPressed, isNull);
      expect(
        await container
            .read(patientSessionProvider.notifier)
            .handover(contextFixture, connected: () => true),
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(adapter.deviceRequests, 1);
      await glasses.disconnect();
      adapter.pending!.complete();
      await tester.pumpAndSettle();
      expect(route(container), '/a6');
      expect(saved.saved, isNull);
      expect(container.read(patientSessionProvider).active, isFalse);
    },
  );

  testWidgets(
    'secure patient session restores offline without caregiver access',
    (tester) async {
      final credentials = TestCredentials();
      final saved = TestSessionStore()..saved = contextFixture;
      final adapter = TestAdapter();
      final container = await mount(
        tester,
        ControlledGlasses(),
        credentials,
        saved,
        adapter,
        restore: true,
      );
      expect(route(container), '/p1');
      expect(credentials.caregiver, isNull);
      expect(adapter.caregiverRequests, 0);
      expect(adapter.deviceRequests, 0);
      expect(container.read(patientSessionProvider).active, isTrue);
      adapter.deviceStatus = 401;
      await tester.runAsync(
        () => expectLater(
          container
              .read(apiClientProvider)
              .request<dynamic>(
                '/patients/$patient/devices',
                credential: ApiCredential.device,
              ),
          throwsA(isA<ApiFailure>()),
        ),
      );
      await tester.pumpAndSettle();
      expect(credentials.token, isNull);
      expect(saved.saved, isNull);
      expect(route(container), '/a2');
    },
  );

  testWidgets('restoration without device token cannot grant patient access', (
    tester,
  ) async {
    final saved = TestSessionStore()..saved = contextFixture;
    final container = await mount(
      tester,
      ControlledGlasses(),
      TestCredentials()..token = null,
      saved,
      TestAdapter(),
      restore: true,
    );
    expect(container.read(patientSessionProvider).active, isFalse);
    expect(saved.saved, isNull);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('connected A6 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(
        tester,
        ControlledGlasses(),
        TestCredentials(),
        TestSessionStore(),
        TestAdapter(),
        language: language,
      );
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('handover-preview')),
          matchesGoldenFile('goldens/a6_connected_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
  }
}
