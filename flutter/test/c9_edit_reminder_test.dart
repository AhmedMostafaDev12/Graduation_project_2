import 'dart:async';

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
import 'package:remori/features/reminders/domain/reminder_draft.dart';
import 'package:remori/features/reminders/presentation/reminder_editor_providers.dart';
import 'package:remori/features/reminders/presentation/reminders_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c8_reminders_test.dart' as c8;

const scope = c8.scope;
const editor = ReminderEditorKey(scope, null);
final starts = DateTime(2026, 10, 1);
final draft = <String, Object?>{
  'title': 'Medicine',
  'spoken_text': 'Time for medicine',
  'type': 'medication',
  'active': true,
  'rrule': 'FREQ=DAILY;BYHOUR=9;BYMINUTE=0',
  'dtstart': '2026-10-01T06:00:00Z',
  'timezone': scope.timezone,
};

CaregiverReminder reminder(String rule, {DateTime? start}) => CaregiverReminder(
  id: 'reminder-0',
  title: 'Medicine',
  kind: ReminderKind.medication,
  rrule: rule,
  dtstart: start ?? DateTime.utc(2026, 10, 1, 6),
  timezone: scope.timezone,
  active: false,
  spokenText: 'Time for medicine',
);

class WriteAdapter extends c8.Adapter {
  bool wrongId = false, wrongPatient = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!['POST', 'PATCH', 'DELETE'].contains(options.method)) {
      return super.fetch(options, requestStream, cancelFuture);
    }
    requests.add(options);
    if (options.method == 'DELETE') return ResponseBody.fromString('', 204);
    final raw = {
      ...body(0),
      ...options.data as Map,
      'id': options.method == 'POST'
          ? 'created-id'
          : wrongId
          ? 'wrong-id'
          : 'reminder-0',
      'patient_id': wrongPatient ? 'other-patient' : scope.patientId,
      'updated_at': c8.at.add(const Duration(minutes: 1)).toIso8601String(),
    };
    return json(options.method == 'POST' ? 201 : 200, raw);
  }
}

class FakeEditorRepository extends c8.FakeRepository {
  FakeEditorRepository(super.client, super.db, super.scope);
  int saves = 0, deletes = 0, deletedCaches = 0;
  Map<String, Object?>? lastPayload;
  bool failDeleteCache = false;
  @override
  Future<CachedRemindersCompanion> save(
    Map<String, Object?> payload, {
    String? id,
  }) async {
    saves++;
    lastPayload = payload;
    if (gate != null) await gate!.future;
    return CachedRemindersCompanion.insert(
      caregiverId: scope.caregiverId,
      patientId: scope.patientId,
      id: id ?? 'created-id',
      title: payload['title'] as String? ?? 'Medicine',
      type: 'medication',
      rrule: c8.rules[0],
      dtstart: c8.at,
      timezone: scope.timezone,
      active: true,
      updatedAt: c8.at,
      position: 0,
    );
  }

  @override
  Future<void> delete(String id) async {
    deletes++;
    if (gate != null) await gate!.future;
  }

