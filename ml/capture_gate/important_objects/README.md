# Important-object detector: training guide (spec D42)

How the ml team builds the small detector that tells the glasses "keys, glasses, wallet, phone, pill box or stove in view": from public datasets and our own footage, through labelling and training, to a model the Pi runs on every frame.

**Owner:** Ahmed Mostafa (lead, AI) with the AI/ML track · **Spec:** [D42](../../../REMORI_SPEC.md) (extends D33) · **Status:** not started. Read this file top to bottom before starting.

---

## 0. In one minute

- **Why:** "Where did I put my keys?" is the weakest question type. The scene embedding the glasses compute every second barely notices small objects, so the moment the keys are put down is usually thrown away. This detector makes the glasses **keep that frame** (`gate_rule = 'important_object'`), and the 30-second look-back buffer keeps the frames just before it.
- **What:** a YOLO-class object detector, **6 classes**, small enough to run on a **Raspberry Pi Zero 2W** on **every frame (1 per second)** next to the face models.
- **It is one rule of the gate, not the whole gate.** Catching *any* useful frame is the job of all the rules together (face, text, medication, novelty, audio events, important objects) and of the **stage-2 classifier** ("is this frame worth keeping?" in general), plus the look-back buffer (spec D33, D42). This model only covers the six objects people most often lose or forget. Its `pill_box` class also serves the **medication rule**, so the Pi runs one model for both.
- **The detector only decides "keep this frame".** It doesn't need to say *where* the keys are or whether the stove is on: the kept frame goes to Gemini in the cloud, which describes it (phase 8.3). So **recall** (not missing a moment) matters far more than a perfect box.
- **Data, in this order:** start **now** with public datasets that already label these objects (LVIS, egocentric sets, §4.1–4.2); then **fine-tune and test** on a smaller set of our own glasses-view footage (§4.3), because the test must look like the real glasses.
- **Deliverables:** a trained model, an INT8 export in `ml/models/` with a model card, measured accuracy per object on our own footage, and the rule code in `ml/edge/`. Details in §11.

---

## 1. The six classes (a contract: names and ids never change)

Class ids are shared with the glasses' code, so their **order is fixed**. Adding a class later is a lead decision and a new model version.

| id | name | What counts | What doesn't |
|---|---|---|---|
| 0 | `keys` | a key, a bunch of keys, a key ring, a car key fob | a key-shaped toy, a lock on a door |
| 1 | `glasses` | a pair of glasses **not on anyone's face**: on a table, in a hand, in an open case, on a bed | glasses being worn (the patient's own, or a visitor's) |
| 2 | `wallet` | a wallet, a purse, a coin purse, a card holder | a handbag or backpack |
| 3 | `phone` | a mobile phone, in a hand or put down, screen on or off | a TV remote, a tablet, a landline phone |
| 4 | `pill_box` | any medicine container: a weekly pill organiser, a medicine box, a bottle, a blister strip | vitamins or food in jars, a tissue box |
| 5 | `stove` | a gas stove / cooktop (the burners area), any state | the oven door alone, a microwave, a kettle |

Why "glasses not worn": the useful question is "where did I put my glasses?". A visitor wearing glasses would fire the rule all day for nothing.

These six are what the model is **trained on and runs with**. Public datasets use their own names (`spectacles`, `cellular_telephone`, `medicine`…): they're mapped onto these six (§4.2), and everything else in those datasets is ignored.

---

## 2. The hard constraints (read before choosing anything)

| Constraint | Value | Consequence |
|---|---|---|
| Device | Raspberry Pi Zero 2W: 4 × Cortex-A53 at 1 GHz, **512 MB RAM** shared with everything | a "nano" model (≈1–3 M parameters), INT8 |
| Rate | **every frame, 1 per second** (D42) | detector + face detector + face embedder + frame embedder all fit in about 1 s. Target for the detector: **≤ 300 ms per frame**, **≤ 40 MB RAM** |
| If it doesn't fit | **lower the input size, never skip frames** (D42) | train at 320 × 320; keep 256 as the fallback |
| Camera view | from the eyes (egocentric), head moving, indoor light, often dim | prefer egocentric public data; fine-tune and **test on our own head-mounted footage**, with motion blur and low light |
| Objects | keys and wallets are **small** at 320 px | close-up *and* across-the-room views; report recall by object size (§8) |

The week-1 **hardware spike** (spec §12, step 0) measures the real speed on the Pi. Until then the numbers above are targets.

---

## 3. Decisions to record before training (ask the lead)

Getting and converting the public data and labelling (§4–§6) **don't depend on these**: start them now. Training waits for decision 1.

