import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionPlatform { android, ios, unsupported }

enum SetupPermission { bluetooth, notifications, location, background }

enum PermissionAccess { granted, denied, limited, blocked, restricted, unknown }

abstract interface class PermissionService {
  PermissionPlatform get platform;
  Future<Map<SetupPermission, PermissionAccess>> read();
  Future<void> request(SetupPermission permission);
}

final permissionPlatformProvider = Provider<PermissionPlatform>(
  (ref) => kIsWeb
      ? PermissionPlatform.unsupported
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => PermissionPlatform.android,
          TargetPlatform.iOS => PermissionPlatform.ios,
          _ => PermissionPlatform.unsupported,
        },
);
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => NativePermissionService(ref.watch(permissionPlatformProvider)),
);

/// Permission preparation only; this does not connect/start a glasses relay.
class NativePermissionService implements PermissionService {
  NativePermissionService(this.platform);
  @override
  final PermissionPlatform platform;
  static const host = MethodChannel('remori/permissions');
  Future<int>? _sdk;
  Future<int> get sdk =>
      _sdk ??= host.invokeMethod<int>('androidSdk').then((value) => value ?? 0);

  List<SetupPermission> get supported => switch (platform) {
    PermissionPlatform.android => SetupPermission.values,
    PermissionPlatform.ios => [SetupPermission.notifications],
    PermissionPlatform.unsupported => [],
  };

  static PermissionAccess access(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => PermissionAccess.granted,
    PermissionStatus.limited ||
    PermissionStatus.provisional => PermissionAccess.limited,
    PermissionStatus.permanentlyDenied => PermissionAccess.blocked,
    PermissionStatus.restricted => PermissionAccess.restricted,
    _ => PermissionAccess.denied,
  };

  Future<List<Permission>> _permissions(SetupPermission kind) async =>
      switch (kind) {
        SetupPermission.bluetooth =>
          await sdk >= 31
              ? [Permission.bluetoothScan, Permission.bluetoothConnect]
              : [Permission.bluetooth],
        SetupPermission.notifications => [Permission.notification],
        SetupPermission.location => [Permission.locationWhenInUse],
        SetupPermission.background => [],
      };

  Future<PermissionAccess> _readOne(SetupPermission kind) async {
    if (kind == SetupPermission.background) {
      final allowed = await host.invokeMethod<bool>('backgroundAllowed');
      return allowed == true
          ? PermissionAccess.granted
          : PermissionAccess.denied;
    }
    final values = await Future.wait(
      (await _permissions(kind))
          .map((permission) async => access(await permission.status)),
    );
    for (final outcome in [
      PermissionAccess.restricted,
      PermissionAccess.blocked,
      PermissionAccess.denied,
      PermissionAccess.limited,
    ]) {
      if (values.contains(outcome)) return outcome;
    }
    return PermissionAccess.granted;
  }

  @override
  Future<Map<SetupPermission, PermissionAccess>> read() async {
    final result = <SetupPermission, PermissionAccess>{};
    for (final kind in supported) {
      result[kind] = await _readOne(kind);
    }
    return result;
  }

  @override
  Future<void> request(SetupPermission kind) async {
    if (!supported.contains(kind)) return;
    if (kind == SetupPermission.background) {
      await host.invokeMethod<void>('openBatterySettings');
      return;
    }
    final permissions = await _permissions(kind);
    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );
    if (statuses.any(
      (status) =>
          status.isPermanentlyDenied ||
          status.isRestricted ||
          status.isLimited ||
          status.isProvisional,
    )) {
      if (!await openAppSettings()) throw StateError('Settings unavailable');
      return;
    }
    // Do not request Always/background location or battery-exemption permissions.
    await permissions.request();
  }
}
