import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;

import '../../../core/api/api_providers.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/api_config.dart';
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
    var phase = 'authentication';
    try {
      await ref.read(authRepositoryProvider).login(email, password);
      phase = 'pairing-reset';
      resetPairingSetup(ref);
      phase = 'session-activation';
      ref.read(caregiverSessionProvider.notifier).signedIn();
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      _reportAuthFailure('login', phase, error, stack);
      state = AsyncError(_authFailure(error), stack);
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
    var phase = 'registration';
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
      phase = 'authentication';
      await repository.login(email, password);
      if (!ref.mounted) return false;
      resetPairingSetup(ref);
      ref.read(caregiverSessionProvider.notifier).signedIn();
      state = const SignUpState(accountCreated: true);
      return true;
    } catch (error, stack) {
      _reportAuthFailure('signup', phase, error, stack);
      if (ref.mounted) {
        state = SignUpState(
          accountCreated: created,
          failure: _authFailure(error),
        );
      }
      return false;
    }
  }
}

ApiFailure _authFailure(Object error) {
  while (error is ProviderException) {
    error = error.exception;
  }
  return error is ApiFailure
      ? error
      : ApiFailure(
          ApiFailureKind.invalidResponse,
          code: error is ApiConfigurationException ? 'APP_CONFIGURATION' : null,
        );
}

/// Diagnostics contain only categories and a source location, never exception
/// messages, request/response bodies, headers, credentials or account details.
void _reportAuthFailure(
  String operation,
  String phase,
  Object error,
  StackTrace stack,
) {
  if (!kDebugMode) return;
  while (error is ProviderException) {
    stack = error.stackTrace;
    error = error.exception;
  }
  final failure = _authFailure(error);
  final code = failure.code;
  final safeCode = code != null && RegExp(r'^[A-Z0-9_]{1,64}$').hasMatch(code)
      ? code
      : 'none';
  final location =
      RegExp(r'package:remori/[a-zA-Z0-9_/.]+\.dart:\d+:\d+')
          .firstMatch(stack.toString())
          ?.group(0) ??
      'unavailable';
  debugPrint(
    'Remori auth/$operation: phase=$phase kind=${failure.kind.name} status=${failure.statusCode ?? 'none'} code=$safeCode type=${error.runtimeType} source=$location',
  );
}
