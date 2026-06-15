# docs-vault Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `docs-vault` skill in `dividendsolo/skills` that teaches any agent runtime (Claude Code, Hermes) to use a per-repo, in-repo, git-synced Obsidian knowledge base at `docs/vault/`, install it into both runtimes, and prove it by backfilling docket's vault.

**Architecture:** The vault is a committed folder of markdown notes inside each repo (`docs/vault/`). Notes describe and link to code; they never copy it. Git is the sync layer, so "remote" agents need no server — they already have the repo. The skill is one `SKILL.md` (the agent-facing contract) plus a pure scaffolding script; the repo's `install.sh` symlinks it into both `~/.hermes/skills/` and `~/.claude/skills/`.

**Tech Stack:** Bash (scaffold + install scripts), Markdown (skill + notes). No build system. Spec: `docs/specs/2026-06-15-docs-vault-design.md`.

---

## File Structure

In `~/Developer/repos/skills` (the skills repo, branch `master`):

- Create: `software-development/docs-vault/SKILL.md` — the agent-facing skill (conventions, read/write/query/commit, runtime resolution, discovery hook).
- Create: `software-development/docs-vault/scripts/init-vault.sh` — idempotent scaffolder for `docs/vault/` in any repo.
- Create: `software-development/docs-vault/references/runtimes.md` — per-runtime repo-root resolution + Hermes Docker/SSHFS write guidance (split out of SKILL.md to keep it lean).
- Modify: `install.sh` — symlink each skill into BOTH Hermes and Claude Code skill dirs.
- Modify: `README.md` — document the dual install and list the new skill.

In `~/Developer/repos/docket` (the test target):

- Create: `docs/vault/**` — backfilled notes (the acceptance test).
- Modify: `AGENTS.md` — add the discovery-hook line.

---

## Task 1: Scaffolding script `init-vault.sh`

**Files:**
- Create: `software-development/docs-vault/scripts/init-vault.sh`
- Test: manual run in a temp dir (bash script; verified by asserting created structure)

- [ ] **Step 1: Write the script**

Create `software-development/docs-vault/scripts/init-vault.sh`:

```bash
#!/usr/bin/env bash
# init-vault.sh — scaffold an in-repo Obsidian knowledge vault at docs/vault/.
# Idempotent: never clobbers existing notes; safe to re-run. Run from a repo root,
# or pass the repo root as $1.
set -euo pipefail

ROOT="${1:-$(pwd)}"
VAULT="$ROOT/docs/vault"

mkdir -p \
  "$VAULT/architecture" \
  "$VAULT/domain" \
  "$VAULT/how-it-works" \
  "$VAULT/standards" \
  "$VAULT/decisions" \
  "$VAULT/gotchas"

# Keep empty category dirs tracked by git until notes land.
for d in architecture domain how-it-works standards decisions gotchas; do
  keep="$VAULT/$d/.gitkeep"
  [ -e "$keep" ] || : > "$keep"
done

INDEX="$VAULT/_index.md"
if [ ! -e "$INDEX" ]; then
  repo_name="$(basename "$ROOT")"
  cat > "$INDEX" <<EOF
---
title: $repo_name knowledge base
tags: [index]
updated: $(date +%F)
---

# $repo_name — knowledge base

Curated knowledge for this repo. Notes describe the code and link to it; they do
not copy it. Start here, then follow links.

Read this file first. Code is the source of truth; if a note disagrees with the
code, the code wins — fix the note.

## Map

- **architecture/** — how subsystems fit together
- **domain/** — domain model and ubiquitous language
- **how-it-works/** — walkthroughs of real flows
- **standards/** — conventions and patterns to follow here
- **decisions/** — decisions; link out to ../adr/* where they exist
- **gotchas/** — traps and pitfalls

## Notes

_(none yet — add links as notes are created)_
EOF
  echo "created $INDEX"
else
  echo "exists  $INDEX (left untouched)"
fi

echo "vault ready at $VAULT"
```

- [ ] **Step 2: Make it executable and run it against a temp dir to verify it fails-safe and creates structure**

Run:
```bash
chmod +x software-development/docs-vault/scripts/init-vault.sh
tmp="$(mktemp -d)"; software-development/docs-vault/scripts/init-vault.sh "$tmp"
find "$tmp/docs/vault" | sort
```
Expected output includes `_index.md` and the six category dirs each with `.gitkeep`:
```
.../docs/vault
.../docs/vault/_index.md
.../docs/vault/architecture
.../docs/vault/architecture/.gitkeep
.../docs/vault/decisions
.../docs/vault/decisions/.gitkeep
.../docs/vault/domain
.../docs/vault/domain/.gitkeep
.../docs/vault/gotchas
.../docs/vault/gotchas/.gitkeep
.../docs/vault/how-it-works
.../docs/vault/how-it-works/.gitkeep
.../docs/vault/standards
.../docs/vault/standards/.gitkeep
```

