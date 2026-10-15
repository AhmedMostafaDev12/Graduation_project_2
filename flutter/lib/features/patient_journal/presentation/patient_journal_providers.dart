import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../data/patient_journal_repository.dart';
import '../data/patient_journal_previews.dart';
import '../domain/patient_journal_data.dart';

final patientJournalYesterdayProvider =
    NotifierProvider.autoDispose<PatientJournalYesterday, bool>(
      PatientJournalYesterday.new,
    );

class PatientJournalYesterday extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(patientTodayKeyProvider);
    return false;
  }

  void select(bool yesterday) => state = yesterday;
}

final patientJournalKeyProvider = Provider.autoDispose<PatientJournalKey?>((
  ref,
) {
  final scope = ref.watch(patientTodayKeyProvider);
  if (scope == null) return null;
  final profile = ref.watch(patientTodayDataProvider(scope));
  if (profile.hasError || profile.value?.settings == null) return null;
  final zone = profile.value!.settings!.timezone;
  final now =
      ref.watch(patientTodayNowProvider).value ??
      ref.watch(patientTodayClockProvider)();
  final local = PatientTime.local(now, zone);
  final date = DateTime.utc(local.year, local.month, local.day).subtract(
    Duration(days: ref.watch(patientJournalYesterdayProvider) ? 1 : 0),
  );
  return (scope, date.toIso8601String().substring(0, 10), zone);
});
final patientJournalRepositoryProvider = Provider.autoDispose
    .family<PatientJournalRepository, PatientJournalKey>((ref, key) {
      final repo = PatientJournalRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(patientTodayClockProvider),
        current: () =>
            ref.mounted && ref.read(patientJournalKeyProvider) == key,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final patientJournalPreviewsProvider = Provider.autoDispose
    .family<PatientJournalPreviews, PatientJournalKey>((ref, key) {
      final store = NativePatientJournalPreviews(
        key,
        ref.watch(patientTodayClockProvider),
      );
      ref.onCancel(store.clear);
      ref.onDispose(store.dispose);
      return store;
    });
final patientJournalDataProvider =
    StreamProvider.autoDispose<PatientJournalData>((ref) {
      final key = ref.watch(patientJournalKeyProvider);
      return key == null
          ? Stream.value(const PatientJournalData())
          : ref.watch(patientJournalRepositoryProvider(key)).watch();
    });

typedef PatientJournalPreviewIdentity = (
  String,
  String,
  String,
  String,
  String?,
  DateTime?,
);
PatientJournalPreviewIdentity patientJournalPreviewIdentity(
  JournalMedia media,
) => (
  media.id,
  media.type,
  media.status,
  media.url,
  media.thumbnailUrl,
  media.expiresAt,
);

class PatientJournalRefreshState {
  const PatientJournalRefreshState({
    this.busy = false,
    this.failed = false,
    this.previewUntil,
    this.allowedPreviews = const {},
    this.revision = 0,
  });
  final bool busy, failed;
  final DateTime? previewUntil;
  final Set<PatientJournalPreviewIdentity> allowedPreviews;
  final int revision;
}

final patientJournalRefreshProvider =
    NotifierProvider.autoDispose<
      PatientJournalRefresh,
      PatientJournalRefreshState
    >(PatientJournalRefresh.new);

class PatientJournalRefresh extends Notifier<PatientJournalRefreshState> {
  int _epoch = 0, _revision = 0;
  final _recovered = <String>{};
  PatientJournalPreviews? _store;
  @override
  PatientJournalRefreshState build() {
    final key = ref.watch(patientJournalKeyProvider);
    if (key == null) {
      final scope = ref.watch(patientTodayKeyProvider);
      if (scope != null) {
        ref.watch(patientTodayControllerProvider(scope).notifier);
      }
    }
    _store?.clear();
    _store = null;
    if (key != null) {
      _store = ref.watch(patientJournalPreviewsProvider(key));
      try {
        ref.watch(patientJournalRepositoryProvider(key));
      } catch (_) {
        /* Gentle unavailable state. */
      }
    }
    final epoch = ++_epoch;
    _recovered.clear();
    Future.microtask(() {
      if (ref.mounted && epoch == _epoch) refresh();
    });
    return PatientJournalRefreshState(revision: ++_revision);
  }

  void hidePreviews() {
    _store?.clear();
    ++_epoch;
    state = PatientJournalRefreshState(
      failed: state.failed,
      revision: ++_revision,
    );
  }

  Future<void> refresh({bool resetFailures = true}) async {
    if (state.busy) return;
    if (resetFailures) _recovered.clear();
    hidePreviews();
    final epoch = _epoch;
    var key = ref.read(patientJournalKeyProvider);
    state = PatientJournalRefreshState(busy: true, revision: _revision);
    final started = ref.read(patientTodayClockProvider)();
    try {
      if (key == null) {
        final scope = ref.read(patientTodayKeyProvider);
        if (scope != null) {
          await ref
              .read(patientTodayControllerProvider(scope).notifier)
              .refresh();
        }
        if (!ref.mounted || epoch != _epoch) return;
        key = ref.read(patientJournalKeyProvider);
      }
      if (key == null) throw StateError('No patient journal scope');
      await ref.read(patientJournalRepositoryProvider(key)).refresh();
      if (!ref.mounted ||
          epoch != _epoch ||
          key != ref.read(patientJournalKeyProvider)) {
        return;
      }
      final fresh = await ref
          .read(patientJournalRepositoryProvider(key))
          .read();
      if (ref.mounted &&
          epoch == _epoch &&
          key == ref.read(patientJournalKeyProvider)) {
        state = PatientJournalRefreshState(
          previewUntil: started.add(const Duration(minutes: 10)),
          allowedPreviews: fresh.entries
              .expand((e) => e.media)
              .map(patientJournalPreviewIdentity)
              .toSet(),
          revision: _revision,
        );
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = PatientJournalRefreshState(failed: true, revision: _revision);
      }
    }
  }

  Future<void> photoFailed(
    PatientJournalKey key,
    JournalMedia media,
    Object error,
  ) async {
    if (error is! PatientJournalPreviewFailure ||
        error.status != 403 ||
        state.previewUntil == null ||
        state.busy ||
        key != ref.read(patientJournalKeyProvider) ||
        !_recovered.add(media.id)) {
      return;
    }
    await refresh(resetFailures: false);
  }
}

typedef PatientJournalPreviewKey = (
  PatientJournalKey,
  JournalMedia,
  DateTime,
  int,
);
final patientJournalPreviewAvailableProvider = StreamProvider.autoDispose
    .family<bool, PatientJournalPreviewKey>((ref, value) {
      final (key, media, freshUntil, _) = value;
      final expiry =
          media.expiresAt != null && media.expiresAt!.isBefore(freshUntil)
          ? media.expiresAt!
          : freshUntil;
      final clock = ref.watch(patientTodayClockProvider),
          stream = StreamController<bool>();
      Timer? timer;
      void schedule() {
        timer?.cancel();
        final now = clock();
        stream.add(expiry.isAfter(now));
        if (expiry.isAfter(now)) {
          timer = Timer(expiry.difference(now), () {
            ref.read(patientJournalPreviewsProvider(key)).expire(expiry);
            stream.add(false);
          });
        }
      }

      schedule();
      ref.onCancel(() => timer?.cancel());
      ref.onResume(schedule);
      ref.onDispose(() {
        timer?.cancel();
        stream.close();
      });
      return stream.stream;
    });
final patientJournalPreviewBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, PatientJournalPreviewKey>((ref, value) async {
      final (key, media, freshUntil, revision) = value;
      final state = ref.watch(patientJournalRefreshProvider);
      if (key != ref.watch(patientJournalKeyProvider) ||
          state.previewUntil != freshUntil ||
          state.revision != revision ||
          !state.allowedPreviews.contains(
            patientJournalPreviewIdentity(media),
          )) {
        throw const PatientJournalPreviewFailure();
      }
      final expiry =
          media.expiresAt != null && media.expiresAt!.isBefore(freshUntil)
          ? media.expiresAt!
          : freshUntil;
      final safe = JournalMedia(
        id: media.id,
        type: media.type,
        trigger: media.trigger,
        status: media.status,
        url: media.url,
        thumbnailUrl: media.thumbnailUrl,
        expiresAt: expiry,
      );
      return ref.watch(patientJournalPreviewsProvider(key)).load(safe);
    });
