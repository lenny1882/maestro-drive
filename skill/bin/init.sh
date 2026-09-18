#!/bin/bash
# Write a project's .maestro-mac.conf.
#
# Deliberately does not guess. `--detect` asks the machine — this one for SSH
# aliases, the Mac for booted simulators and the apps installed on them — and
# prints the candidates so the values put in the file are ones that exist.
#
#   bin/init.sh --detect                        # ssh aliases here
#   bin/init.sh --host <alias> --detect         # simulators + installed apps
#   bin/init.sh --host <alias> --fqdn <mac>.local \
#               --app <bundle-id> --repo <checkout on the Mac> --write
#
# --local writes a conf for a device on THIS machine (BACKLOG item 94). There
# is no host to give, so --app is the only required value:
#
#   bin/init.sh --local --detect                # toolchains, devices, AVDs
#   bin/init.sh --local --app <bundle-id> [--repo <checkout>] --write
#
# --write puts the file in $PWD unless --path says otherwise, and refuses to
# overwrite an existing one without --force.
set -uo pipefail

HOST=""; FQDN=""; APP=""; REPO=""; DEVU=""; OUT="$PWD/.maestro-mac.conf"
DETECT=0; WRITE=0; FORCE=0; LOCAL=0; PLATU=""
_PLAT=""; _PLAT_WHY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --host)  HOST=$2; shift 2 ;;
    --fqdn)  FQDN=$2; shift 2 ;;
    --app)   APP=$2; shift 2 ;;
    --repo)  REPO=$2; shift 2 ;;
    --dev)   DEVU=$2; shift 2 ;;
    --path)  OUT=$2; shift 2 ;;
    --local) LOCAL=1; shift ;;
    --platform) PLATU=$2; shift 2 ;;
    --detect) DETECT=1; shift ;;
    --write)  WRITE=1; shift ;;
    --force)  FORCE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Refused, not ignored. A flag that is silently dropped leaves someone believing
# they configured a thing they did not, and --host with --local is either a
# typo or a misunderstanding of which machine holds the device. Say which.
if [ "$LOCAL" = 1 ] && { [ -n "$HOST" ] || [ -n "$FQDN" ]; }; then
  echo "--local drives a device on this machine, so there is no --host or --fqdn." >&2
  echo "Drop them, or drop --local to configure a Mac across the network." >&2
  exit 2
fi

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15)

# Which platform a local conf should name, and the evidence for it. Two signals,
# and they are different facts: a booted device is one, an AVD that exists but
# is not running is the weaker other. The conf comment says which was found,
# because a default presented as a finding is how a wrong runner survives a
# setup (item 87, 5.2).
#
# `emulator -list-avds` writes crash-reporter lines to stderr on this machine,
# so stdout only or the AVD names arrive with noise attached.
_android_evidence() {
  local d a
  d=$(adb devices 2>/dev/null | sed -n 's/\tdevice$//p' | head -1)
  [ -n "$d" ] && { printf 'a booted device, %s' "$d"; return 0; }
  a=$(emulator -list-avds 2>/dev/null)
  if [ -n "$a" ]; then
    # All of them, with the count. A truncated list in a conf comment reads as
    # the whole answer, and the reader has no way to tell that it is not.
    printf 'AVDs defined but none booted (%s): %s' \
      "$(printf '%s\n' "$a" | grep -c .)" \
      "$(printf '%s' "$a" | tr '\n' ' ' | sed 's/ *$//')"
    return 0
  fi
  printf 'the SDK is here, with no device and no AVD'
}

# Sets _PLAT (empty when it cannot be decided) and _PLAT_WHY (always).
_local_platform() {
  local has_adb=0 has_xcrun=0
  command -v adb   >/dev/null 2>&1 && has_adb=1
  command -v xcrun >/dev/null 2>&1 && has_xcrun=1
  if [ "$has_adb" = 1 ] && [ "$has_xcrun" = 1 ]; then
    _PLAT=""
    _PLAT_WHY="both an Android SDK and Xcode are on this machine"
  elif [ "$has_adb" = 1 ]; then
    _PLAT="android"
    _PLAT_WHY="detected: no xcrun on this machine, and $(_android_evidence)"
  elif [ "$has_xcrun" = 1 ]; then
    _PLAT="ios"
    _PLAT_WHY="detected: xcrun is here and no Android SDK is"
  else
    _PLAT=""
    _PLAT_WHY="neither an Android SDK nor Xcode is on this machine"
  fi
}

