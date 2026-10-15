part of 'remori_database.dart';

/// C12 allowlisted API text/metadata only: never raw metadata or media bytes.
class CachedJournalEntries extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get day => text()();
  TextColumn get id => text()();
  IntColumn get occurredAt => integer().map(const UtcMicros())();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, day, id};
}

class CachedJournalMedia extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get day => text()();
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get payload => text()();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, day, id};
}

class JournalCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get day => text()();
  TextColumn get timezone => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, day};
}
