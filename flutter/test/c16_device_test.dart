import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/device_providers.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/device_pairing/domain/pairing_info.dart';
import 'package:remori/features/device_pairing/presentation/handover_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as home;
import 'c8_reminders_test.dart' as c8;

const scope = ('caregiver-A', home.patient);
final now = home.now;

class Adapter extends home.HomeAdapter {
  bool memory = true, removed = false;
  int count = 1;
  Map<String, Object?>? invalid;
  Completer<void>? gate;
  @override
  List<Map<String, Object?>> get patients => [
    for (final p in super.patients)
      {...p, if (p['id'] == home.patient) 'memory_capture_enabled': memory},
  ];
  Map<String, Object?> device(int i) => {
    'id': 'device-$i',
    'patient_id': home.patient,
    'serial_number': 'RMR-000${7 + i}',
    'firmware_version': '0.3.1',
    'battery_level_pct': 76,
    'last_seen_at': now.subtract(const Duration(minutes: 2)).toIso8601String(),
    'paired_at': now.subtract(Duration(days: i + 1)).toIso8601String(),
    'online': true,
    ...?invalid,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (!o.path.endsWith('/devices') && o.method == 'GET') {
      return super.fetch(o, stream, cancel);
    }
    requests.add(o);
    final before = [
      if (!removed)
        for (var i = 0; i < count; i++) device(i),
    ];
    if (gate != null && o.method == 'GET') await gate!.future;
    if (this.fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    if (denied) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE'},
        }),
        404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (o.method == 'DELETE') {
      removed = true;
      return ResponseBody.fromString('', 204);
    }
    Object? response = before;
    if (o.method == 'PATCH') {
      memory = (o.data as Map)['memory_capture_enabled'] as bool;
      response = patients.first;
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class Repository extends HomeRepository {
  Repository(super.client, super.db, super.caregiverId);
  final updates = StreamController<void>.broadcast();
  bool cacheFails = false;
  @override
  Stream<HomeData> watch() async* {
    yield await read();
    await for (final _ in updates.stream) {
      yield await read();
    }
  }

  @override
  Future<void> refreshDevices(String id) async {
    try {
      await super.refreshDevices(id);
    } finally {
      if (!updates.isClosed) updates.add(null);
    }
  }

  @override
  Future<void> cacheDeviceChange(DeviceChange change) async {
    if (cacheFails) throw StateError('Synthetic cache failure');
    await super.cacheDeviceChange(change);
    if (!updates.isClosed) updates.add(null);
  }

  @override
  void dispose() {
    if (!updates.isClosed) updates.close();
    super.dispose();
  }
}

void main() {
  late RemoriDatabase db;
  late Adapter adapter;
  late ApiClient client;
  late Repository repo;
  late auth.TestCredentials credentials;
  setUpAll(() async {
    for (final e in {
      'DM Sans': 'assets/fonts/DM-Sans.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Readex Pro': 'assets/fonts/Readex-Pro.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  setUp(() {
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = Adapter();
    credentials = auth.TestCredentials();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: credentials,
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = Repository(client, db, scope.$1);
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });
  Future<void> patient({
    String account = 'caregiver-A',
    String id = home.patient,
    bool viewer = false,
  }) => db
      .into(db.dashboardPatients)
      .insert(
        DashboardPatientsCompanion.insert(
          caregiverId: account,
          id: id,
          fullName: 'Patient',
          preferredLanguage: 'en',
          timezone: 'Africa/Cairo',
          memoryCaptureEnabled: true,
          permission: viewer ? 'viewer' : 'manager',
          position: 0,
        ),
      );
  test('device refresh caches firmware, pairing time and readings in the shared cache', () async {
    await patient();
    await repo.refreshDevices(home.patient);
    final d = (await repo.read()).devices.single;
    expect(d.firmware, '0.3.1');
    expect(d.battery, 76);
    expect(d.pairedAt, now.subtract(const Duration(days: 1)));
    expect(adapter.requests.single.path, '/patients/${home.patient}/devices');
  });
  test('offline refresh retains readings', () async {
    await patient();
    await repo.refreshDevices(home.patient);
    adapter.fail = true;
    await expectLater(
      repo.refreshDevices(home.patient),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read()).devices.single.serial, 'RMR-0007');
  });
  for (final bad in [
    {'patient_id': home.otherPatient},
    {'battery_level_pct': 101},
    {'online': 'yes'},
    {'firmware_version': 7},
    {'paired_at': 'bad'},
  ]) {
    test('invalid device refresh is atomic: $bad', () async {
      await patient();
      await repo.refreshDevices(home.patient);
      adapter.invalid = bad;
      await expectLater(
        repo.refreshDevices(home.patient),
        throwsA(isA<ApiFailure>()),
      );
      expect((await repo.read()).devices.single.firmware, '0.3.1');
    });
  }
  test('scoped refresh and unpair preserve another caregiver cache', () async {
    await patient();
    await patient(account: 'other');
    await repo.refreshDevices(home.patient);
    final other = HomeRepository(client, db, 'other');
    await other.refreshDevices(home.patient);
    await repo.cacheDeviceChange(
      await repo.changeDevice(home.patient, unpairId: 'device-0'),
    );
    expect((await repo.read()).devices, isEmpty);
    expect((await other.read()).devices.length, 1);
    other.dispose();
  });
  test(
    'viewer cannot write memory or unpair, including direct repository calls',
    () async {
      await patient(viewer: true);
      await repo.refreshDevices(home.patient);
      await expectLater(
        repo.changeDevice(home.patient, memoryEnabled: false),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        repo.changeDevice(home.patient, unpairId: 'device-0'),
        throwsA(isA<ApiFailure>()),
      );
      expect(adapter.requests.every((r) => r.method == 'GET'), true);
    },
  );
  test(
    'memory PATCH updates only memory_capture_enabled after acknowledgment',
    () async {
      await patient();
      final change = await repo.changeDevice(
        home.patient,
        memoryEnabled: false,
      );
      expect((await repo.read()).patients.single.memoryEnabled, true);
      expect(adapter.requests.single.data, {'memory_capture_enabled': false});
      await repo.cacheDeviceChange(change);
      expect((await repo.read()).patients.single.memoryEnabled, false);
    },
  );
  test('old refresh cannot restore a confirmed unpaired device', () async {
    await patient();
    await repo.refreshDevices(home.patient);
    adapter.gate = Completer<void>();
    final pending = repo.refreshDevices(home.patient);
    while (adapter.requests.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    await repo.cacheDeviceChange(
      await repo.changeDevice(home.patient, unpairId: 'device-0'),
    );
    adapter.gate!.complete();
    await pending;
    expect((await repo.read()).devices, isEmpty);
  });
  test(
    'older Home refresh cannot undo an acknowledged memory change',
    () async {
      await patient();
      adapter.gate = Completer<void>();
      final pending = repo.refresh(home.patient);
      while (!adapter.requests.any((r) => r.path.endsWith('/devices'))) {
        await Future<void>.delayed(Duration.zero);
      }
      await repo.cacheDeviceChange(
        await repo.changeDevice(home.patient, memoryEnabled: false),
      );
      adapter.gate!.complete();
      await pending;
      expect((await repo.read()).patients.single.memoryEnabled, false);
    },
  );
  test('link removed during refresh cannot be recreated', () async {
    await patient();
    adapter.gate = Completer<void>();
    final pending = repo.refreshDevices(home.patient);
    while (adapter.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await db.delete(db.dashboardPatients).go();
    adapter.gate!.complete();
    await pending;
    expect((await repo.read()).devices, isEmpty);
  });
  test('known revoked link purges cached patient and devices', () async {
    await patient();
    await repo.refreshDevices(home.patient);
    adapter.denied = true;
    await expectLater(
      repo.refreshDevices(home.patient),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read()).patients, isEmpty);
    expect((await repo.read()).devices, isEmpty);
  });
  test(
    'schema v12 migration preserves device rows and queued writes',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp(
        'remori-c16-migration-',
      );
      try {
        final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
        db = RemoriDatabase(NativeDatabase(file));
        repo = Repository(client, db, scope.$1);
        await patient();
        await repo.refreshDevices(home.patient);
        await db.saveReminderLog(
          patientId: home.patient,
          reminderId: '00000005-0000-4000-8000-000000000001',
          scheduledAt: now,
          at: now,
          status: ReminderStatus.pending,
        );
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN firmware_version',
        );
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN paired_at',
        );
        await db.customStatement('DROP TABLE cached_caregiver_accounts');
        await db.customStatement('DROP TABLE cached_consents');
        await db.customStatement('DROP TABLE cached_caregiver_links');
        await db.customStatement('DROP TABLE caregivers_cache_states');
        await db.customStatement('DROP TABLE patient_today_settings');
        await db.customStatement('DROP TABLE patient_reminder_cards');
        await db.customStatement('DROP TABLE patient_known_encounters');
        await db.customStatement('DROP TABLE patient_journal_entries');
        await db.customStatement('DROP TABLE patient_journal_media');
        await db.customStatement('DROP TABLE patient_journal_days');
        await db.customStatement('DROP TABLE patient_memory_details');
        await db.customStatement('DROP TABLE patient_game_scores');
        await db.customStatement('DROP TABLE patient_game_refreshes');
        await db.customStatement('DROP TABLE patient_game_people');
        await db.customStatement('DROP TABLE patient_game_sessions');
        await db.customStatement('PRAGMA user_version = 12');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect(
          (await db.select(db.dashboardDevices).getSingle()).firmwareVersion,
          isNull,
        );
        expect((await db.pendingWrites(home.patient)).length, 1);
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
      } finally {
        if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
            !dir.path.contains('remori-c16-migration-')) {
          throw StateError('Unexpected temporary path');
        }
        await dir.delete(recursive: true);
      }
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    DeviceScope? Function()? selected,
  }) async {
    await tester.runAsync(() async {
      if ((await db.select(db.dashboardPatients).get()).isEmpty) {
        await patient(viewer: viewer);
      }
    });
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final defaults = ProviderContainer();
    final builders = defaults.read(screenBuildersProvider);
    defaults.dispose();
    final container = ProviderContainer(
      overrides: [
        routeAccessProvider.overrideWithValue(
          const RouteAccess(caregiverAuthenticated: true),
        ),
        caregiverIdentityProvider.overrideWith((ref) async => scope.$1),
        credentialStoreProvider.overrideWithValue(credentials),
        deviceScopeProvider.overrideWith(
          (ref) => selected == null ? scope : selected(),
        ),
        homeRepositoryProvider(scope.$1).overrideWithValue(repo),
        homeDataProvider.overrideWith(
          (ref) => ref.watch(deviceScopeProvider) == scope
              ? repo.watch()
              : Stream.value(const HomeData()),
        ),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        deviceClockProvider.overrideWithValue(() => now),
        deviceNowProvider.overrideWith((ref) => Stream.value(now)),
        appLocaleProvider.overrideWithValue(Locale(language)),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.a5: (_, state) =>
              Text('Pair destination', key: ValueKey(state.extra)),
          RemoriScreen.a1: (_, _) => const Text('Mode destination'),
          RemoriScreen.c18: (_, _) => const Text('More destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c16-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c16.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('C16 shows actual device readings and memory setting', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('RMR-0007'), findsOneWidget);
    expect(find.text('0.3.1'), findsOneWidget);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('2 min ago'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
  });
  testWidgets('memory toggle persists acknowledged value', (tester) async {
    await mount(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    expect(adapter.requests.where((r) => r.method == 'PATCH').length, 1);
  });
  testWidgets('cache-only retry never repeats confirmed PATCH', (tester) async {
    await mount(tester);
    repo.cacheFails = true;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      find.text('The change was saved. Retry to finish updating this phone.'),
      findsOneWidget,
    );
    repo.cacheFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'PATCH').length, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
  });
  testWidgets('uncertain write locks changes until authoritative refresh', (
    tester,
  ) async {
    final container = await mount(tester);
    adapter.fail = true;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(container.read(deviceControllerProvider(scope)).uncertain, true);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    adapter.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(container.read(deviceControllerProvider(scope)).uncertain, false);
  });
  testWidgets('unpair requires confirmation and Cancel sends nothing', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Unpair glasses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
    await tester.tap(find.text('Unpair glasses'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Unpair glasses').last);
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'DELETE').length, 1);
    expect(find.text('Mode destination'), findsOneWidget);
  });
  testWidgets('viewer sees readings without pairing or unpair controls', (
    tester,
  ) async {
    final container = await mount(tester, viewer: true);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Unpair glasses'), findsNothing);
    expect(find.text('Re-pair glasses'), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      await container
          .read(deviceControllerProvider(scope).notifier)
          .change(memoryEnabled: false),
      false,
    );
  });
  testWidgets('unpair clears only a matching local device grant', (
    tester,
  ) async {
    final container = await mount(tester);
    container
        .read(pairedGlassesProvider.notifier)
        .paired(
          const PairingInfo(
            deviceId: 'device-0',
            patientId: home.patient,
            serial: 'RMR-0007',
          ),
        );
    expect(
      await tester.runAsync(
        () => container
            .read(deviceControllerProvider(scope).notifier)
            .change(unpairId: 'device-0'),
      ),
      true,
    );
    expect(credentials.token, isNull);
    expect(container.read(pairedGlassesProvider), isNull);
  });
  testWidgets('unpair preserves another local device grant', (tester) async {
    final container = await mount(tester);
    container
        .read(pairedGlassesProvider.notifier)
        .paired(
          const PairingInfo(
            deviceId: 'other',
            patientId: home.otherPatient,
            serial: 'RMR-OTHER',
          ),
        );
    expect(
      await tester.runAsync(
        () => container
            .read(deviceControllerProvider(scope).notifier)
            .change(unpairId: 'device-0'),
      ),
      true,
    );
    expect(credentials.token, 'test-device');
  });
  testWidgets('re-pair opens existing A5 with selected patient', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Re-pair glasses'));
    await tester.pumpAndSettle();
    expect(find.text('Pair destination'), findsOneWidget);
    expect(
      (tester.widget<Text>(find.text('Pair destination')).key as ValueKey)
          .value,
      home.patient,
    );
  });
  testWidgets('multiple paired glasses have individual unpair actions', (
    tester,
  ) async {
    adapter.count = 2;
    await mount(tester);
    expect(find.text('RMR-0007'), findsOneWidget);
    expect(find.text('RMR-0008'), findsOneWidget);
    expect(find.text('Unpair glasses'), findsNWidgets(2));
  });
  testWidgets('offline shows saved readings without claiming connected', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await patient();
      await repo.refreshDevices(home.patient);
    });
    adapter.fail = true;
    await mount(tester);
    expect(find.text('RMR-0007'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
    expect(find.text('Status unavailable'), findsOneWidget);
  });
  testWidgets('account or patient change hides previous readings', (
    tester,
  ) async {
    DeviceScope? selected = scope;
    final container = await mount(tester, selected: () => selected);
    selected = null;
    container.invalidate(deviceScopeProvider);
    await tester.pumpAndSettle();
    expect(find.text('RMR-0007'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C16 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, language: language);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c16-preview')),
          matchesGoldenFile('goldens/c16_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C16 $language supports 2x text at 320dp', (tester) async {
      await mount(tester, language: language, scale: 2);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
