# 02 — Database ERD (spec v1, §6)

This is the target for the first Alembic migration. The original v0 model and its problems are recorded in [`SPEC_REVIEW.md`](../SPEC_REVIEW.md).
Mermaid can't express `VECTOR(n)` or enum values as types, so they appear as `vector512` etc., with enum values in the comment.

To keep it readable, the ERD is split into three views that share the `USERS` entity.

---

## 2.1 Accounts, devices, people, privacy

```mermaid
erDiagram
    USERS {
        uuid id PK
        enum role "patient | caregiver"
        text full_name
        text email UK "nullable"
        text phone
        text password_hash "nullable"
        timestamptz updated_at
        timestamptz deleted_at
    }
    PATIENT_PROFILES {
        uuid user_id PK, FK
        enum preferred_language "ar | en"
        text timezone "Africa/Cairo"
        date date_of_birth "nullable"
        bool memory_capture_enabled "caregiver master switch"
    }
    CAREGIVER_PATIENT_LINKS {
        uuid id PK
        uuid caregiver_id FK "UNIQUE with patient_id"
        uuid patient_id FK
        text relationship
        bool is_primary
        enum permission "viewer | manager"
    }
    REFRESH_TOKENS {
        uuid id PK
        uuid user_id FK
        text token_hash
        timestamptz expires_at
        timestamptz revoked_at
    }
    PUSH_TOKENS {
        uuid id PK
        uuid user_id FK
        text fcm_token
    }
    DEVICES {
        uuid id PK
        uuid patient_id FK
        text serial_number UK
        text token_hash
        text firmware_version
        int battery_level_pct
        timestamptz last_seen_at
        timestamptz paired_at
    }
    ENROLLED_PEOPLE {
        uuid id PK
        uuid patient_id FK
        text name
        text relationship
        enum added_by "caregiver_manual | promoted_from_unknown"
        uuid consent_record_id FK
        enum status "active | archived"
    }
    FACE_EMBEDDINGS {
        uuid id PK
        uuid person_id FK
        vector512 embedding
        text model_version "w600k_mbf@1.0"
        uuid source_media_id FK "nullable"
    }
    UNKNOWN_FACE_CLUSTERS {
        uuid id PK
        uuid patient_id FK
        vector512 centroid
        int sighting_count
        int distinct_days
        uuid sample_media_id FK
        enum status "open | awaiting_caregiver | promoted | dismissed"
        uuid promoted_person_id FK "nullable"
    }
    PLACES {
        uuid id PK
        uuid patient_id FK
        text name "Home"
        float latitude
        float longitude
        int radius_m
        uuid created_by FK
    }
    CONSENT_RECORDS {
        uuid id PK
        uuid patient_id FK
        uuid subject_person_id FK "nullable"
        enum consent_type "face_enrollment | ambient_audio_household | cloud_processing | media_retention"
        uuid given_by FK
        timestamptz given_at
        timestamptz revoked_at
    }
    AUDIT_LOG {
        uuid id PK
        uuid actor_user_id FK
        text action
        text entity_type
        uuid entity_id
        timestamptz at
    }

    USERS ||--o| PATIENT_PROFILES : "profile"
    USERS ||--o{ CAREGIVER_PATIENT_LINKS : "as caregiver"
    USERS ||--o{ CAREGIVER_PATIENT_LINKS : "as patient"
    AUTH_IDENTITIES {
        uuid id PK
        uuid user_id FK
        enum provider "google | facebook"
        text provider_subject "UNIQUE with provider"
        text email "nullable"
        bool email_verified
        timestamptz last_used_at "nullable"
    }
    USERS ||--o{ AUTH_IDENTITIES : "signs in with (D26)"
    USERS ||--o{ REFRESH_TOKENS : "sessions"
    USERS ||--o{ PUSH_TOKENS : "notified on"
    USERS ||--o{ DEVICES : "wears"
    USERS ||--o{ ENROLLED_PEOPLE : "knows"
    ENROLLED_PEOPLE ||--|{ FACE_EMBEDDINGS : "has"
    USERS ||--o{ UNKNOWN_FACE_CLUSTERS : "saw"
    UNKNOWN_FACE_CLUSTERS |o--o| ENROLLED_PEOPLE : "promoted to"
    USERS ||--o{ PLACES : "saved"
    USERS ||--o{ CONSENT_RECORDS : "gives"
    CONSENT_RECORDS |o--o| ENROLLED_PEOPLE : "covers"
    USERS ||--o{ AUDIT_LOG : "acted"
```

---

## 2.2 Journal, encounters, audio, media

