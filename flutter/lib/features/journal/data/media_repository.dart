import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/journal_data.dart';
import '../domain/media_detail.dart';

class MediaRepository {
  MediaRepository(this.client, this.db, this.key, this.clock);
  final ApiClient client;
  final RemoriDatabase db;
  final MediaKey key;
  final DateTime Function() clock;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _generation = 0;
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
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

  String _time(Map p, String k) {
    final v = DateTime.tryParse(_text(p, k));
    if (v == null || !v.isUtc) throw _invalid;
    return v.toIso8601String();
  }

  Map<String, Object?> _fields(Map p) {
    final type = _text(p, 'asset_type'),
        status = _text(p, 'status'),
        retention = _optional(p, 'retention_policy'),
        duration = p['duration_seconds'],
        people = p['contains_other_people'];
    if (p['id'] != key.$2 ||
        p['patient_id'] != key.$1.patientId ||
        !{'image', 'video'}.contains(type) ||
        !{'confirmed', 'pending_review'}.contains(status) ||
        (retention != null &&
            !{'auto_expire', 'keep_indefinitely'}.contains(retention)) ||
        (duration != null && (duration is! int || duration < 0)) ||
        (people != null && people is! bool)) {
      throw _invalid;
    }
    Map<String, Object?>? tags;
    if (p['ai_tags'] != null) {
      if (p['ai_tags'] is! Map) throw _invalid;
      final t = p['ai_tags'] as Map;
      if (t['tags'] is! List || (t['tags'] as List).any((v) => v is! String)) {
        throw _invalid;
      }
      tags = {
        'category': _optional(t, 'category'),
        'tags': List<String>.from(t['tags']),
        'reason': _optional(t, 'reason'),
      };
    }
    return {
      'id': key.$2,
      'patient_id': key.$1.patientId,
      'event_id': _text(p, 'event_id'),
      'asset_type': type,
      'trigger': _text(p, 'trigger'),
      'status': status,
      'retention_policy': retention,
      'expires_at': p['expires_at'] == null ? null : _time(p, 'expires_at'),
      'pinned_by': _optional(p, 'pinned_by'),
      'contains_other_people': people,
      'duration_seconds': duration,
      'created_at': _time(p, 'created_at'),
      'ai_tags': tags,
    };
  }

