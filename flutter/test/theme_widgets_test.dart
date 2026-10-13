import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/theme/remori_background.dart';
import 'package:remori/core/theme/remori_navigation_bar.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/core/theme/remori_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final (family, asset) in [
      ('DM Sans', 'DM-Sans.ttf'),
      ('Manrope', 'Manrope.ttf'),
      ('Readex Pro', 'Readex-Pro.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$asset'))).load();
    }
  });

  testWidgets('patient buttons support RTL, large text, and disabled state', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: RemoriTheme.forMode(RemoriMode.patient, arabic: true),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RemoriButton(label: 'خدته', onPressed: () => pressed++),
                      const RemoriButton(
                        label: 'بعدين',
                        onPressed: null,
                        outlined: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(64),
    );
    expect(
      Directionality.of(tester.element(find.text('خدته'))),
      TextDirection.rtl,
    );
    await tester.tap(find.text('خدته'));
    await tester.tap(find.text('بعدين'));
    expect(pressed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RTL navigation maps taps to logical destinations and exposes selection',
    (tester) async {
      final semantics = tester.ensureSemantics();

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? destination;
      var asked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: RemoriTheme.forMode(RemoriMode.patient, arabic: true),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: RemoriNavigationBar(
                    mode: RemoriMode.patient,
                    items: _patientItems,
                    selectedIndex: 0,
                    onSelected: (index) => destination = index,
                    actionLabel: 'اسأل',
                    actionIcon: const Icon(Icons.mic_none),
                    onAction: () => asked = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getCenter(find.text('اليوم')).dx,
        greaterThan(tester.getCenter(find.text('الألعاب')).dx),
      );
      await tester.tap(find.text('التذكيرات'));
      expect(destination, 1);
      await tester.tap(find.bySemanticsLabel('اسأل'));
      expect(asked, isTrue);
      expect(
        tester.getSemantics(find.text('اليوم')),
        matchesSemantics(
          label: 'اليوم',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('labeled input reports edits and localized validation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    var edited = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: RemoriTheme.forMode(RemoriMode.caregiver),
        home: Scaffold(
          body: RemoriInput(
            label: 'Email',
            errorText: 'Invalid email',
            onChanged: (value) => edited = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'test@example.com');
    expect(edited, 'test@example.com');
    expect(find.text('Invalid email'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Email')), findsWidgets);
    semantics.dispose();
  });

  for (final mode in RemoriMode.values) {
    testWidgets('${mode.name} shared components visual preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final patient = mode == RemoriMode.patient;
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: RemoriTheme.forMode(mode, arabic: patient),
          home: Directionality(
            textDirection: patient ? TextDirection.rtl : TextDirection.ltr,
            child: RepaintBoundary(
              key: const Key('preview'),
              child: Scaffold(
                body: RemoriBackground(
                  kind: patient
                      ? RemoriBackgroundKind.wave
                      : RemoriBackgroundKind.onboarding,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: RemoriLogo(
                                  semanticLabel: 'Remori',
                                  width: 100,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                patient
                                    ? 'تذكيرات النهارده'
                                    : 'Shared components',
                                style: RemoriTheme.forMode(
                                  mode,
                                  arabic: patient,
                                ).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              RemoriCard(
                                mode: mode,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      patient ? 'دواء الضغط' : 'Remori glasses',
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        RemoriChip(
                                          label: patient
                                              ? 'متوصلة'
                                              : 'Connected',
                                          kind: RemoriChipKind.success,
                                          mode: mode,
                                        ),
                                        RemoriChip(
                                          label: patient ? 'لسه' : 'Pending',
                                          mode: mode,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              RemoriButton(
                                label: patient ? 'خدته' : 'Continue',
                                onPressed: () {},
                              ),
                              const SizedBox(height: 14),
                              RemoriButton(
                                label: patient ? 'بعدين' : 'Add photos',
                                outlined: true,
                                onPressed: () {},
                              ),
                              if (!patient) ...[
                                const SizedBox(height: 20),
                                const RemoriInput(
                                  label: 'Email',
                                  hint: 'Enter your email',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      RemoriNavigationBar(
                        mode: mode,
                        items: patient ? _patientItems : _caregiverItems,
                        selectedIndex: 0,
                        onSelected: (_) {},
                        actionLabel: patient ? 'اسأل' : 'Add reminder',
                        actionIcon: Icon(patient ? Icons.mic_none : Icons.add),
                        onAction: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Export review images on demand; raster output differs across host platforms.
      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byKey(const Key('preview')),
          matchesGoldenFile('goldens/${mode.name}_components.png'),
        );
      }
      debugDisableShadows = previousShadows;
    });
  }
}

const _patientItems = [
  RemoriNavigationItem(label: 'اليوم', icon: Icon(Icons.wb_sunny_outlined)),
  RemoriNavigationItem(
    label: 'التذكيرات',
    icon: Icon(Icons.notifications_none),
  ),
  RemoriNavigationItem(label: 'يومي', icon: Icon(Icons.book_outlined)),
  RemoriNavigationItem(
    label: 'الألعاب',
    icon: Icon(Icons.sports_esports_outlined),
  ),
];
const _caregiverItems = [
  RemoriNavigationItem(label: 'Home', icon: Icon(Icons.home_outlined)),
  RemoriNavigationItem(label: 'People', icon: Icon(Icons.people_outline)),
  RemoriNavigationItem(
    label: 'Reminders',
    icon: Icon(Icons.notifications_none),
  ),
  RemoriNavigationItem(label: 'More', icon: Icon(Icons.more_horiz)),
];
