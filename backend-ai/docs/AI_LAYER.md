# backend-ai — The AI layer (`app/ai/`)

## 1. Scope: server-side AI only

`app/ai/` covers **only the models and AI services that the backend server calls or runs**, in the API or in Celery workers. Models that run on the glasses (edge) are **out of scope**: they live in `ml/` or `hardware/` and are decided by their owners, not here.

| In scope here (server) | Out of scope (edge: `ml/` or `hardware/`) |
|---|---|
| AI API clients: STT, LLM, vision, embeddings | On-device models on the Pi: face detection + embedding, intent classifier, capture gate, VAD |
| Server-side local models, e.g. the face embedder used at enrollment: loading + inference | Their training, quantization, export and on-device preprocessing |
| RAG: rendering events, retrieval, prompts, answers | On-device runtimes and their performance tuning |
| Vector search in pgvector | |
| Unknown-face clustering on stored embeddings | |
| Prompt templates, timeouts, retries, cost limits | |

Rule of thumb: **if it runs on the server, it belongs here. If it runs on the glasses, it doesn't.**

**One cross-boundary constraint (spec D14):** the face embeddings the server computes at enrollment must be comparable with the ones the glasses compute, or recognition fails. The backend doesn't decide edge processing. The model version and preprocessing are agreed with the edge owners and recorded in the spec.

---

## 2. Folder map

```
app/ai/
├── interfaces.py     # one Protocol per capability + result types (§6)
├── registry.py       # profiles production / small / stub → get_ai() (§6)
├── fakes.py          # deterministic fakes for the stub profile and tests
├── clients/          # real providers, one module per capability, each implementing its interface
│   ├── stt.py        #   transcribe(audio) -> Transcript       (Deepgram Nova-3, ar-EG + speaker labels, D36)
│   ├── llm.py        #   complete(messages, json_schema) -> text (Gemini Flash, paid tier; built in 7.5)
│   ├── vision.py     #   review(image) -> ReviewResult          (Gemini Flash: keep/discard + tags + OCR + room/objects/actions, spec D20, D29; built in 8.3)
│   └── embeddings.py #   embed(texts) -> list[vector]           (Voyage voyage-4, 1024-d, spec D15; built in 7.3, Voyage since 0006)
├── inference/
│   ├── face.py       #   enrollment stub 'stub-0' (until 8.2 switches enrollment) + the glasses' wire format
│   └── face_onnx.py  #   faces(image) -> [Face(box, landmarks, vector(512))]  (SCRFD + w600k_mbf, spec D14; built in 8.1)
├── memory/           # structured memory (§6.4, spec D40): consolidation + the five structures
│   └── extract.py    #   facts, intentions, entities from a transcript: prompts, schemas, validation (7.5)
├── rag/
│   ├── render.py     #   event -> one sentence ("09:20 talked with Ahmed (son): ...")
│   ├── retriever.py  #   filters, then meaning + words + memory structures, fused; premise check (D22, D39, D40; 9.1)
│   ├── planner.py    #   validate the agent's search arguments (track R3)
│   ├── assist_loop.py #  the bounded search-then-answer agent (track R3)
│   └── answer.py     #   /assist: the loop + the retriever + assist_llm → answer + source_event_ids (9.1)
├── clustering.py     #   decode the glasses' vector, nearest enrolled person / cluster (spec D23; built in 8.4)
└── prompts/          #   *.txt templates, versioned (memory_extract.v1.txt, memory_settle.v1.txt, vision_review.v1.txt)
```

---

## 3. Rules

