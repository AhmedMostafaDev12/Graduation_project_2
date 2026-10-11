from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App settings, read from environment variables or the .env file."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = "local"
    database_url: str = "postgresql+psycopg://remori:remori@localhost:5434/remori"


settings = Settings()
