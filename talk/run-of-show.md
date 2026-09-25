# Run of show: Confidently Wrong

**Talk:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway
**Slot:** All Things Open 2026, Tuesday, Databases track, Room 306A, 10:30-11:00.
**Budget:** 20 minutes is the soft target. 25 is the ceiling if the demo needs the room. Q&A fills the rest and ends slightly early. Never run over 25.
**Audience:** DBAs and developers who write or review SQL. Intermediate. No AI background assumed.

## The message (spine)

MariaDB's `ai-plugins` let a developer prototype a real application idea against the **current** MariaDB server, from a handful of prompts, without becoming a version expert and without standing up infrastructure by hand. The tooling does three things:

1. **Removes version variation.** Skills carry today's MariaDB grammar, not a two-year-old training snapshot, so the agent reaches for current idioms.
2. **Makes the agent write for MariaDB, not for any database.** Without skills, a frontier LLM writes correct, generic SQL that runs anywhere in the MySQL family. With skills, the agent uses what MariaDB does well. Experiments 2 to 4 in `research/experiments/` are the evidence.
3. **Keeps the developer on the application, not the plumbing.** The sandbox brings its own MariaDB server, with no Docker and no root, so the developer and the agent spend their attention on the app.

The working practice that makes it repeatable is **spec-driven development**: a short spec that says what the app does and when it is done, never how MariaDB should do it. The spec is the second of the two changes the opening promises.

**The aha.** A plain agent, given a short spec, writes SQL that is correct, runs, and loads the data. It is also generic, and the agent calls it "safe to run more than once" when a rerun silently ignores a schema fix. With the skills turned on, the same spec gives MariaDB, and a rerun applies the fix. That before and after is the audience's own path: an ordinary agent, a result that looks fine, then discovering the skills. The evidence is in `research/experiments/`.

MariaDB stays the point. The database does real work in this demo: native UUID keys, atomic `CREATE OR REPLACE`, descending indexes shaped to the queries, generated columns, and, off stage, REST Service DDL. The tooling puts that work within reach of an agent. It does not stand in for it.

## The runbook is the spine, framed by a spec and told in two acts

The prompts on the cue card are the acts, and one agent context runs them both. Before the acts, the opening shows a short spec, then what a plain agent built from it: SQL that runs but is generic, and a confident rerun claim that fails. Then the skills, and how to install them. Act one then turns that spec's data model into a schema, seeds it, and checks the counts against the spec's "Done when" list. Act two reads the same spec, builds the client on that data, and checks it against the same list. The audience watches a single conversation carry an idea from a spec to a running app, with the agent checking its own work at each step. That continuity is the story: you do not hand the work between tools, you keep talking to one agent and it keeps closing its own loop.

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

## Timed beats (~19:45)

| #   | Beat                                    | Target | Running | What happens |
| --- | --------------------------------------- | ------ | ------- | ------------ |
| 1   | Opening hook                            | 2:00   | 2:00    | I expected the LLM to be confidently wrong about MariaDB. It was, just not where I expected. The Larry Page line, the idea itch, and the terminal notebook, with the "ask my notes a question" thought planted. |
| 2   | The spec, and a coding agent            | 2:30   | 4:30    | The first change, a habit the presenter already had: instead of vibe coding, write down what the app does in a 48-line spec that ends in "Done when". A coding agent builds the schema from it: the SQL runs and loads the data, and the agent's "safe to run more than once" is wrong, because a rerun silently ignores a fix. No mention of skills or generic SQL yet. Anchor 4. |
| 3   | Skills, tools, and the ai-plugins       | 2:00   | 6:30    | The presenter goes looking for help and finds it: skills carry current MariaDB knowledge into the agent's context, and tools let the agent run what it writes, which is how the ignored fix was found. The second change: install the ai-plugins and turn the skills on. |
| 4   | Act one: the data tier (Prompt 1)       | 4:00   | 10:30   | With the skills on, the agent turns the same spec into DDL, deploys the sandbox on 3310, runs the DDL over MCP, loads the fixture as the data contract, and checks the counts against "Done when". The payoff puts the before and after side by side, and only then names the first version as portable SQL: `CREATE OR REPLACE`, so a fix lands, and an index shaped to "pinned first, newest first". Same LLM, same spec. |
| 5   | Act two: the application (Prompt 2)     | 2:30   | 13:00   | The same context reads the same spec, builds the Textual client, and checks it against "Done when" through the committed launcher. The three-pane app opens on the data act one loaded. Name the mode plainly: native, straight to the tables, not proof of a REST tier. The finale. Anchor 2. |
| 6   | The REST boundary                       | 0:45   | 13:45   | The static `SHOW REST VIEWS` slide from the off-stage Prompt 3 run. The API is defined in the metadata, the server that would serve it is not ready yet, and the app does not call it. One sentence, then move on. Anchors 1 and 3. |
| 7   | Agent security: the blocked mass delete | 1:30   | 15:15   | The real incident. `DELETE FROM notes_app.account`, no `WHERE`, cascading to five tables. The database would have run it, the account had the privilege, and the harness classifier stopped it above the grants. |
| 8   | Agent memory, and the next session      | 2:30   | 17:45   | Both changes were the same move. An agent works from two kinds of memory: what the LLM learned in training, which you cannot change, and the agent's context, where skills, the spec, and memory files go. Then the foreshadow planted on slide 4: the next coding session asks the notes a question, with vector search on the same MariaDB server. A plan, not a demo. |
| 9   | Takeaways and the Quincy callback       | 2:00   | 19:45   | Skills make the agent write for your database, write a spec that ends in "Done when", give the agent tools (running it catches a fix that never landed), name the artifact, set every guardrail, and start on greenfield. Close by naming Quincy Larson's keynote. |
| Q&A | Q&A buffer                              | ~9:15  | ~29:00  | Fill the balance of the slot and release the room a minute early. |

## How the time is weighted

The acts are the talk. The framing before them stays tight so the demo carries the argument and the concrete-over-hype edge holds against the competing session. The opening earns its time because it shows the problem the audience will meet, and act one's payoff answers it with the before and after on one slide. The REST beat is kept to 45 seconds because it carries a promise, not evidence. The augmentation story splits: a short frame in beats 2 and 3, then the real weight while the agent works in the acts. The first recording starts at 6:30.

## Fallback plan (first slot, cold AV and wifi): record first

The acts (beats 4 and 5) are the only parts exposed to AV and network risk, and this is the first slot after the keynotes, so the recording is the primary path and live is the stretch.

1. **Recorded run, narrated (primary).** A screen capture of the last clean run of acts one and two, trimmed to the schema landing, the row-count check, the app opening, and the app check. Narrate over it live. Keep it local on the laptop, never streamed.
2. **Warm live, if AV cooperates.** Pre-deploy the sandbox on 3310 before doors open so no cold `sandbox.deploy` runs on stage. The agent still writes the schema live, and act one's prompt reuses a running sandbox. Choose the path at the podium, based on the room.
3. **Static evidence.** `working/RUN_LOG.md` with both acceptance-criteria reports, the `SHOW REST` output from the off-stage Prompt 3 run, and a screenshot of the running app as slides, so the claims hold with no terminal at all.

The Textual app runs offline against the local sandbox, so act two is network-safe whichever path act one takes. Native mode is the default, which is why.

Pre-flight checklist lives in `demo-cue-card.md`: recording loaded and cued to the capture moments; no leftover sandbox on 3310, unless you pre-deployed one for the warm-live path; MCP allowed-paths set to the repo root; terminal font sized for the projector; `git clean -fdx` state confirmed so the tree is re-runnable.
