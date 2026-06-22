---
name: checklist
description: Run an investment idea through an explicit go/no-go screening checklist - the concrete questions every idea must answer (circle of competence, durability, moat, management, financials, valuation, pre-mortem, fit), forcing a reasoned answer to each rather than a gut call. A decision-support thinking tool, not financial advice. Complements /munger (the mental-model lattice). Use when the user invokes /checklist, says "run this through my investment checklist", "screen this stock/idea", "checklist this", or pastes a thesis/ticker and wants it screened against concrete go/no-go questions.
---

# Investment Checklist

Take an investment idea and run it through an explicit screening checklist: the concrete go/no-go questions every idea must clear before it earns capital. The point is **discipline, not insight** - to force a reasoned answer to each gate so nothing important is skipped because the story is exciting. This is a thinking tool to screen a thesis, **not financial advice**; never tell the user to buy or sell, surface the reasoning and a disposition.

The full question set lives in **`checklist.md`** (bundled next to this file). Read it at the start of every run. It is intentionally a growing list - when the user adds or refines questions, edit `checklist.md`, not this file.

**Relationship to `/munger`:** `/munger` runs the idea through the mental-model lattice to see "what pops". This skill runs the structured screen. They overlap on the four core filters; if the user wants the model lattice or an inversion-heavy read, point them at `/munger`. Here, work the gates in order.

## Workflow

### 1. Get the idea
Take the investment idea the user provides - a pasted thesis, a ticker, or a business description. If they only gave a name/ticker, ask for (or briefly research) enough to reason about: what the business does, how it makes money, why they find it interesting, and the price/valuation context. Don't run the checklist on a one-word prompt.

### 2. Load the checklist
Read `checklist.md` for the current question set, grouped by stage. Treat each item as a gate the idea must answer.

### 3. Work the gates in order
Go stage by stage. For each relevant question, record:
- **The question** it is answering.
- **The answer, with its reason.** A bare "yes"/"no" is not an answer; capture the *why*. Quote the specific fact in the idea it rests on.
- **Confidence / gap** - is this answered with evidence, or is it an assumption that still needs checking?

Be honest about unknowns. An unanswered gate is a gap to flag, not a pass to assume.

### 4. Mandatory pre-mortem
Do not skip stage 6 of the checklist. Write the bear case: "it is 5 years from now and this was a mistake, what happened?" Name the single points of failure and the disconfirming evidence the thesis is glossing over. Separately, flag the user's own likely biases (cross-check the `/munger` psychology list).

### 5. Disposition
Synthesize into one disposition, with reasons:
- **Go** - clears the gates; name the two or three things that most need to stay true.
- **No-go** - fails a gate that matters; name which and why.
- **Needs work** - promising but a key gate is unanswered; name what to investigate next.

Frame it as *thinking*, never a directive to trade.

## Rules
- **Not financial advice.** Output reasoning and a disposition, never a directive to buy or sell.
- **Every gate needs a reason.** "Yes" without a "why" is a fail; quote the concrete fact the answer rests on.
- **Flag gaps honestly.** An unanswered question is a gap to investigate, not a silent pass.
- **The pre-mortem is mandatory** (step 4), not optional.
- **`checklist.md` is the source of truth** for the questions - keep it growing there, not here.
