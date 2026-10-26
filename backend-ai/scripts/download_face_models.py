"""Download the face models pinned by spec D14 and check them (phase 8.1).

Fetches InsightFace's official `buffalo_s` pack (v0.7 release), checks its SHA-256, and keeps
only the two files the server uses: the SCRFD detector and the MobileFaceNet embedder, each
checked again. Run by the Dockerfile at image build, and once locally:

    cd backend-ai
    python scripts/download_face_models.py            # → backend-ai/models (gitignored)
    python scripts/download_face_models.py /code/models

Standard library only, so it runs before the app's requirements are installed. The models are
licensed by InsightFace for non-commercial research use.
"""

import hashlib
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

PACK_URL = (
    "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_s.zip"
)
PACK_SHA256 = "d85a87f503f691807cd8bb97128bdf7a0660326cd9cd02657127fa978bab8b5e"
FILES = {
    "det_500m.onnx": "5e4447f50245bbd7966bd6c0fa52938c61474a04ec7def48753668a9d8b4ea3a",
    "w600k_mbf.onnx": "9cc6e4a75f0e2bf0b1aed94578f144d15175f357bdc05e815e5c4a02b319eb4f",
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
    if all((target / n).exists() and sha256(target / n) == h for n, h in FILES.items()):
        print(f"face models already present in {target}")
        return

    with tempfile.TemporaryDirectory() as tmp:
        pack = Path(tmp) / "buffalo_s.zip"
        print(f"downloading {PACK_URL}")
        urllib.request.urlretrieve(PACK_URL, pack)  # a fixed https URL, checked below
        if sha256(pack) != PACK_SHA256:
            raise SystemExit("buffalo_s.zip checksum mismatch: refusing to use it")
        with zipfile.ZipFile(pack) as archive:
            for name, expected in FILES.items():
                out = target / name
                out.write_bytes(archive.read(name))
                if sha256(out) != expected:
                    out.unlink()
                    raise SystemExit(f"{name} checksum mismatch: refusing to use it")
    print(f"face models ready in {target}: {', '.join(FILES)}")


if __name__ == "__main__":
    main()
