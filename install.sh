#!/usr/bin/env bash
# install.sh: symlink every skill in this repo into BOTH the Hermes skills dir and
# the Claude Code skills dir so local edits are live. Idempotent and non-destructive:
# a pre-existing real (non-symlink) destination is left untouched and reported.
#
# Modes:
#   ./install.sh           link any MISSING skills, then wire up the post-merge hook
#                          so future `git pull`s self-heal. Quiet about already-linked
#                          skills; prints only what it changes.
#   ./install.sh --check   report drift WITHOUT changing anything. Exit 0 if every
#                          skill is linked, 1 if any link is missing. The post-merge
#                          hook uses this to decide whether to link.
#
# Override targets with HERMES_SKILLS_DIR / CLAUDE_SKILLS_DIR.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DEST="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills}"
CLAUDE_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

CHECK=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# status <src> <dest> -> echoes: ok | missing | real
#   ok      = symlink already points at src (nothing to do)
#   missing = no link there, or a stale link pointing elsewhere -> should be linked
#   real    = a real (non-symlink) path exists -> never touch it
status() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    [ "$(readlink "$dest")" = "$src" ] && echo ok || echo missing
  elif [ -e "$dest" ]; then
    echo real
  else
    echo missing
  fi
}

missing=0 linked=0 ok=0

shopt -s nullglob
for skill in "$REPO"/*/*/SKILL.md; do
  dir="$(dirname "$skill")"                 # <repo>/<category>/<skill>
  cat="$(basename "$(dirname "$dir")")"     # <category>
  name="$(basename "$dir")"                 # <skill>

  for pair in "hermes|$HERMES_DEST/$cat/$name" "claude|$CLAUDE_DEST/$name"; do
    label="${pair%%|*}"; dest="${pair#*|}"
    case "$(status "$dir" "$dest")" in
      ok) ok=$((ok + 1)) ;;
      real) echo "skip   $label $dest (real path exists; not overwriting)" ;;
      missing)
        missing=$((missing + 1))
        if [ "$CHECK" = 1 ]; then
          echo "MISSING $label $dest"
        else
          mkdir -p "$(dirname "$dest")"
          ln -sfn "$dir" "$dest"
          echo "link   $label $dest -> $dir"
          linked=$((linked + 1))
        fi
        ;;
    esac
  done
done

if [ "$CHECK" = 1 ]; then
  if [ "$missing" -gt 0 ]; then
    echo "drift: $missing skill link(s) missing on this machine. Run ./install.sh"
    exit 1
  fi
  echo "in sync: every skill is linked ($ok link(s))."
  exit 0
fi

# Wire up the post-merge hook so future pulls self-heal (per-machine, .git-local).
if [ -e "$REPO/.git" ] && [ -d "$REPO/.githooks" ]; then
  if [ "$(git -C "$REPO" config --local --get core.hooksPath 2>/dev/null || true)" != ".githooks" ]; then
    git -C "$REPO" config --local core.hooksPath .githooks
    echo "hook   set core.hooksPath=.githooks (future pulls self-heal)"
  fi
fi

if [ "$linked" -gt 0 ]; then
  echo "done: linked $linked new skill link(s); $ok already in sync."
else
  echo "done: all skills already in sync ($ok link(s))."
fi
