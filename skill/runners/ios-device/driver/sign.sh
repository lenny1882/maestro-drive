#!/bin/bash
# Sign a driver that build.sh built, for a phone. Run from Terminal ON THE MAC,
# not over ssh: every codesign over ssh fails with errSecInternalComponent,
# because the login keychain is locked there (measured 24 Sep 2026).
#
#   sign.sh '<identity>' <profile.mobileprovision> <build-dir>
#
# The identity is an "Apple Development: …" name from
# `security find-identity -v -p codesigning`. The profile is a wildcard iOS App
# Development profile listing every phone to be driven — the same pair the
# prebuilt driver is re-signed with (physical-device.md §3). Nested code is
# signed before each app, and --generate-entitlement-der is required.
set -u
IDENT=${1:?usage: sign.sh '<identity>' <profile> <build-dir>}
PROF=${2:?profile}; OUT=${3:?build dir}
TMPD=$(mktemp -d)
security cms -D -i "$PROF" -o "$TMPD/prof.plist" || { echo "sign: cannot read $PROF" >&2; exit 1; }
TEAM=$(plutil -extract TeamIdentifier.0 raw "$TMPD/prof.plist")
cd "$OUT/Build/Products/Debug-iphoneos" || exit 1
ok=0
for APP in maestro-driver-ios.app maestro-driver-iosUITests-Runner.app; do
  BID=$(plutil -extract CFBundleIdentifier raw "$APP/Info.plist")
  plutil -extract Entitlements xml1 -o "$TMPD/ent.plist" "$TMPD/prof.plist"
  plutil -replace application-identifier -string "$TEAM.$BID" "$TMPD/ent.plist"
  cp "$PROF" "$APP/embedded.mobileprovision"
  find "$APP" -depth \( -name "*.framework" -o -name "*.dylib" -o -name "*.xctest" \) \
    -exec codesign --force --timestamp=none --sign "$IDENT" {} \;
  codesign --force --timestamp=none --generate-entitlement-der \
           --entitlements "$TMPD/ent.plist" --sign "$IDENT" "$APP"
  codesign --verify --deep --strict "$APP" && { echo "signed: $APP"; ok=$((ok + 1)); }
done
rm -rf "$TMPD"
[ "$ok" = 2 ] && echo "ALL SIGNED" || { echo "SIGNING FAILED — over ssh? run it from Terminal on the Mac" >&2; exit 1; }
