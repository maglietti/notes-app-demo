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

Good morning. You just sat through two keynotes about how agents are going to change everything. I want to do the opposite for twenty minutes. I want to get specific.

I gave a coding agent one job: build an app against a real MariaDB server, from the data tier up, API tier included. I knew before I started that a model is confidently wrong about a database it never trained on. I handed it the job anyway. And it worked, because of one change I made to the setup.

But start with why I would even try that.
-->

---

<!-- _paginate: false -->
<!-- _class: lead -->

# "Good ideas are always crazy until they're not."

### Larry Page

<!--
SPEAKER NOTES:

Larry Page said that. Handing a coding agent, one that is confidently wrong about a database it never trained on, the job of building an API tier, is a crazy idea. That is the "anyway" in the title of this talk.

So here is my deal with you. By the end, you will watch it stop being crazy, and see the one place it is still crazy. Let me start with the idea.
-->

---

<!-- _class: lead -->

# I had an idea.

### **And I wanted to build the app, not stand up a tech stack.**

<!--
SPEAKER NOTES:

Start with the itch, because I think you know this one.

I had an idea. A small one, the kind you get on a Tuesday and want to have running by Wednesday. And I wanted to build it the way every demo now promises you can: describe it to an agent, and watch it come together against a real database.

Not spend the afternoon standing up a stack. Not paste code from a chat window into a terminal and hope. Build the thing. Schema, data, an API, a working front end.

Let me tell you what the idea was.
-->

---

# The idea: a notebook that lives in my terminal

<div class="columns">
<div>

## The feel

A fast, keyboard-first notebook you never have to leave the terminal for. Three panes: the notebooks, the notes, and the note you are reading, in Markdown.

*The kind of tool you keep open all day.*

</div>
<div>

## What it does

- **Search** every note, full text, instantly
- **Pin** what matters to the top
- **Archive** what is done, out of the way
- **Trash** with a way back, never a cliff
- **Tag** and filter across notebooks

</div>
</div>

<!--
SPEAKER NOTES:

Here is the idea, and I want you to picture it, because the whole point is that in my head it is already real app.

A notebook that lives in the terminal. No browser, no tab to lose, no mouse. Three panes. On the left, your notebooks. In the middle, the notes inside the one you picked. On the right, the note you are reading, rendered from Markdown.

And it does the things you actually want a notebook to do. Search across everything, full text, the moment you type. Pin the notes that matter so they float to the top. Archive the ones you are done with so they get out of your way. Trash, with a way back, because nobody wants a cliff. Tags, so you can slice across notebooks.

That is the app. The kind of thing you would keep open all day. So I opened an agent, pointed it at MariaDB, and asked it to build exactly that.
-->

---

### *Perfect time to vibe code my idea into existence...*

# What usually happens: the LLM lies to you, fluently

<div class="columns">
<div>

## What it hands you

- SQL that is syntactically perfect
- Grammar borrowed from the wrong database
- Not one word about what it guessed

</div>
<div>

## The trap

The SQL parses, and it usually runs. Then you exercise the app and CRUD breaks: a create rejected, an update touching the wrong rows, a read in the wrong shape. You catch it in testing, and every pass is time you wanted for the app.

<span class="accent">Confidently wrong _hallucinations_ are not syntax errors. It is code that looks right and behaves wrong when you use it.</span>

</div>
</div>

<!--
SPEAKER NOTES:

Perfect time to vibe code my idea into existence, right? This is the moment the keynotes promised you. And here is what usually happens instead. The villain of the story shows up, and it is not a dumb model. It is a fluent one.

Ask a model for SQL and you get something that runs, something that looks like a careful engineer wrote it. And for anything it never trained on, it is guessing, and it will not tell you which parts.

That is the trap. The SQL parses, and it usually runs, so nothing waves a flag. Then you exercise the app and the operations break. A create gets rejected. An update touches the wrong rows. A read comes back in a shape the client did not expect. You catch it in testing, not in production, but every pass through that loop is time you meant to spend building, not debugging someone else's confident guess.

That is what I mean by confidently wrong. It is not a syntax error you can see. It is code that looks right and behaves wrong the moment you use it, and the reason is knowledge, not intelligence. Now, why does a database make this so much worse.
-->

---

# So prototyping stalls before it starts

