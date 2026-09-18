#!/bin/bash
# Shared SSH plumbing. Source this, do not run it.
# shellcheck disable=SC1090
# config.sh returns non-zero when the project is not configured. Without the
# guard the caller carries on with an empty MAC_HOST and fails obscurely inside
# ssh instead of on the message that says what to do.
. "$(dirname "${BASH_SOURCE[0]}")/config.sh" || exit 1

mkdir -p "$LDIR"

# Where the runner modules are, on each side (BACKLOG item 87). Plain paths
# rather than a call to bin/runner.sh: runner.sh sources THIS file, and every
# _dev would otherwise pay for a subprocess to learn something config.sh already
# knows. runner.sh validates them and lists the alternatives; these do not.
PLATFORM_SH="$RMODS/${PLATFORM:-ios}/platform.sh"
FRAMEWORK_SH="$RMODS/${RUNNER:-flutter}/framework.sh"
PLATFORM_SH_LOCAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../runners" && pwd)/${PLATFORM:-ios}/platform.sh"
FRAMEWORK_SH_LOCAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../runners" && pwd)/${RUNNER:-flutter}/framework.sh"

# No ControlMaster: it fails inside the sandbox with "muxclient socket():
# Operation not permitted", and each Bash call is its own namespace so the
# socket could not outlive the call anyway (reference/connection.md). SSH connect measures
# 0.30-0.44s, which is not where the time goes.
#
# ~/.ssh/known_hosts persists again as of 11 Aug 2026, so no UserKnownHostsFile
# override is needed.
SSH_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o BatchMode=yes
  -o ConnectTimeout=15
  -o ServerAliveInterval=30
)

# Environment every remote command needs. A non-interactive SSH shell has
# neither Java nor Maestro on PATH, and Maestro will not start without both.
REMOTE_ENV='
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.maestro/bin
export JAVA_HOME=$HOME/.sdkman/candidates/java/current
export PATH=$JAVA_HOME/bin:$PATH
'

# The same job locally, and it is NOT the same script (item 94, 2.1).
#
# REMOTE_ENV REPLACES PATH, which is right for a machine reached by ssh: the
# non-interactive shell's PATH is whatever sshd hands it and the Mac's layout is
# known. Run that here and it would drop every directory the caller's PATH
# carries — on this machine the Android SDK lives under /mnt/sda, so adb would
# vanish and every android verb would fail as "command not found" while looking
# like a broken module.
#
# So: add, never replace. An existing JAVA_HOME wins, because a local machine
# may have Java from somewhere other than sdkman, and a non-existent directory
# prepended to PATH costs nothing.
LOCAL_ENV='
export PATH=$PATH:$HOME/.maestro/bin
export JAVA_HOME=${JAVA_HOME:-$HOME/.sdkman/candidates/java/current}
export PATH=$JAVA_HOME/bin:$PATH
'

# Which alias to talk to, when MAC_HOST names more than one.
#
# The Mac moves between networks and each network has its own alias. On 13 Aug
# 2026 it came into the office for the first time and every command failed with
# "Connection timed out during banner exchange" — which reads as the machine
# being asleep, not as the wrong route, and was reported as exactly that.
#
# Selection has to be a real SSH attempt. A TCP probe would be cheaper, but from
# inside the sandbox /dev/tcp fails against BOTH addresses, including the live
# one, so it cannot tell them apart. A stale alias costs ConnectTimeout, which
# is why the answer is cached: $LDIR/mac-host, same idea as drivers.map.
#
# The cache goes stale the moment the Mac moves, and a stale cache looks like a
# dead machine — the lesson drivers.map already taught. So a failure re-picks
# once rather than giving up.
# The Mac's one-minute load average, or empty if it cannot be read.
#
# Worth knowing before anything expensive, because a booting simulator makes the
# machine look broken for about a minute. Measured 17 Sep 2026: with seven
# simulators already booted and the wall up, load sat at 6 and the machine was
# fine; booting ONE more took it to 122 within 36 seconds, and it began falling
# again as soon as that boot settled. The process count barely moved with it —
# ~170 of about 1,640 — so load here is a boot storm, not a crowded machine.
_mac_load() {
  _ssh "sysctl -n vm.loadavg" 2>/dev/null | tr -d '{}' | awk '{print $1}'
}

