import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/unknown_face_previews.dart';
import '../data/unknown_faces_repository.dart';
import '../domain/people_data.dart';
import '../domain/unknown_faces_data.dart';
import 'people_providers.dart';

final unknownFacesRepositoryProvider = Provider.autoDispose
    .family<UnknownFacesRepository, PeopleScope>((ref, scope) {
      final repo = UnknownFacesRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final unknownFacePreviewsProvider = Provider.autoDispose
    .family<UnknownFacePreviews, PeopleScope>((ref, scope) {
      final store = NativeUnknownFacePreviews(scope);
      ref.onDispose(store.dispose);
      return store;
    });
final unknownFacesDataProvider = StreamProvider.autoDispose<UnknownFacesData>((
  ref,
) {
  final scope = ref.watch(peopleScopeProvider);
  return scope == null
      ? Stream.value(const UnknownFacesData())
      : ref.watch(unknownFacesRepositoryProvider(scope)).watch();
});
final unknownFacesClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final unknownFacesNowProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  final clock = ref.watch(unknownFacesClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});

class UnknownFacesState {
  const UnknownFacesState({
    this.busy = false,
    this.failed = false,
    this.previewsAllowed = false,
    this.revision = 0,
  });
  final bool busy, failed, previewsAllowed;
  final int revision;
}

final unknownFacesRefreshProvider =
    NotifierProvider.autoDispose<UnknownFacesRefresh, UnknownFacesState>(
      UnknownFacesRefresh.new,
    );

class UnknownFacesRefresh extends Notifier<UnknownFacesState> {
  int _epoch = 0, _revision = 0;
  final _recovered = <String>{};
  @override
  UnknownFacesState build() {
    final scope = ref.watch(peopleScopeProvider);
    if (scope != null) {
      ref.watch(unknownFacePreviewsProvider(scope));
      try {
        ref.watch(unknownFacesRepositoryProvider(scope));
      } catch (_) {
        /* Refresh reports configuration failures. */
      }
    }
    ++_epoch;
    _recovered.clear();
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return UnknownFacesState(revision: ++_revision);
  }

  void hidePreviews() {
    final scope = ref.read(peopleScopeProvider);
    if (scope != null) ref.read(unknownFacePreviewsProvider(scope)).clear();
    ++_epoch;
    state = UnknownFacesState(failed: state.failed, revision: ++_revision);
  }

  Future<void> refresh({bool resetFailures = true}) async {
    if (state.busy) return;
    if (resetFailures) _recovered.clear();
    final epoch = _epoch;
    var scope = ref.read(peopleScopeProvider);
    if (scope != null) ref.read(unknownFacePreviewsProvider(scope)).clear();
    state = UnknownFacesState(busy: true, revision: ++_revision);
    try {
      if (ref.read(caregiverIdentityProvider).hasError) {
        ref.invalidate(caregiverIdentityProvider);
      }
      if (scope == null) {
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        scope = ref.read(peopleScopeProvider);
        if (scope == null) {
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          scope = ref.read(peopleScopeProvider);
        }
      }
      if (scope == null) {
        if (ref.mounted && epoch == _epoch) {
          state = UnknownFacesState(failed: true, revision: _revision);
        }
        return;
      }
      await ref.read(unknownFacesRepositoryProvider(scope)).refresh();
      if (ref.mounted &&
          epoch == _epoch &&
          ref.read(peopleScopeProvider) == scope) {
        state = UnknownFacesState(previewsAllowed: true, revision: _revision);
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = UnknownFacesState(failed: true, revision: _revision);
      }
    }
  }

  Future<void> photoFailed(
    PeopleScope scope,
    UnknownFace face,
    Object error,
  ) async {
    if (error is! UnknownPreviewFailure ||
        !state.previewsAllowed ||
        state.busy ||
        error.status != 403 ||
        ref.read(peopleScopeProvider) != scope ||
        !_recovered.add('${face.id}:${face.sampleId}')) {
      return;
    }
    await refresh(resetFailures: false);
  }
}
