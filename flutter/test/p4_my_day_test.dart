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
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';
import 'package:remori/features/patient_journal/data/patient_journal_repository.dart';
import 'package:remori/features/patient_journal/data/patient_journal_previews.dart';
import 'package:remori/features/patient_journal/domain/patient_journal_data.dart';
import 'package:remori/features/patient_journal/presentation/patient_journal_providers.dart';
import 'package:remori/features/patient_journal/presentation/p4_my_day_screen.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;
import 'c6_unknown_faces_test.dart' as c6;
import 'c12_journal_test.dart' as c12;

const today = (p1.key, '2026-10-15', 'Africa/Cairo');
const yesterday = (p1.key, '2026-10-14', 'Africa/Cairo');
final photo = JournalMedia(
  id: 'photo',
  type: 'image',
  trigger: '',
  status: 'confirmed',
  url: 'https://images.example.test/full.jpg',
  thumbnailUrl: 'https://images.example.test/thumb.jpg',
  expiresAt: p1.now.add(const Duration(hours: 1)),
);

PatientJournalData fixture(
  PatientJournalKey key, {
  String language = 'en',
  DateTime? expiry,
}) => PatientJournalData(
  refreshedAt: p1.now,
  entries: [
    JournalEntry(
      id: 'met',
      type: 'encounter',
      source: '',
      occurredAt: DateTime.parse('${key.$2}T06:15:00Z'),
      person: JournalPerson(
        'person',
        language == 'ar' ? 'أحمد' : 'Ahmed',
        'son',
      ),
    ),
    JournalEntry(
      id: 'talk',
      type: 'conversation_segment',
      source: '',
      occurredAt: DateTime.parse('${key.$2}T06:30:00Z'),
      renderedText: language == 'ar'
          ? 'اتكلمت عن ميعاد الدكتور'
          : 'You talked about a doctor visit',
    ),
    JournalEntry(
      id: 'reminder',
      type: 'reminder',
      source: '',
      occurredAt: DateTime.parse('${key.$2}T07:00:00Z'),
    ),
    JournalEntry(
      id: 'recording',
      type: 'user_requested_recording',
      source: '',
      occurredAt: DateTime.parse('${key.$2}T08:30:00Z'),
      media: [
        JournalMedia(
          id: photo.id,
          type: photo.type,
          trigger: '',
          status: photo.status,
          url: photo.url,
          thumbnailUrl: photo.thumbnailUrl,
          expiresAt: expiry ?? photo.expiresAt,
        ),
      ],
    ),
  ],
);

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool fail = false, empty = false;
  String? bad;
  Completer<void>? gate, entered;
  Map<String, Object?> body(String day) => {
    'date': bad == 'day' ? '2020-01-01' : day,
    'timezone': bad == 'timezone' ? 'UTC' : 'Africa/Cairo',
    'entries': [
      if (!empty)
        for (final i in [3, 1, 2, 0])
          {
            'id': bad == 'duplicate' ? 'same' : 'event-$i',
            'patient_id': bad == 'patient' ? 'other' : auth.patient,
            'event_type': [
              'encounter',
              'conversation_segment',
              'reminder',
              'user_requested_recording',
            ][i],
            'occurred_at': '${day}T0${6 + i}:00:00Z',
            'person': i == 0
                ? {
                    'id': 'person',
                    'name': 'Ahmed',
                    'relationship': 'son',
                    'embedding': 'PRIVATE',
                  }
                : null,
            'rendered_text': i == 1 ? 'An actual server description' : null,
            'transcript_text': 'PRIVATE',
            'metadata': {'embedding': 'PRIVATE'},
            'audio_bytes': 'PRIVATE',
            'media': [
              if (i == 3)
                {
                  'id': 'photo',
                  'asset_type': 'image',
                  'status': 'confirmed',
                  'url': bad == 'url'
                      ? 'http://unsafe.example.test/image'
                      : photo.url,
                  'thumbnail_url': photo.thumbnailUrl,
                  'expires_at': photo.expiresAt!.toIso8601String(),
                  'image_bytes': 'PRIVATE',
                  'ai_tags': {'raw': 'PRIVATE'},
                },
            ],
          },
    ],
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    if (entered?.isCompleted == false) entered!.complete();
    if (gate != null) await gate!.future;
    if (fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body(o.queryParameters['date'] as String)),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRepository extends PatientJournalRepository {
  FakeRepository(
    super.client,
    super.db,
    super.key,
    super.clock, {
    required super.current,
    required this.data,
  });
  PatientJournalData data;
  PatientJournalData? emitted;
  bool fail = false;
  int refreshes = 0;
  Completer<void>? gate;
  final updates = StreamController<PatientJournalData>.broadcast();
  @override
  Future<void> refresh() async {
    refreshes++;
    if (gate != null) await gate!.future;
    if (fail) throw ApiFailure(ApiFailureKind.network);
    if (!updates.isClosed) updates.add(emitted ?? data);
  }

  @override
  Stream<PatientJournalData> watch() async* {
    yield emitted ?? data;
    yield* updates.stream;
  }

  @override
  Future<PatientJournalData> read() async => data;
  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

class FakePreviews implements PatientJournalPreviews {
  FakePreviews(this.bytes);
  final Uint8List bytes;
  int loads = 0, clears = 0, expires = 0;
  int? status;
  final pending = <String, Future<Uint8List>>{};
  @override
  Future<Uint8List> load(JournalMedia media) =>
      pending.putIfAbsent(media.id, () {
        loads++;
        return status == null
            ? Future.value(bytes)
            : Future.error(PatientJournalPreviewFailure(status));
      });
  @override
  void expire(DateTime now) {
    expires++;
    PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
    pending.clear();
  }

  @override
  void clear() {
    clears++;
    pending.clear();
    PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
  }

  @override
  void dispose() => clear();
}

final testNowProvider = NotifierProvider<TestNow, DateTime>(TestNow.new);

class TestNow extends Notifier<DateTime> {
  @override
  DateTime build() => p1.now;
  void put(DateTime now) => state = now;
}

void main() {
  late RemoriDatabase db;
  late Adapter adapter;
  late ApiClient client;
  late PatientJournalRepository repo;
  late Uint8List bytes;
  late bool current;
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
    repo = PatientJournalRepository(
      client,
      db,
      today,
      () => p1.now,
      current: () => current,
    );
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });
  test(
    'device journal caches only allowlisted fields in chronological order',
    () async {
      await repo.refresh();
      final data = await repo.read();
      expect(data.entries.map((e) => e.id), [
        'event-0',
        'event-1',
        'event-2',
        'event-3',
      ]);
      expect(data.entries[1].renderedText, 'An actual server description');
      expect(data.entries.every((e) => e.transcript == null), isTrue);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer test-device',
      );
      expect(adapter.requests.single.queryParameters['date'], today.$2);
      final payloads = [
        ...(await db.select(db.patientJournalEntries).get()).map(
          (e) => e.payload,
        ),
        ...(await db.select(db.patientJournalMedia).get()).map(
          (e) => e.payload,
        ),
      ].join();
      expect(payloads, isNot(contains('PRIVATE')));
      expect(payloads, isNot(contains('transcript')));
      expect(await db.pendingWrites(auth.patient), isEmpty);
    },
  );
  for (final bad in ['day', 'timezone', 'patient', 'duplicate', 'url']) {
    test(
      'malformed $bad response preserves the previous cache atomically',
      () async {
        await repo.refresh();
        adapter.bad = bad;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect((await repo.read()).entries, hasLength(4));
      },
    );
  }
  test('day, patient and device scopes do not share cached entries', () async {
    await repo.refresh();
    for (final key in [
      yesterday,
      (p2.otherKey, today.$2, today.$3),
      (
        ('00000001-0000-4000-8000-000000000002', auth.device),
        today.$2,
        today.$3,
      ),
    ]) {
      final other = PatientJournalRepository(
        client,
        db,
        key,
        () => p1.now,
        current: () => true,
      );
      expect((await other.read()).entries, isEmpty);
      other.dispose();
    }
  });
  test('late refresh cannot write after the selected scope is left', () async {
    adapter.gate = Completer();
    adapter.entered = Completer();
    final refresh = repo.refresh();
    await adapter.entered!.future;
    current = false;
    adapter.gate!.complete();
    await refresh;
    expect((await repo.read()).entries, isEmpty);
  });
  test(
    'offline read retains cached text without attempting another request',
    () async {
      await repo.refresh();
      adapter.fail = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      final requests = adapter.requests.length;
      expect((await repo.read()).entries, hasLength(4));
      expect(adapter.requests.length, requests);
    },
  );
  test(
    'v17 migration keeps profile and outbox while creating P4 caches',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp('remori-p4-migration-');
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
        for (final name in [
          'patient_journal_entries',
          'patient_journal_media',
          'patient_journal_days',
        ]) {
          await db.customStatement('DROP TABLE $name');
        }
        await db.customStatement('DROP TABLE patient_memory_details');
        await db.customStatement('DROP TABLE patient_game_scores');
        await db.customStatement('DROP TABLE patient_game_refreshes');
        await db.customStatement('PRAGMA user_version = 17');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect(await db.pendingWrites(auth.patient), hasLength(1));
        expect(
          (await db.select(db.patientTodaySettings).get()).single.fullName,
          'Patient',
        );
        expect(await db.select(db.patientJournalEntries).get(), isEmpty);
        expect(await db.select(db.patientJournalMedia).get(), isEmpty);
        expect(await db.select(db.patientJournalDays).get(), isEmpty);
      } finally {
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
        final absolute = dir.absolute;
        if (absolute.parent.path == Directory.systemTemp.absolute.path &&
            absolute.uri.pathSegments
                .where((s) => s.isNotEmpty)
                .last
                .startsWith('remori-p4-migration-')) {
          await absolute.delete(recursive: true);
        }
      }
    },
  );
  test('native previews use unauthenticated thumbnail transport and clear in-flight bytes', () async {
    final urls = <Uri>[], gate = Completer<void>();
    final store = NativePatientJournalPreviews(today, () => p1.now);
    await HttpOverrides.runZoned(() async {
      final load = store.load(photo);
      await Future<void>.delayed(Duration.zero);
      store.clear();
      gate.complete();
      await expectLater(load, throwsA(isA<PatientJournalPreviewFailure>()));
      expect(urls.single.toString(), photo.thumbnailUrl);
      store.dispose();
    }, createHttpClient: (_) => c12.DelayedImageClient(bytes, urls, 200, gate));
  });
  test(
    'native preview cache evicts at retention and sanitizes 403 failures',
    () async {
      var now = p1.now;
      final urls = <Uri>[];
      final store = NativePatientJournalPreviews(today, () => now);
      await HttpOverrides.runZoned(() async {
        await store.load(photo);
        await store.load(photo);
        expect(urls, hasLength(1));
        now = photo.expiresAt!;
        store.expire(now);
        await expectLater(
          store.load(photo),
          throwsA(isA<PatientJournalPreviewFailure>()),
        );
        store.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 200));
      final denied = NativePatientJournalPreviews(today, () => p1.now);
      await HttpOverrides.runZoned(() async {
        await expectLater(
          denied.load(photo),
          throwsA(
            isA<PatientJournalPreviewFailure>()
                .having((e) => e.status, 'status', 403)
                .having(
                  (e) => e.toString(),
                  'sanitized',
                  'Journal preview unavailable',
                ),
          ),
        );
        denied.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 403));
    },
  );

  test(
    'native memory cache expires even without a visible image subscriber',
    () async {
      final urls = <Uri>[];
      final store = NativePatientJournalPreviews(today, () => p1.now);
      final media = JournalMedia(
        id: photo.id,
        type: photo.type,
        trigger: '',
        status: photo.status,
        url: photo.url,
        thumbnailUrl: photo.thumbnailUrl,
        expiresAt: p1.now.add(const Duration(milliseconds: 20)),
      );
      await HttpOverrides.runZoned(() async {
        await store.load(media);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Keeping the test clock fixed permits loading again. Evicting the
        // previous deduplicated future is what causes another GET.
        await store.load(media);
        expect(urls, hasLength(2));
        store.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 200));
    },
  );

  late Map<PatientJournalKey, FakeRepository> repos;
  late Map<PatientJournalKey, FakePreviews> stores;
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
    bool offline = false,
    bool empty = false,
    int? imageStatus,
    DateTime? expiry,
    bool onlyPhoto = false,
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
    repos = {};
    stores = {};
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith(
          (ref) => ref.watch(p2.selectedScope),
        ),
        patientTodayDataProvider(p1.key).overrideWith(
          (ref) => Stream.value(
            PatientTodayData(
              settings: PatientSettings(
                'Patient',
                language,
                'Africa/Cairo',
                true,
              ),
            ),
          ),
        ),
        patientTodayDataProvider(p2.otherKey).overrideWith(
          (ref) => Stream.value(
            PatientTodayData(
              settings: PatientSettings(
                'Patient',
                language,
                'Africa/Cairo',
                true,
              ),
            ),
          ),
        ),
        patientTodayClockProvider.overrideWith(
          (ref) =>
              () => ref.read(testNowProvider),
        ),
        patientTodayNowProvider.overrideWith(
          (ref) => Stream.value(ref.watch(testNowProvider)),
        ),
        patientAlertCandidateProvider.overrideWithValue(null),
        patientJournalRepositoryProvider.overrideWith((ref, key) {
          final base = fixture(key, language: language, expiry: expiry);
          final data = key.$1 != p1.key || empty
              ? PatientJournalData(refreshedAt: p1.now)
              : onlyPhoto
              ? PatientJournalData(
                  entries: [base.entries.last],
                  refreshedAt: p1.now,
                )
              : base;
          final fake = FakeRepository(
            client,
            db,
            key,
            () => p1.now,
            current: () => true,
            data: data,
          )..fail = offline;
          repos[key] = fake;
          ref.onDispose(fake.dispose);
          return fake;
        }),
        patientJournalPreviewsProvider.overrideWith((ref, key) {
          final store = FakePreviews(bytes)..status = imageStatus;
          stores[key] = store;
          ref.onCancel(store.clear);
          ref.onDispose(store.dispose);
          return store;
        }),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
        screenBuildersProvider.overrideWith(
          (ref) => {
            RemoriScreen.p1: (_, _) => const Text('Today destination'),
            RemoriScreen.p2: (_, _) => const Text('Reminders destination'),
            RemoriScreen.p4: (_, _) => const P4MyDayScreen(),
          },
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const RepaintBoundary(
          key: Key('p4-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    c.read(remoriRouterProvider).goNamed(RemoriScreen.p4.name);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'P4 shows real rendered text and honest generic descriptions without editing',
    (tester) async {
      final c = await mount(tester);
      expect(find.textContaining('You met Ahmed'), findsOneWidget);
      expect(find.text('You talked about a doctor visit'), findsOneWidget);
      expect(find.textContaining('A reminder at'), findsOneWidget);
      expect(find.textContaining('took'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Memory details will be available soon.'), findsNothing);
      expect(
        tester
            .widget<RemoriNavigationBar>(find.byType(RemoriNavigationBar))
            .onAction,
        isNull,
      );
      await tester.tap(find.textContaining('You met Ahmed'));
      await tester.pumpAndSettle();
      expect(
        c.read(remoriRouterProvider).routeInformationProvider.value.uri.path,
        '/p4',
      );
      await unmount(tester, c);
    },
  );
  testWidgets(
    'Today and Yesterday switch scoped caches and clear previous photos',
    (tester) async {
      final c = await mount(tester);
      final old = stores[today]!;
      final clears = old.clears;
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();
      expect(c.read(patientJournalKeyProvider), yesterday);
      expect(repos[yesterday]!.refreshes, 1);
      expect(old.clears, greaterThan(clears));
      await tester.tap(find.text('Today').first);
      await tester.pumpAndSettle();
      expect(c.read(patientJournalKeyProvider), today);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'offline mode keeps text and initials without loading cached URLs',
    (tester) async {
      final c = await mount(tester, offline: true);
      expect(stores[today]!.loads, 0);
      expect(find.textContaining('You met Ahmed'), findsOneWidget);
      expect(
        find.text(
          'Your saved day is here. Updates will arrive when connected.',
        ),
        findsOneWidget,
      );
      repos[today]!.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(stores[today]!.loads, greaterThan(0));
      await unmount(tester, c);
    },
  );
  testWidgets('empty day stays calm without sample events', (tester) async {
    final c = await mount(tester, empty: true);
    expect(find.text('Moments from your day will appear here'), findsOneWidget);
    expect(find.textContaining('Ahmed'), findsNothing);
    await unmount(tester, c);
  });
  testWidgets(
    'backgrounding clears images and ignores an older refresh result',
    (tester) async {
      final c = await mount(tester, onlyPhoto: true);
      final store = stores[today]!, fake = repos[today]!;
      fake.gate = Completer();
      final pending = c.read(patientJournalRefreshProvider.notifier).refresh();
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      final cleared = store.clears;
      fake.gate!.complete();
      await pending;
      await tester.pumpAndSettle();
      expect(c.read(patientJournalRefreshProvider).previewUntil, isNull);
      expect(store.clears, greaterThanOrEqualTo(cleared));
      expect(find.byType(Image), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(c.read(patientJournalRefreshProvider).previewUntil, isNotNull);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'retention expiry hides and evicts preview bytes at the boundary',
    (tester) async {
      final c = await mount(
        tester,
        onlyPhoto: true,
        expiry: p1.now.add(const Duration(seconds: 3)),
      );
      final refreshes = repos[today]!.refreshes;
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(stores[today]!.expires, greaterThan(0));
      expect(repos[today]!.refreshes, refreshes);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'signed-reference lifetime hides previews after ten minutes without network',
    (tester) async {
      final c = await mount(tester, onlyPhoto: true);
      final calls = repos[today]!.refreshes;
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(repos[today]!.refreshes, calls);
      await unmount(tester, c);
    },
  );
  testWidgets(
    '403 triggers at most one automatic refresh per media in this cycle',
    (tester) async {
      final c = await mount(tester, onlyPhoto: true, imageStatus: 403);
      expect(repos[today]!.refreshes, 2);
      expect(stores[today]!.loads, 2);
      expect(find.byType(Image), findsNothing);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'device change hides old names, resets day selection and clears previews',
    (tester) async {
      final c = await mount(tester);
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();
      final old = stores[yesterday]!;
      c.read(p2.selectedScope.notifier).select(p2.otherKey);
      await tester.pumpAndSettle();
      expect(c.read(patientJournalYesterdayProvider), isFalse);
      expect(find.textContaining('Ahmed'), findsNothing);
      expect(old.clears, greaterThan(0));
      await unmount(tester, c);
    },
  );
  testWidgets(
    'fresh response cannot authorize media from an older displayed cache row',
    (tester) async {
      final c = await mount(tester, onlyPhoto: true);
      final fake = repos[today]!, store = stores[today]!;
      expect(find.byType(Image), findsOneWidget);
      final loads = store.loads;
      fake.emitted = fake.data;
      fake.data = PatientJournalData(refreshedAt: p1.now);
      await c.read(patientJournalRefreshProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(store.loads, loads);
      await unmount(tester, c);
    },
  );

  testWidgets('leaving P4 clears its preview store', (tester) async {
    final c = await mount(tester);
    final store = stores[today]!, clears = store.clears;
    c.read(remoriRouterProvider).goNamed(RemoriScreen.p2.name);
    await tester.pumpAndSettle();
    expect(store.clears, greaterThan(clears));
    expect(find.byType(P4MyDayScreen), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('local midnight advances Today and Yesterday by calendar day', (
    tester,
  ) async {
    final c = await mount(tester);
    c.read(testNowProvider.notifier).put(DateTime.utc(2026, 10, 15, 22));
    await tester.pumpAndSettle();
    expect(c.read(patientJournalKeyProvider)?.$2, '2026-10-16');
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(c.read(patientJournalKeyProvider)?.$2, '2026-10-15');
    await unmount(tester, c);
  });
  for (final language in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P4 $language at ${scale}x reference and accessible layout', (
        tester,
      ) async {
        final c = await mount(
          tester,
          language: language,
          scale: scale,
          imageStatus: 500,
        );
        expect(
          Directionality.of(tester.element(find.byType(P4MyDayScreen))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(
          MediaQuery.textScalerOf(tester.element(find.byType(P4MyDayScreen)))
              .scale(22),
          22 * scale,
        );
        if (scale == 1 && autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('p4-preview')),
            matchesGoldenFile('goldens/p4_$language.png'),
          );
        }
        for (final finder in [
          find.byType(FilledButton),
          find.byType(OutlinedButton),
        ]) {
          expect(tester.getSize(finder).height, greaterThanOrEqualTo(64));
        }
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await unmount(tester, c);
      });
    }
  }
}
