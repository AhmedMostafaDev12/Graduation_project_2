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
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/people/data/people_photo_cache.dart';
import 'package:remori/features/people/data/person_detail_photo_cache.dart';
import 'package:remori/features/people/data/person_detail_repository.dart';
import 'package:remori/features/people/domain/people_data.dart';
import 'package:remori/features/people/domain/person_detail.dart';
import 'package:remori/features/people/domain/person_enrollment.dart';
import 'package:remori/features/people/presentation/c5_person_detail_screen.dart';
import 'package:remori/features/people/presentation/people_providers.dart';
import 'package:remori/features/people/presentation/person_detail_providers.dart';
import 'package:remori/features/people/presentation/person_enrollment_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c4_add_person_test.dart' as enrollment;

const owner = PeopleScope('caregiver-A', 'patient-A');
const scope = PersonDetailScope(owner, 'person-A');
final at = DateTime.utc(2026, 10, 14);
final portraits = <String, Uint8List>{};

PersonDetailData fixture({
  int count = 4,
  bool archived = false,
  String name = 'Ahmed',
}) => PersonDetailData(
  person: KnownPerson(
    id: scope.personId,
    name: name,
    relationship: 'son',
    status: archived ? PeopleFilter.archived : PeopleFilter.active,
    updatedAt: at,
  ),
  enrolledByName: 'Ahmed Mostafa',
  refreshedAt: at,
  photos: [
    if (!archived)
      for (var i = 0; i < count; i++)
        EnrolledPhoto(
          id: 'photo-$i',
          url: 'https://example.test/full-$i',
          thumbnailUrl: 'https://example.test/thumb-$i',
        ),
  ],
);

class PhotoCache implements PersonDetailPhotoCache {
  final removed = <String>[];
  @override
  Future<void> evict(PersonDetailScope scope, EnrolledPhoto photo) async =>
      removed.add(photo.key(scope, full: true));
}

