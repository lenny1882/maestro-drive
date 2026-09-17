#!/usr/bin/env bash
# Setup wizard for maestro-remote-mac — the SSH and network side.
#
#   ./wizard.sh            run it
#   ./wizard.sh --status   what is already in place, change nothing
#
# Why this exists rather than more prose. reference/setup.md describes all of
# this correctly and it still gets done wrong, because it spans three files that
# must agree and is read once, at the wrong moment. setup.md's own sentence is
# the argument: the ssh config, /etc/hosts and allowedDomains are "all three or
# none — two out of three produces a failure that looks like something else."
#
# Three phases. A is once per machine, B is once per network and repeatable, C
# is optional and offered only after a new B.
#
#   A  the Mac's user, a key, the key onto the Mac, and proof it works
#   B  a Host block and an allowedDomains entry, per network
#   C  the Mac-side network-change pair, so the Mac holds a fixed address
#
# /etc/hosts is written last, once the address is final, because it is the only
# one of the three nothing else needs: SSH uses the Host block's literal
# Hostname and the sandbox proxy needs the address in allowedDomains. Only curl
# on the .local name needs /etc/hosts.
#
# Nothing here stores a key path. The IdentityFile line in the Host block is the
# record, and a later run reads it back. known_hosts cannot serve that purpose:
# it holds the Mac's host key, not this machine's identity.

set -euo pipefail

LIB_DIR="${LIB_DIR:-$HOME/.local/share/maestro-remote-mac}"
MARKER="$LIB_DIR/phase-a-done"
SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
DEFAULT_KEY="$HOME/.ssh/mac_rc"

STATUS_ONLY=0
for a in "$@"; do
  case "$a" in
    --status)  STATUS_ONLY=1 ;;
    -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }

ask() { # ask <prompt> [default] -> answer on stdout
  local prompt="$1" default="${2:-}" reply
  if [ -n "$default" ]; then
    printf '  %s [%s]: ' "$prompt" "$default" >&2
  else
    printf '  %s: ' "$prompt" >&2
  fi
  read -r reply
  printf '%s' "${reply:-$default}"
}

