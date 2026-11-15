"""The /assist retriever: hybrid search over the patient's memories (track R4; spec D22, D39, D40).

Implements `assist_loop.SearchBackend`. One search (a validated `QueryPlan`) runs:

1. **Filters first (D22):** the patient (bound here, never from the model), the half-open
   time window, event types, and people who were PRESENT (the event's person, its
   encounter's person, or a conversation's `present_person_ids`). Every candidate below must
   pass them.
2. **Three rankings of the candidates**, merged by reciprocal rank fusion:
   - meaning: pgvector cosine between the search text (embedded as a *query*) and each
     event's sentence;
   - words: how many words of the search text appear in the sentence or transcript (vector
     search is weak on exact names and numbers);
   - memory structures (D40): object sightings, actions, facts and plans whose entity or
     words match, each pointing back to its event. They rank first and their line is put at
     the front of that event's text ("[keys seen: on the table, kitchen] …"), so the model
     reads the precise fact even when the sentence is long.
   Without a search text, the newest events come first.
   Premise check (D39): when people were asked about and none was present in the window,
   their last presence outside it comes back, marked "outside the time asked".
3. **Results** as `Evidence(event_id, local time, text)`: the loop only accepts answers that
   cite these ids.

Privacy: nothing is logged (search texts, names and ids are private).
"""

import re
import uuid
from collections import defaultdict
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import numpy as np
from sqlalchemy import Text, and_, case, cast, func, literal, or_, select
from sqlalchemy.dialects.postgresql import array
from sqlalchemy.orm import Session

from app.ai.interfaces import TextEmbedder, VisualTextEmbedder
from app.ai.memory import frame_vectors
from app.ai.rag.assist_loop import TOP_K, Evidence
from app.ai.rag.planner import QueryPlan
from app.ai.rag.render import PRINTED_TEXT, clean
from app.integrations import s3
from app.models import (
    Encounter,
    Event,
    FrameVectorFile,
    MediaAsset,
    MemoryAction,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
    ObjectSighting,
    SceneSegment,
    SceneVector,
)

PER_RANKING = 20  # candidates each ranking contributes before fusion
RRF_K = 60  # reciprocal rank fusion constant (the usual value)
STRUCTURE_WEIGHT = 2.0  # a structure match is precise: it counts twice
ENTITY_MATCH = 0.45  # DRAFT: query ↔ entity-name cosine to count as "about" that entity
MAX_LINES = 3  # structure lines put in front of one event's text
# Sightings: an object seen in many photos (a pizza box in 86) must not fill every slot with the
# same state. Up to this many newest are read, repeats of one state collapse to the newest, and
# a question about a name or writing puts the sightings that quote printed text first.
SIGHTINGS_SCAN = 300
TEXT_QUESTION = {
    "name", "named", "called", "printed", "written", "writing", "text", "label", "brand",
    "title", "website", "address", "number", "says", "sign", "logo",
    "اسم", "الاسم", "اسمه", "اسمها", "مكتوب", "مكتوبة", "كتابة", "المكتوب", "عنوان", "رقم",
    "لافتة", "ماركة",
}  # fmt: skip
MIN_WORD = 3  # shorter words are too common to search for
OUTSIDE_WINDOW = "outside the time asked: the last time this person was present"
# Visual memory (D41): the question's words are embedded into the space of the glasses' frame
# vectors. Tier 1 finds the best scene segments, tier 2 (the hourly per-frame files) finds the
# best second inside each; a hit is attached to the moment memory has from those seconds.
VISUAL_SCAN = 60  # tier-1 vectors read, nearest first
VISUAL_SEGMENTS = 5  # segments kept
VISUAL_MIN = 0.2  # DRAFT: question ↔ frame cosine for a hit (calibrated on the replay)
VISUAL_MARGIN = 0.03  # and no further than this below the best segment
VISUAL_NEAR_S = 120  # a moment this close in time carries a hit when no photo was kept
VISUAL_WEIGHT = 1.0
VISUAL_PROMPT = "a photo of {}"  # CLIP matches short captions best
WORD = re.compile(r"\w+")  # Unicode letters and digits: Arabic too, never "؟" or "،"


def words(text: str) -> list[str]:
    """Distinct search words, lower-cased, long enough to mean something."""
    return list(
        dict.fromkeys(
            w.casefold() for w in WORD.findall(text or "") if len(w) >= MIN_WORD
        )
    )


