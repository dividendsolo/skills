# startup + self-healing vault — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the vault self-healing (read-first / write-after via the repo's AGENTS.md, inserted by `init-vault.sh`) and add a `/startup` skill that makes any repo agent-ready with a pinned default stack.

**Architecture:** Instruction-based enforcement in each repo's `AGENTS.md` (no hooks, no global CLAUDE.md). `init-vault.sh` manages a sentinel-delimited vault block in `AGENTS.md`. `startup` is a new skill in `dividendsolo/skills` that runs the idempotent meta layer (git, AGENTS.md, CLAUDE.md, .gitignore, vault) and offers the pinned stack for fresh JS/TS web projects.

**Tech Stack:** Bash + Markdown. Spec: `docs/specs/2026-06-15-startup-and-self-healing-vault-design.md`. Work in `~/Developer/repos/skills` (branch `master`, commit directly).

---

## Task 1: init-vault.sh manages the AGENTS.md vault block

**Files:** Modify `software-development/docs-vault/scripts/init-vault.sh`

- [ ] **Step 1:** Add this function near the top (after `VAULT=` is defined), and call it at the end of the script (before the final `echo`). The folder name is `$(basename "$VAULT")`.

```bash
ensure_agents_block() {
  local root="$1" vault="$2"          # vault = folder name, e.g. docket-vault
  local agents="$root/AGENTS.md"
  local begin="<!-- docs-vault:begin (managed by the docs-vault skill; edit the skill, not this block) -->"
  local end="<!-- docs-vault:end -->"
  local block
  block="$(cat <<EOF
$begin
## Knowledge vault

This repo has an Obsidian knowledge vault at \`docs/$vault/\`.

- Before exploring the code, read \`docs/$vault/_index.md\` and treat the vault
  as the first source of truth. Follow its links to the relevant code; only read
  code directly when the vault does not cover what you need.
- After completing a unit of work that is implemented, verified, and accepted,
  update the vault: add or revise notes for new findings, gotchas, standards, and
  decisions; add wikilinks and code links; update \`_index.md\`; bump \`updated:\`.
  Record only durable, verified knowledge, never speculation.
$end
EOF
)"
  if [ ! -e "$agents" ]; then
    printf '# %s\n\n%s\n' "$(basename "$root")" "$block" > "$agents"
    echo "created $agents with vault block"
  elif grep -qF "$begin" "$agents"; then
    local tmp; tmp="$(mktemp)"
    awk -v b="$begin" -v e="$end" -v repl="$block" '
      $0==b {print repl; skip=1; next}
      skip && $0==e {skip=0; next}
      !skip {print}
    ' "$agents" > "$tmp" && mv "$tmp" "$agents"
    echo "updated vault block in $agents"
  else
    printf '\n%s\n' "$block" >> "$agents"
    echo "appended vault block to $agents"
  fi
}
```

Call site (before the final `echo "vault ready at $VAULT"`):
```bash
ensure_agents_block "$ROOT" "$(basename "$VAULT")"
```

- [ ] **Step 2:** Test in a temp dir with NO AGENTS.md:
```bash
t=$(mktemp -d)/proj; mkdir -p "$t"
bash software-development/docs-vault/scripts/init-vault.sh "$t"
echo "--- AGENTS.md ---"; cat "$t/AGENTS.md"
```
Expected: `AGENTS.md` created with `# proj` and the `docs-vault:begin/end` block referencing `docs/proj-vault/`.

- [ ] **Step 3:** Idempotency — re-run and confirm exactly ONE block:
```bash
bash software-development/docs-vault/scripts/init-vault.sh "$t"
echo "begin count: $(grep -cF 'docs-vault:begin' "$t/AGENTS.md")"   # must be 1
```
Expected: `begin count: 1`.

- [ ] **Step 4:** Existing AGENTS.md without a block — confirm it appends once and preserves prior content:
```bash
t2=$(mktemp -d)/proj2; mkdir -p "$t2"; printf '# proj2\n\nExisting line.\n' > "$t2/AGENTS.md"
bash software-development/docs-vault/scripts/init-vault.sh "$t2"
grep -c "Existing line." "$t2/AGENTS.md"   # 1
grep -cF 'docs-vault:begin' "$t2/AGENTS.md" # 1
rm -rf "$(dirname "$t")" "$(dirname "$t2")"
```
Expected: both print `1`.

- [ ] **Step 5:** Commit
```bash
cd ~/Developer/repos/skills
git add software-development/docs-vault/scripts/init-vault.sh
git commit -m "feat(docs-vault): manage read-first/write-after block in AGENTS.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Strengthen docs-vault SKILL.md write-after section

**Files:** Modify `software-development/docs-vault/SKILL.md`

- [ ] **Step 1:** Replace the `## Writing / updating` section's intro so it states WHEN and WHAT. Find the section heading `## Writing / updating` and insert, immediately under it (before the numbered list), this paragraph:

