# 05 — Pipelines, use cases, build plan (spec v1)

---

## 5.1 Use cases by actor

```mermaid
flowchart LR
    patient(["👤 Patient"])
    caregiver(["👤 Caregiver"])
    system(["⚙ Cloud jobs"])

    subgraph UC["Remori use cases"]
        uc1(["Hear who is in front of me"])
        uc2(["Have my day remembered"])
        uc3(["Pause / resume memory"])
        uc4(["Ask who / time / medication / where"])
        uc5(["Ask anything about my day · P2"])
        uc6(["Record a moment"])
        uc7(["Get + confirm reminders"])
        uc8(["Recall my day in the app"])
        uc9(["Play mind games"])
        uc10(["Set up patient + pair glasses"])
        uc11(["Enroll / edit people"])
        uc12(["Review unknown faces"])
        uc13(["Manage reminders + places"])
        uc14(["Monitor device + alerts"])
        uc15(["View journal, media, documents"])
        uc16(["Read AI summaries · P2"])
        uc17(["Transcribe speech, delete audio"])
        uc18(["Review media + OCR"])
        uc19(["Cluster unknown faces"])
        uc20(["Expire media · summaries · alerts"])
    end

    patient --> uc1
    patient --> uc2
    patient --> uc3
    patient --> uc4
    patient --> uc5
    patient --> uc6
    patient --> uc7
    patient --> uc8
    patient --> uc9
    caregiver --> uc10
    caregiver --> uc11
    caregiver --> uc12
    caregiver --> uc13
    caregiver --> uc14
    caregiver --> uc15
    caregiver --> uc16
    system --> uc17
    system --> uc18
    system --> uc19
    system --> uc20
```

---

## 5.2 On-device vision pipeline

```mermaid
flowchart TB
    start(["Frame every ~1 s"]) --> gate{"Capture gate (heuristics v1)<br/>face? text-dense? novel scene?"}
    gate -->|"nothing"| drop["Discard immediately"]
    gate -->|"face"| det["Ultra-Light face detector"]
    gate -->|"document"| doc["Queue frame<br/>document_detected"]
    gate -->|"novel"| sal["Queue frame<br/>salient_frame_detected"]

    det --> align["Align + crop 112x112"]
    align --> emb["MobileFaceNet w600k_mbf INT8"]
    emb --> trk{"Belongs to an<br/>open encounter?"}
    trk -->|"yes"| extend["Extend encounter<br/>update best keyframe"]
    trk -->|"no"| match{"Cosine similarity vs all<br/>embeddings above threshold?"}
    match -->|"yes"| cool{"Announced this person<br/>in last 10 min?"}
    cool -->|"no"| say["Piper: name + relationship"]
    cool -->|"yes"| quiet["Silent"]
    match -->|"no"| unk["Unknown encounter<br/>never guess"]

    say --> open["Open encounter"]
    quiet --> open
    unk --> open
    open --> close["On close: queue encounter + keyframe"]
    close --> q[("Encrypted queue")]
    doc --> q
    sal --> q
```

---

## 5.3 On-device audio pipeline: two paths from one mic

```mermaid
flowchart TB
    mic(["I2S mic 16 kHz"]) --> vad{"Silero VAD<br/>speech?"}
    vad -->|"no"| mic
    vad -->|"yes"| who{"Button pressed<br/>just before?"}

    who -->|"no"| mode{"Memory capture on?"}
    mode -->|"paused / disabled"| nothing["Not stored"]
    mode -->|"on"| seg["Segment until silence<br/>Opus 16 kbps"]
    seg --> aq[("Queue audio_segment<br/>to phone, cloud STT, then deleted")]

    who -->|"yes"| intent{"Intent classifier"}
    intent -->|"who_is_this"| a1["Fresh frame + match"]
    intent -->|"what_time_is_it"| a2["ESP32 clock"]
    intent -->|"medication_check"| a3["Today's reminder statuses"]
    intent -->|"record_this"| a4["Record clip"]
    intent -->|"where_am_i"| a5["assist_request to phone"]
    intent -->|"free_form"| a6["assist_request + audio to phone"]
    a1 --> tts["Piper TTS"]
    a2 --> tts
    a3 --> tts
    a5 -.->|"speak"| tts
    a6 -.->|"speak"| tts
    tts --> spk(["Speaker"])
```

