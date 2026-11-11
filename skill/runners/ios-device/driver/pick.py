#!/usr/bin/env python3
"""Choose the identity and profile that sign.sh signs the phone driver with.

    pick.py --identities <find-identity output> --bundle-id <id> [--bundle-id <id>]
            [--udid <udid>] [--now <ISO time>] <profile.mobileprovision>=<decoded.plist> ...

Runs ON THE MAC, from make.sh, which decodes each profile with
`security cms -D` first and passes the pairs: the original path, which is what
sign.sh is given, and the decoded plist, which is what is read here.

A profile qualifies when it is an iOS App Development profile (get-task-allow
true), has not expired, its application-identifier covers every bundle id of
the driver (a pure `*` or a prefix such as `dev.mobile.*`), and one of its
DeveloperCertificates is an identity in the keychain. The certificate is matched
by SHA-1, which is the hash `security find-identity` prints, so the identity is
handed to codesign by hash and two certificates with the same name cannot be
confused. With --udid, the profile must also list that phone.

Several qualify: the one that expires last. Prints one line,
`<sha1>\t<profile path>\t<profile name>\t<identity name>`, and exits 0.
None qualifies: says which requirement every candidate failed, by name, and
exits 1 (BACKLOG item 163).
"""
import argparse
import datetime
import fnmatch
import hashlib
import plistlib
import re
import sys


def identities(text):
    """find-identity -v output -> {sha1: name}."""
    out = {}
    for line in text.splitlines():
        m = re.match(r'\s*\d+\)\s+([0-9A-Fa-f]{40})\s+"(.*)"\s*$', line)
        if m:
            out[m.group(1).upper()] = m.group(2)
    return out


def _when(v):
    if isinstance(v, datetime.datetime):
        return v.replace(tzinfo=None)
    return datetime.datetime.strptime(str(v)[:19], "%Y-%m-%dT%H:%M:%S")


def covers(app_id, bundle_id):
    """Does TEAM.pattern cover bundle_id? The team prefix is dropped first."""
    pattern = app_id.split(".", 1)[1] if "." in app_id else app_id
    return pattern == "*" or fnmatch.fnmatchcase(bundle_id, pattern)


def judge(prof, ids, bundle_ids, udid, now):
    """-> (None, sha1) when it qualifies, else (reason, None)."""
    ent = prof.get("Entitlements", {})
    if ent.get("get-task-allow") is not True:
        return "not a development profile (get-task-allow is not true)", None
    if "ExpirationDate" in prof and _when(prof["ExpirationDate"]) <= now:
        return "expired %s" % _when(prof["ExpirationDate"]).date(), None
    app_id = ent.get("application-identifier", "")
    missed = [b for b in bundle_ids if not covers(app_id, b)]
    if missed:
        return "application-identifier %s does not cover %s" % (app_id, ", ".join(missed)), None
    if udid and udid not in prof.get("ProvisionedDevices", []):
        return "does not list the phone %s" % udid, None
    for der in prof.get("DeveloperCertificates", []):
        h = hashlib.sha1(bytes(der)).hexdigest().upper()
        if h in ids:
            return None, h
    return "none of its certificates is an identity in the login keychain", None


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--identities", required=True)
    ap.add_argument("--bundle-id", action="append", required=True)
    ap.add_argument("--udid", default="")
    ap.add_argument("--now", default="")
    ap.add_argument("profiles", nargs="*")
    a = ap.parse_args(argv)
    now = _when(a.now) if a.now else datetime.datetime.utcnow()

    with open(a.identities) as f:
        ids = identities(f.read())
    if not ids:
        print("pick: no codesigning identity in the login keychain"
              " (security find-identity -v -p codesigning ~/Library/Keychains/login.keychain-db"
              " lists none). Sign in to the Apple account in Xcode > Settings > Accounts"
              " and download the Apple Development certificate.", file=sys.stderr)
        return 1

    best, reasons = None, []
    for pair in a.profiles:
        path, _, decoded = pair.partition("=")
        try:
            with open(decoded, "rb") as f:
                prof = plistlib.load(f)
        except Exception:
            reasons.append((path, "", "could not be read"))
            continue
        name = prof.get("Name", "")
        why, sha = judge(prof, ids, a.bundle_id, a.udid, now)
        if why:
            reasons.append((path, name, why))
            continue
        exp = _when(prof["ExpirationDate"]) if "ExpirationDate" in prof else datetime.datetime.max
        if best is None or exp > best[0]:
            best = (exp, sha, path, name)

    if best:
        _, sha, path, name = best
        print("%s\t%s\t%s\t%s" % (sha, path, name, ids[sha]))
        return 0

    print("pick: no provisioning profile can sign the phone driver (%s)." % ", ".join(a.bundle_id),
          file=sys.stderr)
    print("  It needs an iOS App Development profile, not expired, whose app id covers"
          " those bundle ids (a wildcard such as TEAM.dev.mobile.*), issued for an identity"
          " in the login keychain%s." % (" and listing %s" % a.udid if a.udid else ""),
          file=sys.stderr)
    if not reasons:
        print("  No profiles were found in ~/Library/Developer/Xcode/UserData/Provisioning Profiles"
              " or ~/Library/MobileDevice/Provisioning Profiles.", file=sys.stderr)
    # The near misses first: a profile that covers the bundle ids and fails on
    # one more thing is the one to fix.
    near = [r for r in reasons if "does not cover" not in r[2] and "not a development" not in r[2]]
    for path, name, why in near[:10]:
        print("  %s (%s): %s" % (name or "?", path.rsplit("/", 1)[-1], why), file=sys.stderr)
    rest = len(reasons) - len(near[:10])
    if rest > 0:
        print("  %d other profile(s) are for other apps or are not development profiles." % rest,
              file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
