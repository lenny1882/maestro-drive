#!/bin/bash
#
# on-network-change.sh
#
# Applies a per-SSID IPv4 profile to the Wi-Fi service. Three outcomes:
#   inform <ip> [dns...]              -> manual address, everything else from DHCP
#   manual <ip> <mask> <gw> [dns...]  -> fully static
#   SSID not listed                   -> plain DHCP, DNS back to automatic
#
# Idempotent: reads the live ConfigMethod from the SystemConfiguration store
# and exits without touching anything if it already matches. Safe to fire
# repeatedly from launchd WatchPaths, which triggers 2-3 times per real change.
#
# Must run as root (networksetup writes require it).
#

set -u
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

# ----------------------------------------------------------------- config --

# Per-SSID profiles. First word selects the mode:
#
#   inform <ip> [dns...]              address only; mask/router from DHCP
#   manual <ip> <mask> <gw> [dns...]  full static configuration
#
# Trailing DNS servers are optional in both modes. Omit them to leave DNS
# alone. NOTE: a case statement, not an associative array -- /bin/bash on
# macOS is still 3.2 and has no `declare -A`.
#
# ONE EXAMPLE BLOCK IS SHIPPED. Add one per network you want the Mac to hold a
# fixed address on; every other network falls through to `*)` and gets plain
# DHCP. The real table is local configuration, not package content -- it is the
# LAN layout of every network this Mac joins, so it does not belong in git.
#
# ---- what the values mean -------------------------------------------------
#
#   SSID    The network name EXACTLY as macOS reports it, including any
#           trailing spaces. Some access points advertise them and the match is
#           literal, so a name that looks right can still fall through to DHCP.
#           Quote it.
#   <ip>    The address this Mac should hold on that network. Pick one OUTSIDE
#           the router's DHCP pool, or the router will eventually lease it to
#           something else and you get an address clash that presents as the
#           Mac being intermittently unreachable. This is the address that goes
#           in ~/.ssh/config, /etc/hosts and allowedDomains on the client.
#   <mask>  The subnet mask of that network, e.g. 255.255.255.0. Copy it from
#           the network itself (below) rather than assuming a /24 -- a /22 that
#           is entered as a /24 works until you talk to something in the other
#           three quarters of the range.
#   <gw>    The default gateway -- the router's own address on that subnet.
#   [dns]   DNS servers, in order, space separated. Usually the gateway first
#           so local names still resolve, then public resolvers as fallback.
#           Omit entirely to leave whatever DNS is already configured alone.
#
# ---- finding the values ---------------------------------------------------
#
# Join the network first, let it settle on DHCP, then read back what the
# network handed out. Run these on the Mac, in Terminal:
#
#   # The Wi-Fi device (do not assume en0):
#   networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/ { getline; print $2 }'
#
#   # The service name that device maps to (usually "Wi-Fi", user-renameable):
#   networksetup -listnetworkserviceorder | grep -B1 "Device: en0"
#
#   # The SSID, exactly as macOS sees it. The `sed -n l` prints it in a form
#   # that makes trailing spaces visible -- they show as literal spaces before
#   # the terminating $:
#   ipconfig getsummary en0 | awk -F' SSID : ' '/ SSID : / { print $2; exit }' | sed -n l
#
#   # Address, mask and router currently in use on this network:
#   networksetup -getinfo "Wi-Fi"
#
#   # The default gateway, confirmed from the routing table:
#   netstat -rn -f inet | awk '/^default/ { print $2; exit }'
#
#   # The DNS servers DHCP handed out (what you would keep unless overriding):
#   scutil --dns | awk '/nameserver\[[0-9]+\]/ { print $3 }' | sort -u
#
#   # Whether an address you are considering is already taken. Silence for a
#   # few seconds means free; a reply means pick another:
#   ping -c 3 192.0.2.50
#
# The DHCP pool's range is not visible from the Mac -- read it off the router's
# admin page, and choose an address below the pool's start or above its end.
#
# ---- checking it works ----------------------------------------------------
#
#   sudo /usr/local/bin/network-change.sh    # run it by hand; it logs what it did
#   tail -f /tmp/netchange.log               # and what the daemon does on its own
#
# It is idempotent, so a second run on an unchanged network should print
# "already static ... -- no change" and touch nothing.
#
profile_for_ssid() {
  case "$1" in
    "Example Network Name")
      echo "manual 192.0.2.50 255.255.255.0 192.0.2.1 192.0.2.1 1.1.1.1 8.8.8.8"
      ;;
    *)
      return 1
      ;;
  esac
}

