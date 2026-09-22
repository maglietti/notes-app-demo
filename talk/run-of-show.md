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

MariaDB stays the point. The database does real work in this demo: system versioning, `UUID_v7()`, `FULLTEXT`, generated columns, and REST Service DDL. The tooling puts that work within reach of an agent. It does not stand in for it.

## The runbook is the spine, told in two acts and an optional third

The prompts on the cue card are the acts, and one agent context runs them all. Act one turns the product doc's data model into a schema and seeds it, and act two reads the same product doc and builds the client on that data, so the audience watches a single conversation carry an idea from an empty directory to a running app. That continuity is the story: you do not hand the work between tools, you keep talking to one agent and it keeps closing its own loop.

The REST tier was aspirational in the locked abstract. The agent builds it as metadata, and a router to serve it over HTTP is out of scope, so REST rides in an optional third act: the sharpest evidence for the skills thesis, run when the clock allows. When it is skipped, a 30-second skip path still shows the recorded `SHOW REST` metadata and states the boundary, because the title promises an API tier. The finale of the core run is the app.

## Room context (Day 2, first breakout after the keynotes)

- The Day 2 keynotes run hot on agent hype: Angie Jones "The Maintainer's Dilemma," Lena Hall "The Anything Trap," and "Software's iPhone Moment." This is the first breakout after them, so it opens as the grounding counterpoint. Not "agents change everything," but "here is what one agent did against a real database in minutes, and here is where it stops."
- Head-to-head same slot: Angie Jones, "Skill Issue: Why Your AI Agent Still Sucks" (Ballroom B), a bigger draw on the same theme. This talk wins the room by being the concrete, verified one. Protect that edge: keep the framing tight and let the demo carry the argument.
- Closing keynote: Quincy Larson, "How to Use Scaffolding to Make Your Coding Agents Less Dumb." The same thesis, restated hours later. Name it in the takeaways.

## The framing anchors (non-negotiable)

1. The agent **builds** the API tier. The metadata (`SHOW REST`, `SHOW CREATE REST VIEW`) is the proof it is real. Do not claim the endpoints answer over HTTP.
2. The app runs in **native mode** and does not run on the REST tier. Never present the running app as proof of the tier.
3. Serving REST over HTTP needs a router that is out of scope. State that boundary in one sentence. Naming where the agent's competence stops is the talk modeling its own thesis.

## Timed beats (core ~18:30 with the skip path, ~22:00 with the full optional act)

