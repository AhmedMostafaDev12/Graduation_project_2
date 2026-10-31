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
from zoneinfo import ZoneInfo

from sqlalchemy import Text, and_, case, cast, func, literal, or_, select
from sqlalchemy.dialects.postgresql import array
from sqlalchemy.orm import Session

from app.ai.interfaces import TextEmbedder
from app.ai.rag.assist_loop import TOP_K, Evidence
from app.ai.rag.planner import QueryPlan
from app.models import (
    Encounter,
    Event,
    MediaAsset,
    MemoryAction,
    MemoryEntity,
    MemoryFact,
    MemoryIntention,
    ObjectSighting,
)

PER_RANKING = 20  # candidates each ranking contributes before fusion
RRF_K = 60  # reciprocal rank fusion constant (the usual value)
STRUCTURE_WEIGHT = 2.0  # a structure match is precise: it counts twice
ENTITY_MATCH = 0.45  # DRAFT: query ↔ entity-name cosine to count as "about" that entity
MAX_LINES = 3  # structure lines put in front of one event's text
MIN_WORD = 3  # shorter words are too common to search for
OUTSIDE_WINDOW = "outside the time asked: the last time this person was present"
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
    ):
        self.db, self.patient_id, self.tz = db, patient_id, ZoneInfo(tz)
        self.embedder, self.top_k = embedder, top_k

    async def search(self, plan: QueryPlan) -> list[Evidence]:
        # the session belongs to this thread; the loop awaits searches one at a time
        return self.search_now(plan)

    def search_now(self, plan: QueryPlan) -> list[Evidence]:
        conditions = self._filters(plan)
        tokens = words(plan.search_text)
        lines: dict[uuid.UUID, list[str]] = {}
        if plan.search_text.strip():
            query = self.embedder.embed_query(plan.search_text)
            lines = self._structures(conditions, tokens, query, plan)
            ranked = fuse(
                [
                    (list(lines), STRUCTURE_WEIGHT),
                    (self._by_meaning(conditions, query), 1.0),
                    (self._by_words(conditions, tokens), 1.0),
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
        self, conditions: list, tokens: list[str], query: list[float], plan: QueryPlan
    ) -> dict[uuid.UUID, list[str]]:
        """event id → lines from the structures that match, best first."""
        entities = self._entities(tokens, query)
        candidates = self._candidates(conditions)
        lines: dict[uuid.UUID, list[str]] = defaultdict(list)
        ids = list(entities)

        def add(event_id, line):
            if event_id is not None and line not in lines[event_id]:
                lines[event_id].append(line)

        if ids:
            sightings = self.db.execute(
                select(ObjectSighting, MediaAsset.event_id)
                .join(MediaAsset, MediaAsset.id == ObjectSighting.media_asset_id)
                .where(
                    ObjectSighting.entity_id.in_(ids),
                    ObjectSighting.deleted_at.is_(None),
                    MediaAsset.event_id.in_(candidates),
                )
                .order_by(ObjectSighting.seen_at.desc())
                .limit(PER_RANKING)
            ).all()
            for sighting, event_id in sightings:
                where = ", ".join(x for x in (sighting.state, sighting.room) if x)
                name = entities[sighting.entity_id]
                add(event_id, f"{name} seen" + (f": {where}" if where else ""))

        action_match = [MemoryAction.entity_id.in_(ids)] if ids else []
        action_match += [MemoryAction.verb.contains(t) for t in tokens]
        if action_match:
            actions = self.db.execute(
                select(MemoryAction, MemoryEntity.name)
                .outerjoin(MemoryEntity, MemoryEntity.id == MemoryAction.entity_id)
                .where(
                    or_(*action_match),
                    MemoryAction.deleted_at.is_(None),
                    MemoryAction.evidence_event_id.in_(candidates),
                )
                .order_by(MemoryAction.occurred_at.desc())
                .limit(PER_RANKING)
            ).all()
            for action, name in actions:
                amount = (
                    f" ×{action.quantity:g} {action.unit or ''}".rstrip()
                    if action.quantity
                    else ""
                )
                verb = action.verb.replace("_", " ")
                add(
                    action.evidence_event_id,
                    f"action: {verb} {name or ''}".rstrip() + amount,
                )

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
                    MemoryFact.event_id.in_(candidates),
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

        plan_match = [
            or_(
                func.lower(MemoryIntention.description).contains(t),
                func.lower(MemoryIntention.quote).contains(t),
            )
            for t in tokens
        ]
        if plan_match:
            plans = self.db.scalars(
                select(MemoryIntention)
                .where(
                    or_(*plan_match),
                    MemoryIntention.deleted_at.is_(None),
                    MemoryIntention.source_event_id.in_(candidates),
                )
                .order_by(MemoryIntention.stated_at.desc())
                .limit(PER_RANKING)
            ).all()
            for intention in plans:
                due = (
                    f", due {intention.due_at.astimezone(self.tz):%Y-%m-%d %H:%M}"
                    if intention.due_at
                    else ""
                )
                add(
                    intention.source_event_id,
                    f"plan: {intention.description} (status: {intention.status}{due})",
                )
        return {k: v for k, v in lines.items() if v}

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
