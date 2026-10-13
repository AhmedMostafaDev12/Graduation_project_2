import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../data/pairing_repository.dart';
import '../domain/pairing_info.dart';

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => PairingRepository(
    ref.watch(apiClientProvider),
    ref.watch(credentialStoreProvider),
  ),
);

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
  @override
  PairingState build() => const PairingState();
  Future<void> pair(String patientId, String serial) async {
    if (state.busy || state.info != null) return;
    state = PairingState(busy: true, serial: serial);
    try {
      final info = await ref
          .read(pairingRepositoryProvider)
          .pair(patientId, serial);
      if (ref.mounted) state = PairingState(info: info, serial: serial);
    } catch (error) {
      if (ref.mounted) {
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
