part of 'remori_database.dart';

/// C13 allowlisted metadata only. Photo/video bytes never enter SQLite.
class CachedMediaDetails extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}
