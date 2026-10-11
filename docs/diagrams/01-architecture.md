# 01 — Architecture (spec v1)

Decision references `D#` point to the decision log in [`REMORI_SPEC.md`](../../REMORI_SPEC.md) §0. Dashed lines = optional, stretch, or fallback paths.

---

## 1.1 System context

```mermaid
flowchart TB
    patient(["👤 Patient"])
    caregiver(["👤 Caregiver"])
    household(["👥 Family / visitors"])

    subgraph remori["Remori system"]
        glasses["Smart glasses"]
        papp["Patient's phone<br/>Patient Mode + relay (Android)"]
        capp["Caregiver app<br/>Caregiver Mode (Android / iOS)"]
        cloud["Remori cloud backend"]
    end

    stt["Speech-to-text API<br/>(Whisper-large-v3 class)"]
    llm["LLM API<br/>(RAG, summaries)"]
    vision["Vision model API<br/>(review + OCR)"]
    emb["Embeddings API"]
    fcm["Firebase Cloud Messaging"]
    geo["Reverse geocoding<br/>(optional fallback)"]

    patient -->|"button, voice"| glasses
    glasses -->|"spoken names, answers, reminders"| patient
    household -.->|"seen + heard, with household consent"| glasses
    patient -->|"today, reminders, recall, games"| papp
    caregiver -->|"enroll, reminders, places, monitor"| capp
    glasses <-->|"BLE + Wi-Fi burst"| papp
    papp <-->|"HTTPS"| cloud
    capp <-->|"HTTPS"| cloud
    cloud --> stt
    cloud --> llm
    cloud --> vision
    cloud --> emb
    cloud --> fcm
    fcm --> capp
    papp -.-> geo
```

---

## 1.2 Three-tier container view

```mermaid
flowchart LR
    subgraph G["Tier 1 · Glasses (never needs network)"]
        direction TB
        cam["OV5647 camera ~1 fps"]
        mic["I2S mic 16 kHz"]
        spk["I2S amp + speaker"]
        pi["Raspberry Pi Zero 2W<br/>vision + audio + BLE/Wi-Fi"]
        esp["ESP32-S3<br/>button · LED · battery · clock · power"]
        gdb[("Encrypted local store<br/>people cache · queue · media · audio")]
        cam --> pi
        mic --> pi
        pi --> spk
        esp <-->|"UART"| pi
        pi <--> gdb
    end

    subgraph P["Tier 2 · Patient phone (Android relay)"]
        direction TB
        fgs["Foreground service<br/>BLE link · uploader · reminder sync · GPS"]
        ui["Patient UI"]
        sync["Sync engine<br/>outbox up · delta pull down"]
        sql[("drift / SQLite")]
        fgs <--> sql
        ui <--> sql
        sql <--> sync
    end

    subgraph C["Tier 3 · Cloud"]
        direction TB
        api["FastAPI /api/v1"]
        worker["Celery worker"]
        beat["Celery Beat (cron)"]
        redis[("Redis broker")]
        pg[("PostgreSQL + pgvector<br/>Supabase")]
        s3[("S3 private")]
        api <--> pg
        api --> redis
        beat --> redis
        redis --> worker
        worker <--> pg
        worker <--> s3
    end

    capp["Caregiver app<br/>Android / iOS"]
    ext["External AI APIs<br/>STT · LLM · vision · embeddings"]

    pi <-->|"BLE: control + keyframes + Opus audio"| fgs
    pi -.->|"Wi-Fi burst: video"| fgs
    sync <-->|"HTTPS · device token"| api
    sync -.->|"presigned upload"| s3
    capp <-->|"HTTPS · JWT"| api
    worker --> ext
    api --> ext
```

### Degradation

```mermaid
flowchart LR
    a["Glasses alone"] -->|"+ phone"| b["Glasses + phone offline"]
    b -->|"+ internet"| c["Fully online"]
    a -.- a1["Recognition + announcements<br/>reminders spoken from synced schedule<br/>who_is_this · time · medication_check<br/>recording · everything queued"]
    b -.- b1["+ phone notifications<br/>+ where_am_i (GPS)<br/>+ local journal"]
    c -.- c1["+ transcripts · free-form answers<br/>+ smart review · summaries · alerts"]
```

---

## 1.3 Glasses hardware block diagram (D7)