<div class="columns">
<div>

## Stale, MySQL-flavored knowledge

The model reaches for MySQL habits that do not fit this schema.

- **Keys:** `BINARY(16)` + `UUID()`, missing MariaDB's `UUID` type and `UUID_v7()`
- **Collation:** MySQL's `utf8mb4_0900_ai_ci`, which MariaDB does not have
- **New row back:** `LAST_INSERT_ID()`, useless for UUID keys, not `INSERT ... RETURNING`

*The first things that bite when you move a schema across, not edge cases.*

</div>
<div>

## Standing up the stack by hand

The time you meant for the app goes to plumbing.

- Which version? Docker? A container runtime?
- Ports, credentials, teardown

*An hour of setup before line one of the app.*

</div>
</div>

<!--
SPEAKER NOTES:

Two things stall you here, and together they kill the momentum that makes prototyping worth doing.

The first is knowledge. The model blends MariaDB and MySQL, because they share a family tree, and it reaches for the MySQL habit that does not fit. Three of them show up building this exact app. Our tables are keyed on UUIDs, and MariaDB has a native UUID type and UUID_v7 for keys that sort by time. MySQL has neither, so the model reaches for a BINARY 16 column and the old UUID function, and now your keys are a different type and they do not sort. Every table has a collation, and current MariaDB uses the uca1400 family. The model writes MySQL 8's utf8mb4_0900_ai_ci, which MariaDB does not have, so the CREATE TABLE just fails. And when the app creates a note, it needs the new id back. With a UUID key, MySQL's LAST_INSERT_ID gives you nothing, because that is an auto-increment idea. MariaDB has INSERT RETURNING, and the model does not reach for it. None of these are obscure. They are the first things that bite when you move between the two.

The second is infrastructure. Before you write a single line of the actual app, you are picking a version, fighting Docker, opening ports, wiring credentials, and remembering to tear it down. That is an hour of setup standing between you and the idea.

Both of them, and here is the part that stings. While you fight them, you never get to the reason you chose this database in the first place.
-->

---

# And you never reach what MariaDB actually does

<div class="columns">
<div>

## What this app could lean on

- **Row history** on accounts and notebooks, from system versioning
- **Time-ordered keys**, so the note list sorts itself (`UUID_v7()`)
- **Full-text search** over title and body, no second system
- **One default notebook**, enforced by the schema, not app code

</div>
<div>

## What you build instead

Left to its own knowledge, the model gives you the plain version, so you rebuild the rest by hand: triggers for history, app logic for the default rule, search bolted on the side.

<span class="accent">More code, to get less than the server already does.</span>

</div>
</div>

<!--
SPEAKER NOTES:

This is the part I will not lose in a talk about agents, because it is the reason any of this matters.

MariaDB is good on its own, and this app leans on it. System versioning keeps row history on accounts and notebooks, so I do not write audit triggers or shadow tables. UUID version 7 gives me keys that sort by time, so the note list comes back in order without extra work. FULLTEXT searches title and body, so I do not stand up a separate search system. And a generated column enforces one default notebook per account, so my app code never has to.

All of that is in the server today. But left to its own knowledge, the model does not use any of it. It hands me the plain version, and I rebuild the rest by hand: triggers for history, app logic for the default rule, search bolted on the side. More code, to get less than the server already does.

So the capability is there. What is missing is a way for the agent to know it and use it. That is the fixable part, and it is the turn in the story.
-->

---

# What if the agent already knew?

<div class="columns">
<div>

## Skills carry the knowledge

- Markdown files, one per topic
- The current grammar, the ordering rules, the failure modes
- Reviewed and versioned, no fine-tuning
- They work offline, with no database at all

</div>
<div>

## Tools carry the reach

- An MCP server: a live database connection
- Run SQL, read the schema, run `EXPLAIN`
- Deploy a sandbox server on demand

</div>
</div>

**Together they close the loop: the agent writes the right statement, runs it, reads what comes back, and fixes what broke.** Either one alone leaves you doing half the job by hand.

<!--
SPEAKER NOTES:

Here is the turn in the story. What if the agent was not guessing. What if it already knew.

Two pieces make that happen, and telling them apart is the single most useful idea I can give you today.

