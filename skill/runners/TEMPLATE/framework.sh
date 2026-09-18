#!/bin/sh
# Framework runner TEMPLATE — copy this directory, rename it, fill it in.
#
# A framework runner answers "how is this app built, and how do I see inside it
# while it runs". It knows nothing about simulators, emulators, ports or taps;
# that is the platform runner next door. runners/README.md is the contract.
#
# POSIX sh. The Mac's /bin/sh is bash 3.2 in sh mode, and the test suite runs
# these on Linux without a Mac.
#
# Exit status is the answer:
#   0  the verb succeeded, or the question is answered yes
#   1  a real failure — say what failed and what to do about it, on stderr
#   2  this framework does not have that verb. NOT a failure. The caller says
#      "native apps have no traffic endpoint", not "the relay is broken".
set -u

VERB=${1:-}; [ $# -gt 0 ] && shift

# Print this whenever a verb exits 2, so the caller can pass it straight
# through. One sentence naming what is absent and what the caller loses.
_unsupported() {  # _unsupported <sentence>
  echo "$1" >&2
  exit 2
}

case "$VERB" in

# --- claim <repo> ------------------------------------------------------------
# Is this checkout mine? Exit 0 and print one line of evidence — the file that
# decided it, not the word "yes". RUNNER=auto runs this against every runner and
# refuses if more than one claims, so a loose test here costs somebody a
# refusal they cannot act on.
claim)
  _repo=${1:?claim <repo>}
  # e.g. [ -r "$_repo/pubspec.yaml" ] && { echo "pubspec.yaml"; exit 0; }
  : "$_repo"
  exit 1
  ;;

# --- describe <repo> [app-id] ------------------------------------------------
# What a build would use, building nothing. Free-form text, one fact per line,
# label in the first column. This is the safe half that runs before asking the
# user whether to build, so it must never write anything.
#
#   toolchain  /Users/…/repo/.fvm/flutter/bin/flutter
#              Flutter 3.41.9 • channel stable • …
#   variant    dev — the only one whose app id is acme.e.brandco.runner.dev
#   target     lib/main_dev.dart
#   last build /Users/…/build/ios/iphonesimulator/Runner.app (2026-08-13 14:56)
#
# Where the toolchain is pinned by a version manager, prefer the pinned one over
# anything on PATH and say which you took. A bare `flutter`, `node` or `gradle`
# that is not there reads as a broken install rather than a version manager
# doing its job, and that has cost real minutes.
describe)
  _repo=${1:?describe <repo>}; _appid=${2:-}
  : "$_repo" "$_appid"
  exit 2
  ;;

# --- variants <repo> [--platform <p>] ----------------------------------------
# One buildable variant name per line, or nothing when the project has none.
#
# --platform is OPTIONAL and a module that does not distinguish ignores it.
# Flutter's flavours span both platforms — one `--flavor uat` builds the iOS and
# the Android app — so it answers the same list either way. React Native's do
# not: iOS schemes live in ios/*.xcodeproj and Android product flavours in
# android/app/build.gradle, and they need not share names, so it has two lists
# and needs telling which.
#
# An optional argument rather than a second verb, because the caller always
# knows its platform already — bin/build.sh has PLATFORM in hand — so passing it
# is free, and a framework that does not care is not made to care.
# A variant is only real if every half of it exists — the scheme AND the
# entrypoint, the product flavour AND its source set. Requiring all of them is
# what discards templates and sibling targets without knowing about either.
variants)
  _repo=${1:?variants <repo>}
  : "$_repo"
  exit 0
  ;;

# --- variant-for-appid <repo> <app-id> [--platform <p>] ----------------------
# Which variants produce that bundle or application id, one per line. Takes the
# same optional --platform as `variants`, and for the same reason: an app id is
# itself per-platform — a bundle id on iOS, an applicationId on Android — so a
# framework that keeps them apart needs telling which one it was handed. Zero lines
# or several both mean undecided, and the caller refuses — it does not pick.
#
# Work it out from the build configuration rather than from a name that happens
# to match. A seven-variant project has seven that all build cleanly and six of
# them install a different app.
variant-for-appid)
  _repo=${1:?variant-for-appid <repo> <app-id>}; _appid=${2:?app-id}
  : "$_repo" "$_appid"
  exit 0
  ;;

