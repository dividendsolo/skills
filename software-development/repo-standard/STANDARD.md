# Repo Standard

Version: 3

The canonical list of what a repo must have to be "to standard". The `startup`
skill applies these; the `repo-standard` skill verifies them. Every repo meets
CORE; then exactly one profile adds items. Bump `Version` above whenever an item
is added, removed, or materially changed, so per-repo stamps can detect drift.

Status vocabulary for a repo's checklist: done, todo, or N/A (with a one-line
reason). Counts toward "complete" only when every applicable item is done.

## Profiles

- web-app: Next.js or Vercel apps
- service: backend services and APIs
- cli-tool: CLIs and libraries
- bot: bots and automation workers
- content: dotfiles, docs-only, and skill repos (CORE-lite)

## CORE (every repo)

- C1 AGENTS.md exists, with a filled description and a Commands section (no placeholders).
  check: AGENTS.md exists and contains a "## Commands" heading.
  fix: run /startup, then write the description and Commands.
- C2 CLAUDE.md contains `@AGENTS.md`.
  check: grep `@AGENTS.md` CLAUDE.md.
  fix: create CLAUDE.md containing the single line `@AGENTS.md`.
- C3 Knowledge vault docs/<repo>-vault/ with _index.md, plus the vault block in AGENTS.md.
  Where Obsidian is installed, its registry must point at the vault's real path:
  a moved/renamed repo leaves a stale entry and the vault fails to open.
  check: a docs/*-vault directory with _index.md exists; AGENTS.md has the
  "## Knowledge vault" block; and if obsidian.json is present, no same-named vault
  is registered at a path that no longer exists.
  fix: run the docs-vault skill (startup does this); repoint the stale path in
  obsidian.json (~/Library/Application Support/obsidian on macOS,
  ~/.config/obsidian on Linux), or reopen the folder as a vault in Obsidian.
- C4 .gitignore present.
  check: .gitignore exists.
  fix: add .gitignore (startup does this).
- C5 afk.json registry entry resolves to a real board or project.
  check: ~/.claude/afk.json has an entry for this repo with a tracker.
  fix: run /afk-setup.
- C6 No committed secrets; secrets read from env, not code.
  check: no tracked .env file; no obvious secret literals.
  fix: remove the secret, rotate it, move it to env.
- C7 .env.example present if the repo reads env vars.
  check: if code references env vars, .env.example exists.
  fix: add .env.example listing required keys with placeholder values.
- C8 docs/repo-standard.md present and version-stamped.
  check: docs/repo-standard.md exists with a parseable "Standard: vN" line.
  fix: run /startup, or /repo-standard to generate it.
- C9 CONTEXT.md glossary, once the domain is non-trivial (N/A for pure tools).
  The glossary is the output of a grill-with-docs session, so it records that
  provenance: this proves a grill happened rather than the glossary being
  hand-written or agent-invented, and lets the audit confirm it.
  check: CONTEXT.md or CONTEXT-MAP.md exists and mentions "grill-with-docs" as its
  provenance, else N/A with reason.
  fix: run /grill-with-docs (it stamps the marker); if already grilled, add the
  marker, e.g. an HTML comment naming grill-with-docs.

## Profile add-ons

### web-app, service, cli-tool (engineering and CI)

The audit only confirms these are present and configured. It never executes the
validation pipeline (typecheck, lint, test, build) or any other heavy command.
Running them is CI's job; the audit just checks the repo is wired up to run them.

- E1 Lint and format config (Biome), with the knowledge vault excluded.
  check: biome.json exists; and if a docs/*-vault exists, files.includes contains
  "!docs/*-vault" so the vault prose is never linted or formatted.
  fix: bunx @biomejs/biome init; the docs-vault skill adds the vault exclusion.
- E2 Typecheck (tsc strict) with a typecheck script.
  check: tsconfig has strict true and package.json has a typecheck script.
  fix: enable strict, add "typecheck": "tsc --noEmit".
- E3 Test runner (Vitest) plus at least one test.
  check: a vitest config or dep exists and at least one *.test.* or *.spec.* file exists.
  fix: add vitest and a smoke test.
- E4 Validation commands documented in AGENTS Commands.
  check: AGENTS.md Commands lists typecheck, lint, test, build (presence only).
  fix: document the commands in AGENTS.md. The audit never runs them; CI does.
- E5 docs/adr/ for non-trivial decisions.
  check: docs/adr exists, else N/A with reason.
  fix: add docs/adr and record the first decision.
- CI1 CI workflow file exists.
  check: a .github/workflows/*.yml (or equivalent) is present. The audit confirms
  the file exists; it does not run CI.
  fix: add a CI workflow that runs the validation pipeline on pushes or PRs.
- CI2 Git workflow documented in AGENTS.md.
  check: AGENTS.md states the integration mode (straight-to-main, or branch + PR +
  merge after CI is green). [judge]
  fix: state the mode in AGENTS.md; the shipit skill toggle enforces it, not this.

### bot

- A1 LEARNINGS.md present (AFK or pickup-enrolled repos).
  check: LEARNINGS.md exists.
  fix: the reviewer-pickup flow creates it from review kickbacks.
- S1 Input-safety notes or ADR where the repo handles external input.
  check: an ADR or AGENTS note covers allowlists, SSRF, or similar. [judge]
  fix: add the note or ADR.

### content

CORE-lite. Apply C1 to C8 where sensible. C9 and all E, CI, A, S items are N/A by
default with a one-line reason.
