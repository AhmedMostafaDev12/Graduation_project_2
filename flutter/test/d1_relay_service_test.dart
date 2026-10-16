import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/patient_session_provider.dart';
import 'package:remori/core/api/patient_session_store.dart';
import 'package:remori/core/l10n/locale_providers.dart';
import 'package:remori/core/relay/relay_service.dart';
import 'package:remori/core/relay/relay_service_host.dart';
import 'package:remori/core/relay/permission_service.dart';
import 'package:remori/core/relay/fake_glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/features/patient_today/presentation/patient_today_providers.dart';

import 'a6_handover_test.dart' as auth;

class FakeService implements RelayService {
  final applied = <Map<String, Object>>[];
  final events = <String>[];
  int stops = 0;
  bool open = false, allowed = true, fail = false;
  Completer<void>? gate;
  void Function()? callback;
  @override
  Future<bool> apply({
    required bool mayStart,
    required String language,
    required RelayLink link,
    required bool simulated,
  }) async {
    applied.add({
      'mayStart': mayStart,
      'language': language,
      'link': link.name,
      'simulated': simulated,
    });
    events.add('apply');
    if (gate != null) await gate!.future;
    if (fail) throw PlatformException(code: 'UNAVAILABLE');
    return allowed;
  }

  @override
  Future<void> stop() async {
    stops++;
    events.add('stop');
  }

  @override
  Future<bool> takeOpenRequest() async {
    final value = open;
    open = false;
    return value;
  }

  @override
  void onOpen(void Function()? value) {
    callback = value;
  }

  @override
  void dispose() {
    callback = null;
  }

  void tap() {
    open = true;
    callback?.call();
  }
}

class Session extends PatientSession {
  @override
  PatientSessionState build() {
    restoration = Future.value();
    return const PatientSessionState();
  }

  void put(PatientDeviceContext? context) =>
      state = PatientSessionState(context: context);
}

final linkProvider = NotifierProvider<Link, bool>(Link.new);

class Link extends Notifier<bool> {
  @override
  bool build() => false;
  void put(bool value) => state = value;
}

final languageProvider = NotifierProvider<Language, String>(Language.new);

