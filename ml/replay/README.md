# Replay harness (research Track B)

Recordings are replayed through **Remori's real memory pipeline**, the same code the server runs, then the benchmark's questions go through the real `/assist`. See [`docs/RESEARCH_PLAN.md`](../../docs/RESEARCH_PLAN.md).

## `supermemory.py`: SuperMemory-VQA

[SuperMemory-VQA](https://huggingface.co/datasets/OSU-AIoT-MLSys-Lab/SuperMemory-VQA) (Meta Aria glasses, 10 people, 52.9 h, 4,853 multiple-choice questions; **CC BY-NC-SA 4.0: research only, never in the product**).

| Step | What runs |
|---|---|
| Speech | the released transcript (no raw audio is public) → conversation events → **consolidation** (facts, plans, entities) |
| Frames | 1 frame a second, kept by the gate stand-in (`--gate`: colour-histogram novelty, at least one every `--max-gap` s, and/or the important-object detector) → **photo review**: strangers pixelated, vision model, keep / discard, documents, object sightings, actions |
| Memory | every event rendered + embedded (Voyage) |
| Questions | evidence only in the replayed sessions (+ the unanswerable ones asked in them), asked at their original time through `/assist`; a judge maps the free answer to one of the 4 choices |
| Score | multiple-choice accuracy, per skill, **with the five structures and without** (flat memory, H6) |

```bash
docker compose -f docker-compose.dev.yml up -d db      # local Postgres only
cd backend-ai
DATABASE_URL=postgresql+psycopg://remori:remori@localhost:5434/remori_test \
  .venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3
```

- Data and frames go to `~/.cache/remori/supermemory/` (never git); results to `…/results/`.
- Everything written to the database is deleted at the end.
- Models: `--provider groq` (default: Qwen3.6-27B on Groq for review, consolidation, /assist and the judge; `GROQ_API_KEY`) or `--provider gemini` (`GEMINI_API_KEY`). Embeddings: Voyage (`VOYAGE_API_KEY`). Face models: `scripts/download_face_models.py`.
- Options: `--every 1` (seconds between frames), `--novelty 0.2` (0 = keep every frame), `--max-gap 10`, `--workers 3` (parallel reviews; mind the provider's tokens-per-minute limit), `--limit N` (questions), `--no-flat`.
- Capture gate: `--gate novelty|detector|both` (the important-object detector with the gate rules of [`ml/edge`](../edge/), plus the 30 s look-back), `--detector` (ONNX file; its `thresholds.json` is read), `--text-threshold`, `--object-threshold`, `--lookback 3`. **`--plan`** prints how many frames each gate keeps and the reviews not in the cache, with **no API call and no database**: run it before paying.

Experiments run so far, results and lessons: [`EXPERIMENTS.md`](EXPERIMENTS.md).

**Not the same as the glasses yet:** the gate is a stand-in (colour-histogram novelty, optionally the detector; no frame embeddings, D34) and the visual memory tier (D41) is not built, the transcript comes from the dataset instead of our speech-to-text, and English questions instead of Egyptian Arabic.
