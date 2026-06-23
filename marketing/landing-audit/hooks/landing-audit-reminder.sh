#!/usr/bin/env bash
# Stop hook. If landing-page files were touched in the current repo this session
# and we haven't already nudged, ask the model to offer running /landing-audit.
# Fires at most once per session (sentinel keyed on session_id) so it never nags.
#
# Lives with the landing-audit skill; wired into ~/.claude/hooks + settings.json by
# the skills repo install.sh so it propagates to every machine (incl. the dev box).

input="$(cat)"
sess="$(printf '%s' "$input" | jq -r '.session_id // "nosess"')"
flag="${TMPDIR:-/tmp}/claude-landing-audit-${sess}.flag"
[ -f "$flag" ] && exit 0

# Changed-vs-HEAD plus untracked files in the current repo, filtered to things
# that look like a landing page / marketing homepage.
files="$( { git diff --name-only HEAD; git ls-files --others --exclude-standard; } 2>/dev/null \
  | grep -iE '(^|/)(src/)?app/page\.(t|j)sx?$|(^|/)pages/index\.(t|j)sx?$|landing|(^|/)hero|marketing' \
  | sort -u )"
[ -z "$files" ] && exit 0

touch "$flag"
list="$(printf '%s' "$files" | paste -sd', ' -)"
reason="Landing-page file(s) were modified this session: ${list}. If this unit of work looks complete, ask the user whether to run the landing-audit skill (/landing-audit) on the affected page now before wrapping up. Ask once, conversationally; if they decline, drop it and stop."
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
