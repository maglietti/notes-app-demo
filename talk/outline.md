# Slide outline: Confidently Wrong

The slide-by-slide plan, mapped to the beats in [`run-of-show.md`](run-of-show.md) and to the deck in [`slides.md`](slides.md). Twenty-one slides plus two Q&A backups, across ten beats. Read the titles alone and they tell the story: the spec that became the answer key, the honest spec with and without skills, two acts that build the app from it, the boundary, and the agent memory that ties it together and points to the next session. On-slide text stays sparse, in the MariaDB deck style: a title, a few words, and one artifact. The detail lives in the script and the speaker notes, not on the wall.

Recording note: the two acts play from one trimmed recording, cued at the start of each act. Each act is an act-divider slide holding the prompt's shape, then a cut to that act's recording, then a payoff slide that names what just happened. The REST beat is a static slide, with its output captured from an off-stage run of Prompt 3. The deck carries the frame; the recording carries the work.

Prompt slides show the trimmed shape of the prompt, not the full text. The full prompt lives on the cue card.

Legend: **On slide** is what the audience reads. **Build** is the visual or reveal. **Says** is the one job the slide does.

---

## Beat 1: Opening hook (slides 1-4, ~2:00)

### Slide 1: Title

- **On slide:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway. Michael Aglietti, Head of Developer Relations, MariaDB. All Things Open 2026, Databases.
- **Build:** Lead layout, dark background.
- **Says:** I assumed the LLM would be confidently wrong about MariaDB, built a talk on it, and then tested it. Two changes made the build work, and one thing turned out to be confidently wrong.

### Slide 2: "Good ideas are always crazy until they're not."

- **On slide:** The Larry Page quote.
- **Build:** One line, lead layout.
- **Says:** The "anyway" in the title.

### Slide 3: I had an idea

- **On slide:** I had an idea. And I wanted to build the app, not stand up a tech stack.
- **Build:** Lead layout.
- **Says:** The itch every developer knows.

### Slide 4: The idea: a notebook that lives in my terminal

- **On slide:** Three panes. Search, pin, archive, trash, tags.
- **Build:** Two columns: what the notebook looks like, and what it does.
- **Says:** Picture a real app. The notes plant "ask my notes a question" for slide 19.

---

## Beat 2: The spec that became the answer key (slides 5-6, ~2:00)

### Slide 5: A one-line prompt drifted, so I wrote a spec, and kept adding to the spec

- **On slide:** The one-line prompt drifted on names (`user` for `account`). A spec fixed it, then every failed run added a rule, until the spec reached 288 lines.
- **Build:** Two columns, with the accent line: I never asked whether the spec was starting to do the agent's job.
- **Says:** The vibe-coding kicker, the real history of the spec, and the two terms (LLM and agent) defined once in the notes.

### Slide 6: Then I tested my own spec: with the skills turned off, the LLM still wrote current MariaDB

- **On slide:** Three lines of the 288-line spec beside the SQL the LLM wrote from them with no skills loaded.
- **Build:** Spec wording on the left, generated SQL on the right, with the accent line: my spec was the answer key.
- **Says:** The aha. A spec that grows by chasing failures drifts toward the answer, and only a test shows it. Evidence: experiment 1.

---

## Beat 3: The honest spec, with and without skills (slides 7-8, ~2:00)

### Slide 7: The spec a developer actually writes: what the app does, never how MariaDB does it

- **On slide:** Real lines from the 48-line `talk/notes-app-spec.md`, and three rules: behaviour not syntax, one spec with thin prompts, done is written down.
- **Build:** Spec excerpt on the left, rules on the right.
- **Says:** The spec names no MariaDB feature. The second change.

### Slide 8: From that spec, the agent without skills writes generic SQL. With the skills, the agent writes MariaDB.

- **On slide:** The same table from both runs: `CREATE TABLE IF NOT EXISTS` with an ascending index, against `CREATE OR REPLACE` with an index shaped to "pinned first, newest first". Both ran, and both loaded the sample data.
- **Build:** Two code blocks side by side, with the accent line: the skills made the agent use the database I chose.
- **Says:** The honest finding, with no UUID debate. Evidence: experiments 2 to 4.

---

## Beat 4: Skills, tools, and the ai-plugins (slides 9-10, ~2:00)

### Slide 9: Skills teach the agent MariaDB, and tools let the agent run what it writes

- **On slide:** Skills give the agent current MariaDB knowledge, loaded into its context. Tools let the agent run SQL on a live database or a sandbox.
- **Build:** Two columns.
- **Says:** What made the difference on slide 8, and what let both scripts be tested.

### Slide 10: ai-plugins installs the skills and the tools in your agent

- **On slide:** What the ai-plugins install, two install commands, four harnesses, what to expect.
- **Build:** Install lines large, the DevHub URL in accent.
- **Says:** Both changes together: the 48-line spec, and an agent with the skills and the tools.

---

## Beat 5: Act one, the data tier (slides 11-13, ~4:00)

### Slide 11: Act one divider, Prompt 1

- **On slide:** Act one: from a spec to a schema. The shape of Prompt 1: turn the spec's data model into DDL, deploy a sandbox, seed it, check the counts against "Done when".
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The prompt points at the spec instead of restating it, and ends with the criteria.

### Slide 12: Watch the agent write, deploy, run, and prove the schema

- **On slide:** Reads the spec and writes the DDL, deploys the sandbox, runs the DDL, loads 61 notes and reports against the criteria.
- **Build:** Cut to act one of the recording. **[CAPTURE] schema landing.**
- **Says:** No SQL by hand, and the agent grades its own result.

