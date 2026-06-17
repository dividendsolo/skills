# Repo-to-standard rubric Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `repo-standard` skill that holds the canonical, versioned standard and audits any repo against it, plus wire `startup` to instantiate a per-repo checklist and `pickup`/`reviewer-pickup` to verify it on entry.

**Architecture:** One standard, two sides. The new `software-development/repo-standard/` skill bundles the canonical `STANDARD.md` (so it is symlinked into `~/.claude/skills` and reachable from any repo) plus a `scripts/audit.sh` that runs the deterministic checks. `startup` writes a per-repo `docs/repo-standard.md` from a bundled template, stamped with the profile and standard version. Reviews run `/repo-standard` to reconcile the repo against the current standard and report drift.

**Tech Stack:** Markdown skills, bash, jq. No test framework exists for skills in this repo, so script verification uses shell assertions against fixtures (docket as a near-compliant repo, a temp git repo as a bare one).

Spec: `docs/specs/2026-06-17-repo-standard-rubric-design.md`.

Repo conventions that bind this work: no em dashes in any copy, ever; each skill is `<category>/<skill>/SKILL.md` with `name` + trigger-bearing `description`; the repo is the source of truth and `./install.sh` symlinks skills into `~/.claude/skills` and `~/.hermes/skills`.

---

### Task 1: Canonical standard document

**Files:**
- Create: `software-development/repo-standard/STANDARD.md`

- [ ] **Step 1: Write `STANDARD.md`**

Create the file with exactly this content:

```markdown
# Repo Standard

Version: 1

The canonical list of what a repo must have to be "to standard". The `startup`
skill applies these; the `repo-standard` skill verifies them. Every repo meets
CORE; then exactly one profile adds items. Bump `Version` above whenever an item
is added, removed, or materially changed, so per-repo stamps can detect drift.

Status vocabulary for a repo's checklist: done, todo, or N/A (with a one-line
reason). Counts toward "complete" only when every applicable item is done.

## Profiles

- web-app: Next.js or Vercel apps
- service: backend services and APIs
- cli-tool: CLIs and libraries
- bot: bots and automation workers
- content: dotfiles, docs-only, and skill repos (CORE-lite)

## CORE (every repo)

- C1 AGENTS.md exists, with a filled description and a Commands section (no placeholders).
  check: AGENTS.md exists and contains a "## Commands" heading.
  fix: run /startup, then write the description and Commands.
- C2 CLAUDE.md contains `@AGENTS.md`.
  check: grep `@AGENTS.md` CLAUDE.md.
  fix: create CLAUDE.md containing the single line `@AGENTS.md`.
- C3 Knowledge vault docs/<repo>-vault/ with _index.md, plus the vault block in AGENTS.md.
  check: a docs/*-vault directory with _index.md exists.
  fix: run the docs-vault skill (startup does this).
- C4 .gitignore present.
  check: .gitignore exists.
  fix: add .gitignore (startup does this).
- C5 afk.json registry entry resolves to a real board or project.
  check: ~/.claude/afk.json has an entry for this repo with a tracker.
  fix: run /afk-setup.
- C6 No committed secrets; secrets read from env, not code.
  check: no tracked .env file; no obvious secret literals.
  fix: remove the secret, rotate it, move it to env.
- C7 .env.example present if the repo reads env vars.
  check: if code references env vars, .env.example exists.
  fix: add .env.example listing required keys with placeholder values.
- C8 docs/repo-standard.md present and version-stamped.
  check: docs/repo-standard.md exists with a parseable "Standard: vN" line.
  fix: run /startup, or /repo-standard to generate it.
- C9 CONTEXT.md glossary, once the domain is non-trivial (N/A for pure tools).
  check: CONTEXT.md or CONTEXT-MAP.md exists, else N/A with reason.
  fix: run /grill-with-docs.

## Profile add-ons

### web-app, service, cli-tool (engineering and CI)

- E1 Lint and format config (Biome).
  check: biome.json exists.
  fix: bunx @biomejs/biome init.
- E2 Typecheck (tsc strict) with a typecheck script.
  check: tsconfig has strict true and package.json has a typecheck script.
  fix: enable strict, add "typecheck": "tsc --noEmit".
- E3 Test runner (Vitest) plus at least one test.
  check: a vitest config or dep exists and at least one *.test.* or *.spec.* file exists.
  fix: add vitest and a smoke test.
- E4 Validation pipeline in AGENTS Commands, runs green.
  check: AGENTS.md Commands lists typecheck, lint, test, build.
  fix: document the pipeline in AGENTS.md and make it pass.
- E5 docs/adr/ for non-trivial decisions.
  check: docs/adr exists, else N/A with reason.
  fix: add docs/adr and record the first decision.
- CI1 CI runs the validation pipeline on pushes or PRs.
  check: a .github/workflows/*.yml (or equivalent) exists. [v1: flagged, fix by hand]
  fix: add a CI workflow that runs the validation pipeline.
- CI2 Integration mode declared and consistently followed.
  check: AGENTS.md states the mode (straight-to-main or branch+PR). [v1: flagged, judge]
  fix: state the mode in AGENTS.md; the toggle lives in the shipit skill, not here.

### bot

- A1 LEARNINGS.md present (AFK or pickup-enrolled repos).
  check: LEARNINGS.md exists.
  fix: the reviewer-pickup flow creates it from review kickbacks.
- S1 Input-safety notes or ADR where the repo handles external input.
  check: an ADR or AGENTS note covers allowlists, SSRF, or similar. [judge]
  fix: add the note or ADR.

### content

CORE-lite. Apply C1 to C8 where sensible. C9 and all E, CI, A, S items are N/A by
default with a one-line reason.
```

