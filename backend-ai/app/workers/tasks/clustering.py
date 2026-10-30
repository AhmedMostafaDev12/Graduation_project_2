"""Unknown-face clustering (queue `cpu`, phase 8.4, spec D23).

cluster.unknown_faces: every 10 minutes (Beat). Assigns the unknown encounters that arrived
through events:batch to clusters and asks the caregiver about a face seen on 3 different
days. One sweep at a time (lock), so two sweeps never update the same cluster.
The work is in services/clustering_service.py.
"""

from app.services import clustering_service
from app.workers import db, locks
from app.workers.celery_app import celery_app


@celery_app.task(name="cluster.unknown_faces", soft_time_limit=240, time_limit=270)
def unknown_faces() -> dict | None:
    with locks.task_lock("cluster.unknown_faces", ttl_seconds=300) as got:
        if not got:
            return None
        with db.make_session() as session:
            return clustering_service.sweep(session)
