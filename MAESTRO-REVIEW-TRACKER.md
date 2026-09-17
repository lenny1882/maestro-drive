# Maestro-usage review tracker

Reviewing brandco-flutter-runner sessions for maestro-remote-mac skill usage,
picking up after the last one already observed: `2712fef3` (13 Aug 2026, 16:08).
Session ids here are synthetic placeholders, consistent with `BACKLOG-DONE.md`,
so cross-references resolve; they are not the real transcript ids.

**COMPLETE — 9 Sep 2026.** Every queued session reviewed (all 3 passes). Hardware
queue done earlier; simulator queue finished this session. Final split of the 40
listed "drove maestro" sessions: **7 hardware/mixed**, **21 genuine simulator
driving**, **12 reclassified non-driving** (GSD plan/execute/ship, PR-comment
drafting, worktree/code-review-template freeform, and one flutter-hot-reload-mac
session — their driver.sh/simctl/"20 mcp" counts were PLAN/HANDOFF/reference text
or a sister skill, not executed maestro calls). Backlog items raised or updated by
this review: new 57, 58, 59, 60; updated 8, 14, 19, 22, 24, 26, 40, 41, 47, 49, 52,
56. General conduct routed to `~/claude-sandbox/claude-retrospective/general-frustrations.md`.
The dominant recurring finding is item 49 (ad-hoc driving instead of replaying
existing journeys) — policed by the user in four+ sessions, which is the case for
item 51's enforcement hook over more prose.

Signal for "drove maestro": `driver.sh` calls, `mcp__maestro-mac__*` tool calls,
or `xcrun simctl` in a driving context. Counts are per-session occurrences.

Status: `done` = maestro usage reviewed; `todo` = not yet reviewed.

Target: `sim` = drove the iOS simulator (`simctl`/`driver.sh`/MCP, no device
targeting); `hw` = drove the physical iPhone XS Max (a shared test iPhone,
`00008020-0011223344556677`) via executed `devicectl`/`maestro` against that
UDID. `hw*` = mixed, drove both in the same session. A lone appearance of the
device UDID from the skill's device-catalogue text does not count as `hw`.

## Target split (40 maestro sessions)

Hardware (6 real): 90833915 (hw*, 14 Aug), 480adcc1, 0598a4b6 (21 Aug),
9ea404ec, 3936b43e, a4d6c149 (4 Sep).
Reclassified on review: 46c62657 (4 Sep) was listed hardware but drove no device —
it is the maestro-docs audit (Session M); its XS Max UDID hits were doc content.
fa7aa98c (13 Aug) was listed simulator but drove no device — it is a
`/gsd:plan-phase` session; its 2 driver.sh hits were PLAN.md text.
93695153 (14 Aug) was listed simulator but drove no device — it is a
`/gsd:execute-phase` session; its real MCP calls are Dart `run_tests`, not maestro.
09875116 (14 Aug) was listed simulator but drove no device — it is a
`/gsd:plan-phase 3 --gaps` session; its driver.sh/simctl hits were PLAN text.
9 Sep F7 pre-scan reclassified six more as non-driving (freeform code-review /
worktree / bug-investigation sessions whose driver.sh hits are reference/BACKLOG
text): 44ba8bf7, 05a40890, 6df7125e, 8d1820ae, 922a81f0, 61963b50.
Simulator (21 driving — 90833915 + 9fbfccc2 + 7 more done, 12 outstanding; 12
reclassified non-driving): everything else below.

**Caveat on the `mcp` column.** The recurring value 20 (and near-20) is NOT a
count of `mcp__maestro-mac__*` calls — it counts `mcp__` string mentions,
inflated by tool-listing text, and appears on non-driving sessions too. Do not
treat a "20 mcp, no driver.sh, no simctl" row as confirmed driving; verify each
against actual executed tool calls. So far two such rows (fa7aa98c, 93695153)
turned out non-driving.

**Caveat on delegated driving (`sim*`/`hw*` with a `*`).** A `/gsd:execute-phase`
session can spawn a `gsd-executor` subagent that does the actual maestro driving
(e.g. plan 03-10, the simulator re-verify). Then the parent jsonl holds only
PLAN.md text (inflating its driver.sh/simctl counts) plus the executor's returned
summary — the executor's raw tool calls are NOT in the parent (no sidechain), and
its streaming output lives in an ephemeral `/tmp/.../tasks/*.output` that is
deleted after the session, so raw pass-2 of the real maestro commands is
impossible after the fact. For these, review the returned summary only and mark
the row `sim*`. First instance: 9fbfccc2.

**READ THE BACKLOG SESSION TABLE FIRST (`BACKLOG.md` "Where the evidence is",
~line 165).** It already maps session hashes to letters (A–M) and lists which
items each session raised/touched. Two early sim-queue reviews concluded too
fast for want of it: item 40's "second sighting" mislabel on `de240800` (it is
Session H, the raising session), and missing that `91879ddf` is Session F, the
source of items 29–35. Cross-check every session against this table before
writing findings. Known mappings: F=91879ddf (raised 29–35, ans 14),
G=c0c6fbc5 (raised 36–38, 41–44, 2nd sighting 30), H=de240800 (raised 39, 40),
M=46c62657, L=a4d6c149, K=3936b43e. A–D (c286da8d, b4184377, 379d06ed, 1d33fec2)
are 11–12 Aug, pre-cutoff — not in this queue.

