"""The Textual app: three panes, a status line, and a footer (PRD section 7)."""

from __future__ import annotations

from typing import Callable, TypeVar

from rich.markup import escape
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, VerticalScroll
from textual.screen import Screen
from textual.widgets import Footer, Label, ListItem, ListView, Markdown, Static

from .datasource import DataSource, DataSourceError
from .models import Account, Note, Notebook, NoteSummary, Status
from .screens import ConfirmScreen, EditResult, EditScreen, HelpScreen, SearchScreen

T = TypeVar("T")

VIEW_LABELS: dict[Status, str] = {
    "active": "Active",
    "archived": "Archive",
    "trashed": "Trash",
}

SEED_HINT = (
    "The demo sandbox is seeded from `research/synthetic_data.sql`: "
    "61 notes in 6 notebooks for michael.aglietti@mariadb.com. "
    "If every list is empty, load that fixture into `notes_app`."
)


class NotebookItem(ListItem):
    def __init__(self, notebook: Notebook) -> None:
        marker = "▸" if notebook.is_default else " "
        label = f"{marker} {escape(notebook.name)} [dim]({notebook.note_count})[/dim]"
        super().__init__(Label(label))
        self.notebook = notebook


class NoteItem(ListItem):
    def __init__(self, note: NoteSummary) -> None:
        star = "[yellow]★[/yellow]" if note.is_pinned else " "
        title = escape(note.title) or "[dim](untitled)[/dim]"
        stamp = note.updated_at.strftime("%Y-%m-%d %H:%M")
        super().__init__(Label(f"{star} {title}\n  [dim]{stamp}[/dim]"))
        self.note = note


