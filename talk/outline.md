# Slide outline: Confidently Wrong

The slide-by-slide plan, mapped to the beats in [`run-of-show.md`](run-of-show.md) and to the deck in [`slides.md`](slides.md). Nineteen slides plus two Q&A backups, across nine beats. Read the titles alone and they tell the audience's own path: an idea, a short spec, a plain agent whose SQL runs but is generic and confidently wrong about reruns, the skills and how to install them, two acts that build the app with them, the boundary, and the agent memory that ties it together and points to the next session. On-slide text stays sparse, in the MariaDB deck style.

Recording note: the two acts play from one trimmed recording, cued at the start of each act. Each act is an act-divider slide holding the prompt's shape, then a cut to that act's recording, then a payoff slide. The no-skills result on slide 6 and the REST output on slide 14 are static slides from runs logged in `research/experiments/`.

Prompt slides show the trimmed shape of the prompt, not the full text. The full prompt lives on the cue card.

Legend: **On slide** is what the audience reads. **Build** is the visual or reveal. **Says** is the one job the slide does.

---

## Beat 1: Opening hook (slides 1-4, ~2:00)

### Slide 1: Title

- **On slide:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway. Michael Aglietti, Head of Developer Relations, MariaDB. All Things Open 2026, Databases.
- **Build:** Lead layout, dark background.
- **Says:** I expected the LLM to be confidently wrong about MariaDB. It was, just not where I expected. Two changes made the build work.

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
- **Says:** Picture a real app. The notes plant "ask my notes a question" for slide 17.

---

## Beat 2: The spec, and a plain agent (slides 5-6, ~2:30)

### Slide 5: Instead, I wrote down what the app does, in a short spec

- **On slide:** The vibe-coding kicker, real lines from the 48-line `talk/notes-app-spec.md`, and three rules: describe what the app does, one spec with thin prompts, done is written down.
- **Build:** Kicker above the title. Spec excerpt on the left, rules on the right.
- **Says:** The first change, and a habit the presenter already had: a one-line prompt lets names drift, so write it down first.

### Slide 6: A coding agent built the schema: the SQL ran, and the agent was confidently wrong about reruns

- **On slide:** The DDL a coding agent wrote from the spec (`CREATE TABLE IF NOT EXISTS`) beside the agent's claim, "Safe to run more than once", and what happened: a changed column, a rerun, no error, and a fix that never landed.
- **Build:** Code on the left, the claim and the rerun on the right, with the accent line: nothing told me that my fix was ignored. The slide does not mention skills or generic SQL, because at this point in the story the presenter knows neither.
- **Says:** Confidently wrong, as the audience will meet it: SQL that looks right, runs, loads the data, and quietly ignores a fix. The notes define LLM and agent once. Evidence: experiments 2, 4, and 5.

---

## Beat 3: Skills, tools, and the ai-plugins (slides 7-8, ~2:00)

### Slide 7: Skills teach the agent MariaDB, and tools let the agent run what it writes

- **On slide:** Skills give the agent current MariaDB knowledge, loaded into its context. Tools let the agent run SQL on a live database or a sandbox.
- **Build:** Two columns.
- **Says:** What would have helped: the knowledge the agent lacked, and a way to check its work, which is how the ignored fix was found.

### Slide 8: ai-plugins installs the skills and the tools in your agent

- **On slide:** What the ai-plugins install, two install commands, four harnesses, what to expect.
- **Build:** Install lines large, the DevHub URL in accent.
- **Says:** The second change. Turn the skills on, keep the same spec, and watch.

---

## Beat 4: Act one, the data tier (slides 9-11, ~4:00)

### Slide 9: Act one: from a spec to a schema

- **On slide:** The shape of Prompt 1: turn the spec's data model into DDL, deploy a sandbox, seed it, check the counts against "Done when".
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The prompt points at the spec instead of restating it, and ends with the check.

### Slide 10: Watch the agent write, deploy, run, and prove the schema

- **On slide:** Reads the spec and writes the DDL, deploys the sandbox, runs the DDL, loads 61 notes and checks the counts against the spec.
- **Build:** Cut to act one of the recording. **[CAPTURE] schema landing.**
- **Says:** No SQL by hand, and the agent checks its own result.

### Slide 11: Same spec, now with skills: the agent wrote MariaDB, and a rerun applies the fix

- **On slide:** The same table before (no skills) and after (skills), side by side: `CREATE OR REPLACE`, an index shaped to "pinned first, newest first", and the matching counts.
- **Build:** Two code blocks. The right one comes from the recorded run.
- **Says:** Same LLM, same spec. Only now, with a before and an after, can the presenter see that the first version was portable SQL. The skills changed the agent's context, and the agent used the database I chose.

