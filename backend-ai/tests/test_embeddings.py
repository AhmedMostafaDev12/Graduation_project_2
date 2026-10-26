"""Phase 7.3: journal events → sentence (track R2 renderer) + embedding (spec §7.3 step 4, D15).

Voyage and OpenAI are mocked with respx and the service uses the stub profile's fake embedder: tests never
call a real AI API (AI_LAYER.md rule 9)."""

import json
import uuid
from datetime import UTC, datetime, timedelta

import httpx
import pytest
import respx
from sqlalchemy import update

from app.ai.clients.embeddings import (
    OPENAI_EMBEDDINGS_URL,
    VOYAGE_EMBEDDINGS_URL,
    EmbeddingError,
    OpenAITextEmbedder,
    VoyageTextEmbedder,
)
from app.errors import TransientError
from app.models import TEXT_DIM, EnrolledPerson, Event, Reminder, ReminderLog
from app.services import embedding_service
from app.workers.tasks import embedding as embedding_tasks
from tests.conftest import create_patient, register_and_login

NOW = datetime(2026, 10, 1, 6, 20, tzinfo=UTC)  # 09:20 in Cairo (summer time, UTC+3)


# ----- the embedding clients -----


def _openai_reply(n, dim=TEXT_DIM):
    # returned out of order on purpose: the client must sort by index
    return {
        "data": [
            {"index": i, "embedding": [float(i)] * dim} for i in reversed(range(n))
        ]
    }


@respx.mock
def test_openai_embeds_a_batch_in_order():
    route = respx.post(OPENAI_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(200, json=_openai_reply(2))
    )
    vectors = OpenAITextEmbedder(api_key="test-key").embed(["أ", "b"])
    assert [v[0] for v in vectors] == [0.0, 1.0] and len(vectors[0]) == TEXT_DIM
    request = route.calls.last.request
    assert request.headers["Authorization"] == "Bearer test-key"
    body = json.loads(request.content)
    assert body["model"] == "text-embedding-3-small"
    assert body["dimensions"] == TEXT_DIM  # shortened to fit the same columns


@respx.mock
def test_voyage_embeds_documents_at_our_size():
    route = respx.post(VOYAGE_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(200, json=_openai_reply(2))
    )
    vectors = VoyageTextEmbedder(api_key="test-key").embed(["أ", "b"])
    assert [v[0] for v in vectors] == [0.0, 1.0] and len(vectors[0]) == TEXT_DIM
    request = route.calls.last.request
    assert request.headers["Authorization"] == "Bearer test-key"
    body = json.loads(request.content)
    assert body == {
        "model": "voyage-4",
        "input": ["أ", "b"],
        "input_type": "document",
        "output_dimension": TEXT_DIM,
    }


@pytest.mark.parametrize("status", [429, 500, 503])
@respx.mock
def test_voyage_rate_limits_and_server_errors_are_retried(status):
    respx.post(VOYAGE_EMBEDDINGS_URL).mock(return_value=httpx.Response(status))
    with pytest.raises(TransientError):
        VoyageTextEmbedder(api_key="k").embed(["a"])


@respx.mock
def test_voyage_bad_key_or_wrong_size_is_not_retried():
    respx.post(VOYAGE_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(401, json={"detail": "bad key"})
    )
    with pytest.raises(EmbeddingError, match="Voyage rejected"):
        VoyageTextEmbedder(api_key="k").embed(["a"])
    respx.post(VOYAGE_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(200, json=_openai_reply(1, dim=1536))
    )
    with pytest.raises(EmbeddingError, match="unexpected"):
        VoyageTextEmbedder(api_key="k").embed(["a"])


def test_voyage_needs_a_key_and_skips_empty_input():
    with pytest.raises(EmbeddingError, match="VOYAGE_API_KEY"):
        VoyageTextEmbedder(api_key="")
    assert VoyageTextEmbedder(api_key="k").embed([]) == []


@pytest.mark.parametrize("status", [429, 500, 503])
@respx.mock
def test_openai_rate_limits_and_server_errors_are_retried(status):
    respx.post(OPENAI_EMBEDDINGS_URL).mock(return_value=httpx.Response(status))
    with pytest.raises(TransientError):
        OpenAITextEmbedder(api_key="k").embed(["a"])


@respx.mock
def test_openai_timeout_is_retried():
    respx.post(OPENAI_EMBEDDINGS_URL).mock(side_effect=httpx.ConnectTimeout("slow"))
    with pytest.raises(TransientError):
        OpenAITextEmbedder(api_key="k").embed(["a"])


@respx.mock
def test_openai_bad_request_or_wrong_size_is_not_retried():
    respx.post(OPENAI_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(401, json={"error": {"message": "bad key"}})
    )
    with pytest.raises(EmbeddingError):
        OpenAITextEmbedder(api_key="k").embed(["a"])
    respx.post(OPENAI_EMBEDDINGS_URL).mock(
        return_value=httpx.Response(200, json=_openai_reply(1, dim=3))
    )
    with pytest.raises(EmbeddingError):
        OpenAITextEmbedder(api_key="k").embed(["a"])


