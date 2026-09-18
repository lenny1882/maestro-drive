#!/bin/sh
# Is the app on the simulator the code under test?
#
# Sourced into the remote shell by bin/preflight.sh, which then calls
# `appcheck <container> <repo> [marker]`. It is a file rather than more lines
# inside preflight's SSH string so that it can be run and tested off a Mac —
# hence the BSD-then-GNU pairs below, which are not defensive padding: `stat`
# and `date` genuinely take different flags on the two, and the tests run on
# Linux while the real thing runs on macOS.
#
# Why it exists: sessions A and B each worked this check out from scratch, in
# three or four calls apiece, and **both found the simulator running a build
# from a different branch**. Without it both reviews would have been worthless.
# A third instance turned up on 13 Aug without anyone looking for it.
#
# What it can and cannot say. An installed build older than the newest commit
# cannot contain that commit — that is a fact, and it is the case that bit A
# and B. The reverse is not a fact: a build newer than HEAD may still have come
# from another branch, because a checkout can move after a build. Only the
# optional marker settles that, so the wording here is careful not to promise
# more than it knows.

_ac_epoch() {  # modification time of a path, in seconds
  # GNU first, and the answer is checked rather than trusted: `stat -f` exists
  # on both and means completely different things — a format string on BSD, and
  # "print the file system's status" on GNU, which *succeeds* and prints a
  # block count. Ordering alone is not enough, because a wrong number here is
  # silently compared against a commit date.
  _e=$(stat -c %Y "$1" 2>/dev/null) || _e=""
  case "$_e" in ''|*[!0-9]*) _e=$(stat -f %m "$1" 2>/dev/null) ;; esac
  case "$_e" in ''|*[!0-9]*) return 1 ;; esac
  echo "$_e"
}

_ac_when() {   # an epoch as a readable local time
  date -r "$1" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$1" '+%Y-%m-%d %H:%M' 2>/dev/null
}

_ac_ago() {    # a gap in seconds, said the way a person would
  s=$1
  [ "$s" -lt 0 ] && s=$((-s))
  if   [ "$s" -lt 3600 ];  then echo "$((s / 60)) minutes"
  elif [ "$s" -lt 86400 ]; then echo "$((s / 3600)) hours"
  else                          echo "$((s / 86400)) days"
  fi
}

_ac_plist() {  # one key out of a bundle's Info.plist, or nothing
  # PlistBuddy is the only one of these that reads the binary plists a real
  # build produces. The XML fallback is for the fixtures the tests use.
  /usr/libexec/PlistBuddy -c "Print :$2" "$1/Info.plist" 2>/dev/null && return 0
  # Newlines removed first, so this reads a key and its value whether they sit
  # on one line or two. Reading only the following line looked right and
  # quietly returned the *next* key's value on a one-line plist.
  tr -d '\n' < "$1/Info.plist" 2>/dev/null |
    sed -n "s|.*<key>$2</key>[^<]*<string>\([^<]*\)</string>.*|\1|p"
}

