import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass(frozen=True)
class Config:
    host: str
    port: int
    user: str
    password: str
    database: str
    account_email: str
    mode: str
    rest_url: str

    @classmethod
    def load(cls) -> "Config":
        # Real environment variables win over .env, so a one-off override works.
        load_dotenv(Path.cwd() / ".env", override=False)
        return cls(
            host=os.getenv("NOTES_APP_DB_HOST", "127.0.0.1"),
            port=int(os.getenv("NOTES_APP_DB_PORT", "3310")),
            user=os.getenv("NOTES_APP_DB_USER", "root"),
            password=os.getenv("NOTES_APP_DB_PASSWORD", ""),
            database=os.getenv("NOTES_APP_DB_NAME", "notes_app"),
            account_email=os.getenv("NOTES_APP_ACCOUNT_EMAIL", "michael.aglietti@mariadb.com"),
            mode=os.getenv("NOTES_APP_MODE", "native").lower(),
            rest_url=os.getenv("NOTES_APP_REST_URL", "http://127.0.0.1:8443/notesApp"),
        )
