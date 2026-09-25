"""DTOs the UI works with. They carry no database types beyond str/int/datetime."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Literal

Status = Literal["active", "archived", "trashed"]
STATUSES: tuple[Status, ...] = ("active", "archived", "trashed")


@dataclass(frozen=True)
class Account:
    id: str
    email: str
    display_name: str


@dataclass(frozen=True)
class Notebook:
    id: str
    name: str
    is_default: bool
    note_count: int  # active notes in the notebook


@dataclass(frozen=True)
class NoteSummary:
    id: str
    notebook_id: str
    title: str
    status: Status
    is_pinned: bool
    updated_at: datetime


@dataclass(frozen=True)
class Note:
    id: str
    notebook_id: str
    account_id: str
    title: str
    body: str
    status: Status
    is_pinned: bool
    created_at: datetime
    updated_at: datetime
    tags: list[str] = field(default_factory=list)
