import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/relay/glasses_connection_provider.dart';
import '../../device_pairing/presentation/handover_providers.dart';
import '../domain/home_data.dart';
import 'home_providers.dart';

typedef DeviceScope = (String, String);
final deviceScopeProvider = Provider<DeviceScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider),
      patient = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading ||
      identity.hasError ||
      identity.value == null ||
      patient == null) {
    return null;
  }
  return (identity.value!, patient.id);
});
final deviceClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final deviceNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(deviceClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});

class DeviceState {
  const DeviceState({
    this.busy = false,
    this.loaded = false,
    this.failed = false,
    this.pending = false,
    this.uncertain = false,
  });
  final bool busy, loaded, failed, pending, uncertain;
}

final deviceControllerProvider = NotifierProvider.autoDispose
    .family<DeviceController, DeviceState, DeviceScope>(DeviceController.new);

class DeviceController extends Notifier<DeviceState> {
  DeviceController(this.scope);
  final DeviceScope scope;
  DeviceChange? _pending;
  bool get _current => ref.mounted && ref.read(deviceScopeProvider) == scope;
  bool get canWrite =>
      _current &&
      ref.read(caregiverCanManageProvider) &&
      !state.busy &&
      !state.pending &&
      !state.uncertain;
  @override
  DeviceState build() {
    try {
      ref.watch(homeRepositoryProvider(scope.$1));
    } catch (_) {
      /* Localized configuration failure. */
    }
    Future.microtask(() {
      if (_current) refresh();
    });
    return const DeviceState();
  }

  Future<void> _flush() async {
    final change = _pending;
    if (change == null || !_current) return;
    // Only the matching local pairing can own this device grant.
    final paired = ref.read(pairedGlassesProvider);
    if (change.deviceId != null &&
        paired?.deviceId == change.deviceId &&
        paired?.patientId == scope.$2) {
      await ref.read(credentialStoreProvider).clearDevice();
      if (!_current) return;
      ref.invalidate(pairedGlassesProvider);
      ref.invalidate(handoverConnectionProvider);
      try {
        await ref.read(glassesConnectionProvider).disconnect();
      } catch (_) {
        /* No active BLE implementation. */
      }
    }
    if (!_current) return;
    await ref.read(homeRepositoryProvider(scope.$1)).cacheDeviceChange(change);
    if (_current) _pending = null;
  }

  Future<void> refresh() async {
    if (!_current || state.busy) return;
    final loaded = state.loaded, uncertain = state.uncertain;
    state = DeviceState(
      busy: true,
      loaded: loaded,
      pending: _pending != null,
      uncertain: uncertain,
    );
    try {
      if (_pending != null) {
        await _flush();
      } else if (uncertain) {
        // Reuse Home's patient/settings refresh to reconcile an uncertain PATCH.
        await ref.read(homeRepositoryProvider(scope.$1)).refresh(scope.$2);
      } else {
        await ref
            .read(homeRepositoryProvider(scope.$1))
            .refreshDevices(scope.$2);
      }
      if (_current) state = const DeviceState(loaded: true);
    } catch (_) {
      if (_current) {
        state = DeviceState(
          loaded: loaded,
          failed: true,
          pending: _pending != null,
          uncertain: uncertain,
        );
      }
    }
  }

  Future<bool> change({bool? memoryEnabled, String? unpairId}) async {
    if (!canWrite) return false;
    final loaded = state.loaded;
    state = DeviceState(busy: true, loaded: loaded);
    try {
      final receipt = await ref
          .read(homeRepositoryProvider(scope.$1))
          .changeDevice(
            scope.$2,
            memoryEnabled: memoryEnabled,
            unpairId: unpairId,
          );
      if (!_current) return false;
      _pending = receipt;
      await _flush();
      if (!_current) return false;
      state = DeviceState(loaded: loaded);
      return true;
    } catch (_) {
      if (_current) {
        state = DeviceState(
          loaded: loaded,
          failed: true,
          pending: _pending != null,
          uncertain: _pending == null,
        );
      }
      return false;
    }
  }
}
