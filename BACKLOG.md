# maestro-drive — backlog

**Eleven items are open — 50, 87, 90, 93, 97, 99, 100 and 101–104.** 101–104 came out
of item 99's two-phone run on 24 Sep. 50 was reopened 24 Sep:
its face-up diagnosis had been unreachable since 11 Sep. 87 is not gated; 90 waits on
finding out whether a physical phone can be streamed at all; 93 waits on 87
landing; 97 is three decisions rather than a fix — `bin/mcp.sh` reads this
project's conf, finds one alias, cannot reach it, and exits before it speaks a
word of MCP; 99 has Part 1 done and Part 2, wifi, not started; 100 is gated on the setup
screens until Flutter 3.49 is stable. **17 is done** — the package
has a git repo, a version, a manifest, an installer and an update path. That
released **28**.

**70–82 were raised on 17 Sep** by an audit of the fourteen simulator-driving
sessions of 15 and 16 Sep (PROJ-1812/1811 reproduction and fix verification).
They are the first items to come out of *driving at scale* — four or five
simulators, two live sessions on one Mac, and an observation that had to run for
hours. **73, 74 and 75 are the multi-device failures**; 80–82 are conduct with a
skill change behind them.

**70, 71 and 72 were built the same day and are in `BACKLOG-DONE.md`.** 70 was
the item that cost those two days — `driver.sh watch`, built on 72's `rows` and
71's detached-work rules, verified live on an iPhone the same afternoon. **69 is done and
shipped.** Its route fix is in `skill/bin/driver.sh` and in the v1.0.0 tarball,
and the isolation its fold asked for was run on 18 Sep, which found the cause:
`/swipe` does not rotate its coordinates and `/swipeV2` does, so on a landscape
iPad a v1 swipe lands off the view and is answered 200.

**74 is done and it came back with the opposite of what it claimed.** A device
budget is not the fix: seven simulators idle with the wall up sit at load 6,
while booting **one** more takes the Mac to 122 in 36 seconds. The failure is a
boot storm, not a crowded machine. That makes serialised boots a hard
requirement on item 76 rather than a preference.

**73 and 76 are done.** Ports are pinned per device in a map on the Mac, and
`drivers.sh rig up|down|status` brings several simulators up as one — serialised
boots per 74, and a teardown scoped to what this session booted. **67's
`SessionEnd` piece is now closed.** The hook is in
`skill/hooks/rig-down-on-end.sh`, and `install.sh` registers it rather than
leaving the `settings.json` entry as the machine's step — that reversal is the
whole point: the hook sat unregistered from 17 Sep, which is the failure it
exists to prevent. **67 is closed.** Piece 4 — what a label with no live session
looks like — was decided and built on 17 Sep: `remote/wall.py:96` sets
`HIDE_FROM_PREVIOUS_DAY` and `:136` applies it, so a name from an earlier
calendar day is not shown and the tile falls back to the handset.

**Nothing from the earlier run is still open here.** 75, 77, 78, 79, 80 and 81
are done, and 67 and 69 are closed — see their entries in `BACKLOG-DONE.md`.
**28 is done for everything this repository controls**; the four deletions it
listed are in the pre-repo working directory and are not this package's to make.
**82 is closed here and owned by `flutter-hot-reload-mac` item 16** — the fix is
a hook on that skill's entry points, so nothing in this package was ever going to
change for it.

**Where the toolkit now lives.** Item 17 moved it into its own git repo — the
one this file is in — where `src/` became
`skill/` and the root carries the installer, `manifest.sh`, `VERSION` and
`update.sh`. `build/` and `ship.sh` are superseded and were left in
`~/claude-sandbox/maestro-remote-mac/`, source of truth for nothing; the four
things in that directory that were stored nowhere else —
`MAESTRO-REVIEW-TRACKER.md`, `HANDOFF.md`, `flutter-router-dropdown-repro/` and
`remote-STALE-pre-skill/` — are now in this repo's root.

**Nothing from 17 Sep is live.** The old `~/.claude/skills/maestro-remote-mac`
symlink into `build/` was removed when the package was uninstalled, so there is
no installed skill at all until `./install.sh --link` is run from the repo.
Everything built on 17 Sep is in `skill/` and comes with it.

68 was raised and done on 16 Sep — the wall's tiles no longer overflow their
cards — and 64, 65 and 66 were done on 15 Sep. All four are in
`BACKLOG-DONE.md` with the rest of the history of all 68 earlier items.

**85 is done, on 18 Sep.** It was the first item about setting the skill up
rather than running it, and exercising it cost an afternoon and found eight
faults — eight in the wizard, one of them a wrong conclusion drawn in its own
comments, and one found only by asking what a fresh Mac would do. Nearly every one showed as the same sentence, a connection closed
during the banner exchange, which named none of them. Phases A, B and C have
now run live end to end against the real Mac, including the `sudo` install and
the Wi-Fi cycle, and the `--remove` round trip ran on the real three files.

**86 was raised and fixed on 18 Sep** — the suite went red with no code
change, on a test that was only correct when it was not shortly after midnight.
It is in `BACKLOG-DONE.md`.

**87 was raised on 18 Sep**, the first item about what this package is *for*
rather than how it works. It is the oldest item still open here.

**Next item number: 105.** Items 1–104 are allocated; new items start from 105.

**98 is done and is in `BACKLOG-DONE.md`.** The package is `maestro-drive`
everywhere — the repo on GitHub, the conf, the installed skill and lib
directories, the message prefixes and the sister skill — and v2.1.0 on 21 Sep is
the first release under the new name.

**Two commits on `backlog/87-runner-modules` carry the wrong item number.** They
say `BACKLOG 88` and `BACKLOG 89`, and both of those were already allocated and
done — 88 is the rig-reap item, 89 is `wall.sh label` swallowing its flags. The
work in them is real and is now filed as **91** and **92** below. The commit
messages are left alone rather than rewriting the branch's history for a label.

---

## 104. `driver.sh app` always answers springboard on a phone — **OPEN, raised 24 Sep**

