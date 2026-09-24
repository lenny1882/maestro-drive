#!/usr/bin/env bash
# Tests for the maestro-drive package.
#
# Redirects HOME and CLAUDE_DIR into a temp directory, so the real config is
# never touched.
#
# Three things are being tested, in this order:
#
#   1. that every script in skill/ parses, and that none of them contains the
#      ssh-inside-a-loop-reading-stdin bug. These were `ship.sh`'s pre-publish
#      gates. `ship.sh` is gone; the gates are not, so they live here now and a
#      release cannot be cut past them.
#   2. that the package installs, uninstalls, re-installs without drift, and
#      installs from the release tarball rather than only from a checkout.
#   3. that the skill itself still works *after being installed* — the 360
#      behaviour cases in skill/test/run-tests.sh, run out of the installed
#      copy in the throwaway CLAUDE_DIR rather than out of this checkout. That
#      is the difference between "the files arrived" and "the thing works".
set -uo pipefail

# Unset for the whole suite, and set again by the one case that is about it.
# Phase B writes the allowedDomains entry before it probes when this is set,
# because inside a Claude session every connection goes through the sandbox
# proxy and the proxy carries only what that list names. That is a prompt, and
# not one the other cases are testing — inheriting the variable from whatever
# ran the suite would make every fixed answer stream depend on where it was run.
unset grpc_proxy

# Start from a clean environment (BACKLOG item 106). A shell that has sourced a
# project's lib.sh carries that project's conf — APP_ID, DEV, MAC_HOST, LDIR
# and the rest — and config.sh keeps any value already set, so nine tests saw
# the hugoboss app instead of their own and failed. Rather than unset a list
# that has to follow config.sh, run once more under env -i, keeping only what
# the tests need from outside: PATH, HOME (redirected below, but the real one
# is kept for the cases that ask a login shell), TMPDIR (the only writable
# scratch inside a sandbox), TERM and the locale.
if [ -z "${MAESTRO_DRIVE_CLEAN_ENV:-}" ]; then
  exec env -i MAESTRO_DRIVE_CLEAN_ENV=1 PATH="$PATH" HOME="$HOME" \
    ${TMPDIR:+TMPDIR="$TMPDIR"} ${TERM:+TERM="$TERM"} \
    ${LANG:+LANG="$LANG"} ${LC_ALL:+LC_ALL="$LC_ALL"} \
    bash "${BASH_SOURCE[0]}" "$@"
fi