HOST_CACHE="$LDIR/mac-host"

# Captured here, at source time. Doing it lazily inside the function does not
# work: every caller reads it through $( ), which is a subshell, so the capture
# is thrown away and the list re-reads the already-narrowed MAC_HOST.
_MAC_HOST_LIST="$MAC_HOST"

_host_candidates() { printf '%s\n' $_MAC_HOST_LIST; }

# ConnectTimeout goes BEFORE SSH_OPTS: ssh takes the FIRST value it sees for a
# keyword, so appending it after SSH_OPTS' ConnectTimeout=15 silently does
# nothing — measured, the probe still cost 15s. `timeout` bounds the rest,
# because the failure here is a banner-exchange stall, which ConnectTimeout
# does not cover.
# PROBE_FAST / PROBE_SLOW exist so the tests can run the two passes in seconds
# rather than half a minute. Nothing else should set them.
: "${PROBE_FAST:=8}" ; : "${PROBE_SLOW:=15}"

_probe_host() {  # _probe_host <alias> [connect-seconds]
  local t=${2:-$PROBE_FAST}
  timeout $((t + 2)) ssh -o ConnectTimeout="$t" "${SSH_OPTS[@]}" "$1" 'exit 0' >/dev/null 2>&1
}

_pick_host() {  # sets MAC_HOST to a single alias
  local n cached c
  # Local transport has no host to pick. The candidate count would answer 0 and
  # fall out below anyway; this says so at the top rather than leaving a reader
  # to work out that an empty MAC_HOST reaches the same place by accident.
  [ "${TRANSPORT:-ssh}" = local ] && return 0
  n=$(_host_candidates | grep -c .)
  [ "$n" -le 1 ] && return 0          # nothing to choose; behave as before

  if [ -z "${_HOST_PICKED:-}" ] && [ -r "$HOST_CACHE" ]; then
    cached=$(cat "$HOST_CACHE" 2>/dev/null)
    if _host_candidates | grep -qx -- "$cached"; then
      MAC_HOST=$cached; _HOST_PICKED=1; return 0
    fi
  fi
  [ -n "${_HOST_PICKED:-}" ] && return 0

  for c in $(_host_candidates); do
    if _probe_host "$c"; then
      MAC_HOST=$c; _HOST_PICKED=1
      printf '%s' "$c" > "$HOST_CACHE" 2>/dev/null
      return 0
    fi
  done

  # Nothing answered in 8s. A host that is up answers in well under a second on
  # a LAN, but "your Mac is unreachable" when it is merely slow is the same
  # class of wrong answer this whole thing exists to stop, so try once more
  # with the full timeout before saying it.
  echo "no alias answered within ${PROBE_FAST}s — retrying with the full timeout" >&2
  for c in $(_host_candidates); do
    if _probe_host "$c" "$PROBE_SLOW"; then
      MAC_HOST=$c; _HOST_PICKED=1
      printf '%s' "$c" > "$HOST_CACHE" 2>/dev/null
      return 0
    fi
  done

  echo "none of these answered: $(_host_candidates | tr '\n' ' ')" >&2
  echo "other aliases in ~/.ssh/config: $(_ssh_aliases)" >&2
  return 1
}

_ssh_aliases() {
  awk 'tolower($1)=="host" && $2 !~ /[*?]/ {for(i=2;i<=NF;i++) printf "%s ", $i}' \
    ~/.ssh/config 2>/dev/null
}

