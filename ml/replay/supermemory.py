"""Replay SuperMemory-VQA recordings through Remori's real memory pipeline, then answer its
questions (research plan Track B; spec D33, D39, D40). Real AI calls.

For one participant's session(s):

1. **Speech:** the released transcript (raw audio isn't public) → `conversation_segment`
   events, one per stretch of talk (a new event after a silence or about a minute), with the
   dataset's speaker labels ("User" = the wearer).
2. **Frames:** one frame every `--every` seconds (a stand-in for the glasses' capture gate,
   which doesn't exist yet) → the real photo review (services/review_service.py: strangers
   pixelated, one Gemini call, discard / keep, documents, object sightings, actions). Storage
   is an in-memory stand-in so the real code runs unchanged. Discarded frames are removed
   with their empty event.
3. **Memory:** every event is rendered and embedded (services/embedding_service.py) and every
   conversation consolidated (services/memory_service.py: facts, plans, entities).
4. **Questions:** those whose evidence lies only in the replayed session(s), plus the
   unanswerable ones asked in them, go through the real /assist (rag/answer.py) at the time
   they were asked. A judge call maps each free answer to one of the 4 choices; the score is
   multiple-choice accuracy, per skill, with the five structures and without them (H6).

    docker compose -f docker-compose.dev.yml up -d db     # local Postgres, never Supabase
    cd backend-ai
    DATABASE_URL=postgresql+psycopg://remori:remori@localhost:5434/remori_test \\
      .venv/Scripts/python ../ml/replay/supermemory.py --person 10 --sessions 3

Data: https://huggingface.co/datasets/OSU-AIoT-MLSys-Lab/SuperMemory-VQA (CC BY-NC-SA 4.0:
research only, never in the product). Downloaded to ~/.cache/remori/supermemory, never git.
Needs GEMINI_API_KEY and VOYAGE_API_KEY in backend-ai/.env, ffmpeg (imageio-ffmpeg), and the
face models (scripts/download_face_models.py). Everything written to the database is
deleted at the end; results go to ~/.cache/remori/supermemory/results/.
"""

import argparse
import collections
import dataclasses
import hashlib
import json
import re
import subprocess
import sys
import time
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from functools import partial
from pathlib import Path

HERE = Path(__file__).resolve().parent
BACKEND = HERE.parents[1] / "backend-ai"
sys.path.insert(0, str(BACKEND))

import imageio_ffmpeg
import numpy as np
from PIL import Image
from sqlalchemy import delete, func, select

from app.ai.clients import groq as groq_client
from app.ai.rag import answer as answer_module
from app.ai.rag.retriever import MemorySearch
from app.ai.registry import build
from app.ai.review_contract import ReviewResult
from app.config import settings
from app.database import SessionLocal
from app.integrations import s3
from app.models import (
    CapturedDocument,
    ConsentRecord,
    Event,
    MediaAsset,
    MemoryAction,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
    ObjectSighting,
    PatientProfile,
    User,
)
from app.services import (
    embedding_service,
    memory_service,
    review_service,
)

DATASET = "https://huggingface.co/datasets/OSU-AIoT-MLSys-Lab/SuperMemory-VQA/resolve/main/data"
CACHE = Path.home() / ".cache" / "remori" / "supermemory"
TIMEZONE = "America/New_York"  # recorded in Ohio
TALK_GAP_S = 30.0  # a silence this long starts a new conversation event
TALK_MAX_S = 60.0  # and so does a stretch this long
UNANSWERABLE = "can not be answered"

JUDGE_PROMPT = """You grade a memory assistant on a multiple-choice benchmark. You get a
question, its numbered choices, and the assistant's free answer. Return the number of the
choice the answer states. If the answer says it doesn't know, can't tell, or has nothing in
memory about it, return the choice that says the question can not be answered. If the answer
matches no choice, return -1. Judge only what the answer says, not what is true."""
JUDGE_SCHEMA = {
    "type": "object",
    "properties": {"choice": {"type": "integer"}},
    "required": ["choice"],
}


# ----- the dataset -----


