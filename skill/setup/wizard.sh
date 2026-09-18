#!/usr/bin/env bash
# Setup wizard for maestro-remote-mac — the SSH and network side.
#
#   ./wizard.sh            run it
#   ./wizard.sh --status   what is already in place, change nothing
#   ./wizard.sh --hosts    rewrite the /etc/hosts block only, to reorder it
#   ./wizard.sh --dry-run  ask everything, read everything, write nothing
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
# Only a fallback for a machine with nothing configured yet. Once any Host block
# exists, its IdentityFile is the real answer and is preferred — the name is a
# convention, not a fact, and assuming it is wrong on any machine that chose
# another.
FALLBACK_KEY="$HOME/.ssh/mac_rc"

STATUS_ONLY=0; HOSTS_ONLY=0; DRY=0
for a in "$@"; do
  case "$a" in
    --status)  STATUS_ONLY=1 ;;
    --hosts)   HOSTS_ONLY=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
# --dry-run prints what would be written and writes nothing. Reads still happen:
# probing the Mac, listing its networks and reading back the three files are all
# harmless, and a dry run that skipped them could not show what it would write.
would() { printf '  would  %s\n' "$*"; }
dry()   { [ "$DRY" = 1 ]; }

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
    # Assigned, not just declared: `local x` under `set -u` leaves x UNSET, and
    # on a machine with nothing configured the loops below never assign it. That
    # aborted the script on the one path that matters most — a fresh machine.
    local known_user="" known_name=""
    # Defaults come from what is already configured, never from this machine:
    # its own hostname is not the Mac's, which is what the first version offered.
    for _a in $(configured_aliases || true); do
      known_user=$(host_field "$_a" User); [ -n "$known_user" ] && break
    done
    known_name=$(jq -r '(.sandbox.network.allowedDomains // [])[]
                        | select(endswith(".local"))' \
                    "${SETTINGS:-$HOME/.claude/settings.json}" 2>/dev/null | head -1)
    [ -n "$known_name" ] || known_name=$(awk '/\.local$/ { print $2; exit }' "$HOSTS_FILE" 2>/dev/null)

    mac_user=$(ask "the Mac's username" "$known_user")
    mac_name=$(ask "the Mac's .local name" "$known_name")
    # A name with no dot is a short hostname; mDNS needs the suffix. Without
    # this an allowedDomains entry is written that resolves to nothing while
    # curl on the real name keeps failing.
    case "$mac_name" in *.*) ;; "") ;; *) mac_name="$mac_name.local"; ok "read as $mac_name" ;; esac
    if [ -n "$known_name" ] && [ "$mac_name" != "$known_name" ]; then
      warn "this machine already knows the Mac as $known_name."
      warn "Two names means one of them resolves to nothing."
      confirm "Use $mac_name anyway?" n || mac_name="$known_name"
    fi

    say ""
    say "  A key for this and nothing else. An existing one is fine — the Mac only"
    say "  has to trust it, and its type does not matter."
    local known_key=""
    for _a in $(configured_aliases || true); do
      known_key=$(host_field "$_a" IdentityFile); [ -n "$known_key" ] && break
    done
    known_key="${known_key/#\~/$HOME}"
    key=$(ask "key path, or blank to create one" "${known_key:-$FALLBACK_KEY}")
    key="${key/#\~/$HOME}"

    if [ -r "$key" ]; then
      ok "using existing key $key"
    else
      # -N '' is not optional. Every script in this package passes
      # BatchMode=yes, under which a passphrase prompt is not a prompt but an
      # immediate failure with no explanation.
      if dry; then
        would "create $key: ssh-keygen -t ed25519 -N '' -f $key -C maestro-remote-mac"
      else
        say "  Creating $key (ed25519, no passphrase)."
        ssh-keygen -t ed25519 -N '' -f "$key" -C "maestro-remote-mac" >/dev/null
        ok "created $key"
      fi
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
    if dry; then
      would "run: ssh-copy-id -i $key.pub $mac_user@$addr"
      would "then verify with: ssh -i $key -o BatchMode=yes $mac_user@$addr true"
      would "record phase A in $MARKER"
      PHASE_A_USER="$mac_user"; PHASE_A_NAME="$mac_name"
      PHASE_A_KEY="$key";       PHASE_A_ADDR="$addr"
      export PHASE_A_USER PHASE_A_NAME PHASE_A_KEY PHASE_A_ADDR
      return 0
    fi

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
    if ssh -n -i "$key" -o BatchMode=yes -o ConnectTimeout=8 \
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
  if dry; then printf '%s' "(none taken, dry run)"; return 0; fi
  cp -p "$f" "$b"
  printf '%s' "$b"
}

