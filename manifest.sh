# What this package installs. Sourced by install.sh and uninstall.sh.
#
# This is the skill variant: a directory under ~/.claude/skills. Skills need no
# settings.json entry — Claude Code reads anything under skills/ at startup.
#
# The skill is a directory, but it is not only a directory: it carries two
# hooks and an MCP server, and all three need registering before the skill is
# one step to install. They used to be the user's to paste in by hand, on the
# grounds that both hooks change what happens in every session rather than only
# the ones that load this skill. That was true and it still cost more than it
# saved — rig-down-on-end.sh sat unregistered from 17 Sep, so every untidy
# session left a simulator booted and a stale name on the wall, which is the
# exact failure the hook exists to prevent.
#
# So install.sh now registers all three:
#
#   PreToolUse/Bash  hooks/gate-journey-first.sh   settings.json
#   SessionEnd       hooks/rig-down-on-end.sh      settings.json
#   mcpServers       bin/mcp.sh                    ~/.claude.json
#
# uninstall.sh removes all three. Re-running install.sh is still safe: it
# strips every entry whose command contains OWNS before adding the current
# ones, and both hook commands contain it by way of their skill path.

PKG="maestro-drive"
OWNS="maestro-drive"

# EVERY NAME THIS PACKAGE HAS HAD. It was maestro-remote-mac until 21 Sep 2026
# (BACKLOG item 98), and an upgrade across a rename is the one case where the
# OWNS strip above is not enough: the entries already in settings.json carry the
# old name, so a strip that knows only the current one leaves them behind and
# the user ends up with two gates on every Bash call and a SessionEnd hook
# pointing into a directory that is no longer updated. install.sh and
# uninstall.sh match a hook command against this list as well as against OWNS.
LEGACY_OWNS=(
  "maestro-remote-mac"
)

# Directories a previous name installed into. install.sh takes the skill
# directory out once the new one is in place, and moves what the lib directory
# held — the install record and the phase-A marker — across rather than losing
# it. uninstall.sh sweeps both.
LEGACY_SKILL_DIRS=(
  "$CLAUDE_DIR/skills/maestro-remote-mac"
)
LEGACY_LIB_DIRS=(
  "$HOME/.local/share/maestro-remote-mac"
)

# A skill installs as a whole directory. install.sh copies or symlinks it.
DIRS=(
  "skill:$CLAUDE_DIR/skills/maestro-drive"
)
FILES=()
STATE_DIRS=()

# Where the installed hooks live. install.sh resolves this at install time, so
# a test run with CLAUDE_DIR redirected registers the temp path and never the
# real one. Both commands contain "maestro-drive" by way of that path,
# which is what lets the OWNS strip in install.sh and uninstall.sh find them.
HOOK_DIR="$CLAUDE_DIR/skills/maestro-drive/hooks"

# "bash <path>" rather than the bare path: the sandbox refuses chmod +x under
# ~/.claude, so a hook installed there cannot be relied on to carry its exec
# bit, and a bare path that has lost it fails with "Permission denied" in the
# middle of a session.
GATE_CMD="bash $HOOK_DIR/gate-journey-first.sh"
RIGDOWN_CMD="bash $HOOK_DIR/rig-down-on-end.sh"

