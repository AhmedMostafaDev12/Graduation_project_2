"""Builds the merged 87-class YOLO dataset of the important-object detector (spec D42).

Guide: README.md §4.2 (the steps), §4.3 (the counts it prints) and §5 (what it writes).

    python prepare_dataset.py --out data --egohands /kaggle/input/egohands       # full, on Kaggle
    python prepare_dataset.py --out test --split val --limit 30 --skip wholebody,egohands,auto   # quick local test
    python prepare_dataset.py --coco-val coco_val                                 # the forgetting check's data (§8)

Classes (README §1, a contract with the glasses): 0–79 COCO in the standard order, 80 keys,
81 glasses, 82 wallet, 83 pill_box, 84 stove, 85 text, 86 hand.

Sources, joined by COCO image id (LVIS, COCO, COCO-Text and COCO-WholeBody label the same photos):
- LVIS v1: our five objects (80–84); picks the images we keep.
- COCO 2017 instances: the 80 COCO classes on every COCO photo we use.
- COCO-Text v2: legible text (85) where it covers an image; EasyOCR's CRAFT labels the rest.
- COCO-WholeBody: valid hand boxes (86) on COCO photos.
- EgoHands (a Kaggle input): Google Glass frames with hand polygons; the stock yolo11n labels
  their 80 COCO classes and CRAFT their text.
- Objects365 (two Hugging Face copies): every photo with a key or a wallet, plus samples with glasses,
  phones and gas stoves; its classes mapped onto ours and COCO's; MediaPipe labels their hands.
- Roboflow Universe (needs ROBOFLOW_API_KEY): pill organisers and medicine boxes → pill_box, keys at home →
  keys, close-up wallets → wallet; near-duplicate photos removed by image embedding.
- The reminder set: ~5,000 more COCO photos with all their labels, so the 80 classes aren't forgotten.
- Zoomed crops: small objects of ours (and phones) cut out of the full-size photo, train only.

Needs: numpy, scipy (EgoHands), gdown (WholeBody), Pillow, pyarrow + huggingface_hub + remotezip
(Objects365), easyocr, ultralytics and mediapipe (the auto-labels, GPU for the first two).
"""

import argparse
import csv
import io
import json
import os
import random
import shutil
import struct
import subprocess
import sys
import threading
import urllib.error
import urllib.request
import zipfile
import zlib
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path, PurePosixPath

LVIS = "https://dl.fbaipublicfiles.com/LVIS/lvis_v1_{split}.json.zip"
COCO = "http://images.cocodataset.org/annotations/annotations_trainval2017.zip"
COCO_VAL_IMAGES = "http://images.cocodataset.org/zips/val2017.zip"
COCO_TEXT = "https://github.com/bgshih/cocotext/releases/download/dl/cocotext.v2.zip"
# COCO-WholeBody v1.0, official Google Drive files (github.com/jin-s13/COCO-WholeBody); the train
# file also has a Hugging Face mirror, used when Drive refuses (its daily quota).
WHOLEBODY_DRIVE = {"train": "1thErEToRbmM9uLNi1JXXfOsaS5VK2FXf", "val": "1N6VgwKnj8DeyGXCvp1eYgNbRmw6jdfrb"}
# EgoHands' original link is dead; a full copy of the original release lives on Kaggle
EGOHANDS_KAGGLE = "himaniishah/egohands"
# a Kaggle copy of the LVIS v1 annotations (its val file has the original's exact size, 201,235,232 bytes)
LVIS_KAGGLE = ("alexanderyyy/lvis-v1", {"train": "lvis_v1_train.json/lvis_v1_train.json", "val": "lvis_v1_val/lvis_v1_val.json"})
# Objects365 (README §4.2 step 6b): annotations from one Hugging Face copy (sharded parquet, original
# pixels), photos from another (letterboxed to 384 × 384, in 20 zips read by range requests)
O365_ANN = "jxu124/objects365"
O365_IMG_URL = "https://huggingface.co/datasets/hieupth/objects365_384_squared/resolve/main/images_part{:03d}.zip"
O365_PARTS = range(1, 21)
O365_SIDE = 384
# photos to take per split: every photo with a key or a wallet (0 = all), a sample of the others
O365_TAKE = {"train": {"Key": 0, "Wallet/Purse": 0, "Glasses": 3000, "Cell Phone": 3000, "Gas stove": 3000},
             "val": {"Key": 0, "Wallet/Purse": 0, "Glasses": 300, "Cell Phone": 300, "Gas stove": 300}}
