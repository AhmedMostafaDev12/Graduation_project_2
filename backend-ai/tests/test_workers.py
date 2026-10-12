"""Phase 6 background tasks: alerts, retention, previews. Every task runs twice -> one result
(docs/CELERY_REDIS.md §6). Tasks run inline here; no Redis needed."""

import io
import os
import subprocess
import tempfile
import uuid
from datetime import UTC, datetime, timedelta

import imageio_ffmpeg
import pytest
from celery.exceptions import Retry
from PIL import Image
from sqlalchemy import select, update

from app.errors import StorageUnavailable
from app.models import (
    AudioSegment,
    AuditLog,
    CaregiverAlert,
    Device,
    MediaAsset,
)
from app.services import alert_service, retention_service
from app.workers.tasks import alerts as alert_tasks
from app.workers.tasks import media as media_tasks
from app.workers.tasks import retention as retention_tasks
from tests.conftest import (
    API,
    add_viewer,
    create_patient,
    image_bytes,
    pair_device,
    register_and_login,
)

NOW = datetime.now(UTC)


def _family(client):
    manager = register_and_login(client)
    patient = create_patient(client, manager)
    viewer = add_viewer(client, manager, patient["id"])
    phone = pair_device(client, manager, patient["id"])
    return manager, viewer, patient, phone, f"{API}/patients/{patient['id']}"


def _alerts(session_factory, patient_id, alert_type=None):
    with session_factory() as db:
        query = select(CaregiverAlert).where(
            CaregiverAlert.patient_id == uuid.UUID(patient_id)
        )
        if alert_type:
            query = query.where(CaregiverAlert.alert_type == alert_type)
        return list(db.scalars(query))


def _medication_log(
    client, manager, phone, base, status, scheduled_at, kind="medication"
):
    reminder = client.post(
        f"{base}/reminders",
        json={
            "title": "Blood pressure pill",
            "type": kind,
            "rrule": "FREQ=DAILY",
            "dtstart": "2026-10-01T09:00:00+03:00",
        },
        headers=manager["headers"],
    ).json()
    log_id = str(uuid.uuid4())
    client.post(
        f"{base}/reminder-logs:batch",
        json={
            "logs": [
                {
                    "id": log_id,
                    "reminder_id": reminder["id"],
                    "scheduled_at": scheduled_at.isoformat(),
                    "status": status,
                }
            ]
        },
        headers=phone["headers"],
    )
    return log_id


# ----- alerts.evaluate -----


def test_missed_medication_alerts_every_caregiver_once(client, worker_session):
    manager, viewer, patient, phone, base = _family(client)
    log_id = _medication_log(
        client, manager, phone, base, "missed", NOW - timedelta(hours=1)
    )

    # the test database is shared, so count this patient's alerts, not the task's total
    alert_tasks.evaluate.delay().get()
    alert_tasks.evaluate.delay().get()  # run twice -> one result
    alerts = _alerts(worker_session, patient["id"], "missed_medication")
    assert len(alerts) == 2  # manager + viewer, once each
    assert {str(a.caregiver_id) for a in alerts} == {manager["id"], viewer["id"]}
    assert all(
        a.entity_type == "reminder_log" and str(a.entity_id) == log_id for a in alerts
    )
    assert "Blood pressure pill" in alerts[0].message

    feed = client.get(f"{API}/caregivers/me/alerts", headers=viewer["headers"]).json()
    assert [a["alert_type"] for a in feed] == ["missed_medication"]


def test_missed_medication_grace_period_and_filters(client, worker_session):
    manager, _, patient, phone, base = _family(client)
    _medication_log(
        client, manager, phone, base, "pending", NOW - timedelta(minutes=61)
    )
    _medication_log(
        client, manager, phone, base, "pending", NOW - timedelta(minutes=30)
    )
    _medication_log(client, manager, phone, base, "completed", NOW - timedelta(hours=2))
    _medication_log(client, manager, phone, base, "missed", NOW - timedelta(hours=30))
    _medication_log(
        client, manager, phone, base, "missed", NOW - timedelta(hours=1), "task"
    )

    with worker_session() as db:
        alert_service.evaluate(db, now=NOW)
    # only the 61-minute pending one, for manager + viewer
    assert len(_alerts(worker_session, patient["id"], "missed_medication")) == 2


def test_device_offline_once_per_spell(client, worker_session):
    _, _, patient, phone, _ = _family(client)
    device_id = uuid.UUID(phone["device_id"])

    def seen(at):
        with worker_session() as db:
            db.execute(
                update(Device).where(Device.id == device_id).values(last_seen_at=at)
            )
            db.commit()

    def offline_alerts_after(now):
        with worker_session() as db:
            alert_service.evaluate(db, now=now)
        return len(_alerts(worker_session, patient["id"], "device_offline"))

    seen(NOW - timedelta(minutes=31))
    assert offline_alerts_after(NOW) == 2  # manager + viewer
    assert (
        offline_alerts_after(NOW + timedelta(minutes=5)) == 2
    )  # same spell: nothing new

    seen(NOW + timedelta(minutes=10))  # back online, then silent again
    assert offline_alerts_after(NOW + timedelta(minutes=20)) == 2  # not 30 min yet
    assert offline_alerts_after(NOW + timedelta(minutes=45)) == 4  # a new spell


