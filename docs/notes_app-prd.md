# Notes App: Product Requirements Document

**Version:** 1.0
**Date:** 2026-09-17
**Owner:** Michael Aglietti
**Schema:** [`research/notes_app.sql`](../research/notes_app.sql) (MariaDB 11.8 LTS)
**ER:** [`research/notes_app-er.md`](../research/notes_app-er.md)

## 1. Purpose and role in the talk

The Notes App is a terminal client for the `notes_app` schema. It reads and writes notes through the MariaDB REST Service that the coding agent stands up in the All Things Open talk *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*.

The talk's live demo is the scaffolding run, where the first prompt builds the schema, deploys a sandbox, and runs the DDL over MCP, and an optional third prompt puts a REST service in front of the schema. The agent designs that API tier in about five minutes with no server code written by hand, and the proof that it is real is the metadata, since `SHOW REST` and `SHOW CREATE REST VIEW` show the endpoints the agent defined.

This app is a separate payoff artifact, a usable client on the same schema rather than proof of the tier. It defaults to native mode and reads and writes the tables directly, so it needs no REST Daemon to start and does not run on the `/notesApp` endpoints during the demo. It is a clone-and-run repository, not the primary demo, so budget it as a short closing beat or a post-talk link.

## 2. Stack decisions

| Axis        | Choice               | Reason                                                                                                                                                                                                              |
| ----------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Connection  | **Native (default)** | The client defaults to a native connector, because serving REST over HTTP needs a router that is out of scope, and native keeps the demo running with no daemon. It can also consume the REST Service at `/notesApp` with `NOTES_APP_MODE=rest`, the artifact the talk produces.                                                      |
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

Six tables and one view, from the canonical schema in [`research/notes_app.sql`](../research/notes_app.sql), frozen from the agent's design run. Native mode binds to these exact names, so this section is the specification: a schema generated from it should match the reference in its names, types, defaults, keys, and index names.

It deliberately leaves the MariaDB grammar to the agent and its skills. Each entry says what a column or table must do, not the syntax that does it, so the idioms in a generated schema are the agent's own work rather than a copy of this document.

### 4.1 Conventions

These apply to every object unless a table below says otherwise.

- **Target and schema.** MariaDB 11.8 LTS. A `notes_app` schema in `utf8mb4` with the server's current default Unicode collation, and the same for every table.
- **Rerunnable.** Running the file again replaces each table rather than failing because it already exists.
- **Primary keys.** Every entity table has an `id` primary key: a UUID the server generates, in the database's native UUID type, in time order so new rows sort last and ids do not leak row counts. The join table `note_tag` is the only exception: its key is `(note_id, tag_id)`, and it has no `id` column. Foreign key columns use the same type as the key they reference.
- **Timestamps.** Second precision, defaulting to the time the row is written. Every table has `created_at`, except `note_tag`, which has `added_at` instead. Only `note` has `updated_at`, and the server advances it on every update.
- **Flags.** Required booleans that default to false.
- **Foreign keys.** Every foreign key cascades both deletes and updates, and is named `fk_<table>_<parent>`.
- **Script shape.** Fully qualify every object as `notes_app.<name>`, and order the tables parent-first: `account`, `notebook`, `tag`, `note`, `note_tag`, `attachment`. Rely on no session state: no `USE`, and no `SET` block that saves and restores session variables. This lets `db.execute_sql_script` load the file statement by statement. The file is pure DDL with no `INSERT`s, because data comes from [`research/synthetic_data.sql`](../research/synthetic_data.sql).

### 4.2 Tables

**`account`** holds the one seeded owner, with no password field in this build. It keeps its full row history in the table itself, with no separate history table and no triggers.

- `id`
- `email varchar(320)`, required, unique as `uq_account_email`
- `display_name varchar(120)`, required
- `created_at`

**`notebook`** holds folders. Like `account`, it keeps its full row history in the table itself.

- `id`
- `account_id`, required, foreign key `fk_notebook_account` to `account`
- `name varchar(120)`, required
- `is_default` flag
- `created_at`
- `default_flag`, a stored column the server computes from `is_default`: 1 for the default notebook and `NULL` for every other row
- Keys: `uq_notebook_account_name (account_id, name)` and `uq_notebook_one_default (account_id, default_flag)`. The second key allows at most one default notebook per account, because a unique key ignores the `NULL` flags on non-default rows.

**`tag`** holds free-form labels scoped to one account.

- `id`
- `account_id`, required, foreign key `fk_tag_account` to `account`
- `name varchar(64)`, required
- `created_at`
- Key: `uq_tag_account_name (account_id, name)`

**`note`** holds the notes. It does not keep row history (see section 10).

