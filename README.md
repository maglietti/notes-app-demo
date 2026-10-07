# Notes App demo

This repository holds the runbook for the demo in *Confidently Wrong: Handing a Coding Agent an API Tier Anyway*, a talk in the Databases track at [All Things Open 2026](https://2026.allthingsopen.org/sessions/confidently-wrong-handing-a-coding-agent-an-api-tier-anyway) (Tuesday 20 October, 10:30, Room 306A).

One coding agent, given the MariaDB AI Plugins, turns a short spec into a note-taking schema. It deploys a throwaway MariaDB server, runs the schema against it, and seeds it with sample data. The same agent then builds a terminal client on that data with Textual, the Python terminal-UI framework, so the result is an app you can open and use.

## Repository layout

The repository tracks the instructions and nothing else. The agent reads the two files marked `(agent input)`.

```text
.
├── README.md                    this runbook
├── LICENSE                      Apache License 2.0
├── bin/
│   └── notes-app                stable launcher for the generated app
├── data/
│   └── synthetic_data.sql       the seed fixture (agent input)
└── talk/
    └── notes-app-spec.md        the spec: what the app does and when it is done (agent input)
```

Everything a run generates is gitignored, so `git clean -fdx` removes all of it:

```text
notes_app/                                    the Textual app package
pyproject.toml, uv.lock, .env, .env.example   the app project and its configuration
working/                                      the schema, RUN_LOG.md, and the sandbox data directory
.venv/                                        the app's virtual environment
```

## What you need

- A coding-agent harness. This runbook uses Claude Code.
- macOS or Linux.
- Python 3.11 or newer. `uv` is optional: `bin/notes-app` uses it when present and falls back to `python3`.
- MariaDB Connector/C with `mariadb_config` on the `PATH`, plus a C compiler. The app's `mariadb` Python package builds against them on install. The package is `libmariadb-dev` on Debian and Ubuntu, `mariadb-connector-c-devel` on Fedora, `mariadb-libs` on Arch, and `mariadb-connector-c` in Homebrew.

You do not need a MariaDB server. The sandbox brings its own, with no Docker and no root.

## Step 1: Install the MariaDB AI Plugins

In Claude Code:

```text
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

The plugin installs the MariaDB skills and the `mariadb-shell` MCP server. On first start it downloads the `mariadb-shell` package, once. For other harnesses and for the list of skills and tools, see [ai-plugins.mariadb.org](https://ai-plugins.mariadb.org).

## Step 2: Configure the MCP server

The server starts out allowed to reach nothing. Add this repository's root to its allowed paths, so it can read the spec and the fixture, write `working/`, and reach the sandbox it deploys:

```bash
mariadb-shell -- mcp setup
```

If `mariadb-shell` is not on your `PATH`, use `~/.local/bin/mariadb-shell`.

## Step 3: Build and seed the data tier

Start the agent at the repository root and give it Prompt 1:

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Turn the data model in talk/notes-app-spec.md into MariaDB DDL for the
   notes_app schema, saved as working/notes_app.sql.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Seed it by loading data/synthetic_data.sql with db.execute_sql_script.
   The fixture is the data contract: if it fails, fix working/notes_app.sql and
   redeploy. Never edit the fixture.
4. Check the result against the first "Done when" item in the spec, and report
   each table's row count.
```

The first deploy on a machine with no local MariaDB server downloads the 11.8 server package, a few hundred megabytes. Later deploys reuse the cached copy.

**Check.** The five tables in the spec exist. The seed gives 61 notes (48 active with 6 pinned, 7 archived, and 6 trashed), 6 notebooks, and 12 tags. The spec names no MariaDB features, so read `working/notes_app.sql` to see what the agent chose. With the skills loaded, expect idioms such as `CREATE OR REPLACE TABLE`, `UUID` keys from `UUID_v7()`, and descending index columns that match "pinned first, newest first". A schema fix that the fixture forces is a finding, not a failure.

## Step 4: Build the client

Give the agent Prompt 2:

```text
Build the app that talk/notes-app-spec.md describes, on the schema in
working/notes_app.sql. Build every Must have.

- bin/notes-app is the committed launcher. Read it, and make the app work
  with it.
- Write .env with the sandbox password demo-pw, plus a .env.example, at the
  repository root.
- Keep working/ for the schema, run log and sandbox only.

Check the app against the "Done when" items in the spec, and record each
command and its result in working/RUN_LOG.md.
```

**Check.** `bin/notes-app` starts the app. The left pane lists the six notebooks, and the middle pane shows the notes with the pinned ones on top.

## Step 5: Run the client

```bash
./bin/notes-app
```

The app reads its connection settings from `.env` at the repository root. If `.env` is missing, copy `.env.example` and set the password to `demo-pw`.

## Clean up

The sandbox is a real server process that outlives the conversation. Stop and delete it first:

```text
Stop and delete the sandbox on port 3310.
```

Then remove the generated files:

```bash
git clean -fdx
```

To keep a generation for comparison, commit it to a branch first. The files are ignored, so `git add` needs `-f`, and the `notes_app/*.py` glob keeps the `__pycache__` bytecode out:

```bash
git switch -c run/2026-10-07
git add -f notes_app/*.py pyproject.toml uv.lock working/notes_app.sql working/RUN_LOG.md
git commit -m "run: <harness or model>, <what stood out>"
git switch main
```

## Troubleshooting

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| A tool call hangs and never returns | The repository root is not on the allowed-paths list. | Add it with `mariadb-shell -- mcp setup`. |
| The sandbox deploys but the connection is refused | The root password was blank. | Redeploy with a non-blank password (`demo-pw`). |
| "Not a configured connection" | The URI is not on the allow-list, or asks for more than was configured. | Rerun `mcp setup`, or drop the extra schema or option from the URI. |

## License

Apache License 2.0, in [`LICENSE`](LICENSE). It covers the runbook, the prompts, the spec, the fixture, and the launcher.
