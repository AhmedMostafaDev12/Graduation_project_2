import '../../journal/domain/journal_data.dart';
import '../../patient_today/domain/patient_today_data.dart';
export '../../journal/domain/journal_data.dart'
    show JournalEntry, JournalMedia, JournalPerson;

/// Device scope, patient-local calendar day, IANA timezone.
typedef PatientJournalKey = (PatientTodayKey, String, String);

class PatientJournalData {
  const PatientJournalData({this.entries = const [], this.refreshedAt});
  final List<JournalEntry> entries;
  final DateTime? refreshedAt;
}