# _ssh <remote shell script>   — stdin is passed through to the remote command.
#
# Output streams, it is not captured: shot.sh pipes a base64 image through here
# and journeys read line by line, so buffering would change how every caller
# behaves.
_ssh() {
  # Local transport runs the very same script, through sh -c, on this machine.
  # The 84 call sites do not change: they already hand over a shell script and
  # read its output, and whether that script crosses a network is this
  # function's business and none of theirs (item 94, 2.1).
  #
  # Still bounded by $TMO — a local command can hang as readily as a remote one,
  # and a caller that set a timeout meant it. No retry, though: the 255/124
  # re-pick below exists because ssh failed to reach a host, and locally there
  # is no host to re-pick. A local 124 is the command itself running long, and
  # half of what goes through here taps a screen.
  if [ "${TRANSPORT:-ssh}" = local ]; then
    timeout "$TMO" sh -c "$LOCAL_ENV
cd '$REPO' 2>/dev/null || true
$1"
    return $?
  fi

  _pick_host || return 1
  local rc
  timeout "$TMO" ssh "${SSH_OPTS[@]}" "$MAC_HOST" "$REMOTE_ENV
cd '$REPO' 2>/dev/null || true
$1"
  rc=$?
  # 255 is ssh's own "could not connect", 124 is the timeout — in both the
  # remote command never ran, so re-running is safe. Any other non-zero is the
  # remote command's own status and must NOT be retried: half of what goes
  # through here taps a screen, and doing that twice is worse than failing.
  if { [ "$rc" = 255 ] || [ "$rc" = 124 ]; } \
     && [ -n "${_HOST_PICKED:-}" ] && [ "$(_host_candidates | grep -c .)" -gt 1 ]; then
    rm -f "$HOST_CACHE"; unset _HOST_PICKED
    echo "maestro-remote-mac: $MAC_HOST stopped answering — re-picking" >&2
    _pick_host || return 1
    timeout "$TMO" ssh "${SSH_OPTS[@]}" "$MAC_HOST" "$REMOTE_ENV
cd '$REPO' 2>/dev/null || true
$1"
    rc=$?
  fi
  return "$rc"
}

# _push <file>... <destination>   — move files TO the machine holding the device.
#
# The destination is a path on that machine, with no host prefix: _push adds the
# host across ssh and does not need one locally. A destination ending in / or
# naming an existing directory takes the file's own basename, as scp does.
#
# Locally every caller in this package is pushing a file onto itself, because
# after item 94's 2.2 the destinations ARE the checkout: $RHELP is remote/ and
# $RMODS is runners/, and every source is $HERE/../remote/x or
# $HERE/../runners/y. So the local branch tests for that first — and it must,
# because `cp a a` exits 1 with "are the same file" and every call site here
# ends in `|| exit 1` or `|| return 1`. A bare cp would fail every local run.
#
# The two that are real copies rather than self-copies are mac.sh --send and
# img.sh, which put a file the user named into the scratch directory.
_push() {
  local n=$# dest src target
  [ "$n" -ge 2 ] || { echo "_push needs at least one file and a destination" >&2; return 2; }
  dest=${!n}
  local srcs=("${@:1:n-1}")

  if [ "${TRANSPORT:-ssh}" = local ]; then
    for src in "${srcs[@]}"; do
      target=$dest
      case "$dest" in */) target="$dest$(basename "$src")" ;; esac
      [ -d "$dest" ] && target="${dest%/}/$(basename "$src")"
      [ "$src" -ef "$target" ] && continue
      mkdir -p "$(dirname "$target")" || return 1
      cp "$src" "$target" || return 1
    done
    return 0
  fi

  scp "${SSH_OPTS[@]}" "${srcs[@]}" "$MAC_HOST:$dest" >/dev/null || return 1
}

