"""The DataSource interface (PRD section 9).

The UI only ever holds a DataSource, so it never knows which backend serves it.
NativeDataSource (native.py) is the one implementation in this build.
"""

from __future__ import annotations

from abc import ABC, abstractmethod

from .models import Account, Note, Notebook, NoteSummary, Status


class DataSourceError(Exception):
    """Any backend failure, reduced to a message the status line can show."""


class DataSource(ABC):
    #: Short mode name for the status line, e.g. "native".
    mode: str

    @property
    @abstractmethod
    def address(self) -> str:
        """Where the data comes from, for the status line."""

    @abstractmethod
    def current_account(self) -> Account: ...

    @abstractmethod
    def list_notebooks(self, account_id: str) -> list[Notebook]: ...

    @abstractmethod
    def list_notes(self, notebook_id: str, status: Status) -> list[NoteSummary]:
        """Notes in one notebook and status view, pinned first, newest next."""

    @abstractmethod
    def search_notes(
        self, account_id: str, query: str, status: Status
    ) -> list[NoteSummary]:
        """Full-text search over title and body across the account."""

    @abstractmethod
    def get_note(self, note_id: str) -> Note: ...

    @abstractmethod
    def create_note(
        self, account_id: str, notebook_id: str, title: str, body: str
    ) -> Note: ...

    @abstractmethod
    def update_note(self, note_id: str, title: str, body: str) -> Note: ...

    @abstractmethod
    def set_pinned(self, note_id: str, pinned: bool) -> None: ...

    @abstractmethod
    def set_status(self, note_id: str, status: Status) -> None: ...

    @abstractmethod
    def empty_trash(self, notebook_id: str) -> int:
        """Hard-delete the trashed notes in a notebook; the app's only DELETE."""

    @abstractmethod
    def close(self) -> None: ...
