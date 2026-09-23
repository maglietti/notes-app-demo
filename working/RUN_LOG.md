# Rehearsal run log

## Act one (Prompt 1)

- Start: 2026-09-23 09:49:46
- Step 1: wrote working/notes_app.sql from PRD section 4 (6 tables, 1 view; CREATE OR REPLACE TABLE, utf8mb4_uca1400_ai_ci, UUID DEFAULT uuid_v7(), WITH SYSTEM VERSIONING on account and notebook, PERSISTENT default_flag, DESC index parts, FULLTEXT ft_note_title_body).
- Step 2: no sandbox on 3310; deployed MariaDB 11.8.9 (cached download) with sandbox_dir working/sandbox. Ran working/notes_app.sql via db.execute_sql_script: no errors, 7 warnings from DROP IF EXISTS on a fresh schema.
- Step 3: loaded research/synthetic_data.sql first time, no schema fix needed. Inserted 1 account, 6 notebooks, 12 tags, 61 notes, 82 note_tag rows.
- Step 4: tables account, attachment, note, notebook, note_tag, tag + view v_active_note. Row counts: account 1, notebook 6, tag 12, note 61 (48 active incl. 6 pinned, 7 archived, 6 trashed), note_tag 82, attachment 0, v_active_note 48.
- End: 2026-09-23 09:50:58

## Act two (Prompt 2)

- Start: 2026-09-23 09:50:58
- Built notes_app/ (__main__, app, config, datasource, native), pyproject.toml (hatchling with ignore-vcs so the gitignored package still ships; notes-app console script), .env (demo-pw) and .env.example. uv sync installed textual 8.2.8, mariadb 1.1.14, python-dotenv 1.2.3.
- Verify 1: `bin/notes-app` (tmux, 140x36): started; Notebooks pane lists Inbox (8), Community (7), Conferences (6), DevRel (12), Personal (6), Reading (9); Notes pane shows "★ Reset sandbox before rehearsal" first, then 7 more; status line "native · 127.0.0.1:3310 · Inbox / Active · 8 notes". Quit with q, exit 0.
- Verify 2: `uv run notes-app` (console script): same screen, exit 0. Built wheel contains all 6 notes_app/ modules.
- End: 2026-09-23 09:52:58

## Act three (Prompt 3)

- Start: 2026-09-23 09:52:58
- Step 1: wrote working/notes_app_rest.sql and ran its 6 build statements with db.execute_sql, one at a time, on one connection: CONFIGURE REST METADATA; CREATE OR REPLACE REST SERVICE /notesApp; REST SCHEMA /notes FROM notes_app; REST VIEW /note (@INSERT @UPDATE @DELETE; id @KEY; title/createdAt/updatedAt @SORTABLE; noteTag @UNNEST -> tag @UNNEST { name } flagged @NOINSERT @NOUPDATE @NODELETE); /notebook (@INSERT @UPDATE); /tag (read-only). All AUTHENTICATION NOT REQUIRED. No errors, no warnings.
- Step 2: SHOW REST SERVICES -> /notesApp ENABLED. SHOW REST SCHEMAS FROM SERVICE /notesApp -> /notes ENABLED. SHOW REST VIEWS FROM SERVICE /notesApp SCHEMA /notes -> /note, /notebook, /tag, all ENABLED.
- Step 2, read-back: SHOW CREATE REST VIEW /note returned the nested objects as `noteTag: notes_app.note_tag @INSERT @UPDATE @DELETE @UNNEST` and `tag: notes_app.tag @INSERT @UPDATE @DELETE @UNNEST`. The nested tag objects did NOT come back read-only (known mariadb-shell 26.9.3 behavior, PRD section 13). Logged, metadata not patched.
- Step 2, publish: ALTER REST SERVICE /notesApp PUBLISHED (1 row). SHOW CREATE REST SERVICE /notesApp now includes PUBLISHED.
- Step 3: added notes_app/rest.py (RestDataSource: httpx.AsyncClient, 5 s timeout, base http://127.0.0.1:8443/notesApp; GET/POST/PUT/DELETE on /notes/note, GET /notes/notebook and /notes/tag per section 5; every list read through items + hasMore paging). NOTES_APP_MODE selects the backend, default native. NOTES_APP_MODE and NOTES_APP_REST_URL added to .env.example; httpx 0.28.1 added to dependencies. Status line already names mode and address from the DataSource.
- Step 4, native: `bin/notes-app` -> 6 notebooks, pinned note first, status "native · 127.0.0.1:3310 · Inbox / Active · 8 notes". No regression. Quit with q, exit 0.
- Step 4, rest: `NOTES_APP_MODE=rest bin/notes-app` -> app started, empty panes, status "rest · http://127.0.0.1:8443/notesApp · error: GET http://127.0.0.1:8443/notesApp/notes/notebook: All connection attempts failed". App stayed up; quit with q, exit 0.
- Note: RestDataSource is untested against a live REST router (none running), so the JSON shapes it assumes for UUIDs, booleans and the unnested tag names are unverified.
- End: 2026-09-23 09:55:06
