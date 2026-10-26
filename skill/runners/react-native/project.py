#!/usr/bin/env python3
"""Read a React Native checkout for runners/react-native/framework.sh.

    project.py node <repo> <nvm-dir>       # bin dir of a node react-native accepts
    project.py flavours <repo>             # Android product flavours, one per line
    project.py for-appid <repo> <app-id>   # the flavour that builds <app-id>
    project.py version <repo> [flavour]    # versionName+versionCode, Android

Python rather than sh because both jobs are parses: a semver range out of
react-native's package.json, and nested braces out of build.gradle.
"""
import json
import os
import re
import sys


def _ver(s):
    m = re.match(r"v?(\d+)(?:\.(\d+))?(?:\.(\d+))?", s.strip())
    return tuple(int(g or 0) for g in m.groups()) if m else None


def _satisfies(v, rng):
    # The forms react-native's engines.node has used: ^X.Y.Z and >= X.Y.Z,
    # joined by ||. Anything else returns None, so the caller says it could not
    # tell rather than picking a node that may not run the build.
    for part in rng.split("||"):
        part = part.strip()
        m = re.fullmatch(r"\^\s*(\S+)", part)
        if m:
            lo = _ver(m.group(1))
            if lo is None:
                return None
            if v[0] == lo[0] and v >= lo:
                return True
            continue
        m = re.fullmatch(r">=\s*(\S+)", part)
        if m:
            lo = _ver(m.group(1))
            if lo is None:
                return None
            if v >= lo:
                return True
            continue
        return None
    return False


def node(repo, nvm_dir):
    # A pin in the repo wins when nvm has it. Otherwise the newest nvm node
    # react-native's own engines.node accepts: the default node on a machine
    # with nvm is whatever was last made default, and on this one that is v14,
    # which fails inside Gradle's autolinking step rather than saying so.
    vers = os.path.join(nvm_dir, "versions", "node")
    have = sorted((v for v in (os.listdir(vers) if os.path.isdir(vers) else [])
                   if _ver(v)), key=_ver)
    for pin in (".nvmrc", ".node-version"):
        p = os.path.join(repo, pin)
        if os.path.isfile(p):
            want = open(p).read().strip()
            hit = [v for v in have if v.lstrip("v").startswith(want.lstrip("v"))]
            if hit:
                print(os.path.join(vers, hit[-1], "bin"), "pinned by", pin)
                return 0
            print(f"{pin} pins node {want}, which nvm in {nvm_dir} does not have",
                  file=sys.stderr)
            return 1
    rn = os.path.join(repo, "node_modules", "react-native", "package.json")
    try:
        rng = json.load(open(rn)).get("engines", {}).get("node", "")
    except Exception:
        print("node_modules/react-native/package.json is unreadable, so the node"
              " react-native needs is unknown — run npm install", file=sys.stderr)
        return 1
    ok = [v for v in have if _satisfies(_ver(v), rng)]
    if any(_satisfies(_ver(v), rng) is None for v in have):
        print(f"react-native needs node '{rng}', a range this does not parse",
              file=sys.stderr)
        return 1
    if not ok:
        print(f"react-native needs node '{rng}'; nvm in {nvm_dir} has "
              f"{' '.join(have) or 'none'}", file=sys.stderr)
        return 1
    print(os.path.join(vers, ok[-1], "bin"), f"newest nvm node meeting '{rng}'")
    return 0


def _block(text, name):
    # The body of the first `name {` block, braces balanced. Comments are
    # stripped first, so a commented-out flavour does not count.
    m = re.search(r"\b" + re.escape(name) + r"\s*\{", text)
    if not m:
        return None
    i, depth = m.end(), 1
    while i < len(text) and depth:
        depth += {"{": 1, "}": -1}.get(text[i], 0)
        i += 1
    return text[m.end():i - 1]


def _children(body):
    # Depth-one `name { ... }` blocks inside a block.
    out, i = {}, 0
    for m in re.finditer(r"(\w+)\s*\{", body):
        if m.start() < i:
            continue
        name = m.group(1)
        j, depth = m.end(), 1
        while j < len(body) and depth:
            depth += {"{": 1, "}": -1}.get(body[j], 0)
            j += 1
        out[name] = body[m.end():j - 1]
        i = j
    return out


def _prop(body, key):
    m = re.search(r"\b" + key + r"\s*=?\s*['\"]([^'\"]+)['\"]", body or "")
    return m.group(1) if m else None


def _gradle(repo):
    p = os.path.join(repo, "android", "app", "build.gradle")
    if not os.path.isfile(p):
        p += ".kts"
    text = open(p).read()
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"(?m)//.*$", "", text)
    return text


def flavours(repo):
    pf = _block(_gradle(repo), "productFlavors")
    for name in _children(pf or ""):
        print(name)
    return 0


def for_appid(repo, appid):
    # The app id a variant installs as is defaultConfig's applicationId, then
    # the flavour's own applicationId if it has one, then the flavour's suffix,
    # then the build type's suffix. Every flavour and build type is tried, and
    # more than one flavour matching is refused with the candidates named.
    text = _gradle(repo)
    base = _prop(_block(text, "defaultConfig"), "applicationId")
    fl = _children(_block(text, "productFlavors") or "") or {"": ""}
    bt = _children(_block(text, "buildTypes") or "") or {"debug": "", "release": ""}
    hits = []
    for f, fb in fl.items():
        fid = (_prop(fb, "applicationId") or base or "") + (_prop(fb, "applicationIdSuffix") or "")
        for b, bb in bt.items():
            if fid + (_prop(bb, "applicationIdSuffix") or "") == appid and f not in hits:
                hits.append(f)
    if len(hits) == 1:
        if hits[0]:
            print(hits[0])
        return 0
    if not hits:
        print(f"no Android variant installs as {appid}", file=sys.stderr)
        return 1
    print(f"{len(hits)} flavours install as {appid}: {' '.join(hits)}", file=sys.stderr)
    return 1


def version(repo, flavour=""):
    # versionName and versionCode from defaultConfig, a flavour's own values
    # replacing them where it sets them. versionCode is a bare integer in
    # Groovy, so it is not read with _prop. Either one missing prints nothing:
    # the caller compares against what is installed, and half a pair would
    # compare as a mismatch.
    text = _gradle(repo)
    blocks = [_block(text, "defaultConfig")]
    if flavour:
        fb = _children(_block(text, "productFlavors") or "").get(flavour)
        if fb is None:
            print(f"no flavour {flavour} in build.gradle", file=sys.stderr)
            return 1
        blocks.append(fb)
    name = code = None
    for b in blocks:
        name = _prop(b, "versionName") or name
        m = re.search(r"\bversionCode\s*=?\s*(\d+)", b or "")
        code = m.group(1) if m else code
    if not (name and code):
        print("build.gradle sets no literal versionName and versionCode", file=sys.stderr)
        return 1
    print(f"{name}+{code}")
    return 0


if __name__ == "__main__":
    cmd, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("", [])
    try:
        if cmd == "node" and len(args) == 2:
            sys.exit(node(*args))
        if cmd == "flavours" and len(args) == 1:
            sys.exit(flavours(*args))
        if cmd == "for-appid" and len(args) == 2:
            sys.exit(for_appid(*args))
        if cmd == "version" and len(args) in (1, 2):
            sys.exit(version(*args))
    except FileNotFoundError as e:
        print(f"project.py: {e.filename} is missing", file=sys.stderr)
        sys.exit(1)
    print(__doc__.strip(), file=sys.stderr)
    sys.exit(2)