# Who is driving, for a wall label. The session colour first, because it is what
# the terminal is already showing and is the only one of these a person reads at
# a glance; seven characters of the session id break a tie between two sessions
# that share a colour or have none. Outside a Claude session, whoever is at the
# keyboard.
_label_by() {
  local c=${CLAUDE_SESSION_COLOUR:-} s=${CLAUDE_CODE_SESSION_ID:-}
  if [ -n "$c" ] && [ -n "$s" ]; then printf '%s \xc2\xb7 %s' "$c" "$(printf '%s' "$s" | cut -c1-7)"
  elif [ -n "$c" ]; then printf '%s' "$c"
  elif [ -n "$s" ]; then printf '%s' "$(printf '%s' "$s" | cut -c1-7)"
  else printf '%s@%s' "${USER:-unknown}" "$(hostname -s 2>/dev/null || echo host)"
  fi
}

# The Mac's current LAN address. It moves between networks — its name resolves
# to an address on each of them and DNS returns them all, whichever one is
# actually live, so nothing may hardcode it. Ask the Mac which address it is
# using. One SSH round trip, cached for the shell.
_macip() {
  if [ -z "${MACIP:-}" ]; then
    MACIP=$(_ssh 'ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null' | tr -d '[:space:]')
  fi
  [ -n "$MACIP" ] || { echo "could not determine the Mac's LAN address" >&2; return 1; }
  printf '%s' "$MACIP"
}

# Resolve the device id once per shell and cache it for the session.
_dev() {
  if [ -z "$DEV" ]; then
    # Say so when the choice was arbitrary. The driver is per-device, so driving
    # the wrong one looks like the app misbehaving.
    local booted n
    booted=$(_ssh "sh '$PLATFORM_SH' devices --booted")
    DEV=$(printf '%s\n' "$booted" | head -1 | cut -f1)
    n=$(printf '%s\n' "$booted" | grep -c .)
    if [ "$n" -gt 1 ]; then
      echo "note: $n devices are booted and DEV is not set — using:" >&2
      printf '%s\n' "$booted" | awk -F'\t' '{printf "  %s  %s\n", $1, $3}' >&2
      echo "  pin one with DEV=<udid> in .maestro-mac.conf" >&2
    fi
  fi
  [ -n "$DEV" ] || { echo "no booted device on $MAC_HOST (platform: ${PLATFORM:-ios})" >&2; return 1; }
  printf '%s' "$DEV"
}

# --- which driver belongs to which simulator --------------------------------
# One simulator holds one driver: launching the XCUITest runner again replaces
# the instance that was there, whatever port it was on. So the mapping is
# device -> driver, and it is discoverable rather than something to keep in
# step by hand. The runner process runs out of the simulator's own data
# container, so its command line carries the UDID, and lsof gives the port it
# bound. That is the whole map, read from the live processes:
#
#   7C0331AA-...-0331AA 22088 66556
#   3D30DC5E-...-30DC5E 22087 66744
#
# Cached in $LDIR/drivers.map so the common case costs nothing. The cache is
# only ever wrong in one direction — a driver that has died — and that shows up
# as the relay failing, which refreshes it.
DRIVER_MAP="$LDIR/drivers.map"

# What bin/drivers.sh deliberately started, as opposed to what happens to be
# running: "<udid> <driver port> <epoch>". The two are not the same, and the
# difference is the whole point of this file — a device that is in here and not
# in the scan had its driver taken away by something, which is worth saying.
DRIVER_OWNED="$LDIR/drivers.owned"

# Physical devices, registered by bin/device.sh as "<udid> <port> device". A
# device's driver binds its HTTP server ON THE PHONE and is reached through a
# usbmux forwarder, so the process scan below (which reads a simulator runner's
# own listening port) cannot see it — the registry is how _driver_bind finds it.
DEVICE_MAP="$LDIR/devices.map"

_driver_own() {  # _driver_own <udid> <port>
  local tmp="$DRIVER_OWNED.tmp"
  { grep -v "^$1 " "$DRIVER_OWNED" 2>/dev/null; echo "$1 $2 $(date +%s)"; } > "$tmp"
  mv -f "$tmp" "$DRIVER_OWNED"
}

