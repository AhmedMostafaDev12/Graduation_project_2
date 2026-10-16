import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../data/pairing_repository.dart';
import '../domain/pairing_info.dart';
import 'handover_providers.dart';

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  ref.watch(caregiverSessionProvider);
  final repository = PairingRepository(
    ref.watch(apiClientProvider),
    ref.watch(credentialStoreProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Successful sign-in starts a fresh setup scope, even without prior logout.
void resetPairingSetup(Ref ref) {
  ref.invalidate(pairingControllerProvider);
  ref.invalidate(pairingRepositoryProvider);
  ref.invalidate(pairedGlassesProvider);
}

class PairingState {
  const PairingState({this.busy = false, this.info, this.failure, this.serial});
  final bool busy;
  final PairingInfo? info;
  final ApiFailure? failure;
  final String? serial;
}

final pairingControllerProvider =
    NotifierProvider.autoDispose<PairingController, PairingState>(
      PairingController.new,
    );

class PairingController extends Notifier<PairingState> {
  int _generation = 0;
  @override
  PairingState build() {
    ref.watch(caregiverSessionProvider);
    try {
      ref.watch(pairingRepositoryProvider);
    } catch (_) {
      // Keep setup navigation usable; pair() reports configuration failures.
    }
    ++_generation;
    ref.onDispose(() => ++_generation);
    return const PairingState();
  }

  Future<void> pair(String patientId, String serial) async {
    if (state.busy || state.info != null) return;
    final generation = ++_generation;
    state = PairingState(busy: true, serial: serial);
    try {
      final info = await ref
          .read(pairingRepositoryProvider)
          .pair(patientId, serial);
      if (ref.mounted && generation == _generation) {
        ref.read(pairedGlassesProvider.notifier).paired(info);
        state = PairingState(info: info, serial: serial);
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = PairingState(
          serial: serial,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.network),
        );
      }
    }
  }
}
