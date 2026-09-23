"""NativeDataSource: MariaDB Connector/Python straight to the notes_app tables."""

import asyncio

import mariadb

from notes_app.config import Config
from notes_app.datasource import (
    DataSource,
    DataSourceError,
    Note,
    Notebook,
    NoteSummary,
)


class NativeDataSource(DataSource):
    mode = "native"

    def __init__(self, config: Config) -> None:
        self._config = config
        self._conn: mariadb.Connection | None = None
        self._account_id: str | None = None
        # Connector/Python is blocking and one connection is not thread-safe, so
        # every query runs in a worker thread, one at a time.
        self._lock = asyncio.Lock()

    @property
    def address(self) -> str:
        return f"{self._config.host}:{self._config.port}"

    async def _run(self, fn):
        async with self._lock:
            try:
                return await asyncio.to_thread(fn)
            except mariadb.Error as exc:
                raise DataSourceError(str(exc)) from exc

    def _cursor(self):
        if self._conn is None:
            raise DataSourceError("not connected")
        return self._conn.cursor(dictionary=True)

    async def connect(self) -> None:
        def work():
            c = self._config
            self._conn = mariadb.connect(
                host=c.host,
                port=c.port,
                user=c.user,
                password=c.password,
                database=c.database,
                connect_timeout=5,
                read_timeout=10,
                write_timeout=10,
                autocommit=True,
            )
            cur = self._cursor()
            cur.execute("SELECT id FROM account WHERE email = ?", (c.account_email,))
            row = cur.fetchone()
            if row is None:
                raise DataSourceError(f"account {c.account_email} not found; load the seed data")
            self._account_id = str(row["id"])

        await self._run(work)

    async def close(self) -> None:
        if self._conn is not None:
            conn, self._conn = self._conn, None
            await asyncio.to_thread(conn.close)

    async def list_notebooks(self) -> list[Notebook]:
        def work():
            cur = self._cursor()
            cur.execute(
                """
                SELECT nb.id, nb.name, nb.is_default,
                       COUNT(n.id) AS note_count
                FROM notebook nb
                LEFT JOIN note n ON n.notebook_id = nb.id AND n.status = 'active'
                WHERE nb.account_id = ?
                GROUP BY nb.id, nb.name, nb.is_default
                ORDER BY nb.is_default DESC, nb.name
                """,
                (self._account_id,),
            )
            return [
                Notebook(str(r["id"]), r["name"], bool(r["is_default"]), r["note_count"])
                for r in cur.fetchall()
            ]

        return await self._run(work)

    async def list_notes(self, notebook_id: str, status: str) -> list[NoteSummary]:
        def work():
            cur = self._cursor()
            # Matches ix_note_notebook_updated: pinned first, newest next.
            cur.execute(
                """
                SELECT id, title, is_pinned, status, updated_at
                FROM note
                WHERE notebook_id = ? AND status = ?
                ORDER BY is_pinned DESC, updated_at DESC
                """,
                (notebook_id, status),
            )
            return [
                NoteSummary(str(r["id"]), r["title"], bool(r["is_pinned"]), r["status"], r["updated_at"])
                for r in cur.fetchall()
            ]

        return await self._run(work)

    def _fetch_note(self, note_id: str) -> Note:
        cur = self._cursor()
        cur.execute(
            """
            SELECT id, notebook_id, title, body, status, is_pinned, created_at, updated_at
            FROM note WHERE id = ? AND account_id = ?
            """,
            (note_id, self._account_id),
        )
        r = cur.fetchone()
        if r is None:
            raise DataSourceError(f"note {note_id} not found")
        cur.execute(
            """
            SELECT t.name FROM note_tag nt JOIN tag t ON t.id = nt.tag_id
            WHERE nt.note_id = ? ORDER BY t.name
            """,
            (note_id,),
        )
        tags = [t["name"] for t in cur.fetchall()]
        return Note(
            str(r["id"]), str(r["notebook_id"]), r["title"], r["body"], r["status"],
            bool(r["is_pinned"]), r["created_at"], r["updated_at"], tags,
        )

    async def get_note(self, note_id: str) -> Note:
        return await self._run(lambda: self._fetch_note(note_id))

    async def create_note(self, notebook_id: str, title: str, body: str) -> Note:
        def work():
            cur = self._cursor()
            # RETURNING hands back the server-generated uuid_v7() key.
            cur.execute(
                """
                INSERT INTO note (notebook_id, account_id, title, body)
                VALUES (?, ?, ?, ?) RETURNING id
                """,
                (notebook_id, self._account_id, title, body),
            )
            new_id = str(cur.fetchone()["id"])
            return self._fetch_note(new_id)

        return await self._run(work)

    async def update_note(self, note_id: str, title: str, body: str) -> Note:
        def work():
            cur = self._cursor()
            cur.execute(
                "UPDATE note SET title = ?, body = ? WHERE id = ? AND account_id = ?",
                (title, body, note_id, self._account_id),
            )
            return self._fetch_note(note_id)

        return await self._run(work)

    async def set_pinned(self, note_id: str, pinned: bool) -> None:
        def work():
            self._cursor().execute(
                "UPDATE note SET is_pinned = ? WHERE id = ? AND account_id = ?",
                (pinned, note_id, self._account_id),
            )

        await self._run(work)

    async def set_status(self, note_id: str, status: str) -> None:
        def work():
            self._cursor().execute(
                "UPDATE note SET status = ? WHERE id = ? AND account_id = ?",
                (status, note_id, self._account_id),
            )

        await self._run(work)

    async def empty_trash(self, notebook_id: str) -> int:
        def work():
            cur = self._cursor()
            cur.execute(
                "DELETE FROM note WHERE notebook_id = ? AND account_id = ? AND status = 'trashed'",
                (notebook_id, self._account_id),
            )
            return cur.rowcount

        return await self._run(work)