def fetch(remote: str, local: Path) -> Path:
    if not local.exists():
        local.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading {remote} …", flush=True)
        urllib.request.urlretrieve(f"{DATASET}/{remote}", local)  # fixed https URL
    return local


def session_files(person: int, video_id: str) -> dict[str, Path]:
    folder = CACHE / f"person_{person}"
    tail = video_id.split(f"Person_{person}_", 1)[1]
    return {
        "video": fetch(
            f"video/Person_{person}/{video_id}.mp4", folder / f"{video_id}.mp4"
        ),
        "transcript": fetch(
            f"transcripts/person_{person}/person_{person}_{tail}_gemini_aligned_transcript.json",
            folder / f"person_{person}_{tail}_gemini_aligned_transcript.json",
        ),
    }


def evidence_videos(q: dict) -> set[str]:
    return {
        e["video_id"] for e in (q.get("answer_evidence") or {}).get("evidence_list", [])
    }


def select_questions(qa: list[dict], videos: set[str]) -> list[dict]:
    """Answerable: every piece of evidence is in the replayed sessions. Unanswerable: asked
    in a replayed session, with no evidence outside them."""
    chosen = []
    for q in qa:
        evidence = evidence_videos(q)
        if q["is_answerable"]:
            if evidence and evidence <= videos:
                chosen.append(q)
        elif q["metadata"]["primary_video_id"] in videos and evidence <= videos:
            chosen.append(q)
    return chosen


def asked_at(q: dict) -> datetime:
    """When the question was asked: the end of its question span, else its session start."""
    spans = (q.get("question_evidence") or {}).get("time_spans") or []
    if spans:
        span = spans[-1]
        return datetime.fromtimestamp(
            span["video_start_time_unix"] + span["end_time"], UTC
        )
    return datetime.fromtimestamp(q["start_time"], UTC)


def session_start(qa: list[dict], video_id: str) -> int:
    for q in qa:
        for e in (q.get("answer_evidence") or {}).get("evidence_list", []):
            if e["video_id"] == video_id and e.get("start_time"):
                return int(e["start_time"])
        for s in (q.get("question_evidence") or {}).get("time_spans", []):
            if s["video_id"] == video_id:
                return int(s["video_start_time_unix"])
    raise SystemExit(f"no start time found for {video_id}")


# ----- loading memory -----


class CachedReviewer:
    """Never pay twice for the same frame. A review is reused when the photo (as sent, after
    blurring), its language, the model + review prompt version and the image size are all the
    same; changing any of them makes a fresh review. Cache: ~/.cache/remori/supermemory/reviews/."""

    def __init__(self, inner, photo_side: int):
        self.inner, self.model_id = inner, inner.model_id
        name = re.sub(r"[^\w.-]+", "_", f"{inner.model_id}_{photo_side}px")
        self.folder = CACHE / "reviews" / name
        self.folder.mkdir(parents=True, exist_ok=True)
        self.hits = self.misses = 0

    def review(self, image: bytes, language: str) -> ReviewResult:
        key = hashlib.sha256(image + language.encode()).hexdigest()
        path = self.folder / f"{key}.json"
        if path.exists():
            self.hits += 1
            return ReviewResult.model_validate_json(path.read_text(encoding="utf-8"))
        result = self.inner.review(image, language)
        path.write_text(result.model_dump_json(), encoding="utf-8")
        self.misses += 1
        return result


class MemoryStorage:
    """In-memory stand-in for S3, so the real review code runs unchanged."""

    def __init__(self):
        self.files: dict[str, bytes] = {}

    def install(self):
        s3.exists = lambda key: key in self.files
        s3.get_bytes = lambda key, max_bytes: self.files.get(key)
        s3.delete = lambda key: self.files.pop(key, None)


