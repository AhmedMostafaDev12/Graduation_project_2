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
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/places/data/places_repository.dart';
import 'package:remori/features/places/domain/places_data.dart';
import 'package:remori/features/places/presentation/places_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as home;
import 'c8_reminders_test.dart' as c8;

const scope = PlacesScope('caregiver-A', home.patient);
final now = DateTime.utc(2026, 10, 15);
const names = ['Home · البيت', "بيت أحمد · Ahmed's house", 'Clinic'];
const radii = [100, 150, 80];
PlacesData fixture() => PlacesData(
  refreshedAt: now,
  places: [
    for (var i = 0; i < 3; i++)
      SavedPlace(
        id: 'place-$i',
        name: names[i],
        latitude: 30.0444 + i / 100,
        longitude: 31.2357 + i / 100,
        radiusM: radii[i],
        createdBy: 'caregiver-A',
        updatedAt: now,
      ),
  ],
);

class Adapter implements HttpClientAdapter {
  bool fail = false, empty = false, duplicate = false, missing = false;
  Map<String, Object?>? invalid;
  Completer<void>? gate;
  final requests = <RequestOptions>[];
  Map<String, Object?> body(int i) => {
    'id': 'place-$i',
    'patient_id': scope.patientId,
    'name': names[i],
    'latitude': 30.0444 + i / 100,
    'longitude': 31.2357 + i / 100,
    'radius_m': radii[i],
    'created_by': 'caregiver-A',
    'updated_at': now.toIso8601String(),
    'deleted_at': null,
    if (i == 1 && invalid != null) ...invalid!,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (gate != null) await gate!.future;
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(
        missing
            ? {
                'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE'},
              }
            : empty
            ? []
            : [body(0), body(duplicate ? 0 : 1), body(2)],
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

class FakeRepository extends PlacesRepository {
  FakeRepository(super.client, super.db, super.scope);
  PlacesData data = fixture();
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
  Future<PlacesData> read() async => data;
  @override
  Stream<PlacesData> watch() async* {
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

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late PlacesRepository repo;
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
    repo = PlacesRepository(client, db, scope);
  });
  tearDown(() async {
    client.close();
    await db.close();
  });
  test(
    'GET preserves API names, order, coordinates and scoped local metadata',
    () async {
      await repo.refresh();
      final data = await repo.read();
      expect(data.places.map((p) => p.name), names);
      expect(data.places.map((p) => p.radiusM), radii);
      expect(data.places.first.latitude, 30.0444);
      expect(data.places.first.updatedAt, now);
      expect(data.refreshedAt?.isUtc, true);
      expect(
        adapter.requests.single.path,
        '/patients/${scope.patientId}/places',
      );
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.queryParameters, isEmpty);
      expect(
        (await PlacesRepository(
          client,
          db,
          const PlacesScope('other', home.patient),
        ).read()).places,
        isEmpty,
      );
      expect(
        (await PlacesRepository(
          client,
          db,
          const PlacesScope('caregiver-A', home.otherPatient),
        ).read()).places,
        isEmpty,
      );
    },
  );
  test('network failure preserves saved list and freshness', () async {
    await repo.refresh();
    final before = await repo.read();
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    final after = await repo.read();
    expect(after.refreshedAt, before.refreshedAt);
    expect(after.places.map((p) => p.name), names);
  });
  for (final invalid in [
    {'patient_id': home.otherPatient},
    {'name': ' '},
    {'name': 'a' * 81},
    {'latitude': 91},
    {'latitude': '30.0'},
    {'longitude': -181},
    {'radius_m': 19},
    {'radius_m': 2001},
    {'radius_m': 100.5},
    {'created_by': ''},
    {'updated_at': 'invalid'},
    {'updated_at': '2026-10-15T00:00:00'},
    {'deleted_at': now.toIso8601String()},
  ]) {
    test(
      'rejects ${invalid.keys.single} ${invalid.values.single} atomically',
      () async {
        await repo.refresh();
        final before = await repo.read();
        adapter.invalid = invalid;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        final after = await repo.read();
        expect(after.refreshedAt, before.refreshedAt);
        expect(after.places.map((p) => p.name), names);
      },
    );
  }
  test('duplicate IDs reject the entire refresh', () async {
    await repo.refresh();
    adapter.duplicate = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).places.length, 3);
  });
  Future<void> seedOther() => db
      .into(db.cachedPlaces)
      .insert(
        CachedPlacesCompanion.insert(
          caregiverId: 'other-account',
          patientId: scope.patientId,
          id: 'place-0',
          name: 'Other place',
          latitude: 0,
          longitude: 0,
          radiusM: 100,
          createdBy: 'other-account',
          updatedAt: now,
          position: 0,
        ),
      );
  test('empty refresh deletes only current-scope rows', () async {
    await repo.refresh();
    await seedOther();
    adapter.empty = true;
    await repo.refresh();
    expect((await repo.read()).places, isEmpty);
    expect(
      (await db.select(db.cachedPlaces).getSingle()).caregiverId,
      'other-account',
    );
  });
  test('known missing patient purges its places and freshness', () async {
    await repo.refresh();
    await seedOther();
    adapter.missing = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).places, isEmpty);
    expect((await repo.read()).refreshedAt, isNull);
    expect(
      (await db.select(db.cachedPlaces).getSingle()).caregiverId,
      'other-account',
    );
  });
  test('late refresh cannot undo a purge', () async {
    await repo.refresh();
    adapter.gate = Completer<void>();
    final refresh = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    await repo.purge();
    adapter.gate!.complete();
    await refresh;
    expect((await repo.read()).places, isEmpty);
  });
  test('Home removes place caches for removed links without touching other accounts', () async {
    await repo.refresh();
    await seedOther();
    final homeClient = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: home.HomeAdapter()..empty = true,
      onCredentialsInvalidated: (_) {},
    );
    try {
      await HomeRepository(homeClient, db, scope.caregiverId).refresh(null);
    } finally {
      homeClient.close();
    }
    expect((await repo.read()).places, isEmpty);
    expect((await repo.read()).refreshedAt, isNull);
    expect(
      (await db.select(db.cachedPlaces).getSingle()).caregiverId,
      'other-account',
    );
  });
  test(
    'schema v7 upgrade preserves unknown samples and pending writes',
    () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'remori-c10-migration-',
      );
      try {
        final file = File(
          '${directory.path}${Platform.pathSeparator}cache.sqlite',
        );
        db = RemoriDatabase(NativeDatabase(file));
        await db.saveReminderLog(
          patientId: scope.patientId,
          reminderId: '00000005-0000-4000-8000-000000000001',
          scheduledAt: now,
          at: now,
          status: ReminderStatus.pending,
        );
        await db
            .into(db.cachedUnknownFaceSamples)
            .insert(
              CachedUnknownFaceSamplesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
                clusterId: 'cluster',
                id: 'photo',
                url: 'https://example.test/photo',
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
        await db.customStatement('DROP TABLE cached_places');
        await db.customStatement('DROP TABLE places_cache_states');
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN firmware_version',
        );
        await db.customStatement(
          'ALTER TABLE dashboard_devices DROP COLUMN paired_at',
        );
        await db.customStatement('PRAGMA user_version = 7');
        await db.close();
        db = RemoriDatabase(NativeDatabase(file));
        expect((await db.pendingWrites(scope.patientId)).length, 1);
        expect(
          (await db.select(db.cachedUnknownFaceSamples).getSingle()).id,
          'photo',
        );
        expect(await db.select(db.cachedPlaces).get(), isEmpty);
        expect(await db.select(db.placesCacheStates).get(), isEmpty);
        await db.close();
        db = RemoriDatabase(NativeDatabase.memory());
      } finally {
        if (directory.absolute.parent.path !=
                Directory.systemTemp.absolute.path ||
            !directory.path.contains('remori-c10-migration-')) {
          throw StateError('Unexpected temporary path');
        }
        await directory.delete(recursive: true);
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
    PlacesScope? Function()? selected,
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
        placesScopeProvider.overrideWith(
          (ref) => selected == null ? scope : selected(),
        ),
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
        placesRepositoryProvider(scope).overrideWithValue(fake),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c18: (_, _) => const Text('More destination'),
          RemoriScreen.c9: (_, _) => const Text('Reminder destination'),
          RemoriScreen.c11: (_, state) =>
              Text('Place editor destination', key: ValueKey(state.extra)),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c10-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c10.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('C10 shows saved names and radii and opens scoped C11 editors', (
    tester,
  ) async {
    final fake = FakeRepository(client, db, scope);
    await mount(tester, fake);
    expect(find.text('Saved places'), findsOneWidget);
    expect(find.text(names.first), findsOneWidget);
    expect(find.text('Radius 100 m'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '+ Add'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('place-place-0')));
    await tester.pumpAndSettle();
    expect(find.text('Place editor destination'), findsOneWidget);
    expect(
      (tester.widget<Text>(find.text('Place editor destination')).key
              as ValueKey)
          .value,
      {'patient_id': scope.patientId, 'place_id': 'place-0'},
    );
    expect(fake.refreshes, 1);
  });
  testWidgets('viewer reads places without add or edit prompts', (
    tester,
  ) async {
    await mount(tester, FakeRepository(client, db, scope), viewer: true);
    expect(find.text(names.first), findsOneWidget);
    expect(find.text('+ Add'), findsNothing);
    expect(find.textContaining('place editor is ready'), findsNothing);
  });
  testWidgets('offline list remains readable and Retry refreshes it', (
    tester,
  ) async {
    final fake = FakeRepository(client, db, scope)..fail = true;
    await mount(tester, fake);
    expect(find.text(names.first), findsOneWidget);
    expect(find.textContaining('Showing saved places'), findsOneWidget);
    fake.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(fake.refreshes, 2);
    expect(find.textContaining('Showing saved places'), findsNothing);
  });
  testWidgets('empty list and failed initial load use localized states', (
    tester,
  ) async {
    final fake = FakeRepository(client, db, scope)
      ..data = const PlacesData()
      ..fail = true;
    await mount(tester, fake);
    expect(find.text('No saved places yet.'), findsOneWidget);
    expect(
      find.textContaining('Unable to update saved places'),
      findsOneWidget,
    );
  });
  testWidgets(
    'switching patients hides the old list and ignores its late refresh',
    (tester) async {
      PlacesScope? selected = scope;
      final fake = FakeRepository(client, db, scope);
      final container = await mount(tester, fake, selected: () => selected);
      fake.gate = Completer<void>();
      final refresh = container.read(placesRefreshProvider.notifier).refresh();
      selected = null;
      container.invalidate(placesScopeProvider);
      await tester.pumpAndSettle();
      fake.gate!.complete();
      await refresh;
      await tester.pumpAndSettle();
      expect(find.text(names.first), findsNothing);
      expect(find.textContaining('Select a patient'), findsOneWidget);
    },
  );
  testWidgets('Back uses More and the existing center action opens C9', (
    tester,
  ) async {
    final container = await mount(tester, FakeRepository(client, db, scope));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('More destination'), findsOneWidget);
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c10.name);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Reminder destination'), findsOneWidget);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C10 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(
        tester,
        FakeRepository(client, db, scope),
        language: language,
      );
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c10-preview')),
          matchesGoldenFile('goldens/c10_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C10 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        FakeRepository(client, db, scope),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
