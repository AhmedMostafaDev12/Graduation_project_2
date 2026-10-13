/// The A4 request matches POST /patients; dates are calendar dates, not UTC instants.
class PatientDraft {
  const PatientDraft({
    required this.name,
    required this.relationship,
    required this.language,
    required this.timezone,
    this.dateOfBirth,
    required this.conversationConsent,
    required this.cloudConsent,
  });
  final String name;
  final String relationship;
  final String language;
  final String timezone;
  final String? dateOfBirth;
  final bool conversationConsent;
  final bool cloudConsent;

  Map<String, Object?> toJson() => {
    'full_name': name.trim(),
    'relationship': relationship.trim(),
    'preferred_language': language,
    if (timezone.trim().isNotEmpty) 'timezone': timezone.trim(),
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    'consents': [
      if (conversationConsent) 'ambient_audio_household',
      if (cloudConsent) 'cloud_processing',
    ],
  };

  /// Accepts the displayed DD / MM / YYYY format without date rollover.
  static String? parseBirthDate(String input) {
    for (var digit = 0; digit < 10; digit++) {
      input = input
          .replaceAll('٠١٢٣٤٥٦٧٨٩'[digit], digit.toString())
          .replaceAll('۰۱۲۳۴۵۶۷۸۹'[digit], digit.toString());
    }
    final match = RegExp(r'^\s*(\d{2})\s*/\s*(\d{2})\s*/\s*(\d{4})\s*$')
        .firstMatch(input);
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    if (year < 1) return null;
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return '${match[3]}-${match[2]}-${match[1]}';
  }
}