  @override
  Future<void> cacheDelete(String id) async {
    deletedCaches++;
    if (failDeleteCache) throw StateError('PRIVATE CACHE FAILURE');
  }
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late WriteAdapter adapter;
  late RemindersRepository repo;
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
    adapter = WriteAdapter();
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
  });

  test('explicit selection, duplicate times, maximum four and weekly days are validated', () {
    final schedule = ReminderScheduleDraft(
      starts: starts,
      timezone: scope.timezone,
    );
    expect(schedule.error, 'times');
    schedule.minutes.addAll([540, 540]);
    expect(schedule.error, 'times');
    schedule.minutes
      ..clear()
      ..addAll([60, 120, 180, 240, 300]);
    expect(schedule.error, 'times');
    schedule.minutes
      ..clear()
      ..add(540);
    schedule.repeat = ReminderRepeat.weekly;
    expect(schedule.error, 'days');
    schedule.weekdays.add(1);
    expect(schedule.error, null);
    schedule.timezone = 'invalid/timezone';
    expect(schedule.error, 'timezone');
  });
  test(
    'daily mixed minutes select exact pairs rather than all combinations',
    () {
      final schedule = ReminderScheduleDraft(
        starts: starts,
        timezone: scope.timezone,
        minutes: [990, 555],
      );
      expect(schedule.payload(), {
        'rrule': 'FREQ=DAILY;BYHOUR=9,16;BYMINUTE=15,30;BYSETPOS=1,4',
        'dtstart': '2026-10-01T06:15:00.000Z',
        'timezone': scope.timezone,
      });
      final parsed = ReminderScheduleDraft.parse(
        reminder(
          schedule.payload()['rrule'] as String,
          start: DateTime.utc(2026, 10, 1, 6, 15),
        ),
      )!;
      expect(parsed.minutes, [555, 990]);
      expect(parsed.repeat, ReminderRepeat.daily);
    },
  );
  test('once includes all selected times on the start day and round trips', () {
    final schedule = ReminderScheduleDraft(
      starts: starts,
      timezone: scope.timezone,
      repeat: ReminderRepeat.once,
      minutes: [555, 990],
    );
    expect(
      schedule.payload()['rrule'],
      'FREQ=DAILY;COUNT=2;BYHOUR=9,16;BYMINUTE=15,30;BYSETPOS=1,4',
    );
    expect(
      ReminderScheduleDraft.parse(
        reminder(
          schedule.payload()['rrule'] as String,
          start: DateTime.utc(2026, 10, 1, 6, 15),
        ),
      )!.repeat,
      ReminderRepeat.once,
    );
  });
  test('weekly positions cover every selected day and start on the first eligible day', () {
    final schedule = ReminderScheduleDraft(
      starts: starts,
      timezone: scope.timezone,
      repeat: ReminderRepeat.weekly,
      weekdays: {1, 3},
      minutes: [555, 990],
    );
    expect(schedule.firstDay, DateTime(2026, 10, 5));
    expect(
      schedule.payload()['rrule'],
      'FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=9,16;BYMINUTE=15,30;BYSETPOS=1,4,5,8',
    );
    final parsed = ReminderScheduleDraft.parse(
      reminder(
        schedule.payload()['rrule'] as String,
        start: DateTime.utc(2026, 10, 5, 6, 15),
      ),
    )!;
    expect(parsed.weekdays, {1, 3});
    expect(parsed.minutes, [555, 990]);
  });
  test('four arbitrary times across all days fit the API rule limit', () {
    final schedule = ReminderScheduleDraft(
      starts: starts,
      timezone: scope.timezone,
      repeat: ReminderRepeat.weekly,
      weekdays: {1, 2, 3, 4, 5, 6, 7},
      minutes: [61, 122, 183, 244],
    );
    final raw = schedule.payload();
    expect((raw['rrule'] as String).length, lessThanOrEqualTo(300));
    expect(
      ReminderScheduleDraft.parse(
        reminder(
          raw['rrule'] as String,
          start: DateTime.parse(raw['dtstart'] as String),
        ),
      )!.minutes,
      schedule.minutes,
    );
  });
  test('DST gap is rejected and overlap selects the first occurrence', () {
    final schedule = ReminderScheduleDraft(
      starts: DateTime(2026, 3, 8),
      timezone: 'America/New_York',
      minutes: [150],
    );
    expect(schedule.error, 'gap');
    expect(() => schedule.payload(), throwsStateError);
    expect(
      ReminderScheduleDraft.resolve(
        DateTime(2026, 11, 1),
        90,
        'America/New_York',
      ),
      DateTime.utc(2026, 11, 1, 5, 30),
    );
  });
  for (final rule in [
    'FREQ=MONTHLY;BYMONTHDAY=1',
    'FREQ=DAILY;COUNT=30;BYHOUR=9;BYMINUTE=0',
    'FREQ=WEEKLY;INTERVAL=2',
    'FREQ=DAILY;UNTIL=20261231T000000Z',
    'FREQ=DAILY;BYHOUR=9;BYMINUTE=0;BYSETPOS=-1',
    'FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=9,16;BYMINUTE=15,30;BYSETPOS=1,8',
  ]) {
    test('complex rule remains read-only: $rule', () {
      expect(ReminderScheduleDraft.parse(reminder(rule)), null);
    });
  }

  test('POST stores spoken text under the correct account and patient only after acknowledgment', () async {
    final row = await repo.save(draft);
    expect((await repo.read(c8.day)).reminders, isEmpty);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/patients/${scope.patientId}/reminders');
    expect(request.data, draft);
    await repo.cacheToggle(row);
    final value = (await repo.read(c8.day)).reminders.single;
    expect(value.id, 'created-id');
    expect(value.spokenText, 'Time for medicine');
    final other = RemindersRepository(
      client,
      db,
      const ReminderScope('other', 'patient-A', 'Africa/Cairo'),
    );
    expect((await other.read(c8.day)).reminders, isEmpty);
  });
  test('metadata PATCH preserves recurrence and inactive state', () async {
    adapter.active = false;
    await repo.refresh(c8.day);
    final payload = <String, Object?>{
      'title': 'Updated',
      'spoken_text': null,
      'type': 'task',
    };
    final row = await repo.save(payload, id: 'reminder-0');
    await repo.cacheToggle(row);
    expect(adapter.requests.last.data, payload);
    final value = (await repo.read(c8.day)).reminders.first;
    expect(value.active, false);
    expect(value.rrule, c8.rules.first);
    expect(value.spokenText, null);
  });
  test(
    'mismatched server patient and reminder IDs are rejected without caching',
    () async {
      adapter.wrongPatient = true;
      await expectLater(repo.save(draft), throwsA(isA<ApiFailure>()));
      expect((await repo.read(c8.day)).reminders, isEmpty);
      adapter.wrongPatient = false;
      await repo.refresh(c8.day);
      adapter.wrongId = true;
      await expectLater(
        repo.save({'title': 'Updated'}, id: 'reminder-0'),
        throwsA(isA<ApiFailure>()),
      );
      expect((await repo.read(c8.day)).reminders.first.title, c8.titles.first);
    },
  );
  test('DELETE removes the definition but retains recorded logs and other definitions', () async {
    await repo.refresh(c8.day);
    await repo.delete('reminder-0');
    expect(adapter.requests.last.method, 'DELETE');
    expect(
      adapter.requests.last.path,
      '/patients/${scope.patientId}/reminders/reminder-0',
    );
    await repo.cacheDelete('reminder-0');
    final data = await repo.read(c8.day);
    expect(data.reminders.length, 2);
    expect(data.occurrences.length, 3);
    expect(data.occurrences.first.title, c8.titles.first);
  });
  test('a pre-write refresh cannot erase a created reminder or resurrect a deleted one', () async {
    await repo.refresh(c8.day);
    adapter
      ..delayedDay = c8.day
      ..gate = Completer<void>();
    final refresh = repo.refresh(c8.day);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repo.cacheToggle(await repo.save(draft));
    await repo.delete('reminder-0');
    await repo.cacheDelete('reminder-0');
    adapter.gate!.complete();
    await refresh;
    final ids = (await repo.read(c8.day)).reminders.map((r) => r.id);
    expect(ids, contains('created-id'));
    expect(ids, isNot(contains('reminder-0')));
  });

  FakeEditorRepository fake() => FakeEditorRepository(client, db, scope);
  ProviderContainer controller(
    FakeEditorRepository fake, {
    bool manager = true,
    ReminderScope Function()? selected,
  }) => ProviderContainer(
    overrides: [
      reminderScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
      caregiverCanManageProvider.overrideWithValue(manager),
      remindersRepositoryProvider(scope).overrideWithValue(fake),
    ],
  );
  test(
    'acknowledged creation retries only caching, with the same server ID',
    () async {
      final repository = fake()..failCache = true;
      final container = controller(repository);
      addTearDown(container.dispose);
      final listen = container.listen(
        reminderEditorProvider(editor),
        (_, _) {},
      );
      addTearDown(listen.close);
      final notifier = container.read(reminderEditorProvider(editor).notifier);
      expect(await notifier.save(draft), false);
      expect(container.read(reminderEditorProvider(editor)).acknowledged, true);
      repository.failCache = false;
      expect(await notifier.save({'title': 'Do not create again'}), true);
      expect(repository.saves, 1);
      expect(repository.cacheWrites, 2);
      expect(repository.lastPayload, draft);
    },
  );
  test('acknowledged deletion retries only local removal', () async {
    const owner = ReminderEditorKey(scope, 'reminder-0');
    final repository = fake()..failDeleteCache = true;
    final container = controller(repository);
    addTearDown(container.dispose);
    final listen = container.listen(reminderEditorProvider(owner), (_, _) {});
    addTearDown(listen.close);
    final notifier = container.read(reminderEditorProvider(owner).notifier);
    expect(await notifier.delete(), false);
    repository.failDeleteCache = false;
    expect(await notifier.delete(), true);
    expect(repository.deletes, 1);
    expect(repository.deletedCaches, 2);
  });
  test(
    'duplicate save taps and account changes cannot apply a late response',
    () async {
      final repository = fake()..gate = Completer<void>();
      var selected = scope;
      final container = controller(repository, selected: () => selected);
      addTearDown(container.dispose);
      final listen = container.listen(
        reminderEditorProvider(editor),
        (_, _) {},
      );
      addTearDown(listen.close);
      final notifier = container.read(reminderEditorProvider(editor).notifier);
      final first = notifier.save(draft);
      expect(await notifier.save(draft), false);
      expect(repository.saves, 1);
      selected = const ReminderScope('other', 'other', 'Africa/Cairo');
      container.invalidate(reminderScopeProvider);
      repository.gate!.complete();
      expect(await first, false);
      expect(repository.cacheWrites, 0);
    },
  );
  test('viewers cannot issue create or delete requests', () async {
    final repository = fake();
    final container = controller(repository, manager: false);
    addTearDown(container.dispose);
    final listen = container.listen(reminderEditorProvider(editor), (_, _) {});
    addTearDown(listen.close);
    final notifier = container.read(reminderEditorProvider(editor).notifier);
    expect(await notifier.save(draft), false);
    expect(await notifier.delete(), false);
    expect(repository.saves + repository.deletes, 0);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeEditorRepository fake, {
    String? id,
    String? patientId,
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    Size size = const Size(390, 844),
    ReminderScope Function()? selected,
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
        reminderClockProvider.overrideWithValue(() => c8.at),
        reminderNowProvider.overrideWith((ref) => Stream.value(c8.at)),
        caregiverCanManageProvider.overrideWithValue(!viewer),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        remindersRepositoryProvider(scope).overrideWithValue(fake),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c8: (_, _) => const Text('Reminder list'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c9-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          RemoriScreen.c9.name,
          extra: {
            'patient_id': patientId ?? scope.patientId,
            'reminder_id': ?id,
          },
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'new form defaults to patient today but requires explicit title and time selection',
    (tester) async {
      final repository = fake();
      await mount(tester, repository);
      expect(find.text('Add reminder'), findsOneWidget);
      expect(find.text('Oct 1, 2026'), findsOneWidget);
      expect(find.text('Delete reminder'), findsNothing);
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a title (up to 120 characters).'),
        findsOneWidget,
      );
      expect(find.text('Select 1–4 different times.'), findsOneWidget);
      expect(repository.saves, 0);
    },
  );
  testWidgets(
    'metadata-only edit leaves schedule and active state out of PATCH',
    (tester) async {
      final repository = fake()
        ..data = ReminderListData(
          reminders: [reminder('FREQ=DAILY;BYHOUR=9;BYMINUTE=0')],
          refreshedAt: c8.at,
        );
      await mount(tester, repository, id: 'reminder-0');
      expect(find.text('Time for medicine'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Updated',
      );
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(repository.lastPayload, {
        'title': 'Updated',
        'spoken_text': 'Time for medicine',
        'type': 'medication',
      });
      expect(find.text('Reminder list'), findsOneWidget);
    },
  );
  testWidgets(
    'unsupported schedule is preserved while metadata remains editable',
    (tester) async {
      final repository = fake()
        ..data = ReminderListData(
          reminders: [reminder('FREQ=MONTHLY;BYMONTHDAY=1')],
          refreshedAt: c8.at,
        );
      await mount(tester, repository, id: 'reminder-0');
      expect(
        find.text(
          'This schedule is kept unchanged. You can edit the title, spoken text and type.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Weekly'),
            )
            .onPressed,
        null,
      );
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Monthly medicine',
      );
      await tester.ensureVisible(find.text('Save reminder'));
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(repository.lastPayload!.keys, isNot(contains('rrule')));
    },
  );
  testWidgets('deletion requires confirmation and Cancel sends no request', (
    tester,
  ) async {
    final repository = fake();
    await mount(tester, repository, id: 'reminder-0');
    await tester.tap(find.text('Delete reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletes, 0);
    await tester.tap(find.text('Delete reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete reminder').last);
    await tester.pumpAndSettle();
    expect(repository.deletes, 1);
    expect(find.text('Reminder list'), findsOneWidget);
  });
  Future<void> pick(WidgetTester tester, int hour, int minute) async {
    await tester.ensureVisible(find.text('+ Add time'));
    await tester.tap(find.text('+ Add time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '$hour');
    await tester.enterText(fields.last, '$minute');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'native time selection creates Once with exact pairs and a UTC start',
    (tester) async {
      final repository = fake();
      await mount(tester, repository);
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'One-off task',
      );
      await tester.tap(find.text('Once'));
      await pick(tester, 9, 15);
      await pick(tester, 10, 30);
      await tester.ensureVisible(find.text('Save reminder'));
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(repository.lastPayload, {
        'title': 'One-off task',
        'spoken_text': null,
        'type': 'medication',
        'active': true,
        'rrule': 'FREQ=DAILY;COUNT=2;BYHOUR=9,10;BYMINUTE=15,30;BYSETPOS=1,4',
        'dtstart': '2026-10-01T06:15:00.000Z',
        'timezone': scope.timezone,
      });
      expect(find.text('Reminder list'), findsOneWidget);
    },
  );
  testWidgets('four times hide Add time and removal makes it available again', (
    tester,
  ) async {
    await mount(tester, fake());
    for (var i = 1; i <= 4; i++) {
      await pick(tester, i, i * 5);
    }
    expect(find.text('+ Add time'), findsNothing);
    await tester.tap(find.byTooltip('Remove time').first);
    await tester.pumpAndSettle();
    expect(find.text('+ Add time'), findsOneWidget);
  });
  testWidgets(
    'an acknowledged write locks fields and Retry only updates the cache',
    (tester) async {
      final repository = fake()..failCache = true;
      await mount(tester, repository, id: 'reminder-0');
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(
        find.text('Change saved. Retry to finish updating the list.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('reminder-title')))
            .enabled,
        false,
      );
      repository.failCache = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repository.saves, 1);
      expect(find.text('Reminder list'), findsOneWidget);
    },
  );
  testWidgets(
    'changing the account hides the previous editor and its private fields',
    (tester) async {
      var selected = scope;
      final container = await mount(
        tester,
        fake(),
        id: 'reminder-0',
        selected: () => selected,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('reminder-title')))
            .controller!
            .text,
        c8.titles.first,
      );
      selected = const ReminderScope('other', 'other', 'Africa/Cairo');
      container.invalidate(reminderScopeProvider);
      await tester.pumpAndSettle();
      expect(find.text(c8.titles.first), findsNothing);
      expect(find.byKey(const Key('reminder-title')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final viewer in [true, false]) {
    testWidgets(
      viewer
          ? 'viewer cannot open the editor'
          : 'mismatched patient cannot open the editor',
      (tester) async {
        await mount(
          tester,
          fake(),
          viewer: viewer,
          patientId: viewer ? null : 'other-patient',
        );
        expect(find.byKey(const Key('reminder-title')), findsNothing);
        expect(
          find.text(
            'This reminder is unavailable or you do not have permission to edit it.',
          ),
          findsOneWidget,
        );
      },
    );
  }
  for (final language in ['en', 'ar']) {
    testWidgets('C9 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, fake(), id: 'reminder-0', language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c9-preview')),
          matchesGoldenFile('goldens/c9_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
    testWidgets('C9 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        fake(),
        id: 'reminder-0',
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.text(language == 'en' ? 'Save reminder' : 'حفظ التذكير'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
