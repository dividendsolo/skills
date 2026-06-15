---
name: startup
description: Use when starting a new app or repo, or making an existing repo agent-ready (say "new app", "new repo", "create a project", "bootstrap this repo"). Sets up git, AGENTS.md + CLAUDE.md, .gitignore, and a per-repo Obsidian knowledge vault, then offers the pinned default stack.
---

# startup

Make a repo agent-ready in one move. Idempotent: safe on a brand-new empty
directory or to retrofit an existing repo. Lean into running it when the user
signals a new project; confirm first, then run.

## What it does (meta layer: always, safe, idempotent)

Run the bundled script from the target repo root:

```bash
bash <path-to-this-skill>/scripts/startup.sh "<repo-root>"
```

It ensures, without ever clobbering existing file contents:
1. `git init` (if not already a repo)
2. `AGENTS.md` (scaffolded from the stack template if missing)
3. `CLAUDE.md` containing `@AGENTS.md` (so Claude auto-loads the instructions)
4. `.gitignore` defaults
5. the Obsidian knowledge vault via the `docs-vault` skill (creates
   `docs/<repo>-vault/` and the read-first/write-after block in `AGENTS.md`)
6. an AFK board registry entry via the `afk-setup` skill (best-effort: registers a
   GitHub board inferred from the origin remote; a Linear board is set up later
   with `/afk-setup`)

## Default stack (pinned; edit HERE to pivot for all future repos)

For JS/TS web apps. Override only when it does not make sense (e.g. a Python
service, a static site):

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

## Stack layer (fresh JS/TS web projects only; confirm before running)

Only for an EMPTY/new project dir. Never run a project generator in a non-empty
repo (it can clobber). Skip this entirely when retrofitting an existing repo.

After confirming with the user, scaffold with the official tools, e.g.:

```bash
bun create next-app@latest . --typescript --app --no-eslint
bunx @biomejs/biome init
bun add -d vitest @playwright/test && bunx playwright install
bun add drizzle-orm postgres && bun add -d drizzle-kit
bunx shadcn@latest init
```

Adjust to the pinned stack above. Record the actual chosen stack in the repo's
`AGENTS.md` Stack line. If the project is not a JS/TS web app, skip the stack
layer and keep only the meta layer.

Because `biome init` runs here, AFTER the meta layer scaffolded the vault, the
new `biome.json` will not yet exclude the vault. Re-run the meta layer (or
`docs-vault/scripts/init-vault.sh`, which is idempotent) once Biome exists so it
adds `!docs/*-vault` to `biome.json` files.includes. Vault notes are prose, not
code, and should never be linted or formatted.

## After running

Tell the user what was created and what is left (write the AGENTS.md description,
fill Commands, run the stack layer if it is a fresh web app).