```
Write back when you finish a unit of work that is implemented, verified, and
accepted — not mid-task and not speculatively. Record durable knowledge: a
non-obvious flow, a gotcha, a standard, a decision, or a corrected link. This is
the write half of the self-healing loop; the repo's `AGENTS.md` carries the
read-first/write-after instruction (managed by `init-vault.sh`).
```

- [ ] **Step 2:** Verify the section now has the paragraph and the numbered steps still follow:
```bash
cd ~/Developer/repos/skills
sed -n '/## Writing \/ updating/,/## Discovery hook/p' software-development/docs-vault/SKILL.md
```
Expected: the new paragraph then the numbered list (create note, update index, set updated, commit).

- [ ] **Step 3:** Commit
```bash
git add software-development/docs-vault/SKILL.md
git commit -m "docs(docs-vault): define when/what to write back (self-healing loop)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Author the startup skill

**Files:** Create `software-development/startup/SKILL.md` and `software-development/startup/scripts/startup.sh`

- [ ] **Step 1:** Create `software-development/startup/scripts/startup.sh` (idempotent meta layer):

```bash
#!/usr/bin/env bash
# startup.sh — make a repo agent-ready (idempotent meta layer). Run from the repo
# root, or pass it as $1. Safe to re-run; never clobbers existing file contents.
# Does NOT scaffold an app stack (that is gated/confirmed in the skill body).
set -euo pipefail

ROOT="${1:-$(pwd)}"
mkdir -p "$ROOT"
cd "$ROOT"
name="$(basename "$ROOT")"

# 1. git
if [ ! -d .git ]; then git init -q; echo "git init"; else echo "git: already a repo"; fi

# 2. AGENTS.md (only create if missing; never overwrite existing content)
if [ ! -e AGENTS.md ]; then
  cat > AGENTS.md <<EOF
# $name

<!-- one-line description of what $name is -->

**Stack:** TypeScript (strict), Bun (runtime + package manager), Next.js (App
Router), Supabase (Postgres + Auth), Drizzle + postgres-js, Tailwind v4 +
shadcn/ui, Biome, Vitest, Playwright. Deploy: Vercel (Fly.io for file/SQLite apps).
Override only when it does not make sense for this project.

## Commands

\`\`\`bash
bun dev
bun run typecheck
bun run lint
bun run test
bun run build
\`\`\`

## Conventions

- TDD: failing test first for behavior changes; colocated \`*.test.ts(x)\`.
- Named exports; server components by default.
- No em dashes in any copy, ever.
EOF
  echo "created AGENTS.md"
else
  echo "AGENTS.md: exists (left untouched)"
fi

# 3. CLAUDE.md -> imports AGENTS.md so Claude auto-loads it
if [ ! -e CLAUDE.md ]; then
  printf '@AGENTS.md\n' > CLAUDE.md
  echo "created CLAUDE.md (@AGENTS.md)"
else
  echo "CLAUDE.md: exists (left untouched)"
fi

# 4. .gitignore defaults
if [ ! -e .gitignore ]; then
  cat > .gitignore <<'EOF'
node_modules/
.next/
.env
.env.*
!.env.example
dist/
build/
*.log
.DS_Store
EOF
  echo "created .gitignore"
else
  echo ".gitignore: exists (left untouched)"
fi

# 5. vault (delegates to the docs-vault skill's scaffolder, resolved relative to
#    this script so it works wherever the skill is installed/symlinked)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_INIT="$SCRIPT_DIR/../../docs-vault/scripts/init-vault.sh"
if [ -f "$VAULT_INIT" ]; then
  bash "$VAULT_INIT" "$ROOT"
else
  echo "WARN: docs-vault init-vault.sh not found at $VAULT_INIT; skipping vault" >&2
fi

echo "startup: $name is agent-ready"
```

- [ ] **Step 2:** `chmod +x software-development/startup/scripts/startup.sh`

- [ ] **Step 3:** Create `software-development/startup/SKILL.md`:

```markdown
---
name: startup
description: Use when starting a new app or repo, or making an existing repo agent-ready — say "new app", "new repo", "create a project", "bootstrap this repo". Sets up git, AGENTS.md + CLAUDE.md, .gitignore, and a per-repo Obsidian knowledge vault, then offers the pinned default stack.
---

# startup

Make a repo agent-ready in one move. Idempotent: safe on a brand-new empty
directory or to retrofit an existing repo. Lean into running it when the user
signals a new project; confirm first, then run.

## What it does (meta layer — always, safe, idempotent)

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

## Stack layer (fresh JS/TS web projects only — confirm before running)

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

## After running

Tell the user what was created and what is left (write the AGENTS.md description,
fill Commands, run the stack layer if it is a fresh web app).
```