confirm() { # confirm <prompt> <default y|n> -> 0 if yes
  local prompt="$1" default="$2" reply
  printf '  %s [%s]: ' "$prompt" "$([ "$default" = y ] && echo 'Y/n' || echo 'y/N')" >&2
  read -r reply
  reply="${reply:-$default}"
  case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# --- reading back what is already configured --------------------------------
# The three files are the record, so nothing is cached. A Host block carries the
# alias, the address, the Mac's user and the key; that is everything a later run
# needs to avoid asking twice.

ssh_hosts() { # every Host alias in ~/.ssh/config, uncommented
  [ -r "$SSH_CONFIG" ] || return 0
  awk '/^[[:space:]]*Host[[:space:]]+/ { for (i=2; i<=NF; i++) print $i }' "$SSH_CONFIG"
}

host_field() { # host_field <alias> <keyword> -> value
  [ -r "$SSH_CONFIG" ] || return 0
  awk -v want="$2" '
    /^[[:space:]]*Host[[:space:]]+/ { inblock = ($2 == alias); next }
    inblock && tolower($1) == tolower(want) { print $2; exit }
  ' alias="$1" "$SSH_CONFIG"
}

# Aliases whose block names a key — the ones this package plausibly wrote.
configured_aliases() {
  local h
  for h in $(ssh_hosts); do
    [ -n "$(host_field "$h" IdentityFile)" ] && printf '%s\n' "$h"
  done
}

# --- is the Mac's address on a network this machine can see? ----------------
# A failed connection does not prove the Mac is off. It may simply be on a
# network this machine is not attached to, which is the ordinary case for a
# laptop that moves. Only if a stored address is on one of our own subnets is
# "is it switched on?" the right question to ask.

same_subnet() { # same_subnet <ip> -> 0 if it shares a subnet with this machine
  command -v ip >/dev/null 2>&1 || return 1
  ip -o -4 addr show scope global 2>/dev/null \
    | awk '{ print $4 }' \
    | python3 -c '
import ipaddress, sys
target = sys.argv[1]
try:
    t = ipaddress.ip_address(target)
except ValueError:
    raise SystemExit(1)
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        net = ipaddress.ip_network(line, strict=False)
    except ValueError:
        continue
    if t in net:
        raise SystemExit(0)
raise SystemExit(1)
' "$1"
}

mac_needed() {
  say ""
  say "  The Mac must be switched on and joined to the network you are setting up."
  say "  Everything below talks to it directly."
  say ""
}

# --- phase A ----------------------------------------------------------------

phase_a_status() {
  local aliases key found=0
  aliases=$(configured_aliases || true)
  if [ -z "$aliases" ]; then
    warn "no Host block in $SSH_CONFIG names a key"
    return 1
  fi
  for a in $aliases; do
    key=$(host_field "$a" IdentityFile)
    key="${key/#\~/$HOME}"
    if [ -r "$key" ]; then
      ok "$a -> $key"
      found=1
    else
      warn "$a names $key, which is not readable"
    fi
  done
  [ "$found" = 1 ]
}

phase_a() {
  step "Phase A — the Mac, a key, and proof the key works"

  # A re-run is the common case: someone adding a second or third network. The
  # key is already made and already on the Mac, so the only checks that can be
  # made without the Mac are local ones.
  if [ -e "$MARKER" ]; then
    say "  Phase A ran on $(cat "$MARKER" 2>/dev/null || echo 'an earlier date')."
    if phase_a_status; then
      say ""
      say "  A key exists and a Host block names it, so phase A has nothing to do."
    else
      warn "the marker exists but no usable key was found — treating this as a fresh run"
      rm -f "$MARKER"
    fi
  fi

  if [ ! -e "$MARKER" ]; then
    mac_needed

    local mac_user mac_name key addr
    mac_user=$(ask "the Mac's username")
    mac_name=$(ask "the Mac's .local name" "$(hostname -s 2>/dev/null || echo mac).local")

    say ""
    say "  A key for this and nothing else. An existing one is fine — the Mac only"
    say "  has to trust it, and its type does not matter."
    key=$(ask "key path, or blank to create one" "$DEFAULT_KEY")
    key="${key/#\~/$HOME}"

    if [ -r "$key" ]; then
      ok "using existing key $key"
    else
      # -N '' is not optional. Every script in this package passes
      # BatchMode=yes, under which a passphrase prompt is not a prompt but an
      # immediate failure with no explanation.
      say "  Creating $key (ed25519, no passphrase)."
      ssh-keygen -t ed25519 -N '' -f "$key" -C "maestro-remote-mac" >/dev/null
      ok "created $key"
    fi

    say ""
    say "  The key goes onto the Mac once, not once per network: authorized_keys"
    say "  is a single file there, reachable from any address."
    addr=$(ask "the Mac's address right now")

    say ""
    say "  ssh-copy-id authenticates with the Mac's LOGIN PASSWORD, prompted below."
    say "  The -i flag only names the key to copy."
    say ""
    say "    ssh-copy-id -i $key.pub $mac_user@$addr"
    say ""
    # Foreground, output not captured, no BatchMode. ssh reads the password from
    # /dev/tty, so the prompt reaches the terminal as long as none of those
    # three is broken.
    if ! ssh-copy-id -i "$key.pub" "$mac_user@$addr"; then
      say ""
      warn "ssh-copy-id failed. Refused on port 22 means Remote Login is off"
      warn "(System Settings -> General -> Sharing). Timed out means the wrong"
      warn "address, or the Mac is on a different network."
      return 1
    fi

    say ""
    say "  Proving key authentication works. This uses BatchMode=yes, which is what"
    say "  every script uses — a password that merely worked would not prove it."
    if ssh -i "$key" -o BatchMode=yes -o ConnectTimeout=8 \
           -o StrictHostKeyChecking=accept-new "$mac_user@$addr" true 2>/dev/null; then
      ok "key authentication works"
    else
      warn "the key was copied but BatchMode authentication still fails."
      warn "Check permissions on the Mac: ~/.ssh must be 700, authorized_keys 600."
      return 1
    fi

    mkdir -p "$LIB_DIR"
    date '+%F %T' > "$MARKER"
    ok "phase A recorded in $MARKER"

    PHASE_A_USER="$mac_user"; PHASE_A_NAME="$mac_name"
    PHASE_A_KEY="$key";       PHASE_A_ADDR="$addr"
    export PHASE_A_USER PHASE_A_NAME PHASE_A_KEY PHASE_A_ADDR
  fi
}

# Asked on every re-run, whatever phase A concluded. Adding a network is the
# usual reason to run this again, and a Mac that cannot be reached may simply be
# somewhere this machine is not.
phase_a_followup() {
  local a addr on_our_network=0
  for a in $(configured_aliases || true); do
    addr=$(host_field "$a" Hostname)
    [ -n "$addr" ] || continue
    if same_subnet "$addr"; then
      on_our_network=1
      say ""
      say "  $a ($addr) is on a subnet this machine is attached to, so if the Mac"
      say "  is not answering there, it is the Mac and not the routing."
      confirm "Is the Mac switched on and reachable?" y || \
        warn "Switch it on and joined to that network before going further."
      break
    fi
  done

  if [ "$on_our_network" = 0 ]; then
    say ""
    say "  None of the configured addresses is on a subnet this machine can see."
    say "  That is normal for a Mac on a different network, and is not a fault."
  fi
}

# --- phase B ----------------------------------------------------------------
# One network. The Host block and the allowedDomains entry are written here
# because phase C needs both to reach the Mac at all. /etc/hosts waits until the
# address is final, which is after C has had its chance to change it.

SETTINGS="${SETTINGS:-$HOME/.claude/settings.json}"

# Phase A exports these on a fresh run. On a re-run they come back out of the
# files, which are the record — there is no cache to go stale.
resolve_from_existing() {
  local a
  MAC_USER="${PHASE_A_USER:-}"; MAC_KEY="${PHASE_A_KEY:-}"; MAC_NAME="${PHASE_A_NAME:-}"
  for a in $(configured_aliases || true); do
    [ -n "$MAC_USER" ] || MAC_USER=$(host_field "$a" User)
    [ -n "$MAC_KEY" ]  || MAC_KEY=$(host_field "$a" IdentityFile)
    [ -n "$MAC_USER" ] && [ -n "$MAC_KEY" ] && break
  done
  MAC_KEY="${MAC_KEY/#\~/$HOME}"
  # The .local name is in allowedDomains already if any network was set up.
  if [ -z "$MAC_NAME" ] && [ -r "$SETTINGS" ]; then
    MAC_NAME=$(jq -r '(.sandbox.network.allowedDomains // [])[]
                      | select(endswith(".local"))' "$SETTINGS" 2>/dev/null | head -1)
  fi
}

backup_of() { # backup_of <file> -> writes <file>.bak-<stamp>, prints the path
  local f="$1" b="$1.bak-$(date '+%Y%m%d-%H%M%S')"
  cp -p "$f" "$b"
  printf '%s' "$b"
}

ssh_block_hostname() { host_field "$1" Hostname; }

ssh_block_set_hostname() { # <alias> <addr>
  local tmp; tmp=$(mktemp)
  awk -v alias="$1" -v addr="$2" '
    /^[[:space:]]*Host[[:space:]]+/ { inblock = ($2 == alias) }
    inblock && tolower($1) == "hostname" { print "\tHostname " addr; next }
    { print }
  ' "$SSH_CONFIG" > "$tmp"
  cat "$tmp" > "$SSH_CONFIG"
  rm -f "$tmp"
}

ssh_block_append() { # <alias> <addr> <user> <key>
  # %s is doubled: ssh_config expands % itself, so a single %s never reaches the
  # shell. The ProxyCommand tunnels through the sandbox proxy when one is set
  # (inside a Claude session) and falls back to a direct connection when it is
  # not (an ordinary terminal, including this wizard).
  local key_short="${4/#$HOME/\~}"
  cat >> "$SSH_CONFIG" <<BLOCK

Host $1
	Hostname $2
	User $3
	IdentityFile $key_short
	ConnectTimeout 15
	ServerAliveInterval 30
	ProxyCommand sh -c 'if [ -n "\$grpc_proxy" ]; then A=\$(printf "%%s" "\$grpc_proxy" | sed -e "s|^http://||" -e "s|@.*||"); exec socat - PROXY:localhost:%h:%p,proxyport=3128,proxyauth=\$A; else exec nc %h %p; fi'
BLOCK
}

# $DROP_ADDR, if set, is removed in the same pass. An address that a Host block
# no longer points at is not the Mac any more, and leaving it behind means the
# list grows by one every time a network changes address.
allowed_domains_add() { # <value>...
  [ -r "$SETTINGS" ] || { warn "$SETTINGS does not exist — create it first"; return 1; }
  jq empty "$SETTINGS" 2>/dev/null || { warn "$SETTINGS is not valid JSON"; return 1; }
  local tmp; tmp=$(mktemp)
  local d
  cp "$SETTINGS" "$tmp"
  if [ -n "${DROP_ADDR:-}" ]; then
    jq --arg d "$DROP_ADDR" '
      .sandbox.network.allowedDomains =
        ((.sandbox.network.allowedDomains // []) | map(select(. != $d)))
    ' "$tmp" > "$tmp.next" && mv "$tmp.next" "$tmp"
  fi
  for d in "$@"; do
    jq --arg d "$d" '
      .sandbox.network.allowedDomains =
        ((.sandbox.network.allowedDomains // [])
         | if index($d) then . else . + [$d] end)
    ' "$tmp" > "$tmp.next" && mv "$tmp.next" "$tmp"
  done
  if diff -q <(jq -S . "$SETTINGS") <(jq -S . "$tmp") >/dev/null; then
    ok "allowedDomains already covers: $*"
    rm -f "$tmp"; return 0
  fi
  say ""
  say "  $SETTINGS would change:"
  diff <(jq -S . "$SETTINGS") <(jq -S . "$tmp") | sed 's/^/    /' || true
  say ""
  if confirm "Apply that?" y; then
    local b; b=$(backup_of "$SETTINGS")
    cat "$tmp" > "$SETTINGS"
    ok "written (backup: $b)"
  else
    warn "left unchanged — the Mac will read as switched off from inside a session"
  fi
  rm -f "$tmp"
}

phase_b() {
  step "Phase B — a network"
  resolve_from_existing
  if [ -z "${MAC_USER:-}" ] || [ -z "${MAC_KEY:-}" ]; then
    warn "no Mac user or key found — run phase A first"
    return 1
  fi

  mac_needed

  local alias addr existing
  say "  Name the alias for where the Mac is, not for the Mac: mac-a, mac-b."
  alias=$(ask "alias for this network")
  [ -n "$alias" ] || { warn "no alias given"; return 1; }

  existing=$(ssh_block_hostname "$alias" || true)
  [ -n "$existing" ] && say "  $alias already points at $existing."
  addr=$(ask "the Mac's address on this network" "$existing")
  [ -n "$addr" ] || { warn "no address given"; return 1; }

  say ""
  say "  Checking the Mac answers there before writing anything."
  if ssh -i "$MAC_KEY" -o BatchMode=yes -o ConnectTimeout=8 \
         -o StrictHostKeyChecking=accept-new "$MAC_USER@$addr" true 2>/dev/null; then
    ok "$addr answers and the key works"
  else
    warn "$addr did not answer. Refused means Remote Login is off; timed out means"
    warn "the wrong address, or the Mac is not on this network."
    confirm "Write the configuration anyway?" n || return 1
  fi

  # ~/.ssh/config is the user's file. Two blocks with the same Host name are not
  # merged — ssh takes the first value it obtains for each keyword, so the second
  # is silently dead. Hence update in place rather than append when one exists.
  local b
  if [ -n "$existing" ]; then
    if [ "$existing" = "$addr" ]; then
      ok "Host $alias already has Hostname $addr"
    else
      b=$(backup_of "$SSH_CONFIG")
      ssh_block_set_hostname "$alias" "$addr"
      ok "Host $alias: $existing -> $addr (backup: $b)"
      DROP_ADDR="$existing"
    fi
  else
    [ -e "$SSH_CONFIG" ] || { mkdir -p "$(dirname "$SSH_CONFIG")"; : > "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"; }
    b=$(backup_of "$SSH_CONFIG")
    ssh_block_append "$alias" "$addr" "$MAC_USER" "$MAC_KEY"
    ok "Host $alias added (backup: $b)"
  fi

  # The name covers curl through the proxy; the address covers the SSH tunnel,
  # which asks the proxy for a numeric host because that is what Hostname says.
  if [ -n "${MAC_NAME:-}" ]; then
    allowed_domains_add "$MAC_NAME" "$addr" || true
  else
    allowed_domains_add "$addr" || true
  fi
  DROP_ADDR=""

  B_ALIAS="$alias"; B_ADDR="$addr"
}

phase_c() {
  step "Phase C — a fixed address on the Mac"
  warn "not built yet. See BACKLOG.md item 85 for the settled design."
  say  "  It installs network-change.sh and the plist on the Mac, sets a static"
  say  "  address, cycles Wi-Fi and polls the new address."
}

write_etc_hosts() {
  step "/etc/hosts"
  warn "not built yet — it is written last, once the address is final."
}

# --- main -------------------------------------------------------------------

say "== maestro-remote-mac setup wizard"

command -v jq >/dev/null 2>&1 || {
  say "  jq is needed and is missing — install it and re-run."
  exit 1
}

if [ "$STATUS_ONLY" = 1 ]; then
  step "Phase A"
  [ -e "$MARKER" ] && ok "marker: $(cat "$MARKER")" || warn "no marker at $MARKER"
  phase_a_status || true
  step "Networks"
  for a in $(configured_aliases || true); do
    ok "$a -> $(ssh_block_hostname "$a")"
  done
  exit 0
fi

phase_a
phase_a_followup

# One pass per network. C is offered only after a network is added, because it
# can only configure the network the Mac is currently joined to, and /etc/hosts
# is written once at the end with whatever address ended up being final.
ADDED=0
while confirm "Set up a network now?" "$([ "$ADDED" = 0 ] && echo y || echo n)"; do
  if phase_b; then
    ADDED=1
    say ""
    say "  Phase C gives the Mac a fixed address on this network, so the address"
    say "  just written stays true. Skip it if your router does DHCP reservations."
    if confirm "Run phase C for $B_ALIAS?" n; then
      phase_c
    fi
  fi
  say ""
done

if [ "$ADDED" = 1 ]; then
  write_etc_hosts
else
  say ""
  say "  Nothing else to do. Re-run this any time you join a new network."
fi
