# Notes App demo

This repository holds the runbook for a live demo. One coding agent, handed the MariaDB skills and a live database over the Model Context Protocol, turns a product doc into a note-taking schema, deploys a throwaway MariaDB server, runs the schema against it, and seeds it. The same agent then builds a Textual client, on the Python terminal-UI framework, that runs on the result, so the work the agent did is something you can open and use rather than just read. An optional third prompt puts a REST API in front of the schema.

The talk it supports is *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*, in the Databases track at All Things Open 2026. The specification the agent builds from, with its acceptance criteria, lives in [`docs/notes_app-prd.md`](docs/notes_app-prd.md), and the three prompts that drive the run are collected in [`docs/demo-prompts.md`](docs/demo-prompts.md), inlined below at the step where each one belongs. The prompts originate in the talk's cue card, [`talk/demo-cue-card.md`](talk/demo-cue-card.md), so change them there first.

## Repository layout

The repository tracks the instructions, and nothing else. This is the committed tree, the part you read and run. The prompts point the agent at two of these files, marked `(agent input)`, and have it run `bin/notes-app`:

```text
.
├── README.md                  this runbook
├── LICENSE                    Apache License 2.0
├── bin/
│   └── notes-app              stable launcher for the generated app
├── docs/
│   ├── notes_app-prd.md       the spec: schema, REST surface, app, acceptance criteria (agent input)
│   ├── demo-prompts.md        the three prompts on their own
│   ├── stack-layering.md      how the pieces relate
│   └── decisions.md           the choices behind the demo
├── research/
│   ├── synthetic_data.sql     the seed fixture Prompt 1 loads (agent input)
│   ├── notes_app.sql          reference schema, frozen from an earlier agent run; the prompts do not read it
│   ├── notes_app-er.*         the reference schema's ER diagram
│   └── agent-security-note.md the blocked mass-delete talking point
└── talk/                      the talk that uses this demo
    ├── demo-cue-card.md       the operating sheet, and the source of truth for the prompts
    ├── run-of-show.md         the timed beats
    ├── outline.md             the slide-by-slide plan
    └── slides.md              the deck, in Marp Markdown
```

Everything a run generates is gitignored, so `git clean -fdx` removes all of it:

```text
notes_app/                                    the Textual app package        (Prompt 2)
pyproject.toml, uv.lock, .env, .env.example   the app project and config (Prompt 2)
working/                                      schema, RUN_LOG, sandbox datadir (Prompt 1), REST DDL (Prompt 3)
.venv/                                        the app's virtual environment
```

A run never dirties the committed tree, so `git clean -fdx` returns it to a clean, re-runnable state. During a run the agent reads the product doc and the seed fixture, builds the `notes_app` package at the repository root, and writes its working files under `working/`.

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
- Python 3.11 or newer for the generated app. `uv` is optional: `bin/notes-app` uses it when present and falls back to `python3`.
- MariaDB Connector/C with `mariadb_config` on the `PATH`, plus a C compiler. The app's `mariadb` Python package (Connector/Python) builds against them on install, because it ships no Linux or macOS wheels. The package is `libmariadb-dev` on Debian and Ubuntu, `mariadb-connector-c-devel` on Fedora, `mariadb-libs` on Arch, and `mariadb-connector-c` in Homebrew.

You do not need a MariaDB Server. The sandbox brings its own when the machine has none, with no Docker and no root.

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

If `mariadb-shell` is not on your `PATH`, use the copy the plugin installed at `~/.local/bin/mariadb-shell`. When the setup walks you through it, add this repository's root directory to the allowed paths. You do not need to configure a database connection, because the sandbox registers its own automatically.

## Step 3: Build and seed the data tier

Run the agent from the repository root and give it Prompt 1. The agent turns the data model in section 4 of the product doc into DDL in `working/notes_app.sql`. It deploys a sandbox on port 3310, runs the schema, loads the seed fixture, and logs each step to `working/RUN_LOG.md`.

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Turn the data model in section 4 of docs/notes_app-prd.md into MariaDB DDL
   for the notes_app schema, saved as working/notes_app.sql.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Seed it by loading research/synthetic_data.sql with db.execute_sql_script.
   The fixture is the data contract: if it fails, fix working/notes_app.sql and
   redeploy. Never edit the fixture.
4. Check the result against AC-D1 to AC-D4 in section 11 of the PRD, and report
   each one as passed or failed with its evidence.
