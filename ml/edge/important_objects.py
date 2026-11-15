"""The important-object detector and its gate rules (spec D33, D42; guide
ml/capture_gate/important_objects/README.md §10).

    detector = Detector("remori_objects_v2.onnx", thresholds_json="thresholds.json")
    detections = detector.detect(rgb)          # an H × W × 3 uint8 frame
    rules = fires(detections, detector.thresholds)   # e.g. ["important_object", "text"]

Classes are the 87-class contract: 0–79 COCO, 80 keys, 81 glasses, 82 wallet, 83 pill_box,
84 stove, 85 text, 86 hand. The model finds glasses worn or not; the rule skips a pair being
worn (its box centred in the top 35 % of a person box).
"""

import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np

PERSON, CELL_PHONE = 0, 67
KEYS, GLASSES, WALLET, PILL_BOX, STOVE, TEXT, HAND = 80, 81, 82, 83, 84, 85, 86
NAMES = {
    CELL_PHONE: "cell phone",
    KEYS: "keys",
    GLASSES: "glasses",
    WALLET: "wallet",
    PILL_BOX: "pill_box",
    STOVE: "stove",
    TEXT: "text",
    HAND: "hand",
    PERSON: "person",
}

# rule → the classes that fire it (gate_rule values of spec §7.1)
RULES = {
    "important_object": (KEYS, GLASSES, WALLET, CELL_PHONE, STOVE),
    "medication": (PILL_BOX,),
    "text": (TEXT,),
}
DEFAULT_THRESHOLD = 0.25
PERSON_THRESHOLD = 0.3
WORN_TOP = 0.35


@dataclass(frozen=True)
class Detection:
    cls: int
    score: float
    box: tuple  # x0, y0, x1, y1 in frame pixels


def worn(glasses: Detection, people: list) -> bool:
    """Glasses centred in the top 35 % of a person box are being worn: not "glasses put down"."""
    x0, y0, x1, y1 = glasses.box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    return any(
        p.box[0] <= cx <= p.box[2]
        and p.box[1] <= cy <= p.box[1] + (p.box[3] - p.box[1]) * WORN_TOP
        for p in people
    )


def on_clothing(text: Detection, people: list) -> bool:
    """Text inside another person's box is printed on their clothes (a shirt, a cap): nothing to
    read. Text the wearer holds (a letter, a medicine box) isn't inside anyone's box: the wearer
    isn't in their own view. Measured on SuperMemory-VQA: an exception for "a hand near / over
    the text" let one shirt print through 421 times (hands clasped or holding a plate)."""
    x0, y0, x1, y1 = text.box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    return any(
        p.box[0] <= cx <= p.box[2] and p.box[1] <= cy <= p.box[3] for p in people
    )


def text_boxes(detections: list, thresholds: dict) -> list:
    """The text boxes that can fire the text rule: above threshold, not on clothing."""
    people = [d for d in detections if d.cls == PERSON and d.score >= PERSON_THRESHOLD]
    return [
        d
        for d in detections
        if d.cls == TEXT
        and d.score >= thresholds.get(TEXT, DEFAULT_THRESHOLD)
        and not on_clothing(d, people)
    ]


def fires(detections: list, thresholds: dict) -> list:
    """The gate rules this frame fires, in RULES order (empty: no rule). For the text rule, see
    also TextMemory: the same text seen again shouldn't keep fire after fire."""
    people = [d for d in detections if d.cls == PERSON and d.score >= PERSON_THRESHOLD]
    fired = []
    for rule, classes in RULES.items():
        if rule == "text":
            if text_boxes(detections, thresholds):
                fired.append(rule)
            continue
        for d in detections:
            if d.cls in classes and d.score >= thresholds.get(d.cls, DEFAULT_THRESHOLD):
                if d.cls == GLASSES and worn(d, people):
                    continue
                fired.append(rule)
                break
    return fired