### Slide 13: The agent wrote current MariaDB, and passed its own criteria

- **On slide:** A trimmed `note` DDL from the recorded run, the idioms, and the matching counts: 61 notes, 6 notebooks, 12 tags.
- **Build:** DDL snippet with callouts.
- **Says:** Both fixes paid off: the skills chose the current grammar, and the spec's criteria proved the result.

---

## Beat 6: Act two, the application (slides 14-15, ~2:30)

### Slide 14: Act two: from the same spec to an app you can open

- **On slide:** Same conversation. The prompt only picks the slice. The shape of Prompt 2: build the app the spec describes, make it work with the committed launcher, and check it against "Done when".
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The spec carries the app, so the prompt stays short.

### Slide 15: A running app, straight to the tables

- **On slide:** A real Python package, the "Done when" check through the launcher, three panes, and a status line showing the connection.
- **Build:** Cut to act two of the recording. **[CAPTURE] app opening.**
- **Says:** From no app code to a working app that meets its own acceptance criteria. The title's "straight to the tables" hands off to the REST boundary.

---

## Beat 7: The REST boundary (slide 16, ~0:45)

### Slide 16: The API tier: defined, not served

- **On slide:** `SHOW REST VIEWS` lists `/note`, `/notebook`, `/tag`, from an optional prompt run off stage. The server that would serve them is not ready yet, and the app does not call them.
- **Build:** The captured metadata output, with the boundary line in the boundary color.
- **Says:** The title's promise, kept honestly in under a minute. Knowing where the agent's work stops is the point.

---

## Beat 8: Agent security (slide 17, ~1:30)

### Slide 17: The database would have run the mass delete. The harness would not.

- **On slide:** `DELETE FROM notes_app.account`, and the classifier's refusal. Three controls, each with a veto.
- **Build:** The statement and refusal on the left, the three layers on the right.
- **Says:** The database would have run it. Safety on an agent is layered, and it sits above the grants.

---

## Beat 9: Agent memory, and the next session (slides 18-19, ~2:30)

### Slide 18: An agent works from two kinds of memory, and you can write to only one of them

- **On slide:** What the LLM learned in training (fixed, heavier on MySQL, the same for everyone) against what the agent reads into its context (skills, the spec, memory files with your corrections), with the accent line: when the agent does not load the knowledge, the LLM's training fills the gap.
- **Build:** Two columns with full-sentence headings.
- **Says:** Both fixes were the same move: change the agent's context, because the LLM cannot be changed. The notes carry the real anecdote of teaching the agent once while building the talk.

### Slide 19: The next coding session: ask my notes a question, and an LLM answers from them

- **On slide:** What the app does today (MariaDB, `FULLTEXT`) against what comes next on the same server (a `VECTOR` column built in since 11.7, full-text plus vector search, the same spec-first way of working), with the accent line: one MariaDB server holds the app's data and the agent's memory.
- **Build:** Two columns. Label it clearly as a plan, not a demo.
- **Says:** Pays off the thought planted on slide 4 and the reason planted on slide 6. MariaDB is where I build agentic applications.

---

## Beat 10: Takeaways and close (slides 20-21, ~2:00)

### Slide 20: What to take home

- **On slide:** Six takeaways: skills make the agent write for your database, a spec that ends in acceptance criteria, tools, test your spec with the skills turned off, every guardrail, start on greenfield.
- **Build:** Two columns of three.
- **Says:** The portable lessons, whatever database they run. Skills, spec, and tools come first, because they are the fixes the talk showed.

### Slide 21: Go build something confidently right

- **On slide:** The demo repo (Apache-2.0) and the plugins (GPL-2.0). Questions.
- **Build:** Lead layout. The Quincy Larson line is spoken; keep it off the slide.
- **Says:** Send them to the code, and plant the thesis before the closing keynote restates it.

---

## Q&A backups (not in the main flow)

### Slide A1: One plugin, three layers

- **On slide:** `ai-plugins`, `mariadb-shell`, `mariadb-shell-plugins`. Install the top; the rest arrives on first run.
- **Says:** Held for the architecture question.

### Slide A2: Native mode versus the REST tier

- **On slide:** How the app connects, and why it is not proof of REST.
- **Says:** Held for "does the app run on the API?" It does not, and the metadata answers the REST question.

---

## Decisions folded in

- **The spec replaces act three.** Spec-driven development gets its own beat before act one, and the REST act leaves the stage for a static slide. The app does not consume the endpoints, and the server that would serve them is not ready yet, so the act spent its time on caveats. See `docs/decisions.md`, "Talk framing".
- **Prompt slides:** trimmed shape on the wall, full text on the cue card.
- **Recording:** one trimmed cut for acts one and two, cued per act. No REST cut; the REST slide uses captured output.
- **Three layers:** in the Q&A backups, so beat 3 stays a glance.
- **The opening tells the true story (2026-09-25).** The MySQL-habits premise and the UUID focus came from before the experiments and did not survive them. The opening now follows the spec's history: drift, growth into the answer key, the test, and the honest spec with and without skills. The first recording starts at 8:00.

## Still open

- **Publishing patterns:** slide 18 no longer names `llms.txt`, raw Markdown, MCP interfaces, or `?ask=`. Decide whether they belong in slide 18's notes or in Q&A.
- **Heading sweep:** rewrite the remaining terse headings as plain statements in the copy pass.
- **Auth on the REST slide:** endpoints marked `AUTHENTICATION NOT REQUIRED` read as insecure to a DBA audience. Decide whether to name the auth path as a follow-on if asked, or leave it to Q&A.
