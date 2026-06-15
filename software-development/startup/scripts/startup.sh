#!/usr/bin/env bash
# startup.sh — make a repo agent-ready (idempotent meta layer). Run from the repo
# root, or pass it as $1. Safe to re-run; never clobbers existing file contents.
# Does NOT scaffold an app stack (that is gated/confirmed in the skill body).
set -euo pipefail

# Resolve this script's directory BEFORE changing into $ROOT, while BASH_SOURCE
# is still valid relative to the original cwd. Resolves symlinks via cd ... pwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT="${1:-$(pwd)}"
mkdir -p "$ROOT"
cd "$ROOT"
name="$(basename "$ROOT")"

# 1. git
if [ ! -d .git ]; then git init -q; echo "git init"; else echo "git: already a repo"; fi

# 2. AGENTS.md (only create if missing; never overwrite existing content)
if [ ! -e AGENTS.md ]; then
  cat > AGENTS.md <<EOF
# $name

<!-- one-line description of what $name is -->

**Stack:** TypeScript (strict), Bun (runtime + package manager), Next.js (App
Router), Supabase (Postgres + Auth), Drizzle + postgres-js, Tailwind v4 +
shadcn/ui, Biome, Vitest, Playwright. Deploy: Vercel (Fly.io for file/SQLite apps).
Override only when it does not make sense for this project.

## Commands

\`\`\`bash
bun dev
bun run typecheck
bun run lint
bun run test
bun run build
\`\`\`

## Conventions

- TDD: failing test first for behavior changes; colocated \`*.test.ts(x)\`.
- Named exports; server components by default.
- No em dashes in any copy, ever.
EOF
  echo "created AGENTS.md"
else
  echo "AGENTS.md: exists (left untouched)"
fi

# 3. CLAUDE.md -> imports AGENTS.md so Claude auto-loads it
if [ ! -e CLAUDE.md ]; then
  printf '@AGENTS.md\n' > CLAUDE.md
  echo "created CLAUDE.md (@AGENTS.md)"
else
  echo "CLAUDE.md: exists (left untouched)"
fi

# 4. .gitignore defaults
if [ ! -e .gitignore ]; then
  cat > .gitignore <<'EOF'
node_modules/
.next/
.env
.env.*
!.env.example
dist/
build/
*.log
.DS_Store
EOF
  echo "created .gitignore"
else
  echo ".gitignore: exists (left untouched)"
fi

# 5. vault (delegates to the docs-vault skill's scaffolder, resolved relative to
#    this script so it works wherever the skill is installed/symlinked)
VAULT_INIT="$SCRIPT_DIR/../../docs-vault/scripts/init-vault.sh"
if [ -f "$VAULT_INIT" ]; then
  bash "$VAULT_INIT" "$ROOT"
else
  echo "WARN: docs-vault init-vault.sh not found at $VAULT_INIT; skipping vault" >&2
fi

echo "startup: $name is agent-ready"
