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
import 'package:remori/core/router/patient_preview_provider.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/caregiver_dashboard/presentation/home_providers.dart';
import 'package:remori/features/caregiver_dashboard/domain/home_data.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';

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
  bool preview = false,
  bool bothModes = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      appLocaleProvider.overrideWith(
        (ref) =>
            ref.watch(appLanguageSelectionProvider) ?? ref.watch(_testLocale),
      ),
      routeAccessProvider.overrideWithValue(
        RouteAccess(
          caregiverAuthenticated: mode == RemoriMode.caregiver,
          devicePaired: bothModes || mode == RemoriMode.patient,
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
  if (preview) container.read(patientPreviewProvider.notifier).start();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RemoriApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('shared locale restores from the existing cached profile', () {
    ProviderContainer restore() => ProviderContainer(
      overrides: [
        patientTodayKeyProvider.overrideWithValue(null),
        selectedHomePatientProvider.overrideWithValue(
          const HomePatient(
            id: 'patient',
            name: 'Test',
            language: 'en',
            timezone: 'UTC',
            memoryEnabled: true,
            permission: 'manager',
          ),
        ),
      ],
    );
    final first = restore();
    expect(first.read(appLocaleProvider), const Locale('en'));
    expect(first.read(patientLocaleProvider), const Locale('en'));
    first.read(appLanguageSelectionProvider.notifier).select('ar');
    expect(first.read(appLocaleProvider), const Locale('ar'));
    expect(first.read(patientLocaleProvider), const Locale('ar'));
    first.dispose();
    final restarted = restore();
    expect(restarted.read(appLocaleProvider), const Locale('en'));
    restarted.dispose();
  });

  testWidgets('shared selection changes both real mode shells immediately', (
    tester,
  ) async {
    final container = await mount(
      tester,
      mode: RemoriMode.caregiver,
      bothModes: true,
    );
    final router = container.read(remoriRouterProvider);
    container.read(appLanguageSelectionProvider.notifier).select('en');
    router.goNamed(RemoriScreen.p1.name);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    container.read(appLanguageSelectionProvider.notifier).select('ar');
    await tester.pumpAndSettle();
    expect(find.text('اليوم'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('p1'))),
      TextDirection.rtl,
    );
    router.goNamed(RemoriScreen.c3.name);
    await tester.pumpAndSettle();
    expect(find.text('الأشخاص'), findsOneWidget);
    container.read(appLanguageSelectionProvider.notifier).select('en');
    await tester.pumpAndSettle();
    expect(find.text('People'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('c3'))),
      TextDirection.ltr,
    );
  });

  testWidgets('patient preview follows app language and direction changes', (
    tester,
  ) async {
    final container = await mount(
      tester,
      mode: RemoriMode.patient,
      preview: true,
    );
    expect(find.text('Screen preview · Exit preview'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('p1'))),
      TextDirection.ltr,
    );
    container.read(_testLocale.notifier).set(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('معاينة الشاشات · إنهاء المعاينة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('p1'))),
      TextDirection.rtl,
    );
    container.read(_testLocale.notifier).set(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Screen preview · Exit preview'), findsOneWidget);
  });

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

  testWidgets('Patient Mode uses the shared Arabic app locale', (tester) async {
    await mount(
      tester,
      mode: RemoriMode.patient,
      appLocale: const Locale('ar'),
    );
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

  testWidgets(
    'shared English language retains large patient typography with LTR',
    (tester) async {
      await mount(
        tester,
        mode: RemoriMode.patient,
        appLocale: const Locale('en'),
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
    },
  );

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
