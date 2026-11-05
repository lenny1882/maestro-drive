#!/bin/sh
# Did the last Maestro upgrade finish? The install changes the CLI and leaves two
# things behind, and neither says so: the capture binary the wall runs, and the
# phone driver. Each line names the step in reference/setup.md, "Upgrading Maestro".
#
# It always exits 0: preflight is reporting, and the rest of its report still counts.
JAR=$(ls "$HOME"/.maestro/lib/maestro-cli-*.jar 2>/dev/null | head -1)
if [ -z "$JAR" ]; then
  echo "  no maestro-cli jar under ~/.maestro/lib"
  exit 0
fi
V=$(basename "$JAR" .jar); V=${V#maestro-cli-}
SAID=

DEP=$HOME/.maestro/deps/simulator-server
WANT=$(unzip -p "$JAR" deps/simulator-server/darwin/simulator-server 2>/dev/null | cksum)
if [ "$(cksum < "$DEP" 2>/dev/null)" != "$WANT" ]; then
  echo "  ~/.maestro/deps/simulator-server is not the one in Maestro $V (step 2):"
  echo "    unzip -p $JAR deps/simulator-server/darwin/simulator-server > $DEP"
  SAID=1
fi

# Only for a Mac with a phone driver at all. Either driver will do: deviceup.sh
# prefers the source build and falls back to the prebuilt one.
PRE=$HOME/.maestro/maestro-iphoneos-driver-build/version.properties
BUILDS=$(ls -d "$HOME"/maestro-drive-driver/build-* 2>/dev/null | grep -v '\.log$')
if [ -n "$BUILDS" ] || [ -r "$PRE" ]; then
  PV=$(sed -n 's/^version=//p' "$PRE" 2>/dev/null)
  if [ ! -d "$HOME/maestro-drive-driver/build-$V" ] && [ "$PV" != "$V" ]; then
    echo "  no phone driver for Maestro $V (step 3): runners/ios-device/driver/build.sh $V, then driver/sign.sh in the Mac's GUI Terminal"
    SAID=1
  fi
fi

[ -n "$SAID" ] || echo "  Maestro $V: capture binary and phone driver match"
exit 0
