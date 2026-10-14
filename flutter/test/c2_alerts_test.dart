import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:remori/features/caregiver_dashboard/presentation/alerts_providers.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as c1;
import 'c8_reminders_test.dart' as c8;

const owner = 'caregiver-A';
final now = DateTime.utc(2026, 10, 15, 9);
const types = [
  'unknown_person_flagged',
  'low_battery',
  'missed_medication',
  'device_offline',
  'daily_summary_ready',
];
const entities = [
  'unknown_face_cluster',
  'device',
  'reminder_log',
  'device',
  'daily_summary',
];
HomeData fixture({bool viewer = false}) => HomeData(
  patients: [
    HomePatient(
      id: c1.patient,
      name: 'فاطمة محمود',
      language: 'ar',
      timezone: 'Africa/Cairo',
      memoryEnabled: true,
      permission: viewer ? 'viewer' : 'manager',
    ),
  ],
  alerts: [
    for (var i = 0; i < 5; i++)
      HomeAlert(
        id: 'alert-$i',
        patientId: c1.patient,
        type: types[i],
        message: 'PRIVATE ENGLISH FALLBACK',
        createdAt: i < 2
            ? now.subtract(Duration(hours: i))
            : now.subtract(Duration(days: 1, hours: i)),
        readAt: i < 2 ? null : now,
        entityType: entities[i],
        entityId: 'entity-$i',
      ),
  ],
);

DashboardAlertsCompanion row(HomeAlert alert) =>
    DashboardAlertsCompanion.insert(
      caregiverId: owner,
      id: alert.id,
      patientId: alert.patientId,
      alertType: alert.type,
      message: alert.message,
      createdAt: alert.createdAt,
    );