# Two URLs for one repository barely look alike:
#   git@bitbucket.org:acme/thing.git
#   https://bitbucket.org/acme/thing
# Reduce both to host/path, lowercased, no .git — enough to match the same
# repository across the two forms without pretending to parse URLs properly.
_norm() {
  printf '%s' "${1:-}" |
    sed -E 's#^[a-z+]+://##; s#^[^@]+@##; s#:#/#; s#\.git$##; s#/+$##' |
    tr 'A-Z' 'a-z'
}

if [ "$DETECT" = 1 ] && [ "$LOCAL" = 1 ]; then
  echo "== this machine"
  echo "  $(uname -s) $(uname -r) — the device is here, nothing goes over ssh"

  echo "== toolchains"
  printf '  adb:    %s\n' "$(command -v adb   2>/dev/null || echo 'not found')"
  printf '  xcrun:  %s\n' "$(command -v xcrun 2>/dev/null || echo 'not found')"

  _local_platform
  echo "== platform"
  if [ -n "$_PLAT" ]; then
    echo "  $_PLAT  ($_PLAT_WHY)"
  else
    echo "  cannot be decided here: $_PLAT_WHY"
    echo "  pass --platform ios|android"
  fi

  if command -v adb >/dev/null 2>&1; then
    echo "== android devices"
    adb devices -l 2>/dev/null | sed -n '2,$p' | sed '/^$/d; s/^/  /' |
      grep . || echo "  none attached"
    echo "== AVDs defined"
    emulator -list-avds 2>/dev/null | sed 's/^/  /' | grep . || echo "  none"
  fi
  if command -v xcrun >/dev/null 2>&1; then
    echo "== booted simulators"
    xcrun simctl list devices booted 2>/dev/null | sed -n 's/^ */  /p' |
      grep . || echo "  none booted"
  fi

  echo "== apps installed on the first booted device"
  if command -v adb >/dev/null 2>&1 && [ -n "$(adb devices 2>/dev/null | sed -n 's/\tdevice$//p')" ]; then
    adb shell pm list packages -3 2>/dev/null | sed 's/^package:/  /' | sort |
      grep . || echo "  none, or the device refused the query"
  elif command -v xcrun >/dev/null 2>&1; then
    xcrun simctl listapps booted 2>/dev/null |
      grep -o 'CFBundleIdentifier = "[^"]*"' | sed 's/.*= "/  /;s/"//' |
      grep -v '^  com\.apple\.' | sort -u | grep . || echo "  nothing booted to ask"
  else
    echo "  nothing booted to ask"
  fi

  echo "== this checkout"
  if git -C "$PWD" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "  $(git -C "$PWD" rev-parse --show-toplevel)  <- pass as --repo if the app is built from it"
  else
    echo "  $PWD is not a git working tree"
  fi

  echo
  echo "Then:  $0 --local --app <bundle id or applicationId> --write"
  exit 0
fi

