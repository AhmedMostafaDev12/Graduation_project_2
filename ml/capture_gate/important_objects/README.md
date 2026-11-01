# Important-object detector: training guide (spec D42)

How the ml team builds the small detector the glasses run on every frame: **COCO's 80 everyday objects plus Remori's own classes** (keys, glasses, wallet, pill box, stove, text, hand). It goes from public datasets and our own footage, through labelling and training, to a model the Pi runs on every frame.

**Owner:** Ahmed Mostafa (lead, AI) with the AI/ML track · **Spec:** [D42](../../../REMORI_SPEC.md) (extends D33) · **Status:** design decided (1 Nov 2026, §3). Ready to run: [`train_yolo_kaggle.ipynb`](train_yolo_kaggle.ipynb) (Kaggle, free GPU) with [`prepare_dataset.py`](prepare_dataset.py). The merge was tested locally on LVIS val; the parts that need the GPU or the large downloads (WholeBody, EgoHands, CRAFT, the yolo11n auto-labels) run for the first time on Kaggle. Spec D42 still lists six classes and is updated next. Read this file top to bottom before starting.

---

## 0. In one minute

- **Why:** "Where did I put my keys?" is the weakest question type. The scene embedding the glasses compute every second barely notices small objects, so the moment the keys are put down is usually thrown away. This detector makes the glasses **keep that frame**, and the 30-second look-back buffer keeps the frames just before it.
- **What:** **one** YOLO11n model with **87 classes**. It **keeps** the 80 COCO classes the pretrained model already knows (person, cup, bottle, chair, phone, laptop, fridge…) and **adds** 7 of ours: `keys`, `glasses` (not worn), `wallet`, `pill_box`, `stove`, `text`, `hand`. It's small enough for a **Raspberry Pi Zero 2W** on **every frame (1 per second)** next to the face models.
- **Why one merged model, not a 6-class one:** the six objects were meant to *enhance* a general detector, not replace it. A model fine-tuned on new classes alone **forgets** the 80 it knew. So the training data always keeps COCO images with their full COCO labels (the **reminder set**, §4.2).
- **Why `text` and `hand`:** many benchmark questions failed on **writing** (a pizza box, a label) and on **moments of handling** (taking cans from the fridge). A `text` box keeps the frame *and* shows where the text is, so a zoomed crop can be sent for reading. A `hand` box overlapping an object marks a pick-up or put-down.
- **It's the eyes of several gate rules, not the whole gate.** The detector only says what is in view. The rules in `ml/edge/` decide "keep this frame" (§10), together with the face, novelty and audio rules, the **stage-2 classifier** and the look-back buffer (spec D33, D42). It doesn't need perfect boxes. The kept frame goes to the cloud review, which describes it (phase 8.3). So **recall** (not missing a moment) matters far more than box precision.
- **Data, in this order:** public datasets **now** (COCO, LVIS, COCO-Text, COCO-WholeBody, EgoHands, §4); then **fine-tune and test** on a smaller set of our own glasses-view footage (§4.4), because the test must look like the real glasses.
- **Deliverables:** a trained model, an INT8 export in `ml/models/` with a model card, measured accuracy on our own footage, and the rule code in `ml/edge/` (§11).

---

## 1. The classes (a contract with the glasses)

Class ids are shared with the glasses' code, so their **order is fixed**. Adding or changing a class is a lead decision and a new model version.

**Ids 0–79: COCO's 80 classes, in the standard order** (the same as `yolo11n.pt`, so `person` = 0, `cell phone` = 67, `oven` = 69…). Their definitions are COCO's.

**Ids 80–86: ours.**

