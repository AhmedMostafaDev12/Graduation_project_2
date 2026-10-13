import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../data/patient_repository.dart';
import '../domain/patient_draft.dart';

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepository(ref.watch(apiClientProvider)),
);

class PatientSetupState {
  const PatientSetupState({this.busy = false, this.patientId, this.failure});
  final bool busy;
  final String? patientId;
  final ApiFailure? failure;
}

final patientSetupProvider =
    NotifierProvider.autoDispose<PatientSetupController, PatientSetupState>(
      PatientSetupController.new,
    );

class PatientSetupController extends Notifier<PatientSetupState> {
  @override
  PatientSetupState build() => const PatientSetupState();

  Future<String?> create(PatientDraft draft) async {
    if (state.busy) return null;
    if (state.patientId != null) return state.patientId;
    state = const PatientSetupState(busy: true);
    try {
      final id = await ref.read(patientRepositoryProvider).create(draft);
      if (!ref.mounted) return null;
      state = PatientSetupState(patientId: id);
      return id;
    } catch (error) {
      if (ref.mounted) {
        state = PatientSetupState(
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.network),
        );
      }
      return null;
    }
  }
}
