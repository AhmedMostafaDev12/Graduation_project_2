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
import 'package:remori/features/caregiver_dashboard/data/caregivers_repository.dart';
import 'package:remori/features/caregiver_dashboard/data/more_repository.dart';
import 'package:remori/features/caregiver_dashboard/domain/caregivers_data.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/caregiver_dashboard/presentation/caregivers_providers.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';

import 'a6_handover_test.dart' as auth;
import 'c1_home_test.dart' as c1;
import 'c5_person_detail_test.dart' as c5;
import 'c8_reminders_test.dart' as c8;
import 'c16_device_test.dart' as c16;
import 'c18_more_test.dart' as c18;

const scope = ('caregiver-A', c1.patient);
final now = c1.now;
const draft = CaregiverLinkDraft(
  email: 'new@example.test',
  relationship: 'Daughter',
);

class Adapter extends c16.Adapter {
  bool linked = false, duplicate = false, noEmail = false, emptyLinks = false;
  String? code;
  Map<String, Object?>? bad;
  Completer<void>? gateLinks;
  Map<String, Object?> linkRow(int i) => {
    'id': 'link-$i',
    'caregiver_id': i == 0 ? scope.$1 : 'caregiver-$i',
    'full_name': ['Ahmed Mostafa', 'Mona Ali', 'New caregiver'][i],
    'email': noEmail
        ? null
        : ['owner@example.test', 'mona@example.test', draft.email][i],
    'relationship': ['Son', 'Nurse', draft.relationship][i],
    'permission': i == 0 ? 'manager' : 'viewer',
    'is_primary': i == 0,
    'private_extra': 'MUST_NOT_PERSIST',
    if (i == 1) ...?bad,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (!o.path.endsWith('/caregivers')) return super.fetch(o, stream, cancel);
    requests.add(o);
    final list = [
      if (!emptyLinks) ...[linkRow(1), linkRow(0), if (linked) linkRow(2)],
      if (duplicate) linkRow(0),
    ];
    if (gateLinks != null && o.method == 'GET') await gateLinks!.future;
    if (this.fail) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    Object? result = list;
    var status = 200;
    if (denied) {
      result = {
        'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'PRIVATE'},
      };
      status = 404;
    } else if (o.method == 'POST') {
      if (code != null) {
        result = {
          'error': {'code': code, 'message': 'PRIVATE'},
        };
        status = code == 'ALREADY_LINKED'
            ? 409
            : code == 'MANAGER_ONLY'
            ? 403
            : 404;
        if (code == 'ALREADY_LINKED') linked = true;
      } else {
        linked = true;
        final body = o.data as Map;
        result = {
          ...linkRow(2),
          'email': body['email'],
          'relationship': body['relationship'],
          'permission': body['permission'],
        };
        status = 201;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class Repository extends CaregiversRepository {
  Repository(super.home, super.db, super.scope, super.clock);
  final updates = StreamController<void>.broadcast();
  bool cacheFails = false;
  @override
  Stream<CaregiversData> watch() async* {
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
  Future<void> cacheLink(LinkedCaregiver link) async {
    if (cacheFails) throw StateError('Synthetic cache failure');
    await super.cacheLink(link);
    if (!updates.isClosed) updates.add(null);
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
  late ApiClient client;
  late c18.Home home;
  late Repository repo;
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
    client = ApiClient(
      config: ApiConfig('https://example.test/api/v1'),
      credentials: auth.TestCredentials(),
      adapter: adapter,
      onCredentialsInvalidated: (_) {},
    );
    home = c18.Home(client, db, scope.$1);
    repo = Repository(home, db, scope, () => now);
  });
  tearDown(() async {
    repo.dispose();
    home.dispose();
    client.close();
    await db.close();
  });
  Future<void> patient({bool viewer = false}) => db
      .into(db.dashboardPatients)
      .insert(
        DashboardPatientsCompanion.insert(
          caregiverId: scope.$1,
          id: c1.patient,
          fullName: 'Patient',
          preferredLanguage: 'ar',
          timezone: 'Africa/Cairo',
          memoryCaptureEnabled: true,
          permission: viewer ? 'viewer' : 'manager',
          position: 0,
        ),
      );
  test(
    'GET caches allowlisted caregivers primary first and records refresh time',
    () async {
      await patient();
      await repo.refresh();
      final data = await repo.read();
      expect(data.links.map((l) => l.name), ['Ahmed Mostafa', 'Mona Ali']);
      expect(data.refreshedAt, now);
      expect(
        (await db.select(db.cachedCaregiverLinks).get())
            .map((r) => r.payload)
            .join(),
        isNot(contains('MUST_NOT_PERSIST')),
      );
      expect(
        adapter.requests.single.path,
        '/patients/${c1.patient}/caregivers',
      );
    },
  );
  test('offline keeps saved links and null emails are supported', () async {
    await patient();
    adapter.noEmail = true;
    await repo.refresh();
    adapter.fail = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).links.first.email, isNull);
  });
  for (final bad in [
    {'permission': 'owner'},
    {'is_primary': 'yes'},
    {'caregiver_id': ''},
    {'email': 7},
    {'patient_id': c1.otherPatient},
  ]) {
    test('malformed response leaves prior cache intact: $bad', () async {
      await patient();
      await repo.refresh();
      adapter.bad = bad;
      await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
      expect((await repo.read()).links.length, 2);
    });
  }
  test('duplicate IDs cannot overwrite a valid list', () async {
    await patient();
    await repo.refresh();
    adapter.duplicate = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect((await repo.read()).links.length, 2);
  });
  test('another caregiver or patient cannot read the list', () async {
    await patient();
    await repo.refresh();
    for (final other in [('other', c1.patient), (scope.$1, c1.otherPatient)]) {
      final r = CaregiversRepository(home, db, other, () => now);
      expect((await r.read()).links, isEmpty);
      r.dispose();
    }
  });
  test('viewer cannot link through repository', () async {
    await patient(viewer: true);
    await expectLater(repo.link(draft), throwsA(isA<ApiFailure>()));
    expect(adapter.requests, isEmpty);
  });
  test('POST links an existing account and cache applies only after acknowledgment', () async {
    await patient();
    await repo.refresh();
    final receipt = await repo.link(draft);
    expect((await repo.read()).links.length, 2);
    expect(adapter.requests.last.data, {
      'email': draft.email,
      'relationship': draft.relationship,
      'permission': 'viewer',
    });
    await repo.cacheLink(receipt);
    expect((await repo.read()).links.length, 3);
  });
  test('old GET cannot erase a newly confirmed link', () async {
    await patient();
    adapter.gateLinks = Completer<void>();
    final pending = repo.refresh();
    while (adapter.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await repo.cacheLink(await repo.link(draft));
    adapter.gateLinks!.complete();
    await pending;
    expect((await repo.read()).links.single.email, draft.email);
  });
  test('late response cannot recreate a removed patient link', () async {
    await patient();
    adapter.gateLinks = Completer<void>();
    final pending = repo.refresh();
    while (adapter.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await db.delete(db.dashboardPatients).go();
    adapter.gateLinks!.complete();
    await pending;
    expect(await db.select(db.cachedCaregiverLinks).get(), isEmpty);
  });
  test('disposed repository cannot cache late responses', () async {
    await patient();
    adapter.gateLinks = Completer<void>();
    final pending = repo.refresh();
    while (adapter.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    repo.dispose();
    adapter.gateLinks!.complete();
    await pending;
    expect(await db.select(db.cachedCaregiverLinks).get(), isEmpty);
  });
  test('known missing patient purges list and refresh metadata', () async {
    await patient();
    await repo.refresh();
    adapter.denied = true;
    await expectLater(repo.refresh(), throwsA(isA<ApiFailure>()));
    expect(await db.select(db.cachedCaregiverLinks).get(), isEmpty);
    expect(await db.select(db.caregiversCacheStates).get(), isEmpty);
  });
  test(
    'More counts only successfully refreshed scoped caregiver lists',
    () async {
      await patient();
      final more = MoreRepository(
        client,
        db,
        home,
        auth.TestCredentials(),
        scope,
        c5.PeopleCache(),
        c5.PhotoCache(),
        () => now,
      );
      expect((await more.read()).caregiverCount, isNull);
      await repo.refresh();
      expect((await more.read()).caregiverCount, 2);
      await repo.cacheLink(await repo.link(draft));
      expect((await more.read()).caregiverCount, 3);
      more.dispose();
    },
  );
  test('invalid draft does not send a request', () async {
    await patient();
    await expectLater(
      repo.link(const CaregiverLinkDraft(email: 'bad', relationship: '')),
      throwsA(isA<ApiFailure>()),
    );
    expect(adapter.requests, isEmpty);
  });
  test('schema v14 upgrade preserves accounts and pending writes', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('remori-c19-migration-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}cache.sqlite');
      db = RemoriDatabase(NativeDatabase(file));
      await patient();
      await db
          .into(db.cachedCaregiverAccounts)
          .insert(
            CachedCaregiverAccountsCompanion.insert(
              id: scope.$1,
              fullName: 'Caregiver',
              email: 'owner@example.test',
              refreshedAt: now,
            ),
          );
      await db.saveReminderLog(
        patientId: c1.patient,
        reminderId: '00000005-0000-4000-8000-000000000001',
        scheduledAt: now,
        at: now,
        status: ReminderStatus.pending,
      );
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
      await db.customStatement('PRAGMA user_version = 14');
      await db.close();
      db = RemoriDatabase(NativeDatabase(file));
      expect((await db.pendingWrites(c1.patient)).length, 1);
      expect(
        (await db.select(db.cachedCaregiverAccounts).getSingle()).id,
        scope.$1,
      );
      expect(await db.select(db.cachedCaregiverLinks).get(), isEmpty);
      await db.close();
      db = RemoriDatabase(NativeDatabase.memory());
    } finally {
      if (dir.absolute.parent.path != Directory.systemTemp.absolute.path ||
          !dir.path.contains('remori-c19-migration-')) {
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
    CaregiversScope? Function()? selected,
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
        caregiversScopeProvider.overrideWith(
          (ref) => selected == null ? scope : selected(),
        ),
        homeDataProvider.overrideWith(
          (ref) => ref.watch(caregiversScopeProvider) == scope
              ? home.watch()
              : Stream.value(const HomeData()),
        ),
        homeRepositoryProvider(scope.$1).overrideWithValue(home),
        caregiversRepositoryProvider(scope).overrideWithValue(repo),
        homeRefreshProvider.overrideWith(c8.QuietHome.new),
        appLocaleProvider.overrideWithValue(Locale(language)),
        screenBuildersProvider.overrideWithValue({
          ...builders,
          RemoriScreen.c18: (_, _) => const Text('More destination'),
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: Key('c19-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    container.read(remoriRouterProvider).goNamed(RemoriScreen.c19.name);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> submit(
    WidgetTester tester, {
    String email = 'new@example.test',
    String relationship = 'Daughter',
  }) async {
    await tester.enterText(find.byKey(const Key('caregiver-email')), email);
    await tester.enterText(
      find.byKey(const Key('caregiver-relationship')),
      relationship,
    );
    await tester.ensureVisible(find.text('Add caregiver'));
    await tester.tap(find.text('Add caregiver'));
    await tester.pumpAndSettle();
  }

  testWidgets('C19 shows primary, manager, viewer and you with initials', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Ahmed Mostafa (you)'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('Mona Ali'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Send invite'), findsNothing);
    expect(find.textContaining('No invitation email is sent.'), findsOneWidget);
  });
  testWidgets(
    'valid add defaults to Viewer and clears the form after caching',
    (tester) async {
      await mount(tester);
      await submit(tester);
      expect(find.text('New caregiver'), findsOneWidget);
      expect(adapter.requests.last.data, {
        'email': draft.email,
        'relationship': draft.relationship,
        'permission': 'viewer',
      });
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('caregiver-email')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets('manager permission can be selected explicitly', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Manager').last);
    await submit(tester);
    expect((adapter.requests.last.data as Map)['permission'], 'manager');
  });
  testWidgets('invalid email and relationship prevent POST', (tester) async {
    await mount(tester);
    await submit(tester, email: 'bad', relationship: '');
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });
  testWidgets('confirmed add with cache failure retries only local effects', (
    tester,
  ) async {
    await mount(tester);
    repo.cacheFails = true;
    await submit(tester);
    expect(
      find.text('Caregiver added. Retry to finish updating this phone.'),
      findsOneWidget,
    );
    repo.cacheFails = false;
    await tester.scrollUntilVisible(
      find.text('Retry'),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    expect(find.text('New caregiver'), findsOneWidget);
  });
  testWidgets('uncertain add locks form until a successful list refresh', (
    tester,
  ) async {
    final container = await mount(tester);
    adapter.fail = true;
    await submit(tester);
    expect(container.read(caregiversControllerProvider(scope)).uncertain, true);
    adapter.fail = false;
    await tester.scrollUntilVisible(
      find.text('Retry'),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      container.read(caregiversControllerProvider(scope)).uncertain,
      false,
    );
  });
  testWidgets('missing account explains that registration is required', (
    tester,
  ) async {
    await mount(tester);
    adapter.code = 'CAREGIVER_NOT_FOUND';
    await submit(tester);
    await tester.scrollUntilVisible(
      find.textContaining('No caregiver account'),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('They need to create an account first.'),
      findsOneWidget,
    );
  });
  testWidgets('already linked refreshes the list without repeating POST', (
    tester,
  ) async {
    await mount(tester);
    adapter.code = 'ALREADY_LINKED';
    await submit(tester);
    expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    expect(find.text('New caregiver'), findsOneWidget);
  });
  testWidgets('viewer has read access without the add form', (tester) async {
    final container = await mount(tester, viewer: true);
    expect(find.text('Mona Ali'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await container
        .read(caregiversControllerProvider(scope).notifier)
        .link(draft);
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
  });
  testWidgets('offline list uses saved caregiver data', (tester) async {
    await tester.runAsync(() async {
      await patient();
      await repo.refresh();
    });
    adapter.fail = true;
    await mount(tester);
    expect(find.text('Mona Ali'), findsOneWidget);
  });
  testWidgets('scope change hides previous names and clears form', (
    tester,
  ) async {
    CaregiversScope? selected = scope;
    final container = await mount(tester, selected: () => selected);
    await tester.enterText(
      find.byKey(const Key('caregiver-email')),
      draft.email,
    );
    selected = null;
    container.invalidate(caregiversScopeProvider);
    await tester.pumpAndSettle();
    expect(find.text('Mona Ali'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });
  testWidgets('Back returns to More', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('More destination'), findsOneWidget);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('C19 $language reference capture', (tester) async {
      debugDisableShadows = false;
      await mount(tester, language: language);
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('c19-preview')),
          matchesGoldenFile('goldens/c19_$language.png'),
        );
      }
      debugDisableShadows = true;
      expect(tester.takeException(), isNull);
    });
    testWidgets('C19 $language supports 2x text at 320dp', (tester) async {
      await mount(tester, language: language, scale: 2);
      await tester.drag(find.byType(ListView), const Offset(0, -1300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
