#!/usr/bin/env bash
# init-vault.sh: scaffold an in-repo Obsidian knowledge vault at docs/<repo>-vault/.
# Idempotent: never clobbers existing notes; safe to re-run. Run from a repo root,
# or pass the repo root as $1.
set -euo pipefail

ROOT="${1:-$(pwd)}"
repo_name="$(basename "$ROOT")"
# Folder is named "<repo>-vault" so Obsidian shows the repo name in its vault
# picker / title bar instead of a generic "vault".
VAULT="$ROOT/docs/${repo_name}-vault"

ensure_agents_block() {
  local root="$1" vault="$2"          # vault = folder name, e.g. docket-vault
  local agents="$root/AGENTS.md"
  local begin="<!-- docs-vault:begin (managed by the docs-vault skill; edit the skill, not this block) -->"
  local end="<!-- docs-vault:end -->"
  local block
  block="$(cat <<EOF
$begin
## Knowledge vault

This repo has an Obsidian knowledge vault at \`docs/$vault/\`.

- Before exploring the code, read \`docs/$vault/_index.md\` and treat the vault
  as the first source of truth. Follow its links to the relevant code; only read
  code directly when the vault does not cover what you need.
- After completing a unit of work that is implemented, verified, and accepted,
  update the vault: add or revise notes for new findings, gotchas, standards, and
  decisions; add wikilinks and code links; update \`_index.md\`; bump \`updated:\`.
  Record only durable, verified knowledge, never speculation.
$end
EOF
)"
  if [ ! -e "$agents" ]; then
    printf '# %s\n\n%s\n' "$(basename "$root")" "$block" > "$agents"
    echo "created $agents with vault block"
  elif grep -qF "$begin" "$agents"; then
    local tmp replf; tmp="$(mktemp)"; replf="$(mktemp)"
    printf '%s\n' "$block" > "$replf"
    # Read the replacement block from a file (not a -v string) so BSD awk does
    # not choke on the embedded newlines. Replace everything between the begin
    # and end sentinels in place.
    awk -v b="$begin" -v e="$end" -v replf="$replf" '
      $0==b {while ((getline line < replf) > 0) print line; close(replf); skip=1; next}
      skip && $0==e {skip=0; next}
      !skip {print}
    ' "$agents" > "$tmp" && mv "$tmp" "$agents"
    rm -f "$replf"
    echo "updated vault block in $agents"
  else
    printf '\n%s\n' "$block" >> "$agents"
    echo "appended vault block to $agents"
  fi
}

# If the repo uses Biome, keep the knowledge vault out of its reach. The vault is
# prose, not code: a code formatter has no business reshaping notes, and Obsidian's
# .obsidian state is not source. The vault's own .gitignore already hides .obsidian
# from git; this excludes the tracked .md notes from linting/formatting too. The
# glob "!docs/*-vault" matches the "<repo>-vault" naming, so it survives renames.
# Idempotent; skips silently when there is no Biome config (e.g. a non-JS repo).
ensure_biome_excludes_vault() {
  local root="$1"
  local glob='!docs/*-vault'
  local cfg=""
  local f
  for f in biome.json biome.jsonc; do
    if [ -f "$root/$f" ]; then cfg="$root/$f"; break; fi
  done
  [ -n "$cfg" ] || return 0
  if grep -q 'docs/\*-vault' "$cfg"; then
    echo "exists  vault exclusion in $(basename "$cfg")"
    return 0
  fi
  if ! command -v bun >/dev/null 2>&1; then
    echo "  NOTE: Biome config present but bun not found; add \"$glob\" to files.includes in $(basename "$cfg") manually"
    return 0
  fi
  # Patch via a JSON parse/write (bails on JSONC with comments rather than
  # corrupting it), then re-apply the project's own Biome formatting.
  if CFG="$cfg" GLOB="$glob" bun -e '
    const fs = require("fs");
    const p = process.env.CFG, glob = process.env.GLOB;
    let cfg;
    try { cfg = JSON.parse(fs.readFileSync(p, "utf8")); } catch { process.exit(3); }
    cfg.files = cfg.files || {};
    const inc = Array.isArray(cfg.files.includes) ? cfg.files.includes : ["**"];
    if (!inc.includes(glob)) inc.push(glob);
    cfg.files.includes = inc;
    fs.writeFileSync(p, JSON.stringify(cfg, null, 2) + "\n");
  ' 2>/dev/null; then
    bunx @biomejs/biome format --write "$cfg" >/dev/null 2>&1 || true
    echo "added vault exclusion to $(basename "$cfg")"
  else
    echo "  NOTE: could not edit $(basename "$cfg") automatically (comments?); add \"$glob\" to files.includes"
  fi
}

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

# Obsidian writes per-machine UI state into .obsidian/ when the vault is opened.
# Keep it out of git so the vault stays portable as pure markdown.
GITIGNORE="$VAULT/.gitignore"
if [ ! -e "$GITIGNORE" ]; then
  printf '%s\n' '.obsidian/' > "$GITIGNORE"
  echo "created $GITIGNORE"
fi

INDEX="$VAULT/_index.md"
if [ ! -e "$INDEX" ]; then
  cat > "$INDEX" <<EOF
---
title: $repo_name knowledge base
tags: [index]
updated: $(date +%F)
---

# $repo_name knowledge base

Curated knowledge for this repo. Notes describe the code and link to it; they do
not copy it. Start here, then follow links.

Read this file first. Code is the source of truth; if a note disagrees with the
code, the code wins (fix the note).

## Map

- **architecture/**: how subsystems fit together
- **domain/**: domain model and ubiquitous language
- **how-it-works/**: walkthroughs of real flows
- **standards/**: conventions and patterns to follow here
- **decisions/**: decisions; link out to ../adr/* where they exist
- **gotchas/**: traps and pitfalls

## Notes

_(none yet; add links as notes are created)_
EOF
  echo "created $INDEX"
else
  echo "exists  $INDEX (left untouched)"
fi

ensure_agents_block "$ROOT" "$(basename "$VAULT")"
ensure_biome_excludes_vault "$ROOT"

echo "vault ready at $VAULT"
