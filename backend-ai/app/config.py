from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

LOCAL_JWT_SECRET = "local-development-only-secret"


class Settings(BaseSettings):
    """App settings, read from environment variables or the .env file."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = "local"
    database_url: str = "postgresql+psycopg://remori:remori@localhost:5434/remori"

    # Connections per API worker: 2 workers x (3 + 2) = at most 10 to Supabase's pooler
    db_pool_size: int = 3
    db_max_overflow: int = 2

    # Auth (course: SECRET_KEY / ALGORITHM / ACCESS_TOKEN_EXPIRE_MINUTES)
    jwt_secret: str = LOCAL_JWT_SECRET
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # Media and audio files (private bucket; the EC2 server uses its IAM role, no keys)
    aws_region: str = "eu-central-1"
    s3_bucket: str = "remori-media-090413359449"

    # Celery broker (docs/CELERY_REDIS.md). Compose sets redis://redis:6379/0.
    redis_url: str = "redis://localhost:6379/0"

    @model_validator(mode="after")
    def _real_secret_outside_local(self):
        if self.environment != "local" and self.jwt_secret == LOCAL_JWT_SECRET:
            raise ValueError(
                "JWT_SECRET must be set to a random value outside local development"
            )
        return self


settings = Settings()
