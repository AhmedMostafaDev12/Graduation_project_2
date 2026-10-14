import 'reminder_data.dart';

enum ReminderRepeat { once, daily, weekly }

/// C9's bounded editor, rather than a general RFC 5545 recurrence engine.
class ReminderScheduleDraft {
  ReminderScheduleDraft({
    required this.starts,
    required this.timezone,
    this.repeat = ReminderRepeat.daily,
    List<int> minutes = const [],
    Set<int> weekdays = const {},
  }) : minutes = [...minutes],
       weekdays = {...weekdays};
  DateTime starts;
  String timezone;
  ReminderRepeat repeat;
  final List<int> minutes;
  final Set<int> weekdays;
  static const dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// Match the wall clock against actual offsets. No match is a DST gap;
  /// two matches are an overlap, whose first occurrence RFC 5545 selects.
  static DateTime? resolve(DateTime day, int minute, String timezone) {
    final location = PatientTime.location(timezone);
    final wall = DateTime.utc(
      day.year,
      day.month,
      day.day,
      minute ~/ 60,
      minute % 60,
    );
    final matches = <DateTime>[];
    for (final offset in location.zones.map((z) => z.offset).toSet()) {
      final candidate = wall.subtract(offset);
      final local = PatientTime.local(candidate, timezone);
      if (local.year == day.year &&
          local.month == day.month &&
          local.day == day.day &&
          local.hour == minute ~/ 60 &&
          local.minute == minute % 60) {
        matches.add(candidate);
      }
    }
    matches.sort();
    return matches.isEmpty ? null : matches.first;
  }

  String? get error {
    try {
      PatientTime.location(timezone);
    } catch (_) {
      return 'timezone';
    }
    if (minutes.isEmpty ||
        minutes.length > 4 ||
        minutes.any((m) => m < 0 || m >= 1440) ||
        minutes.toSet().length != minutes.length) {
      return 'times';
    }
    if (repeat == ReminderRepeat.weekly &&
        (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7))) {
      return 'days';
    }
    if (minutes.any((m) => resolve(firstDay, m, timezone) == null)) {
      return 'gap';
    }
    return null;
  }

  DateTime get firstDay {
    var day = DateTime(starts.year, starts.month, starts.day);
    if (repeat == ReminderRepeat.weekly && weekdays.isNotEmpty) {
      for (var i = 0; i < 7 && !weekdays.contains(day.weekday); i++) {
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    return day;
  }

  Map<String, Object?> payload() {
    if (error != null) throw StateError('Invalid reminder schedule');
    final times = [...minutes]..sort();
    final hours = times.map((m) => m ~/ 60).toSet().toList()..sort();
    final mins = times.map((m) => m % 60).toSet().toList()..sort();
    final days = weekdays.toList()..sort();
    final parts = <String>[
      'FREQ=${repeat == ReminderRepeat.weekly ? 'WEEKLY' : 'DAILY'}',
      if (repeat == ReminderRepeat.once) 'COUNT=${times.length}',
      if (repeat == ReminderRepeat.weekly)
        'BYDAY=${days.map((d) => dayCodes[d - 1]).join(',')}',
      'BYHOUR=${hours.join(',')}',
      'BYMINUTE=${mins.join(',')}',
    ];
    // BYHOUR and BYMINUTE otherwise form a Cartesian product. Select only
    // the requested pairs, across every chosen day of the weekly period.
    final candidates = [
      for (final h in hours)
        for (final m in mins) h * 60 + m,
    ];
    if (candidates.length != times.length) {
      final positions = [
        for (
          var d = 0;
          d < (repeat == ReminderRepeat.weekly ? days.length : 1);
          d++
        )
          for (final time in times)
            d * candidates.length + candidates.indexOf(time) + 1,
      ];
      parts.add('BYSETPOS=${positions.join(',')}');
    }
    return {
      'rrule': parts.join(';'),
      'dtstart': resolve(firstDay, times.first, timezone)!.toIso8601String(),
      'timezone': timezone,
    };
  }

  static ReminderScheduleDraft? parse(CaregiverReminder reminder) {
    try {
      final fields = <String, String>{};
      for (final part in reminder.rrule.split(';')) {
        final pair = part.split('=');
        if (pair.length != 2 || fields.containsKey(pair[0])) return null;
        fields[pair[0]] = pair[1];
      }
      if (fields.keys.any(
            (k) => !{
              'FREQ',
              'COUNT',
              'INTERVAL',
              'BYDAY',
              'BYHOUR',
              'BYMINUTE',
              'BYSECOND',
              'BYSETPOS',
              'WKST',
            }.contains(k),
          ) ||
          (fields['INTERVAL'] != null && fields['INTERVAL'] != '1') ||
          (fields['BYSECOND'] != null && fields['BYSECOND'] != '0') ||
          (fields['WKST'] != null && fields['WKST'] != 'MO')) {
        return null;
      }
      final weekly = fields['FREQ'] == 'WEEKLY';
      if (!weekly && fields['FREQ'] != 'DAILY') return null;
      if (!weekly && fields.containsKey('BYDAY')) return null;
      final start = PatientTime.local(reminder.dtstart, reminder.timezone);
      if (start.second != 0 ||
          start.millisecond != 0 ||
          start.microsecond != 0) {
        return null;
      }
      List<int> numbers(String? value, int fallback, int max) {
        final items = value == null
            ? [fallback]
            : value.split(',').map(int.parse).toList();
        if (items.isEmpty ||
            items.any((v) => v < 0 || v > max) ||
            items.toSet().length != items.length) {
          throw const FormatException();
        }
        return items..sort();
      }

      final hours = numbers(fields['BYHOUR'], start.hour, 23),
          mins = numbers(fields['BYMINUTE'], start.minute, 59);
      final days = <int>{};
      if (weekly) {
        for (final code
            in fields['BYDAY']?.split(',') ?? [dayCodes[start.weekday - 1]]) {
          if (!dayCodes.contains(code) ||
              !days.add(dayCodes.indexOf(code) + 1)) {
            return null;
          }
        }
      }
      final candidates = [
        for (final h in hours)
          for (final m in mins) h * 60 + m,
      ];
      if (candidates.length > 16) return null;
      List<int> times = candidates;
      if (fields['BYSETPOS'] case final String positions) {
        final count = weekly ? days.length : 1;
        final selected = List.generate(count, (_) => <int>[]);
        final seen = <int>{};
        for (final raw in positions.split(',')) {
          final position = int.parse(raw);
          if (position <= 0 ||
              position > candidates.length * count ||
              !seen.add(position)) {
            return null;
          }
          selected[(position - 1) ~/ candidates.length].add(
            candidates[(position - 1) % candidates.length],
          );
        }
        for (final list in selected) {
          list.sort();
        }
        if (selected.any((v) => v.join(',') != selected.first.join(','))) {
          return null;
        }
        times = selected.first;
      }
      if (times.isEmpty ||
          times.length > 4 ||
          !times.contains(start.hour * 60 + start.minute) ||
          (weekly && !days.contains(start.weekday))) {
        return null;
      }
      final once = fields.containsKey('COUNT');
      if (once &&
          (weekly ||
              fields['COUNT'] != '${times.length}' ||
              start.hour * 60 + start.minute != times.first)) {
        return null;
      }
      return ReminderScheduleDraft(
        starts: DateTime(start.year, start.month, start.day),
        timezone: reminder.timezone,
        repeat: once
            ? ReminderRepeat.once
            : weekly
            ? ReminderRepeat.weekly
            : ReminderRepeat.daily,
        minutes: times,
        weekdays: days,
      );
    } catch (_) {
      return null;
    }
  }
}
