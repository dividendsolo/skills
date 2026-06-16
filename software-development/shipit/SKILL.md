---
name: shipit
description: Ship the current work — run the validation pipeline plus the tests relevant to the changed files, then commit and push. Use only when the user explicitly invokes /shipit. Never auto-ship.
---

# Shipit

Ship the current changes. Only run when the user explicitly invokes `/shipit`.
Never start this process proactively.

## Workflow

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

### Step 3 — Session log

If the project keeps `notes/session-log.md`, append a short entry: what changed,
decisions made, gotchas, and anything worth promoting to CLAUDE.md.

### Step 4 — Commit and push

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
- Do not commit secrets or `.env*` files.
- Report the commit SHA and what was pushed when done.
