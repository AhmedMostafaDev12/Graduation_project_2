import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/api/api_client.dart';
import 'package:remori/features/device_pairing/data/pairing_repository.dart';
import 'package:remori/features/device_pairing/presentation/glasses_qr_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
const deviceId = '00000002-0000-4000-8000-000000000001';
const grant = {
  'device_id': deviceId,
  'patient_id': patientId,
  'serial_number': 'RMR-0007',
  'device_token': 'test-only-device-secret',
  'paired_at': '2026-10-14T00:00:00Z',
};

class RetryStore extends _Store {
  bool fails = true;
  @override
  Future<void> saveDevice(String token) async {
    if (fails) throw StateError('Storage unavailable');
    device = token;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('pairing authenticates as caregiver and stores token before returning metadata', () async {
    final store = _Store();
    final client = _client(store, (request) {
      expect(request.path, '/devices/pair');
      expect(request.headers['Authorization'], 'Bearer old-access');
      expect(jsonDecode(utf8.decode(request.extra['test.wire'] as List<int>)), {
        'patient_id': patientId,
        'serial_number': 'RMR-0007',
      });
      return _json(201, grant);
    });
    final info = await PairingRepository(
      client,
      store,
    ).pair(patientId, ' RMR-0007 ');
    expect(info.deviceId, deviceId);
    expect(info.patientId, patientId);
    expect(store.device, 'test-only-device-secret');
    expect(info.toString(), isNot(contains('test-only-device-secret')));
    expect(store.caregiver, _oldTokens);
  });
  test('storage retry reuses the received token without re-pairing', () async {
    var requests = 0;
    final store = RetryStore();
    final client = _client(store, (_) {
      requests++;
      return _json(201, grant);
    });
    final repository = PairingRepository(client, store);
    await expectLater(
      repository.pair(patientId, 'RMR-0007'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.credentials,
        ),
      ),
    );
    expect(store.device, 'device-token');
    store.fails = false;
    final info = await repository.pair(patientId, 'RMR-0007');
    expect(info.serial, 'RMR-0007');
    expect(requests, 1);
    expect(store.device, 'test-only-device-secret');
  });
  test(
    'disposed storage retry cannot reuse the previous session grant',
    () async {
      var requests = 0;
      final store = RetryStore();
      final client = _client(store, (_) {
        requests++;
        return _json(201, grant);
      });
      final old = PairingRepository(client, store);
      await expectLater(
        old.pair(patientId, 'RMR-0007'),
        throwsA(isA<ApiFailure>()),
      );
      old.dispose();
      store.fails = false;
      await expectLater(
        old.pair(patientId, 'RMR-0007'),
        throwsA(isA<ApiFailure>()),
      );
      expect(requests, 1);
      expect(store.device, 'device-token');
      await PairingRepository(client, store).pair(patientId, 'RMR-0007');
      expect(requests, 2);
    },
  );
  test(
    'disposed in-flight pairing cannot store or return a late grant',
    () async {
      final started = Completer<void>(), release = Completer<void>();
      final store = _Store();
      final client = _client(store, (_) async {
        started.complete();
        await release.future;
        return _json(201, grant);
      });
      final repository = PairingRepository(client, store);
      final pending = repository.pair(patientId, 'RMR-0007');
      await started.future;
      repository.dispose();
      release.complete();
      await expectLater(pending, throwsA(isA<ApiFailure>()));
      expect(store.device, 'device-token');
    },
  );

  test('pairing conflicts never overwrite existing credentials', () async {
    final store = _Store();
    final client = _client(store, (_) => _error(409, 'DEVICE_ALREADY_PAIRED'));
    await expectLater(
      PairingRepository(client, store).pair(patientId, 'RMR-0007'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.code,
          'code',
          'DEVICE_ALREADY_PAIRED',
        ),
      ),
    );
    expect(store.device, 'device-token');
  });
  test('malformed or mismatched responses never save a token', () async {
    for (final body in [
      null,
      {},
      {...grant, 'device_token': ''},
      {...grant, 'patient_id': deviceId},
      {...grant, 'serial_number': 'OTHER'},
    ]) {
      final store = _Store();
      final client = _client(store, (_) => _json(201, body));
      await expectLater(
        PairingRepository(client, store).pair(patientId, 'RMR-0007'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.invalidResponse,
          ),
        ),
      );
      expect(store.device, 'device-token');
    }
  });
  test('camera extraction accepts plain case QR only', () {
    expect(
      GlassesQrScanner.serialFrom(
        const BarcodeCapture(
          barcodes: [
            Barcode(format: BarcodeFormat.qrCode, rawValue: ' RMR-0007 '),
          ],
        ),
      ),
      'RMR-0007',
    );
    for (final barcode in [
      const Barcode(format: BarcodeFormat.code128, rawValue: 'RMR-0007'),
      const Barcode(format: BarcodeFormat.qrCode, rawValue: ''),
      const Barcode(
        format: BarcodeFormat.qrCode,
        rawValue: 'https://example.test',
      ),
      const Barcode(
        format: BarcodeFormat.qrCode,
        rawValue: '{"serial":"RMR-0007"}',
      ),
    ]) {
      expect(
        GlassesQrScanner.serialFrom(BarcodeCapture(barcodes: [barcode])),
        isNull,
      );
    }
  });
}