def fuse(rankings: list[tuple[list[uuid.UUID], float]]) -> list[uuid.UUID]:
    """Reciprocal rank fusion of several ranked id lists, each with a weight."""
    scores: dict[uuid.UUID, float] = defaultdict(float)
    for ranked, weight in rankings:
        for rank, event_id in enumerate(ranked):
            scores[event_id] += weight / (RRF_K + rank + 1)
    return sorted(scores, key=lambda i: scores[i], reverse=True)


class MemorySearch:
    """One patient's memories, searched by the /assist loop."""

    def __init__(
        self,
        db: Session,
        patient_id: uuid.UUID,
        tz: str,
        embedder: TextEmbedder,
        top_k: int = TOP_K,
        use_structures: bool = True,
        visual: VisualTextEmbedder | None = None,
    ):
        self.db, self.patient_id, self.tz = db, patient_id, ZoneInfo(tz)
        self.embedder, self.top_k = embedder, top_k
        # False = flat memory: event sentences only (the H6 ablation, spec D40)
        self.use_structures = use_structures
        # None = no visual memory: the frame vectors aren't searched (D41 off)
        self.visual = visual

    async def search(self, plan: QueryPlan) -> list[Evidence]:
        # the session belongs to this thread; the loop awaits searches one at a time
        return self.search_now(plan)

    def search_now(self, plan: QueryPlan) -> list[Evidence]:
        conditions = self._filters(plan)
        tokens = words(plan.search_text)
        lines: dict[uuid.UUID, list[str]] = {}
        if plan.search_text.strip():
            query = self.embedder.embed_query(plan.search_text)
            if self.use_structures:
                lines = self._structures(plan, tokens, query)
            seen = self._visual(plan) if self.visual is not None else {}
            for event_id, extra in seen.items():  # after the structure lines
                lines.setdefault(event_id, []).extend(extra)
            ranked = fuse(
                [
                    (list(lines), STRUCTURE_WEIGHT),
                    (self._by_meaning(conditions, query), 1.0),
                    (self._by_words(conditions, tokens), 1.0),
                    (list(seen), VISUAL_WEIGHT),
                ]
            )
        else:
            ranked = self._newest(conditions)
        results = self._evidence(ranked[: self.top_k], lines)
        if not results and plan.person_ids and (plan.window_start or plan.window_end):
            return self._premise(plan)
        return results

    def _premise(self, plan: QueryPlan) -> list[Evidence]:
        """Premise check (D39): nobody of `person_ids` was present in the time asked about.
        The last time each of them was present, outside that window, marked as such, so the
        answer can say "not today, but yesterday at 11" instead of only "not in memory"."""
        found, lines = [], {}
        for person in plan.person_ids:
            outside = QueryPlan(
                window_start=None,
                window_end=plan.window_end if plan.window_start is None else None,
                person_ids=[person],
                event_types=plan.event_types,
                search_text="",
            )
            for event_id in self._newest(self._filters(outside))[:1]:
                if event_id not in lines:
                    found.append(event_id)
                    lines[event_id] = [OUTSIDE_WINDOW]
        return self._evidence(found, lines)

    # ----- filters -----

    def _filters(self, plan: QueryPlan) -> list:
        conditions = [Event.patient_id == self.patient_id, Event.deleted_at.is_(None)]
        if plan.window_start is not None:
            conditions.append(Event.occurred_at >= plan.window_start)
        if plan.window_end is not None:
            conditions.append(Event.occurred_at < plan.window_end)
        if plan.event_types:
            conditions.append(Event.event_type.in_(plan.event_types))
        if plan.person_ids:
            ids = [uuid.UUID(p) for p in plan.person_ids]
            conditions.append(
                or_(
                    Event.person_id.in_(ids),
                    Event.encounter_id.in_(
                        select(Encounter.id).where(Encounter.person_id.in_(ids))
                    ),
                    Event.metadata_["present_person_ids"].has_any(
                        array(plan.person_ids, type_=Text)
                    ),
                )
            )
        return conditions

    def _window(self, plan: QueryPlan) -> list:
        """Only the patient and the time window (for the structures)."""
        return self._filters(
            QueryPlan(
                window_start=plan.window_start,
                window_end=plan.window_end,
                person_ids=[],
                event_types=None,
                search_text="",
            )
        )

    def _candidates(self, conditions: list):
        return select(Event.id).where(*conditions)

    # ----- rankings -----

    def _newest(self, conditions: list) -> list[uuid.UUID]:
        return list(
            self.db.scalars(
                self._candidates(conditions)
                .order_by(Event.occurred_at.desc())
                .limit(self.top_k)
            )
        )

    def _by_meaning(self, conditions: list, query: list[float]) -> list[uuid.UUID]:
        return list(
            self.db.scalars(
                self._candidates(conditions)
                .where(Event.embedding.is_not(None))
                .order_by(Event.embedding.cosine_distance(query))
                .limit(PER_RANKING)
            )
        )

    def _by_words(self, conditions: list, tokens: list[str]) -> list[uuid.UUID]:
        if not tokens:
            return []
        text = func.lower(
            func.coalesce(Event.rendered_text, "")
            + literal(" ")
            + func.coalesce(Event.transcript_text, "")
        )
        hits = sum(case((text.contains(t), 1), else_=0) for t in tokens)
        return list(
            self.db.scalars(
                self._candidates(conditions)
                .where(hits > 0)
                .order_by(hits.desc(), Event.occurred_at.desc())
                .limit(PER_RANKING)
            )
        )

    # ----- memory structures (D40) -----

    def _entities(self, tokens: list[str], query: list[float]) -> dict[uuid.UUID, str]:
        """Entities the search is about: a word of the search in the name (or the other
        way round), or a name close in meaning ("my glasses" ↔ "النضارة")."""
        found: dict[uuid.UUID, str] = {}
        rows = self.db.execute(
            select(
                MemoryEntity.id,
                MemoryEntity.name,
                (1 - MemoryEntity.name_embedding.cosine_distance(query)).label("sim"),
            ).where(
                MemoryEntity.patient_id == self.patient_id,
                MemoryEntity.deleted_at.is_(None),
            )
        ).all()
        for entity_id, name, sim in rows:
            by_word = any(t in name or name in t for t in tokens)
            if by_word or (sim is not None and sim >= ENTITY_MATCH):
                found[entity_id] = name
        return found

    def _structures(
        self, plan: QueryPlan, tokens: list[str], query: list[float]
    ) -> dict[uuid.UUID, list[str]]:
        """event id → lines from the five structures (D40), best first.

        Only the patient and the time window apply here, not the model's type or person
        filters: a sighting from a photo or a fact said *about* someone must not be hidden
        because the model narrowed the event search."""
        entities = self._entities(tokens, query)
        ids = list(entities)
        window = self._candidates(self._window(plan))
        lines: dict[uuid.UUID, list[str]] = defaultdict(list)

        def add(event_id, line):
            if event_id is not None and line not in lines[event_id]:
                lines[event_id].append(line)

        # object sightings: "where is X?" → the newest one is marked "last seen"
        if ids:
            sightings = self.db.execute(
                select(ObjectSighting, MediaAsset.event_id)
                .join(MediaAsset, MediaAsset.id == ObjectSighting.media_asset_id)
                .where(
                    ObjectSighting.entity_id.in_(ids),
                    ObjectSighting.deleted_at.is_(None),
                    MediaAsset.event_id.in_(window),
                )
                .order_by(ObjectSighting.seen_at.desc())
                .limit(SIGHTINGS_SCAN)
            ).all()
            newest: set[uuid.UUID] = set()
            states: set[tuple] = set()
            distinct = []  # (sighting, event id, label): one per state, newest first
            for sighting, event_id in sightings:
                label = "seen" if sighting.entity_id in newest else "last seen"
                newest.add(sighting.entity_id)
                state = (
                    sighting.entity_id,
                    clean(sighting.state).lower(),
                    sighting.room,
                )
                if state not in states:
                    states.add(state)
                    distinct.append((sighting, event_id, label))
            if TEXT_QUESTION & set(tokens):  # "what name was printed on the box?"
                distinct.sort(key=lambda d: not PRINTED_TEXT.search(d[0].state or ""))
            for sighting, event_id, label in distinct[:PER_RANKING]:
                where = ", ".join(x for x in (sighting.state, sighting.room) if x)
                name = entities[sighting.entity_id]
                add(event_id, f"{name} {label}" + (f": {where}" if where else ""))

        # actions: each instance, plus how many times in the window ("how many times?")
        action_match = [MemoryAction.entity_id.in_(ids)] if ids else []
        action_match += [MemoryAction.verb.contains(t) for t in tokens]
        if action_match:
            matching = and_(
                or_(*action_match),
                MemoryAction.deleted_at.is_(None),
                MemoryAction.evidence_event_id.in_(window),
            )
            counts = {
                (verb, entity_id): (n, last)
                for verb, entity_id, n, last in self.db.execute(
                    select(
                        MemoryAction.verb,
                        MemoryAction.entity_id,
                        func.count(),
                        func.max(MemoryAction.occurred_at),
                    )
                    .where(matching)
                    .group_by(MemoryAction.verb, MemoryAction.entity_id)
                )
            }
            actions = self.db.execute(
                select(MemoryAction, MemoryEntity.name)
                .outerjoin(MemoryEntity, MemoryEntity.id == MemoryAction.entity_id)
                .where(matching)
                .order_by(MemoryAction.occurred_at.desc())
                .limit(PER_RANKING)
            ).all()
            for action, name in actions:
                amount = (
                    f" ×{action.quantity:g} {action.unit or ''}".rstrip()
                    if action.quantity
                    else ""
                )
                what = f"{action.verb.replace('_', ' ')} {name or ''}".rstrip()
                add(action.evidence_event_id, f"action: {what}{amount}")
                n, last = counts.get((action.verb, action.entity_id), (1, None))
                if n > 1 and last == action.occurred_at:
                    add(
                        action.evidence_event_id,
                        f"count: {what} ×{n} in the time searched",
                    )

        # facts: the exact words, with their typed values
        fact_match = [func.lower(MemoryFact.quote).contains(t) for t in tokens]
        if ids:
            fact_match.append(
                MemoryFact.about_entity_ids.overlap(
                    cast(array(ids), MemoryFact.about_entity_ids.type)
                )
            )
        if fact_match:
            facts = self.db.scalars(
                select(MemoryFact)
                .where(
                    or_(*fact_match),
                    MemoryFact.deleted_at.is_(None),
                    MemoryFact.event_id.in_(window),
                )
                .order_by(MemoryFact.said_at.desc())
                .limit(PER_RANKING)
            ).all()
            for fact in facts:
                values = ", ".join(
                    v.get("text", "") for v in (fact.values or []) if v.get("text")
                )
                add(
                    fact.event_id,
                    f"said: «{fact.quote}»" + (f" ({values})" if values else ""),
                )

        # plans: their status, and the event that settled them ("did I call the doctor?")
        plan_match = [
            or_(
                func.lower(MemoryIntention.description).contains(t),
                func.lower(MemoryIntention.quote).contains(t),
            )
            for t in tokens
        ]
        if plan_match:
            intentions = self.db.scalars(
                select(MemoryIntention)
                .where(
                    or_(*plan_match),
                    MemoryIntention.deleted_at.is_(None),
                    MemoryIntention.source_event_id.in_(window),
                )
                .order_by(MemoryIntention.stated_at.desc())
                .limit(PER_RANKING)
            ).all()
            for intention in intentions:
                due = (
                    f", due {intention.due_at.astimezone(self.tz):%Y-%m-%d %H:%M}"
                    if intention.due_at
                    else ""
                )
                settled = (
                    f", settled {intention.settled_at.astimezone(self.tz):%Y-%m-%d %H:%M}"
                    if intention.settled_at and intention.status != "open"
                    else ""
                )
                add(
                    intention.source_event_id,
                    f"plan: {intention.description} "
                    f"(status: {intention.status}{due}{settled})",
                )
                for proof in intention.settled_by_event_ids or []:
                    add(
                        proof,
                        f"settles the plan «{intention.description}»: {intention.status}",
                    )
        return {k: v for k, v in lines.items() if v}

    # ----- visual memory (D41) -----

    def _visual(self, plan: QueryPlan) -> dict[uuid.UUID, list[str]]:
        """event id → "seen around HH:MM:SS" lines, best hit first. Two tiers (D41): the
        segments' 3 vectors find the candidate minutes, the hourly files find the best second;
        a hit goes to the photo kept in that segment, else to the closest moment in time."""
        query = self.visual.embed_text(
            [VISUAL_PROMPT.format(plan.search_text.strip())]
        )[0]
        distance = SceneVector.embedding.cosine_distance(query)
        where = [SceneVector.patient_id == self.patient_id]
        if plan.window_start is not None:
            where.append(SceneVector.captured_at >= plan.window_start)
        if plan.window_end is not None:
            where.append(SceneVector.captured_at < plan.window_end)
        best: dict[uuid.UUID, float] = {}
        for segment_id, sim in self.db.execute(
            select(SceneVector.segment_id, (1 - distance).label("sim"))
            .where(*where)
            .order_by(distance)
            .limit(VISUAL_SCAN)
        ):
            best.setdefault(segment_id, float(sim))
        if not best:
            return {}
        top = max(best.values())
        chosen = [
            k
            for k, v in sorted(best.items(), key=lambda kv: -kv[1])
            if v >= VISUAL_MIN and v >= top - VISUAL_MARGIN
        ][:VISUAL_SEGMENTS]
        segments = {
            s.id: s
            for s in self.db.scalars(
                select(SceneSegment).where(SceneSegment.id.in_(chosen))
            )
        }
        vector = np.asarray(query, dtype=np.float32)
        files: dict[uuid.UUID, frame_vectors.FrameVectors | None] = {}
        lines: dict[uuid.UUID, list[str]] = {}
        for segment_id in chosen:
            segment = segments.get(segment_id)
            if segment is None:
                continue
            when, _ = self._best_second(segment, vector, files)
            line = f"seen around {when.astimezone(self.tz):%H:%M:%S}: looks like «{plan.search_text.strip()}»"
            for event_id in self._near(segment, when):
                if line not in lines.setdefault(event_id, []):
                    lines[event_id].append(line)
        return lines

    def _best_second(self, segment, vector, files) -> tuple[datetime, float]:
        """Tier 2: the segment's best frame in the hourly files (its start when none is there)."""
        best_at, best_sim = segment.started_at, -1.0
        hour = segment.started_at.replace(minute=0, second=0, microsecond=0)
        while hour <= segment.ended_at:
            for row in self.db.scalars(
                select(FrameVectorFile).where(
                    FrameVectorFile.patient_id == self.patient_id,
                    FrameVectorFile.device_id == segment.device_id,
                    FrameVectorFile.hour_start == hour,
                )
            ):
                if row.id not in files:
                    data = s3.get_bytes(row.storage_key, frame_vectors.MAX_BYTES)
                    try:
                        files[row.id] = frame_vectors.unpack(data) if data else None
                    except frame_vectors.BadFrameVectorFile:
                        files[row.id] = None
                found = files[row.id]
                if found is None or found.vectors.shape[1] != len(vector):
                    continue
                start = (segment.started_at - hour).total_seconds()
                end = (segment.ended_at - hour).total_seconds()
                inside = (found.seconds >= start) & (found.seconds <= end)
                if inside.any():
                    sims = found.vectors[inside] @ vector
                    i = int(sims.argmax())
                    if float(sims[i]) > best_sim:
                        best_sim = float(sims[i])
                        best_at = hour + timedelta(
                            seconds=float(found.seconds[inside][i])
                        )
            hour += timedelta(hours=1)
        return best_at, best_sim

    def _near(self, segment, when: datetime) -> list[uuid.UUID]:
        """The moment that carries a visual hit: the photo kept in its segment, else the
        closest event within VISUAL_NEAR_S (a conversation, another photo)."""
        if segment.kept_media_ids:
            kept = list(
                self.db.scalars(
                    select(MediaAsset.event_id).where(
                        MediaAsset.id.in_(segment.kept_media_ids),
                        MediaAsset.patient_id == self.patient_id,
                        MediaAsset.event_id.is_not(None),
                        MediaAsset.deleted_at.is_(None),
                    )
                )
            )
            if kept:
                return kept[:1]
        gap = func.abs(func.extract("epoch", Event.occurred_at - when))
        closest = self.db.scalars(
            select(Event.id)
            .where(
                Event.patient_id == self.patient_id,
                Event.deleted_at.is_(None),
                Event.occurred_at >= when - timedelta(seconds=VISUAL_NEAR_S),
                Event.occurred_at <= when + timedelta(seconds=VISUAL_NEAR_S),
            )
            .order_by(gap)
            .limit(1)
        ).first()
        return [closest] if closest else []

    # ----- results -----

    def _evidence(
        self, ranked: list[uuid.UUID], lines: dict[uuid.UUID, list[str]]
    ) -> list[Evidence]:
        if not ranked:
            return []
        events = {
            e.id: e
            for e in self.db.scalars(select(Event).where(and_(Event.id.in_(ranked))))
        }
        out = []
        for event_id in ranked:
            event = events.get(event_id)
            if event is None:
                continue
            sentence = event.rendered_text or event.transcript_text or event.event_type
            extra = lines.get(event_id, [])[:MAX_LINES]
            text = f"[{'; '.join(extra)}] {sentence}" if extra else sentence
            out.append(
                Evidence(
                    event_id=str(event_id),
                    occurred_at=f"{event.occurred_at.astimezone(self.tz):%Y-%m-%d %H:%M}",
                    text=text,
                )
            )
        return out