- [ ] **Step 4:** Test the meta layer on a fresh temp dir:
```bash
cd ~/Developer/repos/skills
t=$(mktemp -d)/freshapp; mkdir -p "$t"
bash software-development/startup/scripts/startup.sh "$t"
echo "--- tree ---"; find "$t" -not -path '*/.git/*' -not -name '.git' | sort
echo "--- AGENTS has vault block? ---"; grep -cF 'docs-vault:begin' "$t/AGENTS.md"
echo "--- CLAUDE.md ---"; cat "$t/CLAUDE.md"
echo "--- vault folder ---"; ls -d "$t/docs/freshapp-vault"
```
Expected: git repo; `AGENTS.md` (with Stack + exactly 1 vault block); `CLAUDE.md` = `@AGENTS.md`; `.gitignore`; `docs/freshapp-vault/` with `_index.md`.

- [ ] **Step 5:** Idempotency — re-run, confirm no duplication / no clobber:
```bash
echo "MARK" >> "$t/AGENTS.md"
bash software-development/startup/scripts/startup.sh "$t"
grep -cF 'docs-vault:begin' "$t/AGENTS.md"   # 1
grep -c 'MARK' "$t/AGENTS.md"                # 1
rm -rf "$(dirname "$t")"
```
Expected: both `1`.

- [ ] **Step 6:** Commit
```bash
git add software-development/startup
git commit -m "feat(startup): agent-ready repo bootstrap skill with pinned stack

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Install + README

**Files:** Modify `README.md`; run `install.sh`

- [ ] **Step 1:** Run the installer (picks up the new skill into both runtimes):
```bash
cd ~/Developer/repos/skills
./install.sh
ls -l ~/.claude/skills/startup && ls -l ~/.hermes/skills/software-development/startup
test -f ~/.claude/skills/startup/SKILL.md && echo "claude OK"
```
Expected: `startup` symlinked into both; `claude OK`.

- [ ] **Step 2:** Add to README's `## Skills` list:
```
- **software-development/startup** — make a repo agent-ready in one move: git,
  AGENTS.md + CLAUDE.md, .gitignore, and a per-repo Obsidian vault, plus the
  pinned default stack (Bun, Next.js, Supabase, Drizzle, Tailwind+shadcn, Biome,
  Vitest, Playwright). Idempotent; also retrofits existing repos.
```

- [ ] **Step 3:** Commit + push
```bash
git add README.md
git commit -m "docs: add startup skill to README

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
git push
```

---

## Task 5: Apply the managed block to docket

docket already has a single manual line `Knowledge base: read docs/docket-vault/_index.md first.` (staged, not committed). Replace it with the managed block.

**Files (in `~/Developer/repos/docket`):** Modify `AGENTS.md`

- [ ] **Step 1:** Remove the old manual line, then run the enhanced scaffolder to add the managed block:
```bash
cd ~/Developer/repos/docket
# drop the old one-liner (the managed block supersedes it)
python3 - <<'PY'
p="AGENTS.md"; ls=open(p).read().splitlines(keepends=True)
out=[l for l in ls if l.strip()!="Knowledge base: read `docs/docket-vault/_index.md` first."]
open(p,"w").writelines(out)
print("removed old line" )
PY
bash ~/Developer/repos/skills/software-development/docs-vault/scripts/init-vault.sh "$(git rev-parse --show-toplevel)"
```

- [ ] **Step 2:** Verify exactly one managed block and the vault was left intact:
```bash
cd ~/Developer/repos/docket
grep -cF 'docs-vault:begin' AGENTS.md          # 1
grep -c 'Knowledge base: read' AGENTS.md       # 0 (old line gone)
ls docs/docket-vault/_index.md                 # still there
```
Expected: `1`, `0`, and the index path listed.

- [ ] **Step 3:** Re-stage and STOP for James's review (docket AGENTS.md requires go-ahead before committing to main):
```bash
cd ~/Developer/repos/docket
git add docs/docket-vault AGENTS.md
git --no-pager diff --cached --stat
```
Present the staged diff; do not commit or push until James says go.

---

## Self-Review

**Spec coverage:** AGENTS.md managed block (T1); write-after definition (T2);
startup skill + pinned stack (T3); install + README (T4); docket application (T5).
Read-first/write-after both in the T1 block. No hooks, no global CLAUDE.md — matches
spec. ✓

**Placeholder scan:** AGENTS.md template intentionally contains a
`<!-- one-line description -->` placeholder for the human to fill; that is content
for the generated repo, not an unfinished plan step. No TBDs in the plan itself.

**Consistency:** sentinel strings (`docs-vault:begin`/`docs-vault:end`), folder name
`docs/<repo>-vault/`, and the `startup.sh` relative path to `init-vault.sh`
(`../../docs-vault/scripts/init-vault.sh`, valid because both live under
`software-development/`) are consistent across tasks.
