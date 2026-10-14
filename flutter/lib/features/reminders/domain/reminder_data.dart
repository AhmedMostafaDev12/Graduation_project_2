import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

class PatientTime {
  static bool _initialized = false;
  static tz.Location location(String name) {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
    return tz.getLocation(name);
  }

  static DateTime local(DateTime instant, String name) =>
      tz.TZDateTime.from(instant, location(name));
  static String day(DateTime instant, String name) {
    final date = local(instant, name);
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class ReminderScope {
  const ReminderScope(this.caregiverId, this.patientId, this.timezone);
  final String caregiverId, patientId, timezone;
  @override
  bool operator ==(Object other) =>
      other is ReminderScope &&
      other.caregiverId == caregiverId &&
      other.patientId == patientId &&
      other.timezone == timezone;
  @override
  int get hashCode => Object.hash(caregiverId, patientId, timezone);
}

enum ReminderKind { medication, appointment, task }

class CaregiverReminder {
  const CaregiverReminder({
    required this.id,
    required this.title,
    required this.kind,
    required this.rrule,
    required this.dtstart,
    required this.timezone,
    required this.active,
  });
  final String id, title, rrule, timezone;
  final ReminderKind kind;
  final DateTime dtstart;
  final bool active;
}

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.kind,
    required this.scheduledAt,
    required this.status,
    this.snoozedUntil,
    this.completedAt,
    this.confirmedVia,
  });
  final String id, reminderId, title, status;
  final ReminderKind kind;
  final DateTime scheduledAt;
  final DateTime? snoozedUntil, completedAt;
  final String? confirmedVia;
}

class ReminderListData {
  const ReminderListData({
    this.reminders = const [],
    this.occurrences = const [],
    this.refreshedAt,
    this.todayAvailable = false,
  });
  final List<CaregiverReminder> reminders;
  final List<ReminderOccurrence> occurrences;
  final DateTime? refreshedAt;
  final bool todayAvailable;
  bool get loaded => refreshedAt != null;
}

/// A display summary only: C8 never generates or invents occurrence logs.
class SimpleReminderSchedule {
  const SimpleReminderSchedule(this.weekdays, this.minutes);
  final List<int> weekdays, minutes;
  static SimpleReminderSchedule? parse(
    CaregiverReminder reminder,
    String patientTimezone,
  ) {
    if (reminder.timezone != patientTimezone) return null;
    final fields = <String, String>{};
    for (final part in reminder.rrule.split(';')) {
      final pair = part.split('=');
      if (pair.length != 2 || fields.containsKey(pair[0])) return null;
      fields[pair[0]] = pair[1];
    }
    if (fields.keys.any(
          (k) => !{
            'FREQ',
            'INTERVAL',
            'BYDAY',
            'BYHOUR',
            'BYMINUTE',
            'BYSECOND',
          }.contains(k),
        ) ||
        (fields['INTERVAL'] != null && fields['INTERVAL'] != '1') ||
        (fields['BYSECOND'] != null && fields['BYSECOND'] != '0')) {
      return null;
    }
    final freq = fields['FREQ'];
    if (freq != 'DAILY' && freq != 'WEEKLY') return null;
    if (freq == 'DAILY' && fields.containsKey('BYDAY')) return null;
    final start = PatientTime.local(reminder.dtstart, reminder.timezone);
    List<int>? numbers(String? raw, int fallback, int max) {
      if (raw == null) return [fallback];
      final values = raw.split(',').map(int.tryParse).toList();
      if (values.any((v) => v == null || v < 0 || v > max)) return null;
      return values.cast<int>().toSet().toList()..sort();
    }

    final hours = numbers(fields['BYHOUR'], start.hour, 23),
        minutes = numbers(fields['BYMINUTE'], start.minute, 59);
    if (hours == null ||
        minutes == null ||
        (fields['BYSECOND'] == null && start.second != 0)) {
      return null;
    }
    final days = <int>[];
    if (freq == 'WEEKLY') {
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      for (final code
          in fields['BYDAY']?.split(',') ?? [codes[start.weekday - 1]]) {
        if (!codes.contains(code)) return null;
        days.add(codes.indexOf(code) + 1);
      }
    }
    final times = [
      for (final hour in hours)
        for (final minute in minutes) hour * 60 + minute,
    ];
    // Keep long rules readable rather than silently omitting some times.
    if (times.length > 4) return null;
    return SimpleReminderSchedule(days.toSet().toList()..sort(), times);
  }
}
