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
        for udid in known - set(booted):
            with self.lock:
                s = self.streams.pop(udid, None)
            if s:
                log(udid, "gone; stopping")
                s.kill()
        # A capture process that has died — killed by hand, or it gave up on a
        # device — leaves a Stream that will never produce another frame. Drop
        # it so the loop below starts a fresh one.
        for udid in list(booted):
            with self.lock:
                s = self.streams.get(udid)
            if s and s.url and (s.proc is None or s.proc.poll() is not None):
                log(udid, "capture process gone; restarting")
                s.kill()
                with self.lock:
                    self.streams.pop(udid, None)

        for udid, name in booted.items():
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
  .group { margin:0 0 22px; }
  .group > h2 { font-size:12px; font-weight:600; text-transform:uppercase;
                letter-spacing:.06em; color:var(--mut); margin:0 0 10px;
                padding-bottom:6px; border-bottom:1px solid var(--line); }
  .row { display:flex; flex-wrap:wrap; gap:16px; align-items:flex-start; }
  /* The tile takes its width from the picture inside it. The old rule capped
     the card at 340px and sized the image from its height alone, so nothing
     capped the image's WIDTH and it ran straight out of the card: at 70vh in a
     1080px-tall window a portrait iPad is 528px wide and a landscape one
     1082px. A phone is 349px, so it overflowed by 9px and nobody saw it for a
     day. Backlog 68. */
  .sim { background:var(--card); border:1px solid var(--line); border-radius:10px;
         padding:10px; }
  /* Only a tile with no picture needs a width of its own — with one, the
     picture supplies it, and a floor would leave dead card beside a narrow
     phone on a small screen. */
  .sim:not(:has(img)) { min-width:260px; }
  /* Capped in BOTH directions with no width or height set, so the browser keeps
     the aspect ratio and scales to whichever limit binds first — a portrait
     iPad is height-bound, a landscape one width-bound. The width cap is
     viewport-relative rather than a constant so one landscape iPad cannot take
     a whole row: at 46vw two still sit side by side.

     The height cap is --tile-h, which tick() sets from how many devices are on
     the page. At a fixed 70vh a phone is 756px tall in a 1080px window, three
     tiles overflow the row, the third wraps and most of the first row is left
     empty. Shrinking the cap as tiles arrive keeps them on one line. */
  .sim img { display:block; width:auto; height:auto;
             max-height:var(--tile-h, 70vh); max-width:46vw;
             border-radius:4px; background:#000; }
  /* Text must not widen the tile. A shrink-to-fit card is as wide as its widest
     child, so a long label would stretch the card past its picture and an
     ellipsis would never trigger. width:0 keeps these out of that calculation;
     min-width:100% then fills whatever width the image settled on. */
  .sim h3, .sim .sub, .sim .who, .sim .err { width:0; min-width:100%; }
  .sim h3 { font-size:13px; font-weight:600; margin:0 0 2px;
            overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .sim .sub { color:var(--mut); font-size:11px; margin:0; }
  .sim .who { color:var(--mut); font-size:11px; margin:0; opacity:.75; }
  .sim .sub:last-of-type, .sim .who { margin-bottom:8px; }
  .sim.stale h3 { color:var(--mut); font-weight:400; }
  /* A tile with no picture has nothing to take its width from, so it falls back
     to the card's min-width and a long error wraps inside it — an error tile and
     a live one are then the same shape, not two different widths. */
  .sim .err { color:#c33; font-size:12px; }
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
  el.className = 'sim' + (d.stale ? ' stale' : '');
  const h = document.createElement('h3');
  h.textContent = d.name || d.device;
  el.appendChild(h);
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
  if (d.live) {
    const img = document.createElement('img');
    img.src = 'device/' + d.udid + '/stream.mjpeg?t=' + Date.now();
    el.appendChild(img);
  } else {
    const p = document.createElement('p');
    p.className = 'err';
    p.textContent = d.error || 'starting\u2026';
    el.appendChild(p);
  }
  return el;
}

async function tick() {
  let devices = [];
  try { devices = await (await fetch('api/devices')).json(); } catch (e) { return; }
  const key = devices.map(d =>
    [d.udid, d.live, d.error || '', d.name, d.group, d.by, d.stale].join(',')).join('|');
  count.textContent = devices.length ? '\u00b7 ' + devices.length : '';
  // How tall a tile may be, from how many there are. Two fit a row at full
  // height; beyond that the cap comes down so they stay on one line instead of
  // wrapping and leaving the first row half empty. Set on the container so one
  // value drives every tile and the CSS stays a single rule.
  wall.style.setProperty('--tile-h',
    devices.length <= 2 ? '70vh' : devices.length <= 4 ? '46vh' : '34vh');
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
  for (const g of groups) {
    const sec = document.createElement('section');
    sec.className = 'group';
    // An ungrouped run gets no heading rather than an "Ungrouped" one, so a
    // machine nobody has labelled looks exactly as it did before.
    if (g.name) {
      const h = document.createElement('h2');
      h.textContent = g.name;
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
