"""Entry point: `python -m notes_app` (bin/notes-app) and the notes-app script."""

from __future__ import annotations

from .app import NotesApp
from .config import load_config
from .native import NativeDataSource


def main() -> None:
    config = load_config()
    NotesApp(NativeDataSource(config)).run()


if __name__ == "__main__":
    main()
