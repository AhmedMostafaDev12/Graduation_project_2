import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remori/core/api/api_providers.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/features/auth/data/auth_repository.dart';
import 'package:remori/core/api/api_config.dart';
import 'package:remori/core/api/api_failure.dart';
import 'package:remori/core/api/credential_store.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      options.extra['test.wire'] = await requestStream
          .expand((chunk) => chunk)
          .toList();
    }
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    'content-type': ['application/json'],
  },
);
ResponseBody _error(int status, String code) => _json(status, {
  'error': {'code': code, 'message': 'Server message'},
});
const _oldTokens = CaregiverTokens(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
);
const _newPair = {
  'access_token': 'new-access',
  'refresh_token': 'new-refresh',
  'token_type': 'bearer',
  'expires_in': 900,
};

class _Store implements CredentialStore {
  CaregiverTokens? caregiver = _oldTokens;
  String? device = 'device-token';
  @override
  Future<CaregiverTokens?> readCaregiver() async => caregiver;
  @override
  Future<void> saveCaregiver(CaregiverTokens tokens) async =>
      caregiver = tokens;
  @override
  Future<void> clearCaregiver() async => caregiver = null;
  @override
  Future<String?> readDevice() async => device;
  @override
  Future<void> saveDevice(String token) async => device = token;
  @override
  Future<void> clearDevice() async => device = null;
}

ApiClient _client(
  _Store store,
  FutureOr<ResponseBody> Function(RequestOptions) respond, {
  FutureOr<ResponseBody> Function(RequestOptions)? refresh,
  void Function(ApiCredential)? invalidated,
}) {
  final client = ApiClient(
    config: ApiConfig('https://example.test/api/v1'),
    credentials: store,
    onCredentialsInvalidated: invalidated ?? (_) {},
    adapter: _Adapter(respond),
    refreshAdapter: _Adapter(refresh ?? (_) => _json(200, _newPair)),
  );
  addTearDown(client.close);
  return client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('login sends anonymous form data and saves both tokens', () async {
    final store = _Store();
    final client = _client(store, (request) {
      expect(request.path, '/auth/login');
      expect(request.method, 'POST');
      expect(request.contentType, 'application/x-www-form-urlencoded');
      expect(request.headers['Authorization'], isNull);
      final wire = utf8.decode(request.extra['test.wire'] as List<int>);
      expect(Uri.splitQueryString(wire), {
        'username': 'carer@example.test',
        'password': ' p&+word ',
      });
      return _json(200, _newPair);
    });
    await AuthRepository(
      client,
      store,
    ).login(' carer@example.test ', ' p&+word ');
    expect(store.caregiver?.accessToken, 'new-access');
    expect(store.caregiver?.refreshToken, 'new-refresh');
    expect(store.device, 'device-token');
  });
  test('invalid credentials never save a new session', () async {
    final store = _Store()..caregiver = null;
    final client = _client(store, (_) => _error(401, 'INVALID_CREDENTIALS'));
    await expectLater(
      AuthRepository(client, store).login('carer@example.test', 'wrong'),
      throwsA(
        isA<ApiFailure>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS'),
      ),
    );
    expect(store.caregiver, isNull);
  });
  test('malformed login responses cannot grant a session', () async {
    for (final body in [
      null,
      {},
      {..._newPair, 'access_token': ''},
      {..._newPair, 'token_type': 'other'},
      {..._newPair, 'expires_in': 0},
    ]) {
      final store = _Store()..caregiver = null;
      final client = _client(store, (_) => _json(200, body));
      await expectLater(
        AuthRepository(client, store).login('carer@example.test', 'password'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.invalidResponse,
          ),
        ),
      );
      expect(store.caregiver, isNull);
    }
  });
  test('secure storage failure cannot create a successful login', () async {
    final store = _FailingStore()..caregiver = null;
    final client = _client(store, (_) => _json(200, _newPair));
    await expectLater(
      AuthRepository(client, store).login('carer@example.test', 'password'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.credentials,
        ),
      ),
    );
    expect(store.caregiver, isNull);
  });
  test(
    'persisted credentials are verified before restoring route access',
    () async {
      final store = _Store();
      final response = Completer<ResponseBody>();
      final started = Completer<void>();
      final client = _client(store, (request) {
        expect(request.path, '/auth/me');
        expect(request.headers['Authorization'], 'Bearer old-access');
        started.complete();
        return response.future;
      });
      final container = ProviderContainer(
        overrides: [
          credentialStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(caregiverSessionProvider), isFalse);
      await started.future;
      response.complete(
        _json(200, {'id': 'caregiver-id', 'role': 'caregiver'}),
      );
      await container.read(caregiverSessionProvider.notifier).restoration;
      expect(container.read(caregiverSessionProvider), isTrue);
      container.read(credentialsInvalidatedProvider)(ApiCredential.caregiver);
      expect(container.read(caregiverSessionProvider), isFalse);
    },
  );
  test('a delayed restore cannot reauthorize after invalidation', () async {
    final store = _Store();
    final response = Completer<ResponseBody>();
    final started = Completer<void>();
    final client = _client(store, (_) {
      started.complete();
      return response.future;
    });
    final container = ProviderContainer(
      overrides: [
        credentialStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    container.read(caregiverSessionProvider);
    await started.future;
    container.read(caregiverSessionProvider.notifier).invalidate();
    response.complete(_json(200, {'id': 'caregiver-id', 'role': 'caregiver'}));
    await container.read(caregiverSessionProvider.notifier).restoration;
    expect(container.read(caregiverSessionProvider), isFalse);
  });
  test(
    'network failure during restore retains tokens without granting access',
    () async {
      final store = _Store();
      final client = _client(
        store,
        (_) => throw StateError('Connection unavailable'),
      );
      final container = ProviderContainer(
        overrides: [
          credentialStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.read(caregiverSessionProvider);
      await container.read(caregiverSessionProvider.notifier).restoration;
      expect(container.read(caregiverSessionProvider), isFalse);
      expect(store.caregiver, _oldTokens);
    },
  );
}

class _FailingStore extends _Store {
  @override
  Future<void> saveCaregiver(CaregiverTokens tokens) async =>
      throw StateError('Storage unavailable');
}