The first is skills. A skill is a Markdown file, one per topic, that carries the current grammar, the order the statements have to run in, and the failure modes the docs leave out. No code. No fine-tuning. Just reviewed, versioned knowledge. And it works offline, because knowledge does not need a database attached.

The second is tools. An MCP server hands the agent a live connection: run SQL, read the schema, run EXPLAIN, and when you have no database yet, deploy a sandbox.

You need both, and here is why. Knowledge without reach just gives you better code that you still copy and run by hand. Reach without knowledge lets the agent run confident, wrong SQL faster than ever. Put them together and the agent writes the right statement, runs it, reads the result, and fixes what broke. It closes its own loop. Now, where do you get both.
-->

---

# ai-plugins: hand your agent the knowledge and the keys

<div class="columns">
<div>

## What it is

- MariaDB **skills**, curated and current
- The **`mariadb-shell` MCP server**, wired up
- Baseline MariaDB 11.8 LTS

## Install, one line

```
/plugin marketplace add mariadb/ai-plugins
/plugin install dev@mariadb
```

</div>
<div>

## Bring your own harness

Claude Code · Codex · OpenCode · Pi

## What to expect

- **Skills work the moment you install them**, offline
- **The MCP server** takes one setup step
- **The sandbox** deploys a real server: no Docker, no root

<span class="accent">ai-plugins.mariadb.com</span>

</div>
</div>

<!--
SPEAKER NOTES:

This is the one thing I installed, and it is the star of the show. The MariaDB ai-plugins. A curated set of skills plus the mariadb-shell MCP server, packaged for the harness you already use, baseline MariaDB 11.8 LTS.

Two lines to install. Add the marketplace, install the plugin. It runs in Claude Code, Codex, OpenCode, and Pi, so bring whatever harness you like.

Three things to expect, because I promised you specifics. The skills work the instant you install them, offline, no database needed, because they are just knowledge. The MCP server takes one setup step, where you tell it what it is allowed to touch. And when you have nothing, the sandbox deploys a real MariaDB server for you, with no Docker and no root. That last one is why the demo you are about to watch starts from an empty directory.

Everything from here is that plugin, doing its job, in one conversation. Watch.
-->

---

<!-- _class: lead -->

# Act one: from a spec to a schema

### **I wrote the data model. The agent writes the DDL.**

```
Work in this repository and complete every step in order.

1. Turn the data model in section 4 of docs/notes_app-prd.md
   into MariaDB DDL in working/notes_app.sql, then compare it
   with research/notes_app.sql.
2. Deploy a MariaDB 11.8 sandbox on port 3310 and run the DDL.
3. Seed it with research/synthetic_data.sql. If the fixture
   fails, fix the schema. Never edit the fixture.
4. List the tables and report each table's row count.
```

<!--
SPEAKER NOTES:

Act one, and I want to be straight about what is scripted, because that is the whole talk. This is the prompt I ran, trimmed to fit the slide. The full text is in the repo.

Notice what it does and does not say. It names the artifacts, it numbers the steps, and it says complete them in order. That is how you phrase a prompt so the work lands. And it points at a spec. Section 4 of my product doc lays out the data model: the tables, the columns, the keys. I wrote that once. The agent's job is to turn it into DDL, deploy a server, run it, and then prove it by loading real data. The fixture is the contract. If the data does not fit, the schema changes, never the data.

Watch what it does with it.
-->

---

# Watch it write, deploy, run, and prove itself

<div class="watch">

**What is happening on screen**

1. It **reads** the data model in the spec and **writes** the DDL
2. It **deploys** a MariaDB sandbox on port 3310, with no Docker and no root
3. It **runs** the DDL over MCP against that live server
4. It **loads 61 real notes** as the data contract, and confirms its own work

</div>

*An agent that emits code hands you a review. An agent that runs it against a live server hands you a result.*

<!--
SPEAKER NOTES:

[CUT TO RECORDING, ACT ONE]

Four things are happening here. It reads the data model out of my spec and writes the DDL. It deploys a MariaDB sandbox on port 3310, and notice, there was no Docker step, no container, nothing I set up beforehand. It runs the DDL over the connection against that live server. And then it loads sixty-one real notes into it, the fixture that the app depends on, and reads the counts back.

That last step is the difference between a demo and a result. An agent that just prints code hands you a review task. This one ran its own code against a real database, and then made real data prove it. It closed the loop by itself.

