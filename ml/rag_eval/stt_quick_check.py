"""Quick speech-to-text check on public Egyptian Arabic data: WER / CER (docs: backend-ai/docs/MODELS_CHOICE.md §8).

Downloads 20 clips each from two public datasets on Hugging Face (with their human
transcripts), transcribes them with the backend's speech-to-text client, and reports word
and character error rates after Arabic normalization.

    cd backend-ai
    python ../ml/rag_eval/stt_quick_check.py

- MGB-3 Egyptian (MightyStudent/Egyptian-ASR-MGB-3): real Egyptian TV/YouTube speech
- FLEURS ar_eg (google/fleurs, CC-BY 4.0): Egyptian speakers reading sentences

Needs DEEPGRAM_API_KEY in backend-ai/.env (a few cents per run). Audio is cached outside the
repo (~/.cache/remori/stt_quick_check); public research data only, never in git.
A quick check, not the research benchmark: that one uses our own recordings (RESEARCH_PLAN §6).
"""

import json
import re
import sys
import urllib.request
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[2] / "backend-ai"
sys.path.insert(0, str(BACKEND))
from app.ai.clients.stt import DeepgramSpeechToText

CACHE = Path.home() / ".cache" / "remori" / "stt_quick_check"
ROWS = "https://datasets-server.huggingface.co/rows?dataset={ds}&config={cfg}&split={split}&offset={off}&length=1"

# name: (dataset, config, split, transcript field, row offsets spread across the split)
SETS = {
    "MGB-3 Egyptian (TV/YouTube, conversational)": (
        "MightyStudent/Egyptian-ASR-MGB-3",
        "default",
        "train",
        "sentence",
        [i * 57 for i in range(20)],
    ),
    "FLEURS ar_eg (read speech)": (
        "google/fleurs",
        "ar_eg",
        "test",
        "transcription",
        [i * 21 for i in range(20)],
    ),
}

DIACRITICS = re.compile(r"[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")
PUNCTUATION = re.compile(r"[^\w\s]|_")
ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")


def normalize(text: str) -> str:
    """Remove diacritics/tatweel/punctuation and unify alef, ya, ta marbuta, hamza seats."""
    text = DIACRITICS.sub("", text.translate(ARABIC_DIGITS))
    text = re.sub("[أإآٱ]", "ا", text).replace("ى", "ي").replace("ة", "ه")
    text = text.replace("ؤ", "و").replace("ئ", "ي")
    return " ".join(PUNCTUATION.sub(" ", text.lower()).split())


def edit_distance(a: list | str, b: list | str) -> int:
    previous = list(range(len(b) + 1))
    for i, x in enumerate(a, 1):
        current = [i]
        for j, y in enumerate(b, 1):
            current.append(
                min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (x != y))
            )
        previous = current
    return previous[-1]


def fetch(ds: str, cfg: str, split: str, field: str, offset: int) -> tuple[bytes, str]:
    CACHE.mkdir(parents=True, exist_ok=True)
    wav = CACHE / f"{ds.replace('/', '_')}_{split}_{offset}.wav"
    meta = wav.with_suffix(".json")
    if not meta.exists():
        url = ROWS.format(ds=ds, cfg=cfg, split=split, off=offset)
        row = json.load(urllib.request.urlopen(url))["rows"][0]["row"]
        urllib.request.urlretrieve(row["audio"][0]["src"], wav)
        meta.write_text(
            json.dumps({"reference": row[field]}, ensure_ascii=False), encoding="utf-8"
        )
    return wav.read_bytes(), json.loads(meta.read_text(encoding="utf-8"))["reference"]


def main() -> None:
    stt = DeepgramSpeechToText()
    print(f"provider: {stt.model_id}\n")
    for name, (ds, cfg, split, field, offsets) in SETS.items():
        word_errors = words = char_errors = chars = 0
        for offset in offsets:
            audio, reference = fetch(ds, cfg, split, field, offset)
            hypothesis = stt.transcribe(audio, "audio/wav", language_hint="ar").text
            ref, hyp = normalize(reference), normalize(hypothesis)
            word_errors += edit_distance(ref.split(), hyp.split())
            words += len(ref.split())
            char_errors += edit_distance(ref.replace(" ", ""), hyp.replace(" ", ""))
            chars += len(ref.replace(" ", ""))
        print(
            f"{name:46} clips {len(offsets):3}  WER {word_errors / words:6.1%}  CER {char_errors / chars:6.1%}"
        )


if __name__ == "__main__":
    main()
