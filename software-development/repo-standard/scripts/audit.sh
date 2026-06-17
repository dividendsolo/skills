#!/usr/bin/env bash
# Audit a repo against the repo-standard. Runs the deterministic checks and
# prints one line per item: PASS, FAIL, NA, or JUDGE (needs human or agent
# judgment). Also reports version drift between the repo stamp and STANDARD.md.
#
# Usage: audit.sh [repo-root]   (defaults to the current directory)
set -u

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
standard="$skill_dir/STANDARD.md"
repo="${1:-$PWD}"
cd "$repo" || { echo "no such repo: $repo" >&2; exit 2; }

std_ver="$(grep -E '^Version: [0-9]+$' "$standard" | grep -oE '[0-9]+' | head -1)"

say() { printf '%-5s %s\n' "$1" "$2"; }

# --- version / drift ---
if [ -f docs/repo-standard.md ]; then
  repo_ver="$(grep -oE 'Standard: v[0-9]+' docs/repo-standard.md | grep -oE '[0-9]+' | head -1)"
  profile="$(grep -oE '^Profile: .*' docs/repo-standard.md | sed 's/^Profile: //' | head -1)"
  if [ -n "$repo_ver" ] && [ "$repo_ver" -lt "$std_ver" ]; then
    say DRIFT "repo is on standard v$repo_ver, current is v$std_ver (reconcile)"
  fi
else
  profile=""
  say FAIL "C8 docs/repo-standard.md missing (run /startup or /repo-standard)"
fi
[ -n "$profile" ] && say INFO "profile: $profile"

ck() { # ck ID PASS-condition message
  local id="$1"; shift
  local msg="$1"; shift
  if "$@"; then say PASS "$id $msg"; else say FAIL "$id $msg"; fi
}

has() { [ -e "$1" ]; }
greps() { grep -qE "$1" "$2" 2>/dev/null; }

# --- CORE ---
ck C1 "AGENTS.md with Commands" bash -c '[ -f AGENTS.md ] && grep -qE "^##+ +Commands" AGENTS.md'
ck C2 "CLAUDE.md contains @AGENTS.md" bash -c 'grep -q "@AGENTS.md" CLAUDE.md 2>/dev/null'
ck C3 "vault with _index.md" bash -c 'ls -d docs/*-vault/_index.md >/dev/null 2>&1'
ck C4 ".gitignore present" has .gitignore
# C5 afk.json (entries are keyed by absolute repo path; fall back to basename)
repo_path="$PWD"
repo_name="$(basename "$PWD")"
if [ -f "$HOME/.claude/afk.json" ] && command -v jq >/dev/null 2>&1; then
  if jq -e --arg p "$repo_path" --arg r "$repo_name" '(.repos // .) as $m | ($m[$p] // $m[$r] // empty)' "$HOME/.claude/afk.json" >/dev/null 2>&1; then
    say PASS "C5 afk.json entry present"
  else
    say FAIL "C5 afk.json entry missing (run /afk-setup)"
  fi
else
  say JUDGE "C5 afk.json or jq unavailable, check by hand"
fi
# C6 no tracked .env
if git ls-files 2>/dev/null | grep -qE '(^|/)\.env$'; then
  say FAIL "C6 a .env file is tracked by git"
else
  say PASS "C6 no tracked .env"
fi
# C7 .env.example if env used
if grep -rqsE 'process\.env|import\.meta\.env|Deno\.env|os\.environ' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.py' . 2>/dev/null; then
  ck C7 ".env.example present (env vars used)" has .env.example
else
  say NA "C7 no env var usage detected"
fi
# C8 handled above
say JUDGE "C9 CONTEXT.md glossary (present? domain non-trivial?)"
[ -f CONTEXT.md ] || [ -f CONTEXT-MAP.md ] && say INFO "C9 CONTEXT.md exists"

# --- profile add-ons ---
case "$profile" in
  web-app|service|cli-tool)
    ck E1 "biome.json" has biome.json
    ck E2 "tsc strict + typecheck script" bash -c 'grep -q "\"strict\": *true" tsconfig*.json 2>/dev/null && grep -q "\"typecheck\"" package.json 2>/dev/null'
    ck E3 "vitest + a test file" bash -c '(ls vitest.config.* >/dev/null 2>&1 || grep -q vitest package.json 2>/dev/null) && (find . -path ./node_modules -prune -o \( -name "*.test.*" -o -name "*.spec.*" \) -print 2>/dev/null | grep -q .)'
    ck E4 "validation pipeline in AGENTS Commands" bash -c 'grep -qi typecheck AGENTS.md && grep -qi "\blint\b" AGENTS.md && grep -qi "\btest\b" AGENTS.md && grep -qi "\bbuild\b" AGENTS.md'
    ck E5 "docs/adr" has docs/adr
    ck CI1 "CI workflow present" bash -c 'ls .github/workflows/*.y*ml >/dev/null 2>&1'
    say JUDGE "CI2 integration mode declared in AGENTS.md and followed"
    ;;
  bot)
    ck A1 "LEARNINGS.md" has LEARNINGS.md
    say JUDGE "S1 input-safety note or ADR for external input"
    ;;
  content)
    say NA "profile content: E, CI, A, S items N/A by default"
    ;;
  "")
    say JUDGE "no profile set, run /startup or set Profile in docs/repo-standard.md"
    ;;
esac