| id | name | Source of labels | What counts | What doesn't |
|---|---|---|---|---|
| 80 | `keys` | LVIS `key` | a key, a bunch of keys, a key ring, a car key fob | a key-shaped toy, a lock on a door |
| 81 | `glasses` | LVIS `spectacles` | a pair of glasses **not on anyone's face**: on a table, in a hand, in an open case, on a bed | glasses being worn (the patient's own, or a visitor's) |
| 82 | `wallet` | LVIS `wallet` | a wallet, a purse, a coin purse, a card holder | a handbag or backpack (those are COCO's `handbag`, `backpack`) |
| 83 | `pill_box` | LVIS `medicine` | any medicine container: a weekly pill organiser, a medicine box or bottle, a blister strip | vitamins or food in jars, a tissue box |
| 84 | `stove` | LVIS `stove` | a gas stove / cooktop (the burners area), any state | the oven door alone (COCO `oven`), a microwave, a kettle |
| 85 | `text` | COCO-Text v2 + auto-labels (§4.2 step 5) | a **legible** region of writing: a word or line on packaging, a label, a sign, a page, a screen | illegible scribbles, text too small to read even in a zoomed crop |
| 86 | `hand` | COCO-WholeBody + EgoHands (§4.2 step 6) | a human hand from the wrist to the fingertips, the wearer's own or another person's, empty or holding something | an arm without a visible hand, a glove lying alone |

- **Phone is not a new class:** COCO's `cell phone` (67) is our phone. That's why it's 87 and not 88.
- **Why "glasses not worn":** the useful question is "where did I put my glasses?". A visitor wearing glasses would fire the rule all day for nothing.
- **Medication:** `pill_box` also serves the **medication rule**, so the Pi runs one model for both.
- Public datasets use their own names (`spectacles`, `medicine`…). They're mapped onto these ids (§4.2), and every other class in those datasets is ignored.

---

## 2. The hard constraints (read before choosing anything)

| Constraint | Value | Consequence |
|---|---|---|
| Device | Raspberry Pi Zero 2W: 4 × Cortex-A53 at 1 GHz, **512 MB RAM** shared with everything | a "nano" model (≈ 2.6 M parameters), INT8. Going from 80 to 87 classes adds almost nothing (only the last layer grows) |
| Rate | **every frame, 1 per second** (D42) | detector + face detector + face embedder + frame embedder all fit in about 1 s. Target for the detector: **≤ 300 ms per frame**, **≤ 40 MB RAM** |
| One model | text and hands come from the **same** model, not a second one | a second detector per frame (e.g. a separate text model) doesn't fit next to the face models |
| If it doesn't fit | **lower the input size, never skip frames** (D42) | train at 320 × 320; keep 256 as the fallback |
| Camera view | from the eyes (egocentric), head moving, indoor light, often dim | use egocentric public data where it exists (EgoHands); fine-tune and **test on our own head-mounted footage**, with motion blur and low light |
| Objects | keys, wallets and text are **small** at 320 px | close-up *and* across-the-room views; report recall by object size (§8) |

The week-1 **hardware spike** (spec §12, step 0) measures the real speed on the Pi. Until then the numbers above are targets.

---

## 3. Decisions

### 3.1 Decided (1 Nov 2026, lead)

| # | Decision | Why |
|---|---|---|
| 1 | **Ultralytics YOLO11n** for stage 1 | fastest to train and export; AGPL-3.0 accepted for the graduation project. NanoDet-Plus-m (Apache 2.0) stays the licence-clean option to compare later (§7.5) |
| 2 | **One merged 87-class model**: COCO 80 + keys, glasses, wallet, pill_box, stove + text + hand (§1) | the six were meant to extend a general detector; one model per frame fits the Pi |
| 3 | **Reminder set** (option A): ~5,000 extra COCO images with their full COCO labels in training | measured: our LVIS images cover the household classes well but **18 of 80 COCO classes have fewer than 10 images** (§4.3). Without the reminder set those are forgotten |
| 4 | **Text from COCO-Text, gaps auto-labelled** (option A): where COCO-Text doesn't cover an image, a ready text detector (EasyOCR's CRAFT, on the Kaggle GPU) draws the text boxes | measured: COCO-Text covers only **31 %** of our LVIS images and **17 %** of the val set with the reminder. The rest would teach "text = background" |
| 5 | **Hands from EgoHands (main) + COCO-WholeBody (for the COCO photos)** | EgoHands is filmed with **Google Glass**, our viewpoint. COCO-WholeBody labels the hands **in our COCO photos**, which contain people about 70 % of the time; unlabelled, those hands would teach "hand = background" |
| 6 | **Hand counts are measured in the Kaggle notebook**, before training, not assumed | COCO-WholeBody doesn't publish how many valid hand boxes fall in our subset (§4.3) |
| 7 | **Public data first, own footage after**; never record before the public model exists | public data gives the first model now; our footage fine-tunes and tests it (§4.4) |

### 3.2 Still open (ask the lead)

1. **Targets in §8**: agree on the recall, false-trigger and "no forgetting" numbers.
2. **The keep rules in §10** beyond "an important object or text is visible": *a new object appears* and *a hand touches an object* are proposed, not decided.
3. **Where the model file lives**: Git LFS or S3 (open decision in the root `AGENTS.md` §5).
4. **Spec D42 update** with the 87-class list (a contract change: spec first, then code).

**Dataset licences:** most of this data is for research use (COCO-WholeBody is explicitly non-commercial). That's fine for the graduation project. Every dataset and its licence goes in the model card (§12).

---

## 4. Get the data

