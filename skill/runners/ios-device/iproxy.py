#!/usr/bin/env python3
# usbmux TCP forwarder: Mac 127.0.0.1:<port> -> device 127.0.0.1:<port>.
# Runs ON THE MAC. Physical devices only.
#
#   iproxy.py <udid> <port>
#
# Why this exists: on a simulator the XCUITest driver's HTTP server and the Mac
# share one loopback, so bin/drivers.sh needs no forward. On a phone the server
# binds the *device's* loopback, so the Mac cannot reach it without a usbmux
# bridge. iproxy/libimobiledevice would do it, but neither is installed and there
# is no Homebrew — and /var/run/usbmuxd is world-writable, so a few lines of
# stdlib Python do it with nothing to install. Speaks usbmux: ListDevices to map
# the UDID to a DeviceID, then Connect with the port in network byte order, then
# pipes bytes both ways. Keep it running for the whole session; it prints
# "forwarding ..." when it binds.
import os, socket, struct, plistlib, threading, select, sys

# --tunnel <address>: a phone on wifi (BACKLOG item 99, Part 2). usbmuxd lists
# nothing for it, so there is no DeviceID to Connect to. Instead the phone's
# CoreDevice tunnel address — `devicectl device info details`'
# tunnelIPAddress — is reached over plain TCP, which works only for a driver
# built from driver/build.sh and started with TEST_RUNNER_BIND set to that
# address; the prebuilt driver listens on the phone's loopback alone.
if len(sys.argv) not in (3, 5) or (len(sys.argv) == 5 and sys.argv[3] != "--tunnel"):
    raise SystemExit("usage: iproxy.py <udid> <port> [--tunnel <address>]")
UDID = sys.argv[1]; LPORT = DPORT = int(sys.argv[2])
# A path, or host:port for a usbmuxd over TCP as libimobiledevice allows. The
# tests use the TCP form for a fake, because a sandbox may forbid Unix sockets.
SOCK = os.environ.get("USBMUXD_SOCKET", "/var/run/usbmuxd")


def mux_socket():
    if not SOCK.startswith("/") and ":" in SOCK:
        host, port = SOCK.rsplit(":", 1)
        return socket.create_connection((host, int(port)))
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK)
    return s
TUNNEL = sys.argv[4] if len(sys.argv) == 5 else None
BASE = {"ClientVersionString": "maestro-fwd", "ProgName": "maestro-fwd",
        "kLibUSBMuxVersion": 3}


def mux_send(s, payload, tag=1):
    body = plistlib.dumps(payload)
    s.sendall(struct.pack("<IIII", 16 + len(body), 1, 8, tag) + body)


def mux_recv(s):
    hdr = b""
    while len(hdr) < 16:
        hdr += s.recv(16 - len(hdr))
    ln = struct.unpack("<I", hdr[:4])[0] - 16
    body = b""
    while len(body) < ln:
        body += s.recv(ln - len(body))
    return plistlib.loads(body)


def find_device_id():
    """The phone's current usbmux DeviceID, or None if usbmuxd does not list it."""
    s = mux_socket()
    mux_send(s, dict(BASE, MessageType="ListDevices"))
    r = mux_recv(s); s.close()
    for d in r.get("DeviceList", []):
        if d["Properties"]["SerialNumber"] == UDID:
            return d["DeviceID"]
    return None


def device_id():
    did = find_device_id()
    if did is None:
        raise SystemExit("device %s not on usbmuxd" % UDID)
    return did


def connect_device(did):
    s = mux_socket()
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
                if not data:
                    return
                dst.sendall(data)
    finally:
        a.close(); b.close()


def connect_tunnel():
    return socket.create_connection((TUNNEL, DPORT), timeout=10)


did = None if TUNNEL else device_id()
srv = socket.socket(); srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", LPORT)); srv.listen(64)
if TUNNEL:
    print("forwarding 127.0.0.1:%d -> tunnel [%s] port %d" % (LPORT, TUNNEL, DPORT), flush=True)
else:
    print("forwarding 127.0.0.1:%d -> device %d port %d" % (LPORT, did, DPORT), flush=True)
while True:
    c, _ = srv.accept()
    try:
        if TUNNEL:
            d = connect_tunnel()
        else:
            try:
                d = connect_device(did)
            except Exception:
                # The DeviceID is usbmuxd's, and a phone gets a new one each
                # time it reconnects: standing it up, a cable wiggle. Looked up
                # once at start, a forwarder kept sending to the gone id and
                # reset every connection, and a driver restart never replaced
                # it (BACKLOG item 101, 24 Sep 2026: id 5, then 8, then 10).
                # So on a failed connect, look again and retry once.
                fresh = find_device_id()
                if fresh is None or fresh == did:
                    raise
                print("device id %d -> %d (reconnected)" % (did, fresh), flush=True)
                did = fresh
                d = connect_device(did)
        d.settimeout(None)
    except Exception:
        c.close(); continue
    threading.Thread(target=pump, args=(c, d), daemon=True).start()
