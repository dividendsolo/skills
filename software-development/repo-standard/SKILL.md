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
- The audit is presence-and-config only. Never run the validation pipeline
  (typecheck, lint, test, build) or any heavy command to verify it is "green";
  that is CI's job. Check that the repo is wired up to run it, not that it passes.
- Report gaps, do not auto-fix unless the user asks.
- Counts toward "complete" only when every applicable item is done; N/A needs a
  one-line reason.
- Precision over coverage: a check you cannot run reliably is JUDGE, not a wrong
  confident verdict.
