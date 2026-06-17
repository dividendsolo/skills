---
name: quiz-me
description: Active-recall flashcards over the personal Obsidian zettelkasten MOCs, drawn from a saved, growing card bank with coaching and weak-spot tracking. Pulls curated Q&A from .quiz/cards/<moc>.md for fast, rapid-fire sessions; generates from notes only when the bank is thin. New cards are added in vetted batches (~5/week). Use when the user invokes /quiz-me, says "quiz me", "test me on <topic>", "drill me", "add quiz cards", or wants to practice recalling their vault knowledge.
---

# Quiz Me — Active Recall over the Vault

Turn the zettelkasten into memory. Run live flashcards so the user can recall the stuff they found valuable — fast, from memory, for use in conversation and writing. Flashcard cadence (one atomic card at a time, answer, reveal), but **you are the coach, not a self-grade button**: the user answers in their own words; you reveal the saved answer and give one sharp line on what to tighten.

Architecture: **author dynamically, serve statically.** Sessions pull curated cards straight from a saved bank (fast — no note-reading, no generation). New cards are authored from the notes in vetted batches (~5/week) and appended to the bank.

**Vault:** `/Users/james/Vaults/zettelkasten/`
**MOCs:** listed in `Home 🏡.md`. Notes live flat in `Processed/`.
**Card bank:** `/Users/james/Vaults/zettelkasten/.quiz/cards/<moc>.md` — saved Q&A per MOC, the source for sessions.
**Progress log:** `/Users/james/Vaults/zettelkasten/.quiz/progress.md` — weak/strong/last-miss per MOC (hidden dot-folder, invisible in Obsidian). Create on first run.

## Invocation

- `/quiz-me <moc>` — quiz that MOC from its saved bank (e.g. `/quiz-me investing`).
- `/quiz-me` — ask which MOC, or offer "weakest across all" / "random".
- `/quiz-me weak` — drill logged weak spots across every MOC.
- `/quiz-me <moc> add` — author ~5 new cards from the MOC's notes and append them to the bank (the weekly habit).

## Workflow

### 1. Resolve the target

Read `Home 🏡.md` for the MOC list. Resolve the argument to one MOC (or the weak set). If bare/ambiguous, ask which — short menu, don't interview.

### 2. Load (fast path)

Read `.quiz/cards/<moc>.md` (the bank) and `.quiz/progress.md`. **That is all a normal session needs** — the answers live in the bank, so you do NOT re-read the MOC's notes. (Notes are read only when adding cards, step 6.)

### 3. Pick the deck (no generation)

Choose ~5 cards from the bank (honor a different count if asked):

- **Weak-first:** lead with the progress log's weak and last-miss cards. This is the spaced-repetition engine.
- Fill the rest with least-recently-seen cards, favoring the high-value **connection** and **application** cards.
- **Fallback:** if the bank for this MOC is empty or thin (<5 cards), generate from the notes for this session (read them now), run them, and offer to save the keepers (step 6).

### 4. Run the cards (one at a time, FAST)

For each card:

1. **Front:** ask the question. Then STOP and wait. Never reveal in the same turn.
2. The user answers from memory in their own words.
3. **Back:** reveal the saved answer, then **one** sharp coaching line — what landed, what to tighten. Tight, not an essay. Honest grading.
4. Silently note the outcome for that card: **got / fuzzy / missed**.

Keep it FAST. Flashcards fly: terse front, answer + one line, next card. Minimal formatting. One card per exchange. No tool calls between cards.

### 5. Recap and update progress

After the last card: a one-line "revisit" recap. Then update `.quiz/progress.md` by card label:

- Move **missed/fuzzy** cards into the MOC's `weak` list; record under `last-misses (<date>)`.
- A card recalled cleanly (`got`) **twice in a row** retires from `weak` to `strong`.
- Compact and human-readable. Convert relative dates to absolute.

### 6. Add cards (~5/week) — `/quiz-me <moc> add`

Read the MOC's notes. Draft ~5 new high-value cards (favor **connection** and **application** — the recall-you-can-use kind). Show them to the user to vet/edit; **skip near-duplicates** of cards already in the bank. Append the accepted ones to `.quiz/cards/<moc>.md`. This is the habit that grows the deck.

## Card bank format

`.quiz/cards/<moc>.md`:

```
# <MOC> — Flashcards

## <short concept label>
Q: <question>
A: <model answer, 1-3 lines>
src: [[source note]]
```

One block per card. The `## label` is the card's stable identity — the progress log references it.

## Progress file format

```
# Quiz Progress

## <MOC name>
weak: <card label>, <card label>
strong: <card label>, <card label>
last-misses (<YYYY-MM-DD>): <card label>, <card label>
```

## Rules

- **Serve from the bank.** Normal sessions pull saved cards — fast, no note-reading, no improvising. Generation is only a fallback for a thin bank.
- **Author deliberately.** New cards come in vetted batches via `add`, not mid-session. Show them to the user before saving; skip duplicates.
- **Source of truth is the vault.** Answers reflect the user's notes. If you add outside context while coaching, flag it as yours ("not in your note, but...").
- **One card per turn.** Ask, wait, then reveal. Never show the answer before the user attempts it.
- **Snappy is a feature.** After the one-time load, cards fly: one-line front, answer + one coaching line, next. If it feels stop-start or essay-ish, you're doing it wrong.
- **Weak-first.** Always lead with logged weak spots and recent misses.
- **Small by default.** ~5 cards. Short sessions, run often.
- **Encouraging and concrete.** Sharpen the user's phrasing for real use in conversation and writing.
