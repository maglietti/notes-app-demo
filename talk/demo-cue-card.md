# Demo cue card: Confidently Wrong

The operating sheet for the live run and for recording it. One agent context runs every act, so open one Claude Code session at the repository root and stay in it from the schema to the app. The prompts below are the source of truth: change them here first, prove the run, then copy them into the README, `docs/demo-prompts.md`, and the act slides. The capture moments are marked **[CAPTURE]**.

## What the audience watches

Two prompts, two acts, one conversation: the data tier, then the app. Both acts start from the same spec, `talk/notes-app-spec.md`, so the schema the agent designs is the schema the app is built on, and each act ends with the agent checking its work against the spec's "Done when" list. Act one seeds the database, so the app has real data to show. Prompt 3, which puts a REST Service in front of the schema, runs off stage only, to capture the `SHOW REST VIEWS` output for the REST slide.

## Running this card as an agent walkthrough

To rehearse, open a fresh Claude Code session at the repository root and say: "Walk through talk/demo-cue-card.md as a rehearsal." Add "including Prompt 3" to run the off-stage REST prompt. The rest of the card is written for the presenter, and an agent follows these five rules instead:

1. **Check the pre-flight, change nothing.**
   - Confirm the MariaDB MCP tools (`sandbox.*`, `db.*`) and the MariaDB skills are available, then run the skills smoke test from One-time setup yourself and check the output for the tells it lists. If the tools or skills are missing, stop and report it, because installing the plugin and running `mariadb-shell -- mcp setup` are interactive steps only the presenter can do.
   - If a sandbox is running on port 3310, ask before stopping and deleting it.
   - If generated files exist (`notes_app/`, `pyproject.toml`, `uv.lock`, `.env`, `.env.example`, `.venv/`, or `working/`), list them and ask the presenter to run `git clean -fdx`, then wait. Do not run git yourself.
   - Skip the presenter-only items: the terminal font, the recording, and the pre-cache step. Act one's pinned deploy downloads MariaDB 11.8 if it is not cached yet.
2. **Run the acts in order, in this one session.** Treat each **Paste** block as the presenter's next message and follow it exactly. Log each act's start and end time (from `date`) in `working/RUN_LOG.md`, so the rehearsal can be compared with the act's target.
3. **Check each act before starting the next.** Check only what the act's **Check** paragraph and **[CAPTURE]** notes name, from output the act already produced: the idioms in the DDL, the agent's row counts against the spec, its "Done when" check for the app, and, for Prompt 3, the `SHOW REST` output and the `/note` read-back report. Record whether each item held. Do not drive the app's features or write to the seeded data, because testing beyond the prompt's own verification inflates the act's time and changes the fixture. Skip the **Line to say** and the manual `./bin/notes-app` launch.
4. **Run Prompt 3 only when asked.** Otherwise stop after act two.
5. **Report and stop.** Finish with a table of the acts: elapsed time against target, checks that passed or failed, and anything you had to fix along the way. Leave the sandbox and the generated files in place for inspection. Run the Cleanup section only when asked, and leave its `git clean -fdx` to the presenter.

## Pre-flight checklist (before doors, then again before you record)

- [ ] `ai-plugins` installed and the skills confirmed loaded (smoke test below).
- [ ] MCP allowed-paths include the repository root (`mariadb-shell -- mcp setup`).
- [ ] MariaDB 11.8 server already downloaded (one-time setup), so the act-one deploy runs offline with no mid-talk download.
- [ ] No sandbox on port 3310. Stop and delete any leftover from a rehearsal (`sandbox.stop`, then `sandbox.delete`), so step 2 of Prompt 1 finds nothing and deploys fresh on stage.
- [ ] Tree is clean: `git clean -fdx` has been run after the sandbox was deleted, and `talk/` and `research/` are intact.
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

Point the MCP server at the repository root so it can read the spec and the fixture, write `working/`, and reach the sandbox:

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

**Target 4:00.** The spec pays off. The agent reads the spec, turns its data model into current MariaDB DDL, deploys it to a fresh sandbox, seeds it, and checks the row counts against the spec.

Paste:

```text
Work in this repository and complete every step in order. Write your files to
working/, and append a short record of each step to working/RUN_LOG.md.

1. Turn the data model in talk/notes-app-spec.md into MariaDB DDL for the
   notes_app schema, saved as working/notes_app.sql. Work from the spec alone:
   in research/, read only synthetic_data.sql.
2. If no MariaDB 11.8 sandbox is running on port 3310, deploy one there with
   root password demo-pw and data directory working/sandbox. Run
   working/notes_app.sql on it via the MCP server.
3. Seed it by loading research/synthetic_data.sql with db.execute_sql_script.
   The fixture is the data contract: if it fails, fix working/notes_app.sql and
   redeploy. Never edit the fixture.
4. Check the result against the first "Done when" item in the spec, and report
   each table's row count.
```