Two sources, in this order: **public datasets now** (enough for a first model), then **our own footage** (smaller, to fine-tune and to test).

### 4.1 Public datasets (in use)

| Dataset | What it gives us | Images | Licence | Role |
|---|---|---|---|---|
| **COCO 2017** (instances) | boxes for the **80 COCO classes** (ids 0–79) | 118K train + 5K val | annotations CC BY 4.0; images Flickr licences (research use) | the 80-class labels on every COCO photo we use, and the **reminder set** |
| **LVIS v1** | boxes for keys, spectacles, wallet, medicine, stove (ids 80–84) on **COCO's own photos** (same image ids) | ~100K train + ~20K val | CC BY 4.0 | the source of our five object classes |
| **COCO-Text v2** | text boxes on COCO photos, marked legible / illegible | 53,686 images, 201K boxes (81K legible) | CC BY 4.0 | `text` (85) where it covers an image |
| **COCO-WholeBody** v1.0 | a left-hand and right-hand box for each **keypoint-annotated person** in COCO, valid only when the hand is clear enough to place keypoints | 200K images, 250K people | CC BY 4.0, **research and non-commercial only** | `hand` (86) on our COCO photos |
| **EgoHands** | hand polygons, the wearer's vs the other person's, left and right | 48 Google Glass videos, **4,800 frames, 15,000+ hands** | CC BY 4.0 | `hand` (86) from **our viewpoint** |

