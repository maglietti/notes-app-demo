# Slide outline: Confidently Wrong

The slide-by-slide plan, mapped to the beats in [`run-of-show.md`](run-of-show.md). Twenty-one slides plus one appendix, across nine beats. On-slide text stays sparse, in the MariaDB deck style: a title, a few words, and one artifact. The detail lives in the script and the speaker notes, not on the wall.

Recording note: the acts play from the recorded run. Acts one and two share one trimmed cut, cued at the start of each act, and the optional act three has its own cut. Each act is an act-divider slide holding the prompt's shape, then a cut to that act's recording, then a payoff slide that names what just happened. The deck carries the frame; the recording carries the work.

Prompt slides show the trimmed shape of the prompt, not the full text. The full prompt lives in the speaker notes and on the cue card.

Legend: **On slide** is what the audience reads. **Build** is the visual or reveal. **Says** is the one job the slide does.

---

## Beat 1: Opening hook (slides 1-3, ~2:00)

### Slide 1: Title

- **On slide:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway. Michael Aglietti, Head of Developer Relations, MariaDB. All Things Open 2026, Databases.
- **Build:** Title layout, Deep Ocean background, Electric Eel accent rule.
- **Says:** This is the concrete, verified session, and it starts on time.

### Slide 2: The hook

- **On slide:** "A model writes fluent, wrong SQL for grammar it never saw. And it cannot tell you which parts it guessed."
- **Build:** One line, large. Optional: a short block of plausible-looking SQL with one MariaDB construct quietly wrong.
- **Says:** Name the problem the whole talk answers. This is what confidently wrong means.

### Slide 3: The promise

- **On slide:** Prototype a real app on current MariaDB, from a handful of prompts. See exactly where the agent stops.
- **Build:** Two lines. The second line in the accent color, because the boundary is the differentiator.
- **Says:** Set the contract with the room, counter to the keynote hype next door.

---

## Beat 2: The two frictions (slides 4-6, ~2:00)

### Slide 4: Friction one, the guessing

- **On slide:** The model conflates MariaDB with MySQL. It gets version-specific grammar wrong, confidently.
- **Build:** Side-by-side: what the model writes vs what current MariaDB wants. One or two lines each.
- **Says:** The knowledge gap is real and it is specific, not hand-waving about hallucination.

### Slide 5: Friction two, standing up the stack by hand

- **On slide:** The time meant for the app goes to plumbing. Which version. Docker. Provisioning.
- **Build:** A short list of the plumbing, struck through, to signal what the tooling removes.
- **Says:** The second cost is time and focus, and the audience feels this one.

### Slide 6: What current MariaDB actually gives you

- **On slide:** System versioning. `UUID_v7()`. `FULLTEXT`. Generated columns.
- **Build:** Four capability chips. This is the MariaDB value slide, so give it room.
- **Says:** The database is worth reaching for. The tooling is how you reach it, not a replacement for it.

---

## Beat 3: The frame and the plugins (slides 7-8, ~2:30)

### Slide 7: Skills and tools

- **On slide:** Skills carry the grammar the model never saw. Tools carry the connection and the instance. You need both to close the loop.
- **Build:** Two columns. Skills: Markdown, versioned, no fine-tuning. Tools: MCP server, sandbox, execute.
- **Says:** The one distinction the whole talk hangs on.

### Slide 8: The ai-plugins, and how to get them

- **On slide:** `ai-plugins`: MariaDB's skills and MCP server, for the harness you already use. Install one line. Skills work offline; the MCP server takes one setup. GPL-2.0.
- **Build:** The install line big (`/plugin marketplace add mariadb/ai-plugins`, `/plugin install dev@mariadb`), four harness logos beneath it (Claude Code, Codex, OpenCode, Pi), and a note: sandbox needs no Docker and no root. DevHub link.
- **Says:** The star of the show, named and reachable. This is a real thing you install today, not a research demo.

---

## Beat 4: Act one, the data tier (slides 9-11, ~4:00)

### Slide 9: Act one divider, Prompt 1

- **On slide:** Act 1: From a spec to a schema. The shape of Prompt 1: turn PRD section 4 into DDL, deploy a sandbox, seed it, report the counts.
- **Build:** Act-divider layout. Trimmed prompt shape, full text in notes.
- **Says:** I wrote the data model once, in a spec. The agent writes the DDL and proves it.

### Slide 10: The recording (schema landing)

- **On slide:** Minimal chrome, the recording fills the frame. Caption: writing the DDL, deploying the sandbox, running it, loading the fixture.
- **Build:** Cut to act one of the recorded run. **[CAPTURE] schema landing.**
- **Says:** No SQL by hand. Watch the loop close against a live database, with real data as the contract.

### Slide 11: What just landed

- **On slide:** `CREATE OR REPLACE TABLE`. `utf8mb4` with `uca1400`. `WITH SYSTEM VERSIONING`. `uuid_v7()`. `FULLTEXT`. Generated `default_flag`. Then 61 notes, 6 notebooks, 12 tags loaded.
- **Build:** The idioms as callouts over a trimmed DDL snippet, with the fixture counts beneath.
- **Says:** The spec describes behaviour, not syntax. The agent chose the current grammar, and the server and the fixture proved it.

---

## Beat 5: Act two, the application (slides 12-14, ~2:30)

### Slide 12: Act two divider, Prompt 2

- **On slide:** Act 2: An idea you can open. The shape of Prompt 2: build the Textual app the PRD specifies, in native mode with its queries behind the DataSource interface, and verify both entry points.
- **Build:** Act-divider layout. Trimmed prompt shape, full text in notes.
- **Says:** Spec-driven development. The same product doc that gave act one its data model drives the client.

