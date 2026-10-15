part of 'remori_database.dart';

/// Display data only. Authentication tokens remain in secure storage.
class CachedCaregiverAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {id};
}

class CachedConsents extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}
