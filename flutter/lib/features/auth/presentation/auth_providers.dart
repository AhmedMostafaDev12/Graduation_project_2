import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/api_failure.dart';
import '../data/auth_repository.dart';
import '../../device_pairing/presentation/pairing_providers.dart';

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
      resetPairingSetup(ref);
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

class SignUpState {
  const SignUpState({
    this.busy = false,
    this.accountCreated = false,
    this.failure,
  });
  final bool busy;
  final bool accountCreated;
  final ApiFailure? failure;
}

final signUpControllerProvider =
    NotifierProvider.autoDispose<SignUpController, SignUpState>(
      SignUpController.new,
    );

class SignUpController extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (state.busy || state.accountCreated) return false;
    state = const SignUpState(busy: true);
    bool created = false;
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      created = true;
      if (!ref.mounted) return false;
      await repository.login(email, password);
      if (!ref.mounted) return false;
      resetPairingSetup(ref);
      ref.read(caregiverSessionProvider.notifier).signedIn();
      state = const SignUpState(accountCreated: true);
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = SignUpState(
          accountCreated: created,
          failure: error is ApiFailure
              ? error
              : ApiFailure(ApiFailureKind.network),
        );
      }
      return false;
    }
  }
}
