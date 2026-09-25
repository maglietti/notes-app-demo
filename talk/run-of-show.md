# Run of show: Confidently Wrong

**Talk:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway
**Slot:** All Things Open 2026, Tuesday, Databases track, Room 306A, 10:30-11:00.
**Budget:** 20 minutes is the soft target. 25 is the ceiling if the demo needs the room. Q&A fills the rest and ends slightly early. Never run over 25.
**Audience:** DBAs and developers who write or review SQL. Intermediate. No AI background assumed.

## The message (spine)

MariaDB's `ai-plugins` let a developer prototype a real application idea against the **current** MariaDB server, from a handful of prompts, without becoming a version expert and without standing up infrastructure by hand. The tooling does three things:

1. **Removes version variation.** Skills carry today's MariaDB grammar, not a two-year-old training snapshot, so the agent reaches for current idioms.
2. **Ends the MySQL guessing.** Skills give the model the MariaDB constructs it otherwise conflates with MySQL and gets confidently wrong.
3. **Keeps the developer on the application, not the plumbing.** The sandbox brings its own MariaDB server, with no Docker and no root, so the developer and the model spend their attention on the app.

The working practice that makes it repeatable is **spec-driven development**. Skills stop the agent guessing about MariaDB, and a spec stops it guessing about the app: what to build, and how the agent knows it is done. The spec is the second of the two changes the opening promises.

MariaDB stays the point. The database does real work in this demo: system versioning, `UUID_v7()`, `FULLTEXT`, generated columns, and REST Service DDL. The tooling puts that work within reach of an agent. It does not stand in for it.

## The runbook is the spine, framed by a spec and told in two acts

The prompts on the cue card are the acts, and one agent context runs them both. Before the acts, a two-minute spec beat shows the practice: the one-line prompt that drifted, the spec that replaced it, and the acceptance criteria that tell the agent when it is done. Act one then turns the spec's data model into a schema, seeds it, and reports against the data criteria. Act two reads the same spec, builds the client on that data, and reports against the app criteria. The audience watches a single conversation carry an idea from a spec to a running app, with the agent checking its own work at each step. That continuity is the story: you do not hand the work between tools, you keep talking to one agent and it keeps closing its own loop.

The REST tier left the stage. The app does not consume the endpoints, and the server that would serve them is not ready yet, so a live act spent its time on caveats. A static beat of about 45 seconds keeps the title's promise: the `SHOW REST VIEWS` output from an off-stage run of Prompt 3, and one sentence on the boundary. The finale is the app.

## Room context (Day 2, first breakout after the keynotes)

- The Day 2 keynotes run hot on agent hype: Angie Jones "The Maintainer's Dilemma," Lena Hall "The Anything Trap," and "Software's iPhone Moment." This is the first breakout after them, so it opens as the grounding counterpoint. Not "agents change everything," but "here is what one agent did against a real database in minutes, and here is where it stops."
- Head-to-head same slot: Angie Jones, "Skill Issue: Why Your AI Agent Still Sucks" (Ballroom B), a bigger draw on the same theme. This talk wins the room by being the concrete, verified one. Protect that edge: keep the framing tight and let the demo carry the argument.
- Closing keynote: Quincy Larson, "How to Use Scaffolding to Make Your Coding Agents Less Dumb." The same thesis, restated hours later. Name it in the takeaways.

## The framing anchors (non-negotiable)

1. The API tier is **defined in the metadata** by an optional prompt run off stage. Say so. Do not claim the endpoints answer over HTTP, and do not imply the REST prompt ran live.
2. The app runs in **native mode** and does not run on the REST tier. Never present the running app as proof of the tier.
3. The server that would serve REST over HTTP is not ready yet. State that boundary in one sentence. Naming where the agent's competence stops is the talk modeling its own thesis.
4. Spec-driven development is shown with **evidence from the run**: the drift story, real lines from the spec, and the agent's acceptance-criteria reports. Keep it a practice, not a methodology pitch.

## Timed beats (~20:45)

