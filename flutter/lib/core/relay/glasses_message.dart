// Typed §7.1 messages. Never log payloads.
sealed class GlassesMessage {
  const GlassesMessage();
  Map<String, Object?> toJson();
  @override
  String toString() => runtimeType.toString();
}

sealed class IncomingGlassesMessage extends GlassesMessage {
  const IncomingGlassesMessage();
  factory IncomingGlassesMessage.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'hello' => Hello.fromJson(json),
        'telemetry' => Telemetry.fromJson(json),
        'encounter' => Encounter.fromJson(json),
        'document_detected' => DocumentDetected.fromJson(json),
        'salient_frame_detected' => SalientFrameDetected.fromJson(json),
        'audio_segment' => AudioSegment.fromJson(json),
        'memory_state' => MemoryState.fromJson(json),
        'voice_query' => VoiceQuery.fromJson(json),
        'assist_request' => AssistRequest.fromJson(json),
        'user_requested_recording' => UserRequestedRecording.fromJson(json),
        'wifi_ready' => WifiReady.fromJson(json),
        'reminder_state' => ReminderState.fromJson(json),
        _ => throw const FormatException('Unsupported glasses message type'),
      };
}

sealed class OutgoingGlassesMessage extends GlassesMessage {
  const OutgoingGlassesMessage();
}

final class Hello extends IncomingGlassesMessage {
  const Hello({
    required this.deviceSerial,
    required this.firmwareVersion,
    required this.protocolVersion,
    required this.queue,
  });
  final String deviceSerial;
  final String firmwareVersion;
  final int protocolVersion;
  final GlassesQueue queue;
  factory Hello.fromJson(Map<String, dynamic> json) => Hello(
    deviceSerial: json['device_serial'] as String,
    firmwareVersion: json['firmware_version'] as String,
    protocolVersion: json['protocol_version'] as int,
    queue: GlassesQueue.fromJson(
      Map<String, dynamic>.from(json['queue'] as Map),
    ),
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'hello',
    'device_serial': deviceSerial,
    'firmware_version': firmwareVersion,
    'protocol_version': protocolVersion,
    'queue': queue.toJson(),
  };
}

final class Telemetry extends IncomingGlassesMessage {
  const Telemetry({
    required this.batteryPct,
    required this.tempC,
    required this.memoryPaused,
    required this.storageFreeMb,
  });
  final int batteryPct;
  final num tempC;
  final bool memoryPaused;
  final int storageFreeMb;
  factory Telemetry.fromJson(Map<String, dynamic> json) => Telemetry(
    batteryPct: json['battery_pct'] as int,
    tempC: json['temp_c'] as num,
    memoryPaused: json['memory_paused'] as bool,
    storageFreeMb: json['storage_free_mb'] as int,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'telemetry',
    'battery_pct': batteryPct,
    'temp_c': tempC,
    'memory_paused': memoryPaused,
    'storage_free_mb': storageFreeMb,
  };
}

final class Encounter extends IncomingGlassesMessage {
  const Encounter({
    required this.id,
    required this.personId,
    required this.startedAt,
    required this.endedAt,
    required this.bestConfidence,
    required this.announced,
    required this.keyframeRef,
    required this.unknownEmbedding,
  });
  final String id;
  final String? personId;
  final String startedAt;
  final String endedAt;
  final num bestConfidence;
  final bool announced;
  final String keyframeRef;
  final String? unknownEmbedding;
  factory Encounter.fromJson(Map<String, dynamic> json) => Encounter(
    id: json['id'] as String,
    personId: json['person_id'] as String?,
    startedAt: json['started_at'] as String,
    endedAt: json['ended_at'] as String,
    bestConfidence: json['best_confidence'] as num,
    announced: json['announced'] as bool,
    keyframeRef: json['keyframe_ref'] as String,
    unknownEmbedding: json['unknown_embedding'] as String?,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'encounter',
    'id': id,
    'person_id': personId,
    'started_at': startedAt,
    'ended_at': endedAt,
    'best_confidence': bestConfidence,
    'announced': announced,
    'keyframe_ref': keyframeRef,
    'unknown_embedding': unknownEmbedding,
  };
}

