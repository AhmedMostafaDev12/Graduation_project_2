import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/main.dart' as entry;
import 'package:remori/features/auth/presentation/a0_splash_screen.dart';

void main() {
  testWidgets('application starts and respects system safe areas', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
    addTearDown(tester.view.resetPadding);

    entry.main();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(tester.getTopLeft(find.byType(A0SplashScreen)).dy, greaterThan(0));
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(Banner), findsNothing);
  });
}