O365_OURS = {"Key": 80, "Glasses": 81, "Wallet/Purse": 82, "Gas stove": 84}
# Objects365 names → COCO's (every one of the 80 has a match; checked)
O365_TO_COCO = {
    "Person": "person", "Bicycle": "bicycle", "Car": "car", "SUV": "car", "Sports Car": "car", "Van": "car",
    "Motorcycle": "motorcycle", "Airplane": "airplane", "Bus": "bus", "Train": "train", "Truck": "truck",
    "Pickup Truck": "truck", "Heavy Truck": "truck", "Fire Truck": "truck", "Boat": "boat", "Sailboat": "boat",
    "Ship": "boat", "Traffic Light": "traffic light", "Fire Hydrant": "fire hydrant", "Stop Sign": "stop sign",
    "Parking meter": "parking meter", "Bench": "bench", "Wild Bird": "bird", "Duck": "bird", "Pigeon": "bird",
    "Goose": "bird", "Swan": "bird", "Parrot": "bird", "Penguin": "bird", "Chicken": "bird", "Cat": "cat",
    "Dog": "dog", "Horse": "horse", "Sheep": "sheep", "Cow": "cow", "Elephant": "elephant", "Bear": "bear",
    "Zebra": "zebra", "Giraffe": "giraffe", "Backpack": "backpack", "Umbrella": "umbrella",
    "Handbag/Satchel": "handbag", "Tie": "tie", "Bow Tie": "tie", "Luggage": "suitcase", "Frisbee": "frisbee",
    "Skiboard": "skis", "Snowboard": "snowboard", "Soccer": "sports ball", "Basketball": "sports ball",
    "Baseball": "sports ball", "Volleyball": "sports ball", "Tennis": "sports ball", "Golf Ball": "sports ball",
    "American Football": "sports ball", "Other Balls": "sports ball", "Kite": "kite", "Baseball Bat": "baseball bat",
    "Baseball Glove": "baseball glove", "Skateboard": "skateboard", "Surfboard": "surfboard",
    "Tennis Racket": "tennis racket", "Bottle": "bottle", "Wine Glass": "wine glass", "Cup": "cup", "Fork": "fork",
    "Knife": "knife", "Spoon": "spoon", "Bowl/Basin": "bowl", "Banana": "banana", "Apple": "apple",
    "Sandwich": "sandwich", "Hamburger": "sandwich", "Orange/Tangerine": "orange", "Broccoli": "broccoli",
    "Carrot": "carrot", "Hot dog": "hot dog", "Pizza": "pizza", "Donut": "donut", "Cake": "cake", "Chair": "chair",
    "Couch": "couch", "Potted Plant": "potted plant", "Bed": "bed", "Dining Table": "dining table",
    "Desk": "dining table", "Coffee Table": "dining table", "Side Table": "dining table", "Toilet": "toilet",
    "Monitor/TV": "tv", "Laptop": "laptop", "Mouse": "mouse", "Remote": "remote", "Keyboard": "keyboard",
    "Cell Phone": "cell phone", "Microwave": "microwave", "Oven": "oven", "Toaster": "toaster", "Sink": "sink",
    "Refrigerator": "refrigerator", "Book": "book", "Clock": "clock", "Vase": "vase", "Scissors": "scissors",
    "Stuffed Toy": "teddy bear", "Hair Dryer": "hair drier", "Toothbrush": "toothbrush",
}
# Roboflow Universe sets (README §4.2 step 6c), CC BY 4.0 or public domain as published. The original photos
# and boxes come from Roboflow's API (its exports are stretched and augmented); needs ROBOFLOW_API_KEY.
# Each set: its label → our id ("*" = every label); boxes with other labels are dropped.
ROBOFLOW_SETS = {
    "andre-anrfr/pill-box": {"*": 83},                    # pill organisers, mostly in hands
    "andre-anrfr/pillboxdetection": {"*": 83},            # the same photos (dropped as duplicates); kept for safety
    "fernando-vela-rdnuo/medicineboxes": {"*": 83},       # medicine boxes in hands and on tables
    "obj-detection-kd5zb/objects_v2": {"keys": 80},       # keys in real homes; its "bag" boxes: yolo11n labels bags
    "senior-project-final-datasets/wallets-cskty": {"Wallet": 82},  # close-up product photos of wallets
}
ROBOFLOW_DUPLICATE = 0.95  # image-embedding cosine above this = the same photo (measured: repeats ≤ 0.975, others ≤ 0.905)
ROBOFLOW_TRAIN_ONLY = {"fernando-vela-rdnuo/medicineboxes"}  # neighbouring video frames would leak into val
# fernando's shelf / mix photos: only some of their boxes are labelled
ROBOFLOW_SKIP_PREFIXES = {"fernando-vela-rdnuo/medicineboxes": ("IMG_", "mix")}
ROBOFLOW_FRAME_EVERY = 5  # fernando's video frames: keep every 5th, neighbours are near-identical
ROBOFLOW_SIDE = 1024      # originals are up to 5,632 px: shrink to this long side
# MediaPipe's hand detector labels the hands Objects365 doesn't (README §4.2 step 6b)
MEDIAPIPE_HANDS = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task"
HAND_PAD = 0.1          # landmarks are joints: widen their box by 10 % on each side to cover the whole hand
WHOLEBODY_MIRROR = {"train": "https://huggingface.co/hngan/cocowholebody/resolve/main/coco_wholebody_train_v1.0.json"}

# our classes after COCO's 80 (README §1); LVIS names for the five objects
OURS = {80: ("keys", "key"), 81: ("glasses", "spectacles"), 82: ("wallet", "wallet"),
        83: ("pill_box", "medicine"), 84: ("stove", "stove")}
TEXT, HAND = 85, 86

NEGATIVE_SHARE = 0.15   # LVIS images where our objects were checked absent
DOUBLE_IOU = 0.7        # ours vs a COCO box on the same object: keep ours (§4.2 step 4)
MIN_TEXT = 0.015        # text boxes lower than 1.5 % of the image height are too small to read
REMINDER = {"train": 4500, "val": 500}
EGO_VAL_PER_ACTIVITY = 2  # 8 of the 48 EgoHands videos go to val, 2 per activity
AUTO_COCO_CONF = 0.5    # stock yolo11n labels on EgoHands frames
# a class with fewer train images than this stops the run (README §4.3: tell the lead)
MIN_TRAIN_IMAGES = 50
# zoomed crops (README §4.2 step 9): small objects seen up close, from the full-size photo
ZOOM_CLASSES = {67, 80, 81, 82, 83, 84}  # cell phone + our five objects
ZOOM_SMALL = 0.125      # an object is small when its long side is under 1/8 of the image's (40 px at 320)
ZOOM_CONTEXT = 5        # the crop's side is 5× the object's long side …
ZOOM_MIN_SIDE = 160     # … but at least 160 px of the original photo
ZOOM_PER_IMAGE = 2      # at most 2 crops per photo
ZOOM_KEEP_BOX = 0.5     # a box cut by the crop stays if half of it is inside …
ZOOM_KEEP_FILL = 0.2    # … or if what's inside covers a fifth of the crop (a person filling the view)


# ---------- downloads ----------

def fetch(url: str, path: Path) -> Path:
    if not path.exists():
        print(f"downloading {url} …", flush=True)
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(path.suffix + ".part")
        with urllib.request.urlopen(url) as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f, 1 << 20)
        tmp.rename(path)
    return path


def unzip_one(zip_path: Path, member: str, target: Path) -> Path:
    if not target.exists():
        with zipfile.ZipFile(zip_path) as z:
            target.write_bytes(z.read(member))
    return target


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def lvis(split: str, cache: Path) -> dict:
    target = cache / f"lvis_v1_{split}.json"
    if not target.exists():
        try:
            z = fetch(LVIS.format(split=split), cache / f"lvis_v1_{split}.json.zip")
            unzip_one(z, f"lvis_v1_{split}.json", target)
        except urllib.error.URLError as e:
            # Meta's server failed (Nov 2026: an expired certificate): use the Kaggle copy instead
            import kagglehub

            handle, paths = LVIS_KAGGLE
            print(f"LVIS server failed ({e.reason}); using the Kaggle copy {handle}", flush=True)
            shutil.copy(kagglehub.dataset_download(handle, path=paths[split]), target)
    return load_json(target)


def coco_instances(part: str, cache: Path) -> dict:
    target = cache / f"instances_{part}.json"
    if not target.exists():
        z = fetch(COCO, cache / "annotations_trainval2017.zip")
        unzip_one(z, f"annotations/instances_{part}.json", target)
    return load_json(target)