- `id`
- `notebook_id`, required, foreign key `fk_note_notebook` to `notebook`
- `account_id`, required, foreign key `fk_note_account` to `account`. This denormalized owner lets a per-account query skip the join to `notebook`.
- `title varchar(255)`, required, default empty
- `body longtext`, required, default empty, the Markdown source
- `status`, one of `active`, `archived`, or `trashed`, required, default `active`
- `is_pinned` flag
- `created_at`
- `updated_at`
- Indexes: `ix_note_notebook_updated` on `notebook_id`, `status`, `is_pinned`, and `updated_at`, with the last two descending to match the pinned-first, newest-first list order; `ix_note_account_status` on `account_id`, `status`, and `updated_at` descending; and a full-text index `ft_note_title_body` on `title` and `body` for search.

**`note_tag`** is the many-to-many join between notes and tags.

- `note_id`, required, foreign key `fk_note_tag_note` to `note`
- `tag_id`, required, foreign key `fk_note_tag_tag` to `tag`
- `added_at`
- Keys: primary key `(note_id, tag_id)`, plus `ix_note_tag_tag (tag_id)` for the reverse lookup of every note carrying one tag.

**`attachment`** holds object-storage pointers. This app treats it as a read model only.

- `id`
- `note_id`, required, foreign key `fk_attachment_note` to `note`
- `file_name varchar(255)`, required
- `mime_type varchar(127)`, required, default `application/octet-stream`
- `size_bytes`, an unsigned 64-bit integer, required, default 0
- `storage_key varchar(512)`, required, an object-storage path such as an S3 key. It has no unique key.
- `created_at`
- Index: `ix_attachment_note (note_id)`

### 4.3 View

**`v_active_note`** backs the default list view. It lists active notes only, with one row per note, and keeps notes that have no tags. Its columns, in order:

- `note_id`, `title`, `body`, `is_pinned`, `created_at`, `updated_at`
- `notebook_id`, `notebook_name`
- `account_id`, `account_email`
- `tags`, the note's distinct tag names in alphabetical order, joined with commas

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

Endpoints the client calls in REST mode, served by the REST Daemon under the service root:

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

**Tags are read-only through `/note`.** The tag names embedded in a note are for display, and a write to `/note` changes only the note's own columns, never `note_tag` or `tag`. This must be explicit, because the server gives nested objects the parent view's write operations unless they are switched off, so a writable `/note` would otherwise make its embedded tags writable too, even with `/tag` read-only. On mariadb-shell 26.9.3 the switch does not stick: the nested `@NOINSERT @NOUPDATE @NODELETE` flags parse, but the metadata stores the nested objects with the parent's operations anyway (section 13). The client never writes tags through `/note`, so the app is unaffected, but the metadata does not yet match this rule.

Two response shapes the client must handle:

- **List responses are paginated.** The REST Service wraps a collection in an `items` array alongside `limit`, `offset`, `count`, `hasMore`, and `links`, so even with a handful of notes the client reads `items` and honours `hasMore` rather than assuming a bare array.
- **Create carries the owning keys.** `note.notebook_id` and `note.account_id` are `NOT NULL` foreign keys, so a `POST /note` must include the current notebook id and the seeded account id, and the UI supplies both from context.

**The demo build marks every endpoint `AUTHENTICATION NOT REQUIRED`** to keep the live path short, and section 10 covers what production would add. The clause must be explicit, because a view created without it defaults to `AUTHENTICATION REQUIRED`.

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
- **Footer:** a footer below the status line lists the key bindings, and `?` opens a help screen.

Key bindings are `n` for a new note, `e` to edit, `p` to pin, `a` to archive, `d` to trash, `u` to restore, `/` to search, `?` for help, `tab` to cycle panes, and `q` to quit. Edit mode is a full-screen Markdown text area with `ctrl+s` to save.

## 8. Non-functional requirements

- **Demo reliability first.** Every network call carries a timeout and a visible error state, and a failed REST call never crashes the app, instead showing the error on the status line and keeping the last good view.
- **Performance.** List views return in one request, and the projector target is a visible paint under 200 ms against a local sandbox.
- **Startup.** There is no build step. The app is a `notes_app` package at the repository root, runnable as `python -m notes_app` and launched on stage with the committed `bin/notes-app` wrapper, and its config comes from environment variables or one `.env`.
- **Portability.** It runs on macOS and Linux, the two platforms the sandbox supports, on Python 3.11 or newer.
- **Security (demo posture).** The sandbox listens on all interfaces with a `root@'%'` account and no TLS, so treat it as throwaway and never point the app at a real database. The app holds no long-lived credential beyond the sandbox password in local config.

## 9. Architecture

``` text
Textual UI  ─▶  DataSource (interface)
                   ├─ NativeDataSource  (default, mariadb Connector/Python)
                   └─ RestDataSource    (optional, httpx → REST Daemon)
```

