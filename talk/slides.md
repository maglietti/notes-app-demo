---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-family: Arial, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size: 18px;
    padding: 56px 76px;
    background: #FFFFFF;
    color: #022934;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
  }
  h1 {
    color: #022934;
    font-size: 38px;
    font-weight: 700;
    margin-bottom: 0.3em;
    line-height: 1.2;
  }
  h2 {
    color: #0E6488;
    font-size: 23px;
    font-weight: 600;
    margin-top: 0.7em;
    margin-bottom: 0.4em;
    border-bottom: 3px solid #4DD8FF;
    padding-bottom: 0.2em;
  }
  h3 {
    color: #424F62;
    font-size: 17px;
    font-weight: 600;
    margin-top: 0.5em;
    margin-bottom: 0.3em;
  }
  p { margin-bottom: 0.6em; line-height: 1.5; }
  ul { margin-top: 0.4em; margin-bottom: 0.8em; }
  li { margin-bottom: 0.35em; line-height: 1.4; }
  strong { color: #022934; font-weight: 700; }
  em { color: #0E6488; font-style: normal; font-weight: 700; }
  code {
    background: #022934;
    padding: 0.15em 0.4em;
    border-radius: 3px;
    font-size: 0.9em;
    color: #4DD8FF;
    font-weight: 500;
  }
  pre {
    background: #022934;
    color: #E5E1E5;
    padding: 1em;
    border-radius: 8px;
    font-size: 14px;
    line-height: 1.5;
  }
  table { font-size: 15px; border-collapse: collapse; width: 100%; margin: 0.8em 0; }
  th { background: #0E6488; color: #FFFFFF; padding: 0.55em; text-align: left; font-weight: 600; }
  td { padding: 0.5em; border-bottom: 1px solid #E5E1E5; }
  tr:nth-child(even) { background: #E5E1E5; }
  .columns { display: grid; grid-template-columns: repeat(2, 1fr); gap: 2rem; margin-top: 0.8em; }
  .small { font-size: 14px; }
  .boundary { color: #00838F; font-weight: 700; }
  .accent { color: #0E6488; font-weight: 700; }
  .watch { background: #E5E1E5; padding: 0.8em 1em; border-radius: 8px; border-left: 4px solid #4DD8FF; }
  section.lead { text-align: center; justify-content: center; background: #022934; color: #FFFFFF; }
  section.lead h1 { color: #FFFFFF; font-size: 46px; margin-bottom: 0.3em; }
  section.lead h3 { color: #D2F801; }
  section.lead strong { color: #FFFFFF; }
  section.lead p { color: #4DD8FF; font-size: 18px; }
  section.lead em { color: #D2F801; }
  section.lead code { background: #0E6488; color: #FFFFFF; }
  footer { color: #95a5a6; font-size: 12px; }
---


<!-- _paginate: false -->
<!-- _class: lead -->

# Confidently Wrong

### **Handing a Coding Agent an API Tier Anyway**

&nbsp;
&nbsp;
&nbsp;

*Michael Aglietti* · Head of Developer Relations, MariaDB
All Things Open 2026 · Databases

<!--
SPEAKER NOTES:

Good morning. You just sat through two keynotes about how agents are going to change everything. For the next twenty minutes I want to do the opposite, and get specific.

I gave a coding agent one job: build an app against a real MariaDB server, from the data tier up, with an API tier behind it. I knew before I started that the LLM underneath is confidently wrong about a database it barely trained on. I handed it the job anyway. Most of it worked, because of two changes I made to how I work with the agent. And I will show you the part that did not.

But first, why would I even try?
-->

---

<!-- _paginate: false -->
<!-- _class: lead -->

# "Good ideas are always crazy until they're not."

### Larry Page

<!--
SPEAKER NOTES:

Larry Page said that. Handing an API tier to a coding agent that is confidently wrong about your database is a crazy idea. That is the "anyway" in the title.

So here is my deal with you. By the end, you will watch most of it stop being crazy, and see the one part that still is. Let me start with the idea.
-->

---

<!-- _class: lead -->

# I had an idea.

### **And I wanted to build the app, not stand up a tech stack.**

<!--
SPEAKER NOTES:

Start with the itch, because I think you know this one.

I had an idea. A small one, the kind you get on a Tuesday and want running by Wednesday. And I wanted to build it the way every demo now promises you can: describe it to an agent, and watch it come together against a real database.

Not spend the afternoon standing up a stack. Not paste code from a chat window into a terminal and hope. Build the thing. Schema, data, an API, a working front end.

Here is the idea.
-->

---

# The idea: a notebook that lives in my terminal

<div class="columns">
<div>

## What the notebook looks like

A fast, keyboard-first notebook you never leave the terminal for. Three panes: the notebooks, the notes, and the note you are reading, rendered from Markdown.

*The kind of tool you keep open all day.*

</div>
<div>

## What the notebook does

- **Search** every note, full text, as you type
- **Pin** the notes that matter to the top
- **Archive** finished notes, out of the way
- **Trash** notes with a way to restore them
- **Tag** notes and filter across notebooks

</div>
</div>

<!--
SPEAKER NOTES:

Picture it with me, because in my head it is already a real app.

A notebook that lives in the terminal. No browser, no tab to lose, no mouse. Three panes. On the left, your notebooks. In the middle, the notes in the one you picked. On the right, the note you are reading, rendered from Markdown.

And it does what you actually want a notebook to do. Search everything, full text, as you type. Pin the notes that matter so they stay on top. Archive the finished ones so they get out of your way. Trash, with a way back, because nobody wants a cliff. And tags, so you can slice across notebooks.

That is the kind of tool you keep open all day. And someday I want to ask my notes a question and get an answer back. Hold that thought, because I come back to it at the end.

So I opened an agent, pointed it at MariaDB, and asked it to build exactly that.
-->

---

### *Perfect time to vibe code my idea into existence...*

# The LLM behind your agent guesses your database, fluently

<div class="columns">
<div>

## What the LLM hands you

- SQL that is syntactically perfect
- Grammar borrowed from the wrong database
- Not one word about what the LLM guessed

</div>
<div>

## Why nothing warns you

The SQL parses, and it usually runs. Then you use the app and the operations break: a create is rejected, an update touches the wrong rows, a read comes back in the wrong shape. You find each bug in testing, and every pass costs time you wanted for the app.

<span class="accent">Confidently wrong means code that looks right and behaves wrong when you use it.</span>

</div>
</div>

<!--
SPEAKER NOTES:

Perfect time to vibe code my idea into existence, right? This is the moment the keynotes promised you. Here is what usually happens instead. The villain of the story shows up, and it is not a dumb LLM. It is a fluent one.

A quick word on terms, because I will use two of them all talk. By LLM I mean the language model underneath your agent. By agent I mean that LLM running inside a harness, like Claude Code or Codex, where it can read files and run tools.

Ask the LLM for SQL and you get something that looks like a careful engineer wrote it. For anything it barely trained on, it is guessing, and it will not tell you which parts.

That is why nothing warns you. The SQL parses, and it usually runs. Then you use the app and the operations break. A create is rejected. An update touches the wrong rows. A read comes back in a shape the client did not expect. You catch it in testing, not in production, but every pass through that loop is time you meant for building, not for debugging someone else's confident guess.

That is what I mean by confidently wrong. Code that looks right and behaves wrong the moment you use it. The cause is knowledge, not intelligence. And with a database, the gap in knowledge has a specific source.
-->

---

# Before you use MariaDB, you have to break the LLM's MySQL habits

<div class="columns">
<div>

## What you correct, round after round

The LLM learned MariaDB as a fork of MySQL, so the SQL is correct MySQL for the wrong database:

- **Keys:** `UUID_TO_BIN()`, a MySQL 8 function MariaDB does not have, instead of MariaDB's `UUID` type and `UUID_v7()`
- **Character set:** plain `utf8`, which MariaDB reads as 3-byte `utf8mb3`, so an emoji in a note is rejected
- **New row id:** `LAST_INSERT_ID()`, which returns nothing useful for a UUID key, instead of `INSERT ... RETURNING`

</div>
<div>

## What you wanted the time for

- **Row history** on accounts and notebooks, from system versioning
- **Time-ordered keys** that leak no row counts, from `UUID_v7()`
- **Full-text search** over title and body, with no second system
- **One default notebook** per account, enforced by the schema

</div>
</div>

<span class="accent">Every correction is time you meant for the app, and for the features you picked MariaDB for.</span>

<!--
SPEAKER NOTES:

Here is where the guessing comes from. The LLM has read far more MySQL than MariaDB. Stack Overflow alone has about forty-five MySQL questions for every MariaDB one. And what the LLM read about MariaDB says it is a fork of MySQL that started as a drop-in replacement. So it assumes MySQL. Notice that none of this is made up. Every example on the left is correct MySQL. It is the wrong database.

Here is what that costs on this exact app. Our tables are keyed on UUIDs. MariaDB has a native UUID type and UUID_v7. MySQL has neither, so the LLM writes the MySQL 8 recipe, UUID_TO_BIN, which MariaDB does not have, and the CREATE TABLE fails. You correct it. It writes plain utf8, which on MariaDB still means the old three-byte form, so the first emoji in a note is rejected. You correct it again. For the new row's id it reaches for LAST_INSERT_ID, an auto-increment idea that gives you nothing with a UUID key, instead of INSERT RETURNING. Another round.

Every one of those rounds is time you meant for something else. The reasons I picked MariaDB for this app are on the right. System versioning keeps row history, so no audit triggers. UUID_v7 gives time-ordered keys. FULLTEXT searches without a second system. A generated column enforces one default notebook per account. And one more reason I will come back to at the end: vector search is built into the server too.

You do get there, eventually. But first you spend the afternoon breaking the LLM's MySQL habits, one correction at a time. That part we can fix.
-->

---

# Fix the knowledge: skills teach MariaDB, tools run the SQL

<div class="columns">
<div>

## Skills give the agent current MariaDB knowledge

- The current grammar, the order statements must run in, and the failure modes
- Curated by MariaDB, installed by a plugin
- Loaded into the agent's context, its working memory, so the LLM's training does not have to change
- Work offline, with no database at all

</div>
<div>

## Tools let the agent run SQL on a live database

- An MCP server gives the agent a live database connection
- The agent runs SQL, reads the schema, and runs `EXPLAIN`
- With no database yet, the agent deploys a sandbox server

</div>
</div>

**With both, the agent writes the right statement, runs it, reads the result, and fixes what broke.**

<!--
SPEAKER NOTES:

So here is the first fix. What if the agent was not guessing? What if it already knew?

Two pieces make that happen, and telling them apart is the most useful idea I can give you today.

The first is skills. A skill carries the current MariaDB grammar, the order the statements have to run in, and the failure modes the docs leave out. MariaDB curates them, and a plugin installs them. When a task needs one, the agent loads it into its context, its working memory for the session. No fine-tuning. The LLM underneath does not change at all. And skills work offline, because knowledge does not need a database attached.

The second is tools. An MCP server gives the agent a live connection. It can run SQL, read the schema, run EXPLAIN, and when you have no database yet, deploy a sandbox.

You need both. Knowledge without a connection gives you better code that you still copy and run by hand. A connection without knowledge lets the agent run confident, wrong SQL faster than ever. With both, the agent writes the right statement, runs it, reads the result, and fixes what broke. It closes its own loop.

So where do you get both?
-->

---

# ai-plugins installs the skills and the tools in your agent

<div class="columns">
<div>

## What the ai-plugins install

- MariaDB **skills**, curated and current
- The **`mariadb-shell` MCP server**, already wired to the agent
- A target of MariaDB 11.8 LTS

## Install with two commands

```
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

</div>
<div>

## Harnesses that run the ai-plugins

Claude Code · Codex · OpenCode · Pi

## What to expect after you install

- **Skills** work at once, offline
- **The MCP server** needs one setup step
- **The sandbox** deploys a real server, with no Docker and no root

<span class="accent">ai-plugins.mariadb.com</span>

</div>
</div>

<!--
SPEAKER NOTES:

This is the one thing I installed, and it is the star of the show. The MariaDB ai-plugins: a curated set of skills plus the mariadb-shell MCP server, packaged for the harness you already use, targeting MariaDB 11.8 LTS.

Two commands to install. Add the marketplace, install the plugin. It runs in Claude Code, Codex, OpenCode, and Pi, so bring whatever harness you like.

Three things to expect, because I promised you specifics. The skills work the moment you install them, offline, because knowledge needs no database. The MCP server takes one setup step, where you tell it what it is allowed to touch. And when you have nothing, the sandbox deploys a real MariaDB server for you, with no Docker and no root. That is why the demo you are about to watch starts with no database and no app code.

That is the first change. It fixes what the agent knows about MariaDB. It does nothing for what the agent knows about my app. That needs the second change.
-->

---

# Vibe coding also guesses what you meant

<div class="columns">
<div>

## What happened with a one-line prompt

- My first act one was a one-line prompt that left the design to the agent
- The SQL was fine, but the names drifted: one run called the owner table `user`, not `account`
- The app binds to those names, so a run that drifted broke the app

*Nothing was wrong with the SQL. The agent guessed my intent, confidently.*

</div>
<div>

## What a spec gives the agent instead

- One document, written once, reviewed like code, and read by the agent on every run
- What the app stores and does, never the syntax
- A numbered must-have list, so a prompt can point at it
- A "Done when" list that says what done looks like

</div>
</div>

<span class="accent">The skills fixed the guessing about MariaDB. The guessing about my app needed a spec.</span>

<!--
SPEAKER NOTES:

Back to that vibe-coding moment, because a second guess hides in it, and a skill cannot fix this one.

My first version of act one was a one-line prompt that left the whole design to the agent. The SQL was fine. Current MariaDB, the skills did their job. But the names drifted. One run called the owner table user instead of account. The app I build next binds to those names, so a run that picked a different name broke the app. Nothing was wrong with the SQL. The agent guessed what I meant, and it guessed confidently. Same failure, one layer up.

So I stopped describing the app in a chat window, and wrote a spec. One short document, reviewed like code, that the agent reads on every run. It says what the app stores and what it does, never the syntax, so the MariaDB grammar is still the agent's job. The must-haves are numbered, so a prompt can point at them. And it ends with a short list called Done when: a written-down answer to the question an agent otherwise answers for itself. Am I done?

This is how I work with an agent every day, and it is the second change.
-->

---

# Fix the intent: a spec the agent checks itself against

<div class="columns">
<div>

## Real lines from the spec in the repo

```
## Data
It is just me for now, one account. The sample
data in research/synthetic_data.sql must load
without changes.

## What the app does
2. List the active notes in a notebook, pinned
   first, newest first

## Done when
- The schema loads, and the sample data loads
  into it: 6 notebooks, 12 tags, 61 notes
```

</div>
<div>

## Three rules for the spec and the prompts

1. **Describe behaviour, not syntax.** The skills carry the grammar.
2. **Keep one spec and thin prompts.** A prompt picks a slice and points at the spec. The prompt never restates the spec.
3. **Write down what done means.** Every prompt ends by checking the "Done when" list.

</div>
</div>

*The prompt says what to build next. The spec says what right looks like.*

<!--
SPEAKER NOTES:

Here is what that looks like, straight from the spec in the repo.

It is short, and I wrote it the way I would write any first spec. The data section says it is just me for now, and that my sample data must load without changes. That sample data is the contract: when it does not fit, the schema changes, never the data. A must-have: list the active notes, pinned first, newest first. And Done when: the schema loads, the sample data loads, and the counts come out at six notebooks, twelve tags, and sixty-one notes. Notice what is missing. Not one word about UUIDs, collations, or MariaDB features.

Three rules make this work. Describe behaviour, not syntax, so the skills still carry the grammar. Keep one spec and thin prompts, so a prompt picks a slice and points at the spec, and nothing drifts between copies. And write down what done means, so every prompt ends by checking the Done when list. The agent grades its own work against my definition of done, not its own.

One more thing, and check me on it, because it is all public. The spec does not link the reference schema I froze from an earlier run, and the prompt tells the agent not to read it. The agent never sees an answer key. It writes its own schema, every time. Let me show you.
-->

---

<!-- _class: lead -->

# Act one: from a spec to a schema

### **I wrote the data model. The agent writes the DDL.**

```
Work in this repository and complete every step in order.

1. Turn the data model in talk/notes-app-spec.md into
   MariaDB DDL in working/notes_app.sql.
2. Deploy a MariaDB 11.8 sandbox on port 3310 and run the DDL.
3. Seed it with research/synthetic_data.sql. If the fixture
   fails, fix the schema. Never edit the fixture.
4. Check the result against the spec's "Done when" list,
   and report each table's row count.
```

<!--
SPEAKER NOTES:

Act one. I want to be straight about what is scripted, because honesty is the whole talk. This is the prompt I ran, trimmed to fit the slide. The full text is in the repo.

Notice what it says. It names the files it wants, it numbers the steps, and it says do them in order. That is how you phrase a prompt so the work lands. It points at the spec instead of restating it. The agent's job is to turn the data model into DDL, deploy a server, run the DDL, and prove the schema by loading real data. If the data does not fit, the schema changes, never the data. And the last step is the one you just saw: check the result against the Done when list.

Watch what the agent does with it.
-->

---

# Watch the agent write, deploy, run, and prove the schema

<div class="watch">

**What the agent does on screen**

1. **Reads** the data model in the spec and **writes** the DDL
2. **Deploys** a MariaDB sandbox on port 3310, with no Docker and no root
3. **Runs** the DDL over MCP against that live server
4. **Loads 61 real notes** as the data contract, and **checks** the counts against the spec

</div>

*An agent that only writes code hands you a review. An agent that runs the code against a live server hands you a result.*

<!--
SPEAKER NOTES:

[CUT TO RECORDING, ACT ONE]

Four things happen here. The agent reads the data model out of my spec and writes the DDL. It deploys a MariaDB sandbox on port 3310, and notice there was no Docker step and no container. I cached the server download ahead of time so you are not watching a progress bar, but the server itself did not exist until the agent deployed it. It runs the DDL over the connection against that live server. Then it loads sixty-one real notes, the fixture the app depends on, and checks the counts against the Done when list in my spec.

That last step is the difference between a demo and a result. An agent that only prints code hands you a review task. This one ran its own code against a real database, made real data prove it, and graded the result against my definition of done.

[LET THE SCHEMA LAND, THEN ADVANCE]
-->

---

# The agent wrote current MariaDB, and passed its own criteria

```sql
CREATE OR REPLACE TABLE notes_app.note (
  id      uuid  NOT NULL DEFAULT uuid_v7(),
  status  enum('active','archived','trashed') NOT NULL DEFAULT 'active',
  FULLTEXT KEY ft_note_title_body (title, body)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
```

- `CREATE OR REPLACE TABLE`, `utf8mb4`, and the current `uca1400` collation
- A `uuid_v7()` primary key and a `FULLTEXT` index in the `note` table
- The fixture loaded, and the counts matched the spec: 61 notes, 6 notebooks, 12 tags
- The LLM's training did not change. The agent's context did: the skills and the spec

<span class="accent">The spec says what the app stores, never the syntax. The MariaDB grammar is the agent's own work.</span>

<!--
SPEAKER NOTES:

Now look at what the agent actually wrote, because this is the payoff of act one.

[UPDATE FROM THE RECORDED RUN: name the idioms the agent actually wrote, and match the DDL snippet on the slide to it.] CREATE OR REPLACE TABLE. utf8mb4 with the current uca1400 collation. UUID keys that default to uuid_v7. A FULLTEXT index for search.

Remember the MySQL habits from a few minutes ago, UUID_TO_BIN and the utf8 that rejects an emoji? None of them are here. And the spec never mentions UUIDs, collations, or key types at all. It says one account, notebooks, notes, and tags, and that my sample data must load. Every MariaDB idiom on this slide is the agent's choice.

Here is what changed since that earlier slide. Not the LLM. Its training is exactly the same. What changed is the agent's context: the skills for the grammar, and the spec for the intent. Then the agent proved the result against the spec. The server accepted the DDL, sixty-one notes loaded, and every criterion passed.

So the schema is real, and it is exactly the schema the app will bind to. Now we build on it.
-->

---

<!-- _class: lead -->

# Act two: from the same spec to an app you can open

### **Same conversation. The prompt only picks the slice.**

```
Build the app that talk/notes-app-spec.md describes, on
the schema in working/notes_app.sql. Build every Must
have, and leave the Later items.

bin/notes-app is the committed launcher. Make the app
work with it, then check the app against the "Done when"
list in the spec.
```

<!--
SPEAKER NOTES:

Act two. Same conversation, same spec. The document that gave act one its data model also describes the app: the three panes, the must-haves, the stack, how it runs, and when it is done.

Look how short the prompt is. I am not describing the app in a chat window. I wrote the spec once, and the prompt only picks the slice: the must-haves, the launcher, and the Done when list. The same agent that built my tables now reads my spec and writes my front end.
-->

---

# A running app, straight to the tables

<div class="watch">

**What the agent does on screen**

1. **Reads the spec** and builds a real Python package, not a snippet
2. **Checks** the "Done when" list: `bin/notes-app` opens with the notebooks and notes
3. **Opens** three panes: notebooks, notes with the pinned ones on top, and the note view
4. **Shows** `native` on the status line, next to the sandbox address

</div>

*One conversation carried the idea from a spec to an app you can use.*

<!--
SPEAKER NOTES:

[CUT TO RECORDING, ACT TWO]

The agent reads the spec and builds a real Python package. Not a snippet in a chat window. A project, with an entry point and dependencies. Then it checks the app against the spec: it starts the app with the committed launcher, and confirms the notebooks and notes appear.

And there it is. Three panes. On the left, the notebooks from act one. In the middle, the notes, pinned ones on top, the way the schema's index intended. On the right, a note rendered from Markdown. Along the bottom, a status line that reads native, so the app talks straight to the tables on the sandbox. That is the data act one loaded, on screen. Search and tag filters are Shoulds in the spec, not Musts, so this prompt leaves them for the next one.

From no app code to a working app, in one conversation, with a report that says it meets the spec.

[ADVANCE TO THE REST SLIDE. KEEP IT UNDER A MINUTE.]
-->

---

# The API tier: defined, not served

<div class="columns">
<div>

## What the metadata shows: the endpoints are defined

```
SHOW REST VIEWS
  FROM SERVICE /notesApp SCHEMA /notes;
```

Lists `/note`, `/notebook`, and `/tag` under the `/notesApp` service, from an optional third prompt that I ran off stage.

</div>
<div>

## What I will not claim: the endpoints do not answer yet

<span class="boundary">The API is defined in the metadata. The server that would serve the API is not ready yet, and this app does not call the endpoints.</span>

</div>
</div>

**Knowing where the agent's work stops is the point. So I am saying where it stops, out loud.**

<!--
SPEAKER NOTES:

The title promised you an API tier, so here is the honest version, in under a minute.

An optional third prompt in the repo has the agent put a REST Service over this schema. I ran it off stage. SHOW REST VIEWS lists the endpoints the agent defined, note, notebook, and tag, under the notesApp service. They exist, in the metadata.

And here is the part I promised you at the start, the part that is still crazy. The server that would serve those endpoints over HTTP is not ready yet, and the app you just watched does not call them. It talks straight to the tables. So I am not going to tell you these endpoints answer a web request, because they do not. They are defined. Serving them is still ahead.

[IF THERE IS TIME: That run had one more surprise. The prompt makes the agent read the view back, and the read-back showed the tool had dropped the read-only flags the agent wrote. The agent was right, the tool was wrong, and the only reason anyone knew is that checking was written into the prompt.]

The agent is good right up to a boundary, and the honest move is to name the boundary instead of smudging it. One more story from building this demo, one I did not plan.

[ADVANCE]
-->

---

# The database would have run the mass delete. The harness would not.

<div class="columns">
<div>

## What the agent tried while I built this demo

While it reseeded the sandbox, the agent tried:

```sql
DELETE FROM notes_app.account
```

No `WHERE`. The whole table, cascading to five more.

> Permission for this action was denied by the Claude Code auto mode classifier.
> Reason: [Cloud Storage Mass Delete].

</div>
<div>

## Why the refusal should reassure you

Three independent controls, each with a veto:

1. **Allow-list:** which files the agent can touch
2. **Action classifier:** which operations the agent can run
3. **Database grants:** what the database account may do

*The account had the privilege. The guardrail sits above the grants, not inside them.*

</div>
</div>

<!--
SPEAKER NOTES:

You should see this one, because you are the people who decide what an agent is allowed to run.

While I was building this demo, reseeding the sandbox between runs, the agent tried to reset the data with this. DELETE FROM account. No WHERE clause. The whole table, cascading to five more through foreign keys. The database would have run it without blinking. The account it connected as had the privilege. It was valid SQL.

It never reached the server. The harness stopped the tool call first, and told the agent to find a safer path or hand the call to a human. The agent took the safe path and skipped the wipe.

Here is why that should reassure you rather than scare you. Safety on an agent is layered. The allow-list controls which files the agent can touch. The action classifier controls which operations it can run. The database grants control what the account may do. Three independent controls, each with its own veto. The database's own permissions would have allowed this delete. The control that caught it sits above the grants, not inside them. You want every layer, and then you do not have to trust the agent's judgment to stay safe.

One more idea ties the two fixes together.
-->

---

# An agent works from two kinds of memory, and you can write to only one of them

<div class="columns">
<div>

## What the LLM learned in training: fixed, and you cannot change it

- More MySQL than MariaDB in what the LLM read
- The same for everyone who uses that LLM

</div>
<div>

## What the agent reads into its context: working memory that you control

- Skills from MariaDB, with the current grammar
- The spec from your team, with what to build and how to check it
- Memory files with your own corrections, such as `CLAUDE.md` or `AGENTS.md`
- You write, review, and version all three like code

</div>
</div>

<span class="accent">When the agent does not load the knowledge, the LLM's training fills the gap.</span>

<!--
SPEAKER NOTES:

Both fixes you saw today were the same move, and it is worth naming.

An agent works from two kinds of memory. The first is what the LLM learned in training. It was fixed the day the LLM was built, it read far more MySQL than MariaDB, and it is the same for everyone who uses it. You cannot change it, and neither can I.

The second is the agent's context, its working memory for the session. That is where the skills go, with the current MariaDB grammar. That is where my spec goes, with what to build and how to check it. And that is where my own corrections go. Here is a real one. While I built this talk, I corrected the agent three times on how to write these slides: no dangling pronouns, say LLM or agent instead of model, and plain headings. Each time, the agent wrote the rule into its memory files, so the next session started with the rule in place. I taught it once, not every session. That is the round-after-round problem from earlier, solved.

You write, review, and version all three like code. And here is the honest flip side: when the agent does not load that knowledge, the LLM's training fills the gap, and the MySQL habits come right back.
-->

---

# The next coding session: ask my notes a question, and an LLM answers from them

<div class="columns">
<div>

## What the app does today

- Stores notebooks, notes, and tags in MariaDB
- Finds notes with the `FULLTEXT` index the agent built

</div>
<div>

## What I will build next, on the same MariaDB server

- Store an embedding beside each note, in a `VECTOR` column built into MariaDB since 11.7
- Combine the `FULLTEXT` index with vector search to find the right notes
- Work the same way: a spec first, skills for the grammar, a sandbox to run it

</div>
</div>

<span class="accent">One MariaDB server holds the app's data and the agent's memory. That is why I build agentic applications on MariaDB.</span>

<!--
SPEAKER NOTES:

Remember the thought I asked you to hold, back at the idea? I want to ask my notes a question and get an answer back. That is my next coding session. I have not built it yet, so this is a plan, not a demo.

Today the app stores notebooks, notes, and tags in MariaDB, and finds notes with the full-text index the agent built. Next, I store an embedding beside each note, in a vector column. Vector search is built into MariaDB since 11.7, so there is nothing to install and no second database to run. Then I combine the full-text index I already have with vector search, so a question finds the right notes whether it uses my exact words or not, and an LLM answers from them.

And I will build it the way you watched today. A spec first, the skills for the grammar, a sandbox to run it.

This is the other reason I picked MariaDB, the one I promised to come back to. My notes become memory for an agentic application, and one MariaDB server holds both the app's data and that memory.
-->

---

# What to take home

<div class="columns">
<div>

1. **Skills are the fix, not a cleverer prompt.** More prompting does not teach the LLM current MariaDB. The ai-plugins load that knowledge into the agent's context, in the harness you already use.
2. **Write a spec, and end the spec in acceptance criteria.** The spec stops the agent guessing about your app, and the criteria let the agent check its own work. Unlike a chat prompt, your team can review a spec.
3. **Give the agent tools to run against.** The MCP server opens a live connection and deploys a sandbox, so the agent runs its SQL and fixes what broke. When a run fails, wrong SQL points to missing knowledge, and a blocked connection points to the tools.

</div>
<div>

4. **Name the artifact, not the outcome.** Ask for the schema, the DDL file, the running app, and number the steps when the order matters.
5. **Set all three guardrails.** The working-directory allow-list, the harness action classifier, and the database grants each get a veto, so you do not rely on the agent's judgment.
6. **Start on greenfield.** The loop is fast and no existing code is at risk. Build your confidence where the blast radius is smallest, then take that confidence into harder work.

</div>
</div>

<!--
SPEAKER NOTES:

Six things to carry out the door, whatever database you run.

One. Skills are the fix, not a cleverer prompt. When the LLM guesses past its training, no amount of prompting teaches it current MariaDB. The ai-plugins load that knowledge into the agent's context, in the harness you already use.

Two. Write a spec, and end it in acceptance criteria. The spec stops the agent guessing about your app, and the criteria let it check its own work against your definition of done, not its own. Unlike a chat prompt, your team can review a spec. That is spec-driven development, and it is how acts one and two happened.

Three. Give the agent tools to run against. The MCP server opens a live connection and can deploy a sandbox, so the agent runs its own SQL and fixes what broke, instead of handing you code to paste. And when a run fails, the split tells you where to look. Wrong SQL means the LLM hit the edge of its training, so the agent needs a skill. A refused connection or a blocked path is a tools setting to fix.

Four. Name the artifact you want. Ask for the schema, the DDL file, the running app, not the outcome you imagine, and number the steps when the order matters.

Five. Set all three guardrails. The working-directory allow-list, the harness action classifier, and the database grants each get a veto. Then you do not rely on the agent's judgment to stay safe.

Six. Start on greenfield. The loop is fast and no existing code is at risk. Build your confidence where the blast radius is smallest, and carry it into harder work from there.
-->

---

<!-- _paginate: false -->
<!-- _class: lead -->

# Go build something confidently right

*Crazy until it's not. Today most of the idea flipped. The server for the API is the part still ahead.*

**Demo, prompts, and schema:** *github.com/maglietti/notes-app-demo* (Apache-2.0)

**The ai-plugins:** *ai-plugins.mariadb.com* (GPL-2.0)

&nbsp;

### Questions?

<!--
SPEAKER NOTES:

Good ideas are crazy until they're not. That was Larry Page, at the start. You just watched most of one stop being crazy. An agent working with an LLM that is confidently wrong about MariaDB built a real data tier and a working app on top of it, because the agent had the knowledge, the connection, and a spec that said what right looks like. And I showed you the part that is still crazy: an API tier that is defined, and not yet served.

One idea, one spec, one conversation, from no app code to a running app that passed its own acceptance criteria, with the boundary named out loud along the way.

Everything you saw is public. The demo, the exact prompts, the spec, and the schema are in the first repo, Apache-2.0. The plugins are in the second, GPL-2.0, so you can read every skill and write your own.

One last thing before questions. This afternoon Quincy Larson closes the day with a keynote called How to Use Scaffolding to Make Your Coding Agents Less Dumb. That is this same idea, on a much bigger stage than mine, hours from now. You heard it here first, at ten-thirty, with a live database. Go see him. Then go write a skill for whatever your own agent is confidently wrong about, and a spec for whatever it keeps guessing.

Questions.
-->

---

<!-- _paginate: false -->

# Appendix: one plugin, three layers

<div class="columns">
<div>

## You install only the top layer

| Layer | What the layer is |
| ----- | ---------- |
| `ai-plugins` | The skills, and the setup that starts the MCP server |
| `mariadb-shell` | The runtime, the MCP server, and the secret store |
| `mariadb-shell-plugins` | The tools, and the REST grammar |

</div>
<div>

## How the three layers fit together

- Installing `ai-plugins` downloads the shell on first run
- The shell hosts the MCP server as a plugin
- Passwords live in the shell's secret store, never in a config file
- 28 tools in three groups: `db.*`, `msm.*`, `sandbox.*`

</div>
</div>

<!--
SPEAKER NOTES:

[Q&A BACKUP, FOR THE ARCHITECTURE QUESTION]

If someone asks how the pieces fit. You install one thing, the ai-plugins. On first run it downloads mariadb-shell, the runtime that hosts the MCP server as a plugin and keeps your passwords in a real secret store, never in a config file. Underneath, the shell plugins are where the tools and the REST grammar are actually implemented. Twenty-eight tools in three groups: db for SQL and schema reads, msm for schema management, sandbox for local sandbox servers. You install the top layer, and the rest arrives on first run.
-->

---

<!-- _paginate: false -->

# Backup: native mode versus the REST tier

<div class="columns">
<div>

## How the app connects: straight to the tables

- The native MariaDB connector, to the sandbox on port 3310
- No router and no daemon, so the app starts offline
- A real client on the schema the agent designed

</div>
<div>

## Why the app is not proof of the REST tier

<span class="boundary">In native mode the app never calls the `/notesApp` endpoints. An optional third prompt defines them, and the server that would serve them is not ready yet, so REST mode has nothing to answer the app. The app takes the native path to the same tables.</span>

</div>
</div>

**The app shows that the schema works. The metadata, not the app, shows that the REST endpoints are defined.**

<!--
SPEAKER NOTES:

[Q&A BACKUP, IF SOMEONE ASKS WHETHER THE APP RUNS ON THE REST API]

The app connects with the native MariaDB connector, straight to the tables on the sandbox. In native mode it never calls the notesApp endpoints, and in REST mode it reports that nothing is serving them. An optional third prompt defines them, and the server that would serve them over HTTP is not ready yet. So the app shows the schema is real and usable. The metadata shows the REST tier is defined. Two different claims, kept separate.
-->
