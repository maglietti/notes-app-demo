# Notes App demo

This repository holds the runbook for the demo in *Confidently Wrong: Handing a Coding Agent the Database Anyway*, a talk in the Databases track at [All Things Open 2026](https://2026.allthingsopen.org/sessions/confidently-wrong-handing-a-coding-agent-an-api-tier-anyway) (Tuesday 20 October, 10:30, Room 306A).

A year of daily Markdown notes is hard to search by meaning: `rg` finds words, and you remember topics. In this demo, one coding agent, given the MariaDB AI Plugins, builds the fix from a short spec. It designs a schema, deploys a MariaDB sandbox, and runs the schema there. It then builds a terminal app with Textual, the Python terminal-UI framework, that imports the notes with local embeddings and finds them by meaning.

## Repository layout

The repository tracks the instructions and nothing else. The agent reads the two inputs marked `(agent input)`.

```text
.
├── README.md                    this runbook
├── LICENSE                      Apache License 2.0
├── notes/                       a year of daily notes and quarterly archives (agent input)
└── talk/
    └── notes-app-spec.md        the spec: what the app does and when it is done (agent input)
```

Everything a run generates is gitignored, so `git clean -fdx` removes all of it:

```text
notes_app/                                    the app package
pyproject.toml, uv.lock, .env, .env.example   the app project and its configuration
working/                                      the schema, RUN_LOG.md, and the sandbox data directory
.venv/                                        the app's virtual environment
```

## What you need

- A coding-agent harness. This runbook uses Claude Code.
- macOS or Linux.
- Python 3.11 or newer, and `uv`, the Python project manager the app is built with.
- MariaDB Connector/C with `mariadb_config` on the `PATH`, plus a C compiler. The app's `mariadb` Python package builds against them on install. The package is `libmariadb-dev` on Debian and Ubuntu, `mariadb-connector-c-devel` on Fedora, `mariadb-libs` on Arch, and `mariadb-connector-c` in Homebrew.
- [Ollama](https://ollama.com), with the embedding model the spec names:

  ```bash
  ollama pull qwen3-embedding:0.6b
  ```

You do not need a MariaDB server. The sandbox brings its own, with no Docker and no root.

## Step 1: Install the MariaDB AI Plugins

In Claude Code:

```text
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

The plugin installs the MariaDB skills and the `mariadb-shell` MCP server. On first start it downloads the `mariadb-shell` package, once. For other harnesses and for the list of skills and tools, see [ai-plugins.mariadb.org](https://ai-plugins.mariadb.org).

## Step 2: Configure the MCP server

The server starts out allowed to reach nothing. Add this repository's root to its allowed paths, so it can read the spec, write `working/`, and reach the sandbox it deploys:

```bash
mariadb-shell -- mcp setup
```

If `mariadb-shell` is not on your `PATH`, use `~/.local/bin/mariadb-shell`.

## Step 3: Build the data tier

Start the agent at the repository root and give it Prompt 1:

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Design the MariaDB schema for the app that talk/notes-app-spec.md
   describes, and save the DDL as working/notes_app.sql.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Report each table you created and what it holds.
```

The first deploy on a machine with no local MariaDB server downloads the 11.8 server package, a few hundred megabytes. Later deploys reuse the cached copy.

**Check.** The schema runs on the sandbox with no errors. The spec names no MariaDB features, so read `working/notes_app.sql` to see what the agent chose.

## Step 4: Build the app

Give the agent Prompt 2:

```text
Build the app that talk/notes-app-spec.md describes, on the schema in
working/notes_app.sql. Build every Must have.

- Write .env with the sandbox password demo-pw, plus a .env.example, at the
  repository root.
- Keep working/ for the schema, run log and sandbox only.

Import my notes, then check the app against the "Done when" items in the spec,
and record each command and its result in working/RUN_LOG.md.
```

**Check.** The import reports all 220 files in `notes/`: 217 daily notes and 3 quarterly summaries. This search lists `2026-04-14.md` in its top three:

```bash
uv run notes-app search "testing a migration without a copy of production"
```

## Step 5: Run the app

```bash
uv run notes-app
```

Type what a note was about, and press Enter on a result to open it in `nvim`. The app reads its connection settings from `.env` at the repository root. If `.env` is missing, copy `.env.example` and set the password to `demo-pw`.

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
| The import fails to reach Ollama | Ollama is not running, or the model is not pulled. | Start Ollama and run `ollama pull qwen3-embedding:0.6b`. |

## License

Apache License 2.0, in [`LICENSE`](LICENSE). It covers the runbook, the prompts, the spec, and the notes.
