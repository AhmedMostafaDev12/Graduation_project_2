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
2. **Measure, don't trust marketing.** Run the pilot recordings through Deepgram, AssemblyAI and Speechmatics (and Munsit if its API is available), compare word error rates, and keep the best. The `SpeechToText` interface makes switching a configuration change. The comparison is also a result for the paper.

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
| **OpenAI `text-embedding-3-small`** (current choice, D15) | $0.02 ($0.01 batch) | limited | multilingual; about **$0.001 per patient per day** at our volume |
| Gemini embedding | $0.15 | ~1,500 requests/day | up to 3,072 dimensions |
| Jina Embeddings v3 | $0.02 | 10M tokens/month | multilingual |
| Cohere embed-v4 | $0.12 | trial | 100+ languages |
| Qwen3-Embedding-8B | free to self-host | — | #1 on the multilingual MTEB leaderboard; candidate for the `small` profile |

**Recommendation:** keep D15 (`text-embedding-3-small`). It is cheap enough that no free tier is needed, and changing it means re-embedding everything (a lead decision).

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

## 7. Status

| Capability | Recommended `production` | Recommended `small` | Decided? |
|---|---|---|---|
| Speech-to-text | Deepgram Nova-3 Arabic + diarization | WhisperX (self-hosted) | to confirm by the lead, then by the pilot WER comparison |
| LLM | Gemini Flash-Lite / Flash (paid) | Qwen3 via Groq | to confirm |
| Vision | Gemini Flash (paid) | Qwen2.5-VL | to confirm |
| Text embeddings | `text-embedding-3-small` | Qwen3-Embedding | **decided (D15)** |

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
