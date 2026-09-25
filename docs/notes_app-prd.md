# Notes App: Product Requirements Document

**Version:** 2.0
**Date:** 2026-09-25
**Owner:** Michael Aglietti

## 1. Purpose

The Notes App is a terminal client for the `notes_app` schema on MariaDB 11.8 LTS. It reads and writes notebooks, notes, and tags. By default it connects to the tables directly through MariaDB Connector/Python, and in REST mode it calls the MariaDB REST Service at `/notesApp` instead.

This document is the specification a coding agent builds from. Sections 2 to 10 say what to build, section 11 says how to check it, and section 12 gives the build order. Requirements carry IDs (`FR-`, `API-`, `NFR-`, `PK-`, `CF-`, `AC-`) so a prompt can name the ones it wants. Each run's prompt chooses which part of the document to build, and where to write the output.

## 2. Stack

| Axis        | Choice                                                                                                   |
| ----------- | -------------------------------------------------------------------------------------------------------- |
| Connection  | Native by default, through MariaDB Connector/Python. REST mode calls the REST Service at `/notesApp`.   |
| Interface   | A terminal UI, with no browser and no build step.                                                        |
| Language    | Python 3.11 or newer, with Textual.                                                                      |
| HTTP client | httpx, in REST mode only. It is async and fits Textual's event loop, whereas a blocking client freezes the UI. |

## 3. Users and scope

The app runs as one seeded account, `michael.aglietti@mariadb.com`, which the fixture creates. The schema supports many accounts, but the app does not need to.

- **In scope:** notebooks, notes, tags, search, pin, archive, and trash and restore.
- **Out of scope:**
  - Account sign-up and password login. The app uses the seeded account.
  - Attachments. The schema stores object-storage pointers, but there is no object store, so the app neither reads nor writes attachments.
  - REST authentication. Every endpoint is `AUTHENTICATION NOT REQUIRED` (section 5). A production build would add an MRS auth app, a REST role scoped per endpoint, a test user, and a login screen that stores the session token, as the `mariadb-rest-service-authorization` skill describes.
  - Note history. Only `account` and `notebook` keep row history (section 4). A history view would first need an `ALTER TABLE` that adds history to `note`.

## 4. Data model

Six tables and one view. Native mode binds to these exact names, so this section is the specification: a schema generated from it must match it in names, types, defaults, keys, and index names.

It deliberately leaves the MariaDB grammar to the agent and its skills. Each entry says what a column or table must do, not the syntax that does it, so the idioms in a generated schema are the agent's own work rather than a copy of this document.

### 4.1 Conventions

These apply to every object unless a table below says otherwise.

- **Target and schema.** MariaDB 11.8 LTS. A `notes_app` schema in `utf8mb4` with the server's current default Unicode collation, and the same for every table.
- **Rerunnable.** Running the file again replaces each table rather than failing because it already exists.
- **Primary keys.** Every entity table has an `id` primary key: a UUID the server generates, in the database's native UUID type, in time order so new rows sort last and ids do not leak row counts. The join table `note_tag` is the only exception: its key is `(note_id, tag_id)`, and it has no `id` column. Foreign key columns use the same type as the key they reference.
- **Timestamps.** Second precision, defaulting to the time the row is written. Every table has `created_at`, except `note_tag`, which has `added_at` instead. Only `note` has `updated_at`, and the server advances it on every update.
- **Flags.** Required booleans that default to false.
- **Foreign keys.** Every foreign key cascades both deletes and updates, and is named `fk_<table>_<parent>`.
- **Script shape.** Fully qualify every object as `notes_app.<name>`, and order the tables parent-first: `account`, `notebook`, `tag`, `note`, `note_tag`, `attachment`. Rely on no session state: no `USE`, and no `SET` block that saves and restores session variables. This lets `db.execute_sql_script` load the file statement by statement. The file is pure DDL with no `INSERT`s, because data comes from the fixture, [`research/synthetic_data.sql`](../research/synthetic_data.sql).

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

**`note`** holds the notes. It does not keep row history (section 3).

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