1. **One interface per capability.** Each client exposes a small function or class (`transcribe`, `complete`, `review`, `embed`). Services depend on that, never on a provider SDK directly, so swapping providers only touches one file. Changing a provider is a lead decision.
2. **Every external call has a timeout.** Temporary failures (timeout, HTTP 429, 5xx) raise `TransientError`, which Celery retries (CELERY_REDIS.md). Permanent failures raise a normal error.
3. **AI calls run in Celery tasks, not in requests.** Exceptions: `POST /assist` (the user is waiting) and face embedding at enrollment (fast, local).
4. **Local models load once per process.** API: FastAPI `lifespan`. Workers: Celery `worker_process_init`. Never load a model inside a request or a task.
5. **Server face embeddings stay compatible with the edge** (spec D14). Use the face model version and preprocessing recorded in the spec. If the edge owners change them, the server follows; the backend never changes them on its own.
6. **Prompts are files, not strings in code.** Change a prompt by adding a new version (`.v2.txt`), never by editing the old one in place.
7. **Vector dimensions are fixed by the model:** face 512, text 1024. Changing a model means re-embedding everything, so it's a lead decision.
8. **Privacy:** blur non-enrolled faces before any vision call (spec §7.4). Never log prompts that contain transcripts or names. Raw audio is deleted after transcription (spec D4).
9. **Tests never call real AI APIs.** Mock them with `respx` and keep a few recorded example responses as fixtures.

---

## 4. Smart-review contract (spec D29)

The vision prompt (Phase 7) must return `ReviewResult` from [`app/ai/review_contract.py`](../app/ai/review_contract.py): `keep`, `category`, `tags`, `reason`, `contains_other_people`, and for documents `document_type`, `ocr_text`, `fields`.

- **Store only through `normalize_document` / `normalize_ai_tags`.** They never raise: unknown categories become `other` with `raw_category`, known keys accept common variants, junk is dropped.
- **Known types use fixed keys** (`DOCUMENT_KEYS`); the app translates them. **`other` carries the model's own `title` and `{label, value}` rows**, written in the patient's language, shown as-is.
- **Keep/discard never depends on the category.** An important photo that fits nothing is kept as `other` with a `reason`.
- **Never add a category in code alone.** Review what the model keeps inventing, then propose it to the lead:
  ```sql
  SELECT extracted_fields->>'raw_category' AS raw, count(*) FROM captured_documents
  WHERE document_type = 'other' GROUP BY 1 ORDER BY 2 DESC;
  SELECT ai_tags->>'raw_category' AS raw, count(*) FROM media_assets
  WHERE ai_tags->>'category' = 'other' GROUP BY 1 ORDER BY 2 DESC;
  ```
  An approved category means: spec change → `DOCUMENT_KEYS` / `MEDIA_CATEGORIES` → prompt version bump → app layout → backfill rows whose `raw_category` matches.

## 5. Where each AI feature lives

| Feature (spec) | Client / module | Runs in |
|---|---|---|
| Transcribe speech segments (§7.3) | `clients/stt.py` | task `transcribe` (queue `ai_io`) |
| Smart review + OCR (§7.4) | `services/review_service.py` (blur strangers) + `clients/vision.py`, output shape in `review_contract.py` | task `review.media` (queue `ai_io`) |
| Embed events for RAG | `rag/render.py` + `clients/embeddings.py` | task `embed` (queue `ai_io`) |
| Facts + intentions from speech (D40) | `memory/extract.py` + `clients/llm.py` | task `memory.consolidate` (queue `ai_io`) |
| Object sightings + action log from photos (D40) | `services/vision_memory.py` (fields from the review call) | inside task `review.media` |
| Answer a question (`/assist`) | `rag/answer.py` + `rag/assist_loop.py` + `rag/retriever.py`, model `assist_llm` | request (user waiting, glasses give up at 20 s) |
| Daily summary (Phase 2) | `clients/llm.py` | Beat → task `summaries` |
| Enrollment face embedding | `inference/face_onnx.py` (stub until 8.2) | request |
| Unknown-face clustering | `clustering.py` + `services/clustering_service.py` | task `cluster.unknown_faces` (queue `cpu`, every 10 min) |

---

## 6. Model interfaces and profiles (spec D37, D38)

**Server engine only.** Gate rules, the frame embedder and audio events run on the glasses and live in `ml/edge/` (D38); this section covers what the backend runs.

