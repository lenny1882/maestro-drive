#!/bin/sh
# Print the directory holding an executable on the machine this runs on.
#
#   sh whereis.sh maestro   ->  /mnt/sda/User/Programs/maestro/bin
#
# Asked of the machine's own login shell, for the same reason remote/javahome.sh
# asks it about the JDK: a tool that was installed anywhere but the default lives
# on a PATH set in a shell init file, and a non-interactive shell does not read
# one. Measured 21 Sep 2026 on this machine — Maestro is at
# /mnt/sda/User/Programs/maestro/bin, exported from ~/.bashrc, which ssh and any
# launcher without a terminal both skip.
#
# Run ONCE, at setup: bin/init.sh records the answer in the conf and every later
# command reads that. Not run per command — an interactive shell with no tty can
# hang, and $TMO would turn that into a three-minute stall inside _ssh.
set -u

name=${1:?whereis.sh <executable>}

# 1. Whatever the login shell can run. stdin closed and stderr dropped, because
#    an interactive shell with something to say would say it here.
p=$("${SHELL:-/bin/sh}" -ic "command -v $name" 2>/dev/null </dev/null)

# 2. This process's own PATH, which is the answer when the caller was started
#    from a shell that already had it.
[ -n "$p" ] || p=$(command -v "$name" 2>/dev/null)

[ -n "$p" ] || exit 1

# Through its symlinks, so a shim directory is not reported as the home of the
# thing it points at.
while [ -L "$p" ]; do
  l=$(readlink "$p")
  case "$l" in
    /*) p=$l ;;
    *)  p=$(dirname "$p")/$l ;;
  esac
done

[ -x "$p" ] || exit 1
d=$(cd "$(dirname "$p")" && pwd) || exit 1
printf '%s\n' "$d"
