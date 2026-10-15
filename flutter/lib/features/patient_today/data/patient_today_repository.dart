import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_today_data.dart';

class PatientTodayRepository {
  PatientTodayRepository(
    this.client,
    this.db,
    this.key,
    this.clock, {
    required this.current,
  });
  final ApiClient client;
  final RemoriDatabase db;
  final PatientTodayKey key;
  final DateTime Function() clock;
  final bool Function() current;
  final _cancel = CancelToken();
  bool _disposed = false, _uploading = false;
  int _generation = 0;
  bool get _active => !_disposed && current();
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

  DateTime _time(Map p, String k) {
    final t = DateTime.tryParse(_text(p, k));
    if (t == null || !t.isUtc) throw _invalid;
    return t;
  }

  Future<dynamic> _get(String suffix, [Map<String, dynamic>? query]) async {
    if (!_active) throw ApiFailure(ApiFailureKind.cancelled);
    final response = await client.request<dynamic>(
      '/patients/${key.$1}/$suffix',
      credential: ApiCredential.device,
      queryParameters: query,
      cancelToken: _cancel,
    );
    if (response.statusCode != 200) throw _invalid;
    return response.data;
  }

  Expression<bool> _settings(PatientTodaySettings r) =>
      r.patientId.equals(key.$1) & r.deviceId.equals(key.$2);
  Expression<bool> _cards(PatientReminderCards r) =>
      r.patientId.equals(key.$1) & r.deviceId.equals(key.$2);
  Expression<bool> _people(PatientKnownEncounters r) =>
      r.patientId.equals(key.$1) & r.deviceId.equals(key.$2);
  Future<void> refresh() async {
    if (!_active) return;
    final generation = ++_generation;
    final sync = await _get('sync');
    if (sync is! Map || sync['settings'] is! Map) throw _invalid;
    final settings = sync['settings'] as Map;
    final name = _text(settings, 'full_name'),
        language = _text(settings, 'preferred_language'),
        zone = _text(settings, 'timezone');
    if (!{'ar', 'en'}.contains(language) ||
        settings['memory_capture_enabled'] is! bool) {
      throw _invalid;
    }
    try {
      PatientTime.location(zone);
    } catch (_) {
      throw _invalid;
    }
    final day = PatientTime.day(clock(), zone);
    final responses = await Future.wait([
      _get('reminder-logs', {'date': day}),
      _get('journal', {'date': day}),
    ]);
    final logs = responses[0], journal = responses[1];
    if (logs is! List ||
        journal is! Map ||
        journal['date'] != day ||
        journal['timezone'] != zone ||
        journal['entries'] is! List) {
      throw _invalid;
    }
    final incoming = <ReminderLogsCompanion>[],
        cards = <PatientReminderCardsCompanion>[],
        people = <String, PatientKnownEncountersCompanion>{},
        ids = <String>{};
    for (final raw in logs) {
      if (raw is! Map ||
          (raw.containsKey('patient_id') && raw['patient_id'] != key.$1)) {
        throw _invalid;
      }
      final id = _text(raw, 'id'),
          reminderId = _text(raw, 'reminder_id'),
          status = _text(raw, 'status');
      final scheduled = _time(raw, 'scheduled_at');
      if (!ids.add(id) ||
          !ReminderStatus.values.any((v) => v.name == status) ||
          PatientTime.day(scheduled, zone) != day) {
        throw _invalid;
      }
      final snoozed = raw['snoozed_until'] == null
              ? null
              : _time(raw, 'snoozed_until'),
          completed = raw['completed_at'] == null
              ? null
              : _time(raw, 'completed_at'),
          via = raw['confirmed_via'];
      if (via != null && !{'app', 'voice', 'caregiver'}.contains(via)) {
        throw _invalid;
      }
      incoming.add(
        ReminderLogsCompanion.insert(
          id: id,
          patientId: key.$1,
          reminderId: reminderId,
          scheduledAt: scheduled,
          status: ReminderStatus.values.byName(status),
          snoozedUntil: Value(snoozed),
          completedAt: Value(completed),
          confirmedVia: Value(via as String?),
          updatedAt: _time(raw, 'updated_at'),
        ),
      );
      cards.add(
        PatientReminderCardsCompanion.insert(
          patientId: key.$1,
          deviceId: key.$2,
          id: id,
          day: day,
          title: _text(raw, 'title'),
        ),
      );
    }
    for (final raw in journal['entries'] as List) {
      if (raw is! Map) throw _invalid;
      if (raw['event_type'] != 'encounter' || raw['person'] == null) continue;
      if (raw['person'] is! Map ||
          (raw.containsKey('patient_id') && raw['patient_id'] != key.$1)) {
        throw _invalid;
      }
      final p = raw['person'] as Map, seen = _time(raw, 'occurred_at');
      if (PatientTime.day(seen, zone) != day) throw _invalid;
      final id = _text(p, 'id'), old = people[id];
      if (old == null || seen.isBefore(old.firstSeen.value)) {
        people[id] = PatientKnownEncountersCompanion.insert(
          patientId: key.$1,
          deviceId: key.$2,
          day: day,
          personId: id,
          name: _text(p, 'name'),
          firstSeen: seen,
        );
      }
    }
    if (!_active || generation != _generation) return;
    await db.transaction(() async {
      if (!_active || generation != _generation) return;
      await db
          .into(db.patientTodaySettings)
          .insert(
            PatientTodaySettingsCompanion.insert(
              patientId: key.$1,
              deviceId: key.$2,
              fullName: name,
              language: language,
              timezone: zone,
              memoryEnabled: settings['memory_capture_enabled'],
              refreshedAt: clock(),
            ),
            mode: InsertMode.insertOrReplace,
          );
      await (db.delete(
        db.patientReminderCards,
      )..where((r) => _cards(r) & r.day.equals(day))).go();
      for (var i = 0; i < incoming.length; i++) {
        final row = incoming[i];
        final old = await (db.select(
          db.reminderLogs,
        )..where((r) => r.id.equals(row.id.value))).getSingleOrNull();
        if (old != null &&
            (old.patientId != key.$1 ||
                old.reminderId != row.reminderId.value ||
                old.scheduledAt != row.scheduledAt.value)) {
          throw _invalid;
        }
        if (old == null ||
            (old.status != ReminderStatus.completed &&
                (row.status.value == ReminderStatus.completed ||
                    row.updatedAt.value.isAfter(old.updatedAt)))) {
          await db
              .into(db.reminderLogs)
              .insert(row, mode: InsertMode.insertOrReplace);
        }
        await db
            .into(db.patientReminderCards)
            .insert(cards[i], mode: InsertMode.insertOrReplace);
      }
      await (db.delete(
        db.patientKnownEncounters,
      )..where((r) => _people(r) & r.day.equals(day))).go();
      for (final person in people.values) {
        await db.into(db.patientKnownEncounters).insert(person);
      }
    });
  }

