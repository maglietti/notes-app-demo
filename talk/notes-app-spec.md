# Notes App

A keyboard-first notebook that lives in my terminal. Three panes: my notebooks,
the notes in the one I pick, and the note I am reading, rendered from Markdown.

## Stack

- MariaDB 11.8
- Python 3.11 or newer, with Textual for the terminal UI
- The app talks to MariaDB directly with MariaDB Connector/Python

## Data

It is just me for now, one account. The sample data in research/synthetic_data.sql
must load without changes, and it expects these tables:

- account: email and display name
- notebook: belongs to an account, has a name, and one notebook is my default
- tag: belongs to an account, has a name
- note: lives in a notebook and belongs to an account. Has a title, a Markdown body,
  a status (active, archived, or trashed), a pinned flag, and when it was created
  and last updated
- note_tag: which tags are on which notes

## What the app does

Must have:

1. List my notebooks, with a note count for each, and mark the default
2. List the active notes in a notebook, pinned first, newest first
3. Open a note and render its Markdown
4. Create a note, and edit its title and body
5. Edit a selected note if I hit enter
6. Pin and unpin a note
7. Archive a note, and bring it back
8. Trash a note, restore it, and empty the trash
9. Show a status line with where the app is connected

Later: full-text search, and filtering by tag.

## How it runs

- `./bin/notes-app` from the repository root starts the app
- Connection settings come from a .env file

## Done when

- The schema loads, and the sample data loads into it: 6 notebooks, 12 tags, 61 notes
- bin/notes-app opens and shows my notebooks and their notes, pinned ones on top