class Language extends Notifier<String> {
  @override
  String build() => 'en';
  void put(String value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  RelayRequest request({bool active = true, bool foreground = true}) => (
    scope: active ? (auth.patient, auth.device) : null,
    foreground: foreground,
    language: 'en',
    link: RelayLink.connected,
    simulated: true,
  );
  test(
    'serialized logout stops after an in-flight start and skips stale updates',
    () async {
      final service = FakeService()..gate = Completer<void>();
      final driver = RelayDriver(service);
      final first = driver.submit(request());
      await Future<void>.delayed(Duration.zero);
      final old = driver.submit(request(foreground: false));
      final stop = driver.submit(request(active: false));
      service.gate!.complete();
      await Future.wait([first, old, stop]);
      expect(service.events, ['stop', 'apply', 'stop']);
      await driver.close();
    },
  );
  test('scope replacement stops old service before a new apply', () async {
    final service = FakeService();
    final driver = RelayDriver(service);
    await driver.submit(request());
    await driver.submit((
      scope: ('other', auth.device),
      foreground: true,
      language: 'ar',
      link: RelayLink.disconnected,
      simulated: false,
    ));
    expect(service.events, ['stop', 'apply', 'stop', 'apply']);
    await driver.close();
  });
  test('disposal wins over pending start and never restarts later', () async {
    final service = FakeService()..gate = Completer<void>();
    final driver = RelayDriver(service);
    final pending = driver.submit(request());
    await Future<void>.delayed(Duration.zero);
    final close = driver.close();
    service.gate!.complete();
    await Future.wait([pending, close]);
    expect(service.events.last, 'stop');
    final count = service.applied.length;
    await driver.submit(request());
    expect(service.applied.length, count);
  });
  test(
    'native denial and failures do not escape and allow foreground retry',
    () async {
      final service = FakeService()..fail = true;
      final driver = RelayDriver(service);
      await driver.submit(request());
      service.fail = false;
      service.allowed = false;
      await driver.submit(request(foreground: false));
      service.allowed = true;
      await driver.submit(request());
      expect(service.applied.length, 3);
      await driver.close();
    },
  );
  test(
    'platform payload contains only allowlisted non-personal state',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(AndroidRelayService.channel, (
        call,
      ) async {
        calls.add(call);
        return call.method == 'stop' ? null : true;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidRelayService.channel,
          null,
        ),
      );
      final service = AndroidRelayService();
      expect(
        await service.apply(
          mayStart: false,
          language: 'fr',
          link: RelayLink.disconnected,
          simulated: true,
        ),
        isTrue,
      );
      expect(calls.single.arguments, {
        'mayStart': false,
        'language': 'ar',
        'link': 'disconnected',
        'simulated': true,
      });
      expect(await service.takeOpenRequest(), isTrue);
      await service.stop();
      service.dispose();
    },
  );
  test('unsupported platform never calls Android channel', () async {
    final c = ProviderContainer(
      overrides: [
        permissionPlatformProvider.overrideWithValue(PermissionPlatform.ios),
      ],
    );
    addTearDown(c.dispose);
    final service = c.read(relayServiceProvider);
    expect(service, isA<UnsupportedRelayService>());
    expect(
      await service.apply(
        mayStart: true,
        language: 'en',
        link: RelayLink.connected,
        simulated: false,
      ),
      isFalse,
    );
  });
  late FakeService service;
  late int opens;
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    bool active = true,
    bool foreground = true,
    bool coldOpen = false,
    Completer<void>? restoration,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(
      foreground ? AppLifecycleState.resumed : AppLifecycleState.paused,
    );
    service = FakeService()..open = coldOpen;
    opens = 0;
    final c = ProviderContainer(
      overrides: [
        relayServiceProvider.overrideWithValue(service),
        patientSessionProvider.overrideWith(Session.new),
        relayRestorationProvider.overrideWithValue(
          restoration?.future ?? Future.value(),
        ),
        patientLocaleProvider.overrideWith(
          (ref) => Locale(ref.watch(languageProvider)),
        ),
        patientLinkProvider.overrideWith(
          (ref) => Stream.value(
            PatientLinkStatus(connected: ref.watch(linkProvider)),
          ),
        ),
        glassesConnectionProvider.overrideWith((ref) {
          final fake = FakeGlassesConnection();
          ref.onDispose(fake.dispose);
          return fake;
        }),
      ],
    );
    addTearDown(c.dispose);
    if (active) {
      (c.read(patientSessionProvider.notifier) as Session).put(
        auth.contextFixture,
      );
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: RelayServiceHost(
          onOpenPatient: () => opens++,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('App'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    c.dispose();
  }

  testWidgets(
    'active foreground patient starts and updates actual link/language without personal data',
    (tester) async {
      final c = await mount(tester);
      expect(service.applied.last['mayStart'], true);
      expect(service.applied.last['simulated'], true);
      c.read(linkProvider.notifier).put(true);
      c.read(languageProvider.notifier).put('ar');
      await tester.pumpAndSettle();
      expect(service.applied.last['link'], 'connected');
      expect(service.applied.last['language'], 'ar');
      expect(
        service.applied.last.keys,
        unorderedEquals(['mayStart', 'language', 'link', 'simulated']),
      );
      await unmount(tester, c);
    },
  );
  testWidgets('no patient session stops service without starting one', (
    tester,
  ) async {
    final c = await mount(tester, active: false);
    expect(service.applied, isEmpty);
    expect(service.stops, greaterThan(0));
    await unmount(tester, c);
  });
  testWidgets('background restoration cannot start a new service; resume can', (
    tester,
  ) async {
    final c = await mount(tester, foreground: false);
    expect(service.applied, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(service.applied.last['mayStart'], true);
    await unmount(tester, c);
  });
  testWidgets('logout stops the service and clears tap authorization', (
    tester,
  ) async {
    final c = await mount(tester);
    final stops = service.stops;
    (c.read(patientSessionProvider.notifier) as Session).put(null);
    await tester.pumpAndSettle();
    expect(service.stops, greaterThan(stops));
    service.tap();
    await tester.pumpAndSettle();
    expect(opens, 0);
    await unmount(tester, c);
  });
  testWidgets(
    'warm notification tap opens only the active patient destination',
    (tester) async {
      final c = await mount(tester);
      service.tap();
      await tester.pumpAndSettle();
      expect(opens, 1);
      await unmount(tester, c);
    },
  );
  testWidgets('cold notification tap waits for secure restoration', (
    tester,
  ) async {
    final restoration = Completer<void>();
    final c = await mount(tester, coldOpen: true, restoration: restoration);
    expect(opens, 0);
    restoration.complete();
    await tester.pumpAndSettle();
    expect(opens, 1);
    await unmount(tester, c);
  });
  testWidgets('tap received while backgrounded opens after resume', (
    tester,
  ) async {
    final c = await mount(tester, foreground: false);
    service.tap();
    await tester.pumpAndSettle();
    expect(opens, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(opens, 1);
    await unmount(tester, c);
  });
  testWidgets('logout while backgrounded stops without waiting for a repaint', (
    tester,
  ) async {
    final c = await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    final stops = service.stops;
    (c.read(patientSessionProvider.notifier) as Session).put(null);
    await tester.pumpAndSettle();
    expect(service.stops, greaterThan(stops));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await unmount(tester, c);
  });
  testWidgets('session loss while restoring cannot open patient mode', (
    tester,
  ) async {
    final restoration = Completer<void>();
    final c = await mount(tester, coldOpen: true, restoration: restoration);
    (c.read(patientSessionProvider.notifier) as Session).put(null);
    restoration.complete();
    await tester.pumpAndSettle();
    expect(opens, 0);
    await unmount(tester, c);
  });
}