- [ ] **Step 2: Verify it has no em dashes and parses a version**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -c "—" software-development/repo-standard/STANDARD.md
grep -E '^Version: [0-9]+$' software-development/repo-standard/STANDARD.md
```
Expected: first prints `0`; second prints `Version: 1`.

- [ ] **Step 3: Commit**

```bash
cd ~/Developer/repos/dividendsolo/skills
git add software-development/repo-standard/STANDARD.md
git commit -m "repo-standard: add canonical STANDARD.md (v1)"
```

---

### Task 2: Per-repo checklist template

**Files:**
- Create: `software-development/repo-standard/checklist-template.md`

- [ ] **Step 1: Write the template**

This is what `startup` copies into a repo as `docs/repo-standard.md`, substituting
`{{REPO}}`, `{{PROFILE}}`, `{{VERSION}}`, `{{DATE}}`, and pruning the profile
blocks that do not apply. Create the file with exactly this content:

```markdown
# Repo standard checklist: {{REPO}}

Standard: v{{VERSION}}
Profile: {{PROFILE}}
Last reconciled: {{DATE}}

Generated by startup, verified by /repo-standard. Source of truth for the items
is the repo-standard skill's STANDARD.md. Mark each item done, todo, or N/A with
a one-line reason. If "Standard" above is behind the skill's current version, run
/repo-standard to reconcile.

## CORE

- [ ] C1 AGENTS.md with filled description and Commands
- [ ] C2 CLAUDE.md contains @AGENTS.md
- [ ] C3 Vault docs/<repo>-vault with _index.md
- [ ] C4 .gitignore present
- [ ] C5 afk.json entry resolves to a board or project
- [ ] C6 No committed secrets
- [ ] C7 .env.example present if env vars are used
- [ ] C8 docs/repo-standard.md present and stamped
- [ ] C9 CONTEXT.md glossary (N/A for pure tools)

## Profile: {{PROFILE}}

<!-- startup keeps only the block matching {{PROFILE}} -->

### web-app, service, cli-tool

- [ ] E1 Biome config
- [ ] E2 tsc strict with typecheck script
- [ ] E3 Vitest plus a smoke test
- [ ] E4 Validation pipeline in AGENTS Commands, green
- [ ] E5 docs/adr for non-trivial decisions
- [ ] CI1 CI runs the validation pipeline
- [ ] CI2 Integration mode declared and followed

### bot

- [ ] A1 LEARNINGS.md present
- [ ] S1 Input-safety note or ADR for external input

### content

CORE-lite. C9 and all E, CI, A, S items N/A by default with a reason.
```

- [ ] **Step 2: Verify no em dashes**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -c "—" software-development/repo-standard/checklist-template.md
```
Expected: `0`.

- [ ] **Step 3: Commit**

