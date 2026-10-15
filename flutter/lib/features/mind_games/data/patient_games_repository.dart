import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart' hide PatientGameScore;
import '../../patient_today/domain/patient_today_data.dart';
import '../domain/patient_games_data.dart';

class PatientGamesRepository {
  PatientGamesRepository(
    this.client,
    this.db,
    this.key,
    this.clock, {
    required this.current,
  });
  final ApiClient client;
  final RemoriDatabase db;
  final PatientTodayKey key;
  final DateTime Function() clock;
  final bool Function() current;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _generation = 0;
  bool get _active => !_disposed && current();
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  Future<void> refresh() async {
    if (!_active) return;
    final generation = ++_generation;
    final scores = <String, PatientGameScore>{};
    for (final type in patientGameTypes) {
      if (!_active || generation != _generation) return;
      final response = await client.request<dynamic>(
        '/patients/${key.$1}/mind-game-sessions',
        credential: ApiCredential.device,
        queryParameters: {'game_type': type, 'limit': 1, 'offset': 0},
        cancelToken: _cancel,
      );
      final rows = response.data;
      if (response.statusCode != 200 || rows is! List || rows.length > 1) {
        throw _invalid;
      }
      if (rows.isEmpty) continue;
      final p = rows.single;
      if (p is! Map ||
          p['patient_id'] != key.$1 ||
          p['game_type'] != type ||
          p['id'] is! String ||
          (p['id'] as String).trim().isEmpty) {
        throw _invalid;
      }
      final score = p['score'],
          duration = p['duration_seconds'],
          at = p['completed_at'];
      final completed = at is String ? DateTime.tryParse(at) : null;
      if (score is! int ||
          score < 0 ||
          score > 100000 ||
          duration is! int ||
          duration < 0 ||
          duration > 14400 ||
          completed == null ||
          !completed.isUtc) {
        throw _invalid;
      }
      scores[type] = PatientGameScore(
        p['id'] as String,
        type,
        score,
        duration,
        completed,
      );
    }
    if (!_active || generation != _generation) return;
    await db.transaction(() async {
      if (!_active || generation != _generation) return;
      await (db.delete(db.patientGameScores)..where(
            (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
          ))
          .go();
      for (final s in scores.values) {
        await db
            .into(db.patientGameScores)
            .insert(
              PatientGameScoresCompanion.insert(
                patientId: key.$1,
                deviceId: key.$2,
                gameType: s.type,
                sessionId: s.id,
                score: s.score,
                durationSeconds: s.durationSeconds,
                completedAt: s.completedAt,
              ),
            );
      }
      for (final type in patientGameTypes) {
        await db
            .into(db.patientGameRefreshes)
            .insert(
              PatientGameRefreshesCompanion.insert(
                patientId: key.$1,
                deviceId: key.$2,
                gameType: type,
                refreshedAt: clock(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  Stream<PatientGamesData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.patientGameScores,
          db.patientGameRefreshes,
          db.patientGameSessions,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<PatientGamesData> read() => db.transaction(() async {
    final scores =
        await (db.select(db.patientGameScores)..where(
              (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
            ))
            .get();
    final states =
        await (db.select(db.patientGameRefreshes)..where(
              (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
            ))
            .get();
    final local =
        await (db.select(db.patientGameSessions)
              ..where(
                (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.completedAt)])
              ..limit(1))
            .getSingleOrNull();
    final latest = scores.where((r) => r.gameType == 'face_match').firstOrNull;
    return PatientGamesData(
      scores: {
        for (final r in scores)
          r.gameType: PatientGameScore(
            r.sessionId,
            r.gameType,
            r.score,
            r.durationSeconds,
            r.completedAt,
          ),
        if (local != null &&
            (latest == null || !local.completedAt.isBefore(latest.completedAt)))
          'face_match': PatientGameScore(
            local.id,
            'face_match',
            local.score,
            local.durationSeconds,
            local.completedAt,
          ),
      },
      refreshed: states.map((r) => r.gameType).toSet(),
    );
  });
}
