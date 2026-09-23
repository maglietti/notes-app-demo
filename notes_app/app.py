"""The three-pane Textual UI from PRD section 7."""

from textual import on, work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import ModalScreen, Screen
from textual.widgets import Footer, Input, Label, ListItem, ListView, Markdown, Static, TextArea

from notes_app.config import Config
from notes_app.datasource import DataSource, DataSourceError, Note, Notebook, NoteSummary
from notes_app.native import NativeDataSource
from notes_app.rest import RestDataSource

VIEW_LABELS = {"active": "Active", "archived": "Archive", "trashed": "Trash"}
VIEW_ORDER = ("active", "archived", "trashed")

HELP_TEXT = """\
# Keys

| Key | Action |
| --- | --- |
| `enter` | Select notebook |
| `v` | Cycle view: active, archive, trash |
| `n` | New note in this notebook |
| `e` | Edit the selected note |
| `p` | Pin or unpin |
| `a` | Archive, or un-archive in the archive view |
| `d` | Move to trash |
| `u` | Restore to active |
| `x` | Empty this notebook's trash (trash view) |
| `tab` | Cycle panes |
| `q` | Quit |

Press `escape` to close.
"""


class HelpScreen(ModalScreen[None]):
    BINDINGS = [Binding("escape,question_mark,q", "dismiss", "Close")]

    def compose(self) -> ComposeResult:
        with VerticalScroll(id="help"):
            yield Markdown(HELP_TEXT)


class EditScreen(Screen[tuple[str, str] | None]):
    """Full-screen Markdown editor. Dismisses with (title, body), or None on cancel."""

    BINDINGS = [
        Binding("ctrl+s", "save", "Save"),
        Binding("escape", "cancel", "Cancel"),
    ]

    def __init__(self, heading: str, title: str = "", body: str = "") -> None:
        super().__init__()
        self._heading = heading
        self._title = title
        self._body = body

    def compose(self) -> ComposeResult:
        yield Label(self._heading, id="edit-heading")
        yield Input(value=self._title, placeholder="Title", id="edit-title")
        yield TextArea(self._body, language="markdown", id="edit-body")
        yield Footer()

    def action_save(self) -> None:
        title = self.query_one("#edit-title", Input).value.strip()
        body = self.query_one("#edit-body", TextArea).text
        self.dismiss((title, body))

    def action_cancel(self) -> None:
        self.dismiss(None)


