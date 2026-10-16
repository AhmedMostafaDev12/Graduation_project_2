import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/credential_store.dart';
import '../domain/pairing_info.dart';

class PairingRepository {
  PairingRepository(this.client, this.credentials);
  final ApiClient client;
  final CredentialStore credentials;
  PairingInfo? _pendingInfo;
  String? _pendingToken;
  bool _busy = false;
  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _pendingInfo = null;
    _pendingToken = null;
  }

  void _checkActive() {
    if (_disposed) throw ApiFailure(ApiFailureKind.cancelled);
  }

  static bool isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<PairingInfo> pair(String patientId, String serial) async {
    _checkActive();
    if (_busy) throw ApiFailure(ApiFailureKind.cancelled);
    if (!isUuid(patientId) || serial.trim().isEmpty) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    _busy = true;
    try {
      serial = serial.trim();
      if (_pendingInfo?.patientId != patientId ||
          _pendingInfo?.serial != serial) {
        final response = await client.request<dynamic>(
          '/devices/pair',
          credential: ApiCredential.caregiver,
          method: 'POST',
          data: {'serial_number': serial, 'patient_id': patientId},
        );
        final data = response.data;
        _checkActive();
        if (response.statusCode != 201 ||
            data is! Map ||
            data['device_id'] is! String ||
            !isUuid(data['device_id'] as String) ||
            data['patient_id'] != patientId ||
            data['serial_number'] != serial ||
            data['device_token'] is! String ||
            (data['device_token'] as String).isEmpty) {
          throw ApiFailure(ApiFailureKind.invalidResponse);
        }
        _pendingInfo = PairingInfo(
          deviceId: data['device_id'] as String,
          patientId: patientId,
          serial: serial,
        );
        _pendingToken = data['device_token'] as String;
      }
      // Preserve a received grant in memory on storage failure. Retry storage,
      // not POST /devices/pair: re-pairing rotates the server device token.
      _checkActive();
      final result = _pendingInfo!;
      final token = _pendingToken!;
      try {
        await credentials.saveDevice(token);
      } catch (_) {
        throw ApiFailure(ApiFailureKind.credentials);
      }
      _checkActive();
      _pendingInfo = null;
      _pendingToken = null;
      return result;
    } finally {
      _busy = false;
    }
  }
}
