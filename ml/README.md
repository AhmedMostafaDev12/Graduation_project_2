# ml — Low-level machine learning

Training, datasets, notebooks, evaluation and model export, plus the trained and exported models themselves.
**Not here:** anything that *uses* a model to serve a request or a job. That lives in `backend-ai/app/ai/` (see `backend-ai/docs/AI_LAYER.md`) or on the glasses (`hardware/pi`).
Read the root [`AGENTS.md`](../AGENTS.md) first.

Owner: **Ahmed Mostafa** (lead, AI) with the AI/ML track.

---

## Folder map

```
ml/
├── face/            # face pipeline: detection + alignment + preprocessing shared by the Pi and the backend (spec D14),
│                    # evaluation (FAR/FRR, threshold choice), export of MobileFaceNet w600k_mbf to ONNX/INT8
├── intent/          # push-to-talk intent classifier (spec D17): dataset scripts, training, export
├── capture_gate/    # on-device capture gate: heuristics first, optional MobileNetV3 (spec §3)
├── rag_eval/        # question/answer evaluation sets for the RAG pipeline
├── notebooks/       # experiments
├── models/          # EXPORTED artifacts + a model card per model (name, version, input/output, metrics)
└── datasets/        # local only (gitignored). README explains how to obtain each dataset
```

## Rules
1. **Every exported model gets a model card** in `models/` (version, input shape, output, preprocessing, metrics, date). Consumers pin a version.
2. **Changing an exported model is a lead decision.** Embeddings stored in the database become invalid when the face model changes.
3. **No personal data in git.** Face photos, voice recordings and transcripts stay out of the repo.
4. **Open decisions (ask the lead):** Git LFS vs S3 for model files, and how `backend-ai` imports `ml/face` (root `AGENTS.md` §5).
