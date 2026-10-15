typedef PatientTodayKey = (String, String);

class PatientSettings {
  const PatientSettings(
    this.name,
    this.language,
    this.timezone,
    this.memoryEnabled,
  );
  final String name, language, timezone;
  final bool memoryEnabled;
}

class PatientReminder {
  const PatientReminder(
    this.id,
    this.title,
    this.dueAt, {
    this.status = 'pending',
    DateTime? scheduledAt,
  }) : scheduledAt = scheduledAt ?? dueAt;
  final String id, title, status;
  final DateTime dueAt;
  final DateTime scheduledAt;
}

class MetPerson {
  const MetPerson(this.id, this.name);
  final String id, name;
}

class PatientTodayData {
  const PatientTodayData({
    this.settings,
    this.next,
    this.people = const [],
    this.reminders = const [],
  });
  final PatientSettings? settings;
  final PatientReminder? next;
  final List<MetPerson> people;
  final List<PatientReminder> reminders;
}