```mermaid
flowchart LR
    bat["Li-Po battery"] --> pm["Charger / power-path board"]
    pm --> esp
    pm -->|"switched by ESP32"| pi

    subgraph PIBOX["Raspberry Pi Zero 2W"]
        pi["Quad Cortex-A53 · 512 MB<br/>BLE 4.2 + Wi-Fi 2.4 GHz"]
        sd[("microSD, encrypted")]
        pi --- sd
    end

    subgraph ESPBOX["ESP32-S3 N16R8 (power / IO controller)"]
        esp["MCU · keeps time · battery gauge"]
    end

    cam["OV5647 5 MP"] -->|"CSI"| pi
    mic["INMP441 I2S mic"] -->|"I2S"| pi
    pi -->|"I2S"| amp["MAX98357A amp"]
    amp --> spk["Speaker / bone conduction"]
    btn["Button<br/>press · double · long"] -->|"GPIO"| esp
    led["Status LED<br/>capturing · paused · recording"] ---|"GPIO"| esp
    pi <-->|"UART: buttons, battery, time, LED, power"| esp
    oled["OLED + combiner<br/>AR stretch goal"] -.->|"SPI / I2C"| pi

    phone["📱 Patient phone (Android)"]
    pi <-->|"BLE GATT"| phone
    pi -.->|"Wi-Fi soft-AP burst"| phone
```

---

## 1.4 Glasses software modules (`hardware/pi`, `hardware/esp32`)

```mermaid
flowchart TB
    subgraph ESP["ESP32 firmware"]
        btn["button gestures"]
        clk["clock"]
        bat["battery gauge"]
        led["LED driver"]
    end

    subgraph RT["Pi runtime"]
        uart["uart bridge"]
        cap["capture · ~1 fps"]
        gate["capture gate<br/>face · document · novelty"]
        fd["face detector"]
        emb["MobileFaceNet w600k_mbf"]
        enc["encounter tracker<br/>announce once + cooldown"]
        vad["Silero VAD"]
        mem["memory segmenter<br/>Opus encode"]
        ptt["push-to-talk buffer"]
        intent["intent classifier"]
        rec["clip recorder"]
        tts["Piper TTS"]
        remr["reminder runner<br/>fires from ESP32 clock"]
        store[("encrypted store<br/>people · queue · media · audio")]
        link["link manager<br/>BLE GATT + Wi-Fi burst"]
    end

    btn --> uart
    clk --> uart
    bat --> uart
    uart --> led
    uart -->|"single press"| ptt
    uart -->|"double press"| rec
    uart -->|"long press: pause/resume"| mem

    cap --> gate
    gate -->|"face"| fd
    fd --> emb
    emb --> enc
    enc -->|"new encounter"| tts
    enc -->|"encounter + keyframe"| store
    gate -->|"document / novel frame"| store

    vad -->|"speech, memory on"| mem
    mem --> store
    vad -->|"speech after press"| ptt
    ptt --> intent
    intent -->|"who_is_this"| enc
    intent -->|"time · medication_check"| tts
    intent -->|"record_this"| rec
    intent -->|"where_am_i · free_form"| link
    rec --> store

    store <--> link
    store -->|"48 h schedule"| remr
    clk -->|"time"| remr
    remr -->|"speak reminder"| tts
    remr -->|"reminder_state"| link
    link -->|"speak"| tts
    link -->|"sync_people · sync_reminders · reminder_update"| store
```

---

## 1.5 Backend component view (`backend-ai/`)

```mermaid
flowchart LR
    papp["Patient phone"] --> mw
    capp["Caregiver app"] --> mw

    subgraph API["FastAPI"]
        mw["Auth: JWT · device token<br/>patient-link authorization"]
        r_auth["auth · patients · caregivers"]
        r_dev["devices: pair · heartbeat"]
        r_sync["sync: delta pull"]
        r_people["people · unknown-faces"]
        r_events["events:batch"]
        r_up["uploads: presign · complete"]
        r_media["media · documents"]
        r_journal["journal · assist (RAG)"]
        r_rem["reminders · reminder-logs"]
        r_places["places"]
        r_misc["alerts · push-token · mind games · summaries"]
        mw --> r_auth
        mw --> r_dev
        mw --> r_sync
        mw --> r_people
        mw --> r_events
        mw --> r_up
        mw --> r_media
        mw --> r_journal
        mw --> r_rem
        mw --> r_places
        mw --> r_misc
    end

    subgraph SVC["Shared services"]
        face["face pipeline (ml/)"]
        rag["RAG: time filter + vector"]
        stor["S3 presigned URLs"]
        audit["audit log"]
    end

    subgraph WK["Celery worker"]
        subgraph Q_AI["queue ai_io · threads"]
            j_stt["transcribe audio + delete"]
            j_embed["render + embed events"]
            j_review["review + OCR (one call)"]
            j_sum["daily summary"]
        end
        subgraph Q_CPU["queue cpu · prefork"]
            j_cluster["unknown-face clustering"]
        end
        subgraph Q_DEF["queue default"]
            j_ret["retention expiry"]
            j_alert["alert rules"]
        end
    end

    beat["Celery Beat<br/>hourly · 5 min · 30 min"]
    flower["Flower<br/>monitoring"]

    pg[("PostgreSQL + pgvector<br/>Supabase")]
    s3[("S3")]
    redis[("Redis")]
    ext["AI APIs"]
    fcm["FCM"]

    r_people --> face
    r_journal --> rag
    r_up --> stor
    r_media --> audit
    r_up -->|"enqueue"| redis
    r_events -->|"enqueue"| redis
    beat -->|"schedule"| redis
    redis --> WK
    flower -.-> redis
    API --> pg
    WK --> pg
    stor --> s3
    WK --> s3
    rag --> ext
    j_stt --> ext
    j_embed --> ext
    j_review --> ext
    j_sum --> ext
    j_alert --> fcm
```

