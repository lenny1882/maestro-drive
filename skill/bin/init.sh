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
# --write puts the file in $PWD unless --path says otherwise, and refuses to
# overwrite an existing one without --force.
set -uo pipefail

HOST=""; FQDN=""; APP=""; REPO=""; DEVU=""; OUT="$PWD/.maestro-mac.conf"
DETECT=0; WRITE=0; FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --host)  HOST=$2; shift 2 ;;
    --fqdn)  FQDN=$2; shift 2 ;;
    --app)   APP=$2; shift 2 ;;
    --repo)  REPO=$2; shift 2 ;;
    --dev)   DEVU=$2; shift 2 ;;
    --path)  OUT=$2; shift 2 ;;
    --detect) DETECT=1; shift ;;
    --write)  WRITE=1; shift ;;
    --force)  FORCE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15)

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
  [ -z "$HOST" ] && miss="$miss --host"
  [ -z "$FQDN" ] && miss="$miss --fqdn"
  [ -z "$APP" ]  && miss="$miss --app"
  [ -n "$miss" ] && { echo "missing:$miss" >&2; exit 2; }
  if [ -e "$OUT" ] && [ "$FORCE" != 1 ]; then
    echo "$OUT already exists — pass --force to replace it" >&2
    echo "current contents:" >&2; sed 's/^/  /' "$OUT" >&2
    exit 1
  fi
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
  [ -n "$REPO" ] && printf '\n# Checkout on the Mac, for git and source reading.\n: "${REPO:=%s}"\n' "$REPO" >> "$OUT"
  [ -n "$DEVU" ] && printf '\n# Pin a simulator. Empty means the first booted one.\n: "${DEV:=%s}"\n' "$DEVU" >> "$OUT"
  echo "wrote $OUT"
  sed 's/^/  /' "$OUT"
  # journeys and app notes belong to the project, so create the places they go
  MAESTRO_MAC_CONF="$OUT" "$(dirname "$0")/notes.sh" init
  if git -C "$(dirname "$OUT")" rev-parse --git-dir >/dev/null 2>&1; then
    cat <<'NOTE'

This is a git working tree. .maestro-mac.conf and maestro/ are untracked, so
they will show in `git status` and can be committed by accident. Decide with
whoever owns the repo whether they belong in it; to keep them out, add:

  .maestro-mac.conf
  maestro/
NOTE
  fi
  exit 0
fi

sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
