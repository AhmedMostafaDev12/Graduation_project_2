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
  const PatientReminder(this.id, this.title, this.dueAt);
  final String id, title;
  final DateTime dueAt;
}

class MetPerson {
  const MetPerson(this.id, this.name);
  final String id, name;
}

class PatientTodayData {
  const PatientTodayData({this.settings, this.next, this.people = const []});
  final PatientSettings? settings;
  final PatientReminder? next;
  final List<MetPerson> people;
}
