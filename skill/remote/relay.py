#!/usr/bin/env python3
"""Republish a loopback-bound service on all interfaces. Runs ON THE MAC.

    nohup python3 relay.py 9100 60895 >/dev/null 2>&1 &

Needed because the Dart VM Service binds to the Mac's 127.0.0.1, and the
sandbox can only reach the Mac's LAN address. socat is not installed on that
Mac, so this stands in for `socat TCP-LISTEN:9100,fork,reuseaddr TCP:...`.

Anyone on the network can then reach the service. For a dev build on a network
you control that is fine; do not leave it running otherwise.
"""
import socket
import sys
import threading


def pipe(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        for s in (src, dst):
            try:
                s.close()
            except OSError:
                pass


def main(lport, rport):
    if lport == rport:
        try:
            probe = socket.create_connection(("127.0.0.1", rport), timeout=3)
            probe.close()
        except OSError:
            print(
                f"no service on port {rport} to republish — "
                "start the service first, then run the relay",
                file=sys.stderr,
            )
            sys.exit(1)

    srv = socket.socket()
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", lport))
    srv.listen(64)
    while True:
        client, _ = srv.accept()
        try:
            upstream = socket.create_connection(("127.0.0.1", rport))
        except OSError:
            client.close()
            continue
        for a, b in ((client, upstream), (upstream, client)):
            threading.Thread(target=pipe, args=(a, b), daemon=True).start()


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
