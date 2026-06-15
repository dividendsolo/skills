#!/usr/bin/env bash
# init-afk.sh: register a repo in the AFK board registry that pickup, triage, and
# reviewer-pickup read. The registry lives at $CLAUDE_CONFIG_DIR/afk.json (default
# ~/.claude/afk.json) and maps an ABSOLUTE repo path to that repo's board
# coordinates. It is per-machine (it keys on absolute paths), so it is NOT
# source-controlled: generate it on each machine (laptop, VPS) with this script.
#
# Idempotent: if this repo already has an entry it is left untouched unless --force.
# The repo path is resolved here (git toplevel), so the same command works anywhere.
#
# Usage:
#   bash init-afk.sh --tracker linear --linear-team TEAM --linear-project PROJECT
#   bash init-afk.sh --tracker github [--gh-project NAME]   # owner/repo from origin
#   bash init-afk.sh                                        # infer github from origin
# Options (defaults match the shared status vocabulary):
#   --root DIR         repo root (default: git toplevel of the current directory)
#   --ready STR        ready-for-agent status   (default "Ready for Agent")
#   --human STR        ready-for-human status   (default "Ready for Human")
#   --ship MODE        ship mode                (default "pr")
#   --force            overwrite an existing entry for this repo
set -euo pipefail

ROOT=""; TRACKER=""; LINEAR_TEAM=""; LINEAR_PROJECT=""; GH_PROJECT=""
READY="Ready for Agent"; HUMAN="Ready for Human"; SHIP="pr"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2;;
    --tracker) TRACKER="$2"; shift 2;;
    --linear-team) LINEAR_TEAM="$2"; shift 2;;
    --linear-project) LINEAR_PROJECT="$2"; shift 2;;
    --gh-project) GH_PROJECT="$2"; shift 2;;
    --ready) READY="$2"; shift 2;;
    --human) HUMAN="$2"; shift 2;;
    --ship) SHIP="$2"; shift 2;;
    --force) FORCE=1; shift;;
    -h|--help) sed -n '2,22p' "$0"; exit 0;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
done

# Resolve the repo root (must be an absolute path; it is the registry key).
if [ -z "$ROOT" ]; then ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"; fi
[ -n "$ROOT" ] || { echo "not a git repo and no --root given" >&2; exit 1; }

# Infer a GitHub owner/repo slug from the origin remote, if any.
ORIGIN="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
GH_SLUG=""
if printf '%s' "$ORIGIN" | grep -qi 'github\.com'; then
  GH_SLUG="$(printf '%s' "$ORIGIN" | sed -E 's#^.*github\.com[:/]+##; s#\.git$##; s#/$##')"
fi

# Default the tracker to github when an origin makes that unambiguous.
if [ -z "$TRACKER" ]; then
  if [ -n "$GH_SLUG" ]; then TRACKER="github"; else
    echo "could not infer a tracker (no github origin). Re-run with --tracker linear --linear-team TEAM --linear-project PROJECT" >&2
    exit 1
  fi
fi
if [ "$TRACKER" = "linear" ] && { [ -z "$LINEAR_TEAM" ] || [ -z "$LINEAR_PROJECT" ]; }; then
  echo "linear tracker needs --linear-team and --linear-project" >&2; exit 1
fi

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$CFG_DIR"
AFK="$CFG_DIR/afk.json"

# JSON is edited with whatever JS runtime is present (Claude Code ships node).
JS=""
for c in node bun; do if command -v "$c" >/dev/null 2>&1; then JS="$c"; break; fi; done
[ -n "$JS" ] || { echo "need node or bun on PATH to edit $AFK" >&2; exit 1; }

AFK_PATH="$AFK" ROOT="$ROOT" TRACKER="$TRACKER" LINEAR_TEAM="$LINEAR_TEAM" \
LINEAR_PROJECT="$LINEAR_PROJECT" GH_SLUG="$GH_SLUG" GH_PROJECT="$GH_PROJECT" \
READY="$READY" HUMAN="$HUMAN" SHIP="$SHIP" FORCE="$FORCE" "$JS" -e '
  const fs = require("fs");
  const p = process.env.AFK_PATH, root = process.env.ROOT;
  let cfg = { repos: {} };
  if (fs.existsSync(p)) {
    try { cfg = JSON.parse(fs.readFileSync(p, "utf8")); }
    catch (e) { console.error("existing " + p + " is not valid JSON; fix or move it first"); process.exit(1); }
  }
  cfg.repos = cfg.repos || {};
  if (cfg.repos[root] && process.env.FORCE !== "1") {
    console.log("exists  entry for " + root + " (use --force to overwrite)");
    process.exit(0);
  }
  const entry = { tracker: process.env.TRACKER };
  if (process.env.TRACKER === "linear") {
    entry.linear = { team: process.env.LINEAR_TEAM, project: process.env.LINEAR_PROJECT };
  } else if (process.env.TRACKER === "github") {
    entry.github = { repo: process.env.GH_SLUG };
    if (process.env.GH_PROJECT) entry.github.project = process.env.GH_PROJECT;
  }
  entry.readyStatus = process.env.READY;
  entry.humanStatus = process.env.HUMAN;
  entry.shipMode = process.env.SHIP;
  cfg.repos[root] = entry;
  fs.writeFileSync(p, JSON.stringify(cfg, null, 2) + "\n");
  console.log((cfg.repos[root] && process.env.FORCE === "1" ? "updated " : "added   ") + root + " (" + process.env.TRACKER + ") in " + p);
'
