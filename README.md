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

- **software-development/pickup**: at the start of any task, load the project's
  `LEARNINGS.md` and treat past code-review lessons as binding constraints. The
  read side of the self-healing learning loop: the senior reviewer *writes*
  `LEARNINGS.md`; the worker *reads* it via this skill, so the same mistakes stop
  recurring.
