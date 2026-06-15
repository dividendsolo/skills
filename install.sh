#!/usr/bin/env bash
# install.sh — symlink every skill in this repo into BOTH the Hermes skills dir
# and the Claude Code skills dir so local edits are live. Idempotent and
# non-destructive: a pre-existing real (non-symlink) destination is left untouched
# and reported, never clobbered.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DEST="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills}"
CLAUDE_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

link() {
  # link <source-dir> <dest-path> <label>
  local src="$1" dest="$2" label="$3"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "skip   $label $dest (real path exists; not overwriting)"
    return
  fi
  ln -sfn "$src" "$dest"
  echo "link   $label $dest -> $src"
}

shopt -s nullglob
linked=0
for skill in "$REPO"/*/*/SKILL.md; do
  dir="$(dirname "$skill")"                 # <repo>/<category>/<skill>
  cat="$(basename "$(dirname "$dir")")"     # <category>
  name="$(basename "$dir")"                 # <skill>

  mkdir -p "$HERMES_DEST/$cat"
  link "$dir" "$HERMES_DEST/$cat/$name" "hermes"

  mkdir -p "$CLAUDE_DEST"
  link "$dir" "$CLAUDE_DEST/$name" "claude"

  linked=$((linked + 1))
done
echo "done: processed $linked skill(s) into $HERMES_DEST and $CLAUDE_DEST"
