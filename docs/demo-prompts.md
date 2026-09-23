# Notes App demo prompts

Three prompts, run in order in one agent session, each pasted into the coding agent. Prompt 1 builds and seeds the data tier, and Prompt 2 builds the Textual client that runs on it. Prompt 3 is optional: it puts a REST Service in front of the schema and refactors the client to run in native or REST mode. The cue card, [`talk/demo-cue-card.md`](../talk/demo-cue-card.md), is the source of truth for these prompts, and this file and the README carry copies of them.

Run the agent from the repository root, where the layout keeps inputs apart from output:

- `docs/` and `research/` are the inputs the agent reads. They hold the product doc, the reference schema, and the seed fixture.
- The Textual app is generated at the repository root as a `notes_app` package with a `pyproject.toml`, laid out like any normal Python project.
- `working/` holds the working artifacts: the schema SQL, the REST DDL, the sandbox data directory, and a `working/RUN_LOG.md` that records each step.

Add the repository root to the MCP allowed paths so the agent can read `docs/` and `research/`, write `working/`, and create the app at the root. The sandbox is deployed with its data directory under `working/sandbox`, so everything the demo generates stays inside the repository.

The prompts name the artifact they want, number the steps, and say "in order" wherever the sequence is a hard constraint, because an agent lands the work more reliably that way. Each one points at a section of [`docs/notes_app-prd.md`](notes_app-prd.md) instead of restating it, so the product doc stays the single description of the app.

---

## Prompt 1: The data tier (schema, sandbox, and seed)

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Turn the data model in section 4 of docs/notes_app-prd.md into MariaDB DDL
   for the notes_app schema, saved as working/notes_app.sql. Only then compare
   it with research/notes_app.sql and report the differences, without changing
   your schema to match.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Seed it by loading research/synthetic_data.sql with db.execute_sql_script.
   The fixture is the data contract: if it fails, fix working/notes_app.sql and
   redeploy. Never edit the fixture.
4. List the tables, show the columns of note, and report each table's row count.
```

What to check. The tables match the six tables and one view in PRD section 4, and the seed reports 61 notes (48 active with 6 pinned, 7 archived, and 6 trashed), 6 notebooks, and 12 tags. The agent writes its schema before it reads `research/notes_app.sql`, so the difference report at the end of step 1 measures how closely the spec pins the design. Any drift it reports is a finding, and if the fixture forces a schema fix, that is the contract working as intended.

---

## Prompt 2: The application (the Textual client, native mode)

```text
Build the Textual app that docs/notes_app-prd.md specifies, in native mode only.
Skip RestDataSource and NOTES_APP_MODE (PRD build order step 7).

- Layout: a notes_app package with a __main__.py at the repository root, and a
  pyproject.toml with the dependencies and a notes-app console script. The repo
  gitignores notes_app/, so make sure the build backend still packages it. Keep
  working/ for the schema, run log and sandbox only.
- Stack: Python 3.11+, Textual, and mariadb Connector/Python against
  127.0.0.1:3310, bound to the columns in working/notes_app.sql.
- Features: the three-pane layout from section 7, with a status line naming
  native mode and the sandbox address, and every Must in section 6: notebooks
  with note counts; list, open, create and edit notes; pin and unpin; archive
  and restore; trash and restore.
- Config: host, port and password from the environment or .env. Write .env with
  password demo-pw, plus .env.example, at the repository root.

Verify both entry points against the sandbox, and record each command and its
result in working/RUN_LOG.md:
1. bin/notes-app (the committed launcher, which runs `python -m notes_app` from
   the root) starts the app and the seeded notes appear in the list.
2. The notes-app console script starts the app too.
```

What to check. Both entry points start the app. The left pane lists the six notebooks, the middle pane shows the seeded notes with the pinned ones at the top, and the status line reads `native` alongside the sandbox address. The console-script check matters because the repository gitignores `notes_app/`, and a build backend that honours `.gitignore` installs a package with no code in it, which `bin/notes-app` alone cannot detect.

---

## Prompt 3 (optional): The API tier and REST mode

```text
Continue against the sandbox on port 3310. Keep database files in working/, and
append each step's result to working/RUN_LOG.md. Complete the steps in order.

1. Build the REST Service from PRD section 5. Save the REST DDL to
   working/notes_app_rest.sql, but run it with db.execute_sql one statement at a
   time: the REST grammar is session state, and db.execute_sql_script gives each
   statement a fresh session.
   - Configure the REST metadata, then create service /notesApp and schema
     /notes mapping notes_app.
   - /note from notes_app.note: id @KEY; title, created_at and updated_at
     @SORTABLE; tag names flattened through note_tag with @UNNEST and
     read-only; @INSERT @UPDATE @DELETE.
   - /notebook from notes_app.notebook, with @INSERT @UPDATE.
   - /tag from notes_app.tag, read-only.
   - Mark every view AUTHENTICATION NOT REQUIRED. This is a local demo.
2. Confirm with SHOW REST SERVICES, SCHEMAS and VIEWS that every endpoint
   exists. Run SHOW CREATE REST VIEW /note and report whether the nested tag
   objects came back read-only. If they did not, log it and move on: do not
   patch the REST metadata. Publish with ALTER REST SERVICE /notesApp
   PUBLISHED, and log the SHOW REST output.
3. Add RestDataSource as the second section 9 DataSource backend beside
   NativeDataSource: httpx against the /notesApp service root, the section 5
   endpoints, and the paginated items/hasMore list shape. NOTES_APP_MODE
   selects the backend and defaults to native. Add the mode and service root
   URL to .env.example, and name the active mode and its address on the status
   line.
4. Run bin/notes-app in native mode to confirm nothing regressed, then with
   NOTES_APP_MODE=rest. No router is running, so the app must start, show the
   connection error on the status line, and stay up (PRD section 8). Log both
   runs.
```

What to check. `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. On mariadb-shell 26.9.3, expect the agent to report that `SHOW CREATE REST VIEW /note` shows the nested tag objects as writable: the shell stores them with the parent view's operations whatever the DDL says (PRD section 13). The endpoints are defined before any router serves them, because the metadata is the API definition. In REST mode the status line names `rest` and the service root, shows a connection error, and the app stays up.

---

## After the prompts

- **Where things land.** The app is a `notes_app` package at the repository root. The schema, the REST DDL, the sandbox data, and `RUN_LOG.md` sit under `working/`, and the inputs the agent read stay in `docs/` and `research/`.
- **REST mode needs a router.** Serving `/notesApp` over HTTP is a MySQL-Router-family binary bootstrapped against the metadata, and it is neither a shell command nor an MCP tool, so standing one up is out of band. Native mode is the reliable demo path, so switch to `NOTES_APP_MODE=rest` against live endpoints only once a router is running and verified.
- **The sandbox outlives the conversation.** Stop and delete it when done with `sandbox.stop(port=3310, password="demo-pw", sandbox_dir="working/sandbox")` and then `sandbox.delete(port=3310, sandbox_dir="working/sandbox")`.
