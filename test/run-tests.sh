#!/usr/bin/env bash
# Tests for the maestro-remote-mac package.
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
printf '%s' "$out" | grep -q "mac-somewhere" \
  && ok "--status finds a configured network" \
  || no "--status finds a configured network" "$out"
printf '%s' "$out" | grep -q "no marker" \
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
FR="$TMP/fresh"; mkdir -p "$FR"
: > "$FR/ssh_config"; echo '{}' > "$FR/settings.json"
printf '127.0.0.1\tlocalhost\n10.0.0.5\tsomething-unrelated\n' > "$FR/hosts"
mkdir -p "$FR/lib"
fresh_out=$(printf 'macuser\nsomemac\n\n10.1.1.5\ny\nmac-newplace\n\ny\nn\n\nn\n' | \
  SSH_CONFIG="$FR/ssh_config" SETTINGS="$FR/settings.json" HOSTS_FILE="$FR/hosts" \
  LIB_DIR="$FR/lib" timeout 120 "$W" --dry-run 2>&1)
fresh_rc=$?

[ "$fresh_rc" = 0 ] \
  && ok "fresh machine: the wizard runs to completion" \
  || no "fresh machine: the wizard runs to completion" "exit $fresh_rc: $(printf '%s' "$fresh_out" | tail -3)"

printf '%s' "$fresh_out" | grep -q "unbound variable" \
  && no "fresh machine: no unbound variable" "$(printf '%s' "$fresh_out" | grep 'unbound')" \
  || ok "fresh machine: no unbound variable"

# Nothing is configured, so nothing can be offered. A default here would be
# invented rather than derived.
printf '%s' "$fresh_out" | grep -q "the Mac's username:" \
  && ok "fresh machine: no username default is invented" \
  || no "fresh machine: no username default is invented" "a default was offered"

printf '%s' "$fresh_out" | grep -q "read as somemac.local" \
  && ok "fresh machine: a short name gains .local" \
  || no "fresh machine: a short name gains .local" "$(printf '%s' "$fresh_out" | grep -i 'local name')"

# settings.json is {} — the whole sandbox.network path has to be created, not
# assumed to exist.
printf '%s' "$fresh_out" | grep -q '"allowedDomains"' \
  && printf '%s' "$fresh_out" | grep -q '"sandbox"' \
  && ok "fresh machine: the whole sandbox.network path is created" \
  || no "fresh machine: the whole sandbox.network path is created" "$(printf '%s' "$fresh_out" | grep -A6 'would change')"

# The /etc/hosts step reads Host blocks off disk, and a dry run describes the
# block rather than writing it — so on a fresh machine it saw nothing and said
# "no configured networks" immediately after configuring one.
printf '%s' "$fresh_out" | grep -q "10.1.1.5 somemac.local" \
  && ok "fresh machine: /etc/hosts counts the network configured in this run" \
  || no "fresh machine: /etc/hosts counts the network configured in this run" "$(printf '%s' "$fresh_out" | sed -n '/etc\/hosts/,$p' | head -5)"

# Dry run means dry run, on every file it was pointed at.
if [ -s "$FR/ssh_config" ] || [ "$(cat "$FR/settings.json")" != "{}" ] || [ -n "$(ls -A "$FR/lib")" ]; then
  no "fresh machine: --dry-run wrote nothing" "one of ssh_config, settings.json or the marker changed"
else
  ok "fresh machine: --dry-run wrote nothing"
fi

# --- the write path, for real ------------------------------------------------
# Everything above runs --dry-run, so until 18 Sep 2026 the wizard had never
# written anything, even to a copy. Running it for real found three defects in
# one pass. sudo is stubbed on PATH rather than invoked, so /etc/hosts here is a
# file in $TMP and the real one is never touched.
RW="$TMP/realwrite"; mkdir -p "$RW/lib" "$RW/bin"
printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
  "$TMP/fake-key" > "$RW/ssh_config"
: > "$TMP/fake-key"
printf '{"sandbox":{"network":{"allowedDomains":["the-mac.local"]}}}\n' > "$RW/settings.json"
printf '127.0.0.1 localhost\n' > "$RW/hosts"
date +%F > "$RW/lib/phase-a-done"

