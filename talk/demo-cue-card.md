# Demo cue card: Confidently Wrong

The operating sheet for the live run and for recording it. One agent context runs every act, so open one Claude Code session at the repository root and stay in it from the schema to the app. The prompts below are the source of truth: change them here first, prove the run, then copy them into the README, `docs/demo-prompts.md`, and the act slides. The capture moments are marked **[CAPTURE]**.

## What the audience watches

Two prompts, two acts, one conversation: the data tier, then the app. Both acts start from the same product doc, `docs/notes_app-prd.md`, so the schema the agent designs is the schema the app is built on. Act one seeds the database, so the app has real data to show. An optional third act puts a REST Service in front of the schema and refactors the app to run in native or REST mode.

## Pre-flight checklist (before doors, then again before you record)

- [ ] `ai-plugins` installed and the skills confirmed loaded (smoke test below).
- [ ] MCP allowed-paths include the repository root (`mariadb-shell -- mcp setup`).
- [ ] MariaDB 11.8 server already downloaded (one-time setup), so the act-one deploy runs offline with no mid-talk download.
- [ ] No sandbox on port 3310. Stop and delete any leftover from a rehearsal (`sandbox.stop`, then `sandbox.delete`), so step 2 of Prompt 1 finds nothing and deploys fresh on stage.
- [ ] Tree is clean: `git clean -fdx` has been run after the sandbox was deleted, and `docs/` and `research/` are intact.
- [ ] Password is `demo-pw` throughout. The act-one deploy sets it, and the `.env` that act two needs must carry the same value. A clean tree has no `.env` until act two builds the app.
- [ ] Terminal font sized for the projector. Test from the back row.
- [ ] Recording loaded on the laptop and cued to the capture moments. Never streamed.

## One-time setup (done before the talk, not on stage)

Install the plugin in Claude Code. First start downloads the `mariadb-shell` package, about a minute, once:

```text
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

Confirm the skills loaded by asking for something only a skill knows. The tell is the MariaDB-only grammar: `CREATE OR REPLACE TABLE`, `utf8mb4`, system versioning, a generated or `INVISIBLE` column, a descending index.

```text
Write a CREATE TABLE for a product catalogue, MariaDB style.
```

Point the MCP server at the repository root so it can read `docs/` and `research/`, write `working/`, and reach the sandbox:

```bash
mariadb-shell -- mcp setup
```

Pre-cache the sandbox server binary. The agent deploys the sandbox live in act one, and the first deploy on a machine with no local MariaDB server downloads the server package, a few hundred megabytes that takes a while. Do that download once, off stage, by deploying the sandbox exactly as act one will, confirming it, then tearing it down:

```text
Deploy a MariaDB 11.8 sandbox on port 3310 with root password demo-pw and data
directory working/sandbox, and report its server version. Then stop and delete it.
```

Both this deploy and act one's Prompt 1 step 2 pin MariaDB 11.8, the LTS series the schema and REST grammar target, so act one reuses this download, cached and offline. The pin is required: with no server on the PATH, a version-less deploy fails instead of downloading or reusing the cache. The cache lives outside the repository, so `git clean -fdx` removes the `working/sandbox` data directory but leaves the download in place. Confirm the reported version is 11.8.x.

## Act one: the data tier (Prompt 1)

**Target 4:00.** The spec beat. The agent reads the product doc, turns its data model into current MariaDB DDL, compares it with the reference schema, deploys it to a fresh sandbox, and seeds it.

Paste:

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

**[CAPTURE] the schema landing.** As the DDL scrolls, call out the current-MariaDB idioms and what they mean:

- `CREATE OR REPLACE TABLE` and `utf8mb4` with a `uca1400` collation. Today's server, not a MySQL habit.
- `WITH SYSTEM VERSIONING` on `account` and `notebook`. Row history built into the table.
- `id uuid DEFAULT uuid_v7()`. A key that sorts by time and does not leak row counts.
- `FULLTEXT (title, body)` on `note`. Search without a second system.
- `default_flag` generated column. One default notebook per account, enforced by the schema.

**Check.** The tables list matches the six tables and one view in PRD section 4, and the seed reports 61 notes: 48 active with 6 pinned, 7 archived, 6 trashed, plus 6 notebooks and 12 tags. Enough to show archive and trash views, pinned sorting, tag filters, search, and pagination past 25 per page. If the fixture fails first time, let the agent fix the schema and reload. A schema that bends to the contract is a finding, not a failure. The agent reports its differences from `research/notes_app.sql` at the end of step 1.

**Line to say:** "No SQL by hand. I wrote the data model down once, in a spec, and the agent turned it into DDL a live server accepts. Then it proved the schema by loading real data into it."

## Act two: the application (Prompt 2)

**Target 2:30.** The finale of the core run. The same context reads the same product doc, builds the client in native mode, and runs it on the data it just seeded.

Paste:

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

The build writes `.env` with the sandbox password `demo-pw`, which the native run needs to reach the seeded data. If `.env` is missing, copy `.env.example` and set the password before launching.

If the build finishes but you want a clean launch on stage, run it yourself:

```bash
./bin/notes-app
```

**[CAPTURE] the app opening.** Left pane lists the six notebooks. Middle pane shows the notes with the pinned ones on top. Status line reads `native` next to the sandbox address. Open a note so the Markdown renders in the right pane.

**Line to say:** "Same conversation, same product doc, from an empty directory to this. The app talks straight to the tables the agent designed, and the data on screen is the data act one loaded."

## Optional act three: the API tier and REST mode (Prompt 3)

**Target 4:00.** Run it only when the clock allows, or cut to the recording. The agent puts a MariaDB REST Service in front of the schema, then refactors the working app to run in native or REST mode. If you skip the act, still show the recorded `SHOW REST VIEWS` output and say the boundary line below, about 30 seconds, because the title promises an API tier.

Paste:

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
     @SORTABLE; tag names flattened through note_tag with @UNNEST; @INSERT
     @UPDATE @DELETE.
   - /notebook from notes_app.notebook, with @INSERT @UPDATE.
   - /tag from notes_app.tag, read-only.
   - No AUTHENTICATION REQUIRED on any view. This is a local demo.
2. Confirm with SHOW REST SERVICES, SCHEMAS and VIEWS that every endpoint
   exists, publish with ALTER REST SERVICE /notesApp PUBLISHED, and log the
   SHOW REST output.
3. Put native data access behind the section 9 DataSource interface as
   NativeDataSource, if it is not already, and add RestDataSource: httpx against
   the /notesApp service root, the section 5 endpoints, and the paginated
   items/hasMore list shape. NOTES_APP_MODE selects the backend and defaults to
   native. Add the mode and service root URL to .env.example, and name the
   active mode and its address on the status line.
4. Run bin/notes-app in native mode to confirm nothing regressed, then with
   NOTES_APP_MODE=rest. No router is running, so the app must start, show the
   connection error on the status line, and stay up (PRD section 8). Log both
   runs.
```

