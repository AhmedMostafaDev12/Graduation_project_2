import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../people/domain/people_data.dart';
import '../../people/domain/person_detail.dart';
import '../../people/presentation/people_providers.dart';
import '../../people/presentation/person_detail_providers.dart';
import '../data/more_repository.dart';
import '../domain/home_data.dart';
import '../domain/more_data.dart';
import 'home_providers.dart';

final moreScopeProvider = Provider<MoreScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider),
      patient = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading || identity.hasError || identity.value == null) {
    return null;
  }
  return (identity.value!, patient?.id);
});
final moreClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final moreRepositoryProvider = Provider.autoDispose
    .family<MoreRepository, MoreScope>((ref, scope) {
      final repo = MoreRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        ref.watch(homeRepositoryProvider(scope.$1)),
        ref.watch(credentialStoreProvider),
        scope,
        ref.watch(peoplePhotoCacheProvider),
        ref.watch(personDetailPhotoCacheProvider),
        ref.watch(moreClockProvider),
      );
      repo.invalidatePerson = (id) {
        if (!ref.mounted || scope.$2 == null) return;
        final owner = PeopleScope(scope.$1, scope.$2!);
        ref.invalidate(peopleRepositoryProvider(owner));
        ref.invalidate(
          personDetailRepositoryProvider(PersonDetailScope(owner, id)),
        );
      };
      ref.onDispose(repo.dispose);
      return repo;
    });
final moreDataProvider = StreamProvider.autoDispose.family<MoreData, MoreScope>(
  (ref, scope) => ref.watch(moreRepositoryProvider(scope)).watch(),
);

class MoreState {
  const MoreState({
    this.busy = false,
    this.failed = false,
    this.pending = false,
    this.uncertain = false,
  });
  final bool busy, failed, pending, uncertain;
}

final moreControllerProvider = NotifierProvider.autoDispose
    .family<MoreController, MoreState, MoreScope>(MoreController.new);

class MoreController extends Notifier<MoreState> {
  MoreController(this.scope);
  final MoreScope scope;
  ConsentRecord? _consent;
  HomePatient? _profile;
  bool _loggingOut = false;
  bool loggedOut = false;
  bool get _current => ref.mounted && ref.read(moreScopeProvider) == scope;
  bool get canWrite =>
      _current &&
      scope.$2 != null &&
      ref.read(caregiverCanManageProvider) &&
      !state.busy &&
      !state.pending &&
      !state.uncertain;
  @override
  MoreState build() {
    try {
      ref.watch(moreRepositoryProvider(scope));
    } catch (_) {
      /* Localized failure. */
    }
    Future.microtask(() {
      if (_current) refresh();
    });
    return const MoreState();
  }

  bool get _pending => _consent != null || _profile != null;
  Future<void> _flush() async {
    final repo = ref.read(moreRepositoryProvider(scope));
    if (_consent != null) await repo.cacheRevocation(_consent!);
    if (!_current) return;
    if (_profile != null) await repo.cacheProfile(_profile!);
    if (_current) {
      _consent = null;
      _profile = null;
    }
  }

  Future<void> refresh() async {
    if (!_current || state.busy) return;
    if (_loggingOut) {
      await logout();
      return;
    }
    final uncertain = state.uncertain;
    state = MoreState(busy: true, pending: _pending, uncertain: uncertain);
    try {
      if (_pending) {
        await _flush();
      } else {
        if (uncertain) {
          await ref.read(homeRepositoryProvider(scope.$1)).refresh(scope.$2);
        }
        if (!_current) return;
        await ref.read(moreRepositoryProvider(scope)).refresh();
      }
      if (_current) state = const MoreState();
    } catch (_) {
      if (_current) {
        state = MoreState(
          failed: true,
          pending: _pending,
          uncertain: uncertain,
        );
      }
    }
  }

  Future<bool> change({PatientProfile? profile, String? revokeId}) async {
    if (!canWrite || (profile == null) == (revokeId == null)) return false;
    state = const MoreState(busy: true);
    try {
      final repo = ref.read(moreRepositoryProvider(scope));
      if (profile != null) {
        final receipt = await repo.editProfile(profile);
        if (!_current) return false;
        _profile = receipt;
      } else {
        final receipt = await repo.revoke(revokeId!);
        if (!_current) return false;
        _consent = receipt;
      }
      await _flush();
      if (!_current) return false;
      state = const MoreState();
      return true;
    } catch (_) {
      if (_current) {
        state = MoreState(
          failed: true,
          pending: _pending,
          uncertain: !_pending,
        );
      }
      return false;
    }
  }

  Future<bool> logout() async {
    if (!_current || state.busy || _pending) return false;
    _loggingOut = true;
    state = const MoreState(busy: true);
    try {
      await ref
          .read(moreRepositoryProvider(scope))
          .logout(current: () => _current);
      if (!_current) return false;
      loggedOut = true;
      state = const MoreState();
      ref.read(caregiverSessionProvider.notifier).invalidate();
      ref.invalidate(caregiverIdentityProvider);
      return true;
    } catch (_) {
      if (_current) {
        _loggingOut = ref
            .read(moreRepositoryProvider(scope))
            .logoutAcknowledged;
        state = MoreState(
          failed: true,
          pending: ref.read(moreRepositoryProvider(scope)).logoutAcknowledged,
        );
      }
      return false;
    }
  }
}
