"""Configuration from the environment, with a .env file as a fallback.

Variables already set in the environment win over .env, which is the usual
loader behaviour. The .env file is looked up from the current directory upward,
so running from the repository root (bin/notes-app, or the notes-app console
script) finds the one written at the root.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

from dotenv import find_dotenv, load_dotenv


@dataclass(frozen=True)
class Config:
    host: str
    port: int
    user: str
    password: str
    database: str
    account_email: str

    @property
    def address(self) -> str:
        """The sandbox address shown on the status line (no password)."""
        return f"{self.user}@{self.host}:{self.port}/{self.database}"


def load_config() -> Config:
    load_dotenv(find_dotenv(usecwd=True), override=False)
    return Config(
        host=os.environ.get("NOTES_APP_DB_HOST", "127.0.0.1"),
        port=int(os.environ.get("NOTES_APP_DB_PORT", "3310")),
        user=os.environ.get("NOTES_APP_DB_USER", "root"),
        password=os.environ.get("NOTES_APP_DB_PASSWORD", ""),
        database=os.environ.get("NOTES_APP_DB_NAME", "notes_app"),
        account_email=os.environ.get(
            "NOTES_APP_ACCOUNT_EMAIL", "michael.aglietti@mariadb.com"
        ),
    )
