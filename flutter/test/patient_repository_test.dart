import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/features/enrollment/data/patient_repository.dart';
import 'package:remori/features/enrollment/domain/patient_draft.dart';
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

const patientId = '00000001-0000-4000-8000-000000000001';
PatientDraft draft({
  bool conversation = false,
  bool cloud = false,
  String? birth,
  String timezone = '',
}) => PatientDraft(
  name: ' Test Patient ',
  relationship: ' daughter ',
  language: 'ar',
  timezone: timezone,
  dateOfBirth: birth,
  conversationConsent: conversation,
  cloudConsent: cloud,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('only checked consents are sent with caregiver authorization', () async {
    for (final conversation in [false, true]) {
      for (final cloud in [false, true]) {
        final store = _Store();
        final client = _client(store, (request) {
          expect(request.path, '/patients');
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer old-access');
          final body = jsonDecode(
            utf8.decode(request.extra['test.wire'] as List<int>),
          );
          expect(body, {
            'full_name': 'Test Patient',
            'relationship': 'daughter',
            'preferred_language': 'ar',
            'consents': [
              if (conversation) 'ambient_audio_household',
              if (cloud) 'cloud_processing',
            ],
          });
          return _json(201, {'id': patientId});
        });
        expect(
          await PatientRepository(client)
              .create(draft(conversation: conversation, cloud: cloud)),
          patientId,
        );
      }
    }
  });
  test('date and timezone preserve contract values', () {
    final json = draft(
      birth: '1954-03-12',
      timezone: ' Africa/Cairo ',
    ).toJson();
    expect(json['date_of_birth'], '1954-03-12');
    expect(json['timezone'], 'Africa/Cairo');
  });
  test('calendar dates accept Arabic digits and reject rollover', () {
    expect(PatientDraft.parseBirthDate(' 29 / 02 / 2024 '), '2024-02-29');
    expect(PatientDraft.parseBirthDate('١٢ / ٠٣ / ١٩٥٤'), '1954-03-12');
    for (final text in [
      '29 / 02 / 2023',
      '31/04/1954',
      '12/13/1954',
      '00/01/1954',
      '12/03/0000',
      '1954-03-12',
    ]) {
      expect(PatientDraft.parseBirthDate(text), isNull);
    }
  });
  test('validation failures do not return a pairing identity', () async {
    final client = _client(_Store(), (_) => _error(422, 'VALIDATION_ERROR'));
    await expectLater(
      PatientRepository(client).create(draft()),
      throwsA(
        isA<ApiFailure>().having((e) => e.code, 'code', 'VALIDATION_ERROR'),
      ),
    );
  });
  test('invalid creation responses are rejected', () async {
    for (final body in [
      null,
      {},
      {'id': 'invalid'},
    ]) {
      final client = _client(_Store(), (_) => _json(201, body));
      await expectLater(
        PatientRepository(client).create(draft()),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.invalidResponse,
          ),
        ),
      );
    }
  });
}
