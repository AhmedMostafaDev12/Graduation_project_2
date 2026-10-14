import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/people_photo_cache.dart';
import '../data/person_detail_photo_cache.dart';
import '../data/person_detail_repository.dart';
import '../domain/person_detail.dart';
import '../domain/person_enrollment.dart';
import 'people_providers.dart';

final personDetailPhotoCacheProvider = Provider<PersonDetailPhotoCache>(
  (ref) => NativePersonDetailPhotoCache(),
);
final personDetailRepositoryProvider = Provider.autoDispose
    .family<PersonDetailRepository, PersonDetailScope>((ref, scope) {
      final repo = PersonDetailRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
        ref.watch(personDetailPhotoCacheProvider),
        ref.watch(peoplePhotoCacheProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final personDetailDataProvider = StreamProvider.autoDispose
    .family<PersonDetailData?, PersonDetailScope>(
      (ref, scope) => ref.watch(personDetailRepositoryProvider(scope)).watch(),
    );

enum PersonAction { edit, addPhotos, removePhoto, archive }

class PersonDetailState {
  const PersonDetailState({
    this.busy = false,
    this.pending = false,
    this.archived = false,
    this.failure,
  });
  final bool busy, pending, archived;
  final ApiFailure? failure;
}

final personDetailControllerProvider = NotifierProvider.autoDispose
    .family<PersonDetailController, PersonDetailState, PersonDetailScope>(
      PersonDetailController.new,
    );

class PersonDetailController extends Notifier<PersonDetailState> {
  PersonDetailController(this.scope);
  final PersonDetailScope scope;
  bool _pending = false, _pendingArchive = false;
  final _photoFailures = <String>{};
  bool get _current =>
      ref.mounted && ref.read(peopleScopeProvider) == scope.owner;
  @override
  PersonDetailState build() {
    ref.watch(personDetailRepositoryProvider(scope));
    Future.microtask(() {
      if (_current) refresh();
    });
    return const PersonDetailState();
  }

  Future<void> refresh({bool resetPhotos = true}) async {
    if (!_current || state.busy) return;
    if (resetPhotos) _photoFailures.clear();
    state = PersonDetailState(busy: true, pending: _pending);
    try {
      await _finish();
    } catch (error) {
      _failed(error);
    }
  }

  Future<void> _finish() async {
    final repo = ref.read(personDetailRepositoryProvider(scope));
    if (_pendingArchive) {
      await repo.cacheArchive();
    } else {
      await repo.refresh();
    }
    if (!_current) return;
    final archived = _pendingArchive;
    _pending = false;
    _pendingArchive = false;
    state = PersonDetailState(archived: archived);
  }

  void _failed(Object error) {
    if (ref.mounted) {
      state = PersonDetailState(
        pending: _pending,
        failure: error is ApiFailure
            ? error
            : ApiFailure(ApiFailureKind.invalidResponse),
      );
    }
  }

  void clearFailure() {
    if (!state.busy && !_pending) state = const PersonDetailState();
  }

  Future<bool> perform(
    PersonAction action, {
    String? name,
    String? relationship,
    String? photoId,
    List<EnrollmentPhoto>? photos,
  }) async {
    if (!_current ||
        state.busy ||
        _pending ||
        !ref.read(caregiverCanManageProvider)) {
      return false;
    }
    final repo = ref.read(personDetailRepositoryProvider(scope));
    state = const PersonDetailState(busy: true);
    var confirmed = false;
    try {
      final current = await repo.read();
      if (!_current ||
          current?.person.status.name != 'active' ||
          !ref.read(caregiverCanManageProvider)) {
        if (ref.mounted) state = const PersonDetailState();
        return false;
      }
      switch (action) {
        case PersonAction.edit:
          await repo.edit(name!, relationship!);
        case PersonAction.addPhotos:
          await repo.addPhotos(photos!);
        case PersonAction.removePhoto:
          await repo.removePhoto(photoId!);
        case PersonAction.archive:
          await repo.archive();
      }
      if (!_current) return false;
      confirmed = true;
      _pending = true;
      _pendingArchive = action == PersonAction.archive;
      state = const PersonDetailState(busy: true, pending: true);
      await _finish();
    } catch (error) {
      _failed(error);
    }
    return confirmed && _current;
  }

  Future<void> photoFailed(EnrolledPhoto photo, Object error) async {
    if (!_current ||
        !isExpiredPeoplePhoto(error) ||
        !_photoFailures.add(photo.id)) {
      return;
    }
    try {
      await ref.read(personDetailPhotoCacheProvider).evict(scope, photo);
    } catch (_) {}
    if (_current) await refresh(resetPhotos: false);
  }
}
