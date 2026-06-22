---
name: checklist
description: Interview the user through their OWN investment screening checklist - you ASK the questions one at a time and the USER answers and clears each gate; the tool never answers, never invents questions, and never checks a gate off. The questions are James's own and live in his Obsidian vault (the source of truth); ask exactly what is there. A decision-support thinking tool, not financial advice. Complements /munger. Use when the user invokes /checklist, says "run this through my investment checklist", "screen this idea", "checklist this", or pastes a thesis/ticker to be screened.
---

# Investment Checklist

Interview the user through their own investment screening checklist for an idea. **You ask the questions; the user answers them.** The purpose is to test whether the *user* understands the business, so you never answer a gate, never invent or pad questions, and never check a gate off yourself. It is their checklist; you hold it up and ask. This is a thinking tool, **not financial advice**; never tell the user to buy or sell.

**The questions are the user's own and live in the vault, the single source of truth:**

> `~/Vaults/zettelkasten/Investing checklist.md`

Read that note at the start of every run and ask **exactly** what is there, in its order, in its sections. The user maintains and grows it as they refine their process - **you never author, reword, or add questions to it.** If you think of a question that is not there, that is not yours to add; at most suggest it to the user as a possible addition for *them* to decide on.

**Relationship to `/munger`:** `/munger` runs the idea through the mental-model lattice and does the reasoning. This skill is the opposite stance: a structured self-quiz where the *user* does the reasoning, gate by gate, against their own list.

## How to run it (interactive interview)

You are the interviewer and scorekeeper, **not the analyst**. The user does the thinking.

### 1. Get the idea
Take the idea the user names - a thesis, a ticker, or a business. If they gave only a ticker, establish enough shared context to know what is being screened (and look up a fact if they ask), but you still do **not** answer the gates.

### 2. Load the checklist
Read the user's note at `~/Vaults/zettelkasten/Investing checklist.md`. Use its sections and questions verbatim. Ask only what the note contains; do not supplement it with questions of your own.

### 3. Ask the questions ONE AT A TIME, in order
- Ask a **single** question from the note, then **stop and wait**. Never batch. Never move on until they have answered.
- When they answer:
  - If it is a bare yes/no with no reason, **push once**: ask for the *why*. A reason is the bar; "yes" without one does not clear the gate.
  - Reflect their answer back in a line, and mark the question **cleared** or **flagged as a gap** based on *their* answer, not your opinion.
  - You may supply a **fact** they ask for (a price, a figure, a definition), never the **judgement**.
- Do not inject your own analysis. If you think they missed something, ask a **follow-up question** - never state the answer.

### 4. Close
Play back the questions they cleared and any gaps they flagged, then ask **them** for the disposition - **In**, **Out**, or **Too hard** - and why. The call is the user's. Not financial advice.
- **In** - a business they want to own at a reasonable price or better.
- **Out** - not a business they want to own.
- **Too hard** - cannot judge it confidently; set it aside rather than force a call.

If the user wants a record of the run, write a dated audit note (question, their verbatim answer, any evidence pulled, per-gate verdict, and the overall In/Out/Too hard call) into the appropriate folder.

## Rules
- **The user answers; you ask.** Never answer a gate, never pre-fill analysis, never check a gate off.
- **Only the vault's questions.** Ask exactly what is in `~/Vaults/zettelkasten/Investing checklist.md`; never invent, reword, or pad. New questions are the user's to add there.
- **A reason is the bar.** If an answer has no "why", push once for it; "yes" alone does not clear a gate.
- **One question at a time.** Ask, then wait.
- **Facts on request, never judgement.** Look up a number if asked; the reasoning stays the user's.
