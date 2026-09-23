"""RestDataSource: httpx against the /notesApp REST Service (PRD section 5)."""

import json
from datetime import datetime

import httpx

from notes_app.config import Config
from notes_app.datasource import (
    DataSource,
    DataSourceError,
    Note,
    Notebook,
    NoteSummary,
)

# Fields the REST Service adds to a document that a PUT must not send back.
_READ_ONLY_FIELDS = {"links", "_metadata", "noteTag"}


def _dt(value) -> datetime:
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            pass
    return datetime.min


def _tags(doc: dict) -> list[str]:
    # @UNNEST flattens note_tag -> tag; depending on nesting depth the service
    # returns plain names or objects that carry a name field.
    raw = doc.get("noteTag") or doc.get("name") or []
    names = [t.get("name") if isinstance(t, dict) else t for t in raw]
    return sorted(n for n in names if n)


class RestDataSource(DataSource):
    mode = "rest"

    def __init__(self, config: Config) -> None:
        self._root = config.rest_url.rstrip("/")
        self._client = httpx.AsyncClient(base_url=self._root, timeout=5.0)
        self._account_id: str | None = None

    @property
    def address(self) -> str:
        return self._root

    async def _request(self, method: str, path: str, **kwargs) -> dict:
        try:
            response = await self._client.request(method, path, **kwargs)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise DataSourceError(f"{method} {self._root}{path}: {exc}") from exc
        return response.json() if response.content else {}

    async def _list(self, path: str, query: dict | None = None) -> list[dict]:
        """Read every page of a collection: items plus hasMore, never a bare array."""
        items: list[dict] = []
        offset = 0
        while True:
            params: dict = {"offset": offset, "limit": 100}
            if query:
                params["q"] = json.dumps(query)
            page = await self._request("GET", path, params=params)
            batch = page.get("items", [])
            items.extend(batch)
            if not page.get("hasMore") or not batch:
                return items
            offset += len(batch)

    async def connect(self) -> None:
        # The owning account id comes from the notebooks, since the service
        # exposes no /account endpoint and a create needs it (PRD section 5).
        notebooks = await self._list("/notes/notebook")
        if not notebooks:
            raise DataSourceError("no notebooks served; load the seed data")
        self._account_id = notebooks[0]["accountId"]

    async def close(self) -> None:
        await self._client.aclose()

    async def list_notebooks(self) -> list[Notebook]:
        notebooks = await self._list("/notes/notebook")
        active = await self._list("/notes/note", {"status": "active"})
        counts: dict[str, int] = {}
        for n in active:
            counts[n["notebookId"]] = counts.get(n["notebookId"], 0) + 1
        result = [
            Notebook(nb["id"], nb["name"], bool(nb["isDefault"]), counts.get(nb["id"], 0))
            for nb in notebooks
        ]
        return sorted(result, key=lambda nb: (not nb.is_default, nb.name))

    async def list_notes(self, notebook_id: str, status: str) -> list[NoteSummary]:
        docs = await self._list(
            "/notes/note",
            {"notebookId": notebook_id, "status": status,
             "$orderby": {"isPinned": "DESC", "updatedAt": "DESC"}},
        )
        return [
            NoteSummary(d["id"], d["title"], bool(d["isPinned"]), d["status"], _dt(d["updatedAt"]))
            for d in docs
        ]

    def _note(self, d: dict) -> Note:
        return Note(
            d["id"], d["notebookId"], d["title"], d["body"], d["status"],
            bool(d["isPinned"]), _dt(d["createdAt"]), _dt(d["updatedAt"]), _tags(d),
        )

    async def _get(self, note_id: str) -> dict:
        return await self._request("GET", f"/notes/note/{note_id}")

    async def get_note(self, note_id: str) -> Note:
        return self._note(await self._get(note_id))

    async def create_note(self, notebook_id: str, title: str, body: str) -> Note:
        doc = await self._request(
            "POST", "/notes/note",
            json={"notebookId": notebook_id, "accountId": self._account_id,
                  "title": title, "body": body},
        )
        return self._note(doc)

    async def _put(self, note_id: str, **changes) -> Note:
        # PUT replaces the document, so send the current one with the changes applied.
        doc = {k: v for k, v in (await self._get(note_id)).items() if k not in _READ_ONLY_FIELDS}
        doc.update(changes)
        return self._note(await self._request("PUT", f"/notes/note/{note_id}", json=doc))

    async def update_note(self, note_id: str, title: str, body: str) -> Note:
        return await self._put(note_id, title=title, body=body)

    async def set_pinned(self, note_id: str, pinned: bool) -> None:
        await self._put(note_id, isPinned=pinned)

    async def set_status(self, note_id: str, status: str) -> None:
        await self._put(note_id, status=status)

    async def empty_trash(self, notebook_id: str) -> int:
        trashed = await self._list("/notes/note", {"notebookId": notebook_id, "status": "trashed"})
        for d in trashed:
            await self._request("DELETE", f"/notes/note/{d['id']}")
        return len(trashed)
