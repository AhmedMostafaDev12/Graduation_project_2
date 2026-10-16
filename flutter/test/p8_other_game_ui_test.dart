import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/app.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/router/patient_preview_provider.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/features/mind_games/domain/patient_games_data.dart';
import 'package:remori/features/mind_games/presentation/card_game_providers.dart';
import 'package:remori/features/mind_games/presentation/p7_games_screen.dart';
import 'package:remori/features/mind_games/presentation/p8_practice_screen.dart';
import 'package:remori/features/mind_games/presentation/patient_games_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/patient_reminder_alert_host.dart';

import 'p1_today_test.dart' as p1;
import 'p2_reminders_test.dart' as p2;
import 'p8_gameplay_test.dart' as p8;

class StaticGamesController extends PatientGamesController {
  StaticGamesController() : super(p1.key);
  @override
  PatientGamesState build() => const PatientGamesState();
  @override
  Future<void> refresh() async {}
}

void main() {
  late p8.TestWatch watch;
  int repositoryReads = 0;
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
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String type = 'picture_naming',
    String language = 'en',
    double scale = 1,
    bool menu = false,
    bool preview = false,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    watch = p8.TestWatch();
    repositoryReads = 0;
    final c = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWithValue(Locale(language)),
        patientLocaleProvider.overrideWithValue(Locale(language)),
        patientTodayKeyProvider.overrideWith(
          (ref) => preview ? null : ref.watch(p2.selectedScope),
        ),
        patientAlertCandidateProvider.overrideWithValue(null),
        cardGameStopwatchProvider.overrideWithValue(() => watch),
        cardGameRepositoryProvider.overrideWith((ref, key) {
          repositoryReads++;
          throw StateError('UI activity must not access game data');
        }),
        patientGamesDataProvider(p1.key)
            .overrideWith((ref) => Stream.value(const PatientGamesData())),
        patientGamesControllerProvider(p1.key)
            .overrideWith(StaticGamesController.new),
        routeAccessProvider.overrideWithValue(
          const RouteAccess(devicePaired: true, entryMode: RemoriMode.patient),
        ),
      ],
    );
    if (preview) c.read(patientPreviewProvider.notifier).start();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const RepaintBoundary(
          key: Key('other-game-preview'),
          child: RemoriApp(),
        ),
      ),
    );
    c
        .read(remoriRouterProvider)
        .goNamed(
          menu ? RemoriScreen.p7.name : RemoriScreen.p8.name,
          extra: menu ? null : (scope: p1.key, type: type),
        );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('preview opens every game without a device or repository', (
    tester,
  ) async {
    final c = await mount(tester, menu: true, preview: true);
    for (final title in [
      'Card game',
      'Name the picture',
      'Remember the words',
    ]) {
      await tap(tester, title);
      expect(find.byType(P8PracticeScreen), findsOneWidget);
      if (title == 'Card game') {
        await tester.tap(find.byKey(const ValueKey('preview-card-0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('preview-card-3')));
        await tester.pump();
        expect(find.byIcon(Icons.local_cafe_outlined), findsNWidgets(2));
      }
      await tap(tester, 'Done');
      expect(find.byType(P7GamesScreen), findsOneWidget);
    }
    expect(repositoryReads, 0);
    await unmount(tester, c);
  });
  testWidgets(
    'picture choices give gentle feedback and cycle bundled objects without a session',
    (tester) async {
      final c = await mount(tester);
      expect(find.byType(RemoriNavigationBar), findsNothing);
      expect(find.text('What is in the picture?'), findsOneWidget);
      await tap(tester, 'Key');
      expect(find.text('Take your time. Try another answer.'), findsOneWidget);
      await tap(tester, 'Cup');
      expect(find.text('Well done! Keep going'), findsOneWidget);
      await tap(tester, 'Next picture');
      expect(find.text('Well done! Keep going'), findsNothing);
      await tap(tester, 'Key');
      expect(find.text('Well done! Keep going'), findsOneWidget);
      await tap(tester, 'Done');
      expect(find.byType(P7GamesScreen), findsOneWidget);
      expect(repositoryReads, 0);
      await unmount(tester, c);
    },
  );
  testWidgets(
    'words transition from three study items to four recall choices and back',
    (tester) async {
      final c = await mount(tester, type: 'word_recall');
      expect(find.text('Cup'), findsOneWidget);
      expect(find.text('Key'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Flower'), findsNothing);
      await tap(tester, 'I’m ready');
      expect(find.text('Which word did you see?'), findsOneWidget);
      expect(find.text('Flower'), findsOneWidget);
      await tap(tester, 'Flower');
      expect(find.text('Take your time. Try another answer.'), findsOneWidget);
      await tap(tester, 'Book');
      expect(find.text('Well done! Keep going'), findsOneWidget);
      await tap(tester, 'See the words again');
      expect(find.text('I’m ready'), findsOneWidget);
      expect(repositoryReads, 0);
      await unmount(tester, c);
    },
  );
  for (final entry in [
    ('Name the picture', 'picture_naming'),
    ('Remember the words', 'word_recall'),
  ]) {
    testWidgets('P7 opens ${entry.$1} through the real router', (tester) async {
      final c = await mount(tester, menu: true);
      await tap(tester, entry.$1);
      expect(
        tester
            .widget<P8PracticeScreen>(find.byType(P8PracticeScreen))
            .target
            .type,
        entry.$2,
      );
      expect(repositoryReads, 0);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(P7GamesScreen), findsOneWidget);
      await unmount(tester, c);
    });
  }
  testWidgets('timer pauses in background and scope changes hide choices', (
    tester,
  ) async {
    final c = await mount(tester);
    watch.advance(const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:12'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    watch.advance(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('00:12'), findsOneWidget);
    c.read(p2.selectedScope.notifier).select(p2.otherKey);
    await tester.pumpAndSettle();
    expect(find.text('Cup'), findsNothing);
    expect(watch.isRunning, isFalse);
    expect(repositoryReads, 0);
    await unmount(tester, c);
  });
  for (final type in ['picture_naming', 'word_recall']) {
    for (final lang in ['en', 'ar']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$type $lang at ${scale}x is readable with large actions', (
          tester,
        ) async {
          final c = await mount(
            tester,
            type: type,
            language: lang,
            scale: scale,
          );
          expect(
            Directionality.of(tester.element(find.byType(P8PracticeScreen))),
            lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(tester.takeException(), isNull);
          if (autoUpdateGoldenFiles) {
            await expectLater(
              find.byKey(const Key('other-game-preview')),
              matchesGoldenFile('goldens/p8_${type}_${lang}_${scale}x.png'),
            );
          }
          if (type == 'word_recall') {
            await tap(tester, lang == 'ar' ? 'أنا جاهز' : 'I’m ready');
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, 1800),
            );
            await tester.pumpAndSettle();
            if (autoUpdateGoldenFiles) {
              await expectLater(
                find.byKey(const Key('other-game-preview')),
                matchesGoldenFile(
                  'goldens/p8_word_choices_${lang}_${scale}x.png',
                ),
              );
            }
          }
          await tap(tester, lang == 'ar' ? 'كوب' : 'Cup');
          expect(repositoryReads, 0);
          final done = find.widgetWithText(
            OutlinedButton,
            lang == 'ar' ? 'خلصت' : 'Done',
          );
          await tester.ensureVisible(done);
          expect(tester.getSize(done).height, greaterThanOrEqualTo(64));
          expect(tester.takeException(), isNull);
          await unmount(tester, c);
        });
      }
    }
  }
}