def coco_text(cache: Path) -> dict:
    target = cache / "cocotext.v2.json"
    if not target.exists():
        unzip_one(fetch(COCO_TEXT, cache / "cocotext.v2.zip"), "cocotext.v2.json", target)
    return load_json(target)


def wholebody(part: str, cache: Path) -> dict:
    target = cache / f"coco_wholebody_{part}_v1.0.json"
    if not target.exists():
        import gdown

        got = gdown.download(id=WHOLEBODY_DRIVE[part], output=str(target), quiet=False)
        if not got and part in WHOLEBODY_MIRROR:
            fetch(WHOLEBODY_MIRROR[part], target)
        if not target.exists():
            raise SystemExit(f"COCO-WholeBody {part} could not be downloaded (Drive quota?). Retry later "
                             f"or upload it as a Kaggle input and copy it to {target}.")
        if zipfile.is_zipfile(target):
            with zipfile.ZipFile(target) as z:
                data = z.read(z.namelist()[0])
            target.write_bytes(data)
    return load_json(target)


# ---------- boxes ----------

def iou(a, b) -> float:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    ix = max(0.0, min(ax + aw, bx + bw) - max(ax, bx))
    iy = max(0.0, min(ay + ah, by + bh) - max(ay, by))
    inter = ix * iy
    union = aw * ah + bw * bh - inter
    return inter / union if union > 0 else 0.0


def clip(box, w, h):
    x, y, bw, bh = box
    x0, y0 = max(0.0, x), max(0.0, y)
    x1, y1 = min(float(w), x + bw), min(float(h), y + bh)
    return (x0, y0, x1 - x0, y1 - y0) if x1 > x0 and y1 > y0 else None


# ---------- 1. LVIS: the images with our objects, negatives, reminder candidates ----------

def from_lvis(data: dict, split: str, seed: int = 0):
    """→ (kept {id: record}, reminder pool [(neg_checked, id, record)], stats)."""
    by_name = {c["name"]: c["id"] for c in data["categories"]}
    ours = {by_name[lvis_name]: cls for cls, (_, lvis_name) in OURS.items()}
    boxes = defaultdict(list)
    for a in data["annotations"]:
        if a["category_id"] in ours:
            boxes[a["image_id"]].append((ours[a["category_id"]], tuple(a["bbox"])))

    kept, negatives, pool, stats = {}, [], [], Counter()
    for img in data["images"]:
        iid = img["id"]
        record = {"split": split, "source": "lvis", "url": img["coco_url"], "w": img["width"],
                  "h": img["height"], "boxes": list(boxes.get(iid, [])), "dropped": 0,
                  "labels": {"coco": "coco", "lvis": "lvis", "text": "none", "hand": "none"}}
        labeled = {cls for cls, _ in record["boxes"]}
        not_exhaustive = {ours[c] for c in img.get("not_exhaustive_category_ids", []) if c in ours}
        checked_absent = {ours[c] for c in img.get("neg_category_ids", []) if c in ours}
        if labeled & not_exhaustive:
            stats["dropped: our object not fully labeled"] += 1
            continue
        if labeled:
            kept[iid] = record
        else:
            if checked_absent:
                negatives.append((iid, record))
            record = dict(record, source="reminder", labels=dict(record["labels"], lvis="none"))
            pool.append((bool(checked_absent), iid, record))

    random.Random(seed).shuffle(negatives)
    n_neg = int(len(kept) * NEGATIVE_SHARE / (1 - NEGATIVE_SHARE))
    for iid, record in negatives[:n_neg]:
        kept[iid] = record
    taken = set(kept)
    pool = [p for p in pool if p[1] not in taken]
    stats["kept with objects"] = sum(1 for r in kept.values() if r["boxes"])
    stats["kept negatives"] = sum(1 for r in kept.values() if not r["boxes"])
    return kept, pool, stats


def pick_reminder(pool, split: str, n: int, seed: int = 0) -> dict:
    """Prefer images where LVIS checked our classes absent (they double as negatives, §4.2 step 8)."""
    if split == "val":  # the val reminder comes from COCO val2017 (§4.5)
        pool = [p for p in pool if "val2017" in p[2]["url"]]
    rng = random.Random(seed)
    checked = [p for p in pool if p[0]]
    other = [p for p in pool if not p[0]]
    rng.shuffle(checked)
    rng.shuffle(other)
    return {iid: record for _, iid, record in (checked + other)[:n]}


# ---------- 2–6. merge the labels of the COCO photos ----------

def add_coco(records: dict, cache: Path, names: dict) -> dict:
    """Adds the 80 COCO classes (ids 0–79). Every pair of glasses stays labelled, worn or not: telling
    a worn pair apart is the gate rule's job, not the model's (README §1, §10)."""
    order = {}
    for part in ("train2017", "val2017"):
        coco = coco_instances(part, cache)
        if not order:
            cats = sorted(coco["categories"], key=lambda c: c["id"])
            order = {c["id"]: i for i, c in enumerate(cats)}
            names.update({i: c["name"] for c, i in zip(cats, range(80))})
        for a in coco["annotations"]:
            record = records.get(a["image_id"])
            if record is None:
                continue
            if a.get("iscrowd"):
                record["dropped"] += 1
                continue
            record["boxes"].append((order[a["category_id"]], tuple(a["bbox"])))
        del coco
    return {"COCO boxes added": sum(1 for r in records.values() for c, _ in r["boxes"] if c < 80)}


def drop_doubles(record: dict) -> None:
    ours = [b for cls, b in record["boxes"] if 80 <= cls <= 84]
    if not ours:
        return
    keep = []
    for cls, b in record["boxes"]:
        if cls < 80 and any(iou(b, o) > DOUBLE_IOU for o in ours):
            record["dropped"] += 1
            continue
        keep.append((cls, b))
    record["boxes"] = keep


def add_coco_text(records: dict, cache: Path) -> Counter:
    ct = coco_text(cache)
    covered = {int(i) for i in ct["imgs"]}
    stats = Counter()
    for a in ct["anns"].values():
        record = records.get(a["image_id"])
        if record is None or a.get("legibility") != "legible":
            continue
        if a["bbox"][3] >= MIN_TEXT * record["h"]:
            record["boxes"].append((TEXT, tuple(a["bbox"])))
            stats["text boxes from COCO-Text"] += 1
    for iid, record in records.items():
        if iid in covered:
            record["labels"]["text"] = "coco-text"
            stats["images covered by COCO-Text"] += 1
    return stats


