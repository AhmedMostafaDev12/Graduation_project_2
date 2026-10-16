import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_service.dart';

enum RelayLink { connected, disconnected }

typedef RelayRequest = ({
  (String, String)? scope,
  bool foreground,
  String language,
  RelayLink link,
  bool simulated,
});

/// D1's Android service boundary. No tokens or personal data cross this channel.
abstract interface class RelayService {
  Future<bool> apply({
    required bool mayStart,
    required String language,
    required RelayLink link,
    required bool simulated,
  });
  Future<void> stop();
  Future<bool> takeOpenRequest();
  void onOpen(void Function()? callback);
  void dispose();
}

final relayServiceProvider = Provider<RelayService>((ref) {
  final service =
      ref.watch(permissionPlatformProvider) == PermissionPlatform.android
      ? AndroidRelayService()
      : UnsupportedRelayService();
  ref.onDispose(service.dispose);
  return service;
});

class AndroidRelayService implements RelayService {
  static const channel = MethodChannel('remori/relay');
  @override
  Future<bool> apply({
    required bool mayStart,
    required String language,
    required RelayLink link,
    required bool simulated,
  }) async =>
      await channel.invokeMethod<bool>('apply', {
        'mayStart': mayStart,
        'language': language == 'en' ? 'en' : 'ar',
        'link': link.name,
        'simulated': simulated,
      }) ==
      true;
  @override
  Future<void> stop() => channel.invokeMethod<void>('stop');
  @override
  Future<bool> takeOpenRequest() async =>
      await channel.invokeMethod<bool>('takeOpenRequest') == true;
  @override
  void onOpen(void Function()? callback) => channel.setMethodCallHandler(
    callback == null
        ? null
        : (call) async {
            if (call.method == 'openPatient') callback();
          },
  );
  @override
  void dispose() => onOpen(null);
}

class UnsupportedRelayService implements RelayService {
  @override
  Future<bool> apply({
    required bool mayStart,
    required String language,
    required RelayLink link,
    required bool simulated,
  }) async => false;
  @override
  Future<void> stop() async {}
  @override
  Future<bool> takeOpenRequest() async => false;
  @override
  void onOpen(void Function()? callback) {}
  @override
  void dispose() {}
}

/// Serializes platform calls so logout/disposal wins over an in-flight start.
class RelayDriver {
  RelayDriver(this.service);
  final RelayService service;
  Future<void> _tail = Future.value();
  int _generation = 0;
  bool _disposed = false;
  (String, String)? _scope;
  Future<void> submit(RelayRequest request) {
    final generation = ++_generation;
    _tail = _tail
        .then((_) async {
          if (_disposed || generation != _generation) return;
          if (request.scope == null) {
            _scope = null;
            await service.stop();
            return;
          }
          if (_scope != request.scope) {
            await service.stop();
            if (_disposed || generation != _generation) return;
            _scope = request.scope;
          }
          await service.apply(
            mayStart: request.foreground,
            language: request.language,
            link: request.link,
            simulated: request.simulated,
          );
        })
        .catchError((Object _) {
          /* Native denial leaves the service stopped. */
        });
    return _tail;
  }

  Future<void> close() {
    _disposed = true;
    ++_generation;
    _tail = _tail.then((_) => service.stop()).catchError((Object _) {});
    return _tail;
  }
}
