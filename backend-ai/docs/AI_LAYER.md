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
├── clients/          # one module per capability, each behind a small interface
│   ├── stt.py        #   transcribe(audio) -> Transcript       (Whisper-large-v3-class API, spec D3)
│   ├── llm.py        #   complete(prompt) -> text               (Haiku / 4o-mini class)
│   ├── vision.py     #   review(image) -> ReviewResult          (keep/discard + tags + OCR, spec D20)
│   └── embeddings.py #   embed(texts) -> list[vector]           (text-embedding-3-small, 1536-d, spec D15)
├── inference/
│   └── face.py       #   embed_face(image) -> vector(512)       (server-side face embedder for enrollment, spec D14; STUB 'stub-0' until Phase 8)
├── rag/
│   ├── render.py     #   event -> one sentence ("09:20 talked with Ahmed (son): ...")
│   ├── retriever.py  #   SQL time window + person filter, then pgvector ranking (spec D22)
│   └── answer.py     #   build prompt from top-k events, call llm, return answer + source_event_ids (STUB: fixed answer until 9.1)
├── clustering.py     #   assign an unknown embedding to the nearest cluster (spec D23)
└── prompts/          #   *.txt templates, versioned (e.g. assist_answer.v1.txt)
```

---

## 3. Rules

1. **One interface per capability.** Each client exposes a small function or class (`transcribe`, `complete`, `review`, `embed`). Services depend on that, never on a provider SDK directly, so swapping providers only touches one file. Changing a provider is a lead decision.
2. **Every external call has a timeout.** Temporary failures (timeout, HTTP 429, 5xx) raise `TransientError`, which Celery retries (CELERY_REDIS.md). Permanent failures raise a normal error.
3. **AI calls run in Celery tasks, not in requests.** Exceptions: `POST /assist` (the user is waiting) and face embedding at enrollment (fast, local).
4. **Local models load once per process.** API: FastAPI `lifespan`. Workers: Celery `worker_process_init`. Never load a model inside a request or a task.
5. **Server face embeddings stay compatible with the edge** (spec D14). Use the face model version and preprocessing recorded in the spec. If the edge owners change them, the server follows; the backend never changes them on its own.
6. **Prompts are files, not strings in code.** Change a prompt by adding a new version (`.v2.txt`), never by editing the old one in place.
7. **Vector dimensions are fixed by the model:** face 512, text 1536. Changing a model means re-embedding everything, so it's a lead decision.
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
| Smart review + OCR (§7.4) | `clients/vision.py`, output shape in `review_contract.py` | task `review` (queue `ai_io`) |
| Embed events for RAG | `rag/render.py` + `clients/embeddings.py` | task `embed` (queue `ai_io`) |
| Answer a question (`/assist`) | `rag/retriever.py` + `rag/answer.py` + `clients/llm.py` | request (user waiting) |
| Daily summary (Phase 2) | `clients/llm.py` | Beat → task `summaries` |
| Enrollment face embedding | `inference/face.py` | request |
| Unknown-face clustering | `clustering.py` | task `cluster` (queue `cpu`) |