appcheck() {  # appcheck <info-file> <repo> [marker] [built-version]
  # <info-file> is `platform.sh installed-info` — key=value lines, with only the
  # keys that platform can answer. An ABSENT key means "cannot tell" and is
  # reasoned from; it is not an error.
  #
  #   version=3.0.4     build=43        every platform
  #   epoch=1758230000                  simulator and Android; a phone has none
  #   container=/path                   simulator only
  #
  # [built-version] is `framework.sh version` — what a build FROM THIS CHECKOUT
  # would produce, as <version>+<build>. It is what makes the check work at all
  # on a device: devicectl reports a version and a build and no timestamp of any
  # kind, so there is nothing to compare against a commit date.
  _info=${1:-}; _repo=${2:-}; _marker=${3:-}; _built=${4:-}

  if [ -z "$_info" ] || [ ! -r "$_info" ]; then
    echo "the app is not installed on this device, so there is nothing to compare"
    return 0
  fi
  _c=$(sed -n 's/^container=//p'  "$_info" | tail -1)
  _it=$(sed -n 's/^epoch=//p'     "$_info" | tail -1)
  _ver=$(sed -n 's/^version=//p'  "$_info" | tail -1)
  _bld=$(sed -n 's/^build=//p'    "$_info" | tail -1)
  if [ -z "$_ver$_bld$_it" ]; then
    echo "the app is not installed on this device, so there is nothing to compare"
    return 0
  fi

  _tag=""
  [ -n "$_ver" ] && _tag="  ($_ver${_bld:+ build $_bld})"
  if [ -n "$_it" ]; then
    echo "installed  $(_ac_when "$_it")$_tag"
  else
    echo "installed  ${_ver:-?}${_bld:+ build $_bld}  (no install time — this platform does not report one)"
  fi

  # --- 1. the timestamp, where there is one ---------------------------------
  # The strongest of the three: a build older than a commit cannot contain it.
  _did=0
  # An install time with nothing to compare it against is a setting that is
  # missing, not a platform that cannot answer — say which, because the two have
  # different fixes and only one of them is the reader's to make.
  if [ -n "$_it" ] && { [ -z "$_repo" ] || [ ! -d "$_repo/.git" ]; }; then
    echo "(no checkout on the Mac to compare it with — set REPO in the conf)"
  fi
  if [ -n "$_it" ] && [ -n "$_repo" ] && [ -d "$_repo/.git" ]; then
    _ht=$(cd "$_repo" && git log -1 --format=%ct 2>/dev/null)
    _br=$(cd "$_repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$_ht" ]; then
      _did=1
      echo "newest commit  $(_ac_when "$_ht")  on $_br"
      if [ "$_it" -lt "$_ht" ]; then
        echo "STALE: the installed build is $(_ac_ago $((_ht - _it))) older than that"
        echo "       commit, so it cannot contain it. Rebuild before trusting"
        echo "       anything on screen."
      else
        echo "ok: the installed build is newer than that commit. That does not prove"
        echo "    it was built from $_br — a checkout can move after a build — only"
        echo "    that it is not stale."
      fi
    fi
  fi

  # --- 2. the version, which is all a phone has -----------------------------
  # A different claim from the timestamp, and in one way a better one: it
  # compares what was BUILT rather than when, so it catches a build from another
  # branch that a timestamp cannot. It is only as good as the build number
  # moving between builds, and it says so rather than implying more.
  if [ -n "$_built" ] && [ -n "$_ver" ]; then
    _did=1
    _bv=${_built%%+*}; _bb=${_built#*+}; [ "$_bb" = "$_built" ] && _bb=""

    # A FLAVOUR DECORATES THE VERSION. pubspec says 3.0.4 and the uat build
    # installs as 3.0.4-uat, so a literal comparison reports a mismatch on a
    # build that is exactly this code — measured 18 Sep 2026 against the phone,
    # and it would have been the first thing this check ever said to anybody.
    #
    # Matched as "the built version, optionally followed by -<suffix>" rather
    # than by stripping everything after a dash: a project whose real version is
    # 1.0.0-beta must still fail against a checkout building 1.0.0.
    _sfx=""
    case "$_ver" in
      "$_bv") : ;;
      "$_bv"-*) _sfx=${_ver#"$_bv"-} ;;
    esac
    if { [ "$_ver" = "$_bv" ] || [ -n "$_sfx" ]; } && { [ -z "$_bb" ] || [ "$_bld" = "$_bb" ]; }; then
      echo "version ok: installed $_ver${_bld:+ build $_bld} matches what this checkout builds"
      [ -n "$_sfx" ] && echo "            (the -$_sfx is the flavour decorating the version, not a difference)"
      [ -n "$_bb" ] || echo "            (no build number in the checkout, so only the version was compared)"
    else
      echo "VERSION MISMATCH: installed $_ver${_bld:+ build $_bld}, this checkout builds $_built."
      echo "                  Whatever is on the device, it is not this code."
    fi
  fi

  # --- 3. the marker, which needs a readable bundle -------------------------
  if [ -n "$_marker" ]; then
    if [ -z "$_c" ]; then
      echo "marker: cannot be checked — this platform has no readable app bundle"
    elif LC_ALL=C grep -rq -- "$_marker" "$_c" 2>/dev/null; then
      _did=1
      echo "marker: found \"$_marker\" in the installed bundle"
    else
      _did=1
      echo "MARKER MISSING: \"$_marker\" is not in the installed bundle, so this is"
      echo "                not the build you are looking for."
    fi
  fi

  # Never leave the reader thinking a check ran when none did.
  [ "$_did" = 1 ] || cat <<'MSG'
nothing could be compared: this platform reports no install time, the framework
gave no version to compare against, and no BUILD_MARKER is set. Set BUILD_MARKER
in the conf, or read the version above against what you expect.
MSG
}

# Executed rather than sourced: `sh appcheck.sh --run <container> <repo> [marker]`.
#
# Nothing in this file happens to need zsh's differences today — there is no
# unquoted expansion in a `for`, and no variable standing as a `case` pattern.
# That is luck rather than design. remote/gitstate.sh had both, was sourced into
# the shell ssh hands over, and reported every lock file as somebody's work for
# as long as it was parameterised; the fix was to stop sourcing it. This takes
# the same entry point so that the next edit here cannot reintroduce the same
# bug in a file nobody is watching for it.
#
# An explicit sentinel, because a sourced file sees the sourcing script's $1 and
# there is no $BASH_SOURCE in POSIX sh to tell the two apart.
if [ "${1:-}" = --run ]; then
  appcheck "${2:-}" "${3:-}" "${4:-}" "${5:-}"
fi
