part of 'remori_database.dart';

class CachedReminders extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get spokenText => text().nullable()();
  TextColumn get type => text()();
  TextColumn get rrule => text()();
  IntColumn get dtstart => integer().map(const UtcMicros())();
  TextColumn get timezone => text()();
  BoolColumn get active => boolean()();
  IntColumn get updatedAt => integer().map(const UtcMicros())();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class CachedReminderOccurrences extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get reminderId => text()();
  TextColumn get day => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  IntColumn get scheduledAt => integer().map(const UtcMicros())();
  TextColumn get status => text()();
  IntColumn get snoozedUntil => integer().map(const UtcMicros()).nullable()();
  IntColumn get completedAt => integer().map(const UtcMicros()).nullable()();
  TextColumn get confirmedVia => text().nullable()();
  IntColumn get updatedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}

class ReminderCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get day => text()();
  TextColumn get timezone => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId};
}
