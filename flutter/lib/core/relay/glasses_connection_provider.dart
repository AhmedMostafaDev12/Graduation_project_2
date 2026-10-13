import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_glasses_connection.dart';
import 'glasses_connection.dart';

GlassesConnection createGlassesConnection({
  required bool releaseMode,
  required bool fakeRequested,
}) => !releaseMode && fakeRequested
    ? FakeGlassesConnection()
    : BleGlassesConnection();

final glassesConnectionProvider = Provider<GlassesConnection>((ref) {
  final connection = createGlassesConnection(
    releaseMode: kReleaseMode,
    fakeRequested: const bool.fromEnvironment('REMORI_FAKE_GLASSES'),
  );
  ref.onDispose(connection.dispose);
  return connection;
});

/// Callback for a future debug-only toggle, unavailable in release and real BLE.
/// PR A adds the hook without introducing screen controls.
final debugGlassesDisconnectProvider = Provider<Future<void> Function()?>((
  ref,
) {
  if (kReleaseMode) return null;
  final connection = ref.watch(glassesConnectionProvider);
  return connection is FakeGlassesConnection
      ? connection.forceDisconnected
      : null;
});