if [ "$DETECT" = 1 ]; then
  if [ -z "$HOST" ]; then
    echo "== ssh aliases in ~/.ssh/config"
    awk 'tolower($1)=="host" {for(i=2;i<=NF;i++) if ($i !~ /[*?]/) print "  " $i}' \
      ~/.ssh/config 2>/dev/null | sort -u
    echo
    echo "Pick the one that reaches the Mac, then:  $0 --host <alias> --detect"
    exit 0
  fi
  echo "== reachable"
  ssh "${SSH_OPTS[@]}" "$HOST" 'echo "  ok: $(scutil --get LocalHostName 2>/dev/null).local  ($(sw_vers -productVersion))"' \
    || { echo "  cannot reach $HOST over ssh" >&2; exit 1; }
  echo "== booted simulators"
  ssh "${SSH_OPTS[@]}" "$HOST" 'xcrun simctl list devices booted | sed -n "s/^ */  /p"'
  echo "== apps installed on the first booted simulator"
  ssh "${SSH_OPTS[@]}" "$HOST" 'xcrun simctl listapps booted 2>/dev/null |
    grep -o "CFBundleIdentifier = \"[^\"]*\"" | sed "s/.*= \"/  /;s/\"//" |
    grep -v "^  com\.apple\." | sort -u'

  # The checkout, matched on the remote rather than the name. Session B spent
  # three SSH calls hunting for it by hand; this is one, and it says which
  # candidate is the same repository rather than which one is spelt the same.
  echo "== checkouts on the Mac"
  found=$(ssh "${SSH_OPTS[@]}" "$HOST" 'sh -s 5' < "$(dirname "$0")/../remote/findrepo.sh")
  if [ -z "$found" ]; then
    echo "  none found under the home directory (searched 5 deep, caches pruned)"
  else
    here=$(_norm "$(git -C "$PWD" remote get-url origin 2>/dev/null)")
    name=$(basename "$PWD")
    # Ranked, so the match is the first line rather than somewhere in a list of
    # a dozen. Same origin beats same name: two repositories can share a
    # directory name, and only one of them is this one.
    printf '%s\n' "$found" | while IFS=$'\t' read -r p o; do
      why=""; rank=2
      if [ -n "$here" ] && [ "$(_norm "$o")" = "$here" ]; then
        why="  <- same origin as $PWD"; rank=0
      elif [ "$(basename "$p")" = "$name" ]; then
        why="  <- same directory name, but a different origin"; rank=1
      fi
      printf '%s\t  %s%s\n' "$rank" "$p" "$why"
    done | sort -k1,1 | cut -f2-
    [ -n "$here" ] || echo "  (no origin here to match against — pick by name)"
  fi
  echo
  echo "Then:  $0 --host $HOST --fqdn <name from above> --app <bundle id> \\"
  echo "         --repo <checkout from above> --write"
  exit 0
fi

if [ "$WRITE" = 1 ]; then
  miss=""
  if [ "$LOCAL" = 1 ]; then
    # One required value. There is no host and no mDNS name to give.
    [ -z "$APP" ] && miss="$miss --app"
    [ -n "$miss" ] && { echo "missing:$miss" >&2; exit 2; }
    if [ -n "$PLATU" ]; then
      _PLAT="$PLATU"; _PLAT_WHY="given on the command line"
    else
      _local_platform
    fi
    # Decided before the file is created, so a machine that cannot answer does
    # not leave half a conf behind for the next run to refuse to overwrite.
    if [ -z "$_PLAT" ]; then
      echo "cannot tell which platform this machine drives: $_PLAT_WHY" >&2
      echo "pass --platform ios|android" >&2
      exit 2
    fi
  else
    [ -z "$HOST" ] && miss="$miss --host"
    [ -z "$FQDN" ] && miss="$miss --fqdn"
    [ -z "$APP" ]  && miss="$miss --app"
    [ -n "$miss" ] && { echo "missing:$miss" >&2; exit 2; }
  fi
  if [ -e "$OUT" ] && [ "$FORCE" != 1 ]; then
    echo "$OUT already exists — pass --force to replace it" >&2
    echo "current contents:" >&2; sed 's/^/  /' "$OUT" >&2
    exit 1
  fi
  if [ "$LOCAL" = 1 ]; then
    cat > "$OUT" <<EOF
# maestro-remote-mac — settings for this project.
# Written by bin/init.sh. The := form means anything already exported wins,
# so a one-off run can override a single value without editing this file.

# How the device is reached. local means a simulator or emulator on THIS
# machine: nothing goes over ssh, and MAC_HOST and MAC_FQDN are neither needed
# nor read.
: "\${TRANSPORT:=local}"

# The app under test. A bundle id on iOS, an applicationId on Android.
: "\${APP_ID:=${APP}}"
EOF
  else
    cat > "$OUT" <<EOF
# maestro-remote-mac — settings for this project.
# Written by bin/init.sh. The := form means anything already exported wins,
# so a one-off run can override a single value without editing this file.

# SSH host alias. It must be an alias with a Host block in ~/.ssh/config: a bare
# name gets no ProxyCommand, and without one there is no route out of the
# sandbox at all. Never a .local name.
: "\${MAC_HOST:=${HOST}}"

# The Mac's mDNS name, for HTTP only. The proxy resolves it, so URLs built from
# it follow the Mac between networks.
: "\${MAC_FQDN:=${FQDN}}"

# The app under test.
: "\${APP_ID:=${APP}}"
EOF
  fi
  cat >> "$OUT" <<'VALS'

