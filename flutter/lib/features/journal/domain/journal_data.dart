class JournalScope {
  const JournalScope(this.caregiverId, this.patientId, this.timezone);
  final String caregiverId, patientId, timezone;
  @override
  bool operator ==(Object other) =>
      other is JournalScope &&
      caregiverId == other.caregiverId &&
      patientId == other.patientId &&
      timezone == other.timezone;
  @override
  int get hashCode => Object.hash(caregiverId, patientId, timezone);
}

typedef JournalKey = (JournalScope, String);

class JournalPerson {
  const JournalPerson(this.id, this.name, this.relationship);
  final String id, name, relationship;
}

class JournalDocument {
  const JournalDocument(this.id, this.type, this.title, this.headline);
  final String id, type;
  final String? title, headline;
}

class JournalMedia {
  const JournalMedia({
    required this.id,
    required this.type,
    required this.trigger,
    required this.status,
    required this.url,
    this.thumbnailUrl,
    this.durationSeconds,
    this.expiresAt,
    this.category,
    this.tags = const [],
    this.reason,
  });
  final String id, type, trigger, status, url;
  final String? thumbnailUrl, category, reason;
  final int? durationSeconds;
  final DateTime? expiresAt;
  final List<String> tags;
  String? get previewUrl => thumbnailUrl ?? (type == 'image' ? url : null);
  bool available(DateTime now) => expiresAt == null || expiresAt!.isAfter(now);
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.type,
    required this.source,
    required this.occurredAt,
    this.endedAt,
    this.person,
    this.transcript,
    this.language,
    this.renderedText,
    this.document,
    this.media = const [],
  });
  final String id, type, source;
  final DateTime occurredAt;
  final DateTime? endedAt;
  final JournalPerson? person;
  final String? transcript, language, renderedText;
  final JournalDocument? document;
  final List<JournalMedia> media;
}

class JournalData {
  const JournalData({this.entries = const [], this.refreshedAt});
  final List<JournalEntry> entries;
  final DateTime? refreshedAt;
}

enum JournalFilter {
  all,
  people,
  talk,
  questions,
  reminders,
  media,
  docs;

  bool includes(JournalEntry e) => switch (this) {
    all => true,
    people => e.type == 'encounter',
    talk => e.type == 'conversation_segment',
    questions => e.type == 'voice_query',
    reminders => e.type == 'reminder',
    media =>
      e.media.isNotEmpty ||
          {
            'user_requested_recording',
            'notable_moment_captured',
          }.contains(e.type),
    docs => e.type == 'document_captured',
  };
}
