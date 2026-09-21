#!/bin/sh
# Print the JDK's home directory on the machine this runs on, or exit 1.
#
# Asked of the machine rather than assumed, because there is no one place a JDK
# lives: sdkman, jenv, mise, asdf, jabba, Homebrew, an Apple installer and a
# hand-unpacked tarball all put it somewhere different, and naming any one of
# them in this package makes that manager a requirement. What every version
# manager has in common is that it works by a line in the login shell's init —
# so the first question is what the machine's own shell says, and the rest are
# for a machine whose shell says nothing.
#
# Run ONCE, at setup: bin/init.sh records the answer as RJAVA in the project's
# conf and every later command reads that. Not run per command — an interactive
# shell with no tty can hang (measured 21 Sep 2026: one run in three took the
# full 60s), and $TMO would turn that into a three-minute stall inside _ssh.
set -u

_ok() { [ -n "${1:-}" ] && [ -x "$1/bin/java" ]; }

# 1. Whatever the login shell's init sets. stdin closed and stderr dropped,
#    because an interactive shell with something to say would say it here.
h=$("${SHELL:-/bin/sh}" -ic 'printf %s "${JAVA_HOME:-}"' 2>/dev/null </dev/null)
_ok "$h" || h=

# 2. macOS's own registry. It reads the bundles under /Library/Java and
#    ~/Library/Java, so it finds an Apple-installed or Homebrew-cask JDK and
#    misses one a version manager keeps in its own directory.
if [ -z "$h" ] && [ -x /usr/libexec/java_home ]; then
  h=$(/usr/libexec/java_home 2>/dev/null) || h=
  _ok "$h" || h=
fi

# 3. The java the login shell can actually run, resolved through its symlinks.
#    /usr/bin/java on macOS is a stub that dispatches to a registered JVM rather
#    than a link into one, so a resolution ending there has found nothing —
#    while on Linux that same path is a symlink chain into the real JDK.
if [ -z "$h" ]; then
  j=$("${SHELL:-/bin/sh}" -ic 'command -v java' 2>/dev/null </dev/null)
  while [ -L "$j" ]; do
    l=$(readlink "$j")
    case "$l" in
      /*) j=$l ;;
      *)  j=$(dirname "$j")/$l ;;
    esac
  done
  case "$j" in
    ""|/usr/bin/java) j= ;;
  esac
  [ -n "$j" ] && h=${j%/bin/java}
  _ok "$h" || h=
fi

# 4. Ask java itself. Any java that can run answers this, which is what makes it
#    the rung that covers the shim managers: jenv without its export plugin, and
#    mise or asdf through shims rather than `activate`, put a shell SCRIPT called
#    java on PATH. Rung 3 resolves that to the shim's own directory, which has no
#    bin/java under it, so a machine with a perfectly good JDK came back empty.
#
#    Last, because it starts a JVM — a fifth of a second against three rungs that
#    cost nothing — and because a rung above it answering means the answer was
#    already unambiguous.
if [ -z "$h" ]; then
  h=$("${SHELL:-/bin/sh}" -ic 'java -XshowSettings:properties -version' 2>&1 </dev/null |
      sed -n 's/^ *java\.home = //p' | head -1 | tr -d '[:space:]')
  _ok "$h" || h=
fi

[ -n "$h" ] || exit 1
printf '%s\n' "$h"
