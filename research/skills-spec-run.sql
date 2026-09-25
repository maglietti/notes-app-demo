-- skills-spec-run.sql
-- Schema for the Notes App (talk/notes-app-spec.md), MariaDB 11.8.
-- Load this file first, then research/synthetic_data.sql.

-- Save current session settings and disable checks for faster, safer bulk import
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES';
SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0;

-- Preserve current charset/collation settings, then switch to utf8mb4 for the import
SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT, @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS;
SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION;
SET NAMES utf8mb4;

-- Schema that holds all Notes App objects.
CREATE SCHEMA IF NOT EXISTS notes_app
  CHARACTER SET = 'utf8mb4'
  COLLATE = 'utf8mb4_uca1400_ai_ci'
  COMMENT = 'Keyboard-first terminal notebook';

-- Account: the owner of notebooks, tags, and notes. One row for now.
CREATE OR REPLACE TABLE notes_app.account (
  id           UUID         NOT NULL DEFAULT UUID_v7(),
  email        VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_account_email (email)
) ENGINE = InnoDB COMMENT = 'Account that owns all notebooks, tags, and notes';

-- Notebook: a named group of notes. Exactly one notebook per account is the default.
CREATE OR REPLACE TABLE notes_app.notebook (
  id         UUID         NOT NULL DEFAULT UUID_v7(),
  account_id UUID         NOT NULL,
  name       VARCHAR(100) NOT NULL,
  is_default BOOLEAN      NOT NULL DEFAULT FALSE,
  -- Holds account_id only on the default row, so the unique key allows one default per account.
  default_for_account UUID AS (IF(is_default, account_id, NULL)) PERSISTENT,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notebook_account_name (account_id, name),
  UNIQUE KEY uq_notebook_one_default (default_for_account),
  -- Target of the composite foreign key on note, which keeps a note in its owner's notebook.
  KEY ix_notebook_id_account (id, account_id),
  CONSTRAINT fk_notebook_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Named groups of notes; one default per account';

-- Tag: a per-account label that can be attached to many notes.
CREATE OR REPLACE TABLE notes_app.tag (
  id         UUID        NOT NULL DEFAULT UUID_v7(),
  account_id UUID        NOT NULL,
  name       VARCHAR(50) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tag_account_name (account_id, name),
  CONSTRAINT fk_tag_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Per-account labels for notes';

-- Note: a Markdown document in a notebook, with a lifecycle status and a pinned flag.
CREATE OR REPLACE TABLE notes_app.note (
  id          UUID         NOT NULL DEFAULT UUID_v7(),
  notebook_id UUID         NOT NULL,
  account_id  UUID         NOT NULL,
  title       VARCHAR(255) NOT NULL,
  body        MEDIUMTEXT   NOT NULL DEFAULT '',
  status      ENUM('active', 'archived', 'trashed') NOT NULL DEFAULT 'active',
  is_pinned   BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  -- Notebook list: active notes in one notebook, pinned first, newest first. Also serves note counts.
  KEY ix_note_notebook_list (notebook_id, status, is_pinned DESC, updated_at DESC),
  -- Account-wide views by status, such as the trash and the archive.
  KEY ix_note_account_status (account_id, status, updated_at DESC),
  CONSTRAINT fk_note_notebook FOREIGN KEY (notebook_id, account_id)
    REFERENCES notes_app.notebook (id, account_id) ON DELETE RESTRICT,
  CONSTRAINT fk_note_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Markdown notes with active/archived/trashed lifecycle';

-- Note_tag: links notes to tags (many to many). Emptying the trash removes the links.
CREATE OR REPLACE TABLE notes_app.note_tag (
  note_id UUID NOT NULL,
  tag_id  UUID NOT NULL,
  PRIMARY KEY (note_id, tag_id),
  -- Reverse lookup for the planned filter-by-tag feature.
  KEY ix_note_tag_tag (tag_id, note_id),
  CONSTRAINT fk_note_tag_note FOREIGN KEY (note_id)
    REFERENCES notes_app.note (id) ON DELETE CASCADE,
  CONSTRAINT fk_note_tag_tag FOREIGN KEY (tag_id)
    REFERENCES notes_app.tag (id) ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Tags attached to notes';

-- Restore original settings
SET SQL_MODE=@OLD_SQL_MODE, FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS, NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY;
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT, CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS;
SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION;
