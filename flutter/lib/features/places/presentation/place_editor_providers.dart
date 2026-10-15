import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../data/place_location.dart';
import '../data/places_repository.dart';
import '../domain/place_draft.dart';
import '../domain/places_data.dart';
import 'places_providers.dart';

typedef PlaceEditorKey = (PlacesScope, String?);
final placeLocationProvider = Provider<PlaceLocation>(
  (ref) => NativePlaceLocation(),
);

class PlaceEditorState {
  const PlaceEditorState({
    this.draft = const PlaceDraft(),
    this.loading = true,
    this.locating = false,
    this.busy = false,
    this.acknowledged = false,
    this.uncertain = false,
    this.missing = false,
    this.offline = false,
    this.failure,
  });
  final PlaceDraft draft;
  final bool loading, locating, busy, acknowledged, uncertain, missing, offline;
  final ApiFailure? failure;
  PlaceEditorState copyWith({
    PlaceDraft? draft,
    bool? loading,
    bool? locating,
    bool? busy,
    bool? acknowledged,
    bool? uncertain,
    bool? missing,
    bool? offline,
    ApiFailure? failure,
    bool clearFailure = false,
  }) => PlaceEditorState(
    draft: draft ?? this.draft,
    loading: loading ?? this.loading,
    locating: locating ?? this.locating,
    busy: busy ?? this.busy,
    acknowledged: acknowledged ?? this.acknowledged,
    uncertain: uncertain ?? this.uncertain,
    missing: missing ?? this.missing,
    offline: offline ?? this.offline,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

final placeEditorProvider = NotifierProvider.autoDispose
    .family<PlaceEditor, PlaceEditorState, PlaceEditorKey>(PlaceEditor.new);

class PlaceEditor extends Notifier<PlaceEditorState> {
  PlaceEditor(this.key);
  final PlaceEditorKey key;
  PlaceReceipt? _receipt;
  int _epoch = 0, _pointRevision = 0;
  bool _dirty = false;
  @override
  PlaceEditorState build() {
    try {
      ref.watch(placesRepositoryProvider(key.$1));
    } catch (_) {
      /* Load localizes configuration failures. */
    }
    Future.microtask(() {
      if (ref.mounted) _load();
    });
    return const PlaceEditorState();
  }

  bool get _current => ref.mounted && ref.read(placesScopeProvider) == key.$1;
  bool get _manager => _current && ref.read(caregiverCanManageProvider);
  PlaceDraft _draft(SavedPlace p) => PlaceDraft(
    name: p.name,
    point: PlacePoint(p.latitude, p.longitude),
    radiusM: p.radiusM,
  );
  Future<void> _load() async {
    final epoch = ++_epoch;
    if (!_manager) return;
    if (key.$2 == null) {
      final revision = _pointRevision;
      state = state.copyWith(loading: false, locating: true);
      PlacePoint? point;
      try {
        point = await ref.read(placeLocationProvider).current();
      } catch (_) {
        /* Manual selection remains available. */
      }
      if (!_manager || epoch != _epoch) return;
      state = state.copyWith(
        locating: false,
        draft: revision == _pointRevision && point != null
            ? state.draft.copyWith(point: point)
            : state.draft,
      );
      return;
    }
    try {
      final repo = ref.read(placesRepositoryProvider(key.$1));
      final cached = (await repo.read()).places
          .where((p) => p.id == key.$2)
          .firstOrNull;
      if (!_manager || epoch != _epoch) return;
      if (cached != null) {
        state = state.copyWith(draft: _draft(cached), loading: false);
      }
      try {
        await repo.refresh();
        if (!_manager || epoch != _epoch) return;
        final fresh = (await repo.read()).places
            .where((p) => p.id == key.$2)
            .firstOrNull;
        if (!_manager || epoch != _epoch) return;
        state = state.copyWith(
          loading: false,
          missing: fresh == null,
          draft: !_dirty && fresh != null ? _draft(fresh) : state.draft,
        );
      } catch (error) {
        if (_current && epoch == _epoch) {
          state = state.copyWith(
            loading: false,
            offline: true,
            missing:
                cached == null ||
                (error is ApiFailure && error.statusCode == 404),
          );
        }
      }
    } catch (_) {
      if (_current && epoch == _epoch) {
        state = state.copyWith(loading: false, missing: true, offline: true);
      }
    }
  }

  void change({String? name, PlacePoint? point, int? radiusM}) {
    if (!_manager ||
        state.loading ||
        state.busy ||
        state.acknowledged ||
        state.missing ||
        state.uncertain) {
      return;
    }
    if (point != null && !point.valid) return;
    if (radiusM != null &&
        (radiusM < 50 || radiusM > 500 || radiusM % 10 != 0)) {
      return;
    }
    if (point != null) ++_pointRevision;
    _dirty = true;
    state = state.copyWith(
      draft: state.draft.copyWith(name: name, point: point, radiusM: radiusM),
      clearFailure: true,
    );
  }

  Future<bool> write({bool delete = false}) async {
    if (!_current ||
        (_receipt == null && !_manager) ||
        state.loading ||
        state.busy ||
        state.uncertain ||
        (_receipt == null &&
            (state.missing ||
                (!delete && !state.draft.valid) ||
                (delete && key.$2 == null)))) {
      return false;
    }
    ++_epoch;
    state = state.copyWith(busy: true, locating: false, clearFailure: true);
    try {
      final repo = ref.read(placesRepositoryProvider(key.$1));
      _receipt ??= delete
          ? await repo.remove(key.$2!)
          : await repo.save(state.draft, id: key.$2);
      if (!_current) return false;
      state = state.copyWith(acknowledged: true);
      await repo.cacheReceipt(_receipt!);
      if (!_current) return false;
      state = state.copyWith(busy: false);
      return true;
    } catch (error) {
      if (_current) {
        final failure = error is ApiFailure
            ? error
            : ApiFailure(ApiFailureKind.invalidResponse);
        final definitive =
            failure.kind == ApiFailureKind.server &&
            failure.statusCode != null &&
            failure.statusCode! < 500;
        final gone = failure.statusCode == 404;
        state = state.copyWith(
          busy: false,
          acknowledged: _receipt != null,
          failure: failure,
          missing: gone,
          uncertain: _receipt == null && !definitive,
        );
      }
      return false;
    }
  }
}