---

## Beat 5: Act two, the application (slides 12-13, ~2:30)

### Slide 12: Act two: from the same spec to an app you can open

- **On slide:** Same conversation. The prompt only picks the slice. The shape of Prompt 2: build the app the spec describes, make it work with the committed launcher, and check it against "Done when".
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The spec carries the app, so the prompt stays short.

### Slide 13: A running app, straight to the tables

- **On slide:** A real Python package, the "Done when" check through the launcher, three panes, and a status line showing the connection.
- **Build:** Cut to act two of the recording. **[CAPTURE] app opening.**
- **Says:** From no app code to a working app that meets its spec. "Straight to the tables" hands off to the REST boundary.

---

## Beat 6: The REST boundary (slide 14, ~0:45)

### Slide 14: The API tier: defined, not served

- **On slide:** `SHOW REST VIEWS` lists `/note`, `/notebook`, `/tag`, from an optional prompt run off stage. The server that would serve them is not ready yet, and the app does not call them.
- **Build:** The captured metadata output, with the boundary line in the boundary color.
- **Says:** The title's promise, kept honestly in under a minute.

---

## Beat 7: Agent security (slide 15, ~1:30)

### Slide 15: The database would have run the mass delete. The harness would not.

- **On slide:** `DELETE FROM notes_app.account`, and the classifier's refusal. Three controls, each with a veto.
- **Build:** The statement and refusal on the left, the three layers on the right.
- **Says:** Safety on an agent is layered, and it sits above the grants.

---

## Beat 8: Agent memory, and the next session (slides 16-17, ~2:30)

### Slide 16: An agent works from two kinds of memory, and you can write to only one of them

- **On slide:** What the LLM learned in training, which you cannot change, against what the agent reads into its context: skills, the spec, and memory files with your corrections.
- **Build:** Two columns with full-sentence headings, and the accent line: when the agent does not load the knowledge, the LLM's training fills the gap.
- **Says:** Both changes were the same move: change the agent's context. The notes carry the anecdote of teaching the agent once.

### Slide 17: The next coding session: ask my notes a question, and an LLM answers from them

- **On slide:** What the app does today (MariaDB, `FULLTEXT`) against what comes next on the same server (a `VECTOR` column, full-text plus vector search, the same spec-first way of working).
- **Build:** Two columns. Labeled as a plan, not a demo.
- **Says:** Pays off the thought planted on slide 4. One MariaDB server holds the app's data and the agent's memory.

---

## Beat 9: Takeaways and close (slides 18-19, ~2:00)

### Slide 18: What to take home

- **On slide:** Six takeaways: skills make the agent write for your database, a spec that ends in acceptance criteria, tools (running it catches a fix that never landed), name the artifact, every guardrail, start on greenfield. Each one comes from something the audience saw.
- **Build:** Two columns of three.
- **Says:** The portable lessons, whatever database they run.

### Slide 19: Go build something confidently right

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

- **The opening follows the audience's path, not the project's history (2026-09-25).** An earlier version told how the 288-line PRD became the answer key. That was the project's history, not the audience's, so the opening now runs: the idea, a short spec, a plain agent (generic SQL, and a confident rerun claim that experiment 5 disproved), the skills and how to install them, then the acts with skills on. The before-and-after comparison sits on the act one payoff, so it appears once. The first recording starts at 6:30.
- **The spec replaces act three.** The REST act left the stage for a static slide, because the app does not consume the endpoints and the server that would serve them is not ready yet.
- **Prompt slides:** trimmed shape on the wall, full text on the cue card.
- **Recording:** one trimmed cut for acts one and two, cued per act. No REST cut; the REST slide uses captured output.
- **Three layers:** in the Q&A backups, so beat 3 stays a glance.

- **Story integrity.** Each slide claims only what the presenter knew at that point in the story. Hindsight appears only in the narrator's framing (slide 1, the act one payoff, the takeaways, the close), and only where the audience has already seen the evidence.

## Still open

- **Slide 11's right-hand DDL** must come from the recorded run.
- **Publishing patterns:** slide 16 no longer names `llms.txt`, raw Markdown, MCP interfaces, or `?ask=`. Decide whether they belong in its notes or in Q&A.
- **Auth on the REST slide:** endpoints marked `AUTHENTICATION NOT REQUIRED` read as insecure to a DBA audience. Decide whether to name the auth path as a follow-on if asked, or leave it to Q&A.