def test_low_battery_at_most_every_12_hours(client, worker_session):
    _, _, patient, phone, _ = _family(client)
    client.post(
        f"{API}/devices/{phone['device_id']}/heartbeat",
        json={"battery_level_pct": 15},
        headers=phone["headers"],
    )
    with worker_session() as db:
        alert_service.evaluate(db)
        alert_service.evaluate(db)  # twice -> one result
    [alert, _] = _alerts(
        worker_session, patient["id"], "low_battery"
    )  # manager + viewer
    assert alert.entity_type == "device" and "15%" in alert.message


# ----- retention.expire_media -----


def _media(client, fake_s3, worker_session, base, phone, **columns):
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "notable_moment_captured",
        "occurred_at": NOW.isoformat(),
    }
    client.post(
        f"{base}/events:batch", json={"events": [event]}, headers=phone["headers"]
    )
    media_id = uuid.uuid4()
    key = f"patients/x/media/{media_id}.jpg"
    fake_s3.put_bytes(key, image_bytes(), "image/jpeg")
    fake_s3.put_bytes(key.replace(".jpg", ".thumb.jpg"), b"thumb", "image/jpeg")
    with worker_session() as db:
        patient_id = db.scalar(
            select(Device.patient_id).where(Device.id == uuid.UUID(phone["device_id"]))
        )
        db.add(
            MediaAsset(
                id=media_id,
                patient_id=patient_id,
                event_id=uuid.UUID(event["id"]),
                asset_type="image",
                storage_key=key,
                trigger="salient_frame",
                status="confirmed",
                thumbnail_key=key.replace(".jpg", ".thumb.jpg"),
                **columns,
            )
        )
        db.commit()
    return media_id, key


def test_retention_deletes_only_expired_unpinned_photos(
    client, fake_s3, worker_session
):
    manager, _, _, phone, base = _family(client)
    expired, expired_key = _media(
        client,
        fake_s3,
        worker_session,
        base,
        phone,
        retention_policy="auto_expire",
        expires_at=NOW - timedelta(hours=1),
    )
    future, _ = _media(
        client,
        fake_s3,
        worker_session,
        base,
        phone,
        retention_policy="auto_expire",
        expires_at=NOW + timedelta(days=3),
    )
    pinned, _ = _media(
        client,
        fake_s3,
        worker_session,
        base,
        phone,
        retention_policy="auto_expire",
        expires_at=NOW - timedelta(hours=1),
        pinned_by=uuid.UUID(manager["id"]),
    )

    result = retention_tasks.expire_media.delay().get()
    assert result["media"] == 1
    assert (
        retention_tasks.expire_media.delay().get()["media"] == 0
    )  # twice -> one result
    assert expired_key not in fake_s3.objects
    assert expired_key.replace(".jpg", ".thumb.jpg") not in fake_s3.objects
    with worker_session() as db:
        assert db.get(MediaAsset, expired).deleted_at is not None
        assert db.get(MediaAsset, future).deleted_at is None
        assert db.get(MediaAsset, pinned).deleted_at is None
        assert db.scalar(
            select(AuditLog.action).where(AuditLog.entity_id == expired)
        ) == ("retention.delete")


def test_retention_deletes_audio_never_transcribed_after_7_days(
    client, fake_s3, worker_session
):
    _, _, _, phone, _ = _family(client)
    segments = []
    for age_days in (8, 6):
        segment_id = uuid.uuid4()
        key = f"patients/x/audio/{segment_id}.ogg"
        fake_s3.put_bytes(key, b"ogg", "audio/ogg")
        with worker_session() as db:
            patient_id = db.scalar(
                select(Device.patient_id).where(
                    Device.id == uuid.UUID(phone["device_id"])
                )
            )
            db.add(
                AudioSegment(
                    id=segment_id,
                    patient_id=patient_id,
                    device_id=uuid.UUID(phone["device_id"]),
                    started_at=NOW,
                    ended_at=NOW,
                    storage_key=key,
                    status="uploaded",
                    created_at=NOW - timedelta(days=age_days),
                )
            )
            db.commit()
        segments.append((segment_id, key))

    with worker_session() as db:
        assert retention_service.expire_media(db)["audio"] == 1
        old, recent = (db.get(AudioSegment, s) for s, _ in segments)
        assert old.status == "deleted" and old.storage_key is None
        assert recent.status == "uploaded"
    assert segments[0][1] not in fake_s3.objects and segments[1][1] in fake_s3.objects


# ----- media.make_thumbnail -----


