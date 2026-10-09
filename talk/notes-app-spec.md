# Notes App

## Why

I keep my notes as Markdown files in a folder, one file per day, named with a date stamp. After a year there are hundreds of files. So, each quarter, I summarize the work and move that quarter's files into an archive folder.

Finding things is a problem. `rg` and `fzf` find exact words, but I rarely remember the words. I remember that a note was good, that it has the facts I need, and roughly what it was about. Asking a coding agent to dig through the files works, but it burns tokens I would rather spend on code.

## What I want

A terminal app that finds my notes semantically. I type what a note was about, and the app shows the notes that match, in a ranked list.

## Stack

- MariaDB 11.8
- Python 3.11 or newer, managed with uv, with Textual for the terminal UI
- Embeddings come from Ollama on my laptop, using `qwen3-embedding:0.6b`
- Everything runs on my laptop with no API keys. I don't want my notes to leave my laptop.

## My notes

- `notes/` holds my current notes. `notes/archive/<quarter>/` holds older notes and a quarterly summary, like `4Q2025.md`.
- Each daily note has a task list and a section for each topic. Some sections have `#tags`.

## Must have

1. Import every note, current and archived
2. Pick up new and changed notes when I run the import again
3. Search by meaning, and show the best matches with their title, date, and folder
4. Search for exact words too
5. Open a note and render its Markdown
6. Open the note in `nvim` if I hit enter
7. Search from the command line

## Nice to have

1. `cron` automation
2. MCP server access
3. Standardized logging set through debug levels

## How it runs

- `uv run notes-app import` imports my notes
- `uv run notes-app` opens the TUI app
- `uv run notes-app search "what the note was about"` prints the best matches
- Secrets are stored in an `.env` file

## Done when

- Every note file is in the database
- Searching for "testing a migration without a copy of production" shows my April 14, 2026 note in the top three
