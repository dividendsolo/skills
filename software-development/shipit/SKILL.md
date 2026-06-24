---
name: shipit
description: Ship the current work. If the branch has an open PR (e.g. from a manual /pickup), merge it once CI is green; otherwise run the validation pipeline plus the tests relevant to the changed files, then commit and push. Use only when the user explicitly invokes /shipit. Never auto-ship.
---

# Shipit

Ship the current changes. Only run when the user explicitly invokes `/shipit`.
Never start this process proactively.

## Two modes

`/shipit` ships whatever the current work is. First detect which case you are in:

- **PR-merge mode** — the current branch is NOT the default branch and has an
  open PR (typically from a `/pickup` the user ran manually). Here the user's
  `/shipit` is their human sign-off: **merge the PR** once CI is green (Step 0).
  `/pickup` deliberately stops at In Review for a separate reviewer; but when the
  user personally picked up the ticket and says ship it, that review gate is
  satisfied by them, so merging is authorized.
- **Direct-to-main mode** — the default: uncommitted/unpushed work on the default
  branch. Validate, run the relevant tests, commit, and push (Steps 1-4).

### Step 0 — PR-merge mode (only when the branch has an open PR)

Detect with `gh pr view --json number,state,headRefName,mergeable,mergeStateStatus`
on the current branch. If there is an OPEN PR for it, this is the whole job:

1. **Require green CI on the head SHA.** `gh pr checks <n>` — every required
   check must be `pass` and the PR `mergeable` / `mergeStateStatus: CLEAN`. If CI
   is still pending, wait for it (`gh run watch`); if anything is failing or the
   PR conflicts, STOP and report — do not merge.
2. **Merge the way the repo merges** (match its history; squash is the common
   default): `gh pr merge <n> --squash --delete-branch`.
3. **Sync and close out.** `git checkout <default> && git pull`, delete the local
   feature branch. If the tracker did not auto-advance the ticket on merge, set it
   to **Done** (the GitHub↔Linear/Projects integration usually does this for you).
4. **Report** the merge commit SHA and that the PR + ticket are shipped. Then
   STOP — skip Steps 1-5. The PR's green CI is the gate; there is nothing
   uncommitted to validate and nothing to commit to `main`.

Only fall through to Steps 1-5 below when there is **no** open PR for the branch.

## Workflow (direct-to-main mode)

### Step 1 — Validate

Run the project's validation pipeline and require all of them to pass before
continuing. Detect the package manager from lockfile / `packageManager` field
(`bun`, `pnpm`, `npm`). Typical pipeline:

1. `<pm> run typecheck`
2. `<pm> run lint`
3. `<pm> run build`

If any step fails, STOP and report the failure. Do not commit.

Note on local build env: some projects keep an empty credential var exported in
the shell that shadows `.env.local` (Next.js gives `process.env` precedence). If
the build fails on an env var that is actually present in `.env.local`, retry the
build with that var unset, e.g. `env -u ANTHROPIC_API_KEY <pm> run build`. Only
do this for local validation — never bake it into the committed build script.

### Step 2 — Run the tests relevant to the change (NOT the full suite)

After validation passes, run the unit/component and e2e tests that exercise the
files this change touched — **not** the whole suite. The goal is to catch
regressions inside the diff's blast radius without paying for an unrelated full
run. The full suite is CI's job; here we run what the change can break.

1. **Find the touched files** — union of uncommitted and committed-but-unpushed:

   ```bash
   git status --porcelain | awk '{print $2}'
   git diff --name-only origin/<default-branch>...HEAD
   ```

2. **Unit / component (Vitest):** let the module graph pick the dependent tests
   — Vitest runs every test that transitively imports a changed file, including
   the colocated `*.test.ts(x)`:

   ```bash
   <pm>x vitest related --run <changed .ts/.tsx files…>
   ```

   Pass the changed **source** files (test files are fine too). If the project
   has no Vitest, fall back to running each changed module's colocated test
   file. This is fast — it's the primary gate.

3. **E2E / visual (Playwright), only when relevant:**
   - Always run any **touched** spec: `<pm>x playwright test <changed *.spec.ts>`.
   - For touched **source** files, run the e2e specs that exercise that surface
     — map by feature dir / route / component name (grep the specs for the route
     or symbol). If nothing clearly maps, say so and skip. **Never** fall back to
     the full e2e suite here.
   - Reuse a running dev server if one is up, or set `E2E_BASE_URL`; the
     Playwright config may already `reuseExistingServer`.
   - If a touched UI surface changed appearance and a visual/snapshot spec
     covers it, run it — and if the baseline legitimately changed, regenerate it
     (`--update-snapshots`) and include the new baseline in the commit.

4. **Everything selected must pass before commit** — same stop condition as
   Step 1. A failure here means fix or report, do not ship.

### Step 3 — Design-rules check on touched UI

After the tests pass, hold the UI the diff touched to the **design-rules** rulebook
— the same blast-radius scoping as Step 2, craft instead of behaviour. No UI in the
diff → skip to Step 4.

1. **Find the touched UI files** — from the same touched-files set as Step 2, keep
   what renders user-facing UI (`*.tsx`/`*.jsx`, `*.css`, files under `components/`
   or `app/`); drop `app/api/*`, `*/route.ts(x)`, server-only modules, and
   `*.test.*` / `*.spec.*`. If none remain, say so and skip to Step 4.
2. **Invoke the `design-rules` skill** and review each touched surface against it:
   every element earns its place; hierarchy by size/contrast/spacing; 3 fonts / 3
   colors and 60/30/10; calm and whitespace; CTA prominence; and the mobile rules
   (no side-by-side, no hover-only affordances, thumb-sized touch targets). For a
   public landing/marketing surface, run `/landing-audit` rather than eyeballing.
3. **Fix cheap, clear breaks in passing; flag the rest** for the user. Mobile
   correctness at 390px gates the ship; a desktop-only cosmetic issue does not
   (CLAUDE.md mobile-first).

### Step 4 — Session log

If the project keeps `notes/session-log.md`, append a short entry: what changed,
decisions made, gotchas, and anything worth promoting to CLAUDE.md.

### Step 5 — Commit and push

This is a **solo operation: commit directly on `main` and push.** No feature
branches, no PRs. (Only create a branch / open a PR if the user explicitly asks
for a review step.)

- Stage the relevant changes, write a clear conventional-commit message.
- End the commit message with the project's required trailer if one exists:

  ```
  Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
  ```

- Commit on `main` and `git push origin main`. Pushing `main` is what triggers
  the production deploy (and any deploy notifications).

## Rules

- Validation **and** the relevant tests (Step 2) must be green before any
  commit. No exceptions.
- "Relevant" means the diff's blast radius — Vitest `related` for unit/component
  plus any touched or surface-matching e2e specs. Don't run the full suite to
  ship; don't skip the relevant slice either.
- When the diff touches UI, run the design-rules check (Step 3) on the touched UI
  files before commit — same blast-radius scoping as the tests, for craft.
- Do not commit secrets or `.env*` files.
- Report the commit SHA and what was pushed when done.