  Future<void> act(String id, {required bool snooze}) async {
    if (!_active) return;
    final data = await read();
    if (!_active || data.next?.id != id) return;
    final log =
        await (db.select(db.reminderLogs)
              ..where((r) => r.id.equals(id) & r.patientId.equals(key.$1)))
            .getSingleOrNull();
    if (log == null || !_active) return;
    final now = clock().toUtc();
    ++_generation;
    await db.saveReminderLog(
      id: log.id,
      patientId: key.$1,
      reminderId: log.reminderId,
      scheduledAt: log.scheduledAt,
      status: snooze ? ReminderStatus.snoozed : ReminderStatus.completed,
      at: now,
      snoozedUntil: snooze ? now.add(const Duration(minutes: 15)) : null,
      completedAt: snooze ? null : now,
      confirmedVia: 'app',
    );
  }

  Future<void> upload() async {
    if (!_active || _uploading) return;
    _uploading = true;
    try {
      final cards = await (db.select(
        db.patientReminderCards,
      )..where(_cards)).get();
      final ids = cards.map((c) => c.id).toSet();
      final pending =
          await (db.select(db.outboxEntries)
                ..where(
                  (r) =>
                      r.patientId.equals(key.$1) &
                      r.kind.equalsValue(OutboxKind.reminderLog) &
                      r.recordId.isIn(ids),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.sequence)])
                ..limit(500))
              .get();
      if (pending.isEmpty || !_active) return;
      final latest = <String, Map>{};
      for (final p in pending) {
        latest[p.recordId] = jsonDecode(p.payload) as Map;
      }
      final response = await client.request<dynamic>(
        '/patients/${key.$1}/reminder-logs:batch',
        credential: ApiCredential.device,
        method: 'POST',
        data: {'logs': latest.values.toList()},
        cancelToken: _cancel,
      );
      final body = response.data;
      if (response.statusCode != 200 || body is! Map) throw _invalid;
      final all = <String>{}, acknowledged = <String>{};
      for (final field in ['accepted', 'duplicates', 'rejected']) {
        final values = body[field];
        if (values is! List) throw _invalid;
        for (final id in values) {
          if (id is! String || !latest.containsKey(id) || !all.add(id)) {
            throw _invalid;
          }
          if (field != 'rejected') acknowledged.add(id);
        }
      }
      if (all.length != latest.length) throw _invalid;
      if (_active) {
        await db.acknowledge(
          key.$1,
          pending
              .where((p) => acknowledged.contains(p.recordId))
              .map((p) => p.id),
        );
      }
    } finally {
      _uploading = false;
    }
  }

  Stream<PatientTodayData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.patientTodaySettings,
          db.patientReminderCards,
          db.patientKnownEncounters,
          db.reminderLogs,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<PatientTodayData> read() => db.transaction(() async {
    final settings = await (db.select(
      db.patientTodaySettings,
    )..where(_settings)).getSingleOrNull();
    if (settings == null) return const PatientTodayData();
    final day = PatientTime.day(clock(), settings.timezone);
    final cards = await (db.select(
      db.patientReminderCards,
    )..where((r) => _cards(r) & r.day.equals(day))).get();
    final logs =
        await (db.select(db.reminderLogs)..where(
              (r) =>
                  r.patientId.equals(key.$1) &
                  r.id.isIn(cards.map((c) => c.id)),
            ))
            .get();
    final next =
        logs
            .where(
              (r) =>
                  r.status == ReminderStatus.pending ||
                  r.status == ReminderStatus.snoozed,
            )
            .toList()
          ..sort(
            (a, b) => (a.snoozedUntil ?? a.scheduledAt).compareTo(
              b.snoozedUntil ?? b.scheduledAt,
            ),
          );
    final people =
        await (db.select(db.patientKnownEncounters)
              ..where((r) => _people(r) & r.day.equals(day))
              ..orderBy([(r) => OrderingTerm.asc(r.firstSeen)])
              ..limit(3))
            .get();
    final first = next.firstOrNull;
    return PatientTodayData(
      settings: PatientSettings(
        settings.fullName,
        settings.language,
        settings.timezone,
        settings.memoryEnabled,
      ),
      next: first == null
          ? null
          : PatientReminder(
              first.id,
              cards.firstWhere((c) => c.id == first.id).title,
              first.snoozedUntil ?? first.scheduledAt,
            ),
      people: people.map((p) => MetPerson(p.personId, p.name)).toList(),
    );
  });
}
