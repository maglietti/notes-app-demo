-- synthetic_data.sql
-- Test data for the canonical notes_app schema (research/notes_app.sql).
-- Self-contained: creates the seeded account, six notebooks, twelve tags,
-- sixty-one notes across all statuses, and the tag links. Set-based and
-- guarded with NOT EXISTS, so it is safe to run more than once and can be loaded
-- against a bare schema. The account is referenced by email, so no UUID is
-- hard-coded and a fresh deploy works unchanged.
--
-- The note bodies are the kind of work a developer relations team actually
-- tracks: content in flight, demo mechanics, community threads, reading, and
-- personal errands. They stay on MariaDB's own behavior and measurements and
-- name no other database vendor, so the seeded app reads as a working notebook
-- on stage rather than a competitive brief.

-- 1. The seeded account the client runs as.
INSERT INTO notes_app.account (email, display_name)
SELECT 'michael.aglietti@mariadb.com', 'Michael Aglietti'
WHERE NOT EXISTS (
  SELECT 1 FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com'
);

-- 2. Notebooks. Inbox is the one default (default_flag enforces at most one).
INSERT INTO notes_app.notebook (account_id, name, is_default)
SELECT (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com'), x.name, x.is_default
FROM (
  SELECT 'Inbox' AS name, 1 AS is_default
  UNION ALL SELECT 'DevRel', 0
  UNION ALL SELECT 'Conferences', 0
  UNION ALL SELECT 'Community', 0
  UNION ALL SELECT 'Reading', 0
  UNION ALL SELECT 'Personal', 0
) x
WHERE NOT EXISTS (
  SELECT 1 FROM notes_app.notebook nb
  WHERE nb.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
    AND nb.name = x.name
);

-- 3. Tags.
INSERT INTO notes_app.tag (account_id, name)
SELECT (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com'), x.name
FROM (
  SELECT 'mariadb' AS name
  UNION ALL SELECT 'talk'
  UNION ALL SELECT 'todo'
  UNION ALL SELECT 'community'
  UNION ALL SELECT 'vector'
  UNION ALL SELECT 'replication'
  UNION ALL SELECT 'blog'
  UNION ALL SELECT 'idea'
  UNION ALL SELECT 'benchmark'
  UNION ALL SELECT 'conference'
  UNION ALL SELECT 'personal'
  UNION ALL SELECT 'licensing'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM notes_app.tag t
  WHERE t.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
    AND t.name = x.name
);

-- 4. Notes: 48 active (6 pinned), 7 archived, 6 trashed.
INSERT INTO notes_app.note (notebook_id, account_id, title, body, status, is_pinned)
SELECT nb.id,
       (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com'),
       s.title, s.body, s.status, s.pinned
FROM (
  -- DevRel: content in flight and demo mechanics.
  SELECT 'DevRel' AS nb, 'Optimizer trace notes' AS title, 'The optimizer_trace output in MariaDB 11.8 explains why the join order changed after the index was added. Capture the before and after JSON for the blog post.' AS body, 'active' AS status, 1 AS pinned
  UNION ALL SELECT 'DevRel', 'Community call agenda', 'Vector search demo, the 11.8 upgrade path, and the open questions carried over from the forum.', 'active', 0
  UNION ALL SELECT 'DevRel', 'ATO demo run-of-show', 'Time the scaffolding run and the app capstone. Target twenty minutes with buffer for questions.', 'active', 1
  UNION ALL SELECT 'DevRel', 'Skill coverage gaps', 'List the MariaDB features the agent gets wrong without a skill. Vector search and system versioning are the clearest two.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Blog closing the agent loop', 'Draft on how an MCP connection lets the agent run its own SQL and verify the result instead of guessing.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Video sandbox in five minutes', 'Screencast deploying a throwaway MariaDB instance and running DDL over MCP.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Migrator demo notes', 'MySQL to MariaDB migration over MCP. Show the resume-safe restart and the false success trap.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Tutorial vector search in twenty lines', 'VECTOR column, VEC_DISTANCE_COSINE, and one HNSW index. Embeddings come from a local model so the reader needs no API key.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Docs gap on system versioning', 'The FOR SYSTEM_TIME examples stop at AS OF. Add AS OF now minus an interval, BETWEEN, and the partition-pruning caveat.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Office hours question log', 'Recurring questions worth turning into posts: connector pooling defaults, JSON validation, and picking a collation.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Newsletter draft on 11.8 LTS', 'Lead with vector indexes, then the uca1400 collations and the utf8mb4 default. Keep it to four paragraphs.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Sample data generator idea', 'A small script that seeds realistic rows for any schema, so tutorials stop shipping foo and bar.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Quarterly content plan', 'Three tutorials, one webinar, two conference talks. Prioritise the REST service walkthrough.', 'archived', 0
  UNION ALL SELECT 'DevRel', 'Webinar on schema management', 'Versioned schema with MSM and a walkthrough of the section model.', 'archived', 0

  -- Conferences: logistics and submissions.
  UNION ALL SELECT 'Conferences', 'All Things Open logistics', 'Databases track, room 306A, Tuesday morning. Bring the HDMI adapter and the recorded fallback clip.', 'active', 1
  UNION ALL SELECT 'Conferences', 'Talk abstract revisions', 'Trim the two setup paragraphs. Lead with the confidently wrong framing.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Speaker bio update', 'Refresh the headshot and the one-line bio before the program goes to print.', 'active', 0
  UNION ALL SELECT 'Conferences', 'CFP tracker', 'Submitted to three events, waiting on two. Next deadline is the SCALE call, closing in eleven days.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Workshop lab environment', 'Forty attendees need a sandbox each. Pre-pull the container image and hand out a printed connection string.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Hallway track notes', 'Three people asked how to test a migration without a staging copy. That is a talk on its own.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Booth demo checklist', 'Laptop, USB stick with the sandbox, printed one-pagers, stickers.', 'archived', 0
  UNION ALL SELECT 'Conferences', 'Travel receipts for FOSDEM', 'Filed. Keeping the note until the reimbursement clears.', 'archived', 0
  UNION ALL SELECT 'Conferences', 'Percona Live follow-ups', 'Reconnect with the replication folks about the failover measurements.', 'trashed', 0

  -- Community: contributors, forums, and meetups.
  UNION ALL SELECT 'Community', 'Triage first-time contributor PRs', 'Four open pull requests are waiting on a first review. Anything older than a week gets a reply today.', 'active', 1
  UNION ALL SELECT 'Community', 'Good first issues list', 'Curate ten issues with enough context that a newcomer can start without asking. Docs examples are the easiest win.', 'active', 0
  UNION ALL SELECT 'Community', 'Where support questions should live', 'Forum threads stay searchable, chat does not. Write down the routing rule and link it from the README.', 'active', 0
  UNION ALL SELECT 'Community', 'Meetup speakers wanted', 'Two slots open for the spring series. Ask the connector maintainers and the ColumnStore team.', 'active', 0
  UNION ALL SELECT 'Community', 'Contributor guide refresh', 'The build steps are two releases behind and the sign-off section is missing. Rewrite both and test on a clean machine.', 'active', 0
  UNION ALL SELECT 'Community', 'Mentoring plan for docs contributions', 'Pair a new contributor with a maintainer for their first three pages. Set a two-week check-in.', 'active', 0
  UNION ALL SELECT 'Community', 'Forum thread on connector timeouts', 'Reproduced the pool exhaustion with connectionLimit at the default. Reply with the acquireTimeout explanation.', 'active', 0
  UNION ALL SELECT 'Community', 'Community survey questions', 'Ran last quarter. Keeping the question set for the next round.', 'archived', 0
  UNION ALL SELECT 'Community', 'Old meetup venue notes', 'The venue closed. No longer useful.', 'trashed', 0

  -- Inbox: the default notebook, unsorted capture.
  UNION ALL SELECT 'Inbox', 'Reply to forum thread', 'Answer the question about UUID_v7 index locality and why it beats UUID v4 on insert-heavy tables.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Expense report', 'Submit the conference travel expenses before month end.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Renew SSL cert', 'The staging demo certificate expires next month.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Idea skill for window functions', 'A skill covering OVER and the framing clauses would close a common gap.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Reset sandbox before rehearsal', 'Drop and redeploy so the run starts from the same state every time.', 'active', 1
  UNION ALL SELECT 'Inbox', 'Ask docs team about REST examples', 'The REST service pages need a worked example that returns rows, not just the DDL.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Follow up on the benchmark harness', 'Pin the dataset, the client count, and the warmup time, or the numbers mean nothing next quarter.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Draft reply to podcast invite', 'Yes, but ask for the topic list a week out so the examples can be prepared.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Check CI flake', 'Intermittent failure in the REST grammar test.', 'trashed', 0
  UNION ALL SELECT 'Inbox', 'Duplicate capture to clean up', 'Same content as the optimizer trace note. Delete after merging the useful line.', 'trashed', 0

  -- Reading: papers, docs, and feature deep dives.
  UNION ALL SELECT 'Reading', 'Paper on time-ordered UUIDs', 'Read the draft on UUIDv7 and index fragmentation, then check the claims against an actual InnoDB page split count.', 'active', 0
  UNION ALL SELECT 'Reading', 'System-versioned tables deep dive', 'How MariaDB keeps history rows and how to query them with FOR SYSTEM_TIME.', 'active', 0
  UNION ALL SELECT 'Reading', 'MCP spec overview', 'Skim the protocol and focus on the tool call semantics.', 'active', 0
  UNION ALL SELECT 'Reading', 'Apache-2.0 and GPL-2.0 notes', 'Which license applies where: the server is GPL-2.0, the talk and skills repositories are Apache-2.0.', 'active', 0
  UNION ALL SELECT 'Reading', 'Window function framing clauses', 'ROWS versus RANGE, and why the default frame surprises people writing a running total.', 'active', 0
  UNION ALL SELECT 'Reading', 'JSON functions in 11.8', 'JSON_TABLE for flattening, JSON_VALUE for extraction, and a CHECK constraint with JSON_VALID.', 'active', 0
  UNION ALL SELECT 'Reading', 'Vector index tuning notes', 'M and ef_search trade recall against latency. Measure both on the demo dataset before quoting a number.', 'active', 1
  UNION ALL SELECT 'Reading', 'Query optimization checklist', 'Read EXPLAIN first, check the estimated versus actual rows, then look at the index before rewriting the query.', 'active', 0
  UNION ALL SELECT 'Reading', 'Parallel replication notes', 'Optimistic mode, the slave_parallel_threads setting, and what GTID gives you on failover.', 'active', 0
  UNION ALL SELECT 'Reading', 'InnoDB page compression', 'Notes on PAGE_COMPRESSED versus the older compressed row format.', 'archived', 0
  UNION ALL SELECT 'Reading', 'Old reading list', 'Superseded by the current quarter list.', 'trashed', 0

  -- Personal: the errands that make the seeded app look lived in.
  UNION ALL SELECT 'Personal', 'Grocery list', 'Coffee, oat milk, pasta, tomatoes.', 'active', 0
  UNION ALL SELECT 'Personal', 'Gym schedule', 'Monday, Wednesday and Friday mornings.', 'active', 0
  UNION ALL SELECT 'Personal', 'Book flight home', 'Book the return flight after the conference closes on Tuesday.', 'active', 0
  UNION ALL SELECT 'Personal', 'Bike tune-up', 'New chain and a brake bleed before the weather turns.', 'active', 0
  UNION ALL SELECT 'Personal', 'Ramen broth recipe', 'Twelve hours on the pork bones, skim every hour, salt at the end.', 'active', 0
  UNION ALL SELECT 'Personal', 'Birthday gift idea', 'The cast iron skillet she mentioned, plus the care instructions printed out.', 'active', 0
  UNION ALL SELECT 'Personal', 'Library books due', 'Returned. Keeping the list for the next visit.', 'archived', 0
  UNION ALL SELECT 'Personal', 'Old draft to discard', 'Superseded notes about the previous abstract version.', 'trashed', 0
) s
JOIN notes_app.notebook nb
  ON nb.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
 AND nb.name = s.nb
WHERE NOT EXISTS (
  SELECT 1 FROM notes_app.note n2
  WHERE n2.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
    AND n2.title = s.title
);

-- 5. Tag links.
INSERT INTO notes_app.note_tag (note_id, tag_id)
SELECT n.id, t.id
FROM (
  SELECT 'Optimizer trace notes' AS title, 'mariadb' AS tag
  UNION ALL SELECT 'Optimizer trace notes', 'blog'
  UNION ALL SELECT 'Community call agenda', 'talk'
  UNION ALL SELECT 'Community call agenda', 'community'
  UNION ALL SELECT 'ATO demo run-of-show', 'talk'
  UNION ALL SELECT 'ATO demo run-of-show', 'conference'
  UNION ALL SELECT 'Skill coverage gaps', 'mariadb'
  UNION ALL SELECT 'Skill coverage gaps', 'idea'
  UNION ALL SELECT 'Blog closing the agent loop', 'blog'
  UNION ALL SELECT 'Blog closing the agent loop', 'mariadb'
  UNION ALL SELECT 'Video sandbox in five minutes', 'blog'
  UNION ALL SELECT 'Video sandbox in five minutes', 'mariadb'
  UNION ALL SELECT 'Migrator demo notes', 'mariadb'
  UNION ALL SELECT 'Migrator demo notes', 'talk'
  UNION ALL SELECT 'Tutorial vector search in twenty lines', 'vector'
  UNION ALL SELECT 'Tutorial vector search in twenty lines', 'mariadb'
  UNION ALL SELECT 'Tutorial vector search in twenty lines', 'blog'
  UNION ALL SELECT 'Docs gap on system versioning', 'mariadb'
  UNION ALL SELECT 'Docs gap on system versioning', 'todo'
  UNION ALL SELECT 'Office hours question log', 'community'
  UNION ALL SELECT 'Office hours question log', 'idea'
  UNION ALL SELECT 'Newsletter draft on 11.8 LTS', 'blog'
  UNION ALL SELECT 'Newsletter draft on 11.8 LTS', 'mariadb'
  UNION ALL SELECT 'Sample data generator idea', 'idea'
  UNION ALL SELECT 'All Things Open logistics', 'talk'
  UNION ALL SELECT 'All Things Open logistics', 'conference'
  UNION ALL SELECT 'Talk abstract revisions', 'talk'
  UNION ALL SELECT 'CFP tracker', 'conference'
  UNION ALL SELECT 'CFP tracker', 'todo'
  UNION ALL SELECT 'Workshop lab environment', 'conference'
  UNION ALL SELECT 'Workshop lab environment', 'todo'
  UNION ALL SELECT 'Hallway track notes', 'conference'
  UNION ALL SELECT 'Hallway track notes', 'idea'
  UNION ALL SELECT 'Triage first-time contributor PRs', 'community'
  UNION ALL SELECT 'Triage first-time contributor PRs', 'todo'
  UNION ALL SELECT 'Good first issues list', 'community'
  UNION ALL SELECT 'Where support questions should live', 'community'
  UNION ALL SELECT 'Meetup speakers wanted', 'community'
  UNION ALL SELECT 'Meetup speakers wanted', 'todo'
  UNION ALL SELECT 'Contributor guide refresh', 'community'
  UNION ALL SELECT 'Contributor guide refresh', 'todo'
  UNION ALL SELECT 'Mentoring plan for docs contributions', 'community'
  UNION ALL SELECT 'Forum thread on connector timeouts', 'community'
  UNION ALL SELECT 'Forum thread on connector timeouts', 'mariadb'
  UNION ALL SELECT 'Community survey questions', 'community'
  UNION ALL SELECT 'Reply to forum thread', 'mariadb'
  UNION ALL SELECT 'Reply to forum thread', 'todo'
  UNION ALL SELECT 'Expense report', 'todo'
  UNION ALL SELECT 'Renew SSL cert', 'todo'
  UNION ALL SELECT 'Idea skill for window functions', 'idea'
  UNION ALL SELECT 'Idea skill for window functions', 'mariadb'
  UNION ALL SELECT 'Reset sandbox before rehearsal', 'todo'
  UNION ALL SELECT 'Reset sandbox before rehearsal', 'talk'
  UNION ALL SELECT 'Ask docs team about REST examples', 'todo'
  UNION ALL SELECT 'Follow up on the benchmark harness', 'benchmark'
  UNION ALL SELECT 'Follow up on the benchmark harness', 'todo'
  UNION ALL SELECT 'Draft reply to podcast invite', 'todo'
  UNION ALL SELECT 'Paper on time-ordered UUIDs', 'mariadb'
  UNION ALL SELECT 'Paper on time-ordered UUIDs', 'benchmark'
  UNION ALL SELECT 'System-versioned tables deep dive', 'mariadb'
  UNION ALL SELECT 'Apache-2.0 and GPL-2.0 notes', 'licensing'
  UNION ALL SELECT 'Window function framing clauses', 'mariadb'
  UNION ALL SELECT 'JSON functions in 11.8', 'mariadb'
  UNION ALL SELECT 'Vector index tuning notes', 'vector'
  UNION ALL SELECT 'Vector index tuning notes', 'benchmark'
  UNION ALL SELECT 'Query optimization checklist', 'mariadb'
  UNION ALL SELECT 'Query optimization checklist', 'benchmark'
  UNION ALL SELECT 'Parallel replication notes', 'replication'
  UNION ALL SELECT 'Parallel replication notes', 'mariadb'
  UNION ALL SELECT 'Percona Live follow-ups', 'replication'
  UNION ALL SELECT 'Percona Live follow-ups', 'conference'
  UNION ALL SELECT 'InnoDB page compression', 'mariadb'
  UNION ALL SELECT 'Grocery list', 'personal'
  UNION ALL SELECT 'Grocery list', 'todo'
  UNION ALL SELECT 'Book flight home', 'personal'
  UNION ALL SELECT 'Book flight home', 'todo'
  UNION ALL SELECT 'Bike tune-up', 'personal'
  UNION ALL SELECT 'Bike tune-up', 'todo'
  UNION ALL SELECT 'Ramen broth recipe', 'personal'
  UNION ALL SELECT 'Birthday gift idea', 'personal'
  UNION ALL SELECT 'Gym schedule', 'personal'
  UNION ALL SELECT 'Library books due', 'personal'
) m
JOIN notes_app.note n
  ON n.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
 AND n.title = m.title
JOIN notes_app.tag t
  ON t.account_id = (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com')
 AND t.name = m.tag
WHERE NOT EXISTS (
  SELECT 1 FROM notes_app.note_tag nt WHERE nt.note_id = n.id AND nt.tag_id = t.id
);