STATE_DIR="/var/run/netchange"
LOCK_DIR="${STATE_DIR}/lock"
STALE_LOCK_MINUTES=2
SETTLE_SECONDS=2      # let the interface finish associating before we look
TAG="netchange"

# ---------------------------------------------------------------- helpers --

log()  { /usr/bin/logger -t "$TAG" -- "$*"; printf '%s %s\n' "$(date '+%F %T')" "$*"; }
die()  { log "ERROR: $*"; exit 1; }

# Atomic lock. launchd can fire several instances within a second or two of
# each other; without this they race on networksetup and log confusingly.
acquire_lock() {
  /bin/mkdir -p "$STATE_DIR" 2>/dev/null
  if ! /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    if [ -n "$(/usr/bin/find "$LOCK_DIR" -maxdepth 0 -mmin "+${STALE_LOCK_MINUTES}" 2>/dev/null)" ]; then
      log "removing stale lock"
      /bin/rmdir "$LOCK_DIR" 2>/dev/null
      /bin/mkdir "$LOCK_DIR" 2>/dev/null || exit 0
    else
      exit 0   # another instance is mid-flight; it will see the same state
    fi
  fi
  trap '/bin/rmdir "$LOCK_DIR" 2>/dev/null' EXIT INT TERM
}

# en0 on most Macs, but don't assume.
wifi_device() {
  networksetup -listallhardwareports \
    | awk '/Hardware Port: Wi-Fi/ { getline; print $2; exit }'
}

# The networksetup *service* name for that device. Usually "Wi-Fi", but it is
# user-renameable and every networksetup write needs the service name.
service_for_device() {
  local dev="$1"
  networksetup -listnetworkserviceorder | awk -v dev="$dev" '
    /^\([0-9]+\)/ { name = substr($0, index($0, ")") + 2) }
    index($0, "Device: " dev ")") { print name; exit }
  '
}

# The SystemConfiguration service UUID for that device. Needed because
# `networksetup -getinfo` cannot distinguish DHCP from DHCP-with-manual-address.
service_id_for_device() {
  local dev="$1" id
  for id in $(scutil <<< "list Setup:/Network/Service/[^/]+/Interface" \
              | sed -n 's|.*Setup:/Network/Service/\([0-9A-Fa-f-]*\)/Interface.*|\1|p'); do
    if scutil <<< "show Setup:/Network/Service/${id}/Interface" \
       | grep -q "DeviceName : ${dev}\$"; then
      printf '%s' "$id"
      return 0
    fi
  done
  return 1
}

# Prints "<ConfigMethod> <first configured address>".
# ConfigMethod is DHCP | INFORM | Manual — INFORM is "DHCP with manual address".
ipv4_config() {
  local out
  out=$(scutil <<< "show Setup:/Network/Service/${1}/IPv4" 2>/dev/null)
  printf '%s %s' \
    "$(printf '%s\n' "$out" | awk '/ConfigMethod[[:space:]]*:/ { print $3; exit }')" \
    "$(printf '%s\n' "$out" | awk '
        /Addresses[[:space:]]*:/          { in_addr = 1; next }
        in_addr && /^[[:space:]]*0[[:space:]]*:/ { print $3; exit }
      ')"
}

# SSID lookup. The airport binary was removed in macOS 14.4, so try the
# supported routes in order and fall back.
current_ssid() {
  local dev="$1" ssid=""

  ipconfig setverbose 1 2>/dev/null
  ssid=$(ipconfig getsummary "$dev" 2>/dev/null \
         | awk -F' SSID : ' '/ SSID : / { print $2; exit }')
  [ -n "$ssid" ] && { printf '%s' "$ssid"; return 0; }
  ipconfig setverbose 0 2>/dev/null

  ssid=$(networksetup -getairportnetwork "$dev" 2>/dev/null \
         | sed -n 's/^Current Wi-Fi Network: //p')
  [ -n "$ssid" ] && { printf '%s' "$ssid"; return 0; }

  # Slow (~2s) but works when the others are blocked.
  ssid=$(system_profiler SPAirPortDataType 2>/dev/null \
         | awk '/Current Network Information:/ { getline; gsub(/^ +| +:$/, ""); print; exit }')
  printf '%s' "$ssid"
}