def seed_patient(db) -> tuple[uuid.UUID, uuid.UUID]:
    caregiver = User(
        role="caregiver",
        full_name="replay caregiver",
        email=f"replay-{uuid.uuid4()}@example.invalid",
    )
    patient = User(role="patient", full_name="SuperMemory wearer (replay)")
    db.add_all([caregiver, patient])
    db.flush()
    db.add(
        PatientProfile(user_id=patient.id, preferred_language="en", timezone=TIMEZONE)
    )
    db.add(
        ConsentRecord(
            patient_id=patient.id,
            consent_type="cloud_processing",
            given_by=caregiver.id,
            given_at=datetime.now(UTC),
        )
    )
    db.commit()
    return patient.id, caregiver.id


def talk_events(db, patient_id, transcript: dict, start_unix: int) -> int:
    """Transcript lines → conversation events (sounds kept as "[sound: …]")."""
    chunks, current = [], []
    for line in transcript["transcript"]:
        if current and (
            line["start"] - current[-1]["end"] > TALK_GAP_S
            or line["end"] - current[0]["start"] > TALK_MAX_S
        ):
            chunks.append(current)
            current = []
        current.append(line)
    if current:
        chunks.append(current)
    for chunk in chunks:
        segments = [
            {
                "start_s": line["start"] - chunk[0]["start"],
                "end_s": line["end"] - chunk[0]["start"],
                "speaker": line.get("person") or "?",
                "text": line["text"]
                if line.get("kind") == "speech"
                else f"[sound: {line['text']}]",
            }
            for line in chunk
        ]
        text = " ".join(
            f"{s['speaker']}: {s['text']}"
            if not s["text"].startswith("[")
            else s["text"]
            for s in segments
        )
        db.add(
            Event(
                id=uuid.uuid4(),
                patient_id=patient_id,
                source="glasses",
                event_type="conversation_segment",
                occurred_at=datetime.fromtimestamp(start_unix + chunk[0]["start"], UTC),
                ended_at=datetime.fromtimestamp(start_unix + chunk[-1]["end"], UTC),
                transcript_text=text[:5000],
                language="en",
                metadata_={"segments": segments, "present_person_ids": []},
            )
        )
    db.commit()
    return len(chunks)


def extract_frames(video: Path, every: float, out: Path) -> list[tuple[float, Path]]:
    out.mkdir(parents=True, exist_ok=True)
    if not any(out.glob("f_*.jpg")):
        subprocess.run(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                str(video),
                "-vf",
                f"fps=1/{every},scale=1280:-2",
                "-q:v",
                "3",
                str(out / "f_%05d.jpg"),
            ],
            check=True,
        )
    frames = sorted(out.glob("f_*.jpg"))
    return [(i * every, path) for i, path in enumerate(frames)]


def histogram(path: Path) -> np.ndarray:
    """A 3 × 16-bin HSV colour histogram: steady under small head turns, moves when the
    scene changes (a head-worn camera never stands still, so pixel differences don't work)."""
    pixels = np.asarray(Image.open(path).convert("HSV").resize((160, 160)))
    counts = np.concatenate(
        [np.histogram(pixels[..., c], bins=16, range=(0, 256))[0] for c in range(3)]
    ).astype(np.float32)
    return counts / counts.sum()


def changed_frames(
    frames: list[tuple[float, Path]], threshold: float, max_gap: float
) -> list[tuple[float, Path]]:
    """Novelty stand-in for the capture gate (D33): keep a frame when its colour histogram
    differs from the last kept one by at least `threshold` (L1), or `max_gap` s passed."""
    if threshold <= 0:
        return frames
    kept, last, last_t = [], None, 0.0
    for offset, path in frames:
        h = histogram(path)
        if (
            last is None
            or np.abs(h - last).sum() >= threshold
            or offset - last_t >= max_gap
        ):
            kept.append((offset, path))
            last, last_t = h, offset
    return kept


