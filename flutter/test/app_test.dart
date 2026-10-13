import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/main.dart' as entry;
import 'package:remori/core/router/remori_routes.dart';

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
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(RemoriScreen.a0))).dy,
      greaterThan(0),
    );
    expect(find.byType(Text), findsNothing);
    expect(find.byType(Banner), findsNothing);
  });
}
