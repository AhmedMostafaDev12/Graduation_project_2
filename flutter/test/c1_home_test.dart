import 'dart:async';
import 'dart:convert';

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
import 'package:remori/core/db/database_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/core/relay/glasses_message.dart';
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/presentation/c1_home_screen.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/journal/presentation/c12_journal_screen.dart';

import 'a6_handover_test.dart' as handover;
import 'a6_permissions_test.dart' as permissions;

const patient = '00000001-0000-4000-8000-000000000001';
const otherPatient = '00000001-0000-4000-8000-000000000002';
final now = DateTime.utc(2026, 10, 14, 12);

class HomeAdapter implements HttpClientAdapter {
  bool fail = false, empty = false;
  String permission = 'manager';
  bool malformed = false;
  bool paginate = false;
  bool denied = false;
  final requests = <RequestOptions>[];
  List<Map<String, Object?>> get patients => [
    {
      'id': patient,
      'full_name': 'فاطمة محمود',
      'preferred_language': 'ar',
      'timezone': 'Africa/Cairo',
      'memory_capture_enabled': true,
      'permission': permission,
      'is_primary': true,
    },
    {
      'id': otherPatient,
      'full_name': 'Second patient',
      'preferred_language': 'en',
      'timezone': 'Asia/Riyadh',
      'memory_capture_enabled': false,
      'permission': 'viewer',
      'is_primary': false,
    },
  ];
  Map<String, Object?> alert(int index, String id) => {
    'id': 'alert-$index-$id',
    'patient_id': id,
    'alert_type': [
      'missed_medication',
      'unknown_person_flagged',
      'daily_summary_ready',
    ][index % 3],
    'message': [
      'Blood pressure pill · yesterday 09:00',
      'Someone new visited 3 times',
      "Yesterday’s summary is ready",
    ][index % 3],
    'read_at': null,
    'created_at': now.subtract(Duration(minutes: index)).toIso8601String(),
    'entity_type': null,
    'entity_id': null,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (fail) {
      throw DioException(
        requestOptions: options,
        error: 'PRIVATE response',
        type: DioExceptionType.connectionError,
      );
    }
    final p = options.path.contains(otherPatient) ? otherPatient : patient;
    if (denied && options.path.startsWith('/patients/$patient/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE response'},
        }),
        404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    Object body;
    if (options.path == '/patients') {
      body = empty ? [] : patients;
    } else if (options.path.endsWith('/devices')) {
      body = [
        {
          'id': 'device-$p',
          'patient_id': p,
          'serial_number': p == patient ? 'RMR-0008' : 'RMR-0009',
          'online': true,
          'battery_level_pct': 76,
          'last_seen_at': now
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
        },
      ];
    } else if (options.path.endsWith('/journal')) {
      body = {
        'date': '2026-10-14',
        'timezone': p == patient ? 'Africa/Cairo' : 'Asia/Riyadh',
        'entries': [
          for (final id in ['known-1', 'known-1', 'known-2', 'known-3'])
            {
              'event_type': 'encounter',
              'person': {'id': id},
            },
          {'event_type': 'encounter', 'person': null},
          {
            'event_type': 'voice_query',
            'person': {'id': 'excluded'},
          },
        ],
      };
    } else if (options.path.endsWith('/reminder-logs')) {
      body = [
        for (var i = 0; i < 3; i++)
          {
            'id': 'log-$i',
            'status': malformed
                ? 'invented'
                : ['completed', 'snoozed', 'pending'][i],
          },
      ];
    } else if (options.path == '/caregivers/me/alerts') {
      body = paginate && options.queryParameters['offset'] == 0
          ? [for (var i = 0; i < 50; i++) alert(i, otherPatient)]
          : [
              for (var i = 0; i < 3; i++) alert(i, patient),
              alert(3, otherPatient),
            ];
    } else {
      body = {'id': 'caregiver-A', 'role': 'caregiver'};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  HomeAdapter adapter,
  RemoriDatabase db, {
  String language = 'en',
  double scale = 1,
  Size size = const Size(390, 844),
  handover.ControlledGlasses? glasses,
  String Function()? identity,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 47);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer(
    overrides: [
      routeAccessProvider.overrideWithValue(
        const RouteAccess(caregiverAuthenticated: true),
      ),
      caregiverIdentityProvider.overrideWith(
        (ref) async => identity?.call() ?? 'caregiver-A',
      ),
      databaseProvider.overrideWithValue(db),
      appLocaleProvider.overrideWithValue(Locale(language)),
      homeClockProvider.overrideWith((ref) => Stream.value(now)),
      permissionServiceProvider.overrideWithValue(
        permissions.FakePermissions(
          platform: glasses == null
              ? PermissionPlatform.ios
              : PermissionPlatform.android,
        ),
      ),
      if (glasses != null)
        glassesConnectionProvider.overrideWith((ref) {
          ref.onDispose(glasses.dispose);
          return glasses;
        }),
      apiClientProvider.overrideWith((ref) {
        final client = ApiClient(
          config: ApiConfig('https://example.test/api/v1'),
          credentials: handover.TestCredentials(),
          adapter: adapter,
          onCredentialsInvalidated: (_) {},
        );
        ref.onDispose(client.close);
        return client;
      }),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(key: Key('c1-preview'), child: RemoriApp()),
    ),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.c1.name);
  await tester.pumpAndSettle();
  return container;
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
  late RemoriDatabase db;
  late HomeAdapter adapter;
  late ApiClient client;
  setUp(() {
    db = RemoriDatabase(NativeDatabase.memory(logStatements: false));
    adapter = HomeAdapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: handover.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
  });
  tearDown(() async {
    client.close();
    await db.close();
  });

  test('refresh caches distinct known people and aligned reminder date without private journal content', () async {
    final repo = HomeRepository(client, db, 'caregiver-A');
    await repo.refresh(null);
    final data = await repo.read();
    expect(data.days.single.peopleMet, 3);
    expect(data.days.single.done, 1);
    expect(data.days.single.total, 3);
    expect(data.days.single.snoozed, 1);
    expect(adapter.requests.first.path, '/patients');
    expect(
      adapter.requests
          .singleWhere((r) => r.path.endsWith('/reminder-logs'))
          .queryParameters,
      {'date': '2026-10-14'},
    );
    expect(
      adapter.requests.every(
        (r) => r.headers['Authorization'] == 'Bearer test-caregiver',
      ),
      isTrue,
    );
    expect(data.patients.first.permission, 'manager');
    expect(data.alerts.where((a) => a.patientId == patient).length, 3);
  });
  test(
    'cache stays isolated by caregiver and rolls back malformed refresh',
    () async {
      final repo = HomeRepository(client, db, 'caregiver-A');
      await repo.refresh(null);
      expect(
        (await HomeRepository(client, db, 'caregiver-B').read()).patients,
        isEmpty,
      );
      adapter.malformed = true;
      await expectLater(repo.refresh(null), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).days.single.total, 3);
      adapter.fail = true;
      await expectLater(repo.refresh(null), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).patients.length, 2);
    },
  );
  test(
    'selected patient alert preview follows caregiver-wide pagination',
    () async {
      adapter.paginate = true;
      final repo = HomeRepository(client, db, 'caregiver-A');
      await repo.refresh(patient);
      expect(
        adapter.requests
            .where((r) => r.path == '/caregivers/me/alerts')
            .map((r) => r.queryParameters['offset']),
        [0, 50],
      );
      expect(
        (await repo.read()).alerts.where((a) => a.patientId == patient).length,
        3,
      );
    },
  );
  test('known revoked access removes that patient cache without touching another caregiver', () async {
    final repo = HomeRepository(client, db, 'caregiver-A');
    await repo.refresh(null);
    await HomeRepository(client, db, 'caregiver-B').refresh(null);
    adapter.denied = true;
    await expectLater(repo.refresh(patient), throwsA(isA<ApiFailure>()));
    final data = await repo.read();
    expect(data.patients.any((p) => p.id == patient), isFalse);
    expect(data.devices, isEmpty);
    expect(data.days, isEmpty);
    expect(data.alerts.any((a) => a.patientId == patient), isFalse);
    expect(
      (await HomeRepository(client, db, 'caregiver-B').read()).patients.length,
      2,
    );
  });
  test('v1 migration retains existing reminder logs and outbox entries', () async {
    await db.close();
    db = RemoriDatabase(
      NativeDatabase.memory(
        setup: (sqlite) {
          sqlite.execute(
            'CREATE TABLE reminder_logs (id TEXT NOT NULL PRIMARY KEY, patient_id TEXT NOT NULL, reminder_id TEXT NOT NULL, scheduled_at INTEGER NOT NULL, status TEXT NOT NULL, snoozed_until INTEGER, completed_at INTEGER, confirmed_via TEXT, updated_at INTEGER NOT NULL)',
          );
          sqlite.execute(
            'CREATE TABLE outbox_entries (sequence INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE, patient_id TEXT NOT NULL, kind TEXT NOT NULL, record_id TEXT NOT NULL, payload TEXT NOT NULL)',
          );
          sqlite.execute(
            "INSERT INTO reminder_logs VALUES ('old-log', '$patient', 'old-reminder', 0, 'pending', NULL, NULL, NULL, 0)",
          );
          sqlite.execute(
            "INSERT INTO outbox_entries (id,patient_id,kind,record_id,payload) VALUES ('old-write', '$patient', 'reminderLog', 'old-log', '{}')",
          );
          sqlite.execute('PRAGMA user_version = 1');
        },
      ),
    );
    final old = db;
    expect((await old.watchReminderLogs(patient).first).single.id, 'old-log');
    expect((await old.pendingWrites(patient)).single.id, 'old-write');
    final tables = await old
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    expect(
      tables.map((r) => r.read<String>('name')),
      containsAll([
        'dashboard_patients',
        'dashboard_devices',
        'dashboard_alerts',
        'dashboard_days',
      ]),
    );
  });
  test('removed links clear that caregiver cached data, without deleting another account', () async {
    final repo = HomeRepository(client, db, 'caregiver-A');
    await repo.refresh(null);
    await HomeRepository(client, db, 'caregiver-B').refresh(null);
    adapter.empty = true;
    await repo.refresh(null);
    final empty = await repo.read();
    expect(empty.patients, isEmpty);
    expect(empty.devices, isEmpty);
    expect(empty.days, isEmpty);
    expect(
      (await HomeRepository(client, db, 'caregiver-B').read()).patients.length,
      2,
    );
  });
  testWidgets('Home shows live cached values and existing destination links', (
    tester,
  ) async {
    final container = await mount(tester, adapter, db);
    expect(find.text('فاطمة محمود'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Memory: Enabled'), findsOneWidget);
    expect(
      find.text('Daily summaries will be available in Phase 2.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Home'), findsOneWidget);
    await tester.tap(find.text('Open journal ›'));
    await tester.pumpAndSettle();
    expect(find.byType(C12JournalScreen), findsOneWidget);
    expect(container.read(remoriRouterProvider).canPop(), isTrue);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(C1HomeScreen), findsOneWidget);
  });
  testWidgets(
    'patient switching isolates card data and hides viewer write action',
    (tester) async {
      final container = await mount(tester, adapter, db);
      await tester.tap(find.text('Switch patient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second patient').last);
      await tester.pumpAndSettle();
      expect(container.read(selectedHomePatientProvider)!.id, otherPatient);
      expect(find.byTooltip('Add reminder'), findsNothing);
      expect(find.text('Memory: Off'), findsOneWidget);
      expect(
        adapter.requests.any(
          (r) => r.path == '/patients/$otherPatient/journal',
        ),
        isTrue,
      );
    },
  );
  testWidgets(
    'offline refresh retains saved statistics with cached-day notice and hides raw error',
    (tester) async {
      final container = await mount(tester, adapter, db);
      adapter.fail = true;
      await tester.runAsync(
        () => container.read(homeRefreshProvider.notifier).refresh(),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Showing saved data. Unable to update Home.'),
        findsOneWidget,
      );
      expect(find.text('Saved statistics for 2026-10-14'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets('empty and first-load error do not fabricate dashboard numbers', (
    tester,
  ) async {
    adapter.empty = true;
    final container = await mount(tester, adapter, db);
    expect(
      find.text('No patients are linked to your account yet.'),
      findsOneWidget,
    );
    expect(find.text('1 / 3'), findsNothing);
    adapter.fail = true;
    await tester.runAsync(
      () => container.read(homeRefreshProvider.notifier).refresh(),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to load Home. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
  testWidgets(
    'selected glasses telemetry updates memory/battery and disconnect overrides old heartbeat',
    (tester) async {
      final glasses = handover.ControlledGlasses();
      await mount(tester, adapter, db, glasses: glasses);
      expect(glasses.connectedSerial, 'RMR-0008');
      expect((glasses.sent.single as TimeSync).timezone, 'Africa/Cairo');
      glasses.incoming.add(
        const Telemetry(
          batteryPct: 60,
          tempC: 61,
          memoryPaused: false,
          storageFreeMb: 2100,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Last seen just now · Battery 60%'), findsOneWidget);
      expect(find.text('Memory: Capturing'), findsOneWidget);
      await glasses.disconnect();
      await tester.pumpAndSettle();
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Memory: Capturing'), findsNothing);
    },
  );
  testWidgets(
    'changing authenticated caregiver identity hides the previous cache',
    (tester) async {
      var identity = 'caregiver-A';
      final container = await mount(
        tester,
        adapter,
        db,
        identity: () => identity,
      );
      expect(find.text('فاطمة محمود'), findsOneWidget);
      identity = 'caregiver-B';
      container.invalidate(caregiverIdentityProvider);
      await tester.pumpAndSettle();
      expect(find.text('فاطمة محمود'), findsNothing);
      expect(find.text('1 / 3'), findsNothing);
      expect(find.byTooltip('Add reminder'), findsNothing);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C1 $language supports large text on a narrow screen', (
      tester,
    ) async {
      await mount(
        tester,
        adapter,
        db,
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('C1 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, adapter, db, language: language);
      final countText = tester.widget<Text>(find.text('1 / 3'));
      expect(countText.textDirection, TextDirection.ltr);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c1-preview')),
          matchesGoldenFile('goldens/c1_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
  }
}