def review_frames(
    patient_id, frames, start_unix, storage: MemoryStorage, workers: int
) -> dict:
    """Each frame → event + media → the real photo review, `workers` at a time."""
    jobs = []
    with SessionLocal() as db:
        for offset, path in frames:
            event = Event(
                id=uuid.uuid4(),
                patient_id=patient_id,
                source="glasses",
                event_type="notable_moment_captured",
                occurred_at=datetime.fromtimestamp(start_unix + offset, UTC),
            )
            db.add(event)
            db.flush()
            media = MediaAsset(
                id=uuid.uuid4(),
                patient_id=patient_id,
                event_id=event.id,
                asset_type="image",
                storage_key=f"replay/{path.name}",
                trigger="salient_frame",
                status="pending_review",
            )
            db.add(media)
            storage.files[media.storage_key] = path.read_bytes()
            jobs.append(media.id)
        db.commit()

    def review(media_id):
        for attempt in range(3):
            try:
                with SessionLocal() as db:
                    return review_service.review_media(db, media_id)
            except Exception as exc:  # noqa: BLE001  temporary API failures: try again
                if attempt == 2:
                    return f"error: {type(exc).__name__}"
                time.sleep(5 * (attempt + 1))
        return "error"

    started = time.perf_counter()
    with ThreadPoolExecutor(workers) as pool:
        outcomes = list(pool.map(review, jobs))
    counts = collections.Counter(outcomes)
    counts["seconds"] = round(time.perf_counter() - started)
    return dict(counts)


def drop_discarded(db, patient_id) -> int:
    """A discarded frame leaves an empty notable-moment event: remove both (replay only)."""
    gone = db.scalars(
        select(MediaAsset).where(
            MediaAsset.patient_id == patient_id, MediaAsset.status == "discarded"
        )
    ).all()
    events = [m.event_id for m in gone]
    for m in gone:
        db.delete(m)
    db.flush()
    db.execute(delete(Event).where(Event.id.in_(events)))
    db.commit()
    return len(events)


def embed_all(db, patient_id) -> int:
    ids = db.scalars(select(Event.id).where(Event.patient_id == patient_id)).all()
    done = 0
    for i in range(0, len(ids), embedding_service.BATCH):
        done += embedding_service.embed_events(
            db, list(ids[i : i + embedding_service.BATCH])
        )
    return done


def consolidate_all(db, patient_id) -> dict:
    ids = db.scalars(
        select(Event.id)
        .where(
            Event.patient_id == patient_id, Event.event_type == "conversation_segment"
        )
        .order_by(Event.occurred_at)
    ).all()
    outcomes = collections.Counter(memory_service.consolidate_event(db, i) for i in ids)
    return dict(outcomes)


def memory_counts(db, patient_id) -> dict:
    def n(table):
        return db.scalar(select(func.count()).where(table.patient_id == patient_id))

    return {
        "events": n(Event),
        "photos kept": db.scalar(
            select(func.count()).where(
                MediaAsset.patient_id == patient_id, MediaAsset.status == "confirmed"
            )
        ),
        "documents": db.scalar(
            select(func.count())
            .select_from(CapturedDocument)
            .join(MediaAsset, MediaAsset.id == CapturedDocument.media_asset_id)
            .where(MediaAsset.patient_id == patient_id)
        ),
        "object sightings": n(ObjectSighting),
        "actions": n(MemoryAction),
        "facts": n(MemoryFact),
        "plans": n(MemoryIntention),
        "entities": n(MemoryEntity),
    }


def cleanup(db, patient_id, caregiver_id) -> None:
    db.execute(
        delete(CapturedDocument).where(
            CapturedDocument.media_asset_id.in_(
                select(MediaAsset.id).where(MediaAsset.patient_id == patient_id)
            )
        )
    )
    for table in (ObjectSighting, MemoryAction, MemoryFact, MemoryIntention):
        db.execute(delete(table).where(table.patient_id == patient_id))
    db.execute(delete(MemoryEntity).where(MemoryEntity.patient_id == patient_id))
    db.execute(delete(MediaAsset).where(MediaAsset.patient_id == patient_id))
    db.execute(delete(Event).where(Event.patient_id == patient_id))
    db.execute(delete(ConsentRecord).where(ConsentRecord.patient_id == patient_id))
    db.execute(delete(PatientProfile).where(PatientProfile.user_id == patient_id))
    db.execute(delete(User).where(User.id.in_([patient_id, caregiver_id])))
    db.commit()


# ----- questions -----


