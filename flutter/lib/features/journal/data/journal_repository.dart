import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/journal_data.dart';

class JournalRepository {
  JournalRepository(this.client, this.db, this.key);
  final ApiClient client;
  final RemoriDatabase db;
  final JournalKey key;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _generation = 0;
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

  String _url(Object? v) {
    final uri = v is String ? Uri.tryParse(v) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw _invalid;
    }
    return v as String;
  }

  Map<String, Object?> _entry(Map p) {
    final occurred = _time(p, 'occurred_at'),
        ended = p['ended_at'] == null ? null : _time(p, 'ended_at');
    if (PatientTime.day(occurred, key.$1.timezone) != key.$2 ||
        (ended != null && ended.isBefore(occurred))) {
      throw _invalid;
    }
    Map<String, Object?>? person, document;
    if (p['person'] != null) {
      if (p['person'] is! Map) throw _invalid;
      final r = p['person'] as Map;
      person = {
        'id': _text(r, 'id'),
        'name': _text(r, 'name'),
        'relationship': _text(r, 'relationship'),
      };
    }
    if (p['document'] != null) {
      if (p['document'] is! Map) throw _invalid;
      final r = p['document'] as Map;
      document = {
        'id': _text(r, 'id'),
        'document_type': _text(r, 'document_type'),
        'title': _optional(r, 'title'),
        'headline': _optional(r, 'headline'),
      };
    }
    return {
      'id': _text(p, 'id'),
      'event_type': _text(p, 'event_type'),
      'source': _text(p, 'source'),
      'occurred_at': occurred.toIso8601String(),
      'ended_at': ended?.toIso8601String(),
      'person': person,
      'document': document,
      'transcript_text': _optional(p, 'transcript_text'),
      'language': _optional(p, 'language'),
      'rendered_text': _optional(p, 'rendered_text'),
    };
  }

  Map<String, Object?> _media(Map p) {
    final type = _text(p, 'asset_type'),
        status = _text(p, 'status'),
        duration = p['duration_seconds'];
    if (!{'image', 'video'}.contains(type) ||
        !{'pending_review', 'confirmed'}.contains(status) ||
        (duration != null && (duration is! int || duration < 0))) {
      throw _invalid;
    }
    Map<String, Object?>? tags;
    if (p['ai_tags'] != null) {
      if (p['ai_tags'] is! Map) throw _invalid;
      final r = p['ai_tags'] as Map, values = r['tags'];
      if (values is! List || values.any((v) => v is! String)) throw _invalid;
      tags = {
        'category': _optional(r, 'category'),
        'tags': List<String>.from(values),
        'reason': _optional(r, 'reason'),
      };
    }
    return {
      'id': _text(p, 'id'),
      'asset_type': type,
      'trigger': _text(p, 'trigger'),
      'status': status,
      'url': _url(p['url']),
      'thumbnail_url': p['thumbnail_url'] == null
          ? null
          : _url(p['thumbnail_url']),
      'duration_seconds': duration,
      'expires_at': p['expires_at'] == null
          ? null
          : _time(p, 'expires_at').toIso8601String(),
      'ai_tags': tags,
    };
  }

  Expression<bool> _entries(CachedJournalEntries r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.day.equals(key.$2);
  Expression<bool> _photos(CachedJournalMedia r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.day.equals(key.$2);
  Expression<bool> _states(JournalCacheStates r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.day.equals(key.$2);
  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final response = await client.request<dynamic>(
        '/patients/${key.$1.patientId}/journal',
        credential: ApiCredential.caregiver,
        queryParameters: {'date': key.$2},
        cancelToken: _cancel,
      );
      final body = response.data;
      if (response.statusCode != 200 ||
          body is! Map ||
          body['date'] != key.$2 ||
          body['timezone'] != key.$1.timezone ||
          body['entries'] is! List) {
        throw _invalid;
      }
      final entries = <CachedJournalEntriesCompanion>[],
          media = <CachedJournalMediaCompanion>[],
          ids = <String>{},
          photoIds = <String>{};
      for (final raw in body['entries'] as List) {
        if (raw is! Map) throw _invalid;
        if (raw.containsKey('patient_id') &&
            raw['patient_id'] != key.$1.patientId) {
          throw _invalid;
        }
        final entry = _entry(raw), id = entry['id'] as String;
        if (!ids.add(id) || raw['media'] is! List) throw _invalid;
        entries.add(
          CachedJournalEntriesCompanion.insert(
            caregiverId: key.$1.caregiverId,
            patientId: key.$1.patientId,
            day: key.$2,
            id: id,
            occurredAt: DateTime.parse(entry['occurred_at'] as String),
            payload: jsonEncode(entry),
          ),
        );
        final photos = raw['media'] as List;
        for (var i = 0; i < photos.length; i++) {
          if (photos[i] is! Map) throw _invalid;
          final p = _media(photos[i] as Map), photoId = p['id'] as String;
          if (!photoIds.add(photoId)) throw _invalid;
          media.add(
            CachedJournalMediaCompanion.insert(
              caregiverId: key.$1.caregiverId,
              patientId: key.$1.patientId,
              day: key.$2,
              id: photoId,
              eventId: id,
              payload: jsonEncode(p),
              position: i,
            ),
          );
        }
      }
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        await (db.delete(db.cachedJournalEntries)..where(_entries)).go();
        await (db.delete(db.cachedJournalMedia)..where(_photos)).go();
        for (final r in entries) {
          await db.into(db.cachedJournalEntries).insert(r);
        }
        for (final r in media) {
          await db.into(db.cachedJournalMedia).insert(r);
        }
        await db
            .into(db.journalCacheStates)
            .insert(
              JournalCacheStatesCompanion.insert(
                caregiverId: key.$1.caregiverId,
                patientId: key.$1.patientId,
                day: key.$2,
                timezone: key.$1.timezone,
                refreshedAt: DateTime.now().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
    } on ApiFailure catch (error) {
      if (error.statusCode == 404 && error.code == 'PATIENT_NOT_FOUND') {
        await purge();
      }
      rethrow;
    }
  }

  Future<void> purge() {
    ++_generation;
    return db.transaction(() async {
      await (db.delete(db.cachedMediaDetails)..where(
            (r) =>
                r.caregiverId.equals(key.$1.caregiverId) &
                r.patientId.equals(key.$1.patientId),
          ))
          .go();
      await (db.delete(db.cachedJournalEntries)..where(
            (r) =>
                r.caregiverId.equals(key.$1.caregiverId) &
                r.patientId.equals(key.$1.patientId),
          ))
          .go();
      await (db.delete(db.cachedJournalMedia)..where(
            (r) =>
                r.caregiverId.equals(key.$1.caregiverId) &
                r.patientId.equals(key.$1.patientId),
          ))
          .go();
      await (db.delete(db.journalCacheStates)..where(
            (r) =>
                r.caregiverId.equals(key.$1.caregiverId) &
                r.patientId.equals(key.$1.patientId),
          ))
          .go();
    });
  }

  Stream<JournalData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedJournalEntries,
          db.cachedJournalMedia,
          db.journalCacheStates,
        },
      )
      .watch()
      .asyncMap((_) => read());
  JournalMedia _decodeMedia(Map p) => JournalMedia(
    id: p['id'],
    type: p['asset_type'],
    trigger: p['trigger'],
    status: p['status'],
    url: p['url'],
    thumbnailUrl: p['thumbnail_url'],
    durationSeconds: p['duration_seconds'],
    expiresAt: p['expires_at'] == null ? null : DateTime.parse(p['expires_at']),
    category: p['ai_tags']?['category'],
    tags: List<String>.from(p['ai_tags']?['tags'] ?? []),
    reason: p['ai_tags']?['reason'],
  );
  Future<JournalData> read() => db.transaction(() async {
    final state = await (db.select(
      db.journalCacheStates,
    )..where(_states)).getSingleOrNull();
    if (state == null || state.timezone != key.$1.timezone) {
      return const JournalData();
    }
    final entries =
        await (db.select(db.cachedJournalEntries)
              ..where(_entries)
              ..orderBy([
                (r) => OrderingTerm.asc(r.occurredAt),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final media =
        await (db.select(db.cachedJournalMedia)
              ..where(_photos)
              ..orderBy([(r) => OrderingTerm.asc(r.position)]))
            .get();
    return JournalData(
      refreshedAt: state.refreshedAt,
      entries: [
        for (final row in entries)
          (() {
            final p = jsonDecode(row.payload) as Map,
                person = p['person'],
                doc = p['document'];
            return JournalEntry(
              id: p['id'],
              type: p['event_type'],
              source: p['source'],
              occurredAt: row.occurredAt,
              endedAt: p['ended_at'] == null
                  ? null
                  : DateTime.parse(p['ended_at']),
              person: person == null
                  ? null
                  : JournalPerson(
                      person['id'],
                      person['name'],
                      person['relationship'],
                    ),
              transcript: p['transcript_text'],
              language: p['language'],
              renderedText: p['rendered_text'],
              document: doc == null
                  ? null
                  : JournalDocument(
                      doc['id'],
                      doc['document_type'],
                      doc['title'],
                      doc['headline'],
                    ),
              media: [
                for (final m in media.where((m) => m.eventId == row.id))
                  _decodeMedia(jsonDecode(m.payload) as Map),
              ],
            );
          })(),
      ],
    );
  });
}