def extract_hands(part: str, cache: Path) -> None:
    """Runs in its own process: the WholeBody train file is 3.2 GB and needs ~20 GB of RAM to load,
    so only the valid hand boxes are kept (a few MB) and the process exits, freeing all of it."""
    wb = wholebody(part, cache)
    hands = defaultdict(list)
    for a in wb["annotations"]:
        if a.get("iscrowd"):
            continue
        for side in ("lefthand", "righthand"):
            if a.get(f"{side}_valid"):
                hands[a["image_id"]].append(a[f"{side}_box"])
    out = {"images": [img["id"] for img in wb["images"]], "hands": hands}
    (cache / f"hands_{part}.json").write_text(json.dumps(out), encoding="utf-8")


def hands_of(part: str, cache: Path) -> dict:
    path = cache / f"hands_{part}.json"
    if not path.exists():
        print(f"extracting COCO-WholeBody {part} hands in a separate process …", flush=True)
        subprocess.run([sys.executable, __file__, "--extract-hands", part, "--cache", str(cache)], check=True)
    return load_json(path)


def add_wholebody(records: dict, cache: Path) -> Counter:
    stats = Counter()
    for part in ("train", "val"):
        if not any(f"{part}2017" in r["url"] for r in records.values()):
            continue
        wb = hands_of(part, cache)
        for iid in wb["images"]:
            record = records.get(iid)
            if record is None:
                continue
            record["labels"]["hand"] = "wholebody"
            for raw in wb["hands"].get(str(iid), []):
                box = clip(raw, record["w"], record["h"])
                if box:
                    record["boxes"].append((HAND, box))
                    stats["hand boxes from COCO-WholeBody"] += 1
    with_person = [r for r in records.values() if any(c == 0 for c, _ in r["boxes"])]
    stats["COCO photos with a person"] = len(with_person)
    stats["…of those with at least one hand box"] = sum(1 for r in with_person if any(c == HAND for c, _ in r["boxes"]))
    return stats


# ---------- Objects365: more keys, wallets, glasses, phones and stoves ----------

def extract_o365(cache: Path, splits) -> None:
    """Runs in its own process (25 M annotations): picks the photos to take (O365_TAKE) and keeps only
    their mapped boxes, in original pixels. Writes o365_<split>.json."""
    import pyarrow.parquet as pq
    from huggingface_hub import HfApi, hf_hub_download

    files = sorted(s.rfilename for s in HfApi().dataset_info(O365_ANN).siblings if s.rfilename.endswith(".parquet"))
    keep = set(O365_OURS) | set(O365_TO_COCO)
    for split in splits:
        take = O365_TAKE[split]
        take_all = {c for c, k in take.items() if not k}
        rng = random.Random(0)
        everything, reservoir, seen = [], {c: [] for c, k in take.items() if k}, Counter()
        prefix = "data/train" if split == "train" else "data/validation"
        for f in (f for f in files if f.startswith(prefix)):
            parquet = pq.ParquetFile(hf_hub_download(O365_ANN, f, repo_type="dataset"))
            for batch in parquet.iter_batches(batch_size=20000, columns=["image_info", "anns_info"]):
                for info, anns in zip(batch.column("image_info").to_pylist(), batch.column("anns_info").to_pylist()):
                    hits = {a["category"] for a in anns} & set(take)
                    if not hits:
                        continue
                    row = {"name": PurePosixPath(info["file_name"]).name, "w": info["width"], "h": info["height"],
                           "boxes": [[a["category"], *a["bbox"]] for a in anns  # bbox: x0, y0, x1, y1
                                     if a["category"] in keep and not a.get("isfake") and not a.get("isreflected")]}
                    if hits & take_all:
                        everything.append(row)
                        continue
                    for c in sorted(hits):  # reservoir sampling: a fair random sample in one pass (sorted: repeatable)
                        seen[c] += 1
                        if len(reservoir[c]) < take[c]:
                            reservoir[c].append(row)
                        elif (j := rng.randrange(seen[c])) < take[c]:
                            reservoir[c][j] = row
            print(f"  Objects365 {split}: read {f}", flush=True)
        chosen = {r["name"]: r for r in everything}
        for rows in reservoir.values():
            chosen.update((r["name"], r) for r in rows)
        (cache / f"o365_{split}.json").write_text(json.dumps(list(chosen.values())), encoding="utf-8")


def objects365(out: Path, cache: Path, names: dict, splits, limit: int, workers: int) -> dict:
    """The chosen Objects365 photos: fetched one by one out of the 384 px zips, black bars cut off,
    boxes scaled and mapped to our ids. → {name: record}."""
    import requests
    from PIL import Image
    from remotezip import RemoteZip

    need = [s for s in splits if not (cache / f"o365_{s}.json").exists()]
    if need:
        print(f"reading Objects365 annotations ({', '.join(need)}) in a separate process …", flush=True)
        subprocess.run([sys.executable, __file__, "--extract-o365", ",".join(need), "--cache", str(cache)], check=True)
    want = {}
    for split in splits:
        rows = load_json(cache / f"o365_{split}.json")
        for r in rows[: limit or None]:
            want[r["name"]] = (split, r)
    coco_id = {name: i for i, name in names.items()}
    classes = {c: O365_OURS.get(c, coco_id.get(O365_TO_COCO.get(c))) for c in set(O365_OURS) | set(O365_TO_COCO)}

    # 1. each zip's file list (its central directory, a few MB) and its direct download address
    def located(part):
        url = O365_IMG_URL.format(part)
        with RemoteZip(url) as z:
            members = [i for i in z.infolist() if PurePosixPath(i.filename).name in want]
        return part, (requests.head(url, allow_redirects=True, timeout=60).url, members)

    with ThreadPoolExecutor(8) as pool:
        parts = dict(pool.map(located, O365_PARTS))
    jobs, taken = [], set()
    for part, (url, members) in parts.items():
        for info in members:
            if PurePosixPath(info.filename).name not in taken:
                taken.add(PurePosixPath(info.filename).name)
                jobs.append((part, info))
    print(f"Objects365: {len(jobs)} of {len(want)} chosen photos found in the zips; fetching …", flush=True)

    # 2. each photo with one byte-range request (one request per photo instead of redirect + reconnect)
    local = threading.local()

    def member_bytes(part, info) -> bytes:
        if not hasattr(local, "session"):
            local.session = requests.Session()
        for attempt in range(3):
            url = parts[part][0]
            start = info.header_offset
            size = 30 + len(info.filename.encode()) + 512 + info.compress_size  # 512: room for the local extra field
            r = local.session.get(url, headers={"Range": f"bytes={start}-{start + size - 1}"}, timeout=60)
            if r.status_code in (401, 403):  # the signed address expired: get a fresh one
                parts[part] = (requests.head(O365_IMG_URL.format(part), allow_redirects=True, timeout=60).url, [])
                continue
            r.raise_for_status()
            raw = r.content
            n, m = struct.unpack("<HH", raw[26:30])
            data = raw[30 + n + m: 30 + n + m + info.compress_size]
            if len(data) == info.compress_size:
                return data if info.compress_type == zipfile.ZIP_STORED else zlib.decompress(data, -15)
        raise OSError(f"could not read {info.filename} from part {part}")

    def fetch(job):
        part, info = job
        base = PurePosixPath(info.filename).name
        split, r = want[base]
        name = f"o365_{PurePosixPath(base).stem}"
        W, H = r["w"], r["h"]
        s = O365_SIDE / max(W, H)
        nw, nh = round(W * s), round(H * s)
        ox, oy = (O365_SIDE - nw) // 2, (O365_SIDE - nh) // 2  # the photo is centred between black bars
        target = out / "images" / split / f"{name}.jpg"
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            try:
                with Image.open(io.BytesIO(member_bytes(part, info))) as image:
                    image.convert("RGB").crop((ox, oy, ox + nw, oy + nh)).save(target, quality=92)
            except (OSError, requests.RequestException):
                return None
        boxes = []
        for c, x0, y0, x1, y1 in r["boxes"]:
            box = clip((x0 * s, y0 * s, (x1 - x0) * s, (y1 - y0) * s), nw, nh)
            if box and classes.get(c) is not None:
                boxes.append((classes[c], box))
        return name, {"split": split, "source": "objects365", "file": target, "w": nw, "h": nh, "boxes": boxes,
                      "dropped": 0, "labels": {"coco": "objects365", "lvis": "objects365", "text": "none", "hand": "none"}}

    records = {}
    with ThreadPoolExecutor(max(workers, 32)) as pool:
        for i, got in enumerate(pool.map(fetch, jobs)):
            if got:
                records[got[0]] = got[1]
            if i % 2000 == 0:
                print(f"  Objects365 photos: {i}/{len(jobs)}", flush=True)
    for r in records.values():
        drop_doubles(r)
    return records


