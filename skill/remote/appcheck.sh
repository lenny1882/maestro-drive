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

appcheck() {  # appcheck <app-container> <repo-on-the-mac> [marker]
  _c=$1; _repo=${2:-}; _marker=${3:-}

  if [ -z "$_c" ] || [ ! -d "$_c" ]; then
    echo "the app is not installed on this simulator, so there is nothing to compare"
    return 0
  fi

  # The executable, not the bundle: installing rewrites the directory's
  # timestamp, so the directory says when it was put there and the binary says
  # what it is. Fall back to the bundle when the plist cannot be read.
  _exe=$(_ac_plist "$_c" CFBundleExecutable)
  _bin=$_c
  [ -n "$_exe" ] && [ -f "$_c/$_exe" ] && _bin=$_c/$_exe

  _it=$(_ac_epoch "$_bin")
  _ver=$(_ac_plist "$_c" CFBundleShortVersionString)
  _bld=$(_ac_plist "$_c" CFBundleVersion)
  _tag=""
  [ -n "$_ver" ] && _tag="  ($_ver${_bld:+ build $_bld})"
  echo "installed  $(_ac_when "$_it")$_tag"

  if [ -z "$_repo" ] || [ ! -d "$_repo/.git" ]; then
    echo "(no checkout on the Mac to compare it with — set REPO in the conf)"
  else
    _ht=$(cd "$_repo" && git log -1 --format=%ct 2>/dev/null)
    _br=$(cd "$_repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$_ht" ]; then
      echo "(no commits in $_repo, so there is nothing to compare it with)"
    else
      echo "newest commit  $(_ac_when "$_ht")  on $_br"
      if [ -z "$_it" ]; then
        echo "(could not read the installed build's timestamp, so nothing is compared)"
      elif [ "$_it" -lt "$_ht" ]; then
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

  if [ -n "$_marker" ]; then
    if LC_ALL=C grep -rq -- "$_marker" "$_c" 2>/dev/null; then
      echo "marker: found \"$_marker\" in the installed bundle"
    else
      echo "MARKER MISSING: \"$_marker\" is not in the installed bundle, so this is"
      echo "                not the build you are looking for."
    fi
  fi
}
