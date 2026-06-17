# Repo-to-standard rubric, design

Date: 2026-06-17
Status: approved (brainstorm), pending implementation plan

## Purpose

One standard, two sides. The `startup` skill is the apply side: it creates the
standard artifacts when a repo is born. This rubric is the verify side: it
confirms `startup` was run, its outputs are present, and they have not drifted.
Both read the same canonical list, so they cannot disagree.

The goal the user set: account for everything being completed, and be able to
check it continually. So every item carries an observable check and a fix
pointer, the per-repo file records completion, and reviews reconcile it on every
entry into a repo.

## Artifacts

1. **Canonical standard: `STANDARD.md`, versioned (`v1`, `v2`, ...).** The single
   source of truth. It is bundled inside a small new skill,
   `software-development/repo-standard/`, rather than a loose doc. Reason: skills
   are symlinked into `~/.claude/skills`, so the standard is readable from inside
   any repo during a review. A loose doc in the skills working tree is not. The
   skill's `SKILL.md` is the short audit workflow; `STANDARD.md` is the bundled
   content; the skill is invokable as `/repo-standard`.

2. **Per-repo checklist: `docs/repo-standard.md`.** `startup` writes this into each
   repo: the core plus profile items as checkboxes, a `Standard: vN` stamp, and a
   per-item status of done, todo, or N/A with a reason. This is the living audit
   that travels with the repo.

3. **Audit workflow (`/repo-standard`).** Re-runs every check for the repo's
   profile, diffs against `docs/repo-standard.md` and the stamp, and reports each
   item as done, drifted, missing, or N/A.

## Versioning and drift

`STANDARD.md` carries a single integer version. A repo is out of sync if either:

- its stamp is behind the canonical version (the standard gained items it has not
  adopted), or
- a previously-checked item now fails (a regression).

The audit re-derives the expected item set from `STANDARD.md` for the repo's
profile, compares to the per-repo file plus reality, and prints the delta.

## Profiles (core plus add-ons)

Every repo meets CORE. Then exactly one profile adds items:

- **web-app**: Next.js or Vercel apps (docket, rep-sheet, pointy, portolio).
- **service / api**: backend services (fundamentals-api).
- **cli-tool / library**.
- **bot / automation**: manifesto-bot, reddit-marketing-agent, ralph-loop.
- **content / config**: dotfiles, the skills repo, docs-only. CORE-lite: most
  engineering and CI items are N/A by default.

`startup` records the chosen profile in `docs/repo-standard.md`.

## Item schema

Each rubric entry has: `id`, `title`, `why`, `check` (shell or observable),
`fix`, `applies` (core or which profile), and `source` (startup-auto vs
v1-manual). `source` is what makes completeness traceable: every item maps to
either a startup action or a known manual gap, so the per-repo file enumerates
everything a repo should have, nothing implicit.

## Rubric items (v1)

### CORE (every repo)

| id | item | check | source |
|---|---|---|---|
| C1 | `AGENTS.md` exists, description and Commands filled (no placeholders) | file exists, sections non-empty | startup scaffolds, prose manual |
| C2 | `CLAUDE.md` contains `@AGENTS.md` | grep for `@AGENTS.md` | startup-auto |
| C3 | Vault `docs/<repo>-vault/` with `_index.md`, and the vault block in `AGENTS.md` | dir and index exist | startup-auto |
| C4 | `.gitignore` present | file exists | startup-auto |
| C5 | `afk.json` registry entry resolves to a real board or project | entry present, tracker set | startup, finish via `/afk-setup` |
| C6 | No committed secrets, secrets read from env not code | scan, no `.env` tracked | manual |
| C7 | `.env.example` present if the repo uses env vars | file exists or N/A | manual |
| C8 | `docs/repo-standard.md` present and version-stamped | file exists, stamp parseable | startup-auto |
| C9 | `CONTEXT.md` glossary, once the domain is non-trivial (N/A for pure tools) | file exists or N/A with reason | startup offers via grill-with-docs |

### Profile: web-app, service, cli-tool, library (engineering and CI)

| id | item | check | source |
|---|---|---|---|
| E1 | Lint and format config (Biome) | `biome.json` present | v1-manual |
| E2 | Typecheck (tsc strict) | strict `tsconfig` plus a `typecheck` script | v1-manual |
| E3 | Test runner (Vitest) plus at least smoke tests | config plus one or more test files | v1-manual |
| E4 | Validation pipeline in AGENTS Commands, runs green (typecheck, lint, test, build) | commands present, optionally run | v1-manual |
| E5 | `docs/adr/` for non-trivial decisions | dir exists or N/A with reason | manual |
| CI1 | CI runs the validation pipeline on pushes or PRs | workflow file present | v1-manual (flagged) |
| CI2 | Integration mode declared and consistently followed | mode noted in AGENTS.md, honored | v1-manual (flagged) |

CI2 is mode-agnostic. The two valid modes are straight-to-main and branch plus
PR plus green-before-merge. The toggle lives in the `shipit` skill and the repo's
`AGENTS.md`, not in the rubric. The rubric only checks that the declared mode is
honored. This preserves the solo-dev straight-to-main default while letting repos
opt into a PR flow.

### Profile: bot / automation

| id | item | check | source |
|---|---|---|---|
| A1 | `LEARNINGS.md` present (AFK or pickup-enrolled repos) | file exists | reviewer flow creates |
| S1 | Input-safety notes or ADR where the repo handles external input (allowlists, SSRF) | ADR or AGENTS note present | manual |

### Profile: content / config

CORE-lite. C1 to C8 apply where sensible; C9 and all E and CI items are N/A by
default with a one-line reason.

## Integration

- **`startup` (apply):** after scaffolding, generate `docs/repo-standard.md` for
  the chosen profile from `STANDARD.md`, stamp the current version, and check off
  what startup just created.
- **reviews, `pickup`, `code-review` (verify):** read `docs/repo-standard.md`
  first, run `/repo-standard` to reconcile against the current `STANDARD.md`, and
  surface gaps. This is the hook that catches drift whenever we enter a repo.

## v1 scope boundaries

- CI1 and CI2 are verified and flagged, fixed by hand. `startup` does not yet
  scaffold CI or secrets hygiene; growing it to do so is a later task that keeps
  apply and verify aligned.
- The audit reports gaps. It does not auto-fix them in v1.

## Out of scope (future)

- Auto-remediation of gaps from the audit.
- A central rollup dashboard across all repos (the per-repo file is the source of
  truth for now).
- Expanding `startup` to scaffold CI and secrets hygiene so every item is
  startup-auto.

## Follow-on

Item H on the backlog (get all repos to standard) consumes this: run
`/repo-standard` per repo, then close the gaps. This design is the gate for H.
