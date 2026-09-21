#!/bin/bash
# Configuration loader. Everything else in bin/ sources this.
#
# The skill is used from any project, so the settings that vary — which Mac,
# which app, which checkout — live with the project rather than with the skill:
#
#   1. $MAESTRO_DRIVE_CONF, if set
#   2. .maestro-drive.conf, searched from $PWD upwards to /
#   3. ~/.maestro-drive.conf
#   4. the conf an earlier call in this session found by (2), remembered in
#      $LDIR — see _CONF_CACHE below
#
# Anything already exported wins over the file, so a one-off run can override a
# single value without editing anything:
#
#   APP_ID=com.example.other ./bin/driver.sh app
#
# If no file is found, bin/init.sh writes one. Do not add project values here.

# Step 4: the conf this session last found by walking up from $PWD.
#
# The upward search assumes $PWD is inside the project, and anything the toolkit
# spawns to run on its own is not: a watcher, a sampler, a background poll
# started from $TMPDIR searches $TMPDIR upwards, finds nothing, and stops with
# "not configured for this project" — which reads as a broken install rather
# than a working one started from the wrong directory. Measured 15 Sep 2026: a
# watcher died on exactly this and every relaunch afterwards had to carry
# MAESTRO_DRIVE_CONF by hand (BACKLOG item 71).
#
# The cache is per session, because $LDIR is ($TMPDIR is session-scoped in the
# sandbox), and it is only ever written from a step-2 hit — an explicit
# $MAESTRO_DRIVE_CONF is an override rather than a discovery, and ~/ is findable
# from anywhere already. A stale entry cannot mislead: the path is re-checked
# for readability before it is used.
_CONF_CACHE="${LDIR:-${TMPDIR:-/tmp}}/conf-path"

_find_conf() {
  if [ -n "${MAESTRO_DRIVE_CONF:-}" ]; then
    [ -r "$MAESTRO_DRIVE_CONF" ] || {
      echo "maestro-remote-mac: \$MAESTRO_DRIVE_CONF=$MAESTRO_DRIVE_CONF is not readable" >&2; return 1; }
    echo "$MAESTRO_DRIVE_CONF"; return
  fi
  local d="$PWD"
  while [ "$d" != "/" ]; do
    [ -r "$d/.maestro-drive.conf" ] && {
      printf '%s' "$d/.maestro-drive.conf" > "$_CONF_CACHE" 2>/dev/null
      echo "$d/.maestro-drive.conf"; return; }
    d=$(dirname "$d")
  done
  [ -r "$HOME/.maestro-drive.conf" ] && { echo "$HOME/.maestro-drive.conf"; return; }
  if [ -r "$_CONF_CACHE" ]; then
    local c; c=$(cat "$_CONF_CACHE" 2>/dev/null)
    [ -n "$c" ] && [ -r "$c" ] && { echo "$c"; return; }
  fi
}

MAESTRO_DRIVE_CONF_FOUND=$(_find_conf)
if [ -n "$MAESTRO_DRIVE_CONF_FOUND" ]; then
  # shellcheck disable=SC1090
  . "$MAESTRO_DRIVE_CONF_FOUND"
  # Everything a project owns — its journeys, its app notes — is found relative
  # to the conf file, so a script run from a subdirectory still finds them.
  PROJECT_DIR=$(cd "$(dirname "$MAESTRO_DRIVE_CONF_FOUND")" && pwd)
else
  PROJECT_DIR=$PWD
fi

# Named value sets: PROFILE=<name> layers .maestro-drive.conf.<name> over the
# base, so a second store, tenant or region overrides only what differs.
# The base conf sets the shared values (MAC_HOST, REPO, APP_ID); the profile
# overrides the per-environment ones (APP_PIN, APP_STORE, APP_USER).
if [ -n "${PROFILE:-}" ] && [ -n "$MAESTRO_DRIVE_CONF_FOUND" ]; then
  _pfile="${MAESTRO_DRIVE_CONF_FOUND}.${PROFILE}"
  if [ -r "$_pfile" ]; then
    # shellcheck disable=SC1090
    . "$_pfile"
  else
    echo "maestro-remote-mac: profile '$PROFILE' not found — expected $_pfile" >&2
    exit 1
  fi
fi

