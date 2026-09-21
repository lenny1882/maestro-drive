#!/usr/bin/env bash
# Installer for maestro-remote-mac.
#
#   ./install.sh           install
#   ./install.sh --link    symlink instead of copying, for working on the repo
#   ./install.sh --yes     no prompts
#   ./install.sh --with-bridge   register the bridge MCP server without asking
#   ./install.sh --no-bridge     do not, and do not ask
#   ./install.sh --dry-run show what would change in settings.json and
#                          ~/.claude.json, write nothing
#
# Re-running is safe and is how you upgrade.
#
# What gets installed is declared in manifest.sh — this file is machinery and
# rarely needs editing.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(head -1 "$REPO/VERSION" | tr -d '[:space:]')"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
# Claude Code keeps mcpServers here, not in settings.json. The file also holds
# project records and auth state, so it is never rewritten in place.
CLAUDE_JSON="$HOME/.claude.json"
LIB_DIR="$HOME/.local/share/maestro-remote-mac"

LINK=0; ASSUME_YES=0; DRY=0; BRIDGE_FLAG=ask
for a in "$@"; do
  case "$a" in
    --link)    LINK=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    --dry-run) DRY=1 ;;
    --with-bridge) BRIDGE_FLAG=yes ;;
    --no-bridge)   BRIDGE_FLAG=no ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }

FILES=(); DIRS=(); STATE_DIRS=(); REGISTRATIONS=()
# shellcheck source=manifest.sh
. "$REPO/manifest.sh"

say "== $PKG v$VERSION"
say "   repo: $REPO"

step "Checking prerequisites"
missing=()
for c in jq; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if [ "${#missing[@]}" -gt 0 ]; then
  say "  Missing: ${missing[*]} — install them and re-run (Debian/Ubuntu: sudo apt install ${missing[*]})"
  exit 1
fi
ok "jq present"

# GSD's session-start migration deletes any hook whose command contains "gsd-",
# which once made a registration vanish between sessions with no error.
case "$PKG" in
  *gsd-*) warn "the package name contains 'gsd-'. GSD's own session-start migration"
          warn "removes hooks matching that, and the registration will disappear."
          warn "Rename it." ;;
esac

place() { # place <source> <destination>
  local src="$REPO/$1" dst="$2"
  [ -e "$src" ] || { warn "missing $src"; return 1; }
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  if [ "$LINK" -eq 1 ]; then ln -s "$src" "$dst"; else cp -r "$src" "$dst"; fi
  ok "$dst"
}

if [ "$DRY" -eq 0 ]; then
  step "Installing files"
  for entry in ${FILES[@]+"${FILES[@]}"}; do place "${entry%%:*}" "${entry#*:}"; done
  for entry in ${DIRS[@]+"${DIRS[@]}"};  do place "${entry%%:*}" "${entry#*:}"; done
  for entry in ${FILES[@]+"${FILES[@]}"}; do chmod +x "${entry#*:}" 2>/dev/null || true; done
  if [ -f "$REPO/lib/update-check.sh" ]; then
    mkdir -p "$LIB_DIR"; rm -f "$LIB_DIR/update-check.sh"
    if [ "$LINK" -eq 1 ]; then ln -s "$REPO/lib/update-check.sh" "$LIB_DIR/update-check.sh"
    else cp "$REPO/lib/update-check.sh" "$LIB_DIR/update-check.sh"; fi
    chmod +x "$LIB_DIR/update-check.sh"; ok "$LIB_DIR/update-check.sh"
  fi
fi