[LET THE SCHEMA LAND, THEN ADVANCE]
-->

---

# It wrote current MariaDB, and the data proved it

```sql
CREATE OR REPLACE TABLE notes_app.note (
  id      uuid  NOT NULL DEFAULT uuid_v7(),
  status  enum('active','archived','trashed') NOT NULL DEFAULT 'active',
  FULLTEXT KEY ft_note_title_body (title, body)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
```

- `CREATE OR REPLACE TABLE` with the `uca1400` collation, not MySQL's `utf8mb4_0900`
- A `uuid_v7()` primary key and `FULLTEXT` search, both in the `note` table shown
- Then the fixture loaded: 61 notes, 6 notebooks, 12 tags

<span class="accent">My spec says what each column does, never the syntax. The MariaDB grammar is the agent's own work.</span>

<!--
SPEAKER NOTES:

Now look at what it actually wrote, because this is the payoff of act one.

CREATE OR REPLACE TABLE. utf8mb4 with the current uca1400 collation. UUID keys defaulting to uuid_v7. System versioning on the owner tables. A generated column that enforces one default notebook per account. A FULLTEXT index for search.

Remember the MySQL habits from a few minutes ago, the BINARY 16 keys and the collation that does not exist on MariaDB? None of them are here. And check me on this, because the spec is in the repo: it never says uuid_v7, uca1400, or system versioning. It says a time-ordered UUID key, row history kept in the table itself, one default notebook per account. The agent picked the current MariaDB grammar for each of those, with a skill in the room. Then it proved the result: the server accepted the DDL, and sixty-one notes loaded into it.

So the schema is real, and it is exactly the schema the app will bind to. Now we build on it.
-->

---

<!-- _class: lead -->

# Act two: an idea you can open

### **Spec-driven development: I wrote the PRD, the agent builds to it.**

```
Build the Textual app that docs/notes_app-prd.md specifies,
in native mode only: the three-pane layout from section 7
and every Must feature from section 6.

Verify both entry points against the sandbox: bin/notes-app
and the notes-app console script.
```

<!--
SPEAKER NOTES:

Act two, still the same conversation, and this is spec-driven development. The same product requirements document that gave act one its data model also describes the app: the three-pane layout, the feature list, the architecture. Now I point the agent at it and ask it to build the client that spec describes, and run it.

That is the shift worth naming. I am not describing the app in a chat prompt. I wrote the spec once, and the agent builds to it. The same context that built my tables reads my spec and writes my front end. You keep talking to one agent, and it keeps building.
-->

---

# From an empty directory to a running app

<div class="watch">

**What is happening on screen**

1. It **reads the product doc** and builds a real Python package, not a snippet
2. It **runs** the app against the sandbox, from the launcher and the installed command
3. Three panes: **notebooks**, **notes** with pinned ones on top, the **note view**
4. The status line reads `native`, next to the sandbox address

</div>

*One conversation carried an idea from nothing to something you can use.*

<!--
SPEAKER NOTES:

[CUT TO RECORDING, ACT TWO]

It reads the product doc and builds a real Python package. Not a snippet in a chat window. A project, with an entry point and dependencies. Then it runs it, both from the launcher and from the command it installed, because a package that installs with no code in it is a classic way to fool yourself.

And there it is. Three panes. On the left, the notebooks from act one. In the middle, the notes, with the pinned ones sorted to the top, exactly the way the schema's index intended. On the right, a note rendered from Markdown. Along the bottom, a status line that reads native, so it talks straight to the tables on the sandbox. That is the data act one loaded, on screen.

From an empty directory to a working app, in one conversation.

[IF THE CLOCK ALLOWS, ADVANCE TO ACT THREE. OTHERWISE SKIP TO "REAL IN THE METADATA" FOR THE 30-SECOND BOUNDARY BEAT.]
-->

---

<!-- _class: lead -->

# Act three: from the schema to a REST API

### **Same conversation. The least-trained grammar in the run.**

```
Build the REST Service from PRD section 5. Run the DDL through
db.execute_sql one statement at a time, because the grammar is
session state. Verify with SHOW REST, read /note back, then
publish.

Add RestDataSource, select it with NOTES_APP_MODE, and run the
app in both modes.
```

