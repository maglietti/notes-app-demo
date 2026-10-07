# Notes App

## Why

I keep my notes as Markdown files in one folder, one file per day, named for the date. After a year there are hundreds of them. When `ls` scrolls too far, I move a quarter's files into an archive folder and have an LLM write a summary of them.

Finding things is the problem. `rg` and `fzf` find exact words, but I rarely remember the words. I remember that a note was good, and roughly what it was about. Asking a coding agent to dig through the files works, but it burns tokens I would rather spend on code.

## What I want

A terminal app that finds my notes by meaning. I type what a note was about, and the app shows the notes that match, best first, even when they use different words.

## Stack

- MariaDB 11.8
- Python 3.11 or newer, managed with uv, with Textual for the terminal UI
- Embeddings come from Ollama on my laptop, with `qwen3-embedding:0.6b`
- Everything runs on my laptop with no API keys. My notes do not leave my machine.

## My notes

- `notes/` holds my current notes. `notes/archive/<quarter>/` holds older notes and a quarterly summary, such as `4Q2025.md`.
- Each daily note has a task list and a section for each topic. Some sections have `#tags`.

## Must have

1. Import every note, current and archived
2. Pick up new and changed notes when I run the import again
3. Search by meaning, and show the best matches with their title, date, and folder
4. Search for exact words too
5. Open a note and render its Markdown
6. Open the note in `nvim` if I hit enter. I keep writing in my editor; the app only finds things.
7. Search from the command line too, so my coding agent can ask the index instead of reading every file

## How it runs

- `uv run notes-app import` imports my notes
- `uv run notes-app` opens the app
- `uv run notes-app search "what the note was about"` prints the best matches
- Connection settings come from a `.env` file

## Done when

- Every note file is in the database
- Searching for "testing a migration without a copy of production" shows my April 14, 2026 note in the top three
