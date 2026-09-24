# Driving a physical iPhone

Everything in the rest of this skill assumes a simulator. A physical device
works too, and none of it is the same. This file is what it took, measured on
21 Aug 2026 against an iPhone XS Max (iOS 18.7.9) attached by cable to the Mac,
driving `acme.e.brandco.runner.dev`. The real device UDID is replaced throughout
this file by the placeholder `00008020-0011223344556677`; substitute your own.

The end state reached: `maestro hierarchy` returning the real view hierarchy off
the phone, with real bounds — `DEV APP [0,0][414,896]`, `SUBMIT
[48,549][365,599]`.

The driving half is now wired into **`bin/device.sh`** (added 10 Sep 2026): it
brings up the forwarder and a persistent driver and registers the phone, so
`DEV=<udid> bin/driver.sh …` drives it exactly like a simulator, and
`driver.sh` restarts a dead device driver on its own (item 46). The sections
below are why each step is there, and the manual commands behind it. Building the
app *on* a device is still by hand (the signing gate, item 45).

**Two things must be true before any of it, or the driver fails as an opaque
"connection was invalidated" rather than as the real cause:**

- **The phone must be UNLOCKED, and set Auto-Lock to Never** (Settings → Display
  & Brightness → Auto-Lock → Never). XCUITest cannot attach to a locked
  springboard: measured 10 Sep 2026, an unlocked phone starts the driver 3/3 and
  a locked one fails every time — and because a bring-up plus a test is often
  under a minute, the default Auto-Lock repeatedly re-locked the phone
  mid-session and killed the run. `bin/device.sh`/`deviceup.sh` refuse with "the
  phone is LOCKED — unlock it" when they find it locked, rather than letting it
  read as a relay fault.
- **Sessions that keep dying within a couple of minutes: restart `remoted` on
  the Mac first.** `sudo killall -9 remoted` (it restarts itself in seconds).
  Measured 24 Sep 2026 on the iPhone 11 over USB: before it, every driver
  session died after 57–108 s with "connection was invalidated", whichever
  driver, and restarting the phone changed nothing; after it, four sessions of
  four were alive at 10 minutes. It needs the Mac user's password, so ask for
  it rather than retrying (item 46).
- **Flat is fine with the driver built from source; the prebuilt one needs
  the phone UPRIGHT.** The prebuilt driver crashes on the first `/touch` when
  the phone reports `.faceUp` (`ScreenSizeHelper.swift:99: Fatal error: Not
  implemented yet`), because it was compiled from older source than the jar
  ships. The driver from `runners/ios-device/driver/build.sh` handles it: on 24
  Sep 2026 the flat XS Max took 5 touches of 5 on it, and died on touch 1 with
  the prebuilt one. `deviceup.sh` starts the source build whenever a signed one
  exists (item 50). On the prebuilt fallback, `driver.sh` names the crash from
  `~/devdrv-<udid>.log` and says "STAND THE PHONE UPRIGHT". Posture can be read
  before a touch with `xcrun devicectl device orientation get --device <udid>`
  (Xcode 27).

## 1. Nothing signs from an SSH session

`bin/mac.sh` runs over SSH, and macOS puts an SSH session in the **Background**
security session:

```
$ launchctl managername
Background
```

`codesign` in that session cannot reach the private key, whatever the screen is
doing:

```
$ codesign --force --sign <hash> /tmp/sigtest
/tmp/sigtest: errSecInternalComponent
$ security show-keychain-info ~/Library/Keychains/login.keychain-db
security: ... User interaction is not allowed.
```

Unlocking the Mac's screen does not change it. Three no-password routes were
tried and all failed: `security unlock-keychain -p ""` (no effect),
`launchctl asuser 501 codesign …` (`Could not switch to audit session:
Operation not permitted` — needs root), and `sudo -n true` (password required).

**What works, with no password at all**, is handing the command to the GUI's
Terminal, which runs in Aqua:

```sh
osascript -e 'tell application "Terminal" to do script "$HOME/build.sh"'
```

Write the script to a file first, have it redirect its own output to a log, and
poll the log from this side. Verified:

```
$ codesign -dvvv /tmp/s6
Authority=Apple Development: Example Developer (AB12CD34EF)
TeamIdentifier=TEAM123456
```

Apple Events reach the GUI from SSH without extra permission — checked with
`osascript -e 'tell application "Finder" to get name of startup disk'` →
`Macintosh HD`. `screencapture` does **not** work the same way; it produced no
file, so the Mac's screen cannot be read this way.

**Two traps that cost time here.**

`security find-identity -v -p codesigning` with no keychain argument omitted an
identity that was present. Naming the keychain found it:

```
$ security find-identity -v -p codesigning              # 2 identities
$ security find-identity -v -p codesigning ~/Library/Keychains/login.keychain-db
  3) A1B2C3D4E5F60718293A4B5C6D7E8F9012345678 "Apple Development: Example Developer (AB12CD34EF)"
```

And Xcode 16 moved provisioning profiles. The old path still exists and still
has files in it, so searching it looks like a complete answer and is not:

| path | what was in it |
| --- | --- |
| `~/Library/MobileDevice/Provisioning Profiles/` | plenty of profiles, none for the app under test |
| `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` | fewer profiles, and the ones that matter |

Search both. The second is the one Xcode 16 writes and reads.

## 2. Build the app in profile mode, not debug

> **Automated since 11 Sep (item 45).** `DEV=<device-udid> bin/build.sh` now does
> everything in this section: it runs a profile build through the Aqua session
> and installs with `devicectl`, gated on a local provisioning profile, and
> checks the installed bundle id is the one asked for. The manual recipe below is
> the reference for what it does and for debugging it.


A debug Flutter build cannot be launched on the device by anything but the
Flutter tooling:

```
$ xcrun devicectl device process launch --device <udid> <bundle-id>
Runner[719:28294] Cannot create a FlutterEngine instance in debug mode without
Flutter tooling or Xcode.
```

That alone rules debug out for anything a person has to start from the home
screen. It is also wrong for any test of backgrounding: an attached debugger
stops iOS suspending the app, so a debug build cannot answer whether suspension
behaves as designed.

`flutter run -d <udid>` is not a way round it. It builds and installs, so it
goes through the same `codesign` call and fails identically — 9 seconds in.

Profile mode launches standalone, suspends for real, and still prints to a
console. Build and install it from the Aqua session:

```sh
cd <repo>
export GEM_HOME=$HOME/.gem; export PATH=$GEM_HOME/bin:$PATH
./.fvm/flutter/bin/flutter build ios --profile --flavor dev -t lib/main_dev.dart
xcrun devicectl device install app --device <udid> build/ios/Profile-dev-iphoneos/Runner.app
```

To watch it: `xcrun devicectl device process launch --device <udid> --console
--terminate-existing <bundle-id>` streams the app's stdout. The console drops
whenever another `devicectl` command runs against the same device, so either
leave it alone or wrap it in a reattach loop.

`log stream --device-name` does not exist on this macOS — device syslog is not
available that way.

## 3. Maestro 2.8.0 cannot build its own device driver

**Superseded 24 Sep 2026 by building from source** (BACKLOG items 99 and 50).
Maestro's git tag has the `MaestroDriverLib` target the jar leaves out, so
`runners/ios-device/driver/build.sh` (on the Mac) builds the driver from it,
and `driver/sign.sh` (from Terminal on the Mac) signs it with the wildcard
profile described below. That build is the only one reachable over wifi and
the only one that survives a flat phone, and `deviceup.sh` prefers it. The
re-sign below is the fallback when no signed build exists.

Maestro **does** support a connected iPhone, despite its own documentation. The
mirror in `docs/pages/` says the opposite in two places and is wrong:

```
get-started__supported-platform.md:14        * iOS: Full support for simulators
…__ios__uikit.md:73     * Physical Devices: … not supported yet.
```

The binary detects the phone:

```
$ maestro --device <udid> hierarchy
Detected connected iPhone with 00008020-0011223344556677!
Building iOS driver for platform=iOS,id=…
Apple account team ID must be specified to build drivers for connected iPhone.
```

`--apple-team-id` is the flag. It is a **subcommand** option, not a root one —
`maestro --device X --apple-team-id Y hierarchy` fails with `Unknown options`;
`maestro --device X hierarchy --apple-team-id Y` is right. It is marked
`hidden` in the picocli spec, so `--help` does not list it, and the docs mention
it only under `record`. Probing with `--apple-team-id <id> --help` shows `test`,
`hierarchy`, `record`, `start-device` and `cloud` accept it, and `check-syntax`
does not. There is no environment variable — the only `MAESTRO_*` strings in the
jars are `MAESTRO_API_URL`, `MAESTRO_CLI_NO_ANALYTICS`,
`MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED`, `MAESTRO_CLOUD_API_KEY`,
`MAESTRO_CLOUD_API_URL`, `MAESTRO_DISABLE_UPDATE_CHECK`,
`MAESTRO_XCODEBUILD_WAIT_TIME` and `MAESTRO_DRIVER_STARTUP_TIMEOUT`.

What it does with the team ID, from
`maestro-cli-2.8.0.jar` → `maestro/cli/driver/DriverBuilder.class`:

```
xcodebuild clean build-for-testing
  -project        <driverRoot>/maestro-driver-ios.xcodeproj
  -scheme         maestro-driver-ios
  -destination    generic/platform=iphoneos
  -allowProvisioningUpdates
  -derivedDataPath ~/.maestro/…/maestro-iphoneos-driver-build
  DEVELOPMENT_TEAM=<teamId>
  ARCHS=<architectures>
  CODE_SIGN_IDENTITY=Apple Development
```

**That build cannot succeed.** The project file has a `MaestroDriverLib` target
and its sources ship in no jar — `unzip -l maestro-cli-2.8.0.jar | grep -ci
MaestroDriverLib` returns `0`. Patching the project to manual signing gets past
provisioning and straight into the real fault:

```
error: Build input file cannot be found:
  '~/.maestro/driver/ios/MaestroDriverLib/Info.plist' (in target 'MaestroDriverLib')
** TEST BUILD FAILED **
```

Provisioning fails first, which is why the missing target is never reached and
the signing error looks like the whole problem. It is not.

Two dead ends worth not repeating. `CODE_SIGN_STYLE = Automatic` in that
project will not consume a profile you install by hand — with the right wildcard
profile sitting in the Xcode 16 directory it still says
`No Accounts: Add a new account in Accounts settings` **and**
`No profiles for 'dev.mobile.maestro-driver-ios' were found`. And passing
`PROVISIONING_PROFILE_SPECIFIER` on the `xcodebuild` command line applies it to
every target, including the library: `MaestroDriverLib does not support
provisioning profiles`.

### The way through: re-sign the prebuilt driver

`maestro-ios-driver.jar` ships the driver already built for device, beside the
simulator one:

```
driver-iPhoneSimulator/…
driver-iphoneos/maestro-driver-ios-config.xctestrun
driver-iphoneos/Debug-iphoneos/maestro-driver-ios.zip
driver-iphoneos/Debug-iphoneos/maestro-driver-iosUITests-Runner.zip
```

Re-sign those and put them where Maestro looks, and it skips its own build. The
skip condition is readable in
`maestro/cli/driver/RealIOSDeviceDriver.validateAndUpdateDriver`: it walks
`~/.maestro/maestro-iphoneos-driver-build/driver-iphoneos/Build/Products/` for a
file with extension `xctestrun`, and reads `version` from
`~/.maestro/maestro-iphoneos-driver-build/version.properties`, rebuilding if
that version is older than the CLI's.