The assistant utterance is also kept as memory (it's logged as a `voice_query` event), so it isn't duplicated as a conversation segment.

---

## 5.4 Cloud processing jobs

```mermaid
flowchart TB
    subgraph AUDIO["Ambient memory"]
        a0(["audio upload complete"]) --> a1["STT API"]
        a1 -->|"ok"| a2["conversation_segment event<br/>+ present_person_ids from encounters"]
        a1 -->|"fail"| a3{"attempts < 3<br/>and age < 7 days?"}
        a3 -->|"yes"| a1
        a3 -->|"no"| a4["Delete audio, mark failed"]
        a2 --> a5["Delete audio from S3"]
    end

    subgraph MEDIA["Smart review"]
        m0(["media upload complete"]) --> m1{"trigger"}
        m1 -->|"user_requested"| m2["confirmed, keep_indefinitely"]
        m1 -->|"gate-proposed"| m3["Blur non-enrolled faces"]
        m3 --> m4["One vision call"]
        m4 -->|"discard"| m5["Delete"]
        m4 -->|"other people"| m6["confirmed, expire in 30 d"]
        m4 -->|"document"| m7["captured_documents<br/>keep_indefinitely"]
        m4 -->|"own moment"| m8["confirmed, keep_indefinitely"]
    end

    subgraph FACES["Unknown faces"]
        f0(["unknown encounter"]) --> f1["Nearest cluster or new"]
        f1 --> f2{"distinct_days >= 3?"}
        f2 -->|"yes"| f3["Alert caregiver"]
        f2 -->|"no"| f4["Wait"]
    end

    a2 --> e1["Render sentence + embed"]
    m7 --> e1
    e0(["any new event"]) --> e1
    e1 --> pg[("events.embedding · pgvector")]
```

---

## 5.5 RAG: ingestion and query (Phase 2, D22)

```mermaid
flowchart LR
    subgraph ING["Ingestion"]
        ev(["Event"]) --> render["Render sentence<br/>'09:20 talked with Ahmed (son): ...'"]
        render --> embm["text-embedding-3-small"]
        embm --> store[("rendered_text + embedding")]
    end

    subgraph QRY["Query: POST /assist"]
        q(["Audio or text"]) --> stt{"Audio?"}
        stt -->|"yes"| wh["STT"]
        stt -->|"no"| parse
        wh --> parse["Extract time range + people<br/>'الصبح' = 06:00-12:00"]
        parse --> sqlf["SQL: patient + time window<br/>+ person filter"]
        sqlf --> vec["pgvector rank inside window"]
        vec --> ctx["Top-k events"]
        ctx --> llm["LLM answer<br/>diacritized Arabic or English"]
        llm --> out(["answer + source_event_ids"])
    end

    store -.-> sqlf
```

---

## 5.6 Build order (spec §12)

```mermaid
flowchart TB
    s0["0 · Hardware spike<br/>FPS · RAM · heat · mA<br/>BLE + Wi-Fi throughput · I2S + Piper"]
    s1["1 · Scaffold monorepo<br/>rename backend-ai"]
    s2["2 · Schema + Alembic<br/>auth + authorization"]
    s3["3 · People, events, reminders,<br/>places, delta sync"]
    s4["4 · Flutter shell, drift,<br/>ApiClient, auth"]
    s5["5 · Caregiver Mode:<br/>enroll, reminders, places, pairing"]
    s6["6 · Pi recognition + encounters,<br/>ESP32 UART, BLE, Piper, intents,<br/>local reminder firing"]
    s7["7 · Android RelayService: BLE,<br/>outbox, reminder sync, where_am_i<br/>+ iPhone smoke test of Caregiver Mode"]
    s8["8 · End-to-end: encounter in journal,<br/>reminder spoken + confirmed"]
    s9["9 · Ambient memory:<br/>segments, STT, delete audio"]
    s10["10 · Media review + OCR,<br/>retention, unknown faces"]
    s11["11 · Patient Mode UI"]
    s12["12 · Phase 2: assist RAG,<br/>summaries, alerts<br/>stretch: wake word, AR, iOS relay"]

    s0 --> s6
    s1 --> s2
    s2 --> s3
    s1 --> s4
    s3 --> s5
    s4 --> s5
    s6 --> s7
    s5 --> s7
    s7 --> s8
    s3 --> s8
    s8 --> s9
    s8 --> s10
    s8 --> s11
    s9 --> s12
    s10 --> s12
    s11 --> s12
```
