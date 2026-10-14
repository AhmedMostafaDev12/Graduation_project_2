import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/db/remori_database.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/reminders_repository.dart';
import '../domain/reminder_data.dart';

final reminderClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final reminderNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(reminderClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});
final reminderScopeProvider = Provider<ReminderScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider),
      patient = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading ||
      identity.hasError ||
      identity.value == null ||
      patient == null) {
    return null;
  }
  return ReminderScope(identity.value!, patient.id, patient.timezone);
});
final reminderDayProvider = Provider<String?>((ref) {
  final scope = ref.watch(reminderScopeProvider);
  final snapshot = ref.watch(reminderNowProvider);
  final now = snapshot.isLoading
      ? ref.watch(reminderClockProvider)()
      : snapshot.value ?? ref.watch(reminderClockProvider)();
  if (scope == null) return null;
  try {
    return PatientTime.day(now, scope.timezone);
  } catch (_) {
    return null;
  }
});
final remindersRepositoryProvider = Provider.autoDispose
    .family<RemindersRepository, ReminderScope>((ref, scope) {
      final repo = RemindersRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        scope,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final remindersDataProvider = StreamProvider.autoDispose<ReminderListData>((
  ref,
) {
  final scope = ref.watch(reminderScopeProvider),
      day = ref.watch(reminderDayProvider);
  return scope == null || day == null
      ? Stream.value(const ReminderListData())
      : ref.watch(remindersRepositoryProvider(scope)).watch(day);
});

class RemindersState {
  const RemindersState({this.busy = false, this.pending = false, this.failure});
  final bool busy, pending;
  final ApiFailure? failure;
}

final remindersControllerProvider =
    NotifierProvider.autoDispose<RemindersController, RemindersState>(
      RemindersController.new,
    );

class RemindersController extends Notifier<RemindersState> {
  int _epoch = 0;
  ReminderScope? _owner;
  final _pending = <String, CachedRemindersCompanion>{};
  @override
  RemindersState build() {
    final scope = ref.watch(reminderScopeProvider);
    ref.watch(reminderDayProvider);
    if (scope != _owner) {
      _pending.clear();
      _owner = scope;
    }
    if (scope != null) {
      try {
        ref.watch(remindersRepositoryProvider(scope));
      } catch (_) {
        /* Refresh reports configuration/platform failures safely. */
      }
    }
    _epoch++;
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return RemindersState(pending: _pending.isNotEmpty);
  }

  bool _current(int epoch, ReminderScope scope) =>
      ref.mounted &&
      epoch == _epoch &&
      ref.read(reminderScopeProvider) == scope;
  Future<void> refresh() async {
    if (state.busy) return;
    final epoch = _epoch;
    state = RemindersState(busy: true, pending: _pending.isNotEmpty);
    try {
      var scope = ref.read(reminderScopeProvider);
      if (scope == null) {
        if (ref.read(caregiverIdentityProvider).hasError) {
          ref.invalidate(caregiverIdentityProvider);
        }
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        scope = ref.read(reminderScopeProvider);
        if (scope == null) {
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          scope = ref.read(reminderScopeProvider);
        }
      }
      final day = ref.read(reminderDayProvider);
      if (scope == null || day == null) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      final repo = ref.read(remindersRepositoryProvider(scope));
      for (final entry in List.of(_pending.entries)) {
        await repo.cacheToggle(entry.value);
        if (!_current(epoch, scope)) return;
        _pending.remove(entry.key);
      }
      await repo.refresh(day);
      if (_current(epoch, scope)) {
        state = RemindersState(
          pending: _pending.isNotEmpty,
          failure: _pending.isEmpty
              ? null
              : ApiFailure(ApiFailureKind.invalidResponse),
        );
      }
    } catch (error) {
      _fail(error, epoch);
    }
  }

  void _fail(Object error, int epoch, {ReminderScope? scope}) {
    if (ref.mounted &&
        (epoch == _epoch ||
            (scope != null &&
                ref.read(reminderScopeProvider) == scope &&
                _pending.isNotEmpty))) {
      state = RemindersState(
        busy: epoch != _epoch && state.busy,
        pending: _pending.isNotEmpty,
        failure: error is ApiFailure
            ? error
            : ApiFailure(ApiFailureKind.invalidResponse),
      );
    }
  }

  Future<void> toggle(String id, bool active) async {
    final scope = ref.read(reminderScopeProvider), epoch = _epoch;
    if (scope == null ||
        state.busy ||
        _pending.isNotEmpty ||
        !ref.read(caregiverCanManageProvider)) {
      return;
    }
    state = const RemindersState(busy: true);
    try {
      final repo = ref.read(remindersRepositoryProvider(scope));
      final row = await repo.toggle(id, active);
      if (!ref.mounted || ref.read(reminderScopeProvider) != scope) return;
      _pending[id] = row;
      await repo.cacheToggle(row);
      if (!ref.mounted || ref.read(reminderScopeProvider) != scope) return;
      _pending.remove(id);
      if (epoch == _epoch || !state.busy) state = const RemindersState();
    } catch (error) {
      _fail(error, epoch, scope: scope);
    }
  }
}