### 6.1 One interface per capability (`app/ai/interfaces.py`)
| Interface | Method | Production (cloud) | Small (open) |
|---|---|---|---|
| `SpeechToText` | `transcribe(audio, content_type, language_hint) -> Transcript` (segments with times and speaker labels) | Deepgram Nova-3 (`ar-EG`) + diarization, `clients/stt.py` | WhisperX |
| `TextEmbedder` | `embed(texts) -> list[vector]` (stored sentences), `embed_query(text) -> vector` (questions) | Voyage `voyage-4` (1024-d, D15; document / query sides) | a multilingual open embedder |
| `VisionReviewer` | `review(image, language) -> dict` (shaped by `review_contract`) | cloud vision model | Qwen2.5-VL |
| `Captioner` | `caption(images, transcript, language) -> str` | cloud vision model | small VLM |
| `LLM` | `complete(messages, json_schema=None) -> str` | Haiku / 4o-mini class | Qwen / Gemma via a local server |
| `FaceEmbedder` | `faces(image) -> [Face]` (box, 5 landmarks, 512-d vector), `embed_face(image)` | InsightFace SCRFD + `w600k_mbf` ONNX (D14), `inference/face_onnx.py` | same |

Every implementation exposes `model_id`, and anything it produces is stored with that id (for example, which model embedded an event).

### 6.2 Profiles and the registry (`app/ai/registry.py`)
- `AI_PROFILE=production | small | stub` picks an implementation for every capability. One capability can be overridden: `AI_STT`, `AI_TEXT_EMBEDDER`, `AI_VISION`, `AI_CAPTIONER`, `AI_LLM`, `AI_ASSIST_LLM` (the /assist agent: `gemini-flash-fast` = the same Gemini with low thinking, for speed), `AI_FACE`.
- `get_ai()` builds the models **once per process** (rule 4) and caches them. Services call `get_ai().stt.transcribe(...)`, never a provider SDK.
- A provider that isn't implemented yet fails with a clear error naming the capability. The default profile stays `stub` until the real clients exist.
- `stub` uses `app/ai/fakes.py`: deterministic fakes with the right shapes and dimensions, for tests and local work without API keys.

### 6.3 Rules for swapping models
1. **Vectors from different models never mix.** Changing the product's `TextEmbedder` means re-embedding everything (rule 7, a lead decision).
2. **Experiments never write to the product database.** The replay harness (`ml/replay/`) uses its own memory store with the `small` or `production` profile.
3. **Adding a provider** = a class implementing the interface + one entry in the registry + tests with mocked HTTP (rule 9). Services don't change.

**Which provider for each capability, and the data rule for free tiers:** [MODELS_CHOICE.md](MODELS_CHOICE.md).

### 6.4 Structured memory (spec D40)
- **Layers:** raw evidence (events, verbatim transcripts with speakers, kept frames, frame embeddings, OCR) → **five structures** → day/week summaries. Summaries never answer alone.
- **The five structures:** object sightings/states, action log (one row per action, never merged), facts (speaker + exact quote + typed numbers/dates), intentions (plan, due time, status, settling evidence), entity index.
- **Consolidation** (`app/ai/memory/`): Celery tasks after transcription and review extract the structures with versioned prompts. Every record stores the ids of the evidence it came from and the `model_id` that extracted it. Quotes are copied verbatim, never paraphrased.
- **Intentions are re-checked** when new actions or events arrive: status moves from unknown to done / not done, with the evidence that settled it.
- **Answering** (`rag/`): route by question type to the structures first, then vector search; the premise check queries the entity index.
- **Two-stage visual search (D41):** first the scene-segment vectors in Postgres find the candidate minutes; then only the matching hourly frame-vector files are loaded from S3 and every frame inside those minutes is re-ranked in memory.
- **Switchable:** a setting turns the structures off, giving the flat-memory baseline used in the research (H6).
