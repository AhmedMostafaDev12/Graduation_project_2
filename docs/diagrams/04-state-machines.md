# 04 — State machines (spec v1)

Each lifecycle becomes a DB enum or a firmware/app state. All three tiers must agree on them.

---

## 4.1 Memory capture mode (glasses, D1 + D24)

```mermaid
stateDiagram-v2
    [*] --> Disabled: caregiver switch off
    [*] --> Capturing: caregiver switch on
    Disabled --> Capturing: caregiver enables memory_capture_enabled
    Capturing --> Paused: long press, says "stopped recording"
    Paused --> Capturing: long press, says "recording again"
    Paused --> Capturing: auto-resume after 2 h (configurable)
    Capturing --> Disabled: caregiver disables
    Paused --> Disabled: caregiver disables

    state Capturing {
        [*] --> Silence
        Silence --> Speech: VAD speech start
        Speech --> Silence: VAD speech end, segment queued
    }
```

LED: Capturing = soft glow · Paused / Disabled = off · clip recording = blinking.

---

## 4.2 Audio segment lifecycle (`audio_segments.status`)

```mermaid
stateDiagram-v2
    [*] --> OnGlasses: speech segment encoded
    OnGlasses --> OnPhone: pulled over BLE + acked
    OnGlasses --> Evicted: storage low, oldest audio
    Evicted --> [*]
    OnPhone --> Uploaded: presigned PUT + complete
    Uploaded --> Transcribing: worker picks job
    Transcribing --> Transcribed: STT ok, event written
    Transcribing --> Failed: STT error
    Failed --> Transcribing: retry, up to 3
    Failed --> Deleted: 7-day hard cap
    Transcribed --> Deleted: audio removed from S3 (D4)
    Deleted --> [*]
```

---

## 4.3 Media asset lifecycle (`media_assets`, D10 / D20)

```mermaid
stateDiagram-v2
    [*] --> OnGlasses: kept by gate or user request
    OnGlasses --> OnPhone: BLE or Wi-Fi burst, acked
    OnGlasses --> Evicted: storage low, never user_requested
    Evicted --> [*]
    OnPhone --> PendingReview: uploaded, gate-proposed
    OnPhone --> Confirmed: uploaded, user_requested
    PendingReview --> Discarded: review says discard
    PendingReview --> Confirmed: review says keep
    Discarded --> [*]: bytes deleted

    state Confirmed {
        [*] --> AutoExpire30d: contains other people
        [*] --> KeepIndefinitely: clip, document, own moment
        AutoExpire30d --> KeepIndefinitely: caregiver pins
    }

    Confirmed --> Deleted: expires_at passed or user deletes
    Deleted --> [*]
```

---

## 4.4 Face identity lifecycle (D23)

```mermaid
stateDiagram-v2
    [*] --> Open: unknown encounter clustered
    Open --> Open: seen again
    Open --> AwaitingCaregiver: seen on 3 distinct days
    AwaitingCaregiver --> Promoted: caregiver names + consents
    AwaitingCaregiver --> Dismissed: caregiver says stranger
    Open --> Dismissed: no sighting for 30 days
    Dismissed --> [*]: photos deleted
    Promoted --> Active

    [*] --> Active: caregiver enrolls manually
    Active --> Active: photos added
    Active --> Archived: caregiver removes
    Archived --> Active: restored
    Archived --> [*]: hard delete, embeddings wiped
```

---

## 4.5 Encounter (D13)

```mermaid
stateDiagram-v2
    [*] --> NoFace
    NoFace --> Tracking: face detected
    Tracking --> Identified: match above threshold
    Tracking --> UnknownTracked: no match after N frames
    Identified --> Announced: outside 10-min cooldown
    Identified --> Silent: announced recently
    Announced --> Lost: face out of frame
    Silent --> Lost: face out of frame
    UnknownTracked --> Lost: face out of frame
    Lost --> Tracking: same face within grace period
    Lost --> Closed: grace period elapsed
    Closed --> NoFace: encounter queued + keyframe
```

---

## 4.6 Assistant interaction (D2, D9, D17)

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Listening: single press, tone
    Listening --> Idle: no speech in 5 s
    Listening --> Classifying: VAD end of utterance
    Classifying --> LocalAnswer: who_is_this, time, medication_check
    Classifying --> Recording: record_this
    Classifying --> AskPhone: where_am_i or free_form
    AskPhone --> SpeakFallback: phone not connected
    AskPhone --> AwaitingPhone: assist_request sent
    AwaitingPhone --> Speaking: speak received
    AwaitingPhone --> SpeakFallback: timeout 5 s / 20 s
    LocalAnswer --> Speaking
    Recording --> Speaking: clip saved
    SpeakFallback --> Speaking
    Speaking --> Idle: TTS done

    Idle --> Speaking: reminder due on local clock (high priority)
    Speaking --> AwaitReminderReply: after a reminder
    AwaitReminderReply --> Idle: "took it" / "later" / 10 s silence
```

---

## 4.7 Reminder occurrence (`reminder_logs.status`, D6)

```mermaid
stateDiagram-v2
    [*] --> Scheduled: RRULE expanded on phone, synced to glasses (48 h)
    Scheduled --> Pending: due, phone notifies + glasses speak (each on own clock)
    Pending --> Completed: voice, app tap, or caregiver
    Pending --> Snoozed: "later"
    Snoozed --> Pending: snoozed_until reached
    Pending --> Missed: grace period (e.g. 60 min)
    Missed --> Completed: late confirmation
    Missed --> [*]: caregiver alerted
    Completed --> [*]
```

The same `log_id` lives on the phone and the glasses. If they disagree, `completed` always wins, otherwise the latest timestamp wins (spec §7.1).

---

## 4.8 Phone relay: two independent links

```mermaid
stateDiagram-v2
    state "Android relay service" as Relay {
        state "Glasses link" as BLE {
            [*] --> Disconnected
            Disconnected --> Scanning: BT on
            Scanning --> Handshake: bonded glasses found
            Handshake --> Draining: hello + time_sync + sync push
            Draining --> Connected: queues empty
            Connected --> Draining: new items announced
            Connected --> WifiBurst: wifi_ready for video
            WifiBurst --> Connected: video pulled + acked
            Connected --> Disconnected: out of range
            Draining --> Disconnected: out of range
        }
        --
        state "Cloud link" as NET {
            [*] --> Offline
            Offline --> Uploading: internet available
            Uploading --> PullingDeltas: outbox empty
            PullingDeltas --> Idle: up to date
            Idle --> Uploading: new outbox items
            Idle --> PullingDeltas: every 15 min or FCM data push
            Uploading --> Offline: connection lost
            PullingDeltas --> Offline: connection lost
            Idle --> Offline: connection lost
        }
    }
```
