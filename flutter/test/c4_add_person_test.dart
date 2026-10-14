import 'dart:async';
import 'dart:convert';

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
import 'package:remori/features/people/data/enrollment_photo_picker.dart';
import 'package:remori/features/people/data/person_enrollment_repository.dart';
import 'package:remori/features/people/domain/people_data.dart';
import 'package:remori/features/people/domain/person_enrollment.dart';
import 'package:remori/features/people/presentation/people_providers.dart';
import 'package:remori/features/people/presentation/person_enrollment_providers.dart';

import 'a6_handover_test.dart' as auth;

const scope = PeopleScope('caregiver-A', 'patient-A');
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
);
PersonEnrollment draft({bool consent = true, int count = 2}) =>
    PersonEnrollment(
      name: ' Person ',
      relationship: ' Daughter ',
      consent: consent,
      photos: List.generate(count, (_) => EnrollmentPhoto(png)),
    );

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 201;
  bool wrongPatient = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode(
        status == 201
            ? {
                'id': 'person-A',
                'patient_id': wrongPatient ? 'patient-B' : scope.patientId,
                'name': 'Person',
                'relationship': 'Daughter',
                'status': 'active',
                'embedding_count': 2,
                'updated_at': DateTime.utc(2026, 10, 14).toIso8601String(),
              }
            : {
                'error': {
                  'code': 'PHOTOS_INVALID',
                  'message': 'PRIVATE SERVER TEXT',
                  'details': [
                    {'field': 'body.photos.1', 'message': 'PRIVATE PHOTO TEXT'},
                  ],
                },
              },
      ),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRepository extends PersonEnrollmentRepository {
  FakeRepository(super.client, super.db, super.scope);
  int creates = 0, caches = 0;
  bool failCache = false;
  ApiFailure? failure;
  Completer<void>? gate;
  @override
  Future<CachedPeopleCompanion> create(PersonEnrollment draft) async {
    creates++;
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    return CachedPeopleCompanion.insert(
      caregiverId: scope.caregiverId,
      patientId: scope.patientId,
      id: 'person-A',
      name: draft.name.trim(),
      relationship: draft.relationship.trim(),
      status: 'active',
      embeddingCount: 1,
      updatedAt: DateTime.utc(2026, 10, 14),
      position: -1,
    );
  }

  @override
  Future<void> cache(CachedPeopleCompanion person) async {
    caches++;
    if (failCache) throw StateError('PRIVATE DB ERROR');
  }
}

class Picker implements EnrollmentPhotoPicker {
  bool? camera;
  bool cancel = false;
  @override
  Future<EnrollmentPhoto?> pick({required bool camera}) async {
    this.camera = camera;
    return cancel ? null : EnrollmentPhoto(png);
  }

