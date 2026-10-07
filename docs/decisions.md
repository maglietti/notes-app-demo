# Decisions

The choices behind this demo and its talk, and why. Newest last. Each entry is the decision and the reason, not the whole debate. The log before 2026-10-07 is preserved at the `pre-rebaseline` tag.

## Rebaseline (2026-10-07)

- **The talk layer was rebuilt, and the evidence was kept.** The deck, outline, run of show, and cue card were built around two live acts and a REST finale, and every later change was patched onto that shape. The demo harness underneath (the spec, the fixture, the launcher, two thin prompts) and the experiments were kept. Everything removed is at the `pre-rebaseline` tag.
- **The talk follows the audience's path: I had an idea, a fresh environment, something works.** The story of how the old PRD grew into an answer key (experiment 1) is project history, not that path, so it left the talk and the repository.
- **Story first, demo last.** A 30-minute slot is short, and a live act that depends on a hosted LLM is a risk in the first slot of the day. The talk tells the story with evidence from the experiments, then shows the run at the end if time permits: a recorded cut, then the app live against the local sandbox, which needs no LLM call.
- **The experiments run again on current versions before a slide cites them.** They ran on `dev@mariadb` 26.9.2. The plugin is now 26.10.0, with more skills, a reworked MCP server, and the DevHub at `ai-plugins.mariadb.org`.
- **The REST mode in the app is gone.** It could only report that nothing serves the endpoints. The REST Service DDL becomes an experiment instead: the least-trained grammar in the stack, with and without skills.
- **One copy of the prompts, in the README.** The cue card, the README, and `docs/demo-prompts.md` each carried a copy, and the copies drifted.
- **No local copy of the plugin architecture.** `docs/stack-layering.md` drifted from upstream within weeks (tool counts, layer details). The README links to the DevHub instead.

## Carried forward

- **The repository tracks the instructions, not the app.** Everything the prompts or the agent produce is gitignored, so `git clean -fdx` returns the tree to a clean, re-runnable state.
- **`bin/notes-app` is the stable launcher.** It runs `python -m notes_app` against whatever the agent generated, so the stage command never changes.
- **The fixture is the data contract.** `research/synthetic_data.sql` is committed, deterministic, and idempotent. When it fails to load, the agent fixes the schema and never edits the fixture.
- **The spec says what the app does, never how MariaDB should do it.** The MariaDB idioms in a generated schema must come from the skills, or the experiments prove nothing.
- **The title and abstract are locked, and the spoken claim is corrected.** The abstract says the run validates the REST endpoints. The REST Service is defined in metadata, and the server that would serve it is not ready yet. On stage, the claim is "defined, not served".
