import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/api_client.dart';
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

  test('configuration rejects absent URLs, wrong prefixes and insecure release URLs', () {
    for (final url in [
      '',
      'https://example.test',
      'https://user:pass@example.test/api/v1',
      'https://example.test/api/v1?key=value',
      'http://example.test/api/v1',
    ]) {
      expect(() => ApiConfig(url, allowInsecure: false), throwsArgumentError);
    }
    expect(
      ApiConfig('https://example.test/api/v1/').baseUrl,
      'https://example.test/api/v1',
    );
    expect(
      ApiConfig('http://localhost:8000/api/v1', allowInsecure: true).baseUrl,
      'http://localhost:8000/api/v1',
    );
  });

  test(
    'caregiver, device and public requests have independent authentication',
    () async {
      final headers = <String?>[];
      final client = _client(_Store(), (request) {
        expect(request.uri.path, '/api/v1/patients');
        expect(request.followRedirects, isFalse);
        headers.add(request.headers['Authorization'] as String?);
        return _json(200, []);
      });
      for (final credential in ApiCredential.values) {
        await client.request<dynamic>('/patients', credential: credential);
      }
      expect(headers, [null, 'Bearer old-access', 'Bearer device-token']);
      for (final path in [
        'https://s3.example.test/file',
        '//s3.example.test/file',
        '../file',
        '/%2e%2e/file',
        '/patients?token=private',
      ]) {
        await expectLater(
          client.request<dynamic>(path, credential: ApiCredential.caregiver),
          throwsArgumentError,
        );
      }
    },
  );

  test('login form encoding has no bearer header', () async {
    final client = _client(_Store(), (request) {
      expect(request.headers['Authorization'], isNull);
      expect(request.contentType, Headers.formUrlEncodedContentType);
      expect(
        utf8.decode(request.extra['test.wire'] as List<int>),
        'username=test%40example.test&password=example-password',
      );
      return _json(200, _newPair);
    });
    await client.request<dynamic>(
      '/auth/login',
      credential: ApiCredential.none,
      method: 'POST',
      contentType: Headers.formUrlEncodedContentType,
      data: {'username': 'test@example.test', 'password': 'example-password'},
    );
  });

  test('simultaneous expired requests share refresh and persist both tokens before retry', () async {
    final store = _Store();
    var refreshes = 0;
    var oldRequests = 0;
    final bothExpired = Completer<void>();
    final client = _client(
      store,
      (request) {
        if (request.headers['Authorization'] == 'Bearer old-access') {
          oldRequests++;
          if (oldRequests == 2) bothExpired.complete();
          return _error(401, 'TOKEN_EXPIRED');
        }
        expect(store.caregiver!.refreshToken, 'new-refresh');
        expect(request.headers['Authorization'], 'Bearer new-access');
        return _json(200, {'ok': true});
      },
      refresh: (request) async {
        refreshes++;
        expect(request.headers['Authorization'], isNull);
        expect(request.data, {'refresh_token': 'old-refresh'});
        await bothExpired.future;
        return _json(200, _newPair);
      },
    );
    final responses = await Future.wait([
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
      client.request<dynamic>('/auth/me', credential: ApiCredential.caregiver),
    ]);
    expect(refreshes, 1);
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(store.caregiver!.accessToken, 'new-access');
  });

  test('a delayed expired response uses rotated credentials without another refresh', () async {
    final store = _Store();
    final lateResponse = Completer<void>();
    var refreshes = 0;
    final client = _client(
      store,
      (request) async {
        if (request.headers['Authorization'] == 'Bearer old-access') {
          if (request.path == '/auth/me') await lateResponse.future;
          return _error(401, 'TOKEN_EXPIRED');
        }
        if (!lateResponse.isCompleted) lateResponse.complete();
        return _json(200, {});
      },
      refresh: (_) {
        refreshes++;
        return _json(200, _newPair);
      },
    );
    await Future.wait([
      client.request<dynamic>('/auth/me', credential: ApiCredential.caregiver),
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
    ]);
    expect(refreshes, 1);
  });

  test(
    'invalid refresh clears only caregiver tokens and emits invalidation',
    () async {
      final store = _Store();
      final invalidated = <ApiCredential>[];
      final client = _client(
        store,
        (_) => _error(401, 'TOKEN_EXPIRED'),
        refresh: (_) => _error(401, 'INVALID_REFRESH_TOKEN'),
        invalidated: invalidated.add,
      );
      await expectLater(
        client.request<dynamic>(
          '/patients',
          credential: ApiCredential.caregiver,
        ),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.code,
            'code',
            'INVALID_REFRESH_TOKEN',
          ),
        ),
      );
      expect(store.caregiver, isNull);
      expect(store.device, 'device-token');
      expect(invalidated, [ApiCredential.caregiver]);
    },
  );

  test(
    'device rejection never refreshes or removes caregiver tokens',
    () async {
      final store = _Store();
      var refreshes = 0;
      final client = _client(
        store,
        (_) => _error(401, 'INVALID_TOKEN'),
        refresh: (_) {
          refreshes++;
          return _json(200, _newPair);
        },
      );
      await expectLater(
        client.request<dynamic>(
          '/patients/id/sync',
          credential: ApiCredential.device,
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(refreshes, 0);
      expect(store.device, isNull);
      expect(store.caregiver, isNotNull);
    },
  );

  test('a second expired response stops after one retry', () async {
    var requests = 0;
    var refreshes = 0;
    final client = _client(
      _Store(),
      (_) {
        requests++;
        return _error(401, 'TOKEN_EXPIRED');
      },
      refresh: (_) {
        refreshes++;
        return _json(200, _newPair);
      },
    );
    await expectLater(
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
      throwsA(isA<ApiFailure>()),
    );
    expect(requests, 2);
    expect(refreshes, 1);
  });

  test('a transient refresh failure preserves credentials', () async {
    final store = _Store();
    final client = _client(
      store,
      (_) => _error(401, 'TOKEN_EXPIRED'),
      refresh: (_) => _error(503, 'DATABASE_UNAVAILABLE'),
    );
    await expectLater(
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'DATABASE_UNAVAILABLE',
        ),
      ),
    );
    expect(store.caregiver, same(_oldTokens));
  });

  test('logout during refresh cannot restore the old session', () async {
    final store = _Store();
    final client = _client(
      store,
      (_) => _error(401, 'TOKEN_EXPIRED'),
      refresh: (_) async {
        await store.clearCaregiver();
        return _json(200, _newPair);
      },
    );
    await expectLater(
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          ApiFailureKind.credentials,
        ),
      ),
    );
    expect(store.caregiver, isNull);
  });

  test('multipart replay clones finalized form data', () async {
    var attempts = 0;
    final client = _client(_Store(), (request) {
      attempts++;
      expect(request.data, isA<FormData>());
      return attempts == 1 ? _error(401, 'TOKEN_EXPIRED') : _json(201, {});
    });
    await client.request<dynamic>(
      '/patients/id/people',
      credential: ApiCredential.caregiver,
      method: 'POST',
      data: FormData.fromMap({
        'photos': MultipartFile.fromBytes([1, 2, 3], filename: 'test.jpg'),
      }),
    );
    expect(attempts, 2);
  });

  test('validation fields survive mapping while exception strings omit messages and payloads', () async {
    final client = _client(
      _Store(),
      (_) => _json(422, {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Private server message',
          'details': [
            {'field': 'body.photos.2', 'message': 'Private photo detail'},
          ],
        },
      }),
    );
    try {
      await client.request<dynamic>(
        '/patients',
        credential: ApiCredential.none,
      );
      fail('Expected validation error');
    } on ApiFailure catch (failure) {
      expect(failure.details.single.field, 'body.photos.2');
      expect(failure.toString(), isNot(contains('Private')));
    }
    expect(_oldTokens.toString(), isNot(contains('old-access')));
  });

  test(
    'malformed server responses and cancellation map to separate failure kinds',
    () async {
      final client = _client(
        _Store(),
        (_) => _json(502, {'unexpected': 'private'}),
      );
      await expectLater(
        client.request<dynamic>('/patients', credential: ApiCredential.none),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ApiFailureKind.invalidResponse,
          ),
        ),
      );
      final cancelled = CancelToken()..cancel('private reason');
      await expectLater(
        client.request<dynamic>(
          '/patients',
          credential: ApiCredential.none,
          cancelToken: cancelled,
        ),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ApiFailureKind.cancelled,
          ),
        ),
      );
    },
  );

  test('secure storage saves a token pair together and preserves device credentials on logout', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SecureCredentialStore();
    await store.saveCaregiver(_oldTokens);
    await store.saveDevice('paired-device');
    expect((await store.readCaregiver())!.refreshToken, 'old-refresh');
    final stored = await const FlutterSecureStorage().readAll();
    expect(
      stored.values.where((value) => value.contains('old-access')).length,
      1,
    );
    expect(
      stored.values.where((value) => value.contains('old-refresh')).length,
      1,
    );
    await store.clearCaregiver();
    expect(await store.readCaregiver(), isNull);
    expect(await store.readDevice(), 'paired-device');
  });
  test(
    'timeouts and connection failures preserve credentials and omit details',
    () async {
      for (final (type, kind) in [
        (DioExceptionType.connectionTimeout, ApiFailureKind.timeout),
        (DioExceptionType.connectionError, ApiFailureKind.network),
      ]) {
        final store = _Store();
        final client = _client(
          store,
          (request) => throw DioException(
            requestOptions: request,
            type: type,
            message: 'private transport detail',
          ),
        );
        await expectLater(
          client.request<dynamic>(
            '/patients',
            credential: ApiCredential.caregiver,
          ),
          throwsA(
            isA<ApiFailure>()
                .having((failure) => failure.kind, 'kind', kind)
                .having(
                  (failure) => failure.toString(),
                  'safe string',
                  isNot(contains('private')),
                ),
          ),
        );
        expect(store.caregiver, same(_oldTokens));
      }
    },
  );

  test('malformed refresh payload does not replace stored tokens', () async {
    final store = _Store();
    final client = _client(
      store,
      (_) => _error(401, 'TOKEN_EXPIRED'),
      refresh: (_) => _json(200, {'access_token': 'incomplete'}),
    );
    await expectLater(
      client.request<dynamic>('/patients', credential: ApiCredential.caregiver),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          ApiFailureKind.invalidResponse,
        ),
      ),
    );
    expect(store.caregiver, same(_oldTokens));
  });
}