The REST Service has this shape:

``` sql
CONFIGURE REST METADATA;
CREATE REST SERVICE  /notesApp;
CREATE REST SCHEMA   /notes FROM `notes_app`;
CREATE REST VIEW     /note     AS notes_app.note     { ... noteTag @UNNEST { tag @UNNEST { name } } }
CREATE REST VIEW     /notebook AS notes_app.notebook { ... }
CREATE REST VIEW     /tag      AS notes_app.tag      { ... }
```

- **API-1.** Service `/notesApp`, with schema `/notes` mapping the `notes_app` schema.
- **API-2.** View `/note` from `notes_app.note`: `id` is `@KEY`; `title`, `created_at`, and `updated_at` are `@SORTABLE`; the note's tag names are nested through `note_tag` with `@UNNEST` and are read-only; the view allows `@INSERT @UPDATE @DELETE`.
- **API-3.** View `/notebook` from `notes_app.notebook`, allowing `@INSERT @UPDATE`.
- **API-4.** View `/tag` from `notes_app.tag`, read-only.
- **API-5.** Every view is marked `AUTHENTICATION NOT REQUIRED`. The clause must be explicit, because a view created without it defaults to `AUTHENTICATION REQUIRED`.
- **API-6.** The service is published.

Endpoints the client calls in REST mode, served under the service root:

| Method + path                         | Use                                                        |
| ------------------------------------- | ---------------------------------------------------------- |
| `GET /notesApp/notes/notebook`        | List notebooks for the sidebar.                            |
| `GET /notesApp/notes/note?q=<filter>` | List notes, filtered by notebook, status or full text.     |
| `GET /notesApp/notes/note/<id>`       | Load one note with its tags (flattened by `@UNNEST`).      |
| `POST /notesApp/notes/note`           | Create a note.                                             |
| `PUT /notesApp/notes/note/<id>`       | Update title, body, status or pin.                         |
| `DELETE /notesApp/notes/note/<id>`    | Hard delete. The app prefers `status = trashed` over this. |
| `GET /notesApp/notes/tag`             | List tags for the tag filter.                              |

`@KEY` on the note `id` is what makes the row-level `GET`, `PUT`, and `DELETE` work, `@SORTABLE` drives ordering, and tags arrive embedded in each note through `@UNNEST`, so the list view needs one request rather than three.

**Tags are read-only through `/note`.** The tag names embedded in a note are for display, and a write to `/note` changes only the note's own columns, never `note_tag` or `tag`. This must be explicit, because the server gives nested objects the parent view's write operations unless they are switched off, so a writable `/note` would otherwise make its embedded tags writable too, even with `/tag` read-only. On mariadb-shell 26.9.3 the metadata does not keep the nested flags (section 13). The client never writes tags through `/note`, so the app is unaffected.

Two response shapes the client must handle:

- **List responses are paginated.** The REST Service wraps a collection in an `items` array alongside `limit`, `offset`, `count`, `hasMore`, and `links`, so even with a handful of notes the client reads `items` and honours `hasMore` rather than assuming a bare array.
- **Create carries the owning keys.** `note.notebook_id` and `note.account_id` are `NOT NULL` foreign keys, so a `POST /note` must include the current notebook id and the seeded account id, and the UI supplies both from context.

## 6. Functional requirements

Priority uses Must, Should, and Could.

**Notebooks**

- **FR-1** (Must) List notebooks, mark the default, and show a note count per notebook.
- **FR-2** (Should) Create and rename a notebook.
- **FR-3** (Could) Delete a notebook, where `ON DELETE CASCADE` removes its notes, so confirm first.

**Notes**

- **FR-4** (Must) List active notes in the selected notebook, pinned first and newest next, backed by `ix_note_notebook_updated`.
- **FR-5** (Must) Open a note and render its Markdown `body`.
- **FR-6** (Must) Create a note in the current notebook.
- **FR-7** (Must) Edit title and body, save, and see `updated_at` change.
- **FR-8** (Must) Pin and unpin.
- **FR-9** (Must) Archive and un-archive, moving `status` between active and archived.
- **FR-10** (Must) Trash and restore, moving `status` between active and trashed, with an emptied-trash view, and emptying the trash is the only hard `DELETE` the app issues.
- **FR-11** (Should) Full-text search across title and body, backed by `ft_note_title_body`.

