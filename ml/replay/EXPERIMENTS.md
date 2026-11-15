# Replay experiments: the detector gate, text, and memory search (Nov 2026)

What we tested on SuperMemory-VQA between 12 and 15 Nov 2026, what we found, what we changed, and what's still open. Every number here was measured; estimates are marked as such. Setup and commands: [`README.md`](README.md). Research plan: [`docs/RESEARCH_PLAN.md`](../../docs/RESEARCH_PLAN.md).

**In one paragraph:** the whole pipeline works end to end and scores **38–41 %** on one session (32 questions), in the range of published baselines with a model of the same size (Video-RAG 45.5 %, EgoButler 39.1 % with Qwen-3-VL 30B). The colleague's 87-class detector (v2, YOLO26n) adds little as a capture gate on head-mounted footage (+1 question). The biggest finding was a **memory search bug**: the photo review *had* read "Luna Pizza Kitchen" on the pizza box, but search never surfaced it. Fixed, the two pizza-name questions went from wrong to right. The next big gap is the **visual memory tier** (D41), not built yet.

---

## 1. Setup (the same for every run)

| | |
|---|---|
| Data | SuperMemory-VQA, Person 10, session 3: 16 min of Meta Aria video (1408 × 1408, fisheye), 944 frames at 1 fps, 17 conversation events from the released transcript |
| Questions | 32: evidence only in this session, plus the unanswerable ones asked in it. 12 object location, 7 visual recall, 4 timeline, 4 conversational, 3 intent, 2 in-context |
| Models | Groq **Qwen3.6-27B** for photo review, consolidation, /assist and the judge; **Voyage** text embeddings; MobileFaceNet faces |
| Code | `main` as of 15 Nov (assist prompt **v4**, Abdelrahman's #101), local Postgres (migration 0007) |
| Scoring | /assist answers freely; a judge maps the answer to one of the 4 choices; multiple-choice accuracy. Structured memory only (`--no-flat`) |
| Cost | photo reviews are cached by image (`~/.cache/remori/supermemory/reviews/`): run A paid 263 reviews, B 20 new, C none; the rest is questions + consolidation |

**Not the full designed system:** the gate's novelty and the 30 s look-back use a **colour histogram** (48 numbers: how much of each colour, brightness and saturation) as a stand-in for the frame embedding (D34). The **visual tier** (D41: scene segments, frame vectors, two-stage search) isn't built, so memory is text only: what speech and the photo review wrote.

## 2. Results

| | A: novelty gate | B: + detector + look-back | C: B + search fix |
|---|---|---|---|
| **Overall** | 38 % (12/32) | 41 % (13/32) | **41 % (13/32)** |
| answerable / unanswerable | 8/28 · 4/4 | 9/28 · 4/4 | 9/28 · 4/4 |
| object location (12) | 5 | 6 | 5 |
| visual recall (7) | 0 | 0 | **2** |
| timeline (4) | 2 | 2 | 1 |
| conversational (4) | 3 | 3 | 3 |
| intent (3) | 1 | 1 | 1 |
| in-context (2) | 1 | 1 | 1 |
| frames reviewed | 263 | 283 | 283 (cached) |

Questions that changed:
- **B gained** "where did Person D grab the Diet Coke cans?" → *the fridge*: one of the detector's extra frames (look-back around an object trigger) showed the cans by the refrigerator.
- **C gained both "name of the pizza place printed on the box?"** → *"The pizza box said "Luna Pizza Kitchen" on it."* The target of the search fix (§5).
- **C lost** the Diet Coke question (back to "in the kitchen") and the phone timeline question ("did I try to take a photo before or after being told not to use my phone?" → "no record of being told"). **Not yet explained:** run-to-run variation of the answering model (1–2 of 32 moving is within that noise) or the longer photo sentences pushing a conversation down the ranking. **To do:** rerun C once; if the same two fail again, it's the fix.

With 32 questions one answer is ~3 points: these runs show *what* fails and *why*, not a precise score.

## 3. The detector as a capture gate (colleague's v2)

Model: `ml/remori_objects_v2/remori_objects_v2.onnx` (YOLO26n, 87 classes, 320 px; model card in that folder), run on every frame with the gate rules in [`ml/edge/important_objects.py`](../edge/important_objects.py): important object (keys, glasses not worn, wallet, phone, stove), medication (pill box), text; plus the 30 s look-back ([`ml/edge/lookback.py`](../edge/lookback.py)). **41 ms per frame** on a laptop CPU (onnxruntime).

**At the thresholds in its `thresholds.json` (0.05 for most classes, chosen for recall), it fires on 676 of 944 frames**: a gate that keeps everything. Frames firing per rule and threshold:

| Rule | 0.05 | 0.15 | 0.25 | 0.35 |
|---|---|---|---|---|
| text | 645 | 503 | 340 | 88 |
| important object | 72 | 13 | 2 | 0 |
| medication (pill box) | 0 | 0 | 0 | 0 |

- Keys never reach 0.35 in 16 minutes; glasses not worn: 0; pill box: 0. The same pattern as the model card's own per-source table (keys 0.01, pill box 0.00 recall on ordinary photos): the high scores come from Roboflow close-ups. This footage is fisheye and dim, unlike any training photo.
- The 13 object frames at 0.15: a phone lying on the blanket (~0.1–0.2, real), a pair of glasses on a face that slipped past the worn test, and a false "stove" on a person by the kitchen.

## 4. Text

### 4.1 One T-shirt fired the text rule hundreds of times
At 0.35, almost all 88 text frames were **the same "PLANT YOUR…" print on one person's shirt**. Fixes in the gate (no model change), measured at threshold 0.25:

| Version | Text frames |
|---|---|
| raw | 340 |
| clothing filter, with an exception for "a hand next to the text" | 142 |
| + "already seen" memory (64-bit difference hash of the text crop, 2 min) | 77 |
| exception narrowed to "a hand covers ≥ 10 % of the text" | 29 |
| **text inside another person's box = clothing, no hand exception** | **2** (both the blanket's pattern) |