Two bundle ids need covering, from the driver's `project.pbxproj` and the
`maestro-driver-ios` scheme:

| target | bundle id installed on the device |
| --- | --- |
| `maestro-driver-ios.app` | `dev.mobile.maestro-driver-ios` |
| `maestro-driver-iosUITests.xctest` | `dev.mobile.maestro-driver-iosUITests.xctrunner` |

A **wildcard** development profile covers both. It must be **iOS App
Development** (`get-task-allow: true`), issued against an `Apple Development`
certificate that is in the Mac's keychain, and list the device. Neither bundle
id resembles the project's own naming and that does not matter — the team
prefix is what is checked. The driver project has no entitlements file, no
`CODE_SIGN_ENTITLEMENTS` and no `com.apple.developer.*` keys, so there is
nothing a wildcard cannot carry.

The re-sign, run from the Aqua session:

```sh
IDENT="Apple Development: <name> (<id>)"
PROF="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/<uuid>.mobileprovision"
ROOT="$HOME/.maestro/maestro-iphoneos-driver-build"
PROD="$ROOT/driver-iphoneos/Build/Products"

rm -rf "$PROD"; mkdir -p "$PROD"; cd "$PROD"
unzip -q -o "$HOME/.maestro/lib/maestro-ios-driver.jar" "driver-iphoneos/*"
mv driver-iphoneos/* . && rmdir driver-iphoneos
cd Debug-iphoneos && for z in *.zip; do unzip -q -o "$z" && rm -f "$z"; done

security cms -D -i "$PROF" -o /tmp/prof.plist
for APP in maestro-driver-ios.app maestro-driver-iosUITests-Runner.app; do
  cp "$PROF" "$APP/embedded.mobileprovision"
  # entitlements: take the profile's, then replace the wildcard
  # application-identifier with <TEAM>.<that bundle's id>, keep get-task-allow
  find "$APP" \( -name "*.framework" -o -name "*.dylib" -o -name "*.xctest" \) \
    -exec codesign --force --timestamp=none --sign "$IDENT" {} \;
  codesign --force --timestamp=none --generate-entitlement-der \
           --entitlements /tmp/ent.plist --sign "$IDENT" "$APP"
done
echo "version=2.8.0" > "$ROOT/version.properties"
```

Sign nested items — frameworks, dylibs, the `.xctest` — before the `.app`.
`--generate-entitlement-der` is required; without it iOS rejects the bundle.

Confirmed installed afterwards:

```
$ xcrun devicectl device info apps --device <udid>
maestro-driver-iosUITests-Runner   dev.mobile.maestro-driver-iosUITests.xctrunner
```

## 4. The driver's HTTP server is on the phone, not the Mac

This is the piece nothing tells you. The runner starts its server on the
**device's** loopback:

```
maestro-driver-iosUITests-Runner[795] [maestro_driver_iosUITests] Will start HTTP server
maestro-driver-iosUITests-Runner[795] [FlyingFox] starting server 127.0.0.1:22087
```

Maestro on the Mac polls the **Mac's** `127.0.0.1:22087` and never reaches it:

```
LocalXCTestInstaller.xcTestDriverStatusCheck: [Failed] … on <udid>,
  exception: java.net.ConnectException: Failed to connect to /127.0.0.1:22087
… iOS driver not ready in time, consider increasing timeout by configuring
  MAESTRO_DRIVER_STARTUP_TIMEOUT
```

On a simulator the two loopbacks are the same one, which is why `driverup.sh`
never needed this. On a phone it needs a USB port forward. `iproxy` is the usual
answer and libimobiledevice is not installed on this Mac, and there is no
Homebrew. `/var/run/usbmuxd` is present and world-writable, so the forward can
be done directly:

```
srw-rw-rw-  1 root  daemon  0 21 Aug 11:24 /var/run/usbmuxd
```

`iproxy.py` — a self-contained forwarder, no installs. Listen on the Mac, and
for each connection speak usbmux: `ListDevices` to map the UDID to a `DeviceID`,
then `Connect` with the port in **network byte order**, then pipe.

```python
import socket, struct, plistlib, threading, select

UDID = "<udid>"; LPORT = DPORT = 22087; SOCK = "/var/run/usbmuxd"
BASE = {"ClientVersionString": "maestro-fwd", "ProgName": "maestro-fwd",
        "kLibUSBMuxVersion": 3}

def mux_send(s, payload, tag=1):
    body = plistlib.dumps(payload)
    s.sendall(struct.pack("<IIII", 16 + len(body), 1, 8, tag) + body)

def mux_recv(s):
    hdr = b""
    while len(hdr) < 16:
        c = s.recv(16 - len(hdr));  hdr += c
    ln = struct.unpack("<I", hdr[:4])[0] - 16
    body = b""
    while len(body) < ln:
        body += s.recv(ln - len(body))
    return plistlib.loads(body)

def device_id():
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK)
    mux_send(s, dict(BASE, MessageType="ListDevices"))
    r = mux_recv(s); s.close()
    for d in r.get("DeviceList", []):
        if d["Properties"]["SerialNumber"] == UDID:
            return d["DeviceID"]
    raise SystemExit("device not on usbmuxd")

def connect_device(did):
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK)
    be = ((DPORT << 8) & 0xFF00) | (DPORT >> 8)     # network byte order
    mux_send(s, dict(BASE, MessageType="Connect", DeviceID=did, PortNumber=be))
    if mux_recv(s).get("Number") != 0:
        s.close(); raise ConnectionError
    return s

def pump(a, b):
    try:
        while True:
            for src in select.select([a, b], [], [])[0]:
                dst = b if src is a else a
                data = src.recv(65536)
                if not data: return
                dst.sendall(data)
    finally:
        a.close(); b.close()

did = device_id()
srv = socket.socket(); srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", LPORT)); srv.listen(64)
while True:
    c, _ = srv.accept()
    try: d = connect_device(did)
    except Exception: c.close(); continue
    threading.Thread(target=pump, args=(c, d), daemon=True).start()
```

It has to be running **before** Maestro starts, and has to stay up for the whole
session. `nohup python3 ~/iproxy.py &` is enough; it prints
`forwarding 127.0.0.1:22087 -> device 1 port 22087` when it binds.

## 5. The device tunnel idles out

`devicectl` reports a device as `connected` only while its tunnel is up, and the
tunnel drops back to `available (paired)` after a short idle. Maestro reads that
state and refuses:

```
Device with id <udid> is not connected
```

Thirty seconds between waking the tunnel and starting Maestro was already too
long. Any `devicectl` call wakes it, so do it in the same script, immediately
before:

```sh
xcrun devicectl device info lockState --device <udid> >/dev/null 2>&1
maestro --device <udid> hierarchy --apple-team-id <team>
```

The same idling explains a `flutter run` that dies with
`CoreDeviceError error 3 … The connection was invalidated`.

Separately: `flutter run` picked up a **stale mDNS advert** from a simulator and
connected to the wrong VM service —
`Unexpectedly found more than one Dart VM Service report for <bundle-id>._dartVmService._tcp.local
- using first one (57694)`. Terminate the app on every booted simulator before
running against the phone.

### It also drops mid-session, and that is not what the error says

Measured 21 Aug 2026 across a two-hour run of idle-timeout checks. The tunnel
does not only idle out *before* Maestro starts — it drops while the XCUITest
driver is running, and most often during a long wait with no traffic, which is
exactly what an idle-timeout test is. `~/devdrv.log` ends with:

