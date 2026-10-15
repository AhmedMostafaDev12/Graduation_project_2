import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/database_providers.dart';
import '../../patient_today/domain/patient_today_data.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../data/patient_games_repository.dart';
import '../domain/patient_games_data.dart';

final patientGamesRepositoryProvider = Provider.autoDispose
    .family<PatientGamesRepository, PatientTodayKey>((ref, key) {
      final repo = PatientGamesRepository(
        ref.watch(apiClientProvider),
        ref.watch(databaseProvider),
        key,
        ref.watch(patientTodayClockProvider),
        current: () => ref.mounted && ref.read(patientTodayKeyProvider) == key,
      );
      ref.onDispose(repo.dispose);
      return repo;
    });
final patientGamesDataProvider = StreamProvider.autoDispose
    .family<PatientGamesData, PatientTodayKey>(
      (ref, key) => ref.watch(patientGamesRepositoryProvider(key)).watch(),
    );

class PatientGamesState {
  const PatientGamesState({this.busy = false, this.failed = false});
  final bool busy, failed;
}

final patientGamesControllerProvider = NotifierProvider.autoDispose
    .family<PatientGamesController, PatientGamesState, PatientTodayKey>(
      PatientGamesController.new,
    );

class PatientGamesController extends Notifier<PatientGamesState> {
  PatientGamesController(this.key);
  final PatientTodayKey key;
  bool get _current => ref.mounted && ref.read(patientTodayKeyProvider) == key;
  @override
  PatientGamesState build() {
    Future.microtask(() {
      if (_current) refresh();
    });
    return const PatientGamesState();
  }

  Future<void> refresh() async {
    if (!_current || state.busy) return;
    state = const PatientGamesState(busy: true);
    try {
      await ref.read(patientGamesRepositoryProvider(key)).refresh();
      if (_current) state = const PatientGamesState();
    } catch (_) {
      if (_current) state = const PatientGamesState(failed: true);
    }
  }
}