Why the hand exception failed: in 421 of 427 cases the shirt's wearer had hands clasped or holding a plate in front of the print. Why dropping it loses little: text the *wearer* holds isn't inside anyone's box (the wearer isn't in their own view). The memory added little at 0.35 because the crop's fingerprint changes as the head moves.

### 4.2 The real pizza-box text is never found by the detector
With the shirt gone, text fires on 2 false frames: **the detector doesn't see the pizza box's print at any threshold.** A dedicated text detector does: **PP-OCRv4 mobile** (`ch_PP-OCRv4_det_infer.onnx`, 4.7 MB, via `rapidocr_onnxruntime`) found text regions in **20 of the 22 seconds** where the box is visible (374–395), and its reader got **"Luna" (0.90–0.96)** at second 386 (the answer is "Luna Pizza Kitchen"). "Pizza Kitchen" is too small even in the full 1408 px frame. Detection alone: **130 ms per frame at 640 px** on a laptop (estimate on a Pi Zero 2W: ~1.7–2 s, too slow for every frame). Proposed as a temporary stand-in for the text class; **not wired in**.

### 4.3 The reading wasn't the problem: search was
The novelty gate had already kept second 386, and the cached photo reviews show the review **did** read it: two reviews tag "Luna" and record the box's state as `held in hands, text: "Luna Pizza Kitchen"`. It was lost in search (§5).

## 5. The memory search fix (backend)

Two causes, both in how memory is searched, not in what was stored:
1. **"Last seen" crowded it out.** The pizza box appears in **86** reviewed photos. A question about an object read only its **20 newest sightings** (`PER_RANKING`): all "open on the floral blanket" from the meal. The two "Luna" sightings (seconds ~380–393) never reached /assist, which honestly answered "the name wasn't recorded".
2. **Printed text wasn't in the searchable sentence.** A photo moment rendered as "captured a special moment in the living room: pizza, Luna, …" (up to 3 tags); the object states weren't included.

