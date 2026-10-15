part of 'remori_database.dart';

class PatientTodaySettings extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get fullName => text()();
  TextColumn get language => text()();
  TextColumn get timezone => text()();
  BoolColumn get memoryEnabled => boolean()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId};
}

class PatientReminderCards extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get id => text()();
  TextColumn get day => text()();
  TextColumn get title => text()();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, id};
}

class PatientKnownEncounters extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get day => text()();
  TextColumn get personId => text()();
  TextColumn get name => text()();
  IntColumn get firstSeen => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, day, personId};
}
