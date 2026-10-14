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
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/reminders/data/reminders_repository.dart';
import 'package:remori/features/reminders/domain/reminder_data.dart';
import 'package:remori/features/reminders/presentation/reminders_providers.dart';

import 'a6_handover_test.dart' as auth;

const scope = ReminderScope('caregiver-A', 'patient-A', 'Africa/Cairo');
const day = '2026-10-01';
final at = DateTime.utc(2026, 10, 1);
const titles = ['Blood pressure pill', 'Doctor appointment', 'Drink water'];
const rules = [
  'FREQ=DAILY;BYHOUR=9;BYMINUTE=0',
  'FREQ=WEEKLY;BYDAY=FR;BYHOUR=17;BYMINUTE=0',
  'FREQ=DAILY;BYHOUR=12,16;BYMINUTE=0',
];
CaregiverReminder definition(
  int i, {
  bool active = true,
  String? rule,
  String timezone = 'Africa/Cairo',
}) => CaregiverReminder(
  id: 'reminder-$i',
  title: titles[i],
  kind: ReminderKind.values[i],
  rrule: rule ?? rules[i],
  dtstart: at.add(Duration(hours: [6, 14, 9][i])),
  timezone: timezone,
  active: active,
);
ReminderListData fixture({bool active = true, bool empty = false}) =>
    ReminderListData(
      refreshedAt: at,
      todayAvailable: true,
      reminders: empty
          ? []
          : [
              for (var i = 0; i < 3; i++)
                definition(i, active: i == 0 ? active : true),
            ],
      occurrences: empty
          ? []
          : [
              ReminderOccurrence(
                id: 'log-0',
                reminderId: 'reminder-0',
                title: titles[0],
                kind: ReminderKind.medication,
                scheduledAt: at.add(const Duration(hours: 6)),
                status: 'completed',
                confirmedVia: 'voice',
              ),
              ReminderOccurrence(
                id: 'log-1',
                reminderId: 'reminder-2',
                title: titles[2],
                kind: ReminderKind.task,
                scheduledAt: at.add(const Duration(hours: 9)),
                status: 'snoozed',
                snoozedUntil: at.add(const Duration(hours: 9, minutes: 15)),
              ),
              ReminderOccurrence(
                id: 'log-2',
                reminderId: 'reminder-2',
                title: titles[2],
                kind: ReminderKind.task,
                scheduledAt: at.add(const Duration(hours: 13)),
                status: 'pending',
              ),
            ],
    );

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool active = true,
      failLogs = false,
      malformed = false,
      denied = false,
      missing = false;
  DateTime updated = at;
  String? delayedDay;
  Completer<void>? gate;
  Map<String, Object?> body(int i) => {
    'id': 'reminder-$i',
    'patient_id': malformed ? 'other-patient' : scope.patientId,
    'title': titles[i],
    'type': ReminderKind.values[i].name,
    'rrule': rules[i],
    'dtstart': at.add(Duration(hours: [6, 14, 9][i])).toIso8601String(),
    'timezone': scope.timezone,
    'active': i == 0 ? active : true,
    'spoken_text': null,
    'deleted_at': null,
    'updated_at': updated.toIso8601String(),
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (denied) {
      return json(404, {
        'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE'},
      });
    }
    if (options.method == 'PATCH') {
      if (missing) {
        return json(404, {
          'error': {'code': 'REMINDER_NOT_FOUND', 'message': 'PRIVATE'},
        });
      }
      active = (options.data as Map)['active'];
      updated = at.add(const Duration(minutes: 1));
      return json(200, body(0));
    }
    if (options.path.endsWith('/reminders')) {
      return json(200, [for (var i = 0; i < 3; i++) body(i)]);
    }
    if (failLogs) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final date = options.queryParameters['date'] as String;
    if (date == delayedDay) await gate!.future;
    final shift = DateTime.parse(date).difference(DateTime.parse(day));
    return json(200, [
      for (final log in fixture().occurrences)
        {
          'id': '${log.id}-$date',
          'reminder_id': log.reminderId,
          'title': log.title,
          'type': log.kind.name,
          'scheduled_at': log.scheduledAt.add(shift).toIso8601String(),
          'status': log.status,
          'snoozed_until': log.snoozedUntil?.add(shift).toIso8601String(),
          'completed_at': null,
          'confirmed_via': log.confirmedVia,
          'updated_at': updated.toIso8601String(),
        },
    ]);
  }

  ResponseBody json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