ssh_block_hostname() { host_field "$1" Hostname; }

ssh_block_set_hostname() { # <alias> <addr>
  if dry; then would "set Hostname to $2 in the Host $1 block of $SSH_CONFIG"; return 0; fi
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
  if dry; then
    would "append a Host $1 block to $SSH_CONFIG:"
    printf '           Hostname %s / User %s / IdentityFile %s / ProxyCommand via socat\n' \
      "$2" "$3" "${4/#$HOME/\~}"
    return 0
  fi
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
  if dry; then
    would "apply that to $SETTINGS"
    rm -f "$tmp"; return 0
  fi
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
  # Trailing whitespace on an alias is invisible here and fatal later: the Host
  # block would carry it and `ssh <alias>` would not match.
  alias=$(printf '%s' "$alias" | tr -d '[:space:]')
  [ -n "$alias" ] || { warn "no alias given"; return 1; }

  existing=$(ssh_block_hostname "$alias" || true)
  [ -n "$existing" ] && say "  $alias already points at $existing."
  # Phase A asked where the Mac is and proved the key against it, so that
  # address is both fresher and already verified. It wins over whatever the
  # block recorded on an earlier run; the line above still shows the difference.
  addr=$(ask "the Mac's address on this network" "${PHASE_A_ADDR:-$existing}")
  [ -n "$addr" ] || { warn "no address given"; return 1; }

  say ""
  say "  Checking the Mac answers there before writing anything."
  if ssh -n -i "$MAC_KEY" -o BatchMode=yes -o ConnectTimeout=8 \
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
      dry || ok "Host $alias: $existing -> $addr (backup: $b)"
      DROP_ADDR="$existing"
    fi
  else
    if [ ! -e "$SSH_CONFIG" ] && ! dry; then
      mkdir -p "$(dirname "$SSH_CONFIG")"; : > "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"
    fi
    b=$(backup_of "$SSH_CONFIG")
    ssh_block_append "$alias" "$addr" "$MAC_USER" "$MAC_KEY"
    dry || ok "Host $alias added (backup: $b)"
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

# --- phase C ----------------------------------------------------------------
# Optional. It gives the Mac a fixed address on this network, so the address
# phase B just wrote stays true. A router doing DHCP reservations achieves the
# same thing with nothing installed on the Mac.
#
# Two files go on the Mac, both needing root there, so the install itself is a
# command the user runs — sudo on the Mac has no passwordless path.
#
# The SSID table is per-machine configuration, not package content: it is the
# LAN layout of every network that Mac joins. The vendored script carries one
# example block; the real entries are spliced in here and never enter the repo.

REMOTE_SCRIPT="/usr/local/bin/network-change.sh"
REMOTE_PLIST="/Library/LaunchDaemons/networkChange.plist"
VENDORED_SCRIPT="$(dirname "$0")/network-change.sh"
VENDORED_PLIST="$(dirname "$0")/networkChange.plist"

# How phase C reaches the Mac. The alias is preferred once its Host block
# exists, but it may not: --dry-run describes the block without writing it, so
# `ssh <alias>` would try to resolve the alias as a hostname and hang. Falling
# back to the key and address needs nothing to have been written yet.
C_SSH=()
c_target() { # c_target <alias> <addr>
  if [ -n "$(ssh_block_hostname "$1")" ] && ! dry; then
    C_SSH=("$1")
  else
    C_SSH=(-i "$MAC_KEY" "$MAC_USER@$2")
  fi
}

# Always succeeds, printing nothing when the Mac cannot be reached. The `|| true`
# is load-bearing: this file runs under `set -e`, and `x=$(mac_run ...)` with a
# failing ssh takes the whole script down before the caller can check whether
# the value came back empty. That is what made a failed phase C look like a hang
# at its own header, with no message and exit 255.
# -n on every ssh in this file. A successful ssh reads and discards whatever is
# on stdin, and stdin here is where `ask` and `confirm` get their answers — so a
# probe against a Mac that ANSWERS silently ate the rest of the run's input.
# Interactively it is invisible, because a person has not typed ahead; it only
# bites a scripted run, and only when the Mac is reachable, which is why every
# earlier test missed it (measured 18 Sep 2026: a three-line stream, and `read`
# after one successful probe returned nothing). Not ssh-copy-id, which must keep
# its stdin to read the password.
mac_run() { # mac_run <ignored> <command> -> stdout, empty if unreachable
  ssh -n -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
      "${C_SSH[@]}" "$2" 2>/dev/null || true
}

static_default() { # <address> -> same network, last octet 250
  printf '%s' "$1" | awk -F. 'NF==4 { print $1"."$2"."$3".250" }'
}

# Insert or replace one SSID arm, immediately before the `*)` default. Replacing
# matters as much as inserting: a second run for the same network must not leave
# two arms, because the first one wins and the second is dead.
splice_profile() { # splice_profile <script-file> <ssid> <profile-line>
  SSID="$2" PROFILE="$3" python3 - "$1" <<'PY'
import os, re, sys

path = sys.argv[1]
ssid = os.environ["SSID"]
profile = os.environ["PROFILE"]

with open(path) as fh:
    text = fh.read()

arm = '    "%s")\n      echo "%s"\n      ;;\n' % (ssid, profile)

# Drop any existing arm for this SSID, then insert before the default.
pattern = re.compile(
    r'[ \t]*"%s"\)\n(?:.*\n)*?[ \t]*;;\n' % re.escape(ssid))
text, dropped = pattern.subn('', text)

marker = "    *)\n"
if marker not in text:
    sys.stderr.write("no default arm found in %s\n" % path)
    raise SystemExit(1)
text = text.replace(marker, arm + marker, 1)

with open(path, "w") as fh:
    fh.write(text)
print("replaced" if dropped else "added")
PY
}

# The vendored script ships one example arm so the file makes sense on its own.
# It has no business on a real Mac.
drop_profile() { # drop_profile <script-file> <ssid>
  SSID="$2" python3 - "$1" <<'PY'
import os, re, sys
path, ssid = sys.argv[1], os.environ["SSID"]
with open(path) as fh:
    text = fh.read()
text, n = re.subn(r'[ \t]*"%s"\)\n(?:.*\n)*?[ \t]*;;\n' % re.escape(ssid), '', text)
with open(path, "w") as fh:
    fh.write(text)
PY
}

phase_c() {
  step "Phase C — a fixed address on the Mac"
  local alias="$B_ALIAS" addr="$B_ADDR"
  c_target "$alias" "$addr"

  mac_needed
  say "  Phase C can only configure the network the Mac is joined to right now,"
  say "  because every value below is read from the live interface."
  say ""

  local dev ssid ssid_list mask gw dns
  dev=$(mac_run "$alias" 'networksetup -listallhardwareports | awk "/Hardware Port: Wi-Fi/ { getline; print \$2; exit }"')
  [ -n "$dev" ] || { warn "no Wi-Fi device found on the Mac"; return 1; }
  ok "Wi-Fi device: $dev"

  ssid=$(mac_run "$alias" "ipconfig getsummary $dev | awk -F' SSID : ' '/ SSID : / { print \$2; exit }'")
  ssid_list=$(mac_run "$alias" "networksetup -listpreferredwirelessnetworks $dev | sed '1d;s/^[[:space:]]*//'")

  if [ -n "$ssid_list" ]; then
    say ""
    say "  Networks this Mac knows:"
    printf '%s\n' "$ssid_list" | sed 's/^/    /'
  fi
  say ""
  say "  The name must match exactly, trailing spaces included — the script"
  say "  compares it literally and a near miss falls through to plain DHCP."
  ssid=$(ask "SSID for this network" "$ssid")
  [ -n "$ssid" ] || { warn "no SSID given"; return 1; }

  local info
  info=$(mac_run "$alias" "networksetup -getinfo \"\$(networksetup -listnetworkserviceorder | awk -v d=$dev '/^\\([0-9]+\\)/ { name = substr(\$0, index(\$0, \")\") + 2) } index(\$0, \"Device: \" d \")\") { print name; exit }')\"")
  mask=$(printf '%s\n' "$info" | awk -F': ' '/^Subnet mask:/ { print $2; exit }')
  gw=$(printf '%s\n' "$info"   | awk -F': ' '/^Router:/ { print $2; exit }')
  [ -n "$gw" ] || gw=$(mac_run "$alias" "netstat -rn -f inet | awk '/^default/ { print \$2; exit }'")
  # Deduped but NOT sorted. Resolvers are tried in order and the gateway belongs
  # first, so local names resolve before anything leaves the network; sorting
  # puts 1.1.1.1 in front of it and quietly changes what the Mac does.
  dns=$(mac_run "$alias" "scutil --dns | awk '/nameserver\\[[0-9]+\\]/ && !seen[\$3]++ { print \$3 }' | tr '\\n' ' '")
  # If the gateway is in the list, it leads.
  dns=$(GW="$gw" DNS="$dns" python3 -c '
import os
gw = os.environ["GW"].strip()
servers = os.environ["DNS"].split()
if gw in servers:
    servers = [gw] + [x for x in servers if x != gw]
print(" ".join(servers))
')

  mask=$(ask "subnet mask" "$mask")
  gw=$(ask "gateway" "$gw")
  dns=$(ask "DNS servers, space separated, in try order" "${dns:-$gw 1.1.1.1 8.8.8.8}")

  # The router's DHCP pool is not visible from the Mac, so the address cannot be
  # derived — only proposed. .250 is high enough to sit above most pools.
  local static
  static=$(ask "static address for the Mac" "$(static_default "$addr")")
  [ -n "$static" ] || { warn "no address given"; return 1; }
  if [ "$static" != "$addr" ] && mac_run "$alias" "ping -c 2 -t 3 $static >/dev/null 2>&1 && echo taken" | grep -q taken; then
    warn "$static already answers — something else holds it. Pick another."
    return 1
  fi
  say "  It must sit outside the router's DHCP pool, which the Mac cannot see."
  confirm "Is $static outside the pool?" y || { warn "pick one that is, and re-run phase C"; return 1; }

  # Start from what the Mac already has, so a second network adds an arm rather
  # than replacing the first network's profile with a one-entry table.
  local work; work=$(mktemp)
  if mac_run "$alias" "test -r $REMOTE_SCRIPT" && mac_run "$alias" "cat $REMOTE_SCRIPT" > "$work" && [ -s "$work" ]; then
    ok "starting from the script already on the Mac"
  else
    cp "$VENDORED_SCRIPT" "$work"
    drop_profile "$work" "Example Network Name"
    ok "starting from the vendored script"
  fi

  local action
  action=$(splice_profile "$work" "$ssid" "manual $static $mask $gw $dns") || {
    warn "could not splice the profile"; rm -f "$work"; return 1; }
  ok "profile $action for \"$ssid\""
  bash -n "$work" || { warn "the spliced script does not parse"; rm -f "$work"; return 1; }

  local stage="/tmp/network-change.sh.new"
  if dry; then
    would "copy the spliced script to $alias:$stage and the plist to $alias:/tmp/"
    say ""
    say "  The profile line it would add:"
    say "    \"$ssid\") -> manual $static $mask $gw $dns"
    rm -f "$work"
    return 0
  fi
  scp -o BatchMode=yes -q "$work" "$alias:$stage" || { warn "could not copy to the Mac"; rm -f "$work"; return 1; }
  scp -o BatchMode=yes -q "$VENDORED_PLIST" "$alias:/tmp/networkChange.plist" || true
  rm -f "$work"

  say ""
  say "  Both files need root on the Mac, and sudo there has no passwordless"
  say "  path. Run this in a terminal on the Mac, or over your own ssh:"
  say ""
  say "    sudo cp -p $REMOTE_SCRIPT $REMOTE_SCRIPT.bak 2>/dev/null"
  say "    sudo install -m 755 -o root -g wheel $stage $REMOTE_SCRIPT"
  say "    sudo install -m 644 -o root -g wheel /tmp/networkChange.plist $REMOTE_PLIST"
  say "    sudo launchctl bootout system $REMOTE_PLIST 2>/dev/null"
  say "    sudo launchctl bootstrap system $REMOTE_PLIST"
  say ""
  confirm "Done?" n || { warn "phase C stopped — nothing on the Mac has changed"; return 1; }

  c_cycle_and_verify "$alias" "$dev" "$static"
}

# The cycle proves the WatchPaths trigger fires, which RunAtLoad alone does not.
# It drops the connection it runs over, by design.
c_cycle_and_verify() { # <alias> <device> <static>
  say ""
  say "  Cycling Wi-Fi on the Mac. This drops the connection on purpose."
  # Detached, or SIGHUP kills it between off and on and the Mac stays off the
  # network. The leading sleep lets ssh return an exit code rather than a
  # broken pipe.
  ssh -n -o BatchMode=yes "${C_SSH[@]}" \
    "nohup /bin/sh -c 'sleep 2; networksetup -setairportpower $2 off; sleep 5; networksetup -setairportpower $2 on' >/dev/null 2>&1 </dev/null &" \
    || warn "the cycle command did not return cleanly; continuing to poll"

  # Wait for the drop before waiting for the recovery. A poll that starts
  # immediately succeeds on the connection it is about to lose, which reads as
  # success and is not.
  local i seen_down=0
  for i in $(seq 1 40); do
    if ssh -n -o BatchMode=yes -o ConnectTimeout=6 "${C_SSH[@]}" true 2>/dev/null; then
      if [ "$seen_down" = 1 ]; then
        ok "back up at $3"
        mac_run "$1" 'tail -4 /tmp/netchange.log' | sed 's/^/    /'
        return 0
      fi
    else
      seen_down=1
    fi
  done
  warn "the Mac did not come back within the poll window."
  warn "Check it is associated, and that $2 is the address it now holds."
  return 1
}

# --- /etc/hosts -------------------------------------------------------------
# Written last, once every address is final. It is the only one of the three
# files nothing else needs: SSH reaches the Mac by the Host block's literal
# Hostname, and the sandbox proxy needs the address in allowedDomains. Only curl
# on the .local name needs this.
#
# Every address is listed at once, deliberately: the resolver returns them all
# and the client tries each in turn, so the name follows the Mac between
# networks with nothing to change. The cost is that all but one are dead on any
# given network and each one ahead of the live address is a connect timeout —
# file order is try order, so the network used most often goes first.

HOSTS_FILE="${HOSTS_FILE:-/etc/hosts}"
HOSTS_MARKER="# mac for ios simulator work"

# The Host block on disk, or the address this run just configured for it.
hosts_addr_for() { # <alias>
  local a; a=$(ssh_block_hostname "$1")
  if [ -z "$a" ] && [ "$1" = "${B_ALIAS:-}" ]; then a="${B_ADDR:-}"; fi
  printf '%s' "$a"
}

write_etc_hosts() {
  step "/etc/hosts"
  resolve_from_existing
  if [ -z "${MAC_NAME:-}" ]; then
    # The .local name is read back from settings.json's allowedDomains, so
    # declining the settings.json step costs this one too. Saying "nothing to
    # map" describes the cause and reads as though there were nothing to do.
    warn "no .local name known, so $HOSTS_FILE cannot be written."
    warn "It is read back from $SETTINGS; the earlier step was declined or that"
    warn "file carries no .local name. Re-run and accept it, or add the line by"
    warn "hand — without it the Mac's name will not resolve from this machine."
    return 0
  fi

  local aliases addr first ordered=""
  aliases=$(configured_aliases || true)
  # The network configured in THIS run counts even if its Host block is not on
  # disk yet — a dry run describes the block rather than writing it, and on a
  # fresh machine that block is the only one there is. Without this the last
  # step of a first run reports nothing to do.
  # configured_aliases prints one per LINE, so the membership test has to be
  # newline-delimited too. Matching `*" $B_ALIAS "*` against a newline-separated
  # list never matches anything but the first entry, and the alias just written
  # was appended a second time — the /etc/hosts step then offered the same
  # network twice as "which do you use most". Measured 18 Sep 2026.
  if [ -n "${B_ALIAS:-}" ]; then
    case $'\n'"$aliases"$'\n' in
      *$'\n'"$B_ALIAS"$'\n'*) ;;
      *) aliases="$aliases"$'\n'"$B_ALIAS" ;;
    esac
  fi
  aliases=$(printf '%s\n' $aliases)
  [ -n "$aliases" ] || { warn "no configured networks — skipping"; return 0; }

  say "  Every configured address maps to $MAC_NAME. The first one listed is"
  say "  tried first, so name the network you are on most often."
  say ""
  for a in $aliases; do
    printf '    %-18s %s\n' "$a" "$(hosts_addr_for "$a")"
  done
  say ""
  # File order is not an answer to "which do you use most" — it is just whichever
  # Host block happens to be first. Offer the one the Mac is reachable on right
  # now, which is at least a fact, and no default when none answers.
  local live=""
  for a in $aliases; do
    if ssh -n -o BatchMode=yes -o ConnectTimeout=4 "$a" true 2>/dev/null; then
      live="$a"; say "  $a answers right now."; break
    fi
  done
  first=$(ask "network to try first" "$live")

  for a in $first $aliases; do
    case " $ordered " in *" $a "*) continue ;; esac
    addr=$(hosts_addr_for "$a")
    [ -n "$addr" ] || continue
    ordered="$ordered $a"
  done

  local block; block="$HOSTS_MARKER"$'\n'
  for a in $ordered; do
    block="$block$(hosts_addr_for "$a") $MAC_NAME"$'\n'
  done

  say ""
  say "  These lines, replacing whatever sits under the marker now:"
  say ""
  printf '%s' "$block" | sed 's/^/    /'
  say ""

  # Needs root, and it is the one file outside the user's home directory that
  # this touches. Default is no: printing the lines is always safe, writing
  # them is a decision.
  if ! confirm "Write $HOSTS_FILE with sudo?" n; then
    say ""
    say "  Add them yourself — sudo \$EDITOR $HOSTS_FILE — replacing any existing"
    say "  block under the same marker."
    return 0
  fi

  local tmp; tmp=$(mktemp)
  MARKER_TEXT="$HOSTS_MARKER" BLOCK="$block" python3 - "$HOSTS_FILE" > "$tmp" <<'PY'