| #   | Beat                                    | Target | Running | What happens |
| --- | --------------------------------------- | ------ | ------- | ------------ |
| 1   | Opening hook                            | 2:00   | 2:00    | Confidently wrong: a model writes fluent, wrong SQL for grammar it never trained on, and cannot tell you which parts it guessed. The grounding counterpoint to the keynote hype. The promise: prototype a real app on current MariaDB in minutes, and see exactly where the agent stops. |
| 2   | The two frictions                       | 2:00   | 4:00    | Prototyping on a database costs a developer twice. The model conflates MariaDB with MySQL and gets version-specific grammar wrong, and the time meant for the app goes to infrastructure instead: which version, Docker, provisioning. Put current MariaDB's payoff on the table now: system versioning, `UUID_v7()`, `FULLTEXT`, generated columns. |
| 3   | The frame: skills and tools             | 2:30   | 6:30    | Skills carry the current MariaDB grammar the model never saw, as reviewed and versioned Markdown, so version drift and MySQL guesses fall away. Tools carry capability: the MCP connection and the sandbox that brings its own server. Name the plugins and how to get them here. Reinforce this concretely while the demo runs, not all up front. |
| 4   | Act one: the data tier (Prompt 1)       | 4:00   | 10:30   | The agent turns the data model in PRD section 4 into DDL, compares it with the reference schema, deploys the sandbox on 3310, runs the DDL over MCP, and loads the fixture as the data contract. Call out the MariaDB idioms as they land, and name what they mean: this is current MariaDB, not MySQL, not a stale snapshot. The spec describes behaviour, not syntax, so the idioms are the agent's choice, and the proof is the server accepting the DDL and 61 notes loading. The velocity beat. |
| 5   | Act two: the application (Prompt 2)     | 2:30   | 13:00   | The same context reads `docs/notes_app-prd.md` and builds the Textual client, then runs it from both the launcher and the installed command. The three-pane app opens on the data act one loaded: notebooks, pinned notes, the status line. Name the mode plainly: native, straight to the tables, not proof of a REST tier. The finale of the core run, and the focus-on-the-app payoff. Anchor 2. |
| 6   | Act three, optional: the API tier (Prompt 3) | 4:00 or 0:30 | 13:30   | Full act: the same context puts a REST Service in front of the schema, one statement per session, writing the least-trained grammar in the run, and `SHOW REST` shows the endpoints are defined. Then it adds REST mode to the app, which starts, reports the missing router, and stays up. Skip path: show the recorded `SHOW REST VIEWS` output and say the boundary line. Either way, one sentence on the boundary: serving the endpoints over HTTP is a router away, out of scope. Anchors 1 and 3. |
| 7   | Agent security: the blocked mass delete | 1:30   | 15:00   | The real incident. `DELETE FROM notes_app.account`, no `WHERE`, cascading to five tables. The database would have run it, the account had the privilege, and the harness classifier stopped it above the grants. Layered safety, and the DBA payoff: what an agent may execute, and on what evidence. |
| 8   | The bigger shift                        | 1:30   | 16:30   | Widen from MariaDB to the room. The projects agents work well against publish their knowledge for agents: `llms.txt`, MCP interfaces, `?ask=` doc endpoints, Markdown source over HTML, packaged skills. `ai-plugins` is MariaDB's move. A maintainer reaches coding tools they do not control by shipping skills for their own project. |
| 9   | Takeaways and the Quincy callback       | 2:00   | 18:30   | Skills carry current, version-specific grammar; tools carry capability; both raise the developer and the model. Phrase a prompt by naming the artifact. Guardrails are layered. Greenfield scaffolding on your own stack pays off first. Close by naming Quincy Larson's keynote: you will hear this thesis again this afternoon. |
| Q&A | Q&A buffer                              | ~10:30 | ~29:00  | Fill the balance of the slot and release the room a minute or two early. The full optional act takes 3:30 of this, leaving about 7:00. |

## How the time is weighted

The acts are the talk. The framing before them stays tight so the demo carries the argument and the concrete-over-hype edge holds against the competing session. The Running column assumes the skip path for act three; running the full act adds 3:30 and lands at 22:00, inside the 25-minute ceiling. REST is the optional act, not the finale, and when it runs it earns its place as evidence for skills rather than as the payload. The augmentation story splits: a short frame in beat 3, then the real weight while the agent works in the acts.

## Fallback plan (first slot, cold AV and wifi): record first

The acts (beats 4 through 6) are the only parts exposed to AV and network risk, and this is the first slot after the keynotes, so the recording is the primary path and live is the stretch.

1. **Recorded run, narrated (primary).** A screen capture of the last clean full run in two cuts. The core cut covers acts one and two, trimmed to the schema landing and the app opening. The optional-act cut covers the REST DDL landing, the `SHOW REST` metadata, and the two modes. Narrate over it live. Keep it local on the laptop, never streamed.
2. **Warm live, if AV cooperates.** Pre-deploy the sandbox on 3310 before doors open so no cold `sandbox.deploy` runs on stage. The agent still writes the schema live, and act one's prompt reuses a running sandbox. Choose the path at the podium, based on the room.
3. **Static evidence.** `working/RUN_LOG.md`, the `SHOW REST` output, and a screenshot of the running app as slides, so the claims hold with no terminal at all.

The Textual app runs offline against the local sandbox, so act two is network-safe whichever path act one takes. Native mode is the default, which is why.

Pre-flight checklist lives in `demo-cue-card.md`: recording loaded and cued to the capture moments; no leftover sandbox on 3310, unless you pre-deployed one for the warm-live path; MCP allowed-paths set to the repo root; terminal font sized for the projector; `git clean -fdx` state confirmed so the tree is re-runnable.
