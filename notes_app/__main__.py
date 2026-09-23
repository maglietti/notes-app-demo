from notes_app.app import NotesApp
from notes_app.config import Config


def main() -> None:
    NotesApp(Config.load()).run()


if __name__ == "__main__":
    main()
