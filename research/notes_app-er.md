# notes_app schema — ER diagram

MariaDB `notes_app` schema (note-taking application, targets MariaDB 11.8+). 6 tables, 1 view, 0 stored routines.

- **Solid lines** = foreign-key relationships between tables.
- **Dashed lines** = view dependencies (`reads`).
- View entities are tagged in their first row (`VIEW`) since Mermaid `erDiagram` has no native node type for them.
- `account` and `notebook` are `WITH SYSTEM VERSIONING` (tagged on their PK row). Every FK uses `ON DELETE CASCADE`.

```mermaid
erDiagram
    %% ---------- Foreign-key relationships (base tables) ----------
    account ||--o{ notebook : "owns"
    account ||--o{ note : "owns"
    account ||--o{ tag : "owns"
    notebook ||--o{ note : "groups"
    note ||--o{ note_tag : "tagged as"
    tag ||--o{ note_tag : "applied as"
    note ||--o{ attachment : "has"

    %% ---------- Base tables ----------
    account {
        uuid account_id PK "system-versioned"
        varchar email "UNIQUE"
        varchar display_name
        varchar password_hash
    }
    notebook {
        uuid notebook_id PK "system-versioned"
        uuid account_id FK
        varchar name "UNIQUE w/ account_id"
        boolean is_default
    }
    note {
        uuid note_id PK
        uuid notebook_id FK
        uuid account_id FK
        varchar title
        longtext body "FULLTEXT(title,body)"
        enum status
        boolean is_pinned
        datetime created_at
        datetime updated_at
    }
    tag {
        uuid tag_id PK
        uuid account_id FK
        varchar name "UNIQUE w/ account_id"
    }
    note_tag {
        uuid note_id PK,FK
        uuid tag_id PK,FK
    }
    attachment {
        uuid attachment_id PK
        uuid note_id FK
        varchar file_name
        varchar mime_type
        bigint byte_size
        varchar storage_key
        datetime uploaded_at
    }

    %% ---------- Views ----------
    v_active_note {
        VIEW _
        col note_id
        col title
        col notebook_name
        col owner
        col is_pinned
        col updated_at
        col tags
    }

    %% ---------- View dependencies (reads) ----------
    note ||..o{ v_active_note : reads
    notebook ||..o{ v_active_note : reads
    account ||..o{ v_active_note : reads
    note_tag ||..o{ v_active_note : reads
    tag ||..o{ v_active_note : reads
```
