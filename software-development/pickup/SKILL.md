---
name: pickup
description: THE workflow for picking up and carrying ONE ticket/card forward, for an autonomous worker agent or for a human doing it locally. Resolves the repo's tracker from the AFK registry (~/.claude/afk.json; GitHub Projects or Linear), picks one ticket by priority, routes by status x label (interview / human walkthrough / execute), loads LEARNINGS.md as binding constraints, implements test-first, then branches to a PR for the reviewer. Use when the user says "pick up <id>", "work on issue <id>", invokes /pickup, or at the very start of working any card.
---

# Pickup

You carry ONE ticket forward, then stop. Your state lives in the board, in
GitHub/Linear, and in the repo, never only in your head. This is the single
workflow for both an autonomous worker (e.g. `ralph`) and a human picking up a
card locally.

**pickup always branches and opens a PR** for `reviewer-pickup` to sign off and
merge. This is the deliberate exception to the global "commit straight to main,
no branches" rule: that rule governs ad-hoc solo edits; pickup is the structured,
reviewed path, so it gets a branch and a PR every run.

Heavy detail is in `references/` and `scripts/`; pull those in only when you
actually need them (e.g. scripting Linear MCP calls). The spine below is what you
always need.

## Model (Claude Code only)
The *engineering* in this workflow (the test-first implementation, sections 6-8)
runs on **Sonnet**, not Opus. Opus is overkill for mechanical red-green-refactor
coding. If you are orchestrating on Opus, dispatch the implementation to a
**Sonnet subagent** (Task/Agent tool, `model: sonnet`): hand it the ticket, the
acceptance criteria, the failing-test-first discipline, and the applicable
`LEARNINGS.md` / `AGENTS.md` / `docs/adr/` constraints, and have it implement and
run the gates. Keep the judgment work on Opus: ticket selection, the
vertical-slice gate, the Triage/Needs-Info interview, the human walkthrough, and
the PR/reviewer interaction. If the session is already Sonnet, just implement
inline. This applies only in Claude Code; Hermes runs its own model, so ignore it
there.

## 0. Resolve the tracker (AFK registry)
Look up the repo root (`git rev-parse --show-toplevel`) in `~/.claude/afk.json`
under `repos`. The entry names the `tracker` (`github`, `linear`, or any other),
the board coordinates, the board's `readyStatus` / `humanStatus` strings, and
`shipMode`. If there is no entry, suggest running `/afk-setup` to pin it.

Every board speaks the same **shared status vocabulary** (`Triage`,
`Ready for Agent`, `Ready for Human`, `In Progress`, `In Review`,
`Changes Requested`, `Done`), the same one `triage` and `reviewer-pickup` use.
Only the mechanics differ (GitHub via `gh`, Linear via the MCP, any future tracker
via the same five operations); see **Trackers** at the bottom. Resolve the actual
status strings from `afk.json` (they should match the canonical names verbatim).

## 1. Pick exactly one ticket
Gather the project's eligible issues. Ready means the board's `readyStatus`
(canonically `Ready for Agent`). Pick in this priority order, never skipping a step:

1. **In Progress (mine):** work I already started. "Mine" = an open branch for
   this ticket whose latest commit is mine, or a PR I opened. NOT just any In
   Progress card. Resume it.
2. **Changes Requested:** work the reviewer kicked back. Finish this before any
   new work; the context is freshest and it clears the board cheapest.
3. **Ready for Agent:** fresh work, only if (1) and (2) are empty.

Within a group, order by the board's **native priority field** highest-first
(`Urgent` > `High` > `Medium` > `Low`, with `No priority` last), then by older
`createdAt` as the tie-break. So a `High` ticket is picked before a `Medium` one in
the same group regardless of age, and equal-priority tickets go oldest-first. (A
`Ready for Agent` ticket with `No priority` should have been kicked back by the
priority audit below; if you still see one, it sorts last.) **Skip** a ticket
whose blockers are not all Done. **Skip** any ticket carrying a `Needs Triage` /
parked marker (it is for a human). In Progress / In Review cards that are **not
mine** belong to other agents; do not touch them. Scope filter: if `afk.json`
names a worker label for the project, only work tickets carrying it.

If nothing is eligible, print `<promise>NO_TICKETS</promise>` and STOP. (The loop
runner greps this token to know the board is clear.)

## 2. Load the project's LEARNINGS
Before writing any code, look for `LEARNINGS.md` at the repo root.
- If present, **read it in full**. These are hard-won rules the senior reviewer
  distilled from past PR-review kickbacks on *this* project. Treat every entry as
  a **binding constraint**, equal in force to `AGENTS.md` and repo conventions.