def _upload(client, fake_s3, base, patient_id, phone, data, content_type, trigger):
    event = {
        "id": str(uuid.uuid4()),
        "event_type": "user_requested_recording",
        "occurred_at": NOW.isoformat(),
    }
    client.post(
        f"{base}/events:batch", json={"events": [event]}, headers=phone["headers"]
    )
    media_id = str(uuid.uuid4())
    ticket = client.post(
        f"{base}/uploads",
        json={"id": media_id, "kind": "media", "content_type": content_type},
        headers=phone["headers"],
    ).json()
    fake_s3.put_bytes(ticket["key"], data, content_type)
    done = client.post(
        f"{API}/uploads/{media_id}/complete",
        json={
            "patient_id": patient_id,
            "kind": "media",
            "content_type": content_type,
            "event_id": event["id"],
            "trigger": trigger,
        },
        headers=phone["headers"],
    )
    assert done.status_code == 200, done.text
    return media_id, ticket["key"]


def _video() -> bytes:
    handle, path = tempfile.mkstemp(suffix=".mp4")
    os.close(handle)
    try:
        subprocess.run(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-v",
                "error",
                "-y",
                "-f",
                "lavfi",
                "-i",
                "testsrc=duration=2:size=640x360:rate=10",
                "-pix_fmt",
                "yuv420p",
                path,
            ],
            check=True,
            timeout=60,
        )
        with open(path, "rb") as f:
            return f.read()
    finally:
        os.remove(path)


def test_video_upload_gets_a_preview_frame(client, fake_s3, worker_session):
    _, _, patient, phone, base = _family(client)
    media_id, key = _upload(
        client,
        fake_s3,
        base,
        patient["id"],
        phone,
        _video(),
        "video/mp4",
        "user_requested",
    )
    thumb_key = key.replace(".mp4", ".thumb.jpg")
    with Image.open(io.BytesIO(fake_s3.objects[thumb_key])) as thumb:
        assert thumb.format == "JPEG" and max(thumb.size) == 320
    with worker_session() as db:
        assert db.get(MediaAsset, uuid.UUID(media_id)).thumbnail_key == thumb_key


def test_make_thumbnail_twice_is_one_result(client, fake_s3, worker_session):
    _, _, patient, phone, base = _family(client)
    media_id, _ = _upload(
        client,
        fake_s3,
        base,
        patient["id"],
        phone,
        image_bytes(),
        "image/jpeg",
        "salient_frame",
    )
    before = dict(fake_s3.objects)
    assert media_tasks.make_thumbnail.delay(media_id).get() is not None
    assert fake_s3.objects == before  # already had one: nothing rewritten


def test_storage_failure_is_retried_but_bad_data_is_not(
    client, fake_s3, worker_session, monkeypatch
):
    _, _, patient, phone, base = _family(client)
    media_id, _ = _upload(
        client,
        fake_s3,
        base,
        patient["id"],
        phone,
        image_bytes(),
        "image/jpeg",
        "salient_frame",
    )
    with worker_session() as db:
        db.execute(
            update(MediaAsset)
            .where(MediaAsset.id == uuid.UUID(media_id))
            .values(thumbnail_key=None)
        )
        db.commit()

    from app.integrations import s3

    def s3_down(key, max_bytes):
        raise StorageUnavailable("down")

    monkeypatch.setattr(s3, "get_bytes", s3_down)
    with pytest.raises(Retry):  # temporary: Celery schedules a retry
        media_tasks.make_thumbnail.delay(media_id)

    def corrupt(key, max_bytes):
        raise ValueError("bad data")

    monkeypatch.setattr(s3, "get_bytes", corrupt)
    with pytest.raises(ValueError):  # a bug or bad data: fails at once, never retried
        media_tasks.make_thumbnail.delay(media_id)


def test_upload_still_succeeds_when_redis_is_down(
    client, fake_s3, worker_session, monkeypatch
):
    from kombu.exceptions import OperationalError

    def broker_down(*args, **kwargs):
        raise OperationalError("redis down")

    _, _, patient, phone, base = _family(client)
    with monkeypatch.context() as patch:  # Redis down only for the upload
        patch.setattr(media_tasks.make_thumbnail, "delay", broker_down)
        media_id, _ = _upload(
            client,
            fake_s3,
            base,
            patient["id"],
            phone,
            image_bytes(),
            "image/jpeg",
            "salient_frame",
        )
    # broker back; the sweep finds the item once it's 2 minutes old

    with worker_session() as db:
        db.execute(
            update(MediaAsset)
            .where(MediaAsset.id == uuid.UUID(media_id))
            .values(created_at=NOW - timedelta(minutes=10))
        )
        db.commit()
    assert media_tasks.backfill_thumbnails.delay().get() >= 1
    with worker_session() as db:
        assert db.get(MediaAsset, uuid.UUID(media_id)).thumbnail_key is not None
