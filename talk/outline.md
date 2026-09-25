# Slide outline: Confidently Wrong

The slide-by-slide plan, mapped to the beats in [`run-of-show.md`](run-of-show.md) and to the deck in [`slides.md`](slides.md). Twenty slides plus two Q&A backups, across ten beats. Read the titles alone and they tell the story: two guesses, two fixes, two acts that prove both, and the boundary. On-slide text stays sparse, in the MariaDB deck style: a title, a few words, and one artifact. The detail lives in the script and the speaker notes, not on the wall.

Recording note: the two acts play from one trimmed recording, cued at the start of each act. Each act is an act-divider slide holding the prompt's shape, then a cut to that act's recording, then a payoff slide that names what just happened. The REST beat is a static slide, with its output captured from an off-stage run of Prompt 3. The deck carries the frame; the recording carries the work.

Prompt slides show the trimmed shape of the prompt, not the full text. The full prompt lives on the cue card.

Legend: **On slide** is what the audience reads. **Build** is the visual or reveal. **Says** is the one job the slide does.

---

## Beat 1: Opening hook (slides 1-4, ~2:00)

### Slide 1: Title

- **On slide:** Confidently Wrong: Handing a Coding Agent an API Tier Anyway. Michael Aglietti, Head of Developer Relations, MariaDB. All Things Open 2026, Databases.
- **Build:** Lead layout, dark background.
- **Says:** I handed an agent a job it is confidently wrong about, and it worked because of two changes to how I work with it.

### Slide 2: "Good ideas are always crazy until they're not."

- **On slide:** The Larry Page quote.
- **Build:** One line, lead layout.
- **Says:** The "anyway" in the title. By the end you will watch it stop being crazy, and see the one place it still is.

### Slide 3: I had an idea

- **On slide:** I had an idea. And I wanted to build the app, not stand up a tech stack.
- **Build:** Lead layout.
- **Says:** The itch every developer knows.

### Slide 4: The idea

- **On slide:** A notebook that lives in the terminal. Three panes. Search, pin, archive, trash, tags.
- **Build:** Two columns: the feel, and what it does.
- **Says:** Picture a real app, because in my head it already is one.

---

## Beat 2: Guess one, the database (slides 5-6, ~1:00)

### Slide 5: The model guesses your database, fluently

- **On slide:** Perfect time to vibe code. What it hands you, and the trap: code that looks right and behaves wrong.
- **Build:** Two columns. The accent line defines confidently wrong.
- **Says:** Name the first guess. The vibe-coding kicker sets up slide 9.

### Slide 6: Before you use MariaDB, you spend the time teaching it MariaDB

- **On slide:** What you correct, round after round (`UUID_TO_BIN`, plain `utf8`, `LAST_INSERT_ID()`), against what you wanted the time for (row history, time-ordered keys, full-text search, one default notebook).
- **Build:** Two columns, with the accent line beneath: every correction is time you meant for the app.
- **Says:** The cost of the guess is steering time, spent before you reach the features you picked MariaDB for. Sets up slide 7 (what if it already knew?), and slide 13 pays off the features.

---

## Beat 3: Fix one, skills and tools (slides 7-8, ~2:30)

### Slide 7: Fix the knowledge: skills, and tools to act on it

- **On slide:** Skills carry the knowledge. Tools carry the reach. Together they close the loop.
- **Build:** Two columns.
- **Says:** The distinction the talk hangs on.

### Slide 8: ai-plugins

- **On slide:** The skills and the `mariadb-shell` MCP server. Install in two lines. Four harnesses. What to expect.
- **Build:** Install lines large, the DevHub URL in accent.
- **Says:** The first change: it fixes what the agent knows about MariaDB, not what it knows about my app.

---

## Beat 4: Guess two and fix two, the spec (slides 9-10, ~2:00)

### Slide 9: Vibe coding also guesses what you meant

- **On slide:** A one-line prompt: fine SQL, drifting names (`user` for `account`). A spec: reviewed like code, behaviour not syntax, requirement IDs, acceptance criteria.
- **Build:** Two columns, with the accent line beneath: skills stop the guessing about MariaDB, a spec stops the guessing about my app.
- **Says:** The second guess, and the same failure at a different layer.