if declare -F settings_merge >/dev/null; then
  step "Merging into $SETTINGS"
  mkdir -p "$(dirname "$SETTINGS")"
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  jq empty "$SETTINGS" 2>/dev/null || { say "  $SETTINGS is not valid JSON — fix it and re-run."; exit 1; }

  # Remove this package's previous entries across every event, then let the
  # manifest add the current ones. That is what makes re-running safe.
  tmp=$(mktemp)
  jq --arg owns "$OWNS" '
    def ours: (.command // "") | contains($owns);
    def strip_ours: map(.hooks |= map(select(ours | not))) | map(select((.hooks | length) > 0));
    if (.hooks | type) == "object" then
      .hooks |= with_entries(
        if (.value | type) == "array" then .value |= strip_ours else . end)
      | .hooks |= with_entries(select((.value | type) != "array" or (.value | length) > 0))
    else . end
  ' "$SETTINGS" | settings_merge > "$tmp"

  if [ "$DRY" -eq 1 ]; then
    diff <(jq -S . "$SETTINGS") <(jq -S . "$tmp") || true
    rm -f "$tmp"
  elif diff -q "$tmp" "$SETTINGS" >/dev/null 2>&1; then
    rm -f "$tmp"; ok "already up to date"
  else
    cp "$SETTINGS" "$SETTINGS.bak-$PKG"
    mv "$tmp" "$SETTINGS"
    for r in ${REGISTRATIONS[@]+"${REGISTRATIONS[@]}"}; do ok "$r"; done
    ok "previous settings kept at $SETTINGS.bak-$PKG"
  fi
fi

# $HOME/.claude.json, for the MCP server. Kept apart from the settings.json
# merge above because the file is a different shape, is not under CLAUDE_DIR,
# and carries things no installer should risk: project records and auth state.
#
# Claude Code writes this file itself while it is running, and concurrent
# read-modify-write on it is a known way to corrupt it, so this writes a temp
# file and renames it — the replacement is a single atomic step — and keeps a
# backup either way. Installing while Claude Code is running is still best
# avoided.
if declare -F claude_json_merge >/dev/null; then
  step "Merging into $CLAUDE_JSON"
  mkdir -p "$(dirname "$CLAUDE_JSON")"
  [ -f "$CLAUDE_JSON" ] || echo '{}' > "$CLAUDE_JSON"
  if ! jq empty "$CLAUDE_JSON" 2>/dev/null; then
    say "  $CLAUDE_JSON is not valid JSON — fix it and re-run."
    exit 1
  fi

  # The bridge server is optional, and the question is asked rather than
  # decided here (item 96). Already registered means keep it and do not ask —
  # an update must not quietly take away a capability, or quietly add one.
  BRIDGE=0
  if jq -e --arg n "$MCP_BRIDGE_NAME" '(.mcpServers // {}) | has($n)' "$CLAUDE_JSON" >/dev/null 2>&1; then
    BRIDGE=1
    ok "$MCP_BRIDGE_NAME already registered — keeping it"
  else
    case "$BRIDGE_FLAG" in
      yes) BRIDGE=1 ;;
      no)  BRIDGE=0 ;;
      *)
        if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
          # Nobody to ask, so nothing is added. A capability that appears in a
          # scripted install is one nobody chose.
          say "  The optional bridge server was not registered — add it with:"
          say "    $0 --with-bridge"
        else
          say
          say "  The bridge server lets a sandboxed Claude session drive a device on THIS"
          say "  machine: it runs this package's scripts outside the sandbox, because the"
          say "  sandbox has no /dev/kvm and its own network. It idles until a session asks"
          say "  it to start; when it does, that helper carries shell to this machine and"
          say "  logs everything it runs. A Mac does not need it — local transport already"
          say "  reaches its own simulator."
          printf '  Register %s? [Y/n]: ' "$MCP_BRIDGE_NAME"
          read -r reply
          case "${reply:-y}" in [Yy]*) BRIDGE=1 ;; *) BRIDGE=0 ;; esac
        fi
        ;;
    esac
  fi

  ctmp=$(mktemp "$(dirname "$CLAUDE_JSON")/.claude.json.XXXXXX")
  claude_json_merge "$BRIDGE" < "$CLAUDE_JSON" > "$ctmp"

  if [ "$DRY" -eq 1 ]; then
    diff <(jq -S . "$CLAUDE_JSON") <(jq -S . "$ctmp") || true
    rm -f "$ctmp"
  elif diff -q "$ctmp" "$CLAUDE_JSON" >/dev/null 2>&1; then
    rm -f "$ctmp"; ok "already up to date"
  else
    cp "$CLAUDE_JSON" "$CLAUDE_JSON.bak-$PKG"
    mv "$ctmp" "$CLAUDE_JSON"
    ok "mcpServers.$MCP_NAME -> $MCP_SCRIPT"
    [ "$BRIDGE" -eq 1 ] && ok "mcpServers.$MCP_BRIDGE_NAME -> $MCP_BRIDGE_SCRIPT"
    ok "previous file kept at $CLAUDE_JSON.bak-$PKG"
  fi
fi

if [ "$DRY" -eq 1 ]; then
  say; say "(dry run — nothing written)"; exit 0
fi

if [ -x "$LIB_DIR/update-check.sh" ]; then
  step "Recording the installed version"
  "$LIB_DIR/update-check.sh" record-install "$VERSION" "$REPO"
  ok "v$VERSION, repo at $REPO"
fi

step "Verifying"
fail=0
for entry in ${FILES[@]+"${FILES[@]}"} ${DIRS[@]+"${DIRS[@]}"}; do
  [ -e "${entry#*:}" ] && ok "${entry#*:}" || { warn "missing ${entry#*:}"; fail=1; }
done
if declare -F verify_probe >/dev/null; then
  if verify_probe; then ok "it does what it is supposed to"
  else warn "the probe in manifest.sh failed — it installed, but does not work"; fail=1; fi
fi

# The skill is installed but cannot reach anything until the SSH and network
# side exists: a key on the Mac, a Host block per network, /etc/hosts and
# allowedDomains. setup.md describes all of it and it still gets done wrong,
# which is what the wizard is for. The marker is a phase A flag — networks
# themselves are discoverable from the three files, so nothing else is tracked.
step "SSH and network setup"
WIZARD="$CLAUDE_DIR/skills/maestro-remote-mac/setup/wizard.sh"
[ -x "$WIZARD" ] || WIZARD="$REPO/skill/setup/wizard.sh"
if [ -e "$LIB_DIR/phase-a-done" ]; then
  ok "phase A done $(cat "$LIB_DIR/phase-a-done" 2>/dev/null)"
  say "  Re-run $WIZARD when you join a new network."
elif [ ! -x "$WIZARD" ]; then
  warn "no wizard found at $WIZARD"
else
  say "  Not set up on this machine yet — no key, no Host block, nothing to talk to."
  if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
    say "  Run it when you are ready:  $WIZARD"
  else
    printf '  Run the setup wizard now? [Y/n]: '
    read -r reply
    case "${reply:-y}" in
      [Yy]*) "$WIZARD" || warn "the wizard exited non-zero — re-run it with $WIZARD" ;;
      *)     say "  Run it later:  $WIZARD" ;;
    esac
  fi
fi

say
if [ "$fail" -eq 0 ]; then
  say "Done. If Claude Code is already running, /hooks forces a settings reload;"
  say "the MCP server is picked up on the next start."
else
  say "Finished with problems — see the warnings above."
  exit 1
fi
