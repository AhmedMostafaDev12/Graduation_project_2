import 'dart:async';

import 'glasses_message.dart';

enum GlassesConnectionState { disconnected, connecting, connected }

abstract class GlassesConnection {
  GlassesConnectionState get state;
  Stream<GlassesConnectionState> get states;
  Stream<IncomingGlassesMessage> get messages;
  Future<void> connect(String serial);
  Future<void> disconnect();
  Future<void> send(OutgoingGlassesMessage message);
  void dispose();
}

final class BleGlassesConnection implements GlassesConnection {
  // TODO(BLE): implement §7.1 with flutter_blue_plus after hardware contracts.
  @override
  GlassesConnectionState get state => GlassesConnectionState.disconnected;
  @override
  Stream<GlassesConnectionState> get states => throw UnimplementedError();
  @override
  Stream<IncomingGlassesMessage> get messages => throw UnimplementedError();
  @override
  Future<void> connect(String serial) async => throw UnimplementedError();
  @override
  Future<void> disconnect() async => throw UnimplementedError();
  @override
  Future<void> send(OutgoingGlassesMessage message) async =>
      throw UnimplementedError();
  @override
  void dispose() {}
}
