import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Null follows the device locale; an auth/profile integration may override it.
/// This does not introduce a persisted preference or settings screen.
final appLocaleProvider = Provider<Locale?>((ref) => null);

/// Patient profile preferred_language will supply this through a repository.
/// Arabic is the specified first/default language until profile sync is wired.
final patientLocaleProvider = Provider<Locale>((ref) => const Locale('ar'));
