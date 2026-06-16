---
name: munger
description: Run an investment idea through Charlie Munger's latticework of mental models and surface which models "pop" — which fire for the idea, which fire against it, and what an inversion pass reveals. A decision-support thinking tool, not financial advice. Use when the user invokes /munger, says "run this idea through mental models", "munger check this", "what mental models apply to this investment", or pastes an investment thesis / ticker / business and asks which models fire.
---

# Munger — Mental Model Lattice

Take an investment idea and run it through Charlie Munger's multidisciplinary latticework. The goal is to **see what pops**: which mental models fire *for* the idea, which fire *against* it, and what blind spots an inversion pass exposes. This is a thinking tool to pressure-test a thesis — **not financial advice**; never tell the user to buy or sell, surface the reasoning.

The full model catalog lives in **`models.md`** (bundled next to this file). Read it at the start of every run. It is intentionally a growing list — when the user adds or refines models, edit `models.md`, not this file.

## Workflow

### 1. Get the idea
Take the investment idea the user provides — a pasted thesis, a ticker, or a business description. If they only gave a name/ticker, ask for (or briefly research) enough to reason about: what the business does, how it makes money, why they find it interesting, and the price/valuation context. Don't proceed on a one-word prompt.

### 2. Load the lattice
Read `models.md` for the current catalog of models (grouped by discipline). Treat it as the checklist to run the idea against — Munger's whole method is running every idea past a *checklist* of models rather than reaching for one.

### 3. Run the idea through the models — find what pops
For each model that is genuinely relevant, record:
- **Model** — name + the discipline it comes from.
- **Direction** — does it fire **for** the thesis, **against** it, or **reframe** it?
- **So what** — the specific, concrete read on *this* idea (not a textbook definition). Quote the part of the thesis it bears on.

Rank by how strongly each model fires. Surface the dominant few rather than listing all — "what pops" means signal, not a full sweep dump.

### 4. Inversion pass
Run Munger's "invert, always invert": **how does this idea fail?** What would have to be true for this to be a terrible investment? Name the disconfirming models and the bear case the thesis is glossing over. Separately, flag any **psychological misjudgment tendencies** (see the psychology section of `models.md`) that may be biasing the user's own thesis — e.g. commitment/consistency, social proof, deprival-superreaction.

### 5. Apply Munger's core filters
Explicitly check the four-filter screen:
1. **Circle of competence** — can this be understood well enough to judge?
2. **Durable competitive advantage** — is there a real moat, and is it widening or eroding?
3. **Able and honest management** — capital allocation, incentives, candour.
4. **Margin of safety / sensible price** — is the price demanding optimism, or leaving room to be wrong?

### 6. Verdict
Synthesize: which models dominate the picture, the two or three things that most need to be true, the biggest disconfirming risk, and what to investigate next. End with a disposition framed as *thinking* — "compelling on moat + price but hinges on X", "pass — outside circle of competence", "needs work — thesis leans on social proof" — never a buy/sell directive.

## Rules
- **Not financial advice.** Output reasoning and disposition, never a directive to trade.
- **Specific, not generic.** Every model that fires must be tied to a concrete fact in the idea — quote it. No textbook recitations.
- **Surface signal.** Rank and feature the models that pop hardest; don't dump the entire catalog.
- **Always invert.** The inversion + bias pass (step 4) is mandatory, not optional.
- The catalog in `models.md` is the source of truth for models — keep it growing there.
