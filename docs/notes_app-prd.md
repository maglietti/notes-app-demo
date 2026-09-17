# Notes App — Product Requirements Document

**Version:** 1.0
**Date:** 2026-09-17
**Owner:** Michael Aglietti
**Schema:** [`notes_app.sql`](notes_app.sql) (MariaDB 11.8 LTS)
**ER:** [`notes_app-er.md`](notes_app-er.md)

## 1. Purpose and role in the talk

The Notes App is a terminal client for the `notes_app` schema. It reads and writes
notes through the MariaDB REST Service that the coding agent stands up in the
All Things Open talk *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*.

The talk's live demo is the scaffolding run: one prompt builds the schema, deploys
a sandbox, runs the DDL over MCP, and puts a REST service in front of the schema.
This app is the capstone that makes the tier concrete. The agent designed an API
in about five minutes, and this client runs on it with no server code written by
hand. It shows the endpoints answering, not by reading metadata, but by a real
application serving a user.

The app is a payoff artifact and a clone-and-run repository, not the primary demo.
Budget it as a short closing beat or a post-talk link.

## 2. Stack decisions

| Axis        | Choice               | Reason                                                                                                                                                                                                              |
| ----------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Connection  | **REST**             | The app consumes the MariaDB REST Service (`/notesApp`), the exact artifact the talk produces. A native connector would bypass the API tier the talk is about.                                                      |
| Interface   | **TUI**              | The whole demo lives in a terminal over MCP and SQL. A TUI keeps the payoff in the same register: no browser, no build step, instant start on a projector.                                                          |
| Language    | **Python + Textual** | Charm is a Go framework and falls outside the Python/Node constraint. Textual is the Python equivalent, with tables, Markdown rendering, and CSS-like styling. Python matches the surrounding plugin tooling.       |
| HTTP client | **httpx**            | Async client that fits Textual's asyncio loop; a blocking `requests` call would freeze the UI mid-render. Its API mirrors `requests`, so little familiarity is lost. `requests` would need a Textual thread worker. |

Alternatives, if the constraints change:

- **Node + Ink** keeps a React mental model in the terminal on Node. Pick this if
  the JavaScript ecosystem matters more than alignment with the plugin tooling.
- **Web React** if the app must run in a browser. It costs a dev server, a bundle
  step, and CORS handling that the TUI avoids.

## 3. Users and scope

The demo runs as one seeded account (`michael.aglietti@mariadb.com`, from the
schema sample data). Multi-user is a schema capability, not a demo requirement.

- **In scope:** notebooks, notes, tags, search, pin, archive, trash and restore.
- **Out of scope for the demo:** account sign-up, attachments (no object storage
  in the demo), and real password authentication. See section 10.

## 4. Data model

Six tables and one view, unchanged from [`notes_app.sql`](notes_app.sql):

- `account` — one seeded row. System-versioned.
- `notebook` — folders, unique name per account, one `is_default`. System-versioned.
- `note` — `title`, Markdown `body`, `status` enum (`active` / `archived` /
  `trashed`), `is_pinned`, timestamps. `FULLTEXT(title, body)` drives search.
- `tag`, `note_tag` — free-form labels, many-to-many with notes.
- `attachment` — object-storage pointers. Read model only in this app.
- `v_active_note` — active notes with notebook, owner and a comma-joined tag list.
  Backs the default list view.

The `status` enum maps directly to three app views: active list, archive, trash.
`is_pinned` sorts pinned notes to the top of the active list.

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

`@KEY` on the note `id` is what makes the row-level `GET`, `PUT` and `DELETE`
work. `@SORTABLE` on `title`, `created_at` and `updated_at` drives ordering.
Tags arrive embedded in each note through `@UNNEST`, so the list view needs one
request, not three.

Two response shapes the client must handle:

- **List responses are paginated.** The REST Service wraps a collection in an
  `items` array alongside `limit`, `offset`, `count`, `hasMore` and `links`. Even
  with a handful of notes, the client reads `items` and honours `hasMore` rather
  than assuming a bare array.
- **Create carries the owning keys.** `note.notebook_id` and `note.account_id`
  are `NOT NULL` foreign keys, so `POST /note` must include the current notebook
  id and the seeded account id. The UI supplies both from context.

**Demo build creates endpoints without `AUTHENTICATION REQUIRED`** to keep the
live path short. Section 10 covers what production would add.

## 6. Functional requirements

Priority uses Must / Should / Could.

**Notebooks**

- (Must) List notebooks, mark the default, show a note count per notebook.
- (Should) Create and rename a notebook.
- (Could) Delete a notebook. `ON DELETE CASCADE` removes its notes, so confirm first.

**Notes**

- (Must) List active notes in the selected notebook, pinned first, newest next.
  Backed by `ix_note_notebook_updated`.
- (Must) Open a note and render its Markdown `body`.
- (Must) Create a note in the current notebook.
- (Must) Edit title and body, save, and see `updated_at` change.
- (Must) Pin and unpin.
- (Must) Archive and un-archive (`status` active ↔ archived).
- (Must) Trash and restore (`status` active ↔ trashed), with an emptied-trash
  view. Emptying trash is the only hard `DELETE` the app issues.
- (Should) Full-text search across title and body, backed by `FULLTEXT(title, body)`.

**Tags**

- (Should) Show a note's tags and filter the list by one tag.
- (Could) Create a tag and attach or detach it from a note.

**Cross-cutting**

