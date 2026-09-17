-- notes_app.sql
-- Schema for a note-taking application: accounts, notebooks, notes, tags.
-- Target: MariaDB 11.8 LTS

-- Save current session settings and disable checks for faster, safer bulk import
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES';
SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0;

-- Preserve current charset/collation settings, then switch to utf8mb4 for the import
SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT, @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS;
SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION;
SET NAMES utf8mb4;

-- The application schema. utf8mb4 so note bodies accept the full Unicode range.
CREATE SCHEMA IF NOT EXISTS notes_app
  CHARACTER SET = 'utf8mb4'
  COLLATE = 'uca1400_ai_ci'
  COMMENT = 'Note-taking application schema';

USE notes_app;

-- People who own notebooks and notes. UUID primary key so the id can be
-- exposed to clients without leaking row counts or creation order.
CREATE OR REPLACE TABLE account (
  account_id    UUID         NOT NULL DEFAULT UUID_v7(),
  email         VARCHAR(320) NOT NULL,
  display_name  VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  PRIMARY KEY (account_id),
  UNIQUE INDEX uq_account_email (email)
) ENGINE = InnoDB
  COMMENT = 'Application user accounts'
  WITH SYSTEM VERSIONING;

-- A folder grouping notes for one account. Notebook names are unique per owner.
CREATE OR REPLACE TABLE notebook (
  notebook_id UUID         NOT NULL DEFAULT UUID_v7(),
  account_id  UUID         NOT NULL,
  name        VARCHAR(120) NOT NULL,
  is_default  BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (notebook_id),
  UNIQUE INDEX uq_notebook_account_name (account_id, name),
  CONSTRAINT fk_notebook_account FOREIGN KEY (account_id)
    REFERENCES account (account_id) ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Notebooks grouping an account''s notes'
  WITH SYSTEM VERSIONING;

-- The notes themselves. body is Markdown text supplied by the client.
-- status drives the trash and archive views in the application.
CREATE OR REPLACE TABLE note (
  note_id     UUID         NOT NULL DEFAULT UUID_v7(),
  notebook_id UUID         NOT NULL,
  account_id  UUID         NOT NULL,
  title       VARCHAR(200) NOT NULL,
  body        LONGTEXT     NULL,
  status      ENUM('active','archived','trashed') NOT NULL DEFAULT 'active',
  is_pinned   BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                                    ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (note_id),
  -- Covers the default list view: one notebook, newest note first.
  INDEX ix_note_notebook_updated (notebook_id, updated_at DESC),
  -- Covers the per-account views that filter on trash or archive state.
  INDEX ix_note_account_status (account_id, status, updated_at DESC),
  FULLTEXT INDEX ft_note_title_body (title, body),
  CONSTRAINT fk_note_notebook FOREIGN KEY (notebook_id)
    REFERENCES notebook (notebook_id) ON DELETE CASCADE,
  CONSTRAINT fk_note_account FOREIGN KEY (account_id)
    REFERENCES account (account_id) ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Notes, one row per note revision-in-place';

-- Free-form labels, scoped to one account so two users can reuse a name.
CREATE OR REPLACE TABLE tag (
  tag_id     UUID        NOT NULL DEFAULT UUID_v7(),
  account_id UUID        NOT NULL,
  name       VARCHAR(60) NOT NULL,
  PRIMARY KEY (tag_id),
  UNIQUE INDEX uq_tag_account_name (account_id, name),
  CONSTRAINT fk_tag_account FOREIGN KEY (account_id)
    REFERENCES account (account_id) ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Tags an account can attach to its notes';

-- Many-to-many join between notes and tags. The composite primary key
-- prevents the same tag being attached to a note twice.
CREATE OR REPLACE TABLE note_tag (
  note_id UUID NOT NULL,
  tag_id  UUID NOT NULL,
  PRIMARY KEY (note_id, tag_id),
  -- Reverse lookup: every note carrying a given tag.
  INDEX ix_note_tag_tag (tag_id),
  CONSTRAINT fk_note_tag_note FOREIGN KEY (note_id)
    REFERENCES note (note_id) ON DELETE CASCADE,
  CONSTRAINT fk_note_tag_tag FOREIGN KEY (tag_id)
    REFERENCES tag (tag_id) ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Note-to-tag assignments';

-- File attachments stored outside the database; the row holds the pointer.
CREATE OR REPLACE TABLE attachment (
  attachment_id UUID         NOT NULL DEFAULT UUID_v7(),
  note_id       UUID         NOT NULL,
  file_name     VARCHAR(255) NOT NULL,
  mime_type     VARCHAR(127) NOT NULL,
  byte_size     BIGINT UNSIGNED NOT NULL,
  storage_key   VARCHAR(512) NOT NULL,
  uploaded_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (attachment_id),
  INDEX ix_attachment_note (note_id),
  CONSTRAINT fk_attachment_note FOREIGN KEY (note_id)
    REFERENCES note (note_id) ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Files attached to a note, held in object storage';

-- Active notes with their notebook, owner and tag list, for the list view.
CREATE OR REPLACE VIEW v_active_note AS
SELECT n.note_id,
       n.title,
       nb.name AS notebook_name,
       a.display_name AS owner,
       n.is_pinned,
       n.updated_at,
       GROUP_CONCAT(t.name ORDER BY t.name SEPARATOR ', ') AS tags
FROM note n
JOIN notebook nb ON nb.notebook_id = n.notebook_id
JOIN account a ON a.account_id = n.account_id
LEFT JOIN note_tag nt ON nt.note_id = n.note_id
LEFT JOIN tag t ON t.tag_id = nt.tag_id
WHERE n.status = 'active'
GROUP BY n.note_id, n.title, nb.name, a.display_name, n.is_pinned, n.updated_at;

-- Sample data: one account with two notebooks, three notes and two tags.
SET @account_id = UUID_v7();
SET @notebook_inbox = UUID_v7();
SET @notebook_devrel = UUID_v7();
SET @note_optimizer = UUID_v7();
SET @note_agenda = UUID_v7();
SET @note_groceries = UUID_v7();
SET @tag_mariadb = UUID_v7();
SET @tag_todo = UUID_v7();

INSERT INTO account (account_id, email, display_name, password_hash) VALUES
  (@account_id, 'michael.aglietti@mariadb.com', 'Michael Aglietti',
   '$2y$10$Nn6t0hG0xQ0S1kQnQ0aVSeJ6y0m2B8Qk0sO3l2mQ1yV8pO9uZ0dWu');

INSERT INTO notebook (notebook_id, account_id, name, is_default) VALUES
  (@notebook_inbox,  @account_id, 'Inbox', TRUE),
  (@notebook_devrel, @account_id, 'DevRel', FALSE);

INSERT INTO note (note_id, notebook_id, account_id, title, body, status, is_pinned) VALUES
  (@note_optimizer, @notebook_devrel, @account_id,
   'Optimizer trace notes',
   '`optimizer_trace` in MariaDB 11.8 explains join order choices. Compare against the PostgreSQL planner output before publishing.',
   'active', TRUE),
  (@note_agenda, @notebook_devrel, @account_id,
   'Community call agenda',
   'Vector search demo, 11.8 upgrade path, open questions from the forum.',
   'active', FALSE),
  (@note_groceries, @notebook_inbox, @account_id,
   'Conference travel checklist',
   'Laptop charger, HDMI adapter, printed slides, USB stick with the demo sandbox.',
   'archived', FALSE);

INSERT INTO tag (tag_id, account_id, name) VALUES
  (@tag_mariadb, @account_id, 'mariadb'),
  (@tag_todo,    @account_id, 'todo');

INSERT INTO note_tag (note_id, tag_id) VALUES
  (@note_optimizer, @tag_mariadb),
  (@note_agenda,    @tag_mariadb),
  (@note_agenda,    @tag_todo);

-- Restore original settings
SET SQL_MODE=@OLD_SQL_MODE, FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS, NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY;
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT, CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS;
SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION;
