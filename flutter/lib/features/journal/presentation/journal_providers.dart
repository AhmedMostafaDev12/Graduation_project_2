import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../data/journal_repository.dart';
import '../data/journal_previews.dart';
import '../domain/journal_data.dart';

final journalScopeProvider = Provider<JournalScope?>((ref) {
  final identity = ref.watch(caregiverIdentityProvider),
      p = ref.watch(selectedHomePatientProvider);
  if (identity.isLoading ||
      identity.hasError ||
      identity.value == null ||
      p == null) {
    return null;
  }
  try {
    PatientTime.location(p.timezone);
  } catch (_) {
    return null;
  }
  return JournalScope(identity.value!, p.id, p.timezone);
});
final journalClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final journalNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(journalClockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock());
});
final journalDayProvider = NotifierProvider.autoDispose<JournalDay, String>(
  JournalDay.new,
);

class JournalDay extends Notifier<String> {
  JournalScope? _scope;
  String? _selected;
  @override
  String build() {
    final scope = ref.watch(journalScopeProvider);
    if (_scope != scope) {
      _selected = null;
      _scope = scope;
    }
    final now =
        ref.watch(journalNowProvider).value ??
        ref.watch(journalClockProvider)();
    return _selected ??
        (scope == null
            ? now.toUtc().toIso8601String().substring(0, 10)
            : PatientTime.day(now, scope.timezone));
  }

  void shift(int days) {
    final parsed = DateTime.parse(state);
    final day = DateTime.utc(parsed.year, parsed.month, parsed.day + days);
    _selected =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    state = _selected!;
  }
}

final journalKeyProvider = Provider<JournalKey?>((ref) {
  final scope = ref.watch(journalScopeProvider),
      day = ref.watch(journalDayProvider);
  return scope == null ? null : (scope, day);
});
final journalRepositoryProvider = Provider.autoDispose
    .family<JournalRepository, JournalKey>((ref, key) {
      final repo = JournalRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final journalPreviewsProvider = Provider.autoDispose
    .family<JournalPreviews, JournalKey>((ref, key) {
      final store = NativeJournalPreviews(key, ref.watch(journalClockProvider));
      ref.onDispose(store.dispose);
      return store;
    });
final journalDataProvider = StreamProvider.autoDispose<JournalData>((ref) {
  final key = ref.watch(journalKeyProvider);
  return key == null
      ? Stream.value(const JournalData())
      : ref.watch(journalRepositoryProvider(key)).watch();
});
// Hide and evict previews at their exact retention boundary, without waiting
// for the journal's minute clock or making another network request.
final journalPreviewAvailableProvider = StreamProvider.autoDispose
    .family<bool, (JournalKey, JournalMedia)>((ref, value) {
      final (key, media) = value;
      final clock = ref.watch(journalClockProvider);
      final controller = StreamController<bool>();
      Timer? timer;
      final expiry = media.expiresAt;
      void schedule() {
        timer?.cancel();
        final now = clock();
        controller.add(media.available(now));
        if (expiry != null && expiry.isAfter(now)) {
          timer = Timer(expiry.difference(now), () {
            ref.read(journalPreviewsProvider(key)).expire(expiry);
            controller.add(false);
          });
        }
      }

      schedule();
      ref.onCancel(() => timer?.cancel());
      ref.onResume(schedule);
      ref.onDispose(() {
        timer?.cancel();
        controller.close();
      });
      return controller.stream;
    });
final journalFilterProvider =
    NotifierProvider.autoDispose<JournalFilterController, JournalFilter>(
      JournalFilterController.new,
    );

class JournalFilterController extends Notifier<JournalFilter> {
  @override
  JournalFilter build() {
    ref.watch(journalScopeProvider);
    return JournalFilter.all;
  }

  void select(JournalFilter filter) => state = filter;
}

class JournalRefreshState {
  const JournalRefreshState({
    this.busy = false,
    this.failed = false,
    this.previews = false,
    this.revision = 0,
  });
  final bool busy, failed, previews;
  final int revision;
}

final journalRefreshProvider =
    NotifierProvider.autoDispose<JournalRefresh, JournalRefreshState>(
      JournalRefresh.new,
    );

class JournalRefresh extends Notifier<JournalRefreshState> {
  int _epoch = 0, _revision = 0;
  final _recovered = <String>{};
  @override
  JournalRefreshState build() {
    final key = ref.watch(journalKeyProvider);
    if (key != null) {
      ref.watch(journalPreviewsProvider(key));
      try {
        ref.watch(journalRepositoryProvider(key));
      } catch (_) {
        /* Refresh reports configuration failures. */
      }
    }
    ++_epoch;
    _recovered.clear();
    final epoch = _epoch;
    Future.microtask(() {
      if (ref.mounted && epoch == _epoch) refresh();
    });
    return JournalRefreshState(revision: ++_revision);
  }

  void hidePreviews() {
    final key = ref.read(journalKeyProvider);
    if (key != null) ref.read(journalPreviewsProvider(key)).clear();
    ++_epoch;
    state = JournalRefreshState(failed: state.failed, revision: ++_revision);
  }

  void expire(DateTime now) {
    final key = ref.read(journalKeyProvider);
    if (key != null) ref.read(journalPreviewsProvider(key)).expire(now);
  }

  Future<void> refresh({bool resetFailures = true}) async {
    if (state.busy) return;
    if (resetFailures) _recovered.clear();
    hidePreviews();
    final epoch = _epoch;
    var key = ref.read(journalKeyProvider);
    state = JournalRefreshState(busy: true, revision: _revision);
    try {
      if (ref.read(caregiverIdentityProvider).hasError) {
        ref.invalidate(caregiverIdentityProvider);
      }
      if (key == null) {
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        key = ref.read(journalKeyProvider);
        if (key == null) {
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          key = ref.read(journalKeyProvider);
        }
      }
      if (key == null) throw StateError('No journal scope');
      await ref.read(journalRepositoryProvider(key)).refresh();
      if (ref.mounted &&
          epoch == _epoch &&
          key == ref.read(journalKeyProvider)) {
        state = JournalRefreshState(previews: true, revision: _revision);
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = JournalRefreshState(failed: true, revision: _revision);
      }
    }
  }

  Future<void> photoFailed(
    JournalKey key,
    JournalMedia media,
    Object error,
  ) async {
    if (error is! JournalPreviewFailure ||
        error.status != 403 ||
        !state.previews ||
        state.busy ||
        ref.read(journalKeyProvider) != key ||
        !_recovered.add(media.id)) {
      return;
    }
    await refresh(resetFailures: false);
  }
}
