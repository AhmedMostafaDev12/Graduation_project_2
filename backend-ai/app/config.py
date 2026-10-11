from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App settings, read from environment variables or the .env file."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = "local"
    database_url: str = "postgresql+psycopg://remori:remori@localhost:5434/remori"

    # Connections per API worker: 2 workers x (3 + 2) = at most 10 to Supabase's pooler
    db_pool_size: int = 3
    db_max_overflow: int = 2


settings = Settings()
