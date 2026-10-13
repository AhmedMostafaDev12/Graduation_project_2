import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CaregiverTokens {
  const CaregiverTokens({
    required this.accessToken,
    required this.refreshToken,
  });
  final String accessToken;
  final String refreshToken;
  @override
  String toString() => 'CaregiverTokens(redacted)';
}

abstract interface class CredentialStore {
  Future<CaregiverTokens?> readCaregiver();
  Future<void> saveCaregiver(CaregiverTokens tokens);
  Future<void> clearCaregiver();
  Future<String?> readDevice();
  Future<void> saveDevice(String token);
  Future<void> clearDevice();
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _caregiverKey = 'remori.caregiver_tokens';
  static const _deviceKey = 'remori.device_token';

  @override
  Future<CaregiverTokens?> readCaregiver() async {
    final value = await _storage.read(key: _caregiverKey);
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json is Map &&
          json['access_token'] is String &&
          (json['access_token'] as String).isNotEmpty &&
          json['refresh_token'] is String &&
          (json['refresh_token'] as String).isNotEmpty) {
        return CaregiverTokens(
          accessToken: json['access_token'] as String,
          refreshToken: json['refresh_token'] as String,
        );
      }
    } on FormatException {
      /* Invalid persisted credentials require sign-in. */
    }
    await clearCaregiver();
    return null;
  }

  @override
  Future<void> saveCaregiver(CaregiverTokens tokens) => _storage.write(
    key: _caregiverKey,
    value: jsonEncode({
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
    }),
  );
  @override
  Future<void> clearCaregiver() => _storage.delete(key: _caregiverKey);
  @override
  Future<String?> readDevice() => _storage.read(key: _deviceKey);
  @override
  Future<void> saveDevice(String token) =>
      _storage.write(key: _deviceKey, value: token);
  @override
  Future<void> clearDevice() => _storage.delete(key: _deviceKey);
}