# ---------- Roboflow Universe: pill boxes, keys, wallets ----------

def roboflow_key():
    key = os.environ.get("ROBOFLOW_API_KEY")
    if not key:
        try:  # on Kaggle: Add-ons → Secrets
            from kaggle_secrets import UserSecretsClient

            key = UserSecretsClient().get_secret("ROBOFLOW_API_KEY")
        except Exception:  # noqa: BLE001 (not on Kaggle, or no such secret)
            key = None
    return key


def roboflow(out: Path, key: str, splits, limit: int, workers: int) -> dict:
    """ROBOFLOW_SETS: original photos (shrunk to ROBOFLOW_SIDE) with their boxes mapped to our ids, near-duplicate
    photos removed by image embedding. Their other objects, text and hands are auto-labelled later, like EgoHands.
    → {name: record}."""
    import numpy as np
    from PIL import Image

    def api(path: str, body=None):
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(f"https://api.roboflow.com/{path}?api_key={key}", data=data,
                                         headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:  # never show the URL: it holds the key
            raise OSError(f"Roboflow API: HTTP {e.code}") from None

    jobs, seen_names = [], set()
    for ref in ROBOFLOW_SETS:
        rows, offset = [], 0
        while True:
            page = api(f"{ref}/search", {"limit": 250, "offset": offset, "fields": ["id", "name", "split"]})
            rows += page["results"]
            offset += 250
            if offset >= page["total"]:
                break
        frames = sorted((r for r in rows if r["name"].startswith("frame_")), key=lambda r: r["name"])
        drop = {r["id"] for i, r in enumerate(frames) if i % ROBOFLOW_FRAME_EVERY}
        kept = 0
        for r in rows:
            if r["name"] in seen_names or r["id"] in drop or r["name"].startswith(ROBOFLOW_SKIP_PREFIXES.get(ref, ())):
                continue  # same photo in andre's two sets, a near-identical frame, or a shelf photo
            split = "train" if ref in ROBOFLOW_TRAIN_ONLY or r.get("split") == "train" else "val"
            if split in splits:
                seen_names.add(r["name"])
                jobs.append((ref, r["id"], split))
                kept += 1
        print(f"Roboflow {ref}: {len(rows)} photos, {kept} kept", flush=True)
    if limit:
        jobs = jobs[:limit]

    # 1. each photo's boxes, size, address and embedding (one API call each)
    def details(job):
        ref, image_id, _ = job
        try:
            image = api(f"{ref}/images/{image_id}")["image"]
            return job, image["annotation"], image["urls"]["original"], image.get("embedding")
        except (OSError, KeyError, ValueError):
            return None

    with ThreadPoolExecutor(min(workers, 16)) as pool:
        found = [d for d in pool.map(details, jobs) if d]

    # 2. the same photo in several sets (scraped shop photos, repeated shots): keep the first
    kept, n = [], 0
    vectors = np.zeros((len(found), max((len(d[3]) for d in found if d[3]), default=1)))
    for d in found:
        if d[3]:
            v = np.asarray(d[3], dtype=float)
            v /= np.linalg.norm(v)
            if n and float(np.max(vectors[:n] @ v)) > ROBOFLOW_DUPLICATE:
                continue
            vectors[n] = v
            n += 1
        kept.append(d)
    print(f"Roboflow: {len(found)} photos, {len(found) - len(kept)} near-duplicates removed", flush=True)

    # 3. download the kept photos, shrink them, map their boxes
    def fetch(d):
        (ref, image_id, split), annotation, url, _ = d
        name = f"rf_{ref.split('/')[1]}_{image_id}"
        target = out / "images" / split / f"{name}.jpg"
        target.parent.mkdir(parents=True, exist_ok=True)
        try:
            W, H = float(annotation["width"]), float(annotation["height"])
            s = min(1.0, ROBOFLOW_SIDE / max(W, H))
            w, h = round(W * s), round(H * s)
            if not target.exists():
                with urllib.request.urlopen(url, timeout=60) as r:
                    raw = r.read()
                with Image.open(io.BytesIO(raw)) as photo:
                    photo.convert("RGB").resize((w, h)).save(target, quality=92)
        except (OSError, KeyError, ValueError):
            return None
        mapping = ROBOFLOW_SETS[ref]
        boxes = []
        for b in annotation.get("boxes", []):
            cls = mapping.get(str(b.get("label")), mapping.get("*"))
            if cls is None:
                continue  # a label we don't use (e.g. objects_v2's "bag"): the auto-labels cover it
            x, y, bw, bh = (float(b[k]) * s for k in ("x", "y", "width", "height"))  # x, y = the box centre
            box = clip((x - bw / 2, y - bh / 2, bw, bh), w, h)
            if box:
                boxes.append((cls, box))
        return name, {"split": split, "source": "roboflow", "file": target, "w": w, "h": h, "boxes": boxes,
                      "dropped": 0, "labels": {"coco": "none", "lvis": "roboflow", "text": "none", "hand": "none"}}

    records = {}
    with ThreadPoolExecutor(min(workers, 16)) as pool:
        for got in pool.map(fetch, kept):
            if got:
                records[got[0]] = got[1]
    per_class = Counter(c for r in records.values() for c, _ in r["boxes"])
    print(f"Roboflow boxes: keys {per_class[80]}, wallet {per_class[82]}, pill_box {per_class[83]}", flush=True)
    return records


# ---------- 7. EgoHands ----------

def egohands(root: Path, limit: int, splits) -> dict:
    """EgoHands frames → records (hands only; COCO classes and text are auto-labelled later)."""
    import numpy as np
    from scipy.io import loadmat

    # Kaggle doesn't always mount an input under its slug: search every input if needed
    hits = list(root.rglob("_LABELLED_SAMPLES")) if root.exists() else []
    if not hits and Path("/kaggle/input").exists():
        hits = list(Path("/kaggle/input").rglob("_LABELLED_SAMPLES"))
    if not hits:
        # not attached: fetch it with kagglehub (on the Kaggle machine; preinstalled in Kaggle notebooks)
        import kagglehub

        print(f"EgoHands not attached; downloading {EGOHANDS_KAGGLE} with kagglehub (~1.3 GB) …", flush=True)
        hits = list(Path(kagglehub.dataset_download(EGOHANDS_KAGGLE)).rglob("_LABELLED_SAMPLES"))
    if not hits:
        raise SystemExit(f"EgoHands not found: open kaggle.com/datasets/{EGOHANDS_KAGGLE} and check it still exists")
    print(f"EgoHands found at {hits[0]}", flush=True)
    videos = sorted(p for p in hits[0].iterdir() if (p / "polygons.mat").exists())
    by_activity = defaultdict(list)
    for v in videos:
        by_activity[v.name.split("_")[0]].append(v.name)
    rng = random.Random(0)
    val = {name for names in by_activity.values() for name in rng.sample(sorted(names), EGO_VAL_PER_ACTIVITY)}

    records = {}
    for v in videos:
        split = "val" if v.name in val else "train"
        if split not in splits:
            continue
        frames = sorted(v.glob("frame_*.jpg"))
        polygons = loadmat(v / "polygons.mat")["polygons"][0]
        if len(polygons) != len(frames):
            raise SystemExit(f"{v.name}: {len(polygons)} polygon sets for {len(frames)} frames")
        for frame, hands in list(zip(frames, polygons))[: limit or None]:
            boxes = []
            for hand in hands:  # my left, my right, your left, your right
                pts = np.asarray(hand, dtype=float).reshape(-1, 2) if np.size(hand) else np.zeros((0, 2))
                if len(pts) >= 3:
                    x0, y0 = pts.min(0)
                    x1, y1 = pts.max(0)
                    box = clip((x0, y0, x1 - x0, y1 - y0), 1280, 720)
                    if box:
                        boxes.append((HAND, box))
            name = f"egohands_{v.name}_{frame.stem.split('_')[1]}"
            records[name] = {"split": split, "source": "egohands", "path": frame, "w": 1280, "h": 720,
                             "boxes": boxes, "dropped": 0,
                             "labels": {"coco": "none", "lvis": "none", "text": "none", "hand": "egohands"}}
    return records


# ---------- 8. auto-labels (GPU) ----------

def auto_text(records: list) -> int:
    """CRAFT text boxes for images COCO-Text doesn't cover (§4.2 step 5)."""
    import easyocr

    reader = easyocr.Reader(["en"], gpu=True, recognizer=False, verbose=False)
    added = 0
    for i, r in enumerate(records):
        horizontal, free = reader.detect(str(r["file"]), canvas_size=1280)
        boxes = [(x0, y0, x1 - x0, y1 - y0) for x0, x1, y0, y1 in horizontal[0]]
        for poly in free[0]:
            xs, ys = [p[0] for p in poly], [p[1] for p in poly]
            boxes.append((min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys)))
        for box in boxes:
            box = clip(box, r["w"], r["h"])
            if box and box[3] >= MIN_TEXT * r["h"]:
                r["boxes"].append((TEXT, box))
                added += 1
        r["labels"]["text"] = "craft-auto"
        if i % 1000 == 0:
            print(f"  text auto-labels: {i}/{len(records)}", flush=True)
    return added


