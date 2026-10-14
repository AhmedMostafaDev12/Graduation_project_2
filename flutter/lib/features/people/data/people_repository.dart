import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/people_data.dart';
import 'people_photo_cache.dart';
import 'person_detail_photo_cache.dart';

class PeopleRepository {
  PeopleRepository(this.client, this.db, this.scope, this.photos);
  final ApiClient client;
  final RemoriDatabase db;
  final PeopleScope scope;
  final PeoplePhotoCache photos;
  final _cancel = CancelToken();
  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  Expression<bool> _rows(CachedPeople row) =>
      row.caregiverId.equals(scope.caregiverId) &
      row.patientId.equals(scope.patientId);
  Expression<bool> _stateRows(PeopleCacheStates row) =>
      row.caregiverId.equals(scope.caregiverId) &
      row.patientId.equals(scope.patientId);
  String _string(Map data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return value;
  }

  List<Map> _list(dynamic body) {
    if (body is! List || body.any((item) => item is! Map)) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return body.cast<Map>();
  }

  Future<List<Map>> _get(String path, [Map<String, dynamic>? query]) async {
    final response = await client.request<dynamic>(
      path,
      credential: ApiCredential.caregiver,
      queryParameters: query,
      cancelToken: _cancel,
    );
    if (response.statusCode != 200) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return _list(response.data);
  }

