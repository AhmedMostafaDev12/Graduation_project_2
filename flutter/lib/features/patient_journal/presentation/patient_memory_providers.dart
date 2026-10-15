import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../data/patient_journal_previews.dart';
import '../data/patient_memory_repository.dart';
import '../domain/patient_memory_detail.dart';
import 'patient_journal_providers.dart';

final patientMemoryRepositoryProvider = Provider.autoDispose
    .family<PatientMemoryRepository, PatientMemoryTarget>((ref, target) {
      final repo = PatientMemoryRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        target,
        ref.watch(patientTodayClockProvider),
        current: () =>
            ref.mounted &&
            ref.read(patientTodayKeyProvider) == target.journal.$1,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final patientMemoryDataProvider = StreamProvider.autoDispose
    .family<PatientMemoryDetail?, PatientMemoryTarget>(
      (ref, target) =>
          ref.watch(patientMemoryRepositoryProvider(target)).watch(),
    );
final patientMemoryPhotosProvider = Provider.autoDispose
    .family<PatientJournalPreviews, PatientMemoryTarget>((ref, target) {
      final store = NativePatientJournalPreviews((
        target.journal.$1,
        'memory:${target.mediaId}',
        target.journal.$3,
      ), ref.watch(patientTodayClockProvider));
      ref.onCancel(store.clear);
      ref.onDispose(store.dispose);
      return store;
    });

class PatientMemoryState {
  const PatientMemoryState({
    this.busy = false,
    this.failed = false,
    this.missing = false,
    this.acknowledged = false,
    this.uncertain = false,
    this.fresh,
    this.revision = 0,
  });
  final bool busy, failed, missing, acknowledged, uncertain;
  final PatientMemoryDetail? fresh;
  final int revision;
}

final patientMemoryControllerProvider = NotifierProvider.autoDispose
    .family<PatientMemoryController, PatientMemoryState, PatientMemoryTarget>(
      PatientMemoryController.new,
    );

class PatientMemoryController extends Notifier<PatientMemoryState> {
  PatientMemoryController(this.target);
  final PatientMemoryTarget target;
  bool _receipt = false, _recovered = false, _removing = false;
  int _epoch = 0, _revision = 0;
  bool get _current =>
      ref.mounted && ref.read(patientTodayKeyProvider) == target.journal.$1;
  @override
  PatientMemoryState build() {
    ref.watch(patientMemoryPhotosProvider(target));
    try {
      ref.watch(patientMemoryRepositoryProvider(target));
    } catch (_) {
      /* Localized unavailable state. */
    }
    Future.microtask(() {
      if (_current) refresh();
    });
    return const PatientMemoryState();
  }

  void hidePhotos() {
    ref.read(patientMemoryPhotosProvider(target)).clear();
    ++_epoch;
    state = PatientMemoryState(
      busy: _removing && state.busy,
      failed: state.failed,
      missing: state.missing,
      acknowledged: _receipt,
      uncertain: state.uncertain,
      revision: ++_revision,
    );
  }

  Future<void> refresh({bool resetFailure = true}) async {
    if (!_current || state.busy || _receipt) return;
    if (resetFailure) _recovered = false;
    final uncertain = state.uncertain;
    hidePhotos();
    final epoch = _epoch;
    state = PatientMemoryState(
      busy: true,
      uncertain: uncertain,
      revision: _revision,
    );
    final repo = ref.read(patientMemoryRepositoryProvider(target));
    try {
      await repo.refresh();
      if (!_current || epoch != _epoch) return;
      final fresh = await repo.read();
      if (_current && epoch == _epoch) {
        state = PatientMemoryState(
          fresh: fresh,
          missing: fresh == null,
          revision: _revision,
        );
      }
    } catch (e) {
      if (_current && epoch == _epoch) {
        _receipt = repo.deleted;
        final missing = _receipt || (e is ApiFailure && e.statusCode == 404);
        state = PatientMemoryState(
          failed: e is! ApiFailure || e.statusCode != 404,
          missing: missing,
          acknowledged: _receipt,
          uncertain: uncertain && !missing,
          revision: _revision,
        );
      }
    }
  }

  Future<void> photoFailed(Object error) async {
    if (!_current ||
        state.fresh == null ||
        state.busy ||
        _recovered ||
        error is! PatientJournalPreviewFailure ||
        error.status != 403) {
      return;
    }
    _recovered = true;
    await refresh(resetFailure: false);
  }

  Future<bool> remove() async {
    if (!_current ||
        state.busy ||
        state.uncertain ||
        (!_receipt &&
            (state.fresh == null ||
                state.fresh!.expired(ref.read(patientTodayClockProvider)())))) {
      return false;
    }
    _removing = true;
    hidePhotos();
    state = PatientMemoryState(
      busy: true,
      acknowledged: _receipt,
      revision: _revision,
    );
    final repo = ref.read(patientMemoryRepositoryProvider(target));
    try {
      if (!_receipt) {
        if (await repo.read() == null || !_current) {
          throw StateError('Unavailable memory');
        }
        try {
          await repo.remove();
        } on ApiFailure catch (e) {
          if (e.statusCode != 404) rethrow;
        }
        _receipt = true;
      }
      if (!_current) return false;
      ref.invalidate(patientJournalRepositoryProvider);
      ref.invalidate(patientJournalPreviewsProvider);
      await repo.cacheDeletion();
      if (!_current) return false;
      state = PatientMemoryState(
        acknowledged: true,
        missing: true,
        revision: _revision,
      );
      return true;
    } catch (error) {
      if (_current) {
        final definitive =
            error is ApiFailure &&
            error.kind == ApiFailureKind.server &&
            error.statusCode != null &&
            error.statusCode! < 500;
        state = PatientMemoryState(
          failed: true,
          acknowledged: _receipt,
          missing: _receipt,
          uncertain: !_receipt && !definitive,
          revision: _revision,
        );
      }
      return false;
    } finally {
      _removing = false;
    }
  }
}

typedef PatientMemoryPhotoKey = (PatientMemoryTarget, int);
final patientMemoryPhotoLiveProvider = StreamProvider.autoDispose
    .family<bool, PatientMemoryPhotoKey>((ref, value) {
      final (target, _) = value;
      final detail = ref.watch(patientMemoryControllerProvider(target)).fresh;
      if (detail == null ||
          ref.watch(patientTodayKeyProvider) != target.journal.$1) {
        return Stream.value(false);
      }
      final expiry = detail.photo().expiresAt!,
          clock = ref.watch(patientTodayClockProvider),
          stream = StreamController<bool>();
      Timer? timer;
      void schedule() {
        timer?.cancel();
        final now = clock();
        stream.add(expiry.isAfter(now));
        if (expiry.isAfter(now)) {
          timer = Timer(expiry.difference(now), () {
            ref.read(patientMemoryPhotosProvider(target)).clear();
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
final patientMemoryPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, PatientMemoryPhotoKey>((ref, value) {
      final (target, revision) = value;
      final state = ref.watch(patientMemoryControllerProvider(target));
      final fresh = state.fresh;
      if (ref.watch(patientTodayKeyProvider) != target.journal.$1 ||
          revision != state.revision ||
          fresh == null ||
          fresh.type != 'image') {
        throw const PatientJournalPreviewFailure();
      }
      return ref.watch(patientMemoryPhotosProvider(target)).load(fresh.photo());
    });