**Tags**

- **FR-12** (Should) Show a note's tags and filter the list by one tag.
- **FR-13** (Could) Create a tag and attach or detach it from a note.

**Cross-cutting**

- **FR-14** (Must) A visible status line naming the current data mode (`native` or `rest`) and its address: the database host and port in native mode, or the service root in REST mode.
- **FR-15** (Should) An empty state that names the seeded sample data, so a fresh sandbox with no data reads correctly.

## 7. TUI layout and interaction

A three-pane layout, Textual widgets:

``` text
┌ Notebooks ─┬ Notes ───────────────┬ Note ─────────────┐
│ ▸ Inbox    │ ★ Optimizer trace    │ # Optimizer trace │
│   DevRel   │   Community call     │ optimizer_trace…  │
│            │   Travel checklist   │                   │
├────────────┴──────────────────────┴───────────────────┤
│ native · 127.0.0.1:3310 · 3 notes                     │
└───────────────────────────────────────────────────────┘
```

- **Left:** the notebook list, where Enter selects a notebook and filters the middle pane.
- **Middle:** the note list for the selected notebook and status view, where a star marks a pinned note and `/` opens search.
- **Right:** the selected note, its Markdown rendered read-only, with `e` to edit.
- **Bottom:** the status line (FR-14), showing the data mode, its address, and the note count.
- **Footer:** a footer below the status line lists the key bindings, and `?` opens a help screen.

Key bindings are `n` for a new note, `e` to edit, `p` to pin, `a` to archive, `d` to trash, `u` to restore, `/` to search, `?` for help, `tab` to cycle panes, and `q` to quit. Edit mode is a full-screen Markdown text area with `ctrl+s` to save.

## 8. Non-functional requirements

- **NFR-1 Reliability.** Every database and network call carries a timeout and a visible error state. A failed call never crashes the app: it shows the error on the status line and keeps the last good view.
- **NFR-2 Performance.** List views return in one request, and the target is a visible paint under 200 ms against a local sandbox.
- **NFR-3 Startup.** There is no build step. Section 10 sets the entry points and configuration.
- **NFR-4 Portability.** It runs on macOS and Linux, the two platforms the sandbox supports, on Python 3.11 or newer.
- **NFR-5 Security.** The sandbox listens on all interfaces with a `root@'%'` account and no TLS, so treat it as throwaway and never point the app at a real database. The app holds no long-lived credential beyond the sandbox password in local config.

## 9. Architecture

``` text
Textual UI  ─▶  DataSource (interface)
                   ├─ NativeDataSource  (default, mariadb Connector/Python)
                   └─ RestDataSource    (optional, httpx → REST Service)
```

A single `DataSource` interface backs two implementations, and the UI never knows which one it holds.

- **`NativeDataSource`** is the default. It runs the app's queries through MariaDB Connector/Python against the sandbox, binding to the schema's actual columns, so the client starts with no REST server.
- **`RestDataSource`** calls the `/notesApp` endpoints from section 5 and handles the paginated list shape. It is selected with `NOTES_APP_MODE=rest` (CF-4). Serving the endpoints over HTTP needs a REST router, which this build does not provide, so the mode stays off by default.

The status line names the active mode (FR-14), so the user always knows which backend is live.

## 10. Packaging and configuration

- **PK-1.** The app is a `notes_app` package at the repository root with a `__main__.py`, runnable as `python -m notes_app` from the root. The committed `bin/notes-app` launcher relies on this.
- **PK-2.** A `pyproject.toml` at the root declares the dependencies and a `notes-app` console script.
- **PK-3.** The repository gitignores `notes_app/`, so the build backend must still include the package. A backend that honours `.gitignore` installs the project with no code in it.
- **CF-1.** Configuration comes from environment variables or one `.env` file at the repository root, and a variable set in the environment wins over `.env`.
- **CF-2.** Native mode reads the database host (default `127.0.0.1`), port (default `3310`), and password from that configuration.
- **CF-3.** The build writes a `.env` with the sandbox password `demo-pw`, plus a `.env.example` listing every setting, both at the repository root.
- **CF-4.** REST mode adds two settings, both listed in `.env.example`: `NOTES_APP_MODE`, which selects `native` or `rest` and defaults to `native`, and the service root URL, which defaults to `http://127.0.0.1:8443/notesApp`.

