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
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/people/data/unknown_faces_repository.dart';
import 'package:remori/features/people/data/unknown_face_previews.dart';
import 'package:remori/features/people/domain/people_data.dart';
import 'package:remori/features/people/domain/unknown_faces_data.dart';
import 'package:remori/features/people/presentation/people_providers.dart';
import 'package:remori/features/people/presentation/unknown_detail_providers.dart';
import 'package:remori/features/people/presentation/unknown_faces_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c6_unknown_faces_test.dart' as c6;
import 'c8_reminders_test.dart' as c8;

const scope = c6.scope;
const detailKey = (scope, 'unknown-0');
UnknownFace reviewFace() => UnknownFace(
  id: 'unknown-0',
  sightingCount: 5,
  distinctDays: 3,
  firstSeenAt: c6.face(0).firstSeenAt,
  lastSeenAt: c6.now,
  sampleId: 'photo-0',
  sampleUrl: 'https://example.test/photo-0',
  thumbnailUrl: 'https://example.test/thumb-0',
  samples: [
    for (var i = 0; i < 3; i++)
      UnknownFaceSample(
        'photo-$i',
        'https://example.test/photo-$i',
        'https://example.test/thumb-$i',
      ),
  ],
);
CachedPeopleCompanion person() => CachedPeopleCompanion.insert(
  caregiverId: scope.caregiverId,
  patientId: scope.patientId,
  id: 'person-new',
  name: 'Test name',
  relationship: 'Doctor',
  status: 'active',
  embeddingCount: 1,
  updatedAt: c6.now,
  position: -1,
);

