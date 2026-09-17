#!/bin/bash
# PreToolUse hook (matcher: Bash) — one speed bump per session on a
# maestro-remote-mac driver call that taps literal coordinates.
#
# Why. Hand-walking a screen the project already has a journey for is the most
# expensive habit in this workflow and the most repeated: raised 21 Aug, 3 Sep
# and twice on 4 Sep 2026. Three memories say don't, and all three were loaded
# into context on the session that did it anyway. On 4 Sep `ls maestro/journeys/`
# was the second tool call of the session, printed the project's login and
# device-setup journeys, and both were then typed out by hand — nine round trips
# and five raw `tap x y` calls for what those two files run in about a
# minute. Prose in a skill or a memory is read before the screen is on the
# table; this fires while it is.
#
# What it matches. Any Bash command that mentions `driver.sh` AND contains a
# `tap` or `swipe` verb followed by literal numbers — `driver.sh tap 293 325`,
# and also `$D tap 179 481`, because shell state does not persist between Bash
# calls so the assignment that defines $D is always in the same command.
# `tapon` is deliberately NOT matched: it resolves by label, which is the thing
# this hook is trying to push people towards.
#
# What it does. Exit 2 — which blocks the call and puts stderr in front of the
# model — the FIRST time it matches in a session, then gets out of the way.
# It is a nudge, not a ban: raw taps are sometimes the only option (the iPad nav
# rail carries no nodes in the accessibility tree at all), so the message says
# to re-run the same command if that is the case, and the second attempt passes.
#
# One bump per session is the conservative setting. If the habit survives it,
# the sharper version keys the marker on the command text instead of the
# session, so every distinct coordinate call gets its own bump.
#
# Ships with the skill. This script lives in the repo's skill/hooks/, which
# install.sh puts at ~/.claude/skills/maestro-remote-mac/, so
# ~/.claude/skills/maestro-remote-mac/hooks/gate-journey-first.sh is the
# installed copy the settings.json entry points at and it follows the skill. It
# only ever fires on a command containing `driver.sh`, this skill's own binary,
# so with the skill uninstalled it is dead weight — that is why it belongs to
# the skill rather than to ~/.claude/hooks.
#
# Install: add the PreToolUse / matcher "Bash" entry in reference/setup.md § 5 to
#          settings.json (a SECOND Bash matcher, beside gate-unsandboxed-bash.sh).
# Disable: remove that entry. A missing script fails open — see the exit 0 below.

JQ=$(command -v jq || echo /usr/bin/jq)
[ -x "$JQ" ] || exit 0   # no jq: fail open rather than break every Bash call

input=$(cat)

cmd=$(printf '%s' "$input" | "$JQ" -r '.tool_input.command // ""')
session=$(printf '%s' "$input" | "$JQ" -r '.session_id // "nosession"')

# Only driver.sh calls are in scope.
case "$cmd" in *driver.sh*) ;; *) exit 0 ;; esac

# `tap` / `swipe` followed by literal coordinates, allowing the --tree/--nodes
# flags that may sit between the verb and its arguments. The leading boundary
# stops `bootstrap 1 2` and friends matching; requiring whitespace after the
# verb stops `tapon` matching.
coords='(^|[^A-Za-z0-9_.-])(tap|swipe)([[:space:]]+--[a-z]+)*[[:space:]]+-?[0-9]+[[:space:]]+-?[0-9]+'
printf '%s' "$cmd" | grep -Eq "$coords" || exit 0

# The marker lives in the temp dir, not under ~/.claude/state, because that
# path is not writable from a sandboxed Bash call and the hook has to behave the
# same whether it is exercised by the harness or tested by hand. Ephemeral is
# correct here: the bump is per session and nothing needs it after that.
#
# If the marker cannot be written, fail OPEN. A hook that blocks but cannot
# remember it has blocked would refuse every raw tap for the rest of the
# session, which is a ban rather than a nudge.
state_dir="${TMPDIR:-/tmp}/claude-journey-first"
marker="$state_dir/$session"
mkdir -p "$state_dir" 2>/dev/null || exit 0
[ -f "$marker" ] && exit 0
: > "$marker" 2>/dev/null || exit 0

cat >&2 <<'EOF'
Blocked once: this taps literal coordinates through driver.sh.

The unit of work on the remote Mac is a journey file, not a driver call. Before
driving this screen by hand:

  1. ls the project's journey directory (maestro/journeys/, or $JOURNEY_DIR).
     Every journey's header names the screen it STARTS on — that is a one-line
     check, not a reading exercise.
  2. If one starts here, run it:  driver.sh script a.journey b.journey
     Chain several in ONE call; that is where the whole saving is.
  3. If none fits, write one as you go and run that. The writing is what makes
     the next session cheap.

A raw tap is sometimes correct — the iPad nav rail carries no nodes in the
accessibility tree at all. Where the hierarchy genuinely has nothing to match,
prefer driver.sh find --explain to hand arithmetic, then re-run this same
command: this hook fires once per session and will not stop it again.
EOF
exit 2
