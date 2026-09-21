#!/usr/bin/env bash
# Remove maestro-remote-mac from this machine.
#
#   ./uninstall.sh                 ask before editing either config file
#   ./uninstall.sh --yes           no prompts
#   ./uninstall.sh --keep-settings leave settings.json and ~/.claude.json alone

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_JSON="$HOME/.claude.json"
LIB_DIR="$HOME/.local/share/maestro-remote-mac"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/maestro-remote-mac"

ASSUME_YES=0; KEEP_SETTINGS=0
for a in "$@"; do
  case "$a" in
    --yes|-y)        ASSUME_YES=1 ;;
    --keep-settings) KEEP_SETTINGS=1 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  local reply; read -r -p "$1 [Y/n] " reply </dev/tty || return 1
  case "$reply" in [Nn]*) return 1 ;; *) return 0 ;; esac
}

FILES=(); DIRS=(); STATE_DIRS=()
# shellcheck source=manifest.sh
. "$REPO/manifest.sh"

printf '%s\n' "== Uninstalling $PKG"

step "Removing files"
for entry in ${FILES[@]+"${FILES[@]}"} ${DIRS[@]+"${DIRS[@]}"}; do
  d="${entry#*:}"
  if [ -e "$d" ] || [ -L "$d" ]; then rm -rf "$d"; ok "removed $d"; else ok "no $d"; fi
done
for d in "$LIB_DIR" "$STATE" ${STATE_DIRS[@]+"${STATE_DIRS[@]}"}; do
  [ -d "$d" ] && { rm -rf "$d"; ok "removed $d"; }
done

step "settings.json"
if [ "$KEEP_SETTINGS" -eq 1 ]; then
  ok "left alone (--keep-settings)"
elif [ ! -f "$SETTINGS" ]; then
  ok "no $SETTINGS"
elif ! jq empty "$SETTINGS" 2>/dev/null; then
  warn "$SETTINGS is not valid JSON — leaving it untouched."
  warn "Remove the hook entries whose command contains '$OWNS' by hand."
elif confirm "  Remove this package's hook entries?"; then
  cp "$SETTINGS" "$SETTINGS.bak-uninstall"
  tmp=$(mktemp)
  jq --arg owns "$OWNS" '
    def ours: (.command // "") | contains($owns);
    def strip_ours: map(.hooks |= map(select(ours | not))) | map(select((.hooks | length) > 0));
    if (.hooks | type) == "object" then
      .hooks |= with_entries(if (.value | type) == "array" then .value |= strip_ours else . end)
      | .hooks |= with_entries(select((.value | type) != "array" or (.value | length) > 0))
      | (if (.hooks // null) == {} then del(.hooks) else . end)
    else . end
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  ok "cleaned; previous file saved as $SETTINGS.bak-uninstall"
else
  ok "left alone"
fi

step "$CLAUDE_JSON"
# The jq above only walks .hooks, and the MCP server is not there — it is a key
# under .mcpServers in a different file. Removing one without the other leaves
# an entry pointing at a script that has just been deleted, which fails at every
# session start rather than visibly.
if [ "$KEEP_SETTINGS" -eq 1 ]; then
  ok "left alone (--keep-settings)"
elif [ ! -f "$CLAUDE_JSON" ]; then
  ok "no $CLAUDE_JSON"
elif ! jq empty "$CLAUDE_JSON" 2>/dev/null; then
  warn "$CLAUDE_JSON is not valid JSON — leaving it untouched."
  warn "Remove the .mcpServers[\"$MCP_NAME\"] entry by hand."
elif ! jq -e --arg n "$MCP_NAME" --arg b "$MCP_BRIDGE_NAME" \
       'has("mcpServers") and ((.mcpServers | has($n)) or (.mcpServers | has($b)))' \
       "$CLAUDE_JSON" >/dev/null 2>&1; then
  ok "no $MCP_NAME entry"
elif confirm "  Remove the $MCP_NAME and $MCP_BRIDGE_NAME MCP server entries?"; then
  cp "$CLAUDE_JSON" "$CLAUDE_JSON.bak-uninstall"
  tmp=$(mktemp "$(dirname "$CLAUDE_JSON")/.claude.json.XXXXXX")
  # Both names: the bridge is optional at install time and is this package's
  # either way, so leaving it behind would leave an entry pointing at a script
  # that has just been deleted (item 96).
  jq --arg n "$MCP_NAME" --arg b "$MCP_BRIDGE_NAME" '
    del(.mcpServers[$n]) | del(.mcpServers[$b])
    | if (.mcpServers // null) == {} then del(.mcpServers) else . end
  ' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
  ok "cleaned; previous file saved as $CLAUDE_JSON.bak-uninstall"
else
  ok "left alone"
fi

printf '\n%s\n' "Done."
