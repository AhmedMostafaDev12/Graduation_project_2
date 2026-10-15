import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
import 'package:remori/features/places/data/place_location.dart';
import 'package:remori/features/places/data/places_repository.dart';
import 'package:remori/features/places/domain/place_draft.dart';
import 'package:remori/features/places/domain/places_data.dart';
import 'package:remori/features/places/presentation/place_editor_providers.dart';
import 'package:remori/features/places/presentation/place_map.dart';
import 'package:remori/features/places/presentation/places_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c10_places_test.dart' as c10;

const scope = c10.scope;
const draft = PlaceDraft(name: 'Home', point: PlacePoint(30.0444, 31.2357));
const mapConfig = PlaceMapConfig(
  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

class Adapter extends c10.Adapter {
  int status = 0;
  bool foreign = false;
  String? failureCode;
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
    if (this.fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final deleted = options.method == 'DELETE';
    final p = body(0);
    if (options.data is Map) {
      p.addAll(Map<String, Object?>.from(options.data as Map));
    }
    if (foreign) p['patient_id'] = 'other-patient';
    return ResponseBody.fromString(
      deleted && failureCode == null
          ? ''
          : jsonEncode(
              failureCode == null
                  ? p
                  : {
                      'error': {'code': failureCode, 'message': 'PRIVATE'},
                    },
            ),
      status != 0
          ? status
          : deleted
          ? 204
          : options.method == 'POST'
          ? 201
          : 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class Location implements PlaceLocation {
  PlacePoint? point = const PlacePoint(30.0444, 31.2357);
  Completer<PlacePoint?>? gate;
  int calls = 0;
  @override
  Future<PlacePoint?> current() async {
    calls++;
    return gate == null ? point : await gate!.future;
  }
}

class Repository extends c10.FakeRepository {
  Repository(super.client, super.db, super.scope);
  int saves = 0, deletes = 0, caches = 0;
  bool failCache = false;
  ApiFailure? writeFailure;
  Completer<void>? writeGate;
  PlaceDraft? submitted;
  @override
  Future<PlaceReceipt> save(PlaceDraft draft, {String? id}) async {
    saves++;
    submitted = draft;
    if (writeGate != null) await writeGate!.future;
    if (writeFailure != null) throw writeFailure!;
    return PlaceReceipt(
      scope,
      id ?? 'created',
      CachedPlacesCompanion.insert(
        caregiverId: scope.caregiverId,
        patientId: scope.patientId,
        id: id ?? 'created',
        name: draft.name.trim(),
        latitude: draft.point!.latitude,
        longitude: draft.point!.longitude,
        radiusM: draft.radiusM,
        createdBy: scope.caregiverId,
        updatedAt: c10.now,
        position: 0,
      ),
    );
  }

  @override
  Future<PlaceReceipt> remove(String id) async {
    deletes++;
    return PlaceReceipt(scope, id, null);
  }

  @override
  Future<void> cacheReceipt(PlaceReceipt receipt) async {
    caches++;
    if (failCache) throw StateError('Local cache unavailable');
  }
}

class Tiles extends TileProvider {
  Tiles(this.bytes);
  final Uint8List bytes;
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(bytes);
}

void main() {
  late RemoriDatabase db;
  late ApiClient client;
  late Adapter adapter;
  late PlacesRepository repo;
  late Uint8List tile;
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
    final recorder = ui.PictureRecorder();
    final tileCanvas = Canvas(recorder);
    tileCanvas.drawColor(const Color(0xFFE2DCEE), BlendMode.src);
    tileCanvas.drawRect(
      const Rect.fromLTWH(0, 115, 256, 12),
      Paint()..color = Colors.white,
    );
    tileCanvas.drawRect(
      const Rect.fromLTWH(160, 0, 12, 256),
      Paint()..color = Colors.white,
    );
    final image = await recorder.endRecording().toImage(256, 256);
    tile = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
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
    'create, edit and delete use scoped API contracts and cache-only receipts',
    () async {
      final created = await repo.save(draft);
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, {
        'name': 'Home',
        'latitude': 30.0444,
        'longitude': 31.2357,
        'radius_m': 100,
      });
      await repo.cacheReceipt(created);
      expect((await repo.read()).places.single.radiusM, 100);
      final edited = await repo.save(
        draft.copyWith(name: 'Changed', radiusM: 150),
        id: 'place-0',
      );
      expect(adapter.requests.last.method, 'PATCH');
      expect(
        adapter.requests.last.path,
        '/patients/${scope.patientId}/places/place-0',
      );
      await repo.cacheReceipt(edited);
      expect((await repo.read()).places.single.name, 'Changed');
      final deleted = await repo.remove('place-0');
      expect(adapter.requests.last.method, 'DELETE');
      expect(adapter.requests.last.data, isNull);
      await repo.cacheReceipt(deleted);
      expect((await repo.read()).places, isEmpty);
      expect(adapter.requests.length, 3);
    },
  );
  test('invalid drafts never send a write', () async {
    for (final invalid in [
      const PlaceDraft(name: 'Name'),
      draft.copyWith(name: ''),
      draft.copyWith(name: 'a' * 81),
      draft.copyWith(point: const PlacePoint(91, 0)),
      draft.copyWith(radiusM: 19),
    ]) {
      await expectLater(repo.save(invalid), throwsA(isA<ApiFailure>()));
    }
    expect(adapter.requests, isEmpty);
  });
  test(
    'foreign and unexpected response IDs never yield cache receipts',
    () async {
      adapter.foreign = true;
      await expectLater(repo.save(draft), throwsA(isA<ApiFailure>()));
      adapter.foreign = false;
      await expectLater(
        repo.save(draft, id: 'other-id'),
        throwsA(isA<ApiFailure>()),
      );
      expect((await repo.read()).places, isEmpty);
    },
  );
  test('receipts cannot cross account/patient scopes', () async {
    final receipt = await repo.save(draft);
    await expectLater(
      PlacesRepository(
        client,
        db,
        const PlacesScope('other', 'patient'),
      ).cacheReceipt(receipt),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read()).places, isEmpty);
  });
  test('a late list response cannot resurrect a deleted place', () async {
    await repo.refresh();
    adapter.gate = Completer<void>();
    final pending = repo.refresh();
    await Future<void>.delayed(Duration.zero);
    final deleted = await repo.remove('place-0');
    await repo.cacheReceipt(deleted);
    adapter.gate!.complete();
    await pending;
    expect((await repo.read()).places.any((p) => p.id == 'place-0'), false);
  });
  test('map configuration rejects insecure or unapproved tile sources', () {
    expect(mapConfig.valid, true);
    for (final value in [
      '',
      'http://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'https://other.test/{z}/{x}/{y}.png',
    ]) {
      expect(PlaceMapConfig(value).valid, false);
    }
  });
  test('known revoked access during a write purges its scoped cache', () async {
    await repo.refresh();
    adapter.status = 404;
    adapter.failureCode = 'PATIENT_NOT_FOUND';
    await expectLater(
      repo.save(draft, id: 'place-0'),
      throwsA(isA<ApiFailure>()),
    );
    expect((await repo.read()).places, isEmpty);
    expect((await repo.read()).refreshedAt, isNull);
  });
  test(
    'known missing place during deletion removes only that cached place',
    () async {
      await repo.refresh();
      adapter.status = 404;
      adapter.failureCode = 'PLACE_NOT_FOUND';
      await expectLater(repo.remove('place-0'), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).places.map((p) => p.id), [
        'place-1',
        'place-2',
      ]);
    },
  );
  Future<ProviderContainer> mount(
    WidgetTester tester,
    Repository fake,
    Location location, {
    String? id = 'place-0',
    String language = 'en',
    bool viewer = false,
    PlacesScope Function()? selected,
    double scale = 1,
    Size size = const Size(390, 844),
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
        placesScopeProvider.overrideWith((ref) => selected?.call() ?? scope),
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
        placeLocationProvider.overrideWithValue(location),
        placeMapBuilderProvider.overrideWithValue(
          (context, draft, locked, select) => PlaceMap(
            draft: draft,
            locked: locked,
            select: select,
            config: mapConfig,
            tiles: Tiles(tile),
          ),
        ),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c10: (_, _) => const Text('Saved places destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c11-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container
        .read(remoriRouterProvider)
        .goNamed(
          RemoriScreen.c11.name,
          extra: {'patient_id': scope.patientId, 'place_id': ?id},
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

  testWidgets(
    'editing uses saved coordinates and never requests phone location',
    (tester) async {
      final location = Location();
      final fake = Repository(client, db, scope);
      await mount(tester, fake, location);
      expect(location.calls, 0);
      expect(find.text('Radius: 100 m'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Updated');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save place'));
      await tester.pumpAndSettle();
      expect(fake.submitted?.point?.latitude, 30.0444);
      expect(find.text('Saved places destination'), findsOneWidget);
    },
  );
  testWidgets('new places use one location fix and hide Delete', (
    tester,
  ) async {
    final location = Location();
    final container = await mount(
      tester,
      Repository(client, db, scope),
      location,
      id: null,
    );
    expect(location.calls, 1);
    expect(find.text('Delete place'), findsNothing);
    expect(
      container.read(placeEditorProvider((scope, null))).draft.point?.latitude,
      30.0444,
    );
  });
  testWidgets(
    'location denied requires manual selection and cannot save zero coordinates',
    (tester) async {
      final location = Location()..point = null;
      final fake = Repository(client, db, scope);
      final container = await mount(tester, fake, location, id: null);
      await tester.enterText(find.byType(TextField), 'New place');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save place'));
      await tester.pumpAndSettle();
      expect(fake.saves, 0);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(find.byType(FlutterMap));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(20, 15),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        container.read(placeEditorProvider((scope, null))).draft.point,
        isNotNull,
      );
      await tester.tap(find.text('Save place'));
      await tester.pumpAndSettle();
      expect(fake.saves, 1);
    },
  );
  testWidgets('late location cannot overwrite a manually selected point', (
    tester,
  ) async {
    final location = Location()..gate = Completer<PlacePoint?>();
    final container = await mount(
      tester,
      Repository(client, db, scope),
      location,
      id: null,
    );
    final controller = container.read(
      placeEditorProvider((scope, null)).notifier,
    );
    controller.change(point: const PlacePoint(20, 21));
    location.gate!.complete(const PlacePoint(30, 31));
    await tester.pumpAndSettle();
    expect(
      container.read(placeEditorProvider((scope, null))).draft.point?.latitude,
      20,
    );
  });
  testWidgets('dragging the actual map pin changes the selected coordinates', (
    tester,
  ) async {
    final container = await mount(
      tester,
      Repository(client, db, scope),
      Location(),
    );
    final before = container
        .read(placeEditorProvider((scope, 'place-0')))
        .draft
        .point!;
    await tester.drag(
      find.byKey(const ValueKey('place-pin')),
      const Offset(30, 15),
    );
    await tester.pumpAndSettle();
    final after = container
        .read(placeEditorProvider((scope, 'place-0')))
        .draft
        .point!;
    expect(after.longitude, isNot(before.longitude));
  });
  testWidgets('Delete requires confirmation and supports cancellation', (
    tester,
  ) async {
    final fake = Repository(client, db, scope);
    await mount(tester, fake, Location());
    await tester.tap(find.text('Delete place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fake.deletes, 0);
    await tester.tap(find.text('Delete place'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete place').last);
    await tester.pumpAndSettle();
    expect(fake.deletes, 1);
    expect(find.text('Saved places destination'), findsOneWidget);
  });
  testWidgets('confirmed save retries only the cache and locks fields', (
    tester,
  ) async {
    final fake = Repository(client, db, scope)..failCache = true;
    await mount(tester, fake, Location());
    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();
    expect(fake.saves, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, true);
    fake.failCache = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(fake.saves, 1);
    expect(fake.caches, 2);
  });
  testWidgets(
    'uncertain writes block resubmission until returning to the list',
    (tester) async {
      final fake = Repository(client, db, scope)
        ..writeFailure = ApiFailure(ApiFailureKind.timeout);
      final container = await mount(tester, fake, Location());
      await tester.tap(find.text('Save place'));
      await tester.pumpAndSettle();
      expect(
        container.read(placeEditorProvider((scope, 'place-0'))).uncertain,
        true,
      );
      expect(
        await container
            .read(placeEditorProvider((scope, 'place-0')).notifier)
            .write(),
        false,
      );
      expect(fake.saves, 1);
    },
  );
  testWidgets('out-of-slider radius is preserved until explicitly changed', (
    tester,
  ) async {
    final fake = Repository(client, db, scope);
    final p = fake.data.places.first;
    fake.data = PlacesData(
      places: [
        SavedPlace(
          id: p.id,
          name: p.name,
          latitude: p.latitude,
          longitude: p.longitude,
          radiusM: 1250,
          createdBy: p.createdBy,
          updatedAt: p.updatedAt,
        ),
      ],
    );
    await mount(tester, fake, Location());
    expect(find.text('Radius: 1,250 m'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();
    expect(fake.submitted?.radiusM, 1250);
  });
  testWidgets('viewer cannot open the editor or request location', (
    tester,
  ) async {
    final location = Location();
    await mount(
      tester,
      Repository(client, db, scope),
      location,
      viewer: true,
      id: null,
    );
    expect(find.byType(TextField), findsNothing);
    expect(location.calls, 0);
  });
  testWidgets('account changes discard late write receipts', (tester) async {
    var selected = scope;
    final fake = Repository(client, db, scope)..writeGate = Completer<void>();
    final container = await mount(
      tester,
      fake,
      Location(),
      selected: () => selected,
    );
    final pending = container
        .read(placeEditorProvider((scope, 'place-0')).notifier)
        .write();
    await tester.pump();
    selected = const PlacesScope('other', 'other-patient');
    container.invalidate(placesScopeProvider);
    await tester.pumpAndSettle();
    fake.writeGate!.complete();
    expect(await pending, false);
    expect(fake.caches, 0);
    expect(find.byType(TextField), findsNothing);
  });
  testWidgets('duplicate Save taps send only one write', (tester) async {
    final fake = Repository(client, db, scope)..writeGate = Completer<void>();
    final container = await mount(tester, fake, Location());
    final controller = container.read(
      placeEditorProvider((scope, 'place-0')).notifier,
    );
    final first = controller.write();
    expect(await controller.write(), false);
    fake.writeGate!.complete();
    expect(await first, true);
    expect(fake.saves, 1);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C11 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(
        tester,
        Repository(client, db, scope),
        Location(),
        language: language,
      );
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c11-preview')),
          matchesGoldenFile('goldens/c11_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C11 $language supports 2x text at 320dp', (tester) async {
      await mount(
        tester,
        Repository(client, db, scope),
        Location(),
        language: language,
        scale: 2,
        size: const Size(320, 844),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -650),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
