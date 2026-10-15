import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../patient_today/domain/patient_today_data.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../../patient_journal/data/patient_journal_previews.dart';
import '../../journal/domain/journal_data.dart';
import '../data/card_game_repository.dart';
import '../domain/card_game.dart';

final cardGameRepositoryProvider = Provider.autoDispose
    .family<CardGameRepository, PatientTodayKey>((ref, key) {
      final repo = CardGameRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(patientTodayClockProvider),
        current: () => ref.mounted && ref.read(patientTodayKeyProvider) == key,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final cardGameUploadProvider = Provider.autoDispose
    .family<Future<void> Function(), PatientTodayKey>(
      (ref, key) => ref.watch(cardGameRepositoryProvider(key)).upload,
    );
final cardGamePhotosProvider = Provider.autoDispose
    .family<PatientJournalPreviews, PatientTodayKey>((ref, key) {
      final store = NativePatientJournalPreviews((
        key,
        'game',
        '',
      ), ref.watch(patientTodayClockProvider));
      ref.onCancel(store.clear);
      ref.onDispose(store.dispose);
      return store;
    });
final cardGameStopwatchProvider = Provider<Stopwatch Function()>(
  (ref) => Stopwatch.new,
);
final cardGameDecodeProvider = Provider<Future<void> Function(Uint8List)>(
  (ref) => (bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  },
);
final cardGameDeckProvider = Provider<List<int> Function()>(
  (ref) =>
      () => [0, 0, 1, 1]..shuffle(Random()),
);

class CardGameState {
  const CardGameState({
    this.people = const [],
    this.photos = const [],
    this.round,
    this.elapsed = Duration.zero,
    this.busy = false,
    this.ready = false,
    this.failed = false,
    this.needPeople = false,
    this.saveFailed = false,
  });
  final List<GamePerson> people;
  final List<Uint8List> photos;
  final CardRound? round;
  final Duration elapsed;
  final bool busy, ready, failed, needPeople, saveFailed;
}

final cardGameControllerProvider = NotifierProvider.autoDispose
    .family<CardGameController, CardGameState, PatientTodayKey>(
      CardGameController.new,
    );

class CardGameController extends Notifier<CardGameState> {
  CardGameController(this.key);
  final PatientTodayKey key;
  late Stopwatch _watch;
  Timer? _ticker, _mismatch, _expiry;
  int _epoch = 0;
  bool _foreground = true, _recovered = false, _saving = false;
  GameSession? _completion;
  String? _id;
  bool get _current => ref.mounted && ref.read(patientTodayKeyProvider) == key;
  @override
  CardGameState build() {
    try {
      ref.watch(cardGameRepositoryProvider(key));
    } catch (_) {
      /* prepare supplies the localized unavailable state. */
    }
    _watch = ref.read(cardGameStopwatchProvider)();
    final store = ref.watch(cardGamePhotosProvider(key));
    ref.onDispose(() {
      ++_epoch;
      _watch.stop();
      _ticker?.cancel();
      _mismatch?.cancel();
      _expiry?.cancel();
      store.clear();
    });
    Future.microtask(() {
      if (_current && _foreground) prepare();
    });
    return const CardGameState();
  }

  void pause() {
    if (!ref.mounted) return;
    _foreground = false;
    ++_epoch;
    _watch.stop();
    _ticker?.cancel();
    _mismatch?.cancel();
    _expiry?.cancel();
    ref.read(cardGamePhotosProvider(key)).clear();
    state = CardGameState(
      people: state.people,
      round: state.round?.waiting == true
          ? state.round!.hideMismatch()
          : state.round,
      elapsed: _watch.elapsed,
      saveFailed: state.saveFailed,
    );
  }

  Future<void> resume() async {
    if (!_current || _saving) return;
    _foreground = true;
    await prepare();
  }

  Future<void> prepare({bool recovery = false}) async {
    if (!_current || !_foreground || state.busy || _saving) return;
    if (!recovery) _recovered = false;
    final oldPeople = state.people, oldRound = state.round;
    _watch.stop();
    _ticker?.cancel();
    _mismatch?.cancel();
    _expiry?.cancel();
    final epoch = ++_epoch, store = ref.read(cardGamePhotosProvider(key));
    store.clear();
    state = CardGameState(
      people: oldPeople,
      round: oldRound,
      elapsed: _watch.elapsed,
      busy: true,
      saveFailed: _completion != null,
    );
    bool valid() => _current && _foreground && epoch == _epoch;
    try {
      final repo = ref.read(cardGameRepositoryProvider(key));
      await repo.refreshPeople();
      if (!valid()) return;
      final all = await repo.people();
      if (!valid()) return;
      final people = all
          .where(
            (p) => p.validUntil.isAfter(ref.read(patientTodayClockProvider)()),
          )
          .take(2)
          .toList();
      if (people.length < 2) {
        state = CardGameState(needPeople: true, elapsed: _watch.elapsed);
        return;
      }
      final photos = <Uint8List>[];
      for (final p in people) {
        final bytes = await store.load(
          JournalMedia(
            id: p.id,
            type: 'image',
            trigger: '',
            status: 'confirmed',
            url: p.url,
            expiresAt: p.validUntil,
          ),
        );
        if (!valid()) return;
        await ref.read(cardGameDecodeProvider)(bytes);
        if (!valid()) return;
        photos.add(bytes);
      }
      if (!valid()) return;
      final until = people
              .map((p) => p.validUntil)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          now = ref.read(patientTodayClockProvider)();
      if (!until.isAfter(now)) throw const PatientJournalPreviewFailure();
      final same =
          oldRound != null &&
          oldPeople.length == 2 &&
          oldPeople[0].id == people[0].id &&
          oldPeople[1].id == people[1].id;
      if (!same) {
        _watch.reset();
        _completion = null;
        _id = repo.newId();
      }
      final round = same
          ? (oldRound.waiting ? oldRound.hideMismatch() : oldRound)
          : CardRound(ref.read(cardGameDeckProvider)());
      state = CardGameState(
        people: List.unmodifiable(people),
        photos: List.unmodifiable(photos),
        round: round,
        elapsed: _watch.elapsed,
        ready: _completion == null,
        saveFailed: _completion != null,
      );
      if (_completion == null) _watch.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (valid() && state.ready) {
          _put(round: state.round, elapsed: _watch.elapsed);
        }
      });
      _expiry = Timer(until.difference(now), () {
        if (valid()) {
          pause();
          _foreground = true;
          state = CardGameState(
            failed: true,
            people: state.people,
            round: state.round,
            elapsed: _watch.elapsed,
            saveFailed: _completion != null,
          );
        }
      });
    } catch (error) {
      if (!valid()) return;
      store.clear();
      state = CardGameState(
        people: oldPeople,
        round: oldRound,
        elapsed: _watch.elapsed,
        failed: true,
        saveFailed: _completion != null,
      );
      if (error is PatientJournalPreviewFailure &&
          error.status == 403 &&
          !_recovered) {
        _recovered = true;
        await prepare(recovery: true);
      }
    }
  }

  void _put({required CardRound? round, required Duration elapsed}) {
    state = CardGameState(
      people: state.people,
      photos: state.photos,
      round: round,
      elapsed: elapsed,
      ready: state.ready,
      saveFailed: state.saveFailed,
    );
  }

  void pick(int index) {
    if (!_current || !_foreground || !state.ready || _saving) return;
    final round = state.round!.pick(index);
    _put(round: round, elapsed: _watch.elapsed);
    if (round.waiting) {
      _mismatch?.cancel();
      _mismatch = Timer(const Duration(milliseconds: 900), () {
        if (_current && state.ready && identical(state.round, round)) {
          _put(round: round.hideMismatch(), elapsed: _watch.elapsed);
        }
      });
    }
  }

  Future<GameResultTarget?> finish() async {
    if (!_current ||
        !_foreground ||
        _saving ||
        (state.round == null) ||
        (!state.ready && !state.saveFailed)) {
      return null;
    }
    _saving = true;
    _watch.stop();
    _ticker?.cancel();
    _mismatch?.cancel();
    _completion ??= GameSession(
      _id!,
      state.round!.score,
      _watch.elapsed.inSeconds.clamp(0, 14400),
      ref.read(patientTodayClockProvider)(),
    );
    state = CardGameState(
      people: state.people,
      photos: state.photos,
      round: state.round,
      elapsed: _watch.elapsed,
      busy: true,
    );
    try {
      final repo = ref.read(cardGameRepositoryProvider(key));
      if (!await repo.complete(_completion!)) {
        throw StateError('Local save unavailable');
      }
      if (!_current) return null;
      final saved = await repo.session(_completion!.id);
      if (!_current || saved == null) {
        throw StateError('Local save unavailable');
      }
      pause();
      return (scope: key, id: saved.id);
    } catch (_) {
      if (_current) {
        state = CardGameState(
          people: state.people,
          photos: state.photos,
          round: state.round,
          elapsed: _watch.elapsed,
          saveFailed: true,
        );
      }
      return null;
    } finally {
      _saving = false;
    }
  }
}

final gameResultProvider = StreamProvider.autoDispose
    .family<GameSession?, GameResultTarget>((ref, target) {
      if (ref.watch(patientTodayKeyProvider) != target.scope) {
        return Stream.value(null);
      }
      return ref
          .watch(cardGameRepositoryProvider(target.scope))
          .watchSession(target.id);
    });
final gameResultUploadProvider = FutureProvider.autoDispose
    .family<void, GameResultTarget>((ref, target) async {
      if (ref.watch(patientTodayKeyProvider) == target.scope) {
        try {
          await ref.watch(cardGameRepositoryProvider(target.scope)).upload();
        } catch (_) {
          /* The immutable snapshot stays queued. */
        }
      }
    });
