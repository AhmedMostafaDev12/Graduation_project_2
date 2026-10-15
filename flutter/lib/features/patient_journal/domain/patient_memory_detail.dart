import 'patient_journal_data.dart';

typedef PatientMemoryTarget = ({
  PatientJournalKey journal,
  String eventId,
  String mediaId,
});

class PatientMemoryDetail {
  const PatientMemoryDetail({
    required this.id,
    required this.eventId,
    required this.type,
    required this.status,
    required this.at,
    required this.refreshedAt,
    required this.url,
    required this.validUntil,
    this.eventType,
    this.person,
    this.expiresAt,
    this.retention,
    this.durationSeconds,
  });
  final String id, eventId, type, status, url;
  final String? eventType, retention;
  final JournalPerson? person;
  final DateTime at, refreshedAt, validUntil;
  final DateTime? expiresAt;
  final int? durationSeconds;
  bool expired(DateTime now) =>
      retention != 'keep_indefinitely' &&
      expiresAt != null &&
      !expiresAt!.isAfter(now);
  JournalMedia photo() => JournalMedia(
    id: id,
    type: type,
    trigger: '',
    status: status,
    url: url,
    expiresAt:
        retention != 'keep_indefinitely' &&
            expiresAt != null &&
            expiresAt!.isBefore(validUntil)
        ? expiresAt
        : validUntil,
  );
}
