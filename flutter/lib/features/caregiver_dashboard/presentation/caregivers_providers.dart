import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../data/caregivers_repository.dart';
import '../domain/caregivers_data.dart';
import 'home_providers.dart';

final caregiversScopeProvider = Provider<CaregiversScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider),
      patient = ref.watch(selectedHomePatientProvider);
  return identity.isLoading ||
          identity.hasError ||
          identity.value == null ||
          patient == null
      ? null
      : (identity.value!, patient.id);
});
final caregiversClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final caregiversRepositoryProvider = Provider.autoDispose
    .family<CaregiversRepository, CaregiversScope>((ref, scope) {
      final repo = CaregiversRepository(
        ref.watch(homeRepositoryProvider(scope.$1)),
        ref.watch(databaseProvider),
        scope,
        ref.watch(caregiversClockProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final caregiversDataProvider = StreamProvider.autoDispose
    .family<CaregiversData, CaregiversScope>(
      (ref, scope) => ref.watch(caregiversRepositoryProvider(scope)).watch(),
    );

class CaregiversState {
  const CaregiversState({
    this.busy = false,
    this.pending = false,
    this.uncertain = false,
    this.successes = 0,
    this.failure,
  });
  final bool busy, pending, uncertain;
  final int successes;
  final ApiFailure? failure;
}

final caregiversControllerProvider = NotifierProvider.autoDispose
    .family<CaregiversController, CaregiversState, CaregiversScope>(
      CaregiversController.new,
    );

class CaregiversController extends Notifier<CaregiversState> {
  CaregiversController(this.scope);
  final CaregiversScope scope;
  LinkedCaregiver? _pending;
  int _successes = 0;
  bool get _current =>
      ref.mounted && ref.read(caregiversScopeProvider) == scope;
  bool get canLink =>
      _current &&
      ref.read(caregiverCanManageProvider) &&
      !state.busy &&
      !state.pending &&
      !state.uncertain;
  @override
  CaregiversState build() {
    try {
      ref.watch(caregiversRepositoryProvider(scope));
    } catch (_) {
      /* Localized configuration failure. */
    }
    Future.microtask(() {
      if (_current) refresh();
    });
    return const CaregiversState();
  }

  Future<void> _flush() async {
    if (_pending == null || !_current) return;
    await ref.read(caregiversRepositoryProvider(scope)).cacheLink(_pending!);
    if (_current) {
      _pending = null;
      ++_successes;
    }
  }

  Future<void> refresh() async {
    if (!_current || state.busy) return;
    final uncertain = state.uncertain,
        permissionChanged = state.failure?.code == 'MANAGER_ONLY';
    state = CaregiversState(
      busy: true,
      pending: _pending != null,
      uncertain: uncertain,
      successes: _successes,
    );
    try {
      if (_pending != null) {
        await _flush();
      } else {
        if (permissionChanged) {
          await ref.read(homeRepositoryProvider(scope.$1)).refresh(scope.$2);
        }
        if (!_current) return;
        await ref.read(caregiversRepositoryProvider(scope)).refresh();
      }
      if (_current) state = CaregiversState(successes: _successes);
    } catch (e) {
      if (_current) {
        state = CaregiversState(
          successes: _successes,
          pending: _pending != null,
          uncertain: uncertain,
          failure: e is ApiFailure
              ? e
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
    }
  }

  Future<void> link(CaregiverLinkDraft draft) async {
    if (!canLink || !draft.isValid) return;
    state = CaregiversState(busy: true, successes: _successes);
    try {
      final receipt = await ref
          .read(caregiversRepositoryProvider(scope))
          .link(draft);
      if (!_current) return;
      _pending = receipt;
      await _flush();
      if (_current) state = CaregiversState(successes: _successes);
    } catch (e) {
      if (!_current) return;
      final error = e is ApiFailure
          ? e
          : ApiFailure(ApiFailureKind.invalidResponse);
      if (error.code == 'ALREADY_LINKED') {
        try {
          await ref.read(caregiversRepositoryProvider(scope)).refresh();
        } catch (_) {
          /* Retain the specific linking result. */
        }
      }
      if (!_current) return;
      final definite =
          error.statusCode != null &&
          error.statusCode! >= 400 &&
          error.statusCode! < 500 &&
          error.statusCode != 403;
      state = CaregiversState(
        successes: _successes,
        pending: _pending != null,
        uncertain: _pending == null && !definite,
        failure: error,
      );
    }
  }
}