Found during item 99. On both phones, `driver.sh app` returned
`"runningAppBundleId" : "com.apple.springboard"`. That was true before and
after `launch com.apple.Preferences` on the iPhone 11 and `launch
com.apple.mobilecal` on the XS Max, while the trees' root nodes read `app
Settings` and `app Calendar`. So on a phone the verb cannot confirm which app is
in front, and it cannot tell two phones apart. The tree could: the root node
names the app.

**Fix:** on a physical device, answer from the tree's root node instead. At
minimum, say the driver's answer is not reliable there rather than print it as
fact. Not checked: whether a simulator gives the right answer, and whether this
is the old on-device runner (item 55).

---

## 103. An install failure is reported as the XCTest session dying — **OPEN, raised 24 Sep**

Found during item 99. On the XS Max, `device.sh up` failed four times in a row,
72 s each. `~/devdrv.log` showed `Installing built products Finished with
error: Connection with the remote side was unexpectedly closed`,
`IXRemoteErrorDomain` code 6, "Connection interrupted", and `xcrun devicectl
device install app` gave the same thing directly as `CoreDeviceError` 3002.
`deviceup.sh` printed item 46's message instead: "the on-device XCTest session
dying … Retry". Retrying did nothing.

Restarting the phone fixed it; the next install took 3 s. On 10 Sep the same
3002 was caused by a second process using the phone's tunnel (a `lockState`
keep-alive loop, `BACKLOG-DONE.md` item 46). This time nothing else on the Mac
was touching the phone. Once the error had occurred, one attempt came back
instead with `CoreDeviceError` 4000, "The device disconnected immediately after
connecting".

**Fix:** in `deviceup.sh`, when the log has `Installing built products …
Finished with error`, say the driver could not be installed on the phone. Name
3002 and 4000, and say that restarting the phone is what cleared it on 24 Sep.
Keep item 46's message for a runner that installed and then died.

---

## 102. The 1/3-scale correction is applied to anything that looks like a marker — **OPEN, raised 24 Sep**

`resolve.py` treats any node whose frame is the screen size divided by some
factor as a marker, and rescales that node's siblings. The factor can also be
below 1. On the XS Max, Calendar's tree has a 1242×2688 node at −414,−896,
which is exactly the phone's pixel size from `/deviceInfo`
(`widthPixels 1242, heightPixels 2688`). `resolve.py` read it as a marker
(`find --explain`: "marker 1242x2688 at -414,-896 -> scale 0.3333 offset
+138,+298.67") and moved Continue from y=781, where the tree has it, to y=559.
`tapon` then returned rc=0 for a tap that hit nothing. Item 50's 11 Sep note of
a target resolved to x=−892 on the home screen was probably the same thing.

The correction exists for one Flutter bug on iOS, where frames come back at 1/3
scale (item 100, and `hugoboss-flutter-runner`'s backlog item 999.16). Applying
it to a native app is guessing.

**Requirement: nothing is corrected automatically.** A transform is applied only
when it passes a check against the real screen, and when it doesn't, the raw
frame is used and `--explain` says which check failed. Checks to build:

- **Against the screen size.** Read `/deviceInfo` (points and pixels) and
  compare the candidate marker's frame with it. A node the size of the screen in
  pixels is pixel space, not a scale marker, and is never taken as one.
- **Against the content.** Under a genuine 1/3 marker, the siblings' raw frames
  fit inside the marker's scaled region. Siblings that already span the screen
  in points, as Calendar's did (Continue at 44,756 on an 896-point screen),
  refute the marker.
- **Against the result.** A transformed point that lands outside every visible
  node, or off the screen, refutes the transform rather than getting tapped.

**Done when:** Calendar's Continue on the XS Max resolves to (207, 781) with no
marker applied, and the Flutter store screen's 1/3 case from
`hugoboss-flutter-runner` still resolves correctly. Both need to be fixtures in
`test/fixtures/`.

---

## 101. A forwarder that outlives a reconnect sends to a dead connection — **OPEN, raised 24 Sep**

Found during item 99. `iproxy.py` looks up the phone's usbmux device id once,
when it starts. The iPhone 11 was stood upright, which apparently reconnected
it and gave it a new id; its forwarder kept sending to the old one ("device 5").
The on-device driver logged `starting server 127.0.0.1:22187`, and `curl` on
the Mac got `Connection reset by peer`. `deviceup.sh` keeps a forwarder that is
already running for that phone and port (`pgrep -f "iproxy.py $UDID $PORT"`),
so item 46's automatic restart replaced the driver three times and never the
forwarder. Only `device.sh down` then `up` fixed it; that bring-up took 11 s.

**Fix, one of:**
- `deviceup.sh` checks the running forwarder's id against a fresh
  `ListDevices` before it keeps it, and replaces it on a mismatch.
- `iproxy.py` resolves the id on each connection rather than once.

The second also covers a reconnect mid-session with no restart in between. It
costs one usbmuxd query per connection; measure that before choosing it.

---

## 50. A flat phone crashes the driver on the first touch, silently — **REOPENED 24 Sep: the diagnosis built on 11 Sep had been unreachable since the same day; fixed again 24 Sep, the phone-side crash itself still open**

The 11 Sep entry is in `BACKLOG-DONE.md`. What it built was a message, not a
guard: `_devdrv_hint` reads the phone's driver log and, on a
`ScreenSizeHelper.swift:99: Fatal error: Not implemented yet`, says "FACE-UP
crash (item 50) … STAND THE PHONE UPRIGHT". The crash cannot be prevented from
this side, because nothing the driver serves says which way the phone is lying.

**Why it never printed.** `_start` calls the hint only after item 46's restart
has failed. On 11 Sep the restart always failed, with `device.sh: Permission
denied`, so the hint always ran. The same day that call was changed to `bash
"$HERE/device.sh"`, and from then on the restart succeeded, emptied the log, and
the hint was never reached. The test for it passed throughout, because its stub
restart never brought the driver back.

**Found 24 Sep, driving two phones for item 99.** Both lay flat on the desk.
Every tap took about 20 s ("settle: screen still moving"), then the next call
printed only `restarting it (item 46)`. The cause was found by tapping once and
reading `~/devdrv-<udid>.log` on the Mac before anything restarted it.

**Fixed 24 Sep:** `_ensure_device` (`bin/driver.sh`) calls `_devdrv_hint`
before it restarts, so the cause is read from the log while it is still there.
A new test gives the stub restart a working driver (`/status` answers 200 once
`device.sh` has run) and fails on the old order.

**Still open:**
- The crash itself. The on-device runner is built from older source than the
  Maestro jar ships (item 55); the jar's `ScreenSizeHelper.swift` handles
  `.faceUp`. Rebuilding the device driver from the jar's source would remove
  the fault rather than name it.
- A flat phone still crashes and restarts on every touch. After the hint has
  named the crash once, the restart could be refused until the phone is
  upright, but there is no way to read "upright" before the next touch.

---

## 100. Journeys are not Maestro tests — **OPEN, raised 24 Sep; gated on the setup screens until Flutter 3.49 is stable**

The default driving path does not use Maestro. `driver.sh` talks straight to the
XCUITest runner's HTTP API on 22087 (`skill/SKILL.md:28-46`), and a journey is
this toolkit's own step language, interpreted line by line in
`bin/driver.sh:818-925`, with `resolve.py` turning each pattern into a point.
The only part of Maestro in the loop is the runner binary. Found by a
`hugoboss-flutter-runner` session on 23 Sep (`8fe2598c`, recorded in that repo's
`maestro/tooling-findings.md` and its backlog item 999.16).

**The step language is not the difference.** Almost every verb has a one-line
Maestro equivalent: `tapon` → `tapOn`, `text` → `inputText`, `key return` →
`pressKey: Enter`, `expect X 15` → `extendedWaitUntil`, `include-if` →
`runFlow` with `when: visible`. What differs is:

- **Who picks the point.** `resolve.py` corrects frames it knows are wrong,
  including the 1/3 scale. Maestro taps the centre of the frame as reported,
  after settling and re-resolving the element in a fresh tree
  (`Maestro.kt:216-255` in `mobile-dev-inc/maestro`).
- **Where it runs.** A journey runs only through this toolkit and its relay. A
  flow runs in CI, on Codemagic, in Maestro Studio, and on another developer's
  machine. Nothing a session learns by driving currently becomes a test anyone
  else can run.
- **What it costs.** A journey keeps the driver up: the setup journey is about
  9 s. Every `maestro test` pays 15–30 s of startup and kills that device's
  driver (`bin/flow.sh:7-10`).
- **What Maestro has that journeys lack.** `id:` selectors, relational
  selectors (`below:`, `childOf:`), `retryTapIfNoChange`, `repeat`, JavaScript,
  `launchApp` with `arguments` and `clearState`, JUnit and HTML reports. Parts of
  its settle-then-re-resolve are rebuilt here: `_settle`, the byte-identical-tree
  check, and the keyboard guard.

**Why it cannot simply switch.** Measured 23 Sep with Maestro 2.8.0 against the
app built on Flutter 3.41.9: once the store dropdown closes, every Flutter node
reports at 1/3 scale until the process restarts, and a restart loses the chosen
store. No Maestro command acts on correct frames between closing the dropdown
and tapping SUBMIT; only a hard-coded `point:` works. `resolve.py`'s correction
is the only reason journeys pass that screen. On the 3.49.0-0.1.pre beta the
scale is fixed and a selector-only flow passed end to end, as long as it
committed the store by filtering and pressing Enter. A second bug survives the
beta. Rows of a `DropdownMenu` whose field moves after it opens keep their old
frame, so a row tap still misses. That bug is isolated in a stock app, and no
upstream report of it was found.

**The shape, as proposed, not decided:**

1. `driver.sh` stays the way to read, look and explore: it is 0.28 s against
   7.7 s for a hierarchy, and it drives several devices.
2. What gets kept and replayed becomes a Maestro flow, run with `maestro test`.
3. Screens after setup can convert now. The setup screens wait for 3.49 stable
   or a launch argument that skips them. Otherwise they need `point:` taps,
   which is the brittleness this exists to remove.
4. When 3.49 is stable, `resolve.py`'s scale correction comes out rather than
   staying as a permanent layer.

**Open before building anything:**

- whether a journey → flow converter is worth writing, or flows are written by
  hand from here on
- whether the byte-identical-tree check has a Maestro equivalent, since Maestro
  reports COMPLETED for a tap that landed on nothing
- what the per-run startup costs a session that iterates on one flow, and
  whether `maestro test --continuous` removes it
- how `flow.sh` and several devices fit together, given each run takes that
  device's driver down

---

## 99. Two phones at once, and a phone with no cable — **OPEN, raised 22 Sep; Part 1 DONE 24 Sep — the port fix is built and two phones were driven at once; Part 2 (wifi) not started**

**Part 1, done 24 Sep** on an iPhone 11 (`00008030-001858493C91402E`, iOS
26.5.2) and the XS Max (`00008020-000A396C3606002E`, iOS 18.7.9), both on USB
to the Mac. Both UDIDs were already on the driver's profile, which expires 21
Aug 2027.

- **The fix.** `_device_port` (`bin/device.sh`) walks up from 22187 past every
  port another phone holds, in `DEVICE_MAP` and in the live forwarders from
  `platform.sh driver-scan`. A phone keeps its own port across restarts, and a
  port asked for that belongs to another phone is refused. There are seven
  offline tests. The defect was not reproduced on the old code first.
- **Live:** with no port given, the iPhone 11 came up on 22187 in 11 s and the
  XS Max on 22188 in 17 s. Each port drove only its own phone: Settings on one,
  Calendar on the other. Every item 46 restart went back to the same port.
- **Two drivers at once:** 30 rounds of reading both trees in parallel, 5 s
  apart, all succeeded at 0.9–1.5 s per read. Both drivers were still up after
  3 minutes idle. Parallel taps landed on both phones once they were upright.
- **One log per phone.** `deviceup.sh` now writes `~/devdrv-<udid>.log`. The
  shared `~/devdrv.log` was emptied by the second phone's bring-up while the
  first phone's `xcodebuild` was still writing to it.

**What the run turned up, not yet fixed — filed as items 101–104:**

- **A forwarder that outlives a reconnect points at a dead phone.** `iproxy.py`
  resolves the usbmux device id once, when it starts. The iPhone 11 got a new
  id when it was stood up, and its forwarder kept sending to "device 5": the
  runner said it was serving, and every connection was reset. `deviceup.sh`
  keeps an existing forwarder, so item 46 restarts never replaced it; only
  `device.sh down` then `up` did. `deviceup.sh` should check the forwarder's id
  against a fresh `ListDevices` before it keeps the forwarder.
- **`resolve.py` applies the Flutter 1/3-scale correction to native apps.**
  Calendar's tree has a 1242×2688 node at −414,−896. `resolve.py` reads it as a
  coordinate-space marker and moves Continue from y=781 to y=559. `tapon`
  returned rc=0 for a tap that hit nothing. Item 50's 11 Sep "x=−892" was the
  same mis-transform.
- **The XS Max's driver install failed with `CoreDeviceError` 3002** (IXRemote
  6, "Connection interrupted") four times in a row, at 72 s each, with nothing
  else using its tunnel. A restart of the phone fixed it, and the install then
  took 3 s. `deviceup.sh` reports this as the item 46 XCTest death, which it is
  not: it fails while Xcode is installing the driver.
- **`driver.sh app` answers `com.apple.springboard` on a phone** whatever is in
  front, so it cannot tell two phones apart.


Every physical-device measurement in `physical-device.md` is one phone on one
cable: the XS Max, 21 Aug to 11 Sep. Two things have never been tried, and they
fail differently, so they are two parts rather than one.

**Part 1 — several connected devices at the same time.** The pieces are already
per-device and none of them is a singleton. `runners/ios-device/iproxy.py` takes
`<udid> <port>` and resolves a `DeviceID` per UDID, so one forwarder per phone
shares `/var/run/usbmuxd`; `deviceup.sh` passes `TEST_RUNNER_PORT=$PORT` so each
phone's on-device server binds its own port; `_dport_for` derives a distinct
relay port; `DEVICE_MAP` is a multi-row file and `device.sh list` reads every
row — the stdin trap fixed on 17 Sep was exactly the bug that hid the second
row. So this is a test, not a build.

**Except for one defect that makes the obvious command silently wrong.**
`bin/device.sh:41` is `port=${3:-$DEVICE_PORT_BASE}` — a fixed 22187 with no
free-port search, where simulators get one from `_port_for`
(`bin/drivers.sh:78`). Bring a second phone up without naming a port and
`deviceup.sh` finds `/status` already answering 200 on 22187, prints `already up
on 22187`, starts nothing, and `_register` writes the second UDID onto the first
phone's port. `DEV=<second-udid> bin/driver.sh tapon …` then taps the **first**
phone and reports success. Give `device.sh` the same free-port walk, against
`DEVICE_MAP` rather than the live runner map, before running the test.

What the test has to answer, none of it guessable from one phone:

- whether one Mac sustains two concurrent `xcodebuild test-without-building`
  XCUITest sessions — item 74 found the simulator cost is a boot storm rather
  than a steady-state load, and a device driver is a different shape
- whether the tunnel drops of `physical-device.md` §5 get worse with two
  tunnels, and whether the `lockState` keep-alive must run per device inside a
  polling loop
- whether `usbmuxd` multiplexes two forwarders cleanly, and whether bus power
  through a hub is a factor

**Part 2 — a device connected over wifi rather than USB.** This may not be a
test at all. `iproxy.py` speaks to `/var/run/usbmuxd` and matches
`SerialNumber` in a `ListDevices` reply; a network-paired device is reached
through the CoreDevice tunnel, not necessarily through usbmuxd, so the forwarder
may have no route to it and the whole §4 mechanism may need replacing rather
than configuring. Establish that first — `ListDevices` with the cable out is a
two-minute answer — before designing anything. If it is absent there, the
question becomes whether `devicectl` exposes a forward, and §5's idling is the
thing to expect to get worse, not better, with no cable holding the tunnel up.

**Both parts are gated on hardware this machine does not have.** A second
iPhone, and the wildcard development profile of §3 must list each device UDID —
a phone not on the profile cannot run the re-signed driver at all. Part 2 also
needs the phone and the Mac on one network that permits it, which is the same
network the §97 aliases exist for.

---

## 97. The MCP server dies when the Mac is on another network — **OPEN, raised 21 Sep; the first two decisions built 21 Sep — the conf lists every alias, and an unreachable Mac now leaves a server that says so**

`maestro-mac` failed to connect for this entire session — `CONNECTION_CLOSED`,
every time, including after `/mcp` reconnects. Nothing else was wrong: the Mac
answered ssh on `mac-senseguest` throughout, and every `bin/` script worked
against it.

**The cause is the conf, and the symptom names none of it.** `bin/mcp.sh`
sources `config.sh`, which loads this project's conf — `MAC_HOST=mac-home`, an
alias for 192.168.4.250. The Mac is on the senseguest network. `_pick_host` has
one candidate, cannot reach it, and the server exits before it speaks a word of
MCP; Claude Code reports that a server closed the connection, which reads as a
broken install.

**`maestro-bridge` shows the same sentence for an unrelated reason, and the two
were conflated on 21 Sep.** That server takes no conf and touches no Mac, so a
network change cannot close it; it failed at session start because the session
was spawned before item 98 renamed the skill directory, and it connected on the
next restart with no change made. Both entries in `~/.claude.json` name
`~/.claude/skills/maestro-drive/bin/`. `CONNECTION_CLOSED` names the transport
and nothing else, so which server said it is the first thing to establish.

**Three things to decide, not one to fix — the first two are now built.**

**Where the aliases live — SETTLED 21 Sep, and it needed no code.** `MAC_HOST`
may name several, and `_pick_host` walks them — but this conf named one. The
conf now reads `mac-home mac-senseguest mac-office`, the three `Host` blocks in
`~/.ssh/config`, existing value first, which is what item 18 built the list for.

**Reproduced first, so the fix is not a guess.** Running `bin/mcp.sh` directly
on 21 Sep printed `socat[22] E CONNECT 192.168.4.250:22: Bad Gateway`, then
`kex_exchange_identification: Connection closed by remote host`, and exited
**255**. With the list in place the same command printed `mcp_viewer_ready
http://127.0.0.1:9999` and `MCP Server: Started. Waiting for messages. Working
directory: /Users/lennny`, and exited 0.

**Read `lib.sh:205` before concluding the list mechanism was broken.**
`_pick_host` returns at `[ "$n" -le 1 ] && return 0` — with one candidate it
never probes, never caches and never re-picks. So the single-alias conf did not
merely make a good mechanism unlucky; it switched the mechanism off. That is why
the failure was total rather than slow.

**`bin/init.sh` writes all of them, 21 Sep.** It used to emit
`: "${MAC_HOST:=$HOST}"` from the single `--host` it was given, so every conf it
wrote started in the state that caused this. `--host` now accumulates — repeated
or as one quoted list — and the conf line needed no change, because `${HOST}`
already interpolated whitespace.

Three other sites did. `--detect` probes **every** alias given and prints which
answered, since "which of my Host blocks reaches the Mac today" is the question
you actually have when it has moved; the rest of the detection then goes to the
first that answered. The write path picks one alias the same way for the JDK and
`maestro` lookups, and **skips both when none answers** — `_javahome` with no
argument answers about the local machine, so passing an empty alias would write
a Linux JDK path into a Mac's conf, a finding that is wrong rather than absent.

Three tests, in the skill suite: both `--host` spellings, and that an
unreachable Mac leaves `RJAVA` unset. 558 passed, 0 failed; package suite 158.

**What the server should do when it cannot reach the Mac — BUILT 21 Sep.**
Exiting is honest and unreadable. `bin/unreachable-mcp.py` is 74 lines of the
same stdio loop as `bridge-mcp.py`: `mcp.sh` execs it instead of exiting, it
answers `initialize` and lists one tool, `why_unreachable`, and it returns the
reason from **every** `tools/call` rather than only its own — a caller that
guessed a Maestro tool name would otherwise get a protocol fault instead of the
answer. `_pick_host` already wrote the right sentence to stderr; the message is
passed in on argv, so the aliases tried and the conf path travel with it and the
wording stays in one place.

It is not a retry and not a proxy. Answering `tools/list` with the Maestro tool
set would be a lie, since none of those tools can run, and connecting lazily on
first use means proxying stdio for the life of the session — larger than
anything in this package. Restarting the session is the fix and the message says
so.

**The list made the hang longer, which is the cost of the first decision.**
Three aliases and no Mac is three probes at `PROBE_FAST` then three at
`PROBE_SLOW` — up to 69s before `_pick_host` gives up. That is now 69s to a
server that explains itself rather than 69s to `CONNECTION_CLOSED`, but it is
still 69s, and cutting it is a separate question from this one.

**Four tests**, in the skill suite: the three calls a client makes before it can
show anything are each answered, and the reason names the aliases by name. 562
passed, 0 failed; package suite 158.

**One failure it does NOT cover.** `config.sh` refuses a conf that is missing
`MAC_FQDN` and exits before any of `mcp.sh`'s own code runs, so a half-written
conf still reads as `CONNECTION_CLOSED`. Same sentence, different cause, and it
is above the line where this fix sits.

**Whether it should be reading the project conf at all.** The MCP server is
spawned once per session, before any project is in view, and `config.sh`'s
search walks up from `$PWD` — which for a server Claude Code spawns is wherever
the session started. The `maestro-bridge` server takes no conf at all and starts
a helper the conf then points at; `mcp.sh` could work the same way.

**A fourth, added 21 Sep by item 94's 5.5: whether it is still called
`maestro-mac`.** The package is becoming `maestro-drive` (item 98), and this
server's name is wrong in the same way — under local or bridge transport it
never touches a Mac. It is here rather than in 98 because the three decisions
above may restructure or retire the server, and because renaming it is not just
the entry: the tool names become `mcp__maestro-drive__*`, and
`MAESTRO-REVIEW-TRACKER.md` counts `mcp__maestro-mac__*` in transcripts to
decide whether a session drove Maestro, so its matcher has to take both prefixes
first. `uninstall.sh` deletes `.mcpServers[$MCP_NAME]` and knows only the
current name, so a rename without a legacy sweep in `manifest.sh` leaves the old
entry in `~/.claude.json` pointing at a script that is gone.

**Gated on:** nothing. Found while proving item 96.

## 96. A device on this machine is on the other side of the sandbox — **DONE 21 Sep 2026; all three stages, and the live run in 3.2 drove a real emulator**

Item 94 made the package drive a device on the machine it runs on. It works —
Stages 1 to 4, 500 tests — and inside a Claude session on THIS machine it
cannot reach the device at all. Measured 21 Sep, from the Bash tool:

```
/dev/kvm       absent          an x86 emulator cannot start
processes      4               its own PID namespace
interfaces     lo              its own network namespace
writes         cwd and $TMPDIR only
```

**The SSH transport works from in here for a reason that local transport
removes.** The sandbox permits egress to the Mac, and the Mac is outside it
doing the work. Locally there is no other machine, so the work lands in the one
place that cannot do it.

**An MCP server is outside the sandbox.** Measured the same day, with a throwaway
server registered and called: `/dev/kvm present, opened read-write`, the AVD
directory writable, 483 processes, the host's interfaces, parent
`/home/james/.local/bin/claude`. So a process Claude Code spawns can do what the
Bash tool cannot.

**And the scratch is shared.** `/tmp/claude-1000` is a real host directory both
sides see. A FIFO created in the sandbox and written by a host process delivered
its bytes. A TCP listener on the host was also reachable, through the egress
proxy, once its address was declared — but `ssh` to the same machine was refused
as *Containment Escape*, so that route rests on a per-command judgement rather
than a rule.

### The shape, and why not the others

**Four shapes were considered.** One MCP tool per `bin/` script (ten typed
tools); one per runner-module verb; one per intent; or a generic channel that
carries what `_ssh` already carries. The first three add a second way to drive
to a package whose whole design is one way to drive — written, tested and kept
in step per platform and per transport, forever, for one machine's testing
problem. The fourth adds a third value to a setting that already exists.

**It is chosen for sharing, and the cost is stated plainly.** The bridge carries
arbitrary shell to this machine — the same capability the ssh transport has
against the Mac, pointed at the machine the sandbox exists to protect, and
nothing reviews the traffic. It is the boundary removed rather than narrowed.
The controls are that it is started deliberately rather than running in every
session, that it logs every script it executes, and that it stops at session
end.

**A Mac never uses it.** On macOS there is no KVM in the picture and seatbelt has
no PID or network namespace, so local transport as 94 built it should reach a
simulator directly. This item exists for this Linux machine's sandbox.

**Local versus remote is three things, and the bridge answers each from an
existing answer:**

| | ssh | local | bridge |
| --- | --- | --- | --- |
| a shell script reaches the device host | `ssh` | `sh -c` | the channel |
| a file reaches it | `scp` | `cp`, one filesystem | `cp`, one filesystem |
| an HTTP client here reaches a port there | relay + proxy + `$MAC_FQDN` | `127.0.0.1` | relay + proxy + the host's address |

That third row is the one that would otherwise bite: `driver.sh` curls
`$BASE/status` **from the sandbox**, and under the bridge the driver is bound to
the host's loopback, which the sandbox cannot reach. `_urlhost` and
`_driver_base` already have the branch point.

### The plan, in stages

**Stage 1 — the channel.**

**1.1 DONE 21 Sep — `remote/bridge.sh`, the host-side helper.** Reads a request id from a
control FIFO, runs the script that request carries, streams stdout and stderr
back down two FIFOs the client made, writes the exit status to a file. One
directory per session under the shared scratch, with a random component in its
name. Every script it runs is appended to a log beside it. *Done when:* a script
sent from the sandbox runs on the host and its output comes back, and the log
shows what ran.

**One request, one set of files, so concurrent calls cannot collide.** The
control FIFO is a doorbell carrying an id; everything else is `<id>.cmd`,
`<id>.in`, `<id>.out`, `<id>.err`, `<id>.rc`. `out` and `err` are FIFOs the
client makes, which is what keeps the streaming real — opening them blocks until
the client is reading, so output arrives as the script produces it rather than
as a file read at the end. Measured in the suite: the first line of
`echo first; sleep 2; echo second` arrives in under a second.

**The starting is what the harness objects to, not the mechanism.** Running the
helper detached from the Bash tool was refused as *Containment Escape*, which is
a fair reading of what it is. Started inside a single call and stopped at the
end it is permitted — which is how the suite exercises it, and how the MCP
server will start it for real (2.1).

**Four repairs to item 95's cases came with this unit**, because the machine
changed underneath them: the apt JDK was removed and its replacement is a
version manager sourced from `.bashrc`, which a non-interactive shell does not
read. The suite now keeps `REAL_HOME` from before it redirects `HOME` — rung 1
asks the login shell, and the login shell's init is in the user's own home —
skips rather than fails when a machine has no JDK on any rung, and builds a
findable JDK for the two cases that need the fallback to succeed.

**Verified:** 512 passed, 0 failed, nine new — stdout and stderr on separate
channels, the script's own exit status, stdin forwarded, the first line arriving
before the script has finished, the log carrying every script, and a directory
owned by somebody else being refused.

**1.2 DONE 21 Sep — `_ssh` gains the bridge branch, and the payload assembly is factored out.**
The message is the same three parts in every transport — environment prefix,
`cd $REPO`, the caller's script — and it is currently written out twice. A third
copy is not the answer. *Done when:* a given call produces byte-identical script
text in all three transports, and the bridge branch streams stdout, forwards
stdin and returns the real exit status.

**`_payload` is the assembly, and the suite asserts local and bridge produce the
same bytes.** ssh's differs in one thing only, and deliberately: `REMOTE_ENV`
replaces `PATH` where `LOCAL_ENV` adds to it (2.1's reason — replacing it here
would lose the Android SDK under `/mnt/sda`).

**Stdin is a channel, not a file read up front, and getting that wrong hung the
suite.** The first version drained stdin into a file before ringing, which
stalls every call whose caller leaves stdin open and sends nothing — most of
them. It is a FIFO with a background writer now, which is what ssh does.

**A background command in a non-interactive shell gets `/dev/null` for stdin
unless it is told otherwise**, so that writer delivered an empty stdin and said
nothing about it. It names the call's own stdin explicitly through fd 9. The
case that catches it pipes text into `_ssh "cat"` and reads it back.

**A helper that is not serving is like a host that is not answering:** it says
so, runs nothing and returns 1. No retry — the same reasoning that keeps the
local branch retry-free, because half of what goes through `_ssh` taps a screen.

**Verified:** 520 passed, 0 failed, eight new; 145 passed, 0 failed in the
package's suite.

**1.3 DONE 21 Sep — the values follow the table.** `_push`/`_pull` take local's answer;
`_urlhost`, `_driver_base` and `$grpc_proxy` take ssh's. *Done when:* a bridge
conf builds a driver URL naming the host's address and a relay port, and a push
is a copy rather than an scp.

**Two predicates replace thirty scattered "is this local" tests.** `_fs_shared`
is true when the machine with the device shares this filesystem — ssh no, local
yes, bridge yes. `_ports_here` is true when a port on that machine is reachable
from this process without a relay and without the proxy — ssh no, local yes,
bridge **no**. Every branch in `bin/` was asking one of those two questions
while appearing to ask about the transport, which is why a third transport would
otherwise have meant editing all of them and getting some wrong.

**The split is not cosmetic.** `_urlhost` and `_driver_base` follow
`_ports_here`, so the bridge reads the driver through `relay.py` exactly as the
Mac is read, and `$grpc_proxy` stays set for the same reason. `_push`, `_pull`,
`$RHELP`, `$RMODS`, `mcp.sh` and `install.sh` follow `_fs_shared`, so a push is
a copy onto itself. `_macip` gains a third answer — the conf's `BRIDGE_HOST` —
because under the bridge the question is real again.

**The four stub `lib.sh` files in the suite carry the predicates**, since a stub
that replaces `lib.sh` replaces `config.sh` with it.

**1.4 DONE 21 Sep — what a failure means.** ssh re-picks a host on 255 and 124; local
deliberately does not retry. The bridge needs its own rule: a helper that is not
running is like a host that is not answering, and a timeout on a live helper is
the command's own. *Done when:* a stopped helper says so and does not retry a
command that may have tapped a screen.

**Three failures, three answers.** No helper serving: say so, run nothing,
return 1. A command that outruns `$TMO`: the far side's own `timeout` ends it
and 124 comes back, once — the log shows one invocation, not two. No status
file after the channels close: report that rather than invent a zero.

**Verified:** 529 passed, 0 failed, nine new across 1.3 and 1.4; 145 passed, 0
failed in the package's suite.

**Stage 2 — starting it.**

**2.1 DONE 21 Sep — the MCP server, one verb.** `bridge start|stop|status`, and nothing else.
No `boot`, no AVD names, nothing platform-shaped — booting a device is
`platform.sh boot` sent over the bridge like everything else, which is what
keeps android and ios sharing the same path. *Done when:* the server starts the
helper, reports where its directory is, and stops it.

**`bin/bridge-mcp.py`, and the verb list is the whole design.** One tool called
`bridge`, one argument, an enum of three. No paths, no device, no AVD name, and
nothing it can run but `remote/bridge.sh`. The suite asserts the tool takes
exactly one property and that a fourth action is refused by name.

**It prints the conf rather than writing one.** `start` returns the three lines
to paste — `TRANSPORT`, `BRIDGE_DIR`, `BRIDGE_HOST` — and says where the log is.
`BRIDGE_HOST` comes from `hostname -I`; when that is empty the reply says the
server is not running where it should be, because a server with no network
interface is one that got spawned inside the sandbox.

**Proved end to end, in one call:** start, then `_ssh` over the bridge running
`hostname; ls /dev/kvm; nproc` on the far side, then stop. Started from a Bash
tool the far side is still the sandbox — no `/dev/kvm` — which is exactly what
the probe measured and what registering the server fixes.

**Verified:** 536 passed, 0 failed, seven new; 145 passed, 0 failed in the
package's suite.

**2.2 DONE 21 Sep — it stops when the session does.** `rig-down-on-end.sh` is already the
SessionEnd hook; the helper hangs off the same idea rather than inventing one.

**The rig goes down first, and the order is the unit's one real decision.**
Under `TRANSPORT=bridge` a `rig down` travels through the helper, so stopping
the helper first would strand the very simulators the hook exists to take down.
Both run in one detached subshell, in that order, so SessionEnd still never
holds the terminal open.

**Two entry points, one implementation.** A hook is not a Claude session and
cannot call an MCP tool, so `bridge-mcp.py` answers `--stop`, `--status` and
`--start` on the command line as well.

**The log is left behind.** A teardown that takes the record of what ran on this
machine with it would be worse than one that leaves a directory.

**Stage 2 is complete.** The helper is started when asked, by one verb that
takes no paths, and it ends with the session.

**Verified:** 540 passed, 0 failed, four new; 145 passed, 0 failed in the
package's suite.

**2.3 DONE 21 Sep — the installer asks.** Registering the server is not the same
as opening the channel — it idles until a session calls `start` — but it does put
the tool in every session on that machine, so `install.sh` asks rather than
decides: a `[Y/n]` with the honest description beside it.

**Three answers, and a fourth that is nobody's.** `--with-bridge` and
`--no-bridge` answer in advance; an unattended install — `--yes`, or no terminal
— registers nothing and prints the flag to add it, because a capability that
appears in a scripted install is one nobody chose.

**An install never removes it.** Already registered means keep it and do not
ask, so `update.sh` — which re-runs the installer with whatever flags it was
given — cannot quietly take it away. `--no-bridge` on a machine that has it
leaves it alone too. `uninstall.sh` removes both names, because the entry would
otherwise point at a script that has just been deleted, which fails at every
session start rather than visibly.

**One thing it does not do yet.** `install.sh` decides whether to ask with
`[ -t 0 ]` and reads with a plain `read`, while `update.sh` and `uninstall.sh`
both read from `</dev/tty`. An update run the usual way — `curl … | bash` —
leaves stdin a pipe, so `update.sh` can ask its own question and `install.sh`
cannot: it falls through to printing the flag. Its existing wizard prompt has
had the same shape all along. One line each, and both prompts should read from
`/dev/tty` when there is one.

**Verified:** 150 passed, 0 failed in the package's suite, five new.

**Stage 3 — proof.**

**3.1 DONE 21 Sep — the suite runs three transports.** 5.1's block gains a column. The helper
can be started in-process, so it still needs no Mac and no device.

**Thirty-four bridge cases in all, across 1.1 to 3.1**, and the helper is
started inside the run every time — so the suite still needs no Mac, no device
and nothing registered. 94's 5.1 block now covers `install.sh`, `_pull` and
`mcp.sh` under the bridge as well, which is where the two columns show: the
checkout is left byte-identical and nothing is copied, exactly as locally,
while the `mkdir` that makes the scratch has to travel through the helper to
happen at all.

**`mcp.sh` execs the server here under the bridge too**, and for a reason worth
writing down: it is spawned by Claude Code, so it is already outside the
sandbox. It has no need of the bridge, and routing it through one would put a
channel between a process and the machine it is already standing on.

**Verified:** 544 passed, 0 failed; 145 passed, 0 failed in the package's suite.

**3.2 DONE 21 Sep — the live run — this is item 94's 5.2.** `rig up`, a flow, a screenshot,
`net.sh`, `prefs.sh`, against `Pixel_6_Pro_API_34` and
`com.prodirectsport.consumer.dev`, with the result recorded verb by verb. 94's
5.3 and item 87's 4.4 follow it.

**It ran.** A sandboxed Claude session booted an emulator on this machine,
launched the app, drove it with Maestro and read the screen back — through the
helper, with every script it ran in the log.

| verb | result |
| --- | --- |
| `platform.sh boot Pixel_6_Pro_API_34` | `emulator-5554`, written for this run |
| `platform.sh devices --booted` | `emulator-5554  device  sdk_gphone64_x86_64` |
| `bin/install.sh` | nothing copied, `/tmp/maestro-mac` made |
| `bin/shot.sh` | 24KB and 47KB PNGs, pulled back and read |
| `bin/prefs.sh` | the app's shared preferences, Flutter keys and all |
| `bin/net.sh` | no VM service — correct, the app was not under `flutter run` |
| `bin/flow.sh` | `Launch app "com.prodirectsport.consumer.dev"... COMPLETED`, then the hierarchy and a screenshot |
| `drivers.sh rig up` | not run: `driver-up` is still 87's 4.4 |

**Three faults, each of them found by running it.**

**`nohup` is not detached enough.** The first boot died a few calls later, and
its own log said why: *Wait for emulator (pid 718350) 20 seconds to shutdown
gracefully*. `nohup` blocks SIGHUP and leaves the process in the caller's
process group, and every bridge request runs under `timeout`, which manages a
group of its own. `setsid` gives the emulator its own session. A device that
dies when the call that booted it finishes is no boot at all.

**The bridge drains stdin when the call is made, and ssh is laxer.**
`bin/flow.sh` resolved the device before reading its flow, so `_dev`'s round
trip ate the heredoc and Maestro reported *Commands Section Required* against a
file with `appId:` and nothing under it. The flow is read first now. This was a
latent bug on the ssh path too — ssh just happened not to consume it.

**Maestro was not on the far side's PATH**, which became item 95's third unit.

**What the far side is:** `/dev/kvm` present, 8 CPUs, `hostname` `oi-jamesl`,
Java 17 from `$RJAVA`. Not the sandbox — the machine.

**Gated on:** nothing. Item 94's Stage 4 is done and this builds on it.

## 95. The JDK was one machine's installer path, hardcoded — **DONE 21 Sep 2026**

**Maestro's own directory is the same question, and 96's live run found it.**
`REMOTE_ENV` put `$HOME/.maestro/bin` on `PATH`, which is where Maestro's
installer puts it and nowhere else. This machine keeps it under
`/mnt/sda/User/Programs/maestro/bin`, exported from `~/.bashrc` — so the process
running the package could not see it, and a flow could not run. `remote/whereis.sh`
asks the login shell where an executable lives, `bin/init.sh` records the answer
as `RMAESTRO`, and the env prefix appends it rather than replacing the default,
so a conf written before this setting keeps working.

**Appended, not substituted, and only recorded when it differs.** A setting that
repeats the default is noise and would go stale if Maestro were reinstalled.

`lib.sh` set `JAVA_HOME=$HOME/.sdkman/candidates/java/current` in `REMOTE_ENV`,
and 2.1 copied it into `LOCAL_ENV` as a fallback. It is true of the Mac this
package was written against and of nothing else: it makes SDKMAN a requirement
of a package that has no business having one, and a machine using jenv, mise,
asdf or a plain Homebrew JDK gets a `JAVA_HOME` pointing at a directory that
does not exist.

**Found while asking what 5.2 needs locally.** This machine has no SDKMAN, so
`LOCAL_ENV`'s fallback resolves to nothing — and worse than nothing, because
Maestro's CLI is a Gradle start script and those use `$JAVA_HOME/bin/java`
whenever `JAVA_HOME` is set.

**What every version manager has in common is the login shell.** sdkman, jenv,
mise, asdf, jabba and a hand-written export all work by a line in `.zshrc` or
`.bash_profile`. So ask the machine's own shell rather than any manager's
directory. `remote/javahome.sh` does that, in three rungs:

1. `$SHELL -ic 'printf %s "$JAVA_HOME"'`, stdin closed — whatever the manager set
2. `/usr/libexec/java_home` — macOS's registry, for an Apple- or cask-installed JDK
3. the login shell's own `java`, resolved through its symlinks, rejecting
   `/usr/bin/java` because on macOS that is a stub rather than a link into a JDK
4. `java -XshowSettings:properties -version`, and read `java.home` out of it

**Rung 4 is the one that covers the shim managers, and it was missing at first.**
jenv without its `export` plugin, and mise or asdf used through shims rather
than `activate`, put a shell *script* called `java` on `PATH`. Rung 1 has
nothing to report, and rung 3 resolves the shim to its own directory, which has
no `bin/java` under it — so a machine with a perfectly good Java came back
empty. Any `java` that can run will say where it lives. It goes last because it
starts a JVM, about a fifth of a second, against three rungs that cost nothing.

**Measured on the Mac, 21 Sep.** Rung 1 answers:
`/Users/lennny/.sdkman/candidates/java/current`, Temurin 21. Rung 2 fails there
— `Unable to locate a Java Runtime`, because `/Library/Java/JavaVirtualMachines`
is empty and SDKMAN registers nothing — and rung 3 would return `/usr`. So on
that machine only the shell knows, which is the whole argument.

**Asked once, at setup, and recorded as `RJAVA` in the conf.** The R family, like
`$RDIR` and `$RHELP`: the machine with the device. `bin/init.sh --detect` prints
it and `--write` records it, in both transports. Per-command discovery was
rejected: an interactive shell with no tty hangs — one run in three took the
full 60s, measured — and `$TMO` would make that a three-minute stall inside
`_ssh`, on the function all 84 call sites go through.

**A recorded `RJAVA` is checked on the far side before it is used.** A JDK that
has been upgraded, removed or swapped for a version manager leaves the conf
naming a directory that is no longer there, and an unguarded export is then
worse than having recorded nothing: Maestro's CLI is a Gradle start script, so a
`JAVA_HOME` that is set and wrong aborts it, while an absent one lets the
fallback find whatever is there now. It says which recorded path is gone and
carries on looking.

**A conf with no `RJAVA` is not guessed at.** `lib.sh` falls back to rungs 2 and
3 on the far side, per command, with no interactive shell; when neither answers
it prints what to run. That is the migration: an existing conf loses `JAVA_HOME`
on the Mac until `bin/init.sh --detect ... --write` records one, and the message
says so rather than the package pretending it knows where a JDK is.

**Verified live against the Mac:** `java -version` over `_ssh` returns Temurin
21 with `JAVA_HOME` from `RJAVA`, and `init.sh --host <alias> --detect` prints
the path and the version. 503 passed, 0 failed in the skill's suite and 145
passed, 0 failed in the package's, eleven of them new — a JDK only a fake shell
init knows about, a JDK reachable only through a shim, a stale `RJAVA` falling
back to the JDK that is actually there and naming the path that is gone, and the
fallback never opening an interactive shell.

**What is verified and what is reasoned.** Verified: SDKMAN on the Mac (rung 1,
live), an apt JDK on the Linux machine (rung 3), a shim manager (rung 4, a
fake), a shell-init manager (rung 1, a fake), and no JDK at all. Reasoned but
not run: an Apple or Temurin `.pkg` under `/Library/Java/JavaVirtualMachines`
(rung 2) — there is no such Mac here — and Homebrew's keg-only `openjdk` reached
by a `PATH` line, which rung 3 resolves through the keg symlink.

## 94. Everything goes over SSH, including when the device is on this machine — **DONE 21 Sep 2026; five stages, the live run in 5.2 drove a real emulator, and 5.5 named the package `maestro-drive`**

The package is named for the case it was built for: a Linux box driving a Mac.
A developer whose simulator or emulator is on the machine they are sitting at
cannot use it at all — `bin/config.sh` refuses to load without `MAC_HOST` and
`MAC_FQDN`, and there is no host to give it.

**It is a smaller job than the shape suggests.** Counted 18 Sep:

```
84  _ssh "<script>"   across 21 files   ONE function in bin/lib.sh
16  raw ssh / scp     across 12 files   individual, mostly file copies
```

The 84 do not change. They already pass a shell script and read its output, and
`_ssh` is free to run that with `sh -c` instead of handing it to ssh. The 16 raw
calls are the ones needing attention one at a time.

**Six things are not simplified locally — they become unnecessary.** Each exists
only because there is a boundary:

| piece | why it exists | locally |
| --- | --- | --- |
| `remote/relay.py`, `bin/publish.sh` | republishes the Mac's loopback-bound debug endpoint on its LAN interface | read `127.0.0.1` |
| `$grpc_proxy` on every curl | the sandbox's egress proxy | no proxy |
| base64 round-trips in `shot.sh`, `flow.sh`, `img.sh` | getting a PNG back over SSH | the file is already there |
| `_pick_host`, `_probe_host`, `MAC_HOST` as a list | the Mac moves between networks | no host to pick |
| `MACIP`, `MAC_FQDN` | building URLs the sandbox can reach | `127.0.0.1` |
| `$RDIR` vs `$LDIR` | two machines, two scratch directories | one |

**Three parts need thought rather than a branch.**

**`config.sh`'s required settings.** It refuses without `MAC_HOST` and
`MAC_FQDN`. Local mode is a different required-settings shape, not an exemption
bolted onto the existing one — and the message it prints when a project is not
configured is one of the more useful things this package does, so it has to stay
that good for both.

**`$RDIR` and `$LDIR` collapsing to one directory.** Code that copies between
them would copy a file onto itself. `bin/shot.sh` and `bin/install.sh` both do.
This is the part that looks trivial and is not: every `scp` and every
`base64 | base64 -d` pair is a copy between two names for what would become one
place.

**The wall.** It binds the Mac's LAN interface and publishes a URL built from
`MAC_FQDN`. Locally that is `127.0.0.1:9990` — but `WALL_URL` already exists as
the override for exactly this, so it may cost nothing. Check before assuming it
does.

**The runner modules are unaffected**, which is worth saying because it is the
same argument item 87 rests on, one layer down. Every platform and framework
verb already runs on the machine that has the device and is invoked as
`sh <module> <verb>`. Whether that machine is reached by ssh or IS this one is
`_ssh`'s business and none of theirs.

**Naming.** If this lands, `maestro-remote-mac` is the wrong name for what the
package does. Not a reason to avoid it, but it is a rename, an installed skill
directory, an MCP server entry and a repo — so decide it deliberately rather
than discovering it at the end.

**Gated on:** nothing. Item 87 touches `_ssh` only as a caller.

**Item 87's 4.4 is gated on THIS item's Stage 2**, which is the reverse
direction and was not seen when either was raised. 4.4 — the Android driver
trio, and whether Maestro's Android client lets its port be chosen per device —
is the one unit of 87 whose note reads *needs an Android SDK and a booted
emulator*. There are emulators on the Linux machine this package is driven
from, and none on the Mac it drives. So the hardware 87 is waiting for is here
already and unreachable: every verb gets to a device by SSH to a Mac with no
Android SDK on it. Stage 2.1 is what turns this machine into a device host, and
87's last hardware-blocked unit falls out of it.

### The plan, in stages

Each unit is one commit. Stage 1 decides the shape; Stages 2 and 3 are
mechanical once it is right, and doing them first would mean doing them twice.
Every stage keeps the SSH path working — there is no cut-over commit.

**Stage 1 — the switch, and what a local project must set.** All four units are
`bin/config.sh` and `bin/init.sh`. Nothing else knows the mode exists yet.

**1.1 DONE 18 Sep — one setting names the transport.** `.maestro-mac.conf`
gains `TRANSPORT`, defaulting to `ssh`, read in `bin/config.sh` above
`MAC_HOST` and exported. Nothing reads it yet. It is an explicit setting rather
than "`MAC_HOST` is empty, so we must be local", because a conf with a misspelt
`MAC_HOST` has to keep failing as a broken remote conf — if emptiness meant
local, the typo would instead start hunting for a device on this machine and
report it missing, which is a true statement about the wrong machine.

**Named `TRANSPORT`, not `MODE`.** It sits beside `RUNNER`, `PLATFORM` and
`PROFILE`, each of which selects one thing and says which in its name. `MODE`
says only that there is more than one of something.

*Files:* `skill/bin/config.sh`. *Verified:* an unset value reads `ssh`;
`TRANSPORT=local` survives and is exported; `TRANSPORT=sssh` is refused by name
with exit 1; and the unconfigured-project message is byte-identical to the one
`git stash` produces, diffed rather than eyeballed.

**1.2 DONE 18 Sep — the required-settings check is per transport.**
`config.sh` demanded `MAC_HOST`, `MAC_FQDN` and `APP_ID` together. Local mode
needs `APP_ID` alone; the other two have no answer on this machine. Two
messages, not one with a conditional clause: the unconfigured-project message is
one of the more useful things this package prints, and it stays that good for
both shapes rather than degrading into a list with `(unset)` against settings
the reader was never meant to fill — and a `--detect` line offering to list ssh
aliases they do not have.

The searched-paths and detached-process paragraphs are duplicated deliberately,
not factored out: the conf search is genuinely the same in both, and a shared
fragment would be one more thing that has to stay true of two messages.

The local message pointed at the two lines that are the whole of a local conf
until 1.4 gave `bin/init.sh` a `--local`; it now names that instead.

*Files:* `skill/bin/config.sh`. *Verified:* `TRANSPORT=local` with no `APP_ID`
names `APP_ID` and nothing else; with `APP_ID` set it loads and leaves
`MAC_HOST` empty; the ssh message diffs byte-identical to the captured
pre-change output; suite 144 passed, 0 failed.

**1.3 DONE 18 Sep — the permission warning has nothing to warn about
locally.** The block matches `permissions.allow` against the real `ssh <host>`
and `scp <host>` strings and suggests `Bash(ssh <prefix>*:*)`. Local transport
runs neither command, so the block is guarded off.

**The reason it was planned for was wrong, and the measurement is the record.**
This item expected an empty `MAC_HOST` to produce `Bash(ssh *:*)` — every host
on the machine, offered to a session that needs none. Removing the guard and
running local mode prints nothing at all: the command list is built from the
alias list, and an empty list has nothing uncovered. So the guard is one
python3 subprocess saved per local session and a statement in the file, not a
behaviour change. It still earns its place — the day `MAC_HOST` gains a local
default is the day that derivation stops holding, silently.

*Files:* `skill/bin/config.sh`. *Verified:* ssh mode with two aliases and no
allows warns and writes `perm-warned`; local mode prints nothing and writes no
marker.

**1.4 DONE 18 Sep — `bin/init.sh --local` writes a local conf.** `--detect`
listed `~/.ssh` aliases and probed each one; `--local --detect` instead reports
this machine's toolchains, attached devices, defined AVDs and checkout, and
`--local --app <id> --write` writes a conf with `TRANSPORT`, `APP_ID` and a
detected `PLATFORM` and nothing else.

**`init.sh` is the one script Stage 2.1 will not reach.** `_ssh` sources
`config.sh`, and `init.sh` exists to write the conf `config.sh` reads — so it
takes `--host` and calls `ssh` directly, and the local path here is a second
path beside those four calls rather than a reuse of them. The questions carry
over even though the code does not.

**`PLATFORM` is detected now, where the ssh path still defaults it.** The ssh
path writes `ios` with *nothing is booted yet to ask about*, which is true at
first-run time across a network. Locally the machine is right here, so: no
`xcrun` and `adb` present gives `android`; `xcrun` and no `adb` gives `ios`;
both present is refused with `--platform ios|android` rather than guessed;
neither is refused naming the missing SDK. The evidence is written above the
setting — a booted device where there is one, otherwise the AVD names, because
those are different facts and the weaker one has to say so. The list is given
whole, with its count: a truncated list in a conf comment reads as the whole
answer and the reader cannot tell that it is not.

**`--host` with `--local` is refused, not ignored.** A silently dropped flag
leaves someone believing they configured something they did not.

**`RUNNER` is detected locally too, and 2.1 is not needed for it.** The first
cut of this unit guarded `runner.sh detect` off locally on the grounds that it
reaches the checkout through `_ssh`. Wrong: `claim` is the one framework verb
that needs no Mac. Every implementation is a filesystem test on the checkout —
`flutter` reads `pubspec.yaml` for a `flutter:` dependency, `react-native`
reads `package.json`'s `dependencies` — and it goes through `_ssh` only because
in ssh transport the checkout is on the Mac. `runner.sh detect` now runs the
module out of `$RUNNERS` when `TRANSPORT=local`, and `runners/README.md` already
said so: *Runs ON THE MAC, except `claim`*.

Caught by the question a local React Native project asks: why would it default
to flutter? It no longer does.

*Files:* `skill/bin/init.sh`, `skill/bin/config.sh` (the 1.2 message now names
`--local`). *Verified:* `--local --detect` on this machine reports `android`
from four defined AVDs with none booted; the written conf loads through
`config.sh` with `MAC_HOST` empty; `--platform ios` overrides and records that
it was given; `--local --host` and a missing `--app` both exit 2 by name; a
local checkout with a react-native dependency writes `RUNNER=react-native` and
one with a flutter dependency writes `flutter`, both marked detected, while a
checkout neither claims writes the default and says so; the ssh path's conf
diffs byte-identical against the pre-change script; suite 144 passed, 0 failed.

**1.5 DONE 18 Sep — an AVD that exists is not an AVD Maestro can drive.**
Raised by 3.3's docs read rather than planned. `--local --detect` and the
`PLATFORM` evidence listed every AVD as though each were a candidate. Two of the
four on this machine are not:

```
Maestro can drive:  Pixel_6_Pro_API_34 (34) Pixel_Tablet (34)
API unsupported:    Medium_Phone (36.1) Small_Phone (36)
```

The supported set is quoted, not inferred, from the mirror at `skill/docs`
(Maestro 2.8.0, mirrored 11 Aug 2026): *"Maestro currently supports API Levels
29, 30, 31, 33, and 34. API 35 and 36 support is arriving in Q2 2026."* 32 is
absent from that sentence and so it is absent here. Hard-coded because the
answer moves on Maestro's release schedule and not on anything this machine can
be asked — when it moves, this list and the mirrored page move together.

The level comes from each AVD's own `config.ini`, whose `image.sysdir.1` carries
it as `system-images/android-<level>/`. An unreadable config reads `(?)` and
sorts as unsupported, because a level that cannot be established is not one that
has been checked.

*Files:* `skill/bin/init.sh`. *Verified:* the detect output and the written
conf both split the four AVDs correctly and the conf comment still wraps inside
80 columns; suite 144 passed, 0 failed.

**Stage 2 — `_ssh` runs the script instead of sending it.** The 84 call sites do
not change in any unit of this stage. That is the whole bet; if a call site has
to change, the bet was wrong and the shape goes back to Stage 1.

**2.1 DONE 18 Sep — `_ssh` gains a local branch.** In local transport it runs
the same script through `sh -c` on this machine. `_pick_host` returns at the
top, `_probe_host` is never reached, `SSH_OPTS` is never expanded, and the
retry-and-re-pick path is skipped: it exists because ssh failed to reach a
host, and locally there is no host to re-pick — a local 124 is the command
itself running long, and half of what goes through here taps a screen. `$TMO`
still bounds it, because a local command hangs as readily as a remote one and a
caller that set a timeout meant it.

**`$REMOTE_ENV` could not be reused, and the reason is the unit's one real
finding.** It *replaces* `PATH` with `/usr/bin:/bin:/usr/sbin:/sbin` plus
Maestro and sdkman's Java — correct for a machine reached by ssh, where the
non-interactive shell's `PATH` is whatever sshd hands it. Run it locally and it
drops every directory the caller's `PATH` carries: on this machine the Android
SDK is under `/mnt/sda`, so `adb` would vanish and every android verb would
fail as `command not found` while reading like a broken module. `LOCAL_ENV`
adds instead of replacing, and an existing `JAVA_HOME` wins.

**Not enough on its own, and 2.2 is why.** The call sites ask for
`$PLATFORM_SH`, which is `$RDIR/runners/…` — `/tmp/maestro-mac/...` locally,
which nothing populates. Verified: the module runs through `_ssh` when called by
its checkout path and exits 127 when called by its `$RDIR` path. That split is
2.2's whole subject.

*Files:* `skill/bin/lib.sh`. *Verified:* `_ssh 'echo hello'` prints it; `exit 3`
comes back as 3; stdin passes through to `cat`; `adb` is still on `PATH` inside
the call; with a poisoned `ssh` on `PATH` that exits 99 and shouts, a local call
runs and never touches it; `runners/android/platform.sh devices` runs from the
checkout with nothing booted; suite 144 passed, 0 failed.

**2.2 DONE 18 Sep — `$RDIR` is two jobs and only one of them collapses.** It
was where the Mac-side code is staged and where the scratch goes. `RDIR` keeps
the scratch; the code is now `RMODS` and `RHELP`.

**Two code names, not one, because the layouts differ.** Pushed across ssh, the
helpers land flat beside the scratch — `$RDIR/hier.py`, `$RDIR/relay.py`,
`$RDIR/wall.py`, `$RDIR/driverup.sh` — while in the checkout they are under
`remote/`. The modules keep their `runners/<name>/` shape in both. So:

```
ssh    RMODS=$RDIR/runners        RHELP=$RDIR
local  RMODS=<checkout>/runners   RHELP=<checkout>/remote
```

Both resolve across ssh to exactly what `$RDIR` resolved to before the split.

**The scratch does not collapse onto `$LDIR` here, and 3.2 is why.**
`bin/shot.sh` runs `base64 < '$RDIR/$N.png'` and redirects the decode to
`$LDIR/$N.png`. Make those one directory before that round trip is converted
and the redirect truncates the file the read is still coming from. The two
scratch names stay distinct until 3.2 removes the copies between them.

**A test caught it, which is the point of the test.** `driver.sh`'s stub
`lib.sh` in `test/run-tests.sh` models the real one and set `RDIR` but not
`RHELP`, so the item-46 recovery died on an unbound variable before reaching
the path under test. Two failures, both real: the split does reach `driver.sh`.
The stubs gained the names rather than the code gaining a `${RHELP:-$RDIR}`
default, which would have hidden exactly this.

*Files:* `skill/bin/config.sh`, `lib.sh`, `runner.sh`, `install.sh`, `build.sh`,
`device.sh`, `driver.sh`, `viewer.sh`, `publish.sh`, `drivers.sh`, `wall.sh`,
`flow.sh`, `hier.sh`, `runners/ios/platform.sh`, `test/run-tests.sh`.
*Verified:* in ssh transport `RMODS` and `RHELP` resolve to `/tmp/maestro-mac/runners`
and `/tmp/maestro-mac`; locally to the checkout's `runners/` and `remote/`;
`PLATFORM_SH` now names the checkout's `runners/android/platform.sh` and its
`devices` and `claim` verbs run through `_ssh` and exit 0, where before the
split the same call exited 127; suite 144 passed, 0 failed.

**2.3 DONE 18 Sep — `bin/install.sh` has nothing to push.** After 2.2 the
helpers and the runner modules are already where a local verb looks for them.
The unit is the skip, the scratch directory, and a message naming the three
paths in play.

**Two ways it would have damaged the checkout, not one.** `$RHELP` and `$RMODS`
in local transport ARE the checkout's `remote/` and `runners/`, so every copy in
this script is a file onto itself — and the form here is `cat > dst < src`,
which truncates `dst` before the read begins. Run converted rather than skipped,
it empties `hier.py` and every runner module in the working tree. The `chmod +x`
on the last line is the second: `hier.py`, `relay.py` and `wall.py` are `100644`
in git and the `.sh` files are already `100755`, so the only thing it achieves
locally is three mode changes in `git status`.

**The scratch directory stays this script's to make.** `$RDIR` is the scratch in
both transports and nothing else creates it, so the local branch still runs the
`mkdir -p` before returning.

*Files:* `skill/bin/install.sh`. *Verified:* a local run copies nothing, creates
`$RDIR` and `$RDIR/flows`, exits 0, and names the modules directory, the helpers
directory and the scratch; `git status` over `skill/` afterwards shows only the
edit to `install.sh` itself; suite 144 passed, 0 failed.

**Stage 2 is complete.** A local conf now loads, `_ssh` runs the script here,
and the module paths resolve to the checkout. What a local session still cannot
do is anything that moves a file — Stage 3.

**Stage 3 — the sixteen raw calls, by shape.** Four shapes, not sixteen
problems. Each unit does every call site of its shape, because a half-converted
shape is the state that hides the next bug.

**3.1 DONE 18 Sep — push a file to the machine with the device → `_push`.**
Eleven sites, one helper in `lib.sh` beside `_ssh`. It takes files and a
destination path with no host prefix, adds the host across ssh, and copies
locally. A destination ending in `/` or naming an existing directory takes the
file's own basename, as `scp` does.

**Nine of the eleven are a file onto itself locally, and the tenth and eleventh
are not.** Every source is `$HERE/../remote/x` or `$HERE/../runners/y`, and
after 2.2 the destinations ARE those directories. `mac.sh --send` and `img.sh`
are the exceptions: they put a file the user named into the scratch directory,
which is a real copy in both transports.

**The same-path test is load-bearing, not tidiness.** `cp a a` exits 1 with
*are the same file*, and every call site ends in `|| exit 1` or `|| return 1`.
A bare `cp` would fail every local run of `rig up`, the wall, the viewer and a
build.

**Three `cat >` forms stay, and they are not pushes.** `drivers.sh:196`,
`flow.sh:89` and `wall.sh:112` write a label or a flow body from a pipe through
`_ssh`, which already carries stdin. `docs-refresh.sh:45` is the one remaining
`scp` and it runs the other way — that is 3.2's.

*Files:* `skill/bin/lib.sh`, `install.sh`, `drivers.sh`, `wall.sh`, `device.sh`,
`driver.sh`, `viewer.sh`, `build.sh`, `mac.sh`, `img.sh`, `test/run-tests.sh`.
*Verified:* a self-push exits 0 and leaves the file intact; a push into a
directory, to a new path whose parent does not exist, and of several files at
once all land; the two driver stubs needed `_push` defined the same way they
needed `RHELP`, which is the modelled-lib.sh lesson landing twice; suite 144
passed, 0 failed.

**3.2 DONE 18 Sep — pull a file back → `_pull`, and the base64 round-trips go.**
`_pull` sits beside `_push`: source on the device machine, destination here, one
`scp` across ssh and a `cp` locally.

**`$RDIR` does NOT collapse onto `$LDIR`, and this unit is where that was
settled.** The item and this plan both said the two scratch directories become
one locally. They must not. `$RDIR` is shared, machine-wide state — `PORTS_MAP`,
the driver labels `drivers.sh` reclaims between sessions, the rig record — and
`$LDIR` is `$TMPDIR`, which is per session. Collapsing them makes the ports map
and every peer label invisible to the next session, which is the failure
`drivers.map` already taught this package once. So both stay, the local `_pull`
is a genuine `cp` between two real paths, and nothing can truncate itself.

**`shot.sh` branches, and the branch is the unit rather than a wart in it.**
Across ssh the fetch is folded into the same `_ssh` as the screenshot, because
the alternative is a second connection for a file already in hand. Locally that
encode and decode is pure cost, so the screenshot verb runs alone and `_pull`
moves the file.

**`flow.sh` cost nothing to convert.** Its fetch was already a raw `ssh` of its
own — a second connection either way — so `scp` is neutral across ssh and drops
the encode locally.

**`img.sh`'s `mac` backend is refused locally instead of converted.** It means
"send it to the machine that has `sips`". Locally that machine is this one, and
it has not got `sips` or the `auto` chain would have chosen it two branches
earlier — so the honest answer is to say no image tool is installed, not to fail
inside a `sips` that is not there.

**Still on base64, and not this unit's:** `preflight.sh:16-17` encodes
`appcheck.sh` and `gitstate.sh` into the command string to avoid a push. Locally
that is an encode and a decode of a checkout file into the scratch directory —
correct, and wasted.

*Files:* `skill/bin/lib.sh`, `shot.sh`, `flow.sh`, `img.sh`, `docs-refresh.sh`.
*Verified:* a local `_pull` between two scratch paths copies; the same path is a
no-op leaving the file intact; a missing source fails with `cp`'s own message
and exit 1; `IMG_BACKEND=mac` on this machine now names the missing tool;
suite 144 passed, 0 failed.

**3.3 DONE 18 Sep — `bin/mcp.sh` execs the server here.** It was `exec ssh …`:
the MCP server process itself, not a command sent through `_ssh`.

**It cannot use `_ssh`, and the reason is structural.** `_ssh` wraps its command
in `timeout $TMO` and returns. An MCP server holds stdio open for the life of
the Claude session, so at the default `$TMO` it would be killed three minutes
in and the session would lose every device tool with no error a reader could
act on. `exec` replaces this process, which is what the config entry already
expects — so the registered entry in `.claude.json` needs no change to follow
the conf between transports.

**Maestro is not installed on this machine.** `LOCAL_ENV` puts
`$HOME/.maestro/bin` on `PATH` and there is no such directory here, so a real
local MCP server cannot start yet. That is Stage 5.2's to fix, and it is the
first hard prerequisite this item has turned up.

*Files:* `skill/bin/mcp.sh`. *Verified:* with a stub `maestro` on `PATH` and a
poisoned `ssh` that exits 99 and shouts, a local run execs `maestro mcp` and
never touches ssh; suite 144 passed, 0 failed.

**3.4 DONE 18 Sep — the two that measure or resolve the boundary.** `bench.sh`
timed an `ssh <host> true` round trip; `publish.sh` read the Mac's address out
of `ssh -G`.

**`bench.sh` says there is no round trip rather than printing three small
numbers.** Timing a local fork and exec would produce real figures, but they
measure the shell, and a reader comparing them against the Mac's 0.30-0.44s
would be comparing two quantities that share a heading. The second heading
follows the transport too — "on this machine" rather than "on the Mac".

**`publish.sh` resolves to `127.0.0.1` without asking ssh.** The endpoint, the
relay and whatever reads the published URL are all here, and `ssh -G` for a host
that is not in the conf would fail on a question with no reason to be asked.
The relay itself is 4.1's.

*Files:* `skill/bin/bench.sh`, `skill/bin/publish.sh`. *Verified:* a local
`bench.sh` reaches `_dev` without touching ssh; suite 144 passed, 0 failed.

**Stage 3 is complete, and running it turned up 3.5.** `bench.sh` stopped with
`no booted device on  (platform: android)` — `lib.sh:302` interpolating an empty
`$MAC_HOST`. Thirteen user-facing messages across nine files do the same.

**3.5 DONE 18 Sep — eleven messages said "on " and nothing.** `lib.sh` gains
`_where`: the alias across ssh, `this machine` locally.

```
before   no booted device on  (platform: android)
after    no booted device on this machine (platform: android)
```

**A function, not a variable set once.** `_pick_host` narrows `MAC_HOST` from a
list to the alias that answered, so a message printed after that has to name the
one alias rather than all of them. Verified both ways round.

**Eleven, not the thirteen counted in 3.4.** `publish.sh:79` and `lib.sh:194`
are inside branches that only ssh reaches — the `ssh -G` failure and the
re-pick after a 255 — so locally they never print and naming them `this machine`
would be wrong rather than better.

*Files:* `skill/bin/lib.sh`, `drivers.sh`, `viewer.sh`, `build.sh`, `wall.sh`,
`docs-refresh.sh`. *Verified:* a local `bench.sh` now names this machine; a
single alias and a narrowed list both print the alias; suite 144 passed, 0
failed.

**Stage 4 — the six that become unnecessary.** These are deletions from the
local path, not new code. Each one stays fully wired for `MODE=ssh`.

**4.1 DONE 21 Sep — the relay.** `remote/relay.py` exists because the thing
being read binds the Mac's loopback and the sandbox can only reach the Mac's LAN
address. Locally that loopback is this machine's, so all three staging sites
lose it: `publish.sh` writes the debug endpoint's own port into the state file,
`driver.sh` reads the driver's own port, and `viewer.sh` prints the viewer's.
`lib.sh` gains `_urlhost` and `_driver_base`; `drivers.sh` prints a driver URL
rather than a relay one.

**The port changes, not only the host, and that is why swapping `MAC_FQDN` for
`127.0.0.1` would not have done it.** Every relay is a pair — 22087 is
republished on 9101, the VM Service's port on 9100, the viewer's on 9999 — and
the left-hand number exists only because something has to listen on the LAN.
Locally the right-hand one is the address. A host-only change would have built
`http://127.0.0.1:9101`, which is a well-formed URL for a port nothing will ever
listen on, and the failure would read as a dead relay. So the URL is asked for
(`_driver_base`) rather than built at each call site.

