import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

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
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/core/db/database_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/people/data/people_photo_cache.dart';
import 'package:remori/features/people/data/people_repository.dart';
import 'package:remori/features/people/domain/people_data.dart';
import 'package:remori/features/people/presentation/c3_people_screen.dart';
import 'package:remori/features/people/presentation/people_providers.dart';

import 'a6_handover_test.dart' as auth;

const patient = '00000001-0000-4000-8000-000000000001';
const otherPatient = '00000001-0000-4000-8000-000000000002';
const scope = PeopleScope('caregiver-A', patient);
final updated = DateTime.utc(2026, 10, 14);

class PhotoCache implements PeoplePhotoCache {
  final evicted = <String>[];
  @override
  Future<void> evict(PeopleScope scope, KnownPerson person) async {
    if (person.photoUrl != null) evicted.add(person.imageKey(scope));
  }
}

class PeopleAdapter implements HttpClientAdapter {
  bool fail = false,
      denied = false,
      malformed = false,
      empty = false,
      archiveFirst = false;
  int rotation = 0;
  final requests = <RequestOptions>[];
  final names = ['Ahmed', 'Sara', 'Dr. Hany', 'Mona'];
  Map<String, Object?> person(int i, String patientId, String status) => {
    'id': 'known-$i',
    'patient_id': patientId,
    'name': status == 'archived' && i == 5 ? 'Archived person' : names[i % 4],
    'relationship': ['son', 'daughter', 'doctor', 'nurse'][i % 4],
    'status': malformed ? 'invalid' : status,
    'embedding_count': status == 'active' ? 2 : 0,
    'updated_at': updated.toIso8601String(),
    'photo_url': status == 'active'
        ? 'https://example.test/person-$i?signature=$rotation'
        : null,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'PRIVATE network failure',
      );
    }
    if (denied) {
      return json(404, {
        'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE response'},
      });
    }
    final p = options.path.contains(otherPatient) ? otherPatient : patient;
    if (options.path.endsWith('/people')) {
      final status = options.queryParameters['status'] as String;
      return json(
        200,
        empty
            ? []
            : status == 'active'
            ? [
                for (var i = archiveFirst ? 1 : 0; i < 4; i++)
                  person(i, p, status),
              ]
            : [person(5, p, status), if (archiveFirst) person(0, p, status)],
      );
    }
    if (options.path.endsWith('/unknown-faces')) {
      return json(
        200,
        empty
            ? []
            : [
                {
                  'id': 'unknown-1',
                  'patient_id': p,
                  'status': 'awaiting_caregiver',
                  'distinct_days': 3,
                },
                {
                  'id': 'unknown-2',
                  'patient_id': p,
                  'status': 'awaiting_caregiver',
                  'distinct_days': 3,
                },
                {
                  'id': 'unknown-2',
                  'patient_id': p,
                  'status': 'awaiting_caregiver',
                  'distinct_days': 3,
                },
                {'id': 'ignored', 'patient_id': p, 'status': 'dismissed'},
              ],
      );
    }
    return json(200, []);
  }

  ResponseBody json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

final images = <String, Uint8List>{};

