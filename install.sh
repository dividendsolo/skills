#!/usr/bin/env bash
# install.sh: symlink every skill in this repo into BOTH the Hermes skills dir and
# the Claude Code skills dir so local edits are live. Idempotent and non-destructive:
# a pre-existing real (non-symlink) destination is left untouched and reported.
#
# Also wires the landing-audit verify-nudge hook that lives beside its skill under
# marketing/landing-audit/hooks/*.sh: it symlinks it into ~/.claude/hooks and
# registers it in ~/.claude/settings.json, so the nudge travels to every machine
# (including the dev box) on the same sync path as the skills. Unlike skills, the
# repo is the source of truth for this hook, so a stale real hook file IS replaced
# with the symlink. Design-rules is intentionally NOT a hook: its rulebook is a DRY
# reference verified at audit time (landing-audit) and ship time (shipit). This
# script also strips any legacy design-rules hook a prior install left behind.
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

# --- UI-craft enforcement hooks -------------------------------------------------
# Symlink each hook script (beside its skill) into ~/.claude/hooks, then register
# it in ~/.claude/settings.json. Repo wins: a stale real hook file is replaced.
CLAUDE_BASE="$(dirname "$CLAUDE_DEST")"            # ~/.claude
HOOKS_DEST="$CLAUDE_BASE/hooks"
SETTINGS="$CLAUDE_BASE/settings.json"
HOOK_SCRIPTS=(
  "marketing/landing-audit/hooks/landing-audit-reminder.sh"
)
# Legacy hook from a prior install (design-rules is no longer a hook): remove its
# symlink so it stops firing. Idempotent — silent if already gone.
LEGACY_HOOK="$HOOKS_DEST/design-rules-reminder.sh"
if [ -L "$LEGACY_HOOK" ] || [ -e "$LEGACY_HOOK" ]; then
  if [ "$CHECK" = 1 ]; then
    echo "STALE  hook $LEGACY_HOOK (design-rules is no longer a hook; run ./install.sh)"
    missing=$((missing + 1))
  else
    rm -f "$LEGACY_HOOK"
    echo "unlink hook $LEGACY_HOOK (design-rules is no longer a hook)"
    linked=$((linked + 1))
  fi
fi
for rel in "${HOOK_SCRIPTS[@]}"; do
  src="$REPO/$rel"
  dest="$HOOKS_DEST/$(basename "$rel")"
  [ -f "$src" ] || continue
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok=$((ok + 1))
  else
    missing=$((missing + 1))
    if [ "$CHECK" = 1 ]; then
      echo "MISSING hook $dest"
    else
      mkdir -p "$HOOKS_DEST"
      ln -sfn "$src" "$dest"          # -f: repo is source of truth, replace stale files
      echo "link   hook $dest -> $src"
      linked=$((linked + 1))
    fi
  fi
done

# Register the landing-audit hook in settings.json (idempotent upsert keyed on
# command), and strip any legacy design-rules PreToolUse hook an older install wired.
LA_CMD="bash $HOOKS_DEST/landing-audit-reminder.sh"
settings_has() {  # event command -> 0 if a hook with that command is registered
  [ -f "$SETTINGS" ] || return 1
  jq -e --arg e "$1" --arg c "$2" \
    '[ .hooks[$e][]?.hooks[]?.command ] | index($c) != null' "$SETTINGS" >/dev/null 2>&1
}
settings_has_legacy_dr() {  # 0 if a stale design-rules hook is still registered
  [ -f "$SETTINGS" ] || return 1
  jq -e '[ .hooks.PreToolUse[]?.hooks[]?.command // empty ] | any(test("design-rules-reminder"))' \
    "$SETTINGS" >/dev/null 2>&1
}
if settings_has Stop "$LA_CMD" && ! settings_has_legacy_dr; then
  : # landing-audit registered and no stale design-rules hook
else
  missing=$((missing + 1))
  if [ "$CHECK" = 1 ]; then
    echo "MISSING hook registration in $SETTINGS"
  elif command -v jq >/dev/null 2>&1; then
    base='{}'; [ -f "$SETTINGS" ] && base="$(cat "$SETTINGS")"
    tmp="$(mktemp)"
    if printf '%s' "$base" | jq \
        --arg la "$LA_CMD" '
        def upsert(ev; entry; cmd):
          .hooks[ev] = (((.hooks[ev]) // [])
            | map(select(((.hooks // []) | any(.command == cmd)) | not)) + [entry]);
        .hooks = (.hooks // {})
        # Drop any legacy design-rules PreToolUse hook, then ensure landing-audit Stop.
        | .hooks.PreToolUse = [ (.hooks.PreToolUse // [])[]
            | select(((.hooks // []) | any(.command | test("design-rules-reminder"))) | not) ]
        | (if (.hooks.PreToolUse | length) == 0 then .hooks |= del(.PreToolUse) else . end)
        | upsert("Stop"; {hooks:[{type:"command", command:$la, timeout:10, statusMessage:"Checking for landing-page edits"}]}; $la)
        ' > "$tmp" && [ -s "$tmp" ]; then
      mv "$tmp" "$SETTINGS"
      echo "hook   registered landing-audit hook (stripped any legacy design-rules hook) in $SETTINGS"
      linked=$((linked + 1))
    else
      rm -f "$tmp"
      echo "warn   hook registration failed; $SETTINGS left unchanged"
    fi
  else
    echo "skip   hook registration ($SETTINGS): jq not found"
  fi
fi

if [ "$CHECK" = 1 ]; then
  if [ "$missing" -gt 0 ]; then
    echo "drift: $missing skill/hook item(s) missing on this machine. Run ./install.sh"
    exit 1
  fi
  echo "in sync: every skill linked and hooks wired ($ok item(s))."
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
