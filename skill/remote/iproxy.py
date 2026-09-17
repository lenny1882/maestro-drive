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
import socket, struct, plistlib, threading, select, sys

if len(sys.argv) != 3:
    raise SystemExit("usage: iproxy.py <udid> <port>")
UDID = sys.argv[1]; LPORT = DPORT = int(sys.argv[2]); SOCK = "/var/run/usbmuxd"
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


def device_id():
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK)
    mux_send(s, dict(BASE, MessageType="ListDevices"))
    r = mux_recv(s); s.close()
    for d in r.get("DeviceList", []):
        if d["Properties"]["SerialNumber"] == UDID:
            return d["DeviceID"]
    raise SystemExit("device %s not on usbmuxd" % UDID)


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
                if not data:
                    return
                dst.sendall(data)
    finally:
        a.close(); b.close()


did = device_id()
srv = socket.socket(); srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", LPORT)); srv.listen(64)
print("forwarding 127.0.0.1:%d -> device %d port %d" % (LPORT, did, DPORT), flush=True)
while True:
    c, _ = srv.accept()
    try:
        d = connect_device(did)
    except Exception:
        c.close(); continue
    threading.Thread(target=pump, args=(c, d), daemon=True).start()
