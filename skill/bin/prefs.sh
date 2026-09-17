#!/bin/bash
# Read the app's persisted NSUserDefaults from the simulator or device.
#
# iOS flushes NSUserDefaults lazily, so freshly-written keys are not on disk
# until the app is backgrounded. This script backgrounds the app first, then
# reads the plist from the data container. `defaults read` cannot see the
# app's container domain, so the plist is read as a file.
#
#   ./bin/prefs.sh                  # all flutter.* keys
#   ./bin/prefs.sh idle_logout      # keys matching a pattern
#   ./bin/prefs.sh --all            # every key
#   ./bin/prefs.sh --raw            # the raw plist XML
set -uo pipefail
. "$(dirname "$0")/lib.sh"
d=$(_dev) || exit 1

filter="${1:-flutter}"
raw=false
all=false
case "$filter" in
  --raw) raw=true ;;
  --all) all=true ;;
esac

_ssh "
# Background the app to flush NSUserDefaults to disk
xcrun simctl spawn '$d' notifyutil -p com.apple.mobile.application_did_enter_background 2>/dev/null
sleep 0.5

C=\$(xcrun simctl get_app_container '$d' '$APP_ID' data 2>/dev/null)
if [ -z \"\$C\" ]; then
  echo 'app $APP_ID is not installed on $d' >&2
  exit 1
fi
PLIST=\"\$C/Library/Preferences/$APP_ID.plist\"
if [ ! -f \"\$PLIST\" ]; then
  echo \"no prefs file at \$PLIST\" >&2
  echo '  the app may not have written any NSUserDefaults yet' >&2
  exit 1
fi
$(if $raw; then echo 'cat "\$PLIST"'
elif $all; then echo 'plutil -p "\$PLIST"'
else echo "plutil -p \"\\\$PLIST\" | grep -i '$filter'"
fi)
"
