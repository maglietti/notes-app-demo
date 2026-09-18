# Notes App demo prompts

Three prompts, run in order, each pasted into the coding agent. Prompt 1 builds the data tier, Prompt 2 puts the REST tier in front of it, and Prompt 3 builds the Textual client that runs on the result.

Run the agent from the repository root, where the layout keeps inputs apart from output:

- `docs/` and `research/` are the inputs the agent reads, holding the design and the reference schema.
- The Textual app is generated at the repository root as a `notes_app` package with a `pyproject.toml`, laid out like any normal Python project.
- `working/` holds the working artifacts: the schema SQL, the REST DDL, the sandbox data directory, and a `working/RUN_LOG.md` that records each step.

Add the repository root to the MCP allowed paths so the agent can read `docs/` and `research/`, write `working/`, and create the app at the root. The sandbox is deployed with its data directory under `working/sandbox`, so everything the demo generates stays inside the repository.

The prompts name the artifact they want, number the steps, and say "in order" wherever the sequence is a hard constraint, because an agent lands the work more reliably that way.

Prompt 1 designs the schema from a short prompt, the way the talk shows it, and the result is checked afterward against `research/notes_app.sql`, the canonical schema frozen from an earlier run. That file is an oracle, never an input to the prompt.

Expect some drift on a free run, since the skill may name the owner table `user` rather than `account`, or leave out the `attachment` table. The REST views in Prompt 2 and the client in Prompt 3 are built for the canonical names (`account`, `notebook`, `note`, `tag`, `note_tag`, and `attachment`), so keep the free design for the talk beat and switch to the app track when the app has to run on the schema. The app track deploys `research/notes_app.sql` and loads the sample data from `research/synthetic_data.sql` as a direct load rather than a prompt, so the API and the client run on a known, populated schema. The README's Step 4 has the load command.

---

## Prompt 1: Infrastructure (schema and sandbox)

```text
Work in this repository and complete every step in order. Put the files you create
in the working/ directory, and append a short record of each step to
working/RUN_LOG.md as you go.

1. Create a MariaDB database schema named notes_app for a note-taking app and
   store it in working/notes_app.sql.

2. Deploy a sandbox instance on port 3310 with root password demo-pw and its data
   directory at working/sandbox, connect to it, and run working/notes_app.sql via
   the MCP server.

3. List the tables you created and show me the columns of the note table.
```

Check against the reference. Compare `working/notes_app.sql` with `research/notes_app.sql`, using the reference to confirm the run reached the MariaDB idioms rather than to demand an exact match. Expect `CREATE OR REPLACE TABLE`, `utf8mb4`, system versioning on the owner and notebook tables, a `FULLTEXT` index over the note title and body, and `UUID` keys from `UUID_v7()`, since the ids here should not leak row counts. Naming that drifts from the reference is a finding for the check, not a failure of the skill.

---

## Prompt 2: REST API (the tier the talk is about)

```text
Continue in this repository, against the sandbox on port 3310. Write any files
you create into working/, and keep appending each step's result to
working/RUN_LOG.md.

Put a MariaDB REST Service in front of the notes_app schema. Save the REST DDL you
run to working/notes_app_rest.sql as a record, but run it through db.execute_sql
one statement at a time, not db.execute_sql_script, because the REST grammar is
session state and each script statement runs in a fresh session.

In order:

1. Configure the REST metadata for the server.

2. Create a REST service with request path /notesApp, then a REST schema /notes
   that maps the notes_app database schema into it.

3. Add a REST data mapping view for each table:
   - /note, from notes_app.note. Mark the id column @KEY. Make title,
     created_at and updated_at @SORTABLE. Flatten the note's tags into the
     document with @UNNEST through note_tag so one request returns a note with
     its tag names. Allow create, read, update and delete with @INSERT @UPDATE
     @DELETE.
   - /notebook, from notes_app.notebook, with @INSERT @UPDATE for create and
     update.
   - /tag, from notes_app.tag, read-only.
   Do not add AUTHENTICATION REQUIRED to any view. This is a local demo and the
   client reads the endpoints without a router auth app.

4. Verify with the SHOW REST commands (SHOW REST SERVICES, SCHEMAS, VIEWS) that
   /notesApp exists with an endpoint for every table, then publish the service
   with ALTER REST SERVICE /notesApp PUBLISHED. Record the SHOW REST output in
   working/RUN_LOG.md.
```

What to check. `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. The endpoints are defined before any router serves them, because the metadata is the API definition.

---

## Prompt 3: Front end (the Textual client)

```text
Read docs/notes_app-prd.md and build the Textual application it specifies. Build
the app at the repository root as a notes_app package with a pyproject.toml, the
way a normal Python project is laid out. Do not put the app under working/; that
directory is only for the schema, the REST DDL and the sandbox. Hold to these
constraints:

- Python 3.11 or newer. Textual for the UI, httpx for REST calls, the mariadb
  Connector/Python for the native fallback.
- Implement the DataSource interface from the PRD with two backends:
  RestDataSource (httpx against the /notesApp service root) and NativeDataSource
  (mariadb connector against 127.0.0.1:3310). Select the backend with the
  NOTES_APP_MODE environment variable, and default to native so the app runs
  without a REST router.
- Build the three-pane layout and status line from section 7, and every Must
  feature from section 6: list notebooks with a per-notebook note count; list,
  open, create and edit notes; pin and unpin; archive and restore; trash and
  restore; and the status line naming the active data mode and service root.
- Read configuration (mode, service root URL, sandbox host, port and password)
  from the environment or a .env file, and ship a .env.example. Keep .env and
  .env.example at the repository root with the app.
- Make it runnable as `python -m notes_app` from the repository root: put the
  source in a notes_app package with a __main__.py, and add a pyproject.toml with
  the dependencies and a notes-app console script. A committed launcher at
  bin/notes-app already runs `python -m notes_app` from the root, so satisfy that
  contract rather than inventing another entry point.

Then run it in native mode with bin/notes-app against the sandbox on port 3310,
confirm the seeded notes from the schema appear in the list, and record the run
command and the result in working/RUN_LOG.md.
```

What to check. The app starts, the left pane lists the six notebooks, and the middle pane shows the seeded notes with the pinned ones at the top. The status line reads `native` alongside the sandbox address.

---

## After the three prompts

- **Where things land.** The app is a `notes_app` package at the repository root, the schema and REST DDL and sandbox data and `RUN_LOG.md` sit under `working/`, and the inputs the agent read stay in `docs/` and `research/`.
- **REST mode needs a router.** Serving `/notesApp` over HTTP is a MySQL-Router-family binary bootstrapped against the metadata, and it is neither a shell command nor an MCP tool, so standing one up is out of band. Native mode is the reliable demo path, so switch to `NOTES_APP_MODE=rest` only once a router is running and verified.
- **The sandbox outlives the conversation.** Stop and delete it when done with `sandbox.stop(port=3310, password="demo-pw", sandbox_dir="working/sandbox")` and then `sandbox.delete(port=3310, sandbox_dir="working/sandbox")`.
