#!/usr/bin/env python3
"""Every booted simulator, live, on one page. Runs ON THE MAC.

    nohup python3 wall.py 9990 >/tmp/maestro-mac/wall.log 2>&1 &

Why this exists rather than Maestro's own viewer (backlog 64, 65):

  * `maestro mcp` starts a viewer on "a free local port", so every session gets
    a different URL and nobody can bookmark one. This binds a port you choose.
  * That viewer only auto-starts a device when exactly one simulator is booted
    — `if (devices.length !== 1) return` in its bundle — so with two booted it
    shows nothing at all.
  * One viewer holds one device session. This holds as many as are booted.
  * Its `streamUrl` is an absolute loopback URL on a random port
    (`http://127.0.0.1:55885/stream.mjpeg`), which a remote browser cannot
    reach whatever you relay. Here every stream is re-served from this port, so
    one host name and one port is the whole surface.

What it drives. `~/.maestro/deps/simulator-server ios --id <udid>` is Maestro's
own capture binary, spawned directly. It prints

    stream_ready http://127.0.0.1:<port>/stream.mjpeg

on stdout once it is up, and **exits the moment its stdin closes** — that is its
shutdown signal, so the pipe is held open for as long as the device is wanted.

It needs Apple's private SimulatorKit, which it loads from a path compiled into
the binary: /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks.
Xcode 27 moved SimulatorKit to Contents/SharedFrameworks and dropped that
directory, so on Xcode 27 the path has to be put back by hand:

    sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks
    sudo ln -s /Applications/Xcode.app/Contents/SharedFrameworks/SimulatorKit.framework \\
               /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/

`simulator-server verify` says which way round it is. Xcode is an App Store
install, so an Xcode update removes the symlink again.

This never touches an XCUITest driver. Capture and driving are separate paths —
measured: starting every stream here left the drivers on 22087 and 22089 with
the same pids, still answering /deviceInfo.

Anyone on the network can watch. For a dev machine on a network you control that
is the point; do not leave it running otherwise.
"""
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SIMSERVER = os.path.expanduser("~/.maestro/deps/simulator-server")
XCRUN = "/usr/bin/xcrun"
BOUNDARY = b"--NextFrame"
SCAN_SECONDS = 5
UDID_RE = re.compile(r"^[0-9A-Fa-f-]{36}$")

# Whoever is driving a simulator names it, by writing a file next to this
# script over the same SSH connection it drives through. The wall only ever
# reads them, so nothing on the network can rename a device — asked for
# explicitly on 15 Sep 2026: "I'm not writing to the wall."
#
#   labels/<udid>     name=Checkout flow, PR 101
#                     group=brandco-flutter-runner
#                     by=purple · 3fa41c7
#
# One file per device rather than one shared file, so two sessions driving two
# simulators never collide and clearing a label is `rm`. The file's mtime is
# how old the label is — no expiry field to keep, and nothing to clean up.
LABELS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "labels")

# Greying a name that has gone quiet for an hour. A session legitimately idles
# longer than this, so it fades the name rather than removing it.
STALE_AFTER = 3600

# Hiding a name outright: once it is from an earlier CALENDAR DAY, not after a
# fixed number of hours. The maintainer's call, 17 Sep 2026, and it matches how anybody
# reads a wall — a name put up at 09:00 is still today's work at 23:00, and one
# put up at 23:00 is yesterday's by breakfast even though it is ten hours old.
#
# Why it needs hiding at all: nothing removes a label when a session ends, so a
# device nobody picks up again keeps its name for good. On the morning of
# 16 Sep 2026 the wall showed four simulators named 13 hours earlier, none of
# them working, and a tile reading `named 15h ago` under a live session that was
# not the one named on it. The session-end hook and the reclaim on reuse
# (item 67, pieces 1-3) cover every device that gets touched again; this covers
# the one nobody comes back to.
#
# Nothing is deleted. The label file stays, `drivers.sh rig status` still prints
# who last had the device, and the tile still says which handset it is — it just
# stops claiming somebody is driving it.
HIDE_FROM_PREVIOUS_DAY = True


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def parse_label(text):
    """{name, group} from a label file's key=value lines.

    Deliberately not JSON: these are written by a shell heredoc through ssh,
    and quoting a name with an apostrophe in it through two shells is how that
    goes wrong. Unknown keys are ignored so a later field cannot break an
    older wall.
    """
    out = {}
    for line in (text or "").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        k = k.strip().lower()
        if k in ("name", "group", "by"):
            out[k] = v.strip()
    return out