### Slide 13: The recording (the app opens)

- **On slide:** The recording fills the frame, then hold on the running three-pane app.
- **Build:** Cut to act two of the recorded run. **[CAPTURE] app opening.** Land on notebooks, pinned notes, the status line reading `native`.
- **Says:** From an empty directory to this, in one conversation, on the data act one loaded.

### Slide 14: A working client, and the line

- **On slide:** Native mode, straight to the tables. A working client on the schema the agent built. Not proof of a REST tier.
- **Build:** App screenshot with the status line circled. The boundary in the accent color.
- **Says:** Draw the line at the emotional peak. This is the honesty the title promises.

---

## Beat 6 (optional): Act three, the API tier (slides 15-17, ~4:00, or ~0:30 on the skip path)

Run this act, or cut to its recording, only when the clock allows. The skip path jumps from slide 14 straight to slide 17 and shows the recorded `SHOW REST VIEWS` output with the boundary line, about 30 seconds, because the title promises an API tier.

### Slide 15: Act three divider, Prompt 3

- **On slide:** Act 3: From the schema to a REST API. The shape of Prompt 3: build the REST Service from PRD section 5 one statement per session, verify with `SHOW REST`, read `/note` back, publish, then add REST mode to the app.
- **Build:** Act-divider layout. Trimmed prompt shape, full text in notes.
- **Says:** The same context now puts a REST Service in front of the schema, and teaches the app to use it.

### Slide 16: The recording (the API tier and the two modes)

- **On slide:** The recording fills the frame. Caption: the REST grammar is session state, then the app flips between native and REST mode.
- **Build:** Cut to the act three recording. **[CAPTURE] the REST DDL landing, the `SHOW CREATE REST VIEW /note` read-back, `SHOW REST`, and the two modes.** On mariadb-shell 26.9.3 the read-back shows the nested tag objects writable despite the DDL's read-only flags, a tool bug the agent reports and does not patch.
- **Says:** The grammar the model is most confidently wrong about is the grammar the skill knows best.

### Slide 17: Defined, not served

- **On slide:** `SHOW REST VIEWS` lists `/note`, `/notebook`, `/tag`. Serving them over HTTP is a router, and that router is a separate job.
- **Build:** The metadata output, with the boundary line beneath it in the accent color. The skip path lands here.
- **Says:** The endpoints are real in the metadata. Knowing where the agent's work stops is the point.

---

## Beat 7: Agent security (slide 18, ~1:30)

### Slide 18: The blocked mass delete

- **On slide:** `DELETE FROM notes_app.account`. The refusal: "denied by the Claude Code auto mode classifier. Reason: [Cloud Storage Mass Delete]."
- **Build:** The statement, then the refusal revealed beneath it. A three-layer strip: working-directory allow-list, action classifier, database grants.
- **Says:** The database would have run it. Safety on an agent is layered, and it sits above the grants.

---

## Beat 8: The bigger shift (slide 19, ~1:30)

### Slide 19: Knowledge agents can reach

- **On slide:** The projects agents work well against publish for agents, not just for browsers. `llms.txt`. MCP interfaces. `?ask=` doc endpoints. Markdown source over HTML. Packaged skills.
- **Build:** Five chips for the industry patterns, with `ai-plugins` marked as MariaDB's move: skills plus an MCP server. One line: your project can join this, whatever it is.
- **Says:** This is a shift in developer experience, not a MariaDB trick. Skills are how a maintainer reaches coding tools they do not control.

---

## Beat 9: Takeaways and close (slides 20-21, ~2:00)

### Slide 20: What to take home

- **On slide:** Skills carry current grammar. Tools carry capability. Name the artifact in your prompt. Guardrails are layered. Greenfield scaffolding pays off first.
- **Build:** Five numbered takeaways, vertical, light background, in the exec-summary style from the North Star deck.
- **Says:** The portable lessons, whatever database they run.

### Slide 21: Close and resources

- **On slide:** The demo repo, the ai-plugins repo and DevHub, GPL-2.0. "You will hear this thesis again this afternoon, from Quincy Larson." Thank you.
- **Build:** Resources block, QR to the repo. The Quincy line is spoken; keep it off the slide.
- **Says:** Send them to the code, and plant the thesis before the closing keynote restates it.

---

## Appendix (Q&A only, not in the main flow)

### Slide A1: One plugin, three layers

- **On slide:** `ai-plugins` (skills and wiring). `mariadb-shell` (the runtime, the MCP server, the secret store). `mariadb-shell-plugins` (the tools and the REST grammar). Install the top; the rest arrives on first run.
- **Build:** Three stacked layers, "you install the top" marked.
- **Says:** Held for the architecture question. Kept out of the main flow because it is the most detail and the least demo.

---

## Decisions folded in

- **Prompt slides:** trimmed shape on the wall, full text in notes and on the cue card.
- **Recording:** one trimmed cut for acts one and two, cued per act, and a separate cut for the optional act three, so control holds when AV is cold, the act can be dropped cleanly, and the single-conversation story still narrates across them.
- **Three layers:** moved to the appendix (slide A1) so beat 3 stays a glance. Promote it into the main flow only if the architecture question is expected to lead.

## Still open

- **Slide 19 chips:** confirm the five patterns to name. Current set: `llms.txt`, MCP interfaces, `?ask=` doc endpoints, Markdown source over HTML, packaged skills. Swap or trim to what you want to stand behind on stage.
