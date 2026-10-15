import '../../reminders/domain/reminder_data.dart';

typedef MoreScope = (String, String?);

class CaregiverAccount {
  const CaregiverAccount(this.id, this.name, this.email);
  final String id, name, email;
}

class PatientProfile {
  const PatientProfile(this.name, this.language, this.timezone);
  final String name, language, timezone;
  bool get isValid {
    if (name.trim().isEmpty ||
        name.trim().length > 120 ||
        !{'ar', 'en'}.contains(language)) {
      return false;
    }
    try {
      PatientTime.location(timezone);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ConsentRecord {
  const ConsentRecord({
    required this.id,
    required this.type,
    required this.givenBy,
    required this.givenAt,
    this.subjectId,
    this.subjectName,
    this.revokedAt,
  });
  final String id, type, givenBy;
  final String? subjectId, subjectName;
  final DateTime givenAt;
  final DateTime? revokedAt;
}

class MoreData {
  const MoreData({
    this.account,
    this.consents = const [],
    this.placeCount,
    this.caregiverCount,
  });
  final CaregiverAccount? account;
  final List<ConsentRecord> consents;
  final int? placeCount;
  final int? caregiverCount;
}
