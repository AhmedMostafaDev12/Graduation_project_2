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
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/mind_games/data/card_game_repository.dart';
import 'package:remori/features/mind_games/data/patient_games_repository.dart';
import 'package:remori/features/mind_games/domain/card_game.dart';
import 'package:remori/features/mind_games/presentation/card_game_providers.dart';
import 'package:remori/features/mind_games/presentation/p8_gameplay_screen.dart';
import 'package:remori/features/mind_games/presentation/p9_game_result_screen.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;
import 'p4_my_day_test.dart' as p4;

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  String? bad;
  int? postStatus;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (gate != null) await gate!.future;
    final post = options.method == 'POST';
    final p = post ? Map<String, dynamic>.from(options.data as Map) : null;
    final rows = [
      for (var i = 0; i < 2; i++)
        {
          'id': bad == 'duplicate' ? 'same' : 'person-$i',
          'patient_id': bad == 'patient' ? 'other' : auth.patient,
          'name': bad == 'name' ? '' : 'Person $i',
          'status': bad == 'status' ? 'archived' : 'active',
          'photo_url': bad == 'missingPhoto'
              ? null
              : bad == 'url'
              ? 'http://unsafe.test/a'
              : 'https://images.example.test/$i.jpg',
          'embeddings': ['PRIVATE'],
          'metadata': 'PRIVATE',
        },
    ];
    return ResponseBody.fromString(
      jsonEncode(
        post
            ? {...p!, 'patient_id': bad == 'receipt' ? 'other' : auth.patient}
            : rows,
      ),
      post ? postStatus ?? 201 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRepository extends CardGameRepository {
  FakeRepository(
    super.client,
    super.db,
    super.key,
    super.clock, {
    required super.current,
    required this.members,
  });
  List<GamePerson> members;
  final results = <String, GameSession>{};
  final changes = StreamController<GameSession?>.broadcast();
  int refreshes = 0, saves = 0, uploads = 0;
  bool fail = false, failSave = false;
  Completer<void>? gate;
  @override
  Future<void> refreshPeople() async {
    refreshes++;
    if (gate != null) await gate!.future;
    if (fail) throw ApiFailure(ApiFailureKind.network);
  }

  @override
  Future<List<GamePerson>> people() async => members;
  @override
  Future<bool> complete(GameSession value) async {
    saves++;
    if (failSave) throw StateError('Local save unavailable');
    results[value.id] = value;
    changes.add(value);
    return true;
  }

  @override
  Future<GameSession?> session(String id) async => results[id];
  @override
  Stream<GameSession?> watchSession(String id) async* {
    yield results[id];
    yield* changes.stream.map((_) => results[id]);
  }

  @override
  Future<void> upload() async {
    uploads++;
  }

  @override
  void dispose() {
    changes.close();
    super.dispose();
  }
}

class TestWatch implements Stopwatch {
  Duration time = Duration.zero;
  bool running = false;
  void advance(Duration duration) {
    if (running) time += duration;
  }

  @override
  Duration get elapsed => time;
  @override
  int get elapsedMilliseconds => time.inMilliseconds;
  @override
  int get elapsedMicroseconds => time.inMicroseconds;
  @override
  int get elapsedTicks => time.inMicroseconds;
  @override
  int get frequency => 1000000;
  @override
  bool get isRunning => running;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  @override
  void reset() {
    time = Duration.zero;
  }
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late CardGameRepository repo;
  late bool current;
  late Uint8List bytes;
  setUpAll(() async {
    bytes = await File('design/screens/images/ahmed.jpg').readAsBytes();
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
    repo = CardGameRepository(
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
  GameSession result() => GameSession(repo.newId(), 2, 80, p1.now);
  test(
    'four cards match without penalties and reject repeated or waiting taps',
    () {
      var round = CardRound([0, 1, 0, 1]);
      round = round.pick(0);
      expect(identical(round.pick(0), round), isTrue);
      round = round.pick(1);
      expect(round.waiting, isTrue);
      expect(identical(round.pick(2), round), isTrue);
      round = round.hideMismatch().pick(0).pick(2);
      expect(round.score, 1);
      expect(round.up(2), isTrue);
      round = round.pick(1).pick(3);
      expect(round.score, 2);
      expect(round.matched.length, 4);
    },
  );
  test(
    'fresh active-person metadata uses device auth and excludes private fields',
    () async {
      await repo.refreshPeople();
      expect((await repo.people()).length, 2);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer test-device',
      );
      expect(adapter.requests.single.queryParameters['status'], 'active');
      expect(
        (await repo.people()).first.validUntil,
        p1.now.add(const Duration(minutes: 10)),
      );
      expect(await db.pendingWrites(auth.patient), isEmpty);
    },
  );
  for (final bad in ['duplicate', 'patient', 'name', 'status', 'url']) {
    test(
      'invalid $bad people response cannot replace verified metadata',
      () async {
        await repo.refreshPeople();
        adapter.bad = bad;
        await expectLater(repo.refreshPeople(), throwsA(isA<ApiFailure>()));
        expect((await repo.people()).length, 2);
      },
    );
  }
  test('missing photos are not replaced by demo faces', () async {
    adapter.bad = 'missingPhoto';
    await repo.refreshPeople();
    expect(await repo.people(), isEmpty);
  });
  test(
    'scope change blocks late face metadata and other devices cannot read it',
    () async {
      adapter.gate = Completer<void>();
      final pending = repo.refreshPeople();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      current = false;
      adapter.gate!.complete();
      await pending;
      expect(await repo.people(), isEmpty);
      current = true;
      adapter.gate = null;
      await repo.refreshPeople();
      final other = CardGameRepository(
        client,
        db,
        p2.otherKey,
        () => p1.now,
        current: () => true,
      );
      expect(await other.people(), isEmpty);
      other.dispose();
    },
  );
  test(
    'completion and immutable outbox snapshot persist once with stable ID',
    () async {
      final value = result();
      expect(await repo.complete(value), isTrue);
      expect(await repo.complete(value), isTrue);
      expect((await repo.session(value.id))!.score, 2);
      expect(await db.pendingWrites(auth.patient), hasLength(1));
      expect(
        await repo.complete(GameSession(value.id, 0, 80, p1.now)),
        isFalse,
      );
      final scores = PatientGamesRepository(
        client,
        db,
        p1.key,
        () => p1.now,
        current: () => true,
      );
      expect((await scores.read()).scores['face_match']!.score, 2);
      scores.dispose();
    },
  );
  test(
    'upload retries same session ID and acknowledges only valid receipt',
    () async {
      final value = result();
      await repo.complete(value);
      adapter.postStatus = 503;
      await expectLater(repo.upload(), throwsA(isA<ApiFailure>()));
      expect(await db.pendingWrites(auth.patient), hasLength(1));
      adapter.postStatus = null;
      adapter.bad = 'receipt';
      await expectLater(repo.upload(), throwsA(isA<ApiFailure>()));
      expect(await db.pendingWrites(auth.patient), hasLength(1));
      adapter.bad = null;
      await repo.upload();
      expect(await db.pendingWrites(auth.patient), isEmpty);
      expect(
        adapter.requests.every(
          (r) =>
              r.data['id'] == value.id &&
              r.headers['Authorization'] == 'Bearer test-device',
        ),
        isTrue,
      );
    },
  );
  test('one device cannot upload or view another device results', () async {
    final value = result();
    await repo.complete(value);
    final other = CardGameRepository(
      client,
      db,
      p2.otherKey,
      () => p1.now,
      current: () => true,
    );
    expect(await other.session(value.id), isNull);
    await other.upload();
    expect(adapter.requests, isEmpty);
    expect(await db.pendingWrites(auth.patient), hasLength(1));
    other.dispose();
  });
  test('invalid results cannot enqueue', () async {
    final id = repo.newId();
    expect(await repo.complete(GameSession(id, 3, 80, p1.now)), isFalse);
    expect(await repo.complete(GameSession(id, 1, -1, p1.now)), isFalse);
    expect(await db.pendingWrites(auth.patient), isEmpty);
  });
  test('v20 migration preserves P7 score cache and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-p8-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      await db
          .into(db.patientGameScores)
          .insert(
            PatientGameScoresCompanion.insert(
              patientId: auth.patient,
              deviceId: auth.device,
              gameType: 'face_match',
              sessionId: 'old',
              score: 8,
              durationSeconds: 240,
              completedAt: p1.now,
            ),
          );
      await db.saveReminderLog(
        patientId: auth.patient,
        reminderId: p1.reminder,
        scheduledAt: p1.now,
        at: p1.now,
        status: ReminderStatus.pending,
      );
      await db.customStatement('DROP TABLE patient_game_people');
      await db.customStatement('DROP TABLE patient_game_sessions');
      await db.customStatement('PRAGMA user_version = 20');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect(await db.select(db.patientGamePeople).get(), isEmpty);
      expect(await db.select(db.patientGameSessions).get(), isEmpty);
      expect(await db.select(db.patientGameScores).get(), hasLength(1));
      expect(await db.pendingWrites(auth.patient), hasLength(1));
    } finally {
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
      final absolute = dir.absolute;
      if (absolute.parent.path == Directory.systemTemp.absolute.path &&
          absolute.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('remori-p8-migration-')) {
        await absolute.delete(recursive: true);
      }
    }
  });

  late FakeRepository fake;
  late p4.FakePreviews photos;
  late TestWatch watch;
  test(
    'a failed outbox insert rolls back the completed local result',
    () async {
      await db.customStatement(
        "CREATE TRIGGER fail_game_outbox BEFORE INSERT ON outbox_entries BEGIN SELECT RAISE(ABORT, 'unavailable'); END",
      );
      final value = result();
      await expectLater(repo.complete(value), throwsA(anything));
      expect(await repo.session(value.id), isNull);
      expect(await db.pendingWrites(auth.patient), isEmpty);
    },
  );
  test('a changed scope cannot acknowledge an in-flight upload', () async {
    final value = result();
    await repo.complete(value);
    adapter.gate = Completer<void>();
    final pending = repo.upload();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    current = false;
    adapter.gate!.complete();
    await pending;
    expect(await db.pendingWrites(auth.patient), hasLength(1));
  });
  test('photo decoder rejects corrupt image bytes', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(cardGameDecodeProvider)(bytes);
    await expectLater(
      c.read(cardGameDecodeProvider)(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
    bool offline = false,
    bool empty = false,
    int? photoStatus,
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
    watch = TestWatch();
    photos = p4.FakePreviews(bytes)..status = photoStatus;
    fake = FakeRepository(
      client,
      db,
      p1.key,
      () => p1.now,
      current: () => true,
      members: empty
          ? []
          : [
              GamePerson(
                'a',
                language == 'ar' ? 'أحمد' : 'Ahmed',
                'https://images.example.test/a.jpg',
                p1.now.add(const Duration(minutes: 10)),
              ),
              GamePerson(
                'b',
                language == 'ar' ? 'منى' : 'Mona',
                'https://images.example.test/b.jpg',
                p1.now.add(const Duration(minutes: 10)),
              ),
            ],
    )..fail = offline;
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith(
          (ref) => ref.watch(p2.selectedScope),
        ),
        patientTodayClockProvider.overrideWithValue(() => p1.now),
        patientAlertCandidateProvider.overrideWithValue(null),
        cardGameRepositoryProvider.overrideWith((ref, key) => fake),
        cardGamePhotosProvider.overrideWith((ref, key) {
          ref.onDispose(photos.dispose);
          return photos;
        }),
        cardGameDecodeProvider.overrideWithValue((_) async {}),
        cardGameStopwatchProvider.overrideWithValue(() => watch),
        cardGameDeckProvider.overrideWithValue(() => [0, 1, 0, 1]),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
        screenBuildersProvider.overrideWith(
          (ref) => {
            RemoriScreen.p1: (_, _) => const Text('Today destination'),
            RemoriScreen.p7: (_, _) => const Text('Games destination'),
            RemoriScreen.p8: (_, state) =>
                P8GameplayScreen(scope: state.extra as (String, String)?),
            RemoriScreen.p9: (_, state) =>
                P9GameResultScreen(target: state.extra as GameResultTarget?),
          },
        ),
      ],
    );
    addTearDown(() {
      c.dispose();
      fake.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const RepaintBoundary(
          key: Key('game-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    c.read(remoriRouterProvider).goNamed(RemoriScreen.p8.name, extra: p1.key);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, int index) async {
    await tester.tap(find.bySemanticsLabel('Card ${index + 1}, face down'));
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester, {String label = 'Done'}) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('an already loaded round can finish after connectivity is lost', (
    tester,
  ) async {
    final c = await mount(tester);
    fake.fail = true;
    await done(tester);
    expect(find.byType(P9GameResultScreen), findsOneWidget);
    expect(fake.results.length, 1);
    await unmount(tester, c);
  });
  testWidgets('a late refresh cannot restore faces after backgrounding', (
    tester,
  ) async {
    final c = await mount(tester);
    fake.gate = Completer<void>();
    final pending = c
        .read(cardGameControllerProvider(p1.key).notifier)
        .resume();
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    fake.gate!.complete();
    await pending;
    await tester.pumpAndSettle();
    expect(c.read(cardGameControllerProvider(p1.key)).photos, isEmpty);
    fake.fail = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('uncached result link cannot invent a result or start uploads', (
    tester,
  ) async {
    final c = await mount(tester);
    c
        .read(remoriRouterProvider)
        .goNamed(RemoriScreen.p9.name, extra: (scope: p1.key, id: 'missing'));
    await tester.pumpAndSettle();
    expect(
      find.text('This game result is not available right now.'),
      findsOneWidget,
    );
    expect(find.text('Play again'), findsNothing);
    expect(fake.uploads, 0);
    await unmount(tester, c);
  });

  testWidgets(
    'four-card matching, mismatch delay, Done and result use actual values',
    (tester) async {
      final c = await mount(tester);
      expect(c.read(cardGameControllerProvider(p1.key)).ready, isTrue);
      expect(photos.loads, 2);
      expect(find.byType(RemoriNavigationBar), findsNothing);
      await pick(tester, 0);
      await pick(tester, 1);
      expect(c.read(cardGameControllerProvider(p1.key)).round!.score, 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await pick(tester, 0);
      await pick(tester, 2);
      expect(c.read(cardGameControllerProvider(p1.key)).round!.score, 1);
      watch.advance(const Duration(seconds: 80));
      await tester.pump(const Duration(seconds: 1));
      await done(tester);
      expect(find.byType(P9GameResultScreen), findsOneWidget);
      expect(find.text('Score: 1 out of 2'), findsOneWidget);
      expect(find.text('Time: 01:20'), findsOneWidget);
      expect(fake.saves, 1);
      expect(fake.uploads, 1);
      expect(photos.clears, greaterThan(0));
      await unmount(tester, c);
    },
  );
  testWidgets(
    'offline cold start never fetches cached signed photos or saves a game',
    (tester) async {
      final c = await mount(tester, offline: true);
      expect(photos.loads, 0);
      expect(c.read(cardGameControllerProvider(p1.key)).ready, isFalse);
      expect(fake.saves, 0);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'fewer than two photos shows caregiver guidance without demo people',
    (tester) async {
      final c = await mount(tester, empty: true);
      expect(find.textContaining('Ask your caregiver'), findsOneWidget);
      expect(photos.loads, 0);
      await unmount(tester, c);
    },
  );
  testWidgets('Back discards unfinished game without a write', (tester) async {
    final c = await mount(tester);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Games destination'), findsOneWidget);
    expect(fake.saves, 0);
    await unmount(tester, c);
  });
  testWidgets(
    'failed local save stays on P8 and retry keeps session ID and score',
    (tester) async {
      final c = await mount(tester);
      fake.failSave = true;
      await done(tester);
      expect(find.byType(P8GameplayScreen), findsOneWidget);
      expect(find.textContaining('couldn’t save'), findsOneWidget);
      fake.failSave = false;
      await done(tester, label: 'Retry');
      expect(fake.saves, 2);
      expect(fake.results.length, 1);
      expect(find.byType(P9GameResultScreen), findsOneWidget);
      await unmount(tester, c);
    },
  );
  testWidgets('background clears photos and excludes background time', (
    tester,
  ) async {
    final c = await mount(tester);
    watch.advance(const Duration(seconds: 20));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(c.read(cardGameControllerProvider(p1.key)).photos, isEmpty);
    watch.advance(const Duration(minutes: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(fake.refreshes, 2);
    expect(watch.elapsed.inSeconds, 20);
    await done(tester);
    expect(find.text('Time: 00:20'), findsOneWidget);
    await unmount(tester, c);
  });
  testWidgets('expired photos clear and disable card actions until refreshed', (
    tester,
  ) async {
    final c = await mount(tester);
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();
    expect(c.read(cardGameControllerProvider(p1.key)).photos, isEmpty);
    expect(c.read(cardGameControllerProvider(p1.key)).ready, isFalse);
    await unmount(tester, c);
  });
  testWidgets('403 recovery is bounded and never starts with failed photos', (
    tester,
  ) async {
    final c = await mount(tester, photoStatus: 403);
    expect(fake.refreshes, 2);
    expect(c.read(cardGameControllerProvider(p1.key)).ready, isFalse);
    await unmount(tester, c);
  });
  testWidgets('device change hides old faces and cannot save previous round', (
    tester,
  ) async {
    final c = await mount(tester);
    await pick(tester, 0);
    c.read(p2.selectedScope.notifier).select(p2.otherKey);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(
      await c.read(cardGameControllerProvider(p1.key).notifier).finish(),
      isNull,
    );
    expect(fake.saves, 0);
    await unmount(tester, c);
  });
  testWidgets('Play again creates fresh game and Back to games exits result', (
    tester,
  ) async {
    final c = await mount(tester);
    await done(tester);
    final id = fake.results.keys.single;
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    await done(tester);
    expect(fake.results.length, 2);
    expect(fake.results.keys.last, isNot(id));
    await tester.tap(find.text('Back to games'));
    await tester.pumpAndSettle();
    expect(find.text('Games destination'), findsOneWidget);
    await unmount(tester, c);
  });
  for (final lang in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P8 and P9 $lang at ${scale}x stay readable and scrollable', (
        tester,
      ) async {
        final c = await mount(tester, language: lang, scale: scale);
        c.read(cardGameControllerProvider(p1.key).notifier).pick(0);
        c.read(cardGameControllerProvider(p1.key).notifier).pick(2);
        watch.advance(const Duration(seconds: 80));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(
            MemoryImage(bytes),
            tester.element(find.byType(P8GameplayScreen)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('game-preview')),
            matchesGoldenFile('goldens/p8_${lang}_${scale}x.png'),
          );
        }
        await done(tester, label: lang == 'ar' ? 'خلصت' : 'Done');
        expect(find.byType(P9GameResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('game-preview')),
            matchesGoldenFile('goldens/p9_${lang}_${scale}x.png'),
          );
        }
        await tester.ensureVisible(
          find.text(lang == 'ar' ? 'رجوع للألعاب' : 'Back to games'),
        );
        expect(tester.takeException(), isNull);
        await unmount(tester, c);
      });
    }
  }
}
