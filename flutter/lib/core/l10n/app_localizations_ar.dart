// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get caregiverHome => 'الرئيسية';

  @override
  String get caregiverPeople => 'الأشخاص';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get caregiverMore => 'المزيد';

  @override
  String get addReminder => 'إضافة تذكير';

  @override
  String get patientToday => 'اليوم';

  @override
  String get patientMyDay => 'يومي';

  @override
  String get patientGames => 'الألعاب';

  @override
  String get ask => 'اسأل';

  @override
  String get appName => 'ريموري';

  @override
  String get splashTagline => 'طبقة هادئة من الذاكرة\nترافقك دائمًا.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get splashSupport => 'دعم للحظاتك اليومية.';

  @override
  String get modeSelectIntro =>
      'دعم للذاكرة للأشخاص الذين يعيشون مع ألزهايمر، ولمن يعتنون بهم.';

  @override
  String get modeCaregiver => 'أنا مقدم رعاية';

  @override
  String get modePatientPhone => 'هذا هاتف المريض';
}
