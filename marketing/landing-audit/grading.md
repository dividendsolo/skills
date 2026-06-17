# Grading reference

The scored core is Marc Lou's 31 principles (verbatim in [`31-principles.md`](31-principles.md)).
Every verdict must trace to that file, not a paraphrase. Adapted from the
viral-audit product build spec.

## Detection tiers — how to judge each principle

Judge from what you rendered + extracted. Each principle falls in a bucket:

- **AUTO** — deterministic from DOM/CSS/meta. High confidence.
- **NLP** — text metric (reading level, word counts, hedge-word dictionary). High confidence.
- **COPY** — judgment over the extracted copy. Medium confidence.
- **VISION** — judgment over the screenshots. Medium confidence.
- **HARD** — needs context not on the page (competitor prices, trends, the signup flow). Grade it anyway, tag **low-confidence**.

| # | Principle | Bucket | How to call it |
|---|---|---|---|
| 1 | No free plan | COPY | Pricing text: any Free/$0 tier? (free *trial* != free *plan*) |
| 2 | Three colors | VISION/AUTO | Cluster non-neutral hues (ignore black/white/grey). Fail if >1 dominant hue family; warn at 2 |
| 3 | Numbers over adjectives | COPY | Ratio of quantified claims vs vague adjectives; list each vague one + a numeric rewrite |
| 4 | Shareable footer | VISION | Last viewport: share links / badge / stat card / repeated CTA? Fail if only legal + sitemap |
| 5 | OG image as thumbnail | AUTO+VISION | Read `og:image`/`twitter:image`. Fail if absent/404; warn if <1200x630 or reused logo. Stop-the-scroll? = vision |
| 6 | One idea per screen | VISION | Each viewport segment pushes one idea, or crams three? |
| 7 | Fifth-grader copy | NLP | Flesch-Kincaid on hero+body. Pass <=6, warn 7-9, fail >=10. Quote 3 worst sentences |
| 8 | Hard paywall | HARD | "no credit card required" = anti-signal; CTA -> checkout = positive. Tag low-confidence |
| 9 | Unique copy | COPY | Lived experience, or template any competitor could paste? |
| 10 | Show before tell | AUTO+VISION | Video/GIF/interactive demo in first 2 viewports, and is it a real product demo not stock art? |
| 11 | One thing | COPY | One problem/solution, or Swiss-Army sprawl? |
| 12 | Popcorn pricing | COPY | Tier count + Good/Better/Best. A single one-time price for a simple product is fine (see #27) |
| 13 | Ride a wave | HARD | Trending tech/topic mentions. Tag low-confidence |
| 14 | Customer-sourced copy | COPY | Sounds like customers talk, or corporate jargon? |
| 15 | Visible founder | VISION | Human face, founder signature, personal voice, screen-recording anywhere? |
| 16 | Prominent pricing | AUTO | Pricing link in header/nav, and/or a pricing section within ~3 viewports |
| 17 | Memorable headline | COPY | Proxy: concreteness, specificity, surprise. Honest medium confidence |
| 18 | Emotional headline | COPY | Triggers a feeling (humor/surprise/relief), or just states a feature? |
| 19 | Novel approach | HARD/COPY | Signals anything new vs "another X clone"? Low confidence; frame as a question |
| 20 | Hero sufficiency | VISION | Above-fold (desktop + mobile): headline + subhead + CTA + visual all in fold, and does it make the case? Mobile fold counts double |
| 21 | Empathy first | COPY | Names the user's pain *before* pitching the solution? |
| 22 | Single CTA | AUTO | Distinct primary actions in hero (same label repeated = one). Fail if >=3, warn at 2 |
| 23 | Memorable name | COPY | Real words, pronounceable, no forced wordplay/neologism needing explanation |
| 24 | Human desire | COPY | Sells money/time/health/status/pain-relief, or lists features? |
| 25 | Play before pay | AUTO | Usable element before any paywall (demo, widget, free-tool input, video)? Warn if all behind "Sign up to see" |
| 26 | No weak words | NLP | Scan for hedges (most, many, some, often, usually, rarely, virtually, almost). Report each + a definitive rewrite |
| 27 | No subscription | COPY | "/month" vs one-time. Flag a sub with no operational justification |
| 28 | Specific CTAs | AUTO+COPY | Flag generic buttons (Get Started, Sign Up, Learn More, Submit, Try Now). Propose the action-specific replacement |
| 29 | Testimonials | AUTO | Social-proof block: quotes, avatar+name, stars, logo wall, embedded tweets. Fail if none |
| 30 | Ten-word pitch | NLP | Extract `<h1>`/hero headline; count words. Pass <=10, fail >14 |
| 31 | Premium pricing | HARD | We don't know competitor prices. Surface the price + the principle, ask the founder. Tag low-confidence |

If a check genuinely can't be run from what you have, mark it **needs-work /
low-confidence** rather than emitting a wrong confident verdict. Precision over coverage.

## Score (reproducible, never hand-typed)

Flat rubric average over all 31. Every principle gets exactly one verdict:

- pass = 1, needs-work = 0.5, fail = 0
- `score = round((passed*1 + needsWork*0.5) / 31 * 1000) / 10`  (one decimal, out of 100)
- The three counts MUST sum to 31. No "advisory / not scored" bucket — HARD items are graded too, just tagged low-confidence.

State the count line: e.g. `31 checks - 18 passed - 7 need work - 6 failed`.

## Categories (directional meters, 0-100)

Group the report into these six. Set each meter from how its members scored:

- **First impression** — 20, 22, 30, 17, 18, 5
- **Clarity** — 7, 11, 26, 3, 6
- **Trust** — 29, 15, 9, 14
- **Pricing** — 1, 12, 16, 27, 31, 8
- **Shareability** — 4, 19, 23, 25
- **Show, don't tell** — 10, 21, 24

## Craft & interaction lens (reported, NOT scored)

These come from the homepage-craft rubric. They overlap the 31 in places
(focal point ~ #20, value-prop-in-5s ~ #30, competing CTAs ~ #22, plain language ~ #7) —
don't double-count those. Report only the genuinely additive items separately,
and keep them OUT of the numeric score (we don't fold in what the 31 don't measure):

- **Micro-interactions** — hover/focus states on every interactive element; press/loading feedback on buttons + forms; scroll-triggered reveals with tasteful easing; motion that reinforces meaning vs gratuitous; respects `prefers-reduced-motion`. Inspect source/CSS (screenshots are static).
- **Time-to-paint / LCP** — a slow hero ruins the first 15ms. Note how fast above-the-fold renders.
- **Intended feeling** — name the emotion the hero should evoke (speed? trust? premium? calm authority?) and judge whether type/spacing/contrast/imagery actually deliver it.

## Report shape

1. **Verdict** — stamped score (e.g. 64.2/100) + one honest human sentence ("Your hero earns the click; your pricing loses it.").
2. **Category meters** — the six above.
3. **The count line** — `31 checks - X passed - Y need work - Z failed`.
4. **Punch-list** — top 3-5 fixes by impact, each: `{rule #, name, evidence (quoted copy / cropped screenshot / element count, with file:line for local apps), exact fix with an example}`.
5. **Needs-work** — each with a one-line note; tag low-confidence where the answer isn't fully on the page.
6. **Passed** — short "don't break these" list.
7. **Craft & interaction** — the unscored lens above.
8. **Rewrites** — 3 ready-to-paste headline/CTA alternatives, each with a one-line why.
