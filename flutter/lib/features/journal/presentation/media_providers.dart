import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/journal_previews.dart';
import '../data/media_repository.dart';
import '../domain/media_detail.dart';
import 'journal_providers.dart';

final mediaRepositoryProvider = Provider.autoDispose
    .family<MediaRepository, MediaKey>((ref, key) {
      final repo = MediaRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(journalClockProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final mediaDataProvider = StreamProvider.autoDispose
    .family<MediaDetail?, MediaKey>(
      (ref, key) => ref.watch(mediaRepositoryProvider(key)).watch(),
    );
final mediaPhotosProvider = Provider.autoDispose
    .family<JournalPreviews, MediaKey>((ref, key) {
      final store = NativeJournalPreviews((
        key.$1,
        'media:${key.$2}',
      ), ref.watch(journalClockProvider));
      ref.onDispose(store.dispose);
      return store;
    });
final mediaPhotoLiveProvider = StreamProvider.autoDispose
    .family<bool, MediaKey>((ref, key) {
      final detail = ref.watch(mediaDataProvider(key)).value;
      final clock = ref.watch(journalClockProvider);
      final controller = StreamController<bool>();
      final expiry = detail?.photo().expiresAt;
      Timer? timer;
      void schedule() {
        timer?.cancel();
        final now = clock();
        controller.add(detail != null && detail.photo().available(now));
        if (expiry != null && expiry.isAfter(now)) {
          timer = Timer(expiry.difference(now), () {
            ref.read(mediaPhotosProvider(key)).clear();
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

class MediaState {
  const MediaState({
    this.refreshing = false,
    this.writing = false,
    this.previews = false,
    this.failed = false,
    this.missing = false,
    this.acknowledged = false,
    this.uncertain = false,
    this.revision = 0,
  });
  final bool refreshing,
      writing,
      previews,
      failed,
      missing,
      acknowledged,
      uncertain;
  final int revision;
}

final mediaControllerProvider = NotifierProvider.autoDispose
    .family<MediaController, MediaState, MediaKey>(MediaController.new);

class MediaController extends Notifier<MediaState> {
  MediaController(this.key);
  final MediaKey key;
  int _epoch = 0, _revision = 0;
  bool _recovered = false;
  MediaReceipt? _receipt;
  bool get _current => ref.mounted && ref.read(journalScopeProvider) == key.$1;
  bool get _manager => _current && ref.read(caregiverCanManageProvider);
  @override
  MediaState build() {
    ref.watch(mediaPhotosProvider(key));
    try {
      ref.watch(mediaRepositoryProvider(key));
    } catch (_) {
      /* Refresh localizes configuration failures. */
    }
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const MediaState();
  }

  void hidePhotos() {
    ref.read(mediaPhotosProvider(key)).clear();
    ++_epoch;
    state = MediaState(
      writing: state.writing,
      failed: state.failed,
      missing: state.missing,
      acknowledged: state.acknowledged,
      uncertain: state.uncertain,
      revision: ++_revision,
    );
  }

  Future<void> refresh({bool resetFailure = true}) async {
    if (!_current || state.writing || state.refreshing || _receipt != null) {
      return;
    }
    if (resetFailure) _recovered = false;
    hidePhotos();
    final epoch = _epoch;
    final uncertain = state.uncertain;
    state = MediaState(
      refreshing: true,
      uncertain: uncertain,
      revision: _revision,
    );
    try {
      await ref.read(mediaRepositoryProvider(key)).refresh();
      if (_current && epoch == _epoch) {
        state = MediaState(previews: true, revision: _revision);
      }
    } catch (e) {
      if (_current && epoch == _epoch) {
        state = MediaState(
          failed: true,
          missing: e is ApiFailure && e.statusCode == 404,
          uncertain: uncertain && !(e is ApiFailure && e.statusCode == 404),
          revision: _revision,
        );
      }
    }
  }

  Future<void> photoFailed(Object error) async {
    if (_current &&
        state.previews &&
        !state.refreshing &&
        !_recovered &&
        error is JournalPreviewFailure &&
        error.status == 403) {
      _recovered = true;
      await refresh(resetFailure: false);
    }
  }

  Future<bool> write({required bool delete}) async {
    if (!_current ||
        (_receipt == null && !_manager) ||
        state.writing ||
        state.refreshing ||
        state.uncertain) {
      return false;
    }
    final repo = ref.read(mediaRepositoryProvider(key));
    if (_receipt == null) {
      final detail = await repo.read();
      if (!_manager ||
          detail == null ||
          detail.expired(ref.read(journalClockProvider)()) ||
          state.writing ||
          state.refreshing) {
        return false;
      }
    }
    hidePhotos();
    state = MediaState(
      writing: true,
      acknowledged: _receipt != null,
      revision: _revision,
    );
    try {
      _receipt ??= await repo.write(delete: delete);
      if (!_current) return false;
      // Cancel any older C12 GET before changing its saved media references.
      ref.invalidate(journalRepositoryProvider);
      state = MediaState(
        writing: true,
        acknowledged: true,
        revision: _revision,
      );
      await repo.cacheReceipt(_receipt!);
      if (!_current) return false;
      state = MediaState(acknowledged: true, revision: _revision);
      return true;
    } catch (error) {
      if (_current) {
        final e = error is ApiFailure
            ? error
            : ApiFailure(ApiFailureKind.invalidResponse);
        final definitive =
            e.kind == ApiFailureKind.server &&
            e.statusCode != null &&
            e.statusCode! < 500;
        state = MediaState(
          failed: true,
          acknowledged: _receipt != null,
          uncertain: _receipt == null && !definitive,
          missing: e.statusCode == 404,
          revision: _revision,
        );
      }
      return false;
    }
  }
}