field() {   # field "<label>" "<networksetup -getinfo output>"
  printf '%s\n' "$2" | awk -F': ' -v k="^$1:" '$0 ~ k { print $2; exit }'
}

current_dns() {
  local out
  out=$(networksetup -getdnsservers "$1" 2>/dev/null)
  case "$out" in
    *"aren't any DNS Servers"*) printf '' ;;
    *) printf '%s' "$(printf '%s\n' "$out" | tr '\n' ' ' | sed 's/ *$//')" ;;
  esac
}

dns_already_ok() {   # empty desired DNS means "don't care"
  [ -z "$1" ] || [ "$(current_dns "$SVC")" = "$1" ]
}

apply_dns() {
  [ -n "$1" ] || return 0
  # shellcheck disable=SC2086
  networksetup -setdnsservers "$SVC" $1 || log "WARN: setdnsservers failed"
}

# ------------------------------------------------------------------- main --

acquire_lock
sleep "$SETTLE_SECONDS"

DEV=$(wifi_device)
[ -n "$DEV" ] || die "no Wi-Fi hardware port found"

SVC=$(service_for_device "$DEV")
[ -n "$SVC" ] || die "no network service maps to device $DEV"

SVC_ID=$(service_id_for_device "$DEV") \
  || die "no SystemConfiguration service found for device $DEV"

SSID=$(current_ssid "$DEV")
if [ -z "$SSID" ]; then
  log "Wi-Fi ($DEV) not associated — leaving configuration alone"
  exit 0
fi

read -r CUR_METHOD CUR_ADDR <<< "$(ipv4_config "$SVC_ID")"
CUR_METHOD="${CUR_METHOD:-unknown}"

if PROFILE=$(profile_for_ssid "$SSID"); then
  # shellcheck disable=SC2086
  set -- $PROFILE
  MODE="$1"; shift

  case "$MODE" in
    inform)
      WANT_IP="$1"; shift
      WANT_DNS="$*"

      if [ "$CUR_METHOD" = "INFORM" ] && [ "$CUR_ADDR" = "$WANT_IP" ] \
         && dns_already_ok "$WANT_DNS"; then
        log "[$SSID] already DHCP-with-manual-address $WANT_IP — no change"
        exit 0
      fi

      log "[$SSID] setting address $WANT_IP, mask/router from DHCP (was $CUR_METHOD $CUR_ADDR)"
      networksetup -setmanualwithdhcprouter "$SVC" "$WANT_IP" \
        || die "setmanualwithdhcprouter failed for $SVC"
      apply_dns "$WANT_DNS"
      ;;

    manual)
      WANT_IP="$1"; WANT_MASK="$2"; WANT_ROUTER="$3"; shift 3
      WANT_DNS="$*"

      INFO=$(networksetup -getinfo "$SVC")
      if [ "$CUR_METHOD" = "Manual" ] && [ "$CUR_ADDR" = "$WANT_IP" ] \
         && [ "$(field 'Subnet mask' "$INFO")" = "$WANT_MASK" ] \
         && [ "$(field 'Router' "$INFO")" = "$WANT_ROUTER" ] \
         && dns_already_ok "$WANT_DNS"; then
        log "[$SSID] already static $WANT_IP — no change"
        exit 0
      fi

      log "[$SSID] setting static $WANT_IP/$WANT_MASK gw $WANT_ROUTER (was $CUR_METHOD $CUR_ADDR)"
      networksetup -setmanual "$SVC" "$WANT_IP" "$WANT_MASK" "$WANT_ROUTER" \
        || die "setmanual failed for $SVC"
      apply_dns "$WANT_DNS"
      ;;

    *)
      die "[$SSID] unknown profile mode '$MODE' — expected 'inform' or 'manual'"
      ;;
  esac
else
  if [ "$CUR_METHOD" = "DHCP" ] && [ -z "$(current_dns "$SVC")" ]; then
    log "[$SSID] already DHCP — no change"
    exit 0
  fi

  log "[$SSID] not in profile set — reverting to DHCP (was $CUR_METHOD $CUR_ADDR)"
  networksetup -setdhcp "$SVC" || die "setdhcp failed for $SVC"
  networksetup -setdnsservers "$SVC" Empty || log "WARN: clearing DNS failed"
fi

printf '%s\t%s\n' "$(date '+%F %T')" "$SSID" > "${STATE_DIR}/last"
log "[$SSID] done"