# Which transport reaches the device (BACKLOG item 94):
#
#   ssh     a Mac across the network. What this package was built for, and the
#           default, so an existing conf is unchanged by this setting's arrival.
#   local   a simulator or emulator on the machine running the skill. MAC_HOST
#           and MAC_FQDN are then neither needed nor used.
#   bridge  the device is on this machine, and this process cannot reach it —
#           a Claude session's sandbox has no /dev/kvm, its own PID and network
#           namespaces, and writes confined to two directories. Scripts go to a
#           helper outside it through the shared scratch, and the screen's port
#           is reached the way the ssh transport reaches the Mac's, because the
#           sandbox really is a different machine from the device host
#           (BACKLOG item 96). BRIDGE_DIR says where the helper serves.
#
# An explicit setting rather than inferring it from an empty MAC_HOST. A conf
# with a misspelt MAC_HOST has to keep failing as a broken remote conf; if
# emptiness meant local, that typo would instead start looking for a device on
# this machine and report it as missing, which is a true statement about the
# wrong machine.
#
# Named TRANSPORT rather than MODE because it sits beside RUNNER, PLATFORM and
# PROFILE, which each select one thing and say which in their name.
: "${TRANSPORT:=ssh}"
case "$TRANSPORT" in
  ssh | local | bridge) ;;
  *)
    echo "maestro-remote-mac: TRANSPORT='$TRANSPORT' is not a transport — use ssh, local or bridge." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac
export TRANSPORT

# Two questions, not one, and most of the package cares about only one of them
# (BACKLOG item 96). Local versus remote is really:
#
#   _fs_shared    the machine with the device shares this filesystem, so a push
#                 is a copy and $RHELP is the checkout itself
#                 ssh: no.  local: yes.  bridge: yes.
#
#   _ports_here   a port on that machine is reachable from THIS process without
#                 a relay and without the proxy
#                 ssh: no.  local: yes.  bridge: NO — the device is on this
#                 machine and the sandbox is in the way, so the screen is
#                 reached exactly as the Mac's is.
#
# Every branch that used to ask "is this local" is really asking one of these.
_fs_shared()  { [ "${TRANSPORT:-ssh}" != ssh ]; }
_ports_here() { [ "${TRANSPORT:-ssh}" = local ]; }

# SSH host alias from ~/.ssh/config. It must be an alias with a Host block: a
# bare name gets no ProxyCommand, and without one there is no route out of the
# sandbox at all. Never a .local name. reference/setup.md §3.
#
# More than one alias may be given, separated by spaces, for a Mac that moves
# between networks:
#
#   : "${MAC_HOST:=mac-a mac-b}"
#
# The first that answers is used and remembered for the session (lib.sh,
# _pick_host). A single value behaves exactly as it always did and costs
# nothing extra — no probing happens unless there is a choice to make.
: "${MAC_HOST:=}"

# The Mac's mDNS name, used for HTTP only. The sandbox proxy resolves it, so it
# follows the Mac between networks and no address is ever hardcoded.
: "${MAC_FQDN:=}"

# App bundle id under test, and the checkout path on the Mac (optional — only
# git and source-reading helpers need it).
: "${APP_ID:=}"
: "${REPO:=}"

# Optional. A string that appears in the build under test and in no other, so
# `bin/preflight.sh` can say whether the app on the simulator is that build
# rather than merely a recent one — a widget key, a feature-flag name, a string
# only this branch introduces. Timestamps catch a stale install on their own;
# this is what catches a fresh install of the wrong branch.
#
# Deliberately not named APP_*: those are exported as project values and
# searched for by bin/secrets.sh as though they were credentials, which this is
# not.
: "${BUILD_MARKER:=}"

# Which runner modules this project uses (BACKLOG item 87, runners/README.md).
# Two axes, because they cross: the framework decides how the app is built and
# how you see inside it, the platform decides how it is installed and driven,
# and Flutter-on-Android is a real combination.
#
# Both default to what this package does today, so an existing conf is
# unchanged by their arrival. `bin/runner.sh which` says what is selected and
# what else is available; `bin/runner.sh detect` asks the checkout on the Mac.
#
# Nothing in bin/ or remote/ reads these yet — the Flutter and iOS logic is
# still in the files it has always been in.
: "${RUNNER:=flutter}"      # framework: flutter | react-native | ios | android
: "${PLATFORM:=ios}"        # platform:  ios | ios-device | android

