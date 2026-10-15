part of 'remori_database.dart';

class PatientGamePeople extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get photoUrl => text()();
  IntColumn get validUntil => integer().map(const UtcMicros())();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, id};
}

@DataClassName('LocalPatientGameSession')
class PatientGameSessions extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get id => text()();
  IntColumn get score => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get completedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, id};
}

class PatientGameScores extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get gameType => text()();
  TextColumn get sessionId => text()();
  IntColumn get score => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get completedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, gameType};
}

class PatientGameRefreshes extends Table {
  TextColumn get patientId => text()();
  TextColumn get deviceId => text()();
  TextColumn get gameType => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {patientId, deviceId, gameType};
}