import os, sys

marker = os.environ["MARKER_TEXT"]
block = os.environ["BLOCK"]

try:
    with open(sys.argv[1]) as fh:
        lines = fh.read().split("\n")
except OSError:
    lines = []

out, i, replaced = [], 0, False
while i < len(lines):
    if lines[i].strip() == marker.strip():
        # Drop the marker and the contiguous address lines under it; anything
        # else in the file is untouched.
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith("#"):
            i += 1
        out.append(block.rstrip("\n"))
        replaced = True
        continue
    out.append(lines[i])
    i += 1

if not replaced:
    while out and not out[-1].strip():
        out.pop()
    out.append("")
    out.append(block.rstrip("\n"))

sys.stdout.write("\n".join(out).rstrip("\n") + "\n")
PY

  say ""
  say "  $HOSTS_FILE would change:"
  diff "$HOSTS_FILE" "$tmp" | sed 's/^/    /' || true
  say ""
  if dry; then
    would "back up $HOSTS_FILE and write the block above, with sudo"
    rm -f "$tmp"; return 0
  fi
  if confirm "Apply that?" n; then
    # Both sudo calls are checked. This function is called as
    # `write_etc_hosts || warn`, and a function invoked with `||` runs with
    # `set -e` suspended for its whole body — so a failing sudo does not abort
    # here, and an unconditional `ok "written"` reported a write that had not
    # happened. Measured 18 Sep 2026 against a sandbox whose sudo is not setuid:
    # two "sudo: must be owned by uid 0" lines, then `ok written`, with the file
    # untouched. /etc/hosts is the third leg of the all-three-or-none this whole
    # script is about, so a false success here is the exact failure it exists to
    # prevent.
    if sudo cp -p "$HOSTS_FILE" "$HOSTS_FILE.bak-$(date '+%Y%m%d-%H%M%S')" &&
       sudo cp "$tmp" "$HOSTS_FILE"; then
      ok "written"
    else
      warn "sudo did not run, so $HOSTS_FILE is UNCHANGED. The ssh config and"
      warn "settings.json were written, so this machine is now two of three:"
      warn "$MAC_NAME will not resolve until this file is written by hand."
      rm -f "$tmp"; return 1
    fi
  else
    warn "left unchanged — curl on $MAC_NAME will not resolve"
  fi
  rm -f "$tmp"
}