## 11. Acceptance criteria

Each run checks the criteria for the part it builds, and reports each one as passed or failed with the evidence.

**Data tier**

- **AC-D1.** The DDL runs on MariaDB 11.8 through `db.execute_sql_script` with no errors.
- **AC-D2.** The schema holds the six tables and one view from section 4, with those names.
- **AC-D3.** The fixture, [`research/synthetic_data.sql`](../research/synthetic_data.sql), loads with no edits. The fixture is the data contract: when it fails, the schema changes, never the fixture.
- **AC-D4.** After the load, the row counts are 1 account, 6 notebooks, 12 tags, and 61 notes: 48 active (6 of them pinned), 7 archived, and 6 trashed.

**Application (native mode)**

- **AC-A1.** `bin/notes-app` starts the app from the repository root, and the seeded notes appear in the list.
- **AC-A2.** The `notes-app` console script, installed from `pyproject.toml`, starts the app too. This catches the packaging failure in PK-3, which `bin/notes-app` alone cannot detect.
- **AC-A3.** The left pane lists the six notebooks with their note counts, and marks Inbox as the default.
- **AC-A4.** The middle pane lists the selected notebook's active notes, pinned first and newest next.
- **AC-A5.** The status line reads `native` next to `127.0.0.1:3310`.

**REST tier and REST mode**

- **AC-R1.** `SHOW REST SERVICES`, `SHOW REST SCHEMAS`, and `SHOW REST VIEWS` list `/notesApp`, `/notes`, and the `/note`, `/notebook`, and `/tag` views.
- **AC-R2.** `SHOW CREATE REST VIEW /note` is read back, and the report says whether the nested tag objects are read-only. On mariadb-shell 26.9.3 they are not (section 13). Report the mismatch and do not patch the REST metadata.
- **AC-R3.** The service is published (API-6).
- **AC-R4.** In native mode, the app still meets AC-A1 and AC-A5.
- **AC-R5.** With `NOTES_APP_MODE=rest` and no router running, the app starts, the status line names `rest` and the service root, it shows the connection error, and it stays up (NFR-1).

## 12. Build order

1. The `DataSource` interface and the DTOs the UI works with.
2. `NativeDataSource` first, because it needs no REST server, so the UI can be built and tested against a plain sandbox.
3. The Textual three-pane shell: the notebook list, the note list, the note view, and the status line.
4. The read paths: list notebooks, list notes, and open a note with its tags.
5. The write paths: create, edit, pin, archive, trash, and restore.
6. Full-text search.
7. `RestDataSource` as the optional REST-mode backend, selected by `NOTES_APP_MODE=rest` and left off by default, since it needs a router.
8. A pass over the section 11 criteria on a fresh sandbox.

## 13. Risks and open questions

- **Writing tags through the `@UNNEST` view is unproven.** The note view flattens tags for reading, but the REST Service's support for writing nested related rows through a data mapping view is limited. Attaching or detaching a tag may need a separate `/noteTag` endpoint or a direct write, so resolve this before building FR-13.
- **Nested read-only flags are dropped (mariadb-shell 26.9.3).** The nested `@NOINSERT @NOUPDATE @NODELETE` flags on `/note` parse, but the shell saves each nested object with the parent view's operations, so `SHOW CREATE REST VIEW /note` shows `noteTag` and `tag` with `@INSERT @UPDATE @DELETE` whatever the DDL says. No DDL spelling avoids it, and moving the flags before `@UNNEST` is a syntax error. Until a fixed shell ships, report the mismatch instead of patching the metadata.
