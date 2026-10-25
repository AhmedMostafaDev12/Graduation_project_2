"""Try the real speech-to-text provider on one audio file (manual check, never in CI).

    cd backend-ai
    python -m scripts.try_stt path/to/clip.ogg            # Egyptian Arabic (default)
    python -m scripts.try_stt path/to/clip.m4a --lang en

Uses DEEPGRAM_API_KEY from .env and costs a fraction of a cent per clip. Use only your
own voice or volunteers who agreed: never a patient's real conversation (MODELS_CHOICE.md §1).
"""

import argparse
import mimetypes
import time
from pathlib import Path

from app.ai.clients.stt import DeepgramSpeechToText

CONTENT_TYPES = {".ogg": "audio/ogg", ".opus": "audio/ogg", ".m4a": "audio/mp4"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("audio", type=Path)
    parser.add_argument("--lang", choices=["ar", "en"], default="ar")
    args = parser.parse_args()

    content_type = (
        CONTENT_TYPES.get(args.audio.suffix.lower())
        or mimetypes.guess_type(args.audio.name)[0]
        or "application/octet-stream"
    )
    started = time.perf_counter()
    result = DeepgramSpeechToText().transcribe(
        args.audio.read_bytes(), content_type, language_hint=args.lang
    )
    seconds = time.perf_counter() - started

    print(f"model={result.model_id} language={result.language} ({seconds:.1f} s)\n")
    for s in result.segments:
        print(f"[{s.start_s:6.1f}–{s.end_s:6.1f}] {s.speaker or '?'}: {s.text}")
    if not result.segments:
        print(result.text or "(no speech found)")


if __name__ == "__main__":
    main()
