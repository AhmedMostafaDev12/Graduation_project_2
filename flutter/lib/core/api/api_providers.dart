import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'credential_store.dart';
import 'patient_session_provider.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);
final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(),
);

/// Invalidation updates router access without exposing credentials.
final credentialsInvalidatedProvider = Provider<void Function(ApiCredential)>(
  (ref) => (credential) {
    if (credential == ApiCredential.caregiver) {
      ref.read(caregiverSessionProvider.notifier).invalidate();
    } else if (credential == ApiCredential.device) {
      ref.read(patientSessionProvider.notifier).invalidate();
    }
  },
);
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    config: ref.watch(apiConfigProvider),
    credentials: ref.watch(credentialStoreProvider),
    onCredentialsInvalidated: ref.watch(credentialsInvalidatedProvider),
    canUseCaregiver: () => !ref.read(patientSessionProvider).active,
  );
  ref.onDispose(client.close);
  return client;
});

/// Route access follows verified authentication, never a UI button press.
final caregiverSessionProvider = NotifierProvider<CaregiverSession, bool>(
  CaregiverSession.new,
);

class CaregiverSession extends Notifier<bool> {
  int _generation = 0;
  late Future<void> restoration;
  @override
  bool build() {
    restoration = Future.microtask(_restore);
    return false;
  }

  Future<void> _restore() async {
    final generation = _generation;
    try {
      await ref.read(patientSessionProvider.notifier).restoration;
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(patientSessionProvider).active) {
        return;
      }
      final tokens = await ref.read(credentialStoreProvider).readCaregiver();
      if (!ref.mounted || tokens == null || generation != _generation) return;
      // /auth/me validates stored credentials, including refresh on expiry.
      final response = await ref
          .read(apiClientProvider)
          .request<dynamic>('/auth/me', credential: ApiCredential.caregiver);
      final data = response.data;
      if (data is Map &&
          data['role'] == 'caregiver' &&
          data['id'] is String &&
          (data['id'] as String).isNotEmpty &&
          ref.mounted &&
          generation == _generation) {
        state = true;
      }
    } catch (_) {
      // Offline restoration cannot authorize the online caregiver shell.
      // Retain credentials so transient failures do not sign the user out.
    }
  }

  void signedIn() {
    _generation++;
    state = true;
  }

  void invalidate() {
    _generation++;
    state = false;
  }
}