## Sessions that drove maestro (40 — 39 outstanding)

| Status | Target | Date | Session | driver.sh | mcp | simctl |
|--------|--------|------|---------|-----------|-----|--------|
| done | sim | 2026-08-13 16:08 | 2712fef3 | 122 | – | 7 |
| done | plan | 2026-08-13 17:00 | fa7aa98c | 2 | – | – |
| done | exec | 2026-08-14 11:39 | 93695153 | – | 20 | – |
| done | sim* | 2026-08-14 13:57 | 9fbfccc2 | 8 | 20 | 2 |
| done | plan | 2026-08-14 14:44 | 09875116 | 2 | 20 | 2 |
| done | hw* | 2026-08-14 17:14 | 90833915 | 406 | 30 | 37 |
| done | sim | 2026-08-19 12:54 | d32077c5 | 203 | 20 | 19 |
| done | sim | 2026-08-19 13:26 | 2696b9ae | 186 | 20 | 16 |
| done | no-drv | 2026-08-19 16:42 | 44ba8bf7 | 8 | 20 | 2 |
| done | sim/docs | 2026-08-19 16:42 | 91879ddf | 381 | 22 | 14 |
| done | no-drv | 2026-08-20 13:22 | 05a40890 | 14 | 20 | 4 |
| done | sim | 2026-08-20 14:56 | de240800 | 218 | 20 | 41 |
| done | no-drv | 2026-08-20 15:07 | 3c45a615 | 10 | 20 | 5 |
| done | no-drv | 2026-08-20 16:20 | 6df7125e | – | 20 | 8 |
| done | no-drv | 2026-08-20 16:43 | 8d1820ae | 4 | 20 | 2 |
| done | sim | 2026-08-20 18:19 | c0c6fbc5 | 510 | 20 | 77 |
| done | no-drv | 2026-08-21 11:58 | 922a81f0 | 8 | 20 | – |
| done | hw | 2026-08-21 13:07 | 480adcc1 | 127 | 30 | 28 |
| done | hw | 2026-08-21 16:39 | 0598a4b6 | 219 | 50 | 9 |
| done | sim | 2026-08-21 17:55 | e5bdd72b | 184 | 20 | 33 |
| done | ship | 2026-08-24 09:51 | 452fd493 | 54 | – | 8 |
| done | sim | 2026-08-24 16:49 | cf5c6f39 | 88 | – | 6 |
| done | hotreload | 2026-08-25 10:51 | f3ec65cc | 12 | – | 29 |
| done | sim | 2026-08-25 14:11 | d62fd2c0 | 52 | 20 | 22 |
| done | sim | 2026-08-25 14:59 | 5827cb0e | 1522 | 20 | 31 |
| done | sim | 2026-08-26 12:51 | 2fcffccc | 192 | 20 | 8 |
| done | no-drv | 2026-08-26 15:03 | 61963b50 | – | 20 | – |
| done | sim | 2026-09-01 16:54 | 07f380e8 | 154 | 20 | 19 |
| done | sim | 2026-09-03 09:50 | 0206540b | 59 | – | 8 |
| done | sim | 2026-09-03 13:15 | eba9ea2b | 40 | – | 2 |
| done | sim/J | 2026-09-03 13:49 | 213647e3 | 225 | – | 41 |
| done | sim | 2026-09-03 15:47 | 9d5eb4e7 | 178 | – | 19 |
| done | sim | 2026-09-03 16:54 | a142c63c | 173 | – | 46 |
| done | sim | 2026-09-04 10:53 | 22d4c486 | 141 | 20 | 20 |
| done | sim/MCP | 2026-09-04 10:54 | 065a39b2 | 93 | 53 | 7 |
| done | sim | 2026-09-04 11:17 | 2896ac1c | 228 | 20 | 65 |
| done | hw | 2026-09-04 11:29 | 9ea404ec | 143 | 30 | 24 |
| done | hw | 2026-09-04 15:06 | 3936b43e | 102 | 20 | 13 |
| done | docs | 2026-09-04 16:10 | 46c62657 | 290 | 20 | 58 |
| done | hw | 2026-09-04 17:01 | a4d6c149 | 242 | 20 | 13 |

## Review queues (39 outstanding; mixed 90833915 in both)

### Hardware queue (7)

- [x] 2026-08-14 17:14  90833915  (mixed) — reviewed 9 Sep (+ raw-tool-call pass); touched 14, 18, 42, 45, 47; raised 53, 54
- [x] 2026-08-21 13:07  480adcc1 — reviewed 9 Sep (narrated + raw + unflagged pass); touched 14, 16, 42, 45, 46, 50, 52, 53; raised 55; fixed item 45 attribution
- [x] 2026-08-21 16:39  0598a4b6 (Session I) — reviewed 9 Sep (all 3 passes); touched 14, 41, 46, 49; raised 56; conduct → retrospective
- [x] 2026-09-04 11:29  9ea404ec — reviewed 9 Sep (all 3 passes); touched 41, 46, 49, 50 (raised 50 here — check "Session K"); conduct → retrospective
- [x] 2026-09-04 15:06  3936b43e — reviewed 9 Sep (all 3 passes); verified chat fix, wrote journey 29; touched 16, 46, 49; settled item-50 "Session K" (9ea404ec raised it); hand-walking → retrospective
- [x] 2026-09-04 16:10  46c62657 — reviewed 9 Sep: NOT a device session (docs audit, Session M); reclassified docs-only; touched 16, 19, 52; conduct (verbosity etc.) → retrospective
- [x] 2026-09-04 17:01  a4d6c149 (Session L) — reviewed 9 Sep (all 3 passes); confirmed items 46-L, 49, 51; decisive evidence for 56; /btw + memory-failed conduct → retrospective. HARDWARE QUEUE COMPLETE.

