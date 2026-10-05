# maestro-drive

A Claude Code skill for driving a simulator or emulator — tapping, typing,
swiping, reading the screen and running whole UI journeys — wherever the device
is. `TRANSPORT` in the project's conf says which: `ssh` for a Mac across the
network, which is what this was built for and what most of this page describes,
or `local` for a device on the machine running the skill, where nothing goes
over ssh and every URL is `127.0.0.1`. The local path has driven a real device
— an Android emulator on the machine running the skill; no local iOS simulator
yet.

The problem it solves is that the obvious route does not work. Maestro's own MCP
server compiles the driver port in as a literal `22087` with no override, and
its session map has no invalidation path, so `inspect_screen` returns whatever
device is on that port **regardless of the `device_id` you pass** — with a
response that looks entirely correct. Measured: asked for the iPhone, it
returned the iPad's tree. Screenshot-driven tapping is no better:
a container's first child can be a marker that redefines the coordinate space
for its siblings, so an element's reported frame is often not where the element
is, and a tap computed off the picture lands somewhere else.

This toolkit runs its own XCUITest driver per simulator and talks straight to
the driver's HTTP API, relayed onto the LAN. It reads the hierarchy in 0.28 s,
taps in 0.46 s, resolves elements by label itself — applying the marker
transform rather than guessing — and drives several devices at once.

**Driving is the same whatever built the app; building it is not.** A tap is a
tap, so everything above generalises. Working out how the project builds,
installing the result and reading inside the running app do not — those are
Flutter's answers, or React Native's, or a plain Xcode project's, and they come
from two plug-in modules rather than from the scripts. See **Runners** below.

## What you actually see

A Claude session on Linux that can be told "drive the app" and does, on a
simulator across the room:

```
$ bin/driver.sh point "^SCAN$"
201 262.6

$ bin/driver.sh tapon "^SCAN$"

$ bin/driver.sh script login.journey
  ok   login.journey:1  launch
  ok   login.journey:2  tapon "^Sign in$"
  ok   login.journey:3  type "^Email$" someone@example.com
  ok   login.journey:4  expect "^Dashboard$"
```

A verb that worked says nothing; a verb that failed prints the line it died on
and then the whole screen, so the next question is answerable without another
round trip. A journey that stops short of its last line fails rather than
passes — that one was a real bug, and files were passing while doing half the
work.

- **Elements are addressed by label, never by coordinate.** The resolver refuses
  rather than guesses: a pattern matching two things is an error, an element
  below the fold or under the keyboard is refused rather than tapped, because
  both of those fail silently or, worse, land on the typing-prediction bar.
- **Several simulators at once.** `bin/drivers.sh rig up` brings a set of them
  up as one, with boots serialised — seven idle simulators sit at load 6, while
  booting one more in parallel takes the Mac to load 122 in 36 seconds.
- **A 154-page mirror of the Maestro documentation** under `skill/docs/pages/`,
  because there is no route to the internet from inside the sandbox.

`skill/SKILL.md` is the entry point and the rest of the reference hangs off it.
`skill/reference/setup.md` is what a new machine needs: the SSH config with its
proxy tunnel, `/etc/hosts`, the sandbox's allowed domains, and the MCP
registration.

## Install

Needs `jq`. Install it on the machine you drive *from* — across a network that
is the Linux box and not the Mac, where nothing is installed beyond Maestro
itself; locally it is the one machine there is.

    curl -fsSL https://github.com/lenny1882/maestro-drive/releases/latest/download/maestro-drive.tar.gz | tar -xz
    cd maestro-drive && ./install.sh

Or from a clone, if you intend to work on the toolkit:

    git clone https://github.com/lenny1882/maestro-drive && cd maestro-drive
    ./install.sh --link       # symlink, so edits in the checkout are live
    ./install.sh --dry-run    # show what would change, write nothing
    ./install.sh --yes        # no prompts

**Prefer `--link` if you will ever edit the skill.** It puts a symlink at
`~/.claude/skills/maestro-drive` pointing at this repo's `skill/`, which
means the live path and the source are the same directory. Without it they are
not, and the failure that follows is a quiet one: a finding written into the
published copy in the belief that it is the source is destroyed by the next
publish, and nothing reports it.

Re-running the installer is safe and is how you upgrade. It rewrites its own
entries in `~/.claude/settings.json` and `~/.claude.json` each time rather than
adding a second copy, so an upgrade leaves no drift; both files are backed up
beside themselves first, and `--dry-run` shows the exact diff without writing.

`~/.claude/skills` is not writable from inside a Claude Code session when the
sandbox is on, so run the installer in your own terminal. New sessions pick the
skill up; the one you are in does not.