class MainScreen(Screen[None]):
    BINDINGS = [
        Binding("n", "new_note", "New"),
        Binding("e", "edit_note", "Edit"),
        Binding("p", "toggle_pin", "Pin"),
        Binding("a", "archive", "Archive"),
        Binding("d", "trash", "Trash"),
        Binding("u", "restore", "Restore"),
        Binding("slash", "search", "Search"),
        Binding("1", "view('active')", "Active", show=False),
        Binding("2", "view('archived')", "Archive view", show=False),
        Binding("3", "view('trashed')", "Trash view", show=False),
        Binding("x", "empty_trash", "Empty trash", show=False),
        Binding("r", "reload", "Reload", show=False),
        Binding("question_mark", "help", "Help"),
        Binding("q", "app.quit", "Quit"),
    ]

    def __init__(self, ds: DataSource) -> None:
        super().__init__()
        self.ds = ds
        self.account: Account | None = None
        self.notebooks: list[Notebook] = []
        self.notebook: Notebook | None = None
        self.view: Status = "active"
        self.search: str = ""
        self.notes: list[NoteSummary] = []
        self.note: Note | None = None
        self.message: str = ""
        self.message_is_error: bool = False

    # -- layout --------------------------------------------------------------

    def compose(self) -> ComposeResult:
        with Horizontal(id="panes"):
            yield ListView(id="notebooks")
            yield ListView(id="notes")
            with VerticalScroll(id="note-pane"):
                yield Markdown("", id="note-view")
        yield Static("", id="status")
        yield Footer()

    async def on_mount(self) -> None:
        self.query_one("#notebooks").border_title = "Notebooks"
        self.query_one("#note-pane").border_title = "Note"
        self._set_notes_title()
        await self.reload(select_default=True)
        self.query_one("#notes", ListView).focus()

    # -- data plumbing -------------------------------------------------------

    def _call(self, fn: Callable[..., T], *args: object) -> T | None:
        """Call the data source; on failure show the error and keep the last view."""
        try:
            return fn(*args)
        except DataSourceError as exc:
            self._say(f"error: {exc}", error=True)
            return None

    def _say(self, message: str, error: bool = False) -> None:
        self.message = message
        self.message_is_error = error
        self._render_status()

    async def reload(
        self, select_default: bool = False, keep_note_id: str | None = None
    ) -> None:
        if self.account is None:
            self.account = self._call(self.ds.current_account)
            if self.account is None:
                await self._show_markdown(f"# Not connected\n\n{SEED_HINT}")
                return
        notebooks = self._call(self.ds.list_notebooks, self.account.id)
        if notebooks is None:
            return
        self.notebooks = notebooks
        if select_default or self.notebook is None:
            self.notebook = next(
                (nb for nb in notebooks if nb.is_default), notebooks[0] if notebooks else None
            )
        else:
            self.notebook = next(
                (nb for nb in notebooks if nb.id == self.notebook.id),
                notebooks[0] if notebooks else None,
            )
        await self._fill_notebooks()
        await self.reload_notes(keep_note_id=keep_note_id)

    async def _fill_notebooks(self) -> None:
        lv = self.query_one("#notebooks", ListView)
        await lv.clear()
        await lv.extend(NotebookItem(nb) for nb in self.notebooks)
        if self.notebook is not None:
            lv.index = next(
                i for i, nb in enumerate(self.notebooks) if nb.id == self.notebook.id
            )

    async def reload_notes(self, keep_note_id: str | None = None) -> None:
        if self.account is None:
            return
        if self.search:
            notes = self._call(self.ds.search_notes, self.account.id, self.search, self.view)
        elif self.notebook is not None:
            notes = self._call(self.ds.list_notes, self.notebook.id, self.view)
        else:
            notes = []
        if notes is None:
            return
        self.notes = notes
        self._set_notes_title()
        lv = self.query_one("#notes", ListView)
        await lv.clear()
        await lv.extend(NoteItem(n) for n in notes)
        if notes:
            ids = [n.id for n in notes]
            lv.index = ids.index(keep_note_id) if keep_note_id in ids else 0
            await self.open_note(notes[lv.index or 0].id)
        else:
            self.note = None
            await self._show_markdown(self._empty_state())
        self._render_status()

    async def open_note(self, note_id: str) -> None:
        note = self._call(self.ds.get_note, note_id)
        if note is None:
            return
        self.note = note
        await self._show_markdown(_render_note(note))
        self._render_status()

    async def _show_markdown(self, text: str) -> None:
        await self.query_one("#note-view", Markdown).update(text)
        self.query_one("#note-pane", VerticalScroll).scroll_home(animate=False)

    def _empty_state(self) -> str:
        if not self.notebooks:
            return f"# No notebooks yet\n\n{SEED_HINT}"
        where = f"matching “{self.search}”" if self.search else f"in {self.notebook.name if self.notebook else '?'}"
        extra = {
            "active": "Press `n` to write one.",
            "archived": "Archive a note with `a` from the Active view.",
            "trashed": "The trash is empty.",
        }[self.view]
        return f"# No {VIEW_LABELS[self.view].lower()} notes {where}\n\n{extra}\n\n{SEED_HINT}"

    def _set_notes_title(self) -> None:
        title = f"Notes · {VIEW_LABELS[self.view]}"
        if self.search:
            title += f" · search: {self.search}"
        self.query_one("#notes").border_title = title

    def _render_status(self) -> None:
        nb = self.notebook.name if self.notebook else "-"
        count = len(self.notes)
        parts = [
            f"[b]{self.ds.mode}[/b]",
            f"mariadb://{escape(self.ds.address)}",
            escape(nb),
            VIEW_LABELS[self.view],
            f"{count} note{'s' if count != 1 else ''}",
        ]
        if self.search:
            parts.append(f"/{escape(self.search)}")
        text = " · ".join(parts)
        if self.message:
            colour = "red" if self.message_is_error else "green"
            text += f"  [{colour}]{escape(self.message)}[/{colour}]"
        self.query_one("#status", Static).update(text)

    # -- list events ---------------------------------------------------------

    async def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.list_view.id == "notebooks" and isinstance(event.item, NotebookItem):
            self.notebook = event.item.notebook
            self.search = ""
            self._say("")
            await self.reload_notes()
            self.query_one("#notes", ListView).focus()
        elif event.list_view.id == "notes":
            self.query_one("#note-pane").focus()

    async def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        if event.list_view.id == "notes" and isinstance(event.item, NoteItem):
            if self.note is None or self.note.id != event.item.note.id:
                await self.open_note(event.item.note.id)

    # -- actions -------------------------------------------------------------

    def _need_note(self) -> Note | None:
        if self.note is None:
            self._say("no note selected", error=True)
        return self.note

    async def _after_write(self, message: str, keep_note_id: str | None = None) -> None:
        # Keep the cursor near where it was when the written note left the list.
        if keep_note_id is None:
            lv = self.query_one("#notes", ListView)
            idx = lv.index or 0
            remaining = [n for n in self.notes if self.note is None or n.id != self.note.id]
            if remaining:
                keep_note_id = remaining[min(idx, len(remaining) - 1)].id
        await self.reload(keep_note_id=keep_note_id)
        self._say(message)

    async def action_view(self, view: Status) -> None:
        self.view = view
        self._say("")
        await self.reload_notes()

    async def action_reload(self) -> None:
        await self.reload(keep_note_id=self.note.id if self.note else None)
        self._say("reloaded")

    def action_new_note(self) -> None:
        if self.account is None or self.notebook is None:
            self._say("no notebook selected", error=True)
            return
        notebook = self.notebook

        async def done(result: EditResult | None) -> None:
            if result is None:
                self._say("new note discarded")
                return
            assert self.account is not None
            note = self._call(
                self.ds.create_note, self.account.id, notebook.id, result.title, result.body
            )
            if note is None:
                return
            self.view = "active"
            self.search = ""
            self.notebook = notebook
            await self.reload(keep_note_id=note.id)
            self._say(f"created “{note.title or '(untitled)'}” in {notebook.name}")

        self.app.push_screen(EditScreen(f"New note in {notebook.name}"), done)

    def action_edit_note(self) -> None:
        note = self._need_note()
        if note is None:
            return

        async def done(result: EditResult | None) -> None:
            if result is None:
                self._say("edit cancelled")
                return
            if result.title == note.title and result.body == note.body:
                self._say("no changes")
                return
            saved = self._call(self.ds.update_note, note.id, result.title, result.body)
            if saved is None:
                return
            await self.reload(keep_note_id=saved.id)
            self._say(f"saved · updated_at {saved.updated_at:%Y-%m-%d %H:%M:%S}")

        self.app.push_screen(
            EditScreen(f"Edit note · updated {note.updated_at:%Y-%m-%d %H:%M:%S}", note.title, note.body),
            done,
        )

    async def action_toggle_pin(self) -> None:
        note = self._need_note()
        if note is None:
            return
        if self._call(self.ds.set_pinned, note.id, not note.is_pinned) is None and self.message_is_error:
            return
        await self._after_write("unpinned" if note.is_pinned else "pinned", keep_note_id=note.id)

    async def _move(self, note: Note, status: Status, message: str) -> None:
        self._call(self.ds.set_status, note.id, status)
        if self.message_is_error:
            return
        await self._after_write(message)

    async def action_archive(self) -> None:
        note = self._need_note()
        if note is None:
            return
        if note.status == "active":
            await self._move(note, "archived", f"archived “{note.title}”")
        elif note.status == "archived":
            await self._move(note, "active", f"un-archived “{note.title}”")
        else:
            self._say("restore the note from the trash first (u)", error=True)

    async def action_trash(self) -> None:
        note = self._need_note()
        if note is None:
            return
        if note.status == "trashed":
            self._say("already in the trash; x empties it", error=True)
            return
        await self._move(note, "trashed", f"moved “{note.title}” to the trash")

    async def action_restore(self) -> None:
        note = self._need_note()
        if note is None:
            return
        if note.status == "active":
            self._say("note is already active", error=True)
            return
        await self._move(note, "active", f"restored “{note.title}”")

    def action_empty_trash(self) -> None:
        if self.view != "trashed" or self.notebook is None:
            self._say("switch to the Trash view (3) to empty it", error=True)
            return
        notebook = self.notebook
        count = len(self.notes)
        if count == 0:
            self._say("the trash is already empty")
            return

        async def done(ok: bool | None) -> None:
            if not ok:
                self._say("kept the trash")
                return
            deleted = self._call(self.ds.empty_trash, notebook.id)
            if deleted is None:
                return
            await self.reload()
            self._say(f"deleted {deleted} note{'s' if deleted != 1 else ''} permanently")

        self.app.push_screen(
            ConfirmScreen(
                f"Permanently delete {count} trashed note{'s' if count != 1 else ''} in {notebook.name}?"
            ),
            done,
        )

    def action_search(self) -> None:
        async def done(query: str | None) -> None:
            if query is None:
                return
            self.search = query
            await self.reload_notes()
            self._say(f"{len(self.notes)} match(es)" if query else "search cleared")

        self.app.push_screen(SearchScreen(), done)

    def action_help(self) -> None:
        self.app.push_screen(HelpScreen())


def _render_note(note: Note) -> str:
    meta = [f"**{note.status}**"]
    if note.is_pinned:
        meta.append("★ pinned")
    meta.append(f"updated {note.updated_at:%Y-%m-%d %H:%M:%S}")
    meta.append(f"created {note.created_at:%Y-%m-%d %H:%M:%S}")
    tags = " ".join(f"`{t}`" for t in note.tags) or "_no tags_"
    title = note.title or "(untitled)"
    return f"# {title}\n\n{' · '.join(meta)}\n\n{tags}\n\n---\n\n{note.body}\n"


class NotesApp(App[None]):
    TITLE = "Notes App"
    CSS_PATH = "app.tcss"

    def __init__(self, ds: DataSource) -> None:
        super().__init__()
        self.ds = ds

    def on_mount(self) -> None:
        self.sub_title = f"{self.ds.mode} · {self.ds.address}"
        self.push_screen(MainScreen(self.ds))

    def on_unmount(self) -> None:
        self.ds.close()
