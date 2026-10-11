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

Saving a file in `app/` reloads the API automatically.

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

## Configuration

Copy `.env.example` to `.env` for running outside Docker. Never commit `.env`. Production values (Supabase, secrets) live only on the server. See [docs/DATABASE.md](docs/DATABASE.md).
