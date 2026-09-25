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

I gave a coding agent one job: build an app against a real MariaDB server, from the data tier up, with an API tier behind it. I expected the LLM underneath to be confidently wrong about MariaDB. It was, just not where I expected. Most of the build worked, because of two changes I made to how I work with the agent. I will show you both, and the one part that still did not work.

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

So I wrote down what I wanted, and handed it to an agent.
-->

---

### *Perfect time to vibe code my idea into existence...*

# Instead, I wrote down what the app does, in a short spec

<div class="columns">
<div>

## Real lines from my 48-line spec

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

## Three rules I follow for a spec and its prompts

1. **Describe what the app does.** Leave the code to the agent.
2. **Keep one spec and thin prompts.** A prompt picks a slice and points at the spec. The prompt never restates the spec.
3. **Write down what done means.** Every prompt ends by checking the "Done when" list.

</div>
</div>

*The prompt says what to build next. The spec says what right looks like.*

<!--
SPEAKER NOTES:

Perfect time to vibe code my idea into existence, right? That is the moment the keynotes promised you. But I have learned to write it down first. A one-line prompt leaves every name to the agent, and then the next run picks different names and your app breaks. So I wrote a short spec, the kind you write in fifteen minutes.

Here are the lines that matter. The data section says it is just me for now, and that my sample data must load without changes. That sample data is the contract: when it does not fit, the schema changes, never the data. A must-have: list the active notes, pinned first, newest first. And Done when: the schema loads, the sample data loads, and the counts come out at six notebooks, twelve tags, and sixty-one notes.

Three rules I follow. Describe what the app does, and leave the code to the agent. Keep one spec and thin prompts, so a prompt points at the spec instead of restating it. And write down what done means, so the agent checks its own work against my definition of done, not its own.

Then I handed it to an agent.
-->

---

# A coding agent built the schema: the SQL ran, and the agent was confidently wrong about reruns

<div class="columns">
<div>

## What the coding agent wrote from my spec

```sql
CREATE TABLE IF NOT EXISTS note (
  ...
  KEY ix_note_notebook_list
    (notebook_id, status,
     is_pinned, created_at)
```

- The SQL ran, and my sample data loaded

</div>
<div>

## What the agent said, and what happened

> "Safe to run more than once."

- I changed a column and reran the script
- No error, only a warning count
- The column did not change, and my fix never landed

</div>
</div>

<span class="accent">The SQL looked right, ran, and loaded my data. Nothing told me that my fix was ignored.</span>

<!--
SPEAKER NOTES:

A quick word on terms, because I use two of them all talk. By LLM I mean the language model underneath your agent. By agent I mean that LLM running inside a harness, like Claude Code or Codex, where it can read files and run tools.

So I gave my spec to a coding agent, the way most people start, and asked for the schema. And I want to be fair: the SQL was correct. It ran, and my sample data loaded into it.

And the agent told me something with total confidence: this script is safe to run more than once. So I tested that the way you would in real life. I changed a column, the way you do after the first bug report, and ran the script again. No error. Just a warning count. And the column did not change. The script creates each table only if it does not already exist, so every fix I make after the first run is silently ignored.

That is what confidently wrong looks like. Not a syntax error. SQL that looks right, runs, loads your data, and quietly ignores your fix.

So I went looking for help.
-->

---

# Skills teach the agent MariaDB, and tools let the agent run what it writes

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

**With both, the agent writes the statement, runs it, reads the result, and fixes what broke.**

<!--
SPEAKER NOTES:

I went looking for two things: a way for the agent to know current MariaDB, and a way for the agent to check its own work.

The first piece is skills. A skill carries the current MariaDB grammar, the order the statements have to run in, and the failure modes the docs leave out. MariaDB curates them, and a plugin installs them. When a task needs one, the agent loads it into its context, its working memory for the session. No fine-tuning. The LLM underneath does not change at all. And skills work offline, because knowledge does not need a database attached.

The second piece is tools. An MCP server gives the agent a live connection. It can run SQL, read the schema, run EXPLAIN, and when you have no database yet, deploy a sandbox. That is how I found the ignored fix: by running the script against a real server, not by reading it.

You need both. Knowledge without a connection gives you better code that you still copy and run by hand. A connection without the knowledge runs confident SQL faster, including SQL that ignores your fix. With both, the agent writes the statement, runs it, reads the result, and fixes what broke.

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

So here are both changes together: the same forty-eight-line spec, and now an agent with the skills and the tools. Watch it build.
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

# Same spec, now with skills: the agent wrote MariaDB, and a rerun applies the fix

<div class="columns">
<div>

## Before: the agent without skills

```sql
CREATE TABLE IF NOT EXISTS note (
  ...
  KEY ix_note_notebook_list
    (notebook_id, status,
     is_pinned, created_at)
```

</div>
<div>

