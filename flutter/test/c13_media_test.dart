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
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/journal/data/media_repository.dart';
import 'package:remori/features/journal/domain/media_detail.dart';
import 'package:remori/features/journal/domain/journal_data.dart';
import 'package:remori/features/journal/presentation/journal_providers.dart';
import 'package:remori/features/journal/presentation/media_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as home;
import 'c12_journal_test.dart' as c12;
import 'c8_reminders_test.dart' as c8;

const key = (c12.scope, 'photo');
final now = c12.now;

class Adapter implements HttpClientAdapter {
  bool fail = false,
      missing = false,
      deleted = false,
      kept = false,
      video = false;
  int? denied;
  Map<String, Object?>? invalid;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  Map<String, Object?> fields() => {
    'id': key.$2,
    'patient_id': key.$1.patientId,
    'event_id': 'event',
    'asset_type': video ? 'video' : 'image',
    'trigger': 'encounter_keyframe',
    'status': 'confirmed',
    'ai_tags': {
      'category': 'person',
      'tags': ['family', 'living room'],
      'reason': null,
      'embedding': 'PRIVATE',
    },
    'contains_other_people': true,
    'duration_seconds': video ? 12 : null,
    'retention_policy': kept ? 'keep_indefinitely' : 'auto_expire',
    'expires_at': kept
        ? null
        : now.add(const Duration(days: 23)).toIso8601String(),
    'pinned_by': kept ? key.$1.caregiverId : null,
    'created_at': now.toIso8601String(),
    'embedding': 'PRIVATE',
  };
  Map<String, Object?> body() => {
    ...fields(),
    'url': 'https://example.test/full-photo?signature=PRIVATE',
    'url_expires_in': 600,
    'event': {
      'id': 'event',
      'event_type': 'encounter',
      'occurred_at': now.toIso8601String(),
      'person': {
        'id': 'person',
        'name': 'Ahmed',
        'relationship': 'son',
        'embedding': 'PRIVATE',
      },
    },
    ...?invalid,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    final before = body();
    if (gate != null) await gate!.future;
    if (fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    if (denied != null) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'FORBIDDEN', 'message': 'PRIVATE'},
        }),
        denied!,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (missing || deleted) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'MEDIA_NOT_FOUND', 'message': 'PRIVATE'},
        }),
        404,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (o.method == 'DELETE') {
      deleted = true;
      return ResponseBody.fromString('', 204);
    }
    if (o.method == 'POST') {
      kept = true;
      return ResponseBody.fromString(
        jsonEncode(fields()),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(before),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class Repository extends MediaRepository {
  Repository(super.client, super.db, super.key, super.clock);
  bool cacheFails = false;
  final updates = StreamController<void>.broadcast();
  @override
  Stream<MediaDetail?> watch() async* {
    yield await read();
    await for (final _ in updates.stream) {
      yield await read();
    }
  }

  @override
  Future<void> refresh() async {
    try {
      await super.refresh();
    } finally {
      if (!updates.isClosed) updates.add(null);
    }
  }

  @override
  Future<void> cacheReceipt(MediaReceipt receipt) async {
    if (cacheFails) throw StateError('Local cache unavailable');
    await super.cacheReceipt(receipt);
    if (!updates.isClosed) updates.add(null);
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
  late Adapter adapter;
  late Repository repo;
  late Uint8List bytes;
  setUpAll(() async {
    bytes = await File('design/screens/images/ahmed-room.jpg').readAsBytes();
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
    repo = Repository(client, db, key, () => now);
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });
  test('audited GET caches allowlisted detail and event metadata, never photo bytes', () async {
    await repo.refresh();
    final d = (await repo.read())!;
    expect(d.person?.name, 'Ahmed');
    expect(d.tags, ['family', 'living room']);
    expect(d.urlValidUntil, now.add(const Duration(minutes: 10)));
    expect(d.containsOtherPeople, true);
    expect(d.photo().previewUrl, d.url);
    expect(d.photo().expiresAt, d.urlValidUntil);
    final p = jsonDecode(
      (await db.select(db.cachedMediaDetails).getSingle()).payload,
    ) as Map;
    expect(p.containsKey('embedding'), false);
    expect((p['event']['person'] as Map).containsKey('embedding'), false);
    expect((p['ai_tags'] as Map).containsKey('embedding'), false);
    expect(
      adapter.requests.single.path,
      '/patients/${key.$1.patientId}/media/${key.$2}',
    );
    expect(adapter.requests.single.method, 'GET');
  });
  for (final bad in [
    {'id': 'other'},
    {'patient_id': 'other'},
    {'asset_type': 'audio'},
    {'status': 'discarded'},
    {'url': 'http://example.test/photo'},
    {'url_expires_in': 0},
    {'created_at': '2026-10-15T08:00:00'},
    {
      'event': {
        'id': 'other',
        'event_type': 'encounter',
        'occurred_at': now.toIso8601String(),
        'person': null,
      },
    },
    {'duration_seconds': -1},
    {
      'ai_tags': {
        'tags': [3],
      },
    },
  ]) {
    test(
      'malformed ${bad.keys.single} response preserves previous cache',
      () async {
        await repo.refresh();
        adapter.invalid = bad;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect((await repo.read())?.person?.name, 'Ahmed');
      },
    );
  }
  Future<void> seedJournal(String caregiver, String patient, String day) async {
    await db
        .into(db.cachedJournalMedia)
        .insert(
          CachedJournalMediaCompanion.insert(
            caregiverId: caregiver,
            patientId: patient,
            day: day,
            id: key.$2,
            eventId: 'event',
            payload: jsonEncode({
              'id': key.$2,
              'status': 'confirmed',
              'expires_at': now.add(const Duration(days: 23)).toIso8601String(),
            }),
            position: 0,
          ),
        );
  }

  test(
    'Pin updates all journal days for only the linked caregiver/patient',
    () async {
      await repo.refresh();
      await seedJournal(key.$1.caregiverId, key.$1.patientId, '2026-10-15');
      await seedJournal(key.$1.caregiverId, key.$1.patientId, '2026-10-14');
      await seedJournal('other', key.$1.patientId, '2026-10-15');
      final receipt = await repo.write(delete: false);
      await repo.cacheReceipt(receipt);
      final d = (await repo.read())!;
      expect(d.kept, true);
      expect(d.expiresAt, isNull);
      expect(d.person?.name, 'Ahmed');
      for (final r in await db.select(db.cachedJournalMedia).get()) {
        final p = jsonDecode(r.payload);
        expect(p['expires_at'] == null, r.caregiverId == key.$1.caregiverId);
      }
      expect(
        adapter.requests.where((r) => r.method == 'POST').single.path,
        '/media/photo/pin',
      );
    },
  );
  test('Delete removes scoped metadata and journal references without deleting event text', () async {
    await repo.refresh();
    await seedJournal(key.$1.caregiverId, key.$1.patientId, '2026-10-15');
    await seedJournal('other', key.$1.patientId, '2026-10-15');
    await repo.cacheReceipt(await repo.write(delete: true));
    expect(await repo.read(), isNull);
    expect(
      (await db.select(db.cachedJournalMedia).getSingle()).caregiverId,
      'other',
    );
    expect(adapter.requests.last.method, 'DELETE');
  });
  test(
    'known missing media removes the saved detail and journal reference',
    () async {
      await repo.refresh();
      await seedJournal(key.$1.caregiverId, key.$1.patientId, '2026-10-15');
      adapter.missing = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(await repo.read(), isNull);
      expect(await db.select(db.cachedJournalMedia).get(), isEmpty);
    },
  );
  test('offline failure preserves metadata; accounts cannot read each other’s cache', () async {
    await repo.refresh();
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read())?.eventType, 'encounter');
    expect(
      await MediaRepository(client, db, (
        const JournalScope('other', 'patient', 'Africa/Cairo'),
        'photo',
      ), () => now).read(),
      isNull,
    );
  });
  test('disposed late detail response does not populate SQLite', () async {
    adapter.gate = Completer<void>();
    final pending = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    repo.dispose();
    adapter.gate!.complete();
    try {
      await pending;
    } on ApiFailure {
      /* cancellation */
    }
    expect(await repo.read(), isNull);
  });
  test(
    'schema v9 upgrade preserves journal entries and queued writes',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp(
        'remori-c13-migration-',
      );
      try {
        final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
        db = RemoriDatabase(NativeDatabase(file));
        await db.saveReminderLog(
          patientId: key.$1.patientId,
          reminderId: '00000005-0000-4000-8000-000000000001',
          scheduledAt: now,
          at: now,
          status: ReminderStatus.pending,
        );
        await seedJournal(key.$1.caregiverId, key.$1.patientId, '2026-10-15');
        await db.customStatement('DROP TABLE cached_documents');
        await db.customStatement('DROP TABLE documents_cache_states');
        await db.customStatement('DROP TABLE cached_media_details');
        await db.customStatement('PRAGMA user_version = 9');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect((await db.pendingWrites(key.$1.patientId)).length, 1);
        expect((await db.select(db.cachedJournalMedia).get()).length, 1);
        expect(await db.select(db.cachedMediaDetails).get(), isEmpty);
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
      } finally {
        if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
            !dir.path.contains('remori-c13-migration-')) {
          throw StateError('Unexpected temporary path');
        }
        await dir.delete(recursive: true);
      }
    },
  );
  test('late detail response cannot restore a confirmed deletion', () async {
    await repo.refresh();
    adapter.gate = Completer<void>();
    final pending = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    await repo.cacheReceipt(const MediaReceipt(deleted: true));
    adapter.gate!.complete();
    await pending;
    expect(await repo.read(), isNull);
  });
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    Size size = const Size(390, 844),
    c12.FakePreviews? previews,
    JournalScope? Function()? selected,
    DateTime Function()? clock,
    bool fromJournal = false,
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
    final journal = c12.FakeRepository(client, db, c12.key);
    addTearDown(journal.dispose);
    final container = ProviderContainer(
      overrides: [
        routeAccessProvider.overrideWithValue(
          const RouteAccess(caregiverAuthenticated: true),
        ),
        appLocaleProvider.overrideWithValue(Locale(language)),
        journalScopeProvider.overrideWith(
          (ref) => selected == null ? key.$1 : selected(),
        ),
        journalClockProvider.overrideWithValue(clock ?? () => now),
        selectedHomePatientProvider.overrideWithValue(
          HomePatient(
            id: key.$1.patientId,
            name: 'Patient',
            language: 'ar',
            timezone: key.$1.timezone,
            memoryEnabled: true,
            permission: viewer ? 'viewer' : 'manager',
          ),
        ),
        mediaRepositoryProvider(key).overrideWithValue(repo),
        journalRepositoryProvider(c12.key).overrideWithValue(journal),
        journalPreviewsProvider(c12.key).overrideWith((ref) {
          final store = c12.FakePreviews(bytes);
          ref.onDispose(store.clear);
          return store;
        }),
        mediaPhotosProvider(key).overrideWith((ref) {
          final store = previews ?? c12.FakePreviews(bytes);
          ref.onDispose(store.clear);
          return store;
        }),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          if (!fromJournal)
            RemoriScreen.c12: (_, _) => const Text('Journal destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c13-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          fromJournal ? RemoriScreen.c12.name : RemoriScreen.c13.name,
          extra: {'patient_id': key.$1.patientId, 'media_id': key.$2},
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'C13 shows API photo, event, tags and actual retention; Pin returns to journal',
    (tester) async {
      await mount(tester);
      expect(find.text('Encounter with Ahmed (son)'), findsOneWidget);
      expect(find.text('family'), findsOneWidget);
      expect(find.text('Auto-deletes in 23 days'), findsOneWidget);
      await tester.tap(find.text('Pin to keep'));
      await tester.pumpAndSettle();
      expect(find.text('Journal destination'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
      expect((await repo.read())?.kept, true);
    },
  );
  testWidgets(
    'Delete requires confirmation; Cancel sends nothing and Confirm deletes once',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Delete photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
      await tester.tap(find.text('Delete photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete photo'));
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'DELETE').length, 1);
      expect(find.text('Journal destination'), findsOneWidget);
    },
  );
  testWidgets('viewer reads photos without management controls', (
    tester,
  ) async {
    final container = await mount(tester, viewer: true);
    expect(find.text('Encounter with Ahmed (son)'), findsOneWidget);
    expect(find.text('Pin to keep'), findsNothing);
    expect(find.text('Delete photo'), findsNothing);
    expect(
      await container
          .read(mediaControllerProvider(key).notifier)
          .write(delete: true),
      false,
    );
    expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
  });
  testWidgets('offline reads show saved metadata with no photo loads', (
    tester,
  ) async {
    await tester.runAsync(repo.refresh);
    adapter.fail = true;
    final previews = c12.FakePreviews(bytes);
    await mount(tester, previews: previews);
    expect(find.text('Encounter with Ahmed (son)'), findsOneWidget);
    expect(previews.loads, 0);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('confirmed Pin with failed local update retries only the cache', (
    tester,
  ) async {
    await mount(tester);
    repo.cacheFails = true;
    await tester.tap(find.text('Pin to keep'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The change was saved'), findsOneWidget);
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    repo.cacheFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    expect(find.text('Journal destination'), findsOneWidget);
  });
  testWidgets(
    'video shows metadata and pending placeholder without image loads',
    (tester) async {
      adapter.video = true;
      final previews = c12.FakePreviews(bytes);
      await mount(tester, previews: previews);
      expect(find.text('Video'), findsOneWidget);
      expect(
        find.textContaining('Video playback will be available'),
        findsOneWidget,
      );
      expect(previews.loads, 0);
      expect(find.text('Delete video'), findsOneWidget);
    },
  );
  testWidgets(
    '403 photo failure refreshes detail once without an infinite loop',
    (tester) async {
      final previews = c12.FakePreviews(bytes)..forbidden = true;
      await mount(tester, previews: previews);
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
      expect(previews.loads, 2);
    },
  );
  testWidgets('leaving or changing account clears private photos and text', (
    tester,
  ) async {
    JournalScope? selected = key.$1;
    final previews = c12.FakePreviews(bytes);
    final container = await mount(
      tester,
      previews: previews,
      selected: () => selected,
    );
    final old = previews.clears;
    selected = null;
    container.invalidate(journalScopeProvider);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ahmed'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(previews.clears, greaterThan(old));
  });
  testWidgets('signed URL expiry hides photos at its exact boundary', (
    tester,
  ) async {
    await mount(tester);
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(adapter.requests.where((r) => r.method == 'GET').length, 1);
  });
  testWidgets(
    'background clears photos and failed resume remains metadata only',
    (tester) async {
      final previews = c12.FakePreviews(bytes);
      final container = await mount(tester, previews: previews);
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
      expect(container.read(mediaControllerProvider(key)).previews, false);
      adapter.fail = true;
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
      expect(find.textContaining('Ahmed'), findsOneWidget);
    },
  );
  test(
    'Home removal purges C13 details only for the affected caregiver',
    () async {
      await repo.refresh();
      final row = await db.select(db.cachedMediaDetails).getSingle();
      await db
          .into(db.cachedMediaDetails)
          .insert(
            CachedMediaDetailsCompanion.insert(
              caregiverId: 'other',
              patientId: row.patientId,
              id: row.id,
              payload: row.payload,
              refreshedAt: row.refreshedAt,
            ),
          );
      final h = ApiClient(
        config: ApiConfig('https://example.test/api/v1'),
        credentials: auth.TestCredentials(),
        adapter: home.HomeAdapter()..empty = true,
        onCredentialsInvalidated: (_) {},
      );
      try {
        await HomeRepository(h, db, key.$1.caregiverId).refresh(null);
      } finally {
        h.close();
      }
      expect(await repo.read(), isNull);
      expect(
        (await db.select(db.cachedMediaDetails).getSingle()).caregiverId,
        'other',
      );
    },
  );
  testWidgets('C12 media opens C13 and Back returns to the journal', (
    tester,
  ) async {
    await mount(tester, fromJournal: true);
    await tester.tap(find.text('Recording captured'));
    await tester.pumpAndSettle();
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Encounter with Ahmed (son)'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Journal'), findsOneWidget);
  });
  testWidgets(
    'uncertain write stays locked after failed refresh until a successful refresh',
    (tester) async {
      final container = await mount(tester);
      adapter.fail = true;
      final controller = container.read(mediaControllerProvider(key).notifier);
      final pending = controller.write(delete: false);
      await tester.pumpAndSettle();
      expect(await pending, false);
      expect(container.read(mediaControllerProvider(key)).uncertain, true);
      final failed = controller.refresh();
      await tester.pumpAndSettle();
      await failed;
      expect(container.read(mediaControllerProvider(key)).uncertain, true);
      expect(await controller.write(delete: false), false);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
      adapter.fail = false;
      final refresh = controller.refresh();
      await tester.pumpAndSettle();
      await refresh;
      expect(container.read(mediaControllerProvider(key)).uncertain, false);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C13 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, language: language);
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
          find.byKey(const Key('c13-preview')),
          matchesGoldenFile('goldens/c13_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C13 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
