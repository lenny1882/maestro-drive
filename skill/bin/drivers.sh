#!/bin/bash
# Bring up one XCUITest driver per simulator, so several devices can be driven
# at once.
#
#   ./bin/drivers.sh                 # what is running, and on which port
#   ./bin/drivers.sh up              # a driver for every booted simulator
#   ./bin/drivers.sh up <udid>       # just that one
#   ./bin/drivers.sh down <udid>     # stop that one
#   ./bin/drivers.sh down-all
#
# Why this exists. Maestro can only ever drive one device at a time from here:
# MaestroSessionManager and McpMaestroSessionManager both compile the driver
# port in as a literal 22087 with no override, and the MCP server's session map
# has no invalidation path. Ask it for a second device and it hands back the
# FIRST device's screen, with a response that looks entirely correct. That has
# cost hours in real sessions.
#
# The driver itself has no such limit. XCTestHTTPServer.swift reads
# `ProcessInfo.processInfo.environment["PORT"]` before falling back to 22087,
# and xcodebuild passes TEST_RUNNER_PORT into the test process as PORT. So a
# driver can be put on any port; only Maestro's own client insists on 22087.
# This starts them the same way Maestro does — same build products out of
# maestro-ios-driver.jar, same xcodebuild invocation — and chooses the port.
#
# The first device takes 22087 so the MCP server keeps working against it.
# Extra devices count up from there, where nothing of Maestro's will find them.
#
# One simulator holds one driver. Launching the runner again replaces the
# instance already there, so `up` reuses a live driver rather than restarting
# it, and an MCP call for a device destroys whatever driver that device had.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HERE=$(cd "$(dirname "$0")" && pwd)

# "<id> <name>", which is what every caller here reads. The platform gives tab
# separated <id> <state> <name>; the state is not interesting once --booted has
# already filtered on it.
_booted() {
  _ssh "sh '$PLATFORM_SH' devices --booted" | awk -F'\t' 'NF{printf "%s %s\n", $1, $3}'
}

_list() {
  local map booted
  map=$(_driver_map --fresh)
  booted=$(_booted)
  [ -n "$booted" ] || { echo "no booted simulator on $(_where)"; return 0; }
  printf '%-38s %-9s %-7s %s\n' UDID DRIVER RELAY DEVICE
  printf '%s\n' "$booted" | while read -r u name; do
    local port
    port=$(printf '%s\n' "$map" | awk -v d="$u" '$1==d{print $2; exit}')
    if [ -n "$port" ]; then
      printf '%-38s %-9s %-7s %s\n' "$u" "$port" "$(_dport_for "$port")" "$name"
    else
      # A dash where this script started one is not "never had a driver", it is
      # "something took it" — see _driver_gone_note in lib.sh.
      local owned; owned=$(_driver_owned "$u")
      if [ -n "$owned" ]; then
        printf '%-38s %-9s %-7s %s\n' "$u" "was ${owned%% *}" "GONE" "$name"
      else
        printf '%-38s %-9s %-7s %s\n' "$u" "-" "-" "$name"
      fi
    fi
  done
}

# The port this device should have. Sticky: once a device has a number it keeps
# it, so a driver that died and came back is on the same port as before and
# nothing that cached it is now pointed at a stranger's simulator (lib.sh,
# PORTS_MAP).
#
#   1. the remembered port, if nothing live is sitting on it
#   2. otherwise the lowest port no live driver and no other device's
#      remembered entry is using — recorded, so this is the last time it moves
#
# Case 2 is also what gives the first device 22087, the port Maestro's own
# client insists on, since it is the lowest.
_port_for() {  # _port_for <udid> <live-map> <ports-map>
  local udid=$1 map=$2 pmap=$3 want p
  want=$(printf '%s\n' "$pmap" | awk -v d="$udid" '$1==d{print $2; exit}')
  if [ -n "$want" ] &&
     ! printf '%s\n' "$map" | awk -v d="$udid" '$1!=d{print $2}' | grep -qx "$want"; then
    echo "$want"; return
  fi
  p=$DRIVER_PORT_BASE
  while printf '%s\n' "$map" | awk '{print $2}' | grep -qx "$p" ||
        printf '%s\n' "$pmap" | awk -v d="$udid" '$1!=d{print $2}' | grep -qx "$p"; do
    p=$((p + 1))
  done
  _ports_remember "$udid" "$p"
  echo "$p"
}

