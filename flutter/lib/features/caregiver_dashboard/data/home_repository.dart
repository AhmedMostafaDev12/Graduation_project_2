import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/home_data.dart';

/// API responses populate the private, caregiver-scoped read cache. UI reads SQLite.
class HomeRepository {
  HomeRepository(this.client, this.db, this.caregiverId);
  final ApiClient client;
  final RemoriDatabase db;
  final String caregiverId;
  final _cancel = CancelToken();
  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    try {
      final response = await client.request<dynamic>(
        path,
        credential: ApiCredential.caregiver,
        queryParameters: query,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      return response.data;
    } on ApiFailure catch (failure) {
      // A known revoked/missing link is not an offline-cache fallback.
      final segments = path.split('/');
      if (failure.statusCode == 404 &&
          failure.code == 'PATIENT_NOT_FOUND' &&
          segments.length >= 4 &&
          segments[1] == 'patients') {
        final patientId = segments[2];
        await db.transaction(() async {
          await (db.delete(db.dashboardPatients)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) & p.id.equals(patientId),
              ))
              .go();
          await (db.delete(db.dashboardDevices)..where(
                (d) =>
                    d.caregiverId.equals(caregiverId) &
                    d.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.dashboardDays)..where(
                (d) =>
                    d.caregiverId.equals(caregiverId) &
                    d.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.dashboardAlerts)..where(
                (a) =>
                    a.caregiverId.equals(caregiverId) &
                    a.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedPeople)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.peopleCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.personDetailStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedPersonPhotos)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
        });
      }
      rethrow;
    }
  }

  String _string(Map data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return value;
  }

  DateTime _time(Map data, String key) {
    final value = DateTime.tryParse(_string(data, key));
    if (value == null || !value.isUtc) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return value;
  }

  List<Map> _list(dynamic value) {
    if (value is! List || value.any((item) => item is! Map)) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return value.cast<Map>();
  }

  Future<void> refresh(String? selectedId) async {
    final patients = _list(await _get('/patients'));
    for (final p in patients) {
      for (final key in [
        'id',
        'full_name',
        'preferred_language',
        'timezone',
        'permission',
      ]) {
        _string(p, key);
      }
      if (p['memory_capture_enabled'] is! bool ||
          !const ['manager', 'viewer'].contains(p['permission'])) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
    }
    final selected =
        patients.where((p) => p['id'] == selectedId).firstOrNull ??
        patients.firstOrNull;
    final patientId = selected?['id'] as String?;
    List<Map> devices = [], alerts = [], logs = [];
    Map? journal;
    if (patientId != null) {
      // journal's default date is today in this patient's IANA timezone.
      final results = await Future.wait([
        _get('/patients/$patientId/devices'),
        _get('/patients/$patientId/journal'),
      ]);
      devices = _list(results[0]);
      if (results[1] is! Map) throw ApiFailure(ApiFailureKind.invalidResponse);
      journal = results[1] as Map;
      final day = _string(journal, 'date');
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      logs = _list(
        await _get('/patients/$patientId/reminder-logs', {'date': day}),
      );
      // Alerts are caregiver-wide: walk pages until this patient's preview is full.
      var offset = 0;
      while (true) {
        final page = _list(
          await _get('/caregivers/me/alerts', {'limit': 50, 'offset': offset}),
        );
        alerts.addAll(page);
        if (page.length < 50 ||
            alerts.where((a) => a['patient_id'] == patientId).length >= 3) {
          break;
        }
        offset += page.length;
      }
    }
    if (_disposed) return;
    await db.transaction(() async {
      await (db.delete(
        db.dashboardPatients,
      )..where((p) => p.caregiverId.equals(caregiverId))).go();
      for (var i = 0; i < patients.length; i++) {
        final p = patients[i];
        await db
            .into(db.dashboardPatients)
            .insert(
              DashboardPatientsCompanion.insert(
                caregiverId: caregiverId,
                id: p['id'],
                fullName: p['full_name'],
                preferredLanguage: p['preferred_language'],
                timezone: p['timezone'],
                memoryCaptureEnabled: p['memory_capture_enabled'],
                permission: p['permission'],
                position: i,
              ),
            );
      }
      final allowedIds = patients.map((p) => p['id'] as String).toList();
      await (db.delete(db.cachedPeople)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.peopleCacheStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.personDetailStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedPersonPhotos)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.dashboardDevices)..where(
            (d) =>
                d.caregiverId.equals(caregiverId) &
                d.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.dashboardDays)..where(
            (d) =>
                d.caregiverId.equals(caregiverId) &
                d.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(
        db.dashboardAlerts,
      )..where((a) => a.caregiverId.equals(caregiverId))).go();
      for (final a in alerts.where(
        (a) => allowedIds.contains(a['patient_id']),
      )) {
        await db
            .into(db.dashboardAlerts)
            .insert(
              DashboardAlertsCompanion.insert(
                caregiverId: caregiverId,
                id: _string(a, 'id'),
                patientId: _string(a, 'patient_id'),
                alertType: _string(a, 'alert_type'),
                message: _string(a, 'message'),
                createdAt: _time(a, 'created_at'),
                readAt: Value(
                  a['read_at'] == null ? null : _time(a, 'read_at'),
                ),
                entityType: Value(a['entity_type'] as String?),
                entityId: Value(a['entity_id'] as String?),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      if (patientId == null) return;
      await (db.delete(db.dashboardDevices)..where(
            (d) =>
                d.caregiverId.equals(caregiverId) &
                d.patientId.equals(patientId),
          ))
          .go();
      for (final d in devices) {
        final battery = d['battery_level_pct'];
        if (d['patient_id'] != patientId ||
            d['online'] is! bool ||
            (battery != null &&
                (battery is! int || battery < 0 || battery > 100))) {
          throw ApiFailure(ApiFailureKind.invalidResponse);
        }
        await db
            .into(db.dashboardDevices)
            .insert(
              DashboardDevicesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: _string(d, 'id'),
                serial: _string(d, 'serial_number'),
                online: d['online'],
                batteryPct: Value(battery as int?),
                lastSeenAt: Value(
                  d['last_seen_at'] == null ? null : _time(d, 'last_seen_at'),
                ),
              ),
            );
      }
      final entries = _list(journal!['entries']);
      final people = <String>{};
      for (final e in entries) {
        if (e['event_type'] == 'encounter' && e['person'] is Map) {
          people.add(_string(e['person'] as Map, 'id'));
        }
      }
      final uniqueLogs = <String, Map>{};
      for (final log in logs) {
        if (!const [
          'pending',
          'completed',
          'snoozed',
          'missed',
        ].contains(log['status'])) {
          throw ApiFailure(ApiFailureKind.invalidResponse);
        }
        uniqueLogs[_string(log, 'id')] = log;
      }
      await (db.delete(db.dashboardDays)..where(
            (d) =>
                d.caregiverId.equals(caregiverId) &
                d.patientId.equals(patientId),
          ))
          .go();
      await db
          .into(db.dashboardDays)
          .insert(
            DashboardDaysCompanion.insert(
              caregiverId: caregiverId,
              patientId: patientId,
              day: journal!['date'],
              peopleMet: people.length,
              remindersDone: uniqueLogs.values
                  .where((l) => l['status'] == 'completed')
                  .length,
              remindersTotal: uniqueLogs.length,
              snoozed: uniqueLogs.values
                  .where((l) => l['status'] == 'snoozed')
                  .length,
              refreshedAt: DateTime.now().toUtc(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Stream<HomeData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.dashboardPatients,
          db.dashboardDevices,
          db.dashboardDays,
          db.dashboardAlerts,
        },
      )
      .watch()
      .asyncMap((_) => read());

  Future<HomeData> read() => db.transaction(() async {
    final patients =
        await (db.select(db.dashboardPatients)
              ..where((p) => p.caregiverId.equals(caregiverId))
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get();
    final devices = await (db.select(
      db.dashboardDevices,
    )..where((d) => d.caregiverId.equals(caregiverId))).get();
    final days =
        await (db.select(db.dashboardDays)
              ..where((d) => d.caregiverId.equals(caregiverId))
              ..orderBy([(d) => OrderingTerm.desc(d.refreshedAt)]))
            .get();
    final alerts =
        await (db.select(db.dashboardAlerts)
              ..where((a) => a.caregiverId.equals(caregiverId))
              ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
            .get();
    return HomeData(
      patients: patients
          .map(
            (p) => HomePatient(
              id: p.id,
              name: p.fullName,
              language: p.preferredLanguage,
              timezone: p.timezone,
              memoryEnabled: p.memoryCaptureEnabled,
              permission: p.permission,
            ),
          )
          .toList(),
      devices: devices
          .map(
            (d) => HomeDevice(
              id: d.id,
              patientId: d.patientId,
              serial: d.serial,
              online: d.online,
              battery: d.batteryPct,
              lastSeen: d.lastSeenAt,
            ),
          )
          .toList(),
      days: days
          .map(
            (d) => HomeDay(
              patientId: d.patientId,
              date: d.day,
              peopleMet: d.peopleMet,
              done: d.remindersDone,
              total: d.remindersTotal,
              snoozed: d.snoozed,
              refreshedAt: d.refreshedAt,
            ),
          )
          .toList(),
      alerts: alerts
          .map(
            (a) => HomeAlert(
              id: a.id,
              patientId: a.patientId,
              type: a.alertType,
              message: a.message,
              createdAt: a.createdAt,
            ),
          )
          .toList(),
    );
  });
}
