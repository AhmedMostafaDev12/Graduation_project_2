"""Frame embeddings (spec D34, D41): every 1 fps frame → a 512-d vector, MobileCLIP-S0's image
half (float16 ONNX, Xenova/mobileclip_s0; its INT8 export is broken: frames one second apart
come out 0.43 alike instead of 0.90). The server embeds the question with the text half of
the same model, so a question and a frame can be compared directly.

Preprocessing is the model's own (its preprocessor_config.json): shortest side resized to 256
(bilinear), centre crop 256 × 256, values / 255, no mean/std normalisation.

    embedder = FrameEmbedder("mobileclip_s0_vision_fp16.onnx")
    vectors = embedder.embed([rgb])      # (1, 512) float32, unit length

MobileCLIP's weights are Apple's, research use only (apple-amlr).
"""

from pathlib import Path

import numpy as np
from PIL import Image

MODEL_ID = "mobileclip-s0@1.0"
SIDE = 256
DIM = 512


def preprocess(rgb: np.ndarray) -> np.ndarray:
    """H × W × 3 uint8 → 3 × 256 × 256 float32."""
    image = Image.fromarray(rgb)
    w, h = image.size
    scale = SIDE / min(w, h)
    image = image.resize(
        (max(SIDE, round(w * scale)), max(SIDE, round(h * scale))), Image.BILINEAR
    )
    w, h = image.size
    left, top = (w - SIDE) // 2, (h - SIDE) // 2
    image = image.crop((left, top, left + SIDE, top + SIDE))
    return (np.asarray(image, dtype=np.float32) / 255).transpose(2, 0, 1)


class FrameEmbedder:
    def __init__(self, model: str | Path, threads: int = 2):
        import onnxruntime as ort

        options = ort.SessionOptions()
        options.intra_op_num_threads = threads
        self.session = ort.InferenceSession(
            str(model), options, providers=["CPUExecutionProvider"]
        )
        self.input = self.session.get_inputs()[0].name

    def embed(self, images: list[np.ndarray]) -> np.ndarray:
        batch = np.stack([preprocess(rgb) for rgb in images])
        (vectors,) = self.session.run(None, {self.input: batch})
        return vectors / np.linalg.norm(vectors, axis=1, keepdims=True)