class RouteTarget extends StatelessWidget {
  const RouteTarget(this.extra, {super.key});
  final Object? extra;
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  RemoriDatabase db,
  PeopleAdapter adapter,
  PhotoCache cache, {
  String language = 'en',
  double scale = 1,
  Size size = const Size(390, 844),
  bool viewer = false,
  String Function()? identity,
  void Function(void Function(Object))? capturePhotoFailure,
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
      screenBuildersProvider.overrideWithValue({
        ...builders,
        for (final target in [
          RemoriScreen.c4,
          RemoriScreen.c5,
          RemoriScreen.c6,
        ])
          target: (context, state) => RouteTarget(state.extra),
      }),
      routeAccessProvider.overrideWithValue(
        const RouteAccess(caregiverAuthenticated: true),
      ),
      caregiverIdentityProvider.overrideWith(
        (ref) async => identity?.call() ?? 'caregiver-A',
      ),
      databaseProvider.overrideWithValue(db),
      appLocaleProvider.overrideWithValue(Locale(language)),
      homeDataProvider.overrideWith(
        (ref) => Stream.value(
          HomeData(
            patients: [
              HomePatient(
                id: patient,
                name: 'Patient',
                language: 'ar',
                timezone: 'Africa/Cairo',
                memoryEnabled: true,
                permission: viewer ? 'viewer' : 'manager',
              ),
              const HomePatient(
                id: otherPatient,
                name: 'Second patient',
                language: 'en',
                timezone: 'Asia/Riyadh',
                memoryEnabled: false,
                permission: 'viewer',
              ),
            ],
          ),
        ),
      ),
      peoplePhotoCacheProvider.overrideWithValue(cache),
      apiClientProvider.overrideWith((ref) {
        final client = ApiClient(
          config: ApiConfig('https://example.test/api/v1'),
          credentials: auth.TestCredentials(),
          adapter: adapter,
          onCredentialsInvalidated: (_) {},
        );
        ref.onDispose(client.close);
        return client;
      }),
      peoplePhotoBuilderProvider.overrideWithValue((
        context,
        person,
        scope,
        onError,
      ) {
        capturePhotoFailure?.call(onError);
        return person.photoUrl == null
            ? const ColoredBox(
                color: Colors.grey,
                child: Icon(Icons.person_outline),
              )
            : Image.memory(images[person.id]!, fit: BoxFit.cover);
      }),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(key: Key('c3-preview'), child: RemoriApp()),
    ),
  );
  container.read(remoriRouterProvider).goNamed(RemoriScreen.c3.name);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, file) in [
      ('DM Sans', 'assets/fonts/DM-Sans.ttf'),
      ('Manrope', 'assets/fonts/Manrope.ttf'),
      ('Readex Pro', 'assets/fonts/Readex-Pro.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(file))).load();
    }
    for (var i = 0; i < 4; i++) {
      images['known-$i'] = await File(
        'design/screens/images/${['ahmed', 'sara', 'hany', 'mona'][i]}.jpg',
      ).readAsBytes();
    }
  });
  late RemoriDatabase db;
  late ApiClient client;
  late PeopleAdapter adapter;
  late PhotoCache photos;
  late PeopleRepository repo;
  Directory? migrationDirectory;
  setUp(() {
    migrationDirectory = null;
    db = RemoriDatabase(NativeDatabase.memory(logStatements: false));
    adapter = PeopleAdapter();
    photos = PhotoCache();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = PeopleRepository(client, db, scope, photos);
  });
  tearDown(() async {
    repo.dispose();
    client.close();
    await db.close();
    if (migrationDirectory != null) {
      final folder = migrationDirectory!;
      if (folder.parent.absolute.path.toLowerCase() !=
          Directory.systemTemp.absolute.path.toLowerCase()) {
        throw StateError('Unexpected migration test directory');
      }
      await folder.delete(recursive: true);
    }
  });
  test(
    'both filters and distinct awaiting face count commit to scoped SQLite',
    () async {
      await repo.refresh();
      final data = await repo.read();
      expect(
        data.people.where((p) => p.status == PeopleFilter.active).length,
        4,
      );
      expect(
        data.people.where((p) => p.status == PeopleFilter.archived).length,
        1,
      );
      expect(data.unknownCount, 2);
      expect(
        adapter.requests.map((r) => r.queryParameters['status']),
        containsAll(['active', 'archived']),
      );
      expect(
        adapter.requests.every(
          (r) => r.headers['Authorization'] == 'Bearer test-caregiver',
        ),
        isTrue,
      );
      expect(
        (await PeopleRepository(
          client,
          db,
          const PeopleScope('caregiver-B', patient),
          photos,
        ).read()).people,
        isEmpty,
      );
      expect(
        (await PeopleRepository(
          client,
          db,
          const PeopleScope('caregiver-A', otherPatient),
          photos,
        ).read()).people,
        isEmpty,
      );
    },
  );
  test('signed URL rotation preserves ID cache key, archiving evicts private photos', () async {
    await repo.refresh();
    final old = (await repo.read()).people.first;
    adapter.rotation++;
    await repo.refresh();
    final rotated = (await repo.read()).people.first;
    expect(rotated.photoUrl, isNot(old.photoUrl));
    expect(rotated.imageKey(scope), old.imageKey(scope));
    expect(photos.evicted, isEmpty);
    adapter.archiveFirst = true;
    await repo.refresh();
    expect(photos.evicted, contains(old.imageKey(scope)));
    expect(
      (await repo.read()).people.singleWhere((p) => p.id == old.id).photoUrl,
      isNull,
    );
  });
  test(
    'malformed and offline responses retain the complete previous snapshot',
    () async {
      await repo.refresh();
      adapter.malformed = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).people.length, 5);
      adapter.fail = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).unknownCount, 2);
    },
  );
  test(
    'known revoked link purges only that scoped cache and its photos',
    () async {
      await repo.refresh();
      final other = PeopleRepository(
        client,
        db,
        const PeopleScope('caregiver-B', patient),
        photos,
      );
      await other.refresh();
      adapter.denied = true;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).people, isEmpty);
      expect((await repo.read()).loaded, isFalse);
      expect((await other.read()).people.length, 5);
      expect(photos.evicted.length, 4);
    },
  );
  test('only native HTTP 403 triggers URL refresh; the URL never becomes a cache key', () {
    expect(
      isExpiredPeoplePhoto(const HttpException('Invalid statusCode: 403')),
      isTrue,
    );
    expect(
      isExpiredPeoplePhoto(const HttpException('Invalid statusCode: 404')),
      isFalse,
    );
    expect(isExpiredPeoplePhoto(StateError('https://private/403')), isFalse);
    final person = KnownPerson(
      id: 'known',
      name: 'Name',
      relationship: 'son',
      status: PeopleFilter.active,
      updatedAt: updated,
      photoUrl: 'https://private/signed-url',
    );
    expect(person.imageKey(scope), isNot(contains('private')));
    expect(
      person.imageKey(scope),
      isNot(person.imageKey(const PeopleScope('caregiver-B', patient))),
    );
  });
  testWidgets('active/archive chips use cached lists and keep active count', (
    tester,
  ) async {
    await mount(tester, db, adapter, photos);
    expect(find.text('Active (4)'), findsOneWidget);
    expect(find.text('2 new faces to review'), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('Son'), findsOneWidget);
    final requests = adapter.requests.length;
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Archived person'), findsOneWidget);
    expect(find.text('Ahmed'), findsNothing);
    expect(find.text('Active (4)'), findsOneWidget);
    expect(adapter.requests.length, requests);
  });
  testWidgets(
    'Add person, review and detail preserve selected patient/record context',
    (tester) async {
      final container = await mount(tester, db, adapter, photos);
      await tester.tap(find.text('+ Add person'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RouteTarget>(find.byType(RouteTarget)).extra,
        patient,
      );
      container.read(remoriRouterProvider).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed'));
      await tester.pumpAndSettle();
      expect(tester.widget<RouteTarget>(find.byType(RouteTarget)).extra, {
        'patient_id': patient,
        'person_id': 'known-0',
      });
      container.read(remoriRouterProvider).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 new faces to review'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RouteTarget>(find.byType(RouteTarget)).extra,
        patient,
      );
    },
  );
  testWidgets(
    'viewer has no write actions but can open people and review list',
    (tester) async {
      await mount(tester, db, adapter, photos, viewer: true);
      expect(find.text('+ Add person'), findsNothing);
      expect(find.byTooltip('Add reminder'), findsNothing);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('2 new faces to review'), findsOneWidget);
    },
  );
  testWidgets(
    'offline refresh keeps people and avoids private exception display',
    (tester) async {
      final container = await mount(tester, db, adapter, photos);
      adapter.fail = true;
      await tester.runAsync(
        () => container.read(peopleRefreshProvider.notifier).refresh(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ahmed'), findsOneWidget);
      expect(
        find.text('Showing saved people. Unable to update the list.'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets(
    '403 refresh evicts scoped image once and requests fresh signed URLs',
    (tester) async {
      final container = await mount(tester, db, adapter, photos);
      final person = container.read(peopleDataProvider).value!.people.first;
      adapter.rotation++;
      final recovery = container
          .read(peopleRefreshProvider.notifier)
          .photoFailed(
            scope,
            person,
            const HttpException('Invalid statusCode: 403'),
          );
      await tester.pumpAndSettle();
      await recovery;
      await tester.pumpAndSettle();
      final count = adapter.requests.length;
      expect(photos.evicted, contains(person.imageKey(scope)));
      expect(
        container.read(peopleDataProvider).value!.people.first.photoUrl,
        isNot(person.photoUrl),
      );
      await container
          .read(peopleRefreshProvider.notifier)
          .photoFailed(
            scope,
            person,
            const HttpException('Invalid statusCode: 403'),
          );
      expect(adapter.requests.length, count);
      final refreshed = container.read(peopleDataProvider).value!.people.first;
      await container
          .read(peopleRefreshProvider.notifier)
          .photoFailed(
            scope,
            refreshed,
            const HttpException('Invalid statusCode: 403'),
          );
      expect(adapter.requests.length, count);
    },
  );
  testWidgets(
    'patient changes reset archived filter and refresh the correct scope',
    (tester) async {
      final container = await mount(tester, db, adapter, photos);
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      container
          .read(selectedHomePatientIdProvider.notifier)
          .select(otherPatient);
      await tester.pumpAndSettle();
      expect(container.read(peopleFilterProvider), PeopleFilter.active);
      expect(container.read(peopleScopeProvider)!.patientId, otherPatient);
      expect(
        adapter.requests.any((r) => r.path == '/patients/$otherPatient/people'),
        isTrue,
      );
    },
  );
  testWidgets('empty cache shows real empty states without a review banner', (
    tester,
  ) async {
    adapter.empty = true;
    await mount(tester, db, adapter, photos);
    expect(find.text('Active (0)'), findsOneWidget);
    expect(find.text('No active people have been added yet.'), findsOneWidget);
    expect(find.textContaining('new faces to review'), findsNothing);
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('No archived people.'), findsOneWidget);
  });
  testWidgets('account changes cannot reuse another caregiver cached people', (
    tester,
  ) async {
    var id = 'caregiver-A';
    final container = await mount(
      tester,
      db,
      adapter,
      photos,
      identity: () => id,
    );
    expect(find.text('Ahmed'), findsOneWidget);
    adapter.empty = true;
    id = 'caregiver-B';
    container.invalidate(caregiverIdentityProvider);
    await tester.pumpAndSettle();
    expect(find.text('Ahmed'), findsNothing);
    expect(container.read(peopleScopeProvider)!.caregiverId, 'caregiver-B');
    expect(container.read(peopleDataProvider).value!.people, isEmpty);
  });
  test('v2 upgrade preserves dashboard, reminder log and outbox caches', () async {
    await db.close();
    migrationDirectory = await Directory.systemTemp.createTemp(
      'remori-c3-migration-',
    );
    final file = File(
      '${migrationDirectory!.path}${Platform.pathSeparator}cache.sqlite',
    );
    db = RemoriDatabase(NativeDatabase(file, logStatements: false));
    await db.customStatement(
      "INSERT INTO dashboard_patients VALUES ('caregiver-A','$patient','Patient','ar','Africa/Cairo',1,'manager',0)",
    );
    await db.saveReminderLog(
      patientId: patient,
      reminderId: '00000005-0000-4000-8000-000000000001',
      scheduledAt: updated,
      at: updated,
      status: ReminderStatus.pending,
    );
    await db.customStatement('DROP TABLE cached_people');
    await db.customStatement('DROP TABLE people_cache_states');
    await db.customStatement('DROP TABLE person_detail_states');
    await db.customStatement('DROP TABLE cached_person_photos');
    await db.customStatement('DROP TABLE cached_reminders');
    await db.customStatement('DROP TABLE cached_reminder_occurrences');
    await db.customStatement('DROP TABLE reminder_cache_states');
    await db.customStatement('PRAGMA user_version = 2');
    await db.customStatement('DROP TABLE cached_journal_entries');
    await db.customStatement('DROP TABLE cached_journal_media');
    await db.customStatement('DROP TABLE journal_cache_states');
    await db.customStatement('DROP TABLE cached_places');
    await db.customStatement('DROP TABLE places_cache_states');
    await db.customStatement('DROP TABLE cached_unknown_face_samples');
    await db.customStatement('DROP TABLE cached_unknown_faces');
    await db.customStatement('DROP TABLE unknown_faces_cache_states');
    await db.close();
    db = RemoriDatabase(NativeDatabase(file, logStatements: false));
    expect((await db.select(db.dashboardPatients).get()).single.id, patient);
    expect((await db.watchReminderLogs(patient).first).length, 1);
    expect((await db.pendingWrites(patient)).length, 1);
    expect(await db.select(db.cachedPeople).get(), isEmpty);
    expect(await db.select(db.peopleCacheStates).get(), isEmpty);
  });
  testWidgets(
    'rotated signed URL resets image stream while preserving scoped disk key',
    (tester) async {
      final container = await mount(tester, db, adapter, photos);
      final defaults = ProviderContainer();
      addTearDown(defaults.dispose);
      final builder = defaults.read(peoplePhotoBuilderProvider);
      final old = container.read(peopleDataProvider).value!.people.first;
      final rotated = KnownPerson(
        id: old.id,
        name: old.name,
        relationship: old.relationship,
        status: old.status,
        updatedAt: old.updatedAt,
        photoUrl: 'https://example.test/rotated',
      );
      final context = tester.element(find.byType(C3PeopleScreen));
      final first = builder(context, old, scope, (_) {}) as CachedNetworkImage;
      final second =
          builder(context, rotated, scope, (_) {}) as CachedNetworkImage;
      expect(first.cacheKey, second.cacheKey);
      expect(first.key, isNot(second.key));
      expect(first.key.toString(), isNot(contains('https')));
    },
  );
  testWidgets(
    'late photo failures after leaving People do not use disposed UI or refresh',
    (tester) async {
      void Function(Object)? fail;
      await mount(
        tester,
        db,
        adapter,
        photos,
        capturePhotoFailure: (callback) => fail = callback,
      );
      final count = adapter.requests.length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        () => fail!(const HttpException('Invalid statusCode: 403')),
        returnsNormally,
      );
      expect(adapter.requests.length, count);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C3 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        db,
        adapter,
        photos,
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('C3 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, db, adapter, photos, language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c3-preview')),
          matchesGoldenFile('goldens/c3_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
  }
}