```

The first deploy on a machine with no local MariaDB server downloads the 11.8 server package, a few hundred megabytes, and later deploys reuse the cached copy.

**Check.** The agent reports AC-D1 to AC-D4 in PRD section 11 as passed. The tables match the six tables and one view in PRD section 4, and the seed gives you 61 notes, made up of 48 active with 6 pinned, 7 archived, and 6 trashed, alongside 6 notebooks and 12 tags. That is enough to exercise the archive and trash views, pinned sorting, tag filtering, full-text search, and pagination past the 25-per-page default. Look for the current-MariaDB idioms in `working/notes_app.sql`: `CREATE OR REPLACE TABLE`, `utf8mb4` with a `uca1400` collation, system versioning on `account` and `notebook`, `UUID` keys generated by `UUID_v7()`, and a `FULLTEXT` index over the note title and body. A schema fix that the fixture forces is a finding, not a failure: the data contract doing its job.

## Step 4: Build the client

Give the agent Prompt 2. It reads the design from [`docs/notes_app-prd.md`](docs/notes_app-prd.md), builds the Textual app as a package at the repository root in native mode, and runs it on the data Step 3 loaded.

```text
Build the Textual app that docs/notes_app-prd.md specifies, in native mode only.
Skip RestDataSource and NOTES_APP_MODE (PRD build order step 7).

- Scope: every Must in section 6, the three-pane layout in section 7,
  NativeDataSource behind the section 9 DataSource interface, and the
  packaging and config in section 10.
- Bind the queries to the columns in working/notes_app.sql, the schema this
  session built.
- Keep working/ for the schema, run log and sandbox only.

Check the app against AC-A1 to AC-A5 in section 11, and record each command and
its result in working/RUN_LOG.md.
```

**Check.** The agent reports AC-A1 to AC-A5 as passed. Both entry points start the app. The left pane lists the six notebooks, the middle pane shows the notes with the pinned ones sorted to the top, and the status line reads `native` alongside the sandbox address. The console-script check catches a packaging failure that the launcher cannot: the repository gitignores `notes_app/`, and a build backend that honours `.gitignore` installs the project with no code in it.

## Step 5: Run the client

The app lives at the repository root, and `bin/notes-app` is the fixed command that runs it, whatever a given run generated. Native mode is both the demo path and the launcher's default, so the client reaches the sandbox on port 3310 directly and needs no router.

```bash
./bin/notes-app
```

Configuration comes from a `.env` file at the repository root, which the client build writes with the sandbox password `demo-pw`. If it is missing, copy the `.env.example` the build produced and set the password. Both `.env` and `.env.example` are generated output, so both are gitignored.

To choose the data mode, set `NOTES_APP_MODE` on the command line, as in `NOTES_APP_MODE=rest ./bin/notes-app`. The launcher exports `NOTES_APP_MODE=native` before the app starts whenever the variable is unset, so a `NOTES_APP_MODE` line in `.env` does not take effect if the app lets the environment win over `.env`, as the usual loaders do. REST mode exists only after Step 6.

## Step 6 (optional): Add the API tier and REST mode

Give the agent Prompt 3 when you want the REST tier the talk's title names. The talk does not run it on stage, and shows only its `SHOW REST VIEWS` output on a static slide. It puts a MariaDB REST Service in front of the schema, then adds a `RestDataSource` beside the `NativeDataSource` that Prompt 2 built, so `NOTES_APP_MODE` selects native or REST mode. The REST DDL has to run through `db.execute_sql` one statement at a time, because the grammar is session state and `db.execute_sql_script` hands each statement a fresh session. The prompt says so up front.

```text
Continue against the sandbox on port 3310. Keep database files in working/, and
append each step's result to working/RUN_LOG.md. Complete the steps in order.

1. Build the REST Service in section 5 of the PRD (API-1 to API-6). Save the
   REST DDL to working/notes_app_rest.sql, but run it with db.execute_sql one
   statement at a time: the REST grammar is session state, and
   db.execute_sql_script gives each statement a fresh session.
2. Check it against AC-R1 to AC-R3 in section 11, and log the SHOW REST output.
   If the nested tag objects did not come back read-only, log it and move on:
   do not patch the REST metadata.
3. Add RestDataSource and NOTES_APP_MODE (PRD build order step 7) beside
   NativeDataSource, with the REST settings in CF-4.