### What the installer registers

Three things, so that installing is one step. `./install.sh --dry-run` prints
the diff for both files before you commit to it, and `./uninstall.sh` takes all
three back out.

`hooks/gate-journey-first.sh` — `PreToolUse`, matcher `Bash`. Blocks a raw
`driver.sh tap` or `swipe` on literal coordinates once per session and names the
journeys to run instead. It is a nudge, not a ban: re-run the same command and
it passes.

`hooks/rig-down-on-end.sh` — `SessionEnd`, no matcher. Takes down the simulators
*this* session booted, and nothing else. Without it an untidy ending leaves a
simulator booted, its driver running and its name on the wall, and the next
session inherits that name as though a person had set it.

`bin/mcp.sh` — the `maestro-mac` MCP server, in `~/.claude.json`. It opens
`maestro mcp` over SSH to the Mac, picking the SSH alias out of
`.maestro-drive.conf` so the server follows the Mac between networks.

Three details, if you are reading the entries it writes:

- The `PreToolUse` entry goes on as its own matcher `Bash` entry rather than
  joining one already there. Two entries both fire and neither depends on the
  other; merging them into one makes them ordered.
- Both hooks are `bash <path>`, not the path alone, because the sandbox refuses
  `chmod +x` under `~/.claude` and a script there cannot be relied on to carry
  its exec bit.
- Every path is absolute and resolved at install time. Claude Code does not
  expand a leading `~` in an `mcpServers` command or argument — it reaches
  `exec` unexpanded and fails at every session start.

`~/.claude.json` also holds your project records and login state. The installer
never rewrites it in place: it writes a temp file beside it and renames, and
keeps `~/.claude.json.bak-maestro-drive`. Claude Code writes that file
itself while running, and concurrent writes to it are a known way to corrupt it,
so install from a terminal with no session running if you can.

`reference/setup.md § 5` and `§ 7` have the longer version, including what to
paste if you would rather do it by hand.

## Update

    ./update.sh            check, ask, upgrade, reinstall
    ./update.sh --check    report what is available and stop

Reads the newest GitHub Release, so drafts and pre-releases are skipped. Works
from a downloaded tarball as well as a clone — no git needed.

## Uninstall

    ./uninstall.sh                 ask before editing settings.json
    ./uninstall.sh --keep-settings leave settings.json alone

Removes `~/.claude/skills/maestro-drive`. If you added either hook to
`settings.json` by hand, remove those entries yourself — the installer never put
them there, so the uninstaller will not take them out.

## Runners

Two questions are being answered and they are independent, so there are two
modules rather than one setting:

```
: "${RUNNER:=flutter}"     # framework: how it is built, how you see inside it
: "${PLATFORM:=ios}"       # platform:  how it is installed and driven
```

They cross — Flutter-on-Android is a real combination — which is why `flutter`
and `android` cannot be alternatives to each other. Both default to what the
package has always done, so a conf that does not mention them is unchanged.

```sh
skill/bin/runner.sh which     # the two in use, and what else exists
skill/bin/runner.sh detect    # ask each framework to claim the checkout
```

`skill/runners/README.md` is the contract: the verbs each module answers, which
side of the SSH boundary each runs on, and the rules a new one has to keep.
`runners/TEMPLATE/` is the module to copy.

| module | state |
| --- | --- |
| `runners/flutter` | complete — every verb verified against a live app |
| `runners/ios` | complete — every verb verified against a booted simulator |
| `runners/ios-device` | complete — every answerable verb verified against a physical iPhone |
| `runners/react-native` | stub; nothing in it has been run |
| `runners/android` | stub; nothing in it has been run |

Both stubs say so at the top and mark each verb as documented-not-measured or
unanswered. Six are unanswered on purpose, because each is a question the
contract does not yet settle — an AVD name and an emulator serial are not the
same identifier, Maestro's Android driver is an instrumented APK rather than an
`xcodebuild` run, and so on. `runners/README.md` lists them.

**A module that lacks a verb says so rather than failing.** Exit 2 means "this
framework does not have that", so `bin/net.sh` under a framework with no traffic
endpoint prints why and exits 2 — which is not a broken relay, and the
distinction is the point.

## How it works

`skill/` is the whole of what gets installed; everything else in this repo is
packaging. Inside it, `bin/` runs on the Linux box, `runners/` holds the plug-in
modules, and `remote/` is what is copied to the Mac and run there regardless of
which modules are in use — a Maestro hierarchy reader and a port forwarder.

Two undocumented behaviours the toolkit depends on, both of which could be
withdrawn without notice:

