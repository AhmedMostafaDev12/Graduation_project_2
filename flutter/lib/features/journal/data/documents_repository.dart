import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/document_data.dart';

class DocumentsRepository {
  DocumentsRepository(this.client, this.db, this.key, this.clock);
  final ApiClient client;
  final RemoriDatabase db;
  final DocumentsKey key;
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

  String? _url(Map p, String k) {
    final value = _optional(p, k);
    if (value == null) return null;
    final u = Uri.tryParse(value);
    if (u == null ||
        u.scheme != 'https' ||
        u.host.isEmpty ||
        u.userInfo.isNotEmpty) {
      throw _invalid;
    }
    return value;
  }

  CachedDocumentsCompanion _card(Map p, int position, DateTime until) {
    final type = _text(p, 'document_type'),
        time = DateTime.tryParse(_text(p, 'captured_at'));
    if (!{'receipt', 'bill', 'medication_label', 'other'}.contains(type) ||
        (key.$2.apiType != null && type != key.$2.apiType) ||
        time == null ||
        !time.isUtc ||
        (p.containsKey('patient_id') && p['patient_id'] != key.$1.patientId)) {
      throw _invalid;
    }
    return CachedDocumentsCompanion.insert(
      caregiverId: key.$1.caregiverId,
      patientId: key.$1.patientId,
      filter: key.$2.name,
      id: _text(p, 'id'),
      eventId: _text(p, 'event_id'),
      mediaAssetId: _text(p, 'media_asset_id'),
      documentType: type,
      title: Value(_optional(p, 'title')),
      headline: Value(_optional(p, 'headline')),
      capturedAt: time,
      url: Value(_url(p, 'url')),
      thumbnailUrl: Value(_url(p, 'thumbnail_url')),
      previewUntil: until,
      position: position,
    );
  }

  Expression<bool> _cards(CachedDocuments r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.filter.equals(key.$2.name);
  Expression<bool> _state(DocumentsCacheStates r) =>
      r.caregiverId.equals(key.$1.caregiverId) &
      r.patientId.equals(key.$1.patientId) &
      r.filter.equals(key.$2.name);
  Future<void> refresh() => _page(reset: true);
  Future<void> loadMore() => _page(reset: false);
  Future<void> _page({required bool reset}) async {
    final generation = ++_generation;
    final previous = reset ? const DocumentsData() : await read();
    if (!reset && !previous.hasMore) return;
    final offset = reset ? 0 : previous.nextOffset;
    try {
      final response = await client.request<dynamic>(
        '/patients/${key.$1.patientId}/documents',
        credential: ApiCredential.caregiver,
        queryParameters: {
          if (key.$2.apiType != null) 'type': key.$2.apiType,
          'limit': 50,
          'offset': offset,
        },
        cancelToken: _cancel,
      );
      final body = response.data;
      if (response.statusCode != 200 || body is! List || body.length > 50) {
        throw _invalid;
      }
      final until = clock().toUtc().add(const Duration(minutes: 10)),
          ids = <String>{};
      final cards = <CachedDocumentsCompanion>[];
      for (var i = 0; i < body.length; i++) {
        if (body[i] is! Map) throw _invalid;
        final card = _card(body[i] as Map, offset + i, until);
        if (!ids.add(card.id.value)) throw _invalid;
        cards.add(card);
      }
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        if (reset) {
          await (db.delete(db.cachedDocuments)..where(_cards)).go();
        }
        final old = reset
            ? <String, int>{}
            : {
                for (final r in await (db.select(
                  db.cachedDocuments,
                )..where(_cards)).get())
                  r.id: r.position,
              };
        for (final card in cards) {
          await db
              .into(db.cachedDocuments)
              .insert(
                old.containsKey(card.id.value)
                    ? card.copyWith(position: Value(old[card.id.value]!))
                    : card,
                mode: InsertMode.insertOrReplace,
              );
        }
        await db
            .into(db.documentsCacheStates)
            .insert(
              DocumentsCacheStatesCompanion.insert(
                caregiverId: key.$1.caregiverId,
                patientId: key.$1.patientId,
                filter: key.$2.name,
                nextOffset: offset + body.length,
                hasMore: body.length == 50,
                refreshedAt: clock().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
    } on ApiFailure catch (e) {
      if (e.statusCode == 404 && e.code == 'PATIENT_NOT_FOUND') await purge();
      rethrow;
    }
  }

  Future<void> purge() {
    ++_generation;
    return db.transaction(() async {
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
    });
  }

  Stream<DocumentsData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.cachedDocuments, db.documentsCacheStates},
      )
      .watch()
      .asyncMap((_) => read());
  Future<DocumentsData> read() => db.transaction(() async {
    final state = await (db.select(
      db.documentsCacheStates,
    )..where(_state)).getSingleOrNull();
    if (state == null) return const DocumentsData();
    final rows =
        await (db.select(db.cachedDocuments)
              ..where(_cards)
              ..orderBy([
                (r) => OrderingTerm.desc(r.capturedAt),
                (r) => OrderingTerm.asc(r.position),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    return DocumentsData(
      refreshedAt: state.refreshedAt,
      nextOffset: state.nextOffset,
      hasMore: state.hasMore,
      documents: [
        for (final r in rows)
          DocumentCard(
            id: r.id,
            eventId: r.eventId,
            mediaId: r.mediaAssetId,
            type: r.documentType,
            capturedAt: r.capturedAt,
            previewUntil: r.previewUntil,
            title: r.title,
            headline: r.headline,
            url: r.url,
            thumbnailUrl: r.thumbnailUrl,
          ),
      ],
    );
  });
}
