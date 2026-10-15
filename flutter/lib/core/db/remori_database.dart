import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'remori_database.g.dart';
part 'dashboard_tables.dart';
part 'people_tables.dart';
part 'reminder_cache_tables.dart';
part 'unknown_faces_tables.dart';
part 'places_tables.dart';
part 'journal_tables.dart';
part 'media_tables.dart';
part 'document_tables.dart';
part 'document_detail_tables.dart';

enum ReminderStatus { pending, completed, snoozed, missed }

enum OutboxKind { event, encounter, reminderLog, gameSession }

/// SQLite integers preserve subsecond ordering and UTC across restarts.
class UtcMicros extends TypeConverter<DateTime, int> {
  const UtcMicros();
  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);
  @override
  int toSql(DateTime value) => value.toUtc().microsecondsSinceEpoch;
}

@DataClassName('LocalReminderLog')
class ReminderLogs extends Table {
  TextColumn get id => text()();
  // Local ownership scope comes from the parent reminder/API patient path.
  TextColumn get patientId => text()();
  TextColumn get reminderId => text()();
  IntColumn get scheduledAt => integer().map(const UtcMicros())();
  TextColumn get status =>
      text().map(EnumNameConverter(ReminderStatus.values))();
  IntColumn get snoozedUntil => integer().map(const UtcMicros()).nullable()();
  IntColumn get completedAt => integer().map(const UtcMicros()).nullable()();
  TextColumn get confirmedVia => text().nullable()();
  IntColumn get updatedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PendingWrite')
class OutboxEntries extends Table {
  // Local ordering and receipt IDs are transport metadata, never API fields.
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get patientId => text()();
  TextColumn get kind => text().map(EnumNameConverter(OutboxKind.values))();
  TextColumn get recordId => text()();
  TextColumn get payload => text()();
}

@DriftDatabase(
  tables: [
    ReminderLogs,
    OutboxEntries,
    DashboardPatients,
    DashboardDevices,
    DashboardAlerts,
    DashboardDays,
    CachedPeople,
    PeopleCacheStates,
    PersonDetailStates,
    CachedPersonPhotos,
    CachedReminders,
    CachedReminderOccurrences,
    ReminderCacheStates,
    CachedUnknownFaces,
    UnknownFacesCacheStates,
    CachedUnknownFaceSamples,
    CachedPlaces,
    PlacesCacheStates,
    CachedJournalEntries,
    CachedJournalMedia,
    JournalCacheStates,
    CachedMediaDetails,
    CachedDocuments,
    DocumentsCacheStates,
    CachedDocumentDetails,
  ],
)
class RemoriDatabase extends _$RemoriDatabase {
  RemoriDatabase(super.executor);
  @override
  int get schemaVersion => 13;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(dashboardPatients);
        await m.createTable(dashboardDevices);
        await m.createTable(dashboardAlerts);
        await m.createTable(dashboardDays);
      }
      if (from < 3) {
        await m.createTable(cachedPeople);
        await m.createTable(peopleCacheStates);
      }
      if (from < 4) {
        await m.createTable(personDetailStates);
        await m.createTable(cachedPersonPhotos);
      }
      if (from < 5) {
        await m.createTable(cachedReminders);
        await m.createTable(cachedReminderOccurrences);
        await m.createTable(reminderCacheStates);
      }
      if (from < 6) {
        await m.createTable(cachedUnknownFaces);
        await m.createTable(unknownFacesCacheStates);
      }
      if (from < 7) {
        await m.createTable(cachedUnknownFaceSamples);
      }
      if (from < 8) {
        await m.createTable(cachedPlaces);
        await m.createTable(placesCacheStates);
      }
      if (from < 9) {
        await m.createTable(cachedJournalEntries);
        await m.createTable(cachedJournalMedia);
        await m.createTable(journalCacheStates);
      }
      if (from < 10) {
        await m.createTable(cachedMediaDetails);
      }
      if (from < 11) {
        await m.createTable(cachedDocuments);
        await m.createTable(documentsCacheStates);
      }
      if (from < 12) {
        await m.createTable(cachedDocumentDetails);
      }
      if (from >= 2 && from < 13) {
        await m.addColumn(dashboardDevices, dashboardDevices.firmwareVersion);
        await m.addColumn(dashboardDevices, dashboardDevices.pairedAt);
      }
    },
  );

  static const _uuid = Uuid();
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  String newRecordId() => _uuid.v4();

  void _validateId(String id) {
    if (!_uuidPattern.hasMatch(id)) throw ArgumentError('Expected a UUID v4.');
  }

  /// Repositories persist a local entity and its immutable upload snapshot in
  /// one transaction. New feature tables are added by their implementation PRs.
  Future<String> writeAndEnqueue({
    required String patientId,
    required OutboxKind kind,
    required Map<String, Object?> payload,
    required Future<void> Function() writeLocal,
  }) async {
    _validateId(patientId);
    final recordId = payload['id'];
    if (recordId is! String) {
      throw ArgumentError('An upload record needs its client UUID.');
    }
    _validateId(recordId);
    final encoded = jsonEncode(payload);
    final operationId = newRecordId();
    return transaction(() async {
      await writeLocal();
      await into(outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: operationId,
          patientId: patientId,
          kind: kind,
          recordId: recordId,
          payload: encoded,
        ),
      );
      return operationId;
    });
  }

  /// D6: completion wins; otherwise use the latest `at`. The occurrence UUID
  /// remains stable across confirmations; each upload snapshot has its own ID.
  Future<String> saveReminderLog({
    String? id,
    required String patientId,
    required String reminderId,
    required DateTime scheduledAt,
    required ReminderStatus status,
    required DateTime at,
    DateTime? snoozedUntil,
    DateTime? completedAt,
    String? confirmedVia,
  }) async {
    final logId = id ?? newRecordId();
    _validateId(logId);
    _validateId(patientId);
    _validateId(reminderId);
    if (confirmedVia != null &&
        !const {'voice', 'app', 'caregiver'}.contains(confirmedVia)) {
      throw ArgumentError('Unsupported confirmation source.');
    }
    return transaction(() async {
      final previous = await (select(
        reminderLogs,
      )..where((row) => row.id.equals(logId))).getSingleOrNull();
      if (previous != null) {
        if (previous.patientId != patientId ||
            previous.reminderId != reminderId ||
            previous.scheduledAt != scheduledAt.toUtc()) {
          throw StateError(
            'An occurrence cannot change ownership or schedule.',
          );
        }
        if (previous.status == ReminderStatus.completed &&
            status != ReminderStatus.completed) {
          return logId;
        }
        if (!(status == ReminderStatus.completed &&
                previous.status != ReminderStatus.completed) &&
            !at.isAfter(previous.updatedAt)) {
          return logId;
        }
      }
      final payload = <String, Object?>{
        'id': logId,
        'reminder_id': reminderId,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'status': status.name,
        'snoozed_until': snoozedUntil?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'confirmed_via': confirmedVia,
        'at': at.toUtc().toIso8601String(),
      };
      await writeAndEnqueue(
        patientId: patientId,
        kind: OutboxKind.reminderLog,
        payload: payload,
        writeLocal: () => into(reminderLogs)
            .insertOnConflictUpdate(
              ReminderLogsCompanion.insert(
                id: logId,
                patientId: patientId,
                reminderId: reminderId,
                scheduledAt: scheduledAt.toUtc(),
                status: status,
                snoozedUntil: Value(snoozedUntil?.toUtc()),
                completedAt: Value(completedAt?.toUtc()),
                confirmedVia: Value(confirmedVia),
                updatedAt: at.toUtc(),
              ),
            )
            .then((_) {}),
      );
      return logId;
    });
  }

  Stream<List<LocalReminderLog>> watchReminderLogs(String patientId) =>
      (select(reminderLogs)
            ..where((row) => row.patientId.equals(patientId))
            ..orderBy([(row) => OrderingTerm.asc(row.scheduledAt)]))
          .watch();

  Future<List<PendingWrite>> pendingWrites(
    String patientId, {
    int limit = 500,
  }) {
    if (limit < 1 || limit > 500) {
      throw ArgumentError('Batch limit must be 1-500.');
    }
    return (select(outboxEntries)
          ..where((row) => row.patientId.equals(patientId))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)])
          ..limit(limit))
        .get();
  }

  Stream<int> watchPendingCount(String patientId) {
    final count = outboxEntries.sequence.count();
    return (selectOnly(outboxEntries)
          ..addColumns([count])
          ..where(outboxEntries.patientId.equals(patientId)))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Only acknowledge captured operation IDs after successful API receipt.
  /// An old receipt cannot remove a newer snapshot of the same occurrence.
  Future<void> acknowledge(
    String patientId,
    Iterable<String> operationIds,
  ) async {
    final ids = operationIds.toList(growable: false);
    if (ids.isEmpty) return;
    await (delete(
      outboxEntries,
    )..where((row) => row.patientId.equals(patientId) & row.id.isIn(ids))).go();
  }
}
