#!/usr/bin/env bash
# install.sh — symlink every skill in this repo into the Hermes skills dir so
# local edits are live (the worker picks up changes immediately). Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills}"

shopt -s nullglob
linked=0
for skill in "$REPO"/*/*/SKILL.md; do
  dir="$(dirname "$skill")"                 # <repo>/<category>/<skill>
  cat="$(basename "$(dirname "$dir")")"     # <category>
  name="$(basename "$dir")"                 # <skill>
  mkdir -p "$DEST/$cat"
  ln -sfn "$dir" "$DEST/$cat/$name"
  echo "linked $cat/$name -> $dir"
  linked=$((linked + 1))
done
echo "done: $linked skill(s) linked into $DEST"
