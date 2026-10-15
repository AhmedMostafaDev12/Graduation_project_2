import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/p3_reminder_alert_screen.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;

PatientReminderAlertTarget target(
  DateTime due, {
  PatientTodayKey scope = p1.key,
  String id = p1.logId,
}) => (scope: scope, id: id, dueAt: due);
PatientTodayData fixture({
  DateTime? due,
  String? type = 'medication',
  String status = 'pending',
  String language = 'en',
  bool completed = false,
}) {
  final reminder = PatientReminder(
    p1.logId,
    language == 'ar' ? 'دواء الضغط' : 'Blood pressure pill',
    due ?? p1.now,
    type: type,
    status: completed ? 'completed' : status,
  );
  return PatientTodayData(
    settings: PatientSettings('Patient', language, 'Africa/Cairo', true),
    next: completed ? null : reminder,
    reminders: [reminder],
  );
}

final fixtureProvider = NotifierProvider<Fixture, PatientTodayData>(
  () => Fixture(fixture()),
);

class Fixture extends Notifier<PatientTodayData> {
  Fixture(this.initial);
  final PatientTodayData initial;
  @override
  PatientTodayData build() => initial;
  void put(PatientTodayData value) => state = value;
}

final testNowProvider = NotifierProvider<TestNow, DateTime>(TestNow.new);

class TestNow extends Notifier<DateTime> {
  @override
  DateTime build() => p1.now;
  void put(DateTime value) => state = value;
}

class Controller extends PatientTodayController {
  Controller(super.key, {this.mockRefresh = false});
  final bool mockRefresh;
  Future<bool>? action;
  @override
  PatientTodayState build() => const PatientTodayState();
  @override
  Future<void> refresh() => mockRefresh ? Future.value() : super.refresh();
  @override
  Future<bool> confirmAlert(
    PatientReminderAlertTarget target, {
    required bool snooze,
  }) {
    action = super.confirmAlert(target, snooze: snooze);
    return action!;
  }

  void busy(bool value) => state = PatientTodayState(busy: value);
}

class Repository extends p2.Repository {
  Repository(
    super.client,
    super.db,
    super.key,
    super.clock, {
    required super.current,
  });
  bool localFails = false;
  @override
  Future<bool> confirmAlert(
    PatientReminderAlertTarget target, {
    required bool snooze,
  }) async {
    if (localFails) throw StateError('Synthetic local failure');
    final saved = await super.confirmAlert(target, snooze: snooze);
    await changed();
    return saved;
  }
}

