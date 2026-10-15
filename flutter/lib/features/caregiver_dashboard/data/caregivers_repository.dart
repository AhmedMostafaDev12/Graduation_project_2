import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/caregivers_data.dart';
import 'home_repository.dart';

class CaregiversRepository {
  CaregiversRepository(this.home, this.db, this.scope, this.clock);
  final HomeRepository home;
  final RemoriDatabase db;
  final CaregiversScope scope;
  final DateTime Function() clock;
  bool _disposed = false;
  int _generation = 0;
  void dispose() {
    _disposed = true;
    ++_generation;
  }

  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _text(Map p, String key) {
    final value = p[key];
    if (value is! String || value.trim().isEmpty) throw _invalid;
    return value;
  }

  LinkedCaregiver _parse(Map p) {
    final email = p['email'], permission = _text(p, 'permission');
    if ((email != null && email is! String) ||
        !{'manager', 'viewer'}.contains(permission) ||
        p['is_primary'] is! bool ||
        (p['is_primary'] == true && permission != 'manager') ||
        (p.containsKey('patient_id') && p['patient_id'] != scope.$2)) {
      throw _invalid;
    }
    return LinkedCaregiver(
      id: _text(p, 'id'),
      userId: _text(p, 'caregiver_id'),
      name: _text(p, 'full_name'),
      relationship: _text(p, 'relationship'),
      permission: permission,
      primary: p['is_primary'],
      email: email as String?,
    );
  }

  Map<String, Object?> _payload(LinkedCaregiver c) => {
    'id': c.id,
    'caregiver_id': c.userId,
    'full_name': c.name,
    'email': c.email,
    'relationship': c.relationship,
    'permission': c.permission,
    'is_primary': c.primary,
  };
  Expression<bool> _rows(CachedCaregiverLinks c) =>
      c.caregiverId.equals(scope.$1) & c.patientId.equals(scope.$2);
  Expression<bool> _state(CaregiversCacheStates c) =>
      c.caregiverId.equals(scope.$1) & c.patientId.equals(scope.$2);
  Future<DashboardPatient?> _patient() =>
      (db.select(db.dashboardPatients)..where(
            (p) => p.caregiverId.equals(scope.$1) & p.id.equals(scope.$2),
          ))
          .getSingleOrNull();
  Future<void> refresh() async {
    final generation = ++_generation;
    if (await _patient() == null) throw _invalid;
    final raw = await home.getCaregivers(scope.$2);
    if (raw is! List) throw _invalid;
    final links = <LinkedCaregiver>[], ids = <String>{}, users = <String>{};
    for (final value in raw) {
      if (value is! Map) throw _invalid;
      final link = _parse(value);
      if (!ids.add(link.id) || !users.add(link.userId)) throw _invalid;
      links.add(link);
    }
    if (_disposed || generation != _generation) return;
    await db.transaction(() async {
      if (_disposed || generation != _generation || await _patient() == null) {
        return;
      }
      await (db.delete(db.cachedCaregiverLinks)..where(_rows)).go();
      for (final link in links) {
        await _insert(link);
      }
      await db
          .into(db.caregiversCacheStates)
          .insert(
            CaregiversCacheStatesCompanion.insert(
              caregiverId: scope.$1,
              patientId: scope.$2,
              refreshedAt: clock(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Future<void> _insert(LinkedCaregiver link) async {
    await db
        .into(db.cachedCaregiverLinks)
        .insert(
          CachedCaregiverLinksCompanion.insert(
            caregiverId: scope.$1,
            patientId: scope.$2,
            id: link.id,
            payload: jsonEncode(_payload(link)),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<LinkedCaregiver> link(CaregiverLinkDraft draft) async {
    if (!draft.isValid || (await _patient())?.permission != 'manager') {
      throw _invalid;
    }
    final response = await home.addCaregiver(scope.$2, {
      'email': draft.email.trim(),
      'relationship': draft.relationship.trim(),
      'permission': draft.permission,
    });
    if (response is! Map) throw _invalid;
    final result = _parse(response);
    if (result.email?.toLowerCase() != draft.email.trim().toLowerCase() ||
        result.relationship != draft.relationship.trim() ||
        result.permission != draft.permission ||
        result.primary) {
      throw _invalid;
    }
    ++_generation;
    return result;
  }

  Future<void> cacheLink(LinkedCaregiver link) {
    ++_generation;
    return db.transaction(() async {
      if (_disposed || await _patient() == null) return;
      // An account has one link per patient, even if stale local IDs differ.
      final old = await (db.select(
        db.cachedCaregiverLinks,
      )..where(_rows)).get();
      for (final row in old) {
        if (_parse(jsonDecode(row.payload) as Map).userId == link.userId &&
            row.id != link.id) {
          await (db.delete(
            db.cachedCaregiverLinks,
          )..where((r) => _rows(r) & r.id.equals(row.id))).go();
        }
      }
      await _insert(link);
    });
  }

  Stream<CaregiversData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedCaregiverLinks,
          db.caregiversCacheStates,
          db.dashboardPatients,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<CaregiversData> read() => db.transaction(() async {
    if (await _patient() == null) return const CaregiversData();
    final rows = await (db.select(db.cachedCaregiverLinks)..where(_rows)).get();
    final state = await (db.select(
      db.caregiversCacheStates,
    )..where(_state)).getSingleOrNull();
    final links = rows.map((r) => _parse(jsonDecode(r.payload) as Map)).toList()
      ..sort((a, b) {
        if (a.primary != b.primary) return a.primary ? -1 : 1;
        final order = a.name.compareTo(b.name);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    return CaregiversData(links: links, refreshedAt: state?.refreshedAt);
  });
}