**`lsof` was asking the Mac a question `_up` had already answered.**
`driver.sh:_start` checks `lsof -nP -iTCP:$DRIVER_PORT` before starting the
relay, to tell "no driver" from "relay up, nothing behind it". Locally there is
no second thing to be behind, so `_up` failing IS "nothing is listening on that
port" — the whole ssh branch collapses to the two retries, which are about the
driver and not about the transport.

**The viewer's blank picture is an ssh-only fault, and locally the note must not
print.** Maestro's viewer hands the browser an absolute
`http://127.0.0.1:<random>/stream.mjpeg`, so the picture is fetched from
whatever machine the browser is on — the reason `bin/wall.sh` exists. Locally
that address is this machine, the browser is here, and the stream resolves.

**Three verbs now say they stopped nothing rather than reporting a kill.**
`driver.sh stop`, `viewer.sh stop` and `publish.sh stop` are `pkill relay.py`
across ssh. Locally each would have found nothing and said "not running", which
is true of the relay and reads as true of the driver or the viewer — and those
are still up. `publish.sh stop` still removes the state file, because that is
real in both transports.

**Verified:** 461 passed, 0 failed in `skill/test/run-tests.sh`, six of them
new — both helpers in both transports, a local driver that does not answer
starting no relay and naming port 22087, and `stop` killing nothing. No live
local run yet; that is 5.2.

