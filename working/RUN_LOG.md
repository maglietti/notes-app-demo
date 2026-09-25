# Run log

## Step 1: Write the DDL (2026-09-25)

- Wrote `working/notes_app.sql` from section 4 of `docs/notes_app-prd.md` only. I did not read the reference `research/notes_app.sql`.
- Six tables in parent-first order (`account`, `notebook`, `tag`, `note`, `note_tag`, `attachment`) plus the view `v_active_note`. Every object is written as `notes_app.<name>`. There is no `USE`, no `SET` and no `INSERT`.
- **Keys:** `UUID NOT NULL DEFAULT UUID_v7()` primary keys. Foreign key columns are `UUID` too. `note_tag` has the composite primary key `(note_id, tag_id)` and no `id` column.
- **Timestamps:** `TIMESTAMP` with second precision, defaulting to `CURRENT_TIMESTAMP`. `note.updated_at` also has `ON UPDATE CURRENT_TIMESTAMP`.
- **Flags:** `BOOLEAN NOT NULL DEFAULT FALSE`.
- **Row history:** `account` and `notebook` use `WITH SYSTEM VERSIONING`. `note` has no row history.
- **`notebook.default_flag`:** `GENERATED ALWAYS AS (IF(is_default, 1, NULL)) PERSISTENT`, with the unique key `uq_notebook_one_default (account_id, default_flag)`.
- **`note` indexes:** `ix_note_notebook_updated (notebook_id, status, is_pinned DESC, updated_at DESC)`, `ix_note_account_status (account_id, status, updated_at DESC)` and `FULLTEXT ft_note_title_body (title, body)`.
- **Foreign keys:** all named `fk_<table>_<parent>`, with `ON DELETE CASCADE ON UPDATE CASCADE`.
- **Character set:** the schema and every table use `utf8mb4` / `utf8mb4_uca1400_ai_ci`, the 11.8 default.
- **Reruns:** `DROP VIEW IF EXISTS` runs first, then one `DROP TABLE IF EXISTS` that lists the tables child-first. The foreign keys would otherwise block `CREATE OR REPLACE` on parent tables. All tables are then created with `CREATE OR REPLACE TABLE`.

## Step 2: Deploy the sandbox and run the DDL

- Port 3310 was closed, so no sandbox was running.
- `sandbox.deploy(port=3310, password="demo-pw", sandbox_dir="working/sandbox", server_version="11.8")` started MariaDB 11.8.9.
- `db.connect("mariadb://root@127.0.0.1:3310")` succeeded.
- `db.execute_sql_script(file_path=...)` was **refused**, because the MCP server's allow-list covers neither `working/` nor `research/`. I did not change the MCP setup. Instead I passed the script text inline with `db.execute_sql_script(sql_script=...)`. The statements matched the file, with its comments left out.
- Result: 11 of 11 statements succeeded. The only messages were the expected first-run notes from the two DROPs (4092 unknown view, 1051 unknown table).

## Step 3: Load the fixture

- I loaded `research/synthetic_data.sql` verbatim (inline, for the same allow-list reason) with `db.execute_sql_script`.
- All 5 INSERTs succeeded with no errors or warnings. Rows inserted: 1 account, 6 notebooks, 12 tags, 61 notes, 82 note_tag links.
- The fixture accepted the schema as written, so no DDL fix or redeploy was needed.
- `git status research/` is clean, so the fixture was not edited.

## Step 4: Check the result

- **Tables:** account, attachment, note, notebook, note_tag, tag. **View:** v_active_note.
- **Columns of `note`:** id uuid (default uuid_v7()), notebook_id uuid, account_id uuid, title varchar(255) default '', body longtext default '', status enum('active','archived','trashed') default 'active', is_pinned tinyint(1) default 0, created_at timestamp default current_timestamp(), updated_at timestamp default current_timestamp() on update current_timestamp(). All columns are NOT NULL.
- **Row counts:** account 1, notebook 6, tag 12, note 61, note_tag 82, attachment 0. The view `v_active_note` returns 48 rows.
- **Notes by status:** 48 active (6 pinned), 7 archived, 6 trashed. This matches the fixture header.

## Prompt 2: Build the Textual app in native mode (2026-09-25)

### What I built

