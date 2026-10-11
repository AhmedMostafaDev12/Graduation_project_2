# backend-ai — The AI layer (`app/ai/`) and its boundary with `ml/`

## 1. The boundary

| `backend-ai/app/ai/`: AI **as software** | `ml/`: **low-level ML** |
|---|---|
| Calling AI APIs (STT, LLM, vision, embeddings) | Training and fine-tuning |
| Running an exported local model (ONNX face embedder) | Datasets and data preparation |
| RAG: rendering events, retrieval, prompts, answers | Notebooks and experiments |
| Vector search in pgvector | Evaluation (face FAR/FRR, intent accuracy, RAG eval sets) |
| Unknown-face clustering on stored embeddings | Quantization and export (`.onnx`, `.tflite`) |
| Prompt templates | Shared preprocessing (face alignment) used by the Pi and the backend |
| Timeouts, retries, cost limits | Model cards: what each exported model is, its version, its metrics |

Rule of thumb: **if it imports a training framework or produces a model file, it belongs in `ml/`. If it uses a model to serve a request or a job, it belongs here.**

The backend **only reads** from `ml/models/`. It never trains or exports. How `backend-ai` imports `ml/` code and model files is an **open decision**, so ask the lead (root `AGENTS.md` §5).

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
│   └── face.py       #   embed_face(image) -> vector(512)       (exported MobileFaceNet from ml/models/, spec D14)
├── rag/
│   ├── render.py     #   event -> one sentence ("09:20 talked with Ahmed (son): ...")
│   ├── retriever.py  #   SQL time window + person filter, then pgvector ranking (spec D22)
│   └── answer.py     #   build prompt from top-k events, call llm, return answer + source_event_ids
├── clustering.py     #   assign an unknown embedding to the nearest cluster (spec D23)
└── prompts/          #   *.txt templates, versioned (e.g. assist_answer.v1.txt)
```

---

## 3. Rules

1. **One interface per capability.** Each client exposes a small function or class (`transcribe`, `complete`, `review`, `embed`). Services depend on that, never on a provider SDK directly, so swapping providers only touches one file. Changing a provider is a lead decision.
2. **Every external call has a timeout.** Temporary failures (timeout, HTTP 429, 5xx) raise `TransientError`, which Celery retries (CELERY_REDIS.md). Permanent failures raise a normal error.
3. **AI calls run in Celery tasks, not in requests.** Exceptions: `POST /assist` (the user is waiting) and face embedding at enrollment (fast, local).
4. **Local models load once per process.** API: FastAPI `lifespan`. Workers: Celery `worker_process_init`. Never load a model inside a request or a task.
5. **Same face preprocessing as the glasses.** Face alignment and preprocessing come from `ml/` (spec D14). A parity test asserts the backend and the Pi produce the same embedding for the same image.
6. **Prompts are files, not strings in code.** Change a prompt by adding a new version (`.v2.txt`), never by editing the old one in place.
7. **Vector dimensions are fixed by the model:** face 512, text 1536. Changing a model means re-embedding everything, so it's a lead decision.
8. **Privacy:** blur non-enrolled faces before any vision call (spec §7.4). Never log prompts that contain transcripts or names. Raw audio is deleted after transcription (spec D4).
9. **Tests never call real AI APIs.** Mock them with `respx` and keep a few recorded example responses as fixtures.

---

## 4. Where each AI feature lives

| Feature (spec) | Client / module | Runs in |
|---|---|---|
| Transcribe speech segments (§7.3) | `clients/stt.py` | task `transcribe` (queue `ai_io`) |
| Smart review + OCR (§7.4) | `clients/vision.py` | task `review` (queue `ai_io`) |
| Embed events for RAG | `rag/render.py` + `clients/embeddings.py` | task `embed` (queue `ai_io`) |
| Answer a question (`/assist`) | `rag/retriever.py` + `rag/answer.py` + `clients/llm.py` | request (user waiting) |
| Daily summary (Phase 2) | `clients/llm.py` | Beat → task `summaries` |
| Enrollment face embedding | `inference/face.py` | request |
| Unknown-face clustering | `clustering.py` | task `cluster` (queue `cpu`) |