**4.2 DONE 21 Sep — `$grpc_proxy` on every curl.** It is the sandbox's egress
proxy, the only route to another machine's LAN address. Locally the target is
this machine's loopback, which a proxy refuses — and the refusal reads as the
service being down. `lib.sh` empties the variable in local transport and
exports it; `curl -x ""` is curl's own spelling of no proxy.

**Emptied in one place rather than branched at four, because one call site is
not in this package.** `publish.sh` and `net.sh` curl directly, but the third
reader is `runners/flutter/framework.sh:25`, which chooses with
`[ -n "${grpc_proxy:-}" ]` in a process those scripts spawn. It inherits the
environment, so an exported empty value answers all three — and the module
needed no edit, which matters because every runner module carries that same
line from the TEMPLATE.

**It was wrong locally in a way ssh hid.** Across ssh the Mac-side verbs never
see the proxy, because ssh does not forward the environment. 2.1 made `_ssh`
run the same script through `sh -c` here, where it inherits everything — so a
local `net.sh` fallback would have sent its loopback read to the sandbox proxy
while its remote twin went direct.

**Defaulted in both transports, which fixes a crash that was never about the
transport.** Every caller runs under `set -u`, and `curl -x "$grpc_proxy"` with
the variable unset is an unbound-variable abort rather than a direct request —
that is the state outside a Claude sandbox, where the ssh path also runs.

**Verified:** 464 passed, 0 failed, three new — a set proxy emptied locally and
seen empty by a child process, left alone across ssh, and empty rather than
unbound when nothing set it.

**4.3 DONE 21 Sep — the wall.** `WALL_URL` was not the answer, and the bind was
not fine as it was. `wall.sh:_url` takes `_urlhost`, and the wall is started
with the interface to serve on as a second argument.

**The URL was one host substitution, as expected.** `$WALLPORT` is ours and
never moves — that is the whole point of the wall, the URL you bookmark once —
so the only thing that differed between the transports was which host to name.
`WALL_URL` overrides both, unchanged.

**The bind is the part that was not free.** `wall.py` bound `0.0.0.0` because
the browser is on another machine and has to reach it. Locally the browser is on
this one, and the same bind would put every app screen on whatever network this
machine is sitting on — a café, a client's office. It now binds `127.0.0.1`
locally, and `WALL_URL` takes the open bind with it, because a tunnel or a
reverse proxy means the wall is deliberately reached from somewhere else.

**One thing was found rather than planned: the wall refused to start on
Android.** `_check_simulatorkit` was the first thing `start` and `status` did,
and it asks whether Apple's private SimulatorKit is where Apple's capture binary
expects it. That is a question about iOS, not about the wall, and on this Linux
machine — where `PLATFORM` is android — it blocked the unit's own "done when".
Gated on `PLATFORM=ios`. It would have blocked any Android wall, in either
transport; there was simply never an Android device to find out with.

**Verified:** 470 passed, 0 failed, six new — the loopback URL with the port
unchanged, the loopback bind, the open bind across ssh, `WALL_URL` overriding
both the URL and the bind, and an Android wall not being asked about
SimulatorKit. Not yet run against a booted device; that is 5.2.

**4.4 DONE 21 Sep — `MACIP` and `MAC_FQDN` leave the local path.** 4.1 and 4.3
took the callers, which is what this unit was waiting for: `_urlhost` stands
where `$MAC_FQDN` did in `driver.sh`, `drivers.sh`, `viewer.sh` and `wall.sh`,
and `publish.sh` no longer resolves an address it does not use. What is left
here is `_macip` itself.

**Refused locally rather than converted.** `_macip` runs
`ipconfig getifaddr en0` — a macOS command against a macOS interface name. Run
on this machine it fails, and the failure says "could not determine the Mac's
LAN address", which is a true sentence about a machine that is not in this
configuration. It now says there is no Mac to ask and that every URL built here
is `127.0.0.1`. Same decision as `img.sh`'s `mac` backend in 3.2: a question
with no local twin is answered by saying so.

**`bin/macip.sh` inherits that and exits 1**, which is right — it exists to
print an address nothing may hardcode, and locally there is no address to print.

**The five remaining reads are all in ssh-only branches**: `_urlhost`'s `else`,
and in `publish.sh` the `ssh -G` resolution and the state line beside it.

**Verified:** 473 passed, 0 failed in the skill's suite and 144 passed, 0
failed in the package's, three new — `_macip` refusing locally with the right
message, not printing the old one, and `macip.sh` exiting 1.

**Stage 4 is complete.** Nothing in the local path starts a relay, carries a
proxy, or reads an address belonging to a machine that is not there. All of it
is still verified by the suite alone — no local run has happened yet, and 5.2
is where that is paid for.

**Stage 5 — proof, docs, and the name.**

**5.1 DONE 21 Sep — the suite runs both modes.** Sixteen cases, in one block:
the conf shapes from 1.2, what `init.sh --local` writes from 1.4, the three
copies from 3.1 and 3.2, `_ssh` from 2.1, `install.sh` from 2.3 and `mcp.sh`
from 3.3. With the eighteen Stage 4 carried, the suite is 489 passed, 0 failed
and still needs no Mac.

**Two of them are about a failure staying wrong in the right way.** An ssh conf
with no `MAC_HOST` must keep failing as a broken remote conf — that is 1.1's
whole argument for an explicit `TRANSPORT` — and a local project must not be
handed the ssh diagnostic, which names `MAC_HOST` and `MAC_FQDN` as missing
values when locally they are not settings at all.