  @override
  Future<List<EnrollmentPhoto>> recover() async => [];
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
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
  });
  tearDown(() async {
    client.close();
    await db.close();
  });

  test('consent, counts, signature and size enforce enrollment contract', () {
    expect(draft().valid, true);
    expect(draft(consent: false).valid, false);
    expect(draft(count: 0).valid, false);
    expect(draft(count: 6).valid, false);
    expect(
      EnrollmentPhoto(Uint8List(4 * 1024 * 1024 + 1)).problem,
      'PHOTO_TOO_LARGE',
    );
    expect(
      EnrollmentPhoto(Uint8List.fromList([1, 2, 3])).problem,
      'UNSUPPORTED_PHOTO',
    );
  });
  test(
    'multipart repeats photos, trims fields, caches only the owned scope',
    () async {
      final repo = PersonEnrollmentRepository(client, db, scope);
      final person = await repo.create(draft());
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/patients/patient-A/people');
      final body = request.data as FormData;
      expect(Map.fromEntries(body.fields), {
        'name': 'Person',
        'relationship': 'Daughter',
        'consent_given': 'true',
      });
      expect(body.files.map((f) => f.key), ['photos', 'photos']);
      expect(body.files.first.value.contentType.toString(), 'image/png');
      await repo.cache(person);
      final rows = await db.select(db.cachedPeople).get();
      expect(rows.single.caregiverId, scope.caregiverId);
      expect(rows.single.patientId, scope.patientId);
      expect(rows.single.photoUrl, null);
      expect(await db.select(db.outboxEntries).get(), isEmpty);
    },
  );
  test(
    'invalid drafts never upload; mismatched response never caches',
    () async {
      final repo = PersonEnrollmentRepository(client, db, scope);
      await expectLater(
        repo.create(draft(consent: false)),
        throwsA(isA<ApiFailure>()),
      );
      expect(adapter.requests, isEmpty);
      adapter.wrongPatient = true;
      await expectLater(repo.create(draft()), throwsA(isA<ApiFailure>()));
      expect(await db.select(db.cachedPeople).get(), isEmpty);
    },
  );
  test(
    'server slot errors stay structured and private text is not stringified',
    () async {
      adapter.status = 422;
      try {
        await PersonEnrollmentRepository(client, db, scope).create(draft());
        fail('expected failure');
      } on ApiFailure catch (error) {
        expect(error.code, 'PHOTOS_INVALID');
        expect(error.details.single.field, 'body.photos.1');
        expect(error.toString(), isNot(contains('PRIVATE')));
      }
    },
  );

  ProviderContainer controller(
    FakeRepository repo, {
    PeopleScope? Function()? selected,
    bool manager = true,
  }) => ProviderContainer(
    overrides: [
      peopleScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
      caregiverCanManageProvider.overrideWithValue(manager),
      personEnrollmentRepositoryProvider(scope).overrideWithValue(repo),
    ],
  );

  test(
    'successful POST survives cache failure without a second enrollment',
    () async {
      final repo = FakeRepository(client, db, scope)..failCache = true;
      final container = controller(repo);
      addTearDown(container.dispose);
      final sub = container.listen(personEnrollmentProvider(scope), (_, _) {});
      addTearDown(sub.close);
      final notifier = container.read(personEnrollmentProvider(scope).notifier);
      expect(await notifier.save(draft()), false);
      expect(container.read(personEnrollmentProvider(scope)).created, true);
      repo.failCache = false;
      expect(await notifier.save(draft()), true);
      expect(repo.creates, 1);
      expect(repo.caches, 2);
    },
  );
  test(
    'viewer cannot create; duplicate taps and late scope changes cannot cache',
    () async {
      final repo = FakeRepository(client, db, scope)..gate = Completer<void>();
      var selected = scope;
      final container = controller(repo, selected: () => selected);
      addTearDown(container.dispose);
      final sub = container.listen(personEnrollmentProvider(scope), (_, _) {});
      addTearDown(sub.close);
      final notifier = container.read(personEnrollmentProvider(scope).notifier);
      final pending = notifier.save(draft());
      expect(await notifier.save(draft()), false);
      selected = const PeopleScope('caregiver-B', 'patient-B');
      container.invalidate(peopleScopeProvider);
      repo.gate!.complete();
      expect(await pending, false);
      expect(repo.creates, 1);
      expect(repo.caches, 0);
      final viewer = controller(repo, manager: false);
      addTearDown(viewer.dispose);
      final listen = viewer.listen(personEnrollmentProvider(scope), (_, _) {});
      addTearDown(listen.close);
      expect(
        await viewer
            .read(personEnrollmentProvider(scope).notifier)
            .save(draft()),
        false,
      );
      expect(repo.creates, 1);
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester,
    FakeRepository repo,
    Picker picker, {
    String lang = 'en',
    bool viewer = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
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
        peopleScopeProvider.overrideWithValue(scope),
        caregiverCanManageProvider.overrideWithValue(!viewer),
        appLocaleProvider.overrideWithValue(Locale(lang)),
        personEnrollmentRepositoryProvider(scope).overrideWithValue(repo),
        enrollmentPhotoPickerProvider.overrideWithValue(picker),
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
          key: Key('c4-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(RemoriScreen.c4.name, extra: scope.patientId);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Person');
    await tester.enterText(find.byType(TextField).at(1), 'Daughter');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
  }

  testWidgets('required fields and consent prevent uploading', (tester) async {
    final repo = FakeRepository(client, db, scope);
    await mount(tester, repo, Picker());
    expect(find.text('Enter full name'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);
    await tester.tap(find.text('Save person'));
    await tester.pumpAndSettle();
    expect(find.text('Add at least one photo.'), findsOneWidget);
    expect(repo.creates, 0);
  });
  testWidgets('photo selection, consent, save returns to People', (
    tester,
  ) async {
    final repo = FakeRepository(client, db, scope);
    final picker = Picker();
    await mount(tester, repo, picker);
    await fill(tester);
    expect(picker.camera, false);
    await tester.tap(find.text('Save person'));
    await tester.pumpAndSettle();
    expect(find.text('People destination'), findsOneWidget);
    expect(repo.creates, 1);
  });
  testWidgets('bad photo slot is outlined without displaying server text', (
    tester,
  ) async {
    final repo = FakeRepository(client, db, scope)
      ..failure = ApiFailure(
        ApiFailureKind.server,
        code: 'PHOTOS_INVALID',
        details: [
          const ApiFieldError(field: 'body.photos.0', message: 'PRIVATE'),
        ],
      );
    await mount(tester, repo, Picker());
    await fill(tester);
    await tester.tap(find.text('Save person'));
    await tester.pumpAndSettle();
    expect(
      find.text('Photo 1: unable to use this photo. Please replace it.'),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE'), findsNothing);
  });
  testWidgets('viewer direct route denies editing', (tester) async {
    await mount(
      tester,
      FakeRepository(client, db, scope),
      Picker(),
      viewer: true,
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('Select a patient you manage from Home, then try again.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'camera cancellation and removing a selected photo preserve the form',
    (tester) async {
      final picker = Picker()..cancel = true;
      await mount(tester, FakeRepository(client, db, scope), picker);
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(picker.camera, true);
      expect(find.byType(Image), findsNothing);
      picker.cancel = false;
      await fill(tester);
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Person'), findsOneWidget);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C4 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(
        tester,
        FakeRepository(client, db, scope),
        Picker(),
        lang: language,
      );
      expect(tester.takeException(), isNull);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c4-preview')),
          matchesGoldenFile('goldens/c4_$language.png'),
        );
      }
      debugDisableShadows = true;
    });
  }
  testWidgets('Arabic enlarged layout scrolls without overflow', (
    tester,
  ) async {
    await mount(
      tester,
      FakeRepository(client, db, scope),
      Picker(),
      lang: 'ar',
      scale: 2,
    );
    expect(find.text('إضافة شخص'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('حفظ الشخص'));
    expect(tester.takeException(), isNull);
  });
}
