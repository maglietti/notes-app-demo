"""Modal and full-screen views: edit, search, confirm, help."""

from __future__ import annotations

from dataclasses import dataclass

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Vertical
from textual.screen import ModalScreen, Screen
from textual.widgets import Footer, Input, Label, Markdown, TextArea


@dataclass(frozen=True)
class EditResult:
    title: str
    body: str


class EditScreen(Screen[EditResult | None]):
    """Full-screen Markdown editor. ctrl+s saves, escape cancels."""

    BINDINGS = [
        Binding("ctrl+s", "save", "Save", priority=True),
        Binding("escape", "cancel", "Cancel", priority=True),
    ]

    def __init__(self, heading: str, title: str = "", body: str = "") -> None:
        super().__init__()
        self._heading = heading
        self._title = title
        self._body = body

    def compose(self) -> ComposeResult:
        with Vertical(id="editor"):
            yield Label(self._heading, id="editor-heading")
            yield Input(value=self._title, placeholder="Title", id="edit-title")
            yield TextArea(self._body, id="edit-body", soft_wrap=True, tab_behavior="indent")
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#edit-title", Input).focus()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        self.query_one("#edit-body", TextArea).focus()

    def action_save(self) -> None:
        title = self.query_one("#edit-title", Input).value.strip()
        body = self.query_one("#edit-body", TextArea).text
        self.dismiss(EditResult(title=title, body=body))

    def action_cancel(self) -> None:
        self.dismiss(None)


class SearchScreen(ModalScreen[str | None]):
    """One-line full-text query. Enter searches, an empty query clears."""

    BINDINGS = [Binding("escape", "cancel", "Cancel")]

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("Search title and body (empty clears the search)")
            yield Input(placeholder="full-text query", id="search-input")

    def on_mount(self) -> None:
        self.query_one(Input).focus()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        self.dismiss(event.value.strip())

    def action_cancel(self) -> None:
        self.dismiss(None)


class ConfirmScreen(ModalScreen[bool]):
    BINDINGS = [
        Binding("y", "answer(True)", "Yes"),
        Binding("n,escape", "answer(False)", "No"),
    ]

    def __init__(self, question: str) -> None:
        super().__init__()
        self._question = question

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label(self._question)
            yield Label("[b]y[/b] yes   [b]n[/b] no")

    def action_answer(self, answer: bool) -> None:
        self.dismiss(answer)


HELP_TEXT = """\
# Notes App: keys

| Key | Action |
| --- | --- |
| `tab` | Cycle panes (notebooks, notes, note) |
| `enter` | Select the highlighted notebook |
| `1` / `2` / `3` | Active, Archive, Trash view |
| `n` | New note in the current notebook |
| `e` | Edit the selected note (`ctrl+s` saves, `escape` cancels) |
| `p` | Pin or unpin |
| `a` | Archive, or un-archive in the Archive view |
| `d` | Move to trash |
| `u` | Restore to active (from Trash or Archive) |
| `x` | Empty the trash for this notebook (hard delete, confirmed) |
| `/` | Full-text search in the current view |
| `r` | Reload from the database |
| `?` | This help |
| `q` | Quit |

Press `escape` or `?` to close.
"""


class HelpScreen(ModalScreen[None]):
    BINDINGS = [Binding("escape,question_mark,q", "close", "Close")]

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog help"):
            yield Markdown(HELP_TEXT)

    def action_close(self) -> None:
        self.dismiss(None)