```mermaid
erDiagram
    USERS {
        uuid id PK
    }
    DEVICES {
        uuid id PK
    }
    ENROLLED_PEOPLE {
        uuid id PK
    }
    UNKNOWN_FACE_CLUSTERS {
        uuid id PK
    }
    ENCOUNTERS {
        uuid id PK "generated on glasses"
        uuid patient_id FK
        uuid device_id FK
        uuid person_id FK "nullable"
        uuid cluster_id FK "nullable, unknown"
        timestamptz started_at
        timestamptz ended_at
        float best_confidence
        bool announced
    }
    EVENTS {
        uuid id PK "client-generated, idempotent"
        uuid patient_id FK
        uuid device_id FK "nullable"
        enum source "glasses | app | server"
        enum event_type "encounter | conversation_segment | voice_query | reminder | ..."
        uuid encounter_id FK "nullable"
        uuid person_id FK "nullable"
        uuid reminder_log_id FK "nullable"
        uuid mind_game_session_id FK "nullable"
        timestamptz occurred_at
        timestamptz ended_at "nullable"
        text transcript_text "nullable"
        enum language "ar | en | mixed"
        text rendered_text "for RAG"
        vector1536 embedding "nullable"
        jsonb metadata "present_person_ids, place_id"
    }
    AUDIO_SEGMENTS {
        uuid id PK "generated on glasses"
        uuid patient_id FK
        uuid device_id FK
        timestamptz started_at
        timestamptz ended_at
        text storage_key "NULL once deleted"
        enum status "uploaded | transcribing | transcribed | failed | deleted"
        uuid event_id FK "resulting transcript"
        int attempts
    }
    MEDIA_ASSETS {
        uuid id PK
        uuid patient_id FK
        uuid event_id FK
        enum asset_type "image | video"
        text storage_key "private S3"
        enum trigger "encounter_keyframe | document_signal | salient_frame | user_requested"
        enum status "pending_review | confirmed | discarded"
        jsonb ai_tags
        bool contains_other_people
        enum retention_policy "auto_expire | keep_indefinitely"
        timestamptz expires_at
        uuid pinned_by FK "nullable"
    }
    CAPTURED_DOCUMENTS {
        uuid id PK
        uuid event_id FK
        uuid media_asset_id FK
        enum document_type "receipt | bill | medication_label | other"
        text ocr_text
        jsonb extracted_fields
    }

    USERS ||--o{ ENCOUNTERS : "met"
    DEVICES ||--o{ ENCOUNTERS : "observed"
    ENROLLED_PEOPLE |o--o{ ENCOUNTERS : "known person"
    UNKNOWN_FACE_CLUSTERS |o--o{ ENCOUNTERS : "unknown person"
    USERS ||--o{ EVENTS : "journal of"
    DEVICES |o--o{ EVENTS : "produced"
    ENCOUNTERS |o--o{ EVENTS : "logged as"
    ENROLLED_PEOPLE |o--o{ EVENTS : "about"
    USERS ||--o{ AUDIO_SEGMENTS : "spoken near"
    AUDIO_SEGMENTS |o--o| EVENTS : "transcribed into"
    EVENTS ||--o{ MEDIA_ASSETS : "has media"
    EVENTS ||--o| CAPTURED_DOCUMENTS : "OCR result"
    MEDIA_ASSETS ||--o| CAPTURED_DOCUMENTS : "scanned from"
```

---

## 2.3 Reminders, activity, insights

```mermaid
erDiagram
    USERS {
        uuid id PK
    }
    EVENTS {
        uuid id PK
        uuid reminder_log_id FK
        uuid mind_game_session_id FK
    }
    REMINDERS {
        uuid id PK
        uuid patient_id FK
        text title
        text spoken_text "nullable"
        enum type "medication | appointment | task"
        text rrule
        timestamptz dtstart
        text timezone
        bool active
        uuid created_by FK
    }
    REMINDER_LOGS {
        uuid id PK "generated on phone"
        uuid reminder_id FK
        timestamptz scheduled_at
        enum status "pending | completed | snoozed | missed"
        timestamptz snoozed_until
        timestamptz completed_at
        enum confirmed_via "voice | app | caregiver"
    }
    MIND_GAME_SESSIONS {
        uuid id PK
        uuid patient_id FK
        text game_type
        int score
        int duration_seconds
        timestamptz completed_at
    }
    DAILY_SUMMARIES {
        uuid id PK
        uuid patient_id FK "UNIQUE with summary_date"
        date summary_date
        text summary_text
        jsonb patterns
    }
    CAREGIVER_ALERTS {
        uuid id PK
        uuid caregiver_id FK
        uuid patient_id FK
        enum alert_type "missed_medication | unknown_person_flagged | low_battery | device_offline | daily_summary_ready"
        text message
        timestamptz read_at
    }

    USERS ||--o{ REMINDERS : "has"
    USERS ||--o{ REMINDERS : "created"
    REMINDERS ||--o{ REMINDER_LOGS : "occurrences"
    REMINDER_LOGS |o--o{ EVENTS : "logged as"
    USERS ||--o{ MIND_GAME_SESSIONS : "plays"
    MIND_GAME_SESSIONS |o--o{ EVENTS : "logged as"
    USERS ||--o{ DAILY_SUMMARIES : "summarized"
    USERS ||--o{ CAREGIVER_ALERTS : "receives"
```

---

## 2.4 Where each table lives

| Table | Postgres | Phone (drift) | Glasses |
|---|---|---|---|
| users, profiles, links, devices | ✅ truth | own records | – |
| enrolled_people + face_embeddings | ✅ truth | cache | cache |
| unknown_face_clusters | ✅ | cache (caregiver) | – |
| encounters, events | ✅ | outbox + cache | queue until ack |
| audio_segments | until transcribed | queue | queue until ack |
| media_assets | metadata, bytes in S3 | pending uploads | bytes until ack |
| reminders, reminder_logs | ✅ | ✅ scheduler | today's schedule |
| places | ✅ | ✅ GPS matcher | – |
| mind_game_sessions | ✅ | outbox | – |
| summaries, alerts | ✅ | cache | – |
| consent_records, audit_log, tokens | ✅ only | – | – |
