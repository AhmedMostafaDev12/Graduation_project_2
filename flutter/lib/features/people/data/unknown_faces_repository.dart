import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/people_data.dart';
import '../domain/unknown_faces_data.dart';

/// An acknowledged server decision. Retrying this receipt writes SQLite only.
class UnknownFaceDecision {
  const UnknownFaceDecision(this.clusterId, this.person);
  final String clusterId;
  final CachedPeopleCompanion? person;
}

class UnknownFacesRepository {
  UnknownFacesRepository(this.client, this.db, this.scope);
  final ApiClient client;
  final RemoriDatabase db;
  final PeopleScope scope;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _generation = 0;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  Expression<bool> _rows(CachedUnknownFaces r) =>
      r.caregiverId.equals(scope.caregiverId) &
      r.patientId.equals(scope.patientId);
  Expression<bool> _states(UnknownFacesCacheStates r) =>
      r.caregiverId.equals(scope.caregiverId) &
      r.patientId.equals(scope.patientId);
  Expression<bool> _samples(CachedUnknownFaceSamples r) =>
      r.caregiverId.equals(scope.caregiverId) &
      r.patientId.equals(scope.patientId);
  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _text(Map raw, String key) {
    final v = raw[key];
    if (v is! String || v.trim().isEmpty) throw _invalid;
    return v;
  }

  DateTime _time(Map raw, String key) {
    final value = DateTime.tryParse(_text(raw, key));
    if (value == null || !value.isUtc) throw _invalid;
    return value;
  }