def judge(llm, q: dict, answer: str) -> int:
    choices = "\n".join(f"{i}. {c}" for i, c in enumerate(q["choices"]))
    raw = llm.complete(
        [
            {"role": "system", "content": JUDGE_PROMPT},
            {
                "role": "user",
                "content": f"Question: {q['question']}\n\nChoices:\n{choices}\n\nAnswer: {answer}",
            },
        ],
        JUDGE_SCHEMA,
    )
    try:
        return int(json.loads(raw)["choice"])
    except (ValueError, KeyError, TypeError):
        return -1


def ask(db, patient_id, questions, ai, *, structures: bool) -> list[dict]:
    answer_module.MemorySearch = partial(MemorySearch, use_structures=structures)
    rows = []
    for q in questions:
        started = time.perf_counter()
        out = answer_module.answer(db, patient_id, q["question"], asked_at=asked_at(q))
        seconds = time.perf_counter() - started
        chosen = judge(ai.llm, q, out["answer"])
        correct = chosen == q["correct_option_index"]
        rows.append(
            {
                "id": q["question_id"],
                "skill": q["metadata"]["skill"],
                "answerable": q["is_answerable"],
                "question": q["question"],
                "answer": out["answer"],
                "chosen": chosen,
                "correct_index": q["correct_option_index"],
                "correct": correct,
                "seconds": round(seconds, 1),
                "sources": len(out["source_event_ids"]),
            }
        )
        mark = "✓" if correct else "✗"
        print(
            f"  {mark} [{q['metadata']['skill']}] {seconds:.0f}s  {q['question'][:90]}\n"
            f"      → {out['answer'][:160]}",
            flush=True,
        )
    return rows


