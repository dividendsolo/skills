---
name: landing-audit
description: Audit a landing page / marketing homepage against Marc Lou's 31 viral-product principles plus a visual craft-and-interaction lens, returning a defensible score out of 100, six category meters, a prioritized punch-list of concrete fixes, and ready-to-paste rewrites. Works on a live URL or a locally running app (renders desktop + mobile screenshots and reads the source). Use when the user invokes /landing-audit, says "audit my landing page / homepage", "viral audit", "review the landing page", "how's my homepage / page", "why doesn't my page convert", or asks what to fix on a landing page.
---

# Landing Audit

Grade a landing page and hand back a scored, prioritized to-do list. The output is
**findings + a punch-list, not edits** — only change code if the user asks afterward.

Two rubrics, merged:
- **Scored core** = Marc Lou's **31 viral-product principles** (verbatim in [`31-principles.md`](31-principles.md)) → one reproducible number out of 100.
- **Unscored lens** = the **design-rules** rulebook (UI craft & feel: hierarchy, type, color, spacing, calm, micro-interactions, motion, load speed) — invoke the `design-rules` skill and grade the rendered page against it, reported alongside but kept out of the number. That skill is the single source of truth; this audit applies it, it does not restate it.

Detection tiers, the scoring formula, categories, and the report shape all live in
[`grading.md`](grading.md). Read it before grading.

## Workflow

1. **Resolve the target.** A live URL, or the project's homepage (Next.js App Router: `app/page.tsx` and the components it renders; else the framework's index route). For a local app, get it running — prefer the project's own launch path (a `run` skill or documented dev command, e.g. `bun dev` -> `localhost:3000`); reuse an already-running dev server.

2. **Render it.** Screenshots are non-negotiable (principles 2, 4, 5, 6, 10, 15, 20 and the whole craft lens need them). Use Playwright to capture **above-the-fold** and **full-page** at **desktop (1440x900)** and **mobile (390x844)**. Save to the project's own audit/screenshots folder if it has one, else a temp dir — never the project root.

3. **Extract signals.** Hero headline, all CTA texts, pricing section, footer, testimonial blocks, meta tags (`og:image`/`twitter:image`), color clusters, reading level, hedge-word hits, media embeds. For local apps, cite `file:line`.

4. **Grade all 31** against the verbatim principles, using the detection tier for each (see `grading.md`). Every principle gets exactly one verdict — pass / needs-work / fail — counts must sum to 31. Run the craft lens separately.

5. **Score + report.** Compute the score with the flat rubric in `grading.md` (pass=1, needs-work=0.5, fail=0, over 31; one decimal). Emit the full report shape from `grading.md`: verdict sentence, six category meters, the count line, punch-list (top 3-5), needs-work, passed, the unscored craft lens, and 3 rewrites.

## Rules

- **Audit, don't edit.** Findings + punch-list only; implement only if asked after.
- **Every verdict traces to `31-principles.md`** — Marc Lou's exact words, never a paraphrase. Quote his language where it sharpens the call.
- **The score is computed, never hand-typed**, and the counts sum to 31.
- **Precision over coverage** — a check you can't run reliably is needs-work / low-confidence, never a wrong confident verdict.
- **Always look at the rendered page** (desktop + mobile); never grade from source alone.
- Be specific and cite evidence (`file:line`, quoted copy, element counts) — no generic design platitudes.
- Offer to turn the punch-list into Todoist tasks or to start on the top items.