<!--
SPEAKER NOTES:

[OPTIONAL ACT. RUN IT, OR CUT TO ITS RECORDING, ONLY WHEN THE CLOCK ALLOWS.]

Act three, and I have not started a new chat. Same agent, same context. It built my schema and my app. Now I ask it to put a REST Service in front of the schema, and to teach the app to use it.

This is the tier the talk is named for, and the real test, because the REST grammar is the most niche syntax in the whole run. It is exactly where a skill earns its place. So do not look away. Watch the agent handle it.
-->

---

# It writes the least-trained grammar in the run

<div class="watch">

**What is happening on screen**

1. The REST grammar runs **one statement per session**, and the agent follows that rule
2. It builds the **service, a schema, and a view per table**, and `SHOW REST` confirms them
3. Reading `/note` back shows the **tool dropped the read-only tag flags**, and the agent reports it
4. It **refactors the app**: a REST data source beside the native one, picked by one variable
5. In REST mode the **status line reports the missing router**, and the app stays up

</div>

*The trickiest grammar in the run, and the skill carries the agent through it.*

<!--
SPEAKER NOTES:

[CUT TO RECORDING, ACT THREE]

This is the trickiest grammar in the whole run. It runs one statement per session, a rule most models have never seen, and I named that rule in the prompt, because saying what you already know is how you phrase a prompt. The prompt also names what I want from each view: a key, sort columns, nested tags, and create, update and delete. Writing those into valid REST Service DDL is the grammar a model is most likely to get wrong from memory. The service, the schema, and a view per table land, and SHOW REST confirms them. Then it reads the note view back, and here is a surprise that is not the model's fault. It wrote the read-only flags on the nested tags correctly, and the tool dropped them on the way into the metadata. The agent only catches that because I told it to read the metadata back. Check the source of truth, not the summary.

Then it goes back to the app it built in act two, adds a REST data source beside the native one, and picks between them with one environment variable. In REST mode the status line says plainly that nothing is serving the endpoints yet, and the app stays up. When the metadata comes up, I get precise.

[ADVANCE WHEN SHOW REST APPEARS]
-->

---

# Real in the metadata. Serving it needs a router.

<div class="columns">
<div>

## The proof

```
SHOW REST VIEWS;
```

Lists `/note`, `/notebook`, `/tag`
under the `/notesApp` service.

The endpoints the agent defined are in the metadata.

</div>
<div>

## The line

<span class="boundary">The API is defined right here. Serving it over HTTP is a router, a separate job I did not stand up today.</span>

I am not going to tell you these endpoints answer a web request, because that is not what I built.

</div>
</div>

**Knowing where the agent's work stops is the whole point.** So I am saying it out loud.

<!--
SPEAKER NOTES:

[THE SKIP PATH LANDS HERE. IF ACT THREE DID NOT RUN, SAY: "The same agent also put a REST Service in front of this schema. Here is the metadata from that run." THEN CONTINUE.]

So how do I know the tier is real. Not because I called it over HTTP. Because I can read it. SHOW REST VIEWS lists the endpoints the agent defined, note, notebook, tag, under the notesApp service. They are genuinely there, in the metadata.

And here is the line I promised you in the first minute. The agent built the API definition. Serving that definition over HTTP is the job of a router, a separate piece I chose not to stand up for this talk. So I am not going to tell you these endpoints answer a web request, because that is not what I built. They are defined. Serving them is a router away.

That distinction is the entire thesis in one breath. The agent is genuinely good, right up to a boundary, and the honest move is to name the boundary instead of smudging it. Which is exactly the tension in the title of this talk. Now, something happened during cleanup that I did not plan.

[ADVANCE]
-->

---

# The database would have run it. The harness would not.

<div class="columns">
<div>

## What happened

While reseeding, the agent tried:

```sql
DELETE FROM notes_app.account
```

No `WHERE`. The whole table. Cascading to five more.

> Permission denied by the Claude Code auto mode classifier.
> Reason: [Cloud Storage Mass Delete].

</div>
<div>

## Why it should reassure you

Three independent controls, each with a veto:

1. **Allow-list**: which files it can touch
2. **Action classifier**: which operations it can run
3. **Database grants**: what the account may do

*The account had the privilege. The guardrail sits above the grants, not inside them.*

