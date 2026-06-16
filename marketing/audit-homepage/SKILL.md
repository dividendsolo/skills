---
name: audit-homepage
description: Audit the current project's homepage / marketing landing page against a fixed set of first-impression principles (engineer the first 15ms, declare war on cognitive load, micro-interactions) and return a prioritized punch-list of concrete fixes. Captures the page visually (desktop + mobile screenshots of the running app) and reads the source, then scores each principle and proposes specific changes. Use when the user invokes /audit-homepage, says "audit my homepage", "review the landing page", "how's my homepage", or asks what to fix on the homepage.
---

# Homepage Audit

Audit the project's homepage / marketing landing page against the principles below and hand back a prioritized, concrete to-do list of changes that would better fulfill them. The output is **suggestions and action items**, not edits — don't change code unless the user then asks.

These principles are visual and interaction-heavy, so a code-only read is not enough: **capture the page as a user sees it**, then judge.

## Principles (the rubric)

These are the user's marketing-homepage principles. Audit against every one. (Extend this list when the user adds new principles.)

### 1. Engineer the first impression — "the first 15 ms"
The feeling a visitor gets in the first moment is the product's first promise. Judge:
- **One dominant focal point** above the fold — the eye should land somewhere deliberate, not bounce.
- **Value prop legible in ~5 seconds** — does the headline answer *what this is / who it's for / why care*?
- **Intended feeling** — name the emotion the hero should evoke (speed? trust? premium? calm authority?) and judge whether the visual craft (type, spacing, contrast, imagery) actually delivers it.
- **Time-to-paint** — a slow hero literally ruins the first 15 ms. Check LCP / how fast the above-the-fold renders.

### 2. Declare war on cognitive load — clarity is the #1 goal
Every unit of thinking you impose is friction. Judge:
- **Competing CTAs** above the fold — ideally one primary action; count them.
- **Copy density** — scannable headline + subhead, or a wall of text?
- **Visual hierarchy** — do size/weight/colour tell the eye where to go next?
- **Decision points** — how many choices are forced on the user early.
- **Language** — plain and concrete vs jargon/abstraction.
- **Navigation** — simple, or a menu of escape hatches.

### 3. Micro-interactions
Small, responsive feedback that makes the page feel alive and crafted — without adding load. Judge:
- **Hover / focus states** on every interactive element.
- **Press / loading feedback** on buttons and forms.
- **Scroll-triggered reveals & transitions** — present, and is the easing tasteful?
- **Purposeful motion** — reinforces meaning vs gratuitous; respects `prefers-reduced-motion`.
- **Delight moments** that reinforce the brand.

## Workflow

### 1. Locate the homepage
Find the landing route (Next.js App Router: `app/page.tsx` and the components it renders; otherwise the framework's index route). Read the source and the components that make up the above-the-fold hero so the audit can cite specifics.

### 2. Capture it visually
Get the app running and screenshot the real page — this is non-negotiable for principles 1 and 3.
- Prefer the project's own launch path: if a `run` skill or documented dev command exists (e.g. `bun dev` → `localhost:3000`), use it. Reuse an already-running dev server if there is one.
- Use Playwright to navigate to `/` and capture: **above-the-fold** and **full-page**, at **desktop (1440px)** and **mobile (390px)**.
- Save to the project's own audit/screenshots folder if it has an established one, else a temp dir. Never save images at the project root.
- For micro-interactions, also note hover/focus by inspecting the source/CSS (screenshots are static).

### 3. Score each principle
For every principle, write:
- **Observation** — what the homepage currently does, with specifics (`file:line`, copy quotes, element counts).
- **Verdict** — strong / partial / gap.
- **Fixes** — concrete, specific changes (not "improve hierarchy" but "the hero has two equal-weight buttons; demote 'Learn more' to a text link so the primary CTA wins").

### 4. Deliver a prioritized punch-list
End with a single ranked to-do list — highest-leverage first — of the changes needed to fulfil the principles. Each item: what to change, which file/section, and which principle it serves. Offer to turn the list into Todoist tasks or to start implementing the top items.

## Rules
- **Audit, don't edit.** Produce findings + a punch-list; only make changes if the user asks afterward.
- **Look at the rendered page** — always screenshot; never audit from source alone.
- Be specific and cite evidence (`file:line`, copy quotes, element counts) — no generic design platitudes.
- Check desktop **and** mobile; the first impression differs on each.
- Keep the rubric in sync with the user's principles; add new ones when they appear.
