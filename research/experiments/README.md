# Experiments

Controlled runs that test what the talk claims. Each entry names the setup, the input, and the result, so a claim on a slide can point at its evidence. All runs used Claude Opus 5.5 in Claude Code 2.1.282 on 2026-09-25, and the prompts said "Do not run it" so no run could test its own SQL.

| # | Question | Setup | Output | Transcript |
| - | -------- | ----- | ------ | ---------- |
| 1 | Does the LLM need skills to write MariaDB from the earlier PRD? | Plugin disabled, repository checkout, PRD section 4 as input | [`no-skills-run.sql`](../no-skills-run.sql) | [`exp1-no-skills-prd.txt`](exp1-no-skills-prd.txt) |
| 2 | What does the LLM write from the minimal spec with no skills? | Plugin disabled, repository checkout, `talk/notes-app-spec.md` as input | [`no-skills-spec-run.sql`](../no-skills-spec-run.sql) | [`exp2-no-skills-spec.txt`](exp2-no-skills-spec.txt) |
| 3 | What changes when the skills are loaded? | Plugin enabled, isolated directory holding only the spec, the fixture, and the launcher, with no git history | [`skills-spec-run.sql`](../skills-spec-run.sql) | [`exp3-skills-spec.txt`](exp3-skills-spec.txt) |
| 4 | Do the DDL files from runs 2 and 3 work through the MCP tools? | Scratch sandbox, MariaDB 11.8.9 on port 3311; each file loaded with `db.execute_sql_script`, then the fixture | Results below | This log |

## Results

1. **The earlier PRD did the work.** With no skills, the LLM wrote current MariaDB from PRD section 4: `UUID` keys with `UUID_v7()`, `uca1400`, system versioning, a generated column, and descending indexes. The PRD described the answer, so it moved to `research/` and the minimal spec replaced it.
2. **With no skills, the minimal spec gave correct, generic SQL.** `INT UNSIGNED AUTO_INCREMENT` keys, `CREATE TABLE IF NOT EXISTS` after `USE notes_app;`, and ascending indexes, plus `uca1400` and a `PERSISTENT` generated column. No MySQL-only constructs such as `UUID_TO_BIN` or plain `utf8`.
3. **With skills, the same spec gave MariaDB.** The agent loaded `mariadb-schema-create-script`, `mariadb-create-table`, `mariadb-create-database`, and `mariadb-create-index`, then wrote `UUID` keys with `UUID_v7()`, `CREATE OR REPLACE TABLE`, fully qualified names, descending index columns that match the list order, and a `SET @OLD_... / restore` block around the script.
4. **Both files work, and both take the fixture.** Each loaded with no errors, and the fixture then gave 1 account, 6 notebooks, 12 tags, 61 notes (48 active, 6 pinned, 7 archived, 6 trashed), and 82 tag links. The skills schema generated UUIDv7 ids. Two suspected failures did not happen:
   - `USE notes_app;` carried across the statements of the script, so `db.execute_sql_script` runs a whole script on one session, as its tool description says. The repository's earlier note that it gives each statement a fresh session is wrong for plain SQL.
   - The skills file's `SET` block restored every session setting. Rerunning the file on a loaded schema also worked: `FOREIGN_KEY_CHECKS=0` let `CREATE OR REPLACE` replace referenced parent tables, and the rerun emptied the tables, as the agent had warned.
   - Side note: `sandbox.delete` reported success but left a 49 MB `myboilerplate-mariadb-11.8.9-MariaDB` directory in the sandbox directory, which was removed by hand.

## What the talk can claim

- Without skills, a frontier LLM writes correct, portable SQL from a developer's spec. With skills, the agent writes MariaDB: native time-ordered UUID keys, atomic `CREATE OR REPLACE`, and indexes shaped to the queries.
- The talk no longer claims that the LLM falls back on MySQL habits. No run showed them. Smaller LLMs are untested.
- The REST prompt's reason for one statement per call ("`db.execute_sql_script` gives each statement a fresh session") is contradicted for plain SQL. Whether the REST grammar fails through a script for another reason is untested.
