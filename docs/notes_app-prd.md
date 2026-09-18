# Notes App: Product Requirements Document

**Version:** 1.0
**Date:** 2026-09-17
**Owner:** Michael Aglietti
**Schema:** [`research/notes_app.sql`](../research/notes_app.sql) (MariaDB 11.8 LTS)
**ER:** [`research/notes_app-er.md`](../research/notes_app-er.md)

## 1. Purpose and role in the talk

The Notes App is a terminal client for the `notes_app` schema. It reads and writes notes through the MariaDB REST Service that the coding agent stands up in the All Things Open talk *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*.

The talk's live demo is the scaffolding run, where one prompt builds the schema, deploys a sandbox, runs the DDL over MCP, and puts a REST service in front of the schema. This app is the capstone that makes the tier concrete, since the agent designed an API in about five minutes and this client runs on it with no server code written by hand. It shows the endpoints answering through a real application serving a user rather than through a read of the metadata.

The app is a payoff artifact and a clone-and-run repository, not the primary demo, so budget it as a short closing beat or a post-talk link.

## 2. Stack decisions

| Axis        | Choice               | Reason                                                                                                                                                                                                              |
| ----------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Connection  | **REST**             | The app consumes the MariaDB REST Service (`/notesApp`), the exact artifact the talk produces. A native connector would bypass the API tier the talk is about.                                                      |
| Interface   | **TUI**              | The whole demo lives in a terminal over MCP and SQL. A TUI keeps the payoff in the same register: no browser, no build step, instant start on a projector.                                                          |
| Language    | **Python + Textual** | Charm is a Go framework and falls outside the Python/Node constraint. Textual is the Python equivalent, with tables, Markdown rendering, and CSS-like styling. Python matches the surrounding plugin tooling.       |
| HTTP client | **httpx**            | Async client that fits Textual's asyncio loop; a blocking `requests` call would freeze the UI mid-render. Its API mirrors `requests`, so little familiarity is lost. `requests` would need a Textual thread worker. |

Alternatives, if the constraints change:

- **Node + Ink** keeps a React mental model in the terminal on Node, and is the pick when the JavaScript ecosystem matters more than alignment with the plugin tooling.
- **Web React** suits an app that must run in a browser, at the cost of a dev server, a bundle step, and the CORS handling the TUI avoids.

## 3. Users and scope

The demo runs as one seeded account (`michael.aglietti@mariadb.com`, from the schema sample data), and multi-user is a schema capability rather than a demo requirement.

- **In scope:** notebooks, notes, tags, search, pin, archive, trash and restore.
- **Out of scope for the demo:** account sign-up, attachments (no object storage in the demo), and real password authentication. See section 10.

## 4. Data model

Six tables and one view, from the canonical schema in [`research/notes_app.sql`](../research/notes_app.sql), frozen from the agent's design run. Every table's primary key is a `uuid` column named `id` defaulting to `UUID_v7()`, and native mode binds to these exact column names.

- `account` holds one seeded row (`id`, `email`, `display_name`, `created_at`, with no password field in this build), and it is system-versioned.
- `notebook` holds folders with a unique name per account and one `is_default`, held to at most one per account by a generated `default_flag`, and it is system-versioned.
- `note` carries a `title`, a Markdown `body`, a `status` enum (`active`, `archived`, `trashed`), an `is_pinned` flag, and created and updated timestamps, with a `FULLTEXT(title, body)` index driving search.
- `tag` and `note_tag` provide free-form labels in a many-to-many with notes, and `note_tag` carries an `added_at`.
- `attachment` holds object-storage pointers (`file_name`, `mime_type`, `size_bytes`, `storage_key`), and this app treats it as a read model only.
- `v_active_note` lists active notes with their notebook, owner, and a comma-joined tag list, and backs the default list view.

The `status` enum maps directly to the three app views for the active list, the archive, and the trash, and `is_pinned` sorts pinned notes to the top of the active list.

## 5. REST API surface

From the `rest-endpoints` recipe, the agent creates:

``` sql
CONFIGURE REST METADATA;
CREATE REST SERVICE  /notesApp;
CREATE REST SCHEMA   /notes FROM `notes_app`;
CREATE REST VIEW     /note     AS notes_app.note     { ... noteTag @UNNEST { tag @UNNEST { name } } }
CREATE REST VIEW     /notebook AS notes_app.notebook { ... }
CREATE REST VIEW     /tag      AS notes_app.tag      { ... }
```

