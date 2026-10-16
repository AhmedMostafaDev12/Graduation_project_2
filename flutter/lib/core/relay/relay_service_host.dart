import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/patient_session_provider.dart';
import '../l10n/locale_providers.dart';
import '../../features/patient_today/presentation/patient_today_providers.dart';
import 'fake_glasses_connection.dart';
import 'glasses_connection_provider.dart';
import 'relay_service.dart';

final relayRestorationProvider = Provider<Future<void>>(
  (ref) => ref.watch(patientSessionProvider.notifier).restoration,
);

class RelayServiceHost extends ConsumerStatefulWidget {
  const RelayServiceHost({
    super.key,
    required this.child,
    required this.onOpenPatient,
  });
  final Widget child;
  final VoidCallback onOpenPatient;
  @override
  ConsumerState<RelayServiceHost> createState() => _RelayServiceHostState();
}

class _RelayServiceHostState extends ConsumerState<RelayServiceHost>
    with WidgetsBindingObserver {
  late RelayService _service;
  late RelayDriver _driver;
  RelayRequest? _last;
  bool _foreground = false,
      _pendingOpen = false,
      _opening = false,
      _consumeAgain = false;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _service = ref.read(relayServiceProvider);
    _driver = RelayDriver(_service);
    _service.onOpen(_consumeOpen);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_consumeOpen);
  }

  Future<void> _consumeOpen() async {
    if (!mounted) return;
    if (_opening) {
      _consumeAgain = true;
      return;
    }
    _opening = true;
    try {
      if (await _service.takeOpenRequest()) {
        await ref.read(relayRestorationProvider);
        if (mounted && ref.read(patientSessionProvider).active) {
          _pendingOpen = true;
        }
      }
    } catch (_) {
      /* Unsupported platform or unavailable session. */
    }
    _opening = false;
    if (mounted) _openIfReady();
    if (mounted && _consumeAgain) {
      _consumeAgain = false;
      Future.microtask(_consumeOpen);
    }
  }

  void _openIfReady() {
    if (_pendingOpen &&
        _foreground &&
        ref.read(patientSessionProvider).active) {
      _pendingOpen = false;
      widget.onOpenPatient();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
    Future.microtask(_sync);
    if (_foreground) {
      _openIfReady();
      unawaited(_consumeOpen());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.onOpen(null);
    unawaited(_driver.close());
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final session = ref.read(patientSessionProvider).context;
    final link = session == null ? null : ref.read(patientLinkProvider);
    final language = session == null
        ? 'ar'
        : ref.read(patientLocaleProvider).languageCode;
    final simulated =
        session != null &&
        !kReleaseMode &&
        ref.read(glassesConnectionProvider) is FakeGlassesConnection;
    final request = (
      scope: session == null ? null : (session.patientId, session.deviceId),
      foreground: _foreground,
      language: language,
      link: link?.value?.connected == true
          ? RelayLink.connected
          : RelayLink.disconnected,
      simulated: simulated,
    );
    if (_last != request) {
      _last = request;
      unawaited(_driver.submit(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(patientSessionProvider).active;
    ref.listen(patientSessionProvider, (_, _) => Future.microtask(_sync));
    if (active) {
      ref.listen(patientLinkProvider, (_, _) => Future.microtask(_sync));
      ref.listen(patientLocaleProvider, (_, _) => Future.microtask(_sync));
      ref.listen(glassesConnectionProvider, (_, _) => Future.microtask(_sync));
    }
    Future.microtask(_sync);
    return widget.child;
  }
}