# Flutter flavour and entrypoint, for bin/build.sh. Both are normally worked
# out from the repo — the flavour from which Xcode configuration produces
# APP_ID, the entrypoint from the flavour — so these are only needed when a
# project has two flavours building the same bundle id, or none at all.
: "${BUILD_FLAVOR:=}"
: "${BUILD_TARGET:=}"

# Simulator UDID. Empty means the first booted device.
: "${DEV:=}"

# Where scratch files live on the machine that holds the device. Screenshots,
# hierarchy dumps, flow output, driver labels, the ports map, the rig record.
: "${RDIR:=/tmp/maestro-mac}"

# Where the CODE that runs on that machine lives (BACKLOG item 94, 2.2).
#
# $RDIR did both jobs and they come apart the moment the device is here. Across
# ssh the helpers and the runner modules are PUSHED into $RDIR by
# bin/install.sh, so code and scratch share a directory and one name served.
# Locally there is nothing to push: the code is in the checkout already, and
# pointing a module path at /tmp/maestro-mac finds nothing — measured, exit 127
# from `sh: 0: Can't open`.
#
# Two names and not one, because the layouts differ. Pushed, the helpers land
# flat beside the scratch; in the checkout they are under remote/. The modules
# keep their runners/<name>/ shape in both.
#
#   ssh    RMODS=$RDIR/runners     RHELP=$RDIR
#   local  RMODS=<checkout>/runners  RHELP=<checkout>/remote
#
# Both resolve across ssh to exactly what $RDIR resolved to before this split.
if _fs_shared; then
  _SKILL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  : "${RMODS:=$_SKILL_DIR/runners}"
  : "${RHELP:=$_SKILL_DIR/remote}"
  unset _SKILL_DIR
else
  : "${RMODS:=$RDIR/runners}"
  : "${RHELP:=$RDIR}"
fi

# Local scratch. Must be writable inside the sandbox.
: "${LDIR:=${TMPDIR:-/tmp}}"

# Where the bridge helper serves, for TRANSPORT=bridge (BACKLOG item 96).
#
# A directory both sides can see — the session scratch — holding the control
# FIFO and one set of files per request. It is the capability: anything that can
# write in it can run anything on the machine with the device, which is why the
# helper refuses a directory that is not its own user's, logs every script it
# runs beside the FIFO, and is started deliberately rather than living in every
# session.
: "${BRIDGE_DIR:=}"

# Where the maestro binary is on the machine with the device — the directory, not
# the file, because it goes on PATH. The R family again, like $RJAVA.
#
# Left empty, $HOME/.maestro/bin is assumed, which is where Maestro's own
# installer puts it. Recorded by `bin/init.sh --detect ... --write`, which asks
# that machine's login shell: an install anywhere else lives on a PATH set in a
# shell init file, and neither ssh nor a launcher without a terminal reads one.
# Measured 21 Sep 2026 on this machine, where it is under /mnt/sda and the
# process running the package could not see it.
: "${RMAESTRO:=}"

# Where the JDK is on the machine with the device — the R family, like $RDIR and
# $RHELP. Written by `bin/init.sh --detect ... --write`, which asks that machine
# rather than assuming an installer's layout: sdkman, jenv, mise, asdf and a
# plain Homebrew install all put it somewhere different, and every one of them
# works by a line in the login shell's init, which is what gets asked.
#
# Left empty, bin/lib.sh falls back to asking the far side per command. Record
# it instead: the fallback cannot use the login shell, so it only finds a JDK
# macOS itself knows about or one on the non-interactive PATH.
: "${RJAVA:=}"

# Default timeout (seconds) for a remote command.
: "${TMO:=180}"

# Ports for the two relays. Both are published on the Mac's LAN interface and
# read from here by name. The viewer keeps 9999 on both sides so the URL matches
# the one open_maestro_viewer prints; change it only if something else on the
# Mac already has the port.
: "${VPORT:=9999}"          # Maestro Viewer

