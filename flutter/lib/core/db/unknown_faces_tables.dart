part of 'remori_database.dart';

/// C6 read metadata only. Face bytes and embeddings never enter SQLite.
class CachedUnknownFaces extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  IntColumn get sightingCount => integer()();
  IntColumn get distinctDays => integer()();
  IntColumn get firstSeenAt => integer().map(const UtcMicros())();
  IntColumn get lastSeenAt => integer().map(const UtcMicros())();
  TextColumn get sampleId => text().nullable()();
  TextColumn get sampleUrl => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class UnknownFacesCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId};
}
