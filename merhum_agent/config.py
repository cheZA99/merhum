import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

ENV_FILE = Path(__file__).parent / ".env"


@dataclass(frozen=True)
class Settings:
    groq_api_key: str
    groq_model: str
    merhum_api_url: str


def read_required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing environment variable {name}. Copy .env.example to .env and fill it in.")
    return value


def load_settings() -> Settings:
    # Real environment variables win over .env, so Docker or CI can override the file.
    load_dotenv(ENV_FILE, override=False)
    return Settings(
        groq_api_key=read_required("GROQ_API_KEY"),
        groq_model=read_required("GROQ_MODEL"),
        merhum_api_url=read_required("MERHUM_API_URL").rstrip("/"),
    )
