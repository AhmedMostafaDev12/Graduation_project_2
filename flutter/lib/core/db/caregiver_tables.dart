part of 'remori_database.dart';

class CachedCaregiverLinks extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class CaregiversCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId};
}
