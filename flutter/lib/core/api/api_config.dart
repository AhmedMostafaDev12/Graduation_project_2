import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig(String value, {bool allowInsecure = !kReleaseMode}) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' && !(allowInsecure && uri.scheme == 'http')) ||
        uri.path.replaceFirst(RegExp(r'/$'), '') != '/api/v1') {
      throw ArgumentError(
        'Configure a valid /api/v1 base URL; release builds require HTTPS.',
      );
    }
    baseUrl = value.replaceFirst(RegExp(r'/$'), '');
  }
  factory ApiConfig.fromEnvironment() =>
      ApiConfig(const String.fromEnvironment('REMORI_API_BASE_URL'));
  late final String baseUrl;
}
