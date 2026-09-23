-- REST Service for notes_app, from docs/notes_app-prd.md section 5.
-- Run with db.execute_sql one statement at a time: the REST grammar keeps
-- session state. Every object still names its service and schema explicitly,
-- so no statement depends on an earlier USE.

CONFIGURE REST METADATA;

CREATE OR REPLACE REST SERVICE /notesApp
    COMMENT "Notes App API over the notes_app schema (local demo)";

CREATE OR REPLACE REST SCHEMA /notes ON SERVICE /notesApp
    FROM `notes_app`
    COMMENT "The notes_app schema";

-- Notes, with their tag names flattened in for display. Writes change only the
-- note's own columns, so the nested join and tag objects are read-only.
CREATE OR REPLACE REST VIEW /note
ON SERVICE /notesApp SCHEMA /notes
AS `notes_app`.`note` @INSERT @UPDATE @DELETE {
    id: id @KEY,
    notebookId: notebook_id,
    accountId: account_id,
    title: title @SORTABLE,
    body: body,
    status: status,
    isPinned: is_pinned,
    createdAt: created_at @SORTABLE,
    updatedAt: updated_at @SORTABLE,
    noteTag: notes_app.note_tag @UNNEST @NOINSERT @NOUPDATE @NODELETE {
        tag: notes_app.tag @UNNEST @NOINSERT @NOUPDATE @NODELETE {
            name: name
        }
    }
}
AUTHENTICATION NOT REQUIRED
COMMENT "Notes: list, read, create, update and delete; tags read-only";

-- Notebooks for the sidebar, with create and rename.
CREATE OR REPLACE REST VIEW /notebook
ON SERVICE /notesApp SCHEMA /notes
AS `notes_app`.`notebook` @INSERT @UPDATE {
    id: id @KEY,
    accountId: account_id,
    name: name @SORTABLE,
    isDefault: is_default,
    createdAt: created_at
}
AUTHENTICATION NOT REQUIRED
COMMENT "Notebooks: list, create and rename";

-- Tags for the tag filter, read-only.
CREATE OR REPLACE REST VIEW /tag
ON SERVICE /notesApp SCHEMA /notes
AS `notes_app`.`tag` {
    id: id @KEY,
    accountId: account_id,
    name: name @SORTABLE,
    createdAt: created_at
}
AUTHENTICATION NOT REQUIRED
COMMENT "Tags: read-only list for the tag filter";

ALTER REST SERVICE /notesApp PUBLISHED;
