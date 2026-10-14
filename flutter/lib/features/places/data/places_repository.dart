import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/places_data.dart';

class PlacesRepository {
  PlacesRepository(this.client, this.db, this.scope);
  final ApiClient client;
  final RemoriDatabase db;
  final PlacesScope scope;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _generation = 0;
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  Expression<bool> _rows(CachedPlaces p) =>
      p.caregiverId.equals(scope.caregiverId) &
      p.patientId.equals(scope.patientId);
  Expression<bool> _states(PlacesCacheStates p) =>
      p.caregiverId.equals(scope.caregiverId) &
      p.patientId.equals(scope.patientId);
  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _text(Map raw, String key) {
    final v = raw[key];
    if (v is! String || v.trim().isEmpty) throw _invalid;
    return v;
  }

  double _coordinate(Map raw, String key, double max) {
    final v = raw[key];
    if (v is! num || !v.isFinite || v.abs() > max) throw _invalid;
    return v.toDouble();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final response = await client.request<dynamic>(
        '/patients/${scope.patientId}/places',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      final body = response.data;
      if (response.statusCode != 200 ||
          body is! List ||
          body.any((r) => r is! Map)) {
        throw _invalid;
      }
      final rows = <CachedPlacesCompanion>[], ids = <String>{};
      for (var position = 0; position < body.length; position++) {
        final p = body[position] as Map;
        final id = _text(p, 'id'),
            name = _text(p, 'name'),
            radius = p['radius_m'];
        final updated = DateTime.tryParse(_text(p, 'updated_at'));
        if (!ids.add(id) ||
            p['patient_id'] != scope.patientId ||
            name.runes.length > 80 ||
            p['deleted_at'] != null ||
            radius is! int ||
            radius < 20 ||
            radius > 2000 ||
            updated == null ||
            !updated.isUtc) {
          throw _invalid;
        }
        rows.add(
          CachedPlacesCompanion.insert(
            caregiverId: scope.caregiverId,
            patientId: scope.patientId,
            id: id,
            name: name,
            latitude: _coordinate(p, 'latitude', 90),
            longitude: _coordinate(p, 'longitude', 180),
            radiusM: radius,
            createdBy: _text(p, 'created_by'),
            updatedAt: updated,
            position: position,
          ),
        );
      }
      if (_disposed || generation != _generation) return;
      await db.transaction(() async {
        if (_disposed || generation != _generation) return;
        await (db.delete(db.cachedPlaces)..where(_rows)).go();
        for (final row in rows) {
          await db.into(db.cachedPlaces).insert(row);
        }
        await db
            .into(db.placesCacheStates)
            .insert(
              PlacesCacheStatesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
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
      await (db.delete(db.cachedPlaces)..where(_rows)).go();
      await (db.delete(db.placesCacheStates)..where(_states)).go();
    });
  }

  Stream<PlacesData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.cachedPlaces, db.placesCacheStates},
      )
      .watch()
      .asyncMap((_) => read());
  Future<PlacesData> read() => db.transaction(() async {
    final rows =
        await (db.select(db.cachedPlaces)
              ..where(_rows)
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get();
    final state = await (db.select(
      db.placesCacheStates,
    )..where(_states)).getSingleOrNull();
    return PlacesData(
      refreshedAt: state?.refreshedAt,
      places: [
        for (final p in rows)
          SavedPlace(
            id: p.id,
            name: p.name,
            latitude: p.latitude,
            longitude: p.longitude,
            radiusM: p.radiusM,
            createdBy: p.createdBy,
            updatedAt: p.updatedAt,
          ),
      ],
    );
  });
}
