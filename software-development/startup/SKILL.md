---
name: startup
description: Use when starting a new app or repo, or making an existing repo agent-ready (say "new app", "new repo", "create a project", "bootstrap this repo"). Sets up git, AGENTS.md + CLAUDE.md, .gitignore, and a per-repo Obsidian knowledge vault, offers the pinned default stack, then optionally pressure-tests scope (make-money) and locks in the domain language (grill-with-docs).
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
6. an AFK board registry entry via the `afk-setup` skill. The default tracker is
   **Linear** (team `Engineering`); since the Linear project cannot be inferred, a
   fresh repo is not auto-registered. Finish it via `/afk-setup` (determine the
   project with the maintainer, reusing or creating one via the Linear MCP), or
   pass `--tracker github` for a GitHub board

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

## Pressure-test scope to make money (optional, the `make-money` lens)

Not every repo is a commercial product. Some are just tools, internal
utilities, or non-commercial apps. So make this a prompt, not an automatic step:

> Ask: "Is this meant to make money, or is it just a tool? Want to run
> `/make-money` now to pressure-test scope toward the first paying user?"

Skip it for throwaway tools and anything not chasing revenue. If it is a
money-making web app and the user says yes:

- **Surface it:** `/make-money` is the reality check for a zero-signup,
  zero-revenue repo. Everything added should earn its keep toward the first
  paying user.
- **Apply it pre-emptively:** before building infra, background jobs, extra
  services, or "nice to have" features, ask the `make-money` question: does this
  move us toward the first paying customer, or is it gold-plating? Default to the
  leanest thing that ships.

Run this before the grill-with-docs step so the lens is active while you decide
what the app is.

## Lock in the shared language (the `grill-with-docs` step)

Final step. Once the repo is scaffolded, offer to run `/grill-with-docs` to nail
down what the app is going to be and capture its ubiquitous language, so every
future conversation about the repo is clear, consistent, and understood.

> Offer: "Want to run `/grill-with-docs` now to lock in the domain language, or
> later?" It is a long, interactive, one-question-at-a-time session, so let the
> user choose now vs later instead of launching it unprompted.

When run, it interviews the user, sharpens fuzzy terms, and writes the results
inline:

- **`CONTEXT.md`** at the repo root: the glossary and nothing else (no
  implementation details). This is the saved shared language that future
  sessions read first.
- **`docs/adr/`**: an ADR only when a decision is hard to reverse, surprising
  without context, and the result of a real trade-off.

This pairs with the vault from the meta layer: the vault holds durable
how-it-works knowledge, `CONTEXT.md` holds the canonical vocabulary.
