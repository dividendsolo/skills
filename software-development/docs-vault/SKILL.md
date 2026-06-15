---
name: docs-vault
description: Use when you need durable, repo-specific context — architecture, domain model, how a flow works, standards, gotchas, decisions — before engineering or reviewing, or when you have learned something worth recording. Reads and writes an in-repo Obsidian knowledge base at docs/vault/, synced by git.
---

# docs-vault

Every repo can carry a curated knowledge base at `docs/vault/` — an Obsidian
vault of markdown notes that describe the code and link to it. Use it to load
context before working, and to record what you learn. Git is the sync layer, so
this works the same locally and for remote agents: everyone has the repo, writes
notes, and commits.

## When to use this skill

- Before engineering or reviewing in an unfamiliar repo: read the vault for how
  things actually work, the domain language, the standards, and the gotchas.
- After learning something durable (a non-obvious flow, a decision, a trap):
  write or update a note so the next agent does not relearn it.

Do NOT put code in the vault, and do NOT mirror source files into markdown. Notes
point AT code; the code stays the single source of truth.

## Vault location

The vault root is `<repo-root>/docs/vault/`. Resolve `<repo-root>` per runtime —
see `references/runtimes.md`. In Claude Code: `git rev-parse --show-toplevel`.

If `docs/vault/` does not exist yet, scaffold it (idempotent):

```bash
bash <path-to-this-skill>/scripts/init-vault.sh "$(git rev-parse --show-toplevel)"
```

This creates `_index.md` and the category folders. Obsidian creates `.obsidian/`
itself when first opened; you do not create it.

## Layout

```
docs/vault/
├── _index.md      Map of Content — entry point; links to every note
├── architecture/  how subsystems fit together
├── domain/        domain model + ubiquitous language
├── how-it-works/  walkthroughs of real flows
├── standards/     conventions/patterns to follow in this repo
├── decisions/     light decisions; wikilink out to ../adr/* where present
└── gotchas/       traps and pitfalls
```

## Note format

Every note starts with frontmatter and links to the code it describes:

```markdown
---
title: How ingestion writes the archive
tags: [how-it-works, ingestion, archive]
updated: 2026-06-15
code: [lib/ingest/ingest-filing.ts, lib/chunk/chunks.ts]
---

# How ingestion writes the archive

Ingestion pulls a filing from EDGAR and writes ordered [[Chunk]]s into the
[[Archive]]. Entry point: [`lib/ingest/ingest-filing.ts`](../../lib/ingest/ingest-filing.ts).

...
```

Rules:
- `title`, `tags`, `updated` (today's date, `YYYY-MM-DD`), and `code` (repo-relative
  paths the note describes) are required in frontmatter.
- Link notes to each other with `[[wikilinks]]`.
- Link to code and existing docs with relative markdown links (e.g.
  `../../CONTEXT.md`, `../adr/0003-....md`).
- Keep notes small and durable. State how things work and why; do not paste code.

## Reading / querying

1. Read `docs/vault/_index.md` first — it maps what exists.
2. Then search the vault:
   - Claude Code: Grep/Glob over `docs/vault/**` (search `tags:` and `code:` to
     find notes about a file or topic).
   - Hermes: `search_files` with `target: "content"` and `file_glob: "*.md"`
     under the vault path.

## Writing / updating

1. Create or edit the `.md` note in the right category folder.
2. Add or update its link in `_index.md` under `## Notes`.
3. Set `updated:` to today.
4. Commit: `git add docs/vault && git commit -m "docs(vault): ..."`. Push per the
   repo's policy. (Solo-dev repos: straight to the default branch unless the
   repo's own AGENTS.md says otherwise — check it.)

Under Hermes Docker, write to the bind-mounted container path so files reach the
host — see `references/runtimes.md`.

## Discovery hook

So other agents actually find the vault, ensure the repo's `AGENTS.md` (or
`CLAUDE.md`) contains a line like:

> Knowledge base: read `docs/vault/_index.md` first.

Add it once if missing; do not duplicate it.

## Accuracy

Notes must be verified against the code, never guessed. If a note disagrees with
the code, the code wins — fix the note and bump `updated:`.
