import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remori/app.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';

final _testAccess = NotifierProvider<_Access, RouteAccess>(_Access.new);

class _Access extends Notifier<RouteAccess> {
  @override
  RouteAccess build() => const RouteAccess();
  void set(RouteAccess access) => state = access;
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  RouteAccess access,
) async {
  final container = ProviderContainer(
    overrides: [
      caregiverCanManageProvider.overrideWithValue(true),
      routeAccessProvider.overrideWith((ref) => ref.watch(_testAccess)),
      screenBuildersProvider.overrideWithValue({
        for (final screen in RemoriScreen.values)
          screen: (context, state) => Center(child: Text(screen.name)),
      }),
      shellLabelsProvider.overrideWithValue({
        RemoriMode.caregiver: RemoriShellLabels(
          destinations: ['Home', 'People', 'Reminders', 'More'],
          action: 'Add reminder',
          direction: TextDirection.ltr,
        ),
        RemoriMode.patient: RemoriShellLabels(
          destinations: ['اليوم', 'التذكيرات', 'يومي', 'الألعاب'],
          action: 'اسأل',
          direction: TextDirection.rtl,
        ),
      }),
    ],
  );
  container.read(_testAccess.notifier).set(access);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RemoriApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String _path(GoRouter router) => router.routeInformationProvider.value.uri.path;

void main() {
  testWidgets('signed-out entry pages stay outside either mode shell', (
    tester,
  ) async {
    final container = await _mount(tester, const RouteAccess());
    final router = container.read(remoriRouterProvider);
    for (final screen in [
      RemoriScreen.a0,
      RemoriScreen.a1,
      RemoriScreen.a2,
      RemoriScreen.a3,
      RemoriScreen.d7,
    ]) {
      router.goNamed(screen.name);
      await tester.pumpAndSettle();
      expect(find.text(screen.name), findsOneWidget);
      expect(find.byType(RemoriNavigationBar), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'caregiver and setup deep links require caregiver authentication',
    (tester) async {
      final container = await _mount(
        tester,
        const RouteAccess(devicePaired: true),
      );
      final router = container.read(remoriRouterProvider);
      for (final screen in [
        RemoriScreen.c1,
        RemoriScreen.c5,
        RemoriScreen.a4,
        RemoriScreen.a5,
        RemoriScreen.a6,
      ]) {
        router.goNamed(screen.name);
        await tester.pumpAndSettle();
        expect(_path(router), RemoriScreen.a2.path);
      }
      container
          .read(_testAccess.notifier)
          .set(const RouteAccess(caregiverAuthenticated: true));
      router.goNamed(RemoriScreen.a4.name);
      await tester.pumpAndSettle();
      expect(find.text('a4'), findsOneWidget);
      expect(find.byType(RemoriNavigationBar), findsNothing);
    },
  );

  testWidgets(
    'patient deep links require a device credential, not a caregiver login',
    (tester) async {
      final container = await _mount(
        tester,
        const RouteAccess(caregiverAuthenticated: true),
      );
      final router = container.read(remoriRouterProvider);
      for (final screen in [
        RemoriScreen.p1,
        RemoriScreen.p3,
        RemoriScreen.p8,
      ]) {
        router.goNamed(screen.name);
        await tester.pumpAndSettle();
        expect(_path(router), RemoriScreen.a2.path);
      }
    },
  );

  testWidgets('caregiver navigation and center action follow exported links', (
    tester,
  ) async {
    final container = await _mount(
      tester,
      const RouteAccess(
        caregiverAuthenticated: true,
        entryMode: RemoriMode.caregiver,
      ),
    );
    final router = container.read(remoriRouterProvider);
    expect(find.text('c1'), findsOneWidget);
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.text('c3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('c9'), findsOneWidget);
    expect(find.byType(RemoriNavigationBar), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('c3'), findsOneWidget);
    expect(find.byType(RemoriNavigationBar), findsOneWidget);
    router.pushNamed(RemoriScreen.c5.name);
    await tester.pumpAndSettle();
    expect(find.byType(RemoriNavigationBar), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('c3'), findsOneWidget);
  });

  testWidgets(
    'patient auto-entry uses RTL and keeps Phase 2 Ask disabled on P1/P2',
    (tester) async {
      await _mount(
        tester,
        const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
      );
      expect(find.text('p1'), findsOneWidget);
      expect(
        tester
            .widget<RemoriNavigationBar>(find.byType(RemoriNavigationBar))
            .onAction,
        isNull,
      );
      final context = tester.element(find.text('p1'));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(
        Theme.of(context).textTheme.bodyMedium!.fontSize,
        greaterThanOrEqualTo(22),
      );
      await tester.tap(find.text('التذكيرات'));
      await tester.pumpAndSettle();
      expect(find.text('p2'), findsOneWidget);
      expect(
        tester
            .widget<RemoriNavigationBar>(find.byType(RemoriNavigationBar))
            .onAction,
        isNull,
      );
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();
      expect(find.text('p2'), findsOneWidget);
      expect(find.text('p6'), findsNothing);
    },
  );

  testWidgets(
    'credential revocation refreshes guards without rebuilding router',
    (tester) async {
      final container = await _mount(
        tester,
        const RouteAccess(
          caregiverAuthenticated: true,
          entryMode: RemoriMode.caregiver,
        ),
      );
      final router = container.read(remoriRouterProvider);
      router.goNamed(RemoriScreen.c3.name);
      await tester.pumpAndSettle();
      container.read(_testAccess.notifier).set(const RouteAccess());
      await tester.pumpAndSettle();
      expect(identical(router, container.read(remoriRouterProvider)), isTrue);
      expect(_path(router), RemoriScreen.a2.path);
      expect(find.byType(RemoriNavigationBar), findsNothing);
      router.go('/does-not-exist');
      await tester.pumpAndSettle();
      expect(_path(router), RemoriScreen.a0.path);
      expect(tester.takeException(), isNull);
    },
  );
}