**[CAPTURE] the break and recover.** The REST grammar is session state, and the prompt names the one-statement-per-session rule up front to save the round trip, so a clean run may not break at all. If the agent still runs part of it as a script, each statement lands in a fresh session and the grammar breaks partway down, and a capable agent recovers after the first failure. When that happens, let the failure and recovery play. It is the point.

**Line to say:** "This is the grammar the model is most confidently wrong about, and it is the grammar the skill knows best. If it trips on the session rule, watch it read the error and fix itself."

**[CAPTURE] the metadata.** `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. State the boundary in one sentence and move on:

**Line to say:** "The endpoints are defined right here in the metadata. Serving them over HTTP is a router, and that router is a separate job I did not stand up today. Knowing where the agent's work stops is the whole idea."

**[CAPTURE] the two modes.** The status line flips from `native` with the sandbox address to `rest` with `/notesApp` and a clean connection error, and the app stays up.

**Line to say:** "Same app, one environment variable. Native mode is a working client on the tables. REST mode is wired to the tier the agent defined, and it tells you plainly that nothing is serving it yet."

## Cleanup (after the run, off the clock)

The sandbox is a real process that outlives the conversation, so stop and delete it first, then reset the tree. Snapshot the run first if you want to keep it (README, "Capturing a run for comparison").

```text
Stop and delete the sandbox on port 3310.
```

```bash
git clean -fdx
```

`git clean -fdx` clears the generated app, `working/` with the sandbox data directory, the `.venv`, and the `.env`, and leaves the committed `README.md`, `bin/`, `docs/`, and `research/`.

## Recording notes

- Capture the core moments in order: schema landing, app opening. For the optional act, add break and recover, `SHOW REST`, and the two modes.
- Trim the waits between tool calls, but keep any fixture-driven schema fix and the break-and-recover intact. The failure is the evidence.
- The core run is about six and a half minutes. Target a trimmed cut of acts one and two inside 6:30, and a separate optional-act cut inside 4:00, so the whole talk lands near 20 and stays under 25 with or without it.
- Record at the projector font size, not your desk size.
- Keep the file local. Have `working/RUN_LOG.md`, an app screenshot, and, for the optional act, the `SHOW REST` output exported as static slides in case the recording will not play.
