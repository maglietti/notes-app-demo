# Notes App demo

This repository holds the runbook for the demo in *Confidently Wrong: Handing a Coding Agent the Database Anyway*, a talk in the Databases track at [All Things Open 2026](https://2026.allthingsopen.org/sessions/confidently-wrong-handing-a-coding-agent-an-api-tier-anyway) (Tuesday 20 October, 10:30, Room 306A).

A year of daily Markdown notes is hard to search by meaning: `rg` finds words, and you remember topics. In this demo, one coding agent, given the MariaDB AI Plugins, builds the fix from a short spec. It designs a schema, deploys a MariaDB sandbox, and runs the schema there. It then builds a terminal app with Textual, the Python terminal-UI framework, that imports the notes with local embeddings and finds them by meaning.

## Repository layout

The repository tracks the instructions, the notes, and the talk's slides. The agent reads the two inputs marked `(agent input)`.

```text
.
├── README.md                    this runbook
├── LICENSE                      Apache License 2.0
├── notes/                       a year of daily notes and quarterly archives (agent input)
└── talk/
    ├── notes-app-spec.md        the spec: what the app does and when it is done (agent input)
    └── slides.pdf               the talk's slides
```

You build the app in a clone of this repository, never in the repository itself. Each run gets its own clone, so the source stays untouched and you can keep runs side by side. A run generates these files in its clone, and all of them are gitignored:

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

The server starts out allowed to reach nothing. Allow the folder that will hold your clones, so the server can read the spec, write `working/`, and reach the sandbox it deploys in every clone:

```bash
mkdir -p ~/notes-app-runs
mariadb-shell -- mcp setup --addPaths=$HOME/notes-app-runs
```

Run `mariadb-shell -- mcp setup` with no options to do the same interactively. If `mariadb-shell` is not on your `PATH`, use `~/.local/bin/mariadb-shell`.

## Step 3: Make a clean clone

The agent must see only the spec and the notes. Clone the repository, then remove anything from the talk that is not the spec. The slides show how earlier runs went, and an agent that reads them can skip the work.

```bash
cd ~/notes-app-runs
git clone https://github.com/maglietti/notes-app-demo.git run-1
cd run-1
rm -f talk/slides.pdf
ls talk
```

**Check.** `ls talk` prints only `notes-app-spec.md`. Use a new folder name, such as `run-2`, for each run.

## Step 4: Build the data tier

Start the agent at the clone's root. Type a short line of your own, such as `Please run these steps.`, then paste Prompt 1 into the same message. A message that is only a pasted block can make the agent stop and ask for confirmation first.

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Design the MariaDB schema for the app that talk/notes-app-spec.md
   describes, and save the DDL as working/notes_app.sql.
2. If no MariaDB 12.3 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Report each table you created and what it holds.
```

The first deploy downloads the MariaDB 12.3 server package, a few hundred megabytes, unless a 12.3 server is already on your `PATH`. Later deploys reuse the cached copy.

**Check.** The schema runs on the sandbox with no errors. The spec names no MariaDB features, so read `working/notes_app.sql` to see what the agent chose.

## Step 5: Build the app

Give the agent Prompt 2 the same way:

```text
Build the app that talk/notes-app-spec.md describes, on the schema in
working/notes_app.sql. Build every Must have, and skip the Nice to have
items.

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

## Step 6: Run the app

```bash
uv run notes-app
```

The bottom bar lists the keys. Search for what a note was about, and press Enter on a result to open it in `nvim`. The app reads its connection settings from `.env` at the clone's root. If `.env` is missing, copy `.env.example` and set the password to `demo-pw`.

## Clean up

The sandbox is a real server process that outlives the conversation. When you are done with a run, stop and delete it:

```text
Stop and delete the sandbox on port 3310.
```

To keep a run for comparison, keep its clone folder. To discard it, delete the folder:

```bash
rm -rf ~/notes-app-runs/run-1
```

The source repository never changes, so there is nothing to reset.

## Troubleshooting

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| A tool call hangs and never returns | The clone is not inside an allowed path. | Add the folder that holds your clones with `mariadb-shell -- mcp setup --addPaths`. |
| The sandbox deploys but the connection is refused | The root password was blank. | Redeploy with a non-blank password (`demo-pw`). |
| Port 3310 is already in use | An earlier run's sandbox is still running. | Stop and delete it before the next run, or deploy on another port. |
| "Not a configured connection" | The URI is not on the allow-list, or asks for more than was configured. | Rerun `mcp setup`, or drop the extra schema or option from the URI. |
| The import fails to reach Ollama | Ollama is not running, or the model is not pulled. | Start Ollama and run `ollama pull qwen3-embedding:0.6b`. |

## Slides

[`talk/slides.pdf`](talk/slides.pdf) holds the talk's slides.

## License

Apache License 2.0, in [`LICENSE`](LICENSE). It covers the runbook, the prompts, the spec, and the notes. It does not cover `talk/slides.pdf`, which uses MariaDB's presentation template. The MariaDB name and logo are trademarks and are not licensed here.
