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
import 'package:remori/core/db/remori_database.dart' hide PatientGameScore;
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/mind_games/data/patient_games_repository.dart';
import 'package:remori/features/mind_games/domain/patient_games_data.dart';
import 'package:remori/features/mind_games/presentation/p7_games_screen.dart';
import 'package:remori/features/mind_games/presentation/patient_games_providers.dart';
import 'package:remori/features/mind_games/presentation/card_game_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;

PatientGamesData fixture({bool empty = false}) => PatientGamesData(
  refreshed: patientGameTypes.toSet(),
  scores: {
    if (!empty)
      for (var i = 0; i < 3; i++)
        patientGameTypes[i]: PatientGameScore(
          'session-$i',
          patientGameTypes[i],
          [8, 6, 5][i],
          240,
          p1.now,
        ),
  },
);

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  String? invalid, failType;
  bool empty = false;
  int score = 8;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (gate != null) await gate!.future;
    final type = options.queryParameters['game_type'];
    final row = {
      'id': invalid == 'id' ? '' : 'session-$type',
      'patient_id': invalid == 'patient' ? 'other' : auth.patient,
      'game_type': invalid == 'type' ? 'unknown' : type,
      'score': invalid == 'score' ? -1 : score,
      'duration_seconds': invalid == 'duration' ? 14401 : 240,
      'completed_at': invalid == 'time'
          ? '2026-10-15T12:00:00'
          : p1.now.toIso8601String(),
      'metadata': 'PRIVATE',
    };
    return ResponseBody.fromString(
      jsonEncode(empty ? [] : [row, if (invalid == 'multiple') row]),
      failType == type ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRepository extends PatientGamesRepository {
  FakeRepository(
    super.client,
    super.db,
    super.key,
    super.clock, {
    required super.current,
    required this.data,
  });
  PatientGamesData data;
  bool fail = false;
  int refreshes = 0;
  final changes = StreamController<PatientGamesData>.broadcast();
  @override
  Future<void> refresh() async {
    refreshes++;
    if (fail) throw ApiFailure(ApiFailureKind.network);
    if (!changes.isClosed) changes.add(data);
  }

  @override
  Stream<PatientGamesData> watch() async* {
    yield data;
    yield* changes.stream;
  }

  @override
  Future<PatientGamesData> read() async => data;
  @override
  void dispose() {
    changes.close();
    super.dispose();
  }
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late PatientGamesRepository repo;
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
    current = true;
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = Adapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      onCredentialsInvalidated: (_) {},
      adapter: adapter,
    );
    repo = PatientGamesRepository(
      client,
      db,
      p1.key,
      () => p1.now,
      current: () => current,
    );
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });
  test('three filtered device GETs cache latest scores without raw metadata or writes', () async {
    await repo.refresh();
    expect(
      adapter.requests.map((r) => r.queryParameters['game_type']),
      patientGameTypes,
    );
    for (final r in adapter.requests) {
      expect(r.headers['Authorization'], 'Bearer test-device');
      expect(r.queryParameters['limit'], 1);
      expect(r.queryParameters['offset'], 0);
    }
    final data = await repo.read();
    expect(data.scores.length, 3);
    expect(data.refreshed, patientGameTypes.toSet());
    expect(data.scores['face_match']!.score, 8);
    expect(await db.pendingWrites(auth.patient), isEmpty);
    expect(
      (await db.select(db.patientGameScores).get())
          .singleWhere((r) => r.gameType == 'face_match')
          .completedAt,
      p1.now,
    );
  });
  for (final invalid in [
    'id',
    'patient',
    'type',
    'score',
    'duration',
    'time',
    'multiple',
  ]) {
    test(
      'invalid $invalid response leaves previous scores unchanged',
      () async {
        await repo.refresh();
        adapter.invalid = invalid;
        adapter.score = 10;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect(
          (await repo.read()).scores.values.every((s) => s.score == 8),
          isTrue,
        );
      },
    );
  }
  test(
    'empty success clears stale scores and records verified empty state',
    () async {
      await repo.refresh();
      adapter.empty = true;
      await repo.refresh();
      expect((await repo.read()).scores, isEmpty);
      expect((await repo.read()).refreshed.length, 3);
    },
  );
  test(
    'failure of a later game preserves all previous scores atomically',
    () async {
      await repo.refresh();
      adapter.score = 10;
      adapter.failType = 'word_recall';
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(
        (await repo.read()).scores.values.every((s) => s.score == 8),
        isTrue,
      );
    },
  );
  test('device and patient scopes cannot read another scope scores', () async {
    await repo.refresh();
    for (final key in [p2.otherKey, ('other-patient', p1.key.$2)]) {
      final other = PatientGamesRepository(
        client,
        db,
        key,
        () => p1.now,
        current: () => true,
      );
      expect((await other.read()).scores, isEmpty);
      expect((await other.read()).refreshed, isEmpty);
      other.dispose();
    }
  });
  test(
    'late response after leaving scope does not write or request other games',
    () async {
      adapter.gate = Completer<void>();
      final pending = repo.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      current = false;
      adapter.gate!.complete();
      await pending;
      expect((await repo.read()).scores, isEmpty);
      expect(adapter.requests, hasLength(1));
    },
  );
  test('offline reads use cached scores without further requests', () async {
    await repo.refresh();
    final count = adapter.requests.length;
    expect((await repo.read()).scores.length, 3);
    expect(adapter.requests.length, count);
  });
  test('v19 migration preserves patient cache and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-p7-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      await db
          .into(db.patientTodaySettings)
          .insert(
            PatientTodaySettingsCompanion.insert(
              patientId: auth.patient,
              deviceId: auth.device,
              fullName: 'Patient',
              language: 'ar',
              timezone: 'Africa/Cairo',
              memoryEnabled: true,
              refreshedAt: p1.now,
            ),
          );
      await db.saveReminderLog(
        patientId: auth.patient,
        reminderId: p1.reminder,
        scheduledAt: p1.now,
        at: p1.now,
        status: ReminderStatus.pending,
      );
      await db.customStatement('DROP TABLE patient_game_scores');
      await db.customStatement('DROP TABLE patient_game_refreshes');
      await db.customStatement('DROP TABLE patient_game_people');
      await db.customStatement('DROP TABLE patient_game_sessions');
      await db.customStatement('PRAGMA user_version = 19');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect(await db.select(db.patientGameScores).get(), isEmpty);
      expect(await db.select(db.patientGameRefreshes).get(), isEmpty);
      expect(await db.select(db.patientTodaySettings).get(), hasLength(1));
      expect(await db.pendingWrites(auth.patient), hasLength(1));
    } finally {
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
      final absolute = dir.absolute;
      if (absolute.parent.path == Directory.systemTemp.absolute.path &&
          absolute.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('remori-p7-migration-')) {
        await absolute.delete(recursive: true);
      }
    }
  });

  late Map<(String, String), FakeRepository> fakes;
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
    bool offline = false,
    bool empty = false,
    bool unrefreshed = false,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    fakes = {};
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith(
          (ref) => ref.watch(p2.selectedScope),
        ),
        patientAlertCandidateProvider.overrideWithValue(null),
        cardGameUploadProvider.overrideWith((ref, key) => () async {}),
        patientGamesRepositoryProvider.overrideWith((ref, key) {
          final fake = FakeRepository(
            client,
            db,
            key,
            () => p1.now,
            current: () => true,
            data: key != p1.key || unrefreshed
                ? const PatientGamesData()
                : fixture(empty: empty),
          )..fail = offline;
          fakes[key] = fake;
          ref.onDispose(fake.dispose);
          return fake;
        }),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
        screenBuildersProvider.overrideWith(
          (ref) => {
            RemoriScreen.p1: (_, _) => const Text('Today destination'),
            RemoriScreen.p7: (_, _) => const P7GamesScreen(),
            RemoriScreen.p8: (_, _) => const Text('Card game destination'),
          },
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const RepaintBoundary(
          key: Key('p7-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    c.read(remoriRouterProvider).goNamed(RemoriScreen.p7.name);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  testWidgets('P7 shows actual scores, enabled Card game and disabled Ask', (
    tester,
  ) async {
    final c = await mount(tester);
    for (final score in [8, 6, 5]) {
      expect(find.text('Last score: $score'), findsOneWidget);
    }
    expect(find.textContaining('of 10'), findsNothing);
    expect(find.text('Card game'), findsOneWidget);
    expect(
      tester
          .widget<RemoriNavigationBar>(find.byType(RemoriNavigationBar))
          .onAction,
      isNull,
    );
    await tester.tap(find.text('Card game'));
    await tester.pumpAndSettle();
    expect(find.text('Card game destination'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('verified empty results do not invent scores', (tester) async {
    final c = await mount(tester, empty: true);
    expect(find.text('No games yet'), findsNWidgets(3));
    expect(find.textContaining('Last score:'), findsNothing);
    await unmount(tester, c);
  });
  testWidgets(
    'unrefreshed offline scores show unavailable rather than no games',
    (tester) async {
      final c = await mount(tester, offline: true, unrefreshed: true);
      expect(find.text('Last score is not available yet'), findsNWidgets(3));
      expect(find.text('No games yet'), findsNothing);
      await unmount(tester, c);
    },
  );
  testWidgets('offline keeps actual cached scores and Retry refreshes', (
    tester,
  ) async {
    final c = await mount(tester, offline: true);
    expect(find.text('Last score: 8'), findsOneWidget);
    final fake = fakes[p1.key]!;
    fake.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(fake.refreshes, 2);
    expect(find.text('Retry'), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('changing device immediately hides old scores', (tester) async {
    final c = await mount(tester);
    c.read(p2.selectedScope.notifier).select(p2.otherKey);
    await tester.pumpAndSettle();
    expect(find.textContaining('Last score:'), findsNothing);
    expect(find.text('Last score is not available yet'), findsNWidgets(3));
    await unmount(tester, c);
  });
  testWidgets('resume refreshes latest scores', (tester) async {
    final c = await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(fakes[p1.key]!.refreshes, 2);
    await unmount(tester, c);
  });
  for (final language in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P7 $language at ${scale}x is accessible and scrollable', (
        tester,
      ) async {
        final c = await mount(tester, language: language, scale: scale);
        expect(
          Directionality.of(tester.element(find.byType(P7GamesScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('p7-preview')),
            matchesGoldenFile('goldens/p7_${language}_${scale}x.png'),
          );
        }
        for (final type in patientGameTypes) {
          final card = find.byKey(ValueKey('patient-game-$type'));
          await tester.scrollUntilVisible(card, 200);
          expect(tester.getSize(card).height, greaterThanOrEqualTo(64));
        }
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await unmount(tester, c);
      });
    }
  }
}
