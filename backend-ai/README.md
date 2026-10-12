# backend-ai

The Remori API (FastAPI). Rules for contributors and AI agents: [AGENTS.md](AGENTS.md). Build order: [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md).

## Run locally (Docker)

```bash
cd backend-ai
docker compose -f docker-compose.dev.yml up --build
```

- API docs: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Postgres (pgAdmin): `localhost:5434`, user `remori`, password `remori`, database `remori`
- Redis: `localhost:6379` · Celery `worker` and `beat` run as their own containers

Saving a file in `app/` reloads the API automatically. The worker doesn't reload: after changing a task or a service it uses, run `docker compose -f docker-compose.dev.yml restart worker`.

Run a task by hand (e.g. the alert rules): `docker compose -f docker-compose.dev.yml exec worker python -c "from app.workers.tasks.alerts import evaluate; evaluate.delay()"`, then watch `docker compose -f docker-compose.dev.yml logs -f worker`.

Locally there are no AWS credentials, so anything that signs or touches S3 (photo lists, previews, retention) answers `503 STORAGE_UNAVAILABLE`. Production uses the EC2 IAM role.

## Run checks (same as CI)

```bash
cd backend-ai
python -m venv .venv
.venv\Scripts\activate            # Windows. macOS/Linux: source .venv/bin/activate
pip install -r requirements-dev.txt

ruff format .
ruff check .
pytest -q
```

Database tests run the migration and the seed against a real Postgres: start the Docker stack first. They create and use a separate `remori_test` database, so your local data is untouched. Without the database they're skipped.

## Database

```bash
alembic upgrade head          # create / update the schema
python -m scripts.seed        # sample data (docs/SEED_DATA.md)
```

## Production

**URL:** https://remori-ai.duckdns.org (API base `/api/v1`, docs at `/docs`). EC2 `remori-api` in eu-central-1, database on Supabase.

```
Phone ──HTTPS──> ufw ──> nginx (certbot certificate) ──> 127.0.0.1:8000 ──> gunicorn, 2 uvicorn workers (Docker)
                                                                                  └──> Supabase as remori_app
```

### Deploy a new version
```bash
# 1. Schema change? Run the migration FROM YOUR LAPTOP first (the server can't change the schema):
#    PowerShell:  $env:DATABASE_URL = "<SUPABASE_DATABASE_URL from .env>"; $env:ENVIRONMENT = "production"; alembic upgrade head
# 2. On the server:
ssh -i ~/.ssh/remori-ec2.pem ubuntu@remori-ai.duckdns.org
cd ~/remori && git pull
cd backend-ai && docker compose up -d --build
# 3. Check:
curl https://remori-ai.duckdns.org/health
```

### Useful commands on the server
| Task | Command (from `~/remori/backend-ai`) |
|---|---|
| App logs | `docker compose logs -f api` (worker: `logs -f worker`, schedule: `logs -f beat`) |
| Restart the app | `docker compose restart api` (or `worker`, `beat`) |
| What the worker is doing | `docker compose exec worker celery -A app.workers.celery_app inspect active` |
| Queued jobs per queue | `docker compose exec redis redis-cli llen default` (also `cpu`, `ai_io`) |
| Memory per container | `docker stats --no-stream` |
| nginx config | `/etc/nginx/sites-available/remori-api` (source: `deploy/nginx-remori-api.conf`) → `sudo nginx -t && sudo systemctl reload nginx` |
| nginx logs | `sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log` |
| Certificate | renews automatically (`certbot.timer`). Check: `sudo certbot renew --dry-run` |
| Firewall | `sudo ufw status` (only SSH + nginx) |
| Server settings | `~/remori/backend-ai/.env` (not in git, readable only by `ubuntu`) |

**Swap (once, before the first Phase 6 deploy):** the t3.small has 2 GB; a 1 GB swap file is a safety net against out-of-memory kills during image builds or bursts:
```bash
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab   # keep it after reboots
free -h                                                      # Swap: 1.0Gi
```
Measured locally: worker ~165 MB, beat ~90 MB, Redis ~4 MB, API (2 gunicorn workers) ~250 MB.

The server pulls code with a **read-only deploy key** (GitHub → Settings → Deploy keys). It can pull but never push.

## Configuration

Copy `.env.example` to `.env` for running outside Docker. Never commit `.env`. Production values (Supabase, secrets) live only on the server. See [docs/DATABASE.md](docs/DATABASE.md).
