#!/bin/bash
#
# SUPERSEDED — kept because the numbers are worth being able to re-derive.
# The question it was built to answer (is there a warm-up benefit to recover?)
# was answered: no. On Maestro 2.12.1 a fresh `maestro hierarchy` costs about 5.2s
# every time — 5.91s cold, then 5.22/5.22/5.20s — because each CLI invocation
# re-establishes its session with the driver. Only a resident client avoids it,
# which is what the MCP server is. See reference/driving.md for the comparison table.
#
# Re-run this after a Maestro upgrade, or on a different Mac. It costs the device
# its driver: Maestro ends the runner when `maestro hierarchy` finishes, so the
# next driver.sh call finds none until bin/drivers.sh up has run again.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
d=$(_dev) || exit 1

# The round trip is the thing this script was built to price, so locally it
# says there is none rather than printing three numbers near zero. Those numbers
# would be real — fork and exec cost something — but they would be measuring the
# shell, and a reader comparing them against the Mac's 0.30-0.44s would be
# comparing two different quantities that share a heading.
if _fs_shared; then
  echo "== round trip =="
  echo "  none. The device is on this machine and nothing crosses a network."
  _WHERE="on this machine"
else
  # MAC_HOST can name several aliases and ssh takes one (item 132).
  _pick_host || exit 1
  echo "== SSH round trip, no work =="
  for i in 1 2 3; do
    s=$(date +%s.%N); ssh "${SSH_OPTS[@]}" "$MAC_HOST" true; e=$(date +%s.%N)
    printf '  %.2fs\n' "$(echo "$e - $s" | bc)"
  done
  _WHERE="on the Mac"
fi

echo "== $_WHERE =="
_ssh "
echo '-- JVM only (maestro --version) x2 --'
for i in 1 2; do /usr/bin/time -p maestro --version >/dev/null 2>>/tmp/b.err; grep real /tmp/b.err | tail -1; : > /tmp/b.err; done
echo '-- hierarchy x4: run 1 cold, 2-4 warm --'
for i in 1 2 3 4; do
  /usr/bin/time -p maestro --device $d hierarchy >/dev/null 2>>/tmp/b.err
  printf '  run %s: ' \$i; grep real /tmp/b.err | tail -1; : > /tmp/b.err
done
rm -f /tmp/b.err"

echo "== driver =="
echo "  maestro hierarchy has ended $d's driver. Bring it back: bin/drivers.sh up $d"