def report(label: str, rows: list[dict]) -> str:
    def acc(rs):
        return (
            f"{sum(r['correct'] for r in rs) / len(rs):.0%} ({sum(r['correct'] for r in rs)}/{len(rs)})"
            if rs
            else "n/a"
        )

    by_skill = collections.defaultdict(list)
    for r in rows:
        by_skill[r["skill"]].append(r)
    lines = [
        (
            f"{label}: accuracy {acc(rows)}"
            f" · answerable {acc([r for r in rows if r['answerable']])}"
            f" · unanswerable {acc([r for r in rows if not r['answerable']])}"
            f" · {sum(r['seconds'] for r in rows) / max(len(rows), 1):.1f}s avg"
        )
    ]
    lines += [f"    {skill}: {acc(rs)}" for skill, rs in sorted(by_skill.items())]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--person", type=int, default=10)
    parser.add_argument("--sessions", type=int, nargs="+", default=[3])
    parser.add_argument(
        "--every", type=float, default=1.0, help="seconds between frames"
    )
    parser.add_argument(
        "--novelty",
        type=float,
        default=0.2,
        help="keep a frame only when the scene changed this much (0 = keep all)",
    )
    parser.add_argument(
        "--max-gap", type=float, default=10.0, help="but keep one at least every N s"
    )
    parser.add_argument(
        "--provider",
        choices=["groq", "gemini", "selfhosted"],
        default="groq",
        help="groq: Qwen3.6-27B on Groq; gemini: Gemini Flash; selfhosted: our own "
        "vLLM server (SELFHOSTED_BASE_URL, see LIGHTNING.md)",
    )
    parser.add_argument(
        "--photo-side",
        type=int,
        default=1024,
        help="pixels of the longest side sent to Groq / self-hosted (larger reads small text)",
    )
    parser.add_argument(
        "--workers", type=int, default=4, help="photo reviews in parallel"
    )
    parser.add_argument(
        "--limit", type=int, default=0, help="at most this many questions"
    )
    parser.add_argument(
        "--no-flat", action="store_true", help="skip the flat-memory run"
    )
    args = parser.parse_args()
    if (
        "localhost" not in settings.database_url
        and "127.0.0.1" not in settings.database_url
    ):
        sys.exit("Refusing to run: DATABASE_URL must point at a local database.")

    qa = json.loads(
        fetch(
            f"json/qa_person_{args.person}.json",
            CACHE / f"person_{args.person}" / f"qa_person_{args.person}.json",
        ).read_text(encoding="utf-8")
    )
    all_videos = sorted({v for q in qa for v in q["video_ids"]})
    videos = {
        v
        for v in all_videos
        if any(
            v.startswith(f"Person_{args.person}_session_{s}_") for s in args.sessions
        )
    }
    if not videos:
        sys.exit(f"no such sessions for person {args.person}: {args.sessions}")
    questions = select_questions(qa, videos)
    if args.limit:
        questions = questions[: args.limit]
    print(f"sessions {sorted(videos)} · {len(questions)} questions", flush=True)

    models = {
        "groq": {"llm": "groq-qwen", "assist_llm": "groq-qwen", "vision": "groq-qwen"},
        "selfhosted": {
            "llm": "selfhosted-qwen",
            "assist_llm": "selfhosted-qwen",
            "vision": "selfhosted-qwen",
        },
        "gemini": {
            "llm": "gemini-flash",
            "assist_llm": "gemini-flash-fast",
            "vision": "gemini-flash",
        },
    }[args.provider]
    groq_client.PHOTO_SIDE = args.photo_side
    ai = build(
        "stub", {**models, "text_embedder": "voyage-4", "face": "mobilefacenet-onnx"}
    )
    reviewer = CachedReviewer(ai.vision, args.photo_side)
    ai = dataclasses.replace(ai, vision=reviewer)
    for module in (answer_module, review_service, memory_service, embedding_service):
        module.get_ai = lambda: ai
    storage = MemoryStorage()
    storage.install()

    db = SessionLocal()
    patient_id, caregiver_id = seed_patient(db)
    results = {
        "sessions": sorted(videos),
        "every_s": args.every,
        "novelty": args.novelty,
        "provider": args.provider,
        "models": {k: getattr(ai, k).model_id for k in ("llm", "assist_llm", "vision")},
    }
    try:
        for video_id in sorted(videos):
            files = session_files(args.person, video_id)
            start = session_start(qa, video_id)
            talks = talk_events(
                db,
                patient_id,
                json.loads(files["transcript"].read_text(encoding="utf-8")),
                start,
            )
            every_frame = extract_frames(
                files["video"],
                args.every,
                CACHE / "frames" / video_id / f"every_{args.every:g}",
            )
            frames = changed_frames(every_frame, args.novelty, args.max_gap)
            print(
                f"{video_id}: {talks} conversation events, "
                f"{len(frames)} of {len(every_frame)} frames → photo review …",
                flush=True,
            )
            results.setdefault("review", {})[video_id] = review_frames(
                patient_id, frames, start, storage, args.workers
            )
            print("  review:", results["review"][video_id], flush=True)
        results["dropped_discarded"] = drop_discarded(db, patient_id)
        print("embedding …", flush=True)
        results["embedded"] = embed_all(db, patient_id)
        print("consolidating conversations …", flush=True)
        results["consolidation"] = consolidate_all(db, patient_id)
        results["memory"] = memory_counts(db, patient_id)
        results["review_cache"] = {"reused": reviewer.hits, "new": reviewer.misses}
        print("memory:", results["memory"], "· review cache:", results["review_cache"], flush=True)

        print("\n== structured (the five structures)", flush=True)
        results["structured"] = ask(db, patient_id, questions, ai, structures=True)
        if not args.no_flat:
            print("\n== flat (event sentences only)", flush=True)
            results["flat"] = ask(db, patient_id, questions, ai, structures=False)
    finally:
        cleanup(db, patient_id, caregiver_id)
        db.close()

    print()
    print(report("structured", results["structured"]))
    if "flat" in results:
        print(report("flat", results["flat"]))
    out = (
        CACHE
        / "results"
        / f"person_{args.person}_sessions_{'_'.join(map(str, args.sessions))}_{datetime.now():%Y%m%d_%H%M}.json"
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(results, ensure_ascii=False, indent=1, default=str), encoding="utf-8"
    )
    print(f"\nresults: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
