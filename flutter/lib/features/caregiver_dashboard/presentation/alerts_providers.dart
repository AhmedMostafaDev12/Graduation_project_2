import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/remori_database.dart';
import '../domain/home_data.dart';
import 'home_providers.dart';

final alertsOwnerProvider = Provider<String?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider);
  return identity.isLoading || identity.hasError ? null : identity.value;
});
final alertsClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final alertsNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(alertsClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});

class AlertsState {
  const AlertsState({
    this.busy = false,
    this.loaded = false,
    this.pending = false,
    this.failure,
    this.readFailure = false,
  });
  final bool busy, loaded, pending, readFailure;
  final ApiFailure? failure;
}

final alertsControllerProvider =
    NotifierProvider.autoDispose<AlertsController, AlertsState>(
      AlertsController.new,
    );

class AlertsController extends Notifier<AlertsState> {
  String? _owner;
  final _pending = <String, DashboardAlertsCompanion>{};
  @override
  AlertsState build() {
    final owner = ref.watch(alertsOwnerProvider);
    if (owner != _owner) {
      _owner = owner;
      _pending.clear();
    }
    if (owner != null) {
      try {
        ref.watch(homeRepositoryProvider(owner));
      } catch (_) {
        /* Report configuration failures safely. */
      }
    }
    Future.microtask(() {
      if (ref.mounted && ref.read(alertsOwnerProvider) == owner) refresh();
    });
    return AlertsState(pending: _pending.isNotEmpty);
  }

  bool _current(String owner) =>
      ref.mounted && ref.read(alertsOwnerProvider) == owner;
  Future<void> _flush(String owner) async {
    final repo = ref.read(homeRepositoryProvider(owner));
    for (final entry in _pending.entries.toList()) {
      if (!_current(owner)) return;
      await repo.cacheAlertRead(entry.value);
      if (!_current(owner)) return;
      _pending.remove(entry.key);
    }
  }

  Future<void> refresh() async {
    final owner = ref.read(alertsOwnerProvider);
    if (owner == null || state.busy) return;
    final loaded = state.loaded;
    state = AlertsState(
      busy: true,
      loaded: loaded,
      pending: _pending.isNotEmpty,
    );
    try {
      await _flush(owner);
      if (!_current(owner)) return;
      // Home owns patient/link validation; C2 reuses those cached identities.
      await ref.read(homeRefreshProvider.notifier).refresh();
      if (!_current(owner)) return;
      await ref.read(homeRepositoryProvider(owner)).refreshAlerts();
      if (_current(owner)) state = const AlertsState(loaded: true);
    } catch (error) {
      if (_current(owner)) {
        state = AlertsState(
          loaded: loaded,
          pending: _pending.isNotEmpty,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
    }
  }

  Future<bool> open(HomeAlert alert) async {
    final owner = ref.read(alertsOwnerProvider);
    if (owner == null || state.busy || _pending.isNotEmpty) return false;
    if (alert.readAt != null) return true;
    final loaded = state.loaded;
    state = AlertsState(busy: true, loaded: loaded);
    try {
      final receipt = await ref
          .read(homeRepositoryProvider(owner))
          .markAlertRead(alert.id);
      if (!_current(owner)) return false;
      _pending[alert.id] = receipt;
      await _flush(owner);
      if (!_current(owner)) return false;
      state = AlertsState(loaded: loaded);
      return true;
    } catch (error) {
      if (_current(owner)) {
        state = AlertsState(
          readFailure: true,
          loaded: loaded,
          pending: _pending.isNotEmpty,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
      return false;
    }
  }
}
