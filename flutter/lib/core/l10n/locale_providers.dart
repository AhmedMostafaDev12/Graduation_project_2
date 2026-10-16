import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/patient_today/presentation/patient_today_providers.dart';
import '../../features/caregiver_dashboard/presentation/home_providers.dart';

/// Null follows the device locale; an auth/profile integration may override it.
/// This does not introduce a persisted preference or settings screen.
final appLanguageSelectionProvider =
    NotifierProvider<AppLanguageSelection, Locale?>(AppLanguageSelection.new);

class AppLanguageSelection extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void select(String language) {
    if (language == 'ar' || language == 'en') state = Locale(language);
  }
}

/// One locale for both shells. Existing scoped profile caches restore it;
/// an explicit selection survives navigation and patient handover in memory.
final appLocaleProvider = Provider<Locale?>((ref) {
  final selected = ref.watch(appLanguageSelectionProvider);
  if (selected != null) return selected;
  final key = ref.watch(patientTodayKeyProvider);
  final language = key == null
      ? ref.watch(selectedHomePatientProvider)?.language
      : ref.watch(patientTodayDataProvider(key)).value?.settings?.language;
  return language == 'ar' || language == 'en' ? Locale(language!) : null;
});

/// Compatibility alias for relay notifications; no separate patient preference.
final patientLocaleProvider = Provider<Locale>((ref) {
  final selected = ref.watch(appLocaleProvider);
  if (selected != null) return selected;
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  return Locale(device.languageCode == 'ar' ? 'ar' : 'en');
});
