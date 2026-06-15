# skills

Personal, evolving collection of agent skills — authored and maintained by
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

For local development (live edits — the worker sees changes immediately), symlink
instead of installing:

```bash
./install.sh        # symlinks every skill in this repo into ~/.hermes/skills/
```

## Skills

- **software-development/pickup** — at the start of any task, load the project's
  `LEARNINGS.md` and treat past code-review lessons as binding constraints. The
  read side of the self-healing learning loop: the senior reviewer *writes*
  `LEARNINGS.md`; the worker *reads* it via this skill, so the same mistakes stop
  recurring.
