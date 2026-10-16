import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remori/core/router/remori_router.dart';
import 'package:remori/core/router/remori_routes.dart';
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/relay/reminder_notification_host.dart';
import 'package:remori/features/patient_today/domain/patient_today_data.dart';
import 'package:remori/features/patient_today/data/patient_today_repository.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

class IdleController extends PatientTodayController {
  IdleController(super.key);
  @override
  PatientTodayState build() => const PatientTodayState();
  final saved = Completer<bool>();
  final actions = <bool>[];
  @override
  Future<bool> confirmAlert(
    PatientReminderAlertTarget target, {
    required bool snooze,
  }) {
    actions.add(snooze);
    return saved.future;
  }
}

class ReadRepository implements PatientTodayRepository {
  ReadRepository(this.data);
  PatientTodayData data;
  @override
  Future<PatientTodayData> read() async => data;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('remori/reminders');
  const key = ('patient', 'device');
  final due = DateTime.utc(2026, 10, 16, 10);
  final target = (scope: key, id: 'occurrence', dueAt: due);
  setUpAll(tz.initializeTimeZones);
  test('receipts reject forged, old device and old snooze-time intents', () {
    final receipt = ReminderReceipt();
    final first = receipt.select(target);
    expect(receipt.select(target), first);
    expect(receipt.resolve('forged'), isNull);
    expect(receipt.resolve(first), target);
    receipt.select((
      scope: key,
      id: target.id,
      dueAt: due.add(const Duration(minutes: 15)),
    ));
    expect(receipt.resolve(first), isNull);
    final second = receipt.token;
    receipt.select((
      scope: ('patient', 'other-device'),
      id: target.id,
      dueAt: due,
    ));
    expect(receipt.resolve(second), isNull);
    final third = receipt.token;
    receipt.select(null);
    expect(receipt.resolve(third), isNull);
    expect(receipt.resolve(null), isNull);
  });

  testWidgets(
    'only cached next occurrence crosses Android boundary; logout clears it',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      final overrides = [
        permissionPlatformProvider.overrideWithValue(
          PermissionPlatform.android,
        ),
        patientTodayKeyProvider.overrideWithValue(key),
        patientTodayDataProvider(key).overrideWith(
          (ref) => Stream.value(
            PatientTodayData(
              settings: const PatientSettings(
                'Private name',
                'en',
                'Africa/Cairo',
                true,
              ),
              next: PatientReminder('occurrence', 'Actual reminder', due),
            ),
          ),
        ),
        patientTodayControllerProvider(key)
            .overrideWith(() => IdleController(key)),
      ];
      final container = ProviderContainer(overrides: overrides);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ReminderNotificationHost(child: SizedBox()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(
        container.read(patientTodayDataProvider(key)).value?.next?.id,
        'occurrence',
      );
      final payload =
          calls
                  .lastWhere((c) => c.method == 'update' && c.arguments != null)
                  .arguments
              as Map;
      expect(payload.keys.toSet(), {
        'token',
        'due',
        'title',
        'time',
        'language',
      });
      expect(payload['title'], 'Actual reminder');
      expect(payload['due'], due.millisecondsSinceEpoch);
      expect((payload['time'] as String).replaceAll('\u202f', ' '), '1:00 PM');
      expect(payload.toString(), isNot(contains('Private name')));
      overrides[1] = patientTodayKeyProvider.overrideWithValue(null);
      container.updateOverrides(overrides);
      await tester.pump();
      await tester.pump();
      expect(calls.last.arguments, isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );

  testWidgets('iOS does not invoke Android reminder channel', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionPlatformProvider.overrideWithValue(PermissionPlatform.ios),
          patientTodayKeyProvider.overrideWithValue(null),
        ],
        child: const ReminderNotificationHost(child: SizedBox()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  for (final action in [
    'open',
    'taken',
    'later',
    'failure',
    'stale',
    'forged',
  ]) {
    testWidgets(
      '$action notification validates target and waits for local save',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        Map? tap;
        String? token;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'take') {
              final result = tap;
              tap = null;
              return result;
            }
            if (call.arguments is Map) {
              token = (call.arguments as Map)['token'] as String?;
            }
            return true;
          },
        );
        final data = PatientTodayData(
          settings: const PatientSettings(
            'Patient',
            'en',
            'Africa/Cairo',
            true,
          ),
          next: PatientReminder('occurrence', 'Reminder', due),
        );
        final repo = ReadRepository(data);
        final controller = IdleController(key);
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const SizedBox()),
            for (final screen in [RemoriScreen.p2, RemoriScreen.p3])
              GoRoute(
                path: screen.path,
                name: screen.name,
                builder: (_, _) => const SizedBox(),
              ),
          ],
        );
        final container = ProviderContainer(
          overrides: [
            permissionPlatformProvider.overrideWithValue(
              PermissionPlatform.android,
            ),
            patientTodayKeyProvider.overrideWithValue(key),
            patientTodayClockProvider.overrideWithValue(() => due),
            patientTodayDataProvider(key)
                .overrideWith((ref) => Stream.value(data)),
            patientTodayRepositoryProvider(key).overrideWithValue(repo),
            patientTodayControllerProvider(key).overrideWith(() => controller),
            remoriRouterProvider.overrideWithValue(router),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ReminderNotificationHost(child: SizedBox()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(token, isNotNull);
        if (action == 'stale') repo.data = const PatientTodayData();
        tap = {
          'token': action == 'forged' ? 'forged' : token,
          'action': action == 'failure' ? 'taken' : action,
        };
        // A resume consumes the native request without exposing a public deep link.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();
        if (['taken', 'later', 'failure'].contains(action)) {
          expect(controller.actions, [action == 'later']);
          expect(router.routeInformationProvider.value.uri.path, '/');
          controller.saved.complete(action != 'failure');
          await tester.pump();
          await tester.pump();
        } else {
          expect(controller.actions, isEmpty);
        }
        expect(
          router.routeInformationProvider.value.uri.path,
          ['taken', 'later'].contains(action)
              ? RemoriScreen.p2.path
              : ['open', 'failure'].contains(action)
              ? RemoriScreen.p3.path
              : '/',
        );
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        router.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      },
    );
  }
}
