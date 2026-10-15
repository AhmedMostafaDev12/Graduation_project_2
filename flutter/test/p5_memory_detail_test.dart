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
import 'package:remori/core/db/remori_database.dart' hide PatientMemoryDetail;
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';
import 'package:remori/features/patient_journal/data/patient_journal_repository.dart';
import 'package:remori/features/patient_journal/data/patient_memory_repository.dart';
import 'package:remori/features/patient_journal/domain/patient_memory_detail.dart';
import 'package:remori/features/patient_journal/domain/patient_journal_data.dart';
import 'package:remori/features/patient_journal/presentation/patient_journal_providers.dart';
import 'package:remori/features/patient_journal/presentation/patient_memory_providers.dart';
import 'package:remori/features/patient_journal/presentation/p4_my_day_screen.dart';
import 'package:remori/features/patient_journal/presentation/p5_memory_detail_screen.dart';

import 'a6_handover_test.dart' as auth;
import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;
import 'p4_my_day_test.dart' as p4;

const target = (journal: p4.today, eventId: 'event-3', mediaId: 'photo');
const widgetTarget = (
  journal: p4.today,
  eventId: 'recording',
  mediaId: 'photo',
);
PatientMemoryDetail detail({String type = 'image', String name = 'Ahmed'}) =>
    PatientMemoryDetail(
      id: 'photo',
      eventId: 'recording',
      type: type,
      status: 'confirmed',
      at: p1.now,
      refreshedAt: p1.now,
      url: 'https://images.example.test/full.jpg',
      validUntil: p1.now.add(const Duration(minutes: 10)),
      eventType: 'encounter',
      person: JournalPerson('person', name, 'son'),
    );

