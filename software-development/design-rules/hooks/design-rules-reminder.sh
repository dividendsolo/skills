#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit). Reminds that the design-rules skill is a
# STRICT, build-time guardrail whenever a FRONTEND file is being edited.
# Quiet (exit 0, no output) for backend/exempt paths so it never nags on non-UI work.
# Non-blocking: only injects additionalContext.
#
# Lives with the design-rules skill; wired into ~/.claude/hooks + settings.json by
# the skills repo install.sh so it propagates to every machine (incl. the dev box).

f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$f" ] && exit 0

# Exemptions (backend / non-UI / tests) -- check FIRST, stay silent.
case "$f" in
  */app/api/*|*/route.ts|*/route.tsx|*/supabase/*|*/migrations/*|*.sql|*.test.*|*.spec.*)
    exit 0 ;;
esac

# Frontend triggers: component/style files, or anything under components/ or app/.
case "$f" in
  *.tsx|*.jsx|*.css|*.scss|*/components/*|*/app/*) ;;
  *) exit 0 ;;
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"STRICT GUARDRAIL (global rule): this is a frontend edit. You MUST invoke the design-rules skill and build to it WHILE writing this, not as a cleanup pass afterward. Design the product the proper way: minimal, tight, calm, premium, and practically relevant to the user at all times. Every page, feature, component, element, color, button, and navigation is in scope -- we are not generalists, the UI is specific to this product. Public-facing pages get extra scrutiny. If you have not invoked design-rules this session, do it now before continuing this edit."}}
JSON
