---
name: afk-setup
description: Register a repo in the AFK board registry (~/.claude/afk.json) so pickup, triage, and reviewer-pickup can resolve its tracker and board. Generates the per-repo entry idempotently with a script, resolving the repo path itself so it works on any machine (laptop, VPS). Use when a repo is not yet on the board ("this repo has no afk.json entry", "set up afk", "register this repo", /afk-setup), or it runs automatically as part of startup.
---

# AFK Setup

Register a repo in the **AFK board registry** so `pickup`, `triage`, and
`reviewer-pickup` can find its board. The registry is a single JSON file at
`$CLAUDE_CONFIG_DIR/afk.json` (default `~/.claude/afk.json`) that maps an
**absolute repo path** to that repo's board coordinates.

**It is per-machine and NOT source-controlled.** It keys on absolute paths, which
differ between your laptop and the VPS, so each machine generates its own with the
bundled script. That is why a freshly-cloned checkout (e.g. on the VPS) has no
entry: you generate it there.

## The schema
```json
{
  "repos": {
    "/abs/path/to/repo": {
      "tracker": "linear",
      "linear": { "team": "Engineering", "project": "Docket phase 1: ingest, feed, reader" },
      "readyStatus": "Ready for Agent",
      "humanStatus": "Ready for Human",
      "shipMode": "pr"
    }
  }
}
```
- `tracker`: `linear`, `github`, or any future tracker.
- Coordinates: `linear: { team, project }`, or `github: { repo: "owner/name", project? }`.
- `readyStatus` / `humanStatus`: the board's two triage-output columns (canonical
  `Ready for Agent` / `Ready for Human`). The other statuses (`Triage`, `In Review`,
  `Changes Requested`, `Done`) are matched by their canonical names verbatim.
- `shipMode`: `pr` (branch and open a PR) is the default.

## Generate the entry
Run the bundled script from the repo root (it resolves the path itself):

```bash
# Linear board (team + project required, cannot be inferred):
bash <path-to-this-skill>/scripts/init-afk.sh \
  --tracker linear --linear-team "Engineering" \
  --linear-project "Docket phase 1: ingest, feed, reader"

# GitHub board (owner/repo inferred from the origin remote):
bash <path-to-this-skill>/scripts/init-afk.sh --tracker github

# No flags: infer github from the origin remote, else it tells you what to pass.
bash <path-to-this-skill>/scripts/init-afk.sh
```

Defaults: `--ready "Ready for Agent"`, `--human "Ready for Human"`, `--ship pr`.
The script is **idempotent**: an existing entry is left untouched unless `--force`.
It edits the JSON with `node` (or `bun`), preserving every other repo's entry.

## Interactive use (/afk-setup)
When the maintainer runs `/afk-setup`, do the figuring-out, then call the script:
1. **Resolve the repo** (`git rev-parse --show-toplevel`). If it already has an
   entry, show it and stop unless they want to change it (`--force`).
2. **Determine the tracker.** If the origin remote is GitHub and they want GitHub
   issues/Projects, that is inferable. If it is a Linear board, you need the team
   and project: list them with the Linear MCP (`list_teams`, `list_projects`) and
   confirm with the maintainer, or just ask. Do not guess a Linear team/project.
3. **Confirm** the values (tracker, coordinates, statuses, ship mode), then run
   `init-afk.sh` with the resolved flags.
4. Read the file back and show the maintainer the entry you wrote.

## Pairs with
- `startup` calls this in its meta layer, so a new repo is registered as it is
  created (best-effort: it auto-registers a GitHub board from the origin remote; a
  Linear board is set up by running `/afk-setup` once the board exists).
- `pickup` / `triage` / `reviewer-pickup` read the entry this writes; if they find
  none, they point the user here.
