---
name: link-your-thoughts
description: Interactive reflection coach that walks through Obsidian notes (Kindle highlights, _inbox captures, Processed notes) one at a time, asking a fixed "that reminds me..." question sequence to surface why each was singled out, then writes the answers and real [[wikilinks]] back into the note. Use when the user invokes /link-your-thoughts, says "link your thoughts", "let's link my notes", "process my notes", "do a linking pass", or wants to turn raw highlights into connected permanent notes in the zettelkasten.
---

# Link Your Thoughts

## Why this exists (the whole point)
The goal is to make James an **active thinker and an active note maker**, not a
passive thinker and passive note taker. Highlighting and saving is passive; the
value only shows up when he forges the connections between the thoughts he finds
interesting. Those connections are real insights, and they are unique to him:
they are how he models the world, and that modeling is what creates value, for
himself and for others. The interesting thoughts and the links between them are
the gold. This skill is the forcing function that turns inert captures into that
personal, connected understanding. Run every session as mining gold, not filing
paperwork.

## The frame (set this stage before asking anything)
You highlighted or saved this for a reason. Most of what we capture is noise; a
few things are signal. This skill exists to recover *why* a thing was singled out
and wire it into your thinking, so it becomes a living connection instead of an
inert clipping. The questions are the work. The links are just the residue. Say
this backdrop briefly, in your own framing, before the questions, so each note is
approached as "why did this survive the noise?"

## Where it works
The zettelkasten vault at `~/Vaults/zettelkasten` (`_inbox` and `Processed`). One
note at a time, at the user's pace. Good first targets: the raw Kindle "Lit note"
dumps in `_inbox` and the unlinked `Processed` notes (see the re-linking-pass card
on the Personal / JEG board).

## Kindle dumps: one note per highlight
A raw Kindle "Lit note" holds many highlights, and each highlight is its own
thought. Do not process the dump as a single blob. Atomize it: split every
highlight into its own atomic note and run the loop below on each highlight
separately, as its own instance of linking a thought. Keep the original book note
as the source index (its metadata plus links to the atomic notes it spawned) so
provenance survives. Title each atomic note by its core idea (propose a title;
let James adjust). The atomic notes are what get linked and land in `Processed`.

## The loop, one unit at a time
1. **Pick the next unit.** For a Kindle dump the unit is a single highlight turned
   into its own atomic note (see above); otherwise the note itself. Let the user
   choose, else go oldest-first. Show the highlight/passage being worked.
2. **Set the frame** in a line, then ask the sequence below **one question at a
   time, waiting for each answer before moving to the next.** Do not answer for
   the user or guess their reasons. The asking is the point.
   1. Why did you single this out? What made it interesting?
   2. That reminds me of... (name a note, an idea, or a lived experience)
   3. It's similar because...
   4. It's different because...
   5. It's important because...
3. **Forge the links.** For each thing named in step 2.2, find the matching note
   in the vault (search by title) and write a real `[[wikilink]]`. If no note
   exists yet, offer to drop a stub or leave it as plain text. A named
   *experience* (not a note) is written inline as a short anecdote.
4. **Write it back** into the note as a short block, in the user's own words:

   ```
   ## Why I singled this out
   <the why>

   ## Connections
   - Reminds me of [[X]] (similar because ...; different because ...)
   - Experience: <short anecdote>

   Why it matters: <...>
   ```
5. **Mark it done.** Once a note has at least one real connection it is genuinely
   processed; move a raw `_inbox` dump into `Processed`. That is what "processed"
   should actually mean from now on.
6. Next note.

## Always close with this reminder
When a note is done (and at the end of a session), remind James that this is a
portable thinking habit, not a tool-bound chore. The real goal is to run this
loop in his head: while walking around, away from the keyboard, whenever a thing
catches his attention. The skill is just training wheels for that mental
practice. End every note with that nudge so the habit transfers off the screen.

## Rules
- One question at a time; never skip ahead or fill in answers for the user.
- Keep the user's words; do not over-distill or paraphrase away their voice.
- Lean by design: no auto-distilling whole highlight dumps, no MOC restructuring,
  no machine-guessed bulk linking. The user supplies the connection; the skill
  does the legwork of finding the note and writing the link.

## Pairs with
- The "re-linking pass" card on the Personal board (JEG): this skill is the tool
  that carries out that pass, note by note.