### Simulator queue (0 genuine-driving outstanding — COMPLETE; 12 reclassified non-driving)

**F7 pre-scan (9 Sep).** Counted actually-executed `driver.sh <verb>` / `simctl
<verb>` calls (not string mentions) across every outstanding sim row. The 22
genuine-driving rows still to review, by executed-driving weight (realdrv +
realsim), heaviest first — do the heavy ones with full three passes:

  5827cb0e (660), 213647e3 (108), 91879ddf (107), e5bdd72b (71), a142c63c (70),
  d32077c5 (55), 2696b9ae (52), de240800 (48), 9d5eb4e7 (49), 2fcffccc (43),
  065a39b2 (35 + 12 real maestro-MCP — only MCP-driven row), 07f380e8 (36),
  22d4c486 (34), c0c6fbc5 (26), 2896ac1c (22 simctl), d62fd2c0 (19),
  eba9ea2b (7), 0206540b (6), f3ec65cc (5 simctl), cf5c6f39 (2 simctl),
  (452fd493, prescanned at 1 driver.sh in a `/gsd:ship` flow, was reviewed and
  reclassified non-driving — the "tap" was a grep spot-check string, not a call.)
  (3c45a615, prescanned at 1 simctl, was reviewed and reclassified non-driving —
  its simctl hits were HANDOFF finding-text, not executed calls.)

**Prescan under-counts quoted invocations.** The F7 prescan regex only matched
bare `driver.sh <verb>`, not `bash "$SKILL/bin/driver.sh" <verb>` (quoted path) —
so its realdrv weights are too low for sessions using the quoted style (e.g.
cf5c6f39 prescanned realdrv=0 but drives heavily with tapon/script). It caused NO
wrong reclassification — a robust quote-aware re-check of all 11 reclassified
sessions on 9 Sep confirmed every one is genuinely non-driving (the only two hits
were a ship-preflight grep string and HANDOFF finding-text). But do not trust the
prescan weights for prioritising; re-measure each remaining session quote-aware
when profiling it.

Reclassified non-driving (fa7aa98c, 93695153, 09875116 above; 44ba8bf7,
05a40890, 6df7125e, 8d1820ae, 922a81f0, 61963b50 by F7 pre-scan):

