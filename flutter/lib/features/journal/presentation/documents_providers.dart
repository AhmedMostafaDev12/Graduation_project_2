import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/documents_repository.dart';
import '../data/journal_previews.dart';
import '../domain/document_data.dart';
import 'journal_providers.dart';

final documentsFilterProvider =
    NotifierProvider.autoDispose<DocumentsFilterController, DocumentFilter>(
      DocumentsFilterController.new,
    );

class DocumentsFilterController extends Notifier<DocumentFilter> {
  @override
  DocumentFilter build() {
    ref.watch(journalScopeProvider);
    return DocumentFilter.all;
  }

  void select(DocumentFilter value) => state = value;
}

final documentsKeyProvider = Provider<DocumentsKey?>((ref) {
  final scope = ref.watch(journalScopeProvider),
      filter = ref.watch(documentsFilterProvider);
  return scope == null ? null : (scope, filter);
});
final documentsRepositoryProvider = Provider.autoDispose
    .family<DocumentsRepository, DocumentsKey>((ref, key) {
      final repo = DocumentsRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(journalClockProvider),
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final documentsDataProvider = StreamProvider.autoDispose<DocumentsData>((ref) {
  final key = ref.watch(documentsKeyProvider);
  return key == null
      ? Stream.value(const DocumentsData())
      : ref.watch(documentsRepositoryProvider(key)).watch();
});
final documentsPreviewsProvider = Provider.autoDispose
    .family<JournalPreviews, DocumentsKey>((ref, key) {
      final store = NativeJournalPreviews((
        key.$1,
        'documents:${key.$2.name}',
      ), ref.watch(journalClockProvider));
      ref.onDispose(store.dispose);
      return store;
    });
final documentsPreviewLiveProvider = StreamProvider.autoDispose
    .family<bool, (DocumentsKey, DocumentCard)>((ref, value) {
      final (key, document) = value;
      final clock = ref.watch(journalClockProvider);
      final controller = StreamController<bool>();
      Timer? timer;
      void schedule() {
        timer?.cancel();
        final now = clock();
        final live = document.previewUntil.isAfter(now);
        controller.add(live);
        if (live) {
          timer = Timer(document.previewUntil.difference(now), () {
            ref
                .read(documentsPreviewsProvider(key))
                .expire(document.previewUntil);
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

class DocumentsState {
  const DocumentsState({
    this.busy = false,
    this.failed = false,
    this.moreFailed = false,
    this.previews = false,
    this.revision = 0,
  });
  final bool busy, failed, moreFailed, previews;
  final int revision;
}

final documentsControllerProvider =
    NotifierProvider.autoDispose<DocumentsController, DocumentsState>(
      DocumentsController.new,
    );

class DocumentsController extends Notifier<DocumentsState> {
  int _epoch = 0, _revision = 0;
  final _recovered = <String>{};
  @override
  DocumentsState build() {
    final key = ref.watch(documentsKeyProvider);
    if (key != null) {
      ref.watch(documentsPreviewsProvider(key));
      try {
        ref.watch(documentsRepositoryProvider(key));
      } catch (_) {
        /* Refresh localizes configuration failures. */
      }
    }
    ++_epoch;
    _recovered.clear();
    final epoch = _epoch;
    Future.microtask(() {
      if (ref.mounted && epoch == _epoch) refresh();
    });
    return DocumentsState(revision: ++_revision);
  }

  void hidePreviews() {
    final key = ref.read(documentsKeyProvider);
    if (key != null) ref.read(documentsPreviewsProvider(key)).clear();
    ++_epoch;
    state = DocumentsState(
      failed: state.failed,
      moreFailed: state.moreFailed,
      revision: ++_revision,
    );
  }

  Future<void> refresh({bool more = false, bool resetFailures = true}) async {
    if (state.busy) return;
    if (resetFailures) _recovered.clear();
    hidePreviews();
    final epoch = _epoch;
    var key = ref.read(documentsKeyProvider);
    state = DocumentsState(busy: true, revision: _revision);
    try {
      if (ref.read(caregiverIdentityProvider).hasError) {
        ref.invalidate(caregiverIdentityProvider);
      }
      if (key == null) {
        await ref.read(homeDataProvider.future);
        if (!ref.mounted || epoch != _epoch) return;
        key = ref.read(documentsKeyProvider);
        if (key == null) {
          await ref.read(homeRefreshProvider.notifier).refresh();
          if (!ref.mounted || epoch != _epoch) return;
          key = ref.read(documentsKeyProvider);
        }
      }
      if (key == null) throw StateError('No document scope');
      final repo = ref.read(documentsRepositoryProvider(key));
      if (more) {
        await repo.loadMore();
      } else {
        await repo.refresh();
      }
      if (ref.mounted &&
          epoch == _epoch &&
          key == ref.read(documentsKeyProvider)) {
        state = DocumentsState(previews: true, revision: _revision);
      }
    } catch (_) {
      if (ref.mounted && epoch == _epoch) {
        state = DocumentsState(
          failed: true,
          moreFailed: more,
          revision: _revision,
        );
      }
    }
  }

  Future<void> photoFailed(DocumentsKey key, String id, Object error) async {
    if (error is JournalPreviewFailure &&
        error.status == 403 &&
        state.previews &&
        !state.busy &&
        ref.read(documentsKeyProvider) == key &&
        _recovered.add(id)) {
      await refresh(resetFailures: false);
    }
  }
}
