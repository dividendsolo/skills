---
name: pickup
description: Run at the very start of working any ticket/card/task in a project, before writing code. Loads the project's LEARNINGS.md (hard-won lessons curated from past code reviews) and treats every entry as a binding constraint, so you stop repeating mistakes that got prior PRs sent back. Use when picking up a card/issue/task to implement.
---

# Pickup

The first thing you do when you pick up a task — before any code.

## 1. Load the project's learnings
- Look for `LEARNINGS.md` at the repository root.
- If present, **read it in full**. These are hard-won rules the senior reviewer
  distilled from past PR-review kickbacks on *this* project. Treat every entry as
  a **binding constraint** on your implementation — on equal footing with
  `AGENTS.md` and the repo's stated conventions.
- If it is **absent or empty, that is fine** — proceed normally. Empty is the
  expected state for a young project; it fills in over time.

## 2. Apply them as you work
- Check your plan and your tests against the relevant learnings *before* you
  implement. If a learning says "fuzz reassembly invariants," write that test; if
  it says "assert structure, not substrings," assert structure.
- These entries exist specifically to stop recurring kickbacks. Shipping a change
  that ignores an applicable learning is the fastest way to get Changes Requested.

## 3. Never write to LEARNINGS.md
- You are a worker: you **read** this file, you do not edit it. Only the senior
  reviewer curates it.
- If you discover a lesson worth recording, surface it in your PR description /
  summary so the reviewer can decide whether to add it. Do not add it yourself.

That's the whole ritual: load the learnings, honor them, leave the file to the reviewer.
