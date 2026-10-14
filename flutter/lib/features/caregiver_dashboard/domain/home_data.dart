class HomePatient {
  const HomePatient({
    required this.id,
    required this.name,
    required this.language,
    required this.timezone,
    required this.memoryEnabled,
    required this.permission,
  });
  final String id, name, language, timezone, permission;
  final bool memoryEnabled;
}

class HomeDevice {
  const HomeDevice({
    required this.id,
    required this.patientId,
    required this.serial,
    required this.online,
    this.battery,
    this.lastSeen,
  });
  final String id, patientId, serial;
  final bool online;
  final int? battery;
  final DateTime? lastSeen;
}

class HomeDay {
  const HomeDay({
    required this.patientId,
    required this.date,
    required this.peopleMet,
    required this.done,
    required this.total,
    required this.snoozed,
    required this.refreshedAt,
  });
  final String patientId, date;
  final int peopleMet, done, total, snoozed;
  final DateTime refreshedAt;
}

class HomeAlert {
  const HomeAlert({
    required this.id,
    required this.patientId,
    required this.type,
    required this.message,
    required this.createdAt,
  });
  final String id, patientId, type, message;
  final DateTime createdAt;
}

class HomeData {
  const HomeData({
    this.patients = const [],
    this.devices = const [],
    this.days = const [],
    this.alerts = const [],
  });
  final List<HomePatient> patients;
  final List<HomeDevice> devices;
  final List<HomeDay> days;
  final List<HomeAlert> alerts;
}