# Name the device's tile on the wall. Two rules, and the second is item 67.
#
# 1. A name set by hand is never overwritten. `bin/wall.sh label` is explicit
#    and this is only a default, so it fills a blank and otherwise leaves well
#    alone.
#
# 2. A name left behind by a session that is GONE is overwritten. Nothing clears
#    a label at session end, so without this every stale label reads as
#    hand-set: the maintainer opened the wall on 16 Sep 2026 to four simulators named 13
#    hours earlier, none of them working, and a tile still saying `named 15h
#    ago` under a live session that was not the one named on it.
#
# Telling the two apart needs more than a session-id mismatch, because two live
# sessions share this Mac routinely (item 80) and the second must not rename the
# first's device out from under it. The test is BOTH of:
#
#   * the label names a different session, and
#   * that device has no live driver, and
#   * the label has not been touched for $LABEL_STALE_AFTER (default 3600s,
#     the same threshold wall.py already greys a tile at).
#
# A driver is the liveness signal because a session that is driving has one up
# by definition. The age is there because Maestro tears a driver down on every
# CLI or MCP run, so "no driver right now" on its own would rename a peer's
# device mid-session.
: "${LABEL_STALE_AFTER:=3600}"

_label_default() {  # _label_default <udid> [<live-map>]
  local udid=$1 map=${2:-} name group mine
  name=${PROFILE:-${APP_ID:-}}
  group=$(basename "$PROJECT_DIR")
  [ -n "$name" ] || name=$group
  mine=$(_label_by)
  # `-s` fills a blank; the second clause reclaims a dead session's label. Both
  # are evaluated on the Mac in one round trip, so this costs nothing extra.
  #
  # The live-driver test below is the exception: its $( ) sits in a
  # double-quoted string, so THIS shell expands it before anything is sent, and
  # the awk runs here against the $map read here. Its \$ escapes were written as
  # though it ran on the Mac, so awk received a literal backslash, died with
  # "backslash not last character on line", and the substitution came back
  # empty — making the test always false. A live driver therefore stopped
  # protecting a peer's label, leaving the age check as the only one of the
  # three guards still working. Found by the first live rig up after Stage 3,
  # and invisible to the tests because a recent label is kept by the age check
  # whether or not this one fires.
  printf 'name=%s\ngroup=%s\nby=%s\n' "$name" "$group" "$mine" |
    _ssh "mkdir -p '$RDIR/labels'
L='$RDIR/labels/$udid'
if [ ! -s \"\$L\" ]; then cat > \"\$L\"; exit 0; fi
if grep -qF 'by=$mine' \"\$L\" 2>/dev/null; then cat >/dev/null; exit 0; fi
if [ -n '$(printf '%s\n' "$map" | awk -v d="$udid" '$1==d{print $2; exit}')' ]; then cat >/dev/null; exit 0; fi
AGE=\$(( \$(date +%s) - \$(stat -f %m \"\$L\" 2>/dev/null || stat -c %Y \"\$L\" 2>/dev/null || date +%s) ))
if [ \"\$AGE\" -gt $LABEL_STALE_AFTER ]; then cat > \"\$L\"; else cat >/dev/null; fi" \
    >/dev/null 2>&1 || true
}
# --- the rig: several simulators brought up and taken down as one -----------
# "Get the rig set up" and "tear the rig down" were the units of work on
# 16 Sep 2026, and neither was a thing this toolkit had. Setting one up by hand
# cost about forty-five minutes in one session; taking one down was assembled
# line by line in the moment every time.
#
# What it does NOT do is build or install. `bin/build.sh` must not run
# unprompted (SKILL.md step 5), and a rig that silently replaced the build under
# test would be worse than no rig. Boot, driver, label — the app is the
# operator's decision.
#
# Boots are SERIALISED and each one is waited out. Measured 17 Sep 2026: this
# Mac sat at load 6 with seven simulators booted and the wall up, and booting
# ONE more took it to 122 within 36 seconds, falling back once that boot
# settled. Five at once is what took a session's four drivers down on 16 Sep.
# The cost is the boot, not the simulator, so the fix is to queue them rather
# than to cap how many there are (item 74).
RIG_OWNED="$RDIR/rig"

_rig_devices() {  # the udids this rig covers: arguments, else the conf
  if [ $# -gt 0 ]; then printf '%s\n' "$@"; return; fi
  [ -n "${RIG_DEVICES:-}" ] || return 1
  printf '%s\n' $RIG_DEVICES
}

_rig_mine() { echo "$RIG_OWNED/$(_label_by | tr -c 'A-Za-z0-9._-' '_')"; }

_rig_claim() {  # _rig_claim <udid> -- this session booted it, so it takes it down
  _ssh "mkdir -p '$RIG_OWNED'; grep -qx '$1' '$(_rig_mine)' 2>/dev/null || echo '$1' >> '$(_rig_mine)'" >/dev/null 2>&1 || true
  _rig_rename "$1"
}

# A device this session BOOTED gets its wall label written over, not merely
# filled if blank. `_label_default` deliberately never overwrites, because it
# cannot tell a name somebody set by hand from one a dead session left behind —
# and since nothing clears a label at session end, every stale label looks
# hand-set (item 67). Booting the device settles that: it was shut down a moment
# ago, so whatever name is on it belongs to a session that is gone.
#
# Measured 17 Sep 2026: this rig booted an iPhone 16e and the wall went on
# showing `orange · f13f0e1`, a session that ended the previous afternoon.
_rig_rename() {  # _rig_rename <udid>
  local udid=$1 name group
  name=${PROFILE:-${APP_ID:-rig}}
  group=$(basename "${PROJECT_DIR:-$PWD}")
  printf 'name=%s\ngroup=%s\nby=%s\n' "$name" "$group" "$(_label_by)" |
    _ssh "mkdir -p '$RDIR/labels'; cat > '$RDIR/labels/$udid'" >/dev/null 2>&1 || true
}

_rig_claimed() { _ssh "cat '$(_rig_mine)' 2>/dev/null" 2>/dev/null; }

_rig_settle() {  # _rig_settle <udid> -- wait for the boot AND for the load it caused
  local udid=$1 waited=0 l
  echo "  waiting for $udid to finish booting" >&2
  # The platform's `boot` already waited for the device itself — this is the
  # second wait, for the machine. They are different things and only the second
  # decides whether the next boot or a driver start survives.
  # bootstatus returns when the device is up, not when the machine has caught
  # up with it, and it is the second one that decides whether the next boot or
  # a driver start survives.
  while [ "$waited" -lt "${RIG_SETTLE_MAX:-180}" ]; do
    l=$(_mac_load); [ -n "$l" ] || break
    [ "${l%%.*}" -lt "${LOAD_WARN:-40}" ] && { echo "  settled, load $l" >&2; return 0; }
    echo "  load $l, waiting (${waited}s)" >&2
    sleep 10; waited=$((waited + 10))
  done
  echo "  carrying on at load ${l:-unknown} after ${waited}s" >&2
}

_rig_up() {
  local devs=() booted d name up_map p_map
  mapfile -t devs < <(_rig_devices "$@") || true
  if [ ${#devs[@]} -eq 0 ]; then
    echo "rig: no devices. Pass udids, or set RIG_DEVICES in .maestro-mac.conf:" >&2
    echo "  : \"\${RIG_DEVICES:=<udid> <udid> <udid>}\"" >&2
    echo "Booted right now:" >&2
    _booted | sed 's/^/  /' >&2
    return 2
  fi
  booted=$(_booted)
  for d in "${devs[@]}"; do
    [ -n "$d" ] || continue
    if printf '%s\n' "$booted" | awk '{print $1}' | grep -qx "$d"; then
      echo "$d  already booted (leaving it alone)"
    else
      echo "$d  booting"
      # One verb: it boots AND waits the device out. Returning before the boot
      # settles is what makes the next caller start a driver mid-storm.
      TMO=300 _ssh "sh '$PLATFORM_SH' boot '$d'" >/dev/null 2>&1 || {
        echo "$d  would not boot" >&2; continue; }
      _rig_claim "$d"          # only what WE booted is ours to shut down
      _rig_settle "$d"
    fi
  done
  # Drivers after every boot has settled, not interleaved with them: a driver
  # start is a ~30s xcodebuild and the one begun during a boot storm is the one
  # that dies.
  up_map=$(_driver_map --fresh); p_map=$(_ports_read)
  for d in "${devs[@]}"; do
    [ -n "$d" ] || continue
    _up_one "$d" "$up_map" "$p_map" || true
    up_map=$(_driver_map --fresh); p_map=$(_ports_read)
  done
  echo; _rig_status
}

_rig_status() {
  local map booted mine labels rows u name port by
  map=$(_driver_map --fresh); booted=$(_booted); mine=$(_rig_claimed)
  [ -n "$booted" ] || { echo "no booted simulator on $(_where)"; return 0; }
  # Every label in ONE call, before the loop. An _ssh inside a loop that is
  # reading from a pipe eats the rest of the pipe — _ssh passes stdin to the
  # remote command — so the first pass of this printed one device out of seven.
  # `up` has carried a comment about that trap for weeks and this is the third
  # time it has been walked into (17 Sep; see also `ports adopt`).
  labels=$(_ssh "cd '$RDIR/labels' 2>/dev/null && grep -H '^by=' * 2>/dev/null | sed 's/:by=/ /'" 2>/dev/null)
  printf '%-38s %-7s %-7s %-5s %-22s %s\n' UDID DRIVER RELAY MINE BY DEVICE
  rows=(); mapfile -t rows <<< "$booted"
  for l in "${rows[@]}"; do
    [ -n "$l" ] || continue
    u=${l%% *}; name=${l#* }
    port=$(printf '%s\n' "$map" | awk -v d="$u" '$1==d{print $2; exit}')
    by=$(printf '%s\n' "$labels" | awk -v d="$u" '$1==d{$1=""; sub(/^ /,""); print; exit}')
    printf '%-38s %-7s %-7s %-5s %-22s %s\n' "$u" "${port:--}" \
      "$([ -n "$port" ] && _dport_for "$port" || echo -)" \
      "$(printf '%s\n' "$mine" | grep -qx "$u" && echo yes || echo -)" \
      "${by:--}" "$name"
  done
}
_rig_down() {
  # Only what this session booted. Everything else on this Mac belongs to
  # somebody, and a teardown that takes a peer's simulator with it is worse
  # than one that leaves something behind.
  local mine d n=0
  mine=$(_rig_claimed)
  if [ -z "$mine" ]; then
    echo "rig: this session booted nothing, so there is nothing to take down."
    echo "  Drivers it started are still listed by: $0"
    return 0
  fi
  for d in $mine; do
    echo "$d  stopping driver, clearing label, shutting down"
    _ssh "sh '$PLATFORM_SH' driver-down '$d' 2>/dev/null
rm -f '$RDIR/labels/$d'
sh '$PLATFORM_SH' shutdown '$d' 2>/dev/null; true" >/dev/null 2>&1 || true
    _driver_disown "$d"
    n=$((n + 1))
  done
  _ssh "rm -f '$(_rig_mine)'" >/dev/null 2>&1 || true
  _driver_scan >/dev/null
  echo "rig down: $n device(s) this session booted. Nothing else was touched."
}

# --- reaping a boot nobody claims -------------------------------------------
# Labels have a reclaim path and boots do not (item 88). `rig down` takes only
# what THIS session booted, deliberately — a teardown that takes a peer's
# simulator mid-run is worse than one that leaves something behind — so a
# simulator whose session has gone stays booted for ever. Measured 18 Sep 2026:
# seven booted, a claim ledger empty since the previous afternoon, and five of
# them last written to two days earlier.
#
# The three tests are the label reclaim's, applied to the boot instead of the
# name: nobody claims it, no driver is live on it, and nothing has written to it
# since a previous calendar day. Calendar day rather than a count of hours
# because that is the rule the wall already uses for a name, and for the reason
# item 67's piece 4 chose it: a device driven at 23:00 is yesterday's work by
# breakfast, though it is only ten hours old.
#
# It shuts nothing down unless asked. Listing is safe; acting is a judgement,
# and item 74's lesson was a session that killed four working simulators to
# recover from a boot storm it had misread.
_rig_reap() {  # _rig_reap [--shutdown]
  local act=0
  [ "${1:-}" = "--shutdown" ] && act=1

  local booted map claimed rows verdicts orphans n
  booted=$(_booted)
  [ -n "$booted" ] || { echo "no booted simulator on $(_where)"; return 0; }
  map=$(_driver_map --fresh)
  claimed=$(_ssh "cat '$RIG_OWNED'/* 2>/dev/null" 2>/dev/null)

  # One round trip for every device's newest app-data write. An app container is
  # the only thing on a simulator that records USE: the device directory's own
  # mtime moves when it boots, so it says when it STARTED, not when anybody last
  # did anything with it.
  #
  # Two levels deep, not one. A container directory's mtime only moves when its
  # immediate contents change, so the container itself reported 16 Sep for a
  # device driven all day on the 18th; Documents/ and Library/ inside it gave
  # 18 Sep 12:56, which is exactly what a recursive find over the whole
  # container returned, for the cost of a glob.
  rows=$(_ssh "sh '$PLATFORM_SH' last-used")

  # One pass, into a variable: a `while read` fed by a pipe runs in a subshell,
  # so anything it decides is lost at the done.
  verdicts=$(printf '%s\n' "$booted" | while read -r u name; do
    [ -n "$u" ] || continue
    local drv day today last why=""
    drv=$(printf '%s\n' "$map"  | awk -v d="$u" '$1==d{print $2; exit}')
    day=$(printf '%s\n' "$rows" | awk -F'|' -v d="$u" '$1==d{print $2; exit}')
    last=$(printf '%s\n' "$rows" | awk -F'|' -v d="$u" '$1==d{print $3; exit}')
    today=$(printf '%s\n' "$rows" | awk -F'|' -v d="$u" '$1==d{print $4; exit}')
    if printf '%s\n' "$claimed" | grep -qx "$u"; then why="a session claims it"
    elif [ -n "$drv" ];            then why="a driver is live on $drv"
    elif [ "$day" = "$today" ];    then why="used today"
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$u" "${drv:--}" "${last:-?}" "${why:-ORPHAN}" "$name"
  done)

  printf '%-38s %-7s %-17s %s\n' UDID DRIVER "LAST USED" VERDICT
  printf '%s\n' "$verdicts" | while IFS=$'\t' read -r u drv last why name; do
    [ -n "$u" ] || continue
    case "$why" in
      ORPHAN) printf '%-38s %-7s %-17s ORPHAN  (%s)\n' "$u" "$drv" "$last" "$name" ;;
      *)      printf '%-38s %-7s %-17s keep — %s\n'    "$u" "$drv" "$last" "$why" ;;
    esac
  done

  orphans=$(printf '%s\n' "$verdicts" | awk -F'\t' '$4=="ORPHAN"{print $1}')
  echo
  if [ -z "$orphans" ]; then
    echo "rig reap: nothing to reap — every booted simulator fails at least one test."
    return 0
  fi
  n=$(printf '%s\n' "$orphans" | grep -c .)
  if [ "$act" = 0 ]; then
    echo "rig reap: $n orphan(s). Nothing has been shut down."
    echo "  To take them down:  $0 rig reap --shutdown"
    echo "  A device used TODAY is never listed, whoever booted it."
    return 0
  fi
  local u
  for u in $orphans; do
    echo "$u  shutting down"
    _ssh "rm -f '$RDIR/labels/$u'; sh '$PLATFORM_SH' shutdown '$u' 2>/dev/null; true" >/dev/null 2>&1 || true
  done
  _driver_scan >/dev/null
  echo "rig reap: $n shut down, labels cleared. Claimed and same-day devices untouched."
}

_up_one() {  # _up_one <udid> <live-map> <ports-map>
  local udid=$1 map=$2 pmap=${3:-} port
  port=$(printf '%s\n' "$map" | awk -v d="$udid" '$1==d{print $2; exit}')
  if [ -n "$port" ] &&
     [ "$(_ssh "curl -s -m 4 -o /dev/null -w '%{http_code}' http://127.0.0.1:$port/status")" = 200 ]; then
    echo "$udid  already up on $port"
    # A driver that is already up is the truth, so make the map agree with it
    # rather than the other way round.
    _ports_remember "$udid" "$port"
    _driver_own "$udid" "$port"
    _label_default "$udid" "$map"
    return 0
  fi
  port=$(_port_for "$udid" "$map" "$pmap")
  echo "$udid  starting on $port (about 30s)"
  _ssh "mkdir -p '$RDIR'" >/dev/null
  _push "$HERE/../remote/driverup.sh" "$RHELP/driverup.sh" || return 1
  TMO=180 _ssh "RDIR='$RDIR' RHELP='$RHELP' sh '$PLATFORM_SH' driver-up '$udid' '$port' '$RDIR/drv'" || return 1
  # Remember it was us. A driver that disappears from the scan afterwards was
  # taken by something, and the note in _driver_bind can say so.
  _driver_own "$udid" "$port"
  _label_default "$udid" "$map"
  # Across ssh the driver is reached through the relay bin/driver.sh starts, so
  # the URL to print is the relay's. Locally there is no relay and the driver's
  # own port is the address (item 94, 4.1) — printing a $DPORT here would name a
  # port nothing will ever listen on.
  if [ "${TRANSPORT:-ssh}" = local ]; then
    echo "$udid  driver:  DEV=$udid  ->  http://127.0.0.1:$port"
  else
    echo "$udid  relay:  DEV=$udid  ->  http://$(_urlhost):$(_dport_for "$port")"
  fi
}

case "${1:-list}" in
  list|"") _list ;;
  up)
    # A driver start is a ~30s xcodebuild per device, and doing it while a
    # simulator is still booting is how a session lost its drivers on 16 Sep: it
    # read the machine as thrashing and killed things that were fine. Say what
    # the load is rather than letting it look like a toolkit failure.
    _l=$(_mac_load)
    if [ -n "$_l" ] && [ "${_l%%.*}" -ge "${LOAD_WARN:-40}" ]; then
      echo "the Mac's 1-minute load is $_l." >&2
      echo "  A simulator that is still booting does this on its own — one boot" >&2
      echo "  measured 6 -> 122 in 36s on 17 Sep, falling back once it settled." >&2
      echo "  Starting drivers now adds a ~30s xcodebuild per device on top of" >&2
      echo "  it, and a driver started into a boot storm is the one that dies." >&2
      echo "  Wait for the boot to finish, then run this again. LOAD_WARN=<n>" >&2
      echo "  changes the threshold; nothing is being refused." >&2
      echo >&2
    fi
    map=$(_driver_map --fresh)
    pmap=$(_ports_read)
    if [ -n "${2:-}" ]; then
      _up_one "$2" "$map" "$pmap" || exit 1
    else
      # Bare `up` walks EVERY booted simulator, including devices another
      # session is driving: a ~30s xcodebuild each, and a driver restarted
      # under a peer mid-journey. Ports no longer move when it does (item 73),
      # so this is a warning about wasted time and interrupted work rather than
      # about landing on the wrong device.
      _others=$(_ssh "grep -l . '$RDIR'/labels/* 2>/dev/null | xargs -r grep -L '$(_label_by)' 2>/dev/null" 2>/dev/null | sed 's|.*/||')
      if [ -n "$_others" ]; then
        echo "another session has named these devices on the wall:" >&2
        for _o in $_others; do echo "  $_o" >&2; done
        echo "  Bare 'up' rebuilds a driver for every booted simulator, which" >&2
        echo "  restarts theirs too. Name yours instead: drivers.sh up <udid>" >&2
        echo >&2
      fi
      # Read the list before the loop, not through a pipe into it: _ssh passes
      # stdin to the remote command, so an ssh call inside the loop swallows the
      # devices that have not been read yet and only the first one starts.
      devs=(); mapfile -t devs < <(_booted)
      # Sequentially: two xcodebuild runs at once contend for the same derived
      # data and the same simulator daemon, and the second usually loses.
      for line in "${devs[@]}"; do
        _up_one "${line%% *}" "$map" "$pmap" || true
        map=$(_driver_map --fresh)
        pmap=$(_ports_read)
      done
    fi
    _driver_scan >/dev/null
    echo; _list
    ;;
  rig)
    case "${2:-status}" in
      up)     shift 2; _rig_up "$@" ;;
      down)   _rig_down ;;
      reap)   shift 2; _rig_reap "$@" ;;
      status) _rig_status ;;
      *) echo "usage: $0 rig [up [<udid>...]|down|reap [--shutdown]|status]" >&2; exit 2 ;;
    esac ;;
  ports)
    case "${2:-list}" in
      list|"") echo "device                                 port"
               _ports_read | sort -k2 -n | awk '{printf "%-38s %s\n", $1, $2}' ;;
      adopt)   # Write down what is already running, without touching a driver.
               # For a Mac that had drivers up before this map existed, and for
               # adopting a peer's assignments rather than competing with them.
               #
               # Read the whole list BEFORE the loop: _ports_remember goes over
               # SSH, and _ssh passes stdin to the remote command, so an ssh
               # call inside a loop reading from a pipe swallows every line not
               # yet read and only the first entry survives. Measured here on
               # 17 Sep — four live drivers, one adopted — and it is the same
               # trap `up` carries a comment about.
               lines=(); mapfile -t lines < <(_driver_map --fresh)
               n=0
               for l in "${lines[@]}"; do
                 set -- $l; u=${1:-}; pt=${2:-}
                 [ -n "$u" ] && [ -n "$pt" ] || continue
                 _ports_remember "$u" "$pt"; n=$((n + 1))
                 echo "  $u  $pt"
               done
               echo "adopted $n live driver port(s); nothing was restarted" ;;
      forget)  _ports_forget "${3:-}"
               echo "forgot ${3:-every remembered port}" ;;
      *) echo "usage: $0 ports [list|adopt|forget [<udid>]]" >&2; exit 2 ;;
    esac ;;
  down)
    u=${2:?usage: drivers.sh down <udid>}
    pid=$(_driver_map --fresh | awk -v d="$u" '$1==d{print $3; exit}')
    [ -n "$pid" ] || { echo "no driver for $u"; exit 0; }
    _ssh "kill $pid 2>/dev/null; pkill -f 'test-without-building.*$u' 2>/dev/null; true" >/dev/null
    _driver_scan >/dev/null
    _driver_disown "$u"
    _ssh "rm -f '$RDIR/labels/$u'" >/dev/null 2>&1 || true
    echo "stopped the driver for $u"
    ;;
  down-all)
    _ssh "pkill -f 'maestro-driver-iosUITests-Runner' 2>/dev/null
          pkill -f 'test-without-building' 2>/dev/null; true" >/dev/null
    _driver_scan >/dev/null
    _driver_disown
    _ssh "rm -rf '$RDIR/labels'" >/dev/null 2>&1 || true
    echo "stopped every driver on $(_where)"
    ;;
  *) echo "usage: drivers.sh [list|up [udid]|down <udid>|down-all|rig [up|down|status]|ports [list|adopt|forget [udid]]]" >&2; exit 2 ;;
esac