# The wall — every booted simulator on one page, bin/wall.sh. Unlike the viewer
# this port is ours to choose and never moves, which is the whole point: it is
# the URL you bookmark once. Maestro's own viewer port cannot be relied on, as
# `maestro mcp` takes "a free local port" for it unless --viewer-port says
# otherwise.
: "${WALLPORT:=9990}"

# The wall URL to publish, if the Mac is reached some other way — a tunnel, a
# different hostname, a reverse proxy. Left empty it is http://$MAC_FQDN:$WALLPORT/.
: "${WALL_URL:=}"

# The driver ports are NOT defaulted here. One simulator holds one driver, and
# each driver gets its own port, so the pair that is right depends on which
# device is being driven — bin/drivers.sh brings them up and lib.sh resolves
# them from the live processes on the Mac (_driver_bind). Setting either here or
# in the environment pins it and skips that lookup, which is what a one-off
# against a known port wants:
#
#   DRIVER_PORT=22088 ./bin/driver.sh nodes
#
# Whether they were set is remembered, because "unset" and "the default" have to
# be told apart.
_DPORT_PINNED=${DPORT:+1}
_DRIVER_PORT_PINNED=${DRIVER_PORT:+1}
: "${DPORT:=}"              # local relay port for the driver API
: "${DRIVER_PORT:=}"        # the driver's own loopback port on the Mac

# The first driver takes 22087, the port Maestro itself uses, so the MCP server
# keeps working against that one device. Every extra device counts up from
# there, out of Maestro's reach.
: "${DRIVER_PORT_BASE:=22087}"
: "${DPORT_BASE:=9101}"

# The viewer URL to publish. Left empty it is built as http://$MAC_FQDN:$VPORT/,
# which is right whenever the Mac is reached by name. Set it when the Mac is
# reached some other way — a tunnel, a different hostname, a reverse proxy — and
# viewer.sh will check and print this instead.
: "${VIEWER_URL:=}"

# Where this project keeps the things it discovers. Both are the project's, not
# the skill's: journeys describe one app's screens, and the notes record what was
# measured about that app.
: "${JOURNEY_DIR:=$PROJECT_DIR/maestro/journeys}"
: "${APP_NOTES:=$PROJECT_DIR/maestro/app-notes.md}"

# --- project values, and where a credential belongs -------------------------
# Anything this file sets whose name begins with APP_ is a *project value*: it
# is exported, so `${APP_PIN}` in a journey or a flow resolves from here instead
# of being typed on the command line every time.
#
# That is what makes a credential storable. The conf is the one file a project
# keeps out of version control — `bin/init.sh` says to gitignore it — while the
# journeys, the flows and the app notes are all committed. So a login PIN, or
# anything else that must not be in the repo, goes here and is referred to by
# name everywhere else. `bin/secrets.sh check` looks for the values having
# escaped into a file git would commit.
#
#   : "${APP_PIN:=1234}"      in the conf
#   type "^Passcode$" ${APP_PIN}   in a journey
#
# Two APP_ names are reserved and are NOT project values: APP_ID, the bundle id,
# and APP_NOTES, where the notes live. Both are ordinary settings, both are safe
# to commit, and neither is treated as a secret. They predate this convention;
# renaming them would break every conf already written.
APP_RESERVED=" APP_ID APP_NOTES APP_RESERVED "

# The names of every project value that actually has a value. Used by
# bin/notes.sh to refuse a note that would write one into the notes, and by
# bin/secrets.sh to search for them.
_app_vars() {
  local n
  for n in ${!APP_@}; do
    case "$APP_RESERVED" in *" $n "*) continue ;; esac
    [ -n "${!n}" ] && printf '%s\n' "$n"
  done
}

# Export them all, reserved ones included — a journey may legitimately want
# ${APP_ID}. Substitution happens in a child python3 reading os.environ, so a
# plain shell variable set above would not reach it.
for _n in ${!APP_@}; do export "${_n?}"; done
unset _n

# What a project must set depends on the transport. Local mode has no host and
# no mDNS name to give, so the ssh message would print two (unset) values
# against settings the reader was never meant to fill, and send them to a
# --detect that lists ssh aliases they do not have. This message is one of the
# more useful things this package prints; it stays that good for both shapes,
# which means two messages rather than one with a conditional clause in it.
#
# The searched-paths and detached-process paragraphs are the same in both,
# because the conf search is the same in both.
if [ "$TRANSPORT" = bridge ] && [ -n "$APP_ID" ] && [ -z "$BRIDGE_DIR" ]; then
  cat >&2 <<MSG