A single `DataSource` interface backs two implementations, and the UI never knows which one it holds.

- **`NativeDataSource`** is the default. It runs the app's queries through MariaDB Connector/Python against port 3310, binding to the schema's actual columns, so the client starts with no REST Daemon.
- **`RestDataSource`** is the on-thesis path, calling the `/notesApp` endpoints from section 5. It is selected with `NOTES_APP_MODE=rest` and needs a running REST Daemon, which is out of scope for the talk, so it stays available but off by default.

The status line names the active mode, so the audience always knows which tier they are watching.

## 10. Out of scope

- **Account sign-up and password login.** The demo uses the seeded account.
- **Attachments.** The schema stores object-storage pointers, but the demo has no object store, so attachments are not read or written.
- **REST authentication.** The demo creates endpoints with `AUTHENTICATION NOT REQUIRED`. Production would add an MRS auth app, a REST role scoped to read or write per endpoint, a seeded test user, and a login screen in the TUI that stores the session token, all of which the `mariadb-rest-service-authorization` skill covers.
- **Note history.** The `note` table does not keep row history in the shipped schema, only `account` and `notebook` do. A history view would first need an `ALTER TABLE` that adds history to `note`, which is a good live push-back demo but a stretch feature here.

## 11. Demo runbook and prerequisites

1. Deploy the sandbox with `sandbox.deploy(port=3310, password="demo-pw", sandbox_dir="working/sandbox")`.
2. Deploy the canonical schema and load the fixture by running [`research/notes_app.sql`](../research/notes_app.sql) and then [`research/synthetic_data.sql`](../research/synthetic_data.sql) with `db.execute_sql_script`, which gives the app 61 notes across the active, archived, and trashed views.
3. Build the REST tier by running the REST DDL through `db.execute_sql` one statement at a time, because the grammar is session state and `db.execute_sql_script` breaks it.
4. Verify the tier from the metadata with `SHOW REST` and `SHOW CREATE REST VIEW`, then publish it with `ALTER REST SERVICE /notesApp PUBLISHED`.
5. Run the client with `bin/notes-app`. It defaults to native mode, so it reads the sandbox on port 3310 directly and needs no daemon.
6. REST mode is optional. Serving the endpoints over HTTP needs a router bootstrapped against the metadata, which is out of band, so switch to `NOTES_APP_MODE=rest` only once that router is running.
7. Clean up with `sandbox.stop` and then `sandbox.delete`, since the sandbox outlives the conversation and cleanup is manual, as the talk notes.

## 12. Build order

1. The `DataSource` interface and the DTOs the UI works with.
2. `NativeDataSource` first, because it needs no daemon, so the UI can be built and tested against a plain sandbox.
3. The Textual three-pane shell: the notebook list, the note list, the note view, and the status line.
4. The read paths: list notebooks, list notes, and open a note with its tags.
5. The write paths: create, edit, pin, archive, trash, and restore.
6. Full-text search.
7. `RestDataSource` as the optional REST-mode backend, selected by `NOTES_APP_MODE=rest` and left off by default, since it needs a router.
8. A seed-data verification pass on a fresh sandbox for the projector.

## 13. Risks and open questions

- **REST Daemon dependency.** The daemon is the least-documented moving part, and because the client runs in native mode by default, it sits off the critical path. It matters only if you choose to show REST mode live, so rehearse that path separately if you plan to.
- **Writing tags through the `@UNNEST` view is unproven.** The note view flattens tags for reading, but the REST Service's support for writing nested related rows through a data mapping view is limited. Attaching or detaching a tag may need a separate `/noteTag` endpoint or a direct write, so resolve this before committing to the (Could) tag-write features.
- **Nested read-only flags are dropped (mariadb-shell 26.9.3).** In `plugins/mrs_plugin/lib/db_objects.py:762`, each nested `object_reference` is saved with the parent object's options (`obj.get("options")`) instead of its own, so `SHOW CREATE REST VIEW /note` shows `noteTag` and `tag` with `@INSERT @UPDATE @DELETE` whatever the DDL says. No DDL spelling avoids it, and moving the flags before `@UNNEST` is a syntax error. Until a fixed shell ships, the demo reports the mismatch instead of patching the metadata. An `UPDATE` on `mysql_rest_service_metadata.object_reference` corrects the flags, but it bypasses the shell and is untested against a router.
- **Search on the sandbox.** A `FULLTEXT` search needs enough sample rows to look real, and the committed fixture `research/synthetic_data.sql` covers this with 61 notes, so load it (README Step 4) rather than relying on a bare seed.
- **Auth on stage.** Endpoints marked `AUTHENTICATION NOT REQUIRED` are simplest but read as insecure to a DBA audience, so decide whether to show the auth path or name it as a follow-on.