```bash
cd ~/Developer/repos/dividendsolo/skills
git add software-development/repo-standard/checklist-template.md
git commit -m "repo-standard: add per-repo checklist template"
```

---

### Task 3: Audit script (deterministic checks)

**Files:**
- Create: `software-development/repo-standard/scripts/audit.sh`

- [ ] **Step 1: Write the script**

Create `software-development/repo-standard/scripts/audit.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Audit a repo against the repo-standard. Runs the deterministic checks and
# prints one line per item: PASS, FAIL, NA, or JUDGE (needs human or agent
# judgment). Also reports version drift between the repo stamp and STANDARD.md.
#
# Usage: audit.sh [repo-root]   (defaults to the current directory)
set -u

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
standard="$skill_dir/STANDARD.md"
repo="${1:-$PWD}"
cd "$repo" || { echo "no such repo: $repo" >&2; exit 2; }

std_ver="$(grep -E '^Version: [0-9]+$' "$standard" | grep -oE '[0-9]+' | head -1)"

say() { printf '%-5s %s\n' "$1" "$2"; }

# --- version / drift ---
if [ -f docs/repo-standard.md ]; then
  repo_ver="$(grep -oE 'Standard: v[0-9]+' docs/repo-standard.md | grep -oE '[0-9]+' | head -1)"
  profile="$(grep -oE '^Profile: .*' docs/repo-standard.md | sed 's/^Profile: //' | head -1)"
  if [ -n "$repo_ver" ] && [ "$repo_ver" -lt "$std_ver" ]; then
    say DRIFT "repo is on standard v$repo_ver, current is v$std_ver (reconcile)"
  fi
else
  profile=""
  say FAIL "C8 docs/repo-standard.md missing (run /startup or /repo-standard)"
fi
[ -n "$profile" ] && say INFO "profile: $profile"

ck() { # ck ID PASS-condition message
  local id="$1"; shift
  local msg="$1"; shift
  if "$@"; then say PASS "$id $msg"; else say FAIL "$id $msg"; fi
}

has() { [ -e "$1" ]; }
greps() { grep -qE "$1" "$2" 2>/dev/null; }

# --- CORE ---
ck C1 "AGENTS.md with Commands" bash -c '[ -f AGENTS.md ] && grep -qE "^##+ +Commands" AGENTS.md'
ck C2 "CLAUDE.md contains @AGENTS.md" bash -c 'grep -q "@AGENTS.md" CLAUDE.md 2>/dev/null'
ck C3 "vault with _index.md" bash -c 'ls -d docs/*-vault/_index.md >/dev/null 2>&1'
ck C4 ".gitignore present" has .gitignore
# C5 afk.json
repo_name="$(basename "$PWD")"
if [ -f "$HOME/.claude/afk.json" ] && command -v jq >/dev/null 2>&1; then
  if jq -e --arg r "$repo_name" '(.repos // .) | (.[$r] // empty)' "$HOME/.claude/afk.json" >/dev/null 2>&1; then
    say PASS "C5 afk.json entry present"
  else
    say FAIL "C5 afk.json entry missing (run /afk-setup)"
  fi
else
  say JUDGE "C5 afk.json or jq unavailable, check by hand"
fi
# C6 no tracked .env
if git ls-files 2>/dev/null | grep -qE '(^|/)\.env$'; then
  say FAIL "C6 a .env file is tracked by git"
else
  say PASS "C6 no tracked .env"
fi
# C7 .env.example if env used
if grep -rqsE 'process\.env|import\.meta\.env|Deno\.env|os\.environ' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.py' . 2>/dev/null; then
  ck C7 ".env.example present (env vars used)" has .env.example
else
  say NA "C7 no env var usage detected"
fi
# C8 handled above
say JUDGE "C9 CONTEXT.md glossary (present? domain non-trivial?)"
[ -f CONTEXT.md ] || [ -f CONTEXT-MAP.md ] && say INFO "C9 CONTEXT.md exists"

# --- profile add-ons ---
case "$profile" in
  web-app|service|cli-tool)
    ck E1 "biome.json" has biome.json
    ck E2 "tsc strict + typecheck script" bash -c 'grep -q "\"strict\": *true" tsconfig*.json 2>/dev/null && grep -q "\"typecheck\"" package.json 2>/dev/null'
    ck E3 "vitest + a test file" bash -c '(ls vitest.config.* >/dev/null 2>&1 || grep -q vitest package.json 2>/dev/null) && (find . -path ./node_modules -prune -o \( -name "*.test.*" -o -name "*.spec.*" \) -print 2>/dev/null | grep -q .)'
    ck E4 "validation pipeline in AGENTS Commands" bash -c 'grep -qi typecheck AGENTS.md && grep -qi "\blint\b" AGENTS.md && grep -qi "\btest\b" AGENTS.md && grep -qi "\bbuild\b" AGENTS.md'
    ck E5 "docs/adr" has docs/adr
    ck CI1 "CI workflow present" bash -c 'ls .github/workflows/*.y*ml >/dev/null 2>&1'
    say JUDGE "CI2 integration mode declared in AGENTS.md and followed"
    ;;
  bot)
    ck A1 "LEARNINGS.md" has LEARNINGS.md
    say JUDGE "S1 input-safety note or ADR for external input"
    ;;
  content)
    say NA "profile content: E, CI, A, S items N/A by default"
    ;;
  "")
    say JUDGE "no profile set, run /startup or set Profile in docs/repo-standard.md"
    ;;
esac
```