maestro-remote-mac: TRANSPORT=bridge with no BRIDGE_DIR.

The device is on this machine and this process cannot reach it, so scripts go
to a helper through a directory both sides can see. Nothing says where that is.

  BRIDGE_DIR=<directory the helper serves>   in .maestro-drive.conf

The helper is remote/bridge.sh and it is started deliberately — it is not
running in every session, by design.
MSG
  return 1 2>/dev/null || exit 1
fi

# The address of the machine with the device, for the URLs this process builds
# under TRANSPORT=bridge. The device is here, but this process reaches its ports
# the way it reaches the Mac's — through the relay and the proxy — so it needs an
# address that is routable from inside the sandbox rather than 127.0.0.1.
# `hostname -I` reports it, and so does `ssh <mac> 'echo $SSH_CLIENT'`.
: "${BRIDGE_HOST:=}"

if _fs_shared; then
  if [ -z "$APP_ID" ]; then
    cat >&2 <<MSG
maestro-remote-mac: not configured for this project.

  TRANSPORT=$TRANSPORT  APP_ID=${APP_ID:-(unset)}
  searched: \$MAESTRO_DRIVE_CONF, .maestro-drive.conf from \$PWD upwards, ~/.maestro-drive.conf,
            and $_CONF_CACHE (this session's last find), which is $([ -r "$_CONF_CACHE" ] && cat "$_CONF_CACHE" || echo "empty")

This transport drives a simulator or emulator on this machine, so MAC_HOST and
MAC_FQDN are neither needed nor read. APP_ID is the only required value: the
bundle id on iOS, the applicationId on Android.

If this is a watcher, sampler or anything else started detached, the search is
the problem and not the config: it walks up from \$PWD, and a detached process
starts nowhere near the project. Pass the conf explicitly:

  MAESTRO_DRIVE_CONF=<project>/.maestro-drive.conf <your command>

Run the skill's bin/init.sh to write one. It asks this machine which toolchains
and devices are here rather than guessing:

  bin/init.sh --local --detect             # toolchains, devices, AVDs, checkout
  bin/init.sh --local --app <bundle id or applicationId> [--repo <path>] --write
MSG
    return 1 2>/dev/null || exit 1
  fi
elif [ -z "$MAC_HOST" ] || [ -z "$MAC_FQDN" ] || [ -z "$APP_ID" ]; then
  cat >&2 <<MSG
maestro-remote-mac: not configured for this project.

  MAC_HOST=${MAC_HOST:-(unset)}  MAC_FQDN=${MAC_FQDN:-(unset)}  APP_ID=${APP_ID:-(unset)}
  searched: \$MAESTRO_DRIVE_CONF, .maestro-drive.conf from \$PWD upwards, ~/.maestro-drive.conf,
            and $_CONF_CACHE (this session's last find), which is $([ -r "$_CONF_CACHE" ] && cat "$_CONF_CACHE" || echo "empty")

If this is a watcher, sampler or anything else started detached, the search is
the problem and not the config: it walks up from \$PWD, and a detached process
starts nowhere near the project. Pass the conf explicitly:

  MAESTRO_DRIVE_CONF=<project>/.maestro-drive.conf <your command>

Run the skill's bin/init.sh to write one. It can list the candidates for each
value rather than guessing:

  bin/init.sh --detect                     # ssh aliases on this machine
  bin/init.sh --host <alias> --detect      # booted simulators and installed apps
  bin/init.sh --host <alias> --fqdn <name> --app <bundle-id> [--repo <path>] --write
MSG
  return 1 2>/dev/null || exit 1
fi


# --- permission allows for ssh and scp --------------------------------------
# Every call this skill makes to the Mac is an `ssh` or `scp` through the Bash
# tool, and without an allow entry each one waits for a permission prompt. The
# entry is two lines. `reference/setup.md` § 6 documents them and gives the
# wildcard-prefix advice, but nothing in the package writes them and nothing
# checked whether they were there, so on a new machine or in a new project they
# are simply absent and the cost is paid on every call until someone notices.
#
# Here rather than in a hook, for three reasons. This is already the first thing
# a project runs and it happens before any SSH. A hook could not write the
# settings file either, so it had no advantage — only a per-Bash-call cost for a
# condition that is true once per project, and a third registration in
# install.sh to keep alive (see item 67 for how that goes).
#
# Detection only. A shell script cannot write either settings file; the session
# asks which file the user wants and writes it with Edit.
#
# Both files count, and global counts for every project: ~/.claude/settings.json
# covers everything, the project's .claude/settings.local.json covers this one.
# The check matches the actual command, so a narrow Bash(ssh mac-a:*) passes
# for MAC_HOST=mac-a and a wide Bash(ssh mac-*:*) passes for all of them.
# Not in local transport. Measured before writing the guard, by removing it:
# the block is already silent there. It builds its command list from MAC_HOST's
# aliases, an empty list has nothing uncovered, and nothing is printed — so the
# guard buys one python3 subprocess per local session, not a behaviour change.
# It is here to say that in the file. A reader should not have to derive "local
# sessions never warn" from an empty split inside a heredoc'd python program,
# and the day MAC_HOST gains a local default is the day the derivation stops
# holding without anyone touching this block.
_PERM_WARNED="${LDIR:-${TMPDIR:-/tmp}}/perm-warned"

if [ "$TRANSPORT" = ssh ] && [ ! -e "$_PERM_WARNED" ] && command -v python3 >/dev/null 2>&1; then
  # First line is the wildcard to suggest; the rest are the uncovered commands.
  _perm_out=$(
    MAC_HOST="$MAC_HOST" PROJECT_DIR="$PROJECT_DIR" python3 - <<'PY' 2>/dev/null
import fnmatch, json, os

hosts = os.environ.get("MAC_HOST", "").split()
files = [
    os.path.expanduser("~/.claude/settings.json"),
    os.path.join(os.environ.get("PROJECT_DIR", ""), ".claude", "settings.local.json"),
]

patterns = []
for f in files:
    try:
        with open(f) as fh:
            data = json.load(fh)
    except Exception:
        continue                      # absent, unreadable or not JSON: no cover
    for entry in data.get("permissions", {}).get("allow", []) or []:
        if entry.startswith("Bash(") and entry.endswith(")"):
            # Bash(ssh mac-*:*) means "commands starting with `ssh mac-*`".
            # str.removesuffix is 3.9+; this machine's python3 is 3.8.
            pat = entry[5:-1]
            if pat.endswith(":*"):
                pat = pat[:-2]
            patterns.append(pat)

missing = [
    "%s %s" % (tool, host)
    for host in hosts
    for tool in ("ssh", "scp")
    if not any(fnmatch.fnmatch("%s %s" % (tool, host), p + "*") for p in patterns)
]

# One entry should cover every alias, because MAC_HOST is a list of them —
# the common prefix of "mac-a mac-b" is "mac-". A single alias gives
# itself, which is correct if narrower.
prefix = os.path.commonprefix(hosts) if hosts else ""
if len(prefix) < 2:
    prefix = hosts[0] if hosts else "<alias>"

print(prefix)
print("\n".join(missing))
PY
  )

  _perm_prefix=$(printf '%s\n' "$_perm_out" | sed -n 1p)
  _perm_missing=$(printf '%s\n' "$_perm_out" | sed -n '2,$p' | sed '/^$/d')

  if [ -n "$_perm_missing" ]; then
    : > "$_PERM_WARNED"
    cat >&2 <<MSG
maestro-remote-mac: no permission allow covers these calls, so each one will
wait for a prompt:

$(printf '%s\n' "$_perm_missing" | sed 's/^/  /; s/$/ .../')

  searched: ~/.claude/settings.json ........... covers every project
            $PROJECT_DIR/.claude/settings.local.json ... covers this one

Ask which file the user wants, then write permissions.allow in it:

  "Bash(ssh ${_perm_prefix}*:*)"
  "Bash(scp ${_perm_prefix}*:*)"

The wildcard is deliberate: MAC_HOST takes several aliases, one per network,
and a Mac that moves should not need a second answer. Choosing the project file
means being asked again the first time another project drives.

Said once per session. Nothing is blocked; this is the cost, not a failure.
MSG
  fi
  unset _perm_out _perm_prefix _perm_missing
fi
