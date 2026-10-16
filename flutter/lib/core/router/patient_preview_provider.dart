import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temporary, in-memory UI access only. Never creates a device session or token.
const patientPreviewEnabled =
    kDebugMode &&
    bool.fromEnvironment('REMORI_PATIENT_PREVIEW', defaultValue: true);

final patientPreviewProvider = NotifierProvider<PatientPreview, bool>(
  PatientPreview.new,
);

class PatientPreview extends Notifier<bool> {
  @override
  bool build() => false;

  void start() {
    if (patientPreviewEnabled) state = true;
  }

  void stop() => state = false;
}
