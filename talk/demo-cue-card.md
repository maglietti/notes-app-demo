# Demo cue card: Confidently Wrong

The operating sheet for the live run and for recording it. One agent context runs every act, so open one Claude Code session at the repository root and stay in it from the schema to the app. The prompts below lead the README for now: prove the run here, then sync the README to match. The capture moments are marked **[CAPTURE]**.

## What the audience watches

Two prompts, two acts, one conversation: the data tier, then the app. Both acts start from the same product doc, `docs/notes_app-prd.md`, so the schema the agent designs is the schema the app is built on. Act one seeds the database, so the app has real data to show. An optional third act puts a REST Service in front of the schema and refactors the app to run in native or REST mode.

## Pre-flight checklist (before doors, then again before you record)

- [ ] Recording loaded on the laptop and cued to the capture moments. Never streamed.
- [ ] Sandbox server binary already downloaded (one-time setup), so the act-one deploy runs offline and instant with no mid-talk download.
- [ ] Port 3310 is free, with no leftover sandbox process from a prior run holding it. Delete any leftover before doors (`sandbox.delete` on port 3310).
- [ ] MCP allowed-paths include the repository root (`mariadb-shell -- mcp setup`).
- [ ] `ai-plugins` installed and the skills confirmed loaded (smoke test below).
- [ ] Terminal font sized for the projector. Test from the back row.
- [ ] Tree is clean and re-runnable: `git clean -fdx` has been run, `docs/` and `research/` intact.
- [ ] Password is `demo-pw` throughout: the act-one deploy sets it, and the app's `.env` (generated in act two) must carry the same value, so the native client connects. `.env` is generated output, so a clean tree will not have it until act two builds the app.

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
Deploy a sandbox on port 3310 with root password demo-pw and its data directory at
working/sandbox, connect to it, and report the server version. Then stop the sandbox
and delete it (sandbox.stop then sandbox.delete on port 3310).
```

The version-less deploy here matches act one exactly, so whatever version it resolves to is the version act one reuses, cached and offline. The cache lives outside the repository, so `git clean -fdx` removes the `working/sandbox` data directory but leaves the download in place. Confirm the reported version is the MariaDB 11.8 LTS series the schema and REST grammar target. If the default is older, pin `MariaDB 11.8` in this deploy and in act one's Prompt 1 step 2 so both use the same version.

## Act one: the data tier (Prompt 1)

**Target 4:00.** The design beat. The agent reads the product doc, turns its data model into current MariaDB DDL, deploys it, and seeds it.

Paste:

```text
Work in this repository and complete every step in order. Put the files you create
in the working/ directory, and append a short record of each step to
working/RUN_LOG.md as you go.

1. Read docs/notes_app-prd.md. Design the MariaDB database schema named notes_app
   that its data model in section 4 describes, keeping the column names the PRD
   gives, since the app binds to them. Write the DDL yourself from the PRD; do not
   copy or read research/notes_app.sql. Store it in working/notes_app.sql.

2. Deploy a sandbox instance on port 3310 with root password demo-pw and its data
   directory at working/sandbox, connect to it, and run working/notes_app.sql via
   the MCP server.

3. Seed the database by loading research/synthetic_data.sql with
   db.execute_sql_script. The fixture is fully qualified and self-contained, and it
   is the data contract: if it fails to load, fix working/notes_app.sql and redeploy
   it. Never edit the fixture.

4. List the tables you created, show me the columns of the note table, and report
   the row count of each notes_app table.
```

**[CAPTURE] the schema landing.** As the DDL scrolls, call out the current-MariaDB idioms and what they mean:

- `CREATE OR REPLACE TABLE` and `utf8mb4` with a `uca1400` collation. Today's server, not a MySQL habit.
- `WITH SYSTEM VERSIONING` on `account` and `notebook`. Row history built into the table.
- `id uuid DEFAULT uuid_v7()`. A key that sorts by time and does not leak row counts.
- `FULLTEXT (title, body)` on `note`. Search without a second system.
- `default_flag` generated column. One default notebook per account, enforced by the schema.

**Check.** The tables list matches the six tables and one view in PRD section 4, and the seed reports 61 notes: 48 active with 6 pinned, 7 archived, 6 trashed, plus 6 notebooks and 12 tags. Enough to show archive and trash views, pinned sorting, tag filters, search, and pagination past 25 per page. If the fixture fails first time, let the agent fix the schema and reload. A schema that bends to the contract is a finding, not a failure. Compare against `research/notes_app.sql` off stage if you want the side-by-side.

**Line to say:** "No SQL by hand. I wrote down the idea, and the agent turned it into grammar this model was never trained on, because a skill handed it the current version. Then it proved the schema by loading real data into it."

## Act two: the application (Prompt 2)

**Target 2:30.** The finale. The same context reads the same product doc, builds the client in native mode, and runs it on the data it just seeded.

Paste:

```text
Build the Textual application that docs/notes_app-prd.md specifies, in native mode
only. Leave RestDataSource and NOTES_APP_MODE for later (PRD build order step 7).
Build the app at the repository root as a notes_app package with a pyproject.toml,
the way a normal Python project is laid out. Do not put the app under working/;
that directory is only for the schema, the run log and the sandbox. Hold to these
constraints:

