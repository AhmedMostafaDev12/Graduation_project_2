"""Download the visual-memory text model pinned by spec D34/D41 and check it.

MobileCLIP-S0 (Apple), the ONNX export by Xenova, at a fixed revision. The server needs only the
**text** half (a search question → a 512-d vector in the same space as the frame vectors the
glasses compute with the image half) and its tokenizer. Run by the Dockerfile at image build,
and once locally:

    cd backend-ai
    python scripts/download_visual_models.py            # → backend-ai/models (gitignored)
    python scripts/download_visual_models.py /code/models

Standard library only, so it runs before the app's requirements are installed. MobileCLIP's
weights are licensed by Apple for research use (apple-amlr): fine for the graduation project,
to be replaced before any product release.
"""

import hashlib
import sys
import urllib.request
from pathlib import Path

# Xenova/mobileclip_s0 as of 17 Apr 2025
REVISION = "757d59c9c6870a76a4b0306f05f5061bca15c39f"
BASE = f"https://huggingface.co/Xenova/mobileclip_s0/resolve/{REVISION}/"
# local name → (path in the repository, SHA-256)
FILES = {
    "mobileclip_s0_text_int8.onnx": (
        "onnx/text_model_int8.onnx",
        "fc8d87978623385c17a46331ffb9cb5ab7fe8b61c513c094602b85f08edd0a0b",
    ),
    "mobileclip_s0_tokenizer.json": (
        "tokenizer.json",
        "72ed5c96db5729294468543e4bc75fce14ca63f58e37300290189ba1c1e52b85",
    ),
}
DEFAULT_DIR = Path(__file__).resolve().parents[1] / "models"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DIR
    target.mkdir(parents=True, exist_ok=True)
    for name, (remote, expected) in FILES.items():
        out = target / name
        if out.exists() and sha256(out) == expected:
            continue
        print(f"downloading {remote}")
        # a fixed https URL, checked below
        urllib.request.urlretrieve(BASE + remote, out)
        if sha256(out) != expected:
            out.unlink()
            raise SystemExit(f"{name} checksum mismatch: refusing to use it")
    print(f"visual models ready in {target}: {', '.join(FILES)}")


if __name__ == "__main__":
    main()
