import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure routing context, not a token or patient profile.
class PatientDeviceContext {
  const PatientDeviceContext({
    required this.patientId,
    required this.deviceId,
    required this.serial,
  });
  final String patientId;
  final String deviceId;
  final String serial;
  Map<String, Object?> toJson() => {
    'patient_id': patientId,
    'device_id': deviceId,
    'serial_number': serial,
  };
  @override
  String toString() => 'PatientDeviceContext';
}

abstract interface class PatientSessionStore {
  Future<PatientDeviceContext?> read();
  Future<void> save(PatientDeviceContext context);
  Future<void> clear();
}

class SecurePatientSessionStore implements PatientSessionStore {
  SecurePatientSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'remori.patient_session';
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  @override
  Future<PatientDeviceContext?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    try {
      final data = jsonDecode(value);
      if (data is Map &&
          data['patient_id'] is String &&
          _uuid.hasMatch(data['patient_id']) &&
          data['device_id'] is String &&
          _uuid.hasMatch(data['device_id']) &&
          data['serial_number'] is String &&
          (data['serial_number'] as String).trim().isNotEmpty) {
        return PatientDeviceContext(
          patientId: data['patient_id'],
          deviceId: data['device_id'],
          serial: data['serial_number'],
        );
      }
    } on FormatException {
      /* Invalid stored context cannot grant access. */
    }
    await clear();
    return null;
  }

  @override
  Future<void> save(PatientDeviceContext context) =>
      _storage.write(key: _key, value: jsonEncode(context.toJson()));
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
