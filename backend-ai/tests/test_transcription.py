"""Phase 7.2: transcribe one audio segment into a journal transcript (spec §7.3, D4, D36, §9).

Tasks run inline (worker_session), S3 is in memory (fake_s3), and speech-to-text is a fake:
tests never call a real AI API (AI_LAYER.md rule 9)."""

import subprocess
import uuid
from datetime import UTC, datetime, timedelta

import imageio_ffmpeg
import pytest
from sqlalchemy import select, update

from app.ai.clients.stt import SpeechToTextError
from app.ai.interfaces import Transcript, TranscriptSegment
from app.errors import TransientError
from app.models import (
    AudioSegment,
    ConsentRecord,
    Encounter,
    EnrolledPerson,
    Event,
    PatientProfile,
)
from app.services import transcription_service
from app.workers.tasks import transcription as transcription_tasks
from tests.conftest import API, pair_device, register_and_login

NOW = datetime.now(UTC).replace(microsecond=0)


class ScriptedSTT:
    """Returns a fixed transcript (or raises), and records what it was sent."""

    model_id = "scripted-stt"

    def __init__(self, text="ميعاد الدكتور بكره الساعة خمسة", error=None):
        self.text, self.error, self.calls = text, error, []

    def transcribe(self, audio, content_type, language_hint=None):
        self.calls.append((audio, content_type, language_hint))
        if self.error:
            raise self.error
        segments = (
            [TranscriptSegment(0.0, 2.5, self.text, speaker="A")] if self.text else []
        )
        return Transcript(
            text=self.text, language="ar", model_id=self.model_id, segments=segments
        )


@pytest.fixture
def stt(monkeypatch):
    fake = ScriptedSTT()

    class Models:
        pass

    models = Models()
    models.stt = fake
    monkeypatch.setattr(transcription_service, "get_ai", lambda: models)
    return fake


def _patient_with_audio(client, fake_s3, worker_session, consents=None):
    manager = register_and_login(client)
    response = client.post(
        f"{API}/patients",
        json={
            "full_name": "Fatma",
            "relationship": "son",
            "consents": consents
            if consents is not None
            else ["cloud_processing", "ambient_audio_household"],
        },
        headers=manager["headers"],
    )
    assert response.status_code == 201, response.text
    patient_id = uuid.UUID(response.json()["id"])
    phone = pair_device(client, manager, str(patient_id))
    device_id = uuid.UUID(phone["device_id"])

    segment_id = uuid.uuid4()
    key = f"patients/{patient_id}/audio/{segment_id}.ogg"
    fake_s3.put_bytes(key, b"opus-bytes", "audio/ogg")
    with worker_session() as db:
        db.add(
            AudioSegment(
                id=segment_id,
                patient_id=patient_id,
                device_id=device_id,
                started_at=NOW,
                ended_at=NOW + timedelta(seconds=20),
                storage_key=key,
                status="uploaded",
            )
        )
        db.commit()
    return patient_id, device_id, segment_id, key


def _person(db, patient_id, name):
    person = EnrolledPerson(
        patient_id=patient_id,
        name=name,
        relationship="son",
        added_by="caregiver_manual",
        status="active",
    )
    db.add(person)
    db.flush()
    return person.id


def test_transcribes_into_a_conversation_segment_and_deletes_the_audio(
    client, fake_s3, worker_session, stt
):
    patient_id, device_id, segment_id, key = _patient_with_audio(
        client, fake_s3, worker_session
    )
    with worker_session() as db:
        ahmed = _person(db, patient_id, "Ahmed")
        sara = _person(db, patient_id, "Sara")
        for person_id, start in (
            (ahmed, NOW - timedelta(minutes=1)),
            (sara, NOW - timedelta(hours=2)),
        ):
            db.add(
                Encounter(
                    patient_id=patient_id,
                    device_id=device_id,
                    person_id=person_id,
                    started_at=start,
                    ended_at=start + timedelta(minutes=2),
                    best_confidence=0.9,
                )
            )
        db.commit()

    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == (
        "transcribed"
    )

    with worker_session() as db:
        segment = db.get(AudioSegment, segment_id)
        assert segment.status == "deleted" and segment.storage_key is None
        assert segment.attempts == 1
        event = db.get(Event, segment.event_id)
        assert event.event_type == "conversation_segment"
        assert event.source == "glasses" and event.device_id == device_id
        assert event.transcript_text == "ميعاد الدكتور بكره الساعة خمسة"
        assert event.language == "ar"
        assert event.occurred_at == NOW and event.ended_at == NOW + timedelta(
            seconds=20
        )
        # only Ahmed's encounter overlaps the segment
        assert event.metadata_["present_person_ids"] == [str(ahmed)]
        assert event.metadata_["segments"][0]["speaker"] == "A"
        assert event.metadata_["stt_model"] == "scripted-stt"
        # 7.3: the new transcript is rendered and embedded right away
        assert event.rendered_text and "Ahmed" in event.rendered_text
        assert event.embedding is not None
    assert key not in fake_s3.objects  # spec D4: only the transcript is kept
    # the fake audio isn't decodable, so it was sent as it came, in the patient's language
    assert stt.calls == [(b"opus-bytes", "audio/ogg", "ar")]


