import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/patient_session_provider.dart';
import 'package:remori/core/api/patient_session_store.dart';
import 'package:remori/core/relay/glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/core/relay/glasses_message.dart';
import 'package:remori/core/l10n/app_localizations.dart';
import 'package:remori/core/theme/remori_theme.dart';
import 'package:remori/core/theme/remori_widgets.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:remori/features/patient_today/presentation/p1_today_screen.dart';

import 'a6_handover_test.dart' as auth;

class Session extends PatientSession {
  @override
  PatientSessionState build() =>
      const PatientSessionState(context: auth.contextFixture);
  void put(PatientDeviceContext? value) =>
      state = PatientSessionState(context: value);
}

class Glasses extends auth.ControlledGlasses {
  int connects = 0;
  String? helloSerial = auth.serial;
  bool throws = false;
  Completer<void>? gate;
  @override
  Future<void> connect(String serial) async {
    connects++;
    connectedSerial = serial;
    if (throws) throw UnimplementedError();
    await gate?.future;
    change(GlassesConnectionState.connected);
    if (helloSerial != null) {
      incoming.add(
        Hello(
          deviceSerial: helloSerial!,
          firmwareVersion: '1',
          protocolVersion: 1,
          queue: const GlassesQueue(events: 0, audioSegments: 0, media: 0),
        ),
      );
    }
  }
}

class QuietToday extends PatientTodayController {
  QuietToday(super.key);
  @override
  PatientTodayState build() => const PatientTodayState();
}

void main() {
  late Glasses glasses;
  late ProviderContainer container;
  void prepare() {
    glasses = Glasses();
    container = ProviderContainer(
      overrides: [
        patientSessionProvider.overrideWith(Session.new),
        glassesConnectionProvider.overrideWithValue(glasses),
        patientTodayDataProvider((auth.patient, auth.device)).overrideWith(
          (ref) => Stream.value(
            PatientTodayData(
              settings: const PatientSettings(
                'Patient',
                'en',
                'Africa/Cairo',
                true,
              ),
              next: PatientReminder(
                'occurrence',
                'Cached reminder',
                DateTime.utc(2026, 10, 16, 12),
              ),
            ),
          ),
        ),
        patientTodayControllerProvider((auth.patient, auth.device))
            .overrideWith(() => QuietToday((auth.patient, auth.device))),
        patientTodayNowProvider.overrideWith(
          (ref) => Stream.value(DateTime.utc(2026, 10, 16, 11)),
        ),
      ],
    );
    container.listen(patientReconnectProvider, (_, _) {});
    container.listen(patientLinkProvider, (_, _) {});
  }

  void check(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      prepare();
      try {
        await body(tester);
      } finally {
        container.dispose();
        glasses.dispose();
        await tester.pump();
      }
    });
  }

  check('matching identity reconnects and sends clock sync', (tester) async {
    await tester.pump();
    final pending = container.read(patientReconnectProvider.notifier).retry();
    await tester.pump();
    await pending;
    expect(glasses.connectedSerial, auth.serial);
    expect(glasses.sent.whereType<TimeSync>(), hasLength(1));
    expect(container.read(patientLinkProvider).value?.connected, true);
    expect(container.read(patientReconnectProvider).busy, false);
  });
  check('wrong identity cannot show Connected or receive clock sync', (
    tester,
  ) async {
    glasses.helloSerial = 'OTHER';
    final pending = container.read(patientReconnectProvider.notifier).retry();
    await tester.pump();
    await pending;
    expect(glasses.sent, isEmpty);
    expect(container.read(patientLinkProvider).value?.connected, false);
    expect(container.read(patientReconnectProvider).offline, true);
  });
  check('connected transport without hello times out safely', (tester) async {
    glasses.helloSerial = null;
    final pending = container.read(patientReconnectProvider.notifier).retry();
    await tester.pump();
    expect(container.read(patientLinkProvider).value?.connected, false);
    await tester.pump(const Duration(seconds: 11));
    await pending;
    expect(container.read(patientReconnectProvider).offline, true);
    expect(glasses.sent, isEmpty);
  });
  check('unimplemented BLE leaves a gentle retry state', (tester) async {
    glasses.throws = true;
    await container.read(patientReconnectProvider.notifier).retry();
    expect(container.read(patientReconnectProvider).offline, true);
    expect(container.read(patientReconnectProvider).busy, false);
    expect(glasses.sent, isEmpty);
  });
  check('repeated taps do not start concurrent connections', (tester) async {
    glasses.gate = Completer<void>();
    final notifier = container.read(patientReconnectProvider.notifier);
    final pending = notifier.retry();
    await notifier.retry();
    expect(glasses.connects, 1);
    glasses.gate!.complete();
    await tester.pump();
    await pending;
  });
  check('session loss ignores a late connection and prevents clock sync', (
    tester,
  ) async {
    glasses.gate = Completer<void>();
    final pending = container.read(patientReconnectProvider.notifier).retry();
    (container.read(patientSessionProvider.notifier) as Session).put(null);
    await tester.pump();
    glasses.gate!.complete();
    await tester.pump();
    await pending;
    expect(glasses.sent, isEmpty);
    expect(container.read(patientLinkProvider).value?.connected, isNot(true));
    expect(container.read(patientReconnectProvider).busy, false);
  });
  check(
    'D5 retry disables during connection, recovers, and shows gentle failure',
    (tester) async {
      glasses.gate = Completer<void>();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: RemoriTheme.forMode(RemoriMode.patient),
            home: const Scaffold(body: P1TodayScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('d5-disconnected')), findsOneWidget);
      expect(find.textContaining('Cached reminder'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      final retry = find.ancestor(
        of: find.text('Try again'),
        matching: find.byType(RemoriButton),
      );
      expect(tester.widget<RemoriButton>(retry).onPressed, isNull);
      glasses.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('d5-disconnected')), findsNothing);
      expect(find.text('Glasses connected'), findsOneWidget);
      glasses.change(GlassesConnectionState.disconnected);
      glasses.throws = true;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.text('We couldn’t connect yet. You can try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('Cached reminder'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
