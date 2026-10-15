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
import 'package:remori/core/l10n/app_localizations.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/patient_today/data/patient_today_repository.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/p1_today_screen.dart';
import 'package:remori/features/patient_today/presentation/p2_reminders_screen.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;

String id(int i) => '00000005-0000-4000-8000-${i.toString().padLeft(12, '0')}';
const otherKey = (auth.patient, '00000003-0000-4000-8000-000000000009');

class Adapter extends p1.Adapter {
  String language = 'en';
  bool extraStates = false, empty = false;
  List<Map<String, Object?>> get logs => [
    row(3, 13, 'pending', language == 'ar' ? 'اشرب مية' : 'Drink water'),
    row(1, 9, 'pending', language == 'ar' ? 'اشرب مية' : 'Drink water'),
    row(
      2,
      6,
      'completed',
      language == 'ar' ? 'دواء الضغط' : 'Blood pressure pill',
    ),
    if (extraStates) ...[
      row(4, 10, 'snoozed', 'Snoozed reminder'),
      row(5, 7, 'missed', 'Earlier reminder'),
    ],
  ];
  Map<String, Object?> row(int i, int hour, String state, String title) => {
    'id': id(i),
    'reminder_id': p1.reminder,
    'title': title,
    'status': state,
    'type': i == 2 ? 'medication' : 'task',
    'scheduled_at': DateTime.utc(2026, 10, 15, hour).toIso8601String(),
    'updated_at': p1.now.subtract(const Duration(hours: 2)).toIso8601String(),
    'snoozed_until': state == 'snoozed'
        ? p1.now.add(const Duration(minutes: 5)).toIso8601String()
        : null,
    'completed_at': state == 'completed'
        ? DateTime.utc(2026, 10, 15, hour, 1).toIso8601String()
        : null,
    'confirmed_via': state == 'completed' ? 'voice' : null,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (!this.fail && o.path.endsWith('/reminder-logs')) {
      requests.add(o);
      return ResponseBody.fromString(
        jsonEncode(empty ? [] : logs),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    final response = await super.fetch(o, stream, cancel);
    if (o.path.endsWith('/sync') && !this.fail) {
      return ResponseBody.fromString(
        jsonEncode({
          'settings': {
            'full_name': 'Patient',
            'preferred_language': language,
            'timezone': zone,
            'memory_capture_enabled': true,
          },
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return response;
  }
}

/// Avoid native SQLite query-cancellation timers in widget-test fake time.
class Repository extends PatientTodayRepository {
  Repository(
    super.client,
    super.db,
    super.key,
    super.clock, {
    required super.current,
  });
  final updates = StreamController<PatientTodayData>.broadcast();
  @override
  Stream<PatientTodayData> watch() async* {
    yield await read();
    yield* updates.stream;
  }

  Future<void> changed() async {
    final data = await read();
    if (!updates.isClosed) updates.add(data);
  }

  @override
  Future<void> act(String id, {required bool snooze}) async {
    await super.act(id, snooze: snooze);
    await changed();
  }

  @override
  Future<void> refresh() async {
    await super.refresh();
    await changed();
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

class Controller extends PatientTodayController {
  Controller(super.key);
  Future<void>? action;
  int refreshes = 0;
  @override
  PatientTodayState build() => const PatientTodayState();
  @override
  Future<void> act(String id, {required bool snooze}) {
    action = super.act(id, snooze: snooze);
    return action!;
  }

  @override
  Future<void> refresh() {
    refreshes++;
    return super.refresh();
  }
}

final selectedScope = NotifierProvider<Scope, PatientTodayKey?>(Scope.new);

class Scope extends Notifier<PatientTodayKey?> {
  @override
  PatientTodayKey? build() => p1.key;
  void select(PatientTodayKey? key) => state = key;
}

void main() {
  late RemoriDatabase db;
  late Adapter adapter;
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
    adapter = Adapter();
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

  test('P2 exposes every cached occurrence chronologically, including completed/missed/snoozed', () async {
    adapter.extraStates = true;
    await repo.refresh();
    final data = await repo.read();
    expect(data.reminders.map((r) => r.id), [
      id(2),
      id(5),
      id(1),
      id(4),
      id(3),
    ]);
    expect(data.reminders.map((r) => r.status), [
      'completed',
      'missed',
      'pending',
      'snoozed',
      'pending',
    ]);
    expect(data.next?.id, id(1));
    expect(data.reminders.first.scheduledAt, DateTime.utc(2026, 10, 15, 6));
    expect(data.reminders[3].dueAt, p1.now.add(const Duration(minutes: 5)));
  });
  test(
    'Done changes list status and advances the next actionable card',
    () async {
      await repo.refresh();
      await repo.act(id(1), snooze: false);
      final data = await repo.read();
      expect(
        data.reminders.singleWhere((r) => r.id == id(1)).status,
        'completed',
      );
      expect(data.next?.id, id(3));
      adapter.fail = true;
      await expectLater(repo.upload(), throwsA(isA<Exception>()));
      expect((await db.pendingWrites(auth.patient)).single.recordId, id(1));
      adapter.fail = false;
      await repo.refresh();
      expect(
        (await repo.read()).reminders.singleWhere((r) => r.id == id(1)).status,
        'completed',
      );
    },
  );
  test('Later changes effective time without moving original chronological position', () async {
    await repo.refresh();
    await repo.act(id(1), snooze: true);
    final data = await repo.read();
    expect(data.reminders.map((r) => r.id), [id(2), id(1), id(3)]);
    final snoozed = data.reminders[1];
    expect(snoozed.status, 'snoozed');
    expect(snoozed.dueAt, p1.now.add(const Duration(minutes: 15)));
    expect(snoozed.scheduledAt, DateTime.utc(2026, 10, 15, 9));
    expect(data.next?.id, id(1));
  });
  test('completed, missed and non-next cards cannot enqueue actions', () async {
    adapter.extraStates = true;
    await repo.refresh();
    for (final i in [2, 3, 4, 5]) {
      await repo.act(id(i), snooze: false);
    }
    expect(await db.pendingWrites(auth.patient), isEmpty);
    expect((await repo.read()).next?.id, id(1));
  });
  test('today list is isolated by day and device', () async {
    await repo.refresh();
    final other = PatientTodayRepository(
      client,
      db,
      otherKey,
      () => clock,
      current: () => true,
    );
    expect((await other.read()).reminders, isEmpty);
    other.dispose();
    clock = clock.add(const Duration(days: 1));
    expect((await repo.read()).reminders, isEmpty);
  });
  test(
    'empty refresh removes old cards without deleting queued confirmations',
    () async {
      await repo.refresh();
      await repo.act(id(1), snooze: false);
      adapter.empty = true;
      await repo.refresh();
      expect((await repo.read()).reminders, isEmpty);
      expect(await db.pendingWrites(auth.patient), hasLength(1));
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
    bool seed = true,
    bool shell = false,
  }) async {
    adapter.language = language;
    if (seed) {
      await tester.runAsync(repo.refresh);
    }
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final container = ProviderContainer(
      overrides: [
        patientAlertCandidateProvider.overrideWithValue(null),
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith((ref) => ref.watch(selectedScope)),
        patientTodayRepositoryProvider(p1.key).overrideWithValue(repo),
        patientTodayControllerProvider(p1.key)
            .overrideWith(() => Controller(p1.key)),
        patientTodayDataProvider(otherKey)
            .overrideWith((ref) => Stream.value(const PatientTodayData())),
        patientTodayControllerProvider(otherKey)
            .overrideWith(() => Controller(otherKey)),
        patientTodayNowProvider.overrideWith((ref) => Stream.value(clock)),
        patientLinkProvider.overrideWith(
          (ref) => Stream.value(const PatientLinkStatus()),
        ),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const Key('p2-preview'),
          child: shell
              ? const RemoriApp()
              : MaterialApp(
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: RemoriTheme.forMode(
                    RemoriMode.patient,
                    arabic: language == 'ar',
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const Scaffold(body: P2RemindersScreen()),
                ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    if (shell) {
      container.read(remoriRouterProvider).goNamed(RemoriScreen.p2.name);
      await tester.pumpAndSettle();
    }
    return container;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'P2 shows actual cards with only one pair of actions and no editing',
    (tester) async {
      final container = await mount(tester);
      expect(find.text('Blood pressure pill'), findsOneWidget);
      expect(find.text('Drink water'), findsNWidgets(2));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(64),
      );
      expect(find.textContaining('9:00'), findsOneWidget);
      expect(find.textContaining('12:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester, container);
    },
  );
  for (final snooze in [false, true]) {
    testWidgets(
      'P2 tap persists ${snooze ? 'Later' : 'Done'} offline and stays on screen',
      (tester) async {
        final container = await mount(tester);
        adapter.fail = true;
        final controller = container.read(
          patientTodayControllerProvider(p1.key).notifier,
        ) as Controller;
        await tester.runAsync(() async {
          await tester.tap(
            snooze ? find.byType(OutlinedButton) : find.byType(FilledButton),
          );
          await controller.action;
        });
        await tester.pumpAndSettle();
        expect(find.byType(P2RemindersScreen), findsOneWidget);
        expect(
          find.text(
            'You can keep using your saved day. Updates will arrive when connected.',
          ),
          findsOneWidget,
        );
        final data = await tester.runAsync(repo.read);
        expect(
          data!.reminders.singleWhere((r) => r.id == id(1)).status,
          snooze ? 'snoozed' : 'completed',
        );
        final pending = await tester.runAsync(
          () => db.pendingWrites(auth.patient),
        );
        expect(pending, hasLength(1));
        expect(tester.takeException(), isNull);
        await unmount(tester, container);
      },
    );
  }
  testWidgets(
    'Retry uploads offline action and refreshes without duplicate confirmation',
    (tester) async {
      final container = await mount(tester);
      final controller = container.read(
        patientTodayControllerProvider(p1.key).notifier,
      ) as Controller;
      adapter.fail = true;
      await tester.runAsync(() => controller.act(id(1), snooze: false));
      await tester.pumpAndSettle();
      adapter.fail = false;
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.refreshes, 1);
      expect(
        await tester.runAsync(() => db.pendingWrites(auth.patient)),
        isEmpty,
      );
      expect(
        adapter.requests.where((o) => o.path.endsWith(':batch')),
        hasLength(2),
      );
      await unmount(tester, container);
    },
  );
  testWidgets(
    'device switch immediately hides previous reminder names and actions',
    (tester) async {
      final container = await mount(tester);
      container.read(selectedScope.notifier).select(otherKey);
      await tester.pumpAndSettle();
      expect(find.text('Blood pressure pill'), findsNothing);
      expect(find.text('Drink water'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      await unmount(tester, container);
    },
  );
  testWidgets('first load and empty day do not invent reminder data', (
    tester,
  ) async {
    final container = await mount(tester, seed: false);
    expect(find.text('Getting your day ready'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    adapter.empty = true;
    await tester.runAsync(repo.refresh);
    await tester.pumpAndSettle();
    expect(find.text('Your reminders will appear here'), findsOneWidget);
    expect(find.text('Drink water'), findsNothing);
    await unmount(tester, container);
  });
  testWidgets('missed and snoozed descriptions stay gentle', (tester) async {
    adapter.extraStates = true;
    final container = await mount(tester);
    expect(find.text('Time has passed'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Snoozed reminder'), 200);
    expect(find.text('Later'), findsWidgets);
    expect(find.textContaining('missed', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester, container);
  });
  testWidgets(
    'P2 tab and P1 Today share the local result; Phase 2 Ask stays disabled',
    (tester) async {
      final container = await mount(tester, shell: true);
      expect(find.byType(P2RemindersScreen), findsOneWidget);
      expect(
        tester
            .widget<RemoriNavigationBar>(find.byType(RemoriNavigationBar))
            .onAction,
        isNull,
      );
      final controller = container.read(
        patientTodayControllerProvider(p1.key).notifier,
      );
      adapter.fail = true;
      await tester.runAsync(() => controller.act(id(1), snooze: false));
      await tester.pumpAndSettle();
      container.read(remoriRouterProvider).goNamed(RemoriScreen.p1.name);
      await tester.pumpAndSettle();
      expect(find.byType(P1TodayScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      final data = await tester.runAsync(repo.read);
      expect(data!.next?.id, id(3));
      await unmount(tester, container);
    },
  );
  for (final language in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P2 $language at ${scale}x reference and accessible layout', (
        tester,
      ) async {
        final container = await mount(
          tester,
          language: language,
          scale: scale,
          shell: scale == 1,
        );
        expect(
          Directionality.of(tester.element(find.byType(P2RemindersScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        if (scale == 1 && autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('p2-preview')),
            matchesGoldenFile('goldens/p2_$language.png'),
          );
        }
        await tester.scrollUntilVisible(find.byType(FilledButton), 100);
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(64),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -1300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await unmount(tester, container);
      });
    }
  }
}