rw_run() { # rw_run <sudo-exit> -> output; answers are fixed
  printf '#!/bin/sh\nexit %s\n' "$1" > "$RW/bin/sudo"
  chmod +x "$RW/bin/sudo"
  printf 'y\nmac-test\n192.168.99.50\ny\ny\nn\ny\ny\ny\n' | \
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
printf '%s' "$rw_out" | grep -qE 'ok    written$' \
  && no "write path: a failed sudo is not reported as written" "it said written" \
  || ok "write path: a failed sudo is not reported as written"

printf '%s' "$rw_out" | grep -q "UNCHANGED" \
  && printf '%s' "$rw_out" | grep -q "two of three" \
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
printf '%s' "$rw_ok" | grep -qE 'ok    written$' \
  && ok "write path: a working sudo does report the write" \
  || no "write path: a working sudo does report the write" \
        "$(printf '%s' "$rw_ok" | sed -n '/Apply that/,$p' | head -3)"

# The .local name is read back from settings.json, so declining that step costs
# /etc/hosts too. Saying "nothing to map" read as though there were nothing to
# do; it has to name the consequence.
printf '{}\n' > "$RW/settings.json"
printf 'Host existing-mac\n  Hostname 10.0.0.10\n  User testuser\n  IdentityFile %s\n' \
  "$TMP/fake-key" > "$RW/ssh_config"
rw_noname=$(printf 'y\nmac-test\n192.168.99.50\ny\nn\nn\nn\nn\n' | \
  PATH="$RW/bin:$PATH" SSH_CONFIG="$RW/ssh_config" SETTINGS="$RW/settings.json" \
  HOSTS_FILE="$RW/hosts" LIB_DIR="$RW/lib" timeout 120 "$W" 2>&1)
printf '%s' "$rw_noname" | grep -q "cannot be written" \
  && ok "write path: an unknown .local name names what it costs" \
  || no "write path: an unknown .local name names what it costs" \
        "$(printf '%s' "$rw_noname" | sed -n '/etc\/hosts/,$p' | head -3)"

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
[ -L "$CLAUDE_DIR/skills/maestro-remote-mac" ] \
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
jq -e '[.hooks | .. | .command? // empty | select(contains("maestro-remote-mac"))]
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
         and (.args[0] | endswith("/skills/maestro-remote-mac/bin/mcp.sh"))
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
if [ -e "$CLAUDE_DIR/skills/maestro-remote-mac" ] || [ -L "$CLAUDE_DIR/skills/maestro-remote-mac" ]; then
  no "uninstall removes the skill" "still there"
else
  ok "uninstall removes the skill"
fi
grep -q "someone-elses-thing" "$CLAUDE_DIR/settings.json" \
  && ok "uninstall leaves other packages alone" || no "uninstall leaves other packages alone" "removed them"
grep -q "someone-elses-bash-thing" "$CLAUDE_DIR/settings.json" \
  && ok "uninstall leaves the other package's Bash hook alone" \
  || no "uninstall leaves the other package's Bash hook alone" "removed it"
jq -e --arg o "maestro-remote-mac" '[.. | .command? // empty] | any(contains($o))' \
  "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 \
  && no "uninstall removes our entries" "still registered" || ok "uninstall removes our entries"

jq -e '.mcpServers | has("maestro-mac")' "$HOME/.claude.json" >/dev/null 2>&1 \
  && no "uninstall removes the MCP entry" "still registered" \
  || ok "uninstall removes the MCP entry"
jq -e '.mcpServers["someone-elses-server"] and .projects["/some/path"]
       and .oauthAccount.accountUuid == "keep-me"' \
  "$HOME/.claude.json" >/dev/null \
  && ok "uninstall leaves other servers and account state alone" \
  || no "uninstall leaves other servers and account state alone" "$(jq -c 'keys' "$HOME/.claude.json")"

echo "release tarball"
# Whether the release tarball is enough to install from — the one thing a git
# checkout can never tell you, because everything is present either way. CI
# builds it with git archive at the tag; this builds the same file list out of
# the checkout and installs it. The rest of the suite then runs against that
# install, because a copy is where the interesting failures are: a symlink
# install cannot drift from its source.
TARBALL_CLAUDE="$TMP/tarball-claude"
TARBALL_SKILL="$TARBALL_CLAUDE/skills/maestro-remote-mac"
if [ -f "$REPO/.github/workflows/release.yml" ]; then
  payload=$(sed -n 's/^ *"\$TAG" -- //p' "$REPO/.github/workflows/release.yml")
  [ -n "$payload" ] && ok "found the payload list in the workflow" || no "found the payload list in the workflow" "no git archive line"
  mkdir -p "$TMP/tarball/maestro-remote-mac"
  ( cd "$REPO" && tar -cf - $payload ) | ( cd "$TMP/tarball/maestro-remote-mac" && tar -xf - )
  CLAUDE_DIR="$TARBALL_CLAUDE" "$TMP/tarball/maestro-remote-mac/install.sh" --yes >"$TMP/out" 2>&1 \
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
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-remote-mac"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && ok "a clean install matches" || no "a clean install matches" "it did not"

  echo "a finding written into the live tree, as happened three times" > "$TARBALL_SKILL/reference/stray.md"
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-remote-mac"
    . "$REPO/manifest.sh"
    tree_matches 2>/dev/null ) \
    && no "a stray file in the live tree is caught" "it passed" || ok "a stray file in the live tree is caught"
  rm -f "$TARBALL_SKILL/reference/stray.md"

  mv "$TARBALL_SKILL/bin/resolve.py" "$TMP/resolve.py.held"
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-remote-mac"
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
  ( CLAUDE_DIR="$TARBALL_CLAUDE"; PKG="maestro-remote-mac"
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