- (Must) A visible status line naming the current data mode (REST or native)
  and the service root. Useful on stage.
- (Should) An empty state that names the seeded sample data so a fresh sandbox
  reads correctly on the projector.

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

- **Left:** notebook list. Enter selects and filters the middle pane.
- **Middle:** note list for the selected notebook and status view. A star marks
  pinned notes. `/` opens search.
- **Right:** the selected note, Markdown rendered read-only, `e` to edit.
- **Bottom:** status line with data mode, service root and note count.

Key bindings: `n` new note, `e` edit, `p` pin, `a` archive, `d` trash, `u`
restore, `/` search, `tab` cycle panes, `q` quit. Edit mode is a full-screen
Markdown text area with `ctrl+s` to save.

## 8. Non-functional requirements

- **Demo reliability first.** Every network call has a timeout and a visible
  error state. A failed REST call never crashes the app; it shows the error in
  the status line and keeps the last good view.
- **Performance.** List views return in one request. The projector target is a
  visible paint under 200 ms against a local sandbox.
- **Startup.** No build step. The app is a `notes_app` package at the repository
  root, runnable as `python -m notes_app` and launched on stage with the committed
  `bin/notes-app` wrapper. Config comes from environment variables or one `.env`.
- **Portability.** Runs on macOS and Linux, the two platforms the sandbox
  supports. Python 3.11+.
- **Security (demo posture).** The sandbox listens on all interfaces with a
  `root@'%'` account and no TLS. Treat it as throwaway and never point the app at
  a real database. The app holds no long-lived credential beyond the sandbox
  password in local config.

## 9. Architecture

``` text
Textual UI  ─▶  DataSource (interface)
                   ├─ RestDataSource   (default, httpx → REST Daemon)
                   └─ NativeDataSource  (fallback, mariadb Connector/Python)
```

A single `DataSource` interface with two implementations. The UI never knows
which one it holds.

- **`RestDataSource`** is the default and the on-thesis path. It calls the
  `/notesApp` endpoints from section 5.
- **`NativeDataSource`** runs the same queries through MariaDB Connector/Python
  against port 3310. It exists for one reason: if the REST Daemon misbehaves on
  stage, `NOTES_APP_MODE=native` swaps the data layer with no UI change and the
  demo still runs. This is a scoped contingency, not speculative feature work.

The status line names the active mode so the audience always knows which tier
they are watching.

## 10. Out of scope

- **Account sign-up and password login.** The demo uses the seeded account.
- **Attachments.** The schema stores object-storage pointers. The demo has no
  object store, so attachments are not read or written.
- **REST authentication.** The demo creates endpoints without
  `AUTHENTICATION REQUIRED`. Production would add an MRS auth app, a REST role
  scoped to read or write per endpoint, a seeded test user, and a login screen
  in the TUI that stores the session token. The
  `mariadb-rest-service-authorization` skill covers the DDL.
- **Note history.** `note` is not system-versioned in the shipped schema, only
  `account` and `notebook` are. A history view would first need
  `ALTER TABLE note ... WITH SYSTEM VERSIONING`, which is a good live push-back
  demo but a stretch feature here.

## 11. Demo runbook and prerequisites

1. Deploy the sandbox: `sandbox.deploy(port=3310, password="demo-pw")`.
2. Run [`notes_app.sql`](notes_app.sql) against it (`db.execute_sql_script`).
3. Run the REST DDL through `db.execute_sql` one statement at a time. The REST
   grammar is session state, so `db.execute_sql_script` breaks it. This is the
   break the talk shows and the agent recovers from.
4. Publish the service: `ALTER REST SERVICE /notesApp PUBLISHED`.
5. Start the REST Daemon so the endpoints answer over HTTP. This is the one piece
   the tutorials leave out, and it is a hard prerequisite for the REST data mode.
6. Point the app at the service root and run it.
7. Fallback: if the daemon is not up, set `NOTES_APP_MODE=native` and the app
   talks to port 3310 directly.
8. Clean up: `sandbox.stop` then `sandbox.delete`. The sandbox outlives the
   conversation, so cleanup is manual, as the talk notes.

## 12. Build order

1. `DataSource` interface and the six DTOs mapped to the endpoints.
2. `NativeDataSource` first. It needs no daemon, so the UI can be built and
   tested against a plain sandbox.
3. Textual three-pane shell: notebook list, note list, note view, status line.
4. Read paths: list notebooks, list notes, open a note with tags.
5. Write paths: create, edit, pin, archive, trash, restore.
6. Full-text search.
7. `RestDataSource` against the running daemon, then make REST the default.
8. Seed-data verification pass on a fresh sandbox for the projector.

## 13. Risks and open questions

- **REST Daemon dependency.** The daemon is the least-documented moving part and
  the biggest live risk. The native fallback is the mitigation. Rehearse both.
- **Writing tags through the `@UNNEST` view is unproven.** The note view
  flattens tags for reading, but the REST Service's support for writing nested
  related rows through a data mapping view is limited. Attaching or detaching a
  tag may need a separate `/noteTag` endpoint or a direct write. Resolve before
  committing to the (Could) tag-write features.
- **Search on the sandbox.** `FULLTEXT` needs enough sample rows to look real.
  The three seeded notes are thin. Decide whether to seed more for the demo.
- **Auth on stage.** Endpoints without `AUTHENTICATION REQUIRED` are simplest but
  read as insecure to a DBA audience. Decide whether to show the auth path or
  name it as a follow-on.