```
Testing failed:
	An error occurred while communicating with a remote process.
	testHttpServer() encountered an error (Encountered a problem with the test
	runner after launch. (Underlying Error: An error occurred while
	communicating with a remote process. (Underlying Error: The connection was
	invalidated.)))
```

**From this side it looks like a relay fault, not a device fault.** Neither
error names the tunnel:

```
relay started but http://<mac>:9101/status did not answer
Traceback (most recent call last):
  File ".../bin/tree.py", line 50, in <module>
    d = json.load(sys.stdin)
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

`bin/drivers.sh list` is no help either — it reports the driver GONE without
saying why. On the Mac, `curl http://127.0.0.1:22087/status` returning `000` is
the driver being dead, and `xcrun devicectl list devices` showing
`available (paired)` rather than `connected` is the tunnel underneath it.

**A `devicectl` relaunch kills the driver every time.** Any
`xcrun devicectl device process launch --terminate-existing <bundle-id>` takes
the driver with it, so a cold relaunch always needs a driver restart straight
after — not only when something has already gone wrong.

**Recovery is cheap, and a first failure means nothing.** `devicectl` failed
once with

```
The tunnel connection failed while the system tried to connect to the device.
(com.apple.dt.RemotePairingError error 4 (0x04))
	(Network.NWError error 54 - Connection reset by peer)
```

and succeeded on a plain retry seconds later — phone plugged in, awake and
unlocked throughout, and `usbmuxd` listing it over USB the whole time. Retry
before concluding anything about the cable or the pairing.

**The guard.** Before any phase of work, and around any wait longer than about
a minute:

```sh
xcrun devicectl device info lockState --device "$UDID" >/dev/null 2>&1
code=$(curl -s -m 4 -o /dev/null -w '%{http_code}' http://127.0.0.1:22087/status)
[ "$code" = 200 ] || "$HOME/devdrv.sh"
```

and inside a polling loop, every 40 to 60 seconds:

```sh
xcrun devicectl device info lockState --device "$UDID" >/dev/null 2>&1
```

A `lockState` call is not a touch and never reaches the app, so it is safe
inside an idle-timeout measurement — it will not reset the thing under test.
Run it inline rather than backgrounded: `&` inside the loop fills the
transcript with job-control noise for no benefit.

## 6. Two incidental things about this Mac

`/tmp` is cleaned aggressively — scripts written there disappeared mid-session,
twice, and a `do script` then silently did nothing because its target was gone.
Write helper scripts to `$HOME`.

There is a file literally named `-` in
`~/Library/Developer/Xcode/UserData/Provisioning Profiles/`. Every `xcodebuild`
run logs `DVTProvisioningProfileManager: Failed to load profile "…/-"` because
of it. Harmless, and it is in every log you will read.

## What goes outward

Worth knowing before running any of this on someone else's account.

**Maestro.** The CLI posts one telemetry event per run to PostHog
(`https://us.i.posthog.com`, a project key), carrying `command` and
`commandStringUsed` — the command line, so a team ID passed as a flag goes with
it — plus `app`, `cli`, `env`, `flutter`, `java`, `os`, `platform`, `xcode`, and
identity fields that are null unless logged into Maestro Cloud. No flow content,
no app binary, no hierarchy: uploading those is `maestro cloud`, a different
command. Off with `MAESTRO_CLI_NO_ANALYTICS=1`, or `"enabled": false` in
`~/.maestro/analytics.json`. Building the driver downloads nothing — the Xcode
project ships inside `maestro-cli-2.8.0.jar` under `driver/ios`.

**Apple.** `-allowProvisioningUpdates` is what creates signing assets when no
local profile matches: an App ID record for each driver bundle id and an
Xcode-managed development profile, both permanent in the team's account and
visible to everyone on it. It needs an authenticated Xcode session; without one
it fails at `GatherProvisioningInputs` before asking for anything — observed
twice, with nothing created either time. The re-signing route in section 3
avoids it entirely, because the profile already exists locally.