class FakeRepository extends RemindersRepository {
  FakeRepository(super.client, super.db, super.scope);
  ReminderListData data = fixture();
  final updates = StreamController<void>.broadcast();
  final days = <String>[];
  String fetchedDay = day;
  int toggles = 0, cacheWrites = 0;
  bool failRefresh = false, failCache = false;
  Completer<void>? gate;
  ReminderListData snapshot(String date) => ReminderListData(
    reminders: data.reminders,
    occurrences: date == day ? data.occurrences : [],
    refreshedAt: data.refreshedAt,
    todayAvailable: date == fetchedDay,
  );
  @override
  Stream<ReminderListData> watch(String date) async* {
    yield snapshot(date);
    await for (final _ in updates.stream) {
      yield snapshot(date);
    }
  }

  @override
  Future<ReminderListData> read(String date) async => snapshot(date);
  @override
  Future<void> refresh(String date) async {
    days.add(date);
    if (failRefresh) throw ApiFailure(ApiFailureKind.network);
    fetchedDay = date;
    updates.add(null);
  }

  @override
  Future<CachedRemindersCompanion> toggle(String id, bool active) async {
    toggles++;
    if (gate != null) await gate!.future;
    return CachedRemindersCompanion.insert(
      caregiverId: scope.caregiverId,
      patientId: scope.patientId,
      id: id,
      title: titles[0],
      type: 'medication',
      rrule: rules[0],
      dtstart: at,
      timezone: scope.timezone,
      active: active,
      updatedAt: at,
      position: 0,
    );
  }

