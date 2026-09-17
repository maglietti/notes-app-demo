-- synthetic_data.sql
-- Test data for the canonical notes_app schema (research/notes_app.sql).
-- Self-contained: creates the seeded account, six notebooks, twelve tags,
-- thirty-four notes across all statuses, and the tag links. Set-based and
-- guarded with NOT EXISTS, so it is safe to run more than once and can be loaded
-- against a bare schema. The account is referenced by email, so no UUID is
-- hard-coded and a fresh deploy works unchanged.

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
  UNION ALL SELECT 'Postgres Watch', 0
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
  UNION ALL SELECT 'postgres'
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

-- 4. Notes: 25 active (4 pinned), 5 archived, 4 trashed.
INSERT INTO notes_app.note (notebook_id, account_id, title, body, status, is_pinned)
SELECT nb.id,
       (SELECT id FROM notes_app.account WHERE email = 'michael.aglietti@mariadb.com'),
       s.title, s.body, s.status, s.pinned
FROM (
  SELECT 'DevRel' AS nb, 'Optimizer trace notes' AS title, 'The optimizer_trace output in MariaDB 11.8 explains join order choices. Compare it against the PostgreSQL planner output before publishing.' AS body, 'active' AS status, 1 AS pinned
  UNION ALL SELECT 'DevRel', 'Community call agenda', 'Vector search demo, the 11.8 upgrade path, and open questions from the forum.', 'active', 0
  UNION ALL SELECT 'DevRel', 'ATO demo run-of-show', 'Time the scaffolding run and the app capstone. Target twenty minutes with buffer for questions.', 'active', 1
  UNION ALL SELECT 'DevRel', 'Skill coverage gaps', 'List the MariaDB features the agent gets wrong without a skill. Vector search and system versioning are the clearest.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Blog closing the agent loop', 'Draft on how an MCP connection lets the agent run its own SQL and verify the results.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Video sandbox in five minutes', 'Screencast deploying a throwaway MariaDB and running DDL over MCP.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Migrator demo notes', 'MySQL to MariaDB migration over MCP. Show the resume-safe false success trap.', 'active', 0
  UNION ALL SELECT 'DevRel', 'Quarterly content plan', 'Three tutorials, one webinar, two conference talks. Prioritise the REST service walkthrough.', 'archived', 0
  UNION ALL SELECT 'DevRel', 'Webinar on schema management', 'Versioned schema with MSM and a walkthrough of the section model.', 'archived', 0
  UNION ALL SELECT 'Conferences', 'All Things Open logistics', 'Databases track, room 306A, Tuesday morning. Bring the HDMI adapter and the recorded fallback clip.', 'active', 1
  UNION ALL SELECT 'Conferences', 'Talk abstract revisions', 'Trim the two setup paragraphs. Lead with the confidently wrong framing.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Speaker bio update', 'Refresh the headshot and the one-line bio.', 'active', 0
  UNION ALL SELECT 'Conferences', 'Booth demo checklist', 'Laptop, USB stick with the sandbox, printed one-pagers, stickers.', 'archived', 0
  UNION ALL SELECT 'Conferences', 'Percona Live follow-ups', 'Reconnect with the replication folks about the failover benchmark.', 'trashed', 0
  UNION ALL SELECT 'Postgres Watch', 'Why Postgres wins mindshare', 'Decompose the claim into tooling, extensions and defaults. Separate the technical kernel from the framing.', 'active', 1
  UNION ALL SELECT 'Postgres Watch', 'pg_lake versus columnar engines', 'Compare the analytical story against MariaDB ColumnStore.', 'active', 0
  UNION ALL SELECT 'Postgres Watch', 'Vector search comparison', 'Benchmark pgvector against MariaDB vector indexes on recall and latency.', 'active', 0
  UNION ALL SELECT 'Postgres Watch', 'Planner output notes', 'Compare the PostgreSQL planner against the MariaDB optimizer trace on the same join order.', 'active', 0
  UNION ALL SELECT 'Postgres Watch', 'Replication comparison', 'Semisync and parallel replication notes for the failover talk.', 'trashed', 0
  UNION ALL SELECT 'Inbox', 'Conference travel checklist', 'Laptop charger, HDMI adapter, printed slides, USB stick with the demo sandbox.', 'archived', 0
  UNION ALL SELECT 'Inbox', 'Reply to forum thread', 'Answer the question about UUID_v7 index locality.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Expense report', 'Submit the conference travel expenses before month end.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Renew SSL cert', 'The staging demo certificate expires next month.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Idea skill for window functions', 'A skill covering OVER and the framing clauses would close a common gap.', 'active', 0
  UNION ALL SELECT 'Inbox', 'Check CI flake', 'Intermittent failure in the REST grammar test.', 'trashed', 0
  UNION ALL SELECT 'Reading', 'Paper on time-ordered UUIDs', 'Read the draft on UUIDv7 and index fragmentation.', 'active', 0
  UNION ALL SELECT 'Reading', 'System-versioned tables deep dive', 'How MariaDB keeps history rows and how to query them with FOR SYSTEM_TIME.', 'active', 0
  UNION ALL SELECT 'Reading', 'MCP spec overview', 'Skim the protocol and focus on the tool call semantics.', 'active', 0
  UNION ALL SELECT 'Reading', 'GPL-2.0 refresher', 'Licensing notes for the skills repository.', 'active', 0
  UNION ALL SELECT 'Reading', 'InnoDB page compression', 'Notes on PAGE_COMPRESSED versus the older row format compressed.', 'archived', 0
  UNION ALL SELECT 'Personal', 'Grocery list', 'Coffee, oat milk, pasta, tomatoes.', 'active', 0
  UNION ALL SELECT 'Personal', 'Gym schedule', 'Monday, Wednesday and Friday mornings.', 'active', 0
  UNION ALL SELECT 'Personal', 'Book flight home', 'Book the return flight after the conference closes on Tuesday.', 'active', 0
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
  UNION ALL SELECT 'Community call agenda', 'talk'
  UNION ALL SELECT 'Community call agenda', 'mariadb'
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
  UNION ALL SELECT 'All Things Open logistics', 'talk'
  UNION ALL SELECT 'All Things Open logistics', 'conference'
  UNION ALL SELECT 'Talk abstract revisions', 'talk'
  UNION ALL SELECT 'Why Postgres wins mindshare', 'postgres'
  UNION ALL SELECT 'Why Postgres wins mindshare', 'blog'
  UNION ALL SELECT 'pg_lake versus columnar engines', 'postgres'
  UNION ALL SELECT 'pg_lake versus columnar engines', 'benchmark'
  UNION ALL SELECT 'Vector search comparison', 'vector'
  UNION ALL SELECT 'Vector search comparison', 'postgres'
  UNION ALL SELECT 'Vector search comparison', 'benchmark'
  UNION ALL SELECT 'Planner output notes', 'postgres'
  UNION ALL SELECT 'Planner output notes', 'mariadb'
  UNION ALL SELECT 'Replication comparison', 'replication'
  UNION ALL SELECT 'Replication comparison', 'benchmark'
  UNION ALL SELECT 'Idea skill for window functions', 'idea'
  UNION ALL SELECT 'Idea skill for window functions', 'mariadb'
  UNION ALL SELECT 'Paper on time-ordered UUIDs', 'mariadb'
  UNION ALL SELECT 'System-versioned tables deep dive', 'mariadb'
  UNION ALL SELECT 'GPL-2.0 refresher', 'licensing'
  UNION ALL SELECT 'Conference travel checklist', 'todo'
  UNION ALL SELECT 'Reply to forum thread', 'mariadb'
  UNION ALL SELECT 'Reply to forum thread', 'todo'
  UNION ALL SELECT 'Expense report', 'todo'
  UNION ALL SELECT 'Grocery list', 'personal'
  UNION ALL SELECT 'Grocery list', 'todo'
  UNION ALL SELECT 'Book flight home', 'personal'
  UNION ALL SELECT 'Book flight home', 'todo'
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
