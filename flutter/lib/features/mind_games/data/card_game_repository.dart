import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../../patient_today/domain/patient_today_data.dart';
import '../domain/card_game.dart';

class CardGameRepository {
  CardGameRepository(
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
  bool _disposed = false, _uploading = false;
  int _generation = 0;
  bool get _active => !_disposed && current();
  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String newId() => db.newRecordId();
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  Future<void> refreshPeople() async {
    if (!_active) return;
    final generation = ++_generation, started = clock();
    final response = await client.request<dynamic>(
      '/patients/${key.$1}/people',
      credential: ApiCredential.device,
      queryParameters: {'status': 'active'},
      cancelToken: _cancel,
    );
    final rows = response.data;
    if (response.statusCode != 200 || rows is! List) throw _invalid;
    final people = <GamePerson>[], ids = <String>{};
    for (final row in rows) {
      if (row is! Map ||
          row['patient_id'] != key.$1 ||
          row['status'] != 'active' ||
          row['id'] is! String ||
          (row['id'] as String).trim().isEmpty ||
          !ids.add(row['id'] as String) ||
          row['name'] is! String ||
          (row['name'] as String).trim().isEmpty) {
        throw _invalid;
      }
      final url = row['photo_url'];
      if (url == null) continue;
      final uri = url is String ? Uri.tryParse(url) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment) {
        throw _invalid;
      }
      people.add(
        GamePerson(
          row['id'] as String,
          row['name'] as String,
          url as String,
          started.add(const Duration(minutes: 10)),
        ),
      );
    }
    if (!_active || generation != _generation) return;
    await db.transaction(() async {
      if (!_active || generation != _generation) return;
      await (db.delete(db.patientGamePeople)..where(
            (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
          ))
          .go();
      for (final p in people) {
        await db
            .into(db.patientGamePeople)
            .insert(
              PatientGamePeopleCompanion.insert(
                patientId: key.$1,
                deviceId: key.$2,
                id: p.id,
                name: p.name,
                photoUrl: p.url,
                validUntil: p.validUntil,
                refreshedAt: clock(),
              ),
            );
      }
    });
  }

  Future<List<GamePerson>> people() async =>
      (await (db.select(db.patientGamePeople)
                ..where(
                  (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.id)]))
              .get())
          .map((r) => GamePerson(r.id, r.name, r.photoUrl, r.validUntil))
          .toList();
  Future<GameSession?> session(String id) async {
    final r =
        await (db.select(db.patientGameSessions)..where(
              (r) =>
                  r.patientId.equals(key.$1) &
                  r.deviceId.equals(key.$2) &
                  r.id.equals(id),
            ))
            .getSingleOrNull();
    return r == null
        ? null
        : GameSession(r.id, r.score, r.durationSeconds, r.completedAt);
  }

  Stream<GameSession?> watchSession(String id) => db
      .customSelect('SELECT 1', readsFrom: {db.patientGameSessions})
      .watch()
      .asyncMap((_) => session(id));
  Future<bool> complete(GameSession value) async {
    if (!_active ||
        value.score < 0 ||
        value.score > 2 ||
        value.seconds < 0 ||
        value.seconds > 14400) {
      return false;
    }
    return db.transaction(() async {
      if (!_active) return false;
      final old = await session(value.id);
      if (old != null) {
        return old.score == value.score &&
            old.seconds == value.seconds &&
            old.completedAt == value.completedAt;
      }
      await db.writeAndEnqueue(
        patientId: key.$1,
        kind: OutboxKind.gameSession,
        payload: value.payload(),
        writeLocal: () => db
            .into(db.patientGameSessions)
            .insert(
              PatientGameSessionsCompanion.insert(
                patientId: key.$1,
                deviceId: key.$2,
                id: value.id,
                score: value.score,
                durationSeconds: value.seconds,
                completedAt: value.completedAt,
              ),
            ),
      );
      return true;
    });
  }

  Future<void> upload() async {
    if (!_active || _uploading) return;
    _uploading = true;
    try {
      final sessions =
          await (db.select(db.patientGameSessions)..where(
                (r) => r.patientId.equals(key.$1) & r.deviceId.equals(key.$2),
              ))
              .get();
      final ids = sessions.map((r) => r.id).toSet();
      final pending =
          await (db.select(db.outboxEntries)
                ..where(
                  (r) =>
                      r.patientId.equals(key.$1) &
                      r.kind.equalsValue(OutboxKind.gameSession) &
                      r.recordId.isIn(ids),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.sequence)])
                ..limit(500))
              .get();
      for (final op in pending) {
        if (!_active) return;
        final payload = jsonDecode(op.payload) as Map;
        final response = await client.request<dynamic>(
          '/patients/${key.$1}/mind-game-sessions',
          method: 'POST',
          credential: ApiCredential.device,
          data: payload,
          cancelToken: _cancel,
        );
        final p = response.data;
        if (response.statusCode != 201 ||
            p is! Map ||
            p['patient_id'] != key.$1 ||
            p['id'] != payload['id'] ||
            p['game_type'] != 'face_match' ||
            p['score'] != payload['score'] ||
            p['duration_seconds'] != payload['duration_seconds'] ||
            p['completed_at'] is! String ||
            DateTime.tryParse(p['completed_at'] as String) !=
                DateTime.tryParse(payload['completed_at'] as String)) {
          throw _invalid;
        }
        if (_active) await db.acknowledge(key.$1, [op.id]);
      }
    } finally {
      _uploading = false;
    }
  }
}