  Future<void> refresh() async {
    try {
      final prefix = '/patients/${scope.patientId}';
      final results = await Future.wait([
        _get('$prefix/people', {'status': 'active'}),
        _get('$prefix/people', {'status': 'archived'}),
        _get('$prefix/unknown-faces'),
      ]);
      final companions = <CachedPeopleCompanion>[];
      final ids = <String>{};
      for (var index = 0; index < 2; index++) {
        final status = PeopleFilter.values[index].name;
        for (var position = 0; position < results[index].length; position++) {
          final person = results[index][position];
          final id = _string(person, 'id');
          final updated = DateTime.tryParse(_string(person, 'updated_at'));
          final embeddingCount = person['embedding_count'];
          final url = person['photo_url'];
          if (person['patient_id'] != scope.patientId ||
              person['status'] != status ||
              !ids.add(id) ||
              updated == null ||
              !updated.isUtc ||
              embeddingCount is! int ||
              embeddingCount < 0 ||
              (url != null &&
                  (url is! String || Uri.tryParse(url)?.scheme != 'https'))) {
            throw ApiFailure(ApiFailureKind.invalidResponse);
          }
          companions.add(
            CachedPeopleCompanion.insert(
              caregiverId: scope.caregiverId,
              patientId: scope.patientId,
              id: id,
              name: _string(person, 'name'),
              relationship: _string(person, 'relationship'),
              status: status,
              embeddingCount: embeddingCount,
              updatedAt: updated,
              position: position,
              // Archiving removes face data: never retain/display an archived photo.
              photoUrl: Value(status == 'active' ? url as String? : null),
            ),
          );
        }
      }
      final unknownIds = <String>{};
      for (final face in results[2]) {
        if (face['patient_id'] != scope.patientId) {
          throw ApiFailure(ApiFailureKind.invalidResponse);
        }
        if (face['status'] == 'awaiting_caregiver') {
          final days = face['distinct_days'];
          if (days is! int || days < 1) {
            throw ApiFailure(ApiFailureKind.invalidResponse);
          }
          if (days >= 3) unknownIds.add(_string(face, 'id'));
        }
      }
      if (_disposed) return;
      final previous = await read();
      await db.transaction(() async {
        await (db.delete(db.cachedPeople)..where(_rows)).go();
        for (final person in companions) {
          await db.into(db.cachedPeople).insert(person);
        }
        await db
            .into(db.peopleCacheStates)
            .insert(
              PeopleCacheStatesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
                unknownCount: unknownIds.length,
                refreshedAt: DateTime.now().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
      final current = await read();
      final invalidDetails = <String>{};
      for (final old in previous.people.where((p) => p.photoUrl != null)) {
        final newer = current.people.where((p) => p.id == old.id).firstOrNull;
        if (newer == null ||
            newer.status == PeopleFilter.archived ||
            newer.updatedAt != old.updatedAt ||
            newer.photoUrl == null) {
          await photos.evict(scope, old);
        }
      }
      for (final old in previous.people) {
        final newer = current.people.where((p) => p.id == old.id).firstOrNull;
        if (newer == null ||
            newer.status == PeopleFilter.archived ||
            newer.updatedAt != old.updatedAt) {
          invalidDetails.add(old.id);
        }
      }
      await purgePersonDetails(db, scope, ids: invalidDetails);
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404 && failure.code == 'PATIENT_NOT_FOUND') {
        await purge();
      }
      rethrow;
    }
  }

  Future<void> purge() async {
    await (db.delete(db.cachedUnknownFaces)..where(
          (r) =>
              r.caregiverId.equals(scope.caregiverId) &
              r.patientId.equals(scope.patientId),
        ))
        .go();
    await (db.delete(db.cachedPlaces)..where(
          (r) =>
              r.caregiverId.equals(scope.caregiverId) &
              r.patientId.equals(scope.patientId),
        ))
        .go();
    await (db.delete(db.placesCacheStates)..where(
          (r) =>
              r.caregiverId.equals(scope.caregiverId) &
              r.patientId.equals(scope.patientId),
        ))
        .go();
    await (db.delete(db.cachedUnknownFaceSamples)..where(
          (r) =>
              r.caregiverId.equals(scope.caregiverId) &
              r.patientId.equals(scope.patientId),
        ))
        .go();
    await (db.delete(db.unknownFacesCacheStates)..where(
          (r) =>
              r.caregiverId.equals(scope.caregiverId) &
              r.patientId.equals(scope.patientId),
        ))
        .go();
    final old = await read();
    await db.transaction(() async {
      await (db.delete(db.cachedPeople)..where(_rows)).go();
      await (db.delete(db.peopleCacheStates)..where(_stateRows)).go();
      await (db.delete(db.dashboardPatients)..where(
            (p) =>
                p.caregiverId.equals(scope.caregiverId) &
                p.id.equals(scope.patientId),
          ))
          .go();
      await (db.delete(db.dashboardDevices)..where(
            (d) =>
                d.caregiverId.equals(scope.caregiverId) &
                d.patientId.equals(scope.patientId),
          ))
          .go();
      await (db.delete(db.dashboardDays)..where(
            (d) =>
                d.caregiverId.equals(scope.caregiverId) &
                d.patientId.equals(scope.patientId),
          ))
          .go();
      await (db.delete(db.dashboardAlerts)..where(
            (a) =>
                a.caregiverId.equals(scope.caregiverId) &
                a.patientId.equals(scope.patientId),
          ))
          .go();
    });
    for (final person in old.people) {
      await photos.evict(scope, person);
    }
    await purgePersonDetails(db, scope);
  }

  Stream<PeopleData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.cachedPeople, db.peopleCacheStates},
      )
      .watch()
      .asyncMap((_) => read());
  Future<PeopleData> read() => db.transaction(() async {
    final rows =
        await (db.select(db.cachedPeople)
              ..where(_rows)
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get();
    final state = await (db.select(
      db.peopleCacheStates,
    )..where(_stateRows)).getSingleOrNull();
    return PeopleData(
      people: rows
          .map(
            (p) => KnownPerson(
              id: p.id,
              name: p.name,
              relationship: p.relationship,
              status: PeopleFilter.values.byName(p.status),
              updatedAt: p.updatedAt,
              photoUrl: p.photoUrl,
            ),
          )
          .toList(),
      unknownCount: state?.unknownCount ?? 0,
      refreshedAt: state?.refreshedAt,
    );
  });
}
