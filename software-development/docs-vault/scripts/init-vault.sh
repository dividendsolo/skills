#!/usr/bin/env bash
# init-vault.sh — scaffold an in-repo Obsidian knowledge vault at docs/vault/.
# Idempotent: never clobbers existing notes; safe to re-run. Run from a repo root,
# or pass the repo root as $1.
set -euo pipefail

ROOT="${1:-$(pwd)}"
VAULT="$ROOT/docs/vault"

mkdir -p \
  "$VAULT/architecture" \
  "$VAULT/domain" \
  "$VAULT/how-it-works" \
  "$VAULT/standards" \
  "$VAULT/decisions" \
  "$VAULT/gotchas"

# Keep empty category dirs tracked by git until notes land.
for d in architecture domain how-it-works standards decisions gotchas; do
  keep="$VAULT/$d/.gitkeep"
  [ -e "$keep" ] || : > "$keep"
done

INDEX="$VAULT/_index.md"
if [ ! -e "$INDEX" ]; then
  repo_name="$(basename "$ROOT")"
  cat > "$INDEX" <<EOF
---
title: $repo_name knowledge base
tags: [index]
updated: $(date +%F)
---

# $repo_name — knowledge base

Curated knowledge for this repo. Notes describe the code and link to it; they do
not copy it. Start here, then follow links.

Read this file first. Code is the source of truth; if a note disagrees with the
code, the code wins — fix the note.

## Map

- **architecture/** — how subsystems fit together
- **domain/** — domain model and ubiquitous language
- **how-it-works/** — walkthroughs of real flows
- **standards/** — conventions and patterns to follow here
- **decisions/** — decisions; link out to ../adr/* where they exist
- **gotchas/** — traps and pitfalls

## Notes

_(none yet — add links as notes are created)_
EOF
  echo "created $INDEX"
else
  echo "exists  $INDEX (left untouched)"
fi

echo "vault ready at $VAULT"
