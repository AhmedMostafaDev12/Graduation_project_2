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
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/journal/data/document_detail_repository.dart';
import 'package:remori/features/journal/domain/document_detail.dart';
import 'package:remori/features/journal/domain/journal_data.dart';
import 'package:remori/features/journal/data/media_repository.dart';
import 'package:remori/features/journal/domain/media_detail.dart';
import 'package:remori/features/journal/presentation/document_detail_providers.dart';
import 'package:remori/features/journal/presentation/journal_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c12_journal_test.dart' as c12;
import 'c14_documents_test.dart' as c14;
import 'c8_reminders_test.dart' as c8;

const key = (c12.scope, 'doc-0');
final now = c12.now;
const ocr = 'Pharmacy receipt\nConcor 5 mg × 1\nTotal: 120 EGP';

class Adapter implements HttpClientAdapter {
  bool fail = false, missing = false;
  Map<String, Object?>? invalid;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  Map<String, Object?> body() => {
    'id': key.$2,
    'event_id': 'event-0',
    'media_asset_id': 'media-0',
    'document_type': 'receipt',
    'title': 'Pharmacy receipt',
    'captured_at': '2026-10-01T08:45:00Z',
    'fields': [
      {
        'key': 'total',
        'label': 'Untrusted label',
        'value': '120 EGP',
        'type': 'text',
      },
      {'key': 'date', 'label': null, 'value': '2026-10-01', 'type': 'date'},
      {
        'key': 'items',
        'label': null,
        'value': 'Concor 5 mg × 1',
        'type': 'text',
      },
    ],
    'ocr_text': ocr,
    'url': 'https://example.test/full?signature=private',
    'thumbnail_url': 'https://example.test/thumb',
    'extracted_fields': {'secret': 'RAW_MUST_NOT_PERSIST'},
    'embedding': 'RAW_MUST_NOT_PERSIST',
    ...?invalid,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    final response = body();
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
                'error': {
                  'code': 'DOCUMENT_NOT_FOUND',
                  'message': 'Unavailable',
                },
              }
            : response,
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

class Repository extends DocumentDetailRepository {
  Repository(super.client, super.db, super.key, super.clock);
  final updates = StreamController<void>.broadcast();
  @override
  Stream<DocumentDetail?> watch() async* {
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
  void dispose() {
    if (!updates.isClosed) updates.close();
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
    final picture = await vg.loadPicture(
      SvgStringLoader(
        await File('design/screens/images/receipt.svg').readAsString(),
      ),
      null,
    );
    final image = await picture.picture.toImage(200, 200);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    picture.picture.dispose();
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
  Future<void> card({JournalScope scope = c12.scope}) => db
      .into(db.cachedDocuments)
      .insert(
        CachedDocumentsCompanion.insert(
          caregiverId: scope.caregiverId,
          patientId: scope.patientId,
          filter: 'all',
          id: key.$2,
          eventId: 'event-0',
          mediaAssetId: 'media-0',
          documentType: 'receipt',
          capturedAt: now,
          previewUntil: now.add(const Duration(minutes: 10)),
          position: 0,
        ),
      );

  test(
    'audited GET stores ordered display data, never raw extraction or bytes',
    () async {
      await card();
      await repo.refresh();
      final d = (await repo.read())!;
      expect(d.fields.map((f) => f.key), ['total', 'date', 'items']);
      expect(d.fields.first.label, isNull);
      expect(d.ocrText, ocr);
      expect(
        d.photo()!.previewUrl,
        'https://example.test/full?signature=private',
      );
      expect(d.previewUntil, now.add(const Duration(minutes: 10)));
      final payload =
          (await db.select(db.cachedDocumentDetails).getSingle()).payload;
      expect(payload, isNot(contains('RAW_MUST_NOT_PERSIST')));
      expect(payload, isNot(contains('thumbnail_url')));
      expect(adapter.requests.single.path, '/documents/doc-0');
      expect(adapter.requests.single.method, 'GET');
    },
  );
  test('uncached document makes no network request', () async {
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
  });
  test(
    'another account or patient cannot supply the cached association',
    () async {
      await card(
        scope: const JournalScope('other-account', 'other-patient', 'UTC'),
      );
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(adapter.requests, isEmpty);
    },
  );
  test('journal alone can verify a document and its event media', () async {
    await db
        .into(db.cachedJournalEntries)
        .insert(
          CachedJournalEntriesCompanion.insert(
            caregiverId: key.$1.caregiverId,
            patientId: key.$1.patientId,
            day: '2026-10-01',
            id: 'event-0',
            occurredAt: now,
            payload: jsonEncode({
              'document': {'id': key.$2},
            }),
          ),
        );
    await db
        .into(db.cachedJournalMedia)
        .insert(
          CachedJournalMediaCompanion.insert(
            caregiverId: key.$1.caregiverId,
            patientId: key.$1.patientId,
            day: '2026-10-01',
            id: 'media-0',
            eventId: 'event-0',
            payload: '{}',
            position: 0,
          ),
        );
    await repo.refresh();
    expect((await repo.read())?.id, key.$2);
  });
  for (final mismatch in [
    {'event_id': 'wrong'},
    {'media_asset_id': 'wrong'},
  ]) {
    test('mismatched document binding $mismatch is purged', () async {
      await card();
      await repo.refresh();
      adapter.invalid = mismatch;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect(await repo.read(), isNull);
      expect(await db.select(db.cachedDocuments).get(), isEmpty);
    });
  }
  test(
    'association removed during GET cannot be restored by late response',
    () async {
      await card();
      adapter.gate = Completer<void>();
      final pending = repo.refresh();
      while (adapter.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await db.delete(db.cachedDocuments).go();
      adapter.gate!.complete();
      await expectLater(pending, throwsA(isA<ApiFailure>()));
      expect(await db.select(db.cachedDocumentDetails).get(), isEmpty);
    },
  );
  test(
    'offline refresh preserves previously verified fields and OCR',
    () async {
      await card();
      await repo.refresh();
      adapter.fail = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read())?.ocrText, ocr);
    },
  );
  test('404 removes cached details and parent cards', () async {
    await card();
    await repo.refresh();
    adapter.missing = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(await repo.read(), isNull);
    expect(await db.select(db.cachedDocuments).get(), isEmpty);
  });
  for (final bad in [
    {'id': 'wrong'},
    {'patient_id': 'wrong'},
    {'document_type': 'unknown'},
    {'url': 'http://example.test/photo'},
    {'ocr_text': 7},
    {
      'fields': [
        {'key': 'date', 'value': '2026-02-30', 'type': 'date'},
      ],
    },
    {
      'fields': [
        {'key': 'unknown', 'value': 'x', 'type': 'text'},
      ],
    },
  ]) {
    test('invalid response does not overwrite saved detail: $bad', () async {
      await card();
      await repo.refresh();
      adapter.invalid = bad;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read())?.ocrText, ocr);
    });
  }
  test(
    'other documents preserve model labels; empty display values are valid',
    () async {
      await card();
      adapter.invalid = {
        'document_type': 'other',
        'fields': [
          {'key': null, 'label': 'عنوان', 'value': '', 'type': 'text'},
        ],
      };
      await repo.refresh();
      expect((await repo.read())!.fields.single.label, 'عنوان');
    },
  );