- If absent or empty, fine. Proceed. Empty is normal for a young project.
- **Never write to `LEARNINGS.md`.** You read it; only the reviewer curates it. If
  you find a lesson worth recording, surface it in your PR description so the
  reviewer can decide.

Also read `docs/repo-standard.md` and run `/repo-standard` before starting. If it
reports drift or gaps in areas you are about to touch, fix them as part of the
work or flag them; do not let the repo fall further out of standard.

## 3. Route by status (the state machine)
Read the ticket's title, labels, body, any agent-brief comment, and its **board
status**. Status is the canonical state machine; labels carry *kind-of-work*
(bug / enhancement / security / tech-debt / documentation / research), which is
orthogonal. First, refuse if truly not actionable (tell the user why):
- Closed, or status `Done` (already shipped), `Canceled`, or `Duplicate`.
- Status `Backlog` (parked): ask if they want to revive it before doing anything.

Otherwise route by status:

| Status | Path |
|---|---|
| `Triage` (+ `needs-info` label) | **Interview:** resolve open design questions (see Interview discipline). Resolution flips status/label, NOT code. This is `triage`'s job; pickup only interviews if asked. |
| `Ready for Human` | **Human walkthrough** (see below). You co-pilot; the user does the work. |
| `Ready for Agent` | **Execute:** sections 4-9. |
| `In Progress` (mine) / `Changes Requested` | **Resume / rework:** section 8, skip the gate. |

**No exceptions for the interview paths.** Even if the body looks well-spec'd, run
the interview; the maintainer needs the structured Q&A, not your read of the body.

