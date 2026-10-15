part of 'remori_database.dart';

/// C14 card metadata only; no OCR, extracted fields or image bytes.
class CachedDocuments extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get filter => text()();
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get mediaAssetId => text()();
  TextColumn get documentType => text()();
  TextColumn get title => text().nullable()();
  TextColumn get headline => text().nullable()();
  IntColumn get capturedAt => integer().map(const UtcMicros())();
  TextColumn get url => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get previewUntil => integer().map(const UtcMicros())();
  IntColumn get position => integer()();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, filter, id};
}

class DocumentsCacheStates extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get filter => text()();
  IntColumn get nextOffset => integer()();
  BoolColumn get hasMore => boolean()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, filter};
}
