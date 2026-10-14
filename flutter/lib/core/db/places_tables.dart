part of 'remori_database.dart';

/// Approved C10 read cache, scoped to its caregiver and patient.
class CachedPlaces extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get radiusM => integer()();
  TextColumn get createdBy => text()();
  IntColumn get updatedAt => integer().map(const UtcMicros())();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class PlacesCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId};
}
