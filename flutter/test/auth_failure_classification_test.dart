import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/features/auth/presentation/auth_providers.dart';

void main() {
  test('debug auth diagnostic excludes private exception messages', () async {
    final lines = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) lines.add(message);
    };
    addTearDown(() => debugPrint = previous);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith(
          (ref) =>
              throw StateError('PRIVATE_EMAIL PRIVATE_PASSWORD PRIVATE_TOKEN'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(loginControllerProvider.notifier)
        .login('PRIVATE_EMAIL', 'PRIVATE_PASSWORD');
    expect(
      lines.join(),
      contains('Remori auth/login: phase=authentication kind=invalidResponse'),
    );
    expect(lines.join(), isNot(contains('PRIVATE_')));
  });
  test(
    'missing build configuration is identified for login and signup',
    () async {
      final container = ProviderContainer(
        overrides: [apiConfigProvider.overrideWith((ref) => ApiConfig(''))],
      );
      addTearDown(container.dispose);
      expect(
        await container
            .read(loginControllerProvider.notifier)
            .login('test@example.com', 'password'),
        isFalse,
      );
      final failure =
          container.read(loginControllerProvider).error as ApiFailure;
      expect(failure.code, 'APP_CONFIGURATION');
      expect(failure.kind, isNot(ApiFailureKind.network));
      final subscription = container.listen(
        signUpControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        await container
            .read(signUpControllerProvider.notifier)
            .signUp(
              name: 'Test',
              email: 'test@example.com',
              password: 'password',
            ),
        isFalse,
      );
      expect(
        container.read(signUpControllerProvider).failure?.code,
        'APP_CONFIGURATION',
      );
    },
  );

  for (final kind in [
    ApiFailureKind.network,
    ApiFailureKind.timeout,
    ApiFailureKind.server,
  ]) {
    test('wrapped $kind failure keeps its actual category', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => throw ApiFailure(
              kind,
              code: kind == ApiFailureKind.server
                  ? 'INVALID_CREDENTIALS'
                  : null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .login('test@example.com', 'password');
      expect(
        (container.read(loginControllerProvider).error as ApiFailure).kind,
        kind,
      );
    });
  }

  test(
    'unexpected local error is not reported as a connection failure',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => throw StateError('local failure'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(loginControllerProvider.notifier)
          .login('test@example.com', 'password');
      expect(
        (container.read(loginControllerProvider).error as ApiFailure).kind,
        ApiFailureKind.invalidResponse,
      );
    },
  );
}