def read_label(udid):
    """{name, group, age, stale} for a device, or {} if nobody has named it."""
    path = os.path.join(LABELS, udid)
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            label = parse_label(fh.read())
        age = max(0, int(time.time() - os.path.getmtime(path)))
    except Exception:
        return {}
    if not label:
        return {}
    # Local time on the Mac, which is where the labels are written and where
    # whoever is reading the wall is sitting.
    if HIDE_FROM_PREVIOUS_DAY:
        named = time.localtime(os.path.getmtime(path))
        today = time.localtime()
        if (named.tm_year, named.tm_yday) != (today.tm_year, today.tm_yday):
            return {}
    label["age"] = age
    label["stale"] = age > STALE_AFTER
    return label


def parse_booted(data):
    """[(udid, name)] from `simctl list devices booted -j`, grouped by runtime.

    simctl lists every runtime it knows, most of them empty, and reports state
    per device — so both have to be filtered rather than assumed.
    """
    found = []
    for runtime, devices in (data.get("devices") or {}).items():
        for d in devices:
            if d.get("state") == "Booted" and d.get("udid"):
                found.append((d["udid"], d.get("name") or d["udid"], runtime))
    found.sort(key=lambda t: (t[2], t[1]))
    return [(u, n) for u, n, _ in found]


def split_frames(buf):
    """(frames, rest) from a partial MJPEG body.

    Parts arrive as `--NextFrame\\r\\nContent-Type:image/jpeg\\r\\n\\r\\n`
    followed by the bytes, with **no Content-Length**, so a frame ends where the
    next boundary begins and the last one is never complete until it does.
    """
    frames = []
    while True:
        start = buf.find(BOUNDARY)
        if start < 0:
            break
        head_end = buf.find(b"\r\n\r\n", start)
        if head_end < 0:
            break
        body = head_end + 4
        nxt = buf.find(BOUNDARY, body)
        if nxt < 0:
            break
        jpeg = buf[body:nxt].rstrip(b"\r\n")
        buf = buf[nxt:]
        if jpeg:
            frames.append(jpeg)
    return frames, buf


def booted_devices():
    """[(udid, name)] for every booted simulator."""
    try:
        out = subprocess.run(
            [XCRUN, "simctl", "list", "devices", "booted", "-j"],
            capture_output=True, timeout=30,
        ).stdout
        return parse_booted(json.loads(out or b"{}"))
    except Exception as e:                      # simctl missing, Xcode broken
        log("simctl failed:", e)
        return []


