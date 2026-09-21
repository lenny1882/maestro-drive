#!/bin/bash
# Resolve and call a runner module. BACKLOG item 87; runners/README.md is the
# contract and runners/TEMPLATE/ is the module to copy.
#
#   bin/runner.sh framework <verb> [args...]   # run a framework verb here
#   bin/runner.sh platform  <verb> [args...]   # run a platform verb here
#   bin/runner.sh path framework               # the module's path in the sandbox
#   bin/runner.sh rpath platform               # its path on the Mac, for _ssh
#   bin/runner.sh which                        # which two modules are selected
#   bin/runner.sh detect                       # ask every framework to claim $REPO
#
# NOTHING IN bin/ OR remote/ CALLS THIS YET. The Flutter and iOS logic is still
# where it always was, in remote/build.sh, remote/vmservice.sh, bin/net.sh,
# bin/publish.sh, bin/prefs.sh, bin/preflight.sh and remote/gitstate.sh. This is
# the dispatcher those seven call sites will use, and runners/flutter and
# runners/ios are the worked examples that show the contract fits them.
#
# Which module is chosen comes from RUNNER and PLATFORM in .maestro-mac.conf,
# both defaulted in bin/config.sh to what this package does today.
set -uo pipefail
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RUNNERS=$(cd "$(dirname "$0")/../runners" && pwd)

# A Mac-side verb runs out of $RDIR, where bin/install.sh puts the module. The
# relative layout is preserved, so a module may refer to its sibling scripts.
RRUNNERS="$RMODS"

_module() {  # _module <framework|platform> -> path to the script
  local kind=$1 name
  case "$kind" in
    framework) name=${RUNNER:-} ;;
    platform)  name=${PLATFORM:-} ;;
    *) echo "runner: expected 'framework' or 'platform', got '$kind'" >&2; return 2 ;;
  esac
  [ -n "$name" ] || { echo "runner: $kind module not set — RUNNER and PLATFORM live in .maestro-mac.conf" >&2; return 2; }
  if [ ! -x "$RUNNERS/$name/$kind.sh" ] && [ ! -r "$RUNNERS/$name/$kind.sh" ]; then
    echo "runner: no $kind module called '$name'." >&2
    echo "  looked for $RUNNERS/$name/$kind.sh" >&2
    echo "  modules that have one: $(_have "$kind")" >&2
    return 2
  fi
  printf '%s' "$RUNNERS/$name/$kind.sh"
}

_have() {  # _have <framework|platform> -> the module names that answer it
  local d
  for d in "$RUNNERS"/*/; do
    [ -r "$d$1.sh" ] || continue
    case "$(basename "$d")" in TEMPLATE) continue ;; esac
    printf '%s ' "$(basename "$d")"
  done
}

case "${1:-}" in
  framework|platform)
    kind=$1; shift
    m=$(_module "$kind") || exit $?
    RDIR="$RDIR" LDIR="$LDIR" RMODS="$RMODS" RHELP="$RHELP" exec sh "$m" "$@"
    ;;

  path)
    m=$(_module "${2:?path <framework|platform>}") || exit $?
    printf '%s\n' "$m"
    ;;

  rpath)
    kind=${2:?rpath <framework|platform>}
    case "$kind" in framework) n=${RUNNER:-} ;; platform) n=${PLATFORM:-} ;; esac
    printf '%s/%s/%s.sh\n' "$RRUNNERS" "$n" "$kind"
    ;;

  which)
    printf 'framework  %-14s %s\n' "${RUNNER:-(unset)}" "$RUNNERS/${RUNNER:-?}/framework.sh"
    printf 'platform   %-14s %s\n' "${PLATFORM:-(unset)}" "$RUNNERS/${PLATFORM:-?}/platform.sh"
    printf 'available  framework: %s\n' "$(_have framework)"
    printf '           platform:  %s\n' "$(_have platform)"
    ;;

  detect)
    # Ask every framework module to claim $REPO, on the Mac, in one round trip.
    # More than one claim, or none, is refused with the candidates named — the
    # same standard remote/build.sh holds itself to when two flavours build one
    # bundle id. Guessing here installs the wrong app, silently.
    [ -n "${REPO:-}" ] || { echo "runner detect: REPO is not set — the checkout." >&2; exit 2; }
    # `claim` is the one framework verb that does not need the Mac: every
    # implementation is a filesystem test on the checkout — flutter reads
    # pubspec.yaml, react-native reads package.json's dependencies. It goes
    # through _ssh here only because in ssh transport the checkout is on the
    # Mac. Locally it is on this machine, so the module runs from $RUNNERS and
    # nothing leaves the box (item 94).
    claims=$(
      for n in $(_have framework); do
        if _fs_shared; then
          out=$(sh "$RUNNERS/$n/framework.sh" claim "$REPO" 2>/dev/null)
        else
          out=$(_ssh "sh '$RRUNNERS/$n/framework.sh' claim '$REPO' 2>/dev/null")
        fi
        [ $? -eq 0 ] && printf '%s\t%s\n' "$n" "$out"
      done
    )
    n=$(printf '%s\n' "$claims" | grep -c .)
    case "$n" in
      1) printf 'RUNNER=%s   (%s)\n' "$(printf '%s' "$claims" | cut -f1)" "$(printf '%s' "$claims" | cut -f2)" ;;
      0) echo "runner detect: no framework module claims $REPO." >&2
         echo "  tried: $(_have framework)" >&2
         echo "  set RUNNER in .maestro-mac.conf, or write a module: runners/README.md" >&2
         exit 1 ;;
      *) echo "runner detect: $n framework modules claim $REPO, so it is not decided:" >&2
         printf '%s\n' "$claims" | sed 's/^/  /' >&2
         echo "  set RUNNER in .maestro-mac.conf." >&2
         exit 1 ;;
    esac
    ;;

  -h|--help|'') sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "runner: unknown command '$1'" >&2; exit 2 ;;
esac
