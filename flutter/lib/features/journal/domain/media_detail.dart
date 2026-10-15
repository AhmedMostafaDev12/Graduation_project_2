import 'journal_data.dart';

typedef MediaKey = (JournalScope, String);

class MediaDetail {
  const MediaDetail({
    required this.id,
    required this.patientId,
    required this.eventId,
    required this.type,
    required this.trigger,
    required this.status,
    required this.createdAt,
    required this.refreshedAt,
    this.retention,
    this.expiresAt,
    this.pinnedBy,
    this.containsOtherPeople,
    this.durationSeconds,
    this.url,
    this.urlValidUntil,
    this.eventType,
    this.occurredAt,
    this.person,
    this.category,
    this.tags = const [],
    this.reason,
  });
  final String id, patientId, eventId, type, trigger, status;
  final String? retention, pinnedBy, url, eventType, category, reason;
  final DateTime createdAt, refreshedAt;
  final DateTime? expiresAt, urlValidUntil, occurredAt;
  final bool? containsOtherPeople;
  final int? durationSeconds;
  final JournalPerson? person;
  final List<String> tags;
  bool get kept => retention == 'keep_indefinitely';
  bool expired(DateTime now) =>
      !kept && expiresAt != null && !expiresAt!.isAfter(now);
  JournalMedia photo() => JournalMedia(
    id: id,
    type: type,
    trigger: trigger,
    status: status,
    url: url ?? '',
    expiresAt: expiresAt == null || kept
        ? urlValidUntil
        : urlValidUntil == null || expiresAt!.isBefore(urlValidUntil!)
        ? expiresAt
        : urlValidUntil,
  );
}

class MediaReceipt {
  const MediaReceipt({required this.deleted, this.payload});
  final bool deleted;
  final Map<String, Object?>? payload;
}
