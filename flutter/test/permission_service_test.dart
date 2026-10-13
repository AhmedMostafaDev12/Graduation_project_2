import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remori/core/relay/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const plugin = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var sdk = 35;
  var battery = false;
  var blocked = false;
  var settings = 0;
  final requests = <List<int>>[];
  final checked = <int>[];
  setUp(() {
    sdk = 35;
    battery = false;
    blocked = false;
    settings = 0;
    requests.clear();
    checked.clear();
    messenger.setMockMethodCallHandler(NativePermissionService.host, (
      call,
    ) async {
      switch (call.method) {
        case 'androidSdk':
          return sdk;
        case 'backgroundAllowed':
          return battery;
        case 'openBatterySettings':
          settings++;
          return null;
        default:
          throw StateError('Unexpected native method');
      }
    });
    messenger.setMockMethodCallHandler(plugin, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          checked.add(call.arguments as int);
          return blocked
              ? PermissionStatus.permanentlyDenied.index
              : PermissionStatus.denied.index;
        case 'requestPermissions':
          final values = List<int>.from(call.arguments as List);
          requests.add(values);
          return {
            for (final value in values) value: PermissionStatus.granted.index,
          };
        case 'openAppSettings':
          settings++;
          return true;
        default:
          throw StateError('Unexpected permission method');
      }
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(plugin, null);
    messenger.setMockMethodCallHandler(NativePermissionService.host, null);
  });
  test('Android requests Scan and Connect on modern versions', () async {
    await NativePermissionService(PermissionPlatform.android)
        .request(SetupPermission.bluetooth);
    expect(requests.single, [
      Permission.bluetoothScan.value,
      Permission.bluetoothConnect.value,
    ]);
  });
  test('legacy Android uses the legacy Bluetooth group', () async {
    sdk = 30;
    await NativePermissionService(PermissionPlatform.android)
        .request(SetupPermission.bluetooth);
    expect(requests.single, [Permission.bluetooth.value]);
  });
  test('location requests foreground only and background opens settings without exemption requests', () async {
    final service = NativePermissionService(PermissionPlatform.android);
    await service.request(SetupPermission.location);
    await service.request(SetupPermission.background);
    expect(requests.single, [Permission.locationWhenInUse.value]);
    expect(settings, 1);
    final first = await service.read();
    expect(first[SetupPermission.background], PermissionAccess.denied);
    battery = true;
    expect(
      (await service.read())[SetupPermission.background],
      PermissionAccess.granted,
    );
  });
  test('permanent denial opens app settings without another prompt', () async {
    blocked = true;
    await NativePermissionService(PermissionPlatform.android)
        .request(SetupPermission.notifications);
    expect(settings, 1);
    expect(requests, isEmpty);
  });
  test('iOS checks and requests notifications only', () async {
    final service = NativePermissionService(PermissionPlatform.ios);
    expect((await service.read()).keys, [SetupPermission.notifications]);
    await service.request(SetupPermission.bluetooth);
    await service.request(SetupPermission.location);
    await service.request(SetupPermission.background);
    await service.request(SetupPermission.notifications);
    expect(
      checked.every((value) => value == Permission.notification.value),
      isTrue,
    );
    expect(requests.single, [Permission.notification.value]);
  });
  test('provisional/restricted access is not reported as granted', () {
    expect(
      NativePermissionService.access(PermissionStatus.provisional),
      PermissionAccess.limited,
    );
    expect(
      NativePermissionService.access(PermissionStatus.restricted),
      PermissionAccess.restricted,
    );
  });
}
