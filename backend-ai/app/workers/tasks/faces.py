"""Face model upkeep (queue `cpu`, phase 8.2, spec D14).

faces.reembed_stub: run once after the real face model is deployed, to replace the stub
embeddings of photos enrolled before it. Not scheduled: the people it can't re-embed (no
face, several faces) are reported for the caregiver to retake, not retried every hour.

    docker compose exec worker celery -A app.workers.celery_app call faces.reembed_stub
"""

import logging

from app.services import people_service
from app.workers import db
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="faces.reembed_stub", soft_time_limit=600, time_limit=660)
def reembed_stub() -> dict:
    with db.make_session() as session:
        result = people_service.reembed_stub_photos(session)
    # ids and counts only, never names or images (AI_LAYER.md rule 8)
    logger.info("stub face embeddings: %s", result)
    return result