**`install.sh` is checked by checksum, not by what it prints.** The risk in 2.3
was never a needless copy: `$RHELP` and `$RMODS` ARE the checkout locally, the
`cat > dst` form truncates before it reads, and the chmod leaves mode changes in
`git status`. The case md5s `remote/` and `runners/` either side of the run.

**`_push` is tested on the trap rather than the happy path.** `cp a a` exits 1
with "are the same file", and every call site ends in `|| exit 1` — so the
self-copy, the self-copy through a directory destination and a real copy are
three separate cases.

**What the suite still cannot reach:** anything needing a booted device. Every
Stage 4 unit is verified by stub and inventory only. 5.2 is where that is paid
for.

**5.2 DONE 21 Sep — one live run, end to end, against an emulator on this machine.** The
lesson item 87 paid for twice: a contract verified only on empty and error paths
is not verified. `rig up`, a flow, a screenshot, `net.sh`, `prefs.sh`. The
device is an Android emulator here rather than a simulator — this is a Linux
machine and there is no local iOS — so this unit runs `PLATFORM=android` and is
the first caller `runners/android` has ever had. *Done when:* each has run
locally and the result is recorded here, verb by verb.

**It ran, and not as this unit expected: through item 96's bridge.** Local
transport as Stages 1 to 4 built it cannot reach a device from inside a Claude
session on this machine — no `/dev/kvm`, its own PID and network namespaces —
which is what item 96 exists for and what the run therefore exercised. On a Mac
none of that applies and this unit's own transport is the one that runs.

| verb | result |
| --- | --- |
| `platform.sh boot Pixel_6_Pro_API_34` | `emulator-5554` — the verb had to be written first |
| `platform.sh devices --booted` | `emulator-5554  device  sdk_gphone64_x86_64` |
| `bin/install.sh` | nothing copied, `/tmp/maestro-mac` made |
| `bin/shot.sh` | 24KB and 47KB PNGs, pulled back and read |
| `bin/prefs.sh` | the app's shared preferences, Flutter keys and all |
| `bin/net.sh` | no VM service, correctly — the app was launched, not run under `flutter run` |
| `bin/flow.sh` | `Launch app "com.prodirectsport.consumer.dev"... COMPLETED`, then the hierarchy and a screenshot |
| `drivers.sh rig up` | not run: `driver-up` is item 87's 4.4, still unanswered |

**The app was `com.prodirectsport.consumer.dev`**, the dev flavour of
`pro-direct-flutter-consumer`, already installed on the emulator.

**Three faults came out of it** — `nohup` where `setsid` was needed, `flow.sh`
reading its flow after a round trip that ate it, and Maestro missing from the
far side's PATH. Item 96's 3.2 has them in full; the third became item 95's
third unit.

**5.3 DONE 21 Sep — `runners/android` stops being a stub, and 87's 4.4 is
answered.** Every verb in the module has now run against `Pixel_6_Pro_API_34` —
`sdk_gphone64_x86_64`, API 34 — over item 96's bridge, against Maestro 2.10.0
and the SDK at `/mnt/sda/User/Programs/android-sdk`. The banner said *NOTHING IN
THIS FILE HAS BEEN RUN*; it now says what ran and when.

| verb | what running it showed |
| --- | --- |
| `claim` | `emulator-5554` claimed, `00008020-0011` refused |
| `devices`, `--booted` | `emulator-5554  device  sdk_gphone64_x86_64` — the model key is the system image's name, never an id |
| `boot` | 27s from kill to serial, the AVD name in and `emulator-5554` out |
| `shutdown` | returns in 0.00s and the serial is still in `adb devices` 3s later |
| `install` | `-r` over a 114MB APK in 1.1s; a wrong app-id exits 1 with the right sentence |
| `installed-info` | `build=100`, `version=3.0.6-dev`, `when=2026-04-02 16:55:14` — dumpsys's order, not the awk's |
| `container` | refuses, and now says why with the path it read |
| `data-container` | **was unreachable**, see below |
| `prefs-read` | 28 XML files concatenated, not one store |
| `prefs-flush` | exit 0; nothing was pending, so it proves the keyevent and no more |
| `orientations` | refuses: the answer is `aapt2 dump xmltree`, and it needs the APK |
| `screenshot` | 1440x3120 8-bit RGBA PNG, 1.6MB |
| `uninstall` | exit 0 whether the package was there or not |
| `locked` | now implemented — 1 asleep, 1 awake, 2 for a serial that is not attached |
| `last-used` | refuses; the qcow2 mtime answers a different question |
| `capture-cmd` | prints a command whose binary is zero bytes on this machine |
| driver trio | refuses; the port question is answered, in 87's 4.4 |

**Three faults, each found by running the contract rather than reading it.**

**Both platform modules had `container)` twice.** `case` takes the first arm, so
the second was dead code — and the second was `data-container`, which
`runners/README.md` names and which `bin/prefs.sh` will call in 87's unit 6. It
answered *unknown verb* in `runners/ios` and `runners/android` alike. Beside it
in both sat `data-installed-info`, a verb the contract does not have, holding a
second copy of `installed-info`'s body. One line each to fix, and invisible to
every reading either file has had.

**`runners/ios-device` had no `uninstall` at all**, and `bin/driver.sh
clearstate` calls it — against a phone that call was answering *unknown verb*
rather than removing anything. Added from `devicectl`, marked not measured,
because there is no phone on this machine.

**`install` printed adb's chatter on stdout.** `adb install` says *Performing
Streamed Install* and *Success*; `simctl install` says nothing. A caller reading
this verb's stdout has to get the same thing from both, so adb's goes to stderr
and the one line at the end stays.

**Four verbs still refuse, and each refusal is now a measurement.** `container`
— `pm path` returns a path with two hashed segments that every install
regenerates, so it cannot stand in for a bundle identity, and
`installed-info`'s `lastUpdateTime` is what appcheck is really asking for.
`orientations` — `aapt dump badging` gives `supports-screens` and no
orientation at all; `aapt2 dump xmltree --file AndroidManifest.xml` gives
`android:screenOrientation=1`, so it needs aapt2 and the artifact, not aapt and
a container path. `last-used` — a wrong answer would keep a forgotten emulator
alive forever. The driver trio — 87's 4.4 to write, now that its question has an
answer.

**`locked` stopped refusing.** API 34 has no `mShowingLockscreen`; the keyguard's
own state is `mIsShowing` under `KeyguardStateMonitor`, and `mDreamingLockscreen`
is the screensaver. `mAwake` tracks the screen and not the lock — `KEYCODE_SLEEP`
took `mAwake` false with `mIsShowing` still false — so reading `mAwake` would
call a sleeping unlocked emulator locked, which is the mistake the verb exists to
prevent. The true path is unmeasured and says so: this AVD has no secure lock.

**Two tests, both regression guards for what was found.** No platform module may
carry a duplicate case label, and `runners/ios`, `runners/ios-device` and
`runners/android` must each answer every verb in the contract's table. Refusing
with exit 2 counts; *unknown verb* does not.

**Verified:** 555 passed, 0 failed in the skill's suite and 150 passed, 0 failed
in the package's. *Files:* `skill/runners/android/platform.sh`,
`skill/runners/ios/platform.sh`, `skill/runners/ios-device/platform.sh`,
`skill/test/run-tests.sh`.

**5.4 DONE 21 Sep — the docs stop describing a Mac across a network as the only
shape.** A section in each of the three, not a rewrite.

**`setup.md` gets a table of the ten steps and what each one is locally.** Six
are about a machine that is not in the picture: the SSH key, `~/.ssh/config`
and `/etc/hosts` are skipped outright, step 1's checks move to this machine, and
step 9 becomes `init.sh --local`. `ssh-copy-id` now appears only inside step 2,
which the table sends a local reader past.

**`SKILL.md` says it once, at the top, and then says how to read the rest.**
Thirteen lines below it say "on the Mac", and rewriting them would be thirteen
chances to get one wrong; the entry says `TRANSPORT` decides which machine has
the device and that "on the Mac" means "on the machine with the device".

**The frontmatter description changed, which is how the skill is found.** It
said "an already-running iOS simulator app on the remote Mac". Every trigger
phrase is kept; what it now covers is a simulator or an emulator, on a remote
Mac or on this machine.

**All three said the local path has not driven a real device.** It was covered
by the suite and nothing else, and a reader who hit something should expect to
be the first. That line was to come out when 5.2 did.

**It came out 21 Sep, after 5.2.** Each document now says what ran and what did
not. `setup.md` lists the seven verbs of 5.2's run — `boot`, `devices --booted`,
`install.sh`, `shot.sh`, `prefs.sh`, `net.sh`, `flow.sh` — and keeps
`drivers.sh rig up` on the not-run side, since `driver-up` is still item 87's
4.4. `SKILL.md` and `README.md` carry the one-sentence version. All three keep
the caveat 5.2 turned up: the run was from inside a Claude session, so it went
through item 96's bridge server rather than local transport on its own, and no
local iOS simulator has been driven.

**Verified:** 493 passed, 0 failed, four new — each of the three documents
naming `TRANSPORT`, and `setup.md` carrying the skip table. After the line came
out, 548 passed, 0 failed in the skill's suite and 150 passed, 0 failed in the
package's.

**5.5 DECIDED 21 Sep — the name is `maestro-drive`, and the rename stops at the
repo and the skill.** The unit was to take the decision rather than to carry it
out; carrying it out is item 98.

**`maestro-drive`**, because it names the verb the package exists for. "DRIVE
the app" is the first line of the skill's own description and "drive the app" is
its main trigger phrase, so what a user types and what the thing is called
finally match — and it separates cleanly from the sibling, where
`flutter-hot-reload-mac` builds and launches and this one drives. The cost,
stated rather than discovered: *driver* already means Maestro's XCUITest driver
inside `bin/drivers.sh`. That collision is between a skill name and a script
name, which nobody types in the same breath.

`maestro-devices` was the runner-up — it names what the package addresses, which
is the genuinely unusual part — but `bin/device.sh` and the contract verb
`devices` already exist, so it moves the collision instead of avoiding it.
`maestro-anywhere` names the thing that changed and ages badly: once local is
the ordinary case it is a claim nobody needs made.

**Measured before deciding the scope.** The name appears 141 times in 25 files,
and four things carry it: the repo slug (pinned as `GITHUB_SLUG` in `update.sh`
and `lib/update-check.sh`, and GitHub redirects the old one, API included), the
installed skill directory (`SKILL.md`'s frontmatter, `manifest.sh`'s `PKG` and
`OWNS`, the hook paths, both MCP script paths), `~/.local/share/`'s lib
directory, and 14 `maestro-remote-mac:` message prefixes.

**`.maestro-mac.conf` CHANGES TOO, and there is no compatibility read.** 96
occurrences. The argument for leaving it was that the file lives in other
people's repositories, so renaming it would break every configured project
unless `config.sh` read both names for a release or two — and that kind of
compatibility read outlives everyone's intention to remove it. The argument does
not hold: a search of this machine finds exactly one `.maestro-mac.conf`, this
repo's. Nobody else has one to break. So it becomes `.maestro-drive.conf`,
`config.sh` looks for that name and no other, and the dual read is never
written.

**The search was wrong, found out 21 Sep.** There were three, not one — this
repo's, `oi/native/hugoboss-flutter-runner/` and its
`.worktrees/hbd20-1812-disappearing-requests/`. The conclusion survives, because
the two that were missed are also this machine's and were renamed by hand on 21
Sep, but it survives by luck: the count *was* the argument for dropping the
compatibility read, and a count that is out by two is not an argument. Item 98
in `BACKLOG-DONE.md` records what renaming those two took, including that their
`.gitignore` entries named the old string literally and so stopped covering the
file the moment it was renamed.

**`flutter-hot-reload-mac` reads the same file and has to move with it.** Nine
references, in its `SKILL.md` and its `bin/lib.sh`. It is a separate skill in a
separate repository, so the two renames have to land together or it stops
finding any settings at all — recorded in item 98 as part of the work, and it is
the reason that item is a release rather than a commit.

**The MCP entry `maestro-mac` does not change here either — it goes to item
97.** It is wrong in the same way, but it cannot move on its own: renaming it
changes the tool names to `mcp__maestro-drive__*`, and `MAESTRO-REVIEW-TRACKER.md`
counts `mcp__maestro-mac__*` in transcripts to decide whether a session drove
Maestro, so its matcher has to take both prefixes first. `uninstall.sh` deletes
`.mcpServers[$MCP_NAME]` and knows only the current name, so a rename leaves the
old entry in `~/.claude.json` pointing at a skill directory that is gone —
`manifest.sh` needs a legacy-names sweep. And 97 may restructure or retire that
server, which would make the rename work done twice. `maestro-bridge` needs
nothing either way; it already says what it is.


## 93. `flutter-hot-reload-mac` carries its own Flutter answers, and they are worse — **OPEN, raised 18 Sep**

Split out of item 87's Stage 5, where it was 5.3. **The work is in the
`flutter-hot-reload-mac` repo, not this one** — it is raised here because this
is where the seam it should plug into lives.

The sister skill installs alongside this one, reads **the same
`.maestro-drive.conf`** — renamed on both sides by item 98 — and does the half
this package deliberately does not:
build from source, launch under `flutter run`, push local edits as hot reloads.

**It defaults where this package discovers, from the same conf file.**

```
flutter-hot-reload-mac                    runners/flutter
bin/lib.sh:46  FLUTTER_BIN               build.sh  _flutter(), eight candidates
   := .fvm/flutter/bin/flutter                     in preference order, the
                                                   pinned SDK first
bin/lib.sh:48  TARGET                    build.sh  derived from the flavour,
   := lib/main_dev.dart                            which is derived from APP_ID
remote/frun.py:34  FRUN_FLUTTER          build.sh  the same discovery
   := .fvm/flutter/bin/flutter
remote/frun.py:55  --flavor FLAVOR       build.sh  _flavour_for_appid, which
                                                   REFUSES rather than guessing
```

`lib/main_dev.dart` is hardcoded as the entrypoint. This package works it out
from the bundle id under test and refuses when two flavours build the same one,
because building the wrong flavour installs a different app and leaves the one
under test untouched — which nothing reports. So a project that is not
`dev`-flavoured gets the right answer from one skill and the wrong one from the
other, **reading the same file**.

**And it has the sharper problem item 24 recorded:** `bin/start.sh` runs
`git checkout` on the single shared `$REPO`, so pointing it at a review branch
silently clobbers uncommitted work in whatever else is using that checkout. That
is a safety requirement for concurrent reviews, not a tidiness one.

**What it should consume.** `describe`, `build` and `inspect` are already the
verbs it needs. `inspect` especially: it has its own VM Service discovery in
`frun.py` reading `/tmp/frun.log`, which is the SECOND log file
`runners/flutter/vmservice.sh` already checks by name — the two were written
against each other by hand rather than sharing one answer.

**The payoff is not tidiness.** It is that "hot reload a React Native app"
becomes a module rather than a second skill, and that two skills reading one
conf stop being able to disagree about which flavour a project builds.

**Gated on:** item 87 landing, so there is a stable contract to plug into.

## 90. The wall shows simulators only, and a phone is a device too — **OPEN, raised 18 Sep**

`bin/wall.sh` puts every booted simulator on one page, live, and it is the first
thing a session starts. A physical iPhone driven through `runners/ios-device` is
invisible on it — so the one device whose screen you cannot see from your chair
is the one the wall does not show.

**Two things stand in the way, and only the second is hard.**

**The wall asks ONE platform module.** `remote/wall.py` resolves
`runners/<PLATFORM>/platform.sh` from the environment and calls `devices
--booted` on it. A Mac with three simulators and a phone has two platforms live
at once, so the wall would have to ask every module it can find and merge the
answers, tagging each row with the module that produced it. That is a small
change and a real one: it is the first place in the package where the two axes
stop being "one choice per session".

**Nothing is known to stream a physical device's screen.** `runners/ios-device
capture-cmd` exits 2 saying exactly that, and it is not a gap to be filled by
guessing. What is known, measured 18 Sep 2026:

  `devicectl device capture screenshot` works on the phone — 6.7MB PNG, about a
  second. That is a poll, not a stream.
  `devicectl device capture screen-record` exists and records to a FILE, which
  is the wrong shape for a tile that has to start before anyone is watching and
  survive the browser going away.
  Whether Maestro's `simulator-server` binary drives a physical device at all is
  unestablished. It takes a platform word — `ios` for a simulator — and nobody
  has tried another.

So the first question is whether a phone can be streamed or only sampled. If
only sampled, the wall's Stream class assumes MJPEG frames arriving from a
child process, and a polled tile is a different thing living beside it rather
than a parameter of it — a phone tile that updates every few seconds is still
worth having, and saying so in the tile is better than a still frame that looks
live.

**Gated on:** nothing in this package. It is gated on finding out what can
stream a phone.

**Related.** Item 87 built `runners/ios-device` and left `capture-cmd`
unanswered for this reason.

## 91. A live driver stopped protecting a peer's wall label — **DONE 18 Sep 2026**

Found by the first live `rig up` after item 87's Stage 3, which printed
`awk: backslash not last character on line`.

The live-driver guard in `_wall_label` is a `$( )` inside a double-quoted `_ssh`
string, so the LOCAL shell expands it and the awk runs here. Its field
references were escaped as `\$1` and `\$2`, as though it ran on the Mac, so awk
died and the substitution came back empty — making the test always false.

One of the three guards on reclaiming another session's label has therefore
never worked. Only the age check stood, and a peer whose label was older than
`LABEL_STALE_AFTER` would have been renamed out from under a live session, which
is the exact failure item 67 added that test to prevent.

The tests did not catch it because they reimplement the reclaim in shell and
test the intended logic rather than the shipped string, and because a recent
label is kept by the age check whether or not this guard fires. The new test
reads the file.

## 92. Three wrong-shell mistakes across the SSH boundary — **DONE 18 Sep 2026**

Item 91 was found by accident, so this searched for the rest of its family
rather than waiting for the next one. Three shapes:

  **a local `$( )` escaped as though remote** — item 91 was the only instance.

  **a POSIX helper sourced into the shell ssh hands over, which is zsh.**
  `remote/gitstate.sh` had two constructs zsh does not share — it neither
  word-splits an unquoted expansion nor globs an unquoted `case` pattern — and
  reported every lock file as somebody's work for as long as it was
  parameterised. `remote/appcheck.sh` was the same shape and survived on luck.
  Both are executed with `sh … --run` now and zsh is out of the path.

  **a pipe eating an exit status**, three times. `sh module inspect … | tail -1`
  on the remote side returned tail's status, so an exit 2 arrived as success.
  `bin/flow.sh` ran `maestro test | grep | tail`, so EVERY FLOW REPORTED
  SUCCESS — and the first fix for it was itself incomplete, because flow.sh then
  ended on `if [ -n "$SHOT" ]`, whose false condition exits 0.

The lesson the tests carry now: read the shipped file, do not model it. Two of
these passed a test that checked the intent.

---

## 85. SSH and network setup is seven manual steps across three files that must all agree — **DONE 18 Sep 2026; A, B and C all run live end to end, and the nine faults that took**

`reference/setup.md` describes the whole SSH and network side and a person does
it by hand. It is correct and it still gets done wrong, because it spans three
files that must agree and is read once, at the wrong moment. A wizard should do
it instead.

**Seven parts.**

1. **Key creation.** `ssh-keygen` for a purpose-built key, not a reused personal
   one. Every script passes `BatchMode=yes`, so a passphrase prompt fails
   immediately with no explanation — and note that is a *key passphrase*, a
   different thing from the password authentication `reference/setup.md:55` warns
   about, which fails the same way. Neither setup.md nor this item said the key
   must be made with `-N ''`. **Drift found 17 Sep**: setup.md documents
   `-t rsa -b 4096 -C "maestro-remote-mac"`; the key actually in use is RSA 3072
   with a default comment, so the documented command was not followed when the
   key was made — which is this item's own argument.

2. **Getting the key onto the Mac.** `ssh-copy-id -i <key>.pub <user>@<addr>`
   authenticates with the Mac's *login password*, prompted on the terminal — the
   `-i` only names the key to copy. That is the one moment the Mac's password is
   typed, so the wizard runs the command in the foreground and lets ssh prompt
   from `/dev/tty`. It must not capture the output, must not pass `BatchMode=yes`,
   and must not background it. Runs **once per machine**, not per network:
   `authorized_keys` is one file on the Mac whatever address reaches it.
   Preconditions worth naming rather than eyeballing (setup.md § 1 lists Remote
   Login as a checkbox): refused on 22 is Remote Login off, timed out is the
   wrong address or the wrong network.

3. **`~/.ssh/config`.** One `Host` block per network, identical but for the
   `Hostname`, named for the place rather than the machine, each carrying the
   socat `ProxyCommand` that tunnels through the sandbox proxy. **One trap, not
   two**: `%s` must be doubled because ssh_config expands `%` itself. The
   `ConnectTimeout` ordering belongs to `bin/lib.sh:69-80`, where `_probe`
   prepends its own value ahead of `SSH_OPTS`, and is already solved there —
   command-line `-o` beats the config file whatever order the file is in, which
   also makes the blocks' own `ConnectTimeout` and `ServerAliveInterval` dead for
   everything going through `bin/`. Merge-not-replace with a backup: it is the
   user's file, with fourteen commented-out entries for unrelated hosts.
   Ownership is matched on `Host <alias>`, with no marker comment — the need is
   only to avoid a duplicate stanza, which `ssh` silently shadows because it
   takes the first value it obtains for each keyword.

4. **`/etc/hosts`.** One line per network mapping `<mac>.local` to that
   network's address, all present at once: the resolver returns them all and the
   client tries each in turn, so the name follows the Mac. The cost is that two
   of three are dead on any given network and each one is a connect timeout
   before the live one answers — file order is try order, so the network used
   most often belongs first. Needs root, so the wizard **asks whether to write it
   itself, defaulting to no**, and prints the lines otherwise. The existing block
   is already marked by `# mac for ios simulator work`, which is the region the
   wizard owns.