class NotesApp(App[None]):
    TITLE = "Notes App"
    CSS = """
    #panes { height: 1fr; }
    #notebooks-pane { width: 26; border: round $primary; }
    #notes-pane { width: 1fr; border: round $primary; }
    #note-pane { width: 2fr; border: round $primary; }
    #notebooks-pane:focus-within, #notes-pane:focus-within { border: round $accent; }
    #status { height: 1; padding: 0 1; background: $boost; }
    #status.error { background: $error 40%; }
    #edit-heading { padding: 0 1; text-style: bold; }
    #edit-body { height: 1fr; }
    HelpScreen { align: center middle; }
    #help { width: 60; height: auto; max-height: 90%; border: round $accent; background: $surface; }
    """

    BINDINGS = [
        Binding("n", "new_note", "New"),
        Binding("e", "edit_note", "Edit"),
        Binding("p", "toggle_pin", "Pin"),
        Binding("a", "archive", "Archive"),
        Binding("d", "trash", "Trash"),
        Binding("u", "restore", "Restore"),
        Binding("v", "cycle_view", "View"),
        Binding("x", "empty_trash", "Empty trash", show=False),
        Binding("question_mark", "help", "Help"),
        Binding("q", "quit", "Quit"),
    ]

    def __init__(self, config: Config) -> None:
        super().__init__()
        # NOTES_APP_MODE picks the backend; anything but rest means native.
        self.source: DataSource = RestDataSource(config) if config.mode == "rest" else NativeDataSource(config)
        self.notebooks: list[Notebook] = []
        self.notes: list[NoteSummary] = []
        self.current_notebook: Notebook | None = None
        self.current_note: Note | None = None
        self.view = "active"

    def compose(self) -> ComposeResult:
        with Horizontal(id="panes"):
            with Vertical(id="notebooks-pane") as pane:
                pane.border_title = "Notebooks"
                yield ListView(id="notebooks")
            with Vertical(id="notes-pane") as pane:
                pane.border_title = "Notes"
                yield ListView(id="notes")
            with VerticalScroll(id="note-pane") as pane:
                pane.border_title = "Note"
                yield Markdown("", id="note")
        yield Static("", id="status")
        yield Footer()

    # -- status line -------------------------------------------------------

    def set_status(self, message: str = "", error: bool = False) -> None:
        parts = [self.source.mode, self.source.address]
        if self.current_notebook is not None:
            parts.append(f"{self.current_notebook.name} / {VIEW_LABELS[self.view]}")
            parts.append(f"{len(self.notes)} notes")
        if message:
            parts.append(message)
        status = self.query_one("#status", Static)
        status.update(" · ".join(parts))
        status.set_class(error, "error")

    def show_error(self, exc: Exception) -> None:
        # Keep the last good view on screen; only the status line changes (PRD section 8).
        self.set_status(f"error: {exc}", error=True)

    # -- loading -----------------------------------------------------------

    async def on_mount(self) -> None:
        self.set_status("connecting...")
        self.load_initial()

    @work(exclusive=True, group="load")
    async def load_initial(self) -> None:
        try:
            await self.source.connect()
            await self.refresh_notebooks()
        except DataSourceError as exc:
            self.show_error(exc)
            return
        if self.notebooks:
            await self.select_notebook(self.notebooks[0])
        else:
            self.set_status("no notebooks: load research/synthetic_data.sql to seed the sample data")
        self.query_one("#notes", ListView).focus()

    async def refresh_notebooks(self) -> None:
        self.notebooks = await self.source.list_notebooks()
        view = self.query_one("#notebooks", ListView)
        index = view.index
        await view.clear()
        for nb in self.notebooks:
            marker = "▸" if nb.is_default else " "
            await view.append(ListItem(Label(f"{marker} {nb.name} ({nb.note_count})")))
        if self.current_notebook is not None:
            ids = [nb.id for nb in self.notebooks]
            index = ids.index(self.current_notebook.id) if self.current_notebook.id in ids else 0
        view.index = index or 0

    async def select_notebook(self, notebook: Notebook) -> None:
        self.current_notebook = notebook
        await self.refresh_notes()

    async def refresh_notes(self, keep_id: str | None = None) -> None:
        if self.current_notebook is None:
            return
        self.notes = await self.source.list_notes(self.current_notebook.id, self.view)
        view = self.query_one("#notes", ListView)
        await view.clear()
        for n in self.notes:
            star = "★" if n.is_pinned else " "
            title = n.title or "(untitled)"
            await view.append(ListItem(Label(f"{star} {title}")))
        ids = [n.id for n in self.notes]
        if self.notes:
            view.index = ids.index(keep_id) if keep_id in ids else 0
            await self.show_note(self.notes[view.index].id)
        else:
            self.current_note = None
            empty = {
                "active": "No active notes here. Press `n` to create one.",
                "archived": "Nothing archived in this notebook.",
                "trashed": "Trash is empty.",
            }[self.view]
            await self.query_one("#note", Markdown).update(f"*{empty}*")
        self.set_status()

    async def show_note(self, note_id: str) -> None:
        self.current_note = await self.source.get_note(note_id)
        n = self.current_note
        tags = " ".join(f"`{t}`" for t in n.tags) or "no tags"
        meta = f"*{n.status} · updated {n.updated_at:%Y-%m-%d %H:%M:%S} · {tags}*"
        await self.query_one("#note", Markdown).update(f"# {n.title or '(untitled)'}\n\n{meta}\n\n{n.body}")

    # -- events ------------------------------------------------------------

    @on(ListView.Selected, "#notebooks")
    async def notebook_selected(self, event: ListView.Selected) -> None:
        index = event.list_view.index
        if index is None or index >= len(self.notebooks):
            return
        try:
            await self.select_notebook(self.notebooks[index])
        except DataSourceError as exc:
            self.show_error(exc)

    @on(ListView.Highlighted, "#notes")
    async def note_highlighted(self, event: ListView.Highlighted) -> None:
        index = event.list_view.index
        if index is None or index >= len(self.notes):
            return
        if self.current_note is not None and self.current_note.id == self.notes[index].id:
            return
        try:
            await self.show_note(self.notes[index].id)
        except DataSourceError as exc:
            self.show_error(exc)

    # -- actions -----------------------------------------------------------

    async def _after_change(self, message: str, keep_id: str | None = None) -> None:
        await self.refresh_notebooks()
        await self.refresh_notes(keep_id)
        self.set_status(message)

    def action_help(self) -> None:
        self.push_screen(HelpScreen())

    async def action_cycle_view(self) -> None:
        self.view = VIEW_ORDER[(VIEW_ORDER.index(self.view) + 1) % len(VIEW_ORDER)]
        try:
            await self.refresh_notes()
        except DataSourceError as exc:
            self.show_error(exc)

    def action_new_note(self) -> None:
        if self.current_notebook is None:
            return
        notebook = self.current_notebook

        async def done(result: tuple[str, str] | None) -> None:
            if result is None:
                return
            try:
                note = await self.source.create_note(notebook.id, *result)
                self.view = "active"
                await self._after_change("created", note.id)
            except DataSourceError as exc:
                self.show_error(exc)

        self.push_screen(EditScreen(f"New note in {notebook.name}"), done)

    def action_edit_note(self) -> None:
        note = self.current_note
        if note is None:
            return

        async def done(result: tuple[str, str] | None) -> None:
            if result is None:
                return
            try:
                saved = await self.source.update_note(note.id, *result)
                await self._after_change(f"saved, updated_at {saved.updated_at:%H:%M:%S}", saved.id)
            except DataSourceError as exc:
                self.show_error(exc)

        self.push_screen(EditScreen("Edit note (ctrl+s to save)", note.title, note.body), done)

    async def action_toggle_pin(self) -> None:
        note = self.current_note
        if note is None:
            return
        try:
            await self.source.set_pinned(note.id, not note.is_pinned)
            await self._after_change("unpinned" if note.is_pinned else "pinned", note.id)
        except DataSourceError as exc:
            self.show_error(exc)

    async def _move(self, status: str, message: str) -> None:
        note = self.current_note
        if note is None or note.status == status:
            return
        try:
            await self.source.set_status(note.id, status)
            await self._after_change(message)
        except DataSourceError as exc:
            self.show_error(exc)

    async def action_archive(self) -> None:
        if self.current_note is not None and self.current_note.status == "archived":
            await self._move("active", "un-archived")
        else:
            await self._move("archived", "archived")

    async def action_trash(self) -> None:
        await self._move("trashed", "moved to trash")

    async def action_restore(self) -> None:
        await self._move("active", "restored")

    async def action_empty_trash(self) -> None:
        if self.view != "trashed" or self.current_notebook is None:
            self.set_status("switch to the trash view (v) to empty it")
            return
        try:
            count = await self.source.empty_trash(self.current_notebook.id)
            await self._after_change(f"emptied trash, {count} deleted")
        except DataSourceError as exc:
            self.show_error(exc)

    async def on_unmount(self) -> None:
        await self.source.close()
