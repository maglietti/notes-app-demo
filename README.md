# Notes App demo

This repository holds the runbook for a live demo. One coding agent, handed the MariaDB skills and a live database over the Model Context Protocol, designs a note-taking schema, deploys a throwaway MariaDB server, runs the schema against it, and puts a REST API in front of it, all from a handful of prompts. A Textual client, built on the Python terminal-UI framework, then runs on the result, so the work the agent did is something you can open and use rather than just read.

The talk it supports is *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*, in the Databases track at All Things Open 2026. The application design lives in [`docs/notes_app-prd.md`](docs/notes_app-prd.md), and the three prompts that drive the run are collected in [`docs/demo-prompts.md`](docs/demo-prompts.md), inlined below at the step where each one belongs.

## Repository layout

The repository tracks the instructions, and nothing else. This is the committed tree, the part you read and run:

```text
.
├── README.md                  this runbook
├── bin/
│   └── notes-app              stable launcher for the generated app
├── docs/                      inputs the agent reads
│   ├── notes_app-prd.md       the client design
│   ├── demo-prompts.md        the three prompts on their own
│   ├── stack-layering.md      how the pieces relate
│   └── decisions.md           the choices behind the demo
└── research/                  inputs the agent reads
    ├── notes_app.sql          the canonical schema (frozen from an agent run)
    ├── synthetic_data.sql     test data for the canonical schema
    ├── agent-security-note.md the blocked mass-delete talking point
    └── notes_app-er.*         the schema ER diagram
```

Everything a run generates is gitignored, so `git clean -fdx` removes all of it:

```text
notes_app/                                    the Textual app package        (Prompt 3)
pyproject.toml, uv.lock, .env, .env.example   the app project and config (Prompt 3)
working/                                      schema, REST DDL, RUN_LOG, sandbox datadir (Prompts 1-2)
.venv/                                        the app's virtual environment
```

The repository is the project, not the output. It holds the instructions for generating the app, while the app itself and every prompt output stay ignored, so a run never dirties the tree and `git clean -fdx` returns it to a clean, re-runnable state. During a run the agent reads from `docs/` and `research/`, builds the `notes_app` package at the repository root, and writes its working files under `working/`.

## The stack, in three layers

| Layer                   | What it is                                                                          | You install it? |
| ----------------------- | ----------------------------------------------------------------------------------- | --------------- |
| `ai-plugins`            | The harness plugin. Ships 82 MariaDB skills and wires the MCP server.               | Yes             |
| `mariadb-shell`         | The host runtime. Loads the plugins and exposes the MCP server.                     | Automatic       |
| `mariadb-shell-plugins` | The tool implementations the shell loads: `mcp_plugin`, `mrs_plugin`, `msm_plugin`. | Automatic       |

You install only the top layer. Installing `ai-plugins` pulls down `mariadb-shell` and its bundled plugins the first time it runs, so the tools you call (`db.*`, `sandbox.*`, `msm.*`, and the REST grammar) all come from the bottom layer with no separate install. For how the three layers fit together, see [`docs/stack-layering.md`](docs/stack-layering.md).

## What you need

- A coding-agent harness. This runbook uses Claude Code.
- macOS or Linux.
- Nothing else. The sandbox brings its own MariaDB Server when the machine has none, with no Docker and no root.

## Step 1: Install the ai-plugins

In Claude Code:

```text
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

On first start the plugin downloads and extracts the `mariadb-shell` package, which takes about a minute and happens only once.

Confirm the skills loaded by asking for something only a skill knows:

```text
Write a CREATE TABLE for a product catalogue, MariaDB style.
```

The tell is not the primary key type, because the skill picks that by domain: an `INT UNSIGNED AUTO_INCREMENT` surrogate for a catalogue, or a `UUID` with `UUID_v7()` where the id should not leak row counts, the way the `notes_app.account` table does. What gives the skill away are the MariaDB-only constructs that generic or MySQL SQL never emits. Look for `CREATE OR REPLACE TABLE`, `utf8mb4` in place of the `utf8` alias, and at least one of `WITH SYSTEM VERSIONING`, a `COMPRESSED` text column, a `PERSISTENT` generated column, an `INVISIBLE` column, a descending index, or `PAGE_COMPRESSED`. When the DDL carries those, the skill loaded.

## Step 2: Configure the MCP server

The server starts out allowed to reach nothing, so point it at this repository root, which lets it read `docs/` and `research/`, write `working/`, and reach the sandbox it deploys:

```bash
mariadb-shell -- mcp setup
```

If `mariadb-shell` is not on your `PATH`, use the copy the launcher installed at `~/.local/bin/mariadb-shell`. When the setup walks you through it, add this repository's root directory to the allowed paths. You do not need to configure a database connection, because the sandbox registers its own automatically.

## Step 3: Build the data tier

Run the agent from the repository root and give it Prompt 1. This is the authentic design beat, where a short prompt is all the agent gets and the schema is its own work. It writes `working/notes_app.sql`, deploys a sandbox on port 3310, runs the schema against it, reads the tables back, and logs each step to `working/RUN_LOG.md`.

```text
Work in this repository and complete every step in order. Put the files you create
in the working/ directory, and append a short record of each step to
working/RUN_LOG.md as you go.

