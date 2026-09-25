# Notes App demo prompts

Three prompts, run in order in one agent session, each pasted into the coding agent. Prompt 1 builds and seeds the data tier, and Prompt 2 builds the Textual client that runs on it. Prompt 3 is optional: it puts a REST Service in front of the schema and adds a REST backend beside the native one, so the client runs in native or REST mode. The talk runs Prompts 1 and 2 on stage, and runs Prompt 3 off stage only, to capture the `SHOW REST VIEWS` output for its REST slide. The cue card, [`talk/demo-cue-card.md`](../talk/demo-cue-card.md), is the source of truth for these prompts, and this file and the README carry copies of them.

Run the agent from the repository root, where the layout keeps inputs apart from output:

- `docs/` and `research/` are the inputs the agent reads. They hold the product doc and the seed fixture, plus the reference schema that the app and fixture were frozen from, which the prompts do not read.
- The Textual app is generated at the repository root as a `notes_app` package with a `pyproject.toml`, laid out like any normal Python project.
- `working/` holds the working artifacts: the schema SQL, the REST DDL, the sandbox data directory, and a `working/RUN_LOG.md` that records each step.

Add the repository root to the MCP allowed paths so the agent can read `docs/` and `research/`, write `working/`, and create the app at the root. The sandbox is deployed with its data directory under `working/sandbox`, so everything the demo generates stays inside the repository.

The prompts name the artifact they want, number the steps, and say "in order" wherever the sequence is a hard constraint, because an agent lands the work more reliably that way. Each one points at sections and requirement IDs in [`docs/notes_app-prd.md`](notes_app-prd.md) instead of restating them, so the PRD stays the single description of the app and of how to check it. A prompt carries only the slice to build, where to write, the order, and a few hard constraints, and it ends by asking the agent to report against the acceptance criteria in PRD section 11.

---

## Prompt 1: The data tier (schema, sandbox, and seed)

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

What to check. The agent reports AC-D1 to AC-D4 as passed. The tables match the six tables and one view in PRD section 4, and the seed reports 61 notes (48 active with 6 pinned, 7 archived, and 6 trashed), 6 notebooks, and 12 tags. If the fixture forces a schema fix, that is a finding, not a failure: the contract working as intended.

---

## Prompt 2: The application (the Textual client, native mode)

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

What to check. The agent reports AC-A1 to AC-A5 as passed. Both entry points start the app. The left pane lists the six notebooks, the middle pane shows the seeded notes with the pinned ones at the top, and the status line reads `native` alongside the sandbox address. The console-script check matters because the repository gitignores `notes_app/`, and a build backend that honours `.gitignore` installs a package with no code in it, which `bin/notes-app` alone cannot detect.

---

## Prompt 3 (optional): The API tier and REST mode

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

What to check. The agent reports AC-R1 to AC-R5, with AC-R2 expected to show the mismatch below. `SHOW REST VIEWS` lists `/note`, `/notebook`, and `/tag` under `/notesApp`. On mariadb-shell 26.9.3, expect the agent to report that `SHOW CREATE REST VIEW /note` shows the nested tag objects as writable: the shell stores them with the parent view's operations whatever the DDL says (PRD section 13). The endpoints are defined before any router serves them, because the metadata is the API definition. In REST mode the status line names `rest` and the service root, shows a connection error, and the app stays up.

---

## After the prompts

- **Where things land.** The app is a `notes_app` package at the repository root. The schema, the REST DDL, the sandbox data, and `RUN_LOG.md` sit under `working/`, and the inputs the agent read stay in `docs/` and `research/`.
- **REST mode needs a router.** Serving `/notesApp` over HTTP is a MySQL-Router-family binary bootstrapped against the metadata, and it is neither a shell command nor an MCP tool, so standing one up is out of band. The REST server expected in `mariadb-shell` is not ready yet. Native mode is the reliable demo path, so switch to `NOTES_APP_MODE=rest` against live endpoints only once a router is running and verified.
- **The sandbox outlives the conversation.** Stop and delete it when done with `sandbox.stop(port=3310, password="demo-pw", sandbox_dir="working/sandbox")` and then `sandbox.delete(port=3310, sandbox_dir="working/sandbox")`.