- **The XCUITest driver's HTTP API.** `bin/driver.sh` talks to it directly
  rather than going through Maestro. `skill/reference/driver-api.md` is the
  record of what it accepts and returns, established by measurement. If Maestro
  changes it, the symptom is HTTP 404 or 400 from `driver.sh` while the MCP
  server carries on working.
- **The marker transform.** A container's first child may be a node whose frame
  is the screen divided by some factor, and it defines the coordinate space for
  that container's *siblings* — not its descendants. `bin/resolve.py` documents
  the rule and the live trees it was derived from. If it stops holding, taps
  land in the wrong place while every element still resolves, which is the worst
  shape of failure this has.

The skill also needs a running XCUITest driver to exist at all, and one only
exists while something holds a Maestro session open — in practice the
`maestro-mac` MCP server. That is why `reference/setup.md` registers it even
though `bin/driver.sh` is the fast path.

## Tests

    ./test/run-tests.sh

Redirects `HOME` and `CLAUDE_DIR` into a temp directory, so your real config is
never touched. Nothing in the suite needs a Mac, a device or a network.

It runs three things. First the gates that must hold before anything is
published: every shell and Python file parses, every shell script carries its
exec bit, and no `ssh` call sits inside a loop reading from stdin — that last
one silently runs the loop once and drops the rest of the list with a zero exit,
and it is easy to write without noticing. Then the packaging: install,
re-install without drift, uninstall, and an install from the release tarball
rather than from the checkout. Then the skill itself — the 360 behaviour cases
in `skill/test/run-tests.sh`, run out of the *installed* copy, against
hierarchies captured off real devices.

The installer ends with the same idea in miniature: it resolves a known element
out of a captured hierarchy and compares the point, so an install that landed
but cannot run says so instead of reporting success. It also compares the
installed tree against what belongs in it, file for file, ignoring the two
things that appear only after use — `__pycache__`, and `reference/staging/`
where `bin/notes.sh promote` parks findings.

`skill/test/run-tests.sh` can be run on its own, from the checkout or from an
installed copy. It runs only the skill's behaviour cases and skips the parse
gates and the packaging round trip, so it is the quicker loop while editing a
script under `skill/`. Run `./test/run-tests.sh` before committing; the release
workflow runs that one and will not build a tarball past a failure.

`bin/driver.sh` binds to a driver on the Mac as it loads, so the suite tests it
against a fake device instead: a stub `curl` on `PATH` that always answers,
always reports the screen as still and serves a captured hierarchy from
`test/fixtures/`, plus a stub `lib.sh` in place of the real one. Flag parsing,
the settle rule and the keyboard checks are all tested this way, offline. Reuse
that harness for any new `driver.sh` behaviour rather than building another.

## Code that runs on the Mac

Anything under `skill/remote/`, or sent to the Mac as part of an SSH command,
runs under macOS tools and, unless told otherwise, under the Mac's login shell,
which is zsh. Three zsh differences have each broken a script here while every
Linux test passed:

- `path` is tied to `PATH` in zsh. A loop such as `while read -r st path`
  empties `PATH` for the rest of the command, and the next lines fail with
  `command not found`. Never use `path` as a variable name; `remote/gitstate.sh`
  uses `_p`, and a test fails if `path` comes back.
- An unquoted expansion is not word-split: `for g in $LIST` sees one word.
- A variable used as a `case` pattern is matched literally, not as a glob.

Because of the last two, `remote/gitstate.sh` and `remote/appcheck.sh` are run
with `sh <file> --run …` rather than sourced into the shell SSH hands over. Give
any new remote script the same entry point.

Scripts that run on both machines must also allow for GNU and BSD tools
differing. `stat -f` exists on GNU as well as BSD and means *file system
status* there: it succeeds and prints something that is not a timestamp. Try
`stat -c %Y` first and check the answer is numeric before falling back to
`stat -f %m`, as `remote/appcheck.sh` does.

## Working on the repo from inside a Claude Code session

The sandbox allows writes only to the working directory and `$TMPDIR`. A write
anywhere else is refused, and the refusal surfaces as `EROFS`, "Read-only file
system", although the filesystem is writable. Do not try to remount anything;
run the write from your own terminal.

The sandbox writes a `.claude/.cc-writes` directory into whatever directory a
command runs in, `skill/` included. This repo's `.gitignore` covers only
`.claude/` at the root, so a copy under `skill/` shows as untracked, and an
install from the checkout without `--link` copies it into
`~/.claude/skills/maestro-drive` with the rest of `skill/`. Run commands from
the repo root, and delete `skill/.claude/` if it appears.

## Releasing

`/release` in this repo — bump `VERSION` on `main`, merge into `release/vX.x`,
tag there. The tag is what publishes it. See
`.claude/skills/release/SKILL.md`.