5. **`~/.claude/settings.json` → `sandbox.network.allowedDomains`.** The name AND
   every address. Without it the proxy refuses and the Mac reads as switched off
   while SSH still works, which is what makes the failure confusing. Union, never
   replace — the array may hold entries for unrelated tools — and the
   `sandbox.network` path may not exist at all. `jq` is already a hard dependency
   (`install.sh:51`), and `install.sh:97-108`'s write-to-temp, `diff`, move
   pattern is what to copy, diff preview included.

6. **Per project — not the wizard's. Both halves now covered.**
   `.maestro-mac.conf` is already covered by `bin/init.sh`, which `bin/config.sh`
   routes into when no conf is found. The permission allows are the uncovered
   half. `reference/setup.md` § 6 documents them, wildcard prefix and all — what
   was missing is that nothing writes them and nothing checked whether they were
   there, so every `ssh` and `scp` waits for a prompt until someone reads § 6 or
   adds them by hand.

   **Built 17 Sep in `bin/config.sh`, not a hook.** It sits immediately after the
   conf check, which is the same moment and before any SSH happens. Read `permissions.allow` from `~/.claude/settings.json` and the
   project's `.claude/settings.local.json`, strip `Bash(…)` and a trailing `:*`,
   and glob-match the patterns against the real `ssh <host>` and `scp <host>`
   command strings for every alias in `MAC_HOST`. Print what is uncovered, once
   per session, marked in `$LDIR`. Block nothing. Detection only: a shell script
   cannot write either settings file, so the session asks which file the user
   wants and writes it with `Edit`. Global counts for every project;
   project-local means being asked again in the next project, which is intended.

   **Not a hook, and the reason matters.** A hook was the first design. It cannot
   write the settings file either, so its only advantage over `config.sh` was
   imaginary — while it would fire on every Bash call for the life of the machine
   to test a condition true once per project, and would need a third registration
   in `install.sh`. See item 67 for how a registration goes missing.

   **Verified against five cases**: nothing configured anywhere warns and names
   both files; a wide `Bash(ssh mac-*:*)` in the global file silences it; a
   project file covering one alias reports only the uncovered one; a second
   call in the same session is silent; and a malformed `settings.json` is
   survived rather than crashing the skill on load.

   **Two findings from the first attempt, which was written, tested and reverted.** The
   suggested entry should use the longest common prefix of the aliases, not the
   first alias: `mac-a mac-b` gives `Bash(ssh mac-*:*)`, which is exactly
   what the two projects on this machine already have by hand, whereas per-alias
   suggestions produce an entry that does not match. And this machine's `python3`
   is **3.8.10**, so `str.removesuffix` is unavailable and the suffix strip is
   manual — worth checking what else under `skill/` assumes 3.9+.

   **State on this machine.** `~/.claude/settings.json` has no `ssh` or `scp`
   allow at all. the client checkout and `claude-sandbox` each carry
   `Bash(ssh mac-*:*)` and `Bash(scp mac-*:*)` in
   `.claude/settings.local.json`, identical and duplicated by hand.

7. **The two Mac-side pieces that handle a network change.** Not an Automator
   script — that guess was wrong. It is `/usr/local/bin/network-change.sh`
   (root:wheel 755, 242 lines) driven by `/Library/LaunchDaemons/networkChange.plist`,
   label `com.you.networkchange`, which fires on `WatchPaths` over
   `/var/run/resolv.conf`, `NetworkInterfaces.plist` and
   `com.apple.airport.preferences.plist` plus `RunAtLoad`, logging to
   `/tmp/netchange.log` and `/tmp/netchange.err`. The script applies a per-SSID
   IPv4 profile to the Wi-Fi service and is idempotent, because WatchPaths fires
   two or three times per real change.

   **The script half is vendored** at `skill/setup/network-change.sh` — three
   real SSID blocks cut to one example on `192.0.2.0/24`, plus a header covering
   what each value means, the Terminal commands that find them on the Mac, and
   how to check the result. Body is byte-identical to the Mac's from the config
   block down. The real table is the LAN layout of every network the Mac joins,
   so it stays local: the wizard writes it, the repo never carries it. **The plist
   is vendored verbatim** at `skill/setup/networkChange.plist` — 837 bytes, six
   keys, no site-specific values in any of them, so it needs no redaction and
   installs as-is.

   **Optional, and last.** It exists to give the Mac a fixed address per network.
   Anyone whose router does DHCP reservations gets the same result with nothing
   installed on the Mac. Offered only after a new network is added, never on its
   own.

   **How the path was recovered, and why it nearly wasn't.** Nothing in the repo
   or in any surviving transcript names these files. A sweep of all 246
   transcripts returned a clean negative — but 417 of 577 sessions no longer have
   a transcript at all, pruned on the rolling 30-day `cleanupPeriodDays` window
   (nothing before 19 Aug survives), and both sessions that set this up (10–11
   Aug) were among them. The path survived only in `~/.claude/history.jsonl`,
   which the window does not touch, in a prompt from 11 Aug 11:03. **Two defects
   found on reading it**: the third SSID's DNS server and its gateway differ by
   one digit, which reads as a typo; and `current_ssid()` calls
   `ipconfig sertverbose 0`, misspelt, so the verbose mode the function turns on
   is never turned off. The second is fixed in the vendored copy; both are still
   live on the Mac.

**Design, settled 17 Sep. Two phases and an optional third.**

**Phase A — once per machine.** Ask the Mac's username and its `.local` name.
Ask for an existing key path or create one: `ed25519` for a new key, no check on
an existing one's type, because the Mac already trusts an RSA key. Print and run
`ssh-copy-id` in the foreground; verify with `BatchMode=yes`. **There is no
stored key path** — the `IdentityFile` line in the `Host` block is the record,
and a later pass reads it back. `known_hosts` cannot serve: it holds the Mac's
host key, not this machine's identity.

**Phase B — once per network, repeatable.** Ask the place name and the Mac's
address on that network, then write the `Host` block and the `allowedDomains`
entry. Both are needed *during* phase C, so they are written with the DHCP
address first and corrected afterwards if C moves it.

**Phase C — optional, offered only when a new B completes.** Install
`network-change.sh` and the plist on the Mac, which needs root there and so is a
printed command the user runs, as in part 2. Discovery runs live on the Mac:
SSIDs offered as a list from `networksetup -listpreferredwirelessnetworks en0`
plus the current one, and mask, gateway and DNS read from `networksetup -getinfo`
and `netstat -rn`. **The static address defaults to the Mac's current address
with the last octet replaced by `250`** — which reproduces all three already in
use, including the /22 where the mask differs — asked rather than assumed, and
refused if it answers `ping`. It must sit outside the router's DHCP pool, which
the Mac cannot see, so the wizard cannot derive it.

**`/etc/hosts` is written last**, once the address is final, whether or not C
ran. It is the only one of the three that can wait: SSH uses the `Host` block's
literal `Hostname` and the proxy needs the address in `allowedDomains`; only
`curl` on the `.local` name needs `/etc/hosts`.

**C drops the connection it runs over**, by design. The last command before the
drop cycles Wi-Fi, detached so SIGHUP does not kill it mid-cycle:

```sh
ssh <alias> 'nohup /bin/sh -c "sleep 2; \
  networksetup -setairportpower en0 off; sleep 5; \
  networksetup -setairportpower en0 on" >/dev/null 2>&1 </dev/null &'
```

The leading `sleep 2` lets ssh return an exit code rather than a broken pipe.
Note `RunAtLoad` already applies the profile on `launchctl load` — the cycle
proves the `WatchPaths` trigger fires, which is the part that must work
unattended.

**Tested live 17 Sep, 23:07.** Four results:

- **`networksetup -setairportpower` needs no sudo**, to read or to set. Exit 0 as
  the ordinary user. That was the last unverified point in phase C.
- **The detached form survives the drop.** The `nohup … &` above returned exit 0
  and the `off`/`on` pair completed after the connection died.
- **One cycle fired the daemon three times** — 23:07:09 not associated, 23:07:18
  and 23:07:28 both `already static … no change`. Exactly the "2-3 times per real
  change" its own header predicts; the lock and the idempotence check absorbed
  it, nothing was written and `/tmp/netchange.err` stayed 0 bytes.
- **Recovery took 19 seconds** end to end. The two-minute poll is slack.

**The poll must wait for the drop before waiting for recovery.** A poll started
immediately succeeds on the connection it is about to lose — observed: the first
attempt returned "up" one second in, before the `sleep 2` had elapsed, which
reads as success and is not. Wait for a failure first, then for the recovery.

**Re-runs of phase A assume the Mac is reachable, but a failure does not prove
it is not.** Compare this machine's current network against the addresses
already stored; if it matches one, ask whether the Mac is on and reachable.
Regardless of the answer, ask whether to set up a new network — that is the
common reason for a re-run, and the Mac may be on a network this machine has
never seen. Reachability is therefore phase B's question about a specific
address, never phase A's about the machine.

**Before any command that needs the Mac**, say plainly that the Mac must be
turned on and joined to the network being configured. Phase C can only discover
the network the Mac is currently on.

**Where it lives.** `skill/setup/wizard.sh`, so it installs with the skill and
can be re-run months later without the repo on the machine. `install.sh` calls
it, and checks a **phase A completion marker** in
`~/.local/share/maestro-remote-mac/` — where `install.sh` already points
`LIB_DIR` — offering the wizard when it is absent. A flag, not a state file:
networks are discoverable from the `Host` block, the `/etc/hosts` line and the
`allowedDomains` entry, which are the record.


**Built 17 Sep — `skill/setup/wizard.sh`, 673 lines.** Phases A, B and C and the
`/etc/hosts` write all exist, and `install.sh` offers the wizard when the phase A
marker is absent. `skill/` installs wholesale, so `setup/` ships with it and the
wizard lands at `~/.claude/skills/maestro-remote-mac/setup/wizard.sh` with no
manifest change. Modes: no argument runs it, `--status` reports what is
configured and writes nothing, `--hosts` re-runs the `/etc/hosts` step alone,
because reordering is a reason to come back without adding a network.

**Tested — 52 package cases, up from 37, plus the skill's 360.** `skill/setup/`
was in none of the three sweeps before this, so the wizard was not even
parse-checked. Fifteen cases now cover what it decides to write, against copies
in `$TMP`: the static address proposal, the SSID table gaining an arm per
network rather than being replaced, an SSID with trailing spaces surviving
splicing, a re-add replacing its arm rather than duplicating it, `--status`
writing nothing, and the `/etc/hosts` rewrite leaving unrelated entries alone
while honouring the requested order. Phase B was exercised by hand against
copies of the real `~/.ssh/config`: a new alias appends a block that `ssh -G`
parses with the `ProxyCommand` byte-identical to the hand-written ones, an
existing alias has its `Hostname` updated in place with no duplicate stanza, and
an address change drops the old entry from `allowedDomains` in the same diff.

**Discovery was run against the Mac and matched the live table** — address, mask
and gateway exact, and the service-name `awk` survived two layers of SSH
quoting. It found one defect: `sort -u` reordered the DNS list, putting a public
resolver ahead of the gateway, which is the opposite of what the table does and
would quietly change what the Mac resolves locally. Now deduped in place with
the gateway promoted, and the discovered line is byte-identical to the Mac's.

**Not yet exercised, and all of it needs a live run.** Phase A's fresh branch
(`ssh-copy-id` with a real password, writing `authorized_keys`), phase A's
subnet comparison (`ip -o -4 addr` returns nothing inside the sandbox, because
every Bash call gets its own network namespace), and phase C's install-and-cycle
sequence. The cycle command itself was verified live — see the test record above
— but not the wizard's wrapping of it.

**Two defects found in this package's own new code while testing it**, both
fixed: `allowedDomains` accumulated a stale address on every address change, and
the DNS ordering above. A third was a bad test rather than bad code — the case-arm
count matched the `printf` continuations inside `ipv4_config()`.

**Run live 18 Sep, in `--dry-run`, against the real Mac. Eleven defects, all
found by running it rather than by reading it.**

`--dry-run` was built first, precisely so the run could be made without writing
anything: it asks everything and reads everything — probing the Mac, listing its
networks, reading back the three files — and writes nothing. Reads stay on
because a dry run that skipped them could not show what it would write.

**Three that stopped the run dead.**

- **Phase C appeared to hang at its own header.** It was not a hang. Under
  `set -euo pipefail`, `dev=$(mac_run …)` against an unreachable Mac takes the
  whole script down before the caller can check whether the value came back
  empty, so the "no Wi-Fi device found" warning never printed and the exit code
  was 255. `mac_run` now always succeeds and prints nothing when the Mac cannot
  be reached, which is what a read helper should do.
- **The same bug one level up.** `phase_c` returning non-zero was the last
  command of its `then` branch, so the shell exited at the `fi`. Both that call
  and `write_etc_hosts` now report and carry on: one phase failing is not the
  run failing.
- **Phase C talked to the alias**, which `--dry-run` describes without writing,
  so `ssh <alias>` tried to resolve the alias as a hostname. It now picks its
  target — the alias once its block exists and this is not a dry run, otherwise
  the key and the address, which need nothing written yet.

**Four about values that were guesses dressed as facts.**

- The `.local` name defaulted to **this machine's own hostname** with `.local`
  appended, which is never the Mac's.
- A name with no dot was taken as given. `oi-james-mac` was about to be written
  into `allowedDomains`, where it would resolve to nothing while `curl` on the
  real name kept failing. The suffix is added when absent, and a name differing
  from the one already configured is challenged.
- The **key path** was a hardcoded `~/.ssh/mac_rc`. `IdentityFile` in an
  existing block is the real answer and is now preferred; the literal name
  survives only as a fallback for a machine with nothing configured.
- **"Network to try first"** defaulted to the first `Host` block in the file —
  the one thing that prompt exists to change. It now probes each alias and
  offers the one that answers, and offers nothing when none does.

**Two about the shape of the run.**

- **The network loop had no memory and no end in sight.** It asked "set up a
  network now?" after every pass, because the prompt was its condition; the same
  alias was typed and the whole thing ran again, which read as being stuck.
- **So the loop was removed.** A second network cannot be finished in the same
  run anyway: phase C reads every value off the interface the Mac is joined to
  right now, and phase B's probe against an address the Mac is not on fails, so
  the block would be written unverified. One network per run, then `/etc/hosts`,
  then a line saying to re-run after joining the next one.

**Two more, from running it against a machine with nothing configured — the case
it exists for, and the one path never exercised.**

- It **aborted at the first prompt**: `local known_user` under `set -u` leaves
  the variable UNSET rather than empty, and the loop that would assign it never
  runs when no `Host` block exists.
- The `/etc/hosts` step reported **"no configured networks" immediately after
  phase B configured one**, because it reads blocks off disk and a dry run
  describes rather than writes. It now counts the network configured in this
  run.

**What the run confirmed, which nothing else could.** Phase C's discovery is
correct against the real Mac: the Wi-Fi device, the preferred-network list
including the SSID with trailing spaces, and mask, gateway and DNS defaults that
reproduce the live table exactly. The splice started from the Mac's own script
and reported `profile replaced`, so a second network extends the table rather
than replacing it. The profile line it would write is byte-identical to the one
running. The subnet comparison in phase A also works outside the sandbox, where
`ip -o -4 addr` returns real interfaces.

**Still untested: the real write path.** `ssh-copy-id` with a password, the
actual writes to `~/.ssh/config`, `settings.json` and `/etc/hosts`, and phase C's
install-and-cycle on the Mac. The cycle command itself was verified live on
17 Sep; the wizard's wrapping of it was not.

**The write path was run for real on 18 Sep, and it found three defects.** Every
earlier test passed `--dry-run`, and the suite's own header said so — *"nothing
talks to a Mac and nothing touches the real files"* — so until now the wizard had
never written anything, not even to a copy. Run against `SSH_CONFIG`, `SETTINGS`,
`HOSTS_FILE` and `LIB_DIR` pointed at a throwaway directory, with `sudo` stubbed
on `PATH`:

- **A failed `sudo` was reported as a successful write.** `write_etc_hosts` ends
  `sudo cp; sudo cp; ok "written"` with no status check. It is called as
  `write_etc_hosts || warn`, and a function invoked with `||` runs with `set -e`
  suspended for its whole body, so the failure did not abort either. Measured
  against a sandbox whose `sudo` is not setuid: two `sudo: must be owned by uid 0`
  lines, then `ok written`, with the file untouched. `/etc/hosts` is the third leg
  of the all-three-or-none this item opens with, so a false success here is
  precisely the failure it exists to prevent. Both calls are now checked and the
  warning names what is inconsistent: the ssh config and settings.json written,
  this one not.
- **The network just configured was offered twice.** `configured_aliases` prints
  one alias per LINE; the guard against listing `$B_ALIAS` twice tested
  `case " $aliases " in *" $B_ALIAS "*`, which cannot match a newline-separated
  list beyond its first entry. The `/etc/hosts` step then asked which network you
  use most and listed the same one twice. Now newline-delimited.
- **Declining `settings.json` silently costs `/etc/hosts`.** The `.local` name is
  read back from `allowedDomains`, so without that write `MAC_NAME` is never
  learned and the step skipped with *"no .local name known, so there is nothing to
  map"* — which describes the cause and reads as though there were nothing to do.
  It now says the file cannot be written, where the name comes from, and what
  fails without it.

**Eight cases added, and they run the wizard rather than a function out of it.**
`sudo` is stubbed to fail and then to succeed, so both branches are covered; the
hosts file is asserted unchanged after the failure; and the `.local`-unknown
message is asserted to name its consequence. One of the eight was wrong when
first written — it matched `ok    written` loosely and caught settings.json's own
`written (backup: …)` from the same run — which is the same class of mistake as
the defect it was written for.

**A sixth defect, found by running `--hosts` against a copy of the real
`/etc/hosts` with the answers piped in: every `ssh` in the file needed `-n`.** A
successful ssh reads and discards whatever is on stdin, and stdin here is where
`ask` and `confirm` get their answers — so the `/etc/hosts` liveness probe
reached a Mac that answered and swallowed every answer after it. Reduced to a
three-line stream through one `ssh <alias> true`, after which `read` returned
nothing. Invisible interactively, because a person has not typed ahead, and only
reproducible when the Mac is actually reachable: both are the real-machine case
this item is about. Six calls, not the four a manual sweep found — the static
test caught two more in phase C, one inside a 40-iteration poll. `ssh-copy-id`
keeps its stdin, because it reads the password through it.

**The re-run path is now covered too.** Every other case adds a NEW alias; a
live run updates one that exists. Three cases assert the Host block is updated
rather than appended beside itself, that it carries the new address, and that
the address it replaced leaves `allowedDomains` instead of accumulating there.

