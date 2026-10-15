import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../data/document_detail_repository.dart';
import '../data/journal_previews.dart';
import '../domain/document_detail.dart';
import 'journal_providers.dart';

final documentDetailRepositoryProvider = Provider.autoDispose
    .family<DocumentDetailRepository, DocumentDetailKey>((ref, key) {
      final repo = DocumentDetailRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(journalClockProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final documentDetailDataProvider = StreamProvider.autoDispose
    .family<DocumentDetail?, DocumentDetailKey>(
      (ref, key) => ref.watch(documentDetailRepositoryProvider(key)).watch(),
    );
final documentDetailPhotosProvider = Provider.autoDispose
    .family<JournalPreviews, DocumentDetailKey>((ref, key) {
      final store = NativeJournalPreviews((
        key.$1,
        'document:${key.$2}',
      ), ref.watch(journalClockProvider));
      ref.onDispose(store.dispose);
      return store;
    });
final documentDetailPhotoLiveProvider = StreamProvider.autoDispose
    .family<bool, DocumentDetailKey>((ref, key) {
      final detail = ref.watch(documentDetailDataProvider(key)).value,
          clock = ref.watch(journalClockProvider);
      final stream = StreamController<bool>();
      Timer? timer;
      void schedule() {
        timer?.cancel();
        final now = clock(), expiry = detail?.previewUntil;
        final live = expiry != null && expiry.isAfter(now);
        stream.add(live);
        if (live) {
          timer = Timer(expiry.difference(now), () {
            ref.read(documentDetailPhotosProvider(key)).clear();
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

class DocumentDetailState {
  const DocumentDetailState({
    this.busy = false,
    this.failed = false,
    this.missing = false,
    this.previews = false,
    this.revision = 0,
  });
  final bool busy, failed, missing, previews;
  final int revision;
}

final documentDetailControllerProvider = NotifierProvider.autoDispose
    .family<DocumentDetailController, DocumentDetailState, DocumentDetailKey>(
      DocumentDetailController.new,
    );

class DocumentDetailController extends Notifier<DocumentDetailState> {
  DocumentDetailController(this.key);
  final DocumentDetailKey key;
  int _epoch = 0, _revision = 0;
  bool _recovered = false;
  bool get _current => ref.mounted && ref.read(journalScopeProvider) == key.$1;
  @override
  DocumentDetailState build() {
    ref.watch(documentDetailPhotosProvider(key));
    try {
      ref.watch(documentDetailRepositoryProvider(key));
    } catch (_) {
      /* Refresh localizes missing configuration. */
    }
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const DocumentDetailState();
  }

  void hidePhotos() {
    ref.read(documentDetailPhotosProvider(key)).clear();
    ++_epoch;
    state = DocumentDetailState(
      failed: state.failed,
      missing: state.missing,
      revision: ++_revision,
    );
  }

  Future<void> refresh({bool resetFailure = true}) async {
    if (!_current || state.busy) return;
    if (resetFailure) _recovered = false;
    hidePhotos();
    final epoch = _epoch;
    state = DocumentDetailState(busy: true, revision: _revision);
    try {
      await ref.read(documentDetailRepositoryProvider(key)).refresh();
      if (_current && epoch == _epoch) {
        state = DocumentDetailState(previews: true, revision: _revision);
      }
    } catch (e) {
      if (_current && epoch == _epoch) {
        final denied =
            e is ApiFailure &&
            (e.statusCode == 404 || e.kind == ApiFailureKind.credentials);
        state = DocumentDetailState(
          failed: true,
          missing: denied,
          revision: _revision,
        );
        if (denied) {
          ref.invalidate(documentDetailDataProvider(key));
        }
      }
    }
  }

  Future<void> photoFailed(Object error) async {
    if (_current &&
        state.previews &&
        !state.busy &&
        !_recovered &&
        error is JournalPreviewFailure &&
        error.status == 403) {
      _recovered = true;
      await refresh(resetFailure: false);
    }
  }
}
