import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/places_data.dart';
import '../domain/place_draft.dart';

/// Acknowledged online write; retrying this receipt never sends another request.
class PlaceReceipt {
  const PlaceReceipt(this.scope, this.id, this.row);
  final PlacesScope scope;
  final String id;
  final CachedPlacesCompanion? row;
}

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

  Future<PlaceReceipt> save(PlaceDraft draft, {String? id}) async {
    if (!draft.valid || (id != null && id.isEmpty)) {
      throw ApiFailure(ApiFailureKind.server, code: 'VALIDATION_ERROR');
    }
    final response = await _writeRequest(
      '/patients/${scope.patientId}/places${id == null ? '' : '/$id'}',
      method: id == null ? 'POST' : 'PATCH',
      id: id,
      data: {
        'name': draft.name.trim(),
        'latitude': draft.point!.latitude,
        'longitude': draft.point!.longitude,
        'radius_m': draft.radiusM,
      },
    );
    final p = response.data;
    if (response.statusCode != (id == null ? 201 : 200) || p is! Map) {
      throw _invalid;
    }
    final returnedId = _text(p, 'id'),
        name = _text(p, 'name'),
        radius = p['radius_m'];
    final updated = DateTime.tryParse(_text(p, 'updated_at'));
    if ((id != null && id != returnedId) ||
        p['patient_id'] != scope.patientId ||
        p['deleted_at'] != null ||
        name.runes.length > 80 ||
        radius is! int ||
        radius < 20 ||
        radius > 2000 ||
        updated == null ||
        !updated.isUtc) {
      throw _invalid;
    }
    return PlaceReceipt(
      scope,
      returnedId,
      CachedPlacesCompanion.insert(
        caregiverId: scope.caregiverId,
        patientId: scope.patientId,
        id: returnedId,
        name: name,
        latitude: _coordinate(p, 'latitude', 90),
        longitude: _coordinate(p, 'longitude', 180),
        radiusM: radius,
        createdBy: _text(p, 'created_by'),
        updatedAt: updated,
        position: -1,
      ),
    );
  }

  Future<PlaceReceipt> remove(String id) async {
    if (id.isEmpty) throw _invalid;
    final response = await _writeRequest(
      '/patients/${scope.patientId}/places/$id',
      method: 'DELETE',
      id: id,
    );
    if (response.statusCode != 204) throw _invalid;
    return PlaceReceipt(scope, id, null);
  }

  Future<Response<dynamic>> _writeRequest(
    String path, {
    required String method,
    String? id,
    Object? data,
  }) async {
    ++_generation;
    try {
      return await client.request<dynamic>(
        path,
        method: method,
        data: data,
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404 && failure.code == 'PATIENT_NOT_FOUND') {
        await purge();
      } else if (failure.statusCode == 404 &&
          failure.code == 'PLACE_NOT_FOUND' &&
          id != null) {
        await cacheReceipt(PlaceReceipt(scope, id, null));
      }
      rethrow;
    } finally {
      ++_generation;
    }
  }

  Future<void> cacheReceipt(PlaceReceipt receipt) => db.transaction(() async {
    if (_disposed) throw ApiFailure(ApiFailureKind.cancelled);
    if (receipt.scope != scope ||
        (receipt.row != null &&
            (receipt.row!.caregiverId.value != scope.caregiverId ||
                receipt.row!.patientId.value != scope.patientId ||
                receipt.row!.id.value != receipt.id))) {
      throw _invalid;
    }
    ++_generation;
    final condition = db.cachedPlaces.id.equals(receipt.id);
    if (receipt.row == null) {
      await (db.delete(
        db.cachedPlaces,
      )..where((p) => _rows(p) & p.id.equals(receipt.id))).go();
    } else {
      final old = await (db.select(
        db.cachedPlaces,
      )..where((p) => _rows(p) & condition)).getSingleOrNull();
      await db
          .into(db.cachedPlaces)
          .insert(
            receipt.row!.copyWith(position: Value(old?.position ?? -1)),
            mode: InsertMode.insertOrReplace,
          );
    }
    // A single write does not claim that the complete list was refreshed.
  });

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