# grep that reads its whole input (BACKLOG item 106). Under pipefail,
# `writer | drain_grep -q` fails when grep matches, exits, and the writer — bash's
# printf writes one line per write(2) into a pipe — is killed by SIGPIPE on its
# next line: a false FAIL on text that matched. Rare, because it needs the
# scheduler to run grep between two of the writer's writes; seen 24 Sep as two
# different tests failing once each in five runs. Assertions on a variable use
# a here-string instead; this is for the ones that pipe a command.
drain_grep() { local r=0; grep "$@" || r=$?; cat > /dev/null; return "$r"; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export CLAUDE_DIR="$TMP/claude"; mkdir -p "$CLAUDE_DIR"

pass=0; fail=0
ok(){ printf '  ok    %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL  %s\n    %s\n' "$1" "$2"; fail=$((fail+1)); }

echo "sanity"
for f in "$REPO"/*.sh "$REPO"/lib/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" && ok "$(basename "$f") parses" || no "$(basename "$f") parses" "syntax error"
done
[ -s "$REPO/VERSION" ] && ok "VERSION is set" || no "VERSION is set" "empty or missing"

echo "the skill's own scripts, before anything is published"
# A broken script here breaks every session that loads the skill, not just the
# one that shipped it. This was the first half of ship.sh.
bad=""
for f in "$REPO"/skill/bin/*.sh "$REPO"/skill/remote/*.sh "$REPO"/skill/hooks/*.sh "$REPO"/skill/setup/*.sh; do
  [ -e "$f" ] || continue
  bash -n "$f" 2>/dev/null || bad="$bad $(basename "$f")"
done
[ -z "$bad" ] && ok "every shell script parses" || no "every shell script parses" "syntax errors in:$bad"

bad=""
for f in "$REPO"/skill/bin/*.py "$REPO"/skill/remote/*.py; do
  [ -e "$f" ] || continue
  python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f" 2>/dev/null \
    || bad="$bad $(basename "$f")"
done
[ -z "$bad" ] && ok "every python file parses" || no "every python file parses" "syntax errors in:$bad"

# _ssh passes stdin to the remote command, so an ssh call inside a loop reading
# from stdin runs once and the rest of the list disappears with a zero exit.
# Three sightings in one afternoon on 17 Sep 2026, in code written beside a
# comment warning about it. This was the second half of ship.sh.
python3 "$REPO/skill/bin/lint-stdin.py" \
  "$REPO"/skill/bin/*.sh "$REPO"/skill/remote/*.sh "$REPO"/skill/hooks/*.sh \
  "$REPO"/skill/setup/*.sh >"$TMP/lint" 2>&1 \
  && ok "no ssh call sits inside a loop reading from stdin" \
  || no "no ssh call sits inside a loop reading from stdin" "$(cat "$TMP/lint")"

# Every shell script is executable in the repo, because git records the bit and
# git archive carries it into the release tarball. It did not used to be: the
# old rsync publish left device.sh without it, ~/.claude refuses chmod +x, and
# a recovery path died with "Permission denied" on a live device (item 46).
unx=$(find "$REPO/skill" -type f -name "*.sh" ! -perm -u+x | sed "s|$REPO/||" | tr '\n' ' ')
[ -z "$unx" ] && ok "every shell script is executable" || no "every shell script is executable" "not executable: $unx"

echo "the setup wizard (item 85)"
# The wizard writes four things a person owns — ~/.ssh/config, settings.json,
# /etc/hosts and a script on the Mac — so what is tested here is the part that
# decides WHAT to write. Everything below runs against copies in $TMP; nothing
# talks to a Mac and nothing touches the real files.
W="$REPO/skill/setup/wizard.sh"
WFN="$TMP/wizard-fns.sh"
sed -n "/^static_default() {/,/^}/p;/^splice_profile() {/,/^}/p;/^drop_profile() {/,/^}/p" "$W" > "$WFN"
# shellcheck disable=SC1090
. "$WFN"

# The static address is proposed, never derived: the router's DHCP pool is not
# visible from the Mac. .250 is what all three existing networks use.
[ "$(static_default 192.168.1.13)" = "192.168.1.250" ] \
  && ok "static address keeps the network and takes .250" \
  || no "static address keeps the network and takes .250" "got $(static_default 192.168.1.13)"
[ "$(static_default 10.0.0.99)" = "10.0.0.250" ] \
  && ok "static address works on a /24 in another range" \
  || no "static address works on a /24 in another range" "got $(static_default 10.0.0.99)"
[ -z "$(static_default not-an-ip)" ] \
  && ok "static address declines to guess from a non-address" \
  || no "static address declines to guess from a non-address" "got $(static_default not-an-ip)"

# A commented-out arm is not an arm. Found 18 Sep against a Mac whose
# Tachikoma:Redux arm had been commented out by hand: unanchored, the pattern
# matched INSIDE the comment — starting after the #, because what follows it is
# whitespace — and the run carried on to the next `;;` that did begin a line,
# which belonged to the live arm after it. That arm was deleted and the orphaned
# # was glued onto the next pattern, commenting it out and leaving its echo with
# nothing to belong to. bash -n caught it and nothing reached the Mac.
CM="$TMP/commented.sh"
cat > "$CM" <<'SCRIPT'
profile_for_ssid() {
  case "$1" in
#    "Commented Net")
#      echo "manual 10.0.1.250 255.255.255.0 10.0.1.1 10.0.1.1"
#      ;;
    "Live Net")
      echo "manual 10.0.2.250 255.255.255.0 10.0.2.1 10.0.2.1"
      ;;
    "Other Net")
      echo "manual 10.0.3.250 255.255.255.0 10.0.3.1 10.0.3.1"
      ;;
    *)
      return 1
      ;;
  esac
}
SCRIPT
cm_action=$(splice_profile "$CM" "Commented Net" "manual 10.0.1.250 255.255.255.0 10.0.1.1 10.0.1.1")
bash -n "$CM" 2>/dev/null \
  && ok "splice: a commented arm does not corrupt the script" \
  || no "splice: a commented arm does not corrupt the script" "$(bash -n "$CM" 2>&1 | head -2)"

grep -q '^    "Live Net")$' "$CM" \
  && grep -q '^    "Other Net")$' "$CM" \
  && ok "splice: the live arms either side of a commented one survive" \
  || no "splice: the live arms either side of a commented one survive" "$(cat "$CM")"

[ "$cm_action" = "added" ] \
  && ok "splice: a commented arm reads as absent, so the SSID is added" \
  || no "splice: a commented arm reads as absent, so the SSID is added" "said $cm_action"

grep -q '^    "Commented Net")$' "$CM" \
  && ok "splice: and the arm it adds is live" \
  || no "splice: and the arm it adds is live" "$(cat "$CM")"

# The comment is a record of a choice, so it stays and the file says what it does.
grep -q '^#    "Commented Net")$' "$CM" \
  && ok "splice: the commented text is left where it was" \
  || no "splice: the commented text is left where it was" "$(cat "$CM")"

# drop_profile carries the same pattern and the same flaw.
cat > "$CM" <<'SCRIPT'
profile_for_ssid() {
  case "$1" in
#    "Commented Net")
#      echo "manual 10.0.1.250 255.255.255.0 10.0.1.1 10.0.1.1"
#      ;;
    "Live Net")
      echo "manual 10.0.2.250 255.255.255.0 10.0.2.1 10.0.2.1"
      ;;
    *)
      return 1
      ;;
  esac
}
SCRIPT
drop_profile "$CM" "Commented Net"
bash -n "$CM" 2>/dev/null && grep -q '^    "Live Net")$' "$CM" \
  && ok "drop: a commented arm is not dropped, and takes no live arm with it" \
  || no "drop: a commented arm is not dropped, and takes no live arm with it" "$(cat "$CM")"

cp "$REPO/skill/setup/network-change.sh" "$TMP/nc.sh"
drop_profile "$TMP/nc.sh" "Example Network Name"
grep -q "Example Network Name" "$TMP/nc.sh" \
  && no "the example SSID is dropped on a fresh install" "it is still there" \
  || ok "the example SSID is dropped on a fresh install"

splice_profile "$TMP/nc.sh" "Somewhere" "manual 10.1.2.250 255.255.255.0 10.1.2.1 10.1.2.1" >/dev/null
# A trailing space in an SSID is real — one of the three on this machine has
# them — and the script compares the name literally, so it has to survive.
splice_profile "$TMP/nc.sh" "Trailing Spaces   " "manual 10.1.3.250 255.255.255.0 10.1.3.1 10.1.3.1" >/dev/null
grep -q '"Trailing Spaces   ")' "$TMP/nc.sh" \
  && ok "an SSID with trailing spaces survives splicing" \
  || no "an SSID with trailing spaces survives splicing" "the arm is missing or trimmed"
# Count case arms only: a line that is a quoted SSID followed by ")". A looser
# pattern catches the printf continuations inside ipv4_config().
arms(){ grep -cE '^    ".*"\)$' "$1"; }
[ "$(arms "$TMP/nc.sh")" = 2 ] \
  && ok "a second network adds an arm rather than replacing the table" \
  || no "a second network adds an arm rather than replacing the table" "$(arms "$TMP/nc.sh") arms"

# ssh takes the first value it obtains for each keyword, so a duplicate arm is
# dead code that silently wins nothing. Same reasoning as the Host block.
r=$(splice_profile "$TMP/nc.sh" "Somewhere" "manual 10.1.2.251 255.255.255.0 10.1.2.1 10.1.2.1")
[ "$r" = "replaced" ] && [ "$(grep -c '"Somewhere")' "$TMP/nc.sh")" = 1 ] \
  && ok "re-adding a network replaces its arm instead of duplicating it" \
  || no "re-adding a network replaces its arm instead of duplicating it" "$r, $(grep -c '"Somewhere")' "$TMP/nc.sh") arms"
grep -q "10.1.2.251" "$TMP/nc.sh" \
  && ok "the replacement carries the new values" \
  || no "the replacement carries the new values" "old values still present"
bash -n "$TMP/nc.sh" \
  && ok "the spliced script still parses" \
  || no "the spliced script still parses" "syntax error after splicing"

# --status reads the three files and changes nothing. Given a config it has
# never seen, it should report what is there and exit clean.
mkdir -p "$TMP/wiz"
printf 'Host mac-somewhere\n\tHostname 10.9.9.9\n\tUser someone\n\tIdentityFile ~/.ssh/somekey\n' > "$TMP/wiz/ssh_config"
touch "$HOME/.ssh_somekey"
out=$(SSH_CONFIG="$TMP/wiz/ssh_config" LIB_DIR="$TMP/wiz/lib" "$W" --status 2>&1)
grep -q "mac-somewhere" <<< "$out" \
  && ok "--status finds a configured network" \
  || no "--status finds a configured network" "$out"
grep -q "no marker" <<< "$out" \
  && ok "--status reports phase A as not done when the marker is absent" \
  || no "--status reports phase A as not done when the marker is absent" "$out"
[ ! -e "$TMP/wiz/lib/phase-a-done" ] \
  && ok "--status writes nothing" \
  || no "--status writes nothing" "it created the marker"

# The /etc/hosts block is replaced wholesale and the rest of the file is not
# touched. File order is try order, so the order it writes is the order asked
# for, not the order the aliases happen to be in.
cat > "$TMP/wiz/hosts" <<'HOSTS'
127.0.0.1	localhost
10.0.0.5	something-unrelated
# mac for ios simulator work
192.168.1.10 the-mac.local
10.0.0.10 the-mac.local
HOSTS
cp "$TMP/wiz/hosts" "$TMP/wiz/hosts.orig"
MARKER_TEXT="# mac for ios simulator work" \
BLOCK="# mac for ios simulator work
10.0.0.10 the-mac.local
192.168.1.10 the-mac.local
" python3 - "$TMP/wiz/hosts" > "$TMP/wiz/hosts.new" <<'PY'
import os, sys
marker = os.environ["MARKER_TEXT"]; block = os.environ["BLOCK"]
lines = open(sys.argv[1]).read().split("\n")
out, i, replaced = [], 0, False
while i < len(lines):
    if lines[i].strip() == marker.strip():
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith("#"):
            i += 1
        out.append(block.rstrip("\n")); replaced = True; continue
    out.append(lines[i]); i += 1
if not replaced:
    while out and not out[-1].strip(): out.pop()
    out.append(""); out.append(block.rstrip("\n"))
sys.stdout.write("\n".join(out).rstrip("\n") + "\n")
PY
grep -q "something-unrelated" "$TMP/wiz/hosts.new" && grep -q "127.0.0.1" "$TMP/wiz/hosts.new" \
  && ok "the hosts rewrite leaves unrelated entries alone" \
  || no "the hosts rewrite leaves unrelated entries alone" "$(cat "$TMP/wiz/hosts.new")"
[ "$(grep -c "the-mac.local" "$TMP/wiz/hosts.new")" = 2 ] \
  && ok "the hosts rewrite does not duplicate the block" \
  || no "the hosts rewrite does not duplicate the block" "$(grep -c "the-mac.local" "$TMP/wiz/hosts.new") lines"
[ "$(grep -n "the-mac.local" "$TMP/wiz/hosts.new" | head -1 | cut -d: -f2- | cut -d' ' -f1)" = "10.0.0.10" ] \
  && ok "the hosts rewrite honours the requested try order" \
  || no "the hosts rewrite honours the requested try order" "first line is not the one asked for"

# A machine with nothing configured is the one this wizard exists for, and was
# the one path never exercised: every earlier test ran against a ~/.ssh/config
# that already had three Host blocks, so the lookups always found something.
# Running it empty aborted at the first prompt with "known_user: unbound
# variable" — `local x` under `set -u` leaves x UNSET, and the loop that would
# assign it never ran.
# ssh is stubbed, not merely pointed at an address that will not answer. What a
# dead address produces is the environment's business — inside this sandbox a
# refused connection arrives as kex_exchange_identification, which is the arm
# that offers to change the username, so the transcript gained a prompt and
# every fixed answer stream slid by one. A refusal is the failure these cases
# want: it casts doubt on neither the address nor the account, so exactly one
# prompt follows it.
ssh_stub() { # ssh_stub <bin dir>
  cat > "$1/ssh" <<'STUB'
#!/bin/sh
echo "ssh: connect to host stub port 22: Connection refused" >&2
exit 255
STUB
  chmod +x "$1/ssh"
}

FR="$TMP/fresh"; mkdir -p "$FR" "$FR/bin"
ssh_stub "$FR/bin"
: > "$FR/ssh_config"; echo '{}' > "$FR/settings.json"
printf '127.0.0.1\tlocalhost\n10.0.0.5\tsomething-unrelated\n' > "$FR/hosts"
mkdir -p "$FR/lib"
# The leading `n` answers "Change any of these?". Phase A stopped being
# create-once on 18 Sep: a re-run now shows the username, the .local name and
# the key it recorded and offers to change them, because a renamed account on
# the Mac was correctable only by editing every Host block by hand.
# The `n` after the address answers "Try again?". A probe that fails now offers
# the way back before it offers the unverified write, so every scripted run
# gained one answer there — and a stream that is short by one feeds the next
# answer into "the Mac's address" and probes a host called `n`.
fresh_out=$(printf 'macuser\nsomemac\n\n10.1.1.5\ny\nmac-newplace\n\nn\ny\nn\n\nn\n' | \
  PATH="$FR/bin:$PATH" SSH_CONFIG="$FR/ssh_config" SETTINGS="$FR/settings.json" \
  HOSTS_FILE="$FR/hosts" LIB_DIR="$FR/lib" timeout 120 "$W" --dry-run 2>&1)
fresh_rc=$?

[ "$fresh_rc" = 0 ] \
  && ok "fresh machine: the wizard runs to completion" \
  || no "fresh machine: the wizard runs to completion" "exit $fresh_rc: $(printf '%s' "$fresh_out" | tail -3)"

grep -q "unbound variable" <<< "$fresh_out" \
  && no "fresh machine: no unbound variable" "$(printf '%s' "$fresh_out" | grep 'unbound')" \
  || ok "fresh machine: no unbound variable"

# Nothing is configured, so nothing can be offered. A default here would be
# invented rather than derived.
grep -q "the Mac's username:" <<< "$fresh_out" \
  && ok "fresh machine: no username default is invented" \
  || no "fresh machine: no username default is invented" "a default was offered"

grep -q "read as somemac.local" <<< "$fresh_out" \
  && ok "fresh machine: a short name gains .local" \
  || no "fresh machine: a short name gains .local" "$(printf '%s' "$fresh_out" | grep -i 'local name')"

# settings.json is {} — the whole sandbox.network path has to be created, not
# assumed to exist.
grep -q '"allowedDomains"' <<< "$fresh_out" \
  && grep -q '"sandbox"' <<< "$fresh_out" \
  && ok "fresh machine: the whole sandbox.network path is created" \
  || no "fresh machine: the whole sandbox.network path is created" "$(printf '%s' "$fresh_out" | grep -A6 'would change')"

# The /etc/hosts step reads Host blocks off disk, and a dry run describes the
# block rather than writing it — so on a fresh machine it saw nothing and said
# "no configured networks" immediately after configuring one.
grep -q "10.1.1.5 somemac.local" <<< "$fresh_out" \
  && ok "fresh machine: /etc/hosts counts the network configured in this run" \
  || no "fresh machine: /etc/hosts counts the network configured in this run" "$(printf '%s' "$fresh_out" | sed -n '/etc\/hosts/,$p' | head -5)"

# Dry run means dry run, on every file it was pointed at.
if [ -s "$FR/ssh_config" ] || [ "$(cat "$FR/settings.json")" != "{}" ] || [ -n "$(ls -A "$FR/lib")" ]; then
  no "fresh machine: --dry-run wrote nothing" "one of ssh_config, settings.json or the marker changed"
else
  ok "fresh machine: --dry-run wrote nothing"
fi

# --- every ssh in the wizard passes -n ---------------------------------------
# A successful ssh reads and discards whatever is on stdin, and in an
# interactive script stdin is where the answers come from. The /etc/hosts
# liveness probe ran `ssh <alias> true` in a loop and ate the rest of the run's
# input whenever an alias actually answered — invisible when a person is typing,
# fatal to a scripted run, and only reproducible against a reachable Mac, which
# is why every test before 18 Sep 2026 missed it. ssh-copy-id is exempt: it must
# keep stdin to read the password.
# Message text mentioning ssh is not an invocation: say/warn/would/ok all take
# a quoted string, and one of them prints the very command a dry run WOULD run.
bad_ssh=$(grep -nE '(^|[^-[:alnum:]_])ssh ' "$W" \
          | grep -v 'ssh-copy-id' \
          | grep -vE '^[0-9]+:[[:space:]]*#' \
          | grep -vE '(say|warn|would|ok|no|confirm) "' \
          | grep -v 'ssh said' \
          | grep -v 'ssh -tt ' \
          | grep -v 'ssh -n ' || true)
[ -z "$bad_ssh" ] \
  && ok "wizard: every ssh passes -n so it cannot eat the answers" \
  || no "wizard: every ssh passes -n so it cannot eat the answers" "$(printf '%s' "$bad_ssh" | head -3)"

# -tt is the deliberate opposite and has to stay rare. Phase C's install is the
# only thing that wants a terminal on the Mac — sudo has to ask for a password
# and the reply has to get back — so it is exempt above, and the exemption is
# worth exactly one call. A second one would be a second way to eat the answers.
tt_count=$(grep -cE '(^|[^-[:alnum:]_])ssh -tt ' "$W")
[ "$tt_count" = 1 ] \
  && ok "wizard: exactly one ssh asks for a terminal, and it is the install" \
  || no "wizard: exactly one ssh asks for a terminal, and it is the install" \
        "$tt_count of them: $(grep -nE '(^|[^-[:alnum:]_])ssh -tt ' "$W" | head -3)"

# /usr/local/bin does not exist on a Mac that has never had Homebrew, and
# `install` does not create parent directories — so on a fresh machine the
# script install fails with "No such file or directory". The directory step goes
# first, and it is guarded: BSD `install -d` on a directory that exists returns 0
# and rewrites its mode and owner anyway, which on an Intel Mac would take
# Homebrew's /usr/local/bin to root:wheel to fix nothing.
printf '%s' "$(sed -n '/install_cmds="/,/bootstrap system/p' "$W")" \
  | head -1 | drain_grep -q '\[ -d .* \] || sudo install -d' \
  && ok "install: the directory is created first, and only when it is missing" \
  || no "install: the directory is created first, and only when it is missing" \
        "$(sed -n '/install_cmds="/,+1p' "$W")"

grep -qE 'ssh -tt "\$alias" "set -e; \$install_cmds"' "$W" \
  && ok "wizard: the install runs under set -e, so a failed step stops the rest" \
  || no "wizard: the install runs under set -e, so a failed step stops the rest" \
        "$(grep -nE 'ssh -tt ' "$W" | head -2)"

# --- every probe at a raw address carries the ProxyCommand -------------------
# A Host block carries the ProxyCommand; a raw user@address has no block and so
# picked up nothing. Inside a Claude session that address is unroutable, ssh
# says "Network is unreachable", and phase B reported it as Remote Login being
# off and offered to write the block unverified — the two-of-three this item
# exists to prevent, arrived at by believing a probe that never ran. Measured
# 18 Sep 2026 against the live Mac: raw address 255, same address with the
# ProxyCommand 0. Phase A's ssh-copy-id and its BatchMode proof are the same
# shape, and are why a fresh machine cannot be set up from inside a session.
bare_probe=$(python3 - "$W" <<'PROBE'
import re, sys
src = open(sys.argv[1]).read()
# Logical lines: a trailing backslash continues the command.
src = re.sub(r"\\\n\s*", " ", src)
bad = []
for line in src.splitlines():
    t = line.strip()
    if t.startswith("#"):
        continue
    if not re.search(r"(^|[^-\w])(ssh|ssh-copy-id|scp)\s", t):
        continue
    # Only the ones naming a raw user@address. An alias target resolves its own
    # block, and "${C_SSH[@]}" is whichever c_target chose.
    if not re.search(r'"\$\w*(user|USER)\w*@\$\w+"', t):
        continue
    if "ProxyCommand" not in t:
        bad.append(t[:90])
print("\n".join(bad))
PROBE
)
[ -z "$bare_probe" ] \
  && ok "wizard: every probe at a raw address carries the ProxyCommand" \
  || no "wizard: every probe at a raw address carries the ProxyCommand" "$bare_probe"

# One string, not two. The block writer and the probes must agree exactly, and
# the way they stop agreeing is a hand-copy that one of them edits.
[ "$(grep -c 'proxyport=3128' "$W")" = 1 ] \
  && ok "wizard: the ProxyCommand is written out once, so it cannot drift" \
  || no "wizard: the ProxyCommand is written out once, so it cannot drift" \
        "$(grep -c 'proxyport=3128' "$W") copies"

# The functional half of the same point: what ssh resolves out of a block this
# wizard wrote, and what it resolves from the -o the probes pass, are the same
# command. %% is the trap — ssh expands % in both places, so a string that is
# right in one and wrong in the other fails only against a real Mac.
PXTMP="$TMP/proxy"; mkdir -p "$PXTMP"
( eval "$(sed -n '/^PROXY_CMD=/,/^)$/p;/^ssh_block_append() {/,/^}/p' "$W")"
  dry() { return 1; }
  SSH_CONFIG="$PXTMP/cfg"; : > "$SSH_CONFIG"
  ssh_block_append probe-alias 10.9.9.9 probeuser "$PXTMP/key"
  ssh -G -F "$SSH_CONFIG" probe-alias 2>/dev/null | grep -i '^proxycommand ' > "$PXTMP/from-block"
  ssh -G -o ProxyCommand="$PROXY_CMD" -o Hostname=10.9.9.9 probe-alias 2>/dev/null \
    | grep -i '^proxycommand ' > "$PXTMP/from-opt" )
if [ -s "$PXTMP/from-block" ] && cmp -s "$PXTMP/from-block" "$PXTMP/from-opt"; then
  ok "wizard: the block's ProxyCommand and the probe's resolve to the same command"
else
  no "wizard: the block's ProxyCommand and the probe's resolve to the same command" \
     "block: $(cat "$PXTMP/from-block" 2>/dev/null | head -c 100)
opt:   $(cat "$PXTMP/from-opt" 2>/dev/null | head -c 100)"
fi

# --- a probe that fails says what to do about it ------------------------------
# Remote Login being off is the failure this hits most, and it is the one a
# person cannot guess the fix for. Before 18 Sep the wizard printed all three
# causes at once and offered only "write it anyway", so the two useful moves —
# turn the setting on, then try again — were both absent. Each diagnosis is
# checked for the action it should name and for the ones it should not: an
# address declared wrong when the fault is a setting sends someone to change
# the thing that was already right.
DIAG="$TMP/diag"; mkdir -p "$DIAG"
diag() { # diag <ssh stderr> -> output; exit status is "the address is suspect"
  ( say() { printf '%s\n' "$*"; }; warn() { printf '%s\n' "$*"; }; ok() { :; }
    MARKER=/dev/null; SETTINGS=/dev/null
    eval "$(sed -n '/^remote_login_help() {/,/^}/p;/^isolation_help() {/,/^}/p;/^probe_diagnosis() {/,/^}/p' "$W")"
    # The real one measures this machine's subnet and ARP table. Stubbed here so
    # both branches are reachable without a second network to run the suite on.
    arp_unanswered() { [ "${ARP_UNANSWERED:-0}" = 1 ]; }
    ip() { printf 'x src 10.9.9.8 x\n'; }
    probe_diagnosis "$1" 10.9.9.9 macuser )
}

refused="ssh: connect to host 10.9.9.9 port 22: Connection refused"
d=$(diag "$refused") || true
grep -q "Remote Login" <<< "$d" \
  && grep -q "System Settings" <<< "$d" \
  && grep -q "setremotelogin" <<< "$d" \
  && ok "a refused probe names Remote Login, the settings path and the command" \
  || no "a refused probe names Remote Login, the settings path and the command" "$d"

# The Mac sent the refusal, so the address reached it. Saying otherwise is the
# wrong repair, and the retry must not ask for the address again.
if diag "$refused" >/dev/null; then
  no "a refused probe does not cast doubt on the address" "it called the address suspect"
else
  ok "a refused probe does not cast doubt on the address"
fi

timedout="ssh: connect to host 10.9.9.9 port 22: Connection timed out"
d=$(diag "$timedout") || true
grep -q "ipconfig getifaddr" <<< "$d" \
  && ok "a timed-out probe says how to read the address off the Mac" \
  || no "a timed-out probe says how to read the address off the Mac" "$d"
if diag "$timedout" >/dev/null; then
  ok "a timed-out probe does cast doubt on the address"
else
  no "a timed-out probe does cast doubt on the address" "it did not"
fi

d=$(diag "ssh: connect to host 10.9.9.9 port 22: Network is unreachable") || true
grep -q "no route" <<< "$d" \
  && ok "an unreachable probe is a route, not a Mac that is switched off" \
  || no "an unreachable probe is a route, not a Mac that is switched off" "$d"

# Never a confident wrong answer. An error this does not recognise has to say so
# rather than pick the nearest arm.
d=$(diag "ssh: something nobody has seen before") || true
grep -q "did not say why" <<< "$d" \
  && ok "an unrecognised error says it is unrecognised" \
  || no "an unrecognised error says it is unrecognised" "$d"

# The one this hit in the field, 18 Sep. Something is listening on 22 and hangs
# up mid-handshake, which on a Mac is Remote Login on but not for this account:
# an account outside com.apple.access_ssh is dropped during the banner exchange
# rather than told no, so it never arrives as Permission denied. It fell through
# to the catch-all, which named the causes and gave no instructions at all.
kex="kex_exchange_identification: Connection closed by remote host"
d=$(diag "$kex") || true
grep -q "Remote Login" <<< "$d" \
  && grep -q "access_ssh" <<< "$d" \
  && ok "a connection closed mid-handshake names Remote Login and the allow list" \
  || no "a connection closed mid-handshake names Remote Login and the allow list" "$d"

# Something answered on 22, so the address and the network are both proven.
if diag "$kex" >/dev/null; then
  no "a connection closed mid-handshake does not cast doubt on the address" "it did"
else
  ok "a connection closed mid-handshake does not cast doubt on the address"
fi

# Unrecognised must not mean silent. Remote Login is the cheapest thing to check
# and the one a person cannot guess, so an error this cannot place still says
# how to rule it out — it just does not claim that is the answer.
d=$(diag "ssh: something nobody has seen before") || true
grep -q "setremotelogin" <<< "$d" \
  && grep -q "did not say why" <<< "$d" \
  && ok "an unrecognised error still says how to rule Remote Login out" \
  || no "an unrecognised error still says how to rule Remote Login out" "$d"

# Every arm that could be Remote Login offers the same words, from one place.
# Captured, never piped: probe_diagnosis exits 1 to mean "the address is not the
# problem", and under pipefail that sinks the whole pipeline however well the
# grep matched — which is what this check first reported as a missing arm.
missing=""
for e in "Connection refused" "$kex" "something nobody has seen before"; do
  d=$(diag "$e") || true
  grep -q "System Settings -> General -> Sharing -> Remote Login" <<< "$d" \
    || missing="$missing $e"
done
[ -z "$missing" ] \
  && ok "every arm that could be Remote Login says how to turn it on" \
  || no "every arm that could be Remote Login says how to turn it on" "missed:$missing"

# The sandbox proxy refusing an address, which is not the Mac at all. Measured
# 18 Sep against a real Mac on a new network: an address in allowedDomains gets
# a connection the Mac then answers, one that is not gets "Bad Gateway" from
# socat before anything leaves this machine — and ssh reports that as
# kex_exchange_identification, which reads as a Mac refusing a login.
d=$(diag "socat[6] E CONNECT 10.9.9.9:22: Bad Gateway") || true
grep -q "sandbox proxy" <<< "$d" \
  && grep -q "allowedDomains" <<< "$d" \
  && ok "a proxy refusal is named as this machine's allowlist, not the Mac" \
  || no "a proxy refusal is named as this machine's allowlist, not the Mac" "$d"

# --- inside a session, allowedDomains comes first -----------------------------
# The ordering this whole item argues for — probe, then write — is unsatisfiable
# for one of the three files. Inside a Claude session every connection goes
# through the sandbox proxy, and the proxy carries only what allowedDomains
# names, so until the address is in it the probe cannot reach the Mac however
# healthy the Mac is. It is also the safe one to write early: an entry permits a
# host, it does not route anything and it cannot make `ssh <alias>` hang.
PX="$TMP/proxyfirst"; mkdir -p "$PX/lib" "$PX/bin"
ssh_stub "$PX/bin"; printf '#!/bin/sh\nexit 1\n' > "$PX/bin/sudo"; chmod +x "$PX/bin/sudo"
: > "$PX/key"
printf 'Host mac-keep\n\tHostname 10.0.0.10\n\tUser testuser\n\tIdentityFile %s\n' \
  "$PX/key" > "$PX/ssh_config"
printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local"]}}}\n' > "$PX/settings.json"
printf '127.0.0.1 localhost\n' > "$PX/hosts"
date +%F > "$PX/lib/phase-a-done"
px=$(printf 'n\ny\nmac-proxy\n10.7.7.7\ny\nn\nn\nmac-proxy\nn\n' | \
  grpc_proxy="http://user:pw@localhost:3128" PATH="$PX/bin:$PATH" \
  SSH_CONFIG="$PX/ssh_config" SETTINGS="$PX/settings.json" \
  HOSTS_FILE="$PX/hosts" LIB_DIR="$PX/lib" timeout 120 "$W" 2>&1)

# Order is the whole point, so it is the order that is asserted.
px_dom=$(printf '%s' "$px" | grep -n "would change" | head -1 | cut -d: -f1)
px_probe=$(printf '%s' "$px" | grep -n "Checking the Mac answers" | head -1 | cut -d: -f1)
if [ -n "$px_dom" ] && [ -n "$px_probe" ] && [ "$px_dom" -lt "$px_probe" ]; then
  ok "in a session: allowedDomains is offered before the probe, not after"
else
  no "in a session: allowedDomains is offered before the probe, not after" \
     "allowedDomains at line ${px_dom:-none}, probe at line ${px_probe:-none}"
fi

grep -q "reads that list when it starts" <<< "$px" \
  && ok "in a session: it says a running session will not see the new entry" \
  || no "in a session: it says a running session will not see the new entry" \
        "$(printf '%s' "$px" | head -20)"

# Outside a session there is no proxy and no allowlist, so the original order
# stands and nothing is written before the probe.
npx=$(printf 'n\ny\nmac-proxy\n10.7.7.7\nn\nn\n' | \
  PATH="$PX/bin:$PATH" SSH_CONFIG="$PX/ssh_config" SETTINGS="$PX/settings.json" \
  HOSTS_FILE="$PX/hosts" LIB_DIR="$PX/lib" timeout 120 "$W" 2>&1)
grep -q "sandbox proxy" <<< "$npx" \
  && no "outside a session: nothing is written before the probe" "it wrote allowedDomains first" \
  || ok "outside a session: nothing is written before the probe"

# Two machines on one subnet with nothing passing between them. Found 18 Sep
# after an afternoon on the Mac: Remote Login on for all users, sshd accepting
# its own loopback, the Mac holding the address it said it held, and neither
# machine able to ping the other. The access point was refusing
# station-to-station traffic, which nothing on either machine reveals — and
# every arm above would have blamed the Mac.
d=$(ARP_UNANSWERED=1 diag "ssh: connect to host 10.9.9.9 port 22: No route to host") || true
grep -q "does not answer ARP" <<< "$d" \
  && grep -qi "isolation" <<< "$d" \
  && ok "same subnet with no ARP reply is named as the access point, not the Mac" \
  || no "same subnet with no ARP reply is named as the access point, not the Mac" "$d"

# The useful part is that it says the Mac is fine, because the Mac is where an
# afternoon goes otherwise.
grep -q "Nothing on the Mac" <<< "$d" \
  && ok "isolation says explicitly that nothing on the Mac is wrong" \
  || no "isolation says explicitly that nothing on the Mac is wrong" "$d"

# It gives the confirming test, from the other end, with this machine's address
# filled in — the check that distinguishes isolation from everything else.
grep -q "ping -c2 10.9.9.8" <<< "$d" \
  && ok "isolation names the ping to run from the Mac, with the address in it" \
  || no "isolation names the ping to run from the Mac, with the address in it" "$d"

# The address is the one thing proven right here — the Mac holds it — so a retry
# must not ask for it again.
if ARP_UNANSWERED=1 diag "ssh: connect to host 10.9.9.9 port 22: No route to host" >/dev/null; then
  no "isolation does not cast doubt on the address" "it did"
else
  ok "isolation does not cast doubt on the address"
fi

# It is a measurement, so it outranks the message — "No route to host" with ARP
# answering is a different fault and must not be read as isolation.
d=$(diag "ssh: connect to host 10.9.9.9 port 22: No route to host") || true
grep -qi "isolation" <<< "$d" \
  && no "an answered ARP is not read as isolation" "$d" \
  || ok "an answered ARP is not read as isolation"

# OpenSSH 9.8 penalises a source address that keeps failing and drops it during
# the handshake — the same symptom as everything else in this arm. It matters
# here because the retry loop is what sustains it: the dropped connection is
# itself another failure, so firing straight back renews the penalty.
d=$(diag "$kex") || true
grep -q "sshd -T | grep -i penal" <<< "$d" \
  && grep -q "launchctl kickstart" <<< "$d" \
  && ok "the closed handshake names source penalties and how to clear them" \
  || no "the closed handshake names source penalties and how to clear them" "$d"

# A refusal is Remote Login off, not a penalty. Naming penalties there would
# send someone to wait out a timer that is not running.
d=$(diag "$refused") || true
grep -q "penal" <<< "$d" \
  && no "a refusal is not read as a penalty" "$d" \
  || ok "a refusal is not read as a penalty"

# --- and offers the way back --------------------------------------------------
# The fix happens on the Mac while the wizard waits, so the retry is the whole
# point: every answer given so far is still in hand and a retry costs one key.
PRB="$TMP/retry"; mkdir -p "$PRB/bin" "$PRB/lib"
cat > "$PRB/bin/ssh" <<'STUB'
#!/bin/sh
n=$(cat "$STUB_COUNT" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$STUB_COUNT"
if [ "$n" -le "${STUB_FAILS:-1}" ]; then
  echo "ssh: connect to host 10.9.9.9 port 22: Connection refused" >&2
  exit 255
fi
exit 0
STUB
chmod +x "$PRB/bin/ssh"
printf '#!/bin/sh\nexit 1\n' > "$PRB/bin/sudo"; chmod +x "$PRB/bin/sudo"
: > "$PRB/key"
date +%F > "$PRB/lib/phase-a-done"

retry_run() { # retry_run <how many probes fail> <answers>
  printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
    "$PRB/key" > "$PRB/ssh_config"
  printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local"]}}}\n' > "$PRB/settings.json"
  printf '127.0.0.1 localhost\n' > "$PRB/hosts"
  : > "$PRB/count"
  printf '%b' "$2" | STUB_COUNT="$PRB/count" STUB_FAILS="$1" PATH="$PRB/bin:$PATH" \
    SSH_CONFIG="$PRB/ssh_config" SETTINGS="$PRB/settings.json" \
    HOSTS_FILE="$PRB/hosts" LIB_DIR="$PRB/lib" timeout 120 "$W" 2>&1
}

# One refusal, then the person turns Remote Login on and says yes.
r=$(retry_run 1 'n\ny\nmac-probe\n10.9.9.9\ny\n\nn\nmac-probe\nn\n')
grep -q "Try again?" <<< "$r" \
  && ok "retry: a failed probe offers the way back" \
  || no "retry: a failed probe offers the way back" "$(printf '%s' "$r" | tail -6)"

grep -q "ssh said: .*Connection refused" <<< "$r" \
  && ok "retry: ssh's own line is printed, not just the verdict" \
  || no "retry: ssh's own line is printed, not just the verdict" "$(printf '%s' "$r" | tail -6)"

# ssh prints its own summary after the ProxyCommand's line, so the line that
# says what happened is not the last one — socat's "Bad Gateway" then ssh's
# kex_exchange_identification, and keeping only the last hid the first.
[ "$(printf '%s' "$r" | grep -c 'ssh said:')" -ge 1 ] \
  && ok "retry: ssh's output is kept by the line, not just its last one" \
  || no "retry: ssh's output is kept by the line, not just its last one" \
        "$(printf '%s' "$r" | head -20)"

grep -q "answers and the key works" <<< "$r" \
  && grep -q "^Host mac-probe$" "$PRB/ssh_config" \
  && ok "retry: saying yes re-probes, and the block is written verified" \
  || no "retry: saying yes re-probes, and the block is written verified" \
        "$(printf '%s' "$r" | tail -6)"

# Nothing is written before the probe passes, so declining both has to leave the
# file exactly as it was — the whole argument for probing first.
r=$(retry_run 99 'n\ny\nmac-probe\n10.9.9.9\nn\nn\n')
if grep -q "^Host mac-probe$" "$PRB/ssh_config"; then
  no "retry: declining both writes nothing" "the block was written anyway"
else
  ok "retry: declining both writes nothing"
fi
grep -q "Nothing has been written yet" <<< "$r" \
  && ok "retry: it says nothing has been written, so the way back is free" \
  || no "retry: it says nothing has been written, so the way back is free" \
        "$(printf '%s' "$r" | tail -6)"

# The unverified write is still reachable, and still says what it is.
r=$(retry_run 99 'n\ny\nmac-probe\n10.9.9.9\nn\ny\n\nn\nmac-probe\nn\n')
grep -q "unverified" <<< "$r" \
  && grep -q "^Host mac-probe$" "$PRB/ssh_config" \
  && ok "retry: the unverified write is still offered, and named as unverified" \
  || no "retry: the unverified write is still offered, and named as unverified" \
        "$(printf '%s' "$r" | tail -6)"

# --- the write path, for real ------------------------------------------------
# Everything above runs --dry-run, so until 18 Sep 2026 the wizard had never
# written anything, even to a copy. Running it for real found three defects in
# one pass. sudo is stubbed on PATH rather than invoked, so /etc/hosts here is a
# file in $TMP and the real one is never touched.
RW="$TMP/realwrite"; mkdir -p "$RW/lib" "$RW/bin"
ssh_stub "$RW/bin"
printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
  "$TMP/fake-key" > "$RW/ssh_config"
: > "$TMP/fake-key"
printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local"]}}}\n' > "$RW/settings.json"
printf '127.0.0.1 localhost\n' > "$RW/hosts"
date +%F > "$RW/lib/phase-a-done"

rw_run() { # rw_run <sudo-exit> -> output; answers are fixed
  printf '#!/bin/sh\nexit %s\n' "$1" > "$RW/bin/sudo"
  chmod +x "$RW/bin/sudo"
  printf 'n\ny\nmac-test\n192.168.99.50\nn\ny\ny\nn\ny\ny\ny\n' | \
    PATH="$RW/bin:$PATH" SSH_CONFIG="$RW/ssh_config" SETTINGS="$RW/settings.json" \
    HOSTS_FILE="$RW/hosts" LIB_DIR="$RW/lib" timeout 120 "$W" 2>&1
}

rw_out=$(rw_run 1)

# The alias just written is already on disk by the time /etc/hosts runs, and
# configured_aliases prints one per LINE. A membership test written with spaces
# never matched, so the network was offered twice as "which do you use most".
[ "$(printf '%s' "$rw_out" | grep -c '^    mac-test ')" = 1 ] \
  && ok "write path: the new alias is listed once, not twice" \
  || no "write path: the new alias is listed once, not twice" \
        "$(printf '%s' "$rw_out" | grep '^    mac-test ' | tr '\n' '/')"

# write_etc_hosts is called as `write_etc_hosts || warn`, which suspends set -e
# for its whole body, so a failing sudo did not abort and `ok written` ran
# anyway. /etc/hosts is the third leg of the all-three-or-none, so a false
# success here is the failure this script exists to prevent.
# Anchored to end of line, not a bare -q: settings.json needs no sudo and
# legitimately reports `ok    written (backup: ...)` in the same run, and that
# line ends in a bracket. Not -qx either — confirm() leaves the prompt and the
# result on one line, so there is no line that is only the result.
grep -qE 'ok    written$' <<< "$rw_out" \
  && no "write path: a failed sudo is not reported as written" "it said written" \
  || ok "write path: a failed sudo is not reported as written"

grep -q "UNCHANGED" <<< "$rw_out" \
  && grep -q "two of three" <<< "$rw_out" \
  && ok "write path: a failed sudo names what is now inconsistent" \
  || no "write path: a failed sudo names what is now inconsistent" \
        "$(printf '%s' "$rw_out" | sed -n '/Apply that/,$p' | head -4)"

[ "$(cat "$RW/hosts")" = "127.0.0.1 localhost" ] \
  && ok "write path: a failed sudo leaves the hosts file alone" \
  || no "write path: a failed sudo leaves the hosts file alone" "$(cat "$RW/hosts")"

# The ssh config is the one file written without sudo, so it lands either way.
grep -q "^Host mac-test$" "$RW/ssh_config" \
  && ok "write path: the Host block is written" \
  || no "write path: the Host block is written" "no Host mac-test in $RW/ssh_config"

ls "$RW"/ssh_config.bak-* >/dev/null 2>&1 \
  && ok "write path: the ssh config is backed up before it is changed" \
  || no "write path: the ssh config is backed up before it is changed" "no .bak-* beside it"

# With sudo working, the same run must report the write and say so once.
rm -f "$RW"/ssh_config.bak-*
printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
  "$TMP/fake-key" > "$RW/ssh_config"
rw_ok=$(rw_run 0)
grep -qE 'ok    written$' <<< "$rw_ok" \
  && ok "write path: a working sudo does report the write" \
  || no "write path: a working sudo does report the write" \
        "$(printf '%s' "$rw_ok" | sed -n '/Apply that/,$p' | head -3)"

# The .local name is read back from settings.json, so declining that step costs
# /etc/hosts too. Saying "nothing to map" read as though there were nothing to
# do; it has to name the consequence.
printf '{}\n' > "$RW/settings.json"
printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
  "$TMP/fake-key" > "$RW/ssh_config"
rw_noname=$(printf 'n\ny\nmac-test\n192.168.99.50\nn\ny\nn\nn\nn\nn\n' | \
  PATH="$RW/bin:$PATH" SSH_CONFIG="$RW/ssh_config" SETTINGS="$RW/settings.json" \
  HOSTS_FILE="$RW/hosts" LIB_DIR="$RW/lib" timeout 120 "$W" 2>&1)
grep -q "cannot be written" <<< "$rw_noname" \
  && ok "write path: an unknown .local name names what it costs" \
  || no "write path: an unknown .local name names what it costs" \
        "$(printf '%s' "$rw_noname" | sed -n '/etc\/hosts/,$p' | head -3)"

# Re-running for an alias that already exists is what a live run does — every
# case above adds a NEW one. The block must be updated in place, not appended
# beside itself, and the address it replaces must leave allowedDomains rather
# than accumulating there.
UP="$TMP/update"; mkdir -p "$UP/lib" "$UP/bin"
ssh_stub "$UP/bin"
printf '#!/bin/sh\nexit 1\n' > "$UP/bin/sudo"; chmod +x "$UP/bin/sudo"
: > "$UP/key"
printf 'Host mac-test\n\tHostname 192.168.99.50\n\tUser testuser\n\tIdentityFile %s\n' \
  "$UP/key" > "$UP/ssh_config"
printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local","192.168.99.50"]}}}\n' > "$UP/settings.json"
printf '127.0.0.1 localhost\n' > "$UP/hosts"
date +%F > "$UP/lib/phase-a-done"
printf 'n\ny\nmac-test\n192.168.99.77\nn\ny\ny\nn\ny\nn\n' | \
  PATH="$UP/bin:$PATH" SSH_CONFIG="$UP/ssh_config" SETTINGS="$UP/settings.json" \
  HOSTS_FILE="$UP/hosts" LIB_DIR="$UP/lib" timeout 120 "$W" >/dev/null 2>&1

[ "$(grep -c '^Host mac-test$' "$UP/ssh_config")" = 1 ] \
  && ok "re-run: an existing Host block is updated, not duplicated" \
  || no "re-run: an existing Host block is updated, not duplicated" \
        "$(grep -c '^Host mac-test$' "$UP/ssh_config") blocks named mac-test"

grep -qE '^[[:space:]]*Hostname 192\.168\.99\.77$' "$UP/ssh_config" \
  && ok "re-run: the Host block carries the new address" \
  || no "re-run: the Host block carries the new address" "$(grep -i hostname "$UP/ssh_config" | tr '\n' '/')"

up_dom=$(python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[1]))['sandbox']['network']['allowedDomains']))" "$UP/settings.json")
case " $up_dom " in
  *" 192.168.99.50 "*) no "re-run: the address it replaced leaves allowedDomains" "still there: $up_dom" ;;
  *" 192.168.99.77 "*) ok "re-run: the address it replaced leaves allowedDomains" ;;
  *) no "re-run: the address it replaced leaves allowedDomains" "new address missing: $up_dom" ;;
esac

# --- listing, and removing without naming ------------------------------------
# A list of aliases alone would hide the failure this item is about, so each row
# says which of the three files knows the network. Two of three is the state
# that produces a failure looking like something else, and it is invisible until
# something asks.
LS="$TMP/list"; mkdir -p "$LS/lib" "$LS/bin"
ssh_stub "$LS/bin"; printf '#!/bin/sh\nexit 1\n' > "$LS/bin/sudo"; chmod +x "$LS/bin/sudo"
: > "$LS/key"
ls_reset() { # <allowedDomains json array> <hosts body>
  { printf 'Host mac-one\n\tHostname 10.0.0.1\n\tUser someuser\n\tIdentityFile %s\n\n' "$LS/key"
    printf 'Host mac-two\n\tHostname 10.0.0.2\n\tUser someuser\n\tIdentityFile %s\n' "$LS/key"
  } > "$LS/ssh_config"
  printf '{"sandbox":{"network":{"allowedDomains":%s}}}\n' "$1" > "$LS/settings.json"
  printf '%b' "$2" > "$LS/hosts"
  date +%F > "$LS/lib/phase-a-done"
}
ls_wiz() { local answers="$1"; shift
  printf '%b' "$answers" | PATH="$LS/bin:$PATH" SSH_CONFIG="$LS/ssh_config" \
    SETTINGS="$LS/settings.json" HOSTS_FILE="$LS/hosts" LIB_DIR="$LS/lib" \
    timeout 60 "$W" "$@" 2>&1
}

ls_reset '["10.0.0.1","10.0.0.2"]' '10.0.0.1 the-mac.local\n10.0.0.2 the-mac.local\n'
l=$(ls_wiz '' --list) || true
grep -qE '^ *mac-one +10\.0\.0\.1 +someuser +yes +yes +yes' <<< "$l" \
  && ok "list: a network in all three files reads yes three times" \
  || no "list: a network in all three files reads yes three times" "$l"
grep -q "every network is in all three files" <<< "$l" \
  && ok "list: it says so when nothing is missing" \
  || no "list: it says so when nothing is missing" "$l"

# The state this item exists to catch: the Host block is there and one of the
# other two is not, which fails as something that names neither.
ls_reset '["10.0.0.1"]' '10.0.0.1 the-mac.local\n'
l=$(ls_wiz '' --list) || true
grep -qE '^ *mac-two +10\.0\.0\.2 +someuser +yes +NO +NO' <<< "$l" \
  && ok "list: a network missing from the other two files is marked NO" \
  || no "list: a network missing from the other two files is marked NO" "$l"
grep -q "the sandbox proxy refuses it" <<< "$l" \
  && grep -q "will not resolve" <<< "$l" \
  && ok "list: it says what each missing file costs, not just that it is missing" \
  || no "list: it says what each missing file costs, not just that it is missing" "$l"

# --remove with nothing after it. Typing an alias from memory is how the wrong
# one goes, so the list it prints is the same one --list prints.
ls_reset '["10.0.0.1","10.0.0.2"]' '10.0.0.1 the-mac.local\n10.0.0.2 the-mac.local\n'
l=$(ls_wiz 'mac-two\ny\n\ny\ny\n' --remove) || true
grep -q "mac-one" <<< "$l" \
  && grep -q '^Host mac-one$' "$LS/ssh_config" \
  && ok "remove: a bare --remove lists what there is and removes the pick" \
  || no "remove: a bare --remove lists what there is and removes the pick" \
        "$(printf '%s' "$l" | head -12)"
grep -q '^Host mac-two$' "$LS/ssh_config" \
  && no "remove: the picked network is the one that goes" "mac-two is still there" \
  || ok "remove: the picked network is the one that goes"

# An empty answer must not be read as a choice.
ls_reset '["10.0.0.1","10.0.0.2"]' '10.0.0.1 the-mac.local\n'
l=$(ls_wiz '\n' --remove) || true
grep -q '^Host mac-two$' "$LS/ssh_config" \
  && grep -q "nothing removed" <<< "$l" \
  && ok "remove: an empty pick removes nothing and says so" \
  || no "remove: an empty pick removes nothing and says so" "$(printf '%s' "$l" | tail -4)"

# `--remove --dry-run` must not try to remove a network called --dry-run.
ls_reset '["10.0.0.1","10.0.0.2"]' '10.0.0.1 the-mac.local\n'
l=$(ls_wiz 'mac-two\nn\n' --remove --dry-run) || true
grep -q "nothing is written" <<< "$l" \
  && ok "remove: a flag after a bare --remove is a flag, not an alias" \
  || no "remove: a flag after a bare --remove is a flag, not an alias" \
        "$(printf '%s' "$l" | head -8)"

# One write, one question. It asked twice — "Write /etc/hosts with sudo?" before
# the file was built, then "Apply that?" after the diff — both defaulting to no,
# and the second reads as a repeat of the first. Saying yes once left the file
# untouched with no sudo prompt, which is indistinguishable from sudo failing,
# and every test passed because each stream happened to carry a spare answer.
# Reported 18 Sep 2026. So the assertion is the count: one yes writes the file.
HW="$TMP/hostswrite"; mkdir -p "$HW/lib" "$HW/bin"
ssh_stub "$HW/bin"
printf '#!/bin/sh\ncase "$1" in -p) shift;; esac\nexec "$@"\n' > "$HW/bin/sudo"
chmod +x "$HW/bin/sudo"
: > "$HW/key"
{ printf 'Host mac-one\n\tHostname 10.0.0.1\n\tUser someuser\n\tIdentityFile %s\n\n' "$HW/key"
  printf 'Host mac-two\n\tHostname 10.0.0.2\n\tUser someuser\n\tIdentityFile %s\n' "$HW/key"
} > "$HW/ssh_config"
printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local","10.0.0.1","10.0.0.2"]}}}\n' \
  > "$HW/settings.json"
printf '127.0.0.1 localhost\n\n# mac for ios simulator work\n10.0.0.1 the-mac.local\n10.0.0.2 the-mac.local\n' \
  > "$HW/hosts"
date +%F > "$HW/lib/phase-a-done"

# y to remove, blank to apply the settings.json diff, blank for the try-order,
# and ONE y for the hosts write. Nothing spare: a stream carrying a spare answer
# is exactly what hid this.
hw=$(printf 'y\n\n\ny\n' | PATH="$HW/bin:$PATH" SSH_CONFIG="$HW/ssh_config" \
  SETTINGS="$HW/settings.json" HOSTS_FILE="$HW/hosts" LIB_DIR="$HW/lib" \
  timeout 60 "$W" --remove mac-two 2>&1)

grep -q '10.0.0.2' "$HW/hosts" \
  && no "hosts: one yes writes the file" "the address is still in $HW/hosts" \
  || ok "hosts: one yes writes the file"

# Anchored past the hosts prompt: settings.json reports `ok written` in the same
# run, and matching that instead is how this check first passed while the hosts
# file was untouched.
printf '%s' "$hw" | sed -n '/with sudo?/,$p' | drain_grep -qE 'ok    written' \
  && ok "hosts: and it reports the write" \
  || no "hosts: and it reports the write" "$(printf '%s' "$hw" | tail -6)"

# The count itself, so a second confirmation cannot creep back in.
[ "$(printf '%s' "$hw" | grep -c 'with sudo?')" = 1 ] \
  && [ "$(printf '%s' "$hw" | grep -c 'Apply that?')" -le 1 ] \
  && ok "hosts: the write is confirmed once, not twice" \
  || no "hosts: the write is confirmed once, not twice" \
        "$(printf '%s' "$hw" | grep -E 'with sudo\?|Apply that\?')"

# Declining has to say what it costs and how to do it later, because the block
# it just printed is the thing that will not resolve without it.
printf '127.0.0.1 localhost\n\n# mac for ios simulator work\n10.0.0.1 the-mac.local\n10.0.0.2 the-mac.local\n' \
  > "$HW/hosts"
{ printf 'Host mac-one\n\tHostname 10.0.0.1\n\tUser someuser\n\tIdentityFile %s\n\n' "$HW/key"
  printf 'Host mac-two\n\tHostname 10.0.0.2\n\tUser someuser\n\tIdentityFile %s\n' "$HW/key"
} > "$HW/ssh_config"
hwn=$(printf 'y\n\n\nn\n' | PATH="$HW/bin:$PATH" SSH_CONFIG="$HW/ssh_config" \
  SETTINGS="$HW/settings.json" HOSTS_FILE="$HW/hosts" LIB_DIR="$HW/lib" \
  timeout 60 "$W" --remove mac-two 2>&1)
printf '%s' "$hwn" | drain_grep -q -- "--hosts" \
  && grep -q '10.0.0.2' "$HW/hosts" \
  && ok "hosts: declining leaves the file and says how to do it later" \
  || no "hosts: declining leaves the file and says how to do it later" \
        "$(printf '%s' "$hwn" | tail -6)"

# --- phase A as an editor ----------------------------------------------------
# What phase A records goes stale. The Mac's account was renamed on 18 Sep and
# the wizard had no way to say so: the username is read back out of a Host
# block's User line, was never printed, and could only be corrected by editing
# every block by hand. Three blocks here, because one Mac has one account name
# and a change that reaches only the block being added is the same two-of-three
# this whole item is about.
ED="$TMP/edit"; mkdir -p "$ED/lib" "$ED/bin"
ssh_stub "$ED/bin"
printf '#!/bin/sh\nexit 1\n' > "$ED/bin/sudo"; chmod +x "$ED/bin/sudo"
: > "$ED/key"; : > "$ED/key2"
ed_reset() {
  { printf 'Host mac-a\n\tHostname 10.0.0.1\n\tUser olduser\n\tIdentityFile %s\n\n' "$ED/key"
    printf 'Host mac-b\n\tHostname 10.0.0.2\n\tUser olduser\n\tIdentityFile %s\n\n' "$ED/key"
    printf 'Host unrelated\n\tHostname 10.9.9.9\n\tUser someoneelse\n'
  } > "$ED/ssh_config"
  printf '{"sandbox":{"network":{"allowedDomains":["old-mac.local","10.0.0.1"]}}}\n' > "$ED/settings.json"
  printf '127.0.0.1 localhost\n' > "$ED/hosts"
  date +%F > "$ED/lib/phase-a-done"
  rm -f "$ED"/*.bak-*
}
ed_wiz() { # ed_wiz <answers> [args...]
  local answers="$1"; shift
  printf '%b' "$answers" | PATH="$ED/bin:$PATH" SSH_CONFIG="$ED/ssh_config" \
    SETTINGS="$ED/settings.json" HOSTS_FILE="$ED/hosts" LIB_DIR="$ED/lib" \
    timeout 120 "$W" "$@" 2>&1
}

ed_reset
e=$(ed_wiz 'n\nn\n')
grep -q "olduser" <<< "$e" \
  && grep -q "old-mac.local" <<< "$e" \
  && grep -qE "from Host mac-a" <<< "$e" \
  && ok "edit: a re-run shows the username, the name and where each came from" \
  || no "edit: a re-run shows the username, the name and where each came from" \
        "$(printf '%s' "$e" | head -14)"

# Declining is the common case and has to be free.
ed_reset; cp "$ED/ssh_config" "$ED/ssh_config.before"
ed_wiz 'n\nn\n' >/dev/null
cmp -s "$ED/ssh_config" "$ED/ssh_config.before" \
  && ok "edit: declining changes nothing" \
  || no "edit: declining changes nothing" "$(diff "$ED/ssh_config.before" "$ED/ssh_config" | head -4)"

# The change that started this. Every block carrying the old name is offered and
# the default is all of them — one Mac with one account is still the common
# case. The blank after the key answer accepts that default.
ed_reset
ed_wiz 'y\nnewuser\n\n\n\n' --edit >/dev/null
[ "$(grep -c '	User newuser$' "$ED/ssh_config")" = 2 ] \
  && ok "edit: a new username lands in every block offered, by default" \
  || no "edit: a new username lands in every block offered, by default" \
        "$(grep -n User "$ED/ssh_config" | tr '\n' '/')"

grep -q "User someoneelse" "$ED/ssh_config" \
  && ok "edit: a block with no key of ours is left alone" \
  || no "edit: a block with no key of ours is left alone" "the unrelated block was rewritten"

grep -qE '^\s*Hostname 10\.0\.0\.1$' "$ED/ssh_config" \
  && grep -qE '^\s*Hostname 10\.0\.0\.2$' "$ED/ssh_config" \
  && ok "edit: changing the username leaves every address where it was" \
  || no "edit: changing the username leaves every address where it was" \
        "$(grep -i hostname "$ED/ssh_config" | tr '\n' '/')"

ls "$ED"/ssh_config.bak-* >/dev/null 2>&1 \
  && ok "edit: the ssh config is backed up before the username changes" \
  || no "edit: the ssh config is backed up before the username changes" "no .bak-* beside it"

# ~/.ssh/config is the user's file and may name a second Mac, a work account, or
# a host that only looks like ours because it borrows the key. So the list is
# editable rather than only confirmable.
ed_reset
ed_wiz 'y\nnewuser\n\n\nmac-a\n' --edit >/dev/null
[ "$(grep -c '	User newuser$' "$ED/ssh_config")" = 1 ] \
  && grep -q '	User olduser$' "$ED/ssh_config" \
  && ok "edit: naming one block changes that one and leaves the other" \
  || no "edit: naming one block changes that one and leaves the other" \
        "$(grep -n User "$ED/ssh_config" | tr '\n' '/')"

# A name that is not one of the blocks offered is a typo, and a typo that
# quietly changed nothing would read as the edit having worked.
ed_reset
e=$(ed_wiz 'y\nnewuser\n\n\nmac-nope\n' --edit)
grep -q "ignored" <<< "$e" \
  && grep -q '	User olduser$' "$ED/ssh_config" \
  && ok "edit: a block name that is not on offer is named and ignored" \
  || no "edit: a block name that is not on offer is named and ignored" \
        "$(printf '%s' "$e" | tail -5)"

# The .local name lives in allowedDomains and in /etc/hosts, so changing it has
# to reach both — and /etc/hosts is written at the end of the run, not here.
ed_reset
e=$(ed_wiz 'y\n\nnew-mac.local\n\n\ny\ny\n' --edit)
ed_dom=$(python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[1]))['sandbox']['network']['allowedDomains']))" "$ED/settings.json")
case " $ed_dom " in
  *" new-mac.local "*) case " $ed_dom " in
      *" old-mac.local "*) no "edit: a new .local name replaces the old one" "both are there: $ed_dom" ;;
      *) ok "edit: a new .local name replaces the old one" ;;
    esac ;;
  *) no "edit: a new .local name replaces the old one" "not added: $ed_dom" ;;
esac
grep -q "etc/hosts" <<< "$e" \
  && ok "edit: renaming the Mac rewrites /etc/hosts, which maps that name" \
  || no "edit: renaming the Mac rewrites /etc/hosts, which maps that name" \
        "$(printf '%s' "$e" | tail -5)"

# A key the Mac has never been told to trust is not a key, and telling it is
# phase A's own job — so the marker goes and the next run copies it.
ed_reset
ed_wiz "y\n\n\n$ED/key2\nn\n" --edit >/dev/null
[ -e "$ED/lib/phase-a-done" ] \
  && no "edit: a new key clears the phase A marker so it gets copied" "the marker is still there" \
  || ok "edit: a new key clears the phase A marker so it gets copied"

# --status is where someone looks when something is wrong, and the username was
# the one field it did not print.
ed_reset
# Captured, not piped: under pipefail the wizard's own exit status sinks the
# pipeline whatever the grep found. Same trap as the diagnosis checks above.
ed_status=$(ed_wiz '' --status) || true
grep -q "as olduser" <<< "$ed_status" \
  && ok "edit: --status prints the account it would connect as" \
  || no "edit: --status prints the account it would connect as" \
        "$(printf '%s' "$ed_status" | tail -4)"

# --- the remove path, the anti-wizard ----------------------------------------
# Adding writes three things that must agree, so removing has to unwrite the
# same three. A round trip is the test that matters: add a network, take it out,
# and every file is back where it started.
RM="$TMP/remove"; mkdir -p "$RM/lib" "$RM/bin"
ssh_stub "$RM/bin"
printf '#!/bin/sh\ncase "$1" in -p) shift;; esac\nexec "$@"\n' > "$RM/bin/sudo"
chmod +x "$RM/bin/sudo"
: > "$RM/key"
rm_reset() {
  printf 'Host mac-keep\n\tHostname 10.0.0.10\n\tUser testuser\n\tIdentityFile %s\n' \
    "$RM/key" > "$RM/ssh_config"
  printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local","10.0.0.10"]}}}\n' \
    > "$RM/settings.json"
  printf '127.0.0.1 localhost\n\n# mac for ios simulator work\n10.0.0.10 the-mac.local\n' \
    > "$RM/hosts"
  date +%F > "$RM/lib/phase-a-done"
  rm -f "$RM"/*.bak-*
}
rm_wiz() { # rm_wiz <answers> [args...]
  local answers="$1"; shift
  printf '%b' "$answers" | PATH="$RM/bin:$PATH" SSH_CONFIG="$RM/ssh_config" \
    SETTINGS="$RM/settings.json" HOSTS_FILE="$RM/hosts" LIB_DIR="$RM/lib" \
    timeout 120 "$W" "$@" 2>&1
}
rm_domains() { python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[1]))['sandbox']['network']['allowedDomains']))" "$RM/settings.json"; }

rm_reset
cp "$RM/ssh_config" "$RM/ssh_config.orig"; cp "$RM/hosts" "$RM/hosts.orig"
orig_domains=$(rm_domains)
# The `n` is "Try again?" — see the note on the write-path stream above. The
# add half of the round trip is a scripted run like any other and gained the
# same answer.
rm_wiz 'n\ny\nmac-gone\n10.0.0.99\nn\ny\ny\nn\ny\ny\ny\n' >/dev/null
rm_wiz 'y\ny\n\ny\ny\n' --remove mac-gone >/dev/null

diff -q "$RM/ssh_config.orig" "$RM/ssh_config" >/dev/null \
  && ok "remove: a round trip leaves the ssh config where it started" \
  || no "remove: a round trip leaves the ssh config where it started" \
        "$(diff "$RM/ssh_config.orig" "$RM/ssh_config" | head -4 | tr '\n' '/')"

diff -q "$RM/hosts.orig" "$RM/hosts" >/dev/null \
  && ok "remove: a round trip leaves /etc/hosts where it started" \
  || no "remove: a round trip leaves /etc/hosts where it started" \
        "$(diff "$RM/hosts.orig" "$RM/hosts" | head -4 | tr '\n' '/')"

# jq rewrites the file, so the bytes change and the values must not.
[ "$(rm_domains)" = "$orig_domains" ] \
  && ok "remove: a round trip leaves allowedDomains where it started" \
  || no "remove: a round trip leaves allowedDomains where it started" "now: $(rm_domains)"

# Removing the last network takes the key path and the Mac's username with it,
# because both are read back FROM a Host block.
rm_reset
rm_last=$(rm_wiz 'y\n' --remove mac-keep); rm_last_rc=$?
grep -q "only configured network" <<< "$rm_last" \
  && [ "$rm_last_rc" != 0 ] \
  && ok "remove: the last network is refused" \
  || no "remove: the last network is refused" "rc=$rm_last_rc: $(printf '%s' "$rm_last" | tail -2 | tr '\n' '/')"
grep -q "^Host mac-keep$" "$RM/ssh_config" \
  && ok "remove: a refusal writes nothing" \
  || no "remove: a refusal writes nothing" "the block is gone"

# An alias that is not there is a typo, and the useful answer is the list.
rm_unknown=$(rm_wiz '' --remove not-a-network); rm_unknown_rc=$?
[ "$rm_unknown_rc" = 2 ] \
  && grep -q "mac-keep" <<< "$rm_unknown" \
  && ok "remove: an unknown alias exits 2 and lists what is configured" \
  || no "remove: an unknown alias exits 2 and lists what is configured" "rc=$rm_unknown_rc"

# One Host line can name several aliases; removing "the block" would take them
# all, silently.
rm_reset
printf 'Host mac-a mac-b\n\tHostname 10.0.0.77\n\tUser testuser\n\tIdentityFile %s\n' \
  "$RM/key" >> "$RM/ssh_config"
rm_multi=$(rm_wiz 'y\n' --remove mac-a); rm_multi_rc=$?
grep -q "names other aliases too" <<< "$rm_multi" \
  && [ "$rm_multi_rc" != 0 ] \
  && ok "remove: a Host line naming several aliases is refused" \
  || no "remove: a Host line naming several aliases is refused" "rc=$rm_multi_rc"

# An address two aliases share is not this one's to withdraw.
rm_reset
printf 'Host mac-twin\n\tHostname 10.0.0.10\n\tUser testuser\n\tIdentityFile %s\n' \
  "$RM/key" >> "$RM/ssh_config"
rm_shared=$(rm_wiz 'y\n\ny\ny\n' --remove mac-twin)
case " $(rm_domains) " in
  *" 10.0.0.10 "*) ok "remove: an address another alias still uses is kept" ;;
  *) no "remove: an address another alias still uses is kept" "domains now: $(rm_domains)" ;;
esac
grep -q "still uses it" <<< "$rm_shared" \
  && ok "remove: it says which alias is keeping the address" \
  || no "remove: it says which alias is keeping the address" "$(printf '%s' "$rm_shared" | grep -A3 'What goes' | tr '\n' '/')"

echo "installer"
# Two pre-existing hooks from some other package, to prove we leave them alone.
# The second is on matcher "Bash", which is the one this package also wants:
# this machine really does carry gate-unsandboxed-bash.sh there. Our entry must
# go on as a SECOND matcher "Bash" entry rather than joining that one, because
# merging them would make two unrelated packages' hooks ordered.
printf '%s\n' '{"hooks":{
  "Stop":[{"hooks":[{"type":"command","command":"someone-elses-thing"}]}],
  "PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"someone-elses-bash-thing"}]}]
}}' > "$CLAUDE_DIR/settings.json"

# $HOME/.claude.json is where mcpServers live. It is seeded with another
# package's server and with the project records and auth-shaped keys the real
# file carries, so the test fails if the merge flattens anything it should not.
printf '%s\n' '{
  "mcpServers":{"someone-elses-server":{"type":"stdio","command":"other","args":[]}},
  "projects":{"/some/path":{"allowedTools":[]}},
  "oauthAccount":{"accountUuid":"keep-me"}
}' > "$HOME/.claude.json"

"$REPO/install.sh" --link --yes >"$TMP/out" 2>&1 \
  && ok "installs" || no "installs" "$(tail -8 "$TMP/out")"
grep -q "someone-elses-thing" "$CLAUDE_DIR/settings.json" \
  && ok "leaves other packages' entries alone" || no "leaves other packages' entries alone" "removed them"
[ -L "$CLAUDE_DIR/skills/maestro-drive" ] \
  && ok "--link leaves a symlink, so edits to the checkout are live" \
  || no "--link leaves a symlink, so edits to the checkout are live" "it is a copy"

# The three registrations. Until install.sh learned to write them these
# assertions had nothing to find, and the surrounding "leaves other packages
# alone" / "installing twice changes nothing" cases passed on an empty merge.
jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(endswith("hooks/gate-journey-first.sh"))' \
  "$CLAUDE_DIR/settings.json" >/dev/null \
  && ok "registers the PreToolUse gate hook" \
  || no "registers the PreToolUse gate hook" "not in settings.json"

jq -e '[.hooks.SessionEnd[]?.hooks[]?.command] | any(endswith("hooks/rig-down-on-end.sh"))' \
  "$CLAUDE_DIR/settings.json" >/dev/null \
  && ok "registers the SessionEnd rig-down hook" \
  || no "registers the SessionEnd rig-down hook" "not in settings.json"

# Both hooks are invoked as "bash <path>", not by bare path: ~/.claude refuses
# chmod +x, so a hook there cannot be relied on to carry its exec bit.
jq -e '[.hooks | .. | .command? // empty | select(contains("maestro-drive"))]
       | length == 2 and all(startswith("bash /"))' \
  "$CLAUDE_DIR/settings.json" >/dev/null \
  && ok "both hooks run through bash, by absolute path" \
  || no "both hooks run through bash, by absolute path" "$(jq -c '[.hooks|..|.command?//empty]' "$CLAUDE_DIR/settings.json")"

# The ordering point: two separate matcher "Bash" entries, not one merged entry.
jq -e '[.hooks.PreToolUse[] | select(.matcher == "Bash")] as $b
       | ($b | length) == 2
         and ($b | all((.hooks | length) == 1))' \
  "$CLAUDE_DIR/settings.json" >/dev/null \
  && ok "adds a second Bash matcher rather than joining the existing one" \
  || no "adds a second Bash matcher rather than joining the existing one" \
       "$(jq -c '.hooks.PreToolUse' "$CLAUDE_DIR/settings.json")"

grep -q "someone-elses-bash-thing" "$CLAUDE_DIR/settings.json" \
  && ok "leaves the other package's Bash hook alone" \
  || no "leaves the other package's Bash hook alone" "removed it"

jq -e '.mcpServers["maestro-mac"]
       | .command == "bash"
         and (.args[0] | endswith("/skills/maestro-drive/bin/mcp.sh"))
         and (.args[0] | startswith("/"))' \
  "$HOME/.claude.json" >/dev/null \
  && ok "registers the MCP server by absolute path" \
  || no "registers the MCP server by absolute path" "$(jq -c '.mcpServers' "$HOME/.claude.json")"

# Claude Code does not expand ~ in an mcpServers command or arg, so a tilde
# written here would reach exec unexpanded and fail at every session start.
jq -e '[.mcpServers["maestro-mac"] | .command, .args[]] | all(contains("~") | not)' \
  "$HOME/.claude.json" >/dev/null \
  && ok "writes no unexpanded ~ into the MCP entry" \
  || no "writes no unexpanded ~ into the MCP entry" "$(jq -c '.mcpServers["maestro-mac"]' "$HOME/.claude.json")"

jq -e '.mcpServers["someone-elses-server"] and .projects["/some/path"]
       and .oauthAccount.accountUuid == "keep-me"' \
  "$HOME/.claude.json" >/dev/null \
  && ok "leaves other servers, project records and auth state alone" \
  || no "leaves other servers, project records and auth state alone" "$(jq -c 'keys' "$HOME/.claude.json")"

# The bridge server is optional and asked about (BACKLOG item 96). A scripted
# install has nobody to ask, so it registers nothing and says how to add it — a
# capability that appears in an unattended install is one nobody chose.
jq -e '.mcpServers | has("maestro-bridge") | not' "$HOME/.claude.json" >/dev/null \
  && ok "an unattended install does not register the bridge server" \
  || no "an unattended install does not register the bridge server" "$(jq -c '.mcpServers | keys' "$HOME/.claude.json")"

"$REPO/install.sh" --link --yes --with-bridge >/dev/null 2>&1
jq -e '.mcpServers["maestro-bridge"]
       | .command == "python3"
         and (.args[0] | endswith("/skills/maestro-drive/bin/bridge-mcp.py"))
         and (.args[0] | startswith("/"))' \
  "$HOME/.claude.json" >/dev/null \
  && ok "--with-bridge registers it by absolute path, run with python3" \
  || no "--with-bridge registers it by absolute path, run with python3" "$(jq -c '.mcpServers' "$HOME/.claude.json")"

# An update re-runs the installer with whatever flags it was given, so the
# choice has to survive one that says nothing.
"$REPO/install.sh" --link --yes >/dev/null 2>&1
jq -e '.mcpServers | has("maestro-bridge")' "$HOME/.claude.json" >/dev/null \
  && ok "and a later install without the flag keeps it, rather than taking it away" \
  || no "and a later install without the flag keeps it, rather than taking it away" "removed on re-install"

"$REPO/install.sh" --link --yes --no-bridge >/dev/null 2>&1
jq -e '.mcpServers | has("maestro-bridge")' "$HOME/.claude.json" >/dev/null \
  && ok "--no-bridge does not remove one that is already registered — uninstall does that" \
  || no "--no-bridge does not remove one that is already registered — uninstall does that" "removed it"

before=$(jq -S . "$CLAUDE_DIR/settings.json")
before_cj=$(jq -S . "$HOME/.claude.json")
"$REPO/install.sh" --link --yes >/dev/null 2>&1
[ "$before" = "$(jq -S . "$CLAUDE_DIR/settings.json")" ] \
  && ok "installing twice changes nothing" || no "installing twice changes nothing" "settings drifted"
[ "$before_cj" = "$(jq -S . "$HOME/.claude.json")" ] \
  && ok "installing twice leaves .claude.json unchanged" \
  || no "installing twice leaves .claude.json unchanged" ".claude.json drifted"

"$REPO/install.sh" --dry-run >"$TMP/out" 2>&1
grep -q "dry run" "$TMP/out" && ok "--dry-run writes nothing" || no "--dry-run writes nothing" "$(tail -3 "$TMP/out")"

"$REPO/uninstall.sh" --yes >/dev/null 2>&1
if [ -e "$CLAUDE_DIR/skills/maestro-drive" ] || [ -L "$CLAUDE_DIR/skills/maestro-drive" ]; then
  no "uninstall removes the skill" "still there"
else
  ok "uninstall removes the skill"
fi
grep -q "someone-elses-thing" "$CLAUDE_DIR/settings.json" \
  && ok "uninstall leaves other packages alone" || no "uninstall leaves other packages alone" "removed them"
grep -q "someone-elses-bash-thing" "$CLAUDE_DIR/settings.json" \
  && ok "uninstall leaves the other package's Bash hook alone" \
  || no "uninstall leaves the other package's Bash hook alone" "removed it"
jq -e --arg o "maestro-drive" '[.. | .command? // empty] | any(contains($o))' \
  "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 \
  && no "uninstall removes our entries" "still registered" || ok "uninstall removes our entries"

jq -e '.mcpServers | has("maestro-mac")' "$HOME/.claude.json" >/dev/null 2>&1 \
  && no "uninstall removes the MCP entry" "still registered" \
  || ok "uninstall removes the MCP entry"

# Both of them: the bridge entry would otherwise point at a script that has
# just been deleted, which fails at every session start rather than visibly.
jq -e '.mcpServers | has("maestro-bridge")' "$HOME/.claude.json" >/dev/null 2>&1 \
  && no "uninstall removes the bridge entry too" "still registered" \
  || ok "uninstall removes the bridge entry too"
jq -e '.mcpServers["someone-elses-server"] and .projects["/some/path"]
       and .oauthAccount.accountUuid == "keep-me"' \
  "$HOME/.claude.json" >/dev/null \
  && ok "uninstall leaves other servers and account state alone" \
  || no "uninstall leaves other servers and account state alone" "$(jq -c 'keys' "$HOME/.claude.json")"

echo "upgrading from the old name (item 98)"
# The package was maestro-remote-mac until 21 Sep 2026. An upgrade across the
# rename is the one case the OWNS strip cannot see on its own: the entries
# already in settings.json, and the directories already on disk, carry the old
# name. Left behind they are not clutter — a second skill directory is a second
# copy of the skill for Claude Code to load, with its own PreToolUse gate on
# every Bash call and a SessionEnd hook pointing into a tree nothing updates.
OLDSKILL="$CLAUDE_DIR/skills/maestro-remote-mac"
OLDLIB="$HOME/.local/share/maestro-remote-mac"
mkdir -p "$OLDSKILL/hooks" "$OLDLIB"
printf 'stale\n' > "$OLDSKILL/SKILL.md"
printf '2026-09-01\n' > "$OLDLIB/phase-a-done"
printf '%s\n' '{"hooks":{
  "PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash '"$OLDSKILL"'/hooks/gate-journey-first.sh"}]}],
  "SessionEnd":[{"hooks":[{"type":"command","command":"bash '"$OLDSKILL"'/hooks/rig-down-on-end.sh"}]}],
  "Stop":[{"hooks":[{"type":"command","command":"someone-elses-thing"}]}]
}}' > "$CLAUDE_DIR/settings.json"

"$REPO/install.sh" --link --yes >"$TMP/out" 2>&1   && ok "an upgrade from the old name installs"   || no "an upgrade from the old name installs" "$(tail -8 "$TMP/out")"

[ -e "$OLDSKILL" ]   && no "the old skill directory is removed" "still at $OLDSKILL"   || ok "the old skill directory is removed"
[ -e "$OLDLIB" ]   && no "the old lib directory is removed" "still at $OLDLIB"   || ok "the old lib directory is removed"
# Moved, not deleted: phase-a-done says the SSH setup was completed, and losing
# it sends somebody back through a wizard they already finished.
[ -f "$HOME/.local/share/maestro-drive/phase-a-done" ]   && ok "what the old lib directory held is kept, not lost"   || no "what the old lib directory held is kept, not lost" "phase-a-done gone"

jq -e '[.. | .command? // empty] | any(contains("maestro-remote-mac"))'   "$CLAUDE_DIR/settings.json" >/dev/null 2>&1   && no "the old name's hook entries are stripped"        "$(jq -c '[..|.command?//empty]' "$CLAUDE_DIR/settings.json")"   || ok "the old name's hook entries are stripped"
jq -e '[.hooks.PreToolUse[] | select(.matcher == "Bash")] | length == 1'   "$CLAUDE_DIR/settings.json" >/dev/null   && ok "one gate on Bash afterwards, not two"   || no "one gate on Bash afterwards, not two"        "$(jq -c '.hooks.PreToolUse' "$CLAUDE_DIR/settings.json")"
grep -q "someone-elses-thing" "$CLAUDE_DIR/settings.json"   && ok "the sweep still leaves other packages alone"   || no "the sweep still leaves other packages alone" "removed them"

# And uninstall sweeps them too: an uninstall that leaves a skill directory
# Claude Code still loads is not an uninstall.
mkdir -p "$OLDSKILL" "$OLDLIB"
"$REPO/uninstall.sh" --yes >/dev/null 2>&1
{ [ -e "$OLDSKILL" ] || [ -e "$OLDLIB" ]; }   && no "uninstall sweeps the old name's directories" "one of them survived"   || ok "uninstall sweeps the old name's directories"

echo "the README describes both shapes (item 94, 5.4)"
# The skill's own documents are checked by its suite. This one is not installed,
# so it is checked here: a reader whose device is on this machine must not be
# told the only shape is a Mac across a network.
grep -q 'TRANSPORT' "$REPO/README.md" \
  && ok "README.md says where the device is is a setting" \
  || no "README.md says where the device is is a setting" "no mention of TRANSPORT"

echo "release tarball"
# Whether the release tarball is enough to install from — the one thing a git
# checkout can never tell you, because everything is present either way. CI
# builds it with git archive at the tag; this builds the same file list out of
# the checkout and installs it. The rest of the suite then runs against that
# install, because a copy is where the interesting failures are: a symlink
# install cannot drift from its source.
TARBALL_CLAUDE="$TMP/tarball-claude"
TARBALL_SKILL="$TARBALL_CLAUDE/skills/maestro-drive"
if [ -f "$REPO/.github/workflows/release.yml" ]; then
  payload=$(sed -n 's/^ *"\$TAG" -- //p' "$REPO/.github/workflows/release.yml")
  [ -n "$payload" ] && ok "found the payload list in the workflow" || no "found the payload list in the workflow" "no git archive line"
  mkdir -p "$TMP/tarball/maestro-drive"
  ( cd "$REPO" && tar -cf - $payload ) | ( cd "$TMP/tarball/maestro-drive" && tar -xf - )
  CLAUDE_DIR="$TARBALL_CLAUDE" "$TMP/tarball/maestro-drive/install.sh" --yes >"$TMP/out" 2>&1 \
    && ok "a tarball install works" || no "a tarball install works" "$(tail -8 "$TMP/out")"
else
  ok "no release workflow to check (--no-release)"
fi

echo "the live tree is checked against what belongs in it (item 17)"
# The failure this exists for: under the old build/ arrangement three edits were
# made straight into the live tree by sessions that believed it was the source.
# Nothing stated what the published tree was supposed to contain, so all three
# were invisible, and all three would have been destroyed by the next publish.
if [ -d "$TARBALL_SKILL" ]; then
  # shellcheck source=manifest.sh
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-drive"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && ok "a clean install matches" || no "a clean install matches" "it did not"

  echo "a finding written into the live tree, as happened three times" > "$TARBALL_SKILL/reference/stray.md"
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-drive"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && no "a stray file in the live tree is caught" "it passed" || ok "a stray file in the live tree is caught"
  rm -f "$TARBALL_SKILL/reference/stray.md"

  mv "$TARBALL_SKILL/bin/resolve.py" "$TMP/resolve.py.held"
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-drive"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && no "a file missing from the live tree is caught" "it passed" || ok "a file missing from the live tree is caught"
  mv "$TMP/resolve.py.held" "$TARBALL_SKILL/bin/resolve.py"

  # The two exceptions, both of which appear only after the skill has been used.
  # Getting these wrong would fail the check the first time anybody drove a
  # device, which is worse than not having it.
  mkdir -p "$TARBALL_SKILL/bin/__pycache__" "$TARBALL_SKILL/reference/staging"
  : > "$TARBALL_SKILL/bin/__pycache__/resolve.cpython-38.pyc"
  : > "$TARBALL_SKILL/reference/staging/some-project-tooling-findings.md"
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-drive"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && ok "__pycache__ and reference/staging are not strays" \
    || no "__pycache__ and reference/staging are not strays" "one of them was flagged"
  rm -rf "$TARBALL_SKILL/bin/__pycache__" "$TARBALL_SKILL/reference/staging"
else
  no "the live tree is checked" "no tarball install to check against"
fi

echo "the installed skill still works"
# skill/test/run-tests.sh, run out of the installed copy. 360 cases against
# hierarchies captured off real devices; no device, network or real config is
# touched, which is why they can run here at all.
if [ -x "$TARBALL_SKILL/test/run-tests.sh" ]; then
  if "$TARBALL_SKILL/test/run-tests.sh" >"$TMP/skill-tests" 2>&1; then
    ok "the skill's own suite passes from the installed path ($(tail -1 "$TMP/skill-tests"))"
  else
    no "the skill's own suite passes from the installed path" \
       "$(grep -E '^  FAIL' "$TMP/skill-tests" | head -10; tail -1 "$TMP/skill-tests")"
  fi
else
  no "the skill's own suite runs from the installed path" "not installed or not executable"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