_driver_disown() {  # _driver_disown [udid]  -- no udid clears the lot
  if [ -z "${1:-}" ]; then rm -f "$DRIVER_OWNED"; return 0; fi
  local tmp="$DRIVER_OWNED.tmp"
  grep -v "^$1 " "$DRIVER_OWNED" 2>/dev/null > "$tmp"
  mv -f "$tmp" "$DRIVER_OWNED"
}

_driver_owned() {  # _driver_owned <udid> -- prints "<port> <epoch>", or nothing
  awk -v d="$1" '$1==d{print $2, $3; exit}' "$DRIVER_OWNED" 2>/dev/null
}

_driver_scan() {
  # The platform's map, read from the live processes on the Mac. What that means
  # differs entirely: an XCUITest runner's command line carries the simulator
  # UDID and lsof gives the port it bound, whereas an Android driver is an
  # instrumented APK and the mapping is adb's. Same three columns either way —
  # "<device> <port> <pid>", one per line.
  _ssh "sh '$PLATFORM_SH' driver-scan" > "$DRIVER_MAP.tmp" 2>/dev/null
  mv -f "$DRIVER_MAP.tmp" "$DRIVER_MAP" 2>/dev/null
  cat "$DRIVER_MAP" 2>/dev/null
}

_driver_map() {  # cached; pass --fresh to re-read from the Mac
  if [ "${1:-}" = --fresh ] || [ ! -s "$DRIVER_MAP" ]; then _driver_scan; else cat "$DRIVER_MAP"; fi
  # Physical devices are registered locally by bin/device.sh, not discovered by
  # the scan, so add them here. Same "<udid> <port> ..." shape, so _driver_bind
  # treats a phone exactly like a simulator.
  cat "$DEVICE_MAP" 2>/dev/null
}

# --- ports that stay with the device ----------------------------------------
# A device keeps the same driver port for as long as this file says so, and the
# file lives ON THE MAC because the sessions that must not collide are not on
# this side.
#
# Why this is not "whatever is free". Ports used to be handed out lowest-first
# among the drivers currently alive, so a device that lost its driver — which
# Maestro does routinely, every CLI or MCP run tears one down — got whatever
# number was free next time, including one another device had just released.
# Two sightings, 16 Sep 2026: after a load spike killed every driver, the iPad's
# came back on 22087, which was the iPhone 16 Pro Max's port; and a session
# holding relay 9105 sent 22 swipes to ANOTHER session's iPhone after a restart
# moved its iPad to 9106. Driving the wrong device is the failure this toolkit
# exists to prevent, and a moving port is how it happens silently.
#
# $RDIR is under /tmp on the Mac, so this does not survive a Mac reboot — and
# that is correct, because a reboot takes every driver with it (item 79).
PORTS_MAP="$RDIR/ports.map"

_ports_read() {  # the whole "<udid> <port>" map, one SSH call
  _ssh "cat '$PORTS_MAP' 2>/dev/null" 2>/dev/null
}

_ports_remember() {  # _ports_remember <udid> <port>
  _ssh "mkdir -p '$RDIR'
grep -v '^$1 ' '$PORTS_MAP' 2>/dev/null > '$PORTS_MAP.tmp'
echo '$1 $2' >> '$PORTS_MAP.tmp'
mv -f '$PORTS_MAP.tmp' '$PORTS_MAP'" >/dev/null 2>&1 || true
}

_ports_forget() {  # _ports_forget [udid] -- no udid clears the lot
  if [ -z "${1:-}" ]; then _ssh "rm -f '$PORTS_MAP'" >/dev/null 2>&1 || true; return 0; fi
  _ssh "grep -v '^$1 ' '$PORTS_MAP' 2>/dev/null > '$PORTS_MAP.tmp'
mv -f '$PORTS_MAP.tmp' '$PORTS_MAP'" >/dev/null 2>&1 || true
}

