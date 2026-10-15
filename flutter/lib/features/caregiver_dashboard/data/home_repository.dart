import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/home_data.dart';
import '../domain/more_data.dart';

/// API responses populate the private, caregiver-scoped read cache. UI reads SQLite.
class HomeRepository {
  HomeRepository(this.client, this.db, this.caregiverId);
  final ApiClient client;
  final RemoriDatabase db;
  final String caregiverId;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _alertGeneration = 0;
  int _deviceGeneration = 0;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async =>
      (await _request(path, query: query)).data;

  Future<Response<dynamic>> _request(
    String path, {
    Map<String, dynamic>? query,
    String method = 'GET',
    Object? data,
    int status = 200,
  }) async {
    try {
      final response = await client.request<dynamic>(
        path,
        credential: ApiCredential.caregiver,
        method: method,
        data: data,
        queryParameters: query,
        cancelToken: _cancel,
      );
      if (response.statusCode != status) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      return response;
    } on ApiFailure catch (failure) {
      // A known revoked/missing link is not an offline-cache fallback.
      final segments = path.split('/');
      if (failure.statusCode == 404 &&
          failure.code == 'PATIENT_NOT_FOUND' &&
          segments.length >= 3 &&
          segments[1] == 'patients') {
        final patientId = segments[2];
        await db.transaction(() async {
          await (db.delete(db.cachedConsents)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedUnknownFaces)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedDocumentDetails)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedDocuments)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.documentsCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedMediaDetails)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedJournalEntries)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedJournalMedia)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.journalCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedPlaces)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.placesCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedUnknownFaceSamples)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.unknownFacesCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
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
          await (db.delete(db.cachedReminders)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.cachedReminderOccurrences)..where(
                (p) =>
                    p.caregiverId.equals(caregiverId) &
                    p.patientId.equals(patientId),
              ))
              .go();
          await (db.delete(db.reminderCacheStates)..where(
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
    final alertGeneration = _alertGeneration;
    final deviceGeneration = _deviceGeneration;
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
    if (_disposed || deviceGeneration != _deviceGeneration) return;
    await db.transaction(() async {
      if (_disposed || deviceGeneration != _deviceGeneration) return;
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
      await (db.delete(db.cachedConsents)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedUnknownFaces)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedDocumentDetails)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedDocuments)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.documentsCacheStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedMediaDetails)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedJournalEntries)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedJournalMedia)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.journalCacheStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedPlaces)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.placesCacheStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedUnknownFaceSamples)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.unknownFacesCacheStates)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
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
      await (db.delete(db.cachedReminders)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.cachedReminderOccurrences)..where(
            (p) =>
                p.caregiverId.equals(caregiverId) &
                p.patientId.isNotIn(allowedIds),
          ))
          .go();
      await (db.delete(db.reminderCacheStates)..where(
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
      // Home fetches only a preview. Keep C2's full history and purge revoked links.
      await (db.delete(db.dashboardAlerts)..where(
            (a) =>
                a.caregiverId.equals(caregiverId) &
                a.patientId.isNotIn(allowedIds),
          ))
          .go();
      if (alertGeneration == _alertGeneration) {
        for (final a in alerts.where(
          (a) => allowedIds.contains(a['patient_id']),
        )) {
          await _mergeAlert(_alertRow(a));
        }
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
                firmwareVersion: Value(_firmware(d)),
                pairedAt: Value(
                  d['paired_at'] == null ? null : _time(d, 'paired_at'),
                ),
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
              firmware: d.firmwareVersion,
              pairedAt: d.pairedAt,
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
              readAt: a.readAt,
              entityType: a.entityType,
              entityId: a.entityId,
            ),
          )
          .toList(),
    );
  });

  DashboardAlertsCompanion _alertRow(Map raw) {
    for (final key in ['entity_type', 'entity_id']) {
      if (raw[key] != null &&
          (raw[key] is! String || (raw[key] as String).isEmpty)) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
    }
    return DashboardAlertsCompanion.insert(
      caregiverId: caregiverId,
      id: _string(raw, 'id'),
      patientId: _string(raw, 'patient_id'),
      alertType: _string(raw, 'alert_type'),
      message: _string(raw, 'message'),
      createdAt: _time(raw, 'created_at'),
      readAt: Value(raw['read_at'] == null ? null : _time(raw, 'read_at')),
      entityType: Value(raw['entity_type'] as String?),
      entityId: Value(raw['entity_id'] as String?),
    );
  }

  Future<void> _mergeAlert(DashboardAlertsCompanion row) async {
    final previous =
        await (db.select(db.dashboardAlerts)..where(
              (a) =>
                  a.caregiverId.equals(caregiverId) & a.id.equals(row.id.value),
            ))
            .getSingleOrNull();
    await db
        .into(db.dashboardAlerts)
        .insert(
          previous?.readAt != null && row.readAt.value == null
              ? row.copyWith(readAt: Value(previous!.readAt))
              : row,
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> refreshAlerts() async {
    final generation = ++_alertGeneration;
    final rows = <DashboardAlertsCompanion>[];
    final ids = <String>{};
    var offset = 0;
    while (!_disposed) {
      final page = _list(
        await _get('/caregivers/me/alerts', {
          'unread_only': false,
          'limit': 50,
          'offset': offset,
        }),
      );
      for (final raw in page) {
        final row = _alertRow(raw);
        if (!ids.add(row.id.value)) {
          throw ApiFailure(ApiFailureKind.invalidResponse);
        }
        rows.add(row);
      }
      if (page.length < 50) break;
      offset += page.length;
    }
    if (_disposed || generation != _alertGeneration) return;
    await db.transaction(() async {
      final patients = await (db.select(
        db.dashboardPatients,
      )..where((p) => p.caregiverId.equals(caregiverId))).get();
      if (_disposed || generation != _alertGeneration) return;
      final allowed = patients.map((p) => p.id).toSet();
      final visible = rows
          .where((r) => allowed.contains(r.patientId.value))
          .toList();
      final visibleIds = visible.map((r) => r.id.value).toList();
      await (db.delete(db.dashboardAlerts)..where(
            (a) => a.caregiverId.equals(caregiverId) & a.id.isNotIn(visibleIds),
          ))
          .go();
      for (final row in visible) {
        await _mergeAlert(row);
      }
    });
  }

  Future<DashboardAlertsCompanion> markAlertRead(String id) async {
    final existing =
        await (db.select(db.dashboardAlerts)..where(
              (a) => a.caregiverId.equals(caregiverId) & a.id.equals(id),
            ))
            .getSingleOrNull();
    if (existing == null) throw ApiFailure(ApiFailureKind.invalidResponse);
    try {
      final response = await client.request<dynamic>(
        '/alerts/$id/read',
        method: 'POST',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 || response.data is! Map) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      final row = _alertRow(response.data as Map);
      if (row.id.value != id ||
          row.patientId.value != existing.patientId ||
          row.readAt.value == null) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      ++_alertGeneration;
      return row;
    } on ApiFailure catch (error) {
      if (error.statusCode == 404 && error.code == 'ALERT_NOT_FOUND') {
        ++_alertGeneration;
        await (db.delete(db.dashboardAlerts)..where(
              (a) => a.caregiverId.equals(caregiverId) & a.id.equals(id),
            ))
            .go();
      }
      rethrow;
    }
  }

  String? _firmware(Map raw) {
    final value = raw['firmware_version'];
    if (value != null && value is! String) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return value as String?;
  }

  Future<DashboardPatient?> _devicePatient(String patientId) =>
      (db.select(db.dashboardPatients)..where(
            (p) => p.caregiverId.equals(caregiverId) & p.id.equals(patientId),
          ))
          .getSingleOrNull();

  Future<void> refreshDevices(String patientId) async {
    final generation = ++_deviceGeneration;
    if (await _devicePatient(patientId) == null) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    final raw = _list(await _get('/patients/$patientId/devices'));
    final rows = <DashboardDevicesCompanion>[];
    final ids = <String>{};
    for (final d in raw) {
      final id = _string(d, 'id'), battery = d['battery_level_pct'];
      if (!ids.add(id) ||
          d['patient_id'] != patientId ||
          d['online'] is! bool ||
          (battery != null &&
              (battery is! int || battery < 0 || battery > 100))) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
      rows.add(
        DashboardDevicesCompanion.insert(
          caregiverId: caregiverId,
          patientId: patientId,
          id: id,
          serial: _string(d, 'serial_number'),
          online: d['online'],
          batteryPct: Value(battery as int?),
          firmwareVersion: Value(_firmware(d)),
          pairedAt: Value(
            d['paired_at'] == null ? null : _time(d, 'paired_at'),
          ),
          lastSeenAt: Value(
            d['last_seen_at'] == null ? null : _time(d, 'last_seen_at'),
          ),
        ),
      );
    }
    if (_disposed || generation != _deviceGeneration) return;
    await db.transaction(() async {
      if (_disposed ||
          generation != _deviceGeneration ||
          await _devicePatient(patientId) == null) {
        return;
      }
      await (db.delete(db.dashboardDevices)..where(
            (d) =>
                d.caregiverId.equals(caregiverId) &
                d.patientId.equals(patientId),
          ))
          .go();
      for (final row in rows) {
        await db.into(db.dashboardDevices).insert(row);
      }
    });
  }

  Future<DeviceChange> changeDevice(
    String patientId, {
    bool? memoryEnabled,
    String? unpairId,
  }) async {
    final patient = await _devicePatient(patientId);
    if (patient?.permission != 'manager' ||
        (memoryEnabled == null) == (unpairId == null)) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    if (unpairId != null) {
      final device =
          await (db.select(db.dashboardDevices)..where(
                (d) =>
                    d.caregiverId.equals(caregiverId) &
                    d.patientId.equals(patientId) &
                    d.id.equals(unpairId),
              ))
              .getSingleOrNull();
      if (device == null) throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    final response = await _request(
      unpairId == null ? '/patients/$patientId' : '/devices/$unpairId',
      method: unpairId == null ? 'PATCH' : 'DELETE',
      status: unpairId == null ? 200 : 204,
      data: unpairId == null ? {'memory_capture_enabled': memoryEnabled} : null,
    );
    if (unpairId != null) {
      if (response.statusCode != 204) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
    } else {
      final data = response.data;
      if (response.statusCode != 200 ||
          data is! Map ||
          data['id'] != patientId ||
          data['memory_capture_enabled'] != memoryEnabled) {
        throw ApiFailure(ApiFailureKind.invalidResponse);
      }
    }
    ++_deviceGeneration;
    return unpairId == null
        ? DeviceChange.memory(patientId, memoryEnabled!)
        : DeviceChange.unpaired(patientId, unpairId);
  }

  Future<void> cacheDeviceChange(DeviceChange change) {
    ++_deviceGeneration;
    return db.transaction(() async {
      if (_disposed || await _devicePatient(change.patientId) == null) return;
      if (change.deviceId != null) {
        await (db.delete(db.dashboardDevices)..where(
              (d) =>
                  d.caregiverId.equals(caregiverId) &
                  d.patientId.equals(change.patientId) &
                  d.id.equals(change.deviceId!),
            ))
            .go();
      } else {
        await (db.update(db.dashboardPatients)..where(
              (p) =>
                  p.caregiverId.equals(caregiverId) &
                  p.id.equals(change.patientId),
            ))
            .write(
              DashboardPatientsCompanion(
                memoryCaptureEnabled: Value(change.memoryEnabled!),
              ),
            );
      }
    });
  }

  Future<dynamic> getConsents(String patientId) =>
      _get('/patients/$patientId/consents');

  Future<HomePatient> changeProfile(
    String patientId,
    PatientProfile profile,
  ) async {
    final old = await _devicePatient(patientId);
    if (old?.permission != 'manager' || !profile.isValid) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    final data = <String, Object?>{
      if (profile.name.trim() != old!.fullName)
        'full_name': profile.name.trim(),
      if (profile.language != old.preferredLanguage)
        'preferred_language': profile.language,
      if (profile.timezone != old.timezone) 'timezone': profile.timezone,
    };
    if (data.isEmpty) {
      return HomePatient(
        id: old.id,
        name: old.fullName,
        language: old.preferredLanguage,
        timezone: old.timezone,
        memoryEnabled: old.memoryCaptureEnabled,
        permission: old.permission,
      );
    }
    final response = await _request(
      '/patients/$patientId',
      method: 'PATCH',
      data: data,
    );
    final p = response.data;
    if (p is! Map ||
        p['id'] != patientId ||
        p['full_name'] != profile.name.trim() ||
        p['preferred_language'] != profile.language ||
        p['timezone'] != profile.timezone ||
        p['memory_capture_enabled'] is! bool) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    ++_deviceGeneration;
    return HomePatient(
      id: patientId,
      name: p['full_name'],
      language: p['preferred_language'],
      timezone: p['timezone'],
      memoryEnabled: p['memory_capture_enabled'],
      permission: old.permission,
    );
  }

  Future<void> cacheProfile(HomePatient patient) {
    ++_deviceGeneration;
    return db.transaction(() async {
      if (_disposed || await _devicePatient(patient.id) == null) return;
      await (db.update(db.dashboardPatients)..where(
            (p) => p.caregiverId.equals(caregiverId) & p.id.equals(patient.id),
          ))
          .write(
            DashboardPatientsCompanion(
              fullName: Value(patient.name),
              preferredLanguage: Value(patient.language),
              timezone: Value(patient.timezone),
            ),
          );
    });
  }

  Future<void> cacheAlertRead(
    DashboardAlertsCompanion row,
  ) => db.transaction(() async {
    // Do not recreate an alert belonging to a link removed while the POST ran.
    final patient =
        await (db.select(db.dashboardPatients)..where(
              (p) =>
                  p.caregiverId.equals(caregiverId) &
                  p.id.equals(row.patientId.value),
            ))
            .getSingleOrNull();
    if (patient == null ||
        row.caregiverId.value != caregiverId ||
        row.readAt.value == null) {
      return;
    }
    await _mergeAlert(row);
  });
}
