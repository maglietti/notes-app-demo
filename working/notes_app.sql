-- notes_app schema for MariaDB 11.8 LTS, generated from docs/notes_app-prd.md section 4.
-- Pure DDL, fully qualified, no session state, so db.execute_sql_script can load it
-- statement by statement. Rerunnable: children are dropped first so each
-- CREATE OR REPLACE TABLE is never blocked by a foreign key from an older copy.

CREATE DATABASE IF NOT EXISTS notes_app
  CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci;

DROP VIEW IF EXISTS notes_app.v_active_note;
DROP TABLE IF EXISTS notes_app.attachment;
DROP TABLE IF EXISTS notes_app.note_tag;
DROP TABLE IF EXISTS notes_app.note;
DROP TABLE IF EXISTS notes_app.tag;
DROP TABLE IF EXISTS notes_app.notebook;
DROP TABLE IF EXISTS notes_app.account;

-- One seeded owner. Row history lives in the table itself.
CREATE OR REPLACE TABLE notes_app.account (
  id           UUID         NOT NULL DEFAULT uuid_v7(),
  email        VARCHAR(320) NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_account_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  WITH SYSTEM VERSIONING;

-- Folders. default_flag is 1 for the default notebook and NULL otherwise, so the
-- unique key allows at most one default per account.
CREATE OR REPLACE TABLE notes_app.notebook (
  id           UUID         NOT NULL DEFAULT uuid_v7(),
  account_id   UUID         NOT NULL,
  name         VARCHAR(120) NOT NULL,
  is_default   BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  default_flag TINYINT GENERATED ALWAYS AS (IF(is_default, 1, NULL)) PERSISTENT,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notebook_account_name (account_id, name),
  UNIQUE KEY uq_notebook_one_default (account_id, default_flag),
  CONSTRAINT fk_notebook_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  WITH SYSTEM VERSIONING;

CREATE OR REPLACE TABLE notes_app.tag (
  id         UUID        NOT NULL DEFAULT uuid_v7(),
  account_id UUID        NOT NULL,
  name       VARCHAR(64) NOT NULL,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tag_account_name (account_id, name),
  CONSTRAINT fk_tag_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Notes. No row history (PRD section 10). Descending index parts match the
-- pinned-first, newest-first list order.
CREATE OR REPLACE TABLE notes_app.note (
  id          UUID         NOT NULL DEFAULT uuid_v7(),
  notebook_id UUID         NOT NULL,
  account_id  UUID         NOT NULL,
  title       VARCHAR(255) NOT NULL DEFAULT '',
  body        LONGTEXT     NOT NULL DEFAULT '',
  status      ENUM('active', 'archived', 'trashed') NOT NULL DEFAULT 'active',
  is_pinned   BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_note_notebook_updated (notebook_id, status, is_pinned DESC, updated_at DESC),
  KEY ix_note_account_status (account_id, status, updated_at DESC),
  FULLTEXT KEY ft_note_title_body (title, body),
  CONSTRAINT fk_note_notebook FOREIGN KEY (notebook_id)
    REFERENCES notes_app.notebook (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_note_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

CREATE OR REPLACE TABLE notes_app.note_tag (
  note_id  UUID     NOT NULL,
  tag_id   UUID     NOT NULL,
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (note_id, tag_id),
  KEY ix_note_tag_tag (tag_id),
  CONSTRAINT fk_note_tag_note FOREIGN KEY (note_id)
    REFERENCES notes_app.note (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_note_tag_tag FOREIGN KEY (tag_id)
    REFERENCES notes_app.tag (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Object-storage pointers, read model only in this app.
CREATE OR REPLACE TABLE notes_app.attachment (
  id          UUID            NOT NULL DEFAULT uuid_v7(),
  note_id     UUID            NOT NULL,
  file_name   VARCHAR(255)    NOT NULL,
  mime_type   VARCHAR(127)    NOT NULL DEFAULT 'application/octet-stream',
  size_bytes  BIGINT UNSIGNED NOT NULL DEFAULT 0,
  storage_key VARCHAR(512)    NOT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_attachment_note (note_id),
  CONSTRAINT fk_attachment_note FOREIGN KEY (note_id)
    REFERENCES notes_app.note (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Default list view: active notes, one row per note, untagged notes kept.
CREATE OR REPLACE VIEW notes_app.v_active_note AS
SELECT
  n.id           AS note_id,
  n.title        AS title,
  n.body         AS body,
  n.is_pinned    AS is_pinned,
  n.created_at   AS created_at,
  n.updated_at   AS updated_at,
  nb.id          AS notebook_id,
  nb.name        AS notebook_name,
  a.id           AS account_id,
  a.email        AS account_email,
  GROUP_CONCAT(DISTINCT t.name ORDER BY t.name SEPARATOR ',') AS tags
FROM notes_app.note n
JOIN notes_app.notebook nb ON nb.id = n.notebook_id
JOIN notes_app.account a ON a.id = n.account_id
LEFT JOIN notes_app.note_tag nt ON nt.note_id = n.id
LEFT JOIN notes_app.tag t ON t.id = nt.tag_id
WHERE n.status = 'active'
GROUP BY n.id, n.title, n.body, n.is_pinned, n.created_at, n.updated_at,
         nb.id, nb.name, a.id, a.email;