**Where each comes from** (the notebook fetches them; nothing goes through your laptop):
- LVIS, COCO annotations, COCO-Text: their official download links.
- COCO-WholeBody: the official Google Drive files (from its GitHub page). If Drive refuses (its daily download limit), the train file falls back to a Hugging Face mirror (`hngan/cocowholebody`); otherwise re-run later.
- EgoHands: its original link is dead (it redirects to the lab's home page). A complete copy of the original release (48 folders × 100 frames + `polygons.mat`, checked by its file list) is on Kaggle as **`himaniishah/egohands`**: add it as a notebook **input**.
- COCO photos: one by one from `images.cocodataset.org`, only the ones we use.

Tools used to fill gaps (not datasets): **EasyOCR's CRAFT** text detector (auto-labels `text`) and **stock `yolo11n.pt`** (auto-labels the 80 COCO classes on EgoHands frames, which have no COCO labels).

**Later, if a class stays weak:** EgoObjects (Meta, egocentric, 368 classes; research licence: read it first), ADL (egocentric, 20 homes), and Roboflow Universe sets (licence differs per set). Never use a dataset whose licence you haven't read.

### 4.2 Building the merged dataset, step by step

Everything below runs in the Kaggle notebook. **LVIS, COCO, COCO-Text and COCO-WholeBody all label the same COCO photos**, joined by the COCO **image id**. EgoHands is the only source with other photos.

1. **Pick the images with our objects (LVIS).** LVIS doesn't check every class in every image: for each image it lists the checked classes (annotated, `neg_category_ids` = checked and absent, `not_exhaustive_category_ids` = only some instances boxed).
   - A strict rule ("all five of ours checked") leaves **zero images** (measured), so the practical rule is: keep an image when **every one of our classes labelled in it is labelled exhaustively**. Our other classes are unchecked there and may rarely appear unlabelled (accepted noise).
   - Phone is not taken from LVIS: COCO's `cell phone` labels it (step 2).
   - About 15 % extra **negatives**: images where LVIS checked our classes absent.
   - Measured on LVIS val: **591 images with our objects + 104 negatives = 695 kept**. LVIS train gives about 5× more; the script prints the exact counts.
2. **Add the COCO labels (ids 0–79)** to each image, by image id (every LVIS image is found in COCO). "Crowd" boxes (dense groups COCO doesn't box one by one) are skipped.
3. **Remove worn-glasses boxes.** A `spectacles` box whose centre lies in the top 35 % of a COCO `person` box is treated as worn: **its box is removed and the photo kept**. Worn glasses aren't our class, so leaving them unlabelled teaches the model **not** to fire on faces. (Measured on LVIS val: 412 boxes removed. An earlier draft dropped the whole photo, which threw away 288 of 695 images.) Labellers spot-check what the rule misses (§6.2).
4. **Remove double labels.** Some objects get two labels from two datasets: a cooktop is COCO `oven` and LVIS `stove`; a pill bottle is COCO `bottle` and LVIS `medicine`. When a box of ours (80–84) and a COCO box overlap with **IoU > 0.7**, keep **ours** (the more specific one) and drop the COCO box. Measured on LVIS val: 131 COCO boxes dropped. Lower overlaps stay (an oven door under a cooktop is both).
5. **Add `text` (85).**
   - Images covered by COCO-Text: its **legible** boxes become `text`; illegible ones are dropped.
   - Images not covered (**83 %** of the val set, reminder included) and every EgoHands frame: **CRAFT** auto-labels the text.
   - From both sources, boxes lower than **1.5 % of the image height** are dropped: too small to read.
   - Spot-check auto-labels (§6.2): they're a machine's guess.
6. **Add `hand` (86).**
   - COCO photos: COCO-WholeBody's **valid** left and right-hand boxes.
   - EgoHands frames: the mask of each hand → its bounding box.
   - Hands of people COCO didn't annotate with keypoints (usually small, far people) stay unlabelled: accepted noise. The notebook prints how many COCO photos with a person got at least one hand box.
7. **Label the EgoHands frames' other classes.** They have only hands. The stock `yolo11n.pt` auto-labels the 80 COCO classes on them (score ≥ 0.5), and CRAFT labels their text (step 5). Our five LVIS classes stay unlabelled there (rare in those card and board games).
8. **Add the reminder set:** ~5,000 random COCO images (4,500 train + 500 val) that aren't already in the set and have none of our five labelled, with all their labels (COCO + text + hands, steps 2–6). The script prefers images where LVIS checked our classes absent, so they double as **negatives** for ours. (In practice it picks them first; on LVIS val all 500 were such images.)
9. **Split** (§4.5) and **write** the YOLO files and the manifest (§5). If one of our classes has **fewer than 50 training images**, the script stops with "STOP, tell the lead". `--accept-low-counts` overrides it, only with the lead's OK.

The script is [`prepare_dataset.py`](prepare_dataset.py). The notebook contains a copy and runs it. Quick local test without a GPU: `python prepare_dataset.py --out test --split val --limit 30 --skip wholebody,egohands,auto`.

### 4.3 What the numbers say (measured or published, not assumed)

| Check | Result | Consequence |
|---|---|---|
| LVIS strict rule (all five of ours checked) | **0 images** | practical rule (§4.2 step 1) |
| LVIS val, practical rule (five LVIS classes; phone from COCO) | **591 with objects + 104 negatives = 695** | LVIS train gives ~5× more |
| COCO labels for the kept images | all found by id (checked on the first 6-class selection: 1,094 / 1,094) | merging is a plain lookup |
| COCO classes in the LVIS images alone (first selection) | **25 of 80** have ≥ 50 images; **18 have < 10** (mostly outdoor and animals: zebra 3, bear 3, airplane 4…). Household classes are plentiful | the reminder set (decision 3) |
| Rarest COCO classes in the val set **with** the reminder (1,195 images) | hair drier 2, bear 4, parking meter 5, toaster 5, snowboard 8… | train is ~9× larger; the train counts are printed |
| Our classes in the val set (images) | stove 206, phone 89, text 61 (COCO-Text only, before CRAFT), glasses 48, keys 40, wallet 24, **pill_box 12** | pill_box and wallet are the weak classes, as expected |
| Worn-glasses boxes removed / double labels dropped (val) | **412 / 131** | §4.2 steps 3–4 |
| COCO-Text coverage | first selection: **334 / 1,094** (31 %); val set with the reminder: **208 / 1,195** (17 %) | auto-label the rest (decision 4) |
| COCO-WholeBody hand boxes in our subset | **not published**; only 200K images / 250K people overall | **counted in the notebook** before training (decision 6) |
| EgoHands | 4,800 Glass frames, 15,000+ hands | the egocentric hand source |

If a count in the notebook comes out much lower than expected, **stop and tell the lead** before training.

### 4.4 Our own footage (smaller, but needed)

Public photos are not glasses-view: wrong angle, good light, objects centred. A model scored only on them looks better than it is. So we record **2–3 sessions per home** for two jobs: **fine-tuning** (a few hundred frames close most of the gap) and the **test set** (the scores that count are measured on our footage, §8).

**Setup**, the same as the benchmark, so the model sees what the glasses see:
- Phone or GoPro on a **head strap at eye level**, **1080p, 30 fps**, as in [RESEARCH_PLAN §5.2](../../../docs/RESEARCH_PLAN.md).
- Indoors, in prepared homes. **No bystanders**, signed consent from everyone on camera, code names in every file ([RESEARCH_PLAN §11](../../../docs/RESEARCH_PLAN.md)).

**Never train on benchmark footage.** The research benchmark measures how well Remori remembers. If the detector learns from the same videos, the benchmark is contaminated. So:
- Record **separate "detector sessions"** on different days from the benchmark sessions.
- Keep **at least one home** that appears **only** in the benchmark test, never in training.
- Name files so the source is obvious: `det_<home>_<date>_<n>.mp4` vs the benchmark's own names.
- Research datasets with non-commercial licences used for evaluation (e.g. SuperMemory-VQA) are **never** training data and never committed to git.

**What to film** (a shot list per session, ~20–30 min). For **each** of keys, glasses, wallet, phone and pill box, and every stove:
- **Put it down and pick it up** in 5–8 different places (table, bed, shelf, drawer, sofa, counter, near the door). This is exactly the moment the rule must catch, and it shows **hands touching objects**.
- **Distances:** close (30–50 cm, in hand), mid (1 m, on a table), far (2–3 m, across the room).
- **Light:** daylight, lamp only, dim evening light. At least a third of the footage should be dim.
- **Hidden partly:** under papers, half in a bag, behind a cup.
- **Clutter:** on a busy table with similar things around.
- **Motion:** turning the head normally (the blur is real data, don't avoid it).
- **Text:** read a medicine box, a food package, a letter, a calendar, a sign, at reading distance and from 1–2 m.
- **Variety:** at least 3–4 different sets of keys, glasses, wallets, phones and pill boxes across sessions.

Also film **hard negatives** (easy to confuse): a TV remote, a tablet, a tissue box, a lighter, sunglasses on a face, a microwave, cutlery. And ordinary minutes with **nothing special**: walking, sitting, watching TV.

### 4.5 Splits and volume

**Public data:** an image id belongs to **one split only**.
- **val** = the kept **LVIS val** images (some come from COCO's train2017; those ids never appear in train), plus ~500 reminder images from COCO val2017, plus 8 of the 48 EgoHands videos.
- **train** = everything else. EgoHands is split **by video**, never by frame.

**Our footage:** split **by session**, never by frame (§7.2).

| Stage | Data | Gives roughly |
|---|---|---|
| First model | public data only (§4.1–4.3) | ~10K–15K images (LVIS kept + 5K reminder + 4.8K EgoHands frames); exact counts printed by the notebook |
| Fine-tuned model | + **4–6 own sessions** in **2 homes** | ~800–1,200 labelled own frames |
| Test set | **2–3 own sessions**, including the held-out home | ~400–600 labelled own frames, never trained on |

---

## 5. Dataset structure (what the notebook writes)

Ultralytics' standard YOLO layout, one folder per split:

```
data/
├── remori_objects.yaml        # path, train, val, and the 87 names (ids 0–86, §1)
├── manifest.csv               # one row per image: where it and each of its labels came from
├── images/
│   ├── train/
│   │   ├── coco_000000123456.jpg       # any COCO photo (LVIS kept or reminder): COCO image id, 12 digits
│   │   └── egohands_CARDS_COURTYARD_B_T_0042.jpg   # EgoHands: video name + frame
│   └── val/
│       └── …
└── labels/
    ├── train/
    │   ├── coco_000000123456.txt       # same name as the image, .txt
    │   └── egohands_CARDS_COURTYARD_B_T_0042.txt
    └── val/
        └── …
```

- **File names carry the source:** `coco_<id>` (LVIS images are COCO images, so they share the prefix), `egohands_<video>_<frame>`, and later `det_<home>_<date>_<n>_<frame>` for our own footage (never in a public place, §6.4).
- **A label file** has one line per box: `<class_id> <x_center> <y_center> <width> <height>`, all four as fractions of the image size (0–1). Example: `80 0.512 0.633 0.041 0.028` is a small key near the centre. **An empty file** means "nothing of the 87 here": a valid negative.
- **`remori_objects.yaml`:**
  ```yaml
  path: /kaggle/working/data
  train: images/train
  val: images/val
  names:
    0: person
    # … 1–79: the COCO names, in COCO order
    80: keys
    81: glasses
    82: wallet
    83: pill_box
    84: stove
    85: text
    86: hand
  ```
- **`manifest.csv`** columns: `image, split, source, coco_labels, lvis_labels, text_labels, hand_labels, boxes_dropped`.
  - `source`: `lvis` / `reminder` / `egohands` / `own`.
  - The label columns say where each group of labels came from: `coco` / `yolo11n-auto` for 0–79; `lvis` / `none` for 80–84; `coco-text` / `craft-auto` for 85; `wholebody` / `egohands` / `none` for 86.
  - `boxes_dropped`: double labels (§4.2 step 4) and crowd boxes.
  - It lets anyone trace a box back to its source, count auto-labels for the model card, and check later results by source.

**How each source is labelled, at a glance:**

| Image source | 0–79 COCO | 80–84 ours | 85 text | 86 hand |
|---|---|---|---|---|
| LVIS kept (COCO photos) | COCO | LVIS | COCO-Text, else CRAFT | COCO-WholeBody |
| Reminder set (COCO photos) | COCO | none (prefer images LVIS checked absent) | COCO-Text, else CRAFT | COCO-WholeBody |
| EgoHands frames | stock yolo11n (auto) | none | CRAFT | EgoHands |
| Our footage (stage 2) | pre-labelled by the stage-1 model, **corrected by people** | people | people | people |

---

## 6. Labelling (our footage, and checking public labels)

### 6.1 Video to frames
Labelling every frame wastes time: neighbouring frames are almost identical. Sample, then remove near-duplicates.

```bash
# 2 frames per second, the long side at 1280 px (labels are scaled down later anyway)
ffmpeg -i det_homeA_2026-11-03_1.mp4 -vf "fps=2,scale=1280:-2" frames/det_homeA_2026-11-03_1_%05d.jpg
```

Keep only frames that differ enough from the last kept one (a perceptual hash, e.g. `imagehash.phash`, with a Hamming distance ≥ 8 is a good start), plus **every** frame within ±2 s of a put-down or pick-up moment. Aim for **≥ 150 labelled own instances** for each of our 7 classes and phone, and **15–20 % of frames with none of them**. Keep the frame name → video + timestamp mapping.

### 6.2 Tool and rules
- **CVAT** (free; app.cvat.ai, or self-hosted), one project **"remori-important-objects"** with the **87 labels in the order of §1**. It exports YOLO text files directly.
- **Pre-label, then correct.** Nobody draws 87 classes by hand: the stage-1 model labels each frame and people **correct** it. Every frame gets a full check of **our 7 classes and `cell phone`**. COCO classes are corrected where they're clearly wrong.
- **Don't use Roboflow's free plan for our footage:** free projects are public, and our frames show people's homes and faces.

Rules (everyone labels the same way):
1. **Tight boxes** around the object only. Keys in a hand: one box for the keys **and** one for the hand.
2. **Label every visible instance**, including small and far ones.
3. **Partly hidden:** label it if about a third or more is visible.
4. **Blurred by motion:** label it if a person can still tell what it is.
5. **`text`:** one box per line or block of writing that a person could read in a zoomed crop. Not single unreadable letters.
6. **Reflections, photos of objects, objects on a TV screen:** don't label (text on a screen *is* labelled as `text`).
7. **When unsure, tag the image "check"** instead of guessing; the reviewer decides.
8. **Public data:** spot-check **5 %** of each source, and **10 % of the auto-labels** (CRAFT text, yolo11n on EgoHands). Look for worn glasses that slipped through and missing hands. Write the error rate in the model card.

### 6.3 Quality control
- A **second person reviews 10 %** of each labeller's frames, and every "check" frame.
- Before fine-tuning, two labellers label the **same 100 frames** and compare. If they disagree on more than ~10 % of boxes, sharpen the rules above and fix the labels.

### 6.4 Privacy of the dataset
- Our frames show homes, family actors and sometimes faces: they're **personal data**.
- Store videos, frames and labels only in the team's **private Drive/S3 folder**. **Never in git** (`ml/README` rule 3), never in a public tool or a public Kaggle dataset.
- Code names in file names; no real names, addresses or phone numbers in labels or notes.

---

## 7. Training

### 7.1 Two stages, and where the score comes from
1. **Stage 1, public data:** the merged dataset (§4.2), starting from **`yolo11n.pt`** (COCO-pretrained). In the [Kaggle notebook](train_yolo_kaggle.ipynb) (free T4 GPU).
2. **Stage 2, fine-tune:** continue from the stage-1 model on our own **train** sessions mixed with public images (about half and half, **including reminder images**), with a lower learning rate, so it adapts to glasses-view without forgetting.
3. **Test only on our own held-out sessions** (§4.4). Report the public validation scores too, but the §8 targets are judged on our footage.

### 7.2 Split our footage by session, not by frame
Frames from the same video look alike; if they land in both train and test, the scores lie.

| Set | Share | Rule |
|---|---|---|
| train | ~60 % | most own sessions (stage 2) |
| val | ~15 % | whole sessions, for choosing epochs and the threshold |
| test | ~25 % | whole sessions, **including the held-out home**; used once, at the end |

### 7.3 Where to train
**Kaggle** (free T4, Internet on, a phone-verified account). The public datasets download inside the notebook, not on your laptop. Stage 1 takes several hours; save a checkpoint so a cut session can resume. Our own footage is **not** uploaded to Kaggle as a public dataset: use a private dataset or train stage 2 elsewhere with the lead's approval.

### 7.4 Settings that matter
- **Start from `yolo11n.pt`.** With 87 classes instead of 80, Ultralytics builds a new last layer; everything below it keeps COCO's knowledge. That's why the reminder set matters: the new layer must learn the 80 again from data.
- **Input size 320** (also try 416 to see the accuracy cost of going small).
- **Augmentations:** mosaic, scale, small rotations (±10°), brightness and colour jitter, **dimmer images**, horizontal flip; **motion blur** where the framework supports it. No vertical flip (text and rooms have an "up").
- **Epochs:** stage 1: 80–150 with early stopping (patience 20); stage 2: 30–80 at a lower learning rate.
- **Class balance:** if one class has far fewer instances (often `pill_box` and `wallet`), add data for it (EgoObjects, a Roboflow set, more own footage) rather than relying on weights.

### 7.5 Commands
Ultralytics YOLO11n (decided):
```bash
pip install ultralytics
yolo detect train data=remori_objects.yaml model=yolo11n.pt imgsz=320 epochs=150 patience=20 batch=64
```

NanoDet-Plus-m (licence-clean alternative to compare later): `num_classes: 87`, the 87 names in §1 order, the same images exported as COCO JSON from the YOLO files.

Record every run: data version (the manifest's counts), stage, settings, scores, and the commit of the training code. A table in the team sheet is enough.

---

## 8. Evaluation (what "good enough" means)

mAP alone doesn't tell us whether the gate works. Report all of these on the **test** set (our own held-out footage), except the forgetting check:

| Metric | Why | Proposed target (agree with the lead) |
|---|---|---|
| **Per-class recall** for keys, glasses, wallet, phone, pill_box, stove, text, hand | a missed object = a moment not kept | ≥ 0.80 each (text and hand: report first, then set) |
| **Moment recall**: of all put-down / pick-up moments, how many have at least one kept frame within ±2 s | what the gate really needs (the look-back buffer covers the seconds before) | ≥ 0.90 |
| **False triggers per hour** of footage with nothing to keep | each one keeps 1 + 3–5 frames, uploads them and costs a cloud review | ≤ 10 per hour |
| **No forgetting:** COCO val2017 mAP@0.5 (80 classes, 320 px) vs stock `yolo11n.pt` at 320 | proves the reminder set worked | within ~3 points |
| mAP@0.5 per class | standard, for comparing runs | report it |
| Recall by object size (small / medium / large) | keys, wallets and text are small | small objects must not be far below the rest |
| Results per lighting (bright / dim) and per label source (manifest) | dim rooms; auto-labels may be noisier | report it |
| Stage 1 vs stage 2 on the same test set | shows how much our own footage adds | report it |

Pick the score thresholds on the **val** set so that recall meets the target, then check false triggers. A slightly lower threshold is fine: the cloud review filters the extra frames later.

Look at the **misses**: they tell you what to record or add next. Then repeat §4–§7.

---

## 9. Export for the Pi

1. **ONNX** export at the chosen input size (opset 12 or newer), simplified; and **NCNN** (the notebook does both).
2. **INT8** quantization with ~200 calibration frames taken from **train**, mostly our own footage (never test).
3. **Check the accuracy after INT8** on the test set: it should drop by no more than ~2 recall points.
4. **Measure on a real Pi Zero 2W** with the hardware team: milliseconds per frame, peak RAM, CPU temperature after 30 minutes, power. Try **NCNN** and **onnxruntime**; the faster one wins. If it misses ≤ 300 ms per frame, try input 256 (D42: lower the size, not the rate).

---

## 10. Hand-over to the glasses

- **Model file** → `ml/models/important_objects/` (or S3, per §3.2 item 3) with its **model card** (§12). Consumers pin a version.
- **Rule code** → `ml/edge/` (D38): pure Python with no camera or file I/O, e.g. `detect(frame) -> [(class_id, score, box)]` and one function per rule over the detections. The Pi runtime (`hardware/pi`) and the research replay both import it, so the paper tests exactly what the glasses run.
- **The rules over the detections** (every frame has objects, so "an object is visible" can't be a rule by itself):

  | Rule | Fires when | `gate_rule` | Status |
  |---|---|---|---|
  | Important object | keys, glasses, wallet, `cell phone` or stove is detected | `important_object` | decided (D42) |
  | Medication | `pill_box` is detected | `medication` | decided (D33) |
  | Text | a `text` box above a minimum size; the box goes with the frame so a **zoomed crop** can be read | `text` | decided (D33: the rule exists; this model now runs it) |
  | New object | a COCO class not seen in the last ~30 s appears | to define | **proposed** |
  | Hand-object | a `hand` box overlaps an object box (pick-up / put-down), plus the look-back buffer | to define | **proposed** |

- **Kept frames** are sent with their `gate_rule` (spec §7.1). New rule names are a contract change: spec first.

---

## 11. Done when

- [x] Notebook and `prepare_dataset.py` updated to the 87-class design (§4.2, §5)
- [ ] First full run on Kaggle; the counts of §4.3 printed and checked
- [ ] Every dataset's licence read and listed (§4.1)
- [ ] A stage-1 model trained on public data, with the forgetting check (§8)
- [ ] Ethics/consent confirmed for our own sessions (RESEARCH_PLAN §11)
- [ ] Own footage recorded per §4.4, kept separate from the benchmark, one home held out
- [ ] ≥ 150 labelled own instances for each of our 7 classes and phone, a labelled own test set, 10 % reviewed
- [ ] A fine-tuned model meeting the §8 targets on our own test set, or a written list of where it falls short
- [ ] INT8 export measured on a Pi Zero 2W (ms, RAM, °C)
- [ ] Model card in `ml/models/`, rule code in `ml/edge/`
- [ ] Results table (all §8 metrics) shared with the lead

---

## 12. Model card template

Copy into `ml/models/important_objects/MODEL_CARD.md` for every exported version (the notebook writes a first version automatically):

```markdown
# important_objects v<N>

- Date, trained by, training-code commit
- Framework + licence: Ultralytics YOLO11n, AGPL-3.0 (graduation project)
- Classes (fixed order): 0–79 COCO (standard order), 80 keys, 81 glasses, 82 wallet,
  83 pill_box, 84 stove, 85 text, 86 hand
- Input: <W>×<H> RGB, letterbox (Ultralytics default), output format
- Files: <name>.onnx (FP32), <name>_int8.onnx / NCNN files, SHA-256 of each
- Data: every dataset (name, version, licence, images used); manifest counts per source;
  share of auto-labels (CRAFT text, yolo11n on EgoHands) and their spot-check error rate;
  own sessions and homes; split
- Test results (own held-out footage): per-class recall at threshold <t>, moment recall,
  false triggers/hour, mAP@0.5, recall by size and lighting; stage 1 vs 2; FP32 vs INT8
- Forgetting check: COCO val2017 mAP@0.5 vs stock yolo11n at the same size
- On the Pi Zero 2W: ms per frame, peak RAM, temperature after 30 min, runtime (NCNN / onnxruntime)
- Known weaknesses: (e.g. keys under 20 px, dark bedrooms, small print)
```

---

## 13. Who does what (suggested)

| Role | Tasks |
|---|---|
| Data lead | public datasets: licences, the merge (§4.2), the manifest and the counts (§4.3, §5) |
| Recording lead | consent, own sessions per §4.4, file naming, held-out home |
| Labellers (2–3) | CVAT per §6, spot-checks of public and auto labels, cross-review |
| Trainer | splits, both training stages, the forgetting check, the results table |
| Evaluator | §8 metrics, miss analysis → what to add next |
| With the hardware team | §9 measurements on the Pi, the runtime choice, the rules in `ml/edge/` |

A realistic pace: **week 1** merged public dataset + stage-1 model, consent and CVAT set up · **week 2** own sessions recorded and labelled, stage-2 fine-tune · **week 3** test on our footage, fix the misses, export, measure on the Pi.

---

## 14. Common mistakes

- **Training on our new classes only.** The model forgets COCO's 80: always include the reminder set (§4.2 step 8).
- **Unlabelled objects of a trained class.** An unlabelled phone, hand or line of text teaches "background". Every image needs labels from **every** class group (§5 table), from a dataset or an auto-labeller.
- **Two labels on one object** (oven + stove, bottle + pill box). Keep ours, drop COCO's (§4.2 step 4).
- **The same image in train and val.** LVIS val contains COCO train2017 images: split by image id (§4.5).
- **Assuming a dataset has enough of something.** Count it first (§4.3).
- **Train/test from the same video.** Split by session (§7.2), EgoHands by video.
- **Benchmark footage in training.** Never (§4.4).
- **Scoring on public data only.** It flatters the model: the targets are judged on our own footage (§7.1).
- **Changing class names or order.** The glasses' code depends on them (§1).
- **Judging by mAP alone.** The gate needs moment recall and few false triggers (§8).
- **Personal data in git or public tools.** Private folder only (§6.4).