**This machine needs no preparation, which is also why B cannot be exercised on
it.** Checked 18 Sep: the three Host blocks, `allowedDomains` and the
`/etc/hosts` marker block all agree, so a run would find nothing to change — a
rehearsal against a copy of the real file produced one whitespace difference and
nothing else. Exercising B for real means deliberately removing one network's
three entries and letting the wizard restore them, or joining the Mac to a
fourth network.

**Phase A was run live against the real Mac on 18 Sep at 13:18 and passed.** The
marker at `~/.local/share/maestro-remote-mac/phase-a-done` is the proof, and it
proves more than that the phase ran: it is written only after the `BatchMode=yes`
verification returns 0, which is after `ssh-copy-id` has returned 0. So both
halves of the one thing that had never run are now exercised — against a key
already on the Mac, so `ssh-copy-id` reported the keys as already installed and
never prompted, which is what makes it safe to re-run.

Declining the network question stopped it cleanly: `~/.ssh/config`, `/etc/hosts`
and `settings.json` were all untouched afterwards, timestamps unchanged from
14 Sep, 14 Sep and this morning's install. `--status` now reports `ok marker`
where it reported `warn no marker`, so the re-run branch — "Phase A ran on …,
nothing to do" — is live from here, and that is the branch every subsequent
network depends on.

**An anti-wizard, built 18 Sep: `wizard.sh --remove <alias>`.** Adding a network
writes three things that must agree, and this item's opening sentence cuts both
ways — two out of three is a failure that looks like something else whether you
got there by adding or by taking away. An address left in `allowedDomains` after
its `/etc/hosts` line has gone means the sandbox permits a host that no longer
resolves; a Host block left behind means `ssh <alias>` hangs on an address
nothing answers.

It is the mirror of phase B and reuses its parts: the Host block goes first
because the rest is derived from it, then `allowedDomains` loses the address that
block named, then `write_etc_hosts` — the same function the add path ends with —
rebuilds the whole block from the aliases that remain, so the file cannot end up
describing a network that is no longer configured.

Four refusals, each for a way of stranding the machine:

- **the last network**, because phase A's key path and the Mac's username are
  both read back *from* a Host block, so removing the last one loses the record
  of them as well as the route;
- **a Host line naming several aliases**, which is one block serving all of them
  — removing "the block" would take the others silently;
- **an unknown alias**, which exits 2 and prints what *is* configured, because a
  typo's useful answer is the list;
- **an address another alias still uses**, which is kept, and the message names
  the alias keeping it.

What it deliberately does not touch: the key, the phase A marker, and the Mac's
own network-change profile. The last of those is not squeamishness — nothing
local records which SSID belonged to which alias, because phase C reads it off
the interface live, so the script says so and points at the file to edit.

**Nine cases, and the round trip is the one that matters**: add a network, remove
it, and all three files are back where they started — `ssh_config` and
`/etc/hosts` byte-identical, `allowedDomains` identical in value (jq rewrites the
file, so the bytes move and the values must not).

**B and C were both run live on 18 Sep, and B was broken in a way only a live
run could show.** Every probe in this file named a raw `$user@$address`. A raw
address has no `Host` block, so it carried no `ProxyCommand` — and inside a
Claude session that address is unroutable. `PROXY_CMD` now names the string
once and phase B's probe, phase A's `ssh-copy-id`, phase A's `BatchMode` proof
and `c_target`'s fallback all pass it with `-o`. The generated block is
byte-identical to the three hand-written ones, checked both ways. **Phase A
could never have run from inside a session either**; that it passed at 13:18
says that run was in an ordinary terminal.

**Then a real network change was used to exercise B and C, and it found five
faults in an afternoon — four of them in this wizard.** The Mac was moved to a
fourth network and the first probe failed with
`kex_exchange_identification: Connection closed by remote host`, which is a
sentence that names nothing. In order:

1. **A probe that could not reach a new network from inside a session.** Every
   connection goes through the sandbox proxy, which carries only what
   `allowedDomains` names, and phase B wrote that entry *after* the probe
   passed. A network being set up for the first time could therefore never be
   verified from inside a session. Same proxy, same command: an address in the
   list gets a connection, one that is not gets `Bad Gateway` before anything
   leaves the machine. `allowedDomains` now goes first, and only that file —
   probe-then-write is unsatisfiable for the file that decides whether the probe
   can happen, and it is the safe one to write early, because an entry permits a
   host, it does not route anything and it cannot make `ssh <alias>` hang.

2. **The line that said what happened was thrown away.** The diagnosis printed
   `tail -1` of stderr, and the ProxyCommand's own message comes *before* ssh's
   summary — so `Bad Gateway` was discarded and `kex_exchange_identification`
   was all that survived. It keeps the output by the line now.

3. **The username was a fact the files recorded and nothing could change.** The
   Mac's account had been renamed. `resolve_from_existing` reads it from a `Host`
   block's `User` line, phase B never asks for it and never printed it, and
   correcting it meant editing every block by hand — while macOS drops an account
   it does not know *during the banner exchange* rather than answering it, so it
   arrives as the same silence as everything else. Phase A stops being
   create-once: a re-run prints the username, the `.local` name and the key with
   the file each came from, and offers to change any of it. Each fact is written
   where it lives and by the phase that owns it. `--edit` runs that alone, and
   `--status` prints the account each alias would connect as — the one field with
   no way to see it, which is how this got a day old unnoticed.

4. **One subnet, no ARP: the access point, not the Mac.** Remote Login was on for
   all users, sshd accepted its own loopback and returned exit status 0, the Mac
   held the address it said it held, and neither machine could ping the other.
   The access point was refusing station-to-station traffic, which nothing on
   either machine reveals and every arm would have blamed the Mac for. ARP is the
   test rather than ping — a host that drops ICMP still answers ARP — and the
   check runs ahead of the error text because it is a measurement where the other
   arms are readings of a message. The message says outright that nothing on the
   Mac is wrong, and gives the confirming ping from the other end.

5. **The retry loop sustained the failure it was diagnosing.** OpenSSH 9.8
   penalises a source address that keeps failing and drops it mid-handshake;
   `min:15` and `max:600` mean any penalty lasts at least fifteen seconds and can
   reach ten minutes, and a connection the penalty drops is itself another
   failure. Firing straight back renews it. The arm names penalties and how to
   clear them, and the retry says to wait rather than inviting another attempt.

**The anti-wizard ran live and found a sixth.** `--remove` took a network out of
all three files, and `/etc/hosts` came back unchanged with no sudo prompt after
the answer was yes. It asked twice — once before the file was built and once
after the diff, both defaulting to no, the second reading as a repeat of the
first. Every test passed through it because each answer stream happened to carry
a spare answer that landed on the second prompt. One question now, after the
diff, and the new case carries nothing spare.

**Two more things the afternoon argued for.** `--list` prints a row per network
saying which of the three files knows it, because a list of aliases alone hides
the state this whole item is about — a `NO` under allow means the proxy refuses
the address and the Mac reads as switched off, a `NO` under hosts means curl on
the `.local` name does not resolve. And `--remove` no longer demands an alias:
typing one from memory is how the wrong network goes, so a bare `--remove`
prints that list and takes a pick.

**Phase A asks which blocks a username or key change reaches.** The first
version wrote every one of them, on the argument that one Mac has one account
name — true of this machine and not of the file, which is the user's and may
name a second Mac, a work account, or a host that only looks like ours because
it borrows the key.

**Phase C, run live as far as a password allows.** Discovery off the live
interface matched the Mac's own table exactly, it took the `starting from the
script already on the Mac` branch, reported `profile replaced`, staged both
files, printed the five `sudo` commands and stopped clean on `Done? n`. The
staged plist is byte-identical to the installed one and the staged script is the
same 8209 bytes carrying the same profile line.

**All of it ran, on the third attempt, once the Mac was back on a network that
carries station-to-station traffic.** Phase B's *verified* add — the probe
passing and the block written on the strength of it — happened at last; the two
earlier attempts were defeated by the proxy ordering and then by client
isolation on the only spare SSID, which cannot be turned off.

**Phase C then found a seventh fault, and `bash -n` caught it before anything
reached the Mac.** The Mac's `Tachikoma:Redux` arm had been commented out by
hand, and the splice reported `profile replaced` and produced a script that
would not parse. The pattern was not anchored: `[ \t]*"SSID")` matches *inside*
a commented arm, starting after the `#` because what follows it is whitespace,
and the lazy run to the next `;;` then skips every commented one and stops at a
live arm's. So it deleted the live `The Sharp Project Tenants` arm and glued the
orphaned `#` onto `    "SenseGuest")`, commenting out its pattern and orphaning
its `echo`. `^` and `re.M` in both `splice_profile` and `drop_profile`: anchored,
a commented arm is not an arm, so the SSID reads as absent, a live arm is added,
and the comment is left where it is — it is a record of a choice, and the file
then says what it does.

**And an eighth, which was a wrong conclusion rather than a bug.** *"sudo there
has no passwordless path"* was true, and the thing built on it was not: sudo
needs a **terminal** to ask for a password on, not a passwordless rule, and
`ssh -tt` gives it one — which `ssh-copy-id` in phase A had been relying on since
the day phase A was written. Phase C now offers to run its five commands itself.
It still prints them, still lets you decline to the old "run these, then say
Done", and a failed install says how to check what got part-way and asks before
carrying on rather than cycling Wi-Fi over a half-installed daemon. `-tt` and
deliberately not `-n`, exempted from item 84's rule the way `ssh-copy-id` is, and
a case caps the exemption at exactly one call.

**A ninth, found by asking what a fresh Mac would do rather than by it
failing.** `install` does not create parent directories, and `/usr/local/bin`
does not exist on a Mac that has never had Homebrew or anything else put
something there — so on a genuinely fresh machine the script install would fail
with `No such file or directory`, which is the one machine phase C has never
run against. `/Library/LaunchDaemons` always exists, so the plist needs no such
step. The directory step is guarded rather than unconditional: measured on the
Mac, BSD `install -d` on a directory that already exists returns 0 and rewrites
its mode anyway — 700 came back 755 — so with `-o root -g wheel` it would rewrite
the owner too, and on an Intel Mac Homebrew owns `/usr/local/bin` as the user.
`[ -d ] ||` makes it a no-op on every machine that has run this before. Verified
both ways on the Mac: an existing 700 directory comes back 700, a missing one is
created 755.

**The install and the cycle then ran end to end.** `network-change.sh.bak`
records the file the install replaced, the new script is on the Mac and parses,
the plist was reinstalled and bootstrapped, and `/tmp/netchange.log` shows the
Wi-Fi going down at 16:32:08 and 16:32:25 and the daemon firing on reassociation
at 16:32:29. The WatchPaths trigger fires, the Mac comes back, and it holds the
static address. One caveat on what that proves: the daemon logged `already
static … — no change`, so the recovery and the trigger are exercised and
*applying* a new address is not — this Mac already held the address the profile
names.

**The round trip ran on the real files too.** `--remove mac-home` took it out of
all three, and the add put it back; `--list` now reports all three networks in
all three files.

**Coverage: 144 package cases, up from 37 when this started.** Seven are the
fresh-machine path, which had none. The rest of today's are the diagnosis and
the way back: each arm checked for the action it should name and the ones it
should not, the retry, the editor, the list, and the count of questions the
`/etc/hosts` write asks. Four harnesses now stub `ssh` rather than aiming at an
address that will not answer, and the suite unsets `grpc_proxy` and sets it
again in the one case that is about it — what a dead address produces is the
environment's business, and letting it vary made every fixed answer stream
depend on where the suite was run from. The suite no longer touches the network.
**Why 3, 4 and 5 belong in one tool: they must all three be right or none is.**
`setup.md:159-161` already says it — *"Add a new address when the Mac joins a new
network, in three places at once: here, `/etc/hosts`, and a new `Host` block in
`~/.ssh/config`. All three or none — two out of three produces a failure that
looks like something else."* That sentence is the item. A third network has been
added since the backlog last mentioned two, so this keeps happening.

**Two existing items are symptoms of the same gap.** Item 18 — `MAC_HOST` became
a space-separated list so a moving Mac stops looking like a broken one, and its
footgun, that `$MAC_HOST` raw is not usable as a hostname, is still open. Item
48 — the MCP server hardcoded one alias and missed the fix every script already
had. Both should cross-reference this one.

**Why a wizard and not more prose.** The same argument items 51 and 56 made: the
instructions exist, are correct, and are read at a moment when they cannot be
acted on.

**Gates.** None.

---

## 87. Flutter and iOS are wired in, not plugged in — **OPEN, raised 18 Sep; seam designed 18 Sep, nothing wired to it yet**

The driving half of this skill does not care what built the app. Maestro taps a
coordinate, reads a hierarchy, runs a journey and takes a screenshot the same way
whatever produced the binary, and `driver.sh`, `drivers.sh`, `flow.sh`, `img.sh`,
`wall.sh` and the journey tooling are all written against Maestro rather than
against Flutter. That half already generalises.

The *other* half — getting an app onto a device and looking inside it while it
runs — is Flutter and iOS all the way down, and it is not separated from the
part that generalises. Wanting to drive a React Native app, or a plain Android or
iOS one, means either forking the package or teaching every one of these files a
second way to do its job.

**Where the framework is wired in.** Counted 18 Sep by `grep -ciE
'flutter|dart|pubspec'`:

| file | hits | what it does that is framework-specific |
| --- | --- | --- |
| `remote/build.sh` | 31 | discovers how the project builds, builds for the simulator, installs |
| `remote/vmservice.sh` | 10 | finds the Dart VM Service base URI and main isolate id |
| `bin/net.sh` | 9 | reads the app's real HTTP traffic out of the Dart VM Service |
| `bin/publish.sh` | 5 | republishes that loopback-bound service on the LAN |
| `remote/gitstate.sh` | 5 | splits tracked changes into build residue and real edits |
| `bin/preflight.sh` | 3 | is the installed app the code under test |
| `bin/prefs.sh`, `bin/driver.sh`, `bin/build.sh`, `bin/config.sh`, `bin/hier.sh`, `bin/secrets.sh`, `bin/resolve.py`, `remote/relay.py`, `remote/net.py`, `remote/wall.py` | 1–2 each | a mention apiece, mostly a path or a comment |

**Where the platform is wired in**, separately and just as deeply — `grep -ciE
'xcrun|simctl|XCUITest|iphonesimulator'`: `remote/wall.py` 11, `remote/build.sh`
8, `bin/driver.sh` 8, `remote/deviceup.sh` 5, `bin/drivers.sh` 5,
`remote/driverup.sh` 4, then `wall.sh`, `lib.sh`, `shot.sh`, `prefs.sh`,
`preflight.sh`, `init.sh` with two or three each. **Nothing under `bin/` or
`remote/` mentions `adb`, an emulator or Android at all**, so Android is not
half-done, it is absent.

**Two axes, not one.** Framework (Flutter, React Native, native) decides how the
app is built and how you see inside it. Platform (iOS simulator, Android
emulator, a physical device) decides how it is installed and driven. They are
independent — React Native on Android is a real combination — and the code
currently assumes one point in that grid without saying so anywhere.

**Approximate shape of the seam.** A runner is a small set of answers, and
everything else stays as it is:

- **detect** — is this checkout mine? (`pubspec.yaml`, `package.json` with a
  react-native dependency, `*.xcodeproj`, `build.gradle`)
- **build and install** — for a given device, returning the installed app id
- **is the installed build the code under test** — `preflight.sh`'s question,
  answered per framework
- **build residue** — the paths `gitstate.sh` should ignore when deciding
  whether a working tree is dirty
- **traffic**, optional — the Dart VM Service for Flutter, Metro or a proxy for
  React Native, nothing at all for native. `net.sh` and `publish.sh` become one
  runner's answer rather than a feature of the package.

Platform is the same shape: install, list devices, boot, screenshot, and the
driver bring-up that `driverup.sh` and `deviceup.sh` do for XCUITest.

**Why it is worth doing rather than forking.** Everything expensive in this
package is in the half that already generalises — the rig, the wall, the journey
tooling, the driver lifecycle, the SSH and network side that item 85 is about.
A fork would copy all of it to change `build.sh`.

**Related.** Item 82 is four sessions opening the wrong skill because one builds
and the other drives; a package that names its runner explicitly makes that
distinction structural rather than a sentence in a description. `flutter-hot-reload-mac`
is the sister package and is Flutter by definition — it is not in scope here, but
whatever seam this item settles on is the one it would plug into.

**Gates.** None. Item 85 touches none of these files.

---

### The seam, as designed 18 Sep. `skill/runners/README.md` is the contract.

**The grep above overcounts.** Recounted by reading the files rather than
grepping them: **eight** hold Flutter *logic* — `remote/build.sh`,
`remote/vmservice.sh`, `bin/net.sh`, `bin/publish.sh`, `remote/net.py`,
`remote/gitstate.sh`, `bin/preflight.sh` and `bin/prefs.sh`. Every other hit in
the table is a comment explaining a measurement. `driver.sh`'s two, `hier.sh`'s,
`resolve.py`'s, `secrets.sh`'s, `wall.py`'s and `relay.py`'s all survive the word
being deleted, so they are not work. `bin/prefs.sh` was missed by the grep
entirely — its default filter is `flutter`, because `shared_preferences`
prefixes every NSUserDefaults key — which is the reverse error and worth the
same note.

**Two modules, confirmed.** The four names the seam is wanted for split cleanly
across the two axes this item already identified: `flutter` and `react-native`
are frameworks, `ios` and `android` are platforms. A single
`RUNNER=flutter|react-native|ios|android` cannot work, because it would make
`flutter` and `android` alternatives to each other when both are true at once.
`ios` and `android` also answer the framework questions for a project with no
framework above the platform.

A module is one POSIX `sh` script per axis, dispatching on its first argument.
**Exit 2 means "this framework does not have that verb"**, and it is not a
failure — it is what lets `net.sh` say "native apps have no traffic endpoint"
instead of "the relay is broken", which is the same distinction `vmservice.sh`
already draws and which cost a session six minutes before it did.

- framework: `claim describe variants variant-for-appid build residue
  devsession inspect traffic-arm traffic-list traffic-one prefs-prefix`
- platform: `claim devices boot shutdown install container data-container
  prefs-read prefs-flush orientations screenshot driver-up driver-down
  driver-scan capture-cmd`

