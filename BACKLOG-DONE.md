

## 165. Three phone states get a generic message or none: flat, landscape, untrusted certificate — **DONE**

**What.** Reported from the same run as item 164 (iPhone 11 Pro, iOS 26.5.2, Xcode 27.2, Maestro 2.12.1).

- **Flat.** Every `/touch` crashed the runner with `ScreenSizeHelper.swift:99: Fatal error: Not implemented yet`,
  after `Device orientation is 5`. `driver.sh` printed only `the device driver for <udid> is not answering —
  restarting it (item 46)`, and not the STAND THE PHONE UPRIGHT message. `_devdrv_hint` in `bin/driver.sh` prints
  that message only when the last 6 lines of `~/devdrv-<udid>.log`, written in the last 600 s, contain
  `ScreenSizeHelper` or `Not implemented yet`. Which of those failed here is not known.
- **Landscape** (orientation 3). `deviceInfo` answered 812x375, and `rows` marked the portrait nodes `off`. Nothing
  warned that the phone was on its side.
- **Untrusted certificate.** After a `flutter run --debug` install, the runner would not launch: `the Developer App
  Certificate is not trusted ... Unable to launch dev.mobile.maestro-driver-iosUITests.xctrunner because it has an
  invalid code signature, inadequate entitlements or its profile has not been explicitly trusted by the user`.
  `device.sh` printed only the `TEST EXECUTE FAILED` / item 46 message, whose fix (restart the driver) does nothing
  here.

**Why.** Each has its own fix (stand the phone up, turn it portrait, trust the developer in Settings → General →
VPN & Device Management), and the messages point at none of them.

**To do.** Get the flat run's `devdrv` log and find why the hint missed. Warn when `deviceInfo` is wider than it
is tall on a phone. Match the untrusted-certificate text in the driver log in `deviceup.sh` and `_devdrv_hint`,
ahead of the item 46 message, and name the Settings path.

**Done so far, 12 Nov 2026.** Tested offline only; nothing run on a phone.
- Flat: `_devdrv_hint` still shows the last six lines of `~/devdrv-<udid>.log`, but now matches the face-up
  and untrusted-certificate texts against the whole log. The likely miss: after the fatal, xcodebuild writes
  its test summary and `Testing failed` lines, which push the fatal above the last six. Not confirmed against
  the real log.
- Landscape: `_ensure_screen` in `bin/driver.sh` warns when a registered phone's `deviceInfo` is wider than
  tall. It warns and carries on, because an iPad may be driven in landscape.
- Untrusted certificate: `_why` in `deviceup.sh` and `_devdrv_hint` in `driver.sh` match `Certificate is
  not trusted` / `explicitly trusted by the user`, ahead of the item 46 message, and name Settings → General
  → VPN & Device Management.
- `physical-device.md`'s list of what must be true first has a portrait line and a trust line.
- `_is_device` reads `${DEVICE_MAP:-}`, so `driver.sh` under a stub `lib.sh` without it no longer stops on
  `set -u`.

**Flat, run on a phone, 12 Nov 2026.** iPhone XS Max `00008020-000A396C3606002E`, flat (`faceUp`), prebuilt
driver forced with `DRIVER_XCTESTRUN=/nonexistent` (the signed source build survives a flat phone). The first
`driver.sh tap` crashed the driver and printed `Bad Gateway` and a settle note, exit 0, naming nothing. Two
causes, neither the tail: over the ssh transport the proxy answers a dead driver with a `Bad Gateway` body and
curl exits 0, so `_post` printed it as the reply; and every CLI verb ending `; echo` exited with echo's status.
The fatal was at line 39 of 91 in the `devdrv` log, so the tail would have missed it too. Fixed: `_gone` in
`bin/driver.sh` recognises `Bad Gateway`; `_post` then fails, says the driver died on that action and runs
`_devdrv_hint`; `_settle` counts it as no answer, runs the hint and returns 2, which fails the CLI verb;
`_echo_rc` keeps `_post`'s status through the trailing `echo` on the eight verbs that ended that way. Rerun:
`POST /touch got 'Bad Gateway'`, the log tail with the fatal, the FACE-UP message, exit 1.

**Waiting on a phone prompt.** The first bring-up on the XS Max failed after about a minute with `Timed out
while enabling automation mode`, and only then said to look at the phone. `deviceup.sh` now says LOOK AT THE
PHONE NOW 10 s into a started driver that is not up (`_waiting_note`), and `device.sh up` streams the
bring-up instead of printing it at the end. Not yet seen live: the retries came up without a prompt.

**Landscape, run on a phone, 12 Nov 2026.** The same XS Max, source-built driver, stood in landscape on the
home screen. `driver.sh rows "."` printed `note: 00008020-000A396C3606002E reports 896x414, wider than tall —
the phone is on its side`, then the rows (77, exit 0), with the 414x896 `Home screen icons` node marked `off`.

**Waiting note, tried on a phone, 12 Nov 2026.** Staging a waiting phone by turning Settings → Developer →
Enable UI Automation off on the XS Max (iOS 18.7.9) did not work: the driver came up in 7 s anyway, so the note
had nothing to fire on. What held the first bring-up at `enabling automation mode` is not known.

**A restart makes the phone wait, 12 Nov 2026.** After the user restarted the XS Max, `device.sh up` at
16:12:46 sat with the phone showing a prompt, and the note stayed silent: `_waiting_note` waited for `Testing
started` in the driver log, and xcodebuild writes that line only at the end (the log read `Running tests...`
from 16:13:08). The bring-up failed at 16:14:10 with `Timed out while enabling automation mode`. With the
prompt answered, the next `device.sh up` came up in 6 s. The note now fires on time alone, 10 s in. The
prompt reads "Enter iPhone Password for 'xctest'" with "Enable UI Automation"; the note quotes it and says
to enter the passcode.

**Waiting note, seen on a phone, 12 Nov 2026.** XS Max restarted again, prompt left unanswered.
`device.sh up` at 16:18:30; `LOOK AT THE PHONE NOW` streamed at 16:18:50 (10 s into the poll, after the
forwarder and tunnel wake); the user entered the passcode; `up on 22187` at 16:19:21, the same bring-up.

**Done, 12 Nov 2026.** Flat, landscape and the waiting note are seen on the XS Max. The untrusted-certificate
messages are tested offline only, against the iPhone 11 Pro run's text: on iOS, untrusting a developer means
deleting every app it signed, and on the XS Max the driver (team `38RS7YKR5P`) sits beside four project builds
that would each need a signed rebuild. Left that way by the user's decision.