  @override
  Future<void> cacheToggle(CachedRemindersCompanion row) async {
    cacheWrites++;
    if (failCache) throw StateError('PRIVATE CACHE ERROR');
    data = fixture(active: row.active.value);
    updates.add(null);
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

class QuietHome extends HomeRefresh {
  @override
  HomeRefreshState build() => const HomeRefreshState();
  @override
  Future<void> refresh() async {}
}

class RouteTarget extends StatelessWidget {
  const RouteTarget(this.extra, {super.key});
  final Object? extra;
  @override
  Widget build(BuildContext context) => const Text('C9 destination');
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late RemindersRepository repo;
  Directory? migrationDirectory;
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
    adapter = Adapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = RemindersRepository(client, db, scope);
  });
  tearDown(() async {
    client.close();
    await db.close();
    if (migrationDirectory != null) {
      final directory = migrationDirectory!;
      if (directory.absolute.parent.path !=
              Directory.systemTemp.absolute.path ||
          !directory.path.contains('remori-c8-migration-')) {
        throw StateError('Unexpected temporary path');
      }
      await directory.delete(recursive: true);
      migrationDirectory = null;
    }
  });
  test('patient day is independent of phone timezone and IANA conversion handles DST', () {
    expect(
      PatientTime.day(DateTime.utc(2026, 10, 1, 22), 'Africa/Cairo'),
      '2026-10-02',
    );
    expect(
      PatientTime.day(DateTime.utc(2026, 10, 1, 2), 'America/New_York'),
      '2026-09-30',
    );
    expect(
      PatientTime.local(DateTime.utc(2026, 1, 15, 9), 'America/New_York').hour,
      4,
    );
    expect(
      PatientTime.local(DateTime.utc(2026, 7, 15, 9), 'America/New_York').hour,
      5,
    );
  });
  test('daily/weekly summaries support multiple times and complex rules have no guessed schedule', () {
    expect(
      SimpleReminderSchedule.parse(definition(0), scope.timezone)!.minutes,
      [540],
    );
    expect(
      SimpleReminderSchedule.parse(definition(1), scope.timezone)!.weekdays,
      [5],
    );
    expect(
      SimpleReminderSchedule.parse(definition(2), scope.timezone)!.minutes,
      [720, 960],
    );
    for (final rule in [
      'FREQ=MONTHLY;BYDAY=1FR',
      'FREQ=DAILY;INTERVAL=2',
      'FREQ=DAILY;COUNT=3',
      'FREQ=DAILY;BYHOUR=99',
      'FREQ=WEEKLY;BYDAY=1MO',
    ]) {
      expect(
        SimpleReminderSchedule.parse(definition(0, rule: rule), scope.timezone),
        null,
      );
    }
    expect(
      SimpleReminderSchedule.parse(
        definition(0, timezone: 'America/New_York'),
        scope.timezone,
      ),
      null,
    );
  });
  test('refresh uses explicit patient day and atomically stores definitions and logs', () async {
    await repo.refresh(day);
    final data = await repo.read(day);
    expect(adapter.requests.length, 2);
    expect(
      adapter.requests
          .singleWhere((r) => r.path.endsWith('/reminder-logs'))
          .queryParameters,
      {'date': day},
    );
    expect(data.reminders.length, 3);
    expect(data.occurrences.length, 3);
    expect(data.todayAvailable, true);
    expect(data.occurrences.first.confirmedVia, 'voice');
    expect(await db.select(db.reminderLogs).get(), isEmpty);
    expect(await db.pendingWrites('patient-A'), isEmpty);
    final other = RemindersRepository(
      client,
      db,
      const ReminderScope('caregiver-B', 'patient-A', 'Africa/Cairo'),
    );
    expect((await other.read(day)).reminders, isEmpty);
  });
  test('partial offline and malformed responses preserve the complete saved snapshot', () async {
    await repo.refresh(day);
    adapter.failLogs = true;
    await expectLater(repo.refresh(day), throwsA(isA<ApiFailure>()));
    expect((await repo.read(day)).occurrences.length, 3);
    adapter.failLogs = false;
    adapter.malformed = true;
    await expectLater(repo.refresh(day), throwsA(isA<ApiFailure>()));
    expect((await repo.read(day)).reminders.length, 3);
  });
  test('yesterday cached logs are never displayed as today', () async {
    await repo.refresh(day);
    final tomorrow = await repo.read('2026-10-02');
    expect(tomorrow.reminders.length, 3);
    expect(tomorrow.occurrences, isEmpty);
    expect(tomorrow.todayAvailable, false);
    final changedTimezone = RemindersRepository(
      client,
      db,
      const ReminderScope('caregiver-A', 'patient-A', 'America/New_York'),
    );
    expect((await changedTimezone.read(day)).occurrences, isEmpty);
  });
  test('older day refresh cannot replace a newer day snapshot', () async {
    adapter.delayedDay = day;
    adapter.gate = Completer<void>();
    final old = repo.refresh(day);
    await Future<void>.delayed(Duration.zero);
    await repo.refresh('2026-10-02');
    adapter.gate!.complete();
    await old;
    expect((await repo.read('2026-10-02')).todayAvailable, true);
    expect((await repo.read(day)).todayAvailable, false);
  });
  test('toggle uses PATCH active only, preserves order and leaves patient outbox untouched', () async {
    await repo.refresh(day);
    final receipt = await repo.toggle('reminder-0', false);
    final request = adapter.requests.last;
    expect(request.path, '/patients/patient-A/reminders/reminder-0');
    expect(request.method, 'PATCH');
    expect(request.data, {'active': false});
    expect((await repo.read(day)).reminders.first.active, true);
    await repo.cacheToggle(receipt);
    expect((await repo.read(day)).reminders.first.active, false);
    expect(await db.pendingWrites('patient-A'), isEmpty);
  });
  test('a stale GET does not overwrite a newer confirmed toggle', () async {
    await repo.refresh(day);
    final receipt = await repo.toggle('reminder-0', false);
    await repo.cacheToggle(receipt);
    adapter.active = true;
    adapter.updated = at;
    await repo.refresh(day);
    expect((await repo.read(day)).reminders.first.active, false);
  });
  test('REMINDER_NOT_FOUND removes the missing row; revoked links purge only their scope', () async {
    await repo.refresh(day);
    adapter.missing = true;
    await expectLater(
      repo.toggle('reminder-0', false),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read(day)).reminders.length, 2);
    final other = RemindersRepository(
      client,
      db,
      const ReminderScope('caregiver-B', 'patient-A', 'Africa/Cairo'),
    );
    await other.refresh(day);
    adapter.denied = true;
    await expectLater(repo.refresh(day), throwsA(isA<ApiFailure>()));
    expect((await repo.read(day)).reminders, isEmpty);
    expect((await other.read(day)).reminders.length, 3);
  });
  test('schema v4 upgrade preserves existing reminders/outbox and adds empty C8 caches', () async {
    await db.close();
    migrationDirectory = await Directory.systemTemp.createTemp(
      'remori-c8-migration-',
    );
    final file = File(
      '${migrationDirectory!.path}${Platform.pathSeparator}cache.sqlite',
    );
    db = RemoriDatabase(NativeDatabase(file));
    const patient = '00000001-0000-4000-8000-000000000001';
    await db.saveReminderLog(
      patientId: patient,
      reminderId: '00000005-0000-4000-8000-000000000001',
      scheduledAt: at,
      at: at,
      status: ReminderStatus.pending,
    );
    await db.customStatement('DROP TABLE cached_reminders');
    await db.customStatement('DROP TABLE cached_reminder_occurrences');
    await db.customStatement('DROP TABLE reminder_cache_states');
    await db.customStatement('PRAGMA user_version = 4');
    await db.customStatement('DROP TABLE cached_unknown_face_samples');
    await db.customStatement('DROP TABLE cached_unknown_faces');
    await db.customStatement('DROP TABLE unknown_faces_cache_states');
    await db.close();
    db = RemoriDatabase(NativeDatabase(file));
    expect((await db.pendingWrites(patient)).length, 1);
    expect((await db.watchReminderLogs(patient).first).length, 1);
    expect(await db.select(db.cachedReminders).get(), isEmpty);
    expect(await db.select(db.cachedReminderOccurrences).get(), isEmpty);
    expect(await db.select(db.reminderCacheStates).get(), isEmpty);
  });

  ProviderContainer controller(
    FakeRepository fake, {
    bool manager = true,
    ReminderScope Function()? selected,
    String Function()? requestedDay,
  }) => ProviderContainer(
    overrides: [
      reminderScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
      reminderDayProvider.overrideWith((ref) => requestedDay?.call() ?? day),
      caregiverCanManageProvider.overrideWithValue(manager),
      remindersRepositoryProvider(scope).overrideWithValue(fake),
    ],
  );
  FakeRepository fakeRepo() => FakeRepository(client, db, scope);
  test('midnight during a successful toggle preserves its receipt for cache-only retry', () async {
    final fake = fakeRepo()..gate = Completer<void>();
    var selectedDay = day;
    final container = controller(fake, requestedDay: () => selectedDay);
    addTearDown(container.dispose);
    final listen = container.listen(remindersControllerProvider, (_, _) {});
    addTearDown(listen.close);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(remindersControllerProvider.notifier);
    final pending = notifier.toggle('reminder-0', false);
    selectedDay = '2026-10-02';
    container.invalidate(reminderDayProvider);
    await Future<void>.delayed(Duration.zero);
    fake.failCache = true;
    fake.gate!.complete();
    await pending;
    expect(container.read(remindersControllerProvider).pending, true);
    fake.failCache = false;
    await notifier.refresh();
    expect(fake.toggles, 1);
    expect(fake.days.last, '2026-10-02');
    expect(container.read(remindersControllerProvider).pending, false);
  });
  test(
    'known successful toggle retries only local cache after cache failure',
    () async {
      final fake = fakeRepo();
      final container = controller(fake);
      addTearDown(container.dispose);
      final listen = container.listen(remindersControllerProvider, (_, _) {});
      addTearDown(listen.close);
      await Future<void>.delayed(Duration.zero);
      fake.failCache = true;
      final notifier = container.read(remindersControllerProvider.notifier);
      await notifier.toggle('reminder-0', false);
      expect(container.read(remindersControllerProvider).pending, true);
      await notifier.toggle('reminder-0', false);
      expect(fake.toggles, 1);
      fake.failCache = false;
      await notifier.refresh();
      expect(fake.cacheWrites, 2);
      expect(fake.toggles, 1);
      expect(container.read(remindersControllerProvider).pending, false);
    },
  );
  test('duplicate taps and late account changes cannot update another account cache', () async {
    final fake = fakeRepo()..gate = Completer<void>();
    var selected = scope;
    final container = controller(fake, selected: () => selected);
    addTearDown(container.dispose);
    final listen = container.listen(remindersControllerProvider, (_, _) {});
    addTearDown(listen.close);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(remindersControllerProvider.notifier);
    final pending = notifier.toggle('reminder-0', false);
    await notifier.toggle('reminder-0', false);
    expect(fake.toggles, 1);
    selected = const ReminderScope('caregiver-B', 'patient-B', 'Africa/Cairo');
    container.invalidate(reminderScopeProvider);
    fake.gate!.complete();
    await pending;
    expect(fake.cacheWrites, 0);
  });
  test('viewer cannot send an active toggle', () async {
    final fake = fakeRepo();
    final container = controller(fake, manager: false);
    addTearDown(container.dispose);
    final listen = container.listen(remindersControllerProvider, (_, _) {});
    addTearDown(listen.close);
    await Future<void>.delayed(Duration.zero);
    await container
        .read(remindersControllerProvider.notifier)
        .toggle('reminder-0', false);
    expect(fake.toggles, 0);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeRepository fake, {
    bool viewer = false,
    String language = 'en',
    double scale = 1,
    Size size = const Size(390, 844),
    ReminderScope Function()? selected,
    Stream<DateTime>? clock,
    DateTime Function()? now,
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
        appLocaleProvider.overrideWithValue(Locale(language)),
        reminderScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
        reminderClockProvider.overrideWithValue(now ?? () => at),
        reminderNowProvider.overrideWith(
          (ref) => clock ?? Stream.value(ref.watch(reminderClockProvider)()),
        ),
        caregiverCanManageProvider.overrideWithValue(!viewer),
        homeRefreshProvider.overrideWith(QuietHome.new),
        remindersRepositoryProvider(scope).overrideWithValue(fake),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c9: (_, state) => RouteTarget(state.extra),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c8-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c8.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'today shows patient times and real statuses, with simple schedule descriptions',
    (tester) async {
      await mount(tester, fakeRepo());
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('Done · voice'), findsOneWidget);
      expect(find.text('Snoozed → 12:15'), findsOneWidget);
      expect(find.text('Every day at 09:00'), findsOneWidget);
      expect(find.text('Fridays at 17:00'), findsOneWidget);
      expect(find.text('Every day at 12:00 and 16:00'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    },
  );
  testWidgets('switch updates stored state without navigating to C9', (
    tester,
  ) async {
    final fake = fakeRepo();
    await mount(tester, fake);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(fake.toggles, 1);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, false);
    expect(find.text('C9 destination'), findsNothing);
  });
  testWidgets('viewer sees data but cannot edit, add or toggle', (
    tester,
  ) async {
    final fake = fakeRepo();
    await mount(tester, fake, viewer: true);
    expect(find.text('+ Add'), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch).first).onChanged, null);
    await tester.tap(find.text('Doctor appointment'));
    await tester.pumpAndSettle();
    expect(find.text('C9 destination'), findsNothing);
    expect(fake.toggles, 0);
    expect(find.byIcon(Icons.add), findsNothing);
  });
  testWidgets('Add and existing card carry patient/reminder context into C9', (
    tester,
  ) async {
    final container = await mount(tester, fakeRepo());
    await tester.tap(find.text('+ Add'));
    await tester.pumpAndSettle();
    expect(tester.widget<RouteTarget>(find.byType(RouteTarget)).extra, {
      'patient_id': scope.patientId,
    });
    container.read(remoriRouterProvider).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doctor appointment'));
    await tester.pumpAndSettle();
    expect(tester.widget<RouteTarget>(find.byType(RouteTarget)).extra, {
      'patient_id': scope.patientId,
      'reminder_id': 'reminder-1',
    });
  });
  testWidgets(
    'offline retains saved reminders and pending cache failure does not repeat PATCH',
    (tester) async {
      final fake = fakeRepo()..failRefresh = true;
      await mount(tester, fake);
      expect(find.text('Doctor appointment'), findsOneWidget);
      expect(find.textContaining('Showing saved reminders'), findsOneWidget);
      fake.failRefresh = false;
      fake.failCache = true;
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Change saved. Retry to finish updating the list.'),
        findsOneWidget,
      );
      fake.failCache = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(fake.toggles, 1);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, false);
    },
  );
  testWidgets(
    'midnight hides yesterday logs even if the next refresh is offline',
    (tester) async {
      final fake = fakeRepo();
      final ticks = StreamController<DateTime>.broadcast();
      addTearDown(ticks.close);
      await mount(tester, fake, clock: ticks.stream);
      ticks.add(at);
      await tester.pumpAndSettle();
      fake.failRefresh = true;
      ticks.add(DateTime.utc(2026, 10, 1, 22));
      await tester.pumpAndSettle();
      expect(find.text('Done · voice'), findsNothing);
      expect(find.text('Doctor appointment'), findsOneWidget);
      expect(fake.days.last, '2026-10-02');
      expect(
        find.text('No saved reminder activity for today.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'resume refresh uses the current clock after a background midnight',
    (tester) async {
      final fake = fakeRepo();
      var now = at;
      await mount(tester, fake, now: () => now);
      now = DateTime.utc(2026, 10, 1, 22);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(fake.days.last, '2026-10-02');
    },
  );
  testWidgets('empty state contains no fake upcoming occurrences', (
    tester,
  ) async {
    await mount(tester, fakeRepo()..data = fixture(empty: true));
    expect(find.text('No reminder activity recorded today.'), findsOneWidget);
    expect(find.text('No reminders have been added yet.'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });
  testWidgets('account change stops displaying previous account reminders', (
    tester,
  ) async {
    final fake = fakeRepo();
    var selected = scope;
    final container = await mount(tester, fake, selected: () => selected);
    selected = const ReminderScope('caregiver-B', 'patient-B', 'Africa/Cairo');
    container.invalidate(reminderScopeProvider);
    await tester.pumpAndSettle();
    expect(find.text('Doctor appointment'), findsNothing);
    expect(find.text('Done · voice'), findsNothing);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C8 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, fakeRepo(), language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c8-preview')),
          matchesGoldenFile('goldens/c8_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
    testWidgets('C8 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        fakeRepo(),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(Switch).last);
      expect(tester.takeException(), isNull);
    });
  }
}
