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
- The reminder set: ~5,000 more COCO photos with all their labels, so the 80 classes aren't forgotten.

Needs: numpy, scipy (EgoHands), gdown (WholeBody), easyocr and ultralytics (the auto-labels, GPU).
"""

import argparse
import csv
import json
import random
import shutil
import urllib.request
import zipfile
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

LVIS = "https://dl.fbaipublicfiles.com/LVIS/lvis_v1_{split}.json.zip"
COCO = "http://images.cocodataset.org/annotations/annotations_trainval2017.zip"
COCO_VAL_IMAGES = "http://images.cocodataset.org/zips/val2017.zip"
COCO_TEXT = "https://github.com/bgshih/cocotext/releases/download/dl/cocotext.v2.zip"
# COCO-WholeBody v1.0, official Google Drive files (github.com/jin-s13/COCO-WholeBody); the train
# file also has a Hugging Face mirror, used when Drive refuses (its daily quota).
WHOLEBODY_DRIVE = {"train": "1thErEToRbmM9uLNi1JXXfOsaS5VK2FXf", "val": "1N6VgwKnj8DeyGXCvp1eYgNbRmw6jdfrb"}
WHOLEBODY_MIRROR = {"train": "https://huggingface.co/hngan/cocowholebody/resolve/main/coco_wholebody_train_v1.0.json"}

# our classes after COCO's 80 (README §1); LVIS names for the five objects
OURS = {80: ("keys", "key"), 81: ("glasses", "spectacles"), 82: ("wallet", "wallet"),
        83: ("pill_box", "medicine"), 84: ("stove", "stove")}
TEXT, HAND = 85, 86
GLASSES = 81

WORN_TOP = 0.35         # a spectacles box centred in the top 35 % of a person box = worn (§4.2 step 3)
NEGATIVE_SHARE = 0.15   # LVIS images where our objects were checked absent
DOUBLE_IOU = 0.7        # ours vs a COCO box on the same object: keep ours (§4.2 step 4)
MIN_TEXT = 0.015        # text boxes lower than 1.5 % of the image height are too small to read
REMINDER = {"train": 4500, "val": 500}
EGO_VAL_PER_ACTIVITY = 2  # 8 of the 48 EgoHands videos go to val, 2 per activity
AUTO_COCO_CONF = 0.5    # stock yolo11n labels on EgoHands frames
# a class with fewer train images than this stops the run (README §4.3: tell the lead)
MIN_TRAIN_IMAGES = 50


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
        z = fetch(LVIS.format(split=split), cache / f"lvis_v1_{split}.json.zip")
        unzip_one(z, f"lvis_v1_{split}.json", target)
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


def worn(glasses_box, person_boxes) -> bool:
    x, y, w, h = glasses_box
    cx, cy = x + w / 2, y + h / 2
    return any(px <= cx <= px + pw and py <= cy <= py + ph * WORN_TOP for px, py, pw, ph in person_boxes)


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
    """Adds the 80 COCO classes (ids 0–79), drops worn glasses. → {coco category id: our id}."""
    persons = defaultdict(list)
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
            cls = order[a["category_id"]]
            record["boxes"].append((cls, tuple(a["bbox"])))
            if cls == 0:
                persons[a["image_id"]].append(a["bbox"])
        del coco

    # worn glasses aren't our class: remove their box, keep the photo (a worn pair left unlabeled
    # teaches the model not to fire on faces, README §1)
    removed = 0
    for iid, r in records.items():
        keep = [(cls, b) for cls, b in r["boxes"] if not (cls == GLASSES and worn(b, persons.get(iid, [])))]
        removed += len(r["boxes"]) - len(keep)
        r["boxes"] = keep
    return {"worn-glasses boxes removed": removed}


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


def add_wholebody(records: dict, cache: Path) -> Counter:
    stats = Counter()
    for part in ("train", "val"):
        if not any(f"{part}2017" in r["url"] for r in records.values()):
            continue
        wb = wholebody(part, cache)
        seen = {img["id"] for img in wb["images"]}
        for a in wb["annotations"]:
            record = records.get(a["image_id"])
            if record is None or a.get("iscrowd"):
                continue
            for side in ("lefthand", "righthand"):
                if a.get(f"{side}_valid"):
                    box = clip(a[f"{side}_box"], record["w"], record["h"])
                    if box:
                        record["boxes"].append((HAND, box))
                        stats["hand boxes from COCO-WholeBody"] += 1
        for iid, record in records.items():
            if iid in seen:
                record["labels"]["hand"] = "wholebody"
        del wb
    with_person = [r for r in records.values() if any(c == 0 for c, _ in r["boxes"])]
    stats["COCO photos with a person"] = len(with_person)
    stats["…of those with at least one hand box"] = sum(1 for r in with_person if any(c == HAND for c, _ in r["boxes"]))
    return stats


# ---------- 7. EgoHands ----------

def egohands(root: Path, limit: int, splits) -> dict:
    """EgoHands frames → records (hands only; COCO classes and text are auto-labelled later)."""
    import numpy as np
    from scipy.io import loadmat

    hits = list(root.rglob("_LABELLED_SAMPLES"))
    if not hits:
        raise SystemExit(f"EgoHands not found under {root}: add the Kaggle dataset 'himaniishah/egohands' as an input")
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


def auto_coco(records: list) -> int:
    """The stock yolo11n labels the 80 COCO classes on EgoHands frames (§4.2 step 7)."""
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
        if split == "train":
            problems += [f"{names[c]}: only {imgs[c]} train images" for c in (*OURS, TEXT, HAND)
                         if imgs[c] < MIN_TRAIN_IMAGES]
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
    parser.add_argument("--skip", default="", help="comma list of: wholebody, egohands, auto (testing)")
    parser.add_argument("--workers", type=int, default=64)
    parser.add_argument("--accept-low-counts", action="store_true", help="write the data even if a class is thin")
    parser.add_argument("--coco-val", type=Path, default=None, help="only build COCO val2017 for the forgetting check")
    args = parser.parse_args()
    cache = args.cache or args.out / "annotations"
    cache.mkdir(parents=True, exist_ok=True)
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
        ego_records = [r for r in records.values() if r["source"] == "egohands"]
        if ego_records:
            print(f"yolo11n COCO boxes on EgoHands: {auto_coco(ego_records)}", flush=True)

    names = all_names(names)
    problems = report(records, names)
    write_labels(records, args.out)
    yaml = write_yaml(args.out, names)
    print(f"\ndataset: {yaml} · manifest: {args.out / 'manifest.csv'}")
    if problems and not args.accept_low_counts:
        raise SystemExit("STOP, tell the lead before training (README §4.3):\n  " + "\n  ".join(problems))


if __name__ == "__main__":
    main()