# The relay port is derived from the driver port rather than tracked, so the
# two can never drift: 22087 -> 9101, 22088 -> 9102, and so on.
_dport_for() { echo $(( DPORT_BASE + ${1:?driver port} - DRIVER_PORT_BASE )); }

# Measured 13 Aug 2026 on three simulators at once. Running Maestro against a
# device — the MCP server, bin/hier.sh, bin/flow.sh, bin/shot.sh — destroys
# THAT DEVICE'S driver and leaves every other one alone. It happens on the way
# out, when Maestro terminates the runner it was talking to, and it happens
# whether the command succeeded or failed.
#
# This corrects what those three scripts say about themselves and what
# BACKLOG.md item 15 assumed: it is not that port 22087 gets taken from
# whichever device held it. Through both runs the iPad kept 22087 and the
# iPhone 16 kept 22089; the iPhone 16 Pro, which was the one named, lost its
# driver both times.
#
# The failure then lands one call later, on whatever tries to use that device
# next, and "no driver for <udid>" reads like the driver was never there.
_driver_gone_note() {  # _driver_gone_note <udid> <live map>
  local owned port when others
  owned=$(_driver_owned "$1") || return 0
  [ -n "$owned" ] || return 0
  port=${owned%% *}; when=${owned##* }
  echo "  bin/drivers.sh up started one on port $port at $(date -d "@$when" '+%H:%M' 2>/dev/null ||
        date -r "$when" '+%H:%M' 2>/dev/null || echo "$when"), and it is gone." >&2
  echo "  Running Maestro against a device destroys that device's driver when it" >&2
  echo "  finishes — the MCP server, bin/hier.sh, bin/flow.sh, bin/shot.sh." >&2
  others=$(printf '%s\n' "$2" | grep -c . 2>/dev/null) || others=0
  case "$others" in
    0) echo "  No other device is affected by that, but none has a driver either." >&2 ;;
    1) echo "  No other device is affected: the remaining one still has its driver." >&2 ;;
    *) echo "  No other device is affected: the other $others still have theirs." >&2 ;;
  esac
}

# Fill in DRIVER_PORT and DPORT for the device being driven. Anything already
# pinned in the conf or the environment is left alone.
_driver_bind() {
  [ -n "${_DRIVER_PORT_PINNED:-}" ] || {
    local map line
    map=$(_driver_map "${1:-}")
    if [ -n "$DEV" ]; then
      line=$(printf '%s\n' "$map" | awk -v d="$DEV" '$1==d{print; exit}')
      [ -n "$line" ] || {
        # A stale cache looks exactly like no driver, so pay for one refresh
        # before saying so.
        [ "${1:-}" = --fresh ] || { _driver_bind --fresh; return $?; }
        echo "no driver for $DEV." >&2
        _driver_gone_note "$DEV" "$map"
        echo "  bring one up:  bin/drivers.sh up $DEV" >&2
        return 1; }
    else
      local n; n=$(printf '%s\n' "$map" | grep -c .)
      if [ "$n" -eq 0 ]; then
        [ "${1:-}" = --fresh ] || { _driver_bind --fresh; return $?; }
        echo "no driver is running on $MAC_HOST. Bring one up:  bin/drivers.sh up" >&2
        return 1
      elif [ "$n" -gt 1 ]; then
        # Driving the wrong simulator looks exactly like the app misbehaving,
        # so this refuses rather than picking.
        echo "$n drivers are running and DEV is not set:" >&2
        printf '%s\n' "$map" | awk '{printf "  %s  port %s\n", $1, $2}' >&2
        echo "  set DEV=<udid>, or pin it in .maestro-mac.conf" >&2
        return 1
      fi
      line=$map
    fi
    DRIVER_PORT=$(printf '%s' "$line" | awk '{print $2}')
    DEV=${DEV:-$(printf '%s' "$line" | awk '{print $1}')}
  }
  [ -n "${_DPORT_PINNED:-}" ] || DPORT=$(_dport_for "$DRIVER_PORT")
}