class Adapter extends p4.Adapter {
  String? invalid;
  int? getStatus, deleteStatus;
  Completer<void>? mediaGate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.contains('/media/')) {
      return super.fetch(options, requestStream, cancelFuture);
    }
    requests.add(options);
    if (options.method == 'DELETE') {
      return ResponseBody.fromString('', deleteStatus ?? 204);
    }
    if (mediaGate != null) await mediaGate!.future;
    return ResponseBody.fromString(
      jsonEncode({
        'id': invalid == 'id' ? 'other' : 'photo',
        'patient_id': invalid == 'patient' ? 'other' : auth.patient,
        'event_id': invalid == 'event' ? 'other' : 'event-3',
        'asset_type': invalid == 'type' ? 'audio' : 'image',
        'status': 'confirmed',
        'retention_policy': 'auto_expire',
        'expires_at': p1.now.add(const Duration(days: 1)).toIso8601String(),
        'duration_seconds': null,
        'url': invalid == 'url' ? 'http://unsafe.test/photo' : p4.photo.url,
        'url_expires_in': invalid == 'expiry' ? -1 : 600,
        'created_at': p1.now.toIso8601String(),
        'event': {
          'id': invalid == 'nestedEvent' ? 'other' : 'event-3',
          'event_type': 'encounter',
          'occurred_at': p1.now.toIso8601String(),
          'person': {
            'id': 'person',
            'name': 'Ahmed',
            'relationship': 'son',
            'embedding': 'PRIVATE',
          },
        },
        'ai_tags': ['PRIVATE'],
        'transcript_text': 'PRIVATE',
        'image_bytes': 'PRIVATE',
      }),
      getStatus ?? 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class FakeMemory extends PatientMemoryRepository {
  FakeMemory(
    super.client,
    super.db,
    super.target,
    super.clock, {
    required super.current,
    required this.data,
  });
  PatientMemoryDetail? data;
  int refreshes = 0, deletes = 0, cleanups = 0;
  bool offline = false, cleanupFails = false, uncertain = false;
  Completer<void>? refreshGate;
  final updates = StreamController<PatientMemoryDetail?>.broadcast();
  @override
  Future<void> refresh() async {
    refreshes++;
    if (refreshGate != null) await refreshGate!.future;
    if (offline) throw ApiFailure(ApiFailureKind.network);
    updates.add(data);
  }

  @override
  Future<PatientMemoryDetail?> read() async => data;
  @override
  Stream<PatientMemoryDetail?> watch() async* {
    yield data;
    yield* updates.stream;
  }

  @override
  Future<void> remove() async {
    deletes++;
    if (uncertain) throw ApiFailure(ApiFailureKind.network);
  }

  @override
  Future<void> cacheDeletion() async {
    cleanups++;
    if (cleanupFails) throw StateError('Local write unavailable');
    data = null;
    updates.add(null);
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
  late PatientMemoryRepository repo;
  late bool current;
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
    current = true;
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = Adapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      onCredentialsInvalidated: (_) {},
      adapter: adapter,
    );
    repo = PatientMemoryRepository(
      client,
      db,
      target,
      () => p1.now,
      current: () => current,
    );
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
  });
  Future<void> seed() async {
    final journal = PatientJournalRepository(
      client,
      db,
      p4.today,
      () => p1.now,
      current: () => true,
    );
    await journal.refresh();
    journal.dispose();
  }

  test(
    'audited device GET stores only allowlisted detail, verified against P4',
    () async {
      await seed();
      await repo.refresh();
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer test-device',
      );
      final saved = (await db.select(db.patientMemoryDetails).get()).single;
      expect(saved.payload, isNot(contains('PRIVATE')));
      expect((await repo.read())!.person!.name, 'Ahmed');
      expect(
        (await repo.read())!.validUntil,
        p1.now.add(const Duration(minutes: 10)),
      );
      expect(await db.pendingWrites(auth.patient), isEmpty);
    },
  );
  for (final invalid in [
    'id',
    'patient',
    'event',
    'nestedEvent',
    'type',
    'url',
    'expiry',
  ]) {
    test('invalid $invalid cannot replace a verified cached detail', () async {
      await seed();
      await repo.refresh();
      final before =
          (await db.select(db.patientMemoryDetails).get()).single.payload;
      adapter.invalid = invalid;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(
        (await db.select(db.patientMemoryDetails).get()).single.payload,
        before,
      );
    });
  }
  test('uncached and wrong-device links make no media request', () async {
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
    await seed();
    final wrong = PatientMemoryRepository(
      client,
      db,
      (
        journal: (p2.otherKey, p4.today.$2, p4.today.$3),
        eventId: target.eventId,
        mediaId: target.mediaId,
      ),
      () => p1.now,
      current: () => true,
    );
    final count = adapter.requests.length;
    await expectLater(wrong.refresh(), throwsA(isA<ApiFailure>()));
    expect(await wrong.read(), isNull);
    expect(adapter.requests.length, count);
    wrong.dispose();
  });
  test(
    'offline preserves metadata and late scope response cannot save',
    () async {
      await seed();
      await repo.refresh();
      adapter.getStatus = 503;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(await repo.read(), isNotNull);
      adapter.getStatus = null;
      await db.delete(db.patientMemoryDetails).go();
      adapter.mediaGate = Completer<void>();
      final pending = repo.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      current = false;
      adapter.mediaGate!.complete();
      await pending;
      expect(await db.select(db.patientMemoryDetails).get(), isEmpty);
    },
  );
  test('confirmed device deletion cleans P5 and all current-device P4 references only', () async {
    await seed();
    await repo.refresh();
    final other = PatientJournalRepository(
      client,
      db,
      (p2.otherKey, p4.today.$2, p4.today.$3),
      () => p1.now,
      current: () => true,
    );
    await other.refresh();
    other.dispose();
    await repo.remove();
    expect(repo.deleted, isTrue);
    expect(adapter.requests.last.method, 'DELETE');
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer test-device',
    );
    await repo.cacheDeletion();
    await repo.cacheDeletion();
    expect(await repo.read(), isNull);
    expect(await db.select(db.patientMemoryDetails).get(), isEmpty);
    expect(await db.select(db.patientJournalMedia).get(), hasLength(1));
    expect(
      (await db.select(db.patientJournalMedia).get()).every(
        (r) => r.deviceId == p2.otherKey.$2,
      ),
      isTrue,
    );
    expect(await db.pendingWrites(auth.patient), isEmpty);
  });
  test('audited 404 removes stale references', () async {
    await seed();
    await repo.refresh();
    adapter.getStatus = 404;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(repo.deleted, isTrue);
    expect(await repo.read(), isNull);
    expect(await db.select(db.patientJournalMedia).get(), isEmpty);
  });
  test('failed DELETE leaves local data intact', () async {
    await seed();
    await repo.refresh();
    adapter.deleteStatus = 503;
    await expectLater(repo.remove(), throwsA(isA<ApiFailure>()));
    expect(repo.deleted, isFalse);
    expect(await repo.read(), isNotNull);
  });

  test('v18 migration preserves P4 media and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-p5-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      repo = PatientMemoryRepository(
        client,
        db,
        target,
        () => p1.now,
        current: () => true,
      );
      await seed();
      await db.saveReminderLog(
        patientId: auth.patient,
        reminderId: p1.reminder,
        scheduledAt: p1.now,
        at: p1.now,
        status: ReminderStatus.pending,
      );
      await db.customStatement('DROP TABLE patient_memory_details');
      await db.customStatement('DROP TABLE patient_game_scores');
      await db.customStatement('DROP TABLE patient_game_refreshes');
      await db.customStatement('PRAGMA user_version = 18');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect(await db.select(db.patientMemoryDetails).get(), isEmpty);
      expect(await db.select(db.patientJournalMedia).get(), hasLength(1));
      expect(await db.pendingWrites(auth.patient), hasLength(1));
    } finally {
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
      final absolute = dir.absolute;
      if (absolute.parent.path == Directory.systemTemp.absolute.path &&
          absolute.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('remori-p5-migration-')) {
        await absolute.delete(recursive: true);
      }
    }
  });

  late FakeMemory fake;
  late p4.FakePreviews photos;
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    double scale = 1,
    bool offline = false,
    String type = 'image',
    bool startP4 = false,
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
    fake = FakeMemory(
      client,
      db,
      widgetTarget,
      () => p1.now,
      current: () => true,
      data: detail(type: type, name: language == 'ar' ? 'أحمد' : 'Ahmed'),
    )..offline = offline;
    photos = p4.FakePreviews(bytes)..status = photoStatus;
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith(
          (ref) => ref.watch(p2.selectedScope),
        ),
        patientTodayDataProvider(p1.key).overrideWith(
          (ref) => Stream.value(
            const PatientTodayData(
              settings: PatientSettings('Patient', 'en', 'Africa/Cairo', true),
            ),
          ),
        ),
        patientTodayClockProvider.overrideWithValue(() => p1.now),
        patientTodayNowProvider.overrideWith((ref) => Stream.value(p1.now)),
        patientAlertCandidateProvider.overrideWithValue(null),
        patientMemoryRepositoryProvider.overrideWith((ref, t) => fake),
        patientMemoryPhotosProvider.overrideWith((ref, t) {
          ref.onDispose(photos.dispose);
          return photos;
        }),
        patientJournalRepositoryProvider.overrideWith((ref, k) {
          final f = p4.FakeRepository(
            client,
            db,
            k,
            () => p1.now,
            current: () => true,
            data: p4.fixture(k),
          );
          ref.onDispose(f.dispose);
          return f;
        }),
        patientJournalPreviewsProvider.overrideWith((ref, k) {
          final f = p4.FakePreviews(bytes);
          ref.onDispose(f.dispose);
          return f;
        }),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
        screenBuildersProvider.overrideWith(
          (ref) => {
            RemoriScreen.p1: (_, _) => const Text('Today destination'),
            RemoriScreen.p4: (_, _) => const P4MyDayScreen(),
            RemoriScreen.p5: (_, state) => P5MemoryDetailScreen(
              target: state.extra as PatientMemoryTarget?,
            ),
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
          key: Key('p5-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    c
        .read(remoriRouterProvider)
        .goNamed(
          startP4 ? RemoriScreen.p4.name : RemoriScreen.p5.name,
          extra: startP4 ? null : widgetTarget,
        );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete(WidgetTester tester, {String label = 'Delete'}) async {
    await tester.ensureVisible(find.text(label).last);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'P4 media opens P5; Back returns to My Day; text-only entries stay read-only',
    (tester) async {
      final c = await mount(tester, startP4: true);
      await tester.tap(find.textContaining('You met Ahmed'));
      await tester.pumpAndSettle();
      expect(find.byType(P4MyDayScreen), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('patient-day-recording')),
      );
      await tester.tap(find.byKey(const ValueKey('patient-day-recording')));
      await tester.pumpAndSettle();
      expect(find.byType(P5MemoryDetailScreen), findsOneWidget);
      expect(find.byType(RemoriNavigationBar), findsNothing);
      expect(find.text('You met Ahmed'), findsOneWidget);
      expect(photos.loads, 1);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(P4MyDayScreen), findsOneWidget);
      await unmount(tester, c);
    },
  );
  testWidgets('offline cached metadata never authorizes a photo or deletion', (
    tester,
  ) async {
    final c = await mount(tester, offline: true);
    expect(find.text('You met Ahmed'), findsOneWidget);
    expect(photos.loads, 0);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Delete'))
          .onPressed,
      isNull,
    );
    await unmount(tester, c);
  });
  testWidgets(
    'video metadata has a playback-pending placeholder and no image download',
    (tester) async {
      final c = await mount(tester, type: 'video');
      expect(find.textContaining('This is a video memory.'), findsOneWidget);
      expect(photos.loads, 0);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'delete asks first; cancel preserves memory; confirmation returns to My Day',
    (tester) async {
      final c = await mount(tester);
      await tapDelete(tester);
      expect(fake.deletes, 0);
      await tester.tap(find.text('Keep memory'));
      await tester.pumpAndSettle();
      expect(fake.deletes, 0);
      await tapDelete(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(fake.deletes, 1);
      expect(fake.cleanups, 1);
      expect(find.byType(P4MyDayScreen), findsOneWidget);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'confirmed deletion retries local cleanup without a second DELETE',
    (tester) async {
      final c = await mount(tester);
      fake.cleanupFails = true;
      await tapDelete(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('The memory was deleted.'), findsOneWidget);
      expect(fake.deletes, 1);
      fake.cleanupFails = false;
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(fake.deletes, 1);
      expect(fake.cleanups, 2);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'uncertain deletion requires successful refresh before another attempt',
    (tester) async {
      final c = await mount(tester);
      fake.uncertain = true;
      await tapDelete(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(
        c.read(patientMemoryControllerProvider(widgetTarget)).uncertain,
        isTrue,
      );
      expect(
        await c
            .read(patientMemoryControllerProvider(widgetTarget).notifier)
            .remove(),
        isFalse,
      );
      expect(fake.deletes, 1);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        c.read(patientMemoryControllerProvider(widgetTarget)).uncertain,
        isFalse,
      );
      await unmount(tester, c);
    },
  );
  testWidgets(
    'background clears photos and resume requires another audited refresh',
    (tester) async {
      final c = await mount(tester);
      final clears = photos.clears;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(photos.clears, greaterThan(clears));
      expect(
        c.read(patientMemoryControllerProvider(widgetTarget)).fresh,
        isNull,
      );
      fake.offline = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(fake.refreshes, 2);
      expect(find.byType(Image), findsNothing);
      await unmount(tester, c);
    },
  );
  testWidgets('403 recovery is bounded to one audited refresh', (tester) async {
    final c = await mount(tester, photoStatus: 403);
    expect(fake.refreshes, 2);
    expect(photos.loads, 2);
    await unmount(tester, c);
  });
  testWidgets('signed photo expiry clears bytes and hides the image', (
    tester,
  ) async {
    final c = await mount(tester);
    final clears = photos.clears;
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();
    expect(photos.clears, greaterThan(clears));
    expect(find.byType(Image), findsNothing);
    await unmount(tester, c);
  });
  testWidgets('an old refresh cannot restore a photo after backgrounding', (
    tester,
  ) async {
    final c = await mount(tester);
    fake.refreshGate = Completer<void>();
    final pending = c
        .read(patientMemoryControllerProvider(widgetTarget).notifier)
        .refresh();
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    fake.refreshGate!.complete();
    await pending;
    await tester.pumpAndSettle();
    expect(c.read(patientMemoryControllerProvider(widgetTarget)).fresh, isNull);
    fake.offline = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await unmount(tester, c);
  });
  testWidgets(
    'scope change hides previous names and prevents confirmation write',
    (tester) async {
      final c = await mount(tester);
      await tapDelete(tester);
      c.read(p2.selectedScope.notifier).select(p2.otherKey);
      await tester.pumpAndSettle();
      expect(find.text('You met Ahmed'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(fake.deletes, 0);
      await unmount(tester, c);
    },
  );
  for (final lang in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('P5 $lang at ${scale}x is readable and scrollable', (
        tester,
      ) async {
        final c = await mount(tester, language: lang, scale: scale);
        await tester.runAsync(
          () => precacheImage(
            MemoryImage(bytes),
            tester.element(find.byType(P5MemoryDetailScreen)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('p5-preview')),
            matchesGoldenFile('goldens/p5_${lang}_${scale}x.png'),
          );
        }
        final label = lang == 'ar' ? 'امسح' : 'Delete';
        await tester.ensureVisible(find.text(label));
        expect(
          tester.getSize(find.widgetWithText(OutlinedButton, label)).height,
          greaterThanOrEqualTo(64),
        );
        await tapDelete(tester, label: label);
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.text(lang == 'ar' ? 'احتفظ بالذكرى' : 'Keep memory'),
        );
        await tester.pumpAndSettle();
        await unmount(tester, c);
      });
    }
  }
}