# --- build <repo> --platform <p> --mode <m> [--variant <v>] [--target <t>] ----
# Build, and print `artifact <path>` as the LAST line of stdout. Do not install:
# that is platform.sh install, and keeping them apart is what lets this runner
# work against a platform it has never heard of.
#
# --platform is ios | ios-device | android | android-device
# --mode     is debug | profile | release
#
# Name the exact output path rather than globbing for it. A tree holds stale
# output directories from earlier builds, and a wildcard picked one of those
# over the fresh output on 11 Sep 2026.
build)
  exit 2
  ;;

# --- version <repo> ----------------------------------------------------------
# The version and build a build FROM THIS CHECKOUT would produce, as
# `<version>+<build>` — the form Flutter's pubspec.yaml already uses.
#
# It exists for the platforms that cannot report when an app was installed. A
# phone gives a version and a build and no timestamp at all, so "is the app on
# this device the code under test" has to be answered by comparing what is
# installed against what this checkout makes, rather than against when its last
# commit landed.
#
# Weaker than the timestamp in one way and stronger in another: it compares what
# was BUILT rather than when, so it catches a build from a different branch that
# a timestamp cannot — but only if the build number moves between builds. Say
# nothing (exit 2) rather than guess when the project does not carry one.
version)
  exit 2
  ;;

# --- residue -----------------------------------------------------------------
# One glob per line. A TRACKED path matching one of these is build residue:
# regenerated by any build, committed in most projects, and therefore something
# `git checkout <branch>` stops on while looking exactly like work somebody did.
#
# Match on the basename or on a trailing path fragment, e.g.
#   pubspec.lock
#   */Podfile.lock
# The caller prints the discard command and does NOT run it — a lock file change
# can be a genuine dependency update, and only whoever made it knows which.
residue)
  exit 0
  ;;

# --- devsession --------------------------------------------------------------
# Is a hot-reload or dev session live? Print the processes and exit 0. When
# there is none, exit 1 and say on stdout what that costs — driving is normally
# unaffected and only the inside-the-app reads are lost, and a reader who is not
# told that reads an empty traffic list as a broken relay.
devsession)
  exit 2
  ;;

# --- inspect <device> <cache-file> -------------------------------------------
# Find the app's live debug endpoint and print `<base-uri> <session-id>`.
#
# Never hardcode either: both change on every launch, install and hot restart.
# Cache them in <cache-file>, and re-validate the cached pair before handing it
# back — a dead session usually answers something that looks fine, so test that
# the session object is the kind you asked for, not merely that a reply arrived.
#
# Two failures, and they are not the same:
#   an endpoint was found but has no live session — the app restarted since
#   no endpoint at all — the app was not started under a dev session, which is
#   NOT the same as "the app is not a debug build"
inspect)
  exit 2
  ;;

# --- traffic-arm <base> <session> --------------------------------------------
# Turn HTTP capture on. Print TWO words: the state found, then the state after
# arming. Each is `on`, `off` or `unknown`.
#
# Two, not one, because "it was already on" and "it was off and is on now" are
# different facts for the reader: in the second, nothing before this moment was
# recorded, and a list that then comes back short is not a quiet app.
#
# Runs on EITHER side. The base URI decides: the LAN-published relay reached
# through $grpc_proxy from the sandbox, or the Mac's own loopback over SSH. Use
# the proxy only when $grpc_proxy is set, and the same verb serves both.
#
# Capture is normally off by default and bound to the session, so it has to be
# re-armed after anything that replaces the session. An unrecorded profile looks
# exactly like an app that made no calls, which cost one session six minutes and
# another its whole line of evidence.
traffic-arm)
  exit 2
  ;;

# --- traffic-list <base> <session> -------------------------------------------
# One request per line: id, method, status, uri. Either side; see traffic-arm.
traffic-list)
  exit 2
  ;;

# --- traffic-one <base> <session> <id> ---------------------------------------
# One request in full: headers, request body, response body. Either side.
traffic-one)
  exit 2
  ;;

# --- prefs-prefix ------------------------------------------------------------
# The key prefix the framework's own preferences API writes, or nothing when it
# writes the platform's keys unprefixed. Used as the default filter when reading
# the store back, so an app's own keys are not buried in the platform's.
prefs-prefix)
  exit 0
  ;;

*)
  echo "framework runner: unknown verb '${VERB:-(none)}'" >&2
  echo "  claim describe variants variant-for-appid build residue devsession" >&2
  echo "  inspect traffic-arm traffic-list traffic-one prefs-prefix" >&2
  exit 2
  ;;
esac
