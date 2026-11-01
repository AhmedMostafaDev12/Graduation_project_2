# Replay harness (research Track B)

Recordings are replayed through **Remori's real memory pipeline**, the same code the server runs, then the benchmark's questions go through the real `/assist`. See [`docs/RESEARCH_PLAN.md`](../../docs/RESEARCH_PLAN.md).

## `supermemory.py`: SuperMemory-VQA

[SuperMemory-VQA](https://huggingface.co/datasets/OSU-AIoT-MLSys-Lab/SuperMemory-VQA) (Meta Aria glasses, 10 people, 52.9 h, 4,853 multiple-choice questions; **CC BY-NC-SA 4.0: research only, never in the product**).

| Step | What runs |
|---|---|
| Speech | the released transcript (no raw audio is public) → conversation events → **consolidation** (facts, plans, entities) |
| Frames | 1 frame a second, kept only when the scene changed (`--novelty`: colour-histogram difference, at least one every `--max-gap` s; a stand-in for the capture gate, not built yet) → **photo review**: strangers pixelated, vision model, keep / discard, documents, object sightings, actions |
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

**Not the same as the glasses yet:** frames are sampled at a fixed rate instead of the capture gate (D33, D42), the transcript comes from the dataset instead of our speech-to-text, and English questions instead of Egyptian Arabic.
