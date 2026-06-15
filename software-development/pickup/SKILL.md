---
name: pickup
description: THE workflow for picking up and carrying one ticket/card/task forward in a project — for an autonomous worker agent or for a human doing it locally. Covers which ticket to pick (priority order), claiming it (move to In Progress + force-unassign), gitflow branch naming, loading the project's LEARNINGS.md as binding constraints, test-first implementation, and stopping at the PR for the reviewer. Use at the very start of working any card, before writing code.
---

# Pickup

You are picking up work from a board (Linear) and carrying ONE ticket forward,
then stopping. Your state lives in the board, in GitHub, and in the repo — never
only in your head. This is the single workflow for both an autonomous worker and
a human picking up a card locally.

Heavy detail is in `references/` and `scripts/`; pull those in only when you
actually need them (e.g. you're scripting MCP calls). The spine below is what you
always need.

## 1. Pick exactly one ticket
Gather the project's eligible issues. "Open" means **Todo** (`statusType:
unstarted`). Pick in this priority order, never skipping a step:

1. **In Progress (mine)** — work I already started. "Mine" is detected by branch
   ownership (an open branch for this ticket whose latest commit is mine, or a PR
   I opened), NOT just "any In Progress card." Resume it.
2. **Changes Requested** — work the reviewer kicked back. Finish this before any
   new work; the context is freshest and it's the cheapest way to clear the board.
3. **Todo** — fresh work, only if (1) and (2) are empty.

Within a group: higher priority first, then older `createdAt`. **Skip** a Todo
whose `blockedBy` includes any issue not yet Done. **Skip** any ticket carrying a
`Needs Triage` label (parked for a human). In Progress / In Review cards that are
**not mine** belong to other agents — do not touch them.

Scope filter (project-specific): only work tickets carrying the project's worker
label if it uses one (e.g. `AFK` on Docket).

If nothing is eligible, print `<promise>NO_TICKETS</promise>` and STOP. (The loop
runner greps this token to know the board is clear.)

## 2. Load the project's LEARNINGS
Before writing any code, look for `LEARNINGS.md` at the repo root.
- If present, **read it in full**. These are hard-won rules the senior reviewer
  distilled from past PR-review kickbacks on *this* project. Treat every entry as
  a **binding constraint**, equal in force to `AGENTS.md` and repo conventions.
- If absent or empty, that's fine — proceed. Empty is the normal state for a young
  project; the reviewer fills it over time.
- **Never write to `LEARNINGS.md`.** You read it; only the reviewer curates it. If
  you find a lesson worth recording, surface it in your PR description so the
  reviewer can decide — do not add it yourself.

## 3. Claim the ticket
Once picked (and, for Todo, only after passing the section 5 gate):
- `save_issue { id, state: "In Progress" }` — claim it **before** coding, so an
  interrupted run leaves the ticket resumable, not stranded.
- **IMMEDIATELY force it unassigned:** `save_issue { id, assignee: null }`. The
  board auto-assigns the acting account on the Todo→started transition; this
  explicit unassign overrides that. Agents are not yet assigned to tickets — leave
  the assignee empty. Do this on **every** claim, not just the first.

## 4. Create the branch (gitflow naming)
`git checkout main && git pull`, then create the branch:
- `feature/<slug>` by default, or `bug/<slug>` if the issue carries a label named
  `bug` (case-insensitive).
- Derive `<slug>` from the issue's own `gitBranchName` by dropping its leading
  prefix segment (everything up to and including the first `/`) and keeping the
  rest. Nothing about the team key, prefix, or title is hard-coded — whatever
  identifier and title the card has flows through verbatim. So
  `<prefix>/<identifier>-<title>` → slug `<identifier>-<title>` → branch
  `feature/<identifier>-<title>`. The identifier stays in the slug so the branch
  traces back to the ticket.

When **resuming** an In Progress / Changes Requested ticket, find its existing
branch by the issue's identifier (`git branch -a --list "*<identifier>-*"`) or the
open PR's head branch — naming differs between older (`<username>/...`) and new
(`feature/...`) branches. Check it out; do NOT reset or check out main (that
discards in-flight work).

## 5. Vertical-slice gate (Todo tickets only — never re-gate started work)
Before starting NEW work, confirm the ticket is a TRUE vertical slice: an
observable end-to-end behaviour change (not a horizontal layer nothing consumes),
independently shippable in one PR with every blocker Done, with concrete testable
acceptance criteria, and genuinely one slice. If it FAILS (too big, horizontal-
only, vague ACs, or several slices smuggled into one): add a `Needs Triage` label,
post a comment explaining why and how to split/sharpen it, do NOT branch or code,
and STOP. Only a passing ticket proceeds.

## 6. Implement test-first — NON-NEGOTIABLE
Every code path is done test-first (use the `matt-pocock/tdd` skill; follow its
red-green-refactor loop):
- **RED FIRST:** write the failing test and see it fail for the right reason. A
  new/changed test that's green on first run is wrong — fix the test.
- **Assert behaviour/structure, not substrings.** Parse and assert real output
  structure; a substring check that passes on broken output is a defect.
- **Changes Requested path:** the FIRST thing you write is a failing test that
  reproduces the reviewer's reported bug at the structural level — red against
  current code, green after the fix. If you can't make it red, you haven't
  understood the bug; re-read the review.
- Honor every applicable `LEARNINGS.md` entry as you write tests and code.
- Then refactor, then run the full gates (e.g. `typecheck && lint && test && build`).

## 7. Per-path specifics
- **In Progress (resume):** inspect what exists (`git status`, `git log
  main..HEAD`), finish remaining work to satisfy EVERY acceptance criterion, gates
  green, commit, push. Open the PR if none exists (body: "Closes <ID>" + each AC
  mapped to how it's met); otherwise the push updates it. Move to **In Review**.
- **Changes Requested (rework):** find the open PR + branch, read ALL feedback
  (GitHub PR reviews, inline comments, and the latest board comments). Write a
  failing test per reported bug, address every requested change scoped to the
  feedback, gates green, commit, push, reply on the PR + board comment, move back
  to **In Review**.
- **Todo (new):** after the gate, claim+unassign (section 3), branch (section 4),
  read `AGENTS.md` and `docs/adr/` first, implement test-first to satisfy every
  AC, follow repo conventions, gates green, commit, push, open the PR, move to
  **In Review**.

## 8. Stop at the PR — do not merge
Open/advance the PR and move the card to **In Review**, then **STOP**. The senior
reviewer owns the merge. Even if a repo's `AGENTS.md` grants self-merge, do not
push the merge button, do not auto-merge via CI, do not delete the branch. The
reviewer signals completion by moving the card to Done (or to Changes Requested,
which comes back to you on the next pickup).

## Rules & habits
- ONE ticket per run, then stop with a short summary of what you did.
- Communicate through the board, not chat: file progress as issue comments
  (`save_comment`), keep chat replies terse. The user reads the board.
- Never push to `main` outside a PR. Never merge your own PR.
- Commit working progress as you go; never end a run with unrecoverable
  uncommitted work — the next run resumes from your commits. If you genuinely
  can't make the gates pass or the ticket is unclear, commit what you have, add a
  comment explaining the blocker, leave it In Progress, and stop. Don't open a
  broken PR.
- For ad-hoc tooling on this machine, use **TypeScript** (`bun`/`tsx`), not
  Python. Don't pull the whole board "to be thorough" — query open work; use
  `get_issue` only when you need a full (untruncated) description.

## References (load on demand)
- `references/linear-mcp-schema.md` — Linear MCP field-name gotchas and response
  shapes. Read it before scripting MCP calls or when a call errors with
  `-32602 unrecognized_keys`. (Claude Code can call the `mcp__linear__*` tools
  directly; the HTTP/JSON-RPC transport notes are for the script path below.)
- `scripts/linear-mcp-client.ts` — minimal Linear MCP client over HTTP+JSON-RPC.
- `scripts/linear-open.ts` — "what's open for me to pick up?" board reader. Copy
  and adapt; don't re-type the SSE-unwrap logic.