void main() {
  late RemoriDatabase db;
  late p2.Adapter adapter;
  late ApiClient client;
  late Repository repo;
  late DateTime clock;
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
    adapter = p2.Adapter();
    clock = p1.now;
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      onCredentialsInvalidated: (_) {},
      adapter: adapter,
    );
    repo = Repository(client, db, p1.key, () => clock, current: () => true);
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });

  test('API reminder type persists and survives a local cache read', () async {
    await repo.refresh();
    final data = await repo.read();
    expect(data.reminders.map((r) => r.type), ['medication', 'task', 'task']);
    expect(
      (await db.select(db.patientReminderCards).get()).every(
        (r) => r.reminderType != null,
      ),
      isTrue,
    );
  });
  test('schema v16 migration preserves cards and queued confirmations with a nullable type', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-p3-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      repo = Repository(client, db, p1.key, () => clock, current: () => true);
      await repo.refresh();
      await repo.act(p1.logId, snooze: true);
      await db.customStatement(
        'ALTER TABLE patient_reminder_cards DROP COLUMN reminder_type',
      );
      await db.customStatement('PRAGMA user_version = 16');
      repo.dispose();
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      repo = Repository(client, db, p1.key, () => clock, current: () => true);
      expect((await repo.read()).reminders, hasLength(3));
      expect(
        (await repo.read()).reminders.every((r) => r.type == null),
        isTrue,
      );
      expect(await db.pendingWrites(auth.patient), hasLength(1));
      await repo.refresh();
      expect((await repo.read()).reminders.first.type, 'medication');
    } finally {
      repo.dispose();
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
      repo = Repository(client, db, p1.key, () => clock, current: () => true);
      final absolute = dir.absolute;
      if (absolute.parent.path == Directory.systemTemp.absolute.path &&
          absolute.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('remori-p3-migration-')) {
        await absolute.delete(recursive: true);
      }
    }
  });
  for (final snooze in [false, true]) {
    test(
      'P3 locally persists ${snooze ? 'snooze' : 'completion'} before any upload',
      () async {
        await repo.refresh();
        final before = (await repo.read()).next!;
        adapter.fail = true;
        expect(
          await repo.confirmAlert(target(before.dueAt), snooze: snooze),
          isTrue,
        );
        expect(await db.pendingWrites(auth.patient), hasLength(1));
        expect(adapter.requests.any((o) => o.path.endsWith(':batch')), isFalse);
        final after = (await repo.read()).reminders.singleWhere(
          (r) => r.id == p1.logId,
        );
        expect(after.status, snooze ? 'snoozed' : 'completed');
        if (snooze) expect(after.dueAt, clock.add(const Duration(minutes: 15)));
      },
    );
  }
  test('stale due time, future time, other device and other occurrence cannot confirm', () async {
    await repo.refresh();
    final before = (await repo.read()).next!;
    for (final bad in [
      target(before.dueAt.add(const Duration(minutes: 1))),
      target(clock.add(const Duration(minutes: 1))),
      target(before.dueAt, scope: p2.otherKey),
      target(before.dueAt, id: p2.id(3)),
    ]) {
      expect(await repo.confirmAlert(bad, snooze: false), isFalse);
    }
    expect(await db.pendingWrites(auth.patient), isEmpty);
  });
  test(
    'a completed occurrence cannot be confirmed or snoozed again through P3',
    () async {
      await repo.refresh();
      final before = (await repo.read()).next!;
      expect(
        await repo.confirmAlert(target(before.dueAt), snooze: false),
        isTrue,
      );
      expect(
        await repo.confirmAlert(target(before.dueAt), snooze: true),
        isFalse,
      );
      expect(await db.pendingWrites(auth.patient), hasLength(1));
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    PatientTodayData? data,
    bool realData = false,
    String language = 'en',
    double scale = 1,
    bool trigger = true,
    PatientReminderAlertTarget? direct,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    if (realData) await tester.runAsync(repo.refresh);
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final container = ProviderContainer(
      overrides: [
        fixtureProvider.overrideWith(
          () => Fixture(data ?? fixture(language: language)),
        ),
        patientTodayKeyProvider.overrideWith(
          (ref) => ref.watch(p2.selectedScope),
        ),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayDataProvider(p1.key).overrideWith(
          (ref) => realData
              ? repo.watch()
              : Stream.value(ref.watch(fixtureProvider)),
        ),
        patientTodayDataProvider(p2.otherKey)
            .overrideWith((ref) => Stream.value(const PatientTodayData())),
        patientTodayRepositoryProvider(p1.key).overrideWithValue(repo),
        patientTodayControllerProvider(p1.key)
            .overrideWith(() => Controller(p1.key, mockRefresh: !realData)),
        patientTodayControllerProvider(p2.otherKey)
            .overrideWith(() => Controller(p2.otherKey, mockRefresh: true)),
        patientTodayNowProvider.overrideWith(
          (ref) => Stream.value(ref.watch(testNowProvider)),
        ),
        patientTodayClockProvider.overrideWith(
          (ref) =>
              () => ref.read(testNowProvider),
        ),
        patientLinkProvider.overrideWith(
          (ref) => Stream.value(const PatientLinkStatus()),
        ),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
        if (!trigger) patientAlertCandidateProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const Key('p3-preview'),
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const RemoriApp(),
          ),
        ),
      ),
    );
    if (realData) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pumpAndSettle();
    if (direct != null) {
      container
          .read(remoriRouterProvider)
          .goNamed(RemoriScreen.p3.name, extra: direct);
      await tester.pumpAndSettle();
    }
    return container;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  String path(ProviderContainer c) =>
      c.read(remoriRouterProvider).routeInformationProvider.value.uri.path;

  testWidgets('due foreground reminder opens P3 without bottom navigation', (
    tester,
  ) async {
    final c = await mount(tester);
    expect(path(c), '/p3');
    expect(find.byType(RemoriNavigationBar), findsNothing);
    expect(find.text('Time for Blood pressure pill'), findsOneWidget);
    expect(find.byKey(const Key('patient-alert-pill')), findsOneWidget);
    expect(c.read(patientAlertSessionProvider), hasLength(1));
    await unmount(tester, c);
  });
  testWidgets(
    'same due time opens only once across P1/P2 navigation and rebuilds',
    (tester) async {
      final c = await mount(tester);
      for (final screen in [
        RemoriScreen.p2,
        RemoriScreen.p1,
        RemoriScreen.p2,
      ]) {
        c.read(remoriRouterProvider).goNamed(screen.name);
        await tester.pumpAndSettle();
        expect(path(c), screen.path);
      }
      c.read(fixtureProvider.notifier).put(fixture());
      await tester.pumpAndSettle();
      expect(path(c), '/p2');
      expect(c.read(patientAlertSessionProvider), hasLength(1));
      await unmount(tester, c);
    },
  );
  testWidgets(
    'future reminder waits, then opens at the next foreground clock update',
    (tester) async {
      final due = p1.now.add(const Duration(minutes: 1));
      final c = await mount(tester, data: fixture(due: due));
      expect(path(c), '/p1');
      c.read(testNowProvider.notifier).put(due);
      await tester.pumpAndSettle();
      expect(path(c), '/p3');
      await unmount(tester, c);
    },
  );
  testWidgets('background due time waits until foreground resume', (
    tester,
  ) async {
    final due = p1.now.add(const Duration(minutes: 1));
    final c = await mount(tester, data: fixture(due: due));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    c.read(testNowProvider.notifier).put(due);
    await tester.pumpAndSettle();
    expect(path(c), '/p1');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(path(c), '/p3');
    await unmount(tester, c);
  });
  testWidgets('new snoozed due time can reopen the same occurrence', (
    tester,
  ) async {
    final c = await mount(tester);
    c.read(remoriRouterProvider).goNamed(RemoriScreen.p2.name);
    await tester.pumpAndSettle();
    final later = p1.now.add(const Duration(minutes: 15));
    c
        .read(fixtureProvider.notifier)
        .put(fixture(due: later, status: 'snoozed'));
    await tester.pumpAndSettle();
    expect(path(c), '/p2');
    c.read(testNowProvider.notifier).put(later);
    await tester.pumpAndSettle();
    expect(path(c), '/p3');
    expect(c.read(patientAlertSessionProvider), hasLength(2));
    await unmount(tester, c);
  });
  testWidgets(
    'busy controller delays opening until the current operation finishes',
    (tester) async {
      final due = p1.now.add(const Duration(minutes: 1));
      final c = await mount(tester, data: fixture(due: due));
      final controller =
          c.read(patientTodayControllerProvider(p1.key).notifier) as Controller;
      controller.busy(true);
      c.read(testNowProvider.notifier).put(due);
      await tester.pumpAndSettle();
      expect(path(c), '/p1');
      controller.busy(false);
      await tester.pumpAndSettle();
      expect(path(c), '/p3');
      await unmount(tester, c);
    },
  );
  for (final type in ['task', 'appointment', null]) {
    testWidgets('$type uses a generic bell instead of claiming medication', (
      tester,
    ) async {
      final c = await mount(tester, data: fixture(type: type));
      expect(find.byKey(const Key('patient-alert-bell')), findsOneWidget);
      expect(find.byKey(const Key('patient-alert-pill')), findsNothing);
      await unmount(tester, c);
    });
  }
  testWidgets('scope switch hides the old patient title and action buttons', (
    tester,
  ) async {
    final c = await mount(tester);
    c.read(p2.selectedScope.notifier).select(p2.otherKey);
    await tester.pumpAndSettle();
    expect(find.text('Time for Blood pressure pill'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('remote completion dismisses the alert without another action', (
    tester,
  ) async {
    final c = await mount(tester);
    c.read(fixtureProvider.notifier).put(fixture(completed: true));
    await tester.pumpAndSettle();
    expect(path(c), '/p2');
    expect(find.byType(P3ReminderAlertScreen), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('wrong-device link never shows a reminder title', (tester) async {
    final c = await mount(
      tester,
      trigger: false,
      direct: target(p1.now, scope: p2.otherKey),
    );
    expect(find.text('Time for Blood pressure pill'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Back to reminders'), findsOneWidget);
    await unmount(tester, c);
  });
  for (final snooze in [false, true]) {
    testWidgets(
      'offline ${snooze ? 'Later' : 'Done'} persists and returns to P2',
      (tester) async {
        final c = await mount(tester, realData: true);
        expect(path(c), '/p3');
        adapter.fail = true;
        final controller = c.read(
          patientTodayControllerProvider(p1.key).notifier,
        ) as Controller;
        await tester.runAsync(() async {
          await tester.tap(
            snooze ? find.byType(OutlinedButton) : find.byType(FilledButton),
          );
          expect(await controller.action, isTrue);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        expect(path(c), '/p2');
        final writes = await tester.runAsync(
          () => db.pendingWrites(auth.patient),
        );
        expect(writes, hasLength(1));
        final data = await tester.runAsync(repo.read);
        expect(
          data!.reminders.singleWhere((r) => r.id == p1.logId).status,
          snooze ? 'snoozed' : 'completed',
        );
        expect(tester.takeException(), isNull);
        await unmount(tester, c);
      },
    );
  }
  testWidgets('local failure stays on P3 and retry saves exactly one action', (
    tester,
  ) async {
    final c = await mount(tester, realData: true);
    repo.localFails = true;
    final controller =
        c.read(patientTodayControllerProvider(p1.key).notifier) as Controller;
    await tester.runAsync(() async {
      await tester.tap(find.byType(FilledButton));
      expect(await controller.action, isFalse);
    });
    await tester.pumpAndSettle();
    expect(path(c), '/p3');
    expect(
      find.text("That wasn't saved yet. Please try again."),
      findsOneWidget,
    );
    expect(
      await tester.runAsync(() => db.pendingWrites(auth.patient)),
      isEmpty,
    );
    repo.localFails = false;
    adapter.fail = true;
    await tester.runAsync(() async {
      await tester.tap(find.byType(FilledButton));
      expect(await controller.action, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(path(c), '/p2');
    expect(
      await tester.runAsync(() => db.pendingWrites(auth.patient)),
      hasLength(1),
    );
    await unmount(tester, c);
  });
  test(
    'local confirmation returns before an in-flight network upload',
    () async {
      await repo.refresh();
      final due = (await repo.read()).next!.dueAt;
      final c = ProviderContainer(
        overrides: [
          patientTodayKeyProvider.overrideWithValue(p1.key),
          patientTodayRepositoryProvider(p1.key).overrideWithValue(repo),
          patientTodayControllerProvider(p1.key)
              .overrideWith(() => Controller(p1.key)),
        ],
      );
      final sub = c.listen(patientTodayControllerProvider(p1.key), (_, _) {});
      addTearDown(() {
        sub.close();
        c.dispose();
      });
      adapter.gate = Completer();
      adapter.posted = Completer();
      final controller =
          c.read(patientTodayControllerProvider(p1.key).notifier) as Controller;
      expect(
        await controller
            .confirmAlert(target(due), snooze: false)
            .timeout(const Duration(seconds: 3)),
        isTrue,
      );
      await adapter.posted!.future.timeout(const Duration(seconds: 3));
      expect(c.read(patientTodayControllerProvider(p1.key)).busy, isTrue);
      expect(adapter.gate!.isCompleted, isFalse);
      adapter.gate!.complete();
      for (
        var i = 0;
        i < 50 && c.read(patientTodayControllerProvider(p1.key)).busy;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(c.read(patientTodayControllerProvider(p1.key)).busy, isFalse);
      expect(await db.pendingWrites(auth.patient), isEmpty);
    },
  );
  for (final language in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P3 $language at ${scale}x reference and accessible layout', (
        tester,
      ) async {
        final c = await mount(tester, language: language, scale: scale);
        expect(find.byType(P3ReminderAlertScreen), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(P3ReminderAlertScreen)),
          ).scale(22),
          22 * scale,
        );
        expect(
          Directionality.of(tester.element(find.byType(P3ReminderAlertScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        if (scale == 1 && autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('p3-preview')),
            matchesGoldenFile('goldens/p3_$language.png'),
          );
        }
        await tester.scrollUntilVisible(find.byType(FilledButton), 150);
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(64),
        );
        await tester.scrollUntilVisible(find.byType(OutlinedButton), 150);
        expect(
          tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(64),
        );
        expect(tester.takeException(), isNull);
        await unmount(tester, c);
      });
    }
  }
}