# Project values. Anything named APP_* is exported, so a journey or a flow can
# say ${APP_PIN} rather than carry the value itself. APP_ID and APP_NOTES are
# reserved settings and are not treated as project values.
#
# This is where a credential goes. This file is kept out of version control;
# the journeys, the flows and the app notes are all committed, so a login PIN
# written into any of those ends up in the repo. `bin/secrets.sh check` looks
# for one having escaped.
#
#: "${APP_PIN:=}"
VALS
  if [ -n "$REPO" ]; then
    if [ "$LOCAL" = 1 ]; then
      printf '\n# Checkout on this machine, for git and source reading.\n: "${REPO:=%s}"\n' "$REPO" >> "$OUT"
    else
      printf '\n# Checkout on the Mac, for git and source reading.\n: "${REPO:=%s}"\n' "$REPO" >> "$OUT"
    fi
  fi

  # Which runner modules this project uses (BACKLOG item 87). Driving is the
  # same whatever built the app; building it, installing it and reading inside
  # it are not, and those come from two plug-in modules.
  #
  # The framework is ASKED rather than assumed, because the checkout is right
  # there and a wrong guess sends a session down a path that cannot work.
  # PLATFORM is written as ios and not detected: nothing has been booted at this
  # point in a first-time setup, so there is no device to ask about.
  _rn=
  if [ -n "$REPO" ]; then
    _rn=$(MAESTRO_MAC_CONF="$OUT" MAC_HOST="$HOST" MAC_FQDN="$FQDN" APP_ID="$APP" REPO="$REPO" \
          TRANSPORT="$([ "$LOCAL" = 1 ] && echo local || echo ssh)" \
          "$(dirname "$0")/runner.sh" detect 2>/dev/null |
          sed -n 's/^RUNNER=\([a-z-][a-z-]*\).*/\1/p')
  fi
  {
    printf '\n# Which runner modules build and install this app. Driving is the same\n'
    printf '# whatever built it; these two decide the rest. runners/README.md is the\n'
    printf '# contract, and bin/runner.sh which says what else is available.\n'
    if [ -n "$_rn" ]; then
      if [ "$LOCAL" = 1 ]; then
        printf ': "${RUNNER:=%s}"     # detected from the checkout on this machine\n' "$_rn"
      else
        printf ': "${RUNNER:=%s}"     # detected from the checkout on the Mac\n' "$_rn"
      fi
    else
      printf '# No framework module claimed the checkout, or REPO was not given, so this\n'
      printf '# is the default rather than a finding. bin/runner.sh detect asks again.\n'
      printf ': "${RUNNER:=flutter}"\n'
    fi
    if [ "$LOCAL" = 1 ]; then
      # The evidence goes above the setting, wrapped, rather than trailing it:
      # an AVD list is as long as the machine has AVDs and would run the line
      # past anything a reader can see at once.
      printf '%s\n' "$_PLAT_WHY" | fold -s -w 74 | sed 's/ *$//; s/^/# /'
      printf ': "${PLATFORM:=%s}"\n' "$_PLAT"
    else
      printf ': "${PLATFORM:=ios}"      # not detected: nothing is booted yet to ask about\n'
    fi
  } >> "$OUT"
  [ -n "$DEVU" ] && printf '\n# Pin a simulator. Empty means the first booted one.\n: "${DEV:=%s}"\n' "$DEVU" >> "$OUT"
  echo "wrote $OUT"
  sed 's/^/  /' "$OUT"
  # journeys and app notes belong to the project, so create the places they go
  MAESTRO_MAC_CONF="$OUT" "$(dirname "$0")/notes.sh" init
  if git -C "$(dirname "$OUT")" rev-parse --git-dir >/dev/null 2>&1; then
    cat <<'NOTE'

This is a git working tree. .maestro-mac.conf and maestro/ are untracked, so
they will show in `git status` and can be committed by accident.

The conf is the one file that must stay out: it is where a credential goes, and
bin/secrets.sh only checks it is gitignored once a project value exists — so the
first APP_PIN written into it would land in an untracked, unignored file that a
`git add -A` sweeps straight in. The second pattern is the PROFILE layering.
maestro/ is your decision; the journeys and notes in it are usually worth
committing.

  .maestro-mac.conf
  .maestro-mac.conf.*
NOTE
  fi
  exit 0
fi

sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
