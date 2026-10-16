import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/patient_session_store.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/patient_session_provider.dart';
import '../../../core/relay/glasses_connection.dart';
import '../../../core/relay/glasses_connection_provider.dart';
import '../../../core/relay/glasses_message.dart';
import '../domain/pairing_info.dart';

/// Published only after POST /devices/pair and secure token storage succeed.
final pairedGlassesProvider = NotifierProvider<PairedGlasses, PairingInfo?>(
  PairedGlasses.new,
);

class PairedGlasses extends Notifier<PairingInfo?> {
  @override
  PairingInfo? build() {
    ref.listen(caregiverSessionProvider, (_, active) {
      // A successful handover intentionally ends the caregiver session.
      if (!active && !ref.read(patientSessionProvider).active) state = null;
    });
    return null;
  }

  void paired(PairingInfo info) => state = info;
}

class HandoverConnectionState {
  const HandoverConnectionState({
    this.context,
    this.connection = GlassesConnectionState.disconnected,
  });
  final PatientDeviceContext? context;
  final GlassesConnectionState connection;
  bool readyFor(String? patientId) =>
      context != null &&
      context!.patientId == patientId &&
      connection == GlassesConnectionState.connected;
}

final handoverConnectionProvider =
    NotifierProvider<HandoverConnection, HandoverConnectionState>(
      HandoverConnection.new,
    );

class HandoverConnection extends Notifier<HandoverConnectionState> {
  StreamSubscription<GlassesConnectionState>? _states;
  StreamSubscription<IncomingGlassesMessage>? _messages;
  bool _working = false;
  int _generation = 0;
  @override
  HandoverConnectionState build() {
    ref.watch(pairedGlassesProvider);
    ref.watch(glassesConnectionProvider);
    ++_generation;
    _working = false;
    // Prior subscriptions are cancelled by the previous build's disposal.
    // A fresh preparation must not await their already-cancelled handles.
    _states = null;
    _messages = null;
    ref.onDispose(() {
      ++_generation;
      unawaited(_states?.cancel());
      unawaited(_messages?.cancel());
    });
    return const HandoverConnectionState();
  }

  Future<void> prepare(String? patientId) async {
    final paired = ref.read(pairedGlassesProvider);
    if (_working || paired == null || paired.patientId != patientId) return;
    if (state.readyFor(patientId) &&
        state.context!.serial == paired.serial &&
        state.context!.deviceId == paired.deviceId) {
      return;
    }
    _working = true;
    final generation = ++_generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        identical(ref.read(pairedGlassesProvider), paired);
    final context = PatientDeviceContext(
      patientId: paired.patientId,
      deviceId: paired.deviceId,
      serial: paired.serial,
    );
    state = HandoverConnectionState(context: context);
    final connection = ref.read(glassesConnectionProvider);
    var identified = false, synced = false;
    var exchange = 0;
    void publish() {
      if (!current()) return;
      final transport = connection.state;
      state = HandoverConnectionState(
        context: context,
        connection:
            transport == GlassesConnectionState.connected &&
                !(identified && synced)
            ? GlassesConnectionState.connecting
            : transport,
      );
    }

    void lost() {
      identified = synced = false;
      ++exchange;
      if (current()) state = HandoverConnectionState(context: context);
    }

    try {
      await _states?.cancel();
      await _messages?.cancel();
      if (!current()) return;
      _states = connection.states.listen(
        (value) {
          if (!current()) return;
          if (value != GlassesConnectionState.connected) lost();
          publish();
        },
        onError: (Object _) => lost(),
        onDone: lost,
      );
      _messages = connection.messages.listen(
        (message) async {
          if (!current()) return;
          if (message is Hello) {
            final attempt = ++exchange;
            identified =
                message.deviceSerial == context.serial &&
                connection.state == GlassesConnectionState.connected;
            synced = false;
            publish();
            if (!identified) return;
            try {
              // Clock sync in UTC; the full relay will supply profile timezone.
              await connection
                  .send(
                    TimeSync(
                      utc: DateTime.now().toUtc().toIso8601String(),
                      timezone: 'UTC',
                    ),
                  )
                  .timeout(const Duration(seconds: 10));
              if (current() && attempt == exchange && identified) {
                synced = true;
                publish();
              }
            } catch (_) {
              if (current() && attempt == exchange) lost();
            }
          }
        },
        onError: (Object _) => lost(),
        onDone: lost,
      );
      await connection.connect(context.serial);
      publish();
    } catch (_) {
      // BLE is unimplemented; retain the existing pending UI.
      if (current()) lost();
    } finally {
      if (current()) _working = false;
    }
  }
}