**[CAPTURE] the schema landing.** The spec names no MariaDB features, so every idiom in the DDL is the agent's choice. As the DDL scrolls, call out the ones that land and what they mean. Typical ones, which vary by run:

- `CREATE OR REPLACE TABLE` and `utf8mb4` with a `uca1400` collation. Today's server, not a MySQL habit.
- `id uuid DEFAULT uuid_v7()`. A key that sorts by time and does not leak row counts.
- `FULLTEXT (title, body)` on `note`. Search without a second system.
- A generated column or a unique key that allows one default notebook per account.

**[CAPTURE] the "Done when" check.** The agent's step 4 reports the row counts against the spec. Hold on it: this is the spec beat's promise, kept.

**Check.** The five tables in the spec exist, and the seed reports 61 notes: 48 active with 6 pinned, 7 archived, 6 trashed, plus 6 notebooks and 12 tags. Enough to show archive and trash views, pinned sorting, tag filters, search, and pagination past 25 per page. If the fixture fails first time, let the agent fix the schema and reload. A schema that bends to the contract is a finding, not a failure.

**Line to say:** "No SQL by hand. My spec says what the app stores, never the syntax. The agent turned it into current MariaDB grammar, with a skill in the room, proved the schema by loading real data into it, and graded itself against my definition of done."

## Act two: the application (Prompt 2)

**Target 2:30.** The finale. The same context reads the same spec, builds the client in native mode, runs it on the data it just seeded, and checks it against the spec's "Done when" list.

Paste:

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

The build writes `.env` with the sandbox password `demo-pw`, which the native run needs to reach the seeded data. If `.env` is missing, copy `.env.example` and set the password before launching.

If the build finishes but you want a clean launch on stage, run it yourself:

```bash
./bin/notes-app
```

**[CAPTURE] the app opening.** Left pane lists the six notebooks. Middle pane shows the notes with the pinned ones on top. Status line reads `native` next to the sandbox address. Open a note so the Markdown renders in the right pane.

**[CAPTURE] the "Done when" check.** The agent records that `bin/notes-app` opens and shows the notebooks and notes, pinned ones on top.

**Line to say:** "Same conversation, same spec, from no app code to this. The app talks straight to the tables the agent designed, and the data on screen is the data act one loaded."

## Off stage: the API tier and REST mode (Prompt 3)

**Not in the talk.** Run it once, off stage, in the same session after act two, to capture the `SHOW REST VIEWS` output for the REST slide (slide 16). The agent puts a MariaDB REST Service in front of the schema, reads the `/note` view back, and adds a REST backend beside the native one. On stage, the REST beat is that static slide and one boundary sentence, about 45 seconds.

Paste:

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

**[CAPTURE] for the REST slide.** Save the `SHOW REST VIEWS` output, which lists `/note`, `/notebook`, and `/tag` under `/notesApp`. That output is the whole on-stage REST beat.

**Expect the read-back mismatch.** On mariadb-shell 26.9.3, `SHOW CREATE REST VIEW /note` shows the nested `noteTag` and `tag` objects with `@INSERT @UPDATE @DELETE`, even though the DDL says `@NOINSERT @NOUPDATE @NODELETE`. The grammar accepts the flags, but the shell stores each nested object with the parent view's operations (`plugins/mrs_plugin/lib/db_objects.py:762`), so no DDL can make them read-only. The prompt asks for a report, not a fix. Re-check on any newer shell. The slide's speaker notes hold an optional one-line mention of it.

**Expect REST mode to report the missing server.** The status line flips from `native` with the sandbox address to `rest` with `/notesApp` and a connection error, and the app stays up. The server that would serve the endpoints is not ready yet.

## Cleanup (after the run, off the clock)

The sandbox is a real process that outlives the conversation, so stop and delete it first, then reset the tree. Snapshot the run first if you want to keep it (README, "Capturing a run for comparison").

```text
Stop and delete the sandbox on port 3310.
```

```bash
git clean -fdx
```

`git clean -fdx` clears the generated app, `working/` with the sandbox data directory, the `.venv`, and the `.env`, and leaves the committed `README.md`, `bin/`, `docs/`, `research/`, and `talk/`.

## Recording notes

- Capture the moments in order: schema landing, the row-count check, app opening, the app check. From the off-stage Prompt 3 run, keep only the `SHOW REST VIEWS` output, for the static slide.
- Trim the waits between tool calls, but keep any fixture-driven schema fix intact. A failure the agent fixes is evidence.
- The two acts are about six and a half minutes. Target a trimmed cut of acts one and two inside 6:30, so the whole talk lands near 21 and stays under 25.
- Record at the projector font size, not your desk size.
- Keep the file local. Have `working/RUN_LOG.md` with both reports, an app screenshot, and the `SHOW REST` output exported as static slides in case the recording will not play.