class Stream:
    """One simulator-server, and the latest frame it has produced.

    Every browser gets its own multipart response generated from `frame`, so a
    viewer joining late sees a picture immediately rather than waiting for the
    next one, and N browsers cost one upstream connection rather than N.
    """

    def __init__(self, udid, name):
        self.udid = udid
        self.name = name
        self.proc = None
        self.url = None
        self.frame = None
        self.seq = 0
        self.error = None
        self.cond = threading.Condition()
        self.stop = threading.Event()

    # -- lifecycle ----------------------------------------------------------
    def start(self):
        if not os.path.exists(SIMSERVER):
            self.error = "simulator-server not found at %s" % SIMSERVER
            log(self.udid, self.error)
            return False
        self.proc = subprocess.Popen(
            [SIMSERVER, "ios", "--id", self.udid],
            stdin=subprocess.PIPE,              # held open: closing it exits it
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        url = None
        deadline = time.time() + 45
        while time.time() < deadline:
            line = self.proc.stdout.readline()
            if not line:
                break
            text = line.decode("utf-8", "replace").rstrip()
            if text.startswith("stream_ready "):
                url = text.split(" ", 1)[1].strip()
                break
            if "Error:" in text:
                self.error = text.split("Error:", 1)[1].strip()
        if not url:
            if not self.error:
                self.error = "simulator-server exited before announcing stream_ready"
            log(self.udid, "no stream:", self.error)
            self.kill()
            return False
        self.url = url
        log(self.udid, self.name, "streaming from", url)
        threading.Thread(target=self._drain, daemon=True).start()
        threading.Thread(target=self._read, daemon=True).start()
        return True

    def kill(self):
        self.stop.set()
        p, self.proc = self.proc, None
        if not p:
            return
        try:
            p.stdin.close()                     # its documented shutdown signal
        except Exception:
            pass
        try:
            p.wait(timeout=5)
        except Exception:
            try:
                p.kill()
            except Exception:
                pass

    def _drain(self):
        """Keep reading its output, or the pipe fills and it blocks."""
        p = self.proc
        while p and not self.stop.is_set():
            line = p.stdout.readline()
            if not line:
                return
            text = line.decode("utf-8", "replace").rstrip()
            if "Error" in text or "error" in text:
                log(self.udid, text)

    # -- frames -------------------------------------------------------------
    def _read(self):
        """Hold one connection to the capture server and publish its frames."""
        while not self.stop.is_set():
            try:
                resp = urllib.request.urlopen(self.url, timeout=30)
            except Exception as e:
                if self.stop.is_set():
                    return
                log(self.udid, "upstream open failed:", e)
                time.sleep(2)
                continue
            buf = b""
            try:
                while not self.stop.is_set():
                    chunk = resp.read(65536)
                    if not chunk:
                        break
                    buf += chunk
                    frames, buf = split_frames(buf)
                    for jpeg in frames:
                        self._publish(jpeg)
                    if len(buf) > 32 * 1024 * 1024:   # never seen; don't grow
                        buf = b""
            except Exception as e:
                if not self.stop.is_set():
                    log(self.udid, "upstream read ended:", e)
            finally:
                try:
                    resp.close()
                except Exception:
                    pass
            if not self.stop.is_set():
                time.sleep(1)

    def _publish(self, jpeg):
        with self.cond:
            self.frame = jpeg
            self.seq += 1
            self.cond.notify_all()

    def wait_frame(self, seen, timeout):
        """Next frame after `seen`, or the current one if there is one."""
        with self.cond:
            if self.seq == seen:
                self.cond.wait(timeout)
            return self.frame, self.seq


class Wall:
    def __init__(self):
        self.streams = {}                       # udid -> Stream
        self.restarting = set()                 # udid -> a hand restart is mid-flight
        self.lock = threading.Lock()

    def scan_forever(self):
        while True:
            try:
                self.scan()
            except Exception as e:
                log("scan failed:", e)
            time.sleep(SCAN_SECONDS)

    def scan(self):
        booted = dict(booted_devices())
        with self.lock:
            known = set(self.streams)
            # A device being restarted by hand is absent from self.streams for a
            # moment. Without this the scan in between sees a booted device with
            # no stream and starts a SECOND capture for it.
            busy = set(self.restarting)
        for udid in known - set(booted) - busy:
            with self.lock:
                s = self.streams.pop(udid, None)
            if s:
                log(udid, "gone; stopping")
                s.kill()
        # A capture process that has died — killed by hand, or it gave up on a
        # device — leaves a Stream that will never produce another frame. Drop
        # it so the loop below starts a fresh one.
        for udid in list(booted):
            if udid in busy:
                continue
            with self.lock:
                s = self.streams.get(udid)
            if s and s.url and (s.proc is None or s.proc.poll() is not None):
                log(udid, "capture process gone; restarting")
                s.kill()
                with self.lock:
                    self.streams.pop(udid, None)

        for udid, name in booted.items():
            if udid in busy:
                continue
            with self.lock:
                existing = self.streams.get(udid)
            # A stream that failed to start is retried on the next scan; one
            # that is running is left alone.
            if existing is not None and existing.url is not None:
                continue
            s = Stream(udid, name)
            if s.start():
                with self.lock:
                    self.streams[udid] = s
            else:
                # Remember the failure so the page can show why, and retry on
                # the next scan rather than spinning here.
                with self.lock:
                    self.streams[udid] = s

    def listing(self):
        with self.lock:
            items = list(self.streams.items())
        out = []
        for u, s in sorted(items, key=lambda t: t[1].name):
            row = {
                "udid": u,
                "device": s.name,
                # Live means the capture server is up, not that a frame has
                # arrived: frames are change-driven, so a simulator sitting on a
                # static screen produces none until something moves. Waiting for
                # one would hide an idle device behind "starting…" forever.
                "live": s.url is not None,
                "error": s.error,
                "name": "",
                "group": "",
                "by": "",
                "age": None,
                "stale": False,
            }
            row.update(read_label(u))
            out.append(row)
        # Grouped devices first, alphabetically; everything unnamed after them.
        out.sort(key=lambda r: (r["group"] == "", r["group"], r["device"]))
        return out

    def restart(self, udid):
        """Tear one device's capture down and bring it straight back.

        A simulator-server can stay alive and stop producing frames. scan() only
        replaces one whose PROCESS has gone, so this state survives every scan
        and that tile never paints again. Measured 18 Sep 2026: the wedged
        capture had used 0.81s of CPU in 26m28s elapsed, beside 14.15s on a
        working one on the same Mac at the same time.

        Reloading the page does not fix it — the browser reconnects to the same
        dead upstream — and reloading the page is itself the thing to avoid on a
        wall showing several devices, because every other tile drops its MJPEG
        connection and has to be re-established. So this restarts one process and
        touches nothing else: the other tiles belong to other sessions.
        """
        booted = dict(booted_devices())
        if udid not in booted:
            return False, "not booted"
        with self.lock:
            if udid in self.restarting:
                return False, "a restart is already running for that device"
            self.restarting.add(udid)
            old = self.streams.pop(udid, None)
        try:
            if old:
                old.kill()
            s = Stream(udid, booted[udid])
            ok = s.start()
            with self.lock:
                self.streams[udid] = s
            log(udid, "reloaded by hand" if ok else "reload failed: %s" % s.error)
            return ok, s.error
        finally:
            with self.lock:
                self.restarting.discard(udid)

    def get(self, udid):
        with self.lock:
            return self.streams.get(udid)


WALL = Wall()

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Simulators</title>
<style>
  :root { color-scheme: light dark; --bg:#f6f6f7; --fg:#111; --mut:#666; --card:#fff; --line:#ddd; }
  @media (prefers-color-scheme: dark) {
    :root { --bg:#131315; --fg:#eee; --mut:#999; --card:#1c1c1f; --line:#2c2c30; }
  }
  * { box-sizing: border-box; }
  body { margin:0; padding:16px; background:var(--bg); color:var(--fg);
         font:14px/1.4 -apple-system, system-ui, sans-serif; }
  h1 { font-size:15px; font-weight:600; margin:0 0 14px; }
  h1 span { color:var(--mut); font-weight:400; }
  /* The WALL flows, not just the cards inside a group. A labelled device and an
     unlabelled one land in different sections, and a section is block-level — so
     two cards that would have sat side by side were stacked one section each,
     with most of both rows empty. min-width:0 lets a wide group shrink so its
     own .row wraps rather than overflowing the page. */
  #wall { display:flex; flex-wrap:wrap; gap:0 22px; align-items:flex-start; }
  .group { flex:0 1 auto; min-width:0; max-width:100%; margin:0 0 22px; }
  .group > h2 { font-size:12px; font-weight:600; text-transform:uppercase;
                letter-spacing:.06em; color:var(--mut); margin:0 0 10px;
                padding-bottom:6px; border-bottom:1px solid var(--line); }
  /* An ungrouped section still gets a heading box, just an invisible one, so its
     card starts level with the grouped ones beside it rather than 42px higher.
     visibility rather than display, because the box has to keep occupying its
     space; and it is only emitted when something else on the page IS named, so a
     wall nobody has labelled is not pushed down by a row of nothing. */
  /* The non-breaking space is load-bearing: an EMPTY block generates no line
     box, so a blank heading kept only its padding, border and margin — 17px of
     the 34px a real one takes — and the cards were still 17px out. */
  .group > h2.blank { visibility:hidden; }
  .group > h2.blank::before { content:"\00a0"; }
  .row { display:flex; flex-wrap:wrap; gap:16px; align-items:flex-start; }
  /* A card is a FIXED size for its class, so the row flows the same whatever is
     booted and whichever way up it is. The card used to shrink-wrap its picture,
     which meant its width changed with the device and with its orientation — a
     landscape iPad 1082px, a portrait one 528px, a phone 349px — so a tile
     arriving, leaving or rotating reflowed every other tile on the row. Backlog
     68 fixed the overflow that came out of the old rule; this fixes the reflow.

     The picture sits in a fixed box and is contained inside it, so an iPad that
     rotates letterboxes within its own card instead of resizing it. An error
     sits in that same box, so a dead tile is exactly the shape of a live one and
     the row does not move when a stream drops. */
  /* max-width as well as width: the width is what makes every card of a class
     identical, and the max-width is what stops a viewport narrower than the card
     being overflowed by it. Measured at 420px: a 432px tablet card ran past the
     edge and took its reload button with it, which the old shrink-to-fit card
     could never do. The media box keeps its height, so a squeezed card
     letterboxes rather than changing shape. */
  .sim { background:var(--card); border:1px solid var(--line); border-radius:10px;
         padding:10px; width:var(--w); max-width:100%; }
  .sim.phone  { --w:264px; --mh:572px; }
  .sim.tablet { --w:432px; --mh:324px; }
  .sim .media { width:100%; height:var(--mh); border-radius:4px; background:#000;
                display:flex; align-items:center; justify-content:center;
                overflow:hidden; }
  /* 100% in BOTH directions with object-fit doing the fitting, not max-* with
     auto sizes: `max-width:100%; width:auto` only ever scales a picture DOWN, so
     a capture smaller than the box sat centred in dead card rather than filling
     it — measured on the wall at 1500x1000, one tile's frame painted 242x525
     inside a 264x572 box while the other filled it exactly. */
  .sim .media img { display:block; width:100%; height:100%; object-fit:contain; }
  /* The reload button sits on the title line rather than under the picture, so
     it is in the same place on a live tile and on a dead one — a dead tile is
     the only kind anyone wants it on. */
  .sim .hd { display:flex; align-items:baseline; gap:8px; }
  .sim .hd h3 { flex:1; min-width:0; }
  .sim button { font:inherit; font-size:11px; color:var(--mut); cursor:pointer;
                background:none; border:1px solid var(--line); border-radius:5px;
                padding:1px 7px; display:inline-flex; align-items:center; gap:4px; }
  .sim button svg { display:block; }
  /* The icon turns while the restart is in flight. Stream.start() waits up to
     45s for stream_ready, so without this the only feedback for most of a
     minute is a disabled button. */
  .sim button.busy svg { animation:spin 1s linear infinite; }
  @keyframes spin { to { transform:rotate(360deg); } }
  .sim button:hover:not(:disabled) { color:var(--fg); }
  .sim button:disabled { opacity:.5; cursor:default; }
  .sim h3 { font-size:13px; font-weight:600; margin:0 0 2px;
            overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .sim .sub { color:var(--mut); font-size:11px; margin:0;
              overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .sim .who { color:var(--mut); font-size:11px; margin:0; opacity:.75;
              overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .sim .sub:last-of-type, .sim .who { margin-bottom:8px; }
  .sim.stale h3 { color:var(--mut); font-weight:400; }
  .sim .err { color:#c33; font-size:12px; padding:0 10px; text-align:center; }
  .empty { color:var(--mut); }
</style>
</head>
<body>
<h1>Simulators <span id="count"></span></h1>
<div id="wall"><p class="empty">Looking&hellip;</p></div>
<script>
const wall = document.getElementById('wall');
const count = document.getElementById('count');
let shown = '';

function ago(sec) {
  if (sec === null) return '';
  if (sec < 90) return 'named just now';
  if (sec < 5400) return 'named ' + Math.round(sec / 60) + 'm ago';
  return 'named ' + Math.round(sec / 3600) + 'h ago';
}

function tile(d) {
  const el = document.createElement('div');
  // Which fixed size this card takes. The model is the only thing that says, and
  // it is on every row already; anything that is not an iPad is phone-shaped.
  el.className = 'sim ' + (/ipad/i.test(d.device) ? 'tablet' : 'phone')
                 + (d.stale ? ' stale' : '');
  const hd = document.createElement('div');
  hd.className = 'hd';
  const h = document.createElement('h3');
  h.textContent = d.name || d.device;
  hd.appendChild(h);
  const btn = document.createElement('button');
  // The circular-arrow refresh glyph, drawn rather than pulled from a font: the
  // wall is served off the Mac with no route to the internet from the machine
  // reading it, so an icon font or a CDN sprite would render as a blank box.
  btn.innerHTML = '<svg viewBox="0 0 16 16" width="11" height="11" aria-hidden="true">'
    + '<path d="M13.65 8a5.65 5.65 0 1 1-1.66-4" fill="none" stroke="currentColor"'
    + ' stroke-width="1.7" stroke-linecap="round"/>'
    + '<path d="M12.15 0.9v3.4h-3.4" fill="none" stroke="currentColor"'
    + ' stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const label = document.createElement('span');
  label.textContent = 'reload';
  btn.appendChild(label);
  btn.title = 'Restart this device\u2019s capture. The other tiles keep streaming.';
  hd.appendChild(btn);
  el.appendChild(hd);
  const sub = document.createElement('p');
  sub.className = 'sub';
  // The model and the short udid always show: a label says what is being
  // driven, not which handset, and both matter when three are on screen.
  sub.textContent = [d.name ? d.device : '', d.udid.slice(0, 8)]
                      .filter(Boolean).join(' \u00b7 ');
  el.appendChild(sub);
  // Who named it and when, on their own line — a wrong name on a shared Mac is
  // only actionable if you can see which session put it there.
  if (d.name) {
    const who = document.createElement('p');
    who.className = 'who';
    who.textContent = [d.by, ago(d.age)].filter(Boolean).join(' \u00b7 ');
    el.appendChild(who);
  }
  const media = document.createElement('div');
  media.className = 'media';
  el.appendChild(media);
  paint(media, d);
  btn.onclick = () => reload(d, media, btn);
  return el;
}

function paint(media, d) {
  media.replaceChildren();
  if (d.live) {
    const img = document.createElement('img');
    img.src = 'device/' + d.udid + '/stream.mjpeg?t=' + Date.now();
    media.appendChild(img);
  } else {
    const p = document.createElement('p');
    p.className = 'err';
    p.textContent = d.error || 'starting\u2026';
    media.appendChild(p);
  }
}

async function reload(d, media, btn) {
  const label = btn.querySelector('span');
  btn.disabled = true;
  btn.classList.add('busy');
  label.textContent = 'reloading';
  // Drop this tile's <img> BEFORE asking for the restart. The browser is still
  // reading the upstream we are about to kill, and it will not open a second
  // connection to a URL it already has one to — so a new src on a live <img>
  // would sit there doing nothing. Only this tile's connection goes; the rest
  // of the wall is untouched, which is the whole point of not reloading.
  media.replaceChildren();
  let r;
  try {
    r = await (await fetch('device/' + d.udid + '/reload', { method: 'POST' })).json();
  } catch (e) {
    r = { ok: false, error: String(e) };
  }
  paint(media, { udid: d.udid, live: !!r.ok, error: r.error });
  shown = '';          // let the next tick rebuild from the server's own view
  btn.disabled = false;
  btn.classList.remove('busy');
  label.textContent = 'reload';
}

async function tick() {
  let devices = [];
  try { devices = await (await fetch('api/devices')).json(); } catch (e) { return; }
  const key = devices.map(d =>
    [d.udid, d.live, d.error || '', d.name, d.group, d.by, d.stale].join(',')).join('|');
  count.textContent = devices.length ? '\u00b7 ' + devices.length : '';
  if (key === shown) return;   // never rebuild a live <img> for nothing
  shown = key;
  if (!devices.length) { wall.innerHTML = '<p class="empty">No simulator is booted.</p>'; return; }
  wall.innerHTML = '';
  const groups = [];
  for (const d of devices) {
    const g = d.group || '';
    let bucket = groups.find(b => b.name === g);
    if (!bucket) groups.push(bucket = { name: g, devices: [] });
    bucket.devices.push(d);
  }
  const anyNamed = groups.some(g => g.name);
  for (const g of groups) {
    const sec = document.createElement('section');
    sec.className = 'group';
    // An ungrouped run gets no heading rather than an "Ungrouped" one, so a
    // machine nobody has labelled looks exactly as it did before. When another
    // group on the page IS named, it gets an invisible one instead, so the cards
    // line up across the row.
    if (g.name || anyNamed) {
      const h = document.createElement('h2');
      if (g.name) h.textContent = g.name; else h.className = 'blank';
      sec.appendChild(h);
    }
    const row = document.createElement('div');
    row.className = 'row';
    for (const d of g.devices) row.appendChild(tile(d));
    sec.appendChild(row);
    wall.appendChild(sec);
  }
}
tick();
setInterval(tick, 5000);
</script>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "maestro-wall"

    def log_message(self, fmt, *args):          # quiet; the wall logs its own
        pass

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path in ("/", "/index.html"):
            return self._bytes(PAGE.encode("utf-8"), "text/html; charset=utf-8")
        if path == "/api/devices":
            body = json.dumps(WALL.listing()).encode("utf-8")
            return self._bytes(body, "application/json")
        parts = path.strip("/").split("/")
        if len(parts) == 3 and parts[0] == "device" and parts[2] == "stream.mjpeg":
            if not UDID_RE.match(parts[1]):
                return self._bytes(b"bad device id", "text/plain", 400)
            return self._stream(parts[1])
        self._bytes(b"not found", "text/plain", 404)

    def do_POST(self):
        path = self.path.split("?", 1)[0]
        parts = path.strip("/").split("/")
        if len(parts) == 3 and parts[0] == "device" and parts[2] == "reload":
            if not UDID_RE.match(parts[1]):
                return self._bytes(b"bad device id", "text/plain", 400)
            # Stream.start() waits up to 45s for stream_ready, so this request is
            # held until the answer is real. ThreadingHTTPServer means the other
            # tiles keep streaming while it does.
            ok, err = WALL.restart(parts[1])
            body = json.dumps({"ok": bool(ok), "error": err}).encode("utf-8")
            return self._bytes(body, "application/json")
        self._bytes(b"not found", "text/plain", 404)

    def _bytes(self, body, ctype, code=200):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        try:
            self.wfile.write(body)
        except Exception:
            pass

    def _stream(self, udid):
        s = WALL.get(udid)
        if not s or not s.url:
            return self._bytes(b"no stream for that device", "text/plain", 404)
        self.send_response(200)
        self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=NextFrame")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Connection", "close")
        self.end_headers()
        seen = -1
        try:
            while True:
                frame, seq = s.wait_frame(seen, 10)
                if s.stop.is_set():
                    return
                if frame is None or seq == seen:
                    continue                    # nothing new; keep the socket
                seen = seq
                self.wfile.write(
                    b"--NextFrame\r\nContent-Type:image/jpeg\r\n"
                    b"Content-Length: " + str(len(frame)).encode() + b"\r\n\r\n"
                )
                self.wfile.write(frame)
                self.wfile.write(b"\r\n")
        except Exception:
            return                              # browser went away


def main(port):
    threading.Thread(target=WALL.scan_forever, daemon=True).start()
    srv = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    srv.daemon_threads = True
    log("wall listening on 0.0.0.0:%d" % port)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        for udid in list(WALL.streams):
            s = WALL.get(udid)
            if s:
                s.kill()


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 9990)
