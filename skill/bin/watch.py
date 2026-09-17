#!/usr/bin/env python3
"""Sample a list on the device until something changes, and say what changed.

This exists because `expect` cannot ask the question. `expect` polls for one
element, in the foreground, against a timeout, for a yes or no. The question
that took two days on 15-16 Sep 2026 was "did the SET of rows change, when, and
from what to what" — over hours, with nobody touching the device. Six sessions
wrote their own version of this inside heredocs; no two logged the same fields,
so two logs of one screen could not be compared (BACKLOG items 70, 72).

Four rules, each of them a failure somebody had:

  * NO DEADLINE by default. A watcher given 60 checks x 25s ended ten minutes
    before the expiry it existed to catch, and the run had to be set up again.
  * A FAILED READ IS NOT "NO CHANGE". A cycle that cannot read the device logs
    ERR and leaves the baseline alone, so a dropped driver can never be
    recorded as the list holding steady.
  * THE CONTEXT IS ON EVERY LINE. A log of ids alone does not say which filter
    was in force, and one watcher spent an afternoon on the wrong one. Whatever
    --context matches is written to every line, so the log proves what was
    being watched rather than asserting it.
  * ONE WATCHER PER DEVICE. Two watchers on one device wrote to one log and
    every change arrived twice. A second start refuses and names the first.

Liveness and stopping go through FILES, not pids. Every Bash call here gets its
own PID namespace, so a pid recorded by one call is meaningless to the next —
`kill -0` on it fails for a process that is running perfectly well, and `kill`
cannot reach it either. Measured 17 Sep 2026 while building this: a pid-file
lock reported "NOT watching" over a live watcher and then let a second one
start, which is the exact failure this is meant to prevent. So the log's mtime
is the heartbeat, and a stop is a file the watcher polls for.

It samples through `driver.sh rows --json`, so the row reader and its
visibility arithmetic are shared with everything else rather than re-derived.
"""

import argparse
import collections
import json
import os
import signal
import subprocess
import sys
import time


def now():
    return time.strftime("%H:%M:%S")


def read_rows(cmd, timeout):
    """One sample. Returns (rows, error). Never raises."""
    try:
        p = subprocess.run(cmd, shell=True, capture_output=True,
                           text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, "timed out after %gs" % timeout
    if p.returncode != 0:
        err = (p.stderr or "").strip().splitlines()
        return None, "rows rc=%d %s" % (p.returncode, err[0] if err else "")
    try:
        return json.loads(p.stdout or "[]"), None
    except json.JSONDecodeError as e:
        return None, "rows gave unparseable JSON (%s)" % e


def summarise(rows):
    """The comparable shape of a sample: text in draw order, plus visibility."""
    return [(r["text"], r["vis"]) for r in rows]


def diff(was, now_):
    """What changed between two samples, as (added, removed, moved).

    Counted, not set-based. A list can hold the same text more than once — four
    rows all reading "Search" is a real screen — and membership tests then say
    "nothing added, nothing removed, everything moved" when two rows genuinely
    arrived. Measured 17 Sep 2026 on the springboard home screen, which is
    exactly that shape.

    A row present in both has not left the list even if it has moved or changed
    visibility, and calling that "removed" would be wrong — that distinction is
    the whole of what PROJ-1811 turned on.
    """
    was_t = collections.Counter(t for t, _ in was)
    now_t = collections.Counter(t for t, _ in now_)
    added = sorted((now_t - was_t).elements())
    removed = sorted((was_t - now_t).elements())

    # Of the rows that stayed, did any change place or visibility? Compare the
    # kept rows in order, trimming each side to the shared multiplicity so an
    # arrival elsewhere does not read as every later row having moved.
    keep = was_t & now_t
    def trim(rows):
        left = collections.Counter(keep)
        out = []
        for t, v in rows:
            if left[t]:
                left[t] -= 1
                out.append((t, v))
        return out
    kept_was, kept_now = trim(was), trim(now_)
    moved = sorted({t for a, b in zip(kept_was, kept_now) if a != b for t in (a[0],)})
    return added, removed, moved


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--rows-cmd", required=True,
                    help="command that prints the current rows as JSON")
    ap.add_argument("--context-cmd", default="",
                    help="optional command whose first line is written to every\nsample line — the filter, tab or chip in force")
    ap.add_argument("--interval", type=float, default=20.0)
    ap.add_argument("--cycles", type=int, default=0,
                    help="0 means run until stopped, which is the default and\nusually the right answer")
    ap.add_argument("--timeout", type=float, default=90.0,
                    help="per-sample timeout; a slower one is an ERR, not a stop")
    ap.add_argument("--log", default="")
    ap.add_argument("--label", default="")
    ap.add_argument("--stop-file", default="",
                    help="exit cleanly when this file appears — the only way to stop a\nwatcher from another Bash call, since pids do not cross the namespace")
    ap.add_argument("--claim-file", default="",
                    help="removed on a clean exit, so a later call can tell a finished\nrun from one that is still going")
    args = ap.parse_args()

    # A stop request left behind by the previous run would kill this one on its
    # first slice, so clear it before starting rather than after.
    if args.stop_file and os.path.exists(args.stop_file):
        os.remove(args.stop_file)

    out = open(args.log, "a", buffering=1) if args.log else None

    def say(line):
        print(line, flush=True)
        if out:
            out.write(line + "\n")

    stopping = {"now": False}

    def stop(_sig, _frm):
        stopping["now"] = True

    def asked_to_stop():
        return stopping["now"] or (args.stop_file and os.path.exists(args.stop_file))

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    say("#### watch start %s pid=%d interval=%gs cycles=%s%s"
        % (now(), os.getpid(), args.interval,
           args.cycles or "unlimited",
           " label=%s" % args.label if args.label else ""))

    base = None          # last GOOD sample; an ERR must never overwrite it
    seq = 0
    changes = 0
    while not asked_to_stop():
        seq += 1
        rows, err = read_rows(args.rows_cmd, args.timeout)
        ctx = ""
        if args.context_cmd and rows is not None:
            c, _ = read_rows(args.context_cmd, args.timeout)
            if c:
                ctx = " ctx=%r" % c[0].get("text", "")

        if err is not None:
            # Deliberately no baseline update. A read that failed says nothing
            # about the list, and recording it as "unchanged" is how a watcher
            # reports steadiness through a dead driver.
            say("%04d %s ERR  %s" % (seq, now(), err))
        else:
            cur = summarise(rows)
            say("%04d %s OK n=%d%s  %s"
                % (seq, now(), len(cur), ctx,
                   " ".join("%s[%s]" % (t[:40], v) for t, v in cur)))
            if base is not None and cur != base:
                added, removed, moved = diff(base, cur)
                changes += 1
                say("     >>> CHANGE at %s seq=%d  added=%s removed=%s moved=%s"
                    % (now(), seq, added or [], removed or [], moved or []))
                say("     >>>   was: %s" % (base,))
                say("     >>>   now: %s" % (cur,))
            base = cur

        if args.cycles and seq >= args.cycles:
            break
        # Sleep in short slices so a stop is answered promptly rather than at
        # the end of a 20-second interval.
        waited = 0.0
        while waited < args.interval and not asked_to_stop():
            time.sleep(min(0.25, args.interval - waited))
            waited += 0.25

    say("#### watch end %s seq=%d changes=%d" % (now(), seq, changes))
    for f in (args.claim_file, args.stop_file):
        if f and os.path.exists(f):
            try:
                os.remove(f)
            except OSError:
                pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