class TextMemory:
    """Remembers a fingerprint of each text region seen (a 64-bit difference hash of its crop) for
    `window_s` seconds. The text rule fires only for text that isn't among them: the same sign,
    label or poster in view minute after minute keeps one frame, not hundreds."""

    def __init__(self, window_s: float = 120.0, max_distance: int = 10):
        self.window_s, self.max_distance = window_s, max_distance
        self.seen: list = []  # (time, fingerprint)

    @staticmethod
    def fingerprint(rgb: np.ndarray, box: tuple) -> int:
        from PIL import Image

        x0, y0, x1, y1 = (int(v) for v in box)
        crop = rgb[max(0, y0) : max(y0 + 1, y1), max(0, x0) : max(x0 + 1, x1)]
        small = np.asarray(
            Image.fromarray(crop).convert("L").resize((9, 8)), dtype=np.int16
        )
        bits = (small[:, 1:] > small[:, :-1]).flatten()
        return int("".join("1" if b else "0" for b in bits), 2)

    def any_new(self, rgb: np.ndarray, boxes: list, t: float) -> bool:
        """True when at least one of these text boxes wasn't seen in the window; every box seen
        now is remembered either way."""
        self.seen = [(s, f) for s, f in self.seen if t - s <= self.window_s]
        new = False
        for d in boxes:
            f = self.fingerprint(rgb, d.box)
            if not any((f ^ g).bit_count() <= self.max_distance for _, g in self.seen):
                new = True
            self.seen.append((t, f))
        return new


class Detector:
    """A YOLO detector exported to ONNX (Ultralytics layout [1, 4 + classes, anchors], scores in 0–1)."""

    def __init__(
        self,
        model: str | Path,
        thresholds_json: str | Path | None = None,
        imgsz: int = 320,
    ):
        import onnxruntime as ort

        self.session = ort.InferenceSession(
            str(model), providers=["CPUExecutionProvider"]
        )
        self.input = self.session.get_inputs()[0].name
        self.imgsz = imgsz
        self.thresholds = {}
        if thresholds_json and Path(thresholds_json).exists():
            by_name = {v: k for k, v in NAMES.items()}
            for name, row in json.loads(
                Path(thresholds_json).read_text(encoding="utf-8")
            )["classes"].items():
                if name in by_name:
                    self.thresholds[by_name[name]] = float(row["threshold"])

    def detect(self, rgb: np.ndarray, min_score: float = 0.05) -> list:
        """Letterbox to imgsz (grey 114, as in training), run, map boxes back to frame pixels.
        No NMS: the rules only ask whether a class is present above its threshold, and where."""
        h, w = rgb.shape[:2]
        s = self.imgsz / max(h, w)
        nh, nw = round(h * s), round(w * s)
        from PIL import Image

        resized = np.asarray(Image.fromarray(rgb).resize((nw, nh), Image.BILINEAR))
        canvas = np.full((self.imgsz, self.imgsz, 3), 114, np.uint8)
        top, left = (self.imgsz - nh) // 2, (self.imgsz - nw) // 2
        canvas[top : top + nh, left : left + nw] = resized
        x = canvas.transpose(2, 0, 1)[None].astype(np.float32) / 255.0
        out = self.session.run(None, {self.input: x})[0][0]  # [4 + classes, anchors]
        boxes, scores = out[:4].T, out[4:].T
        cls = scores.argmax(1)
        best = scores[np.arange(len(cls)), cls]
        keep = best >= min_score
        found = []
        for (cx, cy, bw, bh), c, sc in zip(boxes[keep], cls[keep], best[keep]):
            x0, y0 = (cx - bw / 2 - left) / s, (cy - bh / 2 - top) / s
            x1, y1 = (cx + bw / 2 - left) / s, (cy + bh / 2 - top) / s
            found.append(
                Detection(
                    int(c),
                    float(sc),
                    (max(0.0, x0), max(0.0, y0), min(w, x1), min(h, y1)),
                )
            )
        return found