final class DocumentDetected extends IncomingGlassesMessage {
  const DocumentDetected({
    required this.id,
    required this.suspectedType,
    required this.mediaRef,
    required this.at,
  });
  final String id;
  final String suspectedType;
  final String mediaRef;
  final String at;
  factory DocumentDetected.fromJson(Map<String, dynamic> json) =>
      DocumentDetected(
        id: json['id'] as String,
        suspectedType: json['suspected_type'] as String,
        mediaRef: json['media_ref'] as String,
        at: json['at'] as String,
      );
  @override
  Map<String, Object?> toJson() => {
    'type': 'document_detected',
    'id': id,
    'suspected_type': suspectedType,
    'media_ref': mediaRef,
    'at': at,
  };
}

final class SalientFrameDetected extends IncomingGlassesMessage {
  const SalientFrameDetected({
    required this.id,
    required this.salienceScore,
    required this.mediaRef,
    required this.at,
  });
  final String id;
  final num salienceScore;
  final String mediaRef;
  final String at;
  factory SalientFrameDetected.fromJson(Map<String, dynamic> json) =>
      SalientFrameDetected(
        id: json['id'] as String,
        salienceScore: json['salience_score'] as num,
        mediaRef: json['media_ref'] as String,
        at: json['at'] as String,
      );
  @override
  Map<String, Object?> toJson() => {
    'type': 'salient_frame_detected',
    'id': id,
    'salience_score': salienceScore,
    'media_ref': mediaRef,
    'at': at,
  };
}