</div>
</div>

<!--
SPEAKER NOTES:

You should see this one, because you are the people who decide what an agent is allowed to run.

During that cleanup, reseeding the sandbox, the agent tried to reset the data with this. DELETE FROM account. No WHERE clause. The whole table, cascading to five more through foreign keys. The database would have run it without blinking. The account it was connected as had the privilege. It was valid SQL.

It never reached the server. The harness stopped the tool call first, and told the agent to find a safer path or hand the call to a human. Which it did.

Here is why that should reassure you rather than scare you. Safety on an agent is layered. The allow-list controls which files it can touch. The action classifier controls which operations it can run. The database grants control what the account may do. Three independent controls, each with its own veto. The database's own permissions would have allowed this. The thing that caught it sits above the grants, not inside them. You want both layers, and you do not have to trust the agent's judgment to be safe. Now let me pull the camera back, because this is bigger than my little notes app.
-->

---

# Your agent is only as current as what you publish

<div class="columns">
<div>

## Why the agent got MariaDB right

Not luck. MariaDB publishes its knowledge for agents, not only for browsers:

- `llms.txt`, a map of the docs for a model
- Raw Markdown, not HTML to parse
- An MCP interface, so the agent calls a tool
- `?ask=`, docs that answer a question

</div>
<div>

## You can do the same for your project

- MariaDB's docs run on GitBook and expose all four, and the ai-plugins carry that knowledge into the coding loop as skills
- You cannot retrain the model. You can publish skills and an interface, so the agent reasons from your current knowledge, not a stale guess

</div>
</div>

**The projects agents handle well are the ones that made their knowledge reachable. That is a choice, and it is yours.**

<!--
SPEAKER NOTES:

Pull back with me for a second, because this is bigger than my notes app.

Ask why the agent got MariaDB right. It was not luck, and it was not a smarter model. It was that MariaDB publishes its knowledge in a form an agent can use. The docs run on GitBook, and they expose an llms.txt that maps the docs for a model, raw Markdown instead of HTML you have to parse, an MCP interface so the agent calls a tool instead of scraping, and an ask endpoint that answers a question directly. The ai-plugins take that same knowledge into the coding loop as skills.

Here is the part for the maintainers in the room, and I think that is a lot of you. You do not get to retrain the model on your project, and you never will. But you do get to publish your knowledge where an agent can reach it, so that when someone points their agent at your thing, it reasons from what you actually shipped instead of a two-year-old guess. The projects agents handle well are the ones that made that choice. It is a choice, and it is yours.
-->

---

# What to take home

<div class="columns">
<div>

1. **Skills are the fix, not a cleverer prompt.** When the model guesses past its training, more prompting will not make it know current MariaDB. A skill hands it the knowledge, and the plugin installs it in the harness you already use.
2. **Tools give the agent something to run against.** The MCP server opens a live connection and deploys a sandbox server, so the agent runs its SQL and fixes what broke. When a run fails, wrong SQL points to missing knowledge, and a blocked connection points to the tools.
3. **Name the artifact, not the outcome.** Ask for the schema, the DDL file, the running app, and number the steps when the order matters.

</div>
<div>

4. **For real work, write a spec.** A short PRD drives the agent better than a chat prompt, and unlike a prompt it is something you can review. That is spec-driven development.
5. **Guardrails are layered, so set all three.** The working-directory allow-list, the harness action classifier, and the database grants each get a veto. You do not have to trust the agent's judgment to keep it safe.
6. **Start on greenfield.** The loop is fast and there is no existing code to put at risk. Build your confidence where the blast radius is smallest, then take it into harder work.

</div>
</div>

<!--
SPEAKER NOTES:

Six things to carry out the door, whatever database you run.

One. Skills are the fix, not a cleverer prompt. When the model guesses past its training, no amount of prompting makes it know current MariaDB. A skill hands it that knowledge, and the plugin installs it in the harness you already use.

Two. Tools give the agent something real to run against. The MCP server opens a live connection and can deploy a sandbox server, so the agent runs its own SQL and fixes what broke instead of handing you code to paste. And when a run fails, the split tells you where to look. Wrong SQL means the model hit the edge of its training, so you add a skill. A refused connection or a blocked path is a tools problem, a setting to fix.