- [ ] **Step 3: Verify idempotency — re-run and confirm it does not clobber**

Run:
```bash
echo "MY NOTE" >> "$tmp/docs/vault/_index.md"
software-development/docs-vault/scripts/init-vault.sh "$tmp"
grep -c "MY NOTE" "$tmp/docs/vault/_index.md"
```
Expected: prints `exists  .../_index.md (left untouched)` then `1` (the appended line survived). Then clean up: `rm -rf "$tmp"`.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/repos/skills
git add software-development/docs-vault/scripts/init-vault.sh
git commit -m "feat(docs-vault): idempotent init-vault.sh scaffolder

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: References file (runtime resolution + Hermes write guidance)

**Files:**
- Create: `software-development/docs-vault/references/runtimes.md`

- [ ] **Step 1: Write the references file**

Create `software-development/docs-vault/references/runtimes.md`:

```markdown
# Runtime notes for docs-vault

The vault root is always `<repo-root>/docs/vault/`. The only per-runtime
difference is how you resolve `<repo-root>` and how you write files reliably.

## Resolving the repo root

- **Claude Code (local):** the current working directory is the repo (or a
  parent of it). Use `git rev-parse --show-toplevel` to get the root.
- **Hermes (VPS / `local` terminal backend):** the repo is at a real absolute
  path on the box. Use that path directly; no mount translation.
- **Hermes (Mac / `docker` terminal backend):** the repo is exposed via a
  `docker_volumes` bind mount, conventionally `/repos/<name>`. The vault is then
  `/repos/<name>/docs/vault/`. The container-side path is the ONLY correct path —
  do not guess `/workspace/...` or `/root/...`. If the mount is missing, the
  session needs a fresh start (a Docker restart alone does not create it).
- **Headless Claude Code:** the repo is a clone; treat its checkout dir as root.

## Writing reliably under Hermes Docker

`write_file` writes to Docker's overlay filesystem, not the host disk, when file
sharing is SSHFS-based (Colima). Files appear inside the container but never reach
the Mac (invisible in Finder/Obsidian). The reliable path is a real
`docker_volumes` bind mount (which `/repos/<name>` and `/vault` already are), so
writing to the bind-mounted container path lands on the host. See the existing
`note-taking/obsidian` skill and `colima-docker-fix` skill for the full SSHFS
detail.

## Syncing (all runtimes)

Git is the sync layer. After writing notes: `git add docs/vault && git commit`.
Push per the repo's policy. Another runtime sees the notes after it pulls. There
is no server and no live cross-repo query — the vault is scoped to its own repo.
```

- [ ] **Step 2: Commit**

```bash
cd ~/Developer/repos/skills
git add software-development/docs-vault/references/runtimes.md
git commit -m "docs(docs-vault): add runtime resolution + Hermes write notes

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Author `SKILL.md`

**Files:**
- Create: `software-development/docs-vault/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `software-development/docs-vault/SKILL.md`:

```markdown
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

\```markdown
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
\```

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
```

