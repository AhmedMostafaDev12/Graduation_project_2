# Remori — Orchestrator (read this first)

Instructions for every AI coding agent and every human contributor working in this repository.
Each area has its own `AGENTS.md` with the details. This file says **how the areas fit together** and **which rules apply everywhere**.

Remori is a graduation project: AI memory-assistant smart glasses for people living with Alzheimer's, with a Flutter companion app and a cloud backend. Team lead and owner of architecture, backend and AI: **Ahmed Mostafa**.

---

## 1. Repository map

| Folder | What lives there | Detailed rules |
|---|---|---|
| `backend-ai/` | FastAPI API, database models + migrations, background workers (Celery + Redis), and **all software that uses AI**: AI API clients, RAG, vector search, local model inference wrappers | [`backend-ai/AGENTS.md`](backend-ai/AGENTS.md) |
| `flutter/` | The companion app: Patient Mode + Caregiver Mode, Android + iOS, glasses relay (Android) | [`flutter/AGENTS.md`](flutter/AGENTS.md) |
| `ml/` | **Low-level ML only**: training, datasets, notebooks, evaluation, model export, and the trained/exported model files | [`ml/README.md`](ml/README.md) |
| `hardware/` | Raspberry Pi runtime + ESP32 firmware for the glasses | spec §5, §7.1 |
| `docs/` | Spec companions: review, diagrams, team workflow, API contract, study guide | below |
| `.github/` | CI workflow (pull-request checks) | [`docs/TEAM_WORKFLOW.md`](docs/TEAM_WORKFLOW.md) |

---

## 2. Sources of truth (in priority order)

1. [`REMORI_SPEC.md`](REMORI_SPEC.md): **the** source of truth. Decision log (§0), data model (§6), contracts (§7). If code and spec disagree, the spec wins, or the spec gets changed first by the lead.
2. Area docs: `backend-ai/AGENTS.md` + `backend-ai/docs/*`, `flutter/AGENTS.md` + `flutter/docs/*`, `ml/README.md`.
3. Shared docs:
   - [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md): how backend and Flutter work together
   - [`docs/TEAM_WORKFLOW.md`](docs/TEAM_WORKFLOW.md): branches, pull requests, CI, resolving conflicts
   - [UI board](https://claude.ai/artifact/C5jiujr2ASCXQiREpHPCdW): every screen of the app (layout, colors, text, flows), nothing more and nothing less. Exported as plain files (HTML + PNG + images) in [`flutter/design/screens/`](flutter/design/screens/README.md). Endpoints per screen and the Patient Mode rules: [`flutter/AGENTS.md`](flutter/AGENTS.md) §1
   - [`docs/diagrams/`](docs/diagrams/README.md): architecture, ERD, sequences, state machines
   - [`docs/RESEARCH_PLAN.md`](docs/RESEARCH_PLAN.md): the research paper and experiments (gated memory, benchmark, recording protocol), run in parallel with the build (D32–D39)
   - [`docs/BACKEND_STUDY_GUIDE.md`](docs/BACKEND_STUDY_GUIDE.md): what the backend needs beyond the freeCodeCamp FastAPI course

---

## 3. Rules for everyone

1. **Ask before deciding.** Anything the spec doesn't already decide goes to the lead *before* it's built. That includes new libraries, folders, endpoints, tables, columns, screens, settings, and changes to a contract. Write the question down and propose 2–3 options with a recommendation; don't pick silently.
2. **Stay in your area.** A change touches one area: `backend-ai/`, `flutter/`, `ml/` or `hardware/`. If you need something from another area, ask its owner; don't edit their folder. Shared docs and the spec are edited only with the lead's approval.
3. **Build what's specified, nothing more.** Endpoints come from spec §7.2, screens from the UI board, and tables from spec §6. No extra features, fields or "nice to haves".
4. **One branch and one pull request per change.** Never push to `main`, and keep PRs small. CI must be green before merging. GitHub doesn't block red merges on this private repo, so this rule is enforced by the team. See [`docs/TEAM_WORKFLOW.md`](docs/TEAM_WORKFLOW.md).
5. **Contracts are shared property.** The REST API (spec §7.2) and the BLE protocol (spec §7.1) are changed **contract-first**: spec PR approved by the lead → implementation → consumer update. See [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md).
6. **Privacy is a requirement, not a feature.** Never log transcripts, names, faces or embeddings. Never commit secrets or connection strings. Never expose data outside the API's authorization (spec §9).
7. **Run your area's checks locally before pushing**, the same ones CI runs (listed in each `AGENTS.md`).

---

## 4. How the areas talk to each other

```
glasses (hardware/) ──BLE §7.1──> flutter/ (relay + UI) ──REST §7.2──> backend-ai/ ──> Supabase Postgres, S3, AI APIs
                                                                            │
                                                     loads exported models  ▼
                                                                          ml/models/
```

| Boundary | Contract | Owner of the contract |
|---|---|---|
| Flutter ↔ backend | REST `/api/v1` (spec §7.2), error shape §7.5, OpenAPI at `/docs` once the API runs | lead (backend) |
| Glasses ↔ Flutter | BLE GATT messages (spec §7.1) | lead + hardware + Flutter together |
| backend ↔ ml | Exported model files + model cards in `ml/models/`; shared preprocessing for the face pipeline (spec D14) | lead (AI) |

---

## 5. Open decisions (do not decide these, ask the lead)

| Topic | Question |
|---|---|
| ml ↔ backend packaging | How `backend-ai` imports the shared face preprocessing from `ml/` (local package install, copied module, or published wheel). The memory engine is decided (D38): edge part in `ml/edge/`, server part in `backend-ai/app/ai/` |
| Model files in git | Whether exported models (`*.onnx`, `*.tflite`) use Git LFS or are downloaded from S3 at build time |
| Team assignment | Names per track (spec §11) |
| Email verification | Whether email + password accounts must verify their email (link sent by AWS SES), or stay unverified |
| Google / Facebook timing | Decided in D26 but postponed: when to build it (needs the Google Cloud + Facebook app setup, plan step 3.0) |

---

## 6. Status

**Backend: live** at `https://remori-ai.duckdns.org` (API `/api/v1`, docs `/docs`) since 12 Oct 2026. Plan phases 0–6 done and deployed (12–13 Oct 2026): infrastructure, database (Supabase), auth (email + password), every endpoint the 42 screens need (AI stubs where models aren't ready), and background workers (Celery + Redis: alerts, retention, previews). Next: Phase 7, the ambient memory pipeline.
**Flutter, hardware, ml:** starting. The current step for each area is in its `AGENTS.md`. The contract between app and backend: [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md).