---

## 1.6 Deployment (D5, D25)

```mermaid
flowchart TB
    subgraph USR["User side"]
        glasses["Glasses"]
        pphone["Patient phone<br/>Android relay"]
        cphone["Caregiver phone<br/>Android / iOS"]
    end

    subgraph AWS["AWS"]
        ec2["EC2 small instance<br/>Docker Compose: FastAPI · Celery worker · Beat · Flower · Redis"]
        s3[("S3 private bucket")]
    end

    subgraph SB["Supabase (EU region, D25)"]
        db[("PostgreSQL 16 + pgvector<br/>plain Postgres only<br/>Data API off · RLS on")]
    end

    dev["Team: Supabase dashboard / pgAdmin<br/>(remori_readonly)"]

    subgraph AI["Managed AI APIs"]
        whisper["STT"]
        llm["LLM"]
        vlm["Vision"]
        emb["Embeddings"]
    end

    fcm["Firebase Cloud Messaging"]

    glasses <-->|"BLE / Wi-Fi"| pphone
    pphone <-->|"HTTPS"| ec2
    cphone <-->|"HTTPS"| ec2
    pphone -.->|"presigned PUT"| s3
    cphone -.->|"signed GET"| s3
    ec2 -->|"SSL · remori_app"| db
    dev -.-> db
    ec2 --> s3
    ec2 --> whisper
    ec2 --> llm
    ec2 --> vlm
    ec2 --> emb
    ec2 --> fcm
    fcm --> cphone
```

---

## 1.7 Flutter app navigation (GoRouter)

```mermaid
flowchart TB
    entry["App entry"]
    cg_login["Caregiver login / register"]
    pt_auto["Patient auto-login<br/>device token"]

    entry --> cg_login
    entry --> pt_auto
    cg_login --> CG
    pt_auto --> PT

    subgraph CG["Caregiver shell"]
        cg_dash["Dashboard + alerts"]
        cg_people["People"]
        cg_review["Unknown-face review"]
        cg_rem["Reminders"]
        cg_places["Saved places"]
        cg_dev["Device: pairing, status, memory switch"]
        cg_log["Activity log + media + transcripts"]
        cg_docs["Documents"]
        cg_sum["AI summaries · P2"]
    end

    subgraph PT["Patient shell (Arabic-first, large type)"]
        pt_today["Today"]
        pt_rem["Reminders"]
        pt_journal["Journal recall"]
        pt_ask["Ask · P2"]
        pt_games["Mind games"]
    end
```

## 1.8 Flutter app layers (Riverpod, offline-first, cross-platform, D8)

Everything above the `RelayService` interface is shared Dart code running on Android and iOS. Only the relay has platform implementations.

```mermaid
flowchart TB
    subgraph SHARED["Shared Flutter code · Android + iOS"]
        ui["Presentation<br/>screens · widgets · ThemeData · RTL"]
        prov["Riverpod providers"]
        domain["Domain: entities · use cases"]
        repo["Repositories"]
        local[("drift<br/>UI reads only from here")]
        remote["ApiClient (dio)"]
        syncEng["Sync engine<br/>outbox + delta pull"]
        rem["Reminder planner<br/>RRULE to 48 h of logs<br/>+ local notifications"]
        fcmc["FCM client"]
        relay{{"RelayService interface"}}
    end

    subgraph ANDROID["Android relay (supported)"]
        fgs["Foreground service"]
        ble_a["BLE link + transfer"]
        wifi_a["Wi-Fi burst<br/>WifiNetworkSpecifier"]
        gps_a["GPS + place matcher"]
    end

    subgraph IOS["iOS relay (stretch goal)"]
        ble_i["BLE background mode<br/>+ state restoration"]
        wifi_i["NEHotspotConfiguration"]
        gps_i["Always location"]
    end

    ui --> prov
    prov --> domain
    domain --> repo
    repo --> local
    repo --> remote
    syncEng --> local
    syncEng --> remote
    rem --> local
    rem --> relay
    fcmc --> syncEng
    relay --> fgs
    fgs --> ble_a
    fgs --> wifi_a
    fgs --> gps_a
    relay -.-> ble_i
    relay -.-> wifi_i
    relay -.-> gps_i
    ble_a --> local
```