class AlertsAdapter extends c1.HomeAdapter {
  int count = 61;
  int posts = 0;
  bool wrongPatient = false, wrongId = false, missing = false, failPage = false;
  Completer<void>? alertGate;
  Completer<void>? alertStarted;
  final read = <String>{};
  Map<String, Object?> alertBody(int index) => {
    'id': 'alert-$index',
    'patient_id': c1.patient,
    'alert_type': types[index % 5],
    'message': 'PRIVATE ENGLISH FALLBACK',
    'entity_type': entities[index % 5],
    'entity_id': 'entity-$index',
    'created_at': now.subtract(Duration(minutes: index)).toIso8601String(),
    'read_at': read.contains('alert-$index') ? now.toIso8601String() : null,
  };
  ResponseBody json(Object body, [int status = 200]) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/caregivers/me/alerts') {
      requests.add(options);
      final offset = options.queryParameters['offset'] as int;
      if (failPage && offset > 0) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      final result = [
        for (var i = offset; i < count && i < offset + 50; i++) alertBody(i),
      ];
      if (alertStarted != null && !alertStarted!.isCompleted) {
        alertStarted!.complete();
      }
      if (alertGate != null) await alertGate!.future;
      return json(result);
    }
    if (options.path.startsWith('/alerts/')) {
      requests.add(options);
      posts++;
      if (missing) {
        return json({
          'error': {'code': 'ALERT_NOT_FOUND', 'message': 'PRIVATE'},
        }, 404);
      }
      final id = options.path.split('/')[2];
      read.add(id);
      return json({
        ...alertBody(int.parse(id.split('-').last)),
        if (wrongId) 'id': 'other-alert',
        if (wrongPatient) 'patient_id': c1.otherPatient,
      });
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

class FakeAlerts extends HomeRepository {
  FakeAlerts(super.client, super.db, super.caregiverId);
  HomeData data = fixture();
  final updates = StreamController<void>.broadcast();
  int posts = 0, cacheWrites = 0, refreshes = 0;
  bool failCache = false, failRefresh = false, failRead = false;
  Completer<void>? gate;
  @override
  Stream<HomeData> watch() async* {
    yield data;
    await for (final _ in updates.stream) {
      yield data;
    }
  }

  @override
  Future<HomeData> read() async => data;
  @override
  Future<void> refresh(String? selectedId) async {}
  @override
  Future<void> refreshAlerts() async {
    refreshes++;
    if (failRefresh) throw ApiFailure(ApiFailureKind.network);
  }

  @override
  Future<DashboardAlertsCompanion> markAlertRead(String id) async {
    posts++;
    if (gate != null) await gate!.future;
    if (failRead) throw ApiFailure(ApiFailureKind.network, message: 'PRIVATE');
    final alert = data.alerts.firstWhere((a) => a.id == id);
    return row(alert).copyWith(readAt: Value(now));
  }

  @override
  Future<void> cacheAlertRead(DashboardAlertsCompanion receipt) async {
    cacheWrites++;
    if (failCache) throw StateError('PRIVATE');
    data = HomeData(
      patients: data.patients,
      alerts: [
        for (final alert in data.alerts)
          HomeAlert(
            id: alert.id,
            patientId: alert.patientId,
            type: alert.type,
            message: alert.message,
            createdAt: alert.createdAt,
            readAt: alert.id == receipt.id.value ? now : alert.readAt,
            entityType: alert.entityType,
            entityId: alert.entityId,
          ),
      ],
    );
    updates.add(null);
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late AlertsAdapter adapter;
  late HomeRepository repo;
  setUpAll(() async {
    for (final entry in {
      'DM Sans': 'assets/fonts/DM-Sans.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Readex Pro': 'assets/fonts/Readex-Pro.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  setUp(() {
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = AlertsAdapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = HomeRepository(client, db, owner);
  });
  tearDown(() async {
    client.close();
    await db.close();
  });

  test('full alert refresh paginates, caches read metadata and remains caregiver scoped', () async {
    await repo.refresh(null);
    expect((await repo.read()).alerts.length, 50);
    await repo.refreshAlerts();
    expect((await repo.read()).alerts.length, 61);
    final queries = adapter.requests
        .where(
          (r) =>
              r.path == '/caregivers/me/alerts' &&
              r.queryParameters['unread_only'] == false,
        )
        .toList();
    expect(queries.map((r) => r.queryParameters['offset']), [0, 50]);
    expect((await repo.read()).alerts.first.entityType, 'unknown_face_cluster');
    expect((await HomeRepository(client, db, 'other').read()).alerts, isEmpty);
  });
  test(
    'a failed later page leaves the full previous cache untouched',
    () async {
      await repo.refresh(null);
      await repo.refreshAlerts();
      adapter.failPage = true;
      await expectLater(repo.refreshAlerts(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).alerts.length, 61);
    },
  );
  test(
    'an authoritative empty alert response clears the cached list',
    () async {
      await repo.refresh(null);
      adapter.count = 0;
      await repo.refreshAlerts();
      expect((await repo.read()).alerts, isEmpty);
    },
  );
  test('read marking uses the own-alert endpoint and only caches the acknowledged receipt', () async {
    await repo.refresh(null);
    final receipt = await repo.markAlertRead('alert-0');
    expect((await repo.read()).alerts.first.readAt, null);
    expect(adapter.requests.last.method, 'POST');
    expect(adapter.requests.last.path, '/alerts/alert-0/read');
    await repo.cacheAlertRead(receipt);
    expect((await repo.read()).alerts.first.readAt, now);
  });
  test(
    'Home preview retains C2 history and never clears a confirmed read marker',
    () async {
      await repo.refresh(null);
      await repo.refreshAlerts();
      await repo.cacheAlertRead(await repo.markAlertRead('alert-0'));
      adapter.read.clear();
      await repo.refresh(null);
      final data = await repo.read();
      expect(data.alerts.length, 61);
      expect(data.alerts.first.readAt, now);
    },
  );
  test('a stale full refresh cannot overwrite a confirmed read', () async {
    await repo.refresh(null);
    adapter.alertGate = Completer<void>();
    final pending = repo.refreshAlerts();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.cacheAlertRead(await repo.markAlertRead('alert-0'));
    adapter.alertGate!.complete();
    await pending;
    expect((await repo.read()).alerts.first.readAt, now);
  });
  test('wrong alert or patient responses are rejected', () async {
    await repo.refresh(null);
    adapter.wrongId = true;
    await expectLater(
      repo.markAlertRead('alert-0'),
      throwsA(isA<ApiFailure>()),
    );
    adapter
      ..wrongId = false
      ..wrongPatient = true;
    await expectLater(
      repo.markAlertRead('alert-0'),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read()).alerts.first.readAt, null);
  });
  test(
    'an older Home preview cannot restore an alert reported missing',
    () async {
      await repo.refresh(null);
      adapter.alertGate = Completer<void>();
      adapter.alertStarted = Completer<void>();
      final pending = repo.refresh(null);
      await adapter.alertStarted!.future.timeout(const Duration(seconds: 3));
      adapter.missing = true;
      await expectLater(
        repo.markAlertRead('alert-0'),
        throwsA(isA<ApiFailure>()),
      );
      adapter.alertGate!.complete();
      await pending;
      expect((await repo.read()).alerts.any((a) => a.id == 'alert-0'), false);
    },
  );
  test(
    'missing alert is removed locally without purging other alerts',
    () async {
      await repo.refresh(null);
      adapter.missing = true;
      await expectLater(
        repo.markAlertRead('alert-0'),
        throwsA(isA<ApiFailure>()),
      );
      expect((await repo.read()).alerts.length, 49);
    },
  );
  test(
    'a revoked link prevents a late read receipt recreating its alert',
    () async {
      await repo.refresh(null);
      final receipt = await repo.markAlertRead('alert-0');
      await (db.delete(
        db.dashboardPatients,
      )..where((p) => p.caregiverId.equals(owner))).go();
      await (db.delete(
        db.dashboardAlerts,
      )..where((a) => a.caregiverId.equals(owner))).go();
      await repo.cacheAlertRead(receipt);
      expect((await repo.read()).alerts, isEmpty);
    },
  );

  FakeAlerts fake() => FakeAlerts(client, db, owner);
  ProviderContainer controller(FakeAlerts fake, {String Function()? account}) =>
      ProviderContainer(
        overrides: [
          alertsOwnerProvider.overrideWith((ref) => account?.call() ?? owner),
          homeRepositoryProvider(owner).overrideWithValue(fake),
          homeRefreshProvider.overrideWith(c8.QuietHome.new),
        ],
      );
  test('cache retry never sends the confirmed POST again', () async {
    final repository = fake()..failCache = true;
    final container = controller(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(alertsControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(alertsControllerProvider.notifier);
    expect(await notifier.open(repository.data.alerts.first), false);
    expect(container.read(alertsControllerProvider).pending, true);
    repository.failCache = false;
    await notifier.refresh();
    expect(repository.posts, 1);
    expect(repository.cacheWrites, 2);
    expect(container.read(alertsControllerProvider).pending, false);
  });
  test(
    'duplicate taps and account changes cannot apply a late read response',
    () async {
      final repository = fake()..gate = Completer<void>();
      var account = owner;
      final container = controller(repository, account: () => account);
      addTearDown(container.dispose);
      final subscription = container.listen(
        alertsControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(alertsControllerProvider.notifier);
      final pending = notifier.open(repository.data.alerts.first);
      expect(await notifier.open(repository.data.alerts.first), false);
      expect(repository.posts, 1);
      account = 'other';
      container.invalidate(alertsOwnerProvider);
      repository.gate!.complete();
      expect(await pending, false);
      expect(repository.cacheWrites, 0);
    },
  );
  test('already-read cached alerts can open offline without POST', () async {
    final repository = fake()..failRefresh = true;
    final container = controller(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(alertsControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(
      await container
          .read(alertsControllerProvider.notifier)
          .open(repository.data.alerts[2]),
      true,
    );
    expect(repository.posts, 0);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeAlerts fake, {
    String language = 'en',
    double scale = 1,
    Size size = const Size(390, 844),
    String Function()? account,
    Stream<DateTime>? ticks,
  }) async {
    tester.view.physicalSize = size;
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
        caregiverIdentityProvider.overrideWith(
          (ref) async => account?.call() ?? owner,
        ),
        homeDataProvider.overrideWith(
          (ref) => ref.watch(alertsOwnerProvider) == owner
              ? fake.watch()
              : Stream.value(const HomeData()),
        ),
        homeRepositoryProvider(owner).overrideWithValue(fake),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        alertsClockProvider.overrideWithValue(() => now),
        alertsNowProvider.overrideWith((ref) => ticks ?? Stream.value(now)),
        appLocaleProvider.overrideWithValue(Locale(language)),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c8: (_, _) => const Text('Reminder destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c2-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c2.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'all alert types render localized descriptions, unread count and grouped patient times',
    (tester) async {
      await mount(tester, fake());
      expect(find.text('2 unread'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Someone new'), findsOneWidget);
      expect(find.text('Low battery'), findsOneWidget);
      expect(find.text('Missed medication'), findsOneWidget);
      expect(find.text('Device offline'), findsOneWidget);
      expect(find.text('Daily summary ready'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.textContaining('فاطمة محمود'), findsNWidgets(5));
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets(
    'viewer can mark read while unfinished targets keep the alerts screen visible',
    (tester) async {
      final repository = fake()..data = fixture(viewer: true);
      await mount(tester, repository);
      await tester.tap(find.byKey(const ValueKey('alert-alert-0')));
      await tester.pumpAndSettle();
      expect(repository.posts, 1);
      expect(find.text('1 unread'), findsOneWidget);
      expect(
        find.text(
          'Alert read. This destination will be available when its screen is ready.',
        ),
        findsOneWidget,
      );
      expect(find.text('Alerts'), findsOneWidget);
    },
  );
  testWidgets('medication alert opens C8 with the alert patient selected', (
    tester,
  ) async {
    final repository = fake();
    final container = await mount(tester, repository);
    await tester.tap(find.byKey(const ValueKey('alert-alert-2')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder destination'), findsOneWidget);
    expect(container.read(selectedHomePatientIdProvider), c1.patient);
    expect(repository.posts, 0);
  });
  testWidgets(
    'offline refresh retains cards and failed marking leaves the unread count intact',
    (tester) async {
      final repository = fake()
        ..failRefresh = true
        ..failRead = true;
      await mount(tester, repository);
      expect(
        find.text('Showing saved alerts. Retry to check the latest state.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('alert-alert-0')));
      await tester.pumpAndSettle();
      expect(find.text('2 unread'), findsOneWidget);
      expect(
        find.text('Unable to mark the alert as read. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets('cache-only Retry clears pending state without repeating POST', (
    tester,
  ) async {
    final repository = fake()..failCache = true;
    await mount(tester, repository);
    await tester.tap(find.byKey(const ValueKey('alert-alert-0')));
    await tester.pumpAndSettle();
    expect(
      find.text('Alert marked as read. Retry to finish updating this phone.'),
      findsOneWidget,
    );
    repository.failCache = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.posts, 1);
    expect(find.text('1 unread'), findsOneWidget);
  });
  testWidgets('account switch hides names and previous alert cards', (
    tester,
  ) async {
    var account = owner;
    final container = await mount(tester, fake(), account: () => account);
    account = 'other';
    container.invalidate(caregiverIdentityProvider);
    await tester.pumpAndSettle();
    expect(find.textContaining('فاطمة'), findsNothing);
    expect(find.byKey(const ValueKey('alert-alert-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('patient midnight regroups alerts even when offline', (
    tester,
  ) async {
    final ticks = StreamController<DateTime>.broadcast();
    addTearDown(ticks.close);
    await mount(tester, fake()..failRefresh = true, ticks: ticks.stream);
    ticks.add(DateTime.utc(2026, 10, 15, 22));
    await tester.pumpAndSettle();
    expect(find.text('TODAY'), findsNothing);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('Oct 14, 2026'), findsOneWidget);
  });
  testWidgets('empty alerts show a real empty state', (tester) async {
    final repository = fake()..data = HomeData(patients: fixture().patients);
    await mount(tester, repository);
    expect(find.text('No alerts yet.'), findsOneWidget);
    expect(find.text('0 unread'), findsOneWidget);
  });
  testWidgets(
    'Today appears before Yesterday across patients in different timezones',
    (tester) async {
      final repository = fake();
      repository.data = HomeData(
        patients: [
          fixture().patients.single,
          const HomePatient(
            id: c1.otherPatient,
            name: 'Second patient',
            language: 'en',
            timezone: 'America/New_York',
            memoryEnabled: true,
            permission: 'viewer',
          ),
        ],
        alerts: [
          HomeAlert(
            id: 'recent',
            patientId: c1.patient,
            type: 'low_battery',
            message: 'PRIVATE',
            createdAt: DateTime.utc(2026, 10, 15, 20),
          ),
          HomeAlert(
            id: 'earlier',
            patientId: c1.otherPatient,
            type: 'low_battery',
            message: 'PRIVATE',
            createdAt: DateTime.utc(2026, 10, 15, 19),
          ),
        ],
      );
      await mount(
        tester,
        repository,
        ticks: Stream.value(DateTime.utc(2026, 10, 15, 22)),
      );
      expect(
        tester.getTopLeft(find.text('TODAY')).dy,
        lessThan(tester.getTopLeft(find.text('YESTERDAY')).dy),
      );
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C2 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, fake(), language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c2-preview')),
          matchesGoldenFile('goldens/c2_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
    testWidgets('C2 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        fake(),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('alert-alert-4')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