1. **Framework and licence.** All three are fine technically; the licence is what differs.

   | Option | Licence | Size | For us |
   |---|---|---|---|
   | **NanoDet-Plus-m (320)** | Apache 2.0 | ~1.2 M params | built for phone/ARM CPUs, very fast with NCNN; plainer tooling |
   | **YOLOX-Nano** | Apache 2.0 | ~0.9 M params | small and well documented; trains at 416 by default |
   | Ultralytics **YOLO11n** | **AGPL-3.0** | ~2.6 M params | best tooling and usually the best accuracy; fine for research, but a shipped product must publish its code or buy a licence |

   **Recommendation:** NanoDet-Plus-m-320 (licence-clean and the fastest on ARM). If its accuracy falls short of the targets in §8, compare YOLO11n on the same data and let the lead decide whether AGPL is acceptable for the project.

2. **Targets in §8**: agree on the recall and false-trigger numbers.
3. **Where the model file lives**: Git LFS or S3 (open decision in the root `AGENTS.md` §5).
4. **Dataset licences:** most public detection data is for research use (non-commercial). That's fine for the graduation project; list every dataset and its licence in the model card, as for the face model.

---

## 4. Get the data

Two sources, in this order: **public datasets now** (enough for a first model), then **our own footage** (smaller, to fine-tune and to test).

### 4.1 Public datasets

| Dataset | View | Our six | Licence | Use |
|---|---|---|---|---|
| **LVIS v1** (COCO images, 1,203 classes) | normal photos | **all six**: `key`, `spectacles`, `wallet`, `cellular_telephone`, `medicine` (fewer images), `stove`. Also `remote_control` and `sunglasses`: look-alikes for negatives | annotations CC BY 4.0, images COCO/Flickr | the main source for the first model |
| **EgoObjects** (Meta, 2023) | **egocentric**, 4 wearable devices, varied light, distance and motion | 368 classes: check which of our six are in it | research licence (read it before downloading) | the closest to our camera |
| **ADL** (Pirsiavash & Ramanan, 2012) | egocentric, 20 real homes, object tracks | household objects: check the mapping | research use | extra egocentric frames; low resolution |
| Roboflow Universe | mixed | community sets ("keys", "pill bottle", "wallet"…) | **differs per set**: check each | only to fill a weak class (often `pill_box`, `keys`) |

Never use a dataset whose licence you haven't read. Record each one (name, version, licence, how many images) for the model card.

### 4.2 Converting public data (and two traps)

