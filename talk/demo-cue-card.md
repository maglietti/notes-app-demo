# Demo cue card: Confidently Wrong

The operating sheet for the live run and for recording it. One agent context runs all three acts, so open one Claude Code session at the repository root and stay in it from the schema to the app. Every prompt below is verbatim from the README, which stays the source of truth. The four capture moments are marked **[CAPTURE]**.

## What the audience watches

Three prompts, three acts, one conversation: the data tier, the API tier, the app. A seed load sits between act one and act two so the app has real data to show. The blocked mass delete (beat 7) is narrated over a captured screenshot, not reproduced live. Do not run an unqualified `DELETE` on stage.

## Pre-flight checklist (before doors, then again before you record)

- [ ] Recording loaded on the laptop and cued to the four capture moments. Never streamed.
- [ ] Sandbox server binary already downloaded (one-time setup), so the act-one deploy runs offline and instant with no mid-talk download.
- [ ] Port 3310 is free, with no leftover sandbox process from a prior run holding it. Delete any leftover before doors (`sandbox.delete` on port 3310).
- [ ] MCP allowed-paths include the repository root (`mariadb-shell -- mcp setup`).
- [ ] `ai-plugins` installed and the skills confirmed loaded (smoke test below).
- [ ] Terminal font sized for the projector. Test from the back row.
- [ ] Tree is clean and re-runnable: `git clean -fdx` has been run, `docs/` and `research/` intact.
- [ ] Password is `demo-pw` throughout: the act-one deploy sets it, and the app's `.env` (generated in act three) must carry the same value, so the native client connects. `.env` is generated output, so a clean tree will not have it until act three builds the app.

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

**Target 3:30.** The authentic design beat. A short prompt is all the agent gets, and the schema is its own work.

Paste:

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

**[CAPTURE] the schema landing.** As the DDL scrolls, call out the current-MariaDB idioms and what they mean:

- `CREATE OR REPLACE TABLE` and `utf8mb4` with a `uca1400` collation. Today's server, not a MySQL habit.
- `WITH SYSTEM VERSIONING` on `account` and `notebook`. Row history built into the table.
- `id uuid DEFAULT uuid_v7()`. A key that sorts by time and does not leak row counts.
- `FULLTEXT (title, body)` on `note`. Search without a second system.
- `default_flag` generated column. One default notebook per account, enforced by the schema.

**Check.** The tables list, and the `note` columns match the fields above. On a free run expect a little drift, such as an owner table named `user`. Drift is a finding, not a failure. Compare against `research/notes_app.sql` off stage if you want the side-by-side.

**Line to say:** "No SQL by hand. The agent reached for grammar this model was never trained on, because a skill handed it the current version."

## Seed load (between acts, ~0:30)

Not a design prompt. A direct load that puts the frozen version of that same design and its sample data on the sandbox, so the API and the app run on the schema they were written for and there is real data on screen.

Paste:

```text
Deploy research/notes_app.sql onto the sandbox on port 3310, replacing the schema
from the design run, then load research/synthetic_data.sql. The fixture is fully
qualified and self-contained, so db.execute_sql_script loads it in one call. Report
the row count of each notes_app table and record it in working/RUN_LOG.md.
```

**Check.** 61 notes: 48 active with 6 pinned, 7 archived, 6 trashed, plus 6 notebooks and 12 tags. Enough to show archive and trash views, pinned sorting, tag filters, search, and pagination past 25 per page.

**Line to say:** "I swap the live design for its frozen twin and load sample data, so the rest of the run is the same every time."

## Act two: the API tier (Prompt 2)

**Target 2:30.** The tier the talk is named for, and the sharpest evidence for skills.

Paste:

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

**[CAPTURE] the break and recover.** The REST grammar is session state. If any part runs as a script, each statement lands in a fresh session and the grammar breaks partway down. A capable agent works this out after the first failure and reruns one statement per session. Let that failure and recovery play. It is the point.

**Line to say:** "This is the grammar the model is most confidently wrong about, and it is the grammar the skill knows best. Watch it fail once, read the error, and fix itself."

**[CAPTURE] the metadata.** `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. State the boundary in one sentence and move on:

**Line to say:** "The endpoints are defined right here in the metadata. Serving them over HTTP is a router, and that router is a separate job I did not stand up today. Knowing where the agent's work stops is the whole idea."

## Act three: the application (Prompt 3)

**Target 2:30.** The finale. The same context reads the product doc and builds the client, then runs it.

Paste:

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

The build ships `.env.example`, not `.env`. For the native run to reach the seeded data, `.env` must exist at the repository root with the sandbox password `demo-pw`. If the build left only `.env.example`, copy it and set the password before launching.

If the build finishes but you want a clean launch on stage, run it yourself:

```bash
./bin/notes-app
```

**[CAPTURE] the app opening.** Left pane lists the six notebooks. Middle pane shows the notes with the pinned ones on top. Status line reads `native` next to the sandbox address. Open a note so the Markdown renders in the right pane.

**Line to say:** "Same conversation, from an empty directory to this. The app talks straight to the tables in native mode, so this is a working client on the schema the agent designed, not proof of the REST tier. That line matters, so I am drawing it."

## Beat 7: the blocked mass delete (narrated over a screenshot, not live)

Show the captured refusal. Do not reproduce it on stage. What happened, during a reseed while building this demo:

```sql
DELETE FROM notes_app.account
```

The refusal:

> Permission for this action was denied by the Claude Code auto mode classifier.
> Reason: [Cloud Storage Mass Delete].

**Lines to say:** "The database would have run this. No `WHERE`, the whole table, cascading to five more. The connected account had the privilege. It never reached the server. The harness stopped it above the grants. Least-privilege accounts and action controls are separate layers, and a DBA wants both."

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

- Capture the four marked moments in order: schema landing, break and recover, `SHOW REST`, app opening.
- Trim the waits between tool calls, but keep the break-and-recover intact. The failure is the evidence.
- Full run is about five minutes. Target a trimmed cut that fits acts one through three inside 8:30, so the whole talk lands near 20 and stays under 25.
- Record at the projector font size, not your desk size.
- Keep the file local. Have `working/RUN_LOG.md`, the `SHOW REST` output, and an app screenshot exported as static slides in case the recording will not play.
