import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'credential_store.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);
final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(),
);

/// Auth integration will clear the corresponding route access on invalidation.
final credentialsInvalidatedProvider = Provider<void Function(ApiCredential)>(
  (ref) => (_) {},
);
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    config: ref.watch(apiConfigProvider),
    credentials: ref.watch(credentialStoreProvider),
    onCredentialsInvalidated: ref.watch(credentialsInvalidatedProvider),
  );
  ref.onDispose(client.close);
  return client;
});