Changes ([`render.py`](../../backend-ai/app/ai/rag/render.py), [`embedding_service.py`](../../backend-ai/app/services/embedding_service.py), [`retriever.py`](../../backend-ai/app/ai/rag/retriever.py)):
- A photo moment's sentence lists up to 3 objects the review saw, with their state, **printed text first**: *"…: pizza, pizza box (held in hands, text: "Luna Pizza Kitchen"), …"*.
- Sightings: up to 300 newest are read, **repeats of one state collapse** to the newest, and **when the question asks about a name, writing or text** (English or Arabic words), sightings that quote printed text come first.
- Tests: 2 new (one rebuilds the 40-sightings case); all 387 backend tests pass.

Result: run C, both pizza-name questions right (§2).

## 6. Hands

The detector's best class on this footage (EgoHands was filmed with head-mounted glasses). But as a raw signal it floods:

| Hand rule (measured, **not built**) | Frames with a hand | Boxes per frame |
|---|---|---|
| as exported (0.1, no NMS) | 872 / 944 | 24.8 |
| + NMS | 872 | 5.1 |
| + threshold 0.4 | 641 | 1.3 |
| + wearer's hands only (not inside another person's box) | **255** | **0.3** |

A hand-object rule (a hand touching an object) didn't catch the pizza box: it isn't a class the model knows. Object tracking (ByteTrack) was discussed and postponed: it needs 10–30 fps; the glasses send 1 fps.

## 7. Compared with the paper

SuperMemory-VQA ([arXiv 2606.00825](https://arxiv.org/abs/2606.00825)), 4-way accuracy over all 4,853 questions:

| Backbone | Video-RAG | EgoButler |
|---|---|---|
| Gemini-3-Flash | **61.0 %** | 54.1 % |
| GPT-5.4 | 52.3 % | 48.0 % |
| Qwen-3-VL 30B (closest to ours) | 45.5 % | 39.1 % |
| Qwen-3-VL 8B | 41.8 % | 38.8 % |

Not like for like yet: Video-RAG builds its context **at question time** from the stored video (32 frames of the most relevant 30 min, Whisper transcript, **EasyOCR text**, detections); Remori must choose frames in real time and keeps only its memory. Their model ranks the 4 choices directly; ours answers freely and a judge maps it (stricter). And our 32 questions are one session against their 4,853.

## 8. Lessons

- **Look at the frames before trusting a rule.** Every gate number above changed meaning once we looked at what fired (a T-shirt, a blanket).
- **Follow one failed question through the whole chain** (gate → review → memory → search → answer). The pizza case looked like a detector problem, then a reading problem; it was a search problem.
- **Check the cache before quoting a cost.** The review cache was empty before these runs (estimates were too low once); it's filled now.
- One session is a probe, not a measurement.

## 9. Next

1. Rerun C once to separate noise from the fix's side effects (questions only).
2. Run all of Person 10's sessions for a number worth comparing (cost estimate first).
3. **Build the visual tier (D41)**: per-frame embeddings, scene segments with 3 vectors, two-stage search in /assist. Expected to help object location and visual questions, where frames weren't kept.
4. Gate rules still to build in `ml/edge`: the hand rules of §6; PP-OCR as the text stand-in (§4.2) if the lead wants it.
5. Own glasses footage (recorded with consent) for the detector's stage 2 and a real test set.

## 10. Reproduce

```bash
docker compose -f backend-ai/docker-compose.dev.yml up -d db
cd backend-ai
export DATABASE_URL=postgresql+psycopg://remori:remori@localhost:5434/remori_test
# frames each gate would keep + estimated cost, no API calls
.venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3 --plan --gate both --text-threshold 0.25 --object-threshold 0.15
# A: novelty only
.venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3 --gate novelty --no-flat
# B / C: novelty + detector + look-back (C = with the search fix in the code)
.venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3 --gate both --text-threshold 0.25 --object-threshold 0.15 --no-flat
```

Results JSON (per question, with answers) and logs stay in `~/.cache/remori/supermemory/` (research data: never in git). The detector file is the colleague's `ml/remori_objects_v2/remori_objects_v2.onnx` (not in git until the model-file decision).
