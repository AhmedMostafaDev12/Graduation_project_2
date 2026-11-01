# Models choice: which cloud AI models Remori uses, and why

Research done in **October 2026** for the server engine's capabilities (speech-to-text, LLM, vision, text embeddings; see [AI_LAYER.md](AI_LAYER.md) §6). Prices, free tiers and limits change often: **re-check the provider's own pricing page before relying on a number.** Sources are listed at the end.

Choosing a provider is a **lead decision** (AI_LAYER.md rule 1). This document records the options and the recommendations; a choice becomes final when it is written into the registry's `production` / `small` profiles.

---

## 1. The data rule (read first)

Some free tiers **use your data to train their models**. Gemini's free tier, for example, says its content is used to improve Google's products; the paid tier does not. Remori sends **transcripts of patients' conversations and photos of their homes**: sensitive personal and health data under the Egyptian Personal Data Protection Law (spec D24).

| Data | Allowed tier |
|---|---|
| Fakes, synthetic data, the team testing with its own voices | free tiers are fine |
| Research volunteers' recordings and real patients | **only tiers that do not train on our data** (usually paid, and cheap at our volume), with the provider's no-training terms confirmed |

---

## 2. Speech-to-text with speaker labels (phase 7.1, spec D36)

The hardest capability: **Egyptian Arabic is weak almost everywhere.** On real conversational dialect speech, even the best systems average word error rates in the mid-20s %, and Whisper large-v3 is around 37%.