- **Files at the repository root:** `pyproject.toml`, `uv.lock`, `.env` (password `demo-pw`), `.env.example` (password left blank), and the `notes_app/` package. The package holds `__main__.py`, `app.py`, `screens.py`, `app.tcss`, `datasource.py`, `native.py`, `models.py` and `config.py`. Nothing app-related was written to `working/`.
- **Packaging:** the build backend is `setuptools.build_meta` with `packages = ["notes_app"]` and no VCS plugin. Setuptools does not read `.gitignore`, so the gitignored `notes_app/` still ships. Hatchling and setuptools-scm do read it, and would build an empty wheel. The console script is `notes-app = notes_app.__main__:main`.
- **Dependencies:** `textual>=0.80` (resolved to 8.2.8), `mariadb>=1.1,<2` (1.1.14, built against Homebrew Connector/C) and `python-dotenv`. `uv` picked Python 3.11.11.
- **Data access:** `datasource.py` defines the abstract `DataSource` (PRD section 9). `NativeDataSource` implements it with Connector/Python, using `?` parameters, `autocommit=True`, connect/read/write timeouts and one reconnect on a lost link.
  - Every failure becomes a `DataSourceError`. The UI shows it in red on the status line and keeps the last good view.
  - Queries use the columns from `working/notes_app.sql`.
  - The note list is ordered `is_pinned DESC, updated_at DESC`, which matches `ix_note_notebook_updated`.
  - Search runs `MATCH(title, body) AGAINST (...)` on `ft_note_title_body`.
  - Create uses `INSERT ... RETURNING id`, because the ids are server-generated `UUID_v7()`.
  - Emptying the trash runs `DELETE ... WHERE status='trashed'` for the current notebook. It is the app's only DELETE.
- **UI:** three panes (notebooks with their active-note counts and a `▸` on the default, a note list with `★` on pinned notes, and the rendered Markdown with its tags), a status line, and a footer.
  - The status line shows `native · mariadb://root@127.0.0.1:3310/notes_app · <notebook> · <view> · N notes`, followed by any message.
  - Keys from the PRD: `n e p a d u / ? tab q`. I added `1/2/3` to switch between the Active, Archive and Trash views, `x` to empty the trash (asks for confirmation) and `r` to reload.
  - Edit mode is a full-screen editor where `ctrl+s` saves and `escape` cancels.
  - An empty list shows a message naming the seed fixture.
- **Config:** `NOTES_APP_DB_HOST/PORT/USER/PASSWORD/NAME` and `NOTES_APP_ACCOUNT_EMAIL` are read from the environment first, then from `.env` via `find_dotenv(usecwd=True)`.

### Verification

| # | Command | Result |
|---|---------|--------|
| 0 | `uv sync` | Installed 13 packages, including `notes-app==0.1.0`, `mariadb==1.1.14` and `textual==8.2.8`. |
| 0 | `uv run python /tmp/pilot_notes.py` (a scratch Textual Pilot script, not kept in the repo) | Every Must passed against the sandbox. Notebooks: Inbox 8 (default), Community 7, Conferences 6, DevRel 12, Personal 6, Reading 9. Inbox lists 8 notes with the pinned note first. The test created a note in DevRel, edited it (`updated_at` moved 13:21:29 → 13:21:31), pinned and unpinned it, archived and un-archived it, trashed and restored it, trashed it again, and emptied the trash ("deleted 1 note permanently"). Search `replication` returned 1 match; `?` opened the help screen. The test only touched the note it created. |
| 0 | Seed check after the test | Notes 48 active (6 pinned) / 7 archived / 6 trashed, note_tag 82. Unchanged. |
| 0 | `NOTES_APP_DB_PORT=3399 uv run python /tmp/pilot_err.py` | The app stayed up. The status line reads `error: ... Can't connect to server on '127.0.0.1'`. This also shows the environment winning over `.env`. |
| 1 | `./bin/notes-app` in a 150x40 tmux pane (the launcher runs `uv run python -m notes_app`) | Started. The notebooks pane lists all six notebooks; the notes pane shows the 8 Inbox notes, `★ Reset sandbox before rehearsal` first; the note pane renders it with the tags `talk todo`. Status line: `native · mariadb://root@127.0.0.1:3310/notes_app · Inbox · Active · 8 notes`. `q` quit with EXIT=0. |
| 2a | `uv build --wheel`, then `uv pip install` the wheel into a fresh `/tmp/na-venv` | The wheel contains all 9 `notes_app/` files and `entry_points.txt` with `notes-app = notes_app.__main__:main`. Run from `/tmp`, the import resolves to `site-packages/notes_app`, so the packaging does not depend on the source tree. |
| 2b | `/tmp/na-venv/bin/notes-app` (non-editable install), run from the repository root in tmux | Started. It showed the same Inbox list, pinned note first, and the same native status line. `q` quit with EXIT=0. |
| 2c | `.venv/bin/notes-app` (the project venv from `uv sync`, the same script `uv run notes-app` runs) | Started with the same result. EXIT=0. |

- **Cleanup:** removed the `build/` and `notes_app.egg-info/` directories that the wheel build left behind, and the scratch venv and dist in `/tmp`. `git status --short` is clean because every generated file is gitignored.
