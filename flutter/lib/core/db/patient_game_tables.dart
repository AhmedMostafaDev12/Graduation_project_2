part of 'remori_database.dart';

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
