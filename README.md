# skills

Personal, evolving collection of agent skills, authored and maintained by
[@dividendsolo](https://github.com/dividendsolo) and pulled into the Hermes agent
(and other harnesses) as the source of truth. Edit here; everything else installs
from this repo.

Skills are organized by category, mirroring the Hermes layout:
`<category>/<skill>/SKILL.md`.

## Install into Hermes

Tap this repo as a skill source, then install a skill:

```bash
hermes skills tap add dividendsolo/skills
hermes skills install dividendsolo/skills/software-development/pickup
```

For local development (live edits, both runtimes see changes immediately),
symlink instead of installing:

```bash
./install.sh        # symlinks every skill into ~/.hermes/skills/ AND ~/.claude/skills/
```

Override targets with `HERMES_SKILLS_DIR` / `CLAUDE_SKILLS_DIR` if needed. A
pre-existing real (non-symlink) skill directory is left untouched, never clobbered.

### Staying in sync (self-healing pulls)

Because skills are symlinked, **edits to an existing skill go live on the next
`git pull` with no install step**. The only thing a pull can't fix on its own is a
brand-new skill directory, which has no symlink yet.

`install.sh` solves that: it wires up a `post-merge` git hook
(`core.hooksPath=.githooks`) the first time you run it on a machine. After that,
every `git pull` auto-links any new skills and tells you what it linked, staying
silent when nothing's new. So the one-time setup per machine (laptop, VPS) is a
single `./install.sh`; from then on, `git pull` keeps the machine in sync.

To check a machine by hand without changing anything:

```bash
./install.sh --check   # exits 0 if every skill is linked, 1 (and lists them) if not
```

Note: `--check`/`install` report (but never overwrite) a *real* directory shadowing
a skill name. If you see a `skip ... real path exists` line, that skill is a stale
standalone copy, not live-linked; remove it and re-run `install.sh` to link it.

## Skills

- **software-development/triage**: groom and route tickets on ANY board through
  a shared status vocabulary (`Triage` -> `Ready for Agent` / `Ready for Human`),
  tracker-agnostic (GitHub Projects, Linear, or any board via a small adapter).
  Owns the pre-implementation flow; pairs with `pickup` (executes) and
  `reviewer-pickup` (merges). James-owned replacement for the matt-pocock triage.

- **software-development/startup**: make a repo agent-ready in one move: git,
  AGENTS.md + CLAUDE.md, .gitignore, and a per-repo Obsidian vault, plus the
  pinned default stack (Bun, Next.js, Supabase, Drizzle, Tailwind+shadcn, Biome,
  Vitest, Playwright). Idempotent; also retrofits existing repos.

- **software-development/docs-vault**: read and write a per-repo, in-repo
  Obsidian knowledge base at `docs/<repo>-vault/` (architecture, domain,
  how-it-works, standards, decisions, gotchas). The folder is named after the repo
  so Obsidian shows the repo name. Git is the sync layer, so the same skill works
  for local Claude Code and remote Hermes. Load it before engineering/reviewing
  to get context; write notes back as you learn.

- **software-development/pickup**: carry ONE ticket forward, then stop. Resolves
  the repo's tracker/board from the AFK registry, picks one ticket by priority,
  routes by status (interview / human walkthrough / execute), reads `LEARNINGS.md`
  as binding constraints, implements test-first, and branches to a PR. The single
  worker workflow for both an autonomous loop and a human picking up a card.

- **software-development/reviewer-pickup**: the senior-reviewer counterpart. Review
  ONE `In Review` PR, then stop: sign off and merge (LIVE) or kick back with
  specific feedback. Sole curator of `LEARNINGS.md`. Designed to run once per
  iteration inside an external loop (a ralph cron), not to loop itself.

- **software-development/afk-setup**: register a repo in the AFK board registry
  (`~/.claude/afk.json`) so pickup/triage/reviewer-pickup can resolve its board.
  Generates the per-repo entry idempotently with a script; per-machine, so each
  box (laptop, VPS) generates its own. Runs as part of `startup`, or standalone
  via `/afk-setup`.
