import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/reminder_data.dart';

class RemindersRepository {
  RemindersRepository(this.client, this.db, this.scope);
  final ApiClient client;
  final RemoriDatabase db;
  final ReminderScope scope;
  final _cancel = CancelToken();
  bool _disposed = false;
  int _refreshGeneration = 0;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  String get _path => '/patients/${scope.patientId}';
  Expression<bool> _definitions(CachedReminders p) =>
      p.caregiverId.equals(scope.caregiverId) &
      p.patientId.equals(scope.patientId);
  Expression<bool> _occurrences(CachedReminderOccurrences p) =>
      p.caregiverId.equals(scope.caregiverId) &
      p.patientId.equals(scope.patientId);
  Expression<bool> _states(ReminderCacheStates p) =>
      p.caregiverId.equals(scope.caregiverId) &
      p.patientId.equals(scope.patientId);
  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _string(Map raw, String key) {
    final value = raw[key];
    if (value is! String || value.trim().isEmpty) throw _invalid;
    return value;
  }

  DateTime _date(Object? value) {
    if (value is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw _invalid;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _invalid;
    return parsed.toUtc();
  }

  DateTime? _optionalDate(Object? value) => value == null ? null : _date(value);
  String _kind(Map raw) {
    final type = _string(raw, 'type');
    if (!ReminderKind.values.any((k) => k.name == type)) throw _invalid;
    return type;
  }

  List<Map> _list(Response<dynamic> response) {
    if (response.statusCode != 200 ||
        response.data is! List ||
        (response.data as List).any((v) => v is! Map)) {
      throw _invalid;
    }
    return (response.data as List).cast<Map>();
  }

  CachedRemindersCompanion _definition(Map raw, int position) {
    if (raw['patient_id'] != scope.patientId ||
        raw['active'] is! bool ||
        raw['deleted_at'] != null ||
        (raw['spoken_text'] != null && raw['spoken_text'] is! String)) {
      throw _invalid;
    }
    final timezone = _string(raw, 'timezone');
    try {
      PatientTime.location(timezone);
    } catch (_) {
      throw _invalid;
    }
    return CachedRemindersCompanion.insert(
      caregiverId: scope.caregiverId,
      patientId: scope.patientId,
      id: _string(raw, 'id'),
      title: _string(raw, 'title'),
      spokenText: Value(raw['spoken_text'] as String?),
      type: _kind(raw),
      rrule: _string(raw, 'rrule'),
      dtstart: _date(raw['dtstart']),
      timezone: timezone,
      active: raw['active'],
      updatedAt: _date(raw['updated_at']),
      position: position,
    );
  }

  Future<void> refresh(String day) async {
    final generation = ++_refreshGeneration;
    try {
      final responses = await Future.wait([
        client.request<dynamic>(
          '$_path/reminders',
          credential: ApiCredential.caregiver,
          cancelToken: _cancel,
        ),
        client.request<dynamic>(
          '$_path/reminder-logs',
          credential: ApiCredential.caregiver,
          queryParameters: {'date': day},
          cancelToken: _cancel,
        ),
      ]);
      final definitions = _list(responses[0]),
          occurrences = _list(responses[1]);
      final rows = <CachedRemindersCompanion>[],
          logs = <CachedReminderOccurrencesCompanion>[];
      final ids = <String>{};
      for (var i = 0; i < definitions.length; i++) {
        final row = _definition(definitions[i], i);
        if (!ids.add(row.id.value)) throw _invalid;
        rows.add(row);
      }
      ids.clear();
      for (final log in occurrences) {
        final id = _string(log, 'id'), status = _string(log, 'status');
        final scheduled = _date(log['scheduled_at']);
        final via = log['confirmed_via'];
        if (!ids.add(id) ||
            !['pending', 'completed', 'snoozed', 'missed'].contains(status) ||
            (via != null && !['voice', 'app', 'caregiver'].contains(via)) ||
            PatientTime.day(scheduled, scope.timezone) != day) {
          throw _invalid;
        }
        logs.add(
          CachedReminderOccurrencesCompanion.insert(
            caregiverId: scope.caregiverId,
            patientId: scope.patientId,
            id: id,
            reminderId: _string(log, 'reminder_id'),
            day: day,
            title: _string(log, 'title'),
            type: _kind(log),
            scheduledAt: scheduled,
            status: status,
            snoozedUntil: Value(_optionalDate(log['snoozed_until'])),
            completedAt: Value(_optionalDate(log['completed_at'])),
            confirmedVia: Value(via as String?),
            updatedAt: _date(log['updated_at']),
          ),
        );
      }
      if (_disposed || generation != _refreshGeneration) return;
      await db.transaction(() async {
        final previous = await (db.select(
          db.cachedReminders,
        )..where(_definitions)).get();
        final latest = {for (final row in previous) row.id: row};
        await (db.delete(db.cachedReminders)..where(_definitions)).go();
        await (db.delete(
          db.cachedReminderOccurrences,
        )..where(_occurrences)).go();
        for (final row in rows) {
          final cached = latest[row.id.value];
          await db
              .into(db.cachedReminders)
              .insert(
                cached != null && cached.updatedAt.isAfter(row.updatedAt.value)
                    ? cached.toCompanion(false)
                    : row,
              );
        }
        for (final row in logs) {
          await db.into(db.cachedReminderOccurrences).insert(row);
        }
        await db
            .into(db.reminderCacheStates)
            .insert(
              ReminderCacheStatesCompanion.insert(
                caregiverId: scope.caregiverId,
                patientId: scope.patientId,
                day: day,
                timezone: scope.timezone,
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

  Future<CachedRemindersCompanion> toggle(String id, bool active) async {
    final existing = await (db.select(
      db.cachedReminders,
    )..where((r) => _definitions(r) & r.id.equals(id))).getSingleOrNull();
    if (existing == null) throw _invalid;
    try {
      final response = await client.request<dynamic>(
        '$_path/reminders/$id',
        method: 'PATCH',
        credential: ApiCredential.caregiver,
        data: {'active': active},
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 || response.data is! Map) throw _invalid;
      final value = _definition(response.data as Map, existing.position);
      if (value.id.value != id || value.active.value != active) throw _invalid;
      return value;
    } on ApiFailure catch (error) {
      if (error.statusCode == 404 && error.code == 'REMINDER_NOT_FOUND') {
        await (db.delete(
          db.cachedReminders,
        )..where((r) => _definitions(r) & r.id.equals(id))).go();
      } else if (error.statusCode == 404 && error.code == 'PATIENT_NOT_FOUND') {
        await purge();
      }
      rethrow;
    }
  }

  Future<void> cacheToggle(CachedRemindersCompanion row) => db.transaction(
    () async {
      final previous =
          await (db.select(db.cachedReminders)
                ..where((r) => _definitions(r) & r.id.equals(row.id.value)))
              .getSingleOrNull();
      if (previous != null && previous.updatedAt.isAfter(row.updatedAt.value)) {
        return;
      }
      await db
          .into(db.cachedReminders)
          .insert(row, mode: InsertMode.insertOrReplace);
    },
  );
  Future<void> purge() => db.transaction(() async {
    await (db.delete(db.cachedReminders)..where(_definitions)).go();
    await (db.delete(db.cachedReminderOccurrences)..where(_occurrences)).go();
    await (db.delete(db.reminderCacheStates)..where(_states)).go();
  });
  Stream<ReminderListData> watch(String day) => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedReminders,
          db.cachedReminderOccurrences,
          db.reminderCacheStates,
        },
      )
      .watch()
      .asyncMap((_) => read(day));
  Future<ReminderListData> read(String day) => db.transaction(() async {
    final definitions =
        await (db.select(db.cachedReminders)
              ..where(_definitions)
              ..orderBy([(r) => OrderingTerm.asc(r.position)]))
            .get();
    final state = await (db.select(
      db.reminderCacheStates,
    )..where(_states)).getSingleOrNull();
    final todayAvailable =
        state?.day == day && state?.timezone == scope.timezone;
    final logs = todayAvailable
        ? await (db.select(db.cachedReminderOccurrences)
                ..where((r) => _occurrences(r) & r.day.equals(day))
                ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
              .get()
        : <CachedReminderOccurrence>[];
    return ReminderListData(
      refreshedAt: state?.refreshedAt,
      todayAvailable: todayAvailable,
      reminders: [
        for (final r in definitions)
          CaregiverReminder(
            id: r.id,
            title: r.title,
            kind: ReminderKind.values.byName(r.type),
            rrule: r.rrule,
            dtstart: r.dtstart,
            timezone: r.timezone,
            active: r.active,
          ),
      ],
      occurrences: [
        for (final r in logs)
          ReminderOccurrence(
            id: r.id,
            reminderId: r.reminderId,
            title: r.title,
            kind: ReminderKind.values.byName(r.type),
            scheduledAt: r.scheduledAt,
            status: r.status,
            snoozedUntil: r.snoozedUntil,
            completedAt: r.completedAt,
            confirmedVia: r.confirmedVia,
          ),
      ],
    );
  });
}