4. Check both modes against AC-R4 and AC-R5. No router is running, so REST mode
   must report the connection error and stay up. Log both runs.
```

**Check.** The agent reports AC-R1 to AC-R5, with AC-R2 expected to show the mismatch below. `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. On mariadb-shell 26.9.3, expect the agent to report that `SHOW CREATE REST VIEW /note` shows the nested tag objects as writable: the shell stores them with the parent view's operations whatever the DDL says (PRD section 13). The endpoints exist in the metadata before any router serves them over HTTP, and reading that metadata is how the talk confirms the tier is real. With `NOTES_APP_MODE=rest ./bin/notes-app`, the status line names `rest` and the service root, shows the connection error, and the app stays up.

### REST mode needs a router

Serving `/notesApp` over HTTP is the job of a MySQL-Router-family binary, bootstrapped against the REST metadata. It is neither a shell command nor an MCP tool, and standing one up is out of band. The REST server expected in `mariadb-shell` is not ready yet, which is why REST mode stays optional. Point the client at live endpoints only once a router is running and verified. For the live demo, stay in native mode.

## Capturing a run for comparison

By default a run leaves nothing behind in git, since the output is ignored, which is what you want for a clean demo. When you want to keep a generation instead, to study it or to compare two runs of the plugins, snapshot it on a branch. This is the one place the ignored files are committed on purpose, so `git add` needs its `-f` flag.

```bash
git switch -c run/2026-09-18
git add -f notes_app/*.py pyproject.toml uv.lock working/notes_app.sql working/RUN_LOG.md
git status --short
git commit -m "run: <harness or model>, <what stood out>"
git switch main
```

The glob `notes_app/*.py` matters. `-f` overrides every ignore rule under a path you name, so `git add -f notes_app` would also commit the `__pycache__` bytecode that any launch of the app leaves behind. Check the `git status --short` output for stray `__pycache__` or `.env` entries before you commit. If the run included the optional Prompt 3, add `working/notes_app_rest.sql` to the list too. Keep the snapshot scoped to what you actually want to compare, which is the app source and the SQL the agent wrote, and leave out the `.venv`, the `.env`, and the sandbox data directory as noise. Switching back to `main` removes the snapshotted files from your working tree, so the app no longer runs there. They stay safe on the run branch, and switching to it brings them back. The files you left out, such as `.venv` and `.env`, stay in place. To compare two runs, diff their branches:

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

Because the repository tracks only the instructions, `git clean -fdx` clears every generated file (the app, the `working/` artifacts, the sandbox, the `.venv`, and the `.env`) and leaves only the committed files: `README.md`, `LICENSE`, `bin/`, `docs/`, `research/`, and `talk/`. Re-run the prompts from Step 3 for a fresh build with no residue.

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
- [`docs/notes_app-prd.md`](docs/notes_app-prd.md) is the specification the agent builds from: the schema, the REST surface, the app, its packaging, and the acceptance criteria each prompt checks against.
- [`docs/demo-prompts.md`](docs/demo-prompts.md) collects the three prompts on their own.
- [`docs/stack-layering.md`](docs/stack-layering.md) explains how the layers relate.
- [`docs/decisions.md`](docs/decisions.md) records the choices behind the demo and why.
- [`research/notes_app.sql`](research/notes_app.sql) is the reference schema, frozen from an earlier agent run. The prompts do not read it: the agent writes its own from PRD section 4. Use it to load the tier without an agent, or to compare against a run.
- [`research/synthetic_data.sql`](research/synthetic_data.sql) is the seed fixture that Prompt 1 loads.
- [`research/agent-security-note.md`](research/agent-security-note.md) is the blocked mass-delete talking point.
- [`research/notes_app-er.md`](research/notes_app-er.md) is the reference schema's ER diagram.
- [`talk/demo-cue-card.md`](talk/demo-cue-card.md) is the operating sheet for the live run, and the source of truth for the prompts. The rest of `talk/` holds the run of show, the slide outline, and the deck.
- `working/` holds what the demo generates: the agent's schema, the REST DDL from the optional prompt, and `RUN_LOG.md`.

## License

Apache License 2.0, in [`LICENSE`](LICENSE). The license covers the runbook, the prompts, the schema, and the launcher script alike. Copy the SQL, the prompts, or the launcher into your own work, with attribution and the notice preserved.