class PeopleCache implements PeoplePhotoCache {
  final removed = <String>[];
  @override
  Future<void> evict(PeopleScope scope, KnownPerson person) async =>
      removed.add(person.imageKey(scope));
}

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int count = 4, rotation = 0;
  bool archived = false, fail = false, malformed = false, denied = false;
  String name = 'Ahmed', relationship = 'son';
  Map<String, Object?> body({bool detail = true}) => {
    'id': scope.personId,
    'patient_id': malformed ? 'patient-B' : owner.patientId,
    'name': name,
    'relationship': relationship,
    'status': archived ? 'archived' : 'active',
    'embedding_count': archived ? 0 : count,
    'updated_at': at.toIso8601String(),
    if (detail) ...{
      'enrolled_by_name': 'Ahmed Mostafa',
      'photos': [
        if (!archived)
          for (var i = 0; i < count; i++)
            {
              'id': 'photo-$i',
              'url': 'https://example.test/full-$i?v=$rotation',
              'thumbnail_url': 'https://example.test/thumb-$i?v=$rotation',
            },
      ],
    },
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (denied) {
      return json(404, {
        'error': {'code': 'PERSON_NOT_FOUND', 'message': 'PRIVATE'},
      });
    }
    if (options.method == 'PATCH') {
      final fields = options.data as Map;
      name = fields['name'];
      relationship = fields['relationship'];
    }
    if (options.method == 'POST') {
      count += (options.data as FormData).files.length;
    }
    if (options.method == 'DELETE' && options.path.contains('/photos/')) {
      count--;
    }
    if (options.method == 'DELETE' && !options.path.contains('/photos/')) {
      archived = true;
      return json(204, null);
    }
    return json(200, body(detail: options.method == 'GET'));
  }

  ResponseBody json(int status, Object? value) => ResponseBody.fromString(
    jsonEncode(value),
    status,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

class FakeRepository extends PersonDetailRepository {
  FakeRepository(
    super.client,
    super.db,
    super.scope,
    super.photos,
    super.peoplePhotos,
  );
  PersonDetailData data = fixture();
  final updates = StreamController<PersonDetailData?>.broadcast();
  int refreshes = 0,
      edits = 0,
      additions = 0,
      removals = 0,
      archives = 0,
      archiveCaches = 0;
  bool failRefresh = false, failArchiveCache = false;
  ApiFailure? writeFailure;
  Completer<void>? gate;
  @override
  Future<PersonDetailData?> read() async => data;
  @override
  Stream<PersonDetailData?> watch() async* {
    yield data;
    yield* updates.stream;
  }

  @override
  Future<void> refresh() async {
    refreshes++;
    if (failRefresh) throw ApiFailure(ApiFailureKind.network);
    updates.add(data);
  }

  @override
  Future<void> edit(String name, String relationship) async {
    edits++;
    if (gate != null) await gate!.future;
    data = fixture(count: data.photos.length, name: name.trim());
  }

  @override
  Future<void> addPhotos(List<EnrollmentPhoto> photos) async {
    additions++;
    if (writeFailure != null) throw writeFailure!;
    data = fixture(count: data.photos.length + photos.length);
  }

  @override
  Future<void> removePhoto(String id) async {
    removals++;
    data = fixture(count: data.photos.length - 1);
  }

  @override
  Future<void> archive() async {
    archives++;
  }

  @override
  Future<void> cacheArchive() async {
    archiveCaches++;
    if (failArchiveCache) throw StateError('PRIVATE');
    data = fixture(archived: true);
    updates.add(data);
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
  late PhotoCache photos;
  late PeopleCache peoplePhotos;
  late PersonDetailRepository repo;
  Directory? migrationDirectory;
  setUpAll(() async {
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
    portraits['a'] = File('design/screens/images/ahmed.jpg').readAsBytesSync();
    portraits['b'] = File('design/screens/images/ahmed2.jpg').readAsBytesSync();
  });
  setUp(() {
    db = RemoriDatabase(NativeDatabase.memory());
    adapter = Adapter();
    photos = PhotoCache();
    peoplePhotos = PeopleCache();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    repo = PersonDetailRepository(client, db, scope, photos, peoplePhotos);
  });
  tearDown(() async {
    client.close();
    await db.close();
    if (migrationDirectory != null) {
      final directory = migrationDirectory!;
      if (directory.absolute.parent.path !=
              Directory.systemTemp.absolute.path ||
          !directory.path.contains('remori-c5-migration-')) {
        throw StateError('Unexpected temporary path');
      }
      await directory.delete(recursive: true);
      migrationDirectory = null;
    }
  });

  test('detail refresh is atomic, scoped and fetched in one request', () async {
    await repo.refresh();
    expect(adapter.requests.length, 1);
    expect(adapter.requests.single.path, '/people/person-A');
    final value = (await repo.read())!;
    expect(value.enrolledByName, 'Ahmed Mostafa');
    expect(value.photos.length, 4);
    expect(
      (await db.select(db.cachedPeople).get()).single.photoUrl,
      contains('thumb-0'),
    );
    final other = PersonDetailRepository(
      client,
      db,
      const PersonDetailScope(
        PeopleScope('caregiver-B', 'patient-A'),
        'person-A',
      ),
      photos,
      peoplePhotos,
    );
    expect(await other.read(), null);
    adapter.malformed = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read())!.photos.length, 4);
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read())!.person.name, 'Ahmed');
  });
  test(
    'photo key survives URL rotation, with separate full and thumbnail keys',
    () async {
      await repo.refresh();
      final first = (await repo.read())!.photos.first;
      adapter.rotation++;
      await repo.refresh();
      final second = (await repo.read())!.photos.first;
      expect(first.key(scope, full: true), second.key(scope, full: true));
      expect(first.url, isNot(second.url));
      expect(
        first.key(scope, full: true),
        isNot(first.key(scope, full: false)),
      );
      expect(first.key(scope, full: true), isNot(contains('https')));
      expect(photos.removed, isEmpty);
    },
  );
  test('edit and photo uploads use the existing contract without another enrollment', () async {
    await repo.refresh();
    await repo.edit(' New name ', ' Daughter ');
    expect(adapter.requests.last.method, 'PATCH');
    expect(adapter.requests.last.data, {
      'name': 'New name',
      'relationship': 'Daughter',
    });
    await repo.addPhotos([
      EnrollmentPhoto(enrollment.png),
      EnrollmentPhoto(enrollment.png),
    ]);
    final upload = adapter.requests.last;
    expect(upload.path, '/people/person-A/photos');
    expect((upload.data as FormData).files.map((f) => f.key), [
      'photos',
      'photos',
    ]);
    expect((upload.data as FormData).fields, isEmpty);
    await repo.refresh();
    expect((await repo.read())!.photos.length, 6);
    expect(await db.pendingWrites('patient-A'), isEmpty);
  });
  test(
    'removal refresh evicts the removed photo and updates the list cache',
    () async {
      await repo.refresh();
      await repo.removePhoto('photo-3');
      expect(adapter.requests.last.path, '/people/person-A/photos/photo-3');
      await repo.refresh();
      expect((await repo.read())!.photos.length, 3);
      expect(photos.removed.single, contains('photo-3'));
    },
  );
  test(
    'last photo cannot be removed and invalid batches never upload',
    () async {
      adapter.count = 1;
      await repo.refresh();
      final before = adapter.requests.length;
      await expectLater(
        repo.removePhoto('photo-0'),
        throwsA(isA<ApiFailure>().having((e) => e.code, 'code', 'LAST_PHOTO')),
      );
      await expectLater(repo.addPhotos([]), throwsA(isA<ApiFailure>()));
      await expectLater(repo.edit('', 'son'), throwsA(isA<ApiFailure>()));
      expect(adapter.requests.length, before);
    },
  );
  test('archive removes face metadata and evicts images without losing historical name', () async {
    await repo.refresh();
    await repo.archive();
    await repo.cacheArchive();
    final data = (await repo.read())!;
    expect(data.person.status, PeopleFilter.archived);
    expect(data.person.name, 'Ahmed');
    expect(data.photos, isEmpty);
    expect(await db.select(db.personDetailStates).get(), isEmpty);
    expect(photos.removed.length, 4);
    expect(peoplePhotos.removed.length, 1);
  });
  test('PERSON_NOT_FOUND purges only the affected person scope', () async {
    await repo.refresh();
    final other = PersonDetailRepository(
      client,
      db,
      const PersonDetailScope(
        PeopleScope('caregiver-B', 'patient-A'),
        'person-A',
      ),
      photos,
      peoplePhotos,
    );
    await other.refresh();
    adapter.denied = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(await repo.read(), null);
    expect((await other.read())!.photos.length, 4);
    expect(photos.removed.length, 4);
  });
  test('observed remote archive removes cached photo data', () async {
    await repo.refresh();
    adapter.archived = true;
    await repo.refresh();
    expect((await repo.read())!.photos, isEmpty);
    expect(await db.select(db.cachedPersonPhotos).get(), isEmpty);
    expect(photos.removed.length, 4);
  });
  test(
    'detail invalidation purges and evicts only the selected account/person',
    () async {
      await repo.refresh();
      final other = PersonDetailRepository(
        client,
        db,
        const PersonDetailScope(
          PeopleScope('caregiver-B', 'patient-A'),
          'person-A',
        ),
        photos,
        peoplePhotos,
      );
      await other.refresh();
      await purgePersonDetails(
        db,
        owner,
        ids: {scope.personId},
        photoCache: photos,
      );
      expect((await repo.read())!.photos, isEmpty);
      expect((await other.read())!.photos.length, 4);
      expect(photos.removed.length, 4);
      expect((await repo.read())!.person.name, 'Ahmed');
    },
  );
  test('v3 migration preserves People, reminders and outbox', () async {
    await db.close();
    migrationDirectory = await Directory.systemTemp.createTemp(
      'remori-c5-migration-',
    );
    final file = File(
      '${migrationDirectory!.path}${Platform.pathSeparator}cache.sqlite',
    );
    db = RemoriDatabase(NativeDatabase(file));
    repo = PersonDetailRepository(client, db, scope, photos, peoplePhotos);
    await repo.refresh();
    await db.saveReminderLog(
      patientId: '00000001-0000-4000-8000-000000000001',
      reminderId: '00000005-0000-4000-8000-000000000001',
      scheduledAt: at,
      at: at,
      status: ReminderStatus.pending,
    );
    await db.customStatement('DROP TABLE person_detail_states');
    await db.customStatement('DROP TABLE cached_person_photos');
    await db.customStatement('DROP TABLE cached_reminders');
    await db.customStatement('DROP TABLE cached_reminder_occurrences');
    await db.customStatement('DROP TABLE reminder_cache_states');
    await db.customStatement('PRAGMA user_version = 3');
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
    await db.customStatement('DROP TABLE cached_unknown_faces');
    await db.customStatement('DROP TABLE unknown_faces_cache_states');
    await db.close();
    db = RemoriDatabase(NativeDatabase(file));
    expect((await db.select(db.cachedPeople).get()).single.name, 'Ahmed');
    expect(await db.select(db.personDetailStates).get(), isEmpty);
    expect(await db.select(db.cachedPersonPhotos).get(), isEmpty);
    expect(
      (await db.pendingWrites('00000001-0000-4000-8000-000000000001')).length,
      1,
    );
    expect(
      (await db.watchReminderLogs('00000001-0000-4000-8000-000000000001').first)
          .length,
      1,
    );
  });

  ProviderContainer controller(
    FakeRepository fake, {
    PeopleScope Function()? selected,
    bool manager = true,
  }) => ProviderContainer(
    overrides: [
      peopleScopeProvider.overrideWith((ref) => selected?.call() ?? owner),
      caregiverCanManageProvider.overrideWithValue(manager),
      personDetailRepositoryProvider(scope).overrideWithValue(fake),
      personDetailPhotoCacheProvider.overrideWithValue(photos),
    ],
  );
  FakeRepository fakeRepo() =>
      FakeRepository(client, db, scope, photos, peoplePhotos);
  test(
    'confirmed photo upload retries only refresh after refresh failure',
    () async {
      final fake = fakeRepo();
      final container = controller(fake);
      addTearDown(container.dispose);
      final listen = container.listen(
        personDetailControllerProvider(scope),
        (_, _) {},
      );
      addTearDown(listen.close);
      await Future<void>.delayed(Duration.zero);
      fake.failRefresh = true;
      final notifier = container.read(
        personDetailControllerProvider(scope).notifier,
      );
      expect(
        await notifier.perform(
          PersonAction.addPhotos,
          photos: [EnrollmentPhoto(enrollment.png)],
        ),
        true,
      );
      expect(
        container.read(personDetailControllerProvider(scope)).pending,
        true,
      );
      expect(
        await notifier.perform(
          PersonAction.addPhotos,
          photos: [EnrollmentPhoto(enrollment.png)],
        ),
        false,
      );
      fake.failRefresh = false;
      await notifier.refresh();
      expect(fake.additions, 1);
      expect(
        container.read(personDetailControllerProvider(scope)).pending,
        false,
      );
    },
  );
  test(
    'known archive cache failure retries the cache instead of DELETE',
    () async {
      final fake = fakeRepo()..failArchiveCache = true;
      final container = controller(fake);
      addTearDown(container.dispose);
      final listen = container.listen(
        personDetailControllerProvider(scope),
        (_, _) {},
      );
      addTearDown(listen.close);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(
        personDetailControllerProvider(scope).notifier,
      );
      expect(await notifier.perform(PersonAction.archive), true);
      fake.failArchiveCache = false;
      await notifier.refresh();
      expect(fake.archives, 1);
      expect(fake.archiveCaches, 2);
      expect(
        container.read(personDetailControllerProvider(scope)).archived,
        true,
      );
    },
  );
  test('viewer cannot write and duplicate taps or late identity changes cannot refresh', () async {
    final fake = fakeRepo()..gate = Completer<void>();
    var selected = owner;
    final container = controller(fake, selected: () => selected);
    addTearDown(container.dispose);
    final listen = container.listen(
      personDetailControllerProvider(scope),
      (_, _) {},
    );
    addTearDown(listen.close);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(
      personDetailControllerProvider(scope).notifier,
    );
    final before = fake.refreshes;
    final pending = notifier.perform(
      PersonAction.edit,
      name: 'New',
      relationship: 'son',
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      await notifier.perform(
        PersonAction.edit,
        name: 'Again',
        relationship: 'son',
      ),
      false,
    );
    selected = const PeopleScope('caregiver-B', 'patient-A');
    container.invalidate(peopleScopeProvider);
    fake.gate!.complete();
    expect(await pending, false);
    expect(fake.edits, 1);
    expect(fake.refreshes, before);
    final viewer = controller(fake, manager: false);
    addTearDown(viewer.dispose);
    expect(
      await viewer
          .read(personDetailControllerProvider(scope).notifier)
          .perform(PersonAction.archive),
      false,
    );
    expect(fake.archives, 0);
  });
  test('403 recovery is bounded per photo ID and never triggered by arbitrary errors', () async {
    final fake = fakeRepo();
    final container = controller(fake);
    addTearDown(container.dispose);
    final listen = container.listen(
      personDetailControllerProvider(scope),
      (_, _) {},
    );
    addTearDown(listen.close);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(
      personDetailControllerProvider(scope).notifier,
    );
    final photo = fake.data.photos.first, before = fake.refreshes;
    await notifier.photoFailed(photo, StateError('PRIVATE 403 URL'));
    await notifier.photoFailed(
      photo,
      const HttpException('Invalid statusCode: 403'),
    );
    await notifier.photoFailed(
      photo,
      const HttpException('Invalid statusCode: 403'),
    );
    expect(fake.refreshes, before + 1);
    expect(photos.removed.length, 1);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeRepository fake, {
    bool viewer = false,
    String language = 'en',
    double scale = 1,
    Size size = const Size(390, 844),
    PeopleScope Function()? selected,
    void Function(void Function(Object))? captureFailure,
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
        peopleScopeProvider.overrideWith((ref) => selected?.call() ?? owner),
        caregiverCanManageProvider.overrideWithValue(!viewer),
        personDetailRepositoryProvider(scope).overrideWithValue(fake),
        personDetailPhotoCacheProvider.overrideWithValue(photos),
        enrollmentPhotoPickerProvider.overrideWithValue(enrollment.Picker()),
        detailPhotoBuilderProvider.overrideWithValue((
          context,
          scope,
          photo,
          full,
          onError,
        ) {
          captureFailure?.call(onError);
          return Image.memory(
            portraits[photo.id.endsWith('1') || photo.id.endsWith('3')
                ? 'b'
                : 'a']!,
            fit: BoxFit.cover,
          );
        }),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c3: (_, _) => const Text('People destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c5-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          RemoriScreen.c5.name,
          extra: {'patient_id': owner.patientId, 'person_id': scope.personId},
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'detail renders offline cached data and viewer controls are hidden',
    (tester) async {
      final fake = fakeRepo()..failRefresh = true;
      await mount(tester, fake, viewer: true);
      expect(find.text('Ahmed'), findsNWidgets(2));
      expect(find.text('Son · enrolled by Ahmed Mostafa'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('+ Add photos'), findsNothing);
      expect(find.text('Archive person'), findsNothing);
      expect(find.byType(Image), findsNWidgets(5));
    },
  );
  testWidgets('Edit updates an existing person instead of creating one', (
    tester,
  ) async {
    final fake = fakeRepo();
    await mount(tester, fake);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Updated name');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(fake.edits, 1);
    expect(fake.additions, 0);
    expect(find.text('Updated name'), findsNWidgets(2));
  });
  testWidgets('adding photos selects and uploads once', (tester) async {
    final fake = fakeRepo();
    await mount(tester, fake);
    await tester.tap(find.text('+ Add photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save photos'));
    await tester.pumpAndSettle();
    expect(fake.additions, 1);
    expect(find.text('Enrolled photos (5)'), findsOneWidget);
  });
  testWidgets(
    'invalid photo slots are reported without exposing backend text',
    (tester) async {
      final fake = fakeRepo()
        ..writeFailure = ApiFailure(
          ApiFailureKind.server,
          code: 'PHOTOS_INVALID',
          details: [
            const ApiFieldError(
              field: 'body.photos.0',
              message: 'PRIVATE ERROR',
            ),
          ],
        );
      await mount(tester, fake);
      await tester.tap(find.text('+ Add photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save photos'));
      await tester.pumpAndSettle();
      expect(
        find.text('Photo 1: unable to use this photo. Please replace it.'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets(
    'known archive awaiting cache retry hides photos and never repeats DELETE',
    (tester) async {
      final fake = fakeRepo()..failArchiveCache = true;
      await mount(tester, fake);
      await tester.tap(find.text('Archive person'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive person'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(
        find.text('Changes saved. Refresh to finish updating this page.'),
        findsOneWidget,
      );
      fake.failArchiveCache = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(fake.archives, 1);
      expect(find.text('People destination'), findsOneWidget);
    },
  );
  testWidgets(
    'archive cancellation does nothing and confirmation returns to People',
    (tester) async {
      final fake = fakeRepo();
      await mount(tester, fake);
      await tester.tap(find.text('Archive person'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fake.archives, 0);
      await tester.tap(find.text('Archive person'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive person'));
      await tester.pumpAndSettle();
      expect(fake.archives, 1);
      expect(find.text('People destination'), findsOneWidget);
    },
  );
  testWidgets(
    'photo removal requires confirmation and last photo cannot be tapped',
    (tester) async {
      final fake = fakeRepo();
      await mount(tester, fake);
      await tester.tap(find.byType(Image).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove photo'));
      await tester.pumpAndSettle();
      expect(fake.removals, 1);
      expect(find.text('Enrolled photos (3)'), findsOneWidget);
      fake.data = fixture(count: 1);
      fake.updates.add(fake.data);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Image).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets('archived person has no photos or editing controls', (
    tester,
  ) async {
    final fake = fakeRepo()..data = fixture(archived: true);
    await mount(tester, fake);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Archive person'), findsNothing);
    expect(find.text('This person is archived.'), findsOneWidget);
  });
  testWidgets(
    'account change hides private dialog data and late photo callbacks are ignored',
    (tester) async {
      final fake = fakeRepo();
      var selected = owner;
      void Function(Object)? callback;
      final container = await mount(
        tester,
        fake,
        selected: () => selected,
        captureFailure: (value) => callback = value,
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      selected = const PeopleScope('caregiver-B', 'patient-B');
      container.invalidate(peopleScopeProvider);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Ahmed'), findsNothing);
      final before = fake.refreshes;
      callback!(const HttpException('Invalid statusCode: 403'));
      await tester.pumpAndSettle();
      expect(fake.refreshes, before);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        () => callback!(const HttpException('Invalid statusCode: 403')),
        returnsNormally,
      );
    },
  );
  testWidgets(
    'full image and grid use separate keys; URL rotation resets only the UI stream',
    (tester) async {
      await mount(tester, fakeRepo());
      final defaults = ProviderContainer();
      addTearDown(defaults.dispose);
      final builder = defaults.read(detailPhotoBuilderProvider);
      final context = tester.element(find.byType(C5PersonDetailScreen));
      final photo = fixture().photos.first;
      final full =
          builder(context, scope, photo, true, (_) {}) as CachedNetworkImage;
      final thumb =
          builder(context, scope, photo, false, (_) {}) as CachedNetworkImage;
      final rotated = builder(
        context,
        scope,
        EnrolledPhoto(id: photo.id, url: 'https://example.test/rotated'),
        true,
        (_) {},
      ) as CachedNetworkImage;
      expect(full.imageUrl, photo.url);
      expect(thumb.imageUrl, photo.thumbnailUrl);
      expect(full.cacheKey, isNot(thumb.cacheKey));
      expect(full.cacheKey, rotated.cacheKey);
      expect(full.key, isNot(rotated.key));
      expect(full.key.toString(), isNot(contains('https')));
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C5 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, fakeRepo(), language: language);
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c5-preview')),
          matchesGoldenFile('goldens/c5_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
    testWidgets('C5 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        fakeRepo(),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.text(language == 'en' ? 'Archive person' : 'أرشفة الشخص'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
