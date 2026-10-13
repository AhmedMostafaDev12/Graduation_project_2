import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_failure.dart';
import 'api_providers.dart';
import 'patient_session_store.dart';

final patientSessionStoreProvider = Provider<PatientSessionStore>(
  (ref) => SecurePatientSessionStore(),
);

class PatientSessionState {
  const PatientSessionState({
    this.context,
    this.busy = false,
    this.failed = false,
  });
  final PatientDeviceContext? context;
  final bool busy;
  final bool failed;
  bool get active => context != null;
}

final patientSessionProvider =
    NotifierProvider<PatientSession, PatientSessionState>(PatientSession.new);

class PatientSession extends Notifier<PatientSessionState> {
  int _generation = 0;
  late Future<void> restoration;
  @override
  PatientSessionState build() {
    restoration = Future.microtask(_restore);
    return const PatientSessionState();
  }

  Future<void> _restore() async {
    final generation = _generation;
    try {
      final saved = await ref.read(patientSessionStoreProvider).read();
      if (!ref.mounted || generation != _generation || saved == null) return;
      final credentials = ref.read(credentialStoreProvider);
      final token = await credentials.readDevice();
      if (!ref.mounted || generation != _generation) return;
      if (token == null || token.isEmpty) {
        await ref.read(patientSessionStoreProvider).clear();
        return;
      }
      // Restore the previously validated secure context offline. Later device
      // API 401s revoke access; connection loss alone never signs the patient out.
      await credentials.clearCaregiver();
      if (!ref.mounted || generation != _generation) return;
      ref.read(caregiverSessionProvider.notifier).invalidate();
      state = PatientSessionState(context: saved);
    } catch (_) {
      // Storage failure cannot enable Patient Mode or expose platform details.
    }
  }

  Future<bool> handover(
    PatientDeviceContext context, {
    required bool Function() connected,
  }) async {
    if (state.busy || state.active || !connected()) return false;
    final generation = ++_generation;
    state = const PatientSessionState(busy: true);
    try {
      final credentials = ref.read(credentialStoreProvider);
      final token = await credentials.readDevice();
      if (token == null || token.isEmpty) {
        throw ApiFailure(ApiFailureKind.credentials);
      }
      final response = await ref
          .read(apiClientProvider)
          .request<dynamic>(
            '/patients/${context.patientId}/devices',
            credential: ApiCredential.device,
          );
      final data = response.data;
      if (response.statusCode != 200 ||
          data is! List ||
          !data.any(
            (item) =>
                item is Map &&
                item['id'] == context.deviceId &&
                item['patient_id'] == context.patientId &&
                item['serial_number'] == context.serial,
          )) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      if (!ref.mounted ||
          generation != _generation ||
          !connected() ||
          await credentials.readDevice() != token) {
        throw ApiFailure(ApiFailureKind.credentials);
      }
      await ref.read(patientSessionStoreProvider).save(context);
      await credentials.clearCaregiver();
      if (!ref.mounted ||
          generation != _generation ||
          !connected() ||
          await credentials.readDevice() != token) {
        throw ApiFailure(ApiFailureKind.credentials);
      }
      state = PatientSessionState(context: context);
      ref.read(caregiverSessionProvider.notifier).invalidate();
      return true;
    } catch (_) {
      try {
        await ref.read(patientSessionStoreProvider).clear();
      } catch (_) {}
      if (ref.mounted && generation == _generation) {
        state = const PatientSessionState(failed: true);
      }
      return false;
    }
  }

  void invalidate() {
    _generation++;
    state = PatientSessionState(failed: state.busy);
    ref.read(patientSessionStoreProvider).clear().catchError((Object _) {});
  }
}