### Slide 10: Fix the intent: a spec the agent checks itself against

- **On slide:** An excerpt from the PRD (FR-4, AC-D3, AC-D4), and three rules: behaviour not syntax, one spec with thin prompts, done is written down.
- **Build:** Code block of real spec lines on the left, the rules on the right.
- **Says:** The second change. The agent grades its own work against my definition of done, and never sees an answer key.

---

## Beat 5: Act one, the data tier (slides 11-13, ~4:00)

### Slide 11: Act one divider, Prompt 1

- **On slide:** Act one: from a spec to a schema. The shape of Prompt 1: turn PRD section 4 into DDL, deploy a sandbox, seed it, check AC-D1 to AC-D4.
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The prompt points at the spec instead of restating it, and ends with the criteria.

### Slide 12: Watch it write, deploy, run, and prove itself

- **On slide:** Reads the spec and writes the DDL, deploys the sandbox, runs the DDL, loads 61 notes and reports against the criteria.
- **Build:** Cut to act one of the recording. **[CAPTURE] schema landing.**
- **Says:** No SQL by hand, and the agent grades its own result.

### Slide 13: It wrote current MariaDB, and passed its own criteria

- **On slide:** A trimmed `note` DDL, the idioms, and the AC-D report: 61 notes, 6 notebooks, 12 tags.
- **Build:** DDL snippet with callouts.
- **Says:** Both fixes paid off: the skills chose the current grammar, and the spec's criteria proved the result.

---

## Beat 6: Act two, the application (slides 14-15, ~2:30)

### Slide 14: Act two: from the same spec to an app you can open

- **On slide:** Same conversation. The prompt only picks the slice. The shape of Prompt 2: build the app the PRD specifies, in native mode, and check AC-A1 to AC-A5.
- **Build:** Act-divider layout. Trimmed prompt shape.
- **Says:** The spec carries the app, so the prompt stays short.

### Slide 15: A running app, straight to the tables

- **On slide:** A real Python package, AC-A1 to AC-A5 checked from both entry points, three panes, a `native` status line.
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

### Slide 17: The database would have run it. The harness would not.

- **On slide:** `DELETE FROM notes_app.account`, and the classifier's refusal. Three controls, each with a veto.
- **Build:** The statement and refusal on the left, the three layers on the right.
- **Says:** The database would have run it. Safety on an agent is layered, and it sits above the grants.

---

## Beat 9: The bigger shift (slide 18, ~1:30)

### Slide 18: Agents are only as good as what you write down for them

- **On slide:** Maintainers write down the knowledge (skills, `llms.txt`, raw Markdown, MCP, `?ask=`). Teams write down the intent (a spec, IDs, acceptance criteria).
- **Build:** Two columns, one per fix, with the review-it-like-code line beneath.
- **Says:** Both fixes were the same move. Neither is a smarter model.

---

## Beat 10: Takeaways and close (slides 19-20, ~2:00)

### Slide 19: What to take home

- **On slide:** Six takeaways: skills, a spec with acceptance criteria, tools, name the artifact, layered guardrails, start on greenfield.
- **Build:** Two columns of three.
- **Says:** The portable lessons, whatever database they run. Skills, spec, and tools come first, because they are the fixes the talk showed.

### Slide 20: Go build something confidently right

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
- **Title spine:** parallel titles for the guesses (slides 5 and 9) and the fixes (slides 7 and 10), so the two changes the opening promises are visible in the titles alone.
- **One problem slide:** the MySQL habits and what MariaDB already does share slide 6, so the first recording starts at 7:30.

## Still open

- **Slide 18 items:** confirm the four publishing patterns to name. Current set: `llms.txt`, raw Markdown, an MCP interface, `?ask=`.
- **Auth on the REST slide:** endpoints marked `AUTHENTICATION NOT REQUIRED` read as insecure to a DBA audience. Decide whether to name the auth path as a follow-on if asked, or leave it to Q&A.