# --- main -------------------------------------------------------------------

say "== maestro-remote-mac setup wizard"
dry && say "   --dry-run: everything is asked and read, nothing is written."

command -v jq >/dev/null 2>&1 || {
  say "  jq is needed and is missing — install it and re-run."
  exit 1
}

if [ "$HOSTS_ONLY" = 1 ]; then
  write_etc_hosts
  exit 0
fi

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
# One network per run, not a loop. A second network cannot be finished in the
# same run anyway: phase C reads every value off the interface the Mac is joined
# to right now, and phase B's probe against an address the Mac is not on will
# fail, so the Host block would be written unverified. Joining the other network
# is a step outside this script, and re-running it afterwards is the same code.
ADDED=0
if confirm "Set up a network now?" y; then
  if phase_b; then
    ADDED=1
    say ""
    say "  Phase C gives the Mac a fixed address on this network, so the address"
    say "  just written stays true. Skip it if your router does DHCP reservations."
    # `|| warn` is load-bearing under `set -e`: a phase that reports failure by
    # returning non-zero is the last command of this branch, so without it the
    # script exits at the `fi` and nothing after it runs. Reporting and carrying
    # on is the point — one phase failing is not the run failing.
    if confirm "Run phase C for $B_ALIAS?" n; then
      phase_c || warn "phase C did not complete for $B_ALIAS"
    fi
    say ""
    ok "$B_ALIAS is done."
  fi
fi

if [ "$ADDED" = 1 ]; then
  write_etc_hosts || warn "/etc/hosts was not written"
  say ""
  say "  Join another network and re-run this to add it. Phase A is skipped from"
  say "  now on, so it is two questions and a check."
else
  say ""
  say "  Nothing else to do. Re-run this any time you join a new network."
fi