**Priority audit (before executing `Ready for Agent` / `Ready for Human`).** A
fully groomed ticket carries a **priority** (the board's native priority field). If
it is unset (`No priority`), the ticket skipped triage's final step: do NOT execute
it. Kick it back, set status `Triage`, post a comment saying the priority is
missing, and STOP. `triage` owns grooming completeness and assigns the priority
(default Medium; `bug`/`security` at least High) before the ticket returns to
`Ready for Agent`.

## 4. Vertical-slice gate (new tickets only; never re-gate started work)
Before starting NEW work, confirm the ticket is a TRUE vertical slice:

<vertical-slice-rules>
- Cuts END-TO-END through all layers (data/schema -> logic -> API -> UI -> tests),
  NOT a horizontal slice of one layer.
- Independently demoable/verifiable on its own.
- As THIN as possible while still complete; prefer many thin slices over few thick.
</vertical-slice-rules>

The gate FAILS if the ticket is horizontal, not independently demoable, or could be
thinned further while staying a full slice. (Thickness alone is not a failure; a
fat-but-complete slice is fine.)

- **Interactive (you, locally):** STOP. Surface the failure and prompt the user to
  help thin/split it; offer to run `/to-issues`. Do not "just start on the first
  bit"; wait for the decision on how to slice it.
- **Autonomous (worker):** add a `Needs Triage` label, post a comment explaining
  why and how to split/sharpen, do NOT branch or code, and STOP.

Only a passing ticket proceeds.

## 5. Claim the ticket
Once picked (and, for new tickets, only after passing section 4):
- Set status **In Progress** **before** coding, so an interrupted run leaves the
  ticket resumable, not stranded.
- **IMMEDIATELY force it unassigned** (`assignee: null`). The board auto-assigns
  the acting account on the started transition; override that. Agents are not
  assigned to tickets. Do this on **every** claim, not just the first.

## 6. Create the branch (gitflow naming)
`git checkout main && git pull`, then branch:
- `feature/<slug>` by default, or `bug/<slug>` if the issue carries a `bug` label
  (case-insensitive).
- Derive `<slug>` from the issue's own branch name / identifier: drop the leading
  prefix segment (up to and including the first `/`) and keep the rest, so
  `<prefix>/<identifier>-<title>` -> `feature/<identifier>-<title>`. The identifier
  stays so the branch traces back to the ticket.

When **resuming**, find the existing branch by identifier
(`git branch -a --list "*<identifier>-*"`) or the open PR's head branch; check it
out. Do NOT reset or check out main (that discards in-flight work).

## 7. Implement test-first, routed by label (NON-NEGOTIABLE)
Every code path is done test-first (use the `tdd` skill; follow red-green-refactor):
- **RED FIRST:** write the failing test and see it fail for the right reason. A
  new/changed test green on first run is wrong; fix the test.
- **Assert behaviour/structure, not substrings.** A substring check that passes on
  broken output is a defect.
- Honor every applicable `LEARNINGS.md` entry, `AGENTS.md`, and `docs/adr/`.
- Then refactor, then run the full gates (e.g. `typecheck && lint && test && build`).

Route the *kind* of work by label:

| Label | How to work it |
|---|---|
| `enhancement` | Test-first vertical slice. One failing test -> one slice of impl -> repeat. Tracer bullets, not horizontal layers. |
| `bug` | Reproduce with a failing test FIRST, then minimal fix. Never AskUserQuestion about fix direction before the repro confirms the shape. |
| `bug` (hard repro / perf) | Diagnose discipline: reproduce -> minimise -> hypothesise -> instrument -> fix -> regression-test. |
| `security` | Treat as a bug: failing test demonstrating the vuln, then patch. |
| `tech-debt` | Refactor / rename / dead-code removal, no behaviour change. Tests still pass; ideally no test changes beyond renames. |
| `documentation` | Edit the doc; no code change. Treat as P0. |

If multiple labels apply or routing is ambiguous, state your read and ask which path.

## 8. Per-path specifics
- **In Progress (resume):** inspect what exists (`git status`, `git log
  main..HEAD`), finish every acceptance criterion, gates green, commit, push. Open
  the PR if none exists (body: "Closes <ID>" + each AC mapped to how it's met);
  else the push updates it. Move to **In Review**.
- **Changes Requested (rework):** find the open PR + branch, read ALL feedback
  (PR reviews, inline comments, latest board comments). Write a failing test per
  reported bug, address every requested change scoped to the feedback, gates green,
  commit, push, reply on the PR + board, move back to **In Review**.
- **Ready for Agent (new):** after the gate, claim+unassign (5), branch (6), read
  `AGENTS.md` + `docs/adr/` first, implement test-first to satisfy every AC, gates
  green, commit, push, open the PR, move to **In Review**.

## 9. Stop at the PR (do not merge)
Open/advance the PR and move the card to **In Review**, then **STOP**. The senior
reviewer (`reviewer-pickup`) owns the merge. Even if a repo's `AGENTS.md` grants
self-merge, do not push the merge button, do not auto-merge via CI, do not delete
the branch. The reviewer signals completion by moving the card to Done (or to
Changes Requested, which comes back to you on the next pickup).

**Manual-QA flag (do this as you move to In Review).** If your closing summary's
**Manual QA** is a real item (anything other than "none needed"), the change needs
a human check before it can ship. So that the reviewer parks it instead of
auto-merging:
- Add the **`Needs Manual QA`** label to the card.
- Post a board comment titled **`Manual QA required before merge`** (with the AI
  disclaimer). It MUST lead with **where to look**, on its own lines at the very
  top, so James never has to guess what he is QA-ing:
  - `**Branch:** <branch-name>`
  - `**Preview:** <vercel-preview-url>` (the deploy of THIS branch, not prod). Get
    it from the PR's Vercel comment / `gh pr view`. If no preview exists yet, say
    so and how to get one (push, or run locally on that branch) rather than
    leaving it blank, and flag it so previews get fixed.
  Then list the exact steps James must run or eyeball and why an agent cannot do
  them. Keep it concrete; this is the checklist James works from and the text the
  reviewer puts in its Discord ping. The Discord `qa-hold` ping must also name the
  branch and preview URL.
- **Linear: also pin the preview as a clickable chip.** In addition to the comment,
  add a Linear link attachment titled `Preview` pointing at the same branch-alias
  preview URL, so it renders as a chip at the top of the card and James does not have
  to open the comment to reach it. Mechanism: `save_issue` with
  `links: [{title: "Preview", url}]` (the `create_attachment` tool is for file
  uploads, NOT this). `links` is append-only, so first read the card's existing
  attachments (`get_issue`) and only add when there is no `Preview` attachment
  already, to avoid stacking duplicates on a re-run. On GitHub or other trackers,
  skip this; the comment above is enough.
When the only thing left on an approved, CI-green PR is this manual QA, the reviewer
will leave the card parked in `In Review`, NOT merge it, and ping James; James QAs,
then merges (or asks an agent to). If Manual QA is "none needed", do not add the
label, and the reviewer merges as usual.

Non-execution outcomes (from any path):
- **Needs Info:** implementation surfaced a question only the reporter can answer.
  Post a comment (with the disclaimer) listing the specific questions; set status
  **Needs Info** / `Backlog`. Do NOT commit speculative code.
- **Blocked:** a dependency surfaced mid-flight. Add a `blocked`/`blockedBy`
  marker, comment naming the blocker, leave status as-is.

### Closing summary (STRICT: exactly four items)
Write each as a standalone **paragraph** (bold label + text), separated by blank
lines (list markers render tight in the terminal; `&nbsp;` prints literally). No
file lists, no diffs, no per-file walkthrough. The user does not read them.

```
**What the card was:** <the issue in one line>

**What we did:** <the change in plain terms, outcomes not file paths>

**How it was verified:** <tests run + result, typecheck/lint, any visual check>

**Manual QA:** <"none needed (covered by X)" OR the specific thing the human must
eyeball/click and why an agent couldn't>
```

## Interview discipline (Triage / Needs Info / Backlog)
The triage state means "needs the human's brain." Resolve design questions BEFORE
applying labels or flipping state.
- **Plain English.** Talk about the actual app (alert emails, dashboard cards,
  Form 4, 8-K), not jargon ("consumer", "registry", "coupling") unless defined.
- **One question at a time.** Never batch decisions.
- **Vertical slices.** Every shaped issue must describe a tracer-bullet slice
  end-to-end. If horizontal, narrow it.
- **No "when does this ship?" questions.** Scheduling is the user's call.
- **No code dumps.** Default reply shape: Issue -> Options -> Recommendation -> Effects.
- **No AskUserQuestion about bug-fix direction before reproducing.** Failing test first.

When the issue plausibly introduces/renames a domain term, changes the data model,
sets tier/gating semantics, or warrants an ADR, the interview must update
`CONTEXT.md` and/or `docs/adr/` inline as decisions crystallise. Otherwise the
conversation alone is enough. After resolving, apply the category label and the new
status; don't auto-advance to implementation in the same session unless told to.

## Human walkthrough (Ready for Human)
The user does the work (reads samples, exercises the UI, makes the judgement call,
accesses systems you can't reach). Keep them in flow: hold the rubric, surface one
step at a time, capture findings, draft the closeout.

First check for blockers (issue body / sub-issue tree). If a needed dependency is
still open, surface it and stop. Otherwise:
1. **Parse the work plan** (the body's Work / Acceptance / numbered steps). Build
   the step list in your head; do not dump it on the user.
2. **Restate the goal in one sentence**, then state step 1 with the *minimum*
   context they need (rubric, file/URL, what "good" looks like).
3. **Wait for their finding** (clean / drift / question / tangent).
4. **Capture it** in a running log, one line per step in the AC format.
5. **Surface the next step**, same shape.
6. **If they get stuck**, pause and help resolve before continuing.
7. **At the end**, draft the closeout comment (per-step findings + verdict + any
   prompt changes); show the user before posting.

## Comment disclaimer
Any comment you post on a ticket during pickup must start with:

```
> *This was generated by AI during pickup.*
```

## Trackers (mechanics only; the vocabulary is shared)
Every board uses the same status vocabulary; only the API differs. Resolve the
tracker and the actual status strings from `afk.json`.
- **GitHub Projects:** `gh issue view` to read; `gh project item-edit` to set
  status; `gh issue edit --add-label` for labels.
- **Linear:** load MCP tools via ToolSearch (`get_issue`, `list_comments`,
  `save_issue`, `save_comment`); fetch by identifier (e.g. `JAM-6`); set status
  with `save_issue { state }`.
- **Any other tracker:** implement the same five operations (fetch, set status,
  add/remove label, comment, close). Nothing else here is tracker-specific.

Kind-of-work labels (bug/enhancement/etc.) may not exist in a young workspace;
infer the route from the body and say so. If a specific CLI/MCP call isn't to
hand, ask the user once rather than doing it manually.

## Rules & habits
- ONE ticket per run, then stop with the closing summary.
- Communicate through the board, not chat: file progress as ticket comments; keep
  chat replies terse. The user reads the board.
- Never push to `main` outside a PR. Never merge your own PR.
- Commit working progress as you go; never end a run with unrecoverable uncommitted
  work; the next run resumes from your commits. If you can't make the gates pass
  or the ticket is unclear, commit what you have, comment the blocker, leave it In
  Progress, and stop. Don't open a broken PR.
- For ad-hoc tooling on this machine, use **TypeScript** (`bun`/`tsx`), not Python.
  Query open work; don't pull the whole board "to be thorough."

### Discipline that survives across all paths
- **Default to DELETE, not "gate behind a flag"** when reviewing pre-revenue features.
- **UI changes verify both light AND dark mode.**
- **High-risk surfaces (pricing/checkout/auth/public copy) need a Playwright spec.**
- **Paid-service call sites get audited for token waste.**
- **Out-of-scope bugs surfaced mid-pickup -> open an issue immediately**, don't just
  mention inline.

## References (load on demand)
- `references/linear-mcp-schema.md`: Linear MCP field-name gotchas and response
  shapes. Read before scripting MCP calls or on a `-32602 unrecognized_keys` error.
- `scripts/linear-mcp-client.ts`: minimal Linear MCP client over HTTP+JSON-RPC.
- `scripts/linear-open.ts`: "what's open for me to pick up?" board reader.