| #   | Beat                                    | Target | Running | What happens |
| --- | --------------------------------------- | ------ | ------- | ------------ |
| 1   | Opening hook                            | 2:00   | 2:00    | Two changes to how I work with an agent made a crazy idea work. The Larry Page line, the idea itch, and the terminal notebook the audience should picture as real. |
| 2   | The frictions                           | 2:00   | 4:00    | Vibe coding hands you fluent, wrong SQL: MySQL habits (`UUID_TO_BIN`, plain `utf8`, `LAST_INSERT_ID()`) and an hour of plumbing. Put current MariaDB's payoff on the table: system versioning, `UUID_v7()`, `FULLTEXT`, generated columns. |
| 3   | The frame: skills and tools             | 2:30   | 6:30    | Skills carry the current grammar as reviewed Markdown, and tools carry the MCP connection and the sandbox. Name the plugins and how to get them. The first change: it fixes what the agent knows about MariaDB. |
| 4   | The spec                                | 2:00   | 8:30    | The second change. A one-line prompt gave fine SQL with drifting names (`user` for `account`), so the app broke downstream. The spec says what each column does, never the syntax, gives each requirement an ID, and ends in acceptance criteria. Show real lines from the PRD. Skills stop the guessing about MariaDB, a spec stops the guessing about the app. Anchor 4. |
| 5   | Act one: the data tier (Prompt 1)       | 4:00   | 12:30   | The agent turns the data model in PRD section 4 into DDL, deploys the sandbox on 3310, runs the DDL over MCP, loads the fixture as the data contract, and reports AC-D1 to AC-D4. Call out the MariaDB idioms as they land. The spec describes behaviour, not syntax, so the idioms are the agent's choice, and the proof is the server, the fixture, and the passing report. |
| 6   | Act two: the application (Prompt 2)     | 2:30   | 15:00   | The same context reads the same spec, builds the Textual client, and reports AC-A1 to AC-A5 from both the launcher and the installed command. The three-pane app opens on the data act one loaded. Name the mode plainly: native, straight to the tables, not proof of a REST tier. The finale. Anchor 2. |
| 7   | The REST boundary                       | 0:45   | 15:45   | The static `SHOW REST VIEWS` slide from the off-stage Prompt 3 run. The API is defined in the metadata, the server that would serve it is not ready yet, and the app does not call it. One sentence, then move on. Anchors 1 and 3. |
| 8   | Agent security: the blocked mass delete | 1:30   | 17:15   | The real incident. `DELETE FROM notes_app.account`, no `WHERE`, cascading to five tables. The database would have run it, the account had the privilege, and the harness classifier stopped it above the grants. |
| 9   | The bigger shift                        | 1:30   | 18:45   | Widen from MariaDB to the room. The projects agents work well against publish their knowledge for agents: `llms.txt`, raw Markdown, MCP interfaces, `?ask=` doc endpoints. `ai-plugins` carries that into the coding loop as skills. |
| 10  | Takeaways and the Quincy callback       | 2:00   | 20:45   | Skills, a spec with acceptance criteria, and tools first, then name the artifact, layered guardrails, and greenfield first. Close by naming Quincy Larson's keynote: you will hear this thesis again this afternoon. |
| Q&A | Q&A buffer                              | ~8:15  | ~29:00  | Fill the balance of the slot and release the room a minute early. |

## How the time is weighted

The acts are the talk. The framing before them stays tight so the demo carries the argument and the concrete-over-hype edge holds against the competing session. The spec beat earns its two minutes because the acts pay it off: each act ends in an acceptance-criteria report the audience can see. The REST beat is kept to 45 seconds because it carries a promise, not evidence. The augmentation story splits: a short frame in beats 3 and 4, then the real weight while the agent works in the acts.

## Fallback plan (first slot, cold AV and wifi): record first

The acts (beats 5 and 6) are the only parts exposed to AV and network risk, and this is the first slot after the keynotes, so the recording is the primary path and live is the stretch.

1. **Recorded run, narrated (primary).** A screen capture of the last clean run of acts one and two, trimmed to the schema landing, the AC-D report, the app opening, and the AC-A report. Narrate over it live. Keep it local on the laptop, never streamed.
2. **Warm live, if AV cooperates.** Pre-deploy the sandbox on 3310 before doors open so no cold `sandbox.deploy` runs on stage. The agent still writes the schema live, and act one's prompt reuses a running sandbox. Choose the path at the podium, based on the room.
3. **Static evidence.** `working/RUN_LOG.md` with both acceptance-criteria reports, the `SHOW REST` output from the off-stage Prompt 3 run, and a screenshot of the running app as slides, so the claims hold with no terminal at all.

The Textual app runs offline against the local sandbox, so act two is network-safe whichever path act one takes. Native mode is the default, which is why.

Pre-flight checklist lives in `demo-cue-card.md`: recording loaded and cued to the capture moments; no leftover sandbox on 3310, unless you pre-deployed one for the warm-live path; MCP allowed-paths set to the repo root; terminal font sized for the projector; `git clean -fdx` state confirmed so the tree is re-runnable.