class DecisionAdapter extends c6.Adapter {
  bool malformedPerson = false, decided = false;
  int status = 200;
  Completer<void>? postGate;
  @override
  Map<String, Object?> body(int i) {
    final raw = super.body(i);
    if (i == 0) {
      raw['samples'] = [
        ...(raw['samples'] as List),
        for (var n = 1; n < 3; n++)
          {
            'id': 'extra-$n',
            'url': 'https://example.test/extra-$n',
            'thumbnail_url': null,
          },
      ];
    }
    return raw;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET') {
      return super.fetch(options, requestStream, cancelFuture);
    }
    requests.add(options);
    if (postGate != null) await postGate!.future;
    if (this.fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final promote = options.path.endsWith('/promote');
    final cluster = body(0)..['status'] = promote ? 'promoted' : 'dismissed';
    if (!promote) {
      cluster['samples'] = [];
      cluster['sample_url'] = null;
      cluster['sample_thumbnail_url'] = null;
    }
    final payload = status != 200
        ? {
            'error': {'code': 'ALREADY_DECIDED', 'message': 'PRIVATE'},
          }
        : promote
        ? {
            'cluster': cluster,
            'person': {
              'id': 'person-new',
              'patient_id': malformedPerson ? 'other-patient' : scope.patientId,
              'status': 'active',
              'name': 'Test name',
              'relationship': 'Doctor',
              'embedding_count': 1,
              'updated_at': c6.now.toIso8601String(),
              'photo_url': null,
            },
          }
        : cluster;
    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class ReviewRepository extends c6.FakeRepository {
  ReviewRepository(super.client, super.db, super.scope) {
    data = UnknownFacesData(faces: [reviewFace()], refreshedAt: c6.now);
  }
  int decisions = 0, cacheWrites = 0;
  bool failCache = false;
  ApiFailure? decisionFailure;
  Completer<void>? decisionGate;
  String? submittedName, submittedRelationship;
  bool submittedConsent = false;
  @override
  Future<UnknownFaceDecision> decide(
    String id, {
    String? name,
    String? relationship,
    bool consent = false,
  }) async {
    decisions++;
    submittedName = name;
    submittedRelationship = relationship;
    submittedConsent = consent;
    if (decisionGate != null) await decisionGate!.future;
    if (decisionFailure != null) throw decisionFailure!;
    return UnknownFaceDecision(id, name == null ? null : person());
  }

  @override
  Future<void> cacheDecision(UnknownFaceDecision decision) async {
    cacheWrites++;
    if (failCache) throw StateError('Local cache unavailable');
    data = UnknownFacesData(refreshedAt: c6.now);
    updates.add(null);
  }
}

class ReviewPreviews extends c6.FakePreviews {
  ReviewPreviews(super.frames);
  @override
  Future<Uint8List> load(UnknownFace face) =>
      pending.putIfAbsent(face.sampleId!, () {
        loads++;
        return Future.value(frames[face.sampleId!.endsWith('1') ? 1 : 0]);
      });
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late DecisionAdapter adapter;
  late UnknownFacesRepository repo;
  late List<Uint8List> frames;
  setUpAll(() async {
    frames = [
      await File('design/screens/images/stranger.jpg').readAsBytes(),
      await File('design/screens/images/stranger2.jpg').readAsBytes(),
    ];
    for (final entry in {
      'DM Sans': 'assets/fonts/DM-Sans.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Readex Pro': 'assets/fonts/Readex-Pro.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  setUp(() {
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = DecisionAdapter();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = UnknownFacesRepository(client, db, scope);
  });
  tearDown(() async {
    client.close();
    await db.close();
  });

  test('three ordered samples stay scoped and contain metadata only', () async {
    await repo.refresh();
    final data = await repo.read();
    expect(data.faces.first.samples.map((s) => s.id), [
      'sample-0',
      'extra-1',
      'extra-2',
    ]);
    expect(
      (await UnknownFacesRepository(
        client,
        db,
        const PeopleScope('other', 'other'),
      ).read()).faces,
      isEmpty,
    );
    final columns = await db
        .customSelect('PRAGMA table_info(cached_unknown_face_samples)')
        .get();
    expect(columns.map((r) => r.read<String>('name')), [
      'caregiver_id',
      'patient_id',
      'cluster_id',
      'id',
      'url',
      'thumbnail_url',
      'position',
    ]);
    adapter.empty = true;
    await repo.refresh();
    expect(await db.select(db.cachedUnknownFaceSamples).get(), isEmpty);
  });
  test(
    'promotion uses explicit consent and caches People and removal atomically',
    () async {
      await repo.refresh();
      await db
          .into(db.peopleCacheStates)
          .insert(
            PeopleCacheStatesCompanion.insert(
              caregiverId: scope.caregiverId,
              patientId: scope.patientId,
              unknownCount: 2,
              refreshedAt: c6.now,
            ),
          );
      final decision = await repo.decide(
        'unknown-0',
        name: ' Test name ',
        relationship: ' Doctor ',
        consent: true,
      );
      expect(adapter.requests.last.path, '/unknown-faces/unknown-0/promote');
      expect(adapter.requests.last.data, {
        'name': 'Test name',
        'relationship': 'Doctor',
        'consent_given': true,
      });
      await repo.cacheDecision(decision);
      expect((await db.select(db.cachedPeople).getSingle()).name, 'Test name');
      expect((await repo.read()).faces.map((f) => f.id), ['unknown-1']);
      expect(
        (await db.select(db.cachedUnknownFaceSamples).get()).map(
          (s) => s.clusterId,
        ),
        ['unknown-1'],
      );
      expect(
        (await db.select(db.peopleCacheStates).getSingle()).unknownCount,
        1,
      );
    },
  );
  test(
    'dismiss is bodyless, removes sample metadata and creates no person',
    () async {
      await repo.refresh();
      final decision = await repo.decide('unknown-0');
      expect(adapter.requests.last.path, '/unknown-faces/unknown-0/dismiss');
      expect(adapter.requests.last.data, isNull);
      await repo.cacheDecision(decision);
      expect(await db.select(db.cachedPeople).get(), isEmpty);
      expect((await repo.read()).faces.map((f) => f.id), ['unknown-1']);
    },
  );
  test('invalid consent and lengths never send a POST', () async {
    for (final name in ['', 'a' * 81, 'Valid']) {
      await expectLater(
        repo.decide('unknown-0', name: name, relationship: 'Doctor'),
        throwsA(isA<ApiFailure>()),
      );
    }
    await expectLater(
      repo.decide(
        'unknown-0',
        name: 'Valid',
        relationship: 'a' * 41,
        consent: true,
      ),
      throwsA(isA<ApiFailure>()),
    );
    expect(adapter.requests, isEmpty);
  });
  test(
    'cross-patient promotion and already-decided responses never change SQLite',
    () async {
      await repo.refresh();
      adapter.malformedPerson = true;
      await expectLater(
        repo.decide(
          'unknown-0',
          name: 'Valid',
          relationship: 'Doctor',
          consent: true,
        ),
        throwsA(isA<ApiFailure>()),
      );
      adapter.status = 409;
      await expectLater(
        repo.decide('unknown-0'),
        throwsA(
          isA<ApiFailure>().having((e) => e.code, 'code', 'ALREADY_DECIDED'),
        ),
      );
      expect((await repo.read()).faces.length, 2);
      expect(await db.select(db.cachedPeople).get(), isEmpty);
    },
  );
  test('a late list refresh cannot resurrect a decided face', () async {
    await repo.refresh();
    adapter.gate = Completer<void>();
    final refresh = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    final decision = await repo.decide('unknown-0');
    await repo.cacheDecision(decision);
    adapter.gate!.complete();
    await refresh;
    expect((await repo.read()).faces.map((f) => f.id), ['unknown-1']);
  });
  test('patient purge removes samples only from its owner scope', () async {
    await repo.refresh();
    await db
        .into(db.cachedUnknownFaceSamples)
        .insert(
          CachedUnknownFaceSamplesCompanion.insert(
            caregiverId: 'other',
            patientId: scope.patientId,
            clusterId: 'unknown-0',
            id: 'p',
            url: 'https://example.test/p',
            position: 0,
          ),
        );
    await repo.purge();
    expect(
      (await db.select(db.cachedUnknownFaceSamples).getSingle()).caregiverId,
      'other',
    );
  });
  test('cache failure rolls back People, samples and badge before cache-only retry', () async {
    await repo.refresh();
    await db
        .into(db.peopleCacheStates)
        .insert(
          PeopleCacheStatesCompanion.insert(
            caregiverId: scope.caregiverId,
            patientId: scope.patientId,
            unknownCount: 2,
            refreshedAt: c6.now,
          ),
        );
    final decision = await repo.decide(
      'unknown-0',
      name: 'Test name',
      relationship: 'Doctor',
      consent: true,
    );
    await db.customStatement(
      "CREATE TRIGGER c7_cache_failure BEFORE DELETE ON cached_unknown_face_samples BEGIN SELECT RAISE(ABORT, 'cache unavailable'); END",
    );
    await expectLater(repo.cacheDecision(decision), throwsA(isA<Exception>()));
    expect(await db.select(db.cachedPeople).get(), isEmpty);
    expect((await repo.read()).faces.length, 2);
    expect((await db.select(db.peopleCacheStates).getSingle()).unknownCount, 2);
    await db.customStatement('DROP TRIGGER c7_cache_failure');
    await repo.cacheDecision(decision);
    expect((await db.select(db.cachedPeople).getSingle()).id, 'person-new');
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
  });

  test('schema v6 migration preserves face metadata and outbox', () async {
    await db.close();
    final directory = await Directory.systemTemp.createTemp(
      'remori-c7-migration-',
    );
    try {
      final file = File(
        '${directory.path}${Platform.pathSeparator}cache.sqlite',
      );
      db = RemoriDatabase(NativeDatabase(file));
      repo = UnknownFacesRepository(client, db, scope);
      await repo.refresh();
      await db.saveReminderLog(
        patientId: scope.patientId,
        reminderId: '00000005-0000-4000-8000-000000000001',
        scheduledAt: c6.now,
        at: c6.now,
        status: ReminderStatus.pending,
      );
      await db.customStatement('DROP TABLE cached_document_details');
      await db.customStatement('DROP TABLE cached_documents');
      await db.customStatement('DROP TABLE documents_cache_states');
      await db.customStatement('DROP TABLE cached_media_details');
      await db.customStatement('DROP TABLE cached_journal_entries');
      await db.customStatement('DROP TABLE cached_journal_media');
      await db.customStatement('DROP TABLE journal_cache_states');
      await db.customStatement('DROP TABLE cached_places');
      await db.customStatement('DROP TABLE places_cache_states');
      await db.customStatement('DROP TABLE cached_unknown_face_samples');
      await db.customStatement(
        'ALTER TABLE dashboard_devices DROP COLUMN firmware_version',
      );
      await db.customStatement(
        'ALTER TABLE dashboard_devices DROP COLUMN paired_at',
      );
      await db.customStatement('DROP TABLE cached_caregiver_accounts');
      await db.customStatement('DROP TABLE cached_consents');
      await db.customStatement('PRAGMA user_version = 6');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect((await db.select(db.cachedUnknownFaces).get()).length, 2);
      expect((await db.pendingWrites(scope.patientId)).length, 1);
      expect((await db.watchReminderLogs(scope.patientId).first).length, 1);
      expect(await db.select(db.cachedUnknownFaceSamples).get(), isEmpty);
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
    } finally {
      if (directory.absolute.parent.path !=
              Directory.systemTemp.absolute.path ||
          !directory.path.contains('remori-c7-migration-')) {
        throw StateError('Unexpected temporary path');
      }
      await directory.delete(recursive: true);
    }
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    ReviewRepository fake,
    ReviewPreviews photos, {
    String language = 'en',
    bool viewer = false,
    double scale = 1,
    Size size = const Size(390, 844),
    PeopleScope Function()? selected,
    String? clusterId,
    c6.FakePreviews? listPhotos,
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
        peopleScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
        selectedHomePatientProvider.overrideWithValue(
          HomePatient(
            id: scope.patientId,
            name: 'Patient',
            language: 'ar',
            timezone: 'Africa/Cairo',
            memoryEnabled: true,
            permission: viewer ? 'viewer' : 'manager',
          ),
        ),
        unknownFacesRepositoryProvider(scope).overrideWithValue(fake),
        unknownDetailPreviewsProvider(detailKey).overrideWith((ref) {
          ref.onDispose(photos.dispose);
          return photos;
        }),
        if (listPhotos != null)
          unknownFacePreviewsProvider(scope).overrideWithValue(listPhotos),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        unknownFacesClockProvider.overrideWithValue(() => c6.now),
        unknownFacesNowProvider.overrideWith((ref) => Stream.value(c6.now)),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c3: (_, _) => const Text('People destination'),
          if (listPhotos == null)
            RemoriScreen.c6: (_, _) => const Text('New faces destination'),
        }),
      ],
    );
    addTearDown(() {
      container.dispose();
      photos.dispose();
      listPhotos?.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c7-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          listPhotos == null ? RemoriScreen.c7.name : RemoriScreen.c6.name,
          extra: listPhotos != null
              ? scope.patientId
              : {
                  'patient_id': scope.patientId,
                  'cluster_id': clusterId ?? 'unknown-0',
                },
        );
    await tester.pumpAndSettle();
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
    return container;
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Test name');
    await tester.enterText(find.byType(TextField).at(1), 'Doctor');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'C6 opens real C7 and clears only the covered list photo session',
    (tester) async {
      final listPhotos = c6.FakePreviews(frames),
          photos = ReviewPreviews(frames);
      await mount(
        tester,
        ReviewRepository(client, db, scope),
        photos,
        listPhotos: listPhotos,
      );
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('unknown-face-unknown-0')));
      await tester.pumpAndSettle();
      expect(find.text('Who is this?'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(3));
      expect(listPhotos.pending, isEmpty);
      expect(photos.pending.length, 3);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('New faces to review'), findsOneWidget);
      expect(photos.pending, isEmpty);
    },
  );

  testWidgets('shows three images and requires explicit consent', (
    tester,
  ) async {
    final fake = ReviewRepository(client, db, scope),
        photos = ReviewPreviews(frames);
    await mount(tester, fake, photos);
    expect(find.byType(Image), findsNWidgets(3));
    expect(photos.loads, 3);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      find.textContaining('Seen 5 times on 3 different days'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save as a known person'));
    await tester.pumpAndSettle();
    expect(fake.decisions, 0);
    expect(find.textContaining('consent before saving'), findsOneWidget);
  });
  testWidgets('promotion returns to People only after local cache update', (
    tester,
  ) async {
    final fake = ReviewRepository(client, db, scope);
    await mount(tester, fake, ReviewPreviews(frames));
    await fill(tester);
    await tester.tap(find.text('Save as a known person'));
    await tester.pumpAndSettle();
    expect(fake.decisions, 1);
    expect(fake.submittedConsent, true);
    expect(fake.submittedName, 'Test name');
    expect(fake.cacheWrites, 1);
    expect(find.text('People destination'), findsOneWidget);
  });
  testWidgets(
    'dismiss confirmation can cancel or delete then return to People',
    (tester) async {
      final fake = ReviewRepository(client, db, scope);
      await mount(tester, fake, ReviewPreviews(frames));
      await tester.tap(find.text('Stranger, dismiss'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fake.decisions, 0);
      await tester.tap(find.text('Stranger, dismiss'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Stranger, dismiss'));
      await tester.pumpAndSettle();
      expect(fake.decisions, 1);
      expect(fake.submittedName, isNull);
      expect(find.text('People destination'), findsOneWidget);
    },
  );
  testWidgets(
    'acknowledged cache failure retries SQLite without a second decision',
    (tester) async {
      final fake = ReviewRepository(client, db, scope)..failCache = true,
          photos = ReviewPreviews(frames);
      await mount(tester, fake, photos);
      await fill(tester);
      await tester.tap(find.text('Save as a known person'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Decision saved'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(photos.pending, isEmpty);
      fake.failCache = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(fake.decisions, 1);
      expect(fake.cacheWrites, 2);
      expect(find.text('People destination'), findsOneWidget);
    },
  );
  testWidgets(
    'uncertain failure blocks another decision until a successful refresh',
    (tester) async {
      final fake = ReviewRepository(client, db, scope)
        ..decisionFailure = ApiFailure(ApiFailureKind.timeout);
      final container = await mount(tester, fake, ReviewPreviews(frames));
      await fill(tester);
      await tester.tap(find.text('Save as a known person'));
      await tester.pumpAndSettle();
      expect(
        container.read(unknownDetailControllerProvider(detailKey)).uncertain,
        isTrue,
      );
      await tester.tap(find.text('Save as a known person'));
      await tester.pumpAndSettle();
      expect(fake.decisions, 1);
      fake.fail = true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        container.read(unknownDetailControllerProvider(detailKey)).uncertain,
        isTrue,
      );
      fake.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        container.read(unknownDetailControllerProvider(detailKey)).uncertain,
        isFalse,
      );
    },
  );
  testWidgets('rapid duplicate submissions send only one decision', (
    tester,
  ) async {
    final fake = ReviewRepository(client, db, scope)
      ..decisionGate = Completer<void>();
    final container = await mount(tester, fake, ReviewPreviews(frames));
    final controller = container.read(
      unknownDetailControllerProvider(detailKey).notifier,
    );
    final first = controller.decide(
      name: 'Test name',
      relationship: 'Doctor',
      consent: true,
    );
    final second = await controller.decide(
      name: 'Test name',
      relationship: 'Doctor',
      consent: true,
    );
    expect(second, false);
    fake.decisionGate!.complete();
    expect(await first, true);
    expect(fake.decisions, 1);
  });
  testWidgets('viewer can review photos but cannot make a decision', (
    tester,
  ) async {
    final fake = ReviewRepository(client, db, scope);
    final container = await mount(
      tester,
      fake,
      ReviewPreviews(frames),
      viewer: true,
    );
    expect(find.byType(Image), findsNWidgets(3));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save as a known person'),
          )
          .onPressed,
      isNull,
    );
    expect(
      await container
          .read(unknownDetailControllerProvider(detailKey).notifier)
          .decide(),
      false,
    );
    expect(fake.decisions, 0);
  });
  testWidgets('offline shows cached metadata and never fetches photos', (
    tester,
  ) async {
    final fake = ReviewRepository(client, db, scope)..fail = true,
        photos = ReviewPreviews(frames);
    await mount(tester, fake, photos);
    expect(find.byType(Image), findsNothing);
    expect(photos.loads, 0);
    expect(find.textContaining('Seen 5 times'), findsOneWidget);
  });
  testWidgets(
    'background clears memory and a late refresh cannot show photos',
    (tester) async {
      final fake = ReviewRepository(client, db, scope),
          photos = ReviewPreviews(frames);
      final container = await mount(tester, fake, photos);
      fake.gate = Completer<void>();
      final controller = container.read(
        unknownDetailControllerProvider(detailKey).notifier,
      );
      final refresh = controller.refresh();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      fake.gate!.complete();
      await refresh;
      expect(
        container.read(unknownDetailControllerProvider(detailKey)).previews,
        false,
      );
      expect(photos.pending, isEmpty);
      fake.fail = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
    },
  );
  testWidgets('missing cluster disables all decision controls', (tester) async {
    final fake = ReviewRepository(client, db, scope);
    await mount(tester, fake, ReviewPreviews(frames), clusterId: 'missing');
    expect(
      find.textContaining('This face is no longer available'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(fake.decisions, 0);
  });
  testWidgets(
    'switching accounts discards late decisions and clears old photos',
    (tester) async {
      var selected = scope;
      final fake = ReviewRepository(client, db, scope)
        ..decisionGate = Completer<void>();
      final photos = ReviewPreviews(frames);
      final container = await mount(
        tester,
        fake,
        photos,
        selected: () => selected,
      );
      final pending = container
          .read(unknownDetailControllerProvider(detailKey).notifier)
          .decide(name: 'Test name', relationship: 'Doctor', consent: true);
      await tester.pump();
      selected = const PeopleScope('other-account', 'other-patient');
      container.invalidate(peopleScopeProvider);
      await tester.pumpAndSettle();
      fake.decisionGate!.complete();
      expect(await pending, false);
      expect(fake.cacheWrites, 0);
      expect(photos.pending, isEmpty);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets(
    '403 recovery is bounded by sample ID and resets on manual refresh',
    (tester) async {
      final fake = ReviewRepository(client, db, scope);
      final container = await mount(tester, fake, ReviewPreviews(frames));
      final controller = container.read(
        unknownDetailControllerProvider(detailKey).notifier,
      );
      final sample = reviewFace().samples.first.preview(reviewFace());
      await controller.photoFailed(sample, const UnknownPreviewFailure(403));
      await controller.photoFailed(sample, const UnknownPreviewFailure(403));
      expect(fake.refreshes, 2);
      await controller.refresh();
      await controller.photoFailed(sample, const UnknownPreviewFailure(403));
      expect(fake.refreshes, 4);
      await tester.pumpAndSettle();
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('captures C7 $language', (tester) async {
      debugDisableShadows = false;
      await mount(
        tester,
        ReviewRepository(client, db, scope),
        ReviewPreviews(frames),
        language: language,
      );
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .every((w) => w.image != null),
        isTrue,
      );
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c7-preview')),
          matchesGoldenFile('goldens/c7_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C7 $language handles 2x text on a narrow screen', (
      tester,
    ) async {
      await mount(
        tester,
        ReviewRepository(client, db, scope),
        ReviewPreviews(frames),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
