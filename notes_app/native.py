"""NativeDataSource: MariaDB Connector/Python straight to the notes_app tables.

Bound to the columns in working/notes_app.sql. Every statement is parameterized
with qmark (?) placeholders, and the connection runs with autocommit on, so each
single-statement write is committed as it runs.
"""

from __future__ import annotations

from typing import Any, Callable, TypeVar

import mariadb

from .config import Config
from .datasource import DataSource, DataSourceError
from .models import Account, Note, Notebook, NoteSummary, Status

T = TypeVar("T")

# Pinned first, newest next; ix_note_notebook_updated matches this order.
_LIST_ORDER = "ORDER BY n.is_pinned DESC, n.updated_at DESC, n.id DESC"

_SUMMARY_COLS = "n.id, n.notebook_id, n.title, n.status, n.is_pinned, n.updated_at"


class NativeDataSource(DataSource):
    mode = "native"

    def __init__(self, config: Config) -> None:
        self._config = config
        self._conn: mariadb.Connection | None = None

    # -- connection handling -------------------------------------------------

    @property
    def address(self) -> str:
        return self._config.address

    def _connect(self) -> mariadb.Connection:
        c = self._config
        return mariadb.connect(
            host=c.host,
            port=c.port,
            user=c.user,
            password=c.password,
            database=c.database,
            autocommit=True,
            connect_timeout=5,
            read_timeout=10,
            write_timeout=10,
        )

    def _run(self, fn: Callable[[mariadb.Cursor], T]) -> T:
        """Run fn with a dictionary cursor, reconnecting once on a lost link."""
        for attempt in (1, 2):
            try:
                if self._conn is None:
                    self._conn = self._connect()
                cur = self._conn.cursor(dictionary=True)
                try:
                    return fn(cur)
                finally:
                    cur.close()
            except (mariadb.InterfaceError, mariadb.OperationalError) as exc:
                self._drop()
                if attempt == 2:
                    raise DataSourceError(f"{self.address}: {exc}") from exc
            except mariadb.Error as exc:
                raise DataSourceError(str(exc)) from exc
        raise AssertionError("unreachable")

    def _drop(self) -> None:
        if self._conn is not None:
            try:
                self._conn.close()
            except mariadb.Error:
                pass
        self._conn = None

    def close(self) -> None:
        self._drop()

    def _all(self, sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
        def fn(cur: mariadb.Cursor) -> list[dict[str, Any]]:
            cur.execute(sql, params)
            return list(cur.fetchall())

        return self._run(fn)

    def _one(self, sql: str, params: tuple[Any, ...] = ()) -> dict[str, Any] | None:
        rows = self._all(sql, params)
        return rows[0] if rows else None

    def _exec(self, sql: str, params: tuple[Any, ...] = ()) -> int:
        def fn(cur: mariadb.Cursor) -> int:
            cur.execute(sql, params)
            return cur.rowcount

        return self._run(fn)

    # -- reads ---------------------------------------------------------------

    def current_account(self) -> Account:
        row = self._one(
            "SELECT id, email, display_name FROM notes_app.account WHERE email = ?",
            (self._config.account_email,),
        )
        if row is None:
            raise DataSourceError(
                f"account {self._config.account_email} not found; "
                "load research/synthetic_data.sql"
            )
        return Account(id=row["id"], email=row["email"], display_name=row["display_name"])

    def list_notebooks(self, account_id: str) -> list[Notebook]:
        rows = self._all(
            """
            SELECT nb.id, nb.name, nb.is_default,
                   COUNT(n.id) AS note_count
            FROM notes_app.notebook nb
            LEFT JOIN notes_app.note n
              ON n.notebook_id = nb.id AND n.status = 'active'
            WHERE nb.account_id = ?
            GROUP BY nb.id, nb.name, nb.is_default
            ORDER BY nb.is_default DESC, nb.name
            """,
            (account_id,),
        )
        return [
            Notebook(
                id=r["id"],
                name=r["name"],
                is_default=bool(r["is_default"]),
                note_count=int(r["note_count"]),
            )
            for r in rows
        ]

    def list_notes(self, notebook_id: str, status: Status) -> list[NoteSummary]:
        rows = self._all(
            f"""
            SELECT {_SUMMARY_COLS}
            FROM notes_app.note n
            WHERE n.notebook_id = ? AND n.status = ?
            {_LIST_ORDER}
            """,
            (notebook_id, status),
        )
        return [_summary(r) for r in rows]

    def search_notes(
        self, account_id: str, query: str, status: Status
    ) -> list[NoteSummary]:
        rows = self._all(
            f"""
            SELECT {_SUMMARY_COLS}
            FROM notes_app.note n
            WHERE n.account_id = ? AND n.status = ?
              AND MATCH(n.title, n.body) AGAINST (? IN NATURAL LANGUAGE MODE)
            {_LIST_ORDER}
            """,
            (account_id, status, query),
        )
        return [_summary(r) for r in rows]

    def get_note(self, note_id: str) -> Note:
        row = self._one(
            """
            SELECT id, notebook_id, account_id, title, body, status, is_pinned,
                   created_at, updated_at
            FROM notes_app.note WHERE id = ?
            """,
            (note_id,),
        )
        if row is None:
            raise DataSourceError(f"note {note_id} not found")
        tags = self._all(
            """
            SELECT t.name FROM notes_app.note_tag nt
            JOIN notes_app.tag t ON t.id = nt.tag_id
            WHERE nt.note_id = ? ORDER BY t.name
            """,
            (note_id,),
        )
        return Note(
            id=row["id"],
            notebook_id=row["notebook_id"],
            account_id=row["account_id"],
            title=row["title"],
            body=row["body"],
            status=row["status"],
            is_pinned=bool(row["is_pinned"]),
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            tags=[t["name"] for t in tags],
        )

    # -- writes --------------------------------------------------------------

    def create_note(
        self, account_id: str, notebook_id: str, title: str, body: str
    ) -> Note:
        row = self._one(
            """
            INSERT INTO notes_app.note (notebook_id, account_id, title, body)
            VALUES (?, ?, ?, ?)
            RETURNING id
            """,
            (notebook_id, account_id, title, body),
        )
        assert row is not None
        return self.get_note(row["id"])

    def update_note(self, note_id: str, title: str, body: str) -> Note:
        # updated_at advances through ON UPDATE CURRENT_TIMESTAMP when a value changes.
        self._exec(
            "UPDATE notes_app.note SET title = ?, body = ? WHERE id = ?",
            (title, body, note_id),
        )
        return self.get_note(note_id)

    def set_pinned(self, note_id: str, pinned: bool) -> None:
        self._exec(
            "UPDATE notes_app.note SET is_pinned = ? WHERE id = ?",
            (1 if pinned else 0, note_id),
        )

    def set_status(self, note_id: str, status: Status) -> None:
        self._exec(
            "UPDATE notes_app.note SET status = ? WHERE id = ?", (status, note_id)
        )

    def empty_trash(self, notebook_id: str) -> int:
        return self._exec(
            "DELETE FROM notes_app.note WHERE notebook_id = ? AND status = 'trashed'",
            (notebook_id,),
        )


def _summary(r: dict[str, Any]) -> NoteSummary:
    return NoteSummary(
        id=r["id"],
        notebook_id=r["notebook_id"],
        title=r["title"],
        status=r["status"],
        is_pinned=bool(r["is_pinned"]),
        updated_at=r["updated_at"],
    )
