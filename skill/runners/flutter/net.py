#!/usr/bin/env python3
"""Summarise dart:io HTTP profiling pulled from the Dart VM Service.

  net.py list <getHttpProfile.json>
  net.py one  <getHttpProfileRequest.json>

The debug build records every request and response the app made. This is the
source of truth about app state — far better than inferring it from the UI.
"""
import json
import sys


def body(section):
    b = section.get("body") or section.get("bodyBytes")
    if isinstance(b, list):
        try:
            return bytes(b).decode("utf-8", "replace")
        except Exception:
            return repr(b)[:400]
    return b if isinstance(b, str) else ""


def do_list(d):
    reqs = d.get("result", d).get("requests", [])
    for r in reqs:
        req = r.get("request", {}) or {}
        res = r.get("response", {}) or {}
        code = res.get("statusCode") or req.get("statusCode") or "-"
        method = r.get("method") or req.get("method") or "-"
        uri = r.get("uri") or req.get("uri") or "-"
        print(f"{r.get('id','-'):>22} {method:6} {str(code):4} {uri}")


def do_one(d):
    r = d.get("result", d)
    req = r.get("request", {}) or {}
    res = r.get("response", {}) or {}
    print(f"{r.get('method','-')} {r.get('uri','-')}  -> {res.get('statusCode','-')}")
    print("--- request headers ---")
    print(json.dumps(req.get("headers") or r.get("requestHeaders") or {}, indent=2))
    rb = body(req) or body(r)
    if rb:
        print("--- request body ---")
        print(rb[:4000])
    print("--- response body ---")
    print((body(res) or "")[:8000])


if __name__ == "__main__":
    mode = sys.argv[1]
    with open(sys.argv[2]) as fh:
        d = json.load(fh)
    (do_list if mode == "list" else do_one)(d)