final class AudioSegment extends IncomingGlassesMessage {
  const AudioSegment({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.codec,
    required this.bytes,
    required this.audioRef,
  });
  final String id;
  final String startedAt;
  final String endedAt;
  final String codec;
  final int bytes;
  final String audioRef;
  factory AudioSegment.fromJson(Map<String, dynamic> json) => AudioSegment(
    id: json['id'] as String,
    startedAt: json['started_at'] as String,
    endedAt: json['ended_at'] as String,
    codec: json['codec'] as String,
    bytes: json['bytes'] as int,
    audioRef: json['audio_ref'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'audio_segment',
    'id': id,
    'started_at': startedAt,
    'ended_at': endedAt,
    'codec': codec,
    'bytes': bytes,
    'audio_ref': audioRef,
  };
}

final class MemoryState extends IncomingGlassesMessage {
  const MemoryState({required this.paused, required this.at});
  final bool paused;
  final String at;
  factory MemoryState.fromJson(Map<String, dynamic> json) =>
      MemoryState(paused: json['paused'] as bool, at: json['at'] as String);
  @override
  Map<String, Object?> toJson() => {
    'type': 'memory_state',
    'paused': paused,
    'at': at,
  };
}

final class VoiceQuery extends IncomingGlassesMessage {
  const VoiceQuery({
    required this.id,
    required this.intent,
    required this.answeredLocally,
    required this.at,
  });
  final String id;
  final String intent;
  final bool answeredLocally;
  final String at;
  factory VoiceQuery.fromJson(Map<String, dynamic> json) => VoiceQuery(
    id: json['id'] as String,
    intent: json['intent'] as String,
    answeredLocally: json['answered_locally'] as bool,
    at: json['at'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'voice_query',
    'id': id,
    'intent': intent,
    'answered_locally': answeredLocally,
    'at': at,
  };
}

final class AssistRequest extends IncomingGlassesMessage {
  const AssistRequest({
    required this.id,
    required this.intent,
    required this.audioRef,
    required this.at,
  });
  final String id;
  final String intent;
  final String? audioRef;
  final String at;
  factory AssistRequest.fromJson(Map<String, dynamic> json) => AssistRequest(
    id: json['id'] as String,
    intent: json['intent'] as String,
    audioRef: json['audio_ref'] as String?,
    at: json['at'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'assist_request',
    'id': id,
    'intent': intent,
    'audio_ref': audioRef,
    'at': at,
  };
}

final class UserRequestedRecording extends IncomingGlassesMessage {
  const UserRequestedRecording({
    required this.id,
    required this.triggerSource,
    required this.durationSeconds,
    required this.videoRef,
    required this.at,
  });
  final String id;
  final String triggerSource;
  final int durationSeconds;
  final String videoRef;
  final String at;
  factory UserRequestedRecording.fromJson(Map<String, dynamic> json) =>
      UserRequestedRecording(
        id: json['id'] as String,
        triggerSource: json['trigger_source'] as String,
        durationSeconds: json['duration_seconds'] as int,
        videoRef: json['video_ref'] as String,
        at: json['at'] as String,
      );
  @override
  Map<String, Object?> toJson() => {
    'type': 'user_requested_recording',
    'id': id,
    'trigger_source': triggerSource,
    'duration_seconds': durationSeconds,
    'video_ref': videoRef,
    'at': at,
  };
}

final class WifiReady extends IncomingGlassesMessage {
  const WifiReady({required this.ssid, required this.psk, required this.host});
  final String ssid;
  final String psk;
  final String host;
  factory WifiReady.fromJson(Map<String, dynamic> json) => WifiReady(
    ssid: json['ssid'] as String,
    psk: json['psk'] as String,
    host: json['host'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'wifi_ready',
    'ssid': ssid,
    'psk': psk,
    'host': host,
  };
}

final class ReminderState extends IncomingGlassesMessage {
  const ReminderState({
    required this.logId,
    required this.status,
    required this.via,
    required this.snoozedUntil,
    required this.at,
  });
  final String logId;
  final String status;
  final String? via;
  final String? snoozedUntil;
  final String at;
  factory ReminderState.fromJson(Map<String, dynamic> json) => ReminderState(
    logId: json['log_id'] as String,
    status: json['status'] as String,
    via: json['via'] as String?,
    snoozedUntil: json['snoozed_until'] as String?,
    at: json['at'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'reminder_state',
    'log_id': logId,
    'status': status,
    'via': via,
    'snoozed_until': snoozedUntil,
    'at': at,
  };
}

final class TimeSync extends OutgoingGlassesMessage {
  const TimeSync({required this.utc, required this.timezone});
  final String utc;
  final String timezone;
  factory TimeSync.fromJson(Map<String, dynamic> json) => TimeSync(
    utc: json['utc'] as String,
    timezone: json['timezone'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'time_sync',
    'utc': utc,
    'timezone': timezone,
  };
}

final class Speak extends OutgoingGlassesMessage {
  const Speak({
    required this.requestId,
    required this.text,
    required this.language,
    required this.priority,
  });
  final String? requestId;
  final String text;
  final String language;
  final String priority;
  factory Speak.fromJson(Map<String, dynamic> json) => Speak(
    requestId: json['request_id'] as String?,
    text: json['text'] as String,
    language: json['language'] as String,
    priority: json['priority'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'speak',
    'request_id': requestId,
    'text': text,
    'language': language,
    'priority': priority,
  };
}

final class SyncReminders extends OutgoingGlassesMessage {
  const SyncReminders({required this.horizonUntil, required this.items});
  final String horizonUntil;
  final List<GlassesReminder> items;
  factory SyncReminders.fromJson(Map<String, dynamic> json) => SyncReminders(
    horizonUntil: json['horizon_until'] as String,
    items: (json['items'] as List)
        .map(
          (item) =>
              GlassesReminder.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'sync_reminders',
    'horizon_until': horizonUntil,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

final class ReminderUpdate extends OutgoingGlassesMessage {
  const ReminderUpdate({
    required this.logId,
    required this.status,
    required this.snoozedUntil,
    required this.at,
  });
  final String logId;
  final String status;
  final String? snoozedUntil;
  final String at;
  factory ReminderUpdate.fromJson(Map<String, dynamic> json) => ReminderUpdate(
    logId: json['log_id'] as String,
    status: json['status'] as String,
    snoozedUntil: json['snoozed_until'] as String?,
    at: json['at'] as String,
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'reminder_update',
    'log_id': logId,
    'status': status,
    'snoozed_until': snoozedUntil,
    'at': at,
  };
}

final class SyncPeople extends OutgoingGlassesMessage {
  const SyncPeople({required this.upserts, required this.deletes});
  final List<GlassesPerson> upserts;
  final List<String> deletes;
  factory SyncPeople.fromJson(Map<String, dynamic> json) => SyncPeople(
    upserts: (json['upserts'] as List)
        .map(
          (item) =>
              GlassesPerson.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    deletes: (json['deletes'] as List).cast<String>(),
  );
  @override
  Map<String, Object?> toJson() => {
    'type': 'sync_people',
    'upserts': upserts.map((item) => item.toJson()).toList(),
    'deletes': deletes,
  };
}

final class GetReference extends OutgoingGlassesMessage {
  const GetReference({required this.ref, required this.offset});
  final String ref;
  final int offset;
  factory GetReference.fromJson(Map<String, dynamic> json) =>
      GetReference(ref: json['ref'] as String, offset: json['offset'] as int);
  @override
  Map<String, Object?> toJson() => {
    'type': 'get',
    'ref': ref,
    'offset': offset,
  };
}

final class Ack extends OutgoingGlassesMessage {
  const Ack({required this.ids, required this.refs});
  final List<String> ids;
  final List<String> refs;
  factory Ack.fromJson(Map<String, dynamic> json) => Ack(
    ids: (json['ids'] as List).cast<String>(),
    refs: (json['refs'] as List).cast<String>(),
  );
  @override
  Map<String, Object?> toJson() => {'type': 'ack', 'ids': ids, 'refs': refs};
}

final class GlassesQueue {
  const GlassesQueue({
    required this.events,
    required this.audioSegments,
    required this.media,
  });
  final int events;
  final int audioSegments;
  final int media;
  factory GlassesQueue.fromJson(Map<String, dynamic> json) => GlassesQueue(
    events: json['events'] as int,
    audioSegments: json['audio_segments'] as int,
    media: json['media'] as int,
  );
  Map<String, Object?> toJson() => {
    'events': events,
    'audio_segments': audioSegments,
    'media': media,
  };
  @override
  String toString() => 'GlassesQueue';
}

final class GlassesReminder {
  const GlassesReminder({
    required this.logId,
    required this.spokenText,
    required this.type,
    required this.scheduledAt,
    required this.status,
    required this.snoozedUntil,
  });
  final String logId;
  final String spokenText;
  final String type;
  final String scheduledAt;
  final String status;
  final String? snoozedUntil;
  factory GlassesReminder.fromJson(Map<String, dynamic> json) =>
      GlassesReminder(
        logId: json['log_id'] as String,
        spokenText: json['spoken_text'] as String,
        type: json['type'] as String,
        scheduledAt: json['scheduled_at'] as String,
        status: json['status'] as String,
        snoozedUntil: json['snoozed_until'] as String?,
      );
  Map<String, Object?> toJson() => {
    'log_id': logId,
    'spoken_text': spokenText,
    'type': type,
    'scheduled_at': scheduledAt,
    'status': status,
    'snoozed_until': snoozedUntil,
  };
  @override
  String toString() => 'GlassesReminder';
}

final class GlassesPerson {
  const GlassesPerson({
    required this.id,
    required this.name,
    required this.relationship,
    required this.embeddings,
  });
  final String id;
  final String name;
  final String relationship;
  final List<String> embeddings;
  factory GlassesPerson.fromJson(Map<String, dynamic> json) => GlassesPerson(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: json['relationship'] as String,
    embeddings: (json['embeddings'] as List).cast<String>(),
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'embeddings': embeddings,
  };
  @override
  String toString() => 'GlassesPerson';
}
