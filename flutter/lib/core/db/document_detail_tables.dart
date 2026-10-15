part of 'remori_database.dart';

/// C15 display fields and OCR are approved; raw extracted fields/bytes are not.
class CachedDocumentDetails extends Table {
  TextColumn get caregiverId => text()();
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get mediaAssetId => text()();
  TextColumn get payload => text()();
  IntColumn get refreshedAt => integer().map(const UtcMicros())();
  @override
  Set<Column> get primaryKey => {caregiverId, patientId, id};
}
