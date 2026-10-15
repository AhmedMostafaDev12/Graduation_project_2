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
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/journal/data/journal_previews.dart';
import 'package:remori/features/journal/data/journal_repository.dart';
import 'package:remori/features/journal/domain/journal_data.dart';
import 'package:remori/features/journal/presentation/journal_providers.dart';
import 'package:remori/features/reminders/domain/reminder_data.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as home;
import 'c6_unknown_faces_test.dart' as c6;
import 'c8_reminders_test.dart' as c8;

const scope = JournalScope('caregiver-A', home.patient, 'Africa/Cairo');
const key = (scope, '2026-10-15');
final now = DateTime.utc(2026, 10, 15, 8);
const media = JournalMedia(
  id: 'photo',
  type: 'image',
  trigger: 'user_request',
  status: 'confirmed',
  url: 'https://example.test/image',
  thumbnailUrl: 'https://example.test/thumb',
);
JournalData fixture() => JournalData(
  refreshedAt: now,
  entries: [
    JournalEntry(
      id: 'reminder',
      type: 'reminder',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 5),
    ),
    JournalEntry(
      id: 'encounter',
      type: 'encounter',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 6, 12),
      endedAt: DateTime.utc(2026, 10, 15, 6, 30),
      person: const JournalPerson('person', 'Mona', 'Sister'),
    ),
    JournalEntry(
      id: 'talk',
      type: 'conversation_segment',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 6, 30),
      endedAt: DateTime.utc(2026, 10, 15, 6, 35),
      person: const JournalPerson('person', 'Mona', 'Sister'),
      transcript: 'كيف حالك اليوم؟',
      language: 'ar',
    ),
    JournalEntry(
      id: 'query',
      type: 'voice_query',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 6, 36),
      transcript: 'What time is it?',
    ),
    JournalEntry(
      id: 'recording',
      type: 'user_requested_recording',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 7),
      media: const [media],
    ),
    JournalEntry(
      id: 'doc',
      type: 'document_captured',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 7, 10),
      document: const JournalDocument(
        'doc',
        'prescription',
        'Prescription',
        'Follow-up in two weeks',
      ),
    ),
    JournalEntry(
      id: 'notable',
      type: 'notable_moment_captured',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 7, 20),
      renderedText: 'A walk in the garden',
    ),
    JournalEntry(
      id: 'paused',
      type: 'memory_paused',
      source: 'glasses',
      occurredAt: DateTime.utc(2026, 10, 15, 7, 30),
    ),
  ],
);

