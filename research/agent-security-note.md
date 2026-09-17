# Talking point: the blocked mass delete

A real incident from building this demo. While reseeding the sandbox, the agent
tried to wipe the table and the harness refused. It is a compact illustration of
where the guardrails on an agent actually sit, and it fits the talk's audience of
people deciding what an agent may execute and on what evidence.

## What happened

The agent ran this to reset the data before reloading the fixture:

```sql
DELETE FROM notes_app.account
```

The database would have run it without complaint. The account the agent was
connected as is the sandbox `root`, and the statement is valid. Every notebook,
note, tag and link would have gone too, because the foreign keys cascade on
delete. It never reached the server. The Claude Code auto-mode classifier stopped
the tool call first, with:

> Permission for this action was denied by the Claude Code auto mode classifier.
> Reason: [Cloud Storage Mass Delete].

The refusal also told the agent how to behave: try a safer method, do not work
around the denial in malicious ways, and if the action is essential, stop and let
the human decide. The agent did the safe thing. It skipped the wipe, ran an
idempotent no-op instead to confirm the new SQL parsed, and left the full
from-scratch validation for a clean deploy.

## Why it is a good talking point

**The guardrail lives above the database, not in it.** Two independent controls
were in play, and only one fired. The database's own permission model would have
allowed the delete, because the connected account had the privilege. The harness
classifier, sitting between the agent and the tool, blocked it on the shape of the
action alone. Least-privilege database accounts and harness-level action controls
are separate layers, and you want both.

**An unqualified `DELETE` is the canonical footgun.** No `WHERE`, whole table,
cascading to five more. Classifiers match exactly that shape: destructive,
irreversible, and broad. The same pattern catches `TRUNCATE`, `DROP`, and mass
updates.

**It was arguably a false positive, and that is the point.** This was a throwaway
sandbox and a legitimate reset. The guardrail cannot know that, so it trades a bit
of friction for safety and hands the decision back to the human. The refusal even
named the fix: a Bash permission rule the user adds deliberately, once, rather
than the agent deciding for itself.

**The agent's obligation on a block is to adapt, not to circumvent.** The designed
behavior is to find a safe alternative or escalate, never to reach for a clever
workaround. That is what keeps a capable agent inside the fence.

## How it maps to the talk

The abstract already promises the audience will leave knowing "what an agent may
execute and on what evidence," and that the allow-list keeping the agent inside the
working directory is configured once, up front. This is the same lesson one layer
deeper: the working-directory allow-list scopes what files it can touch, and the
action classifier scopes what operations it can run. The database's own grants are
the third layer. A DBA does not have to trust the agent's judgement, because three
independent controls each get a veto.

## The one-liner

The database would have run the delete. The account had the privilege. The harness
stopped it anyway, because safety on an agent is layered, and the destructive-action
classifier sits above the grants, not inside them.