Endpoints the TUI calls, served by the REST Daemon under the service root:

| Method + path                         | Use                                                        |
| ------------------------------------- | ---------------------------------------------------------- |
| `GET /notesApp/notes/notebook`        | List notebooks for the sidebar.                            |
| `GET /notesApp/notes/note?q=<filter>` | List notes, filtered by notebook, status or full text.     |
| `GET /notesApp/notes/note/<id>`       | Load one note with its tags (flattened by `@UNNEST`).      |
| `POST /notesApp/notes/note`           | Create a note.                                             |
| `PUT /notesApp/notes/note/<id>`       | Update title, body, status or pin.                         |
| `DELETE /notesApp/notes/note/<id>`    | Hard delete. The app prefers `status = trashed` over this. |
| `GET /notesApp/notes/tag`             | List tags for the tag filter.                              |

`@KEY` on the note `id` is what makes the row-level `GET`, `PUT`, and `DELETE` work, `@SORTABLE` on `title`, `created_at`, and `updated_at` drives ordering, and tags arrive embedded in each note through `@UNNEST`, so the list view needs one request rather than three.

Two response shapes the client must handle:

- **List responses are paginated.** The REST Service wraps a collection in an `items` array alongside `limit`, `offset`, `count`, `hasMore`, and `links`, so even with a handful of notes the client reads `items` and honours `hasMore` rather than assuming a bare array.
- **Create carries the owning keys.** `note.notebook_id` and `note.account_id` are `NOT NULL` foreign keys, so a `POST /note` must include the current notebook id and the seeded account id, and the UI supplies both from context.

**The demo build creates endpoints without `AUTHENTICATION REQUIRED`** to keep the live path short, and section 10 covers what production would add.

## 6. Functional requirements

Priority uses Must, Should, and Could.

**Notebooks**

- (Must) List notebooks, mark the default, and show a note count per notebook.
- (Should) Create and rename a notebook.
- (Could) Delete a notebook, where `ON DELETE CASCADE` removes its notes, so confirm first.

**Notes**

- (Must) List active notes in the selected notebook, pinned first and newest next, backed by `ix_note_notebook_updated`.
- (Must) Open a note and render its Markdown `body`.
- (Must) Create a note in the current notebook.
- (Must) Edit title and body, save, and see `updated_at` change.
- (Must) Pin and unpin.
- (Must) Archive and un-archive, moving `status` between active and archived.
- (Must) Trash and restore, moving `status` between active and trashed, with an emptied-trash view, and emptying the trash is the only hard `DELETE` the app issues.
- (Should) Full-text search across title and body, backed by `FULLTEXT(title, body)`.

**Tags**

- (Should) Show a note's tags and filter the list by one tag.
- (Could) Create a tag and attach or detach it from a note.

**Cross-cutting**

- (Must) A visible status line naming the current data mode (REST or native) and the service root, which is useful on stage.
- (Should) An empty state that names the seeded sample data, so a fresh sandbox reads correctly on the projector.

## 7. TUI layout and interaction

A three-pane layout, Textual widgets:

``` text
┌ Notebooks ─┬ Notes ───────────────┬ Note ─────────────┐
│ ▸ Inbox    │ ★ Optimizer trace    │ # Optimizer trace │
│   DevRel   │   Community call     │ optimizer_trace…  │
│            │   Travel checklist   │                   │
├────────────┴──────────────────────┴───────────────────┤
│ REST · http://127.0.0.1:8443/notesApp · 3 notes · /   │
└───────────────────────────────────────────────────────┘
```

- **Left:** the notebook list, where Enter selects a notebook and filters the middle pane.
- **Middle:** the note list for the selected notebook and status view, where a star marks a pinned note and `/` opens search.
- **Right:** the selected note, its Markdown rendered read-only, with `e` to edit.
- **Bottom:** the status line, showing the data mode, the service root, and the note count.

Key bindings are `n` for a new note, `e` to edit, `p` to pin, `a` to archive, `d` to trash, `u` to restore, `/` to search, `tab` to cycle panes, and `q` to quit. Edit mode is a full-screen Markdown text area with `ctrl+s` to save.

## 8. Non-functional requirements

