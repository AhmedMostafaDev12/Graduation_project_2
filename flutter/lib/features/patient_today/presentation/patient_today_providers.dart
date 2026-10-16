import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/patient_session_provider.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/relay/glasses_connection.dart';
import '../../../core/relay/glasses_connection_provider.dart';
import '../../../core/relay/glasses_message.dart';
import '../../device_pairing/presentation/handover_providers.dart';
import '../data/patient_today_repository.dart';
import '../domain/patient_today_data.dart';

final patientTodayKeyProvider = Provider<PatientTodayKey?>((ref) {
  final context = ref.watch(patientSessionProvider).context;
  return context == null ? null : (context.patientId, context.deviceId);
});
final patientTodayClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final patientTodayNowProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  final clock = ref.watch(patientTodayClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});
final patientTodayRepositoryProvider = Provider.autoDispose
    .family<PatientTodayRepository, PatientTodayKey>((ref, key) {
      final repo = PatientTodayRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(patientTodayClockProvider),
        current: () => ref.mounted && ref.read(patientTodayKeyProvider) == key,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final patientTodayDataProvider = StreamProvider.autoDispose
    .family<PatientTodayData, PatientTodayKey>((ref, key) {
      ref.watch(patientTodayNowProvider);
      return ref.watch(patientTodayRepositoryProvider(key)).watch();
    });

class PatientTodayState {
  const PatientTodayState({this.busy = false, this.offline = false});
  final bool busy, offline;
}

final patientTodayControllerProvider = NotifierProvider.autoDispose
    .family<PatientTodayController, PatientTodayState, PatientTodayKey>(
      PatientTodayController.new,
    );

class PatientTodayController extends Notifier<PatientTodayState> {
  PatientTodayController(this.key);
  final PatientTodayKey key;
  bool get _current => ref.mounted && ref.read(patientTodayKeyProvider) == key;
  @override
  PatientTodayState build() {
    try {
      ref.watch(patientTodayRepositoryProvider(key));
    } catch (_) {
      /* Soft unavailable state. */
    }
    Future.microtask(() {
      if (_current) refresh();
    });
    return const PatientTodayState();
  }

  Future<void> refresh() async {
    if (!_current || state.busy) return;
    state = const PatientTodayState(busy: true);
    var offline = false;
    try {
      await ref.read(patientTodayRepositoryProvider(key)).upload();
    } catch (_) {
      offline = true;
    }
    if (!_current) return;
    try {
      await ref.read(patientTodayRepositoryProvider(key)).refresh();
    } catch (_) {
      offline = true;
    }
    if (_current) state = PatientTodayState(offline: offline);
  }

  Future<void> act(String id, {required bool snooze}) async {
    if (!_current || state.busy) return;
    state = const PatientTodayState(busy: true);
    var offline = false;
    try {
      final repo = ref.read(patientTodayRepositoryProvider(key));
      await repo.act(id, snooze: snooze);
      if (_current) await repo.upload();
    } catch (_) {
      offline = true;
    }
    if (_current) state = PatientTodayState(offline: offline);
  }

  /// P3 leaves only after local persistence, without waiting for connectivity.
  Future<bool> confirmAlert(
    PatientReminderAlertTarget target, {
    required bool snooze,
  }) async {
    if (!_current || state.busy || target.scope != key) return false;
    state = const PatientTodayState(busy: true);
    try {
      final repo = ref.read(patientTodayRepositoryProvider(key));
      final saved = await repo.confirmAlert(target, snooze: snooze);
      if (!_current) return false;
      if (!saved) {
        state = const PatientTodayState();
        return false;
      }
      unawaited(_uploadAlert(repo));
      return true;
    } catch (_) {
      if (_current) state = const PatientTodayState(offline: true);
      return false;
    }
  }

  Future<void> _uploadAlert(PatientTodayRepository repo) async {
    var offline = false;
    try {
      await repo.upload();
    } catch (_) {
      offline = true;
    }
    if (_current) state = PatientTodayState(offline: offline);
  }
}

class PatientLinkStatus {
  const PatientLinkStatus({this.connected = false, this.paused});
  final bool connected;
  final bool? paused;
}

final patientReconnectProvider =
    NotifierProvider.autoDispose<PatientReconnect, PatientTodayState>(
      PatientReconnect.new,
    );

class PatientReconnect extends Notifier<PatientTodayState> {
  int _generation = 0;
  StreamSubscription<IncomingGlassesMessage>? _subscription;
  Completer<bool>? _pending;
  @override
  PatientTodayState build() {
    ref.watch(patientSessionProvider);
    ref.watch(glassesConnectionProvider);
    ++_generation;
    ref.onDispose(() {
      final pending = _pending;
      if (pending != null && !pending.isCompleted) pending.complete(false);
      unawaited(_subscription?.cancel());
    });
    return const PatientTodayState();
  }

  Future<void> retry() async {
    final context = ref.read(patientSessionProvider).context;
    if (context == null || state.busy) return;
    final connection = ref.read(glassesConnectionProvider);
    final generation = ++_generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(patientSessionProvider).context == context;
    state = const PatientTodayState(busy: true);
    StreamSubscription<IncomingGlassesMessage>? subscription;
    final hello = Completer<bool>();
    _pending = hello;
    void finish(bool value) {
      if (!hello.isCompleted) hello.complete(value);
    }

    try {
      subscription = connection.messages.listen(
        (message) {
          if (message is Hello) finish(message.deviceSerial == context.serial);
        },
        onError: (Object _) => finish(false),
        onDone: () => finish(false),
      );
      _subscription = subscription;
      await connection
          .connect(context.serial)
          .timeout(const Duration(seconds: 10));
      final matches = await hello.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!current()) return;
      if (!matches || connection.state != GlassesConnectionState.connected) {
        state = const PatientTodayState(offline: true);
        return;
      }
      final settings = ref
          .read(patientTodayDataProvider((context.patientId, context.deviceId)))
          .value
          ?.settings;
      await connection
          .send(
            TimeSync(
              utc: DateTime.now().toUtc().toIso8601String(),
              timezone: settings?.timezone ?? 'UTC',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (current()) state = const PatientTodayState();
    } catch (_) {
      if (current()) state = const PatientTodayState(offline: true);
    } finally {
      unawaited(subscription?.cancel());
    }
  }
}

final patientLinkProvider = StreamProvider.autoDispose<PatientLinkStatus>((
  ref,
) {
  final context = ref.watch(patientSessionProvider).context;
  if (context == null) return Stream.value(const PatientLinkStatus());
  final connection = ref.watch(glassesConnectionProvider),
      handover = ref.read(handoverConnectionProvider);
  var trusted =
      handover.context?.deviceId == context.deviceId &&
      handover.context?.patientId == context.patientId &&
      handover.context?.serial == context.serial;
  var connected =
      trusted && connection.state == GlassesConnectionState.connected;
  bool? paused;
  final stream = StreamController<PatientLinkStatus>();
  Timer? expiry;
  void emit() {
    if (!stream.isClosed) {
      stream.add(
        PatientLinkStatus(
          connected: connected,
          paused: connected ? paused : null,
        ),
      );
    }
  }

  final subscriptions = <StreamSubscription>[];
  emit();
  try {
    subscriptions.add(
      connection.states.listen(
        (value) {
          connected = trusted && value == GlassesConnectionState.connected;
          if (!connected) {
            trusted = false;
            paused = null;
            expiry?.cancel();
          }
          emit();
        },
        onError: (Object _) {
          connected = false;
          paused = null;
          emit();
        },
      ),
    );
    subscriptions.add(
      connection.messages.listen(
        (message) {
          if (message is Hello) {
            trusted = message.deviceSerial == context.serial;
            connected =
                trusted && connection.state == GlassesConnectionState.connected;
            paused = null;
            emit();
          } else if (message is Telemetry && trusted && connected) {
            paused = message.memoryPaused;
            expiry?.cancel();
            expiry = Timer(const Duration(seconds: 90), () {
              paused = null;
              emit();
            });
            emit();
          }
        },
        onError: (Object _) {
          paused = null;
          emit();
        },
      ),
    );
  } catch (_) {
    connected = false;
    emit();
  }
  ref.onDispose(() {
    expiry?.cancel();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    stream.close();
  });
  return stream.stream;
});
