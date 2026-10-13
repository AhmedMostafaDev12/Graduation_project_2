// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get caregiverHome => 'Home';

  @override
  String get caregiverPeople => 'People';

  @override
  String get reminders => 'Reminders';

  @override
  String get caregiverMore => 'More';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get patientToday => 'Today';

  @override
  String get patientMyDay => 'My Day';

  @override
  String get patientGames => 'Games';

  @override
  String get ask => 'Ask';

  @override
  String get appName => 'Remori';

  @override
  String get splashTagline => 'A quiet layer of memory\nthat stays with you.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get splashSupport => 'Support for everyday moments.';

  @override
  String get modeSelectIntro =>
      'Memory support for people living with Alzheimer\'s, and for the people who care for them.';

  @override
  String get modeCaregiver => 'I\'m a caregiver';

  @override
  String get modePatientPhone => 'This is the patient\'s phone';
}
