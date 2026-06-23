---
name: design-rules
description: The hard rules of UI craft and feel. Every element must earn its place and do its one job well; the page must be tight, clean, calm, and genuinely pleasant to use. Use when building or editing ANY user-facing UI, page, screen, hero, or component, or when the user mentions design, layout, hierarchy, typography, color, spacing, contrast, CTAs, or micro-interactions. Build with this, then verify with landing-audit.
---

# Design Rules

Not negotiable. Invoke this skill and build to it EVERY time you create or edit any frontend / user-facing surface -- page, feature, component, element, color, button, navigation, micro-interaction -- and hold the work to it WHILE building, never as a cleanup pass afterward. This is a guardrail, not a checklist we follow sometimes. "Go off and build whatever, then come back and fix it later" is exactly what this prevents: it is too much work and too much to maintain. The only things out of scope are pure backend with no UI (the database and the API / server routes).

We are not generalists. The UI is specific to THIS product, and it earns "premium" by being minimal, tight, calm, and practically relevant to the user at all times -- not by adding more. Public-facing pages get the most scrutiny. We will make mistakes; we fix them by updating these rules, not by abandoning them.

This is about craft and feel, not marketing.

## Broken hierarchically

Fix with:
- Size
- Contrast
- Spacing

Make the most important thing the biggest, give it room.

## Fonts

Rules:
- 3 fonts max
  - Body
  - Content
  - Accents - this is an exception, try to keep it to 2

Readability bests personality.
Header font to express character.
Body font should almost be invisible.

## Color

3 colors max:
- primary brand color
- 1 neutral
- 1 accent cta, etc

60/30/10:
- 60 background/neutral
- 30 secondary
- 10 accent

3-5 intentional colors and stick with them only for all pages.

## Contrast

- Should be enough that screenreaders can pick it up.
- Cornerstone of accessibility.

## What makes your page look expensive

- Real photography
- Custom illustrations
- Branded graphics

Fine:
- Free stock images

The images can show how your product works or maybe the flow of how things work in your process.

Try to tell a story with the pictures about what your product offers without using words.

## Calm

- Give the content room to breathe.
- Try to be aggressively minimal.
- White space is your friend.

What makes people stay: it's clarity. Answer their one question: Is this for me?

## Hero (THE MOST IMPORTANT SECTION BY FAR!)

Hero needs to nail 3 things:
1. Headline tells a stranger exactly what you do, and why it matters to them, not cute or clever just clear.
2. Cta tells them what to do next.
3. A visual that reinforces the message instead of distracting from it.

Make sure to demonstrate the USP.

## Social proof

Formats that actually shift behavior are ones that tell a complete story:
- Before and after transformations
- Specific numbers attached to specific outcomes
- A video with a real person talks about the change they experienced

Placement matters as much as format. Proof at the bottom never gets seen. Weave it in throughout.

Can use ugc instead to see the product in action.

The higher you can get the social proof the better.

Every claim put social proof to demonstrate it works if possible.

Logo bar at the top?

## Every major section should be doing a job

- Addressing a specific fear
- Answering a specific objection
- Building confidence to take the next step

## CTA

Primary action button should be the single most visually prominent element on the page.

If 2 put main on left with more accent.

Each call to action should support and be relevant to the section in which it's placed instead of just using stock words like "Get Started" or "Buy Now" or whatever.

Structure sections so that clicking the CTA feels like the most natural next step. It's not about forcing them into clicking the CTA. It's about removing all the friction.

## Animation

Does the animation serve the experience or is it the experience - micro interactions are better.

Showing off is worse.

## Mobile

- No side by side layout
- No hover
- Navigation needs to collapse for a thumb
- Touch targets need to be large enough for average sized thumbs

## The key thing

Don't ask what do I want it to look like, ask what do I need it to do.

Answer the 3 objections visitors have before they buy.

Any design decision should start with a question. Does this help the right person take the right action? That's the key thing.

Every element needs to have a job and every element needs to do that job well. That's the key thing for design.

---

When the build is done, verify with the `landing-audit` skill.
