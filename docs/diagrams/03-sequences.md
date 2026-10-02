# 03 — Sequence diagrams (spec v1)

Participants: **Patient** · **Caregiver** · **ESP32** · **Glasses** (Pi runtime) · **Phone** (patient's phone: Flutter app + Android relay service) · **CApp** (caregiver app, Android or iOS) · **API** (FastAPI) · **Worker** (Celery) · **DB** · **S3** · **AI** (external STT / LLM / vision / embeddings).

---

## 3.1 Caregiver onboarding + glasses pairing

```mermaid
sequenceDiagram
    autonumber
    actor CG as Caregiver
    participant Phone as Patient phone
    participant G as Glasses
    participant API
    participant DB

    CG->>Phone: Register / log in (Caregiver Mode, first setup)
    Phone->>API: POST /auth/register, then /auth/login
    API-->>Phone: JWT + refresh token
    CG->>Phone: Create patient profile + household consent
    Phone->>API: POST /patients
    API->>DB: users, patient_profiles, links, consent_records
    CG->>Phone: Scan QR on the glasses case (serial)
    Phone->>G: BLE scan + bond (LE Secure Connections)
    Phone->>API: POST /devices/pair (serial, patient_id)
    API->>DB: devices row with token_hash
    API-->>Phone: Device token + storage encryption key
    Phone->>G: Provision encryption key, time_sync
    Phone->>Phone: Switch to Patient Mode, start foreground service
    Phone->>API: GET /patients/{id}/sync?since=0
    API-->>Phone: People, embeddings, reminders, places
    Phone->>G: sync_people, sync_reminders
```

---

## 3.2 Enroll a person

```mermaid
sequenceDiagram
    autonumber
    actor CG as Caregiver
    participant CApp
    participant API
    participant DB
    participant S3
    participant Phone as Patient phone
    participant G as Glasses

    CG->>CApp: 1-5 photos + name + relationship + consent
    CApp->>API: POST /patients/{id}/people (multipart)
    loop Each photo
        API->>API: Shared face pipeline (ml/): detect, align, embed
    end
    alt Any photo has zero or several faces
        API-->>CApp: 422 with the photo index to retake
    else All valid
        API->>S3: Store reference photos
        API->>DB: enrolled_people + face_embeddings + consent_records
        API-->>CApp: 201 person
    end
    Note over Phone,G: Next time the patient phone syncs
    Phone->>API: GET /patients/{id}/sync?since=T
    API-->>Phone: New person + embeddings
    Phone->>G: sync_people (delta, float16)
    G->>G: Update encrypted people cache
```

---

## 3.3 Real-time recognition with encounters (offline, D13)

```mermaid
sequenceDiagram
    autonumber
    actor P as Patient
    participant G as Glasses
    participant Phone

    loop Every ~1 second
        G->>G: Capture frame, gate, detect, embed
        G->>G: Associate face with an open encounter or open a new one
    end
    alt New encounter, known person, outside 10-min cooldown
        G->>P: Piper TTS "ده أحمد، ابنك"
        G->>G: Mark encounter announced, keep best keyframe
    else Known person within cooldown
        G->>G: Stay silent, extend encounter
    else Unknown face
        G->>G: Never guess, keep embedding + keyframe for the encounter
    end
    Note over G: Face gone longer than the grace period, so the encounter closes
    G->>G: Queue encounter (+ unknown_embedding if unknown)
    opt Phone connected
        G->>Phone: encounter (id, person_id, times, keyframe_ref)
        Phone->>G: get keyframe_ref
        G-->>Phone: JPEG chunks on bulk characteristic
        Phone->>Phone: Save to drift outbox
        Phone->>G: ack (ids, refs)
        G->>G: Delete acked items
    end
```

---

## 3.4 Ambient memory: speech to journal transcript (D1-D4)

```mermaid
sequenceDiagram
    autonumber
    participant G as Glasses
    participant Phone
    participant API
    participant S3
    participant W as Worker
    participant AI
    participant DB

    loop All day while memory is on (LED glowing)
        G->>G: Silero VAD finds a speech segment
        G->>G: Opus encode 16 kbps, queue audio_segment
    end
    G->>Phone: audio_segment (id, times, audio_ref)
    Phone->>G: get audio_ref
    G-->>Phone: Opus bytes
    Phone->>G: ack
    Note over Phone: Queued until internet is available
    Phone->>API: POST /patients/{id}/uploads (audio, segment id)
    API-->>Phone: Presigned S3 URL
    Phone->>S3: PUT audio
    Phone->>API: POST /uploads/{id}/complete
    API->>DB: audio_segments status uploaded
    API->>W: Enqueue transcribe
    W->>S3: Fetch audio
    W->>AI: STT (auto-detect Arabic / English)
    AI-->>W: Transcript
    W->>DB: Find encounters overlapping the segment
    W->>DB: Insert conversation_segment event with transcript + present_person_ids
    W->>S3: DELETE audio (D4)
    W->>DB: audio_segments status deleted
    W->>AI: Embed rendered_text
    W->>DB: Store embedding for RAG
```

---

## 3.5 Fixed-intent question (button, offline)

```mermaid
sequenceDiagram
    autonumber
    actor P as Patient
    participant E as ESP32
    participant G as Glasses
    participant Phone

    P->>E: Single press
    E->>G: UART button=single
    G->>P: Short listening tone
    P->>G: "مين ده؟"
    G->>G: VAD end of utterance, intent classifier
    alt who_is_this
        G->>G: Fresh frame, detect, match
        G->>P: "ده أحمد، ابنك" or "مش عارف الشخص ده"
    else what_time_is_it
        G->>E: Read clock over UART
        G->>P: "الساعة عشرة الصبح، يوم الخميس"
    else medication_check
        G->>G: Look up today's synced reminder statuses
        G->>P: "خدت دوا الضغط الساعة تسعة"
    end
    G->>Phone: voice_query (intent, answered_locally) when connected
```

---

## 3.6 "Where am I?" (phone GPS + saved places, D9)

```mermaid
sequenceDiagram
    autonumber
    actor P as Patient
    participant G as Glasses
    participant Phone
    participant Geo as Reverse geocoder

    P->>G: Press, then "أنا فين؟"
    G->>G: Intent where_am_i
    alt Phone not connected
        G->>P: "مش قادر أعرف المكان دلوقتي"
    else Phone connected
        G->>Phone: assist_request (intent where_am_i)
        Phone->>Phone: Current GPS fix, nearest saved place within radius
        alt Inside a saved place
            Phone->>G: speak "إنت في البيت"
        else No saved place, internet available
            Phone->>Geo: Reverse geocode
            Geo-->>Phone: Street / area
            Phone->>G: speak "إنت في شارع الجمهورية، المنصورة"
        else No saved place, offline
            Phone->>G: speak "مش عارف المكان ده بالظبط"
        end
        G->>P: Piper TTS
    end
```

---

## 3.7 Free-form question (Phase 2 RAG)

```mermaid
sequenceDiagram
    autonumber
    actor P as Patient
    participant G as Glasses
    participant Phone
    participant API
    participant AI
    participant DB

    P->>G: Press, then "أحمد قالي إيه الصبح؟"
    G->>G: No fixed intent, so free_form
    alt Phone not connected
        G->>P: Fallback "أقدر أجاوب على أسئلة معينة بس دلوقتي"
    else Phone connected
        G->>P: Thinking tone
        G->>Phone: assist_request (free_form, audio_ref)
        Phone->>G: get audio_ref
        G-->>Phone: Opus bytes
        alt Phone offline from internet
            Phone->>G: speak fallback
        else Online
            Phone->>API: POST /patients/{id}/assist (audio)
            API->>AI: STT
            API->>API: Parse time range ("الصبح" = 06:00-12:00)
            API->>DB: Events in window, ranked by pgvector similarity
            API->>AI: LLM with events, ask for diacritized Arabic
            AI-->>API: Answer
            API->>DB: voice_query event with question + answer
            API-->>Phone: answer + source_event_ids
            Phone->>G: speak (request_id, text)
        end
        G->>P: Piper TTS, or fallback after 20 s timeout
    end
```

---

## 3.8 Reminder (D6)

```mermaid
sequenceDiagram
    autonumber
    actor CG as Caregiver
    participant CApp
    participant API
    participant Phone as Patient phone
    participant G as Glasses
    actor P as Patient

    CG->>CApp: Create "دواء الضغط" daily 09:00 (Android or iOS)
    CApp->>API: POST /patients/{id}/reminders (rrule, dtstart, timezone)
    Phone->>API: Delta sync
    API-->>Phone: New reminder
    Phone->>Phone: Expand RRULE into reminder_logs for next 48 h
    Phone->>Phone: Schedule local notifications
    Phone->>G: sync_reminders (48 h, same log_ids)
    Note over Phone,G: 09:00, both fire independently on their own clocks
    par Phone
        Phone->>P: Notification with Taken / Later + Reminders section
    and Glasses (works even if phone is away)
        G->>P: Piper TTS "ميعاد دواء الضغط"
        G->>G: Listen 10 s for a spoken reply
    end
    alt Patient says "خدته" to glasses
        G->>Phone: reminder_state completed, via voice (now or on reconnect)
        Phone->>Phone: Mark completed, cancel notification
    else Patient taps Taken on phone
        Phone->>G: reminder_update completed
        G->>G: Stop prompting
    else Patient says "بعدين" or taps Later
        G->>Phone: reminder_state snoozed (or reminder_update from the phone side)
        Note over Phone,G: Both re-fire at snoozed_until (+15 min)
    else No reply
        G->>P: Repeat once after 5 min
        Note over Phone,G: After 60 min grace, whichever side reaches it first marks missed
    end
    Note over Phone,G: Merge rule: completed always wins, otherwise latest timestamp
    Phone->>API: POST reminder-logs:batch
    opt Final state missed
        API->>CApp: Alert missed_medication via FCM
    end
```

---

## 3.9 User-requested recording (double press, Wi-Fi burst)

```mermaid
sequenceDiagram
    autonumber
    actor P as Patient
    participant E as ESP32
    participant G as Glasses
    participant Phone
    participant API
    participant S3

    alt Button
        P->>E: Double press
        E->>G: UART button=double
    else Voice
        P->>G: Press, then "سجل ده"
    end
    E->>E: LED blinking
    G->>P: "بسجل"
    G->>G: Record 12 s clip
    G->>P: "اتحفظ"
    G->>Phone: user_requested_recording (video_ref)
    G->>G: Start soft-AP
    G->>Phone: wifi_ready (ssid, psk, host)
    Phone->>G: Join via WifiNetworkSpecifier, HTTP GET video
    Phone->>G: ack
    G->>G: Stop soft-AP, delete clip
    Phone->>API: POST uploads (video), PUT to S3, complete
    API->>S3: Stored
    Note over API: user_requested: confirmed + keep_indefinitely, no review
```

---

## 3.10 Smart review + OCR for gate-proposed frames (D20)

```mermaid
sequenceDiagram
    autonumber
    participant Phone
    participant API
    participant S3
    participant W as Worker
    participant AI
    participant DB

    Phone->>API: events:batch (document_detected / salient_frame / encounter)
    API->>DB: Idempotent insert
    Phone->>API: uploads presign, PUT S3, complete
    API->>DB: media_assets pending_review
    API->>W: Enqueue review
    W->>S3: Fetch image
    W->>W: Blur faces not matching enrolled people
    W->>AI: One vision call: keep?, tags, other people?, document fields
    AI-->>W: Decision JSON
    alt Discard
        W->>S3: Delete
        W->>DB: discarded
    else Keep with other people
        W->>DB: confirmed, auto_expire, expires_at = +30 days
    else Keep, document
        W->>DB: confirmed, keep_indefinitely, captured_documents row
    else Keep, own moment
        W->>DB: confirmed, keep_indefinitely, ai_tags
    end
```

---

## 3.11 Unknown recurring face → caregiver (D23)

```mermaid
sequenceDiagram
    autonumber
    participant Phone as Patient phone
    participant API
    participant W as Worker
    participant DB
    actor CG as Caregiver
    participant CApp

    Phone->>API: events:batch with an unknown encounter + embedding
    API->>W: Enqueue clustering
    W->>DB: Nearest open cluster above similarity threshold, or new cluster
    W->>DB: Update sighting_count, distinct_days
    alt distinct_days reaches 3
        W->>DB: Cluster awaiting_caregiver + alert
        W-->>CApp: FCM "Someone new has visited 3 times"
        CG->>CApp: Review sample photos
        alt Caregiver knows them
            CG->>CApp: Name + relationship + consent
            CApp->>API: POST /unknown-faces/{id}/promote
            API->>DB: enrolled_people + face_embeddings from cluster
            Note over Phone: Next delta sync pushes the person to the glasses
        else Stranger
            CApp->>API: POST /unknown-faces/{id}/dismiss
            API->>DB: Dismissed, sample photos deleted
        end
    end
```

---

## 3.12 Nightly summary + alerts (Phase 2)

```mermaid
sequenceDiagram
    autonumber
    participant Cron as Celery Beat
    participant W as Worker
    participant DB
    participant AI
    participant CApp

    Cron->>W: Every 30 min, picks patients whose local time passed 23:30
    W->>DB: Day's encounters, transcripts, reminder_logs, games
    W->>W: Patterns: adherence %, visits, talk minutes, routine change
    W->>AI: LLM summary in caregiver language
    AI-->>W: Summary
    W->>DB: Upsert daily_summaries
    W->>DB: Alert daily_summary_ready
    W-->>CApp: FCM push
    Note over Cron,W: Other cron jobs: retention expiry hourly, device_offline from heartbeat gaps, low_battery from telemetry
```
