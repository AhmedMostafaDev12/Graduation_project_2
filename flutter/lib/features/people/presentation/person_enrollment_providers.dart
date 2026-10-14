import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/db/remori_database.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/enrollment_photo_picker.dart';
import '../data/person_enrollment_repository.dart';
import '../domain/people_data.dart';
import '../domain/person_enrollment.dart';
import 'people_providers.dart';

final enrollmentPhotoPickerProvider = Provider<EnrollmentPhotoPicker>(
  (ref) => NativeEnrollmentPhotoPicker(),
);
final personEnrollmentRepositoryProvider = Provider.autoDispose
    .family<PersonEnrollmentRepository, PeopleScope>((ref, scope) {
      final repo = PersonEnrollmentRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });

class PersonEnrollmentState {
  const PersonEnrollmentState({
    this.busy = false,
    this.created = false,
    this.failure,
  });
  final bool busy, created;
  final ApiFailure? failure;
}

final personEnrollmentProvider = NotifierProvider.autoDispose
    .family<PersonEnrollmentController, PersonEnrollmentState, PeopleScope>(
      PersonEnrollmentController.new,
    );

class PersonEnrollmentController extends Notifier<PersonEnrollmentState> {
  PersonEnrollmentController(this.scope);
  final PeopleScope scope;
  CachedPeopleCompanion? _created;
  @override
  PersonEnrollmentState build() {
    ref.watch(personEnrollmentRepositoryProvider(scope));
    return const PersonEnrollmentState();
  }

  bool get _allowed =>
      ref.mounted &&
      ref.read(peopleScopeProvider) == scope &&
      ref.read(caregiverCanManageProvider);
  void clearFailure() {
    if (!state.busy) state = PersonEnrollmentState(created: _created != null);
  }

  Future<bool> save(PersonEnrollment draft) async {
    if (!_allowed || state.busy) return false;
    state = PersonEnrollmentState(busy: true, created: _created != null);
    try {
      final repo = ref.read(personEnrollmentRepositoryProvider(scope));
      _created ??= await repo.create(draft);
      if (!_allowed) return false;
      state = const PersonEnrollmentState(busy: true, created: true);
      await repo.cache(_created!);
      if (!_allowed) return false;
      state = const PersonEnrollmentState(created: true);
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = PersonEnrollmentState(
          created: _created != null,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
      return false;
    } finally {
      if (ref.mounted && state.busy) {
        state = PersonEnrollmentState(created: _created != null);
      }
    }
  }
}