1. Create a MariaDB database schema named notes_app for a note-taking app and
   store it in working/notes_app.sql.

2. Deploy a MariaDB 11.8 sandbox instance on port 3310 with root password demo-pw
   and its data directory at working/sandbox, connect to it, and run
   working/notes_app.sql via the MCP server.

3. List the tables you created and show me the columns of the note table.
```

**Check against the reference.** Compare `working/notes_app.sql` against `research/notes_app.sql`, the canonical schema frozen from an earlier run. That file is the oracle, never an input to the prompt, so use it to confirm the run reached for the MariaDB idioms: `CREATE OR REPLACE TABLE`, `utf8mb4`, system versioning on the owner and notebook tables, a `FULLTEXT` index over the note title and body, and `UUID` keys generated by `UUID_v7()`. Expect some drift on a free run, such as an owner table named `user` instead of `account`, or a missing `attachment` table. Drift is a finding for the check, not a failure of the skill.

**Reproducible app track.** The REST tier and the client are built for the canonical schema, so Step 4 deploys `research/notes_app.sql` and loads the sample data. That way the API and the app run on the schema they were written for, whatever this particular design run produced.

## Step 4: Seed test data

For the reproducible app track, put the canonical schema and its sample data on the sandbox so the API and the client have something real to serve. This step is a direct load rather than a design prompt.

```text
Deploy research/notes_app.sql onto the sandbox on port 3310, replacing the schema
from the design run, then load research/synthetic_data.sql. The fixture is fully
qualified and self-contained, so db.execute_sql_script loads it in one call. Report
the row count of each notes_app table and record it in working/RUN_LOG.md.
```

**Check.** The load gives you 61 notes, made up of 48 active with 6 pinned, 7 archived, and 6 trashed, alongside 6 notebooks and 12 tags. That is enough to exercise the archive and trash views, pinned sorting, tag filtering, full-text search, and pagination past the 25-per-page default. The fixture is idempotent and self-contained, so it runs safely more than once and works against a bare schema.

## Step 5: Build the REST tier

Give the agent Prompt 2. This is the tier the talk is named for. The REST DDL has to run through `db.execute_sql` one statement at a time, because the grammar is session state and `db.execute_sql_script` hands each statement a fresh session. A capable agent works that out after the first failure, and the prompt says so up front to save the round trip.

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

**Check.** `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. The endpoints exist in the metadata before any router serves them over HTTP, and reading that metadata is how the talk confirms the tier is real.

## Step 6: Build the client

Give the agent Prompt 3. It reads the design from [`docs/notes_app-prd.md`](docs/notes_app-prd.md), builds the Textual app as a package at the repository root, and defaults to native mode so the client runs without a router.

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

**Check.** The app starts, the left pane lists the six notebooks, the middle pane shows the notes with the pinned ones sorted to the top, and the status line reads `native` alongside the sandbox address.

## Step 7: Run the client

The app lives at the repository root, and `bin/notes-app` is the fixed command that runs it, whatever a given run generated. Native mode is both the demo path and the launcher's default, so the client reaches the sandbox on port 3310 directly and needs no router.

```bash
./bin/notes-app
```

The launcher sets `NOTES_APP_MODE` to `native` unless you override it, so REST mode is `NOTES_APP_MODE=rest ./bin/notes-app`. Configuration comes from a `.env` file at the repository root, which you create by copying the `.env.example` the client build produced and setting the sandbox password to `demo-pw`. Both `.env` and `.env.example` are generated output, so both are gitignored.

### REST mode is optional and needs a router