def auto_hands(records: list, cache: Path) -> int:
    """MediaPipe's hand detector labels the hands on Objects365 and Roboflow photos (they have no hand class)."""
    import mediapipe as mp
    import numpy as np
    from mediapipe.tasks.python import vision
    from mediapipe.tasks.python.core.base_options import BaseOptions
    from PIL import Image

    model = fetch(MEDIAPIPE_HANDS, cache / "hand_landmarker.task")
    detector = vision.HandLandmarker.create_from_options(vision.HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(model)), num_hands=6, min_hand_detection_confidence=0.4))
    added = 0
    for i, r in enumerate(records):
        with Image.open(r["file"]) as image:
            rgb = np.ascontiguousarray(np.asarray(image.convert("RGB")))
        for hand in detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)).hand_landmarks:
            xs, ys = [p.x * r["w"] for p in hand], [p.y * r["h"] for p in hand]
            pw, ph = (max(xs) - min(xs)) * HAND_PAD, (max(ys) - min(ys)) * HAND_PAD
            box = clip((min(xs) - pw, min(ys) - ph, max(xs) - min(xs) + 2 * pw, max(ys) - min(ys) + 2 * ph), r["w"], r["h"])
            if box:
                r["boxes"].append((HAND, box))
                added += 1
        r["labels"]["hand"] = "mediapipe-auto"
        if i % 2000 == 0:
            print(f"  hand auto-labels: {i}/{len(records)}", flush=True)
    detector.close()
    return added


def auto_coco(records: list) -> int:
    """The stock yolo11n labels the 80 COCO classes on EgoHands and Roboflow photos (§4.2 steps 6c, 7)."""
    from ultralytics import YOLO

    model = YOLO("yolo11n.pt")
    added = 0
    for r, result in zip(records, model.predict([str(r["file"]) for r in records], imgsz=640,
                                                conf=AUTO_COCO_CONF, stream=True, verbose=False)):
        for cls, (x0, y0, x1, y1) in zip(result.boxes.cls.tolist(), result.boxes.xyxy.tolist()):
            r["boxes"].append((int(cls), (x0, y0, x1 - x0, y1 - y0)))
            added += 1
        r["labels"]["coco"] = "yolo11n-auto"
    return added