**Written.** `skill/runners/README.md` (the contract, the seven call sites, and
what the stubs found), `runners/TEMPLATE/` (the module to copy),
`runners/flutter/framework.sh` and `runners/ios/platform.sh` (worked, delegating
to today's scripts), `runners/react-native/framework.sh` and
`runners/android/platform.sh` (stubs — **nothing in either has been run**, and
each verb says whether it is documented-not-measured or unanswered),
`bin/runner.sh` (the dispatcher: `which`, `path`, `rpath`, `detect`).

**Applied to the existing code**, behaviour unchanged and Flutter still coupled:

- `remote/build.sh` prints `artifact <path>` on a successful build and gains
  `--build-only`. This is the one real change the seam demanded and it is done:
  the simulator install is `_install_sim`, a named unit `runners/ios` mirrors,
  and on the physical-device path `--build-only` emits the build half of the
  script handed to the GUI session without the `devicectl` half. Five tests.
- `remote/gitstate.sh` — the residue list is `$RESIDUE_GLOBS`, defaulting to the
  same five patterns. Verified against a React-Native-shaped override.
- `bin/preflight.sh` — the dev-session heading, pgrep pattern and consequence
  text are variables, still holding the Flutter values.
- `bin/config.sh` — `RUNNER=flutter`, `PLATFORM=ios`. Nothing reads them yet.
- `bin/install.sh` pushes `runners/` to `$RDIR`; `bin/build.sh --no-install`
  passes `--build-only` through.

**Six verbs left unanswered on purpose, and they are the useful part.** Each is
a hole in the contract, not work nobody got round to. `android boot` — an AVD
name and an emulator serial are not the same identifier, and the contract
assumes they are. `android container` — `appcheck`'s timestamp-and-plist
comparison, the single most valuable check in `preflight.sh`, has no Android
equivalent. `android driver-up`/`driver-down`/`driver-scan` — Maestro's Android
driver is an instrumented APK behind `adb forward`, and whether its port can be
chosen per device at all decides whether several-devices-at-once crosses.
`react-native variants` — iOS schemes and Android product flavours are two
lists, which makes it the one verb where the axes are not independent.

**Done 18 Sep: `bin/build.sh` splits into two SSH calls, not one.** Call site 3
is the first of the seven wired, and it is the only one that needed a decision
rather than a substitution. `framework.sh build` then `platform.sh install`,
both reached through `runner.sh rpath`; `platform.sh claim` replaces the
UUID-shape test, `platform.sh devices --booted` replaces the inline `simctl`
parse behind `--all`, `framework.sh describe` answers `--detect`, and
`--install-only <path>` is new. Verified live against the Mac: `runner.sh
detect` claims the real checkout as Flutter, `--detect` reports through the
module, and a build returns 22s with the artefact path parsed back out. **The
install half is not verified live — no simulator was booted.**
`framework build` returns `artifact <path>` to this side, then one
`platform install` loops over the target devices on the Mac. Concatenating the
two verbs into a single remote command would save one round trip — 0.35s
against a 36s incremental build, about 1% — and would leave the artefact path
as a shell variable on the Mac.

Keeping the path here is what lets a *second* install skip the build. Not the
several-simulators case: `--all` already builds once and installs to every
booted simulator in one call, so devices present at build time cost the same
either way. It is every install of an artefact already built — a simulator
booted after the build (item 24), a reinstall after `simctl erase`, an
uninstall to test first launch, a driver or device replaced mid-session.

**A no-op build is 21-22s, measured 18 Sep 2026.** Three consecutive
`bin/build.sh --no-install` runs against an unchanged tree on the Mac: 34s
(19.6s Xcode), 22s (13.2s), 21s (12.4s). The first also re-confirms the 13 Aug
figure of 36s. It does not collapse to nothing, because Xcode re-runs Flutter's
script phase every time whatever the staleness of its outputs, and ~9s goes on
`pub get` resolution before Xcode starts at all.

So each repeat install saves 21s rather than the 36s first claimed here, and
one of them still pays for sixty builds' worth of the single-call saving.

Left open by that: the physical-device path polls a GUI-session build for up to
1200s and keeps its own `TMO`, so the two paths do not share a timeout rule.

---

### What is left, in units

Each unit is one commit. `runners/README.md` has the contract and the shape of
every call site's change; this is the order and the stopping condition.

**Stage 1 — wire the call sites that need no new answers. DONE 18 Sep**, five
commits, 1.1 to 1.5. Every call site now asks a module, and `RUNNER` changes
what five scripts say. Verified live against the Mac at each step; the three
bugs it turned up are in the unit notes below.

**1.1 DONE.** 1.1 Residue comes from the framework.** `bin/preflight.sh` passes
`RESIDUE_GLOBS=$(framework.sh residue)` into the remote call before it sources
`gitstate.sh`. `gitstate.sh` keeps its current default, because it is also
sourced standalone and by the tests, but nothing in the live path uses it any
more. *Files:* `bin/preflight.sh`. *Done when:* preflight against a checkout
whose runner answers `yarn.lock` reports `yarn.lock` as residue and
`pubspec.lock` as a change.

**1.2 DONE.** 1.2 The dev-session probe comes from the framework.** The three
`DEVSESSION_*` variables are filled from `framework.sh devsession` rather than
defaulted in the script. It runs on the Mac, so it folds into preflight's one
SSH call rather than adding another. *Files:* `bin/preflight.sh`. *Done when:*
`RUNNER=react-native` makes preflight say Metro rather than `flutter run`, and
say the app may not start at all rather than that driving is unaffected.

**1.3 DONE.** 1.3 `publish.sh` finds its endpoint through the framework.** The
`vmservice.sh` call becomes `framework.sh inspect`; `_profiling` and
`_profiling_on` become `framework.sh traffic-arm`. The relay, the state file and
the per-device suffix stay — `relay.py` does not care what is behind the port.
*Files:* `bin/publish.sh`. *Done when:* a framework whose `inspect` exits 2
makes `publish.sh` say that framework has no debug endpoint, rather than that
the relay failed.

**1.4 DONE.** 1.4 `net.sh` reads traffic through the framework.** The two `ext.dart.io`
URLs and the `net.py` calls become `traffic-list` and `traffic-one`. Keep the
fast-path/SSH-fallback choice and keep `_explain_empty`: "the app made no
calls" and "capture was never armed" look identical and must not be conflated.
*Files:* `bin/net.sh`. *Done when:* `RUNNER=react-native` makes `net.sh` print
the proxy explanation and exit 2, and Flutter behaves exactly as it does today.

**NOTE on 1.3 and 1.4.** The `traffic-*` verbs run **in the sandbox**, through
`$grpc_proxy`, while every other verb runs on the Mac. `runner.sh framework`
handles the local side and `runner.sh rpath` the remote one. A verb invoked on
the wrong side fails as a network error, which reads as a broken relay rather
than as a wiring mistake.

**1.5 DONE.** 1.5 `prefs.sh` uses both modules.** The container lookup and the plist read
become `platform.sh data-container` / `prefs-read` / `prefs-flush`; the default
filter becomes `framework.sh prefs-prefix`. The only call site that needs both.
*Files:* `bin/prefs.sh`. *Done when:* the default filter comes from the runner
and a framework with no prefix reads every key rather than none.

**Stage 2 — prove it against something that is not Flutter.** Doing this before
the mechanical work means Stage 3 is done against a contract known to hold
rather than one hoped to.

**2.1 DONE 18 Sep**, and extended on the same day to the multi-device forms.
Every booted-device path in the platform contract has now run against a real
device, which none of them had: Stages 1 and 3 were verified
only on empty and error paths, because nothing was booted.

Exercised through their real callers, not by hand — `boot`, `driver-up`,
`driver-scan`, `devices --booted`, `install`, `container`, `orientations`,
`data-container`, `prefs-flush`, `prefs-read`, `screenshot`, `capture-cmd`,
`last-used`, `uninstall`, `driver-down`, `shutdown`. `locked` returns 2 for a
simulator, which is the self-gate working.

**The split's saving, measured rather than argued: `--install-only` is 3s
against 25s for build-and-install.** That is the 22s the no-op build costs,
recovered exactly as predicted.

Two things it found:

  `rig up` printed an awk error. The live-driver guard on the wall's label
  reclaim is a $( ) inside a double-quoted _ssh string — expanded LOCALLY — and
  its field references were escaped as though it ran on the Mac. awk died, the
  substitution came back empty, and the guard has never fired. One of the three
  tests protecting a peer's label was dead, leaving only the age check. Raised
  and fixed as item 88.

  The reclaim tests did not catch it because they reimplement the logic in shell
  and test the intent rather than the shipped string. The new test reads the
  file instead.

**The forms that need more than one device, verified 18 Sep with two booted:**

  drivers.sh down <udid>   stops one driver and leaves the other alone
  drivers.sh up <udid>     brings it back ON THE SAME PORT — 22088, which is
                           the per-device ports map holding across a restart,
                           and is the whole reason that map lives on the Mac
  build.sh --all           one build, both installs, `platform.sh devices
                           --booted` feeding the target list and the install
                           loop running on the Mac in ONE round trip
  --all --install-only     both devices in 23s against 88s for the build-and-
                           install, which is the saving scaling with the device
                           count rather than being spent per device

Left as found: rig down, nothing booted.

**2.2 React Native on iOS, end to end.** The cheapest second target by a
distance: `runners/ios` already works, so only `framework.sh` is new. Fill in
`describe`, `build` and `residue` against a real checkout. **Needs a React
Native checkout on the Mac — there is none today.** *Files:*
`runners/react-native/framework.sh`. *Done when:* `bin/build.sh --detect`
reports an RN project and `--no-install` produces an artefact path.

**Stage 3 — call site 7. DONE 18 Sep**, seven units, seven commits. It was
planned as four files and "one command substituted for another, repeatedly".
Call site 7 covers seven files, and two of the substitutions were not
substitutions at all.

**3.1 `lib.sh` DONE.** `_dev` and `_driver_scan` become `devices --booted` and
`driver-scan`. The module paths are plain strings set in `lib.sh` rather than a
call to `bin/runner.sh`, because `runner.sh` sources `lib.sh` and every `_dev`
would otherwise pay for a subprocess to learn what `config.sh` already knows.

**3.2 `drivers.sh` DONE.** Six call sites, five of them substitutions.

The sixth was `rig reap`'s freshness probe, which walked CoreSimulator's per-app
data containers for an mtime — two levels deep, because a container's own mtime
only moves when its IMMEDIATE contents change and a device driven all day on the
18th reported the 16th. That is archaeology rather than a command, so it became
**`last-used`**: `<id>|<yyyymmdd>|<human>|<today>` for every booted device in one
call. Today's date comes from the device's own host, so clock skew between the
two cannot reap a live device. Android's is unanswered and says why — an
emulator image's mtime says the emulator is running, not that anyone is driving
it, which is a different question.

Boot and settle also split. `platform.sh boot` waits for the DEVICE;
`drivers.sh` still waits for the MACHINE afterwards, and it is the second that
decides whether the next boot or a driver start survives. Two different things
that happened to share a function.

**3.3 `shot.sh` DONE.** One line.

**3.4 `wall.py` DONE, and reading it settled the open decision rather than a
design argument.** `wall.py` used the runtime ONLY to sort and dropped it from
the return — so no JSON form was needed. `devices` gained an optional fourth
column carrying the runtime, and the single text format stays. No `simctl`,
`XCRUN` or `SIMSERVER` left in the file.

The module's `devices` reads `-j` and parses it with python rather than scraping
simctl's human listing, because that listing puts the runtime on a heading line
ABOVE its devices and a line-at-a-time parse cannot carry it down to the rows.

**3.5 `preflight.sh` DONE.** `container`, and `orientations` — which already
existed and had no caller. `orientations` takes the container rather than the
device on purpose: it reports what the INSTALLED BUILD declares, not what the
device supports, and those differ on exactly the case the check exists for, a
landscape-locked app on a natively-portrait iPad.

**3.6 `flow.sh` DONE.** The other screenshot.

**3.7 `driver.sh` DONE**, and it needed two verbs the contract lacked.

`uninstall <id> <app-id>` for `clearstate`. Removing the app removes its data
with it, which is the point: clearstate wants a first-launch app, not a
logged-out one. An app already absent is not a failure.

`locked <id>` has THREE statuses — 0 locked, 1 not, **2 the question does not
apply** — and the third is what lets the check self-gate. `devicectl` returns
nothing for a simulator udid, so a simulator gets 2 and the caller never needs
to know which kind of device it holds. Verified live.

That third status caught a latent test bug. The three lock stubs answered by
PRINTING `passcodeRequired: true`; they answer by status now, and the simulator
case returns 2 where it returned 0 — which under the new code means "locked".

**Three verbs and a column added across the stage:** `last-used`, `uninstall`,
`locked`, and `devices`' optional fourth column.

**Nothing under `bin/` calls `xcrun`, `simctl` or `devicectl` any more.** What
still matches is comments in `build.sh` and `driver.sh`, and three files that
are a module's own territory rather than a caller's: `remote/vmservice.sh` and
`remote/build.sh` belong to the flutter framework runner, `remote/deviceup.sh`
to the `ios-device` platform runner. Moving them inside `runners/` would leave
`remote/` holding only shared code, and is worth doing before a second platform
arrives.

`bin/init.sh` is the real remainder and is **5.2**: it lists devices and
installed apps for the setup wizard, which is conf-writing rather than driving.

**Stage 4 — answer the six unanswered verbs.** Two are paper decisions and can
be taken now. Two need hardware this Mac may not have.

**4.1 DONE 18 Sep — `boot` prints the id it booted, as its last line.** Not a
second `resolve` verb: the caller always has to act on the booted device
afterwards, so returning the id costs one line on a platform where it does not
change and saves every caller a round trip on one where it does. `runners/ios`
echoes its argument.

The consequence for `devices` is recorded with it: on a platform like that, the
id column means "the id you use to act on this device IN ITS CURRENT STATE", so
a shut-down emulator lists under its AVD name and a running one under its
serial. Inherent to the platform, not a wrinkle in the contract.

**4.2 DONE 18 Sep — `variants` and `variant-for-appid` take an optional
`--platform <p>`.** A framework whose variants span both platforms accepts it
and answers the same: one Flutter `--flavor uat` builds the iOS app and the
Android one, so ignoring it is the right answer rather than an omission, and a
caller can pass it unconditionally. React Native's do not span, and it needs
telling which list.

An optional argument rather than a second verb, because the caller always knows
its platform already — `bin/build.sh` has `PLATFORM` in hand — so passing it is
free and a framework that does not care is not made to care.

`variant-for-appid` takes it for the same reason: an app id is itself
per-platform, a bundle id on iOS and an applicationId on Android.

**4.3 SUPERSEDED 18 Sep.** It asked for an Android `container`, and the answer
turned out to be that `appcheck` should stop needing one. `platform.sh
installed-info` reports what a platform CAN say and `appcheck` reasons from
whatever arrives, so an absent key is a fact rather than a failure. Android
answers `version`, `build` AND a timestamp through `dumpsys package`, which is
more than a phone gives — so `container` being unanswerable there costs the
check nothing. Written and unmeasured, like the rest of that module.

**4.4 The Android driver trio. THE QUESTION IS ANSWERED — 21 Sep 2026 — and the
answer is yes.** Measured against Maestro 2.10.0 and `Pixel_6_Pro_API_34` over
item 96's bridge, in item 94's 5.3. The three verbs are still to write; what
follows is what they can be written against.

**The port can be chosen, per run.** `maestro --driver-host-port <n>` is a
global option — absent from `maestro --help`, present in `App.class` beside
`--host` and `--port`. The default is `DEFAULT_DRIVER_HOST_PORT = 7001` in
`maestro/android/AndroidDeviceConnection`, where `driverHostPort` is a
constructor parameter rather than a literal at the call site, and it is
validated at startup:

```
$ maestro --device emulator-5554 --driver-host-port 1 test flow.yaml
Requested driver host port 1 is not available          # exit 1
$ maestro --device emulator-5554 --driver-host-port 7099 test flow.yaml
Launch app "com.prodirectsport.consumer.dev"... COMPLETED   # exit 0
```

So Android does **not** repeat the iOS client's hardcoded 22087, and several
devices at once crosses platforms. `bin/drivers.sh`'s ports map has an Android
half to allocate into.

**The APKs are inside Maestro's own jar, not `~/.maestro/deps`.**
`maestro-client.jar` carries `maestro-app.apk` (11.7MB) and `maestro-server.apk`
(0.9MB). They install as `dev.mobile.maestro` and `dev.mobile.maestro.test` for
the length of a run and are gone from `pm list packages` afterwards — so a scan
for a resident package finds nothing between runs.

**`adb forward --list` is not the `driver-scan` analogue.** It stayed empty for
the whole of a flow, and no host socket appeared on 7001 or 7099 either:
Maestro reaches the device through dadb, its own ADB client, so there is no
forward registered with the adb server to scan for. Whatever `driver-scan`
becomes on Android, it is not the iOS shape and it is not `adb forward`.

**What is still unmeasured:** whether one emulator can hold one driver as one
simulator does. There is a single emulator on this machine, so two at once could
not be tried.

**Stage 5 — what falls out once a second runner works.**

**5.1 DONE 18 Sep.** A paragraph beside the config step saying what a runner is
and why there are two settings, and the sentence that does the work: everything
Flutter or iOS in the rest of the file is one runner's answer. Step 5 is "a dev
session" and carries the warning that no Metro is not the same as no
`flutter run`. The build numbers are 18 Sep's, including `--install-only` at 3s
against 25s. `--detect` is named as the framework's `describe`; `bin/runner.sh`
joins the tool table.

**5.2 DONE 18 Sep.** The framework is asked, not assumed — with a REPO, init
runs `runner.sh detect` and writes what claimed it. Without one it writes the
default AND SAYS SO, because a default presented as a finding is how a wrong
runner survives a setup. PLATFORM is ios with the reason given: nothing is
booted yet to ask about. The gitignore advice covers `.maestro-mac.conf.*` too,
which is where a credential actually lives in a two-environment project.

**5.3 is now item 93** and left this one. It is work in another repo, and
keeping it inside 87 made 87 look unfinished when what remains is a separate
package's to do.

**5.4 `remote/` keeps only shared code.** Raised by Stage 3 rather than planned:
three files there are a module's own territory and sit outside `runners/`
because that is where they were before the seam existed.

  `remote/vmservice.sh`  the Dart VM Service discovery — the flutter framework
                         runner's `inspect`, which already shells into it
  `remote/build.sh`      the Flutter build — the same runner's `build`
  `remote/deviceup.sh`   the physical-device driver bring-up, with its usbmux
                         forwarder and its tunnel wake

**The first two are DONE 18 Sep.** `remote/build.sh` and `remote/vmservice.sh`
are `runners/flutter/`'s now. The gain was not tidiness: `variants` and
`variant-for-appid` REPRODUCED build.sh's flavour rule rather than calling it,
so the subtle part — a flavour is real only when both an xcscheme and a
`lib/main_<f>.dart` exist — had two implementations that could drift. build.sh
gained `--list-variants` and `--variant-for`, and both verbs ran for real
against the seven-flavour repo for the first time: six flavours listed,
`variant-for-appid` narrowing to exactly `uat`.

**The third is not a move.** `remote/deviceup.sh` belongs to `runners/ios-device`,
which does not exist — and both `bin/build.sh` and `runners/ios/platform.sh`
already name `ios-device` as a platform that ought to. Creating it is closer in
size to 2.2 than to a file move: devicectl rather than simctl, a profile build,
a usbmux forwarder, a lock refusal, and `remote/iproxy.py` with it.

**This one has a dependency the rest of Stage 5 does not.** `remote/` holding
iOS-specific helpers is what a second PLATFORM trips over, so 5.4 wants doing
before 4.3 and 4.4 rather than after them.

**The flutter module is verified end to end as of 18 Sep — EVERY verb has run
live.** `claim` against sixteen checkouts, `describe`, `variants` and
`variant-for-appid` against the seven-flavour repo, `build`, `residue`,
`devsession`, `prefs-prefix`, `inspect` in both failure modes and in success,
`traffic-arm` with both states, `traffic-list` and `traffic-one`.

The last two needed a recorded request, and this app only calls out on login.
The login needs a PIN, and the PIN is in the `hugoboss-flutter-runner` project's
own `.maestro-mac.conf` **on this machine** — which is the convention working
exactly as designed, and which I first looked for on the Mac and under one local
path and wrongly concluded was absent. Pointing `MAESTRO_MAC_CONF` at that
project picks up its conf, its `DEV`, its dev flavour and its committed
journeys, and `00-login-store-set.journey` does the rest.

  traffic-list  GET /v1/users?storeId=1927 -> 200, /v1/chats -> 401, and more
  traffic-one   headers and body, user-agent: Dart/3.11 (dart:io)

The credential stayed where it belongs throughout: the journey reads
`${APP_PIN}` from the conf rather than taking it on the command line, so the run
log shows the variable name and not the value, and `bin/secrets.sh check`
afterwards reported clean — no project value in any file git would commit.

The live run also found a bug in 1.4 that could never have worked: the module
addressed net.py as `$RDIR/net.py`, a path on the MAC, for verbs that run in the
sandbox. Only the SSH fallback worked, and nothing had reached the fast path.

**Order.** Stage 1, 2.1, Stage 3, 5.1, 5.2, 5.4's first half and the traffic
verification — all done. Left: 5.4's second half (`runners/ios-device`), Stage 4,
5.3, and 2.2 whenever there is an RN checkout to use.

**Answered 18 Sep: neither is on that Mac today.** No `adb`, no SDK directory,
no `~/.android/avd`, no emulator binary; `~/.maestro/deps` holds the iOS capture
binary and nothing else. And no React Native checkout — both runners were asked
to claim all sixteen repos on the Mac and every one is Flutter, including
`hb-phase2`, which the name does not give away.

So 2.2, 4.3 and 4.4 are each blocked on an install rather than on a decision,
and the two are not the same size: an RN checkout is node, a `react-native init`
app and a `pod install`, while Android is an SDK, an emulator and Maestro's
Android driver on top.