Serving `/notesApp` over HTTP is the job of a MySQL-Router-family binary, bootstrapped against the REST metadata. It is neither a shell command nor an MCP tool, and standing one up is out of band, which is why REST mode stays optional. Switch to `NOTES_APP_MODE=rest` and point the client at the service root only once a router is running and verified. For the live demo, stay in native mode.

## Capturing a run for comparison

By default a run leaves nothing behind in git, since the output is ignored, which is what you want for a clean demo. When you want to keep a generation instead, to study it or to compare two runs of the plugins, snapshot it on a branch. This is the one place the ignored files are committed on purpose, so `git add` needs its `-f` flag.

```bash
git switch -c run/2026-09-18
git add -f notes_app pyproject.toml uv.lock working/notes_app.sql working/notes_app_rest.sql working/RUN_LOG.md
git commit -m "run: <harness or model>, <what stood out>"
git switch main
```

Keep the snapshot scoped to what you actually want to compare, which is the app source and the SQL the agent wrote, and leave out the `.venv`, the `.env`, and the sandbox data directory as noise. Switching back to `main` clears those generated files from your working tree, though they stay safe on the run branch. To compare two runs, diff their branches:

```bash
git diff run/2026-09-17 run/2026-09-18 -- notes_app
```

Delete a snapshot you no longer need with `git branch -D run/2026-09-18`.

## Clean up after a run

There are two things to tidy after a run, the sandbox process and the generated files. Stop and delete the sandbox first, since it is a real server process that outlives the conversation:

```text
Stop and delete the sandbox on port 3310.
```

That runs `sandbox.stop(port=3310, password="demo-pw", sandbox_dir="working/sandbox")` and then `sandbox.delete(port=3310, sandbox_dir="working/sandbox")`. Because `sandbox.delete` refuses a running instance, the stop has to land first, and `sandbox.kill` forces a wedged server down when a stop fails.

With the sandbox gone, remove the generated files. Snapshot the generation first if you want to keep it (see Capturing a run for comparison), then reset to a clean repo:

```bash
git clean -fdx
```

Because the repository tracks only the instructions, `git clean -fdx` clears every generated file (the app, the `working/` artifacts, the sandbox, the `.venv`, and the `.env`) and leaves only the committed `README.md`, `bin/`, `docs/`, and `research/`. Re-run the prompts from Step 3 for a fresh build with no residue.

## Troubleshooting

| Symptom                                    | Cause                                                                         | Fix                                                                 |
| ------------------------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| A tool call hangs and never returns        | The repository root is not on the allowed-paths list.                         | Add it with `mariadb-shell -- mcp setup`.                           |
| Sandbox deploys but the connection refuses | The root password was blank.                                                  | Redeploy with a non-blank password (`demo-pw`).                     |
| REST DDL fails partway down                | It ran through `db.execute_sql_script`, which gives each statement a session. | Rerun through `db.execute_sql`, one statement at a time.            |
| Endpoints do not answer over HTTP          | No router is serving the service.                                             | Expected. Use native mode, or bootstrap a router for REST mode.     |
| "Not a configured connection"              | The URI is not on the allow-list or asks for more than was configured.        | Rerun `mcp setup`, or drop the extra schema or option from the URI. |

## Files

- [`bin/notes-app`](bin/notes-app) is the stable launcher for the client.
- [`docs/notes_app-prd.md`](docs/notes_app-prd.md) is the client design.
- [`docs/demo-prompts.md`](docs/demo-prompts.md) collects the three prompts on their own.
- [`docs/stack-layering.md`](docs/stack-layering.md) explains how the layers relate.
- [`docs/decisions.md`](docs/decisions.md) records the choices behind the demo and why.
- [`research/notes_app.sql`](research/notes_app.sql) is the canonical schema.
- [`research/synthetic_data.sql`](research/synthetic_data.sql) is the test data for it.
- [`research/agent-security-note.md`](research/agent-security-note.md) is the blocked mass-delete talking point.
- [`research/notes_app-er.md`](research/notes_app-er.md) is the schema ER diagram.
- `working/` holds what the demo generates: the design-run schema, the REST DDL, and `RUN_LOG.md`.

## License

Apache License 2.0, in [`LICENSE`](LICENSE). The license covers the runbook, the prompts, the schema, and the launcher script alike. Copy the SQL, the prompts, or the launcher into your own work, with attribution and the notice preserved.
