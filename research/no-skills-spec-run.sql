-- no-skills-spec-run.sql
-- Schema for the notes_app database, built from talk/notes-app-spec.md alone.
-- Target: MariaDB 11.8. Load this first, then research/synthetic_data.sql.
-- Safe to run more than once.

CREATE DATABASE IF NOT EXISTS notes_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_uca1400_ai_ci;

USE notes_app;

-- One row per user. The spec has one account for now, but every other table
-- carries account_id so a second account needs no schema change.
CREATE TABLE IF NOT EXISTS account (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email        VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_account_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notebook (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id INT UNSIGNED NOT NULL,
  name       VARCHAR(100) NOT NULL,
  is_default BOOLEAN      NOT NULL DEFAULT FALSE,
  -- NULL for every non-default notebook, so the unique key below allows many
  -- of those but only one default notebook per account.
  default_for_account INT UNSIGNED AS (IF(is_default, account_id, NULL)) PERSISTENT,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notebook_account_name (account_id, name),
  UNIQUE KEY uq_notebook_one_default (default_for_account),
  -- Target for the composite foreign key on note, which keeps a note and its
  -- notebook in the same account.
  UNIQUE KEY uq_notebook_id_account (id, account_id),
  CONSTRAINT fk_notebook_account
    FOREIGN KEY (account_id) REFERENCES account (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tag (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id INT UNSIGNED NOT NULL,
  name       VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tag_account_name (account_id, name),
  CONSTRAINT fk_tag_account
    FOREIGN KEY (account_id) REFERENCES account (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS note (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  notebook_id INT UNSIGNED NOT NULL,
  account_id  INT UNSIGNED NOT NULL,
  title       VARCHAR(255) NOT NULL,
  body        MEDIUMTEXT   NOT NULL,  -- Markdown source
  status      ENUM('active', 'archived', 'trashed') NOT NULL DEFAULT 'active',
  is_pinned   BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  -- Serves "active notes in a notebook, pinned first, newest first".
  KEY ix_note_notebook_list (notebook_id, status, is_pinned, created_at),
  -- Serves "empty the trash" and account-wide status views.
  KEY ix_note_account_status (account_id, status),
  CONSTRAINT fk_note_notebook
    FOREIGN KEY (notebook_id, account_id) REFERENCES notebook (id, account_id),
  CONSTRAINT fk_note_account
    FOREIGN KEY (account_id) REFERENCES account (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS note_tag (
  note_id INT UNSIGNED NOT NULL,
  tag_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (note_id, tag_id),
  KEY ix_note_tag_tag (tag_id),
  -- Emptying the trash deletes notes; their tag links go with them.
  CONSTRAINT fk_note_tag_note
    FOREIGN KEY (note_id) REFERENCES note (id) ON DELETE CASCADE,
  CONSTRAINT fk_note_tag_tag
    FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE
) ENGINE=InnoDB;
