import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_journal_data.dart';

class PatientJournalRepository {
  PatientJournalRepository(
    this.client,
    this.db,
    this.key,
    this.clock, {
    required this.current,
  });
  final ApiClient client;
  final RemoriDatabase db;
  final PatientJournalKey key;
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
  String _text(Map p, String field) {
    final v = p[field];
    if (v is! String || v.trim().isEmpty) throw _invalid;
    return v;
  }

  String? _optional(Map p, String field) {
    final v = p[field];
    if (v != null && v is! String) throw _invalid;
    return v as String?;
  }

  DateTime _time(Map p, String field) {
    final v = DateTime.tryParse(_text(p, field));
    if (v == null || !v.isUtc) throw _invalid;
    return v;
  }

  String _url(Object? value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw _invalid;
    }
    return value as String;
  }

  void _ownership(Map p) {
    if (p.containsKey('patient_id') && p['patient_id'] != key.$1.$1) {
      throw _invalid;
    }
  }

  Expression<bool> _entries(PatientJournalEntries r) =>
      r.patientId.equals(key.$1.$1) &
      r.deviceId.equals(key.$1.$2) &
      r.day.equals(key.$2);
  Expression<bool> _media(PatientJournalMedia r) =>
      r.patientId.equals(key.$1.$1) &
      r.deviceId.equals(key.$1.$2) &
      r.day.equals(key.$2);
  Expression<bool> _days(PatientJournalDays r) =>
      r.patientId.equals(key.$1.$1) &
      r.deviceId.equals(key.$1.$2) &
      r.day.equals(key.$2);
  Future<void> refresh() async {
    if (!_active) return;
    final generation = ++_generation;
    final response = await client.request<dynamic>(
      '/patients/${key.$1.$1}/journal',
      credential: ApiCredential.device,
      queryParameters: {'date': key.$2},
      cancelToken: _cancel,
    );
    final body = response.data;
    if (response.statusCode != 200 ||
        body is! Map ||
        body['date'] != key.$2 ||
        body['timezone'] != key.$3 ||
        body['entries'] is! List) {
      throw _invalid;
    }
    _ownership(body);
    final entries = <PatientJournalEntriesCompanion>[],
        media = <PatientJournalMediaCompanion>[],
        ids = <String>{},
        mediaIds = <String>{};
    for (final raw in body['entries'] as List) {
      if (raw is! Map || raw['media'] is! List) throw _invalid;
      _ownership(raw);
      final id = _text(raw, 'id'), at = _time(raw, 'occurred_at');
      if (!ids.add(id) || PatientTime.day(at, key.$3) != key.$2) throw _invalid;
      Map<String, Object?>? person;
      if (raw['person'] != null) {
        if (raw['person'] is! Map) throw _invalid;
        final p = raw['person'] as Map;
        person = {
          'id': _text(p, 'id'),
          'name': _text(p, 'name'),
          'relationship': _optional(p, 'relationship'),
        };
      }
      final entry = {
        'event_type': _text(raw, 'event_type'),
        'person': person,
        'rendered_text': _optional(raw, 'rendered_text'),
      };
      entries.add(
        PatientJournalEntriesCompanion.insert(
          patientId: key.$1.$1,
          deviceId: key.$1.$2,
          day: key.$2,
          id: id,
          occurredAt: at,
          payload: jsonEncode(entry),
        ),
      );
      var position = 0;
      for (final rawMedia in raw['media'] as List) {
        if (rawMedia is! Map) throw _invalid;
        _ownership(rawMedia);
        final mediaId = _text(rawMedia, 'id'),
            type = _text(rawMedia, 'asset_type'),
            status = _text(rawMedia, 'status');
        if (!mediaIds.add(mediaId) ||
            !{'image', 'video'}.contains(type) ||
            !{'pending_review', 'confirmed'}.contains(status)) {
          throw _invalid;
        }
        final payload = {
          'asset_type': type,
          'status': status,
          'url': _url(rawMedia['url']),
          'thumbnail_url': rawMedia['thumbnail_url'] == null
              ? null
              : _url(rawMedia['thumbnail_url']),
          'expires_at': rawMedia['expires_at'] == null
              ? null
              : _time(rawMedia, 'expires_at').toIso8601String(),
        };
        media.add(
          PatientJournalMediaCompanion.insert(
            patientId: key.$1.$1,
            deviceId: key.$1.$2,
            day: key.$2,
            id: mediaId,
            eventId: id,
            position: position++,
            payload: jsonEncode(payload),
          ),
        );
      }
    }
    if (!_active || generation != _generation) return;
    await db.transaction(() async {
      if (!_active || generation != _generation) return;
      await (db.delete(db.patientJournalEntries)..where(_entries)).go();
      await (db.delete(db.patientJournalMedia)..where(_media)).go();
      for (final e in entries) {
        await db.into(db.patientJournalEntries).insert(e);
      }
      for (final m in media) {
        await db.into(db.patientJournalMedia).insert(m);
      }
      await db
          .into(db.patientJournalDays)
          .insert(
            PatientJournalDaysCompanion.insert(
              patientId: key.$1.$1,
              deviceId: key.$1.$2,
              day: key.$2,
              timezone: key.$3,
              refreshedAt: clock(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Stream<PatientJournalData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.patientJournalEntries,
          db.patientJournalMedia,
          db.patientJournalDays,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<PatientJournalData> read() => db.transaction(() async {
    final day = await (db.select(
      db.patientJournalDays,
    )..where(_days)).getSingleOrNull();
    if (day == null || day.timezone != key.$3) {
      return const PatientJournalData();
    }
    final rows =
        await (db.select(db.patientJournalEntries)
              ..where(_entries)
              ..orderBy([
                (r) => OrderingTerm.asc(r.occurredAt),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final photos =
        await (db.select(db.patientJournalMedia)
              ..where(_media)
              ..orderBy([(r) => OrderingTerm.asc(r.position)]))
            .get();
    return PatientJournalData(
      refreshedAt: day.refreshedAt,
      entries: rows.map((r) {
        final p = jsonDecode(r.payload) as Map, person = p['person'] as Map?;
        return JournalEntry(
          id: r.id,
          type: p['event_type'] as String,
          source: '',
          occurredAt: r.occurredAt,
          renderedText: p['rendered_text'] as String?,
          person: person == null
              ? null
              : JournalPerson(
                  person['id'] as String,
                  person['name'] as String,
                  person['relationship'] as String? ?? '',
                ),
          media: photos.where((m) => m.eventId == r.id).map((m) {
            final q = jsonDecode(m.payload) as Map;
            return JournalMedia(
              id: m.id,
              type: q['asset_type'] as String,
              trigger: '',
              status: q['status'] as String,
              url: q['url'] as String,
              thumbnailUrl: q['thumbnail_url'] as String?,
              expiresAt: q['expires_at'] == null
                  ? null
                  : DateTime.parse(q['expires_at'] as String),
            );
          }).toList(),
        );
      }).toList(),
    );
  });
}
