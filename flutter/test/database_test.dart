import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/db/remori_database.dart';

const patient = '00000001-0000-4000-8000-000000000001';
const otherPatient = '00000001-0000-4000-8000-000000000002';
const reminder = '00000005-0000-4000-8000-000000000001';
final scheduled = DateTime.utc(2026, 10, 13, 9);
final at = scheduled.add(const Duration(minutes: 1));

Future<String> save(
  RemoriDatabase db, {
  String? id,
  String patientId = patient,
  ReminderStatus status = ReminderStatus.pending,
  DateTime? changedAt,
}) => db.saveReminderLog(
  id: id,
  patientId: patientId,
  reminderId: reminder,
  scheduledAt: scheduled,
  status: status,
  at: changedAt ?? at,
  completedAt: status == ReminderStatus.completed ? changedAt ?? at : null,
  confirmedVia: status == ReminderStatus.completed ? 'app' : null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RemoriDatabase db;
  var databaseOpen = true;
  setUp(() => db = RemoriDatabase(NativeDatabase.memory(logStatements: false)));
  tearDown(() async {
    if (databaseOpen) await db.close();
    databaseOpen = true;
  });

  test(
    'local writes and pending API snapshots share a stable client UUID',
    () async {
      final id = await save(db);
      final local = (await db.watchReminderLogs(patient).first).single;
      final pending = (await db.pendingWrites(patient)).single;
      expect(id, matches(RegExp(r'^[0-9a-f-]{14}4[0-9a-f-]{21}$')));
      expect(local.id, id);
      expect(pending.recordId, id);
      expect(pending.id, isNot(id));
      final payload = jsonDecode(pending.payload) as Map;
      expect(payload['id'], id);
      expect(payload['scheduled_at'], scheduled.toIso8601String());
      expect(payload['at'], at.toIso8601String());
      expect(payload.containsKey('patient_id'), isFalse);
      expect(await db.watchPendingCount(patient).first, 1);
    },
  );

  test(
    'an outer rollback removes both the local record and upload snapshot',
    () async {
      await expectLater(
        db.transaction(() async {
          await save(db);
          throw StateError('Test rollback');
        }),
        throwsStateError,
      );
      expect(await db.watchReminderLogs(patient).first, isEmpty);
      expect(await db.pendingWrites(patient), isEmpty);
    },
  );

  test(
    'an outbox insert failure rolls back the already-written local record',
    () async {
      // Simulate a storage constraint failure after the entity has been persisted.
      await db.customStatement(
        "CREATE TRIGGER fail_outbox BEFORE INSERT ON outbox_entries BEGIN SELECT RAISE(ABORT, 'Test failure'); END",
      );
      await expectLater(save(db), throwsA(isA<Exception>()));
      expect(await db.watchReminderLogs(patient).first, isEmpty);
      expect(await db.pendingWrites(patient), isEmpty);
    },
  );

  test(
    'patient reads and acknowledgements cannot cross ownership scopes',
    () async {
      final id = await save(db);
      await save(db, patientId: otherPatient);
      final pending = (await db.pendingWrites(patient)).single;
      expect((await db.watchReminderLogs(patient).first).single.id, id);
      expect(await db.watchPendingCount(otherPatient).first, 1);
      await db.acknowledge(otherPatient, [pending.id]);
      expect(await db.watchPendingCount(patient).first, 1);
      await expectLater(
        save(db, id: id, patientId: otherPatient),
        throwsStateError,
      );
      expect(await db.watchPendingCount(otherPatient).first, 1);
    },
  );

  test('completed wins over newer states and late completion beats an older missed log', () async {
    final id = await save(db, status: ReminderStatus.missed);
    await save(
      db,
      id: id,
      status: ReminderStatus.completed,
      changedAt: at.subtract(const Duration(seconds: 1)),
    );
    await save(
      db,
      id: id,
      status: ReminderStatus.snoozed,
      changedAt: at.add(const Duration(minutes: 5)),
    );
    expect(
      (await db.watchReminderLogs(patient).first).single.status,
      ReminderStatus.completed,
    );
    expect(await db.watchPendingCount(patient).first, 2);
  });

  test('latest timestamp wins otherwise, preserving microseconds and avoiding duplicate writes', () async {
    final precise = at.add(const Duration(microseconds: 500));
    final id = await save(db, changedAt: precise);
    await save(
      db,
      id: id,
      status: ReminderStatus.snoozed,
      changedAt: precise.subtract(const Duration(microseconds: 1)),
    );
    expect(await db.watchPendingCount(patient).first, 1);
    await save(
      db,
      id: id,
      status: ReminderStatus.snoozed,
      changedAt: precise.add(const Duration(microseconds: 1)),
    );
    final local = (await db.watchReminderLogs(patient).first).single;
    expect(local.status, ReminderStatus.snoozed);
    expect(local.updatedAt, precise.add(const Duration(microseconds: 1)));
    await save(
      db,
      id: id,
      status: ReminderStatus.snoozed,
      changedAt: local.updatedAt,
    );
    expect(await db.watchPendingCount(patient).first, 2);
  });

  test(
    'old receipts do not delete newer snapshots or cached records',
    () async {
      final id = await save(db);
      final uploaded = (await db.pendingWrites(patient)).single;
      await save(
        db,
        id: id,
        status: ReminderStatus.completed,
        changedAt: at.add(const Duration(seconds: 1)),
      );
      await db.acknowledge(patient, [uploaded.id]);
      final remaining = (await db.pendingWrites(patient)).single;
      expect(remaining.recordId, id);
      expect((jsonDecode(remaining.payload) as Map)['status'], 'completed');
      expect(await db.watchReminderLogs(patient).first, hasLength(1));
    },
  );

  test('queue order and batch limits are deterministic', () async {
    final ids = [await save(db), await save(db), await save(db)];
    final batch = await db.pendingWrites(patient, limit: 2);
    expect(batch.map((row) => row.recordId), ids.take(2));
    expect(() => db.pendingWrites(patient, limit: 501), throwsArgumentError);
  });

  test(
    'local data and queued writes persist across database restarts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'remori-db-test-',
      );
      final file = File.fromUri(directory.uri.resolve('test.sqlite'));
      await db.close();
      db = RemoriDatabase(NativeDatabase(file, logStatements: false));
      try {
        final id = await save(db);
        await db.close();
        db = RemoriDatabase(NativeDatabase(file, logStatements: false));
        expect((await db.watchReminderLogs(patient).first).single.id, id);
        expect((await db.pendingWrites(patient)).single.recordId, id);
      } finally {
        await db.close();
        databaseOpen = false;
        if (await file.exists()) await file.delete();
        await directory.delete();
      }
    },
  );
}
