part of 'remori_database.dart';

class CachedPeople extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relationship => text()();
  TextColumn get status => text()();
  IntColumn get embeddingCount => integer()();
  IntColumn get updatedAt => integer().map(const UtcMicros())();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class PeopleCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  IntColumn get unknownCount => integer()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId};
}

class PersonDetailStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get personId => text()();
  TextColumn get enrolledByName => text().nullable()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, personId};
}

class CachedPersonPhotos extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get personId => text()();
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, personId, id};
}