| Provider | Egyptian Arabic | Speaker labels | Free tier | Paid price |
|---|---|---|---|---|
| **Deepgram Nova-3 Arabic** | explicitly supports **Egyptian** among 17 Arabic variants (dedicated Arabic model, January 2026) | yes, +$0.002/min | **$200 credit (~690 hours)** | ~$0.0045/min + diarization |
| **AssemblyAI Universal-3 Pro** | Arabic in its 99-language model | yes, ~$0.02/hour | $50 credit (~185 hours) | ~$0.15–0.27/hour |
| **ElevenLabs Scribe v2** | Arabic; strong benchmark numbers (FLEURS, mostly MSA) | yes, included | 10,000 credits/month | per plan |
| **Speechmatics** | Egyptian + code-switching | yes | 480 min/month | from ~$0.13/hour |
| **Munsit** (Arabic specialist) | best on a multi-dialect Arabic leaderboard (26.7% average WER vs Whisper large-v3's 36.9%) | to check | to check | to check |
| Groq Whisper large-v3-turbo | general Whisper, weaker on dialect | **no** | free tier | $0.67 per 1,000 min |

**Recommendation:**
1. **Phase 7.1 starts with Deepgram Nova-3 Arabic + diarization.** It is the only option that names Egyptian Arabic explicitly, it has speaker labels, and the $200 credit covers development and the whole research pilot.
2. **Measure, don't trust marketing.** Measured in §7: Deepgram beats AssemblyAI on Egyptian Arabic (WER 32.7 % vs 41.1 % conversational, 4.6 % vs 9.0 % read). Re-check on the pilot recordings (and Speechmatics / Munsit if needed); the `SpeechToText` interface makes switching a configuration change.

---

## 3. LLM (answering, extracting facts and intentions, summaries)

| Provider | Free tier | Paid | Notes |
|---|---|---|---|
| **Google Gemini Flash / Flash-Lite** | ~1,000–1,500 requests/day, 1M-token context; **free-tier data is used for training** | Flash-Lite **$0.10 / $0.40** per 1M tokens (input / output) | strong Arabic; text, image and audio in one API; Pro models are paid-only since April 2026 |
| **Groq** (open models such as Qwen3 32B, gpt-oss) | ~30 requests/min, ~1,000 requests/day; **no training on data by default**, zero data retention available | Qwen3 32B $0.29 / $0.59 per 1M tokens | very fast; data stored in the US |
| OpenRouter `:free` models | 50 requests/day (1,000 after a $10 top-up) | varies by model | good for trying many models |
| Cerebras | **no permanent free tier** since July 2026 | — | skip |

**Recommendation:**
- **`production` profile:** Gemini Flash-Lite or Flash on the **paid tier** (pennies per patient per day, no training on our data).
- **`small` profile and research (H5):** open models through **Groq** (free tier, no training by default).
- **Development:** Gemini's free tier with synthetic data only.

---

## 4. Vision (photo review, OCR, objects: spec D20, D29, D40)

**Gemini Flash** is the strongest affordable choice: one call does the keep/discard review, OCR of Arabic labels and receipts, and the memory fields (`room`, `objects`, `actions`). Same rule: **paid tier** for real data. Groq's vision models are still in preview, so they aren't relied on yet.

---

## 5. Text embeddings (RAG, spec D15)

| Model | Price per 1M tokens | Free | Notes |
|---|---|---|---|
| **Voyage `voyage-4`** (current choice, D15) | $0.06 after the allowance | **200M tokens** once per account | multilingual; 256 / 512 / **1024** / 2048 dimensions; separate document and query modes; **uses data for training unless you opt out** in the dashboard |
| OpenAI `text-embedding-3-small` | $0.02 ($0.01 batch) | none (prepaid, minimum $5) | multilingual; can be shortened to 1024 dimensions, so it fits the same columns (kept as an alternative) |
| Gemini embedding | $0.15 | ~1,500 requests/day | up to 3,072 dimensions |
| Jina Embeddings v3 | $0.02 | 10M tokens/month | multilingual |
| Cohere embed-v4 | $0.12 | trial | 100+ languages |
| Qwen3-Embedding-8B | free to self-host | — | #1 on the multilingual MTEB leaderboard; candidate for the `small` profile |

**Decision (26 Oct 2026):** Voyage `voyage-4` at **1024 dimensions** (D15 changed). OpenAI has no free tier and a Google billing account needs a $30 minimum; Voyage's 200M free tokens cover roughly 8,000 patient-days (about 25k tokens per patient per day). 1024 and not 2048 because pgvector's HNSW index stops at 2,000 dimensions. Measured once: 1024-d unit vectors, ~1.3 s for a small batch. **Before real data:** opt out of training in the Voyage dashboard.

---

## 6. Expected cost

For a demo with a few patients, using the starting credits:

| Capability | Monthly cost |
|---|---|
| Speech-to-text | covered by Deepgram's $200 credit for months |
| LLM + vision | a few dollars on paid Gemini |
| Embeddings | under a dollar |

Realistically **under $10 a month** until the credits run out.

---

## 7. Measured results on Egyptian Arabic (October 2026): speech-to-text (7.1–7.4), LLM extraction (7.5)

### 7.1 Public datasets (WER / CER)
**What:** 40 clips with human-written transcripts, 20 from each dataset, spread across the split. Each clip transcribed with the provider's Arabic setting; both texts normalized the same way (diacritics, tatweel and punctuation removed; alef / ya / ta marbuta / hamza seats unified) so spelling variants don't count as errors.
**Script:** [`ml/rag_eval/stt_quick_check.py`](../../ml/rag_eval/stt_quick_check.py) (re-run it to reproduce the Deepgram numbers; audio is cached outside the repo).

| Dataset | What it is | Deepgram Nova-3 (`ar-EG`) | AssemblyAI Universal (`ar`) |
|---|---|---|---|
| **MGB-3 Egyptian** (`MightyStudent/Egyptian-ASR-MGB-3`) | real Egyptian TV / YouTube speech: spontaneous, hesitations, fast | **WER 32.7 %** · CER 19.5 % | WER 41.1 % · CER 22.7 % |
| **FLEURS `ar_eg`** (`google/fleurs`, CC-BY 4.0) | Egyptian speakers reading sentences | **WER 4.6 %** · CER 1.0 % | WER 9.0 % · CER 2.7 % |

*WER = share of words wrong, CER = share of characters wrong; lower is better.* For context: the best published systems average word error rates in the mid-20s % on multi-dialect Arabic benchmarks, and Whisper large-v3 about 37 % (§2).

**Reading the numbers:**
- Deepgram wins on both datasets, by about 8 points on conversational speech and half the errors on read speech.
- Clear speech is almost perfect (about 1 word in 20 wrong). Real conversational Egyptian is about 1 word in 3, close to the state of the art.
- Many of the remaining "errors" aren't real mistakes: the human transcripts keep hesitations (`ن ن`, `آ`) and `...`, and spoken forms are spelled differently (`حاله` / `حالة`). The real errors are mostly names and similar-sounding words (`استضفنا` → `اصطادتنا`, `سواق` → `سواء`).

### 7.2 Our own two-person recording (qualitative)
A 32-second WhatsApp voice note (two people, one voice much quieter; heavily compressed at 15 kb/s):

| | Result |
|---|---|
| Deepgram, original audio | words good (`عيني حاضر`, `اعملي لنا حاجة فيها بروتين`), but the quiet opening and the last sentence were **missing**; **everyone labelled speaker A** |
| Deepgram, volume boosted (`try_stt.py --normalize`) | about **20 % more speech recovered** (`ازيك يا ماما عامله ايه`, `العطف واللطف…`); speakers **still all A** |
| AssemblyAI, told "2 speakers", boosted | **speakers alternate A / B** like a real dialogue, but many Egyptian phrases garbled (`زي كمان عم لقيه`, `ثابروتين`, `أنا إيه خاطر`); without the speaker hint, no separation at all |
| Speed | Deepgram ~4 s, AssemblyAI ~10 s (upload + job polling) |

### 7.3 Decisions from these results
1. **Speech-to-text: Deepgram Nova-3 `ar-EG`** (better words on every test, faster). AssemblyAI is not kept as a provider.
2. **Boost the volume before transcribing** (`dynaudnorm` + `loudnorm`, 16 kHz mono) in the real pipeline (phase 7.2): it clearly recovers quiet speech.
3. **Speaker separation is still open:** Deepgram's diarization failed on the two-person clip. Candidates: pyannote matched to Deepgram's word timestamps, plus faces (`present_person_ids`) and the wearer's voice being the loudest on the glasses.

### 7.4 Caveats
- 20 clips per dataset is a quick check, not the research benchmark (RESEARCH_PLAN §6 uses our own recordings).
- MGB-3 and FLEURS are public and widely used, so commercial models may have trained on them, which can flatter the results.
- The AssemblyAI numbers came from a temporary client that wasn't kept, so the script reproduces only the Deepgram numbers.
- Speaker separation wasn't measured on the datasets (their clips are single-speaker).

### 7.5 LLM extraction: facts, intentions, settlements (phase 7.5)
**What:** 15 synthetic conversations (5 scenarios × 3 days: 10 Egyptian Arabic, 4 mixed, 1 English; fictional people), written by ChatGPT with gold labels: 44 facts, 23 intentions, 11 settlements (7 done, 4 not done), 106 entities and 56 traps that must not be extracted. Each model ran the **backend's real prompts and validation** (`memory_extract.v1`, `memory_settle.v1`, `app/ai/memory/extract.py`). Settlements were asked against the gold open plans, so they're scored on their own.
**Script:** [`ml/rag_eval/extraction_eval.py`](../../ml/rag_eval/extraction_eval.py), test set [`ml/rag_eval/data/extraction_testset.json`](../../ml/rag_eval/data/extraction_testset.json).

| | **Gemini Flash** (`gemini-3.8-flash`, paid) | Qwen3.8-27B (Groq) | GPT-OSS-120B (Groq) |
|---|---|---|---|
| Facts F1 | **84 %** (precision 92 %) | 79 % | 73 % |
| Typed values F1 | 66 % | **72 %** | 63 % |
| Intentions F1 | **94 %** (recall 100 %) | 85 % | 87 % |
| Holder right (patient / other) | **100 %** | 95 % | 75 % |
| Due time exact (date right) | **79 %** (89 %) | 78 % (94 %) | 56 % (94 %) |
| Settlements F1 | **69 %** | 63 % | 67 % |
| Entities F1 (loose: names vary) | **55 %** | 31 % | 45 % |
| Answers thrown away by validation | **0 %** | 28 % (one intention repeated 26 times) | 3 % |
| Time per call | 16.9 s | **1.3 s** | 4.2 s |

*A fact or intention counts as found when it's in the same segment and one quote contains the other or they share half their words.*

**Reading the numbers:**
- Gemini is best where a mistake would mislead the patient: every plan found, every holder right, fewest invented facts.
- Qwen is close, free and 13× faster, but unstable: one answer looped (the validation now keeps each item once), and two runs differed by 7 points on facts.
- GPT-OSS often gets the holder and the exact time wrong.
- Gemini's 17 s per call doesn't matter for consolidation (a background task); it would for `/assist`, where D39 allows 20 s for the whole answer.

**Decisions:**
1. **Consolidation (7.5): Gemini Flash, paid tier.** The same key serves vision in Phase 8.
2. **Answering (`/assist`, Phase 9): open.** Speed matters there; Groq Qwen is the candidate to measure then.

**Caveats:** 15 conversations, gold labels written by a model (some "wrong" answers are defensible plans the labels missed), one run per model. Enough to choose a model, not a research result.

## 8. Status

| Capability | Recommended `production` | Recommended `small` | Decided? |
|---|---|---|---|
| Speech-to-text | Deepgram Nova-3 `ar-EG` + diarization, volume boosted first | WhisperX (self-hosted) | **decided** (measured, §7); speaker separation still open |
| LLM | Gemini Flash (`gemini-3.8-flash`, **paid tier**; `clients/llm.py`, phase 7.5) | Qwen3.8-27B via Groq | **decided for consolidation** (measured, §7.5). `/assist` (9.1): the same model with **low thinking** (`gemini-flash-fast`): median 7.9 → 4.0 s per call; Groq Qwen stays the candidate if 20 s isn't met |
| Vision | Gemini Flash (paid; `clients/vision.py`, phase 8.3) | Qwen2.5-VL | **decided, implemented** (checked on a portrait and a receipt: fields read right, ~7 s per photo; not measured on a test set yet) |
| Text embeddings | Voyage `voyage-4`, 1024-d (`clients/embeddings.py`, migration 0006) | Qwen3-Embedding | **decided (D15, changed 26 Oct), implemented** |

Keys go in `backend-ai/.env` locally and in the server's environment, **never in git**.

---

## Sources

- [Munsit: Best Arabic Speech to Text in 2026](https://www.munsit.com/blog/best-arabic-speech-to-text)
- [Munsit: 10 Best Arabic Speech to Text APIs for MENA](https://www.munsit.com/blog/best-arabic-voice-speech-to-text-apis)
- [Munsit: Deepgram alternatives for Arabic STT](https://munsit.com/blog/deepgram-alternatives-arabic-stt)
- [Gladia: Best Speech-to-Text APIs in 2026](https://www.gladia.io/blog/best-speech-to-text-apis)
- [Speech-to-Text APIs in 2026: Benchmarks and Pricing](https://futureagi.substack.com/p/speech-to-text-apis-in-2026-benchmarks)
- [AssemblyAI pricing](https://www.assemblyai.com/pricing)
- [AssemblyAI pricing 2026 breakdown](https://www.cekura.ai/blogs/assemblyai-pricing)
- [Speaker diarization: AssemblyAI vs Deepgram vs Pyannote](https://www.forasoft.com/blog/article/speaker-diarization-api-comparison)
- [Deepgram pricing 2026](https://smallest.ai/blog/deepgram-pricing-plans-cost-what-you-get-in-2026)
- [Deepgram per-minute rates and add-ons](https://www.activepieces.com/blog/deepgram-pricing-2026-per-minute-rates-and-add-ons.md)
- [ElevenLabs Arabic speech to text](https://elevenlabs.io/speech-to-text/arabic)
- [ElevenLabs Scribe review 2026](https://discoverai.tools/articles/elevenlabs-scribe-speech-to-text-review-2026)
- [NADI 2026: multidialectal Arabic speech processing shared task](https://arxiv.org/pdf/2609.27086)
- [OpenRouter: Free LLM APIs compared](https://openrouter.ai/blog/tutorials/free-llm-apis-compared/)
- [Free LLM APIs: real limits and catches](https://continuumcode.ai/guides/free-llm-api/)
- [Gemini API free tier 2026](https://pecollective.com/tools/gemini-free-tier-guide/)
- [Is the Gemini API free? (data use on the free tier)](https://www.lilachbullock.com/is-gemini-api-free/)
- [Gemini API pricing 2026](https://www.metacto.com/blogs/the-true-cost-of-google-gemini-a-guide-to-api-pricing-and-integration)
- [Groq API data privacy guide](https://apistatuscheck.com/blog/groq-api-data-privacy-guide)
- [Which AI APIs train on your data](https://www.developersdigest.tech/blog/which-ai-apis-train-on-your-data)
- [Groq pricing 2026](https://www.aipricing.guru/groq-pricing/)
- [Best embedding models 2026 (OpenRouter)](https://openrouter.ai/blog/insights/best-embedding-models-2026/)
- [Embeddings API pricing 2026](https://aiapiprices.com/embeddings-api-pricing/)
- [Best free embedding APIs 2026](https://www.ainomam.com/post/embedding-model-api-free-2026)