def test_openai_needs_a_key_and_skips_empty_input():
    with pytest.raises(EmbeddingError, match="OPENAI_API_KEY"):
        OpenAITextEmbedder(api_key="")
    assert OpenAITextEmbedder(api_key="k").embed([]) == []


# ----- the service and tasks (database) -----


def _patient(client, worker_session):
    manager = register_and_login(client)
    patient_id = uuid.UUID(create_patient(client, manager)["id"])
    with worker_session() as db:
        ahmed = EnrolledPerson(
            patient_id=patient_id,
            name="Ahmed",
            relationship="son",
            added_by="caregiver_manual",
            status="active",
        )
        db.add(ahmed)
        db.commit()
        return patient_id, ahmed.id


def _event(db, patient_id, **fields):
    event = Event(
        id=uuid.uuid4(),
        patient_id=patient_id,
        source="glasses",
        occurred_at=NOW,
        **fields,
    )
    db.add(event)
    db.flush()
    return event.id


def test_events_get_a_sentence_and_an_embedding(client, worker_session):
    patient_id, ahmed = _patient(client, worker_session)
    with worker_session() as db:
        conversation = _event(
            db,
            patient_id,
            event_type="conversation_segment",
            ended_at=NOW + timedelta(minutes=4),
            transcript_text="ميعاد الدكتور بكره الساعة خمسة",
            language="ar",
            metadata_={"present_person_ids": [str(ahmed)]},
        )
        encounter = _event(db, patient_id, event_type="encounter", person_id=ahmed)
        reminder = Reminder(
            patient_id=patient_id,
            title="Blood pressure pill",
            type="medication",
            rrule="FREQ=DAILY",
            dtstart=NOW,
            created_by=patient_id,
        )
        db.add(reminder)
        db.flush()
        log = ReminderLog(
            reminder_id=reminder.id,
            scheduled_at=NOW,
            status="completed",
            confirmed_via="voice",
        )
        db.add(log)
        db.flush()
        taken = _event(db, patient_id, event_type="reminder", reminder_log_id=log.id)
        db.commit()

    # the test database is shared, so the sweep may also embed other tests' events
    assert embedding_tasks.backfill.delay().get() >= 3

    with worker_session() as db:
        for event_id in (conversation, encounter, taken):
            event = db.get(Event, event_id)
            assert event.rendered_text and len(event.embedding) == TEXT_DIM
            assert event.metadata_["embedding_model"] == "fake-text-embedder"
        said = db.get(Event, conversation)
        assert "Ahmed" in said.rendered_text and "ميعاد الدكتور" in said.rendered_text
        assert "09:20" in said.rendered_text  # Cairo local time, not UTC
        assert said.metadata_["present_person_ids"] == [str(ahmed)]  # kept
        assert "Ahmed" in db.get(Event, encounter).rendered_text


def test_running_again_embeds_nothing_twice(client, worker_session):
    patient_id, _ = _patient(client, worker_session)
    with worker_session() as db:
        event_id = _event(db, patient_id, event_type="memory_paused")
        db.commit()
    assert embedding_tasks.embed_events.delay([str(event_id)]).get() == 1
    assert embedding_tasks.embed_events.delay([str(event_id)]).get() == 0
    with worker_session() as db:
        assert event_id not in embedding_service.pending_event_ids(db, 10_000)


def test_deleted_events_are_skipped(client, worker_session):
    patient_id, _ = _patient(client, worker_session)
    with worker_session() as db:
        event_id = _event(db, patient_id, event_type="memory_resumed")
        db.execute(update(Event).where(Event.id == event_id).values(deleted_at=NOW))
        db.commit()
        assert event_id not in embedding_service.pending_event_ids(db, 100)
    assert embedding_tasks.embed_events.delay([str(event_id)]).get() == 0
    with worker_session() as db:
        assert db.get(Event, event_id).embedding is None


def test_a_failed_embedding_call_stores_nothing(client, worker_session, monkeypatch):
    patient_id, _ = _patient(client, worker_session)
    with worker_session() as db:
        event_id = _event(db, patient_id, event_type="memory_paused")
        db.commit()

    class Down:
        model_id, dim = "down", TEXT_DIM

        def embed(self, texts):
            raise TransientError("OpenAI returned 503")

    class Models:
        text_embedder = Down()

    monkeypatch.setattr(embedding_service, "get_ai", lambda: Models())
    with worker_session() as db, pytest.raises(TransientError):
        embedding_service.embed_events(db, [event_id])
    with worker_session() as db:
        event = db.get(Event, event_id)
        assert event.embedding is None and event.rendered_text is None
