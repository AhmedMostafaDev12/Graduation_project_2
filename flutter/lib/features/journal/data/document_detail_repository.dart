import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/document_detail.dart';

class DocumentDetailRepository {
  DocumentDetailRepository(this.client, this.db, this.key, this.clock);
  final ApiClient client;
  final RemoriDatabase db;
  final DocumentDetailKey key;
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
  ApiFailure get _unavailable => ApiFailure(
    ApiFailureKind.server,
    statusCode: 404,
    code: 'DOCUMENT_NOT_FOUND',
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

  String _time(Map p, String k) {
    final t = DateTime.tryParse(_text(p, k));
    if (t == null || !t.isUtc) throw _invalid;
    return t.toIso8601String();
  }

  bool _date(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final d = DateTime.tryParse(value);
    return d != null && d.toIso8601String().substring(0, 10) == value;
  }

  Map<String, Object?> _parse(Map p) {
    final type = _text(p, 'document_type'),
        rows = p['fields'],
        ocr = p['ocr_text'];
    if (p['id'] != key.$2 ||
        !{'receipt', 'bill', 'medication_label', 'other'}.contains(type) ||
        rows is! List ||
        ocr is! String ||
        (p.containsKey('patient_id') && p['patient_id'] != key.$1.patientId)) {
      throw _invalid;
    }
    final fields = <Map<String, Object?>>[];
    for (final raw in rows) {
      if (raw is! Map) throw _invalid;
      final fieldKey = _optional(raw, 'key'),
          label = _optional(raw, 'label'),
          value = raw['value'],
          kind = _text(raw, 'type');
      if (value is! String ||
          !{'date', 'text'}.contains(kind) ||
          (kind == 'date' && !_date(value)) ||
          (type == 'other'
              ? (fieldKey != null || label == null || label.trim().isEmpty)
              : (fieldKey == null || !DocumentField.keys.contains(fieldKey)))) {
        throw _invalid;
      }
      fields.add({
        'key': fieldKey,
        'label': type == 'other' ? label : null,
        'value': value,
        'type': kind,
      });
    }
    final url = _optional(p, 'url');
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw _invalid;
      }
    }
    return {
      'id': key.$2,
      'event_id': _text(p, 'event_id'),
      'media_asset_id': _text(p, 'media_asset_id'),
      'document_type': type,
      'title': _optional(p, 'title'),
      'captured_at': _time(p, 'captured_at'),
      'fields': fields,
      'ocr_text': ocr,
      'url': url,
      'preview_until': clock()
          .toUtc()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
    };
  }

  Expression<bool> _row(CachedDocumentDetails r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.id.equals(key.$2);
  Future<Set<(String, String)>> _links() async {
    final links = <(String, String)>{};
    final cards =
        await (db.select(db.cachedDocuments)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId) &
                  r.id.equals(key.$2),
            ))
            .get();
    for (final row in cards) {
      links.add((row.eventId, row.mediaAssetId));
    }
    final entries =
        await (db.select(db.cachedJournalEntries)..where(
              (r) =>
                  r.caregiverId.equals(key.$1.caregiverId) &
                  r.patientId.equals(key.$1.patientId),
            ))
            .get();
    for (final row in entries) {
      final payload = jsonDecode(row.payload) as Map;
      if (payload['document']?['id'] != key.$2) continue;
      final media =
          await (db.select(db.cachedJournalMedia)..where(
                (r) =>
                    r.caregiverId.equals(key.$1.caregiverId) &
                    r.patientId.equals(key.$1.patientId) &
                    r.day.equals(row.day) &
                    r.eventId.equals(row.id),
              ))
              .get();
      for (final m in media) {
        links.add((row.id, m.id));
      }
    }
    return links;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    if ((await _links()).isEmpty) {
      await purge();
      throw _unavailable;
    }
    try {
      final response = await client.request<dynamic>(
        '/documents/${key.$2}',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 || response.data is! Map) throw _invalid;
      final payload = _parse(response.data as Map);
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        if (!(await _links()).contains((
          payload['event_id'],
          payload['media_asset_id'],
        ))) {
          await _purgeDetail();
          throw _unavailable;
        }
        await db
            .into(db.cachedDocumentDetails)
            .insert(
              CachedDocumentDetailsCompanion.insert(
                caregiverId: key.$1.caregiverId,
                patientId: key.$1.patientId,
                id: key.$2,
                mediaAssetId: payload['media_asset_id'] as String,
                payload: jsonEncode(payload),
                refreshedAt: clock().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
    } on ApiFailure catch (e) {
      if (e.statusCode == 404 && e.code == 'DOCUMENT_NOT_FOUND') await purge();
      rethrow;
    }
  }

  Future<void> _purgeDetail() async {
    await (db.delete(db.cachedDocumentDetails)..where(_row)).go();
  }

  Future<void> purge() {
    ++_generation;
    return db.transaction(() async {
      await _purgeDetail();
      await (db.delete(db.cachedDocuments)..where(
            (r) =>
                r.caregiverId.equals(key.$1.caregiverId) &
                r.patientId.equals(key.$1.patientId) &
                r.id.equals(key.$2),
          ))
          .go();
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
      final entries =
          await (db.select(db.cachedJournalEntries)..where(
                (r) =>
                    r.caregiverId.equals(key.$1.caregiverId) &
                    r.patientId.equals(key.$1.patientId),
              ))
              .get();
      for (final row in entries) {
        final p = jsonDecode(row.payload) as Map<String, dynamic>;
        if (p['document']?['id'] == key.$2) {
          p['document'] = null;
          await (db.update(db.cachedJournalEntries)..where(
                (r) =>
                    r.caregiverId.equals(row.caregiverId) &
                    r.patientId.equals(row.patientId) &
                    r.day.equals(row.day) &
                    r.id.equals(row.id),
              ))
              .write(
                CachedJournalEntriesCompanion(payload: Value(jsonEncode(p))),
              );
        }
      }
    });
  }

  Stream<DocumentDetail?> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedDocumentDetails,
          db.cachedDocuments,
          db.cachedJournalEntries,
          db.cachedJournalMedia,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<DocumentDetail?> read() => db.transaction(() async {
    final row = await (db.select(
      db.cachedDocumentDetails,
    )..where(_row)).getSingleOrNull();
    if (row == null) return null;
    final p = jsonDecode(row.payload) as Map;
    if (!(await _links()).contains((p['event_id'], p['media_asset_id']))) {
      return null;
    }
    return DocumentDetail(
      id: p['id'],
      eventId: p['event_id'],
      mediaId: p['media_asset_id'],
      type: p['document_type'],
      title: p['title'],
      capturedAt: DateTime.parse(p['captured_at']),
      ocrText: p['ocr_text'],
      fields: [
        for (final f in p['fields'])
          DocumentField(
            key: f['key'],
            label: f['label'],
            value: f['value'],
            type: f['type'],
          ),
      ],
      url: p['url'],
      previewUntil: DateTime.parse(p['preview_until']),
      refreshedAt: row.refreshedAt,
    );
  });
}