def test_running_twice_gives_one_event(client, fake_s3, worker_session, stt):
    _, _, segment_id, _ = _patient_with_audio(client, fake_s3, worker_session)
    first = transcription_tasks.transcribe_segment.delay(str(segment_id)).get()
    second = transcription_tasks.transcribe_segment.delay(str(segment_id)).get()
    assert (first, second) == ("transcribed", "done")
    with worker_session() as db:
        events = db.scalars(
            select(Event).where(
                Event.id == transcription_service.event_id_for(segment_id)
            )
        ).all()
        assert len(events) == 1
    assert len(stt.calls) == 1


def test_no_household_consent_deletes_the_audio_untranscribed(
    client, fake_s3, worker_session, stt
):
    _, _, segment_id, key = _patient_with_audio(
        client, fake_s3, worker_session, consents=["cloud_processing"]
    )
    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == (
        "not_allowed"
    )
    with worker_session() as db:
        segment = db.get(AudioSegment, segment_id)
        assert segment.status == "deleted" and segment.event_id is None
    assert key not in fake_s3.objects
    assert stt.calls == []  # nothing reached the provider


def test_master_switch_off_or_revoked_consent_blocks_transcription(
    client, fake_s3, worker_session, stt
):
    patient_id, _, segment_id, _ = _patient_with_audio(client, fake_s3, worker_session)
    with worker_session() as db:
        db.execute(
            update(PatientProfile)
            .where(PatientProfile.user_id == patient_id)
            .values(memory_capture_enabled=False)
        )
        db.commit()
        assert not transcription_service.capture_allowed(db, patient_id)

        db.execute(
            update(PatientProfile)
            .where(PatientProfile.user_id == patient_id)
            .values(memory_capture_enabled=True)
        )
        db.execute(
            update(ConsentRecord)
            .where(
                ConsentRecord.patient_id == patient_id,
                ConsentRecord.consent_type == "ambient_audio_household",
            )
            .values(revoked_at=NOW)
        )
        db.commit()
        assert not transcription_service.capture_allowed(db, patient_id)

    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == (
        "not_allowed"
    )
    assert stt.calls == []


def test_silence_creates_no_event(client, fake_s3, worker_session, stt):
    _, _, segment_id, key = _patient_with_audio(client, fake_s3, worker_session)
    stt.text = ""
    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == (
        "no_speech"
    )
    with worker_session() as db:
        segment = db.get(AudioSegment, segment_id)
        assert segment.status == "deleted" and segment.event_id is None
    assert key not in fake_s3.objects


def test_permanent_stt_error_marks_failed_and_keeps_the_audio_for_retention(
    client, fake_s3, worker_session, stt
):
    _, _, segment_id, key = _patient_with_audio(client, fake_s3, worker_session)
    stt.error = SpeechToTextError("bad audio")
    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == (
        "failed"
    )
    with worker_session() as db:
        assert db.get(AudioSegment, segment_id).status == "failed"
    assert key in fake_s3.objects  # retention deletes it after 7 days (spec §8)


def test_temporary_errors_are_retried_then_marked_failed(
    client, fake_s3, worker_session, stt
):
    _, _, segment_id, key = _patient_with_audio(client, fake_s3, worker_session)
    stt.error = TransientError("Deepgram returned 503")

    with worker_session() as db, pytest.raises(TransientError):
        transcription_service.transcribe_segment(db, segment_id)
    with worker_session() as db:
        segment = db.get(AudioSegment, segment_id)
        assert segment.status == "transcribing" and segment.attempts == 1

    # the last retry fails too: the task marks the segment failed and re-raises
    # (in tests, tasks run inline and errors propagate)
    with pytest.raises(TransientError):
        transcription_tasks.transcribe_segment.apply(
            args=[str(segment_id)], retries=transcription_tasks.MAX_RETRIES
        )
    with worker_session() as db:
        assert db.get(AudioSegment, segment_id).status == "failed"
    assert key in fake_s3.objects


def test_a_crash_after_saving_the_transcript_still_deletes_the_audio(
    client, fake_s3, worker_session, stt
):
    _, _, segment_id, key = _patient_with_audio(client, fake_s3, worker_session)
    with worker_session() as db:
        db.execute(
            update(AudioSegment)
            .where(AudioSegment.id == segment_id)
            .values(status="transcribed")
        )
        db.commit()
    assert transcription_tasks.transcribe_segment.delay(str(segment_id)).get() == "done"
    with worker_session() as db:
        assert db.get(AudioSegment, segment_id).status == "deleted"
    assert key not in fake_s3.objects
    assert stt.calls == []


