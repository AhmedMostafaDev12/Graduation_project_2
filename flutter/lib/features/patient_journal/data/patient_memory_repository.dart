import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart' hide PatientMemoryDetail;
import '../domain/patient_journal_data.dart';
import '../domain/patient_memory_detail.dart';

class PatientMemoryRepository {
  PatientMemoryRepository(
    this.client,
    this.db,
    this.target,
    this.clock, {
    required this.current,
  });
  final ApiClient client;
  final RemoriDatabase db;
  final PatientMemoryTarget target;
  final DateTime Function() clock;
  final bool Function() current;
  final _cancel = CancelToken();
  bool _disposed = false, _deleted = false;
  bool get deleted => _deleted;
  int _generation = 0;
  bool get _active => !_disposed && current();
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  ApiFailure get _missing => ApiFailure(
    ApiFailureKind.server,
    statusCode: 404,
    code: 'MEDIA_NOT_FOUND',
  );
  String _text(Map p, String k) {
    final v = p[k];
    if (v is! String || v.trim().isEmpty) throw _invalid;
    return v;
  }

  String? _optional(Map p, String k) {
    final v = p[k];
    if (v != null && v is! String) throw _invalid;
    return v as String?;
  }

  DateTime _time(Map p, String k) {
    final v = DateTime.tryParse(_text(p, k));
    if (v == null || !v.isUtc) throw _invalid;
    return v;
  }

  Expression<bool> _row(PatientMemoryDetails r) =>
      r.patientId.equals(target.journal.$1.$1) &
      r.deviceId.equals(target.journal.$1.$2) &
      r.id.equals(target.mediaId);
  Future<bool> _source() async =>
      await (db.select(db.patientJournalMedia)..where(
            (r) =>
                r.patientId.equals(target.journal.$1.$1) &
                r.deviceId.equals(target.journal.$1.$2) &
                r.day.equals(target.journal.$2) &
                r.id.equals(target.mediaId) &
                r.eventId.equals(target.eventId),
          ))
          .getSingleOrNull() !=
      null;
  Future<void> refresh() async {
    if (!_active || _deleted) return;
    if (!await _source()) throw _missing;
    if (!_active || _deleted) return;
    final generation = ++_generation, started = clock();
    try {
      final response = await client.request<dynamic>(
        '/patients/${target.journal.$1.$1}/media/${target.mediaId}',
        credential: ApiCredential.device,
        cancelToken: _cancel,
      );
      final p = response.data;
      if (response.statusCode != 200 ||
          p is! Map ||
          p['id'] != target.mediaId ||
          p['patient_id'] != target.journal.$1.$1 ||
          p['event_id'] != target.eventId) {
        throw _invalid;
      }
      final type = _text(p, 'asset_type'),
          status = _text(p, 'status'),
          retention = _optional(p, 'retention_policy'),
          seconds = p['url_expires_in'],
          duration = p['duration_seconds'];
      if (!{'image', 'video'}.contains(type) ||
          !{'confirmed', 'pending_review'}.contains(status) ||
          (retention != null &&
              !{'keep_indefinitely', 'auto_expire'}.contains(retention)) ||
          seconds is! int ||
          seconds <= 0 ||
          (duration != null && (duration is! int || duration < 0))) {
        throw _invalid;
      }
      final url = _text(p, 'url'), uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment) {
        throw _invalid;
      }
      Map<String, Object?>? event;
      if (p['event'] != null) {
        if (p['event'] is! Map) throw _invalid;
        final e = p['event'] as Map;
        if (e['id'] != target.eventId) throw _invalid;
        Map<String, Object?>? person;
        if (e['person'] != null) {
          if (e['person'] is! Map) throw _invalid;
          final r = e['person'] as Map;
          person = {
            'id': _text(r, 'id'),
            'name': _text(r, 'name'),
            'relationship': _optional(r, 'relationship'),
          };
        }
        event = {
          'event_type': _text(e, 'event_type'),
          'occurred_at': _time(e, 'occurred_at').toIso8601String(),
          'person': person,
        };
      }
      final payload = {
        'event_id': target.eventId,
        'asset_type': type,
        'status': status,
        'retention_policy': retention,
        'expires_at': p['expires_at'] == null
            ? null
            : _time(p, 'expires_at').toIso8601String(),
        'duration_seconds': duration,
        'created_at': _time(p, 'created_at').toIso8601String(),
        'url': url,
        'valid_until': started
            .add(Duration(seconds: seconds.clamp(1, 600)))
            .toIso8601String(),
        'event': event,
      };
      if (!_active || _deleted || generation != _generation) return;
      await db.transaction(() async {
        if (!_active ||
            _deleted ||
            generation != _generation ||
            !await _source()) {
          return;
        }
        await db
            .into(db.patientMemoryDetails)
            .insert(
              PatientMemoryDetailsCompanion.insert(
                patientId: target.journal.$1.$1,
                deviceId: target.journal.$1.$2,
                id: target.mediaId,
                payload: jsonEncode(payload),
                refreshedAt: clock(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
    } on ApiFailure catch (e) {
      if (_active && generation == _generation && e.statusCode == 404) {
        _deleted = true;
        ++_generation;
        await cacheDeletion();
      }
      rethrow;
    }
  }

  Future<void> remove() async {
    if (!_active || _deleted || !await _source()) throw _missing;
    if (!_active || _deleted) throw _missing;
    final response = await client.request<dynamic>(
      '/media/${target.mediaId}',
      method: 'DELETE',
      credential: ApiCredential.device,
      cancelToken: _cancel,
    );
    if (response.statusCode != 204) throw _invalid;
    _deleted = true;
    ++_generation;
  }

  Future<void> cacheDeletion() async {
    ++_generation;
    await db.transaction(() async {
      await (db.delete(db.patientMemoryDetails)..where(_row)).go();
      await (db.delete(db.patientJournalMedia)..where(
            (r) =>
                r.patientId.equals(target.journal.$1.$1) &
                r.deviceId.equals(target.journal.$1.$2) &
                r.id.equals(target.mediaId),
          ))
          .go();
    });
  }

  Stream<PatientMemoryDetail?> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.patientMemoryDetails, db.patientJournalMedia},
      )
      .watch()
      .asyncMap((_) => read());
  Future<PatientMemoryDetail?> read() => db.transaction(() async {
    if (!await _source()) return null;
    final row = await (db.select(
      db.patientMemoryDetails,
    )..where(_row)).getSingleOrNull();
    if (row == null) return null;
    final p = jsonDecode(row.payload) as Map;
    if (p['event_id'] != target.eventId) return null;
    final e = p['event'] as Map?, person = e?['person'] as Map?;
    return PatientMemoryDetail(
      id: target.mediaId,
      eventId: target.eventId,
      type: p['asset_type'] as String,
      status: p['status'] as String,
      retention: p['retention_policy'] as String?,
      durationSeconds: p['duration_seconds'] as int?,
      expiresAt: p['expires_at'] == null
          ? null
          : DateTime.parse(p['expires_at'] as String),
      at: DateTime.parse((e?['occurred_at'] ?? p['created_at']) as String),
      eventType: e?['event_type'] as String?,
      person: person == null
          ? null
          : JournalPerson(
              person['id'] as String,
              person['name'] as String,
              person['relationship'] as String? ?? '',
            ),
      url: p['url'] as String,
      validUntil: DateTime.parse(p['valid_until'] as String),
      refreshedAt: row.refreshedAt,
    );
  });
}
