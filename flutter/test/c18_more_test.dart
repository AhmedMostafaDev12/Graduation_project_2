import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/db/remori_database.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/caregiver_dashboard/data/home_repository.dart';
import 'package:remori/features/caregiver_dashboard/data/more_repository.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/domain/more_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/caregiver_dashboard/presentation/more_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as c1;
import 'c5_person_detail_test.dart' as c5;
import 'c8_reminders_test.dart' as c8;
import 'c16_device_test.dart' as c16;

const MoreScope scope = ('caregiver-A', c1.patient);
final now = c1.now;

class Adapter extends c16.Adapter {
  bool revoked = false, face = false, already = false;
  bool emptyConsents = false;
  Map<String, Object?>? badConsent, badAccount;
  Completer<void>? consentGate;
  String name = 'Patient', language = 'ar', timezone = 'Africa/Cairo';
  @override
  List<Map<String, Object?>> get patients => [
    for (final p in super.patients)
      {
        ...p,
        if (p['id'] == c1.patient) ...{
          'full_name': name,
          'preferred_language': language,
          'timezone': timezone,
        },
      },
  ];
  Map<String, Object?> consent(int i) => {
    'id': 'consent-$i',
    'consent_type': face && i == 0
        ? 'face_enrollment'
        : i == 0
        ? 'ambient_audio_household'
        : 'cloud_processing',
    'subject_person_id': face && i == 0 ? 'person-A' : null,
    'subject_name': face && i == 0 ? 'Family member' : null,
    'given_by': scope.$1,
    'given_at': now.subtract(Duration(days: 13 + i)).toIso8601String(),
    'revoked_at': revoked && i == 0 ? now.toIso8601String() : null,
    'embedding': 'PRIVATE_EXTRA',
    ...?badConsent,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (!o.path.endsWith('/consents') &&
        !o.path.endsWith('/revoke') &&
        o.path != '/auth/me' &&
        o.path != '/auth/logout' &&
        o.method != 'PATCH') {
      return super.fetch(o, stream, cancel);
    }
    requests.add(o);
    Object? result;
    var status = 200;
    if (o.path == '/auth/me') {
      result = {
        'id': scope.$1,
        'role': 'caregiver',
        'full_name': 'Caregiver',
        'email': 'caregiver@example.test',
        'password': 'PRIVATE_EXTRA',
        ...?badAccount,
      };
    }
    if (o.path.endsWith('/consents')) {
      result = [
        if (!emptyConsents)
          for (var i = 0; i < 2; i++) consent(i),
      ];
    }
    if (consentGate != null && o.path.endsWith('/consents')) {
      await consentGate!.future;
    }
    if (this.fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    if (o.path.endsWith('/revoke')) {
      revoked = true;
      if (already) {
        result = {
          'error': {'code': 'ALREADY_REVOKED', 'message': 'PRIVATE'},
        };
        status = 409;
      } else {
        result = consent(0);
      }
    }
    if (o.method == 'PATCH') {
      final p = o.data as Map;
      name = p['full_name'] as String? ?? name;
      language = p['preferred_language'] as String? ?? language;
      timezone = p['timezone'] as String? ?? timezone;
      result = patients.first;
    }
    if (o.path == '/auth/logout') return ResponseBody.fromString('', 204);
    return ResponseBody.fromString(
      jsonEncode(result),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class Credentials extends auth.TestCredentials {
  bool failClear = false;
  @override
  Future<void> clearCaregiver() async {
    if (failClear) throw StateError('Synthetic storage failure');
    await super.clearCaregiver();
  }
}

class Home extends HomeRepository {
  Home(super.client, super.db, super.caregiverId);
  final updates = StreamController<void>.broadcast();
  @override
  Stream<HomeData> watch() async* {
    yield await read();
    await for (final _ in updates.stream) {
      yield await read();
    }
  }

  @override
  Future<void> cacheProfile(HomePatient patient) async {
    await super.cacheProfile(patient);
    updates.add(null);
  }

  @override
  void dispose() {
    updates.close();
    super.dispose();
  }
}

class Repository extends MoreRepository {
  Repository(
    super.client,
    super.db,
    super.home,
    super.credentials,
    super.scope,
    super.peoplePhotos,
    super.personPhotos,
    super.clock,
  );
  final updates = StreamController<void>.broadcast();
  bool cacheFails = false;
  @override
  Stream<MoreData> watch() async* {
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
  Future<void> cacheProfile(HomePatient receipt) async {
    if (cacheFails) throw StateError('Synthetic cache failure');
    await super.cacheProfile(receipt);
    updates.add(null);
  }

  @override
  Future<void> cacheRevocation(ConsentRecord c) async {
    if (cacheFails) throw StateError('Synthetic cache failure');
    await super.cacheRevocation(c);
    updates.add(null);
  }

  @override
  void dispose() {
    if (!updates.isClosed) updates.close();
    super.dispose();
  }
}

void main() {
  late RemoriDatabase db;
  late Adapter adapter;
  late Credentials credentials;
  late ApiClient client;
  late Home home;
  late Repository repo;
  late c5.PeopleCache peoplePhotos;
  late c5.PhotoCache personPhotos;
  setUpAll(() async {
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
    credentials = Credentials();
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: credentials,
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    home = Home(client, db, scope.$1);
    peoplePhotos = c5.PeopleCache();
    personPhotos = c5.PhotoCache();
    repo = Repository(
      client,
      db,
      home,
      credentials,
      scope,
      peoplePhotos,
      personPhotos,
      () => now,
    );
  });
  tearDown(() async {
    repo.dispose();
    home.dispose();
    client.close();
    await db.close();
  });
  Future<void> patient({bool viewer = false, String account = 'caregiver-A'}) =>
      db
          .into(db.dashboardPatients)
          .insert(
            DashboardPatientsCompanion.insert(
              caregiverId: account,
              id: c1.patient,
              fullName: 'Patient',
              preferredLanguage: 'ar',
              timezone: 'Africa/Cairo',
              memoryCaptureEnabled: true,
              permission: viewer ? 'viewer' : 'manager',
              position: 0,
            ),
          );
  Future<void> face() async {
    await db
        .into(db.cachedPeople)
        .insert(
          CachedPeopleCompanion.insert(
            caregiverId: scope.$1,
            patientId: c1.patient,
            id: 'person-A',
            name: 'Family member',
            relationship: 'family',
            status: 'active',
            embeddingCount: 1,
            updatedAt: now,
            photoUrl: const Value('https://example.test/person'),
            position: 0,
          ),
        );
    await db
        .into(db.cachedPersonPhotos)
        .insert(
          CachedPersonPhotosCompanion.insert(
            caregiverId: scope.$1,
            patientId: c1.patient,
            personId: 'person-A',
            id: 'photo',
            url: 'https://example.test/photo',
            position: 0,
          ),
        );
  }

  test(
    'refresh persists allowlisted account and scoped consent display fields',
    () async {
      await patient();
      await repo.refresh();
      final data = await repo.read();
      expect(data.account?.email, 'caregiver@example.test');
      expect(data.consents.length, 2);
      final payload = (await db.select(db.cachedConsents).get())
          .map((c) => c.payload)
          .join();
      expect(payload, isNot(contains('PRIVATE_EXTRA')));
      expect(adapter.requests.map((r) => r.path), [
        '/auth/me',
        '/patients/${c1.patient}/consents',
      ]);
    },
  );
  test('offline refresh preserves saved account and consent records', () async {
    await patient();
    await repo.refresh();
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).consents.length, 2);
  });
  test('different account cannot read cached account or consents', () async {
    await patient();
    await repo.refresh();
    final other = MoreRepository(
      client,
      db,
      home,
      credentials,
      ('other', c1.patient),
      peoplePhotos,
      personPhotos,
      () => now,
    );
    expect((await other.read()).account, isNull);
    expect((await other.read()).consents, isEmpty);
    other.dispose();
  });
  for (final bad in [
    {'id': ''},
    {'consent_type': 'unknown'},
    {'given_at': 'bad'},
    {'patient_id': c1.otherPatient},
    {'consent_type': 'face_enrollment', 'subject_person_id': null},
  ]) {
    test(
      'malformed consent refresh leaves previous cache intact: $bad',
      () async {
        await patient();
        await repo.refresh();
        adapter.badConsent = bad;
        await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
        expect((await repo.read()).consents.length, 2);
      },
    );
  }
  test('mismatched account response cannot overwrite cache', () async {
    await patient();
    await repo.refresh();
    adapter.badAccount = {'id': 'other'};
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).account?.id, scope.$1);
  });
  test(
    'profile sends only changed fields and caches only after acknowledgment',
    () async {
      await patient();
      final receipt = await repo.editProfile(
        const PatientProfile('New name', 'ar', 'Africa/Cairo'),
      );
      expect(adapter.requests.single.data, {'full_name': 'New name'});
      expect((await home.read()).patients.single.name, 'Patient');
      await repo.cacheProfile(receipt);
      expect((await home.read()).patients.single.name, 'New name');
    },
  );
  test('profile caching preserves a newer memory-switch update', () async {
    await patient();
    final receipt = await repo.editProfile(
      const PatientProfile('New name', 'ar', 'Africa/Cairo'),
    );
    await home.cacheDeviceChange(const DeviceChange.memory(c1.patient, false));
    await repo.cacheProfile(receipt);
    expect((await home.read()).patients.single.memoryEnabled, false);
  });
  test('account remains available when no patient is selected', () async {
    final accountOnly = MoreRepository(
      client,
      db,
      home,
      credentials,
      (scope.$1, null),
      peoplePhotos,
      personPhotos,
      () => now,
    );
    await accountOnly.refresh();
    expect((await accountOnly.read()).account?.id, scope.$1);
    expect(adapter.requests.single.path, '/auth/me');
    accountOnly.dispose();
  });
  test(
    'place count distinguishes missing cache from a refreshed empty list',
    () async {
      await patient();
      expect((await repo.read()).placeCount, isNull);
      await db
          .into(db.placesCacheStates)
          .insert(
            PlacesCacheStatesCompanion.insert(
              caregiverId: scope.$1,
              patientId: c1.patient,
              refreshedAt: now,
            ),
          );
      expect((await repo.read()).placeCount, 0);
    },
  );
  test('invalid profile and viewer writes send no requests', () async {
    await patient(viewer: true);
    await expectLater(
      repo.editProfile(const PatientProfile('Name', 'en', 'UTC')),
      throwsA(isA<ApiFailure>()),
    );
    await expectLater(repo.revoke('consent-0'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
    expect(const PatientProfile('Name', 'en', 'Invalid/Zone').isValid, false);
    expect(const PatientProfile('', 'en', 'UTC').isValid, false);
  });
  test('revocation verifies cached consent before sending', () async {
    await patient();
    await expectLater(repo.revoke('unknown'), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
  });
  test(
    'face revocation archives the person and evicts enrolled photos',
    () async {
      await patient();
      await face();
      adapter.face = true;
      await repo.refresh();
      await repo.cacheRevocation(await repo.revoke('consent-0'));
      final p = await db.select(db.cachedPeople).getSingle();
      expect(p.status, 'archived');
      expect(p.photoUrl, isNull);
      expect(p.embeddingCount, 0);
      expect(await db.select(db.cachedPersonPhotos).get(), isEmpty);
      expect(peoplePhotos.removed.length, 1);
      expect(personPhotos.removed.length, 1);
      expect((await repo.read()).consents.first.revokedAt, now);
    },
  );
  test('refresh also applies face revocation made on another phone', () async {
    await patient();
    await face();
    adapter.face = true;
    adapter.revoked = true;
    await repo.refresh();
    expect((await db.select(db.cachedPeople).getSingle()).status, 'archived');
    expect(personPhotos.removed.length, 1);
  });
  test(
    'already-revoked conflict refreshes instead of repeating POST',
    () async {
      await patient();
      await repo.refresh();
      adapter.already = true;
      final c = await repo.revoke('consent-0');
      expect(c.revokedAt, now);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    },
  );
  test(
    'removed patient link cannot be restored by a late consent response',
    () async {
      await patient();
      adapter.consentGate = Completer<void>();
      final pending = repo.refresh();
      while (!adapter.requests.any((r) => r.path.endsWith('/consents'))) {
        await Future<void>.delayed(Duration.zero);
      }
      await db.delete(db.dashboardPatients).go();
      adapter.consentGate!.complete();
      await pending;
      expect(await db.select(db.cachedConsents).get(), isEmpty);
    },
  );
  test('disposed refresh cannot write a late response', () async {
    await patient();
    adapter.consentGate = Completer<void>();
    final pending = repo.refresh();
    while (!adapter.requests.any((r) => r.path.endsWith('/consents'))) {
      await Future<void>.delayed(Duration.zero);
    }
    repo.dispose();
    adapter.consentGate!.complete();
    try {
      await pending;
    } on ApiFailure {
      /* cancelled */
    }
    expect(await db.select(db.cachedConsents).get(), isEmpty);
  });
  test(
    'logout clears caregiver tokens only after unauthenticated POST succeeds',
    () async {
      await repo.logout(current: () => true);
      expect(credentials.caregiver, isNull);
      expect(credentials.token, 'test-device');
      final request = adapter.requests.single;
      expect(request.path, '/auth/logout');
      expect(request.data, {'refresh_token': 'test-refresh'});
      expect(request.headers.containsKey('Authorization'), false);
    },
  );
  test('logout storage retry does not repeat the acknowledged POST', () async {
    credentials.failClear = true;
    await expectLater(repo.logout(current: () => true), throwsStateError);
    credentials.failClear = false;
    await repo.logout(current: () => true);
    expect(adapter.requests.length, 1);
    expect(credentials.caregiver, isNull);
  });
  test('failed logout retains credentials', () async {
    adapter.fail = true;
    await expectLater(
      repo.logout(current: () => true),
      throwsA(isA<ApiFailure>()),
    );
    expect(credentials.caregiver, isNotNull);
  });
  test(
    'account change prevents logout from clearing another session',
    () async {
      await expectLater(
        repo.logout(current: () => false),
        throwsA(isA<ApiFailure>()),
      );
      expect(adapter.requests, isEmpty);
      expect(credentials.caregiver, isNotNull);
    },
  );
  test('schema v13 upgrade preserves Home and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-c18-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      await patient();
      await db.saveReminderLog(
        patientId: c1.patient,
        reminderId: '00000005-0000-4000-8000-000000000001',
        scheduledAt: now,
        at: now,
        status: ReminderStatus.pending,
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
      await db.customStatement('PRAGMA user_version = 13');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect((await db.pendingWrites(c1.patient)).length, 1);
      expect((await db.select(db.dashboardPatients).get()).length, 1);
      expect(await db.select(db.cachedConsents).get(), isEmpty);
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
    } finally {
      if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
          !dir.path.contains('remori-c18-migration-')) {
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
    MoreScope? Function()? selected,
  }) async {
    await tester.runAsync(() async {
      if ((await db.select(db.dashboardPatients).get()).isEmpty) {
        await patient(viewer: viewer);
      }
    });
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
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
        moreScopeProvider.overrideWith(
          (ref) => selected == null ? scope : selected(),
        ),
        homeDataProvider.overrideWith(
          (ref) => ref.watch(moreScopeProvider) == scope
              ? home.watch()
              : Stream.value(const HomeData()),
        ),
        homeRepositoryProvider(scope.$1).overrideWithValue(home),
        moreRepositoryProvider(scope).overrideWithValue(repo),
        credentialStoreProvider.overrideWithValue(credentials),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        appLocaleProvider.overrideWithValue(Locale(language)),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          for (final screen in [
            RemoriScreen.c10,
            RemoriScreen.c12,
            RemoriScreen.c14,
            RemoriScreen.c16,
          ])
            screen: (_, _) => Text('${screen.name} destination'),
          RemoriScreen.a1: (_, _) => const Text('Mode destination'),
          RemoriScreen.c19: (_, _) => const Text('Caregivers destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c18-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c18.name);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'More shows actual account, patient and consent data with staged entries',
    (tester) async {
      await mount(tester);
      expect(find.text('Patient · Arabic · Africa/Cairo'), findsOneWidget);
      expect(find.text('Caregiver · caregiver@example.test'), findsOneWidget);
      expect(
        find.textContaining('Conversation memory · given'),
        findsOneWidget,
      );
      expect(find.text('2 linked · invite another'), findsNothing);
      await tester.tap(find.text('Caregivers'));
      await tester.pumpAndSettle();
      expect(find.text('Caregivers destination'), findsOneWidget);
    },
  );
  for (final destination in {
    'Journal': RemoriScreen.c12,
    'Saved places': RemoriScreen.c10,
    'Documents': RemoriScreen.c14,
    'Device': RemoriScreen.c16,
  }.entries) {
    testWidgets('${destination.key} opens the existing screen', (tester) async {
      await mount(tester);
      await tester.ensureVisible(find.text(destination.key));
      await tester.tap(find.text(destination.key));
      await tester.pumpAndSettle();
      expect(
        find.text('${destination.value.name} destination'),
        findsOneWidget,
      );
    });
  }
  testWidgets('profile dialog validates timezone and saves changed name', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Patient profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New patient');
    await tester.enterText(find.byType(TextFormField).last, 'Invalid/Zone');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    await tester.enterText(find.byType(TextFormField).last, 'Africa/Cairo');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('New patient · Arabic · Africa/Cairo'), findsOneWidget);
  });
  testWidgets('consent revocation needs confirmation; Cancel sends no POST', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Revoke'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    expect(find.textContaining('revoked'), findsOneWidget);
  });
  testWidgets('confirmed revoke with local failure retries cache only', (
    tester,
  ) async {
    await mount(tester);
    repo.cacheFails = true;
    await tester.tap(find.text('Revoke').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Revoke'));
    await tester.pumpAndSettle();
    expect(
      find.text('The change was saved. Retry to finish updating this phone.'),
      findsOneWidget,
    );
    repo.cacheFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
  });
  testWidgets(
    'confirmed profile update retries cache without repeating PATCH',
    (tester) async {
      final container = await mount(tester);
      repo.cacheFails = true;
      await tester.runAsync(
        () => container
            .read(moreControllerProvider(scope).notifier)
            .change(
              profile: const PatientProfile('New name', 'ar', 'Africa/Cairo'),
            ),
      );
      await tester.pumpAndSettle();
      expect(container.read(moreControllerProvider(scope)).pending, true);
      repo.cacheFails = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.method == 'PATCH').length, 1);
      expect(find.text('New name · Arabic · Africa/Cairo'), findsOneWidget);
    },
  );
  testWidgets('viewer has no profile editing or revoke action', (tester) async {
    await mount(tester, viewer: true);
    expect(find.text('Revoke'), findsNothing);
    await tester.tap(find.text('Patient profile'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('offline retains actual cached account and consents', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await patient();
      await repo.refresh();
    });
    adapter.fail = true;
    await mount(tester);
    expect(find.textContaining('Conversation memory · given'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Caregiver · caregiver@example.test'),
      180,
    );
    expect(find.text('Caregiver · caregiver@example.test'), findsOneWidget);
  });
  testWidgets(
    'patient or account change hides previous names and consent actions',
    (tester) async {
      MoreScope? selected = scope;
      final container = await mount(tester, selected: () => selected);
      selected = null;
      container.invalidate(moreScopeProvider);
      await tester.pumpAndSettle();
      expect(find.text('Caregiver · caregiver@example.test'), findsNothing);
      expect(find.text('Revoke'), findsNothing);
    },
  );
  testWidgets('logout succeeds then returns to mode selection', (tester) async {
    await mount(tester);
    await tester.scrollUntilVisible(find.text('Log out'), 180);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(credentials.caregiver, isNull);
    expect(find.text('Mode destination'), findsOneWidget);
  });
  testWidgets(
    'logout storage retry clears credentials without repeating POST',
    (tester) async {
      await mount(tester);
      credentials.failClear = true;
      await tester.scrollUntilVisible(find.text('Log out'), 180);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      credentials.failClear = false;
      await tester.scrollUntilVisible(find.text('Retry'), -180);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(credentials.caregiver, isNull);
      expect(adapter.requests.where((r) => r.path == '/auth/logout').length, 1);
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets('C18 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, language: language);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c18-preview')),
          matchesGoldenFile('goldens/c18_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C18 $language supports 2x text at 320dp', (tester) async {
      await mount(tester, language: language, scale: 2);
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
