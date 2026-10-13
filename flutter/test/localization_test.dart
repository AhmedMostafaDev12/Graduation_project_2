import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/app_localizations.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/theme/remori_theme.dart';

final _testLocale = NotifierProvider<_Locale, Locale?>(_Locale.new);

class _Locale extends Notifier<Locale?> {
  @override
  Locale? build() => null;
  void set(Locale? locale) => state = locale;
}

Future<ProviderContainer> mount(
  WidgetTester tester, {
  required RemoriMode mode,
  Locale appLocale = const Locale('en'),
  Locale patientLocale = const Locale('ar'),
}) async {
  final container = ProviderContainer(
    overrides: [
      appLocaleProvider.overrideWith((ref) => ref.watch(_testLocale)),
      patientLocaleProvider.overrideWithValue(patientLocale),
      routeAccessProvider.overrideWithValue(
        RouteAccess(
          caregiverAuthenticated: mode == RemoriMode.caregiver,
          devicePaired: mode == RemoriMode.patient,
          entryMode: mode,
        ),
      ),
      screenBuildersProvider.overrideWithValue({
        for (final screen in RemoriScreen.values)
          screen: (context, state) => Text(screen.name),
      }),
    ],
  );
  container.read(_testLocale.notifier).set(appLocale);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RemoriApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('Arabic and English resources have complete matching keys', () {
    final english =
        jsonDecode(File('lib/core/l10n/app_en.arb').readAsStringSync()) as Map;
    final arabic =
        jsonDecode(File('lib/core/l10n/app_ar.arb').readAsStringSync()) as Map;
    Set<String> keys(Map map) =>
        map.keys.cast<String>().where((key) => !key.startsWith('@')).toSet();
    expect(keys(arabic), keys(english));
    for (final key in keys(arabic)) {
      expect(arabic[key], isA<String>());
      expect((arabic[key] as String).trim(), isNotEmpty);
    }
  });

  testWidgets('English caregiver shell uses localized labels and LTR', (
    tester,
  ) async {
    await mount(tester, mode: RemoriMode.caregiver);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    final context = tester.element(find.text('c1'));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'DM Sans');
    expect(AppLocalizations.of(context).addReminder, 'Add reminder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic caregiver shell switches text, RTL and fonts together', (
    tester,
  ) async {
    await mount(
      tester,
      mode: RemoriMode.caregiver,
      appLocale: const Locale('ar'),
    );
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الأشخاص'), findsOneWidget);
    final context = tester.element(find.text('c1'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'Readex Pro');
    expect(
      tester.getCenter(find.text('الرئيسية')).dx,
      greaterThan(tester.getCenter(find.text('المزيد')).dx),
    );
  });

  testWidgets('Patient Mode defaults to Arabic despite an English app locale', (
    tester,
  ) async {
    await mount(tester, mode: RemoriMode.patient);
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('التذكيرات'), findsOneWidget);
    final context = tester.element(find.text('p1'));
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(Directionality.of(context), TextDirection.rtl);
    expect(
      Theme.of(context).textTheme.bodyMedium!.fontSize,
      greaterThanOrEqualTo(22),
    );
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('اسأل'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('English patient preference retains large typography with LTR', (
    tester,
  ) async {
    await mount(
      tester,
      mode: RemoriMode.patient,
      patientLocale: const Locale('en'),
    );
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('My Day'), findsOneWidget);
    final context = tester.element(find.text('p1'));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'DM Sans');
    expect(
      Theme.of(context).textTheme.bodyMedium!.fontSize,
      greaterThanOrEqualTo(22),
    );
  });

  testWidgets(
    'changing app locale retains the router and current destination',
    (tester) async {
      final container = await mount(tester, mode: RemoriMode.caregiver);
      final router = container.read(remoriRouterProvider);
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();
      container.read(_testLocale.notifier).set(const Locale('ar'));
      await tester.pumpAndSettle();
      expect(identical(router, container.read(remoriRouterProvider)), isTrue);
      expect(find.text('c3'), findsOneWidget);
      expect(find.text('الأشخاص'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsupported app locale falls back to English', (tester) async {
    await mount(
      tester,
      mode: RemoriMode.caregiver,
      appLocale: const Locale('ja'),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.text('c1'))).languageCode,
      'en',
    );
  });
}