# ---------- 9. zoomed crops ----------

def zoom_crops(records: dict, out: Path, seed: int = 0) -> dict:
    """Small objects (keys, pill boxes… a few pixels at 320) seen up close: a square crop of the
    full-size photo around the object, with every label inside it. Train only; val stays natural.
    → {name: record} of the new crops."""
    from PIL import Image

    rng = random.Random(seed)
    crops = {}
    for name, r in sorted(records.items()):
        if r["split"] != "train" or r["source"] == "egohands":
            continue
        W, H = r["w"], r["h"]
        small = [b for c, b in r["boxes"] if c in ZOOM_CLASSES and max(b[2], b[3]) < ZOOM_SMALL * max(W, H)]
        if not small:
            continue
        rng.shuffle(small)
        with Image.open(r["file"]) as image:
            image = image.convert("RGB")
            for k, (x, y, w, h) in enumerate(small[:ZOOM_PER_IMAGE]):
                side = int(min(max(ZOOM_CONTEXT * max(w, h), ZOOM_MIN_SIDE), W, H))
                # a random position that keeps the whole object inside, so it isn't always centred
                x0 = int(rng.uniform(max(0.0, x + w - side), min(x, W - side)))
                y0 = int(rng.uniform(max(0.0, y + h - side), min(y, H - side)))
                boxes = []
                for c, (bx, by, bw, bh) in r["boxes"]:
                    ix0, iy0 = max(bx, x0), max(by, y0)
                    ix1, iy1 = min(bx + bw, x0 + side), min(by + bh, y0 + side)
                    if ix1 <= ix0 or iy1 <= iy0:
                        continue
                    inside = (ix1 - ix0) * (iy1 - iy0)
                    if inside >= ZOOM_KEEP_BOX * bw * bh or inside >= ZOOM_KEEP_FILL * side * side:
                        boxes.append((c, (ix0 - x0, iy0 - y0, ix1 - ix0, iy1 - iy0)))
                crop_name = f"{name}_zoom{k}"
                target = out / "images" / "train" / f"{crop_name}.jpg"
                image.crop((x0, y0, x0 + side, y0 + side)).save(target, quality=92)
                crops[crop_name] = {"split": "train", "source": "zoom", "file": target, "w": side, "h": side,
                                    "boxes": boxes, "dropped": 0, "labels": dict(r["labels"])}
    return crops


# ---------- writing ----------

def place_images(records: dict, out: Path, workers: int) -> None:
    def one(item):
        name, r = item
        target = out / "images" / r["split"] / f"{name}.jpg"
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            try:
                if "path" in r:
                    shutil.copy(r["path"], target)
                else:
                    target.write_bytes(urllib.request.urlopen(r["url"], timeout=60).read())
            except OSError:
                return name, None
        return name, target

    with ThreadPoolExecutor(workers) as pool:
        for name, target in pool.map(one, list(records.items())):
            if target is None:
                del records[name]
            else:
                records[name]["file"] = target