Three. Name the artifact you want. Ask for the schema, the DDL file, the running app, not the outcome you are imagining, and number the steps when the sequence matters.

Four. For real work, write a spec. For anything past a one-liner, a short product doc drives the agent better than a chat prompt, and unlike a prompt it is something you and your team can review. That is spec-driven development, and it is how acts one and two happened.

Five. Guardrails are layered. The working-directory allow-list, the harness action classifier, and the database grants each get a veto. Set all three, and you do not have to trust the agent's judgment to stay safe.

Six. Start on greenfield. The loop is fast and there is no existing code to put at risk. Build your confidence where the blast radius is smallest, and carry it into harder work from there.
-->

---

<!-- _paginate: false -->
<!-- _class: lead -->

# Go build something confidently right

*Crazy until it's not. You watched it flip, and I showed you where it hasn't.*

**Demo, prompts, and schema:** *github.com/maglietti/notes-app-demo* (Apache-2.0)

**The plugins:** *ai-plugins.mariadb.com* (GPL-2.0)

&nbsp;

### Questions?

<!--
SPEAKER NOTES:

Good ideas are crazy until they're not. That was Larry Page, at the start. You just watched one stop being crazy: a confidently wrong agent built a real data tier, a working app on top of it, and an API tier you can read in the metadata, because it had the knowledge and the reach. And I showed you the one place it is still crazy, the router I did not stand up.

That is the story. One idea, one conversation, from an empty directory to a running app, with the boundary named out loud along the way.

Everything you saw is public. The demo, the exact prompts, and the schema are in the first repo, Apache-2.0. The plugins themselves are in the second, GPL-2.0, so you can read every skill and write your own.

One last thing before questions. This afternoon Quincy Larson closes the day with a keynote called How to Use Scaffolding to Make Your Coding Agents Less Dumb. That is this same idea, restated hours later on a much bigger stage than mine. You got it here first, at ten-thirty, with a live database. Go see him. And then go write a skill for whatever your own agent is confidently wrong about.

Questions.
-->

---

<!-- _paginate: false -->

# Appendix: one plugin, three layers

<div class="columns">
<div>

## You install the top

| Layer | What it is |
| ----- | ---------- |
| `ai-plugins` | Skills, and the wiring |
| `mariadb-shell` | The runtime, the MCP server, the secret store |
| `mariadb-shell-plugins` | The tools, and the REST grammar |

</div>
<div>

## How it fits

- Install `ai-plugins`; it downloads the shell on first run
- The shell hosts the MCP server as a plugin
- Passwords live in the shell's secret store, never a config file
- 28 tools: `db.*`, `msm.*`, `sandbox.*`

</div>
</div>

<!--
SPEAKER NOTES:

[Q&A backup, for the architecture question]

If someone asks how the pieces fit. You install one thing, the ai-plugins. On first run it downloads the mariadb-shell, the runtime that hosts the MCP server as a plugin and keeps your passwords in a real secret store, never a config file. Underneath, the shell plugins are where the tools and the REST grammar are actually implemented. Twenty-eight tools in three groups. db for SQL and schema reads, msm for schema management, sandbox for local sandbox servers. You install the top layer, and the rest arrives on first run.
-->

---

<!-- _paginate: false -->

# Backup: native mode versus the REST tier

<div class="columns">
<div>

## How the app connects

- The native MariaDB connector, to the sandbox on 3310
- No router, no daemon, it starts offline
- A real client on the schema the agent designed

</div>
<div>

## Why it is not proof of REST

<span class="boundary">In native mode it never calls the `/notesApp` endpoints. Those were defined in Act three, and serving them needs a router, so REST mode has nothing to answer it. The app takes the native path to the same tables.</span>

</div>
</div>

**The app tells you the schema works. Whether the REST endpoints serve is answered by the metadata, not by this app.**

<!--
SPEAKER NOTES:

[Q&A backup, if someone asks whether the app runs on the REST API]

The app connects with the native MariaDB connector, straight to the tables on the sandbox. In native mode it never calls the slash notesApp endpoints, and in REST mode it reports that nothing is serving them. Those were defined in Act three, and serving them over HTTP needs a router I did not stand up. So the app shows the schema is real and usable. Whether the REST tier serves was answered earlier, in the metadata. Two different claims, kept separate.
-->
