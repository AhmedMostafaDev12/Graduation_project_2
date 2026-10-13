import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/api_failure.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(credentialStoreProvider),
  ),
);

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(LoginController.new);

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> login(String email, String password) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).login(email, password);
      ref.read(caregiverSessionProvider.notifier).signedIn();
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      state = AsyncError(
        error is ApiFailure ? error : ApiFailure(ApiFailureKind.network),
        stack,
      );
      return false;
    }
  }
}