1. **Map the names** onto our six. For LVIS: `key` → `keys`, `spectacles` → `glasses`, `wallet` → `wallet`, `cellular_telephone` → `phone`, `medicine` → `pill_box`, `stove` → `stove`. Drop every other class.
2. **Trap 1: LVIS doesn't label every object in every image.** For each image it lists the classes it checked: the annotated ones, `neg_category_ids` (checked, not present) and `not_exhaustive_category_ids` (only some instances boxed). An unchecked phone in an image becomes "background" in training and teaches the model to ignore phones. So **keep an image only if each of our six classes is either annotated exhaustively or listed in its `neg_category_ids`**. If that leaves too few images for a class, relax the rule for that class only, and note it.
3. **Trap 2: worn glasses.** LVIS `spectacles` includes glasses on faces, which our class excludes (§1). Import the `spectacles` images into CVAT and let a labeller delete the worn ones (it's quick).
4. Convert to **COCO JSON** with our six class ids (§1), keep the source of every image in its file name (`lvis_000123.jpg`, `ego_…`), and put the result in the private folder.
5. **Negatives:** add images where all six are confirmed absent (in `neg_category_ids`), especially kitchens, living rooms and the look-alikes (`remote_control`, tablets, `sunglasses` on faces).

### 4.3 Our own footage (smaller, but needed)

Public photos are not glasses-view: wrong angle, good light, objects centred. A model scored only on them looks better than it is. So we record **2–3 sessions per home** for two jobs: **fine-tuning** (a few hundred frames close most of the gap) and the **test set** (the scores that count are measured on our footage, §8).

**Setup**, the same as the benchmark, so the model sees what the glasses see:
- Phone or GoPro on a **head strap at eye level**, **1080p, 30 fps**, as in [RESEARCH_PLAN §5.2](../../../docs/RESEARCH_PLAN.md).
- Indoors, in prepared homes. **No bystanders**, signed consent from everyone on camera, code names in every file ([RESEARCH_PLAN §11](../../../docs/RESEARCH_PLAN.md)).

**Never train on benchmark footage.** The research benchmark measures how well Remori remembers. If the detector learns from the same videos, the benchmark is contaminated. So:
- Record **separate "detector sessions"** on different days from the benchmark sessions.
- Keep **at least one home** that appears **only** in the benchmark test, never in training.
- Name files so the source is obvious: `det_<home>_<date>_<n>.mp4` vs the benchmark's own names.

**What to film** (a shot list per session, ~20–30 min). For **each** of the six objects:
- **Put it down and pick it up** in 5–8 different places (table, bed, shelf, drawer, sofa, counter, near the door). This is exactly the moment the rule must catch.
- **Distances:** close (30–50 cm, in hand), mid (1 m, on a table), far (2–3 m, across the room).
- **Light:** daylight, lamp only, dim evening light. At least a third of the footage should be dim.
- **Hidden partly:** under papers, half in a bag, behind a cup.
- **Clutter:** on a busy table with similar things around.
- **Motion:** turning the head normally (the blur is real data, don't avoid it).
- **Variety:** at least 3–4 different sets of keys, glasses, wallets, phones and pill boxes across sessions, and every stove in every home.

Also film **hard negatives** (no target object, but easy to confuse): a TV remote, a tablet, a tissue box, a lighter, sunglasses on a face, a microwave, cutlery. And ordinary minutes with **nothing**: walking, sitting, watching TV.

### 4.4 Volume
| Stage | Data | Gives roughly |
|---|---|---|
| First model (weeks 1–2) | public data only (§4.1–4.2) | thousands of images; ≥ 400 instances per class after filtering |
| Fine-tuned model | + **4–6 own sessions** in **2 homes** | ~800–1,200 labelled own frames |
| Test set | **2–3 own sessions**, including the held-out home | ~400–600 labelled own frames, never trained on |

---

## 5. From video to frames worth labelling

For our own footage (and egocentric videos). Labelling every frame wastes time: neighbouring frames are almost identical. Sample, then remove near-duplicates.

```bash
# 2 frames per second, the long side at 1280 px (labels are scaled down later anyway)
ffmpeg -i det_homeA_2026-11-03_1.mp4 -vf "fps=2,scale=1280:-2" frames/det_homeA_2026-11-03_1_%05d.jpg
```

Then keep only frames that differ enough from the last kept one (a perceptual hash, e.g. `imagehash.phash`, with a Hamming distance ≥ 8 is a good start), plus **every** frame within ±2 s of a put-down or pick-up moment (those matter most). Aim for:
- **≥ 150 labelled own instances per class** for fine-tuning (public data supplies the bulk);
- **15–20 % of frames with no object at all** (negatives), so the model learns to stay quiet.

Keep the frame name → video + timestamp mapping, so any frame can be traced back to its session.

---

## 6. Labelling

### 6.1 Tool: CVAT
Use **CVAT** (free; app.cvat.ai, or self-hosted). Create one project, **"remori-important-objects"**, with the six labels in the order of §1. It imports and exports both COCO JSON (NanoDet, YOLOX) and YOLO text files (Ultralytics), so labelling doesn't depend on decision 1.

**Don't use Roboflow's free plan for our footage:** free projects are public, and our frames show people's homes and faces.

### 6.2 Rules (everyone labels the same way)
1. **Tight boxes** around the object only. Keys in a hand: box the keys, not the hand.
2. **Label every visible instance**, including small and far ones.
3. **Partly hidden:** label it if about a third or more is visible. Less than that: skip it.
4. **Blurred by motion:** label it if a person can still tell what it is.
5. **Reflections, photos of objects, objects on a TV screen:** don't label.
6. **When unsure, tag the image "check"** in CVAT instead of guessing; the reviewer decides.
7. A frame with **none** of the objects is still saved (an empty label file): it's a negative.
8. **Public images:** spot-check 5 % of each converted dataset against these rules (and remove worn glasses, §4.2). Their boxes were drawn by other people with other rules.

### 6.3 Quality control
- A **second person reviews 10 %** of each labeller's frames, and every "check" frame.
- Before fine-tuning, two labellers label the **same 100 frames** and compare. If they disagree on more than ~10 % of boxes, sharpen the rules above and fix the labels.

### 6.4 Privacy of the dataset
- Our frames show homes, family actors and sometimes faces: they're **personal data**.
- Store videos, frames and labels only in the team's **private Drive/S3 folder**. **Never in git** (`ml/README` rule 3), never in a public tool.
- Code names in file names; no real names, addresses or phone numbers in labels or notes.

---

## 7. Training

### 7.1 Two stages, and where the score comes from
1. **Stage 1, public data:** train on the converted public datasets (§4.1–4.2), starting from COCO-pretrained weights.
2. **Stage 2, fine-tune:** continue from the stage-1 model on our own **train** sessions mixed with some public images (about half and half), with a lower learning rate, so it adapts to glasses-view without forgetting.
3. **Test only on our own held-out sessions** (§4.3). Report the public validation scores too, but the §8 targets are judged on our footage.

### 7.2 Split our footage by session, not by frame
Frames from the same video look alike; if they land in both train and test, the scores lie. Split by **session**:

| Set | Share | Rule |
|---|---|---|
| train | ~60 % | most own sessions (stage 2) |
| val | ~15 % | whole sessions, for choosing epochs and the threshold |
| test | ~25 % | whole sessions, **including the held-out home** (§4.3); used once, at the end |

### 7.3 Where to train
A free **Kaggle** or **Google Colab** GPU is enough for a nano model (a few hours per stage). Keep the data in the private folder and mount it; don't upload our footage anywhere public.

### 7.4 Settings that matter
- **Start from COCO-pretrained weights** (transfer learning). COCO already knows `cell phone` and `oven`, which helps.
- **Input size 320** (also try 416 to see the accuracy cost of going small).
- **Augmentations:** mosaic, scale, small rotations (±10°), brightness and colour jitter, **motion blur** and **darker images** (head movement and dim rooms are our reality), horizontal flip.
- **Epochs:** stage 1: 150–300 with early stopping on validation mAP; stage 2: 30–80 at a lower learning rate.
- **Class balance:** if one class has far fewer instances (often `pill_box` from LVIS, or `keys`), add data for it (a Roboflow set, more own footage) rather than relying on weights.

### 7.5 Starting commands (adapt paths; check each repo's README for its current version)

NanoDet-Plus (recommended):
```bash
git clone https://github.com/RangiLyu/nanodet && cd nanodet && pip install -r requirements.txt && python setup.py develop
# copy config/nanodet-plus-m_320.yml → config/important_objects.yml, then set:
#   num_classes: 6, class_names: [keys, glasses, wallet, phone, pill_box, stove]
#   data.train / data.val: COCO JSON + image folders (stage 1: converted public data; stage 2: + own train sessions)
python tools/train.py config/important_objects.yml
```

YOLOX-Nano:
```bash
git clone https://github.com/Megvii-BaseDetection/YOLOX && cd YOLOX && pip install -v -e .
# write exps/important_objects.py based on exps/example/custom (num_classes = 6, COCO paths)
python tools/train.py -f exps/important_objects.py -d 1 -b 64 --fp16 -c yolox_nano.pth
```

Ultralytics YOLO11n (only after the licence decision, §3):
```bash
pip install ultralytics
yolo detect train data=important_objects.yaml model=yolo11n.pt imgsz=320 epochs=200 batch=64
```

Record every run: data version, stage, settings, scores, and the commit of the training code. A table in the team sheet is enough.

---

## 8. Evaluation (what "good enough" means)

mAP alone doesn't tell us whether the gate works. Report all of these on the **test** set (our own held-out footage, §7.1):

| Metric | Why | Proposed target (agree with the lead) |
|---|---|---|
| **Per-class recall** at the chosen threshold | a missed object = a moment not kept | ≥ 0.80 for every class |
| **Moment recall**: of all put-down / pick-up moments, how many have at least one detected frame within ±2 s | what the gate really needs (the look-back buffer covers the seconds before) | ≥ 0.90 |
| **False triggers per hour** of footage with no target object | each false trigger keeps 1 + 3–5 frames, uploads them and costs a Gemini call | ≤ 10 per hour |
| mAP@0.5 per class | standard, for comparing runs | report it, no target |
| Recall by object size (small / medium / large) | keys and wallets are small | report it; small objects must not be far below the rest |
| Results per lighting (bright / dim) | dim rooms are common | report it |
| Stage 1 vs stage 2 on the same test set | shows how much our own footage adds | report it |

Pick the score threshold on the **val** set so that recall meets the target, then check false triggers. A slightly lower threshold is fine: Gemini filters the extra frames later.

Look at the **misses** (frames from the test set where the model found nothing): they tell you what to record or add next. Then repeat §4–§7.

---

## 9. Export for the Pi

1. **ONNX** export at the chosen input size (opset 12 or newer), simplified (`onnxsim`).
2. **INT8** quantization with ~200 calibration frames taken from **train**, mostly our own footage (never test): ONNX Runtime static quantization, or NCNN's int8 tools.
3. **Check the accuracy after INT8** on the test set: it should drop by no more than ~2 recall points. If it drops more, use more calibration frames or keep some layers in FP16.
4. **Measure on a real Pi Zero 2W** together with the hardware team: milliseconds per frame, peak RAM, CPU temperature after 30 minutes, power. Try **NCNN** and **onnxruntime**; the faster one wins. If it misses ≤ 300 ms per frame, try input 256 (D42: lower the size, not the rate).

---

## 10. Hand-over to the glasses

- **Model file** → `ml/models/important_objects/` (or S3, per decision 3) with its **model card** (§12). Consumers pin a version.
- **Rule code** → `ml/edge/` (D38): a pure Python function with no camera or file I/O, for example `detect(frame) -> [(class_id, score, box)]`, `fires(detections) -> bool` for the important-object rule, and the medication rule reading the same detections (`pill_box`). Thresholds from §8. The Pi runtime (`hardware/pi`) and the research replay both import it, so the paper tests exactly what the glasses run.
- **Kept frames** are sent with `gate_rule = "important_object"` (or `"medication"` for a `pill_box`), spec §7.1. The backend already stores whatever rule the glasses send.

---

## 11. Done when

- [ ] Public datasets chosen, licences read and listed, converted to our six classes with the LVIS filter (§4.2)
- [ ] A stage-1 model trained on public data
- [ ] Ethics/consent confirmed for our own sessions (RESEARCH_PLAN §11)
- [ ] Own footage recorded per §4.3, kept separate from the benchmark, one home held out
- [ ] ≥ 150 labelled own instances per class for fine-tuning, a labelled own test set, 10 % reviewed
- [ ] Framework decision recorded (§3)
- [ ] A fine-tuned model meeting the §8 targets on our own test set, or a written list of where it falls short
- [ ] INT8 export measured on a Pi Zero 2W (ms, RAM, °C)
- [ ] Model card in `ml/models/`, rule code in `ml/edge/`
- [ ] Results table (all §8 metrics) shared with the lead

---

## 12. Model card template

Copy into `ml/models/important_objects/MODEL_CARD.md` for every exported version:

```markdown
# important_objects v<N>

- Date, trained by, training-code commit
- Framework + licence: (e.g. NanoDet-Plus-m, Apache 2.0)
- Classes (fixed order): 0 keys, 1 glasses, 2 wallet, 3 phone, 4 pill_box, 5 stove
- Input: <W>×<H> RGB, preprocessing (mean/std, letterbox), output format
- Files: <name>.onnx (FP32), <name>_int8.onnx / NCNN files, SHA-256 of each
- Data: public datasets (name, version, licence, images used), own sessions and homes,
  frames and instances per class, split
- Test results (own held-out footage): per-class recall at threshold <t>, moment recall,
  false triggers/hour, mAP@0.5, recall by size and lighting; stage 1 vs 2; FP32 vs INT8
- On the Pi Zero 2W: ms per frame, peak RAM, temperature after 30 min, runtime (NCNN / onnxruntime)
- Known weaknesses: (e.g. keys under 20 px, dark bedrooms)
```

---

## 13. Who does what (suggested)

| Role | Tasks |
|---|---|
| Data lead | public datasets: licences, download, conversion and the LVIS filter (§4.1–4.2) |
| Recording lead | consent, own sessions per §4.3, file naming, held-out home |
| Labellers (2–3) | CVAT per §6, cross-review, the worn-glasses clean-up |
| Trainer | splits, both training stages, the results table |
| Evaluator | §8 metrics, miss analysis → what to add next |
| With the hardware team | §9 measurements on the Pi, the runtime choice |

A realistic pace: **week 1** public data converted + stage-1 model, consent and CVAT set up · **week 2** own sessions recorded and labelled, stage-2 fine-tune · **week 3** test on our footage, fix the misses, export, measure on the Pi.

---

## 14. Common mistakes

- **Train/test from the same video.** Split by session (§7.2).
- **Benchmark footage in training.** Never (§4.3).
- **LVIS images with unchecked objects.** They teach the model to ignore our classes: filter them (§4.2).
- **Scoring on public data only.** It flatters the model: the targets are judged on our own footage (§7.1).
- **Thousands of near-identical frames.** De-duplicate (§5).
- **Only bright, close, centred objects.** The real world is dim, small and blurred (§4.3); public photos are mostly the former.
- **Changing class names or order.** The glasses' code depends on them (§1).
- **Judging by mAP alone.** The gate needs moment recall and few false triggers (§8).
- **Personal data in git or public tools.** Private folder only (§6.4).
