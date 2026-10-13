/// Safe pairing metadata. The device token is never exposed to presentation.
class PairingInfo {
  const PairingInfo({
    required this.deviceId,
    required this.patientId,
    required this.serial,
  });
  final String deviceId;
  final String patientId;
  final String serial;
}
