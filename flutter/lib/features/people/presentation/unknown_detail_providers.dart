import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/unknown_face_previews.dart';
import '../data/unknown_faces_repository.dart';
import '../domain/people_data.dart';
import '../domain/unknown_faces_data.dart';
import 'people_providers.dart';
import 'unknown_faces_providers.dart';

typedef UnknownDetailKey = (PeopleScope, String);

// Separate from C6: covering the list clears its previews, not C7's session.
final unknownDetailPreviewsProvider = Provider.autoDispose
    .family<UnknownFacePreviews, UnknownDetailKey>((ref, key) {
      final store = NativeUnknownFacePreviews(key.$1);
      ref.onDispose(store.dispose);
      return store;
    });

class UnknownDetailState {
  const UnknownDetailState({
    this.refreshing = false,
    this.writing = false,
    this.previews = false,
    this.failed = false,
    this.acknowledged = false,
    this.uncertain = false,
    this.revision = 0,
    this.failure,
  });
  final bool refreshing, writing, previews, failed, acknowledged, uncertain;
  final int revision;
  final ApiFailure? failure;
  UnknownDetailState withoutPhotos(int revision) => UnknownDetailState(
    writing: writing,
    failed: failed,
    acknowledged: acknowledged,
    uncertain: uncertain,
    revision: revision,
    failure: failure,
  );
}

final unknownDetailControllerProvider = NotifierProvider.autoDispose
    .family<UnknownDetailController, UnknownDetailState, UnknownDetailKey>(
      UnknownDetailController.new,
    );

class UnknownDetailController extends Notifier<UnknownDetailState> {
  UnknownDetailController(this.key);
  final UnknownDetailKey key;
  int _epoch = 0, _revision = 0;
  final _recovered = <String>{};
  UnknownFaceDecision? _receipt;
  @override
  UnknownDetailState build() {
    try {
      ref.watch(unknownFacesRepositoryProvider(key.$1));
    } catch (_) {
      // Refresh reports a missing build configuration as a localized failure.
    }
    ref.watch(unknownDetailPreviewsProvider(key));
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const UnknownDetailState();
  }

  bool get _current => ref.mounted && ref.read(peopleScopeProvider) == key.$1;
  bool get _manager => _current && ref.read(caregiverCanManageProvider);
  void hidePhotos() {
    ref.read(unknownDetailPreviewsProvider(key)).clear();
    ++_epoch;
    state = state.withoutPhotos(++_revision);
  }

  Future<void> refresh({bool resetFailures = true}) async {
    if (!_current || state.writing || state.acknowledged || state.refreshing) {
      return;
    }
    if (resetFailures) _recovered.clear();
    hidePhotos();
    final epoch = _epoch;
    final uncertain = state.uncertain;
    state = UnknownDetailState(
      refreshing: true,
      uncertain: uncertain,
      revision: _revision,
    );
    try {
      await ref.read(unknownFacesRepositoryProvider(key.$1)).refresh();
      if (_current && epoch == _epoch) {
        state = UnknownDetailState(previews: true, revision: _revision);
      }
    } catch (_) {
      if (_current && epoch == _epoch) {
        state = UnknownDetailState(
          failed: true,
          uncertain: uncertain,
          revision: _revision,
        );
      }
    }
  }

  Future<void> photoFailed(UnknownFace face, Object error) async {
    if (_current &&
        state.previews &&
        !state.refreshing &&
        error is UnknownPreviewFailure &&
        error.status == 403 &&
        _recovered.add(face.sampleId ?? '')) {
      await refresh(resetFailures: false);
    }
  }

  Future<bool> decide({
    String? name,
    String? relationship,
    bool consent = false,
  }) async {
    if (!_current ||
        (_receipt == null && !_manager) ||
        state.writing ||
        state.refreshing ||
        state.uncertain) {
      return false;
    }
    hidePhotos();
    state = UnknownDetailState(
      writing: true,
      acknowledged: _receipt != null,
      revision: _revision,
    );
    try {
      final repo = ref.read(unknownFacesRepositoryProvider(key.$1));
      if (_receipt == null) {
        final data = await repo.read();
        if (!_manager || !data.faces.any((f) => f.id == key.$2)) {
          if (_current) state = UnknownDetailState(revision: _revision);
          return false;
        }
      }
      _receipt ??= await repo.decide(
        key.$2,
        name: name,
        relationship: relationship,
        consent: consent,
      );
      if (!_current) return false;
      // Authorization can change while awaiting the API; retain the receipt,
      // clear private photos, and never replay an acknowledged decision.
      state = UnknownDetailState(
        writing: true,
        acknowledged: true,
        revision: _revision,
      );
      await repo.cacheDecision(_receipt!);
      if (!_current) return false;
      state = UnknownDetailState(acknowledged: true, revision: _revision);
      return true;
    } catch (error) {
      if (_current) {
        final failure = error is ApiFailure
            ? error
            : ApiFailure(ApiFailureKind.invalidResponse);
        final definitive =
            failure.kind == ApiFailureKind.server &&
            failure.statusCode != null &&
            failure.statusCode! < 500 &&
            failure.statusCode != 409 &&
            failure.statusCode != 404;
        state = UnknownDetailState(
          acknowledged: _receipt != null,
          uncertain: _receipt == null && !definitive,
          revision: _revision,
          failure: failure,
        );
      }
      return false;
    }
  }
}
