# Run snapshot: 2026-09-25

This branch captures a full run of the demo prompts: pi as the harness, Claude Opus 5.5 as the model, Prompts 1 and 2, native mode only. Unlike the scoped snapshot the main README describes, it commits every generated file, including the gitignored ones: the `notes_app/` package, `pyproject.toml`, `uv.lock`, `.env.example`, the `.venv`, the `working/` artifacts, and the MariaDB sandbox with its data. The pi session export, `pi-session-2026-09-25-claude-opus-5-5.html`, records the run itself.

The sandbox data directory holds the `notes_app` schema already loaded with the seed fixture, so the app runs without re-running any prompt. You only need to start the server again, recreate `.env`, and launch the app.

## What this snapshot depends on

The sandbox is not portable. The plugin that deployed it wrote absolute paths into its option file and scripts, so three things must match the machine that made the run:

- **The checkout path.** `working/sandbox/3310/my.cnf`, `start.sh`, and `stop.sh` all point at `/Users/maglietti/Code/magliettiGit/notes-app-demo`. Check the branch out at that path, or edit the `datadir`, `log_error`, and `socket` lines in `my.cnf` and the paths in both scripts to match your checkout.
- **The server binary.** The server itself is not in the repository. `start.sh` runs `/Users/maglietti/.local/share/mariadb-sandbox-server/11.8.9/bin/mariadbd`, which the `sandbox.*` tools of the `mariadb-shell` plugin downloaded on first deploy. If that directory is gone, deploy any 11.8 sandbox once through the agent to download it again, then delete that sandbox.
- **The Python interpreter.** The committed `.venv` links to the uv-managed CPython 3.11 under `~/.local/share/uv/python/`. If that interpreter is missing, `uv run` rebuilds the `.venv` from `uv.lock`, so no manual step is needed.

## Restart the sandbox

1. Check out the branch:

   ```bash
   git switch run/2026-09-25
   ```

2. Make sure nothing else is listening on port 3310, such as the sandbox from a newer run. This prints nothing when the port is free:

   ```bash
   lsof -nP -iTCP:3310 -sTCP:LISTEN
   ```

   If a server is listening, stop it first with the `stop.sh` of the sandbox it belongs to, or ask the agent to stop the sandbox on port 3310.

3. Remove the PID file captured with the snapshot. It holds the process ID of the server that was running when the snapshot was taken. Left in place, it points `stop.sh` at whatever process now has that ID, and `stop.sh` would kill it:

   ```bash
   rm -f working/sandbox/3310/3310.pid
   ```

4. Start the server. The script runs `mariadbd` in the background and returns at once:

   ```bash
   working/sandbox/3310/start.sh
   ```

   The snapshot copied the data directory while the server was running, so the first start runs InnoDB crash recovery. It takes a few seconds, and the server logs it to `working/sandbox/3310/sandboxdata/error.log`.

5. Confirm the server is up. Run the `lsof` command from step 2 again and look for a `mariadbd` line. If none appears after about 10 seconds, read the end of the error log:

   ```bash
   tail -20 working/sandbox/3310/sandboxdata/error.log
   ```

## Run the app

1. Recreate `.env`. It was deliberately left out of the snapshot, and the app reads the database password from it. The sandbox root password is `demo-pw`, as the main README and `working/RUN_LOG.md` record:

   ```bash
   sed 's/^NOTES_APP_DB_PASSWORD=$/NOTES_APP_DB_PASSWORD=demo-pw/' .env.example > .env
   ```

2. Launch the app with the repository's launcher:

   ```bash
   ./bin/notes-app
   ```

   The left pane lists six notebooks, with Inbox marked as the default. The middle pane shows the 8 Inbox notes, and `★ Reset sandbox before rehearsal` sits first because it is pinned. The status line reads `native · mariadb://root@127.0.0.1:3310/notes_app · Inbox · Active · 8 notes`. Press `q` to quit.

If the status line shows `error: ... Can't connect to server on '127.0.0.1'`, the sandbox is not running. Go back to step 5 of the previous section.

## Stop the sandbox

When you are done, stop the server:

```bash
working/sandbox/3310/stop.sh
```

Stop it before you switch back to `main`. Switching branches removes the committed data directory from your working tree, and a server still running would lose its files while it is still using them.

A running server writes to its data directory, and so does every note you create, edit, or delete in the app, so `git status` soon shows modified files under `working/sandbox/`. To return to the captured state, stop the server and run `git restore working/sandbox`, then repeat step 3 of Restart the sandbox before the next start.
