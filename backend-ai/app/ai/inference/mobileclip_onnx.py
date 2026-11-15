"""MobileCLIP-S0's text half on the server (spec D34, D41; registry: mobileclip-s0-onnx).

The glasses embed every frame with the image half (ml/edge); a question is embedded here with
the text half, into the same 512-d space, so /assist can search what the glasses saw. The
float16 ONNX export (Xenova/mobileclip_s0, pinned revision; its INT8 export loses too much:
cosine 0.85–0.92 to float16) and its tokenizer come from
scripts/download_visual_models.py into VISUAL_MODELS_DIR. MobileCLIP is licensed by Apple for
research use (apple-amlr).
"""

from functools import cache
from pathlib import Path

import numpy as np

from app.ai.inference.clip_tokenizer import CONTEXT, ClipTokenizer
from app.config import settings

MODEL_ID = "mobileclip-s0@1.0"  # the same string the glasses send with their vectors (spec §7.1)
VISUAL_DIM = 512
TEXT_FILE = "mobileclip_s0_text_fp16.onnx"
TOKENIZER_FILE = "mobileclip_s0_tokenizer.json"


class VisualModelMissing(RuntimeError):
    """The model files aren't where VISUAL_MODELS_DIR points (run the download script)."""


def _models_dir() -> Path:
    return Path(settings.visual_models_dir)


@cache
def _text_model():
    import onnxruntime  # imported here: only processes that search frames pay for it

    paths = [_models_dir() / TEXT_FILE, _models_dir() / TOKENIZER_FILE]
    missing = [p.name for p in paths if not p.exists()]
    if missing:
        raise VisualModelMissing(
            f"visual model files missing in {_models_dir()}: {missing}. "
            "Run: python scripts/download_visual_models.py"
        )
    options = onnxruntime.SessionOptions()
    # one short text per question: leave the CPU to the other workers
    options.intra_op_num_threads = 1
    session = onnxruntime.InferenceSession(
        str(paths[0]), options, providers=["CPUExecutionProvider"]
    )
    return session, ClipTokenizer(paths[1])


class OnnxMobileClipText:
    """`VisualTextEmbedder` for the `production` and `small` profiles."""

    model_id = MODEL_ID
    dim = VISUAL_DIM

    def __init__(self):
        _text_model()  # fail at start if the model files are missing

    def embed_text(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        session, tokenizer = _text_model()
        # the export adds a fixed 77-position table: every text is padded to CLIP's full length,
        # with 0 ("!"), never read because CLIP pools at the end token (the highest id)
        batch = np.zeros((len(texts), CONTEXT), dtype=np.int64)
        for row, text in enumerate(texts):
            ids = tokenizer.encode(text)
            batch[row, : len(ids)] = ids
        vectors = session.run(None, {session.get_inputs()[0].name: batch})[0]
        vectors /= np.linalg.norm(vectors, axis=1, keepdims=True)
        return vectors.astype(float).tolist()
