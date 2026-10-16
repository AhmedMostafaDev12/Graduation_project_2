import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/patient_today/presentation/p6_ask_screen.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'P6 $language opens from every patient tab and returns with Back',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final defaults = ProviderContainer();
        final builders = defaults.read(screenBuildersProvider);
        defaults.dispose();
        final container = ProviderContainer(
          overrides: [
            appLocaleProvider.overrideWithValue(Locale(language)),
            routeAccessProvider.overrideWithValue(
              const RouteAccess(
                devicePaired: true,
                entryMode: RemoriMode.patient,
              ),
            ),
            screenBuildersProvider.overrideWithValue({
              ...builders,
              for (final screen in [
                RemoriScreen.p1,
                RemoriScreen.p2,
                RemoriScreen.p4,
                RemoriScreen.p7,
              ])
                screen: (_, _) => Text(screen.name),
            }),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RemoriApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = container.read(remoriRouterProvider);
        for (final screen in [
          RemoriScreen.p1,
          RemoriScreen.p2,
          RemoriScreen.p4,
          RemoriScreen.p7,
        ]) {
          router.goNamed(screen.name);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.mic_none));
          await tester.pumpAndSettle();
          expect(find.byType(P6AskScreen), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).enabled,
            false,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(TextButton));
          await tester.pumpAndSettle();
          expect(find.text(screen.name), findsOneWidget);
          expect(router.canPop(), false);
          await tester.tap(find.byIcon(Icons.mic_none));
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text(screen.name), findsOneWidget);
        }
      },
    );
  }
}
