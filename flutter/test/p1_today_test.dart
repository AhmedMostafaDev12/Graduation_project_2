import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/patient_session_provider.dart';
import 'package:remori/core/relay/glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/core/relay/glasses_message.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/app_localizations.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/core/theme/remori_widgets.dart';
import 'package:remori/features/patient_today/data/patient_today_repository.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/p1_today_screen.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';

import 'a6_handover_test.dart' as auth;

const patient = auth.patient;
const key = (patient, auth.device);
const logId = '00000005-0000-4000-8000-000000000001';
const reminder = '00000006-0000-4000-8000-000000000001';
final now = DateTime.utc(2026, 10, 15, 12);

class StaticController extends PatientTodayController {
  StaticController(super.key);
  @override
  PatientTodayState build() => const PatientTodayState();
}

class Session extends PatientSession {
  @override
  PatientSessionState build() {
    restoration = Future.value();
    return const PatientSessionState(context: auth.contextFixture);
  }
}

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool fail = false, reject = false, badReceipt = false, wrongDay = false;
  String status = 'pending', zone = 'Africa/Cairo';
  Completer<void>? gate;
  Completer<void>? posted;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    if (fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    Object body;
    if (o.path.endsWith('/sync')) {
      body = {
        'settings': {
          'full_name': 'Patient',
          'preferred_language': 'en',
          'timezone': zone,
          'memory_capture_enabled': true,
        },
        'people': {
          'upserts': [
            {'embedding': 'PRIVATE'},
          ],
        },
        'server_time': now.toIso8601String(),
      };
    } else if (o.path.endsWith(':batch')) {
      posted?.complete();
      await gate?.future;
      body = {
        'accepted': reject ? [] : [badReceipt ? 'foreign' : logId],
        'duplicates': [],
        'rejected': reject ? [logId] : [],
      };
    } else if (o.path.endsWith('/reminder-logs')) {
      body = [
        {
          'id': logId,
          'reminder_id': reminder,
          'title': 'Medicine',
          'type': 'medication',
          'status': status,
          'scheduled_at': now
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'updated_at': now
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'snoozed_until': null,
          'completed_at': null,
          'confirmed_via': null,
        },
      ];
    } else {
      body = {
        'date': wrongDay ? '2026-10-14' : '2026-10-15',
        'timezone': zone,
        'entries': [
          for (final i in [3, 1, 2, 1, 4])
            {
              'event_type': 'encounter',
              'occurred_at': now
                  .subtract(Duration(minutes: 10 - i))
                  .toIso8601String(),
              'person': {'id': 'person-$i', 'name': 'Person $i'},
              'private_extra': 'PRIVATE',
            },
          {'event_type': 'encounter', 'person': null},
          {'event_type': 'audio', 'transcript': 'PRIVATE'},
        ],
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  late RemoriDatabase db;
  late Adapter adapter;
  late ApiClient client;
  late PatientTodayRepository repo;
  late DateTime clock;
  late bool current;
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
    clock = now;
    current = true;
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      onCredentialsInvalidated: (_) {},
      adapter: adapter,
    );
    repo = PatientTodayRepository(
      client,
      db,
      key,
      () => clock,
      current: () => current,
    );
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });

  test('device-only refresh stores allowlisted data and three distinct known people', () async {
    await repo.refresh();
    final data = await repo.read();
    expect(data.settings?.language, 'en');
    expect(data.next?.title, 'Medicine');
    expect(data.people.map((p) => p.id), ['person-1', 'person-2', 'person-3']);
    expect(adapter.requests, hasLength(3));
    expect(
      adapter.requests.every(
        (o) => o.headers['Authorization'] == 'Bearer test-device',
      ),
      isTrue,
    );
    expect(adapter.requests.first.queryParameters, isEmpty);
    expect(await db.pendingWrites(patient), isEmpty);
    expect(
      (await db.select(db.patientTodaySettings).get()).single.fullName,
      'Patient',
    );
  });
  test('other device has no access to this device cache', () async {
    await repo.refresh();
    final other = PatientTodayRepository(
      client,
      db,
      (patient, 'other-device'),
      () => clock,
      current: () => true,
    );
    addTearDown(other.dispose);
    expect((await other.read()).settings, isNull);
    expect((await other.read()).people, isEmpty);
  });
  test('invalid day rolls back the complete refresh', () async {
    adapter.wrongDay = true;
    await expectLater(repo.refresh(), throwsA(isA<Exception>()));
    expect((await repo.read()).settings, isNull);
    expect(await db.select(db.reminderLogs).get(), isEmpty);
  });
  test('invalid timezone does not persist settings', () async {
    adapter.zone = 'Invalid/Zone';
    await expectLater(repo.refresh(), throwsA(isA<Exception>()));
    expect((await repo.read()).settings, isNull);
  });
  test('inactive scope neither fetches nor modifies data', () async {
    current = false;
    await repo.refresh();
    await repo.act(logId, snooze: false);
    await repo.upload();
    expect(adapter.requests, isEmpty);
    expect(await db.pendingWrites(patient), isEmpty);
  });
  test(
    'Done is local and durable offline; remote pending cannot undo completion',
    () async {
      await repo.refresh();
      adapter.fail = true;
      await repo.act(logId, snooze: false);
      expect((await repo.read()).next, isNull);
      expect(
        (await db.pendingWrites(patient)).single.kind,
        OutboxKind.reminderLog,
      );
      await expectLater(repo.upload(), throwsA(isA<Exception>()));
      expect(await db.pendingWrites(patient), hasLength(1));
      adapter.fail = false;
      await repo.refresh();
      expect((await repo.read()).next, isNull);
      await repo.upload();
      expect(await db.pendingWrites(patient), isEmpty);
    },
  );
  test(
    'Later uses exactly fifteen minutes and uploads actual occurrence ID',
    () async {
      await repo.refresh();
      await repo.act(logId, snooze: true);
      expect(
        (await repo.read()).next?.dueAt,
        now.add(const Duration(minutes: 15)),
      );
      await repo.upload();
      final logs = (adapter.requests.last.data as Map)['logs'] as List;
      expect(logs.single['id'], logId);
      expect(logs.single['status'], 'snoozed');
      expect(logs.single['confirmed_via'], 'app');
      expect(await db.pendingWrites(patient), isEmpty);
    },
  );
  for (final malformed in [false, true]) {
    test('rejected or malformed batch retains outbox ($malformed)', () async {
      await repo.refresh();
      await repo.act(logId, snooze: true);
      adapter.reject = !malformed;
      adapter.badReceipt = malformed;
      if (malformed) {
        await expectLater(repo.upload(), throwsA(isA<Exception>()));
      } else {
        await repo.upload();
      }
      expect(await db.pendingWrites(patient), hasLength(1));
    });
  }
  test('an old receipt acknowledges captured operations only', () async {
    await repo.refresh();
    await repo.act(logId, snooze: true);
    adapter.gate = Completer();
    adapter.posted = Completer();
    final upload = repo.upload();
    await adapter.posted!.future;
    clock = now.add(const Duration(minutes: 1));
    await repo.act(logId, snooze: false);
    adapter.gate!.complete();
    await upload;
    final writes = await db.pendingWrites(patient);
    expect(writes, hasLength(1));
    expect(jsonDecode(writes.single.payload)['status'], 'completed');
  });
  test('cached yesterday is not displayed as today', () async {
    await repo.refresh();
    clock = now.add(const Duration(days: 1));
    expect((await repo.read()).people, isEmpty);
    expect((await repo.read()).next, isNull);
  });

  test(
    'uploader leaves unrelated occurrences and outbox kinds untouched',
    () async {
      await repo.refresh();
      await repo.act(logId, snooze: true);
      await db.saveReminderLog(
        id: '00000005-0000-4000-8000-000000000002',
        patientId: patient,
        reminderId: reminder,
        scheduledAt: now,
        status: ReminderStatus.completed,
        at: now,
        completedAt: now,
      );
      await db.writeAndEnqueue(
        patientId: patient,
        kind: OutboxKind.event,
        payload: {'id': '00000008-0000-4000-8000-000000000001'},
        writeLocal: () async {},
      );
      await repo.upload();
      final logs = (adapter.requests.last.data as Map)['logs'] as List;
      expect(logs, hasLength(1));
      expect(logs.single['id'], logId);
      final remaining = await db.pendingWrites(patient);
      expect(remaining, hasLength(2));
      expect(remaining.any((r) => r.kind == OutboxKind.event), isTrue);
    },
  );

  testWidgets(
    'matching Hello is required and stale telemetry clears memory status',
    (tester) async {
      final glasses = auth.ControlledGlasses();
      final container = ProviderContainer(
        overrides: [
          patientSessionProvider.overrideWith(Session.new),
          glassesConnectionProvider.overrideWithValue(glasses),
        ],
      );
      final sub = container.listen(patientLinkProvider, (_, _) {});
      await tester.pump();
      glasses.change(GlassesConnectionState.connected);
      await tester.pump();
      expect(container.read(patientLinkProvider).value?.connected, isFalse);
      glasses.incoming.add(
        const Hello(
          deviceSerial: auth.serial,
          firmwareVersion: '1',
          protocolVersion: 1,
          queue: GlassesQueue(events: 0, audioSegments: 0, media: 0),
        ),
      );
      await tester.pump();
      expect(container.read(patientLinkProvider).value?.connected, isTrue);
      glasses.incoming.add(
        const Telemetry(
          batteryPct: 80,
          tempC: 30,
          memoryPaused: false,
          storageFreeMb: 200,
        ),
      );
      await tester.pump();
      expect(container.read(patientLinkProvider).value?.paused, isFalse);
      await tester.pump(const Duration(seconds: 91));
      expect(container.read(patientLinkProvider).value?.paused, isNull);
      glasses.change(GlassesConnectionState.disconnected);
      await tester.pump();
      expect(container.read(patientLinkProvider).value?.connected, isFalse);
      sub.close();
      container.dispose();
      glasses.dispose();
      await tester.pump();
    },
  );

  for (final locale in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'P1 $locale at $scale text scale stays readable with disabled Ask',
        (tester) async {
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = ProviderContainer(
            overrides: [
              patientTodayKeyProvider.overrideWithValue(key),
              patientTodayControllerProvider(key)
                  .overrideWith(() => StaticController(key)),
              patientTodayDataProvider(key).overrideWith(
                (ref) => Stream.value(
                  PatientTodayData(
                    settings: PatientSettings(
                      'Patient',
                      locale,
                      'Africa/Cairo',
                      true,
                    ),
                    next: PatientReminder(logId, 'Medicine', now),
                    people: const [
                      MetPerson('1', 'Mona Ali'),
                      MetPerson('2', 'Omar'),
                      MetPerson('3', 'Ahmed'),
                    ],
                  ),
                ),
              ),
              patientTodayNowProvider.overrideWith((ref) => Stream.value(now)),
              patientLinkProvider.overrideWith(
                (ref) => Stream.value(const PatientLinkStatus()),
              ),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: RemoriTheme.forMode(
                  RemoriMode.patient,
                  arabic: locale == 'ar',
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const RepaintBoundary(
                  key: Key('p1-preview'),
                  child: Scaffold(body: P1TodayScreen()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('d5-disconnected')), findsOneWidget);
          final retry = find.text(locale == 'en' ? 'Try again' : 'حاول تاني');
          expect(retry, findsOneWidget);
          expect(
            tester
                .getSize(
                  find.ancestor(of: retry, matching: find.byType(RemoriButton)),
                )
                .height,
            greaterThanOrEqualTo(64),
          );
          if (autoUpdateGoldenFiles) {
            await expectLater(
              find.byKey(const Key('p1-preview')),
              matchesGoldenFile(
                scale == 1
                    ? 'goldens/p1_$locale.png'
                    : 'goldens/d5_${locale}_2x.png',
              ),
            );
          }
          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsNothing);
          await tester.scrollUntilVisible(
            find.text(
              AppLocalizations.of(tester.element(find.byType(P1TodayScreen)))
                  .todayAskLater,
            ),
            200,
          );
          final button = find.ancestor(
            of: find.text(
              AppLocalizations.of(tester.element(find.byType(P1TodayScreen)))
                  .todayAskLater,
            ),
            matching: find.byType(OutlinedButton),
          );
          expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(64));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
