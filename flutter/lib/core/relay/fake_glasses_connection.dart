import 'dart:async';

import 'package:uuid/uuid.dart';

import 'glasses_connection.dart';
import 'glasses_message.dart';

/// Development transport: no API writes, permission requests or payload logs.
final class FakeGlassesConnection implements GlassesConnection {
  final _states = StreamController<GlassesConnectionState>.broadcast();
  final _messages = StreamController<IncomingGlassesMessage>.broadcast();
  final _pending = <String, IncomingGlassesMessage>{};
  final _pendingRefs = <String>{};
  final _uuid = const Uuid();
  Timer? _timer;
  bool _disposed = false;
  bool _timeSynced = false;
  int _tick = 0;
  int _battery = 76;
  DateTime? _utc;
  String? _serial;
  GlassesConnectionState _state = GlassesConnectionState.disconnected;

  @override
  GlassesConnectionState get state => _state;
  @override
  Stream<GlassesConnectionState> get states => _states.stream;
  @override
  Stream<IncomingGlassesMessage> get messages => _messages.stream;
  Set<String> get pendingIds => Set.unmodifiable(_pending.keys);
  Set<String> get pendingRefs => Set.unmodifiable(_pendingRefs);

  void _setState(GlassesConnectionState value) {
    _state = value;
    _states.add(value);
  }

  @override
  Future<void> connect(String serial) async {
    if (_disposed) throw StateError('Connection disposed');
    if (serial.trim().isEmpty) throw ArgumentError('Serial is required');
    if (_serial != null &&
        _serial != serial.trim() &&
        (_pending.isNotEmpty || _pendingRefs.isNotEmpty)) {
      throw StateError('Acknowledge queued items before changing glasses');
    }
    if (_serial != serial.trim()) {
      _tick = 0;
      _battery = 76;
    }
    _serial = serial.trim();
    if (_state != GlassesConnectionState.disconnected) await disconnect();
    _timeSynced = false;
    _setState(GlassesConnectionState.connecting);
    _setState(GlassesConnectionState.connected);
    _messages.add(
      Hello(
        deviceSerial: serial.trim(),
        firmwareVersion: '0.3.1',
        protocolVersion: 1,
        queue: GlassesQueue(
          events: _pending.length,
          audioSegments: 0,
          media: _pendingRefs.length,
        ),
      ),
    );
  }

  @override
  Future<void> send(OutgoingGlassesMessage message) async {
    if (_disposed || _state != GlassesConnectionState.connected) {
      throw StateError('Glasses disconnected');
    }
    if (!_timeSynced && message is! TimeSync) {
      throw StateError('time_sync must follow hello');
    }
    if (message is TimeSync) {
      final utc = DateTime.parse(message.utc);
      if (!utc.isUtc || message.timezone.isEmpty) {
        throw const FormatException('UTC time and timezone required');
      }
      _utc = utc;
      if (!_timeSynced) {
        _timeSynced = true;
        for (final item in _pending.values) {
          _messages.add(item);
        }
        _timer = Timer.periodic(
          const Duration(seconds: 60),
          (_) => _emitTick(),
        );
      }
    } else if (message is Ack) {
      for (final id in message.ids) {
        _pending.remove(id);
      }
      _pendingRefs.removeAll(message.refs);
    }
  }

  void _emitTick() {
    _tick++;
    _utc = _utc!.add(const Duration(seconds: 60));
    for (final item in _pending.values) {
      _messages.add(item);
    }
    _messages.add(
      Telemetry(
        batteryPct: _battery,
        tempC: 61,
        memoryPaused: false,
        storageFreeMb: 2100,
      ),
    );
    if (_tick % 5 == 0 && _battery > 0) _battery--;
    if (_tick % 3 == 0) {
      final id = _uuid.v4();
      final ref = 'img-$id';
      _pendingRefs.add(ref);
      _enqueue(
        id,
        Encounter(
          id: id,
          personId: null,
          startedAt: _utc!
              .subtract(const Duration(seconds: 30))
              .toIso8601String(),
          endedAt: _utc!.toIso8601String(),
          bestConfidence: 0.94,
          announced: false,
          keyframeRef: ref,
          unknownEmbedding: null,
        ),
      );
    }
    if (_tick % 4 == 0) {
      final id = _uuid.v4();
      _enqueue(
        id,
        ReminderState(
          logId: id,
          status: 'completed',
          via: 'voice',
          snoozedUntil: null,
          at: _utc!.toIso8601String(),
        ),
      );
    }
  }

  void _enqueue(String id, IncomingGlassesMessage item) {
    _pending[id] = item;
    _messages.add(item);
  }

  /// Test hook and future debug-only toggle; not exposed by the release provider.
  Future<void> forceDisconnected() => disconnect();

  @override
  Future<void> disconnect() async {
    if (_disposed) return;
    _timer?.cancel();
    _timer = null;
    _timeSynced = false;
    _setState(GlassesConnectionState.disconnected);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _timer?.cancel();
    _disposed = true;
    _state = GlassesConnectionState.disconnected;
    unawaited(_states.close());
    unawaited(_messages.close());
  }
}