- [ ] **Step 2: Make it executable**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
chmod +x software-development/repo-standard/scripts/audit.sh
```

- [ ] **Step 3: Verify against a bare temp repo (expect FAILs)**

Run:
```bash
rm -rf /tmp/rs-bare && mkdir -p /tmp/rs-bare && cd /tmp/rs-bare && git init -q
~/Developer/repos/dividendsolo/skills/software-development/repo-standard/scripts/audit.sh /tmp/rs-bare
```
Expected: prints a `FAIL` line for `C8 docs/repo-standard.md missing`, `FAIL C2`, `FAIL C4`, and a `JUDGE C9` line. No crash, exit status 0.

- [ ] **Step 4: Verify against docket (expect mostly PASS on CORE)**

Run:
```bash
~/Developer/repos/dividendsolo/skills/software-development/repo-standard/scripts/audit.sh ~/Developer/repos/dividendsolo/docket | grep -E '^(PASS|FAIL) C[1-4]'
```
Expected: `PASS C1`, `PASS C2`, `PASS C3`, `PASS C4` (docket has AGENTS.md with Commands, CLAUDE.md with @AGENTS.md, a vault, and .gitignore).

- [ ] **Step 5: Clean up and commit**

```bash
rm -rf /tmp/rs-bare
cd ~/Developer/repos/dividendsolo/skills
git add software-development/repo-standard/scripts/audit.sh
git commit -m "repo-standard: add deterministic audit script"
```

---

### Task 4: The repo-standard SKILL.md (audit workflow)

**Files:**
- Create: `software-development/repo-standard/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `software-development/repo-standard/SKILL.md` with exactly this content:

```markdown
---
name: repo-standard
description: Audit a repo against the canonical repo-standard (STANDARD.md) and report what is done, drifted, missing, or N/A, with a fix for each gap. Verifies that startup was run and its outputs have not drifted, and generates the per-repo docs/repo-standard.md checklist when missing. Use when the user invokes /repo-standard, says "audit this repo against the standard", "is this repo to standard", "check repo standard", "bring this repo to standard", or when a review or pickup enters a repo.
---

# repo-standard

The verify side of `startup`. The canonical list lives in
[STANDARD.md](STANDARD.md); every verdict traces to it. Do not grade from memory.

## Workflow

1. **Find the profile.** Read `docs/repo-standard.md` for the `Profile:` line. If
   the file is missing, generate it (see "Generate the checklist") and pick the
   profile with the user: web-app, service, cli-tool, bot, or content.

2. **Run the audit.** From the repo root:

   ```bash
   bash <path-to-this-skill>/scripts/audit.sh "<repo-root>"
   ```

   It prints PASS, FAIL, NA, JUDGE, DRIFT, and INFO lines for the deterministic
   checks.

3. **Resolve the JUDGE items yourself** against STANDARD.md: C9 (is the domain
   non-trivial enough to need a glossary?), CI2 (is the integration mode declared
   in AGENTS.md and followed?), S1 (is external input handled safely?). These need
   reading, not a grep.

4. **Reconcile drift.** If the audit prints DRIFT, the repo stamp is behind the
   current standard version. Re-evaluate the new items, update
   `docs/repo-standard.md`, and bump its `Standard: vN` and `Last reconciled`.

5. **Report.** One status per item: done, drifted, missing, or N/A with a reason.
   Lead with the gaps, each with its fix from STANDARD.md. Offer to fix the
   mechanical ones now; do not edit unless asked.

## Generate the checklist

When `docs/repo-standard.md` is missing, copy
[checklist-template.md](checklist-template.md) to `docs/repo-standard.md`,
substitute `{{REPO}}` (repo dir name), `{{PROFILE}}`, `{{VERSION}}` (from
STANDARD.md), and `{{DATE}}` (today), and keep only the profile block that
matches. Mark items already satisfied as done. This is what `startup` calls.

## Rules

- Every verdict traces to STANDARD.md, never memory.
- Report gaps, do not auto-fix unless the user asks.
- Counts toward "complete" only when every applicable item is done; N/A needs a
  one-line reason.
- Precision over coverage: a check you cannot run reliably is JUDGE, not a wrong
  confident verdict.
```