  test('confirmed media deletion removes its document detail', () async {
    await card();
    await repo.refresh();
    await MediaRepository(client, db, (
      key.$1,
      'media-0',
    ), () => now).cacheReceipt(const MediaReceipt(deleted: true));
    expect(await db.select(db.cachedDocumentDetails).get(), isEmpty);
  });
  test('disposed request cannot write a late detail response', () async {
    await card();
    adapter.gate = Completer<void>();
    final pending = repo.refresh();
    while (adapter.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    repo.dispose();
    adapter.gate!.complete();
    try {
      await pending;
    } on ApiFailure {
      /* cancelled */
    }
    expect(await db.select(db.cachedDocumentDetails).get(), isEmpty);
  });
  test('schema v11 upgrade preserves cards and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-c15-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      await card();
      await db.saveReminderLog(
        patientId: key.$1.patientId,
        reminderId: '00000005-0000-4000-8000-000000000001',
        scheduledAt: now,
        at: now,
        status: ReminderStatus.pending,
      );
      await db.customStatement('DROP TABLE cached_document_details');
      await db.customStatement(
        'ALTER TABLE dashboard_devices DROP COLUMN firmware_version',
      );
      await db.customStatement(
        'ALTER TABLE dashboard_devices DROP COLUMN paired_at',
      );
      await db.customStatement('PRAGMA user_version = 11');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect((await db.pendingWrites(key.$1.patientId)).length, 1);
      expect((await db.select(db.cachedDocuments).getSingle()).id, key.$2);
      expect(await db.select(db.cachedDocumentDetails).get(), isEmpty);
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
    } finally {
      if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
          !dir.path.contains('remori-c15-migration-')) {
        throw StateError('Unexpected temporary path');
      }
      await dir.delete(recursive: true);
    }
  });

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    c14.Previews? photos,
    JournalScope? Function()? selected,
  }) async {
    await tester.runAsync(() async {
      if ((await db.select(db.cachedDocuments).get()).isEmpty) await card();
    });
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
        documentDetailRepositoryProvider(key).overrideWithValue(repo),
        documentDetailPhotosProvider(key).overrideWith((ref) {
          final store = photos ?? c14.Previews([bytes, bytes]);
          ref.onDispose(store.clear);
          return store;
        }),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c15-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          RemoriScreen.c15.name,
          extra: {'patient_id': key.$1.patientId, 'document_id': key.$2},
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'viewer sees translated fields, patient-local capture and collapsible actual OCR',
    (tester) async {
      await mount(tester, viewer: true);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('120 EGP'), findsOneWidget);
      expect(find.text('Oct 1, 2026'), findsOneWidget);
      expect(find.textContaining('Thu 1 Oct, 11:45'), findsOneWidget);
      expect(find.text(ocr), findsNothing);
      await tester.tap(find.text('Full text read from the photo'));
      await tester.pumpAndSettle();
      expect(find.text(ocr), findsOneWidget);
      expect(adapter.requests.every((r) => r.method == 'GET'), true);
    },
  );
  testWidgets('offline saved fields and OCR display without loading photos', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await card();
      await repo.refresh();
    });
    adapter.fail = true;
    final photos = c14.Previews([bytes, bytes]);
    await mount(tester, photos: photos);
    expect(find.text('120 EGP'), findsOneWidget);
    expect(photos.loads, 0);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Full text read from the photo'));
    await tester.pumpAndSettle();
    expect(find.text(ocr), findsOneWidget);
  });
  testWidgets('background clears photos and failed resume keeps placeholders', (
    tester,
  ) async {
    final photos = c14.Previews([bytes, bytes]);
    final container = await mount(tester, photos: photos);
    final before = photos.clears;
    adapter.fail = true;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    expect(photos.clears, greaterThan(before));
    expect(
      container.read(documentDetailControllerProvider(key)).previews,
      false,
    );
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('120 EGP'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('signed URL expiry clears and hides the full image', (
    tester,
  ) async {
    final photos = c14.Previews([bytes, bytes]);
    await mount(tester, photos: photos);
    final before = photos.clears;
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();
    expect(photos.clears, greaterThan(before));
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('photo 403 refreshes detail at most once automatically', (
    tester,
  ) async {
    final photos = c14.Previews([bytes, bytes])..forbidden = true;
    await mount(tester, photos: photos);
    expect(adapter.requests.length, 2);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('changing account or patient removes document text and photos', (
    tester,
  ) async {
    JournalScope? selected = key.$1;
    final photos = c14.Previews([bytes, bytes]);
    final container = await mount(
      tester,
      photos: photos,
      selected: () => selected,
    );
    final before = photos.clears;
    selected = null;
    container.invalidate(journalScopeProvider);
    await tester.pumpAndSettle();
    expect(find.text('120 EGP'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(photos.clears, greaterThan(before));
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C15 $language reference capture', (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      await mount(tester, language: language);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c15-preview')),
          matchesGoldenFile('goldens/c15_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C15 $language supports 2x text at 320dp', (tester) async {
      await mount(tester, language: language, scale: 2);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
