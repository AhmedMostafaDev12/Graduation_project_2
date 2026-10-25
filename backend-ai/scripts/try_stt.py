"""Try the real speech-to-text provider on one audio file (manual check, never in CI).

    cd backend-ai
    python -m scripts.try_stt path/to/clip.ogg            # Egyptian Arabic (default)
    python -m scripts.try_stt path/to/clip.m4a --lang en
    python -m scripts.try_stt path/to/clip.ogg --normalize   # boost quiet voices first

Uses DEEPGRAM_API_KEY from .env and costs a fraction of a cent per clip. Use only your
own voice or volunteers who agreed: never a patient's real conversation (MODELS_CHOICE.md §1).
"""

import argparse
import mimetypes
import subprocess
import time
from pathlib import Path

import imageio_ffmpeg

from app.ai.clients.stt import DeepgramSpeechToText

CONTENT_TYPES = {".ogg": "audio/ogg", ".opus": "audio/ogg", ".m4a": "audio/mp4"}

# dynaudnorm lifts quiet stretches (a softer or farther speaker) toward the main voice;
# loudnorm then evens out the overall level. 16 kHz mono is plenty for speech.
NORMALIZE_FILTER = "dynaudnorm=f=150:g=15:p=0.9,loudnorm=I=-16:TP=-1.5:LRA=11"


def normalize(audio: bytes) -> bytes:
    """Return the audio as loudness-normalized 16 kHz mono WAV."""
    result = subprocess.run(
        [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            "pipe:0",
            "-af",
            NORMALIZE_FILTER,
            "-ac",
            "1",
            "-ar",
            "16000",
            "-f",
            "wav",
            "pipe:1",
        ],
        input=audio,
        capture_output=True,
        check=True,
    )
    return result.stdout


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("audio", type=Path)
    parser.add_argument("--lang", choices=["ar", "en"], default="ar")
    parser.add_argument(
        "--normalize", action="store_true", help="boost quiet voices before sending"
    )
    args = parser.parse_args()

    content_type = (
        CONTENT_TYPES.get(args.audio.suffix.lower())
        or mimetypes.guess_type(args.audio.name)[0]
        or "application/octet-stream"
    )
    audio = args.audio.read_bytes()
    if args.normalize:
        audio, content_type = normalize(audio), "audio/wav"

    started = time.perf_counter()
    result = DeepgramSpeechToText().transcribe(
        audio, content_type, language_hint=args.lang
    )
    seconds = time.perf_counter() - started

    mode = "normalized" if args.normalize else "original"
    print(
        f"model={result.model_id} language={result.language} {mode} ({seconds:.1f} s)\n"
    )
    for s in result.segments:
        print(f"[{s.start_s:6.1f}–{s.end_s:6.1f}] {s.speaker or '?'}: {s.text}")
    if not result.segments:
        print(result.text or "(no speech found)")


if __name__ == "__main__":
    main()
