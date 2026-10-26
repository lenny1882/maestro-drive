# maestro-drive

A Claude Code skill that drives a running app on an iOS simulator or Android
emulator: tap, type, swipe, read the screen, and run whole UI journeys written
as short scripts.

Commands in this README are written as `bin/…`. In an installed copy that is
`~/.claude/skills/maestro-drive/bin/`, and in a checkout it is `skill/bin/`.

Elements are addressed by their label rather than by screen coordinates. The
device can be on a Mac across the network or on the machine Claude runs on; see
[Where the device runs](#where-the-device-runs).

Several simulators and physical iPhones can be driven at once, each with its
own driver. `bin/drivers.sh rig up` boots a set of simulators as one, and
`bin/device.sh` brings up a phone attached by cable to the machine with the
simulators.

`bin/wall.sh` serves a live view of every booted iOS simulator on one web page
at a fixed URL. Each tile is labelled with what the session is driving on it.
Android emulators and physical phones don't appear on it yet.

```
$ bin/driver.sh tapon "^SCAN$"

$ bin/driver.sh script login.journey
  ok   login.journey:1  launch
  ok   login.journey:2  tapon "^Sign in$"
  ok   login.journey:3  type "^Email$" someone@example.com
  ok   login.journey:4  expect "^Dashboard$"
```

The skill drives an app that is already installed. `bin/build.sh` can build
the project's app and install it on a device, but only when you ask, because a
build replaces the app under test.

## Contents

- [Why not Maestro's own MCP server](#why-not-maestros-own-mcp-server)
- [Where the device runs](#where-the-device-runs)
- [Requirements](#requirements)
- [Install](#install)
  - [Setup steps](#setup-steps)
  - [Project configuration](#project-configuration)
- [Using it](#using-it)
  - [What a project holds](#what-a-project-holds)
  - [Journeys](#journeys)
  - [Maestro flows](#maestro-flows)
  - [Inspecting the app](#inspecting-the-app)
  - [Troubleshooting](#troubleshooting)
- [Update](#update)
- [Uninstall](#uninstall)
- [Local development](#local-development)
  - [Layout](#layout)
  - [Runners](#runners)
  - [Tests](#tests)
  - [Known risks](#known-risks)
  - [Scripts that run on the Mac](#scripts-that-run-on-the-mac)
  - [Working from inside a Claude Code session](#working-from-inside-a-claude-code-session)
  - [Releasing](#releasing)
- [Licence](#licence)

## Why not Maestro's own MCP server

This section is about iOS. On Android, each Maestro run brings up its own
driver and removes it afterwards, so there is no standing driver to call.

Maestro's MCP server has the driver port `22087` compiled in and never drops a
cached session. `inspect_screen` returns the tree of whichever device holds that
port, whatever `device_id` you pass. With two devices booted, it can return one
device's screen for a request naming the other, with nothing in the response to
show it.

Tapping from screenshots fails too. A container's first child can be a marker
node that sets the coordinate space for its siblings, so an element's reported
frame is often not where it is drawn.

Maestro's own viewer can't be watched from another machine either. Its stream
address is `127.0.0.1` on a random port, and it only attaches when exactly one
simulator is booted.

maestro-drive runs its own XCUITest driver per simulator and calls the driver's
HTTP API directly. It resolves elements by label, applying the marker
transform. Reading the hierarchy takes 0.28 s and a tap 0.46 s.

## Where the device runs

`TRANSPORT` in the project's `.maestro-drive.conf` says where the device is.
The commands are the same for all three.

| `TRANSPORT` | device | supports |
| --- | --- | --- |
| `ssh` (default) | a Mac across the network, reached over SSH | iOS simulators and physical iPhones |
| `local` | the machine Claude runs on, with the sandbox off | Android emulators; iOS simulators untested |
| `bridge` | the machine Claude runs on, from inside the sandbox | Android emulators |

`bridge` exists because a sandboxed session cannot start an emulator or see one
started outside it: the sandbox has no `/dev/kvm` and its own process and
network namespaces. The `maestro-bridge` MCP server runs outside the sandbox and
starts a helper, `skill/remote/bridge.sh`, that runs the skill's commands on
this machine. The helper logs every command it runs and stops when the session
ends.

The remote side of `ssh` has to be a Mac. A remote Linux box running an Android
emulator is not supported yet.

## Requirements

On the machine Claude runs on:

- Claude Code
- `jq`, `curl` and python3
- for `ssh`: `socat` and `nc`, and an SSH alias for the Mac in `~/.ssh/config`

On the machine with the device — the Mac for `ssh`, this machine otherwise:

- [Maestro](https://maestro.dev), a JDK and python3
- Xcode with a simulator for iOS, or the Android SDK with an AVD for Android
- for `ssh`: Remote Login turned on, and a firewall exception for the relays if
  the firewall is on

## Install

Run these in your own terminal, not from inside a Claude Code session. The
session's sandbox cannot write to `~/.claude/skills`.

    curl -fsSL https://github.com/lenny1882/maestro-drive/releases/latest/download/maestro-drive.tar.gz | tar -xz
    cd maestro-drive && ./install.sh

| option | effect |
| --- | --- |
| `--dry-run` | print the changes to `settings.json` and `~/.claude.json`, write nothing |
| `--yes` | no prompts |
| `--with-bridge` / `--no-bridge` | register the `maestro-bridge` MCP server, or don't, without asking |
| `--link` | symlink instead of copy (see [Local development](#local-development)) |

The installer puts the skill at `~/.claude/skills/maestro-drive` and registers:

- a `PreToolUse` hook that steers raw coordinate taps towards journeys
- a `SessionEnd` hook that shuts down the simulators the session booted
- the `maestro-mac` MCP server in `~/.claude.json`, which runs `maestro mcp`
  on the machine with the device
- the `maestro-bridge` MCP server, if you ask for it — needed for
  `TRANSPORT=bridge`

Both config files are backed up before they are changed. New sessions pick the
skill up; one already running does not.

### Setup steps

For `local` and `bridge` there is no network setup; skip to
[Project configuration](#project-configuration).

For `ssh`, the installer offers to run the setup wizard,
`skill/setup/wizard.sh`. It runs in three phases.

1. **Once per machine.** Asks for the Mac's login user, picks or creates an SSH
   key, copies it onto the Mac and checks that SSH works.
2. **Once per network the Mac joins.** Adds a `Host` block to `~/.ssh/config`
   that tunnels through the sandbox proxy. Adds the Mac's address to
   `sandbox.network.allowedDomains` in `~/.claude/settings.json`. Last, it
   writes the Mac's `.local` name into `/etc/hosts`. A network missing from any
   of the three fails as something unrelated, which is why one step writes all
   three.
3. **Optional, on the Mac.** Installs a launchd job that gives the Mac a fixed
   address on each known Wi-Fi network, so the addresses above stay correct.

Re-run the wizard when the Mac joins a new network. `wizard.sh --status` shows
what is in place without changing anything, and `--remove <alias>` takes one
network back out.

`skill/reference/setup.md` covers each step in full, including how to do it by
hand.

### Project configuration

Each project you drive needs a `.maestro-drive.conf` at its root, giving the
app's bundle ID and where the device is. `bin/init.sh` writes it from what it
finds:

    ~/.claude/skills/maestro-drive/bin/init.sh --detect           # ssh
    ~/.claude/skills/maestro-drive/bin/init.sh --local --detect   # local or bridge

`init.sh` writes `local`. For `bridge`, set `TRANSPORT=bridge` and `BRIDGE_DIR`
(the directory the helper serves) in the conf yourself.

Keep `.maestro-drive.conf` out of version control. It is where credentials go.

## Using it

Open a Claude Code session in the project and ask Claude to drive the app,
test a screen or reproduce a bug. The skill loads from that request. At the
start of a session it:

1. starts the wall and posts its URL
2. checks that the project has a `.maestro-drive.conf`
3. reads the project's app notes, if there are any
4. boots the simulators and starts a driver for each
5. asks before building the app or starting a dev session — it never does
   either unprompted

`skill/SKILL.md` is what Claude follows, and the rest of the reference hangs
off it.

### What a project holds

| path | contents | commit it? |
| --- | --- | --- |
| `.maestro-drive.conf` | where the device is, the app's bundle ID, credentials | no |
| `maestro/journeys/` | the project's journeys | yes |
| `maestro/app-notes.md` | what has been learnt about driving this app; read at the start of every session | yes |

`bin/init.sh --write` creates the notes file from a template, and
`bin/notes.sh init` creates it later. A journey or a Maestro flow can refer to
`${APP_PIN}`, or any other `APP_*` value in the conf, rather than holding the
value itself. `bin/secrets.sh check` looks for a conf value that has ended up
in a file that would be committed.

### Journeys

A journey is a text file of steps, one per line, run in a single call:

```
# login.journey
launch
tapon "^Sign in$"
type "^Email$" ${EMAIL}
type "^PIN$" ${APP_PIN}
include dismiss-banner.journey
expect "^Dashboard$" 15
```

    bin/driver.sh script login.journey
    EMAIL=someone@example.com bin/driver.sh script login.journey

- `tapon`, `type`, `scrollto` and `expect` take a regular expression matched
  against element labels. A pattern matching two elements is refused, and so is
  an element off screen or under the keyboard.
- Every action waits for the screen to stop moving before the next line runs.
- `include` runs another journey, and `include-if` runs one only when a pattern
  is on screen.
- `${VAR}` is taken from the environment.
- The first failing line stops the run and prints the whole screen. A journey
  that ends early fails rather than passes.

A bare name passed to `script` is looked up in `maestro/journeys/`, or in
`JOURNEY_DIR` if set. No journeys ship with the skill. Claude writes them as it
gets each screen working, and a later run replays the steps without Claude
deciding each one. `skill/reference/journeys.md` lists every command.

### Maestro flows

`bin/flow.sh` runs a Maestro YAML flow on a chosen device and prints the
resulting screen in the same call:

    bin/flow.sh -f signin.yaml -e PIN=1234
    bin/flow.sh <<'YAML'
    - tapOn: "Search"
    - inputText: "5012345678900"
    YAML

Each run pays Maestro's start-up time of 15–30 seconds, and Maestro stops that
device's driver when the flow ends. Use journeys for driving, and flows for
tests that also have to run under Maestro elsewhere.

### Inspecting the app

These read state the screen doesn't show. Which of them work depends on the
runner: a native app has no Dart VM Service, so `net.sh` has nothing to read.

| command | reads |
| --- | --- |
| `bin/net.sh` | the app's HTTP requests and responses, from the Dart VM Service of a debug build |
| `bin/prefs.sh` | the app's persisted preferences, off the device |
| `bin/driver.sh watch` | a list on screen, sampled until it changes with nobody touching the device |
| `bin/driver.sh shot` | a screenshot from the device's own driver |

### Troubleshooting

The table "What breaks, and what it actually means" in
[`skill/reference/setup.md`](skill/reference/setup.md#what-breaks-and-what-it-actually-means)
maps each error to its cause: SSH failures, a URL that hangs, MCP tools that
fail to connect, reads that land on the wrong simulator, and build-tool errors.

## Update

    ./update.sh            check, ask, upgrade, reinstall
    ./update.sh --check    report the newest release and stop

This downloads the newest GitHub Release over the current directory and re-runs
the installer. It works from a tarball or a clone. Other options are passed to
`install.sh`.

## Uninstall

    ./uninstall.sh                  ask before editing either config file
    ./uninstall.sh --yes            no prompts
    ./uninstall.sh --keep-settings  leave settings.json and ~/.claude.json alone

This removes the skill directory, both hooks, both MCP server entries,
`~/.local/share/maestro-drive/` and `~/.local/state/maestro-drive/` (or the
same directory under `$XDG_STATE_HOME`).

## Local development

    git clone https://github.com/lenny1882/maestro-drive && cd maestro-drive
    ./install.sh --link

`--link` makes `~/.claude/skills/maestro-drive` a symlink to `skill/`, so edits
in the checkout are live. Without it, the installed copy is separate and edits
made there are lost on the next install.

### Layout

| path | contents |
| --- | --- |
| `skill/` | everything that gets installed; `skill/SKILL.md` is the entry point |
| `skill/bin/` | the commands Claude runs, on the machine Claude runs on |
| `skill/remote/` | scripts copied to and run on the Mac |
| `skill/runners/` | per-framework and per-platform modules |
| `skill/reference/` | reference pages the skill reads; `driver-api.md` records the driver's HTTP API |
| `skill/docs/pages/` | an offline copy of the Maestro documentation |
| `install.sh`, `manifest.sh` | the installer; `manifest.sh` says what is installed and registered |
| `lib/update-check.sh` | the release check, installed to `~/.local/share/maestro-drive/` |
| `test/` | the packaging test suite |
| `BACKLOG.md`, `BACKLOG-DONE.md` | open work items, and finished ones |

### Runners

Two settings in `.maestro-drive.conf` choose the modules: `RUNNER` is the
framework (how the app is built and inspected) and `PLATFORM` is how it is
installed and driven. They default to `flutter` and `ios`.

| module | state |
| --- | --- |
| `flutter` | complete |
| `ios` | complete |
| `ios-device` | complete, for physical iPhones |
| `android` | complete for emulators except `container`, `orientations` and `driver-up`, which refuse |
| `react-native` | stub; nothing in it has been run |

`skill/runners/README.md` is the contract every module follows, and
`skill/runners/TEMPLATE/` is the module to copy. A module exits 2 for a verb it
does not support. `skill/bin/runner.sh which` shows the modules in use.

### Tests

    ./test/run-tests.sh          everything: parse checks, install round trip, skill cases
    skill/test/run-tests.sh      the skill's behaviour cases only — the quicker loop

Neither needs a Mac, a device or a network. The full suite redirects `HOME`
into a temporary directory, so your real config is not touched. The release
workflow runs it and will not publish past a failure.

`driver.sh` is tested against a stub `curl` that serves hierarchies captured
from real devices in `skill/test/fixtures/`. Add new `driver.sh` tests to that
harness.

### Known risks

The toolkit depends on two undocumented behaviours, and either could change in
a Maestro release.

- **The XCUITest driver's HTTP API.** `bin/driver.sh` calls it directly.
  `skill/reference/driver-api.md` records what it accepts and returns. If it
  changes, `driver.sh` gets HTTP 404 or 400 while the `maestro-mac` MCP server
  still works.
- **The marker transform.** A marker node's frame is the screen divided by some
  factor, and it sets the coordinate space for the container's other children,
  not for its own descendants. `bin/resolve.py` documents the rule and the trees
  it came from. If the rule stops holding, elements still resolve but taps land
  in the wrong place.

The driver only runs while something holds a Maestro session open. In practice
that is the `maestro-mac` MCP server, which is why the installer registers it
even though `driver.sh` doesn't go through it.

### Scripts that run on the Mac

Anything under `skill/remote/`, or sent over SSH, runs under the Mac's zsh and
BSD tools. All Linux tests can pass while it is broken there.

- Never name a variable `path`. In zsh it is tied to `PATH`.
- zsh does not word-split an unquoted `$LIST`, and matches a `case` pattern held
  in a variable literally. Run remote scripts as `sh <file> --run …`, as
  `remote/gitstate.sh` does, rather than sourcing them.
- `stat -f` means different things on GNU and BSD. Try `stat -c %Y`, check the
  result is numeric, then fall back to `stat -f %m`.

### Working from inside a Claude Code session

The sandbox allows writes only to the working directory and `$TMPDIR`. A write
elsewhere fails with `EROFS` ("Read-only file system"); run it from your own
terminal instead.

Run commands from the repo root. A command run inside `skill/` leaves a
`skill/.claude/` directory, which a copying install would ship. Delete it if it
appears.

### Releasing

Run `/release` in a Claude session in this repo. It bumps `VERSION` on `main`,
merges into `release/vX.x` and tags there; the tag triggers
`.github/workflows/release.yml`, which builds and publishes the tarball.

## Licence

MIT with the Commons Clause; see [`LICENSE`](LICENSE). You may use, copy,
change and share the code, but not sell it or sell a service whose value comes
mainly from it. Every copy, and every substantial part of one, must keep the
copyright notice crediting <https://github.com/lenny1882/maestro-drive>.