- [ ] **Step 2: Verify frontmatter and no em dashes**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -c "—" software-development/repo-standard/SKILL.md
grep -E '^name: repo-standard$' software-development/repo-standard/SKILL.md
```
Expected: first prints `0`; second prints `name: repo-standard`.

- [ ] **Step 3: Commit**

```bash
cd ~/Developer/repos/dividendsolo/skills
git add software-development/repo-standard/SKILL.md
git commit -m "repo-standard: add audit workflow SKILL.md"
```

---

### Task 5: Install and verify the skill is reachable

**Files:**
- No file changes; runs `./install.sh`.

- [ ] **Step 1: Symlink the new skill into both runtimes**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
./install.sh 2>&1 | tail -5
```
Expected: a line linking `repo-standard` into `~/.claude/skills`, and "done".

- [ ] **Step 2: Verify the symlink resolves**

Run:
```bash
ls -l ~/.claude/skills/repo-standard
cat ~/.claude/skills/repo-standard/STANDARD.md | grep -E '^Version: 1$'
```
Expected: the symlink points to the repo path; `Version: 1` prints (confirms the bundled doc is reachable from the global skills dir).

---

### Task 6: Wire startup to instantiate the checklist

**Files:**
- Modify: `software-development/startup/SKILL.md`

- [ ] **Step 1: Add the checklist step to the meta layer "After running" area**

In `software-development/startup/SKILL.md`, find the `## After running` section:

```markdown
## After running

Tell the user what was created and what is left (write the AGENTS.md description,
fill Commands, run the stack layer if it is a fresh web app).
```

Replace it with:

```markdown
## After running

Tell the user what was created and what is left (write the AGENTS.md description,
fill Commands, run the stack layer if it is a fresh web app).

Then instantiate the standard checklist: pick the repo profile with the user
(web-app, service, cli-tool, bot, or content) and use the `repo-standard` skill's
"Generate the checklist" step to write `docs/repo-standard.md`, stamped with the
current standard version and profile, with the items startup just satisfied
marked done. The `repo-standard` skill is the verify side of this flow: run
`/repo-standard` any time to confirm the repo is still in sync.
```

- [ ] **Step 2: Verify no em dashes were introduced**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -c "—" software-development/startup/SKILL.md
grep -n "repo-standard" software-development/startup/SKILL.md
```
Expected: first prints `0`; second shows the new references.

- [ ] **Step 3: Commit**

```bash
cd ~/Developer/repos/dividendsolo/skills
git add software-development/startup/SKILL.md
git commit -m "startup: instantiate repo-standard checklist after bootstrap"
```

---

### Task 7: Wire pickup and reviewer-pickup to verify on entry

**Files:**
- Modify: `software-development/pickup/SKILL.md`
- Modify: `software-development/reviewer-pickup/SKILL.md`

- [ ] **Step 1: Read both files to find where binding constraints / LEARNINGS are loaded**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -n "LEARNINGS" software-development/pickup/SKILL.md software-development/reviewer-pickup/SKILL.md
```
Expected: line numbers where LEARNINGS.md is loaded in each. Note the nearest
section heading above each match; you will add the repo-standard line right after
that LEARNINGS instruction.