class Adapter implements HttpClientAdapter {
  bool fail = false, missing = false;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  Map<String, dynamic>? response;
  Map<String, dynamic> body(RequestOptions o) =>
      response ??
      {
        'date': o.queryParameters['date'],
        'timezone': scope.timezone,
        'entries': [
          for (final hour in [7, 6])
            {
              'id': 'entry-$hour',
              'event_type': 'conversation_segment',
              'source': 'glasses',
              'occurred_at': '${o.queryParameters['date']}T0$hour:00:00Z',
              'ended_at': null,
              'person': {
                'id': 'person',
                'name': 'Mona',
                'relationship': 'Sister',
                'embedding': 'PRIVATE',
              },
              'transcript_text': 'Saved conversation',
              'language': 'en',
              'rendered_text': null,
              'metadata': {
                'unknown_embedding': 'PRIVATE',
                'unapproved': 'PRIVATE',
              },
              'document': {
                'id': 'document',
                'document_type': 'prescription',
                'title': 'Prescription',
                'headline': 'Follow-up',
              },
              'media': [
                {
                  'id': 'photo-$hour',
                  'asset_type': 'image',
                  'trigger': 'user_request',
                  'status': 'confirmed',
                  'duration_seconds': null,
                  'expires_at': null,
                  'url': media.url,
                  'thumbnail_url': media.thumbnailUrl,
                  'ai_tags': {
                    'category': 'food',
                    'tags': ['Lunch'],
                    'reason': null,
                    'embedding': 'PRIVATE',
                  },
                  'bytes': 'PRIVATE',
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
    if (gate != null) await gate!.future;
    if (fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(
        missing
            ? {
                'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE'},
              }
            : body(o),
      ),
      missing ? 404 : 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRepository extends JournalRepository {
  FakeRepository(super.client, super.db, super.key);
  JournalData data = fixture();
  bool fail = false;
  int refreshes = 0;
  Completer<void>? gate;
  final updates = StreamController<void>.broadcast();
  @override
  Future<void> refresh() async {
    refreshes++;
    if (gate != null) await gate!.future;
    if (fail) throw ApiFailure(ApiFailureKind.network);
    updates.add(null);
  }

  @override
  Stream<JournalData> watch() async* {
    yield data;
    await for (final _ in updates.stream) {
      yield data;
    }
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

class FakePreviews implements JournalPreviews {
  FakePreviews(this.bytes);
  final Uint8List bytes;
  int clears = 0, loads = 0;
  bool forbidden = false;
  final pending = <String, Future<Uint8List>>{};
  @override
  Future<Uint8List> load(JournalMedia p) => pending.putIfAbsent(p.id, () {
    loads++;
    return forbidden
        ? Future.error(const JournalPreviewFailure(403))
        : Future.value(bytes);
  });
  @override
  void expire(DateTime now) {}
  @override
  void clear() {
    clears++;
    pending.clear();
    PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
  }

  @override
  void dispose() => clear();
}

class DelayedImageClient extends c6.ImageClient {
  DelayedImageClient(super.bytes, super.urls, super.status, this.gate);
  final Completer<void> gate;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    urls.add(url);
    return DelayedImageRequest(bytes, status, gate);
  }
}

class DelayedImageRequest extends c6.ImageRequest {
  DelayedImageRequest(super.bytes, super.status, this.gate);
  final Completer<void> gate;
  @override
  Future<HttpClientResponse> close() async {
    await gate.future;
    return c6.ImageResponse(bytes, status);
  }
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late JournalRepository repo;
  late Uint8List bytes;
  setUpAll(() async {
    bytes = await File('design/screens/images/stranger.jpg').readAsBytes();
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
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = JournalRepository(client, db, key);
  });
  tearDown(() async {
    client.close();
    await db.close();
  });
  test('journal GET caches sorted allowlisted content and never arbitrary metadata', () async {
    await repo.refresh();
    final data = await repo.read();
    expect(data.entries.map((e) => e.id), ['entry-6', 'entry-7']);
    expect(data.entries.first.transcript, 'Saved conversation');
    expect(data.entries.first.person?.relationship, 'Sister');
    expect(data.entries.first.document?.headline, 'Follow-up');
    expect(data.entries.first.media.single.tags, ['Lunch']);
    final payloads = [
      ...(await db.select(db.cachedJournalEntries).get()).map((r) => r.payload),
      ...(await db.select(db.cachedJournalMedia).get()).map((r) => r.payload),
    ].join();
    expect(payloads, isNot(contains('PRIVATE')));
    expect(payloads, isNot(contains('metadata')));
    expect(
      adapter.requests.single.path,
      '/patients/${scope.patientId}/journal',
    );
    expect(adapter.requests.single.queryParameters, {'date': key.$2});
    expect(adapter.requests.single.method, 'GET');
  });
  test('network failure preserves saved text and no media requests are made by repository', () async {
    await repo.refresh();
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).entries.length, 2);
    expect(adapter.requests.every((r) => r.path.endsWith('/journal')), true);
  });
  test(
    'day validation uses patient midnight rather than UTC midnight',
    () async {
      final p = adapter.body(RequestOptions(queryParameters: {'date': key.$2}));
      final e = (p['entries'] as List).first as Map;
      e['occurred_at'] = '2026-10-14T22:30:00Z';
      adapter.response = p;
      await repo.refresh();
      expect(
        (await repo.read()).entries.first.occurredAt,
        DateTime.utc(2026, 10, 14, 22, 30),
      );
    },
  );
  test('calendar-day filtering works across daylight-saving transitions', () {
    expect(
      PatientTime.day(DateTime.utc(2026, 10, 28, 21, 30), scope.timezone),
      '2026-10-29',
    );
    expect(
      PatientTime.day(DateTime.utc(2026, 10, 29, 21, 30), scope.timezone),
      '2026-10-29',
    );
    expect(
      PatientTime.day(DateTime.utc(2026, 10, 29, 22, 30), scope.timezone),
      '2026-10-30',
    );
  });
  for (final bad in [
    'wrong-day',
    'timezone',
    'duplicate',
    'media',
    'url',
    'person',
    'ended',
    'naive',
  ]) {
    test(
      'malformed $bad response leaves previous cache atomically intact',
      () async {
        await repo.refresh();
        final p = adapter.body(adapter.requests.last);
        final entries = p['entries'] as List;
        final e = entries.first as Map;
        switch (bad) {
          case 'wrong-day':
            e['occurred_at'] = '2026-10-14T06:00:00Z';
          case 'timezone':
            p['timezone'] = 'UTC';
          case 'duplicate':
            entries.add(entries.first);
          case 'media':
            (e['media'] as List).add((e['media'] as List).first);
          case 'url':
            (e['media'] as List).first['url'] = 'http://unsafe.test/image';
          case 'person':
            e['person'] = {'id': 'person', 'name': 'Mona'};
          case 'ended':
            e['ended_at'] = '2026-10-15T01:00:00Z';
          case 'naive':
            e['occurred_at'] = '2026-10-15T07:00:00';
        }
        adapter.response = p;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect((await repo.read()).entries.length, 2);
      },
    );
  }
  test('same entry and media IDs remain isolated across caregiver, patient and day', () async {
    await repo.refresh();
    final other = JournalRepository(client, db, (
      const JournalScope('other', home.patient, 'Africa/Cairo'),
      key.$2,
    ));
    final tomorrow = JournalRepository(client, db, (scope, '2026-10-16'));
    final patient = JournalRepository(client, db, (
      const JournalScope('caregiver-A', 'other-patient', 'Africa/Cairo'),
      key.$2,
    ));
    await other.refresh();
    await tomorrow.refresh();
    await patient.refresh();
    adapter.response = {
      'date': key.$2,
      'timezone': scope.timezone,
      'entries': [],
    };
    await repo.refresh();
    expect((await repo.read()).entries, isEmpty);
    expect((await other.read()).entries.length, 2);
    expect((await tomorrow.read()).entries.length, 2);
    expect((await patient.read()).entries.length, 2);
  });
  test('known missing patient purges all cached days only for current account and patient', () async {
    await repo.refresh();
    final tomorrow = JournalRepository(client, db, (scope, '2026-10-16'));
    await tomorrow.refresh();
    final other = JournalRepository(client, db, (
      const JournalScope('other', home.patient, 'Africa/Cairo'),
      key.$2,
    ));
    await other.refresh();
    adapter.missing = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).refreshedAt, isNull);
    expect((await tomorrow.read()).entries, isEmpty);
    expect((await other.read()).entries.length, 2);
  });
  test(
    'Home removed links purge journal entries, media and refresh state',
    () async {
      await repo.refresh();
      final h = ApiClient(
        config: ApiConfig('https://example.test/api/v1'),
        credentials: auth.TestCredentials(),
        adapter: home.HomeAdapter()..empty = true,
        onCredentialsInvalidated: (_) {},
      );
      try {
        await HomeRepository(h, db, scope.caregiverId).refresh(null);
      } finally {
        h.close();
      }
      expect(await db.select(db.cachedJournalEntries).get(), isEmpty);
      expect(await db.select(db.cachedJournalMedia).get(), isEmpty);
      expect((await repo.read()).refreshedAt, isNull);
    },
  );
  test('disposed in-flight refresh cannot populate cache', () async {
    adapter.gate = Completer<void>();
    final pending = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    repo.dispose();
    adapter.gate!.complete();
    try {
      await pending;
    } on ApiFailure {
      /* cancellation is expected */
    }
    expect((await repo.read()).entries, isEmpty);
  });
  test(
    'schema v8 upgrade preserves pending writes and creates journal tables',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp(
        'remori-c12-migration-',
      );
      try {
        final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
        db = RemoriDatabase(NativeDatabase(file));
        await db.saveReminderLog(
          patientId: scope.patientId,
          reminderId: '00000005-0000-4000-8000-000000000001',
          scheduledAt: now,
          at: now,
          status: ReminderStatus.pending,
        );
        await db
            .into(db.cachedPlaces)
            .insert(
              CachedPlacesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
                id: 'place',
                name: 'Home',
                latitude: 30,
                longitude: 31,
                radiusM: 100,
                createdBy: scope.caregiverId,
                updatedAt: now,
                position: 0,
              ),
            );
        await db.customStatement('DROP TABLE cached_document_details');
        await db.customStatement('DROP TABLE cached_documents');
        await db.customStatement('DROP TABLE documents_cache_states');
        await db.customStatement('DROP TABLE cached_media_details');
        await db.customStatement('DROP TABLE cached_journal_entries');
        await db.customStatement('DROP TABLE cached_journal_media');
        await db.customStatement('DROP TABLE journal_cache_states');
        await db.customStatement('PRAGMA user_version = 8');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect((await db.pendingWrites(scope.patientId)).length, 1);
        expect((await db.select(db.cachedPlaces).getSingle()).name, 'Home');
        expect(await db.select(db.cachedJournalEntries).get(), isEmpty);
        expect(await db.select(db.cachedJournalMedia).get(), isEmpty);
        expect(await db.select(db.journalCacheStates).get(), isEmpty);
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
      } finally {
        if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
            !dir.path.contains('remori-c12-migration-')) {
          throw StateError('Unexpected temporary path');
        }
        await dir.delete(recursive: true);
      }
    },
  );
  test('native previews use bare HTTPS thumbnails, ID deduplication and clear on exit', () async {
    final urls = <Uri>[];
    final http = c6.ImageClient(bytes, urls, 200);
    final store = NativeJournalPreviews(key, () => now);
    await HttpOverrides.runZoned(() async {
      final first = store.load(media);
      expect(identical(first, store.load(media)), true);
      expect(await first, bytes);
      expect(urls.single.path, '/thumb');
      store.clear();
      await store.load(media);
      expect(urls.length, 2);
      expect(http.closed, true);
      store.dispose();
      await expectLater(
        store.load(media),
        throwsA(isA<JournalPreviewFailure>()),
      );
    }, createHttpClient: (_) => http);
  });
  for (final boundary in ['expiry', 'clear']) {
    test('late image response cannot survive $boundary', () async {
      final gate = Completer<void>(), urls = <Uri>[];
      var clock = now;
      final store = NativeJournalPreviews(key, () => clock);
      final p = JournalMedia(
        id: media.id,
        type: media.type,
        trigger: media.trigger,
        status: media.status,
        url: media.url,
        expiresAt: now.add(const Duration(seconds: 1)),
      );
      await HttpOverrides.runZoned(() async {
        final pending = store.load(p);
        final rejected = expectLater(
          pending,
          throwsA(isA<JournalPreviewFailure>()),
        );
        await Future<void>.delayed(Duration.zero);
        if (boundary == 'expiry') {
          clock = now.add(const Duration(seconds: 1));
        } else {
          store.clear();
        }
        gate.complete();
        await rejected;
        store.dispose();
      }, createHttpClient: (_) => DelayedImageClient(bytes, urls, 200, gate));
    });
  }
  test(
    'video without thumbnail and expired images never make HTTP requests',
    () async {
      final urls = <Uri>[];
      final store = NativeJournalPreviews(key, () => now);
      await HttpOverrides.runZoned(() async {
        for (final p in [
          const JournalMedia(
            id: 'v',
            type: 'video',
            trigger: 'user_request',
            status: 'confirmed',
            url: 'https://example.test/video',
          ),
          JournalMedia(
            id: 'expired',
            type: 'image',
            trigger: 'user_request',
            status: 'confirmed',
            url: media.url,
            expiresAt: now,
          ),
        ]) {
          await expectLater(
            store.load(p),
            throwsA(isA<JournalPreviewFailure>()),
          );
        }
        expect(urls, isEmpty);
        store.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 200));
    },
  );
  test(
    'preview errors expose only sanitized status and expired bytes are evicted',
    () async {
      final urls = <Uri>[];
      var clock = now;
      final store = NativeJournalPreviews(key, () => clock);
      final p = JournalMedia(
        id: media.id,
        type: media.type,
        trigger: media.trigger,
        status: media.status,
        url: media.url,
        expiresAt: now.add(const Duration(minutes: 1)),
      );
      await HttpOverrides.runZoned(() async {
        await store.load(p);
        clock = now.add(const Duration(minutes: 1));
        store.expire(clock);
        await expectLater(store.load(p), throwsA(isA<JournalPreviewFailure>()));
        expect(urls.length, 1);
        store.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 200));
      final forbidden = NativeJournalPreviews(key, () => now);
      await HttpOverrides.runZoned(() async {
        await expectLater(
          forbidden.load(media),
          throwsA(
            isA<JournalPreviewFailure>()
                .having((e) => e.status, 'status', 403)
                .having(
                  (e) => e.toString(),
                  'safe error',
                  'Journal preview unavailable',
                ),
          ),
        );
        forbidden.dispose();
      }, createHttpClient: (_) => c6.ImageClient(bytes, urls, 403));
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeRepository fake, {
    String language = 'en',
    double scale = 1,
    Size size = const Size(390, 844),
    JournalScope? Function()? selected,
    FakePreviews? previews,
    DateTime Function()? clock,
    bool viewer = false,
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
        journalScopeProvider.overrideWith(
          (ref) => selected == null ? scope : selected(),
        ),
        journalClockProvider.overrideWithValue(clock ?? () => now),
        selectedHomePatientProvider.overrideWithValue(
          HomePatient(
            id: home.patient,
            name: 'Patient',
            language: 'ar',
            timezone: 'Africa/Cairo',
            memoryEnabled: true,
            permission: viewer ? 'viewer' : 'manager',
          ),
        ),
        journalRepositoryProvider(key).overrideWithValue(fake),
        journalPreviewsProvider(key).overrideWith((ref) {
          final store = previews ?? FakePreviews(bytes);
          ref.onDispose(store.clear);
          return store;
        }),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c1: (_, _) => const Text('Home destination'),
          RemoriScreen.c9: (_, _) => const Text('Reminder destination'),
          RemoriScreen.c15: (_, state) => Text(
            'Document destination',
            key: ValueKey(state.extra.toString()),
          ),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c12-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c12.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'retention expiry hides previews at the boundary without refreshing',
    (tester) async {
      final expires = now.add(const Duration(seconds: 10));
      final p = JournalMedia(
        id: media.id,
        type: media.type,
        trigger: media.trigger,
        status: media.status,
        url: media.url,
        expiresAt: expires,
      );
      final fake = FakeRepository(client, db, key)
        ..data = JournalData(
          entries: [
            JournalEntry(
              id: 'only',
              type: 'user_requested_recording',
              source: 'glasses',
              occurredAt: now,
              media: [p],
            ),
          ],
        );
      await mount(tester, fake);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(fake.refreshes, 1);
    },
  );
  testWidgets(
    'default day follows patient midnight and explicit dates stay selected',
    (tester) async {
      var clock = DateTime.utc(2026, 10, 14, 21, 30);
      final container = await mount(
        tester,
        FakeRepository(client, db, key),
        clock: () => clock,
      );
      expect(container.read(journalDayProvider), '2026-10-15');
      clock = DateTime.utc(2026, 10, 15, 21, 30);
      container.invalidate(journalNowProvider);
      await tester.pumpAndSettle();
      expect(container.read(journalDayProvider), '2026-10-16');
      container.read(journalDayProvider.notifier).shift(-1);
      await tester.pumpAndSettle();
      clock = DateTime.utc(2026, 10, 16, 21, 30);
      container.invalidate(journalNowProvider);
      await tester.pumpAndSettle();
      expect(container.read(journalDayProvider), '2026-10-15');
    },
  );
  testWidgets('linked viewer opens document details without editor actions', (
    tester,
  ) async {
    await mount(tester, FakeRepository(client, db, key), viewer: true);
    expect(find.byTooltip('Add reminder'), findsNothing);
    await tester.tap(find.textContaining('Prescription · Follow-up'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          {'patient_id': scope.patientId, 'document_id': 'doc'}.toString(),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'C12 shows actual journal data and each filter selects its event type',
    (tester) async {
      final fake = FakeRepository(client, db, key);
      await mount(tester, fake);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Reminder activity recorded.'), findsOneWidget);
      expect(find.textContaining('Mona (Sister)'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
      for (final entry in {
        'People': 'ENCOUNTER',
        'Talk': 'CONVERSATION',
        'Questions': 'QUESTION ASKED',
        'Reminders': 'REMINDER',
        'Media': 'RECORDING',
        'Docs': 'DOCUMENT',
      }.entries) {
        final chip = find
            .ancestor(
              of: find.text(entry.key),
              matching: find.byType(GestureDetector),
            )
            .first;
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
      }
      expect(fake.refreshes, 1);
    },
  );
  testWidgets(
    'offline journal shows saved text and placeholders until successful retry',
    (tester) async {
      final fake = FakeRepository(client, db, key)..fail = true;
      final previews = FakePreviews(bytes);
      await mount(tester, fake, previews: previews);
      expect(find.textContaining('Showing saved journal text'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(previews.loads, 0);
      fake.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(previews.loads, 1);
      expect(fake.refreshes, 2);
    },
  );
  testWidgets('day navigation resets previews and uses calendar dates', (
    tester,
  ) async {
    final previews = FakePreviews(bytes);
    final container = await mount(
      tester,
      FakeRepository(client, db, key),
      previews: previews,
    );
    final old = previews.clears;
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(container.read(journalDayProvider), '2026-10-14');
    expect(find.textContaining('Mona (Sister)'), findsNothing);
    expect(previews.clears, greaterThan(old));
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(container.read(journalDayProvider), key.$2);
  });
  testWidgets('patient switch hides old journal and ignores late refresh', (
    tester,
  ) async {
    JournalScope? selected = scope;
    final fake = FakeRepository(client, db, key);
    final container = await mount(tester, fake, selected: () => selected);
    fake.gate = Completer<void>();
    final pending = container.read(journalRefreshProvider.notifier).refresh();
    selected = null;
    container.invalidate(journalScopeProvider);
    await tester.pumpAndSettle();
    fake.gate!.complete();
    await pending;
    await tester.pumpAndSettle();
    expect(find.textContaining('Mona (Sister)'), findsNothing);
    expect(container.read(journalRefreshProvider).previews, false);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets(
    'background clears photos and failed resume leaves cached text only',
    (tester) async {
      final fake = FakeRepository(client, db, key);
      final previews = FakePreviews(bytes);
      final container = await mount(tester, fake, previews: previews);
      final old = previews.clears;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      expect(previews.clears, greaterThan(old));
      expect(container.read(journalRefreshProvider).previews, false);
      fake.fail = true;
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('Mona (Sister)'), findsOneWidget);
    },
  );
  testWidgets('forbidden preview refreshes once and never loops', (
    tester,
  ) async {
    final fake = FakeRepository(client, db, key);
    final previews = FakePreviews(bytes)..forbidden = true;
    await mount(tester, fake, previews: previews);
    await tester.pumpAndSettle();
    expect(fake.refreshes, 2);
    expect(previews.loads, 2);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets(
    'existing center action opens reminder editor and clears previews',
    (tester) async {
      final previews = FakePreviews(bytes);
      await mount(tester, FakeRepository(client, db, key), previews: previews);
      final old = previews.clears;
      await tester.tap(find.byTooltip('Add reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Reminder destination'), findsOneWidget);
      expect(previews.clears, greaterThan(old));
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C12 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, FakeRepository(client, db, key), language: language);
      for (
        var i = 0;
        i < 20 &&
            tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((w) => w.image == null);
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c12-preview')),
          matchesGoldenFile('goldens/c12_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C12 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        FakeRepository(client, db, key),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
