part of 'remori_database.dart';

class PatientJournalEntries extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get day => text()();
  TextColumn get id => text()();
  IntColumn get occurredAt => integer().map(const UtcMicros())();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, day, id};
}

class PatientJournalMedia extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get day => text()();
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  IntColumn get position => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, day, id};
}

class PatientJournalDays extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get day => text()();
  TextColumn get timezone => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, day};
}

class PatientMemoryDetails extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, id};
}
