import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:remori/features/journal/data/documents_repository.dart';
import 'package:remori/features/journal/data/journal_previews.dart';
import 'package:remori/features/journal/data/media_repository.dart';
import 'package:remori/features/journal/domain/document_data.dart';
import 'package:remori/features/journal/domain/journal_data.dart';
import 'package:remori/features/journal/domain/media_detail.dart';
import 'package:remori/features/journal/presentation/documents_providers.dart';
import 'package:remori/features/journal/presentation/journal_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as home;
import 'c12_journal_test.dart' as c12;
import 'c8_reminders_test.dart' as c8;

const key = (c12.scope, DocumentFilter.all);
final now = c12.now;

class Adapter implements HttpClientAdapter {
  int count = 2;
  bool fail = false, missing = false, duplicate = false;
  Map<String, Object?>? invalid;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  Map<String, Object?> card(int i) => {
    'id': 'doc-$i',
    'event_id': 'event-$i',
    'media_asset_id': 'media-$i',
    'document_type': ['receipt', 'medication_label', 'bill', 'other'][i % 4],
    'title': i == 0
        ? 'Pharmacy receipt'
        : i == 1
        ? 'Medication label'
        : 'Document $i',
    'headline': i == 0
        ? '120 EGP'
        : i == 1
        ? 'Concor 5 mg'
        : null,
    'captured_at': now.subtract(Duration(hours: i)).toIso8601String(),
    'url': 'https://example.test/full-$i?signature=private',
    'thumbnail_url': 'https://example.test/thumb-$i?signature=private',
    'ocr_text': 'PRIVATE OCR',
    'extracted_fields': {'PRIVATE': 'MUST NOT BE STORED'},
    'fields': [
      {'value': 'PRIVATE'},
    ],
    if (i == 0) ...?invalid,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    final all = [for (var i = 0; i < count; i++) card(i)]
        .where(
          (p) =>
              o.queryParameters['type'] == null ||
              p['document_type'] == o.queryParameters['type'],
        )
        .toList();
    final offset = o.queryParameters['offset'] as int;
    final page = all.skip(offset).take(50).toList();
    if (duplicate && page.isNotEmpty) page.add(page.first);
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
            : page,
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

DocumentsData fixture({bool more = false}) => DocumentsData(
  refreshedAt: now,
  hasMore: more,
  nextOffset: 50,
  documents: [
    for (var i = 0; i < 2; i++)
      DocumentCard(
        id: 'doc-$i',
        eventId: 'event-$i',
        mediaId: 'media-$i',
        type: i == 0 ? 'receipt' : 'medication_label',
        capturedAt: now.subtract(Duration(days: i)),
        previewUntil: now.add(const Duration(minutes: 10)),
        title: i == 0 ? 'Pharmacy receipt' : 'Medication label',
        headline: i == 0 ? '120 EGP' : 'Concor 5 mg',
        url: 'https://example.test/full-$i',
        thumbnailUrl: 'https://example.test/thumb-$i',
      ),
  ],
);

class FakeRepository extends DocumentsRepository {
  FakeRepository(super.client, super.db, super.key, super.clock);
  DocumentsData data = fixture();
  bool fail = false;
  int refreshes = 0, pages = 0;
  Completer<void>? gate;
  final updates = StreamController<void>.broadcast();
  @override
  Future<void> refresh() async {
    refreshes++;
    if (gate != null) await gate!.future;
    if (fail) {
      throw ApiFailure(ApiFailureKind.network);
    }
    updates.add(null);
  }

  @override
  Future<void> loadMore() async {
    pages++;
    if (fail) {
      throw ApiFailure(ApiFailureKind.network);
    }
    data = fixture();
    updates.add(null);
  }

  @override
  Stream<DocumentsData> watch() async* {
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

class Previews implements JournalPreviews {
  Previews(this.frames);
  final List<Uint8List> frames;
  final pending = <String, Future<Uint8List>>{};
  int loads = 0, clears = 0, expirations = 0;
  bool forbidden = false;
  @override
  Future<Uint8List> load(JournalMedia photo) =>
      pending.putIfAbsent(photo.id, () {
        loads++;
        return forbidden
            ? Future.error(const JournalPreviewFailure(403))
            : Future.value(frames[photo.id.endsWith('1') ? 1 : 0]);
      });
  @override
  void expire(DateTime now) {
    expirations++;
  }

  @override
  void clear() {
    clears++;
    pending.clear();
    for (final bytes in frames) {
      PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
    }
  }

  @override
  void dispose() => clear();
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late DocumentsRepository repo;
  late List<Uint8List> frames;
  setUpAll(() async {
    frames = [];
    for (final name in ['receipt', 'medbox']) {
      final picture = await vg.loadPicture(
        SvgStringLoader(
          await File('design/screens/images/$name.svg').readAsString(),
        ),
        null,
      );
      final image = await picture.picture.toImage(200, 200);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      frames.add(bytes!.buffer.asUint8List());
      image.dispose();
      picture.picture.dispose();
    }
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
    repo = DocumentsRepository(client, db, key, () => now);
  });
  tearDown(() async {
    client.close();
    await db.close();
  });
  test(
    'GET stores only document card metadata and uses list thumbnails',
    () async {
      await repo.refresh();
      final data = await repo.read();
      expect(data.documents.map((d) => d.id), ['doc-0', 'doc-1']);
      expect(data.documents.first.title, 'Pharmacy receipt');
      expect(data.documents.first.preview()?.url, contains('/thumb-0'));
      expect(data.nextOffset, 2);
      expect(data.hasMore, false);
      expect(
        adapter.requests.single.path,
        '/patients/${key.$1.patientId}/documents',
      );
      expect(adapter.requests.single.queryParameters, {
        'limit': 50,
        'offset': 0,
      });
      final columns = await db
          .customSelect('PRAGMA table_info(cached_documents)')
          .get();
      expect(
        columns.map((r) => r.read<String>('name')),
        isNot(contains('ocr_text')),
      );
      expect(
        columns.map((r) => r.read<String>('name')),
        isNot(contains('extracted_fields')),
      );
    },
  );
  test(
    'pages append newest-first, advance by API count and stop at the last page',
    () async {
      adapter.count = 53;
      await repo.refresh();
      expect((await repo.read()).documents.length, 50);
      expect((await repo.read()).hasMore, true);
      await repo.loadMore();
      final data = await repo.read();
      expect(data.documents.length, 53);
      expect(data.nextOffset, 53);
      expect(data.hasMore, false);
      expect(adapter.requests.last.queryParameters['offset'], 50);
      await repo.loadMore();
      expect(adapter.requests.length, 2);
      expect(data.documents.last.id, 'doc-52');
    },
  );
  test(
    'filtered requests stay isolated and reject unexpected document types',
    () async {
      await repo.refresh();
      final filtered = DocumentsRepository(client, db, (
        key.$1,
        DocumentFilter.receipts,
      ), () => now);
      await filtered.refresh();
      expect((await filtered.read()).documents.single.type, 'receipt');
      expect(adapter.requests.last.queryParameters['type'], 'receipt');
      expect((await repo.read()).documents.length, 2);
    },
  );
  for (final bad in [
    {'title': 4},
    {'document_type': 'unknown'},
    {'patient_id': 'other'},
    {'captured_at': '2026-10-15T08:00:00'},
    {'url': 'http://example.test/photo'},
    {'media_asset_id': null},
  ]) {
    test(
      'malformed ${bad.keys.single} page preserves the saved cache',
      () async {
        await repo.refresh();
        adapter.invalid = bad;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect((await repo.read()).documents.length, 2);
      },
    );
  }
  test('duplicate IDs are rejected atomically', () async {
    await repo.refresh();
    adapter.duplicate = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).documents.length, 2);
  });
  test(
    'failed next page preserves existing cards and offset for retry',
    () async {
      adapter.count = 53;
      await repo.refresh();
      adapter.fail = true;
      await expectLater(repo.loadMore(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).documents.length, 50);
      expect((await repo.read()).nextOffset, 50);
      adapter.fail = false;
      await repo.loadMore();
      expect((await repo.read()).documents.length, 53);
    },
  );
  test(
    'null title/headline and missing images remain real nullable metadata',
    () async {
      adapter.invalid = {
        'title': null,
        'headline': null,
        'url': null,
        'thumbnail_url': null,
      };
      await repo.refresh();
      final d = (await repo.read()).documents.first;
      expect(d.title, isNull);
      expect(d.headline, isNull);
      expect(d.preview(), isNull);
    },
  );
  test(
    'refresh replaces only the selected filter and caregiver cache',
    () async {
      await repo.refresh();
      final other = DocumentsRepository(client, db, (
        const JournalScope('other', home.patient, 'Africa/Cairo'),
        DocumentFilter.all,
      ), () => now);
      await other.refresh();
      adapter.count = 0;
      await repo.refresh();
      expect((await repo.read()).documents, isEmpty);
      expect((await other.read()).documents.length, 2);
    },
  );
  test('known missing patient purges all filter caches only for the affected scope', () async {
    await repo.refresh();
    final filtered = DocumentsRepository(client, db, (
      key.$1,
      DocumentFilter.receipts,
    ), () => now);
    await filtered.refresh();
    adapter.missing = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await filtered.read()).documents, isEmpty);
    expect((await repo.read()).refreshedAt, isNull);
  });
  test('late response cannot write after disposal', () async {
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
    expect((await repo.read()).documents, isEmpty);
  });
  test(
    'Home link removal clears document cards and pagination metadata',
    () async {
      await repo.refresh();
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
      expect((await repo.read()).refreshedAt, isNull);
      expect(await db.select(db.cachedDocuments).get(), isEmpty);
    },
  );
  test('confirmed media deletion removes documents by media ID and invalidates pagination', () async {
    await repo.refresh();
    await MediaRepository(client, db, (
      key.$1,
      'media-0',
    ), () => now).cacheReceipt(const MediaReceipt(deleted: true));
    expect((await repo.read()).documents.single.id, 'doc-1');
    expect((await repo.read()).hasMore, false);
    expect((await repo.read()).nextOffset, 0);
  });
  test(
    'schema v10 upgrade preserves media details and pending writes',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp(
        'remori-c14-migration-',
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
        await db
            .into(db.cachedMediaDetails)
            .insert(
              CachedMediaDetailsCompanion.insert(
                caregiverId: key.$1.caregiverId,
                patientId: key.$1.patientId,
                id: 'media',
                payload: '{}',
                refreshedAt: now,
              ),
            );
        await db.customStatement('DROP TABLE cached_document_details');
        await db.customStatement('DROP TABLE cached_documents');
        await db.customStatement('DROP TABLE documents_cache_states');
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN firmware_version',
        );
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN paired_at',
        );
        await db.customStatement('DROP TABLE cached_caregiver_accounts');
        await db.customStatement('DROP TABLE cached_consents');
        await db.customStatement('DROP TABLE cached_caregiver_links');
        await db.customStatement('DROP TABLE caregivers_cache_states');
        await db.customStatement('DROP TABLE patient_today_settings');
        await db.customStatement('DROP TABLE patient_reminder_cards');
        await db.customStatement('DROP TABLE patient_known_encounters');
        await db.customStatement('DROP TABLE patient_journal_entries');
        await db.customStatement('DROP TABLE patient_journal_media');
        await db.customStatement('DROP TABLE patient_journal_days');
        await db.customStatement('DROP TABLE patient_memory_details');
        await db.customStatement('DROP TABLE patient_game_scores');
        await db.customStatement('DROP TABLE patient_game_refreshes');
        await db.customStatement('DROP TABLE patient_game_people');
        await db.customStatement('DROP TABLE patient_game_sessions');
        await db.customStatement('PRAGMA user_version = 10');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect((await db.pendingWrites(key.$1.patientId)).length, 1);
        expect(
          (await db.select(db.cachedMediaDetails).getSingle()).id,
          'media',
        );
        expect(await db.select(db.cachedDocuments).get(), isEmpty);
        expect(await db.select(db.documentsCacheStates).get(), isEmpty);
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
      } finally {
        if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
            !dir.path.contains('remori-c14-migration-')) {
          throw StateError('Unexpected temporary path');
        }
        await dir.delete(recursive: true);
      }
    },
  );
  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeRepository fake, {
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Previews? previews,
    JournalScope? Function()? selected,
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
          (ref) => selected == null ? key.$1 : selected(),
        ),
        journalClockProvider.overrideWithValue(() => now),
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
        documentsRepositoryProvider(key).overrideWithValue(fake),
        documentsPreviewsProvider(key).overrideWith((ref) {
          final store = previews ?? Previews(frames);
          ref.onDispose(store.clear);
          return store;
        }),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c18: (_, _) => const Text('More destination'),
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
          key: Key('c14-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c14.name);
    await tester.pumpAndSettle();
    return container;
  }

  FakeRepository fake() => FakeRepository(client, db, key, () => now);
  testWidgets('C14 shows actual cards and opens scoped document details', (
    tester,
  ) async {
    final f = fake();
    await mount(tester, f);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Pharmacy receipt'), findsOneWidget);
    expect(find.text('120 EGP'), findsOneWidget);
    expect(find.textContaining('Thu 15 Oct, 11:00'), findsOneWidget);
    await tester.tap(find.text('Pharmacy receipt'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          {'patient_id': key.$1.patientId, 'document_id': 'doc-0'}.toString(),
        ),
      ),
      findsOneWidget,
    );
    expect(f.refreshes, 1);
  });
  testWidgets('filter changes hide old cards and clear their photos', (
    tester,
  ) async {
    final previews = Previews(frames);
    final container = await mount(tester, fake(), previews: previews);
    final before = previews.clears;
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(container.read(documentsFilterProvider), DocumentFilter.bills);
    expect(find.text('Pharmacy receipt'), findsNothing);
    expect(previews.clears, greaterThan(before));
  });
  testWidgets('offline cards have placeholders until a successful retry', (
    tester,
  ) async {
    final f = fake()..fail = true;
    final previews = Previews(frames);
    await mount(tester, f, previews: previews);
    expect(find.text('Pharmacy receipt'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(previews.loads, 0);
    f.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(previews.loads, 2);
  });
  testWidgets('scrolling near the end requests the next page', (tester) async {
    final f = fake()
      ..data = DocumentsData(
        hasMore: true,
        nextOffset: 50,
        refreshedAt: now,
        documents: [
          for (var i = 0; i < 50; i++)
            DocumentCard(
              id: 'page-$i',
              eventId: 'event-$i',
              mediaId: 'media-$i',
              type: 'receipt',
              capturedAt: now,
              previewUntil: now.add(const Duration(minutes: 10)),
              title: 'Document $i',
            ),
        ],
      );
    await mount(tester, f);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(f.pages, 1);
  });
  testWidgets('403 previews trigger bounded list refreshes', (tester) async {
    final f = fake();
    final previews = Previews(frames)..forbidden = true;
    await mount(tester, f, previews: previews);
    expect(f.refreshes, lessThanOrEqualTo(3));
    expect(f.refreshes, greaterThan(1));
    expect(find.byType(Image), findsNothing);
  });
  testWidgets(
    'changing patient hides private cards and ignores an old refresh',
    (tester) async {
      JournalScope? selected = key.$1;
      final f = fake();
      final container = await mount(tester, f, selected: () => selected);
      f.gate = Completer<void>();
      final pending = container
          .read(documentsControllerProvider.notifier)
          .refresh();
      selected = null;
      container.invalidate(journalScopeProvider);
      await tester.pumpAndSettle();
      f.gate!.complete();
      await pending;
      await tester.pumpAndSettle();
      expect(find.text('Pharmacy receipt'), findsNothing);
      expect(container.read(documentsControllerProvider).previews, false);
    },
  );
  testWidgets(
    'expiry clears preview bytes and hides thumbnails without another GET',
    (tester) async {
      final f = fake();
      final previews = Previews(frames);
      await mount(tester, f, previews: previews);
      expect(find.byType(Image), findsNWidgets(2));
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(previews.expirations, greaterThan(0));
      expect(f.refreshes, 1);
    },
  );
  testWidgets(
    'background and failed resume keep saved cards but clear photos',
    (tester) async {
      final f = fake();
      final previews = Previews(frames);
      await mount(tester, f, previews: previews);
      final old = previews.clears;
      for (final life in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(life);
        await tester.pump();
      }
      expect(previews.clears, greaterThan(old));
      f.fail = true;
      for (final life in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(life);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Pharmacy receipt'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
  testWidgets('viewer reads documents without the manager center action', (
    tester,
  ) async {
    await mount(tester, fake(), viewer: true);
    expect(find.text('Pharmacy receipt'), findsOneWidget);
    expect(find.byTooltip('Add reminder'), findsNothing);
  });
  testWidgets(
    'Back opens More and the existing manager center action opens C9',
    (tester) async {
      final container = await mount(tester, fake());
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('More destination'), findsOneWidget);
      container.read(remoriRouterProvider).goNamed(RemoriScreen.c14.name);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Reminder destination'), findsOneWidget);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C14 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, fake(), language: language);
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
          find.byKey(const Key('c14-preview')),
          matchesGoldenFile('goldens/c14_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C14 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        fake(),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
