# Notes App — demo prompts

Three prompts, run in order, each pasted into the coding agent. Prompt 1 builds the
data tier, Prompt 2 puts the REST tier in front of it, Prompt 3 builds the Textual
client that runs on it.

Run the agent from the repository root. The layout separates inputs from output:

- `docs/` and `research/` are inputs the agent reads (the PRD, the reference schema).
- The Textual app is generated at the repository root, as a `notes_app` package with
  a `pyproject.toml`, the way a normal Python project is laid out.
- `working/` holds the working artifacts: the schema SQL, the REST DDL, the sandbox
  data directory, and a `working/RUN_LOG.md` recording each step's result.

Add the repository root to the MCP allowed paths so the agent can read `docs/` and
`research/`, write `working/`, and create the app at the root. The sandbox is
deployed with its data directory under `working/sandbox`, so everything the demo
generates stays inside the repository.

The prompts name the artifact and number the steps, and say "in order" where the
sequence is a hard constraint, because agents land the work better that way.

The entity names in Prompt 1 are fixed on purpose. The REST views in Prompt 2 and
the client in Prompt 3 depend on the tables being named `account`, `notebook`,
`note`, `tag`, `note_tag` and `attachment`. Leaving the schema free to vary is
what breaks the later steps. A reference schema with those names is in
`research/notes_app.sql`.

---

## Prompt 1 — Infrastructure (schema and sandbox)

```text
Work in this repository. Put every file you create in the working/ directory, and
append a short record of each step (the command, and the key result) to
working/RUN_LOG.md as you go. Complete every step in order.

1. Design a MariaDB schema named notes_app for a note-taking application and
   write it to working/notes_app.sql. A reference schema with the names to match
   is in research/notes_app.sql. Use these tables and names exactly:
   - account: a person, with email, display name and password hash.
   - notebook: a folder of notes owned by an account, unique name per account,
     one default per account.
   - note: belongs to a notebook and an account, with a title, a Markdown body,
     a status of active, archived or trashed, a pinned flag, and created and
     updated timestamps.
   - tag and note_tag: free-form labels owned by an account, many-to-many with
     notes through the note_tag junction.
   - attachment: a file pointer for a note (file name, mime type, byte size,
     storage key, uploaded timestamp).
   Make note titles and bodies full-text searchable. Give account and notebook
   row history. Add a view of active notes with their notebook, owner and a
   joined tag list. Use MariaDB idioms throughout.

2. Deploy a MariaDB sandbox on port 3310 with root password demo-pw and its data
   directory at working/sandbox, connect to it, and run working/notes_app.sql over
   the MCP server.

3. List the tables you created and show the columns of the note table to confirm
   the schema is in place. Record the table list in working/RUN_LOG.md.
```

What to check: `working/notes_app.sql` opens and closes with a settings block,
primary keys are native `UUID` with `UUID_v7()`, `account` and `notebook` are
`WITH SYSTEM VERSIONING`, and `note` has a `FULLTEXT` index on `(title, body)`.

---

## Prompt 2 — REST API (the tier the talk is about)

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

What to check: `SHOW REST VIEWS` lists `/note`, `/notebook` and `/tag` under
`/notesApp`. The endpoints are defined even before a router serves them, because
the metadata is the API definition.

---

## Prompt 3 — Front end (the Textual client)

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

What to check: the app starts, the left pane shows the `Inbox` and `DevRel`
notebooks, and the middle pane shows the seeded notes with the pinned one first.
The status line reads `native` and the sandbox address.

---

## After the three prompts

- **Where things land:** the app is a `notes_app` package at the repository root;
  the schema, the REST DDL, the sandbox data and `RUN_LOG.md` are under `working/`;
  the inputs it read stay in `docs/` and `research/`.
- **REST mode needs a router.** Serving `/notesApp` over HTTP is a
  MySQL-Router-family binary bootstrapped against the metadata. It is not a shell
  or MCP command, and standing one up is out of band. Native mode is the reliable
  demo path; switch to `NOTES_APP_MODE=rest` only once a router is running and
  verified.
- **The sandbox outlives the conversation.** Stop and delete it when done:
  `sandbox.stop(port=3310, password="demo-pw")`, then `sandbox.delete(port=3310)`.
