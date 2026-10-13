import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/patient_session_store.dart';
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
  PairingInfo? build() => null;
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
  @override
  HandoverConnectionState build() {
    ref.onDispose(() {
      unawaited(_states?.cancel());
      unawaited(_messages?.cancel());
    });
    return const HandoverConnectionState();
  }

  Future<void> prepare(String? patientId) async {
    final paired = ref.read(pairedGlassesProvider);
    if (_working || paired == null || paired.patientId != patientId) return;
    if (state.readyFor(patientId) && state.context!.serial == paired.serial) {
      return;
    }
    _working = true;
    final context = PatientDeviceContext(
      patientId: paired.patientId,
      deviceId: paired.deviceId,
      serial: paired.serial,
    );
    state = HandoverConnectionState(context: context);
    final connection = ref.read(glassesConnectionProvider);
    try {
      await _states?.cancel();
      await _messages?.cancel();
      _states = connection.states.listen(
        (value) {
          if (ref.mounted) {
            state = HandoverConnectionState(
              context: context,
              connection: value,
            );
          }
        },
        onError: (Object _) {
          if (ref.mounted) state = HandoverConnectionState(context: context);
        },
      );
      _messages = connection.messages.listen((message) async {
        if (message is Hello && message.deviceSerial == context.serial) {
          try {
            // Clock sync in UTC; the full relay will supply profile timezone.
            await connection.send(
              TimeSync(
                utc: DateTime.now().toUtc().toIso8601String(),
                timezone: 'UTC',
              ),
            );
          } catch (_) {
            if (ref.mounted) state = HandoverConnectionState(context: context);
          }
        }
      }, onError: (Object _) {});
      await connection.connect(context.serial);
      if (ref.mounted) {
        state = HandoverConnectionState(
          context: context,
          connection: connection.state,
        );
      }
    } catch (_) {
      // BLE is unimplemented; retain the existing pending UI.
      if (ref.mounted) state = HandoverConnectionState(context: context);
    } finally {
      _working = false;
    }
  }
}
