import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remori/core/relay/fake_glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection.dart';
import 'package:remori/core/relay/glasses_connection_provider.dart';
import 'package:remori/core/relay/glasses_message.dart';

const time = TimeSync(utc: '2026-10-14T09:00:00Z', timezone: 'Africa/Cairo');

void main() {
  test('queued data cannot be replayed under a different serial', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      connection.send(time);
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 3));
      expectLater(connection.connect('RMR-0009'), throwsStateError);
      clock.flushMicrotasks();
      connection.dispose();
      clock.flushMicrotasks();
    });
  });

  test('debug disconnect hook exists only for the fake connection', () async {
    final realContainer = ProviderContainer();
    addTearDown(realContainer.dispose);
    expect(realContainer.read(debugGlassesDisconnectProvider), isNull);
    final fake = FakeGlassesConnection();
    final container = ProviderContainer(
      overrides: [
        glassesConnectionProvider.overrideWith((ref) {
          ref.onDispose(fake.dispose);
          return fake;
        }),
      ],
    );
    addTearDown(container.dispose);
    await fake.connect('RMR-0008');
    await container.read(debugGlassesDisconnectProvider)!();
    expect(fake.state, GlassesConnectionState.disconnected);
  });

  test('dispose cancels timers, closes streams and prevents reuse', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      var closed = false;
      connection.messages.listen((_) {}, onDone: () => closed = true);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      connection.send(time);
      clock.flushMicrotasks();
      expect(clock.periodicTimerCount, 1);
      connection.send(time);
      clock.flushMicrotasks();
      expect(clock.periodicTimerCount, 1);
      connection.dispose();
      clock.flushMicrotasks();
      expect(clock.periodicTimerCount, 0);
      expect(closed, isTrue);
      expectLater(connection.connect('RMR-0008'), throwsStateError);
      clock.flushMicrotasks();
      connection.dispose();
    });
  });

  test('connect emits states and exact hello, waiting for time_sync', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      final states = <GlassesConnectionState>[];
      final messages = <IncomingGlassesMessage>[];
      connection.states.listen(states.add);
      connection.messages.listen(messages.add);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      expect(states, [
        GlassesConnectionState.connecting,
        GlassesConnectionState.connected,
      ]);
      expect(messages.single.toJson(), {
        'type': 'hello',
        'device_serial': 'RMR-0008',
        'firmware_version': '0.3.1',
        'protocol_version': 1,
        'queue': {'events': 0, 'audio_segments': 0, 'media': 0},
      });
      clock.elapse(const Duration(minutes: 2));
      expect(messages.length, 1);
      connection.dispose();
      clock.flushMicrotasks();
    });
  });

  test('time_sync starts 60-second telemetry, battery falls gradually', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      final messages = <IncomingGlassesMessage>[];
      connection.messages.listen(messages.add);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      connection.send(time);
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 59));
      expect(messages.whereType<Telemetry>(), isEmpty);
      clock.elapse(const Duration(seconds: 1));
      expect(messages.whereType<Telemetry>().single.toJson(), {
        'type': 'telemetry',
        'battery_pct': 76,
        'temp_c': 61,
        'memory_paused': false,
        'storage_free_mb': 2100,
      });
      clock.elapse(const Duration(minutes: 5));
      expect(messages.whereType<Telemetry>().last.batteryPct, 75);
      connection.dispose();
      clock.flushMicrotasks();
    });
  });

  test('items keep UUIDs until ack, refs are acknowledged independently', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      final messages = <IncomingGlassesMessage>[];
      connection.messages.listen(messages.add);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      connection.send(time);
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 4));
      final encounter = messages.whereType<Encounter>().first;
      final reminder = messages.whereType<ReminderState>().first;
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuid.hasMatch(encounter.id), isTrue);
      expect(uuid.hasMatch(reminder.logId), isTrue);
      expect(encounter.personId, isNull);
      expect(encounter.unknownEmbedding, isNull);
      expect(
        connection.pendingIds,
        containsAll([encounter.id, reminder.logId]),
      );
      expect(messages.whereType<Encounter>().length, 2);
      connection.send(Ack(ids: [encounter.id], refs: []));
      clock.flushMicrotasks();
      expect(connection.pendingIds, isNot(contains(encounter.id)));
      expect(connection.pendingRefs, contains(encounter.keyframeRef));
      connection.send(
        Ack(ids: [reminder.logId], refs: [encounter.keyframeRef]),
      );
      clock.flushMicrotasks();
      expect(connection.pendingIds, isEmpty);
      expect(connection.pendingRefs, isEmpty);
      clock.elapse(const Duration(minutes: 1));
      expect(messages.whereType<Encounter>().length, 2);
      connection.dispose();
      clock.flushMicrotasks();
    });
  });

  test('disconnect cancels timers and reconnect redelivers pending items', () {
    fakeAsync((clock) {
      final connection = FakeGlassesConnection();
      final messages = <IncomingGlassesMessage>[];
      connection.messages.listen(messages.add);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      connection.send(time);
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 3));
      final id = messages.whereType<Encounter>().first.id;
      connection.forceDisconnected();
      clock.flushMicrotasks();
      expect(connection.state, GlassesConnectionState.disconnected);
      final count = messages.length;
      clock.elapse(const Duration(minutes: 5));
      expect(messages.length, count);
      connection.connect('RMR-0008');
      clock.flushMicrotasks();
      expect((messages.last as Hello).queue.events, 1);
      connection.send(time);
      clock.flushMicrotasks();
      expect((messages.last as Encounter).id, id);
      connection.dispose();
      clock.flushMicrotasks();
    });
  });

  test('invalid ordering and disconnected sends fail', () async {
    final connection = FakeGlassesConnection();
    addTearDown(connection.dispose);
    await expectLater(connection.send(time), throwsStateError);
    await connection.connect('RMR-0008');
    await expectLater(
      connection.send(const Ack(ids: [], refs: [])),
      throwsStateError,
    );
    await expectLater(
      connection.send(const TimeSync(utc: 'invalid', timezone: '')),
      throwsFormatException,
    );
    await connection.send(time);
    await connection.disconnect();
    await expectLater(connection.send(time), throwsStateError);
    await expectLater(connection.connect(' '), throwsArgumentError);
  });

  test(
    'release always selects BLE; development fake requires explicit opt-in',
    () {
      for (final release in [false, true]) {
        for (final requested in [false, true]) {
          final connection = createGlassesConnection(
            releaseMode: release,
            fakeRequested: requested,
          );
          expect(
            connection,
            !release && requested
                ? isA<FakeGlassesConnection>()
                : isA<BleGlassesConnection>(),
          );
          connection.dispose();
        }
      }
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(glassesConnectionProvider),
        isA<BleGlassesConnection>(),
      );
    },
  );

  test(
    'all incoming §7.1 types parse and round-trip without exposing payloads',
    () {
      final fixtures = <Map<String, dynamic>>[
        {
          'type': 'hello',
          'device_serial': 'RMR-0008',
          'firmware_version': '0.3.1',
          'protocol_version': 1,
          'queue': {'events': 0, 'audio_segments': 0, 'media': 0},
        },
        {
          'type': 'telemetry',
          'battery_pct': 76,
          'temp_c': 61,
          'memory_paused': false,
          'storage_free_mb': 2100,
        },
        {
          'type': 'encounter',
          'id': 'id',
          'person_id': null,
          'started_at': 'start',
          'ended_at': 'end',
          'best_confidence': 0.94,
          'announced': false,
          'keyframe_ref': 'ref',
          'unknown_embedding': null,
        },
        {
          'type': 'document_detected',
          'id': 'id',
          'suspected_type': 'receipt',
          'media_ref': 'ref',
          'at': 'at',
        },
        {
          'type': 'salient_frame_detected',
          'id': 'id',
          'salience_score': 0.78,
          'media_ref': 'ref',
          'at': 'at',
        },
        {
          'type': 'audio_segment',
          'id': 'id',
          'started_at': 'start',
          'ended_at': 'end',
          'codec': 'opus',
          'bytes': 18432,
          'audio_ref': 'ref',
        },
        {'type': 'memory_state', 'paused': true, 'at': 'at'},
        {
          'type': 'voice_query',
          'id': 'id',
          'intent': 'who_is_this',
          'answered_locally': true,
          'at': 'at',
        },
        {
          'type': 'assist_request',
          'id': 'id',
          'intent': 'free_form',
          'audio_ref': null,
          'at': 'at',
        },
        {
          'type': 'user_requested_recording',
          'id': 'id',
          'trigger_source': 'button',
          'duration_seconds': 12,
          'video_ref': 'ref',
          'at': 'at',
        },
        {
          'type': 'wifi_ready',
          'ssid': 'private-network',
          'psk': 'private-password',
          'host': '192.168.4.1',
        },
        {
          'type': 'reminder_state',
          'log_id': 'id',
          'status': 'completed',
          'via': 'voice',
          'snoozed_until': null,
          'at': 'at',
        },
      ];
      for (final json in fixtures) {
        final message = IncomingGlassesMessage.fromJson(json);
        expect(message.toJson(), json);
        expect(message.toString(), message.runtimeType.toString());
      }
      expect(
        () => IncomingGlassesMessage.fromJson({'type': 'invented'}),
        throwsFormatException,
      );
    },
  );

  test('outgoing messages preserve exact §7.1 shapes', () {
    expect(time.toJson(), {
      'type': 'time_sync',
      'utc': time.utc,
      'timezone': 'Africa/Cairo',
    });
    expect(const Ack(ids: ['id'], refs: ['ref']).toJson(), {
      'type': 'ack',
      'ids': ['id'],
      'refs': ['ref'],
    });
    expect(const GetReference(ref: 'ref', offset: 0).toJson(), {
      'type': 'get',
      'ref': 'ref',
      'offset': 0,
    });
    expect(
      const Speak(
        requestId: null,
        text: 'text',
        language: 'ar',
        priority: 'normal',
      ).toJson(),
      {
        'type': 'speak',
        'request_id': null,
        'text': 'text',
        'language': 'ar',
        'priority': 'normal',
      },
    );
    final sync = SyncReminders.fromJson({
      'horizon_until': 'until',
      'items': [
        {
          'log_id': 'id',
          'spoken_text': 'text',
          'type': 'medication',
          'scheduled_at': 'at',
          'status': 'pending',
          'snoozed_until': null,
        },
      ],
    });
    expect(sync.toJson()['items'], [sync.items.single.toJson()]);
    final people = SyncPeople.fromJson({
      'upserts': [
        {
          'id': 'id',
          'name': 'name',
          'relationship': 'relative',
          'embeddings': ['base64'],
        },
      ],
      'deletes': ['old'],
    });
    expect(people.toJson()['upserts'], [people.upserts.single.toJson()]);
    expect(
      const ReminderUpdate(
        logId: 'id',
        status: 'completed',
        snoozedUntil: null,
        at: 'at',
      ).toJson(),
      {
        'type': 'reminder_update',
        'log_id': 'id',
        'status': 'completed',
        'snoozed_until': null,
        'at': 'at',
      },
    );
  });
}