Note: in the actual file, the nested fenced code block for the note example uses
escaped backticks (`\```)` above only to embed it in this plan. When you write the
file, use a normal fenced block — i.e. wrap the note example in a ` ```markdown `
fence with plain closing backticks. The simplest correct approach: write the note
example using a `~~~markdown` outer fence so the inner ``` does not collide.

- [ ] **Step 2: Verify frontmatter parses and required keys are present**

Run:
```bash
cd ~/Developer/repos/skills
head -5 software-development/docs-vault/SKILL.md
```
Expected: a YAML frontmatter block with `name: docs-vault` and a `description:`
line that begins with "Use when".

- [ ] **Step 3: Verify the skill body has no leftover escaping artifacts**

Run:
```bash
grep -n '\\`\`\`' software-development/docs-vault/SKILL.md || echo "clean"
```
Expected: `clean` (no escaped-backtick artifacts leaked from this plan into the
real file).

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/repos/skills
git add software-development/docs-vault/SKILL.md
git commit -m "feat(docs-vault): author SKILL.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Dual-runtime `install.sh`

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Replace install.sh with a dual-target version**

Overwrite `install.sh` with:

```bash
#!/usr/bin/env bash
# install.sh — symlink every skill in this repo into BOTH the Hermes skills dir
# and the Claude Code skills dir so local edits are live. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DEST="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills}"
CLAUDE_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

shopt -s nullglob
linked=0
for skill in "$REPO"/*/*/SKILL.md; do
  dir="$(dirname "$skill")"                 # <repo>/<category>/<skill>
  cat="$(basename "$(dirname "$dir")")"     # <category>
  name="$(basename "$dir")"                 # <skill>

  # Hermes: category-nested, mirrors the Hermes layout.
  mkdir -p "$HERMES_DEST/$cat"
  ln -sfn "$dir" "$HERMES_DEST/$cat/$name"
  echo "hermes  $cat/$name -> $dir"

  # Claude Code: flat skill name.
  mkdir -p "$CLAUDE_DEST"
  ln -sfn "$dir" "$CLAUDE_DEST/$name"
  echo "claude  $name -> $dir"

  linked=$((linked + 1))
done
echo "done: $linked skill(s) linked into $HERMES_DEST and $CLAUDE_DEST"
```

- [ ] **Step 2: Run the installer**

Run:
```bash
cd ~/Developer/repos/skills
./install.sh
```
Expected: lines for each skill including `hermes  software-development/docs-vault -> ...`
and `claude  docs-vault -> ...`, ending with `done: N skill(s) linked ...`.

- [ ] **Step 3: Verify both symlinks resolve to the repo**

Run:
```bash
ls -l ~/.claude/skills/docs-vault
ls -l ~/.hermes/skills/software-development/docs-vault
test -f ~/.claude/skills/docs-vault/SKILL.md && echo "claude OK"
test -f ~/.hermes/skills/software-development/docs-vault/SKILL.md && echo "hermes OK"
```
Expected: both symlinks point into `~/Developer/repos/skills/software-development/docs-vault`, and both print `OK`.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/repos/skills
git add install.sh
git commit -m "feat: install skills into both Hermes and Claude Code

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: README update

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the install section and skill list**

In `README.md`, change the "Install" guidance to note the dual target and add the
new skill to the `## Skills` list.

Replace the local-development paragraph and its code block with:

```markdown
For local development (live edits — both runtimes see changes immediately),
symlink instead of installing:

\```bash
./install.sh        # symlinks every skill into ~/.hermes/skills/ AND ~/.claude/skills/
\```

Override targets with `HERMES_SKILLS_DIR` / `CLAUDE_SKILLS_DIR` if needed.
```

(Write the code fence with plain backticks in the real file.)

Add to the `## Skills` list:

```markdown
- **software-development/docs-vault** — read and write a per-repo, in-repo
  Obsidian knowledge base at `docs/vault/` (architecture, domain, how-it-works,
  standards, decisions, gotchas). Git is the sync layer, so the same skill works
  for local Claude Code and remote Hermes. Load it before engineering/reviewing
  to get context; write notes back as you learn.
```

- [ ] **Step 2: Commit**

```bash
cd ~/Developer/repos/skills
git add README.md
git commit -m "docs: document dual install + docs-vault skill

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
git push
```

---

## Task 6: Acceptance test — backfill docket's vault

This exercises the full mechanism: scaffold, write accurate notes, populate the
index, add the discovery hook, and commit. Do this in `~/Developer/repos/docket`.

**Files:**
- Create: `docs/vault/**` in docket
- Modify: `docket/AGENTS.md`

- [ ] **Step 1: Scaffold docket's vault**

Run:
```bash
cd ~/Developer/repos/docket
bash ~/Developer/repos/skills/software-development/docs-vault/scripts/init-vault.sh "$(git rev-parse --show-toplevel)"
find docs/vault -maxdepth 2 | sort
```
Expected: `_index.md` plus the six category dirs created.

- [ ] **Step 2: Write the domain note from CONTEXT.md**

Create `docs/vault/domain/glossary.md` capturing docket's ubiquitous language
(Kernel, Archive, Chunk, Feed, Reader, Summary, Query, Tracked ticker,
Distribution tripwire) sourced from `CONTEXT.md`. Frontmatter:
```yaml
---
title: Domain glossary
tags: [domain, language]
updated: 2026-06-15
code: [lib/chunk/chunks.ts, lib/feed/feed.ts]
---
```
Body: one short paragraph per term, each linking to the relevant code where it
exists, and a relative link to `../../CONTEXT.md` as the source. Wikilink terms
to each other (e.g. `[[Archive]]`). Verify each term against `CONTEXT.md` — do not
invent terms.

- [ ] **Step 3: Write the architecture overview note**

Create `docs/vault/architecture/overview.md` describing how the surfaces sit over
the archive and where each lives in `lib/` (`lib/edgar`, `lib/ingest`,
`lib/chunk`, `lib/extract`, `lib/feed`). Frontmatter `code:` lists those dirs.
Link to `[[Domain glossary]]` and to the relevant ADRs in `../decisions/`. Verify
the file paths exist (`ls lib/`) before asserting them in the note.

- [ ] **Step 4: Write one how-it-works note for ingestion**

Create `docs/vault/how-it-works/ingestion.md` walking the path from EDGAR fetch
(`lib/edgar/`) → ingest (`lib/ingest/ingest-filing.ts`) → chunking
(`lib/chunk/`) → extraction (`lib/extract/`). Read those files first; describe the
real flow, link to the entry points, do not paste code. Frontmatter `code:` lists
the touched files.

- [ ] **Step 5: Write decision stubs that link to existing ADRs**

For each file in `docs/adr/`, create a short note in `docs/vault/decisions/` whose
body is a one-line summary plus a relative wikilink to the ADR (e.g.
`See [ADR-0003](../../adr/0003-supabase-postgres-pgvector-vercel-gha-cron.md).`).
Do not copy ADR contents; link out. List the ADRs first: `ls docs/adr/`.

- [ ] **Step 6: Populate `_index.md`**

Edit `docs/vault/_index.md`, replacing the `_(none yet ...)_` line under
`## Notes` with wikilinks to every note created above, grouped by category. Bump
`updated:` to today.

- [ ] **Step 7: Add the discovery hook to docket's AGENTS.md**

In `docket/AGENTS.md`, after the existing line that begins "Read `CONTEXT.md`
(glossary) and `docs/adr/`...", add:

```
Knowledge base: read `docs/vault/_index.md` first.
```
Verify it appears exactly once: `grep -c "docs/vault/_index.md" AGENTS.md` → `1`.

- [ ] **Step 8: Verify the vault is navigable and accurate**

Run:
```bash
cd ~/Developer/repos/docket
test -f docs/vault/_index.md && echo index-ok
# every code: path referenced in notes exists
grep -rhoE '\b(lib|app|db)/[A-Za-z0-9_./-]+' docs/vault --include='*.md' | sort -u | while read p; do
  [ -e "$p" ] || echo "MISSING: $p"
done
echo "path check done"
```
Expected: `index-ok`, then `path check done` with NO `MISSING:` lines (every code
path a note claims must exist). Fix any note that references a non-existent path.

- [ ] **Step 9: Stage and show the diff for review (do NOT push yet)**

docket's `AGENTS.md` requires James's go-ahead before committing straight to
`main`. Stage and present the diff; pause for approval.

Run:
```bash
cd ~/Developer/repos/docket
git add docs/vault AGENTS.md
git status
git --no-pager diff --cached --stat
```
Then STOP and ask James to review before committing/pushing. Only on his
go-ahead:
```bash
git commit -m "docs(vault): backfill knowledge base

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
git push
```

- [ ] **Step 10: Final smoke test — fresh-eyes navigation**

Open `docs/vault/_index.md`, follow each link, and confirm: links resolve, notes
describe the real code, and a reader with zero context could orient. Report the
result.

---

## Self-Review

**Spec coverage:**
- In-repo + git vault → Tasks 1, 6. ✓
- Link-out, no migration → SKILL.md rules + Task 5/6 (decision stubs link to ADRs, existing docs untouched). ✓
- Vault layout (six folders + `_index.md` + frontmatter) → Task 1 (scaffold), Task 3 (SKILL.md convention). ✓
- Runtime-aware read/write/commit + Hermes Docker write → Task 2 (references), Task 3 (SKILL.md). ✓
- Discovery hook → Task 3 (SKILL.md), Task 6 step 7. ✓
- Scaffolding script → Task 1. ✓
- Install into both runtimes by default → Task 4. ✓
- README → Task 5. ✓
- Backfill docket as the test → Task 6. ✓

**Placeholder scan:** No "TBD/TODO". Content notes in Task 6 (steps 2–5) intentionally describe what to capture rather than pre-writing every note verbatim, because the note bodies must be derived from and verified against docket's live code — pre-writing them would invite hallucinated paths. Each such step names exact files to read, exact frontmatter, and a verification gate (step 8) that fails on any non-existent path.

**Type/name consistency:** `docs/vault/` root, six category names (architecture, domain, how-it-works, standards, decisions, gotchas), `_index.md`, frontmatter keys (`title`, `tags`, `updated`, `code`) are identical across the scaffold script, SKILL.md, and the docket backfill. Install dirs (`~/.hermes/skills/<cat>/<name>`, `~/.claude/skills/<name>`) match between install.sh and its verification. ✓
