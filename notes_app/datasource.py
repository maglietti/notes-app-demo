"""The section 9 DataSource interface and the DTOs the UI works with."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime

STATUSES = ("active", "archived", "trashed")


class DataSourceError(Exception):
    """Any backend failure, surfaced on the status line rather than crashing the app."""


@dataclass
class Notebook:
    id: str
    name: str
    is_default: bool
    note_count: int


@dataclass
class NoteSummary:
    id: str
    title: str
    is_pinned: bool
    status: str
    updated_at: datetime


@dataclass
class Note:
    id: str
    notebook_id: str
    title: str
    body: str
    status: str
    is_pinned: bool
    created_at: datetime
    updated_at: datetime
    tags: list[str] = field(default_factory=list)


class DataSource(ABC):
    """One interface, two backends. The UI never knows which one it holds."""

    mode: str

    @property
    @abstractmethod
    def address(self) -> str: ...

    @abstractmethod
    async def connect(self) -> None: ...

    @abstractmethod
    async def close(self) -> None: ...

    @abstractmethod
    async def list_notebooks(self) -> list[Notebook]:
        """Notebooks with their active-note counts, default first."""

    @abstractmethod
    async def list_notes(self, notebook_id: str, status: str) -> list[NoteSummary]:
        """Notes in one notebook and status, pinned first, then newest."""

    @abstractmethod
    async def get_note(self, note_id: str) -> Note: ...

    @abstractmethod
    async def create_note(self, notebook_id: str, title: str, body: str) -> Note: ...

    @abstractmethod
    async def update_note(self, note_id: str, title: str, body: str) -> Note: ...

    @abstractmethod
    async def set_pinned(self, note_id: str, pinned: bool) -> None: ...

    @abstractmethod
    async def set_status(self, note_id: str, status: str) -> None: ...

    @abstractmethod
    async def empty_trash(self, notebook_id: str) -> int:
        """Hard-delete the trashed notes in one notebook. The app's only DELETE."""
