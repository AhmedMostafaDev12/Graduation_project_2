part of 'remori_database.dart';

/// Read caches are scoped to the authenticated caregiver, never an auth grant.
class DashboardPatients extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get preferredLanguage => text()();
  TextColumn get timezone => text()();
  BoolColumn get memoryCaptureEnabled => boolean()();
  TextColumn get permission => text()();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, id};
}

class DashboardDevices extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get serial => text()();
  BoolColumn get online => boolean()();
  IntColumn get batteryPct => integer().nullable()();
  IntColumn get lastSeenAt => integer().map(const UtcMicros()).nullable()();
  @override
  Set<Column> get primaryKey => {caregiverId, id};
}

class DashboardAlerts extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get alertType => text()();
  TextColumn get message => text()();
  IntColumn get createdAt => integer().map(const UtcMicros())();
  IntColumn get readAt => integer().map(const UtcMicros()).nullable()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  @override
  Set<Column> get primaryKey => {caregiverId, id};
}

class DashboardDays extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get day => text()();
  IntColumn get peopleMet => integer()();
  IntColumn get remindersDone => integer()();
  IntColumn get remindersTotal => integer()();
  IntColumn get snoozed => integer()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, day};
}