def write_labels(records: dict, out: Path) -> None:
    for name, r in records.items():
        folder = out / "labels" / r["split"]
        folder.mkdir(parents=True, exist_ok=True)
        rows = [f"{cls} {(x + bw / 2) / r['w']:.6f} {(y + bh / 2) / r['h']:.6f} {bw / r['w']:.6f} {bh / r['h']:.6f}"
                for cls, (x, y, bw, bh) in r["boxes"] if bw > 0 and bh > 0]
        (folder / f"{name}.txt").write_text("\n".join(rows), encoding="utf-8")
    with open(out / "manifest.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["image", "split", "source", "coco_labels", "lvis_labels", "text_labels", "hand_labels", "boxes_dropped"])
        for name, r in sorted(records.items()):
            lab = r["labels"]
            w.writerow([f"{name}.jpg", r["split"], r["source"], lab["coco"], lab["lvis"], lab["text"], lab["hand"], r["dropped"]])


def write_yaml(out: Path, names: dict) -> Path:
    yaml = out / "remori_objects.yaml"
    lines = "\n".join(f"  {i}: {names[i]}" for i in range(87))
    yaml.write_text(f"path: {out.resolve().as_posix()}\ntrain: images/train\nval: images/val\nnames:\n{lines}\n",
                    encoding="utf-8")
    return yaml


def all_names(names: dict) -> dict:
    full = dict(names)
    full.update({cls: name for cls, (name, _) in OURS.items()})
    full.update({TEXT: "text", HAND: "hand"})
    return full


def report(records: dict, names: dict) -> list:
    """Prints the counts (README §4.3) and returns the problems that should stop the run."""
    problems = []
    for split in ("train", "val"):
        rs = [r for r in records.values() if r["split"] == split]
        if not rs:
            continue
        print(f"\n[{split}] {len(rs)} images · by source: {dict(Counter(r['source'] for r in rs))}")
        imgs, boxes = Counter(), Counter()
        for r in rs:
            boxes.update(c for c, _ in r["boxes"])
            imgs.update({c for c, _ in r["boxes"]})
        print(f"[{split}] our classes (images / boxes): "
              + ", ".join(f"{names[c]} {imgs[c]}/{boxes[c]}" for c in (67, *OURS, TEXT, HAND)))
        rare = sorted((imgs[c], names[c]) for c in range(80))[:10]
        print(f"[{split}] the 10 rarest COCO classes (images): " + ", ".join(f"{n} {k}" for k, n in rare))
        print(f"[{split}] label sources: " + "; ".join(
            f"{k} {dict(Counter(r['labels'][k] for r in rs))}" for k in ("coco", "lvis", "text", "hand")))
        print(f"[{split}] boxes dropped (crowd + double labels): {sum(r['dropped'] for r in rs)}")
        if split == "train":  # zoomed crops repeat photos, so they don't count here
            real = Counter(c for r in rs if r["source"] != "zoom" for c in {c for c, _ in r["boxes"]})
            problems += [f"{names[c]}: only {real[c]} train photos" for c in (*OURS, TEXT, HAND)
                         if real[c] < MIN_TRAIN_IMAGES]
    return problems


def coco_val_check(out: Path, cache: Path) -> None:
    """COCO val2017 in YOLO format, for the forgetting check (README §8)."""
    coco = coco_instances("val2017", cache)
    cats = sorted(coco["categories"], key=lambda c: c["id"])
    order = {c["id"]: i for i, c in enumerate(cats)}
    images = out / "images" / "val"
    if not images.exists():
        z = fetch(COCO_VAL_IMAGES, cache / "val2017.zip")
        with zipfile.ZipFile(z) as zf:
            zf.extractall(out / "images")
        (out / "images" / "val2017").rename(images)
    size = {img["id"]: (img["width"], img["height"]) for img in coco["images"]}
    rows = defaultdict(list)
    for a in coco["annotations"]:
        if a.get("iscrowd"):
            continue
        w, h = size[a["image_id"]]
        x, y, bw, bh = a["bbox"]
        rows[a["image_id"]].append(f"{order[a['category_id']]} {(x + bw / 2) / w:.6f} {(y + bh / 2) / h:.6f} {bw / w:.6f} {bh / h:.6f}")
    labels = out / "labels" / "val"
    labels.mkdir(parents=True, exist_ok=True)
    for iid in size:
        (labels / f"{iid:012d}.txt").write_text("\n".join(rows.get(iid, [])), encoding="utf-8")
    names80 = {i: c["name"] for i, c in enumerate(cats)}
    for file, names in (("coco80.yaml", names80), ("coco87.yaml", all_names(names80))):
        lines = "\n".join(f"  {i}: {n}" for i, n in names.items())
        (out / file).write_text(f"path: {out.resolve().as_posix()}\ntrain: images/val\nval: images/val\nnames:\n{lines}\n",
                                encoding="utf-8")
    print(f"COCO val2017: {len(size)} images → {out}/coco80.yaml (stock yolo11n), {out}/coco87.yaml (ours)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=Path("data"))
    parser.add_argument("--cache", type=Path, default=None, help="annotation files (default: <out>/annotations)")
    parser.add_argument("--egohands", type=Path, default=Path("/kaggle/input/egohands"))
    parser.add_argument("--split", choices=["train", "val", "both"], default="both")
    parser.add_argument("--limit", type=int, default=0, help="at most N images per split and source (testing)")
    parser.add_argument("--skip", default="", help="comma list of: wholebody, objects365, roboflow, egohands, auto (testing)")
    parser.add_argument("--workers", type=int, default=64)
    parser.add_argument("--accept-low-counts", action="store_true", help="write the data even if a class is thin")
    parser.add_argument("--coco-val", type=Path, default=None, help="only build COCO val2017 for the forgetting check")
    parser.add_argument("--extract-hands", choices=["train", "val"], help=argparse.SUPPRESS)  # internal, see hands_of
    parser.add_argument("--extract-o365", help=argparse.SUPPRESS)  # internal, see objects365
    args = parser.parse_args()
    cache = args.cache or args.out / "annotations"
    cache.mkdir(parents=True, exist_ok=True)
    if args.extract_hands:
        extract_hands(args.extract_hands, cache)
        return
    if args.extract_o365:
        extract_o365(cache, args.extract_o365.split(","))
        return
    if args.coco_val:
        coco_val_check(args.coco_val, cache)
        return
    skip = {s.strip() for s in args.skip.split(",") if s.strip()}
    splits = ["train", "val"] if args.split == "both" else [args.split]

    # 1. LVIS → kept images + the reminder set, per split
    photos = {}
    for split in splits:
        kept, pool, stats = from_lvis(lvis(split, cache), split)
        reminder = pick_reminder(pool, split, REMINDER[split])
        if args.limit:
            kept = dict(list(kept.items())[: args.limit])
            reminder = dict(list(reminder.items())[: args.limit])
        print(f"[{split}] " + ", ".join(f"{k}: {v}" for k, v in stats.items()) + f", reminder: {len(reminder)}", flush=True)
        photos.update(kept)
        photos.update(reminder)

    # 2–6. the labels of the other datasets, joined by COCO image id
    names = {}
    print(add_coco(photos, cache, names), flush=True)
    for r in photos.values():
        drop_doubles(r)
    print(dict(add_coco_text(photos, cache)), flush=True)
    if "wholebody" not in skip:
        print(dict(add_wholebody(photos, cache)), flush=True)
    records = {f"coco_{iid:012d}": r for iid, r in photos.items()}

    # Objects365: more keys, wallets, glasses, phones and stoves
    if "objects365" not in skip:
        o365 = objects365(args.out, cache, names, splits, args.limit, args.workers)
        print(f"Objects365: {len(o365)} photos, {sum(len(r['boxes']) for r in o365.values())} boxes", flush=True)
        records.update(o365)

    # Roboflow: pill organisers, medicine boxes, keys at home, wallets (needs ROBOFLOW_API_KEY; skipped without it)
    if "roboflow" not in skip:
        key = roboflow_key()
        if key:
            rf = roboflow(args.out, key, splits, args.limit, args.workers)
            print(f"Roboflow: {len(rf)} photos kept", flush=True)
            records.update(rf)
        else:
            print("Roboflow skipped: no ROBOFLOW_API_KEY (Kaggle: Add-ons → Secrets)", flush=True)

    # 7. EgoHands
    if "egohands" not in skip:
        ego = egohands(args.egohands, args.limit, splits)
        print(f"EgoHands: {len(ego)} frames, {sum(len(r['boxes']) for r in ego.values())} hands", flush=True)
        records.update(ego)

    place_images(records, args.out, args.workers)

    # 8. auto-labels
    if "auto" not in skip:
        need_text = [r for r in records.values() if r["labels"]["text"] == "none"]
        print(f"CRAFT text boxes: {auto_text(need_text)} on {len(need_text)} images", flush=True)
        no_coco = [r for r in records.values() if r["source"] in ("egohands", "roboflow")]
        if no_coco:
            print(f"yolo11n COCO boxes on EgoHands + Roboflow: {auto_coco(no_coco)} on {len(no_coco)} photos", flush=True)
        no_hands = [r for r in records.values() if r["source"] in ("objects365", "roboflow")]
        if no_hands:
            print(f"MediaPipe hand boxes on Objects365 + Roboflow: {auto_hands(no_hands, cache)} on {len(no_hands)} photos",
                  flush=True)

    # 9. zoomed crops (after the auto-labels, so the crops carry the text boxes too)
    crops = zoom_crops(records, args.out)
    print(f"zoomed crops of small objects: {len(crops)}", flush=True)
    records.update(crops)

    names = all_names(names)
    problems = report(records, names)
    write_labels(records, args.out)
    yaml = write_yaml(args.out, names)
    print(f"\ndataset: {yaml} · manifest: {args.out / 'manifest.csv'}")
    if problems and not args.accept_low_counts:
        raise SystemExit("STOP, tell the lead before training (README §4.3):\n  " + "\n  ".join(problems))


if __name__ == "__main__":
    main()
