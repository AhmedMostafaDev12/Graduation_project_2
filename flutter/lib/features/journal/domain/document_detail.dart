import 'journal_data.dart';

typedef DocumentDetailKey = (JournalScope, String);

class DocumentField {
  const DocumentField({
    this.key,
    this.label,
    required this.value,
    required this.type,
  });
  final String? key, label;
  final String value, type;
  static const keys = {
    'total',
    'date',
    'items',
    'merchant',
    'issuer',
    'due_date',
    'medication_name',
    'strength',
    'instructions',
    'expiry_date',
  };
}

class DocumentDetail {
  const DocumentDetail({
    required this.id,
    required this.eventId,
    required this.mediaId,
    required this.type,
    required this.capturedAt,
    required this.ocrText,
    required this.fields,
    required this.previewUntil,
    required this.refreshedAt,
    this.title,
    this.url,
  });
  final String id, eventId, mediaId, type, ocrText;
  final String? title, url;
  final DateTime capturedAt, previewUntil, refreshedAt;
  final List<DocumentField> fields;
  JournalMedia? photo() => url == null
      ? null
      : JournalMedia(
          id: id,
          type: 'image',
          trigger: 'document_signal',
          status: 'confirmed',
          url: url!,
          expiresAt: previewUntil,
        );
}
