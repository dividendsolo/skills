# Repo onboarding: get every working repo on the same playing field

**Goal:** bring all active repos up to the standard `docket` already meets, so the
triage / pickup / reviewer-pickup loop and the shared tooling work the same
everywhere. Created 2026-06-15.

`docket` is the reference implementation. Everything below is "make repo X look
like docket" plus the per-machine wiring.

## The standard (what "same playing field" means)

Per repo, idempotent where possible:

1. **git + agent files**: `git init`, `AGENTS.md` (stack + commands + conventions),
   `CLAUDE.md` containing `@AGENTS.md`, `.gitignore` defaults.
2. **Knowledge vault**: `docs/<repo>-vault/` plus the read-first / write-after block
   in `AGENTS.md` (via `docs-vault`).
3. **Biome vault exclusion**: if the repo uses Biome, `biome.json` `files.includes`
   carries `!docs/*-vault` (vault notes are prose, never linted). `init-vault.sh`
   adds this.
4. **No-em-dash gate**: `scripts/no-em-dash.sh` plus a test that greps tracked files,
   matching docket. (STRICT house rule: no em dashes in any copy.)
5. **LEARNINGS.md** at repo root (reviewer-owned, workers read only). Seed empty for
   any repo that will run the AFK loop.
6. **AFK registry entry**: `init-afk.sh` writes the per-repo entry into this
   machine's `~/.claude/afk.json`. GitHub boards are inferred from the origin
   remote; Linear boards need `--linear-team` and `--linear-project`. Per machine,
   so repeat on laptop and VPS.
7. **Board shape**: the repo's tracker uses the shared status vocabulary (`Triage`,
   `Ready for Agent`, `Ready for Human`, `In Progress`, `In Review`,
   `Changes Requested`, `Done`), the category labels
   (bug / enhancement / security / tech-debt / documentation / research), and the
   native priority field. Linear statuses cannot be created via MCP, so this step is
   manual in the Linear UI.
8. **Per machine, once**: run `./install.sh` from the skills checkout (links skills
   and arms the self-healing post-merge hook). After that, `git pull` keeps the
   machine in sync.
9. **Optional (autonomous repos only)**: add the repo to the VPS ralph cron rotation
   that drives pickup / reviewer-pickup every ~5 min.

## Step 0: decide what is in scope

Not every directory under `~/Developer/repos` is a working repo. Many are dead
experiments and should be skipped or archived, not onboarded. Mark each one before
doing any work. As of 2026-06-15 the candidates are below (state column is the quick
probe: git / AGENTS.md / vault / LEARNINGS.md / biome.json present).

| Repo | Current state | In scope? | Tracker | Notes |
|---|---|---|---|---|
| docket | git AGENTS vault LEARN biome | DONE (reference) | Linear | the standard |
| recall | git AGENTS | ? | ? | RAG MVP, client work |
| fieldlog | git AGENTS | ? | ? | dispatch console MVP |
| mission-control | git AGENTS | ? | ? | ADRs / strategy home |
| dividend-solo | git AGENTS biome | ? | ? | |
| echo-form | git AGENTS biome | ? | ? | |
| portolio | git AGENTS biome | frozen | ? | superseded by docket |
| rep-sheet | git AGENTS biome | ? | ? | |
| reddit-marketing-agent | git AGENTS biome | ? | ? | |
| zero-phase | git AGENTS biome | ? | ? | |
| pointy | git AGENTS | ? | ? | |
| viral-audit | git AGENTS | ? | ? | |
| fundamentals-api | git biome | ? | ? | SEC numbers source |
| browser-harness | git AGENTS | tooling | n/a | global skill, maybe exempt |
| ralph-loop | git | ? | ? | the loop runner itself |
| lookout, darndest, dmarc-reader, manifesto-bot, vercel-discord-bridge | git, sparse | ? | ? | |
| ai, brecka-timer, practice | not git / scratch | likely skip | n/a | experiments |
| dotfiles, skills | infra (not loop targets) | n/a | n/a | skills is the toolbox |

James fills the "In scope?" and "Tracker" columns; only in-scope repos get the full
treatment.

## Automation: how far startup.sh gets us

`startup.sh <repo-root>` already does steps 1, 2, 3, and 6 (GitHub-inferred)
idempotently on any existing repo. So the bulk is:

```bash
# from the skills checkout, for each in-scope repo:
bash software-development/startup/scripts/startup.sh /Users/james/Developer/repos/<repo>
```

What that does NOT cover, and why (the manual / judgment steps):

- **Linear AFK entry** (step 6): needs team + project, which cannot be inferred. Run
  `init-afk.sh --tracker linear --linear-team ... --linear-project ...` per Linear
  repo, or `/afk-setup` interactively.
- **Board shape** (step 7): creating Linear statuses / labels / priority is manual UI
  work. Reviewer + triage skills assume the vocabulary exists.
- **No-em-dash gate** (step 4): not yet in startup. Either copy
  `scripts/no-em-dash.sh` + the test from docket, or (better) add it to startup as a
  pinned-stack gate so future repos get it for free. See "Possible follow-up" below.
- **LEARNINGS.md seed** (step 5): trivial, but only for loop repos.
- **VPS cron** (step 9): manual rotation edit on the box.

### Possible follow-up (worth building once the list is set)

- An `onboard.sh <repo>` in the skills repo that chains: `startup.sh`, a
  no-em-dash-gate installer, a `LEARNINGS.md` seed, and a guided `init-afk.sh`. Then
  onboarding a repo is one command plus the manual board setup.
- Fold the no-em-dash gate into `startup` so it is part of the pinned stack, the same
  way the vault and afk registry already are.

## Suggested order

1. James marks the in-scope repos and their trackers (step 0 table).
2. For each in-scope repo: run `startup.sh` (steps 1, 2, 3, 6-GitHub).
3. Add the no-em-dash gate and `LEARNINGS.md` where missing (steps 4, 5).
4. Set up the board vocabulary / labels / priority per tracker (step 7).
5. Register Linear repos in `afk.json` with explicit team/project (step 6).
6. Run `./install.sh` on the VPS (step 8); add loop repos to the cron (step 9).
7. Spot-check each with `/triage` or `/pickup` to confirm the loop resolves the board.
