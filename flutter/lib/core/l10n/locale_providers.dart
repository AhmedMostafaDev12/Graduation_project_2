import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/patient_today/presentation/patient_today_providers.dart';

/// Null follows the device locale; an auth/profile integration may override it.
/// This does not introduce a persisted preference or settings screen.
final appLocaleProvider = Provider<Locale?>((ref) => null);

/// Patient-scoped settings supply the language; Arabic is the offline default.
final patientLocaleProvider = Provider<Locale>((ref) {
  final key = ref.watch(patientTodayKeyProvider);
  if (key == null) return const Locale('ar');
  final data = ref.watch(patientTodayDataProvider(key));
  return Locale(
    data.isLoading || data.hasError
        ? 'ar'
        : data.value?.settings?.language ?? 'ar',
  );
});