  String? _url(Object? value) {
    if (value == null) return null;
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw _invalid;
    }
    return value as String;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final response = await client.request<dynamic>(
        '/patients/${scope.patientId}/unknown-faces',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 ||
          response.data is! List ||
          (response.data as List).any((v) => v is! Map)) {
        throw _invalid;
      }
      final rows = <CachedUnknownFacesCompanion>[];
      final photoRows = <CachedUnknownFaceSamplesCompanion>[];
      final ids = <String>{};
      for (final raw in (response.data as List).cast<Map>()) {
        final id = _text(raw, 'id'),
            count = raw['sighting_count'],
            days = raw['distinct_days'];
        final first = _time(raw, 'first_seen_at'),
            last = _time(raw, 'last_seen_at');
        if (!ids.add(id) ||
            raw['patient_id'] != scope.patientId ||
            raw['status'] != 'awaiting_caregiver' ||
            count is! int ||
            days is! int ||
            days < 1 ||
            count < days ||
            last.isBefore(first)) {
          throw _invalid;
        }
        final samples = raw['samples'];
        if (samples is! List ||
            samples.length > 3 ||
            samples.any((v) => v is! Map)) {
          throw _invalid;
        }
        final sampleIds = <String>{};
        for (final sample in samples.cast<Map>()) {
          if (!sampleIds.add(_text(sample, 'id')) ||
              _url(sample['url']) == null) {
            throw _invalid;
          }
          _url(sample['thumbnail_url']);
        }
        final url = _url(raw['sample_url']),
            thumbnail = _url(raw['sample_thumbnail_url']);
        final sample = samples.isEmpty ? null : samples.first as Map;
        if ((sample == null && (url != null || thumbnail != null)) ||
            (sample != null &&
                (sample['url'] != url ||
                    sample['thumbnail_url'] != thumbnail))) {
          throw _invalid;
        }
        // The board/spec exposes faces only after sightings on three days.
        if (days < 3) continue;
        for (var position = 0; position < samples.length; position++) {
          final photo = samples[position] as Map;
          photoRows.add(
            CachedUnknownFaceSamplesCompanion.insert(
              caregiverId: scope.caregiverId,
              patientId: scope.patientId,
              clusterId: id,
              id: photo['id'] as String,
              url: photo['url'] as String,
              thumbnailUrl: Value(photo['thumbnail_url'] as String?),
              position: position,
            ),
          );
        }
        rows.add(
          CachedUnknownFacesCompanion.insert(
            caregiverId: scope.caregiverId,
            patientId: scope.patientId,
            id: id,
            sightingCount: count,
            distinctDays: days,
            firstSeenAt: first,
            lastSeenAt: last,
            sampleId: Value(sample?['id'] as String?),
            sampleUrl: Value(url),
            thumbnailUrl: Value(thumbnail),
          ),
        );
      }
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        await (db.delete(db.cachedUnknownFaces)..where(_rows)).go();
        await (db.delete(db.cachedUnknownFaceSamples)..where(_samples)).go();
        for (final photo in photoRows) {
          await db.into(db.cachedUnknownFaceSamples).insert(photo);
        }
        for (final row in rows) {
          await db.into(db.cachedUnknownFaces).insert(row);
        }
        await db
            .into(db.unknownFacesCacheStates)
            .insert(
              UnknownFacesCacheStatesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
                refreshedAt: DateTime.now().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
        // Keep the existing C3 review badge aligned without marking People fresh.
        await (db.update(db.peopleCacheStates)..where(
              (r) =>
                  r.caregiverId.equals(scope.caregiverId) &
                  r.patientId.equals(scope.patientId),
            ))
            .write(
              PeopleCacheStatesCompanion(unknownCount: Value(rows.length)),
            );
      });
    } on ApiFailure catch (error) {
      if (error.statusCode == 404 && error.code == 'PATIENT_NOT_FOUND') {
        await purge();
      }
      rethrow;
    }
  }

  Future<void> purge() => db.transaction(() async {
    ++_generation;
    await (db.delete(db.cachedUnknownFaces)..where(_rows)).go();
    await (db.delete(db.cachedUnknownFaceSamples)..where(_samples)).go();
    await (db.delete(db.unknownFacesCacheStates)..where(_states)).go();
  });
  Stream<UnknownFacesData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedUnknownFaces,
          db.unknownFacesCacheStates,
          db.cachedUnknownFaceSamples,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<UnknownFacesData> read() => db.transaction(() async {
    final rows =
        await (db.select(db.cachedUnknownFaces)
              ..where(_rows)
              ..orderBy([(r) => OrderingTerm.desc(r.lastSeenAt)]))
            .get();
    final state = await (db.select(
      db.unknownFacesCacheStates,
    )..where(_states)).getSingleOrNull();
    final samples =
        await (db.select(db.cachedUnknownFaceSamples)
              ..where(_samples)
              ..orderBy([(r) => OrderingTerm.asc(r.position)]))
            .get();
    return UnknownFacesData(
      refreshedAt: state?.refreshedAt,
      faces: [
        for (final r in rows)
          UnknownFace(
            id: r.id,
            sightingCount: r.sightingCount,
            distinctDays: r.distinctDays,
            firstSeenAt: r.firstSeenAt,
            lastSeenAt: r.lastSeenAt,
            sampleId: r.sampleId,
            sampleUrl: r.sampleUrl,
            thumbnailUrl: r.thumbnailUrl,
            samples: [
              for (final p in samples.where((p) => p.clusterId == r.id))
                UnknownFaceSample(p.id, p.url, p.thumbnailUrl),
            ],
          ),
      ],
    );
  });

  Future<UnknownFaceDecision> decide(
    String id, {
    String? name,
    String? relationship,
    bool consent = false,
  }) async {
    final promote = name != null;
    if (id.isEmpty ||
        (promote &&
            (!consent ||
                name.trim().isEmpty ||
                name.trim().runes.length > 80 ||
                relationship == null ||
                relationship.trim().isEmpty ||
                relationship.trim().runes.length > 40))) {
      throw ApiFailure(ApiFailureKind.server, code: 'VALIDATION_ERROR');
    }
    ++_generation;
    final response = await client.request<dynamic>(
      '/unknown-faces/$id/${promote ? 'promote' : 'dismiss'}',
      method: 'POST',
      credential: ApiCredential.caregiver,
      cancelToken: _cancel,
      data: promote
          ? {
              'name': name.trim(),
              'relationship': relationship!.trim(),
              'consent_given': true,
            }
          : null,
    );
    ++_generation;
    final body = response.data;
    final cluster = promote && body is Map ? body['cluster'] : body;
    if (response.statusCode != 200 ||
        cluster is! Map ||
        cluster['id'] != id ||
        cluster['patient_id'] != scope.patientId ||
        cluster['status'] != (promote ? 'promoted' : 'dismissed')) {
      throw _invalid;
    }
    if (!promote) {
      if (cluster['samples'] is! List ||
          (cluster['samples'] as List).isNotEmpty ||
          cluster['sample_url'] != null ||
          cluster['sample_thumbnail_url'] != null) {
        throw _invalid;
      }
      return UnknownFaceDecision(id, null);
    }
    final person = (body as Map)['person'];
    if (person is! Map ||
        person['patient_id'] != scope.patientId ||
        person['status'] != 'active' ||
        person['embedding_count'] is! int ||
        (person['embedding_count'] as int) < 0) {
      throw _invalid;
    }
    return UnknownFaceDecision(
      id,
      CachedPeopleCompanion.insert(
        caregiverId: scope.caregiverId,
        patientId: scope.patientId,
        id: _text(person, 'id'),
        name: _text(person, 'name'),
        relationship: _text(person, 'relationship'),
        status: 'active',
        embeddingCount: person['embedding_count'] as int,
        updatedAt: _time(person, 'updated_at'),
        position: -1,
        photoUrl: Value(_url(person['photo_url'])),
      ),
    );
  }

  Future<void> cacheDecision(UnknownFaceDecision decision) =>
      db.transaction(() async {
        if (_disposed) throw ApiFailure(ApiFailureKind.cancelled);
        ++_generation;
        if (decision.person != null) {
          final p = decision.person!;
          if (p.caregiverId.value != scope.caregiverId ||
              p.patientId.value != scope.patientId) {
            throw _invalid;
          }
          await db
              .into(db.cachedPeople)
              .insert(p, mode: InsertMode.insertOrReplace);
        }
        await (db.delete(db.cachedUnknownFaceSamples)..where(
              (r) => _samples(r) & r.clusterId.equals(decision.clusterId),
            ))
            .go();
        await (db.delete(
          db.cachedUnknownFaces,
        )..where((r) => _rows(r) & r.id.equals(decision.clusterId))).go();
        final remaining = await (db.select(
          db.cachedUnknownFaces,
        )..where(_rows)).get();
        await (db.update(db.peopleCacheStates)..where(
              (r) =>
                  r.caregiverId.equals(scope.caregiverId) &
                  r.patientId.equals(scope.patientId),
            ))
            .write(
              PeopleCacheStatesCompanion(unknownCount: Value(remaining.length)),
            );
      });
}
