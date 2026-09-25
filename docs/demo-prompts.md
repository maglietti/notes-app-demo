# Notes App demo prompts

Three prompts, run in order in one agent session, each pasted into the coding agent. Prompt 1 builds and seeds the data tier, and Prompt 2 builds the Textual client that runs on it. Prompt 3 is optional: it puts a REST Service in front of the schema and adds a REST backend beside the native one, so the client runs in native or REST mode. The talk runs Prompts 1 and 2 on stage, and runs Prompt 3 off stage only, to capture the `SHOW REST VIEWS` output for its REST slide. The cue card, [`talk/demo-cue-card.md`](../talk/demo-cue-card.md), is the source of truth for these prompts, and this file and the README carry copies of them.

Run the agent from the repository root, where the layout keeps inputs apart from output:

- The agent reads two inputs: the spec, [`talk/notes-app-spec.md`](../talk/notes-app-spec.md), and the seed fixture, `research/synthetic_data.sql`. `research/` also holds the reference schema and the earlier PRD, and Prompt 1 tells the agent not to read either.
- The Textual app is generated at the repository root as a `notes_app` package with a `pyproject.toml`, laid out like any normal Python project.
- `working/` holds the working artifacts: the schema SQL, the REST DDL, the sandbox data directory, and a `working/RUN_LOG.md` that records each step.

Add the repository root to the MCP allowed paths so the agent can read the spec and the fixture, write `working/`, and create the app at the root. The sandbox is deployed with its data directory under `working/sandbox`, so everything the demo generates stays inside the repository.

The prompts name the artifact they want, number the steps, and say "in order" wherever the sequence is a hard constraint, because an agent lands the work more reliably that way. Prompts 1 and 2 point at the spec instead of restating it, so the spec stays the single description of the app, and each ends by asking the agent to check its work against the spec's "Done when" list. A prompt carries only the slice to build, where to write, the order, and a few hard constraints. The spec is deliberately minimal, the one a developer writes to take an idea to a working app, so it says what the app does and never how MariaDB should do it. The REST Service is not in the spec, so Prompt 3 carries its own requirements, like a later coding session.

---

## Prompt 1: The data tier (schema, sandbox, and seed)

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Turn the data model in talk/notes-app-spec.md into MariaDB DDL for the
   notes_app schema, saved as working/notes_app.sql. Work from the spec alone:
   do not read research/notes_app.sql or research/notes_app-prd.md.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Seed it by loading research/synthetic_data.sql with db.execute_sql_script.
   The fixture is the data contract: if it fails, fix working/notes_app.sql and
   redeploy. Never edit the fixture.
4. Check the result against the first "Done when" item in the spec, and report
   each table's row count.
```

What to check. The five tables in the spec exist, and the seed reports 61 notes (48 active with 6 pinned, 7 archived, and 6 trashed), 6 notebooks, and 12 tags. If the fixture forces a schema fix, that is a finding, not a failure: the contract working as intended.

---

## Prompt 2: The application (the Textual client, native mode)

```text
Build the app that talk/notes-app-spec.md describes, on the schema in
working/notes_app.sql. Build every Must have, and leave the Later items.

- bin/notes-app is the committed launcher. Read it, and make the app work
  with it.
- Write .env with the sandbox password demo-pw, plus a .env.example, at the
  repository root.
- Keep working/ for the schema, run log and sandbox only.

Check the app against the "Done when" items in the spec, and record each
command and its result in working/RUN_LOG.md.
```

What to check. `bin/notes-app` starts the app. The left pane lists the six notebooks, the middle pane shows the seeded notes with the pinned ones at the top, and the status line shows where the app is connected.

---

## Prompt 3 (optional): The API tier and REST mode

```text
Continue against the sandbox on port 3310. Keep database files in working/, and
append each step's result to working/RUN_LOG.md. Complete the steps in order.

1. Put a MariaDB REST Service in front of the notes_app schema: service
   /notesApp, schema /notes, and three views. /note allows read, insert,
   update and delete, and nests each note's tag names read-only. /notebook
   allows read, insert and update. /tag is read-only. Mark every view
   AUTHENTICATION NOT REQUIRED, because this is a local demo. Save the DDL to
   working/notes_app_rest.sql, but run it with db.execute_sql one statement at
   a time: the REST grammar is session state, and db.execute_sql_script gives
   each statement a fresh session.
2. Publish the service. Confirm with SHOW REST SERVICES, SCHEMAS and VIEWS that
   every endpoint exists, and log the output. Run SHOW CREATE REST VIEW /note
   and report whether the nested tag objects came back read-only. If they did
   not, log it and move on: do not patch the REST metadata.
3. Add a REST backend to the app beside the native one, selected by
   NOTES_APP_MODE (default native), and show the active mode on the status line.
4. Run bin/notes-app in native mode, then with NOTES_APP_MODE=rest. No server is
   serving the endpoints, so REST mode must show the connection error and stay
   up. Log both runs.
```

What to check. `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. On mariadb-shell 26.9.3, expect the agent to report that `SHOW CREATE REST VIEW /note` shows the nested tag objects as writable: the shell stores them with the parent view's operations whatever the DDL says (see `docs/decisions.md`, "REST tier"). The endpoints are defined before any router serves them, because the metadata is the API definition. In REST mode the status line names `rest` and the service root, shows a connection error, and the app stays up.

---

## After the prompts

- **Where things land.** The app is a `notes_app` package at the repository root. The schema, the REST DDL, the sandbox data, and `RUN_LOG.md` sit under `working/`, and the inputs the agent read stay in `talk/` and `research/`.
- **REST mode needs a router.** Serving `/notesApp` over HTTP is a MySQL-Router-family binary bootstrapped against the metadata, and it is neither a shell command nor an MCP tool, so standing one up is out of band. The REST server expected in `mariadb-shell` is not ready yet. Native mode is the reliable demo path, so switch to `NOTES_APP_MODE=rest` against live endpoints only once a router is running and verified.
- **The sandbox outlives the conversation.** Stop and delete it when done with `sandbox.stop(port=3310, password="demo-pw", sandbox_dir="working/sandbox")` and then `sandbox.delete(port=3310, sandbox_dir="working/sandbox")`.
