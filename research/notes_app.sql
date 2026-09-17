-- notes_app.sql
-- Canonical schema for the note-taking application, frozen from the schema the
-- coding agent designed on the demo sandbox. This is the deterministic target
-- the REST tier and the Textual client are built against. Pure DDL, no data;
-- load research/synthetic_data.sql for a populated database.
-- Target: MariaDB 11.8 LTS.
--
-- Every object is fully qualified and the tables are ordered parent-first, so
-- the file loads cleanly statement by statement (db.execute_sql_script gives
-- each statement its own session, so it cannot rely on USE).

CREATE SCHEMA IF NOT EXISTS notes_app
  CHARACTER SET = 'utf8mb4'
  COLLATE = 'uca1400_ai_ci'
  COMMENT = 'Note-taking application schema';

-- Note owners. System-versioned so account changes keep an audit trail.
CREATE OR REPLACE TABLE notes_app.account (
  id           uuid         NOT NULL DEFAULT uuid_v7() COMMENT 'Surrogate key exposed over REST',
  email        varchar(320) NOT NULL COMMENT 'Login identity, max length per RFC 3696',
  display_name varchar(120) NOT NULL,
  created_at   timestamp    NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  UNIQUE KEY uq_account_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Note owners' WITH SYSTEM VERSIONING;

-- Folders holding notes. A generated default_flag plus a unique key enforces
-- at most one default notebook per account.
CREATE OR REPLACE TABLE notes_app.notebook (
  id           uuid         NOT NULL DEFAULT uuid_v7(),
  account_id   uuid         NOT NULL,
  name         varchar(120) NOT NULL,
  is_default   tinyint(1)   NOT NULL DEFAULT 0 COMMENT 'Target notebook for a note created with no notebook chosen',
  created_at   timestamp    NOT NULL DEFAULT current_timestamp(),
  default_flag tinyint(1)   GENERATED ALWAYS AS (if(is_default,1,NULL)) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uq_notebook_account_name (account_id,name),
  UNIQUE KEY uq_notebook_one_default (account_id,default_flag),
  CONSTRAINT fk_notebook_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Folders holding notes' WITH SYSTEM VERSIONING;

-- Labels applied to notes, scoped to one account.
CREATE OR REPLACE TABLE notes_app.tag (
  id         uuid        NOT NULL DEFAULT uuid_v7(),
  account_id uuid        NOT NULL,
  name       varchar(64) NOT NULL,
  created_at timestamp   NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tag_account_name (account_id,name),
  CONSTRAINT fk_tag_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Labels applied to notes';

-- The notes themselves. status drives the trash and archive views; the FULLTEXT
-- index backs search over title and body.
CREATE OR REPLACE TABLE notes_app.note (
  id          uuid         NOT NULL DEFAULT uuid_v7(),
  notebook_id uuid         NOT NULL,
  account_id  uuid         NOT NULL COMMENT 'Denormalized owner, so a per-account query needs no join to notebook',
  title       varchar(255) NOT NULL DEFAULT '',
  body        longtext     NOT NULL DEFAULT '' COMMENT 'Markdown source rendered by the client',
  status      enum('active','archived','trashed') NOT NULL DEFAULT 'active',
  is_pinned   tinyint(1)   NOT NULL DEFAULT 0,
  created_at  timestamp    NOT NULL DEFAULT current_timestamp(),
  updated_at  timestamp    NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (id),
  KEY ix_note_notebook_updated (notebook_id,status,is_pinned DESC,updated_at DESC),
  KEY ix_note_account_status (account_id,status,updated_at DESC),
  FULLTEXT KEY ft_note_title_body (title,body),
  CONSTRAINT fk_note_account FOREIGN KEY (account_id)
    REFERENCES notes_app.account (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_note_notebook FOREIGN KEY (notebook_id)
    REFERENCES notes_app.notebook (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Notes, with Markdown bodies and full-text search';

-- Many-to-many join between notes and tags.
CREATE OR REPLACE TABLE notes_app.note_tag (
  note_id  uuid      NOT NULL,
  tag_id   uuid      NOT NULL,
  added_at timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (note_id,tag_id),
  KEY ix_note_tag_tag (tag_id) COMMENT 'Serves the reverse lookup: every note carrying one tag',
  CONSTRAINT fk_note_tag_note FOREIGN KEY (note_id)
    REFERENCES notes_app.note (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_note_tag_tag FOREIGN KEY (tag_id)
    REFERENCES notes_app.tag (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Note-to-tag assignments';

-- File attachments stored outside the database; the row holds the pointer.
CREATE OR REPLACE TABLE notes_app.attachment (
  id          uuid         NOT NULL DEFAULT uuid_v7(),
  note_id     uuid         NOT NULL,
  file_name   varchar(255) NOT NULL,
  mime_type   varchar(127) NOT NULL DEFAULT 'application/octet-stream',
  size_bytes  bigint(20) unsigned NOT NULL DEFAULT 0,
  storage_key varchar(512) NOT NULL COMMENT 'Object-storage path, for example an S3 key',
  created_at  timestamp    NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (id),
  KEY ix_attachment_note (note_id),
  CONSTRAINT fk_attachment_note FOREIGN KEY (note_id)
    REFERENCES notes_app.note (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci
  COMMENT='Object-storage pointers for note attachments';

-- Active notes with their notebook, owner and a joined tag list, for the list view.
CREATE OR REPLACE VIEW notes_app.v_active_note AS
SELECT n.id            AS note_id,
       n.title         AS title,
       n.body          AS body,
       n.is_pinned     AS is_pinned,
       n.created_at    AS created_at,
       n.updated_at    AS updated_at,
       nb.id           AS notebook_id,
       nb.name         AS notebook_name,
       a.id            AS account_id,
       a.email         AS account_email,
       GROUP_CONCAT(DISTINCT t.name ORDER BY t.name SEPARATOR ',') AS tags
FROM notes_app.note n
JOIN notes_app.notebook nb ON nb.id = n.notebook_id
JOIN notes_app.account a   ON a.id = n.account_id
LEFT JOIN notes_app.note_tag nt ON nt.note_id = n.id
LEFT JOIN notes_app.tag t       ON t.id = nt.tag_id
WHERE n.status = 'active'
GROUP BY n.id;
