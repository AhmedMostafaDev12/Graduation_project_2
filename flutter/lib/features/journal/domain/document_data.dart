import 'journal_data.dart';

enum DocumentFilter {
  all,
  receipts,
  bills,
  medicationLabels;

  String? get apiType => switch (this) {
    all => null,
    receipts => 'receipt',
    bills => 'bill',
    medicationLabels => 'medication_label',
  };
}

typedef DocumentsKey = (JournalScope, DocumentFilter);

class DocumentCard {
  const DocumentCard({
    required this.id,
    required this.eventId,
    required this.mediaId,
    required this.type,
    required this.capturedAt,
    required this.previewUntil,
    this.title,
    this.headline,
    this.url,
    this.thumbnailUrl,
  });
  final String id, eventId, mediaId, type;
  final String? title, headline, url, thumbnailUrl;
  final DateTime capturedAt, previewUntil;
  JournalMedia? preview() {
    final target = thumbnailUrl ?? url;
    return target == null
        ? null
        : JournalMedia(
            id: id,
            type: 'image',
            trigger: 'document_signal',
            status: 'confirmed',
            url: target,
            expiresAt: previewUntil,
          );
  }
}

class DocumentsData {
  const DocumentsData({
    this.documents = const [],
    this.nextOffset = 0,
    this.hasMore = false,
    this.refreshedAt,
  });
  final List<DocumentCard> documents;
  final int nextOffset;
  final bool hasMore;
  final DateTime? refreshedAt;
}
