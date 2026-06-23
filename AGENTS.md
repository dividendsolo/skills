# skills

Personal, evolving collection of agent skills authored by @dividendsolo and used as
the source of truth. Each skill is a `SKILL.md` (plus optional bundled resources)
under `<category>/<skill>/`, symlinked into Claude Code (`~/.claude/skills/`) and
Hermes (`~/.hermes/skills/`) by `install.sh`. Edit skills HERE; both runtimes see
changes live.

**This is not an app — there is no build/runtime stack.** Skills are Markdown plus
the occasional bundled bash script. Categories in use: `software-development`,
`investing`, `business`, `marketing`, `productivity`.

## Commands

```bash
./install.sh           # symlink any missing skills into both runtimes; wire the design-rules + landing-audit enforcement hooks into Claude Code; wire the self-healing post-merge hook
./install.sh --check   # report skill-link AND hook-wiring drift without changing anything (exit 1 if anything is missing)
```

The UI-craft enforcement hooks live beside their skills at
`software-development/design-rules/hooks/` and `marketing/landing-audit/hooks/`.
`install.sh` symlinks them into `~/.claude/hooks/` and registers them in
`~/.claude/settings.json` (idempotent), so the design-rules build-time guardrail
travels to every machine on the same sync path as the skills.

## Conventions

- Each skill lives at `<category>/<skill>/SKILL.md` with YAML frontmatter (`name`,
  `description`). The `description` MUST carry the trigger phrases that fire the skill.
- The repo is the source of truth — edit skills here, never the symlinked copies in
  `~/.claude/skills` or `~/.hermes/skills`.
- Keep `SKILL.md` terse and progressively disclosed; put long reference material in
  sibling files the skill reads on demand (e.g. `munger/models.md`).
- Skill folder name, frontmatter `name`, and trigger should agree.
- No em dashes in any copy, ever.

<!-- docs-vault:begin (managed by the docs-vault skill; edit the skill, not this block) -->
## Knowledge vault

This repo has an Obsidian knowledge vault at `docs/skills-vault/`.

- Before exploring the code, read `docs/skills-vault/_index.md` and treat the vault
  as the first source of truth. Follow its links to the relevant code; only read
  code directly when the vault does not cover what you need.
- After completing a unit of work that is implemented, verified, and accepted,
  update the vault: add or revise notes for new findings, gotchas, standards, and
  decisions; add wikilinks and code links; update `_index.md`; bump `updated:`.
  Record only durable, verified knowledge, never speculation.
<!-- docs-vault:end -->