  Map<String, Object?> _view(Map p) {
    final fields = _fields(p),
        url = _text(p, 'url'),
        seconds = p['url_expires_in'];
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        seconds is! int ||
        seconds <= 0) {
      throw _invalid;
    }
    Map<String, Object?>? event;
    if (p['event'] != null) {
      if (p['event'] is! Map) throw _invalid;
      final e = p['event'] as Map;
      if (e['id'] != fields['event_id']) throw _invalid;
      Map<String, Object?>? person;
      if (e['person'] != null) {
        if (e['person'] is! Map) throw _invalid;
        final t = e['person'] as Map;
        person = {
          'id': _text(t, 'id'),
          'name': _text(t, 'name'),
          'relationship': _text(t, 'relationship'),
        };
      }
      event = {
        'id': e['id'],
        'event_type': _text(e, 'event_type'),
        'occurred_at': _time(e, 'occurred_at'),
        'person': person,
      };
    }
    return {
      ...fields,
      'url': url,
      'url_valid_until': clock()
          .toUtc()
          .add(Duration(seconds: seconds))
          .toIso8601String(),
      'event': event,
    };
  }

  Expression<bool> _row(CachedMediaDetails r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.id.equals(key.$2);
  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final response = await client.request<dynamic>(
        '/patients/${key.$1.patientId}/media/${key.$2}',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 || response.data is! Map) throw _invalid;
      final payload = _view(response.data as Map);
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        await db
            .into(db.cachedMediaDetails)
            .insert(
              CachedMediaDetailsCompanion.insert(
                caregiverId: key.$1.caregiverId,
                patientId: key.$1.patientId,
                id: key.$2,
                payload: jsonEncode(payload),
                refreshedAt: clock().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
    } on ApiFailure catch (e) {
      await _missing(e);
      rethrow;
    }
  }

  Future<void> _missing(ApiFailure e) async {
    if (e.statusCode != 404) return;
    if (e.code == 'MEDIA_NOT_FOUND') {
      await cacheReceipt(const MediaReceipt(deleted: true));
    } else if (e.code == 'PATIENT_NOT_FOUND') {
      ++_generation;
      await db.transaction(() async {
        await (db.delete(db.cachedConsents)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .go();
        await (db.delete(db.cachedDocumentDetails)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .go();
        await (db.delete(db.cachedDocuments)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .go();
        await (db.delete(db.documentsCacheStates)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .go();
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
  }

  Future<MediaReceipt> write({required bool delete}) async {
    try {
      final response = await client.request<dynamic>(
        '/media/${key.$2}${delete ? '' : '/pin'}',
        method: delete ? 'DELETE' : 'POST',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (delete) {
        if (response.statusCode != 204) throw _invalid;
        return const MediaReceipt(deleted: true);
      }
      if (response.statusCode != 200 || response.data is! Map) throw _invalid;
      final fields = _fields(response.data as Map);
      if (fields['retention_policy'] != 'keep_indefinitely' ||
          fields['expires_at'] != null) {
        throw _invalid;
      }
      return MediaReceipt(deleted: false, payload: fields);
    } on ApiFailure catch (e) {
      await _missing(e);
      rethrow;
    }
  }

  Future<void> cacheReceipt(MediaReceipt receipt) {
    ++_generation;
    return db.transaction(() async {
      if (receipt.deleted) {
        await (db.delete(db.cachedMediaDetails)..where(_row)).go();
        await (db.delete(db.cachedDocumentDetails)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId) &
                  r.mediaAssetId.equals(key.$2),
            ))
            .go();
        await (db.delete(db.cachedDocuments)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId) &
                  r.mediaAssetId.equals(key.$2),
            ))
            .go();
        // A deletion shifts offset pages. Refresh before paging this cache again.
        await (db.update(db.documentsCacheStates)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .write(
              const DocumentsCacheStatesCompanion(
                nextOffset: Value(0),
                hasMore: Value(false),
              ),
            );
      } else {
        final row = await (db.select(
          db.cachedMediaDetails,
        )..where(_row)).getSingleOrNull();
        if (row == null) throw _invalid;
        final previous = jsonDecode(row.payload) as Map<String, dynamic>;
        if (previous['event_id'] != receipt.payload!['event_id']) {
          throw _invalid;
        }
        await (db.update(db.cachedMediaDetails)..where(_row)).write(
          CachedMediaDetailsCompanion(
            payload: Value(jsonEncode({...previous, ...receipt.payload!})),
          ),
        );
      }
      final rows =
          await (db.select(db.cachedJournalMedia)..where(
                (r) =>
                    r.caregiverId.equals(key.$1.caregiverId) &
                    r.patientId.equals(key.$1.patientId) &
                    r.id.equals(key.$2),
              ))
              .get();
      for (final row in rows) {
        final query = (db.delete(db.cachedJournalMedia)
          ..where(
            (r) =>
                r.caregiverId.equals(row.caregiverId) &
                r.patientId.equals(row.patientId) &
                r.day.equals(row.day) &
                r.id.equals(row.id),
          ));
        if (receipt.deleted) {
          await query.go();
        } else {
          final p = jsonDecode(row.payload) as Map<String, dynamic>;
          await (db.update(db.cachedJournalMedia)..where(
                (r) =>
                    r.caregiverId.equals(row.caregiverId) &
                    r.patientId.equals(row.patientId) &
                    r.day.equals(row.day) &
                    r.id.equals(row.id),
              ))
              .write(
                CachedJournalMediaCompanion(
                  payload: Value(
                    jsonEncode({
                      ...p,
                      'expires_at': null,
                      'status': receipt.payload!['status'],
                    }),
                  ),
                ),
              );
        }
      }
    });
  }

  Stream<MediaDetail?> watch() => db
      .customSelect('SELECT 1', readsFrom: {db.cachedMediaDetails})
      .watch()
      .asyncMap((_) => read());
  Future<MediaDetail?> read() async {
    final row = await (db.select(
      db.cachedMediaDetails,
    )..where(_row)).getSingleOrNull();
    if (row == null) return null;
    final p = jsonDecode(row.payload) as Map,
        e = p['event'],
        person = e?['person'],
        tags = p['ai_tags'];
    DateTime? time(String k) => p[k] == null ? null : DateTime.parse(p[k]);
    return MediaDetail(
      id: p['id'],
      patientId: p['patient_id'],
      eventId: p['event_id'],
      type: p['asset_type'],
      trigger: p['trigger'],
      status: p['status'],
      createdAt: DateTime.parse(p['created_at']),
      refreshedAt: row.refreshedAt,
      retention: p['retention_policy'],
      expiresAt: time('expires_at'),
      pinnedBy: p['pinned_by'],
      containsOtherPeople: p['contains_other_people'],
      durationSeconds: p['duration_seconds'],
      url: p['url'],
      urlValidUntil: time('url_valid_until'),
      eventType: e?['event_type'],
      occurredAt: e == null ? null : DateTime.parse(e['occurred_at']),
      person: person == null
          ? null
          : JournalPerson(person['id'], person['name'], person['relationship']),
      category: tags?['category'],
      tags: List<String>.from(tags?['tags'] ?? []),
      reason: tags?['reason'],
    );
  }
}
