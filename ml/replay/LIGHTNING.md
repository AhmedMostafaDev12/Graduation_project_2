# Run Qwen3.6-27B on Lightning AI for the replay

How to serve **Qwen3.6-27B (FP8)** on a Lightning AI GPU with **vLLM**, expose it as an OpenAI-compatible API, and point Remori's replay harness at it. Same model as the Groq runs, so results stay comparable, but you pay **per GPU hour instead of per token**, and you can review every frame at full size.

**Use it for research data only** (SuperMemory-VQA, our own recordings with consent). Real patient data never goes to a server like this without the lead's approval (spec D24, §9).

**Note (1 Nov 2026):** Lightning AI workspaces weren't opening at the end of October. The same steps work on any rented GPU with Docker or SSH (e.g. Vast.ai, an RTX PRO 6000 96 GB): start vLLM with the command in §3, then point `SELFHOSTED_BASE_URL` at it. The model download (~30 GB) happens on the rented machine, not on your laptop.

---

## 1. Pick the GPU

| GPU (memory) | Model to serve | Notes |
|---|---|---|
| **L40S (48 GB)**, recommended | `Qwen/Qwen3.6-27B-FP8` (official) | near-full quality, room to batch several frames |
| A100 / H100 (80 GB) | `Qwen/Qwen3.6-27B-FP8` | fastest, most expensive per hour |
| L4 / A10G (24 GB), cheapest | `QuantTrio/Qwen3.6-27B-AWQ` (community 4-bit) | slight quality loss, one or two frames at a time; results less comparable with Groq |

`Qwen/Qwen3.6-27B-FP8` is published by Qwen: "performance metrics nearly identical to the original model". Check the hourly price of each machine in Lightning's machine picker before starting, and how many free credits you have left.

## 2. Start the Studio

1. Sign in at lightning.ai → **New Studio**.
2. Switch the machine to the GPU from §1 (the machine picker at the top right).
3. Open the Studio's **terminal**.

The model download is about 30 GB (FP8), so the first start takes a while. The Studio keeps it for the next time.

## 3. Install and start vLLM

```bash
pip install "vllm>=0.19"            # the version the model card recommends for Qwen3.6
export VLLM_API_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(24))")
echo "$VLLM_API_KEY"                # copy it: Remori needs it (never paste it in chat or git)

vllm serve Qwen/Qwen3.6-27B-FP8 \
  --host 0.0.0.0 --port 8000 \
  --api-key "$VLLM_API_KEY" \
  --max-model-len 32768 \
  --reasoning-parser qwen3 \
  --limit-mm-per-prompt '{"image": 1}' \
  --gpu-memory-utilization 0.92
```

Why these options:
- `--max-model-len 32768`: the model card suggests 128K+ context **for thinking**. Remori turns thinking off and our prompts are under 8K tokens, so 32K is plenty and leaves memory for more frames at once.
- `--reasoning-parser qwen3`: separates any reasoning from the answer.
- `--limit-mm-per-prompt '{"image": 1}'`: one photo per request, as Remori sends.
- On a 24 GB GPU with the AWQ model: use `--max-model-len 16384`.

Wait for `Application startup complete`, then test inside the Studio:

```bash
curl -s http://localhost:8000/v1/models -H "Authorization: Bearer $VLLM_API_KEY"
```

## 4. Expose the API

In the Studio, open the **ports / web apps** panel, add **port 8000**, and copy the **public URL** Lightning gives it. The API is that URL plus `/v1`. Anyone with the URL **and the key** can use it: keep the key private.

From your laptop:

```bash
curl -s https://<your-port-8000-url>/v1/models -H "Authorization: Bearer <the key>"
```

## 5. Point Remori at it

In `backend-ai/.env` (never in git):

```
SELFHOSTED_BASE_URL=https://<your-port-8000-url>/v1
SELFHOSTED_API_KEY=<the key>
SELFHOSTED_MODEL=Qwen/Qwen3.6-27B-FP8        # must match the served model name
```

Quick check (one short request):

```bash
cd backend-ai
.venv/Scripts/python -c "from app.ai.registry import build; print(build('stub', {'llm': 'selfhosted-qwen'}).llm.complete([{'role': 'user', 'content': 'Say OK'}]))"
```

## 6. Run the replay

Every frame (no novelty filter), larger images so printed text is readable, more reviews in parallel (vLLM batches them):

```bash
DATABASE_URL=postgresql+psycopg://remori:remori@localhost:5434/remori_test \
  .venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3 \
  --provider selfhosted --novelty 0 --photo-side 1600 --workers 8
```

- **Reviews are cached** (`~/.cache/remori/supermemory/reviews/`): a frame is reviewed again only when the photo, the model, the review prompt version or the image size changes. Experiments on retrieval or answering reuse them for free.
- The same server answers the questions (`/assist`) and the judge, with thinking off.

## 7. Stop the GPU

**The Studio bills while its GPU machine runs.** When the run ends: stop vLLM (Ctrl+C), then **switch the Studio back to a CPU machine or stop it**. The downloaded model stays for next time.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `CUDA out of memory` at start | lower `--max-model-len` (16384) or `--gpu-memory-utilization` (0.85) |
| out of memory during the run | fewer `--workers` in the harness |
| `401` | `SELFHOSTED_API_KEY` doesn't match `--api-key` |
| `404 model not found` | `SELFHOSTED_MODEL` must equal the name after `vllm serve` |
| first request very slow | normal: the model is still loading or compiling |
| answers contain `<think>` | the client removes them; check `--reasoning-parser qwen3` is set |