# Reads the stripped settings.json on stdin and adds this package's entries.
#
# PreToolUse goes on as its own matcher "Bash" entry rather than merging into
# an existing one. This machine already has gate-unsandboxed-bash.sh on its own
# Bash matcher; separate entries both fire and neither depends on the other,
# whereas merging them into one entry makes them ordered and couples two
# packages that know nothing about each other. setup.md section 5 says the
# same.
settings_merge() {
  jq --arg gate "$GATE_CMD" --arg rigdown "$RIGDOWN_CMD" '
    def add($event; $entry):
      .hooks //= {}
      | .hooks[$event] = ((.hooks[$event] // []) + [$entry]);
    add("PreToolUse"; {matcher: "Bash", hooks: [{type: "command", command: $gate}]})
    | add("SessionEnd"; {hooks: [{type: "command", command: $rigdown}]})
  '
}

# The MCP server. This one does not live in settings.json — Claude Code keeps
# mcpServers in $HOME/.claude.json, which also holds project records and auth
# state, so install.sh gives it its own backup and writes it by temp-file and
# rename. It keys off $HOME rather than CLAUDE_DIR, which is why the test suite
# redirects both.
#
# Absolute path, resolved at install time. Claude Code does NOT expand a
# leading ~ in an mcpServers command or arg — it goes to the OS unexpanded and
# exec fails — and while ${HOME} is expanded, a path resolved here is true
# regardless and matches what the hooks do.
#
# "bash" with the script as an argument, for the exec-bit reason above.
MCP_NAME="maestro-mac"
MCP_SCRIPT="$CLAUDE_DIR/skills/maestro-drive/bin/mcp.sh"

# The bridge server (BACKLOG item 96), which is optional and asked about at
# install time. It starts and stops the helper that runs this package's scripts
# outside the Bash sandbox, for a Linux machine whose sandbox sits between the
# package and a device that is on that machine. A Mac has no use for it: local
# transport reaches its own simulator.
#
# python3 rather than bash, and the same exec-bit reasoning — the script is
# named as an argument rather than run directly.
MCP_BRIDGE_NAME="maestro-bridge"
MCP_BRIDGE_SCRIPT="$CLAUDE_DIR/skills/maestro-drive/bin/bridge-mcp.py"

# Reads $HOME/.claude.json on stdin and sets this package's servers, leaving
# every other key and every other server untouched.
#
#   claude_json_merge [1]   -- 1 also registers the bridge server
#
# It never REMOVES the bridge entry. An installer that quietly took away a
# capability somebody registered would be as surprising as one that quietly
# added it, and `uninstall.sh` is where things get removed.
claude_json_merge() {
  jq --arg name "$MCP_NAME" --arg script "$MCP_SCRIPT" \
     --arg bname "$MCP_BRIDGE_NAME" --arg bscript "$MCP_BRIDGE_SCRIPT" \
     --argjson bridge "${1:-0}" '
    .mcpServers //= {}
    | .mcpServers[$name] = {type: "stdio", command: "bash", args: [$script]}
    | if $bridge == 1
      then .mcpServers[$bname] = {type: "stdio", command: "python3", args: [$bscript]}
      else . end
  '
}

REGISTRATIONS=(
  "skills/maestro-drive"
  "settings.json  PreToolUse/Bash  hooks/gate-journey-first.sh"
  "settings.json  SessionEnd       hooks/rig-down-on-end.sh"
  ".claude.json   mcpServers       bin/mcp.sh as \"$MCP_NAME\""
  ".claude.json   mcpServers       bin/bridge-mcp.py as \"$MCP_BRIDGE_NAME\" (only if asked for)"
)

# Everything under skill/ that is part of the published tree. Two kinds of file
# are deliberately not, and both appear only after the skill has been used:
#
#   __pycache__/*.pyc     running the skill writes compiled Python into
#                         whatever directory it loaded from, so the live copy
#                         grows files that were never shipped and never should
#                         be. A check that did not ignore them would fail the
#                         first time anybody drove a device.
#   reference/staging/    where `bin/notes.sh promote` parks a project's
#                         tooling findings until a person folds them into
#                         reference/. It is work in progress, not payload.
belongs() {
  ( cd "$1" && find . -type f \
      ! -path "*/__pycache__/*" ! -name "*.pyc" \
      ! -path "./reference/staging/*" \
      | sed 's|^\./||' | LC_ALL=C sort )
}

# The check item 17 of the backlog asked for: not "did the files we copied
# arrive", which is trivially true, but "does the live tree contain exactly what
# belongs in it". Before this package existed the skill was published by rsync
# into a build/ directory symlinked into ~/.claude/skills, and three edits were
# made straight into that live tree by sessions that believed it was the source.
# All three were invisible — nothing stated what the published tree was supposed
# to contain — and all three would have been destroyed by the next publish.
#
# A --link install makes the question moot, because the live path and the
# checkout are then the same directory. A copy install is where it earns its
# keep.
tree_matches() {
  local live="$CLAUDE_DIR/skills/$PKG"
  [ -d "$live" ] || return 1
  local extra
  extra=$(comm -13 <(belongs "$REPO/skill") <(belongs "$live"))
  local absent
  absent=$(comm -23 <(belongs "$REPO/skill") <(belongs "$live"))
  if [ -n "$extra" ] || [ -n "$absent" ]; then
    [ -n "$absent" ] && printf '        missing from the live tree: %s\n' $absent >&2
    [ -n "$extra" ]  && printf '        in the live tree but not in skill/: %s\n' $extra >&2
    return 1
  fi
}

# Confirm the installed skill is well formed, that its tree is exactly what
# belongs, and that the part of it Claude reaches for first actually runs. The
# resolver is that part — every tap goes through it — and it answers offline
# from a captured hierarchy, so the probe needs no Mac, no device and no
# network.
verify_probe() {
  local live="$CLAUDE_DIR/skills/$PKG"
  local f="$live/SKILL.md"
  [ -f "$f" ] || return 1
  head -1 "$f" | grep -q '^---$' || return 1
  grep -q '^name:' "$f" && grep -q '^description:' "$f" || return 1
  tree_matches || return 1
  command -v python3 >/dev/null 2>&1 || return 0
  local got
  got=$(python3 "$live/bin/resolve.py" "^SCAN$" --width 402 --height 874 --point \
          < "$live/test/fixtures/iphone-portrait-keyboard-up.json" 2>&1)
  [ "$got" = "201 262.6" ] || { printf '        resolver returned %s, want 201 262.6\n' "$got" >&2; return 1; }
}