## After: the agent with the skills

```sql
CREATE OR REPLACE TABLE notes_app.note (
  ...
  KEY ix_note_notebook_list
    (notebook_id, status,
     is_pinned DESC, updated_at DESC)
```

</div>
</div>

- A rerun replaces the schema, so a fix lands
- The index follows the spec's order: pinned first, newest first
- The counts matched the spec: 61 notes, 6 notebooks, 12 tags

<span class="accent">Same LLM, same spec. The skills changed the agent's context, and the agent used the database I chose.</span>

<!--
SPEAKER NOTES:

[UPDATE FROM THE RECORDED RUN: match the right-hand DDL to what the agent wrote on stage. The lines shown come from the same spec with the skills loaded, in research/skills-spec-run.sql.]

Here is the before and after. Same LLM. Same forty-eight-line spec. The difference is that the agent now has the MariaDB skills.

On the left, the agent before the skills: create the table only if it does not exist, and an ascending index. Now that I can put the two side by side, I can see something I could not see before. The first version was portable SQL that would run almost anywhere in the MySQL family. On the right, with the skills: CREATE OR REPLACE, so when I fix a column and run it again, the fix lands. It replaces the data too, and the agent told me that up front. And an index with pinned and updated descending, shaped to exactly the order the spec asks for, pinned first, newest first.

The spec never mentions any of this. Every MariaDB choice on the right is the agent's, made with a skill in its context. The LLM's training did not change. What changed is what the agent had to work with.

Then the agent checked itself against the spec. The server accepted the DDL, sixty-one notes loaded, and the counts matched. So the schema is real, and it is exactly the schema the app will bind to. Now we build on it.
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

The second is the agent's context, its working memory for the session. That is where the skills go, with the current MariaDB grammar. That is where my spec goes, with what to build and how to check it. And that is where my own corrections go. Here is a real one. While I built this talk, I corrected the agent three times on how to write these slides: no dangling pronouns, say LLM or agent instead of model, and plain headings. Each time, the agent wrote the rule into its memory files, so the next session started with the rule in place. I taught it once, not every session.

You write, review, and version all three like code. And here is the honest flip side: when the agent does not load that knowledge, the LLM's training fills the gap, and you are back to generic SQL.
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

1. **Skills make the agent write for your database, not for any database.** Without them, a frontier LLM writes correct, generic SQL. The ai-plugins load MariaDB's knowledge into the agent's context, in the harness you already use.
2. **Write a spec, and end the spec in acceptance criteria.** The spec stops the agent guessing about your app, and the criteria let the agent check its own work. Unlike a chat prompt, your team can review a spec.
3. **Give the agent tools to run against.** The MCP server opens a live connection and deploys a sandbox, so the agent runs its SQL and fixes what broke. Running it is how you catch a fix that never landed. When a run fails, wrong SQL points to missing knowledge, and a blocked connection points to the tools.

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

One. Skills make the agent write for your database, not for any database. Without them, a frontier LLM writes correct SQL that would run anywhere in the MySQL family. With them, the agent uses what you chose MariaDB for. The ai-plugins load that knowledge into the agent's context, in the harness you already use.

Two. Write a spec, and end it in acceptance criteria. The spec stops the agent guessing about your app, and the criteria let it check its own work against your definition of done, not its own. Unlike a chat prompt, your team can review a spec. That is spec-driven development, and it is how acts one and two happened.

Three. Give the agent tools to run against. The MCP server opens a live connection and can deploy a sandbox, so the agent runs its own SQL and fixes what broke, instead of handing you code to paste. And when a run fails, the split tells you where to look. Generic or wrong SQL means the LLM hit the edge of its training, so the agent needs a skill. A refused connection or a blocked path is a tools setting to fix.

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

Good ideas are crazy until they're not. That was Larry Page, at the start. You just watched most of one stop being crazy. An agent built a real data tier and a working app on top of it, because it had the knowledge, the connection, and a spec that said what right looks like. I showed you the part that is still crazy: an API tier that is defined, and not yet served. And I showed you where the agent was confidently wrong: a script it called safe to rerun, that quietly ignored my fix, until I ran it.

One idea, one spec, one conversation, from no app code to a running app that passed its own acceptance criteria, with the boundary named out loud along the way.

Everything you saw is public. The demo, the exact prompts, the spec, the schema, and the experiments behind these slides are in the first repo, Apache-2.0. The plugins are in the second, GPL-2.0, so you can read every skill and write your own.

One last thing before questions. This afternoon Quincy Larson closes the day with a keynote called How to Use Scaffolding to Make Your Coding Agents Less Dumb. That is this same idea, on a much bigger stage than mine, hours from now. You heard it here first, at ten-thirty, with a live database. Go see him. Then go write a short spec for your next idea, keep it about behaviour, and run everything the agent writes.

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
