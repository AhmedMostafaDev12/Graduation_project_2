import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/places_repository.dart';
import '../domain/places_data.dart';

final placesScopeProvider = Provider<PlacesScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider);
  final patient = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading ||
      identity.hasError ||
      identity.value == null ||
      patient == null) {
    return null;
  }
  return PlacesScope(identity.value!, patient.id);
});
final placesRepositoryProvider = Provider.autoDispose
    .family<PlacesRepository, PlacesScope>((ref, scope) {
      final repo = PlacesRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final placesDataProvider = StreamProvider.autoDispose<PlacesData>((ref) {
  final scope = ref.watch(placesScopeProvider);
  return scope == null
      ? Stream.value(const PlacesData())
      : ref.watch(placesRepositoryProvider(scope)).watch();
});

class PlacesRefreshState {
  const PlacesRefreshState({this.busy = false, this.failed = false});
  final bool busy, failed;
}

final placesRefreshProvider =
    NotifierProvider.autoDispose<PlacesRefresh, PlacesRefreshState>(
      PlacesRefresh.new,
    );

class PlacesRefresh extends Notifier<PlacesRefreshState> {
  int _epoch = 0;
  @override
  PlacesRefreshState build() {
    final scope = ref.watch(placesScopeProvider);
    if (scope != null) {
      try {
        ref.watch(placesRepositoryProvider(scope));
      } catch (_) {
        /* Refresh localizes configuration errors. */
      }
    }
    ++_epoch;
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const PlacesRefreshState();
  }

  Future<void> refresh() async {
    if (state.busy) return;
    final epoch = _epoch;
    state = const PlacesRefreshState(busy: true);
    try {
      if (ref.read(caregiverIdentityProvider).hasError) {
        ref.invalidate(caregiverIdentityProvider);
      }
      var scope = ref.read(placesScopeProvider);
      if (scope == null) {
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        scope = ref.read(placesScopeProvider);
        if (scope == null) {
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          scope = ref.read(placesScopeProvider);
        }
      }
      if (scope == null) throw StateError('No selected patient');
      await ref.read(placesRepositoryProvider(scope)).refresh();
      if (ref.mounted &&
          epoch == _epoch &&
          ref.read(placesScopeProvider) == scope) {
        state = const PlacesRefreshState();
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = const PlacesRefreshState(failed: true);
      }
    }
  }
}