def test_unknown_segment_is_ignored(worker_session, stt):
    assert transcription_tasks.transcribe_segment.delay(str(uuid.uuid4())).get() == (
        "missing"
    )


def test_normalize_boosts_real_audio_and_rejects_garbage():
    tone = subprocess.run(
        [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=300:duration=1",
            "-af",
            "volume=0.05",
            "-c:a",
            "libopus",
            "-f",
            "ogg",
            "pipe:1",
        ],
        capture_output=True,
        check=True,
    ).stdout
    wav = transcription_service.normalize(tone)
    assert wav is not None and wav[:4] == b"RIFF"
    assert transcription_service.normalize(b"not audio") is None


# ----- phase 7.4: uploads start the transcription; the sweep catches what was missed -----


def _complete_audio(client, patient_id, clip_id, phone):
    return client.post(
        f"{API}/uploads/{clip_id}/complete",
        json={
            "patient_id": patient_id,
            "kind": "audio",
            "content_type": "audio/ogg",
            "started_at": "2026-10-12T10:00:00+03:00",
            "ended_at": "2026-10-12T10:00:20+03:00",
        },
        headers=phone["headers"],
    )


def test_the_phones_audio_upload_ends_up_in_the_journal(client, fake_s3, stt):
    manager = register_and_login(client)
    patient = client.post(
        f"{API}/patients",
        json={
            "full_name": "Fatma",
            "relationship": "son",
            "consents": ["cloud_processing", "ambient_audio_household"],
        },
        headers=manager["headers"],
    ).json()
    phone = pair_device(client, manager, patient["id"])
    base = f"{API}/patients/{patient['id']}"

    clip_id = str(uuid.uuid4())
    ticket = client.post(
        f"{base}/uploads",
        json={"id": clip_id, "kind": "audio", "content_type": "audio/ogg"},
        headers=phone["headers"],
    ).json()
    fake_s3.put_bytes(ticket["key"], b"opus-bytes", "audio/ogg")
    done = _complete_audio(client, patient["id"], clip_id, phone)
    # the phone is told what happened at upload time; the work runs after the commit
    assert done.status_code == 200 and done.json()["status"] == "uploaded"

    journal = client.get(
        f"{base}/journal", params={"date": "2026-10-12"}, headers=manager["headers"]
    ).json()
    talks = [e for e in journal["entries"] if e["event_type"] == "conversation_segment"]
    assert len(talks) == 1
    assert talks[0]["transcript_text"] == "ميعاد الدكتور بكره الساعة خمسة"
    assert talks[0]["rendered_text"]  # 7.3 ran right after 7.2
    assert ticket["key"] not in fake_s3.objects  # spec D4: the audio is gone
    assert len(stt.calls) == 1

    # the phone retrying `complete` doesn't transcribe twice
    again = _complete_audio(client, patient["id"], clip_id, phone)
    assert again.status_code == 200 and len(stt.calls) == 1


def test_backfill_requeues_only_stuck_segments(client, fake_s3, worker_session, stt):
    _, _, missed, _ = _patient_with_audio(client, fake_s3, worker_session)
    _, _, fresh, _ = _patient_with_audio(client, fake_s3, worker_session)
    _, _, given_up, _ = _patient_with_audio(client, fake_s3, worker_session)
    with worker_session() as db:
        # the test database is shared and kept between runs: retire other tests' leftover
        # segments so the sweep only meets this test's three (their audio isn't in fake_s3)
        db.execute(
            update(AudioSegment)
            .where(
                AudioSegment.id.not_in([missed, fresh, given_up]),
                AudioSegment.status.in_(("uploaded", "transcribing")),
            )
            .values(status="deleted", storage_key=None)
        )
        db.execute(
            update(AudioSegment)
            .where(AudioSegment.id == missed)
            .values(created_at=NOW - timedelta(minutes=10))  # queueing failed
        )
        db.execute(
            update(AudioSegment)
            .where(AudioSegment.id == given_up)
            .values(
                status="transcribing",
                attempts=transcription_tasks.MAX_RETRIES + 1,
                created_at=NOW - timedelta(hours=2),
            )
        )
        db.commit()
        stuck = transcription_service.stuck_segment_ids(
            db, max_attempts=transcription_tasks.MAX_RETRIES
        )
        assert missed in stuck
        assert fresh not in stuck  # just uploaded: its own task is on the way
        assert given_up not in stuck  # out of retries: retention deletes it

    assert transcription_tasks.backfill.delay().get() >= 1
    with worker_session() as db:
        assert db.get(AudioSegment, missed).status == "deleted"  # transcribed + cleaned
        assert db.get(AudioSegment, fresh).status == "uploaded"
