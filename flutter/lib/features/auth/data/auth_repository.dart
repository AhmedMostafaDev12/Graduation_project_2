import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/credential_store.dart';

/// Authentication is online; credentials are stored only in secure storage,
/// never in the offline database or outbox.
class AuthRepository {
  AuthRepository(this.client, this.credentials);
  final ApiClient client;
  final CredentialStore credentials;

  /// Registration returns an account, not tokens. Login is a separate step.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await client.request<dynamic>(
      '/auth/register',
      credential: ApiCredential.none,
      method: 'POST',
      data: {
        'full_name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    final data = response.data;
    if (response.statusCode != 201 ||
        data is! Map ||
        data['id'] is! String ||
        (data['id'] as String).isEmpty ||
        data['role'] != 'caregiver') {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
  }

  Future<void> login(String email, String password) async {
    final response = await client.request<dynamic>(
      '/auth/login',
      credential: ApiCredential.none,
      method: 'POST',
      contentType: 'application/x-www-form-urlencoded',
      data: {'username': email.trim(), 'password': password},
    );
    final data = response.data;
    if (data is! Map ||
        data['access_token'] is! String ||
        (data['access_token'] as String).isEmpty ||
        data['refresh_token'] is! String ||
        (data['refresh_token'] as String).isEmpty ||
        data['token_type'] != 'bearer' ||
        data['expires_in'] is! int ||
        (data['expires_in'] as int) <= 0) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    try {
      await credentials.saveCaregiver(
        CaregiverTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        ),
      );
    } catch (_) {
      throw ApiFailure(ApiFailureKind.credentials);
    }
  }
}
