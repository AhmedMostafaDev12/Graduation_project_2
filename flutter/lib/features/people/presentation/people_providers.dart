import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/people_photo_cache.dart';
import '../data/people_repository.dart';
import '../domain/people_data.dart';

final peopleScopeProvider = Provider<PeopleScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider);
  final patient = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading ||
      identity.hasError ||
      identity.value == null ||
      patient == null) {
    return null;
  }
  return PeopleScope(identity.value!, patient.id);
});
final peoplePhotoCacheProvider = Provider<PeoplePhotoCache>(
  (ref) => NativePeoplePhotoCache(),
);
final peopleRepositoryProvider = Provider.autoDispose
    .family<PeopleRepository, PeopleScope>((ref, scope) {
      final repo = PeopleRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
        ref.watch(peoplePhotoCacheProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final peopleDataProvider = StreamProvider.autoDispose<PeopleData>((ref) {
  final scope = ref.watch(peopleScopeProvider);
  return scope == null
      ? Stream.value(const PeopleData())
      : ref.watch(peopleRepositoryProvider(scope)).watch();
});
final peopleFilterProvider =
    NotifierProvider.autoDispose<PeopleFilterController, PeopleFilter>(
      PeopleFilterController.new,
    );

class PeopleFilterController extends Notifier<PeopleFilter> {
  @override
  PeopleFilter build() {
    ref.watch(peopleScopeProvider);
    return PeopleFilter.active;
  }

  void select(PeopleFilter value) => state = value;
}

class PeopleRefreshState {
  const PeopleRefreshState({this.busy = false, this.failed = false});
  final bool busy, failed;
}

final peopleRefreshProvider =
    NotifierProvider.autoDispose<PeopleRefresh, PeopleRefreshState>(
      PeopleRefresh.new,
    );

class PeopleRefresh extends Notifier<PeopleRefreshState> {
  int _epoch = 0;
  final _recoveredPhotoKeys = <String>{};
  @override
  PeopleRefreshState build() {
    ref.watch(peopleScopeProvider);
    _epoch++;
    _recoveredPhotoKeys.clear();
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const PeopleRefreshState();
  }

  Future<void> refresh({bool resetPhotoFailures = true}) async {
    if (state.busy) return;
    if (resetPhotoFailures) _recoveredPhotoKeys.clear();
    final epoch = _epoch;
    state = const PeopleRefreshState(busy: true);
    try {
      if (ref.read(caregiverIdentityProvider).hasError) {
        ref.invalidate(caregiverIdentityProvider);
      }
      var scope = ref.read(peopleScopeProvider);
      if (scope == null) {
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        scope = ref.read(peopleScopeProvider);
        if (scope == null) {
          // Cold entry uses the existing authenticated patient-selection bootstrap.
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          if (ref.read(homeRefreshProvider).failed) {
            throw ApiFailure(ApiFailureKind.network);
          }
          scope = ref.read(peopleScopeProvider);
        }
      }
      if (scope != null) {
        await ref.read(peopleRepositoryProvider(scope)).refresh();
      }
      if (ref.mounted && epoch == _epoch) state = const PeopleRefreshState();
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = const PeopleRefreshState(failed: true);
      }
    }
  }

  Future<void> photoFailed(
    PeopleScope scope,
    KnownPerson person,
    Object error,
  ) async {
    final url = person.photoUrl;
    if (!isExpiredPeoplePhoto(error) ||
        url == null ||
        ref.read(peopleScopeProvider) != scope ||
        !_recoveredPhotoKeys.add(person.imageKey(scope))) {
      return;
    }
    try {
      await ref.read(peoplePhotoCacheProvider).evict(scope, person);
    } catch (_) {
      /* Do not expose signed URLs/platform failures. */
    }
    if (ref.mounted && ref.read(peopleScopeProvider) == scope) {
      await refresh(resetPhotoFailures: false);
    }
  }
}