- [x] 2026-08-13 17:00  fa7aa98c — reviewed 9 Sep (all 3 passes); NOT a driving session. `/gsd:plan-phase 3 --gaps`; the 2 driver.sh hits are PLAN.md/plan-checker text ("runnable via maestro-remote-mac/bin/driver.sh"), no simctl/MCP/tap executed. Reclassified `plan`, like 46c62657. Nothing for backlog.
- [x] 2026-08-14 11:39  93695153 — reviewed 9 Sep (all 3 passes); NOT a driving session. `/gsd:progress` + `/gsd:execute-phase 3`; builds Dart plans 03-08/03-09. The 2 real MCP calls are Dart Flutter `run_tests` (unit suite), no simctl/maestro/device. The tracker's "20 mcp" is a false count (see header). Reclassified `exec`. Nothing for backlog.
- [x] 2026-08-14 13:57  9fbfccc2 — reviewed 9 Sep (all 3 passes). DELEGATED driving: `/gsd:execute-phase 3` spawned a gsd-executor subagent that drove the iPhone 16 Pro simulator for plan 03-10. Parent's 8 driver.sh / 2 simctl are PLAN.md text; the real driving is in the subagent, whose raw transcript wasn't preserved (ephemeral /tmp tasks dir gone) — so only the executor's returned summary is reviewable, no raw pass-2 possible. Visible conduct SOUND: drove via `driver.sh kill`, cold-launched across grace, captured device syslog to catch a High-sev BottomNavigationBar cold-start-race crash (project bug, not skill), re-verified fields before re-submit, scoped the crash out of plan. Nothing for backlog. `sim*` = delegated. See methodology caveat below.
- [x] 2026-08-14 14:44  09875116 — reviewed 9 Sep (all 3 passes); NOT a driving session. `/gsd:plan-phase 3 --gaps`; spawned gsd-planner + gsd-plan-checker. The 2 driver.sh / 2 simctl hits are PLAN.md/plan-checker text, no device driving. Reclassified `plan`, like fa7aa98c. Nothing for backlog.
- [x] 2026-08-14 17:14  90833915  (mixed) — reviewed 9 Sep (+ raw-tool-call pass); touched 14, 18, 42, 45, 47; raised 53, 54
- [x] 2026-08-19 12:54  d32077c5 — reviewed 9 Sep (all 3 passes). GENUINE driving: full code+device review of PROJ-1786 on iPhone 16 Pro + iPad Pro 11" (no Simulator.app — booted runtimes, driver HTTP API). Verbs: nodes 49, tapon 25 (selector), shot 36, raw tap 25, script 9. This session is the SOURCE of item 24 (concurrent branch reviews) — added its session hash. Touched item 8: drove iPad app controls with RAW `driver.sh tap` + hand-computed `834-x`, never tapon; measured that raw tap needs the transform. NB: an initial F13 read wrongly reopened item 8 as a tapon defect — the sibling session 2696b9ae (13:26), reviewed next, tested tapon directly in landscapeLeft and found it works first time (raw tap with the same conversion did nothing twice). So the real d32077c5 lesson is CONDUCT — reverted to raw tap + hand arithmetic on the iPad instead of tapon. Item 8 corrected accordingly (not reopened); genuine iPad remainder is the nav rail = item 26. Raw iPhone taps mostly legitimate (unlabelled free-text field → tapon can't resolve, documented via notes.sh; + accessibility-clipping probe y=433 vs y=431). 8 sleeps = build/vmservice poll-waits (weak echo of item 41, left as-is). Conduct SOUND: good notes.sh discipline, verified on device, scope-disciplined. FURTHER LOGGED (9 Sep, after the maintainer flagged I'd left findings only as chat-offers): item 22 — followed the stale "Mac has no Bitbucket key → use a git bundle" instruction without testing it, when item 22's fetch recipe works (review-branch skill staleness); item 26 — the unlabelled free-text field it raw-tapped (no accessibility label → tapon can't resolve; fragile point) as an instance broadening item 26 beyond the iPad rail; item 59 — the stray home-dir dotfiles it noticed at the repo root.
- [x] 2026-08-19 13:26  2696b9ae — reviewed 9 Sep (all 3 passes). GENUINE driving: code+device review of PROJ-1784 (unassign) on iPhone 16 Pro + iPad Pro 11" landscapeLeft. Verbs: tapon 45 (selector), nodes 41, script 17, raw tap 7. EXEMPLARY selector discipline — the clean counter-example to d32077c5's raw-tap conduct. Its measured "controls that lie" note CORRECTS item 8: tapon works on iPad app controls in landscapeLeft (opened the card first time) where the hand-converted raw tap did nothing twice — folded into item 8 (which I'd briefly mis-reopened off d32077c5). Reconfirms item 26 (nav rail has no tree entries, still needs coords, landscapeLeft/Right only). Hit the already-documented CocoaPods/GEM_HOME build requirement (item 5). Good notes discipline throughout. RAISED item 57 (with d32077c5): the shipped docs contradict each other on iPad taps — driver-api.md:181-184 says the driver rotates so send portrait coords, example-app.md:53 says hand-transform `834-app_y` — and nothing steers the operator to tapon; resolution approximation baked into the item (one-tap confirming test, reconcile the two docs, add the prefer-tapon iPad rule per item 56).
- [x] 2026-08-19 16:42  44ba8bf7 — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform "where does the code-review template live?"; realdrv=0 realsim=0, no executor. Its driver.sh hit is maestro reference text read into context. Reclassified `no-drv`.
- [x] 2026-08-19 16:42  91879ddf — reviewed 9 Sep (all 3 passes). GENUINE driving, but a DOCS-AUDIT-AND-SETTLE session (like 46c62657/Session M, but earlier and it drove): the maintainer asked to audit the project's maestro docs for conflicts; found 18 contradictions in app-notes.md, settled 4 against the device + rest by reasoning, edited notes in place. Verbs: tapon 48, script 26, nodes 24, swipe 7, find 7, raw tap 3 (iPhone measurement probes), 0 sleeps, 0 screenshot-fallbacks — EXEMPLARY journey-first/selector conduct. Reconciliation: primary → item 19 (added as earliest/largest instance; and it settled the iPad transform on 19 Aug which 46c62657 found contradictory AGAIN on 4 Sep — the recurrence that argues for a standing checker). Reinforces items 8/57 (settled the iPad tapon contradiction here, striking the stale 11 Aug note) and item 14 (its item-6 found 01-device-setup.journey still uses filter-then-return that silently signs in the wrong user — the app's half). CORRECTION (added 9 Sep after reading the backlog session table): this session is SESSION F — the SOURCE of items 29–35 (tapon --anyway, keyboard-guard-fires-when-down, typed.py false pass, tree.py flag column, --explain marker, keyboard-test-centre-only) and it answered item 14's open question. All already raised/attributed in the backlog, so no backlog change — but my first pass here was narration-biased and missed that the toolkit findings in its driving are items 29–35. Lesson: cross-check the session table + run pass 2 against the driving, not just the narrative.
- [x] 2026-08-20 13:22  05a40890 — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform code-review-template change; realdrv=0 realsim=0, no executor. The 3 driver.sh hits are BACKLOG quotes ("settled 19 Aug: driver.sh tap takes app space"). Reclassified `no-drv`.
- [x] 2026-08-20 14:56  de240800 — reviewed 9 Sep (all 3 passes). GENUINE driving: code+device review of PROJ-1772 on iPhone 16 Pro + iPad. Verbs: nodes 45, tapon 32, script 22, shot 12, raw tap 11 (iPad rail item 26 + iPhone probes), swipe 6, 36 sleeps. This is Session H in the backlog's session table (raised items 39 & 40). Reconciliation: item 40 — this session RAISED it; on review I named the launch mechanism more precisely (nohup/detached build → install torn down with the calling shell) and corrected an initial mislabel that called it a "second sighting" (it is the raising sighting). item 41 (raised by Session G) — added de240800 as a legitimate additional instance: 36 sleeps hand-rolled as poll loops waiting for build/online/offline, widening the item to off-screen predicates. No new maestro backlog items. CONDUCT threads — checked against the "everything on the backlog" rule and both are genuinely NON-maestro, so correctly off this backlog: (a) reported the type:'' submit bug "fixed", then corrected it after the maintainer pushed and it checked source — assertion-without-checking → NOW WRITTEN to claude-retrospective/general-frustrations.md under "Assertions made without checking" (20 Aug instance); not a maestro change; (b) probed skill reference/ writability with a throwaway `touch .writetest`, reported the write blocked (this-machine.md says try Write/Edit first) and couldn't rm it (Bash gated) → stranded a 0-byte .writetest in the shipped skill — machine/sandbox conduct, already homed in ~/.claude/reference/this-machine.md + memory never_report_a_write_as_blocked.md. Also: the stray home-dir dotfiles it flagged at the repo root → logged as item 59 (raised with d32077c5). Recurring env note: stray home-dir dotfiles at repo root (also seen in d32077c5).
- [x] 2026-08-20 15:07  3c45a615 — reviewed 9 Sep (all 3 passes); NOT a driving session. PR-comment drafting ("pull my comments from the runner-api PRs as a template, draft comments for the 1786 findings"); 0 driver.sh, 0 taps, 0 sleeps. The 20 simctl/maestro string hits are all reads of maestro/HANDOFF-*.md finding text. Same class as 6df7125e. Reclassified `no-drv`. Nothing for backlog.
- [x] 2026-08-20 16:20  6df7125e — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform critique of draft PR-comment voice (PR 1772); realdrv=0 realsim=0, no driver.sh in results at all. Reclassified `no-drv`.
- [x] 2026-08-20 16:43  8d1820ae — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform code-review-template backtick formatting; realdrv=0 realsim=0, no executor. Its driver.sh hit is maestro reference text. Reclassified `no-drv`.
- [x] 2026-08-20 18:19  c0c6fbc5 — reviewed 9 Sep (all 3 passes). This is SESSION G in the backlog's session table — ALREADY fully reconciled: reconciling an outside Maestro suite (handover-maestro, build 1.0.0-uat) into the project's journeys, then running 7 against the iPhone 16 Pro. RAISED items 36–38 and 41–44 and added the 2nd sighting to item 30 (VERIFY at y=649 refused by the y=641 keyboard guard). The maintainer explicitly directed "never make the change yourself, backlog it" — this session IS the backlog-it workflow. Driving: tapon 19, script 25, tree 17, raw tap 2, 0 sleeps — good discipline. Verified all its findings are captured (they are). FURTHER LOGGED (9 Sep): its six unlabelled icon controls (pencil/trash/tick/cross/two gears) carried in as DERIVED-NOT-MEASURED coordinates → added to item 26 as an instance broadening it beyond the iPad rail to any no-label/no-frame control (silent-fail-prone). Side effect of reviewing it: found the session-letter table (line 165+), which exposed my item-40 "second sighting" mislabel on de240800 (Session H = the raising session) — corrected. Conduct threads (general, already logged): the "concise" pushback (writing-style.md) and "six passes / I don't trust you" + "forty files dismissed over two config values" (general-frustrations.md).
- [x] 2026-08-21 11:58  922a81f0 — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform "I want a worktree for the phase 2 branch"; realdrv=0 realsim=0, no driver.sh in results at all. Reclassified `no-drv`.
- [x] 2026-08-21 17:55  e5bdd72b — reviewed 9 Sep (all 3 passes). GENUINE driving, not in the backlog session table (new). Mixed session: /gsd:progress + roadmap-table/checkbox fix + commit, THEN a UI-fix verification (the idle-logout modal card) driving 3 SIMULATORS (iPad Pro 11 F0EDF404 ×58, iPhone 16 Pro BA42FF52 ×20, a newer iPad ADA680DD ×10). POOR driving discipline — nodes 63, raw tap 33, tapon 2, shot 14: coordinate-stabbing + screenshot-reliance. The maintainer reacted hard ("5 minutes for taps?! ... ignored all past instructions about how to find elements? AGAIN?"); the session self-critiqued well ("bad work, not intent"). Reconciliation: item 19 (added the COST of the contradiction — two 12 Aug notes, one saying "app controls need no transform", licensed 3 blind taps before find --explain recovered it; "the wrong method chosen with confidence"); item 56 (added as the loud 21-Aug coordinate-stabbing repeat — instruction existed, behaviour repeated, response was another note/memory); reinforces item 57 (the docs "no transform" note is what misled it). This session is the 21-Aug node of the three contradictory iPad-transform notes (12/19/21 Aug) 46c62657 cites. RAISED item 58 (its two device-verification conduct foot-guns, on the backlog with approximate resolutions per the maintainer's "everything on the backlog" rule): (a) fudging the app source to force the idle modal raced the driver latency and forced a clean rebuild → prefer a Remote Config override; (b) asked which orientation before reading Info.plist's landscape-only iPad constraint, time-sink switching iPads → read UISupportedInterfaceOrientations~ipad first. [Corrected 9 Sep: I first mis-routed these to the retrospective; maestro-session conduct that implies a skill change goes on the backlog.]
- [x] 2026-08-24 09:51  452fd493 — reviewed 9 Sep (all 3 passes); NOT a driving session. `/gsd:ship` for Phase 3 (created PR #110, resolved a development→branch merge already in progress, showed app.dart diff, ran Dart run_tests). 0 real device calls — the prescan's "1 driver.sh tap" was a grep spot-check string ("...08-add-note.journey...", "...tap...") in a ship-preflight file check, not a driver call. Reclassified `ship`. Nothing for backlog.
- [x] 2026-08-24 16:49  cf5c6f39 — reviewed 9 Sep (all 3 passes). GENUINE driving (prescan under-counted it — uses `bash "$SKILL/bin/driver.sh" <verb>` quoted style; quote-aware recount: launch 1, nodes 9, script 12, tapon 6, tap 2 sel, 0 raw, 0 sleeps, 1 shot — GOOD journey-first/selector discipline). PR #103 (PROJ-1786) re-verification on 3 simulators: 9/11 comments fixed, confirmed on device; 2 minor left. The assistant explicitly "recorded three things about driving it" → all reconciled: item 47 (viewer relay not answering on 9999, 24 Aug — earlier than session J's 3 Sep; benign handling, added as a dated instance); item 14 (filter-then-return picked 4001 not LOC1 again in 01-device-setup.journey — recurrence of the app-half); item 41 (NEW nuance: `settle` after opening the language dropdown closed it and broke the journey — settle can actively break a step, added journey-authoring warning). No new items. Good notes discipline.
- [x] 2026-08-25 10:51  f3ec65cc — reviewed 9 Sep (all 3 passes); NOT a maestro-remote-mac session. It's a `flutter-hot-reload-mac` (sister skill) session: "spin up flutter run on the iPhone sim, watch my saves, sync and hot-reload, screenshot after every load." No tapon/tap/nodes/script; screenshots via `simctl io` (the prescan's 5 "simctl"), sync via sync.sh/frun.py/fifo. It even packaged flutter-hot-reload-mac at the end. Reclassified `hotreload`. Nothing for the MAESTRO backlog. Checked the sister skill's backlog (`~/claude-sandbox/flutter-hot-reload-mac/BACKLOG.md`): f3ec65cc is effectively its origin session (packaged the skill 25 Aug; that backlog was opened the same day), and its findings are already captured there — Behaviour item 6 is exactly the "watcher exits after each save / misses saves in the relaunch gap" issue, plus items 7–13 (native/asset changes, dead flutter run, cropping, exception read-back). So nothing outstanding anywhere from this session.
- [x] 2026-08-25 14:11  d62fd2c0 — reviewed 9 Sep (all 3 passes). GENUINE driving (light): review of PRs #106/#107 without disturbing 1788 work. Verbs launch 1, nodes 2, tapon 2, script 3, tap ~1, 8 shots, 1 sleep — good discipline (tapon; shots as UI-indicator evidence). KEY reconciliation → item 24: this is the REAL RUN of the concurrent-review approach item 24 only reasoned about — it started a 2nd checkout (brandco-flutter-runner-review on pr417) + a 5th simulator (review-iPhone16Pro) alongside 4 running drivers, built and drove it, left the 1788 checkout and the other 4 untouched. Added to item 24: (a) the "boot another, install per-device" half now verified live; (b) a sharper danger — flutter-hot-reload-mac/bin/start.sh runs `git checkout` on the single shared $REPO, so a review branch would silently clobber uncommitted in-progress work → the worktree/second-checkout rule is a SAFETY requirement, not just an enabler. PR findings (RUNNER capsule for all users, etc.) are app-specific, in the review. No new backlog items.
- [x] 2026-08-25 14:59  5827cb0e — reviewed 9 Sep (all 3 passes). HEAVIEST session (4572 lines). Full test-script run (from a Google-Drive CSV, Phase 3) meant to use existing journeys/flows. Quote-aware verbs: tapon 380, tree 254, nodes 206, script 78, tap 130 (all raw, 64 distinct pts), swipe 36, text 34, expect 27, kill 22, settle 17, launch 30; 12 sleeps, 38 shots. Heavy tapon use, but 130 raw taps across the long run (the maintainer did NOT flag taps here — likely mostly forced/unlabelled targets; not treated as stabbing). BACKLOG: item 49 (wrote a NEW journey — duplicated 01-device-setup.journey as -v3 to dodge item-41's settle bug at line 20 instead of fixing it; the maintainer: "Why are you writing new journeys?" / "only when there really is no other file"); item 52 (wrote a failing-test-case finding into maestro app-notes.md; the maintainer caught it live — earlier instance than Session M's 4 Sep audit); item 41 (the settle bug triggered the duplication — 41↔49 compound). RETROSPECTIVE (general conduct → general-frustrations.md "Close the point"): treated open test cases as settled when the maintainer jumped back (298, 299), "individually" instruction ignored twice, stopped showing open questions, stopped short of running the full script ("I want the entire script run" ×2); peak frustration ("Listen here, you little shit"). No new backlog items.
- [x] 2026-08-26 12:51  2fcffccc — reviewed 9 Sep (all 3 passes). GENUINE driving: UAT bug-repro (store 4002 — push a request through, flag errors, assign/unassign) + PR #111 (PROJ-1794) review. Built the uat flavour (not installed), reproduced a 400 create-request failure pre-redeploy, full flow worked after (4002-99350); PR #111 finding withdrawn on ticket clarification. Verbs: nodes 35, tapon 14, tap 25 raw (21 distinct — low repetition, driving many screens once each, NOT stabbing; the maintainer didn't flag), text 7, find 4, swipe 3, 4 sleeps, script 0. Reconciliation: item 49 (milder echo — 0 journeys for a journey-covered flow, but per-step error-repro task partly justifies manual stepping; logged as a data point, not a strong instance). No new backlog items. Conduct acceptable — no user pushback.
- [x] 2026-08-26 15:03  61963b50 — reviewed 9 Sep (F7 pre-scan + verify); NOT driving. Freeform bug investigation (request-page filter regression vs tag v2.0.0); realdrv=0 realsim=0, no driver.sh in results. Investigated by code-reading, drove nothing. Reclassified `no-drv`. [WITHDRAWN 9 Sep: I earlier flagged this as "could have used the simulator but didn't / best practice dropped" — on reflection that's wrong. Code-reading a filter-logic regression against a tag is a legitimate, often faster approach than device repro. Not a gap, nothing to log.]
- [x] 2026-09-01 16:54  07f380e8 — reviewed 9 Sep (all 3 passes). GENUINE driving, EXCELLENT tap discipline (tapon 46, 0 raw taps, 1 sleep) checking support ticket SUP-22's UI-label questions against UAT store 4003. MIXED: good journey judgement + recurring app-notes misuse. Reconciliation: item 49 POSITIVE — wrote `00-login-filtered.journey` correctly (existing 00-login can't reach a below-the-fold store since the dropdown lazy-renders ~7 rows; documented why) — the good-judgement contrast to 5827cb0e's dodge-fork; item 14 (added the dropdown's SECOND failure mode — below-the-fold rows aren't in the tree, fail with misleading "no visible node matches"; fix = filter-first, which the new journey does); item 52 RECURRENCE — put code-bug findings (a missing-await bug in the language getter; an EAN discrepancy) into app-notes "Known test data" on 1 Sep, a week AFTER 5827cb0e was flagged for the same misuse (the store-4003 test data itself is legit) — shows the one-time flag didn't stick, reinforcing item 52's SKILL.md-fix argument. No new backlog items.
- [x] 2026-09-03 09:50  0206540b — reviewed 9 Sep (all 3 passes). GENUINE driving (light, 193 lines): "get this branch running, log in as requester, stop there." Built bugfix/PROJ-1798 uat (45s), logged in via journeys (script 2) + tapon 3, 0 raw taps, 0 sleeps, stopped exactly as instructed on the SEARCH tab. Clean conduct — journeys used, no hurdles. Nothing for backlog.
- [x] 2026-09-03 13:15  eba9ea2b — reviewed 9 Sep (all 3 passes). GENUINE driving (tiny, 160 lines): "run this branch, login to 4001." Built v2.x uat, logged in via 7 tapon, 0 raw taps, 0 sleeps — clean taps. Reconciliation: item 49 (mild echo — login-by-tapon, script=0, when 00-login.journey is built for exactly store 4001; extended item 49's habit-frequency note: two mild echoes + two hard cases = a habit of hand-driving even a covered login). No new backlog items.
- [x] 2026-09-03 13:49  213647e3 — reviewed 9 Sep (all 3 passes). This is SESSION J (recorded its hash on item 47) — the PROJ-1804 auto-logout/JWT fix; it spawned the viewer agent that RAISED items 47 & 48 (already captured). EXCELLENT tap discipline: script 44 (journeys), tapon 46, nodes 45, launch 28, 0 raw taps, 1 shot — but 70 SLEEPS. Reconciliation: item 41 (added — 70 sleeps/3 expects for timed idle-state waits, some irreducible but modal-appearance waits replaceable by expect-timeout; + `settle` after `key return` commits the user and a bare journey `settle` times out at 10s); NEW item 60 (`erase` deletes backwards from the caret so it can't clear a field — F36 forked a journey unit to avoid it; cross-ref item 49); the F36 fork is item-49-shaped but toolkit-limitation-driven (item 60), not laziness. Conduct otherwise strong (heavy journey use, 0 raw taps). No other new items.
- [x] 2026-09-03 15:47  9d5eb4e7 — reviewed 9 Sep (all 3 passes). This is the SOURCE OF ITEM 49 — the PROJ-1799 chat-empty-state repro that spent an afternoon hand-driving (ad-hoc driver.sh tap login, item-49 flagship cost) and re-investigating a bug already recorded in COVERAGE.md from 22 July; the session itself wrote item 49. Added its hash to item 49 + the 22-July-rediscovery detail (its own words: "one line of COVERAGE.md was the answer to the whole afternoon"). Also captures the APP_PIN empty-credential mechanism (already in item 49). Driving: tapon 11, script 6, tap 32 (6 raw-coord, part of the ad-hoc login), 0 sleeps. RETROSPECTIVE: the premature "reproduced and fixed" claim, SELF-corrected within the session ("correcting that"), then found the real release-only Expanded cause from source/SDK — added to general-frustrations.md as the self-caught contrast (3 Sep). Eventual outcome was correct and well-verified. No NEW backlog items (item 49 already existed from here).
- [x] 2026-09-03 16:54  a142c63c — reviewed 9 Sep (all 3 passes). GENUINE driving: review of PR #116 (SUP-22 USA fixes) "without affecting the local checkout or mac testing." GOOD discipline: script 40 (journeys), tapon 26, nodes 51, tap 3 raw, 22 sleeps, 13 shots. Reconciliation: item 24 (POSITIVE — a 2nd real concurrent run using a separate worktree + own simulator; added: the pattern is now routine → promote to a documented supported workflow). RETROSPECTIVE (general conduct, assertions-without-checking, 3 Sep): declared it "couldn't reproduce" a zero/missing-price after only its own narrow cap/shirt searches — the maintainer pushed, then it found the real cause (the price getter swallows errors → null); plus a "$0.00" claim from an off-app API scan / mid-fetch node read, self-corrected. Eventual review was thorough (real before/after evidence). No new backlog items.
- [x] 2026-09-04 10:53  22d4c486 — reviewed 9 Sep (all 3 passes). GENUINE driving: review of bugfix/PROJ-1805 (US-store locale/EAN). Tap counts good (tapon 20, 0 raw, 1 sleep) BUT user furious twice. Reconciliation: item 24 (the concurrent-safe approach is NOT the default — it went to switch the shared checkout's branch; the maintainer reminded it re bundles/separate checkout; + proposed a needless git stash of discardable lock files → added the "discard lock files directly, no stash; make separate-checkout the default" detail); item 49 (user named it outright: "You're just adhoc'ing calls... rather than using the proper approaches and journeys. Do better." — assistant admitted it should have used 01-device-setup.journey; added as the direct-pushback instance, strengthening the item-51-hook case). RETROSPECTIVE (general conduct → general-frustrations.md "Proposing work on ground he has already settled"): the stash-for-already-declared-safe-lock-files, "wasting my time again". No new backlog items.
- [x] 2026-09-04 10:54  065a39b2 — reviewed 9 Sep (all 3 passes). THE ONLY review-session that drove via the maestro-mac MCP (inspect_screen ×5, run ×2, take_screenshot, list_devices ×3, cheat_sheet). Follow-up to SUP-22 (screenshot the null-price) "without affecting other running testing." Tap discipline good (tapon 18, 0 raw). RICH maestro findings, all logged: item 24 (the MCP-22087 concurrent-collision hit HARD — inspect_screen "Device became unreachable", leftover simulator-server holding 22087, kill cascade + auto-respawn, escaped via raised DRIVER_PORT_BASE; PLUS a NEW second shared port — the relay LAN port defaults to 9101 and collides across sessions → needs a per-device RELAY_PORT_BASE; + "keep MCP off during concurrent runs" posture); item 26 (NEW 4th coordinate-fragility axis — device SIZE: a journey tuned on iPhone 16 Pro didn't land on 16 Pro Max); item 56 (POSITIVE — self-caught the screenshot-to-locate anti-pattern per rule 7, evidence the rules work when surfaced at the moment). Also confirmed the null-price finding on device (style 10000001). No new numbered items (folded into 24/26/56). Harness note (not maestro): auto-mode gates each kill separately.
- [x] 2026-09-04 11:17  2896ac1c — reviewed 9 Sep (all 3 passes). LAST sim-queue session. Review of feature/PROJ-1802-filter-design-changes (PR #119) "without interfering with other running sims." Tap counts looked fine (tapon 40, 1 raw) but ONLY AFTER a strong rebuke. Reconciliation: item 49 (the STRONGEST instance — "Seeing a lot of bad habits... Do it properly" then "you _must_ use the proper journeys, do not adhoc your calls... I've already wasted an hour waiting for you to do it wrong"; correct behaviour (chaining existing journeys, batched) only appeared after the rebuke — extended item 49's 22d4c486 note; makes it a policed-every-time repeat, hardening the item-51-hook case; one justified new journey = notification-prompt dismissal, genuinely missing). RETROSPECTIVE (general conduct → "Dropped riders" near close-the-point): iPad opened as a front before the iPhone was finished ("Why are you fucking around with the ipad? Get everything working on the iphone, then do the ipad"). The icon-only filter (no text label) it flagged is an app-design finding in the review (item-26 class but the app's, not a toolkit gap). No new backlog items.

## Sessions with no maestro driving (6 — excluded)

Only mentions / config references / hot-reload skill availability, no `driver.sh`,
`mcp__maestro-mac`, or `simctl` calls.

- 2026-08-25 10:03 — eec3f0f8
- 2026-09-02 11:47 — 39715306
- 2026-09-02 13:50 — be0a97c7
- 2026-09-03 13:15 — 6afeddea
- 2026-09-03 13:50 — fdc52d20
- 2026-09-04 09:48 — a42d0a50
