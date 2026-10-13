import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/features/device_pairing/presentation/a6_permissions_screen.dart';
import 'package:remori/features/device_pairing/presentation/permissions_providers.dart';

class FakePermissions implements PermissionService {
  FakePermissions({this.platform = PermissionPlatform.android});
  @override
  final PermissionPlatform platform;
  final values = <SetupPermission, PermissionAccess>{
    SetupPermission.bluetooth: PermissionAccess.granted,
    SetupPermission.notifications: PermissionAccess.granted,
    SetupPermission.location: PermissionAccess.denied,
    SetupPermission.background: PermissionAccess.denied,
  };
  final requested = <SetupPermission>[];
  Completer<void>? pending;
  bool grant = true;
  bool fails = false;
  @override
  Future<Map<SetupPermission, PermissionAccess>> read() async {
    if (fails) throw StateError('PRIVATE native exception');
    return platform == PermissionPlatform.ios
        ? {
            SetupPermission.notifications:
                values[SetupPermission.notifications]!,
          }
        : Map.of(values);
  }

  @override
  Future<void> request(SetupPermission permission) async {
    requested.add(permission);
    if (pending != null) await pending!.future;
    if (grant) values[permission] = PermissionAccess.granted;
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  FakePermissions service, {
  String language = 'en',
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 47);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(caregiverAuthenticated: true),
        ),
        permissionServiceProvider.overrideWithValue(service),
      ],
      child: const RepaintBoundary(key: Key('a6-preview'), child: RemoriApp()),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RemoriApp)),
  );
  container
      .read(remoriRouterProvider)
      .goNamed(
        RemoriScreen.a6.name,
        extra: '00000001-0000-4000-8000-000000000001',
      );
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
  });
  testWidgets(
    'status is read without prompting; handover is disabled and caregiver continues',
    (tester) async {
      final service = FakePermissions();
      final container = await mount(tester, service);
      expect(service.requested, isEmpty);
      expect(find.text('Granted'), findsNWidgets(2));
      final handover = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Give phone to patient → patient mode'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(handover.onPressed, isNull);
      await tester.tap(find.text('Continue on caregiver mode'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(remoriRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/c1',
      );
      expect(container.read(routeAccessProvider).devicePaired, isFalse);
    },
  );
  testWidgets(
    'a denied request stays denied and duplicate requests are blocked',
    (tester) async {
      final service = FakePermissions()
        ..grant = false
        ..pending = Completer<void>();
      final container = await mount(tester, service);
      await tester.tap(find.text('Allow').first);
      await tester.pump();
      expect(service.requested, [SetupPermission.location]);
      await container
          .read(setupPermissionsProvider.notifier)
          .request(SetupPermission.location);
      expect(service.requested.length, 1);
      service.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Granted'), findsNWidgets(2));
      expect(find.text('Allow'), findsNWidgets(2));
    },
  );
  testWidgets('returning from settings refreshes current status', (
    tester,
  ) async {
    final service = FakePermissions();
    await mount(tester, service);
    service.values[SetupPermission.location] = PermissionAccess.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Granted'), findsNWidgets(3));
  });
  testWidgets(
    'platform failures do not show stale grants or private exceptions',
    (tester) async {
      final service = FakePermissions();
      final container = await mount(tester, service);
      service.fails = true;
      await container.read(setupPermissionsProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Granted'), findsNothing);
      expect(
        find.text('Unable to update permissions. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE'), findsNothing);
    },
  );
  testWidgets('iOS shows notifications and caregiver continuation only', (
    tester,
  ) async {
    await mount(tester, FakePermissions(platform: PermissionPlatform.ios));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Bluetooth'), findsNothing);
    expect(find.text('Location'), findsNothing);
    expect(find.text('Background activity'), findsNothing);
    expect(find.text('Give phone to patient → patient mode'), findsNothing);
  });
  testWidgets('back passes patient context to A5', (tester) async {
    final container = await mount(tester, FakePermissions());
    await tester.tap(find.text('Permissions'));
    await tester.pumpAndSettle();
    final router = container.read(remoriRouterProvider);
    expect(router.routeInformationProvider.value.uri.path, '/a5');
    expect(
      router.routerDelegate.currentConfiguration.extra,
      '00000001-0000-4000-8000-000000000001',
    );
  });
  for (final language in ['en', 'ar']) {
    testWidgets('A6 $language enlarged text scrolls to caregiver action', (
      tester,
    ) async {
      await mount(
        tester,
        FakePermissions(),
        language: language,
        size: const Size(320, 480),
        scale: 2,
      );
      final action = find.text(
        language == 'en'
            ? 'Continue on caregiver mode'
            : 'المتابعة في وضع مقدم الرعاية',
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(A6PermissionsScreen), findsNothing);
    });
    for (final platform in [
      PermissionPlatform.android,
      PermissionPlatform.ios,
    ]) {
      testWidgets('A6 $language ${platform.name} reference capture', (
        tester,
      ) async {
        final shadows = debugDisableShadows;
        if (autoUpdateGoldenFiles) debugDisableShadows = false;
        try {
          await mount(
            tester,
            FakePermissions(platform: platform),
            language: language,
          );
          expect(
            Directionality.of(tester.element(find.byType(A6PermissionsScreen))),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(tester.getTopLeft(find.byType(A6PermissionsScreen)).dy, 47);
          expect(tester.takeException(), isNull);
          if (autoUpdateGoldenFiles) {
            await expectLater(
              find.byKey(const Key('a6-preview')),
              matchesGoldenFile('goldens/a6_${platform.name}_$language.png'),
            );
          }
        } finally {
          debugDisableShadows = shadows;
        }
      });
    }
  }
}