- **Demo reliability first.** Every network call carries a timeout and a visible error state, and a failed REST call never crashes the app, instead showing the error on the status line and keeping the last good view.
- **Performance.** List views return in one request, and the projector target is a visible paint under 200 ms against a local sandbox.
- **Startup.** There is no build step. The app is a `notes_app` package at the repository root, runnable as `python -m notes_app` and launched on stage with the committed `bin/notes-app` wrapper, and its config comes from environment variables or one `.env`.
- **Portability.** It runs on macOS and Linux, the two platforms the sandbox supports, on Python 3.11 or newer.
- **Security (demo posture).** The sandbox listens on all interfaces with a `root@'%'` account and no TLS, so treat it as throwaway and never point the app at a real database. The app holds no long-lived credential beyond the sandbox password in local config.

## 9. Architecture

``` text
Textual UI  ─▶  DataSource (interface)
                   ├─ RestDataSource   (default, httpx → REST Daemon)
                   └─ NativeDataSource  (fallback, mariadb Connector/Python)
```

A single `DataSource` interface backs two implementations, and the UI never knows which one it holds.

- **`RestDataSource`** is the default and the on-thesis path, calling the `/notesApp` endpoints from section 5.
- **`NativeDataSource`** runs the same queries through MariaDB Connector/Python against port 3310. It exists for one reason. If the REST Daemon misbehaves on stage, `NOTES_APP_MODE=native` swaps the data layer with no UI change and the demo still runs, a scoped contingency rather than speculative feature work.

The status line names the active mode, so the audience always knows which tier they are watching.

## 10. Out of scope

- **Account sign-up and password login.** The demo uses the seeded account.
- **Attachments.** The schema stores object-storage pointers, but the demo has no object store, so attachments are not read or written.
- **REST authentication.** The demo creates endpoints without `AUTHENTICATION REQUIRED`. Production would add an MRS auth app, a REST role scoped to read or write per endpoint, a seeded test user, and a login screen in the TUI that stores the session token, all of which the `mariadb-rest-service-authorization` skill covers.
- **Note history.** The `note` table is not system-versioned in the shipped schema, only `account` and `notebook` are. A history view would first need `ALTER TABLE note ... WITH SYSTEM VERSIONING`, which is a good live push-back demo but a stretch feature here.

## 11. Demo runbook and prerequisites

1. Deploy the sandbox with `sandbox.deploy(port=3310, password="demo-pw")`.
2. Run [`research/notes_app.sql`](../research/notes_app.sql) against it with `db.execute_sql_script`.
3. Run the REST DDL through `db.execute_sql` one statement at a time, because the REST grammar is session state and `db.execute_sql_script` breaks it. This is the break the talk shows and the agent recovers from.
4. Publish the service with `ALTER REST SERVICE /notesApp PUBLISHED`.
5. Start the REST Daemon so the endpoints answer over HTTP. This is the one piece the tutorials leave out, and it is a hard prerequisite for the REST data mode.
6. Point the app at the service root and run it.
7. Fall back to native if the daemon is not up: set `NOTES_APP_MODE=native` and the app talks to port 3310 directly.
8. Clean up with `sandbox.stop` and then `sandbox.delete`, since the sandbox outlives the conversation and cleanup is manual, as the talk notes.

## 12. Build order

1. The `DataSource` interface and the six DTOs mapped to the endpoints.
2. `NativeDataSource` first, because it needs no daemon, so the UI can be built and tested against a plain sandbox.
3. The Textual three-pane shell: the notebook list, the note list, the note view, and the status line.
4. The read paths: list notebooks, list notes, and open a note with its tags.
5. The write paths: create, edit, pin, archive, trash, and restore.
6. Full-text search.
7. `RestDataSource` against the running daemon, then make REST the default.
8. A seed-data verification pass on a fresh sandbox for the projector.

## 13. Risks and open questions

- **REST Daemon dependency.** The daemon is the least-documented moving part and the biggest live risk, so the native fallback is the mitigation and both are worth rehearsing.
- **Writing tags through the `@UNNEST` view is unproven.** The note view flattens tags for reading, but the REST Service's support for writing nested related rows through a data mapping view is limited. Attaching or detaching a tag may need a separate `/noteTag` endpoint or a direct write, so resolve this before committing to the (Could) tag-write features.
- **Search on the sandbox.** A `FULLTEXT` search needs enough sample rows to look real, and the three seeded notes are thin, so decide whether to seed more for the demo.
- **Auth on stage.** Endpoints without `AUTHENTICATION REQUIRED` are simplest but read as insecure to a DBA audience, so decide whether to show the auth path or name it as a follow-on.