- [ ] **Step 2: Add the verify line to pickup**

In `software-development/pickup/SKILL.md`, immediately after the sentence that
tells the worker to load `LEARNINGS.md` as binding constraints, add this line on
its own paragraph (match the surrounding bullet or prose style):

```markdown
Also read `docs/repo-standard.md` and run `/repo-standard` before starting. If it
reports drift or gaps in areas you are about to touch, fix them as part of the
work or flag them; do not let the repo fall further out of standard.
```

- [ ] **Step 3: Add the verify line to reviewer-pickup**

In `software-development/reviewer-pickup/SKILL.md`, immediately after the sentence
that loads or curates `LEARNINGS.md`, add this line on its own paragraph:

```markdown
As part of review, run `/repo-standard` on the repo and include any drift or new
gaps in the review: the PR should not regress the repo's standard checklist
(`docs/repo-standard.md`), and ideally closes gaps it touches.
```

- [ ] **Step 4: Verify edits and no em dashes**

Run:
```bash
cd ~/Developer/repos/dividendsolo/skills
grep -c "—" software-development/pickup/SKILL.md software-development/reviewer-pickup/SKILL.md
grep -n "repo-standard" software-development/pickup/SKILL.md software-development/reviewer-pickup/SKILL.md
```
Expected: both em-dash counts are `0`; the grep shows the new references in each file.

- [ ] **Step 5: Commit**

```bash
cd ~/Developer/repos/dividendsolo/skills
git add software-development/pickup/SKILL.md software-development/reviewer-pickup/SKILL.md
git commit -m "pickup, reviewer-pickup: verify repo-standard on entry"
```

---

### Task 8: End-to-end check and push

**Files:**
- No file changes; validates the whole flow.

- [ ] **Step 1: Generate a checklist into a throwaway repo via the template**

Simulate what startup does, to prove the template substitutes cleanly:

```bash
rm -rf /tmp/rs-e2e && mkdir -p /tmp/rs-e2e/docs && cd /tmp/rs-e2e && git init -q
t=~/Developer/repos/dividendsolo/skills/software-development/repo-standard
ver="$(grep -oE '[0-9]+' <<<"$(grep '^Version:' "$t/STANDARD.md")")"
sed -e "s/{{REPO}}/rs-e2e/" -e "s/{{PROFILE}}/cli-tool/" -e "s/{{VERSION}}/$ver/" -e "s/{{DATE}}/$(date +%Y-%m-%d)/" "$t/checklist-template.md" > docs/repo-standard.md
grep -E 'Standard: v[0-9]+|Profile: cli-tool' docs/repo-standard.md
```
Expected: prints `Standard: v1` and `Profile: cli-tool` with no `{{...}}` left.

- [ ] **Step 2: Run the audit against it and confirm profile + drift logic**

```bash
~/Developer/repos/dividendsolo/skills/software-development/repo-standard/scripts/audit.sh /tmp/rs-e2e | grep -E 'profile: cli-tool|E1'
```
Expected: an `INFO profile: cli-tool` line and an `E1` line (FAIL, since no biome.json), proving the profile branch runs.

- [ ] **Step 3: Clean up**

```bash
rm -rf /tmp/rs-e2e
```

- [ ] **Step 4: Confirm the tree is clean and push**

```bash
cd ~/Developer/repos/dividendsolo/skills
git status --short
git push 2>&1 | tail -3
```
Expected: `git status --short` shows nothing uncommitted from this work; push reports the commits going to `main`.

---

## Notes for the implementer

- The spec's "single source of truth" principle means item IDs appear in three
  places: STANDARD.md (definitions), checklist-template.md (per-repo tracking),
  and audit.sh (checks). Keep the IDs identical across all three. If you add an
  item, bump `Version` in STANDARD.md so existing repos show DRIFT.
- This plan adds verify hooks to `pickup` and `reviewer-pickup` only. The
  built-in `code-review` skill is not in this repo and is out of scope.
- Do not expand `startup` to scaffold CI or secrets in this task; that is the
  named future follow-on and would change the apply/verify balance.
```
