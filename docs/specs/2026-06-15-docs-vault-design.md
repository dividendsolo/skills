# docs-vault skill — design

Date: 2026-06-15
Status: approved (brainstorming complete, proceeding to plan)
Repo home: `dividendsolo/skills` → `software-development/docs-vault/`

## Problem

Each repo accumulates knowledge that is not obvious from the code alone:
architecture, the domain model, how a given flow actually works, the standards to
follow, and the gotchas. Agents (local Claude Code, Hermes on Mac/VPS, headless
runs) and the human need one place to **read that context before engineering or
reviewing**, and to **write it back** as they learn. Today there is no shared,
per-repo, agent-readable knowledge base.

## Decision summary (resolved forks)

1. **Vault location & sync — in-repo + git.** The vault is a committed folder
   inside each repo: `docs/vault/`. Obsidian opens it directly. Every runtime
   already has the repo on disk (local cwd, Hermes `/repos/<name>` bind mount,
   VPS real path, headless clone), so "remote" needs no server — an agent writes
   markdown and commits; the next agent pulls. Git is the sync layer. A
   centralized over-the-net query service was explicitly deferred; it would only
   pay off for cross-repo recall and can be layered on later as a read-only view.

2. **Relationship to existing docs — link out, don't migrate.** The vault holds a
   curated *knowledge layer* only. It does NOT contain code and is NOT a markdown
   mirror of source files. Existing `CONTEXT.md`, `AGENTS.md`, and
   `docs/adr|notes|issues` stay exactly where they are; vault notes link to them
   with relative links / wikilinks. Notes point AT code (paths in frontmatter +
   relative links) rather than copying it, so code stays the single source of
   truth and notes stay small and durable.

3. **Skill home — `dividendsolo/skills`.** Authored once as
   `software-development/docs-vault/SKILL.md`; installed into both Claude Code and
   Hermes via the repo's `install.sh`.

## Vault layout (the convention the skill enforces)

```
docs/vault/
├── _index.md          ← Map of Content: entry point; links to every note
├── architecture/      ← how subsystems fit together
├── domain/            ← domain model + ubiquitous language
├── how-it-works/      ← walkthroughs of real flows (e.g. "ingestion")
├── standards/         ← conventions/patterns to follow in this repo
├── decisions/         ← light decisions + wikilinks out to ../adr/*
└── gotchas/           ← traps and pitfalls
```

Note frontmatter convention (keeps notes greppable and tied to code):

```yaml
---
title: <human title>
tags: [architecture, ingestion]
updated: 2026-06-15
code: [lib/ingest/fetch.ts, lib/ingest/parse.ts]   # code this note describes
---
```

- Notes link to each other with `[[wikilinks]]`.
- Notes link to code and existing docs with relative markdown links.
- `_index.md` is the always-current map; every new note is added to it.

## How agents use it (runtime-aware)

- **Resolve the vault root.** It is `<repo-root>/docs/vault/`. Each runtime
  resolves `<repo-root>` its own way: Claude Code = current working dir; Hermes
  Mac = the `/repos/<name>` bind mount; Hermes VPS / local = real absolute path;
  headless = clone path. The skill documents this resolution explicitly so agents
  do not guess.
- **Read / query.** Always start at `_index.md`. Then Grep/Glob over
  `docs/vault/**` (Claude Code) or `search_files` (Hermes). Frontmatter `tags` and
  `code:` make targeted lookups possible.
- **Write.** Create or edit a `.md` note, update `_index.md`, then `git add` +
  `git commit` (push optional, per repo policy — solo dev commits to `main`).
  Hermes Mac writes through the bind mount; the skill carries the existing
  Docker/SSHFS guidance so writes actually reach the host.
- **Discovery hook.** The skill instructs agents to ensure a single pointer line
  exists in the repo's `AGENTS.md`/`CLAUDE.md`:
  *"Knowledge base: read `docs/vault/_index.md` first."* This is what makes agents
  actually consult the vault.

## Scaffolding

A small idempotent `scripts/init-vault.sh` bundled with the skill. Run from a
repo root, it creates the folder skeleton and a starter `_index.md` if absent. It
does NOT create `.obsidian/` (Obsidian creates that on first open). Idempotent:
safe to re-run; never clobbers existing notes.

## Install into both runtimes

Extend the repo's `install.sh` so each skill symlinks into BOTH targets (default):

- `~/.hermes/skills/<category>/<skill>` (existing behavior)
- `~/.claude/skills/<skill>` (new; flat name, where custom Claude skills live)

Both Claude Code and Hermes use the same `SKILL.md` format (`name` +
`description` frontmatter + markdown body), so one authored file serves both. The
only difference is the install directory. Default is install-into-both; a future
flag can carve out Hermes-only skills if needed.

## Test: backfill docket's vault

Acceptance test for the whole mechanism. Against `~/Developer/repos/docket`:

1. Run `init-vault.sh` to scaffold `docs/vault/`.
2. Using the skill, write real notes sourced from docket's code + `CONTEXT.md`:
   an architecture map, the domain model, how ingest/extract/reader actually work,
   and decision notes that wikilink to the existing `docs/adr/*`.
3. Populate `_index.md` as the map.
4. Add the discovery-hook line to docket's `AGENTS.md`.
5. Commit to docket `main`.

Success = a fresh agent, given only the repo, can open `docs/vault/_index.md`,
navigate to an accurate description of a subsystem, and follow links to the right
code. Notes must be accurate (verified against the code), not hallucinated.

## Out of scope (YAGNI)

- No HTTP/MCP vault server, no over-the-net query API.
- No automatic code→markdown mirroring or doc generation.
- No migration of existing ADRs/notes/issues into the vault.
- No retries/daemon/sync framework — git is the sync.

## Components & boundaries

- `SKILL.md` — the instructions/conventions (the only thing agents read).
- `scripts/init-vault.sh` — pure scaffolding, no knowledge of note content.
- `install.sh` (repo-level) — pure install/symlink, no knowledge of any skill's
  content.
- `references/` (optional) — runtime path-resolution + Docker/SSHFS notes split
  out of `SKILL.md` if it grows too long.

Each unit is independently understandable and testable; the skill body is the
contract agents depend on.