- Python 3.11 or newer. Textual for the UI, and the mariadb Connector/Python
  against 127.0.0.1:3310 for data access, bound to the columns in
  working/notes_app.sql.
- Build the three-pane layout and status line from section 7, and every Must
  feature from section 6: list notebooks with a per-notebook note count; list,
  open, create and edit notes; pin and unpin; archive and restore; trash and
  restore; and the status line naming the native data mode and the sandbox address.
- Read configuration (sandbox host, port and password) from the environment or a
  .env file, and ship a .env.example. Keep .env and .env.example at the repository
  root with the app.
- Make it runnable as `python -m notes_app` from the repository root: put the
  source in a notes_app package with a __main__.py, and add a pyproject.toml with
  the dependencies and a notes-app console script. A committed launcher at
  bin/notes-app already runs `python -m notes_app` from the root, so satisfy that
  contract rather than inventing another entry point.

Then run it with bin/notes-app against the sandbox on port 3310, confirm the seeded
notes appear in the list, and record the run command and the result in
working/RUN_LOG.md.
```

The build ships `.env.example`, not `.env`. For the native run to reach the seeded data, `.env` must exist at the repository root with the sandbox password `demo-pw`. If the build left only `.env.example`, copy it and set the password before launching.

If the build finishes but you want a clean launch on stage, run it yourself:

```bash
./bin/notes-app
```

**[CAPTURE] the app opening.** Left pane lists the six notebooks. Middle pane shows the notes with the pinned ones on top. Status line reads `native` next to the sandbox address. Open a note so the Markdown renders in the right pane.

**Line to say:** "Same conversation, same product doc, from an empty directory to this. The app talks straight to the tables the agent designed, and the data on screen is the data act one loaded."

## Optional act three: the API tier and REST mode (Prompt 3)

**Target 4:00.** Run it only when the clock allows, or cut to the recording. The agent puts a MariaDB REST Service in front of the schema, then refactors the working app to run in native or REST mode.

Paste:

```text
Continue in this repository, against the sandbox on port 3310. Write any
database files you create into working/, and keep appending each step's result to
working/RUN_LOG.md.

Put a MariaDB REST Service in front of the notes_app schema, as PRD section 5
describes. Save the REST DDL you run to working/notes_app_rest.sql as a record,
but run it through db.execute_sql one statement at a time, not
db.execute_sql_script, because the REST grammar is session state and each script
statement runs in a fresh session.

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

5. Refactor the notes_app package to the architecture in PRD section 9: move the
   native data access behind the DataSource interface as NativeDataSource, and add
   RestDataSource (httpx against the /notesApp service root) for the endpoints in
   section 5, handling the paginated items/hasMore list shape. Select the backend
   with the NOTES_APP_MODE environment variable, default to native, and add the
   mode and service root URL to .env.example. The status line names the active
   mode and the service root.

6. Run bin/notes-app in native mode and confirm nothing regressed. Then run it
   with NOTES_APP_MODE=rest. No REST router is running, so confirm the app starts,
   shows the connection error on the status line, and does not crash, as PRD
   section 8 requires. Record both runs in working/RUN_LOG.md.
```

**[CAPTURE] the break and recover.** The REST grammar is session state. If any part runs as a script, each statement lands in a fresh session and the grammar breaks partway down. A capable agent works this out after the first failure and reruns one statement per session. Let that failure and recovery play. It is the point.

**Line to say:** "This is the grammar the model is most confidently wrong about, and it is the grammar the skill knows best. Watch it fail once, read the error, and fix itself."

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

`git clean -fdx` clears the generated app, `working/`, the sandbox, the `.venv`, and the `.env`, and leaves the committed `README.md`, `bin/`, `docs/`, and `research/`.

## Recording notes

- Capture the core moments in order: schema landing, app opening. For the optional act, add break and recover, `SHOW REST`, and the two modes.
- Trim the waits between tool calls, but keep any fixture-driven schema fix and the break-and-recover intact. The failure is the evidence.
- The core run is about six and a half minutes. Target a trimmed cut of acts one and two inside 6:30, and a separate optional-act cut inside 4:00, so the whole talk lands near 20 and stays under 25 with or without it.
- Record at the projector font size, not your desk size.
- Keep the file local. Have `working/RUN_LOG.md`, an app screenshot, and, for the optional act, the `SHOW REST` output exported as static slides in case the recording will not play.
