# startup skill + self-healing vault loop — design

Date: 2026-06-15
Status: approved (brainstorming complete, proceeding to plan)
Repo home: `dividendsolo/skills`
Builds on: `docs/specs/2026-06-15-docs-vault-design.md`

## Problem

The `docs-vault` skill gives a repo a knowledge vault, but two things are missing:

1. **It is not self-healing.** Nothing makes agents (Claude Code, Hermes, or James
   solo) reliably read the vault *before* the code, or update it *after* verified
   work. We want a read-first / write-after loop, like the existing
   `pickup`/`LEARNINGS.md` pattern, working across every agent and every repo.
2. **New repos start cold.** There is no one move that makes a repo "agent-ready"
   (git, agent instructions, the vault, the pinned stack). James wants a `/startup`
   skill that does this, leaned-into-automatically when he says "new app / new repo".

## Decisions (resolved forks)

1. **Enforcement surface = the repo's `AGENTS.md`, NOT hooks.** Hooks are
   runtime-specific (a Claude Code hook does nothing in Hermes) and invisible.
   An instruction in `AGENTS.md` is read by every competent agent, travels with
   the repo, is version-controlled, and covers James-solo too (Claude Code
   auto-loads `CLAUDE.md`/`AGENTS.md` every session; docket's `CLAUDE.md` is just
   `@AGENTS.md`). No global `~/.claude/CLAUDE.md` line either — that would
   duplicate what the per-repo `AGENTS.md` already says once the block is present.
   A Claude-Code-only hook may be added LATER as an optional backstop if the
   instruction proves skippable; it is explicitly not the foundation.

2. **The vault read/write loop is one managed block in `AGENTS.md`,** inserted and
   kept current by `init-vault.sh` (idempotent, sentinel-delimited). Read-first and
   write-after stated together so the whole loop lives in one place.

3. **`startup` is a new skill = the "make this repo agent-ready" layer,** in
   `dividendsolo/skills/software-development/startup/`, installed into both runtimes
   by `install.sh`. It is idempotent (also retrofits existing repos). It does the
   safe meta layer automatically; it gates destructive stack scaffolding behind a
   confirm and only offers it for fresh/empty JS/TS web projects.

4. **The pinned stack lives canonically in the `startup` SKILL.md** ("Default
   stack" section), so a future stack pivot is a one-place edit. `startup` writes
   the stack into each new repo's `AGENTS.md`, so a repo stays pinned to what it
   was born with.

## The self-healing loop (AGENTS.md block)

`init-vault.sh` ensures this sentinel-delimited block in the repo's `AGENTS.md`
(creating `AGENTS.md` if missing). Re-running replaces the block in place; it never
duplicates. `<repo>-vault` is the actual folder name.

```
<!-- docs-vault:begin (managed by the docs-vault skill; edit the skill, not this block) -->
## Knowledge vault

This repo has an Obsidian knowledge vault at `docs/<repo>-vault/`.

- Before exploring the code, read `docs/<repo>-vault/_index.md` and treat the vault
  as the first source of truth. Follow its links to the relevant code; only read
  code directly when the vault does not cover what you need.
- After completing a unit of work that is implemented, verified, and accepted,
  update the vault: add or revise notes for new findings, gotchas, standards, and
  decisions; add wikilinks and code links; update `_index.md`; bump `updated:`.
  Record only durable, verified knowledge, never speculation.
<!-- docs-vault:end -->
```

The `docs-vault` SKILL.md "Writing / updating" section is strengthened to define
WHEN to write back (implemented + verified + accepted) and WHAT (durable findings,
gotchas, standards, decisions, links) so an agent prompted by the block has the
procedure.

## startup skill — behavior

Run order, all idempotent. Detects new-empty-dir vs existing repo.

**Meta layer (always, safe, automatic):**
1. `git init` if not already a git repo.
2. `AGENTS.md` — if missing, scaffold from template (repo name + Stack section +
   Commands placeholder + Conventions); if present, leave existing content alone.
3. `CLAUDE.md` — ensure present and contains `@AGENTS.md` so Claude auto-loads it.
4. `.gitignore` — sane defaults if missing (node_modules, .env*, .next, etc.).
5. Vault — run `init-vault.sh` (creates `docs/<repo>-vault/` + the managed
   AGENTS.md block).

**Stack layer (fresh JS/TS web projects only, behind a confirm):**
6. Write the pinned stack into `AGENTS.md`'s Stack line.
7. Offer to run the install commands (create-next-app/bun, drizzle, tailwind+
   shadcn, biome, vitest, playwright). Only on an empty dir; never run a project
   generator in a non-empty repo. Skipped automatically when retrofitting.

For non-JS/TS or clearly-different projects, the stack layer is skipped (the
"unless it doesn't make sense" escape hatch) and only the meta layer runs.

## Default stack (canonical; lives in startup SKILL.md)

For JS/TS web apps; override only when it doesn't make sense:

- Language: TypeScript (strict)
- Runtime + package manager: Bun (always)
- Framework: Next.js (App Router)
- Database + Auth: Supabase (Postgres + Supabase Auth)
- ORM / query: Drizzle + postgres-js
- UI: Tailwind v4 + shadcn/ui
- Lint + format: Biome (no Prettier)
- Unit tests: Vitest
- E2E / browser: Playwright
- Deploy: Vercel (default); Fly.io for file/SQLite apps

## Triggering

`startup`'s description triggers on "new app", "new repo", "create a project",
"bootstrap this repo", "make this agent-ready". Default posture: when James signals
a new project, propose running `startup` and run it on confirm.

## Out of scope (YAGNI)

- No hooks in v1 (instruction-based; optional Claude-only backstop later).
- No global `~/.claude/CLAUDE.md` edit (would duplicate per-repo AGENTS.md).
- `startup` does not reimplement create-next-app or shadcn init; it orchestrates
  the official tools.
- No CI scaffolding in v1 (can be added to startup later).

## Components & boundaries

- `init-vault.sh` (docs-vault) — gains AGENTS.md managed-block insertion. Stays a
  pure scaffolder.
- `docs-vault/SKILL.md` — strengthened write-after section.
- `startup/SKILL.md` — the bootstrap procedure + canonical Default stack. The only
  thing agents read for `/startup`.
- `startup/scripts/startup.sh` (if needed) — the idempotent meta-layer mechanics
  (git/AGENTS.md/CLAUDE.md/.gitignore), so the SKILL body stays readable.
- `install.sh`, `README.md` — pick up the new skill (already dual-target).

## Test

1. docs-vault: re-run enhanced `init-vault.sh` on docket; confirm the single
   existing discovery line becomes the full managed block, idempotently (re-run =
   no duplication). docket vault stays staged pending James's commit go-ahead.
2. startup: dry-run on a fresh temp dir → git repo + AGENTS.md (with Stack +
   vault block) + CLAUDE.md (@AGENTS.md) + .gitignore + docs/<name>-vault/. Re-run
   → no duplication, no clobber. Confirm it appears as `/startup` after `install.sh`.
