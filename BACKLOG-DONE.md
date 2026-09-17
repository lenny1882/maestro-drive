# maestro-remote-mac — backlog

Raised 12 Aug 2026 from a review of two sessions that used the skill against a
real app. Ordered by measured time cost, highest first.

Re-evaluated 12 Aug 2026 against the source and against the two later sessions
that have run the toolkit since. Items 1–4 were already done; 13 has been closed
since; 8 was fixed today, and its diagnosis and proposed fix were both wrong and
have been rewritten; 14–17 are new. 18 was added on 13 Aug, and 11 and 18 were
both done that day, as were 5, 6, 7, 9, 10, 12, 14, 15 and 16.

**Re-read again 13 Aug, later.** The first review looked at four sessions; there
were eight that drove the Mac. Reading the other four raised **20, 21 and 22**,
all from session E (`2712fef3`, 13 Aug 13:03–14:25), and corrected what item 5
said about Bitbucket. Session `99462431` (10 Aug) is the origin session and adds
no new item — it hit items 5 and 10 before either existed, so both now have two
sessions behind them rather than one. The two small sessions touched the Mac
barely and add nothing.

That leaves **eight open**: 17, 19, 22, 23, 24, 26, 27, 28. **20** was raised
and struck the same day, and **21** was done on the evening of 13 Aug and sits
built and unpublished in `src/` — its heading said `OPEN` until 19 Aug. **23** is
the one to take first. **24** came in on 19 Aug from a peer session as capture
only — no work asked for yet — and **25–28** the same day, from reading
`~/claude-sandbox/HANDOFF-2026-08-STALE.md` against this file. **25** was settled the same
day; 26 is a doc, 27 is not ours to close, and 28 waits on 17.

**19 Aug, later.** Session **F** added **29–35**, all OPEN, and gave item **14**
the cause it was missing. They came out of auditing a project's `maestro/` notes
for internal contradictions and then settling four of them on a device, so most
are things the toolkit reports confidently and wrongly rather than things it
cannot do. **30** is the one to take first of them: it refuses a tap that works,
on the exact method item 14 lands on.

**20 Aug.** Sessions **G** and **H** added **36–44**, all OPEN, gave item **30** a
second sighting on a different screen — where it breaks `expect` rather than
`tapon`, so a button on screen is reported as absent — and made item **17**'s
"an edit made directly in `build/`" concrete, three times over. **39** and **40**
were raised in session H at 13:30 and written into `build/…/reference/` rather
than here, where the next ship would have deleted them; they were recovered from
that session's transcript and filed on 20 Aug.

**36** is the one to take first, ahead of everything: a journey that stops after
one line and exits 0 makes every other guarantee in this toolkit conditional,
including the ones items 30, 38 and 41 are about. Four sightings by the end of
the day, all stopping after the first line the journey executed, which narrows
it to once-per-invocation setup. **17** is now second and no longer "out of
scope" — until `build/` is unmistakable from the inside, findings will keep
being written into it and thrown away. **41** is the one with the most reach
after those two: it is what stops a journey asserting anything about a screen
that changes without moving.

**3 Sep.** Session **J** added **47** and **48**, both OPEN and both halves of
one dead end: the viewer could not be reached on 9999, and the MCP tool that
starts it could not be reached either. Take **48** first — it is a one-file
launcher, and **47**'s second half cannot be tested while the MCP server is
down.

**4 Sep.** Sessions **K** and **L**, both on the physical iPhone, added **50**
and **51**. K found a second, distinct way into item 46's symptom — a phone
lying flat kills the driver on the first touch while reads keep working. L
found that **46**'s own proposed fix 2 is wrong: the `lockState` keep-alive it
calls safe does not keep the driver alive and broke a `devicectl` install, so
that half should be dropped and fix 1 (an ensure-driver step) is now the whole
of item 46. L also gave **49** a recurrence that changes its fix — the journeys
directory was listed and the screens were hand-walked anyway, so "list the
directory" is not the rule that was missing. **51** is what follows from that:
prose has now failed twice, and a `PreToolUse` hook is drafted but has nowhere
in the skill to live. Take **46** first of these three — it is the one costing
restarts in every device session, and **50** and **51** both point at it.

Session **M**, later on 4 Sep, added **52** from a full audit of one project's
`maestro/` documentation — 205KB across eleven files, 168KB of it in the app
notes alone. It is the first item raised about the *notes* rather than the code:
the template says skill-level material belongs in `reference/`, three sections
had grown in a project's notes anyway, and there is no route for a project to
hand one back. It is small and it unblocks nothing, so take it after **46**.

Status is on every heading — read it before starting anything. The numbering is
still the original ordering by measured time cost and no longer reflects what is
left. **36** first, then **20**; **17** stays last by instruction, and **19** is
not to be started yet.

**9 Sep.** Started reviewing the *hardware* sessions oldest-first — the queue is
in `MAESTRO-REVIEW-TRACKER.md`. Session `90833915` (14 Aug) is the earliest: the
first time a physical device was touched at all, six days before session H, and
on a *different* phone — an iPhone 11 (`00008030-...`), not the XS Max. It adds
references to **14**, **18**, **42** and **47**, moves **45**'s first sighting
back to 14 Aug (with a device-readiness note added there), and raised **53** and
**54**. A raw-tool-call pass added the **18** footgun (a multi-value `MAC_HOST`
breaks a git push to the Mac), the journey-failure note on **14**, and the
`devicectl`/`timeout` details on **54**/**42**. Nothing it hit was fixed by a
later session; its
physical-device dead end (no signing certificate for the project's team, the
device in no profile) is the concrete first instance of item 45's third open
question.

Session `480adcc1` (21 Aug) followed — the real physical-device bring-up that
cracked signing, the driver re-sign and the usbmux forward and wrote
`physical-device.md`, so item 45's "Session H" attribution is corrected to it. Its
login then stalled on the item-14 dropdowns and it ran none of the seven target
tests in three hours. It touched **14, 16, 42, 45, 46, 50, 52, 53** and raised
**55**. It also confirmed, at length, that this app's first-run dropdowns do not
filter and that typing selects nothing (item 14) — the finding that blocked the
whole run.

Session `0598a4b6` (21 Aug, immediately after) is Session I: it finished plan
03-11 on the phone and wrote item 46, but lost much of ~3.5h to broken journeys
(item 14), hand-rolled poll loops (item 41 — 179 `sleep`s, 0 `expect`) and raw
taps (104). It touched **14, 41, 46, 49** and raised **56** — the structural point
that skill-usage lessons keep being saved at repo level
(`driving_the_app_wasted_time.md`) instead of shipping in the skill.

Session `9ea404ec` (4 Sep AM) tried to reproduce the chat error on the phone and
got nowhere in ~1h43m — the flat-phone crash (it raised item 50), the driver
crashing repeatedly (item 46), `settle` hitting its 20 s ceiling four times a
login (item 41), and a journey failing on retired data (`LOC1`, item 49). It
touched **41, 46, 49, 50**; the old "Session K = `3936b43e`" credit on item 50 was
wrong — `9ea404ec` raised it (settled at the `3936b43e` review below).

Session `3936b43e` (4 Sep, straight after) is the one that succeeded: it verified
the PROJ-1799 chat fix on the phone both directions in ~26 minutes and wrote the
finding back into a new journey — the write-back item 49 asks for, done right. It
also corrected 3 Sep notes that read a debug-sim build and wrongly concluded the
bug did not reproduce (item 16, a build-mode false negative). Touched **16, 46,
49**. The one blot: it too opened by hand-walking until told, again, to use the
journeys.

Session `46c62657` (4 Sep) is the maestro-docs audit (Session M): it drove **no
device** — so the hardware queue mis-listed it, corrected on review (its UDID hits
were doc content) — and raised item 52, gave item 19 a concrete instance (three
contradictory "measured" iPad-transform notes) and item 16 the version-drift
point. Its conduct half — over-long responses the user twice called out, asserting
without checking, committing to a branch unasked — went to the retrospective.

Session `a4d6c149` (Session L, 4 Sep) closes the hardware queue. It verified the
chat fix on the phone, then — prompted by the user's `/btw` history, which had
been flagging coordinate-stabbing and hand-walking for weeks with none of it
reaching the model — reviewed its own driving and reached this review's own
conclusion independently: the behaviour memories were loaded and ignored, so the
fix belongs in the skill (items 49, 51, 56), not in memory. It wrote items 46-L,
49-sharpened and 51, and is the decisive evidence for **56**. Conduct (the `/btw`
gap, hand-walking despite loaded memories) → retrospective.

**Hardware queue complete (9 Sep): six device sessions reviewed** — 90833915,
480adcc1, 0598a4b6, 9ea404ec, 3936b43e, a4d6c149 — plus 46c62657 reclassified as
docs-only. New items raised across the pass: 53, 54, 55, 56.

**`SKILL.md` rules to add from the hardware review — apply as one change.** The
drafted wording lives in each item with its full context; apply them together, not
piecemeal, because they touch one section:

| change | item | what |
| --- | --- | --- |
| rule 1 extension | 49 | the unit of work is a journey file; journey-first check before driving a screen |
| rule 3 extension | 56 | do not carry a coordinate across calls — resolve and tap in one |
| rule 6 extension | 14 | a filled field is not a set value; assert the committed value, not the visible text |
| new rule 9 | 55 | test before reporting a capability impossible; docs/assumptions are not authority over a device test |
| `PreToolUse` hook | 51 | ship `gate-journey-first.sh`; the literal `settings.json` block is in item 51 |

Rules 1/3/6 (and 7, already present) are *sharpenings of rules that exist and were
not being read* — item 51's hook is what enforces adherence, so it is part of the
same change, not a separate wish. This is item 56's whole point made concrete.

**Applied in `src/` and shipped 10 Sep 2026.** The whole table landed as one
change: rule 1 extension, rule 3 extension, rule 6 folded into "Assert inside the
batch", new rule 9, plus item 49's start-of-session step (journeys/flows/`COVERAGE.md`),
its `preflight.sh` count line, and a new rule 10 (a conf credential is only readable
inside the toolkit's own process). The `PreToolUse` hook ships in-skill: the draft
became `src/hooks/gate-journey-first.sh`, `ship.sh` carries and syntax-checks it, and
the `settings.json` block is documented in `reference/setup.md` § 5 for a person to
apply. Nine hook behaviour tests added; suite 170 → 179, all passing. Left for the
operator, all done by 11 Sep: the ship ran 10 Sep, the § 5 hook entry is in
`~/.claude/settings.json` (line 35 points at the skill's `hooks/gate-journey-first.sh`),
and the interim standalone `~/.claude/hooks/gate-journey-first.sh` has been deleted.

## Prioritisation matrix (9 Sep 2026)

Every open item scored against your core considerations — read from what you
pulled me up on across these sessions — plus two axes I've added for growing the
skill. Adjust the axes or weights and the order falls out again.

- **T — Time** wasted for the operator/session the fix removes. *("wasted an hour", "take less time" — your most-repeated concern.)*
- **S — Silent failure** it stops: a wrong result that reports success (tap ok but nothing moved, empty PIN, build-not-installed). The kind that corrupts a review.
- **M — Method** discipline: makes the right approach (journeys, the resolver) the default or enforced.
- **R — Reach**: the fix lives in the skill, so every Flutter repo gets it — not one project's notes/memory.
- **C — Concurrency**: supports several reviews at once without interference.
- **Eff — Effort** (added): implementation cost, L/M/H — low effort lifts priority.
- **⚑ Foundational** (added): unblocks other items.

Each axis 0–3. **P = 2·T + 2·S + M + R + C** (Time and Silent doubled — your top two). Tiers group by leverage, not raw P alone.

### Now — highest leverage (do these first, as one programme where linked)

| # | Item | T | S | M | R | C | Eff | ⚑ | P |
|---|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 49 | Read/replay existing journeys, not ad-hoc driving | 3 | 2 | 3 | 3 | 0 | L |  | 16 |
| 51 | Ship a hook (enforce the discipline) | 3 | 2 | 3 | 3 | 0 | M | ⚑ | 16 |
| 41 | `expect` with a timeout — kill the sleep-spam | 3 | 2 | 2 | 3 | 1 | M |  | 16 |
| 46 | Driver dies mid-session; errors blame the relay | 3 | 2 | 1 | 3 | 1 | H |  | 15 |
| 36 | A journey stops after one line and exits 0 | 2 | 3 | 1 | 3 | 0 | M |  | 14 |
| 40 | `build.sh` exits 0 without installing | 2 | 3 | 0 | 2 | 0 | L |  | 12 |
| 56 | Skill-usage conduct belongs in the skill, not memory | 2 | 1 | 3 | 3 | 0 | M | ⚑ | 12 |
| 24 | Concurrency: per-device vmservice + relay ports | 2 | 1 | 0 | 2 | 3 | M | ⚑ | 11 |
| 17 | Packaging: installer, version, manifest, git | 1 | 0 | 0 | 3 | 0 | M | ⚑ | 5 |

**Why these, and how they connect.** Four are one programme, not four wishes:
**17** (packaging) lets the skill ship a **51** (hook), which enforces **49**
(journeys over ad-hoc) and **56** (conduct lives in the skill) — prose alone has
failed that across five+ sessions, so the hook is the lever. The rest are the
biggest standalone wins: **41** (a wait-for-condition primitive) erases the
single largest time sink; **46** (driver stability) the biggest reliability one;
**36**/**40** are cheap stoppers for the worst silent failures; **24** makes the
concurrency you already use routinely actually safe.

### Next

| # | Item | T | S | M | R | C | Eff | ⚑ | P |
|---|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 57 | Contradictory iPad-tap docs; steer to `tapon` | 2 | 2 | 2 | 3 | 0 | L |  | 13 |
| 50 | Flat phone crashes the driver on first touch, silently | 2 | 3 | 0 | 2 | 0 | M |  | 12 |
| 26 | Unlabelled controls / iPad rail need coordinates | 2 | 2 | 1 | 2 | 0 | M |  | 11 |
| 30 | Keyboard guard fires when the keyboard is down | 2 | 2 | 1 | 2 | 0 | M |  | 11 |
| 39 | `vmservice.sh` finds nothing while run is healthy | 2 | 2 | 0 | 2 | 0 | M |  | 10 |
| 31 | `typed.py` passes when text landed elsewhere | 1 | 3 | 0 | 2 | 0 | M |  | 10 |
| 19 | Two notes contradict each other unnoticed | 2 | 2 | 1 | 1 | 0 | M |  | 10 |
| 52 | Nowhere to put a non-app finding (app-notes bloat) | 2 | 1 | 1 | 3 | 0 | M |  | 10 |
| 55 | Shipped docs stale/wrong about physical iOS | 1 | 2 | 1 | 3 | 0 | M |  | 10 |
| 45 | Physical iPhone support lives outside the skill | 2 | 1 | 1 | 3 | 0 | H |  | 10 |
| 44 | Four things a flow can say a journey cannot | 1 | 1 | 2 | 3 | 0 | M |  | 9 |
| 47 | `relay.py` relays into itself (viewer down) | 2 | 1 | 0 | 2 | 1 | L |  | 9 |
| 53 | Resolver ignores the predictive-text/QuickType bar | 1 | 2 | 1 | 2 | 0 | M |  | 9 |
| 58 | No clean way to force a timed state; read orientation | 2 | 1 | 1 | 2 | 0 | M |  | 9 |
| 60 | `erase` can't clear a field (deletes from caret) | 1 | 2 | 1 | 2 | 0 | L |  | 9 |
| 48 | MCP server hardcodes one SSH alias | 1 | 1 | 0 | 2 | 2 | L |  | 8 |
| 33 | Renderers truncate strings meant to be copied verbatim | 1 | 2 | 0 | 2 | 0 | L |  | 8 |
| 29 | `tapon` can't take `--anyway`; refusal misleads | 1 | 1 | 1 | 2 | 0 | L |  | 7 |
| 38 | No way to assert enabled/disabled state | 1 | 1 | 1 | 2 | 0 | M |  | 7 |
| 43 | `tree` has no compact mode (noise, no dedup) | 2 | 0 | 1 | 2 | 0 | M |  | 7 |
| 54 | Reading persisted prefs is a multi-step gotcha | 1 | 1 | 1 | 2 | 0 | M |  | 7 |

### Later

| # | Item | T | S | M | R | C | Eff | ⚑ | P |
|---|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 32 | `tree.py` runs the flag column into the label | 1 | 1 | 0 | 2 | 0 | L |  | 6 |
| 37 | Nowhere to keep a second set of test values | 1 | 0 | 1 | 2 | 0 | M |  | 5 |
| 42 | No way to run a project's own script on the Mac | 1 | 0 | 1 | 2 | 0 | M |  | 5 |
| 59 | Home-dir dotfiles surface at the repo root | 1 | 1 | 0 | 1 | 0 | L |  | 5 |
| 22 | Bitbucket fetch on the Mac reads as a missing key | 1 | 0 | 0 | 2 | 0 | L |  | 4 |
| 34 | `--explain` marker per level reads as compounding | 0 | 1 | 0 | 2 | 0 | L |  | 4 |
| 23 | `secrets.sh check` doesn't check the conf is protected | 0 | 1 | 0 | 1 | 0 | L |  | 3 |
| 35 | Keyboard test uses the centre only | 0 | 1 | 0 | 1 | 0 | L |  | 3 |
| 27 | Flutter a11y finding parked with no ticket | 0 | 0 | 0 | 0 | 0 | L |  | 0 |
| 28 | Machine/client data left in the directory | 0 | 0 | 0 | 0 | 0 | L |  | 0 |

## Where the evidence is

The transcripts live in the local Claude Code projects directory for the app's
checkout. Session ids throughout this file are synthetic placeholders: they are
consistent with each other and with the review tracker, so every cross-reference
still resolves, but they are not the real transcript ids.

| ref | session | when | what it was doing |
| --- | --- | --- | --- |
| **M** | `46c62657` | 4 Sep, 14:06–15:09 | Auditing `brandco-flutter-runner`'s whole `maestro/` directory for duplicates, contradictions and stale documents, then applying the fixes. Raised **52**; strong instance of **19** (three contradictory "measured" iPad-transform notes) and **16** (version-drift). No device driven; no MCP calls. **Reviewed 9 Sep — the 9 Sep hardware queue mis-listed it as a device session; the XS Max UDID appears in it only as content of the docs it was editing (0 `devicectl`, 0 `mac.sh`). Reclassified: docs-only.** |
| **L** | `a4d6c149` | 4 Sep, 11:2x–12:0x | Verifying the PROJ-1799 chat empty-state fix on the physical iPhone XS Max — reproduced it on a pre-fix profile build, then built and installed the fix branch and re-ran. Raised **51**, added a second half to **46** (the driver dies between processes, and item 46's own proposed keep-alive makes it worse) and a recurrence to **49** (the journeys directory was listed and hand-walked anyway). One device; no MCP calls. **Reviewed 9 Sep (last of the hardware queue) — also the decisive evidence for item 56 (two behaviour memories loaded at start, hand-walked anyway) and where the item 51 hook was drafted; it self-corrected its own "Session K"→"L" mislabel. `/btw` conduct → retrospective.** |
| **K** | `3936b43e` | 4 Sep, 10:29–10:55 | Verified the PROJ-1799 chat empty-state fix on the physical XS Max both directions — reproduced on the pre-fix build, confirmed gone on the fix build — and wrote `29-chat-empty-state.journey` with a build-mode caveat. Corrected the 3 Sep notes that wrongly said the bug "does not reproduce" (they read a debug simulator build). It did **not** raise item 50 — that was `9ea404ec` (4 Sep AM); the earlier "raised 50" credit on this row was wrong. Touched **16, 46, 49**. Reviewed 9 Sep. |
| **G** | `c0c6fbc5` | 20 Aug, 15:0x–16:0x | Reconciling an outside Maestro suite (`handover-maestro`, build 1.0.0-uat, store 4002) into `brandco-flutter-runner`'s journeys, then running seven of the results against the iPhone 16 Pro. Raised **36–38** and **41–44**, and added a second sighting to **30**. One device; no MCP calls. |
| **H** | `de240800` | 20 Aug, 10:0x–13:5x | Code and UI review of `proj1772-review`, with a `flutter run` and HTTP capture on the iPhone 16 Pro. Raised **39** and **40**, and wrote both into `build/…/reference/` instead of here — recovered from the transcript by session G. Also the session that established the skill tree is writable from the sandbox after four sessions had claimed otherwise. |
| **F** | `91879ddf` | 19 Aug, 14:5x–16:0x | Auditing `brandco-flutter-runner`'s `maestro/` docs for internal conflicts, then settling four of them against the iPhone 16 Pro. Raised items **29–35** and answered the open question in **14**. Drove one device only; no MCP calls. |
| **`90833915`** | `90833915` | 14 Aug, 13:52–16:14 | GSD phase-03 (automated-logout) execute, waves 7–8. Verified 03-12/03-13 on the iPhone 16 Pro *simulator*, created three store-4001 requests behind a temporary `type:""` patch (reverted clean), then made the **first physical-device attempt** — an iPhone 11 (`00008030-0022334455667788`) that Maestro could not drive and that no signed current build could reach. `devicectl` read the app's prefs plist off the phone. Touched **14, 45, 47**; raised **53**. First of the hardware-queue review, 9 Sep. |
| **`480adcc1`** | `480adcc1` | 21 Aug, 08:49–12:06 | The physical-device bring-up that actually worked: signed and installed the branch on the iPhone XS Max via the `osascript`/Aqua route, re-signed Maestro's prebuilt `driver-iphoneos` products, forwarded the driver port over usbmux (~50 lines of Python), pinned the port so `driver.sh`/`resolve.py` drove the phone; wrote `src/physical-device.md`. Then the first-run login stalled on the dropdowns (item 14) and **none of the 7 outstanding hardware tests ran** in three hours. Touched **14, 16, 42, 45, 46, 50, 52, 53**; raised **55**. The real source for item 45, not the evidence table's H. Reviewed 9 Sep (+ raw pass + narrated-but-unflagged pass). |
| **`0598a4b6`** (Session I) | `0598a4b6` | 21 Aug, 12:07–15:38 | The idle-timeout run that finished plan 03-11 on the physical XS Max (all 7 checks passed) and **wrote item 46**. ~3.5h, much of it lost: journeys existed but were broken (item 14) so login was re-derived by raw taps (104, against 5 `tapon`); 179 `sleep`s and 0 `expect` in hand-rolled poll loops (item 41); screenshots used to find elements (a repeat the user had covered). Touched **14, 41, 46, 49**; raised **56**. Wrote the repo-level `driving_the_app_wasted_time.md`. Reviewed 9 Sep (all three passes). |
| **`9ea404ec`** | `9ea404ec` | 4 Sep, 08:46–10:29 | Tried to reproduce and fix the chat empty-state error (PROJ-1799) on the physical XS Max with the 21 Aug infra. Reproduced nothing in ~1h43m: hit the flat-phone crash (**raised item 50 here**), the driver crashed repeatedly (item 46), `settle` hit its 20 s ceiling four times per login (item 41), and a journey failed on retired data (`LOC1` gone, item 49). Stopped twice, then "I'll get another session". Touched **41, 46, 49, 50**. Reviewed 9 Sep (all three passes). |
| **A** | `c286da8d` | 12 Aug, 08:13–08:59 | GSD phase-2 verification on iPhone + iPad. 131 Bash calls, 12 MCP calls, 8 of 9 steps verified. |
| **B** | `b4184377` | 11 Aug, 20:47–22:11 | PROJ-1789 code and UI review on iPhone + iPad. 171 Bash calls, 18 MCP calls, 13 findings. |
| **C** | `379d06ed` | 12 Aug, 09:09–11:25 | Task-locking sign-off on two iPhones, after an iPad attempt was abandoned. 279 Bash calls, 110 of them `driver.sh`, no MCP calls. |
| **D** | `1d33fec2` | 12 Aug, 13:04–14:01 | Code and UI review on iPhone. 126 Bash calls, 62 `driver.sh`, 24 screenshots taken and 14 read, no MCP calls. iPad dropped from the review. |

C and D are the sessions the re-evaluation added. Neither used the MCP server at
all, which is a change from A and B and closes some of what follows.

Timestamps below are wall-clock in each transcript, so a stretch can be found
by searching for the time.

---

## 1. One driver, one port — a second simulator cannot be driven — **DONE 12 Aug**

**Sessions: A and B.** B lost 17 minutes to it (21:22–21:39) and B's second
switch back (21:51 onwards) was never recovered. A lost the same argument at
08:26 and needed the user to intervene at 08:51.

`McpMaestroSessionManager` keeps a `ConcurrentHashMap<deviceId, session>` with
no invalidation path, and hardcodes `127.0.0.1:22087`. Asking for a second
device creates a second session object pointing at the same port, where the
first device's driver is still listening. **The wrong device's screen comes
back looking exactly like a correct answer.** B took a "screenshot of the iPad"
at 21:22 and got the iPhone; A did the same at 08:26.

What the transcripts establish:

- Reconnecting the MCP server, *then* touching the new device first, is the
  only thing that rebinds it.
- `pkill -f maestro-driver-ios` makes it worse, not better. B did this at
  21:52 and every later MCP call failed with `Device became unreachable during
  deviceInfo`. That session never got the fast path back.
- `maestro --device <udid>` from the CLI is ignored while another driver holds
  the port (B, 21:28).

**Fixed.** The experiment worked. `bin/drivers.sh` starts one driver per
simulator, each on its own port, using Maestro's own build products and
`xcodebuild test-without-building` with `TEST_RUNNER_PORT` — the port reaches
the runner as `PORT`, which `XCTestHTTPServer.swift` reads. `driver.sh`
resolves the port from `DEV`. Verified live: iPhone and iPad driven
simultaneously, a `launchApp` on one leaving the other untouched. ~30 s cold
per device, ~12 s warm, reads unchanged at 0.43 s. Mechanism and the three
tested facts are in `reference/driver-api.md`; the rules are in `SKILL.md`.

**One thing turned out worse than described here.** MCP does not merely return
the first device it bound — it returns whatever device is on 22087 at the time.
With the iPad's driver there, `inspect_screen` for the iPhone's UDID returned
the iPad's tree.

## 2. `DEV` does nothing for `driver.sh` — **DONE 12 Aug**

**Sessions: A and B**, both throughout. B prefixed roughly fifteen commands
with `export DEV=<ipad-udid>` believing it targeted the iPad (21:39 onwards).
It did not — the MCP rebind did.

`driver.sh` never calls `_dev()`. It talks to whatever driver is on port 22087.
`DEV` only reaches `hier.sh`, `flow.sh`, `net.sh`, `publish.sh`, `preflight.sh`,
`shot.sh`, `bench.sh`. `SKILL.md` reinforces the wrong belief: "Pin it before a
long run — the driver is per-device."

**Fixed as part of item 1.** `DEV=<udid>` now selects the device for every
`driver.sh` command. With one driver and no `DEV` it uses that one; with
several and no `DEV` it refuses and lists them rather than picking. The
device-to-port map is read from the live runner processes on the Mac — the
process runs out of the simulator's data container, so its command line carries
the UDID — so there is nothing to keep in step by hand.

## 3. `net.sh` returns nothing — HTTP profiling is off by default — **DONE 12 Aug**

**Sessions: A and B.** B hit it at 21:08, spent five minutes, concluded "wrong
isolate or a non-`dart:io` client" and **abandoned network capture**, reading
source instead. A hit the same wall at 08:44 and found the cause at 08:47:
`ext.dart.io.httpEnableTimelineLogging` is off until something turns it on.

A wrote the discovery to the *project's* app notes under "open questions", so
the skill still does not know it.

**Fixed.** `publish.sh start` reads the flag, turns it on, and reports which of
the two it was — `was off, now on — only calls made from here on are captured`,
or `already on`. `net.sh` no longer prints nothing on an empty list: it checks
the flag and says either "profiling was OFF, that is why this is empty, it is
on now, repeat the action" or "profiling is on, the app really has made none".

**A second cause found while verifying this.** `remote/vmservice.sh` handed
back dead isolates. Its `valid()` accepted any reply containing `"type"`, and a
collected isolate returns `{"type":"Sentinel","kind":"Collected"}` — so after
every hot restart the cache passed validation and `net.sh` read an isolate that
no longer existed, coming back empty. It now requires `"type":"Isolate"`.
Confirmed live: a hot restart also resets the profiling flag, so both faults
fired together on exactly the workflow the sessions were using.

Verified against a throwaway Flutter app on the iPad: capture works, both
empty-list branches produce the right message, and the advice to repeat the
action and read again does then show the request.

## 4. `published.state` cannot be found without reading the source — **DONE 12 Aug**

**Sessions: A and B.** B took five calls to locate it (21:08:43–21:09:23:
`find`, two greps of `lib.sh`, a grep of `config.sh`, then a `bash -c` to
source it). A took six (08:46:11–08:47:01).

`LDIR` is only defined inside `config.sh`, so any ad-hoc VM service call means
hunting for it first.

**Fixed.** `publish.sh start` and `publish.sh status` both print a labelled
block: base URI, isolate, profiling state, state file path, and the two ways to
read it — `net.sh`, or the exact two lines for an ad-hoc curl.

## 5. Building the branch on the Mac is not in the skill — **DONE 13 Aug**

**Session: B**, 20:53:12–20:57:39 — 4.5 minutes between the first build attempt
and the build actually starting, working out three things from scratch:

- Flutter is fvm-pinned at `.fvm/flutter/bin/flutter`, nothing on `PATH`
- CocoaPods needs `GEM_HOME=$HOME/.gem` and `$GEM_HOME/bin` on `PATH`
- the build is flavoured: `--flavor dev -t lib/main_dev.dart`

The build itself took 62 seconds. **Session A paid none of this** because B
wrote the recipe to a project memory file at the end — which is the proof it is
worth having, and also the problem: it is stored per project, so the next app on
the same Mac pays it again.

**Done.** `bin/build.sh` (local) and `remote/build.sh` (on the Mac), one round
trip. All three are worked out from the repo rather than configured, which is
what stops the recipe being per-project:

- **The SDK**, pinned first. `$REPO/.fvm/flutter/bin/flutter`, then the older
  fvm layout, then the version named in `.fvm/flutter.version` under
  `~/fvm/versions`, then `PATH`, then the usual install locations. Pinned wins
  over `PATH` deliberately: it is the version the project expects, so a
  different one on `PATH` is a worse answer rather than a fallback.
- **CocoaPods**, only when needed. `GEM_HOME` is reported only if `pod` is
  genuinely absent from the PATH the build will have — setting it when it is
  not needed breaks a working install just as easily.
- **The flavour, from the bundle id.** This is the part worth keeping. Xcode
  names each build configuration `<Debug|Release|Profile>-<flavour>` and each
  carries its own `PRODUCT_BUNDLE_IDENTIFIER`, so `APP_ID` traces back to the
  flavour that produces it. On the real project that picked `dev` out of six
  candidates with evidence rather than from the name happening to match.

A flavour counts only if **both** halves exist — an Xcode scheme of that name
and a `lib/main_<flavour>.dart`. That one rule discards a template entrypoint
(`main_env.tpl.dart`), an extension's own scheme, and either half on its own,
without the script knowing about any of them. If the bundle id is not decisive
it lists the candidates and refuses: building the wrong flavour installs a
different bundle id and leaves the app under test exactly as it was, and nothing
reports that.

`--detect` reads and reports without building, and is the thing to run before
asking the user. `SKILL.md`'s rule that nothing builds unprompted is restated
rather than weakened — the script existing is not permission to run it.

**Both halves of what this item said about Bitbucket were wrong, corrected
13 Aug after re-reading the sessions.** It said the Mac has no Bitbucket key and
that the problem had not recurred. The Mac has one, and it recurred the same
afternoon — see item 22.

Verified with a real build: 36 s end to end on the iPhone 16, 22 s of it Xcode,
installed and then confirmed by item 6's preflight check. Seventeen test cases
offline against a fake repo built to the same shape; 126 became 144.

## 6. Nothing checks the installed app is the code under test — **DONE 13 Aug**

**Sessions: A and B**, both inventing the same check independently in three or
four calls: `simctl get_app_container`, then grep
`Frameworks/App.framework/flutter_assets/…` for a string only present on the
branch under test.

B found the simulator running a build from a different branch (20:50:05). A
found the same (08:14:17). Without the check both reviews would have been
worthless, and it is the first thing you need before trusting anything on
screen.

**Fix.** `preflight.sh` already reports the repo branch and whether the app is
installed, but never compares them. Add the installed bundle's build date and
an optional marker string to grep for.

**Fixed 13 Aug.** A third instance turned up that morning without anyone looking
for it: the Mac's checkout was on `proj1787-review` while the local branches were
elsewhere.

- `remote/appcheck.sh` — reads the installed bundle's executable timestamp and
  version from `Info.plist`, compares it with the newest commit in the Mac's
  checkout, and says which. A file rather than more lines inside preflight's
  SSH string so it can be run and tested off a Mac; sent base64-encoded as part
  of the command, so preflight is still one round trip.
- `BUILD_MARKER` in the conf — optional, a string only the build under test
  contains. Deliberately not named `APP_*`, because those are exported as
  project values and searched for by `secrets.sh` as though they were
  credentials. Adds about a second to preflight.

The wording is careful about what it knows. Older than the newest commit is a
fact and is called STALE. Newer is not proof of the branch, because a checkout
can move after a build, and the output says so rather than implying a clean
bill of health.

Two bugs the tests caught before this went anywhere, both of the silent kind:
`stat -f` exists on GNU as well as BSD and means *file system status* there, so
it succeeds and prints a block count that was about to be compared against a
commit date; and reading a plist value from the line after its key returns the
*next* key's value when the two sit on one line. 7 tests, offline, with fixture
timestamps set at both signs of the comparison.

## 7. Exploration is one action per round trip, plus redundant sleeps — **DONE 13 Aug, and the premise was half wrong**

**Session A**: 75 `driver.sh` Bash calls containing **88 `sleep N` statements**.
**Session B**: 57. **Session C**: 1, across 110 `driver.sh` calls. **Session D**,
four hours after C: 44. So it was never a trend, it was per-session luck about
whether the model trusted `settle`.

Only 45 of A's 75 calls combined an action with a read; the rest were `tapon`
alone then `nodes` alone. Journeys solve this for known sequences, but
exploration is where the sessions spent their time and journeys do not apply
yet.

**The premise, corrected 13 Aug.** This item said `tapon`, `tap`, `type` and
`swipe` all already called `_settle`, so every sleep was redundant. That was
true of the **journey** verbs and false of the **command-line** ones, where only
`tapon` and `type` waited. Counting what each sleep actually followed:

| the sleep followed | A | B | C | D | total |
| --- | --- | --- | --- | --- | --- |
| a verb that already settled (`tapon`, `type`, `script`) | 73 | 18 | 0 | 21 | **112** |
| a verb that did **not** (`tap`, `text`, `key`, `swipe`, `erase`, `launch`) | 15 | 13 | 0 | 14 | **42** |
| not a `driver.sh` call at all | 0 | 26 | 1 | 9 | 36 |

So 42 of them were doing real work, and the rule this item asked for would have
been wrong as written. The gap had to be closed before the rule could be true.

**Done.** Three changes:

1. **The command-line action verbs now settle**, like the journey verbs always
   have: `tap`, `text`, `key`, `button`, `erase`, `swipe`, `launch`, `orient`.
   A settle timeout warns on stderr and leaves the exit status alone — the
   action happened; only the screen is still busy. Journeys keep the stricter
   rule, where a timeout fails the step. `SETTLE=0` now means *do not wait*
   rather than *fail immediately*, which is the escape hatch for a screen that
   never stops moving.
2. **`--tree` / `--nodes` on every action verb**, read directly after the verb,
   printing the screen once the action has settled. Not at the end of the line:
   `type` takes the rest of the line as the text to type, and a flag there
   would be typed rather than obeyed. The screen prints even when the action
   failed, which is when it is most worth seeing. Measured live: 2.29 s
   combined against 2.61 s as two calls, so the process saving is 0.3 s and
   beside the point — what it removes is a decision cycle.
3. **The rule, in `SKILL.md` rule 5**, now naming every verb and saying never
   add a sleep, rather than the old "`settle`, not `sleep`" — which a model
   could satisfy while still sleeping after every `tapon`. Also in
   `reference/driving.md`, `reference/driver-api.md` and `reference/journeys.md`.

The inline python that printed the tree moved to `bin/tree.py` so both call
sites could share it, verified byte-identical against all three fixtures in both
modes first. That also made the renderer testable for the first time.

**Testing driver.sh at all is new.** It binds to a driver on the Mac at load, so
nothing in the suite had ever run it. A stub `curl` and a stub `lib.sh` in the
test give it a fake device that is always up, always still and always shows a
fixture, which is what makes the flag parsing and the settle rule checkable
offline. Eleven cases; 93 tests became 105.

## 8. On iPad the resolver works in the wrong coordinate space — **DONE 12 Aug; landscape app-control `tapon` confirmed working 19 Aug**

**Sessions: A, B and D.** A and B could not use `tapon` on the iPad at all and
fell back to raw `tap x y` with hand arithmetic on every action (B from 21:41,
A from 08:53). D gave up on the iPad entirely: *"the tap resolver doesn't apply
this app's iPad coordinate conversion, so signing in by hand cost more than the
remaining findings were worth"* — an iPad was dropped from a code review because
of this.

**What this item claimed, and what is actually true.** It said `/touch` takes
portrait-referenced coordinates, so every tap needed converting. Measured on
12 Aug against the runner app on an iPad Pro 11-inch: it does not. `/touch`
takes **app-space** coordinates and app controls need no conversion at all —
the whole of `00-login.journey`, `01-device-setup.journey` and every navigation
tap land untransformed. What is in a different space is only what **iOS** draws:
the status bar, permission alerts and the keyboard. The evidence quoted here was
gathered against a throwaway app, which may not have been landscape-locked.

**Its proposed fix cannot work.** "Compare the root frame's aspect against
`/deviceInfo`" — `/deviceInfo` returns `1194x834`, the same as the app root, so
there is no mismatch there to detect. Checked live. What does work is the status
bar: it is always present, always a thin strip along one edge, and when it comes
back `24x1194` against a `1194x834` screen the two spaces are transposed, with
its `x` saying which way round.

**Fixed** in `bin/resolve.py`: `system_transform()` converts system-drawn nodes
from native space into app space, and `keyboard_band()` takes the keyboard's top
edge from its size rather than its position. `tapon "^Allow$"` now dismisses the
notification permission dialog first time, and `00-login.journey` runs clean on
the iPad unmodified — the step that used to fail. Covered by
`test/run-tests.sh`, with fixtures captured off both devices.

**Left over.** The mirrored transform, for when the status bar sits at `x=0`,
is arithmetic that has not been confirmed against a real tap. One tap on a
system alert in `landscapeRight` would settle it.

**Landscape app controls confirmed working via `tapon` — sessions `d32077c5`
and `2696b9ae`, 19 Aug.** Two sibling iPad Pro 11-inch (`F0EDF404`) reviews an
hour apart, read together, settle this — and correct a first pass that misread it.
(The operator-guidance gap this exposed — both sessions hand-transforming raw taps
instead of using `tapon`, misled by a docs contradiction — is item 57.)

- `d32077c5` (12:54) drove the iPad's app controls with **raw** `driver.sh tap`
  and a hand-computed transform, and concluded (correctly, for raw tap): *"raw
  driver.sh tap on APP controls DOES need the transform `device_x = 834 - app_y`,
  `device_y = app_x`."* It never invoked `tapon` on the iPad, so it could say
  nothing about whether the resolver handled the transform.
- `2696b9ae` (13:26) tested that directly in `landscapeLeft` and measured, verbatim:
  *"tapon DOES work on iPad app controls. driver.sh tap 599 962 — the converted
  centre of the 4001-55368 task card (app centre 962.8,236.3; device_x = 834 -
  app_y) — did nothing on two attempts, and tapon "4001-55368" opened it first
  time. CORRECTS the 11 Aug note saying tapon/find resolve correctly but tap the
  wrong place on iPad."*

So `tapon` applies the landscape transform internally and taps app controls
correctly, including in `landscapeLeft` — the fix holds in landscape, not only the
portrait path it was first verified in. What is unreliable is **raw** `driver.sh
tap`: even the correct hand-conversion `(834 − app_y, app_x)` did nothing twice,
where `tapon` worked first time. The lesson from `d32077c5` is therefore conduct,
not a toolkit gap: it reverted to raw `tap` with hand arithmetic on the iPad
instead of using `tapon`, hand-rolling — unreliably — a transform the resolver
already does. The one genuine iPad remainder both sessions still hit is the
**navigation rail**, which has no accessibility-tree entries and so cannot be
resolved by selector at all — that is item 26, not this item. This also settles
the old "Left over": the transform is real and `tapon` applies it.

## 9. The occlusion refusal does not say what is covering the element — **DONE 13 Aug**

**Session A**, 08:23:29–08:24:00. The model read the refusal as a false
positive, overrode it, tapped anyway and typed a stray `f` into a store field.
The refusal had been correct — the keyboard was on top of a dropdown that
looked visually above it.

What was *thought* to have worked, found at 08:24:26 and recorded only in the
project's notes: type to filter the list, then `key return`, which commits the
match and drops the keyboard.

**Premise revised 12 Aug.** This was written up as a correct refusal that got
overridden. Since then the guard has been shown wrong in both directions — on
iPad it fired on every element on screen, on iPhone it never fired at all (see
item 8). Both are fixed, so the refusal can now be trusted, which makes naming
the covering node worth doing rather than papering over a bad guard.

**Premise revised again 13 Aug, and the fix this item proposed was wrong.** It
said the refusal message should point at filter-then-return. It must not. Item
14 measured that method on a clean install: the list does not always filter, and
`key return` dismisses the keyboard without committing anything. Sending someone
who has just been refused a tap towards a method that silently selects the wrong
row is worse than saying nothing.

**Done.** The refusal now shows its working, which is the only thing that would
have changed session A's mind:

```
resolve: /^SETTINGS/ is at [40.2, 804.5], which is UNDER THE KEYBOARD — the tap
will hit the keyboard instead
  the keyboard's top edge is y=569 and this centre is 235.5 points below it
  569 is the 874-point screen less the keyboard's thickness of 305, measured
  from SystemInputAssistantView 402x72 and keyboard 402x233 — sizes, not
  positions, because the keyboard reports its position in the device's own
  space rather than the app's
  dismiss the keyboard or scroll the element clear, tap it, and then assert
  what happened with `expect` rather than assuming the tap took
  --anyway taps regardless. On 12 Aug that was done on the belief that the
  refusal was a false positive, and it typed a stray character into the field
  underneath
```

The awkward part was the third line. Naming the covering containers means
printing their frames, and their *positions* arrive in the device's own space —
which is precisely what made the guard wrong in both directions until 12 Aug. A
message quoting a position beside an app-space edge would invite the same
mistake it is trying to prevent, so it prints the sizes and says why.

The off-screen refusal got the same treatment: which way and how far past the
edge, rather than "scroll it into view", plus the warning that a node reported
`0,0 0x0` is off a scrolling container's viewport and that dismissing the
keyboard does not bring it back (measured 13 Aug).

`find --explain` carries the same reasoning, since that is the read that comes
before the tap. `keyboard_band` was split into `keyboard_geometry`, which
returns the edge, the thickness and the containers behind them, with
`keyboard_band` left as a wrapper so its existing test and contract are
untouched. Nine test cases, including one that fails if the advice ever points
at filter-then-return again; 105 became 114.

## 10. `init.sh --host X --detect` does not look for the checkout — **DONE 13 Aug**

**Sessions: A and B.** B spent three SSH calls hunting for it at 20:48:41
(`ls -d ~/src/* ~/Development/* ~/Projects/*`, then
`find ~ -maxdepth 4 -type d -name …`). A had it in the conf already.

**Done.** `--host <alias> --detect` now lists the checkouts under the Mac's home
directory and marks the right one, in the same call that already reports
simulators and installed apps. `remote/findrepo.sh` prints `<path>\t<origin>`
for each; `init.sh` ranks them.

Two things it does rather than the obvious:

- **It matches on the remote, not the directory name.** Two repositories can be
  spelt the same and only one of them is yours. `git@host:org/thing.git` and
  `https://host/org/thing` are reduced to `host/org/thing` — lowercased, no
  `.git`, no scheme, no user — which is enough to match the two forms without
  pretending to parse URLs. A name-only match is still shown, labelled as one.
- **It prunes the caches.** Without that the answer is a screenful of
  `.pub-cache` clones with the real checkouts lost among them: measured on the
  Mac, 4.3 s and mostly noise unpruned, 3.3 s and twelve real checkouts pruned.
  `Library`, `.pub-cache`, `.gradle`, `node_modules`, `Pods`, `.fvm`, `.Trash`,
  `.cache`, `.cocoapods`, `DerivedData`.

Verified against the real Mac: twelve checkouts, the right one first and marked
`<- same origin`. The whole `--detect` call is 5.1 s.

## 11. No screenshot crop or rotate — **DONE 13 Aug**

**Session B**, about eight times between 21:23 and 21:58: `sips -r 270` to
correct the landscape iPad, `sips -c … --cropOffset …` to cut evidence images
down to the region that showed the defect. All by hand on the Mac.

**Fix.** Options on `shot.sh` / `driver.sh shot` for rotate and crop.

**Re-measured 12 Aug.** Session D took **24 screenshots and read 14 of them**,
and spent calls probing for an image tool — `python3 -c "import PIL"`, then
`which convert magick pngquant` — before hand-writing ImageMagick crops against
a 1206x2622 source. The crop happens on the Linux side after fetching, and
nothing guarantees a tool is there: PIL is **not** installed on this machine,
confirmed again today. So the fix needs to either do the crop on the Mac, where
`sips` always exists, or state a dependency.

**Fixed 13 Aug.** One correction to the paragraph above first: ImageMagick 6.9.10
*is* installed here, at `/usr/bin/convert`, and crops a 6-megapixel image in
0.15 s. Session D's `which convert magick pngquant` should have found it. PIL is
genuinely absent.

- `bin/img.sh` — crop, rotate and shrink a PNG in pixels. No dependency to
  state: ImageMagick if the machine has it, `sips` if the skill is being run
  from a Mac, otherwise the file goes to the Mac and back, where `sips` always
  exists (1.8 s). `IMG_BACKEND` pins the choice so the Mac path can be tested
  from a machine that has ImageMagick. Also `--size`, which reads a PNG's
  dimensions out of its header without decoding it.
- `driver.sh shot` — delivers the picture **upright and in app-space points**:
  `--on <pattern>` crops to a named element with `--pad`, `--crop x,y,w,h`
  takes points, `--scale` shrinks, `--raw` opts out of all of it.
- `shot.sh` — the same three pixel options, handed to `img.sh`. It has no
  hierarchy, so the upright correction and `--on` are not available there.
- `resolve.py --space` and `--rect` — the rotation and the crop rectangle come
  from the status-bar reading that already existed, so there is one detection
  rather than a second one that could disagree with it.

Measured: iPhone shot 0.6 s (no hierarchy is fetched when the picture and the
screen agree), iPad shot 1.2 s including the rotation. 15 tests added, all
offline.

## 12. No cleanup helper — **DONE 13 Aug, and it was smaller than it was written**

**Session A**, 08:58:38–08:59:07. Restoring the Mac was blocked because the
session's own builds had regenerated `ios/Podfile.lock` and `pubspec.lock`,
which then had to be discarded by hand before the branch would switch back.

**Premise revised 13 Aug.** Most of this item was about putting things back the
way they were found. The maintainer: *"I don't need them returned to a state — the
testing should be rebuilt from scratch every time."* So restoring simulator or
app state is not wanted, and anything built for it would go unused. Rebuilding
from scratch is cheap: `simctl uninstall`, `install` from a copy of the bundle,
`launch`, then the login journey — under a minute, and it guarantees a first-run
screen that no amount of tidying can.

What survived is narrow and real: **build residue in the Mac's checkout blocking
a branch switch.**

**Done.** `remote/gitstate.sh`, folded into `preflight.sh` in place of its
`git status --short | head -5`:

```
branch     unit/PROJ-1788-automated-logout-phase
residue    ios/Podfile.lock pubspec.lock
           regenerated by any build, and tracked, so a branch switch
           stops on them. Discard when they are not a real change:
             git -C <repo> checkout -- ios/Podfile.lock pubspec.lock
untracked  1 file(s) — these do not block a branch switch
```

The command is printed and **not run**. A `Podfile.lock` change can be a genuine
dependency update, and only whoever made it knows which it was. Untracked files
are counted rather than listed, because they do not block a switch — which is
the actual question.

**One bug worth remembering.** The read loop was `while read -r st path`, and
the Mac's login shell is zsh, where `path` is tied to `PATH`. Reading a filename
into it emptied `PATH` for everything that ran afterwards in the same command —
the next two sections of preflight failed with `command not found: tail` and
`command not found: appcheck`, which reads as a broken Mac rather than a shell
variable. The loop variable is `_p` now, and a test fails if `path` comes back.

Verified on the real Mac against exactly the state session A hit: the two lock
files still modified from a build the day before, now named as residue with the
command to clear them.

## 13. The CLI fallbacks are labelled for the wrong situation — **DONE**

**Sessions: A and B.** `hier.sh`, `flow.sh` and `shot.sh` all open with
"FALLBACK ONLY. Prefer the MCP server" — but the situation that actually sends
you to them is MCP being bound to the wrong device, which they never mention.
B read `hier.sh`'s header at 21:27:26 while working out exactly that.

**Fix.** Say so in the headers.

**Done.** `hier.sh`, `flow.sh` and `shot.sh` all now name the port-22087
binding, and go further than the item asked — each warns that running it starts
a driver on 22087 and replaces whatever was there. See item 15: the warning is
right, and nothing enforces it.

---

# Added by the 12 Aug re-evaluation

## 14. Filter-then-return picks the wrong entry — **DONE 13 Aug. The remaining half is the app's, not this toolkit's. Rule 6 extension ("a filled field is not a set value") built and shipped 10 Sep**

`SKILL.md` and the project journeys both teach filter-then-return as the way to
drive a searchable dropdown, because the list renders under the keyboard. It
does not reliably commit the right row.

**Session C**, on the iPad: `01-device-setup.journey` set the user to
"Other User" instead of "Test User" and the location to "4001" instead of
"LOC1". The session then hit the same thing on an **iPhone** and said so
outright: *"Same failure as the iPad — so this isn't an iPad quirk: the
journey's filter-then-return is picking the wrong entry."*

Two separate causes, only one of them fixed:

- `text ${USER}` unquoted in the journey, so `USER="Test User"` filtered on
  `Test`, which also matches "Other User" — first alphabetically, and that is
  what `key return` took. Fixed in the app repo 12 Aug by quoting.

  **Corrected 13 Aug: this is not `driver.sh text`.** The same verb behaves
  differently depending on where it is called from:

  | where | called from | what `text Test User` types |
  | --- | --- | --- |
  | `driver.sh:419` | the command line | `"$*"` — joins every argument, so `Test User` |
  | `driver.sh:342` | a journey line | `"${a[1]}"` — first token only, so `Test` |

  A journey line is `${VAR}`-expanded and *then* `shlex.split`, so a value
  containing a space silently becomes two tokens and everything after the first
  is dropped. `type` at line 339 has the same shape with `${a[2]}`. Quoting in
  the journey works around it; the verbs disagreeing with each other is the
  actual defect, and it is not specific to any app — the failure is silent
  because a truncated string still filters a list and still matches something.
- With the quoting fixed, the **user** field commits correctly but the
  **location** field still does not: typing `LOC1` and pressing return committed
  `4001`, the first entry of the *unfiltered* list, so the text never reached
  that field. Reproduced today. Tapping the filtered row works instead.

**Fix.** Two things, and the second does not depend on diagnosing the first:

1. ~~Make the journey verbs take the rest of the line rather than one token, so
   `text` and `type` mean the same thing from a journey as from the CLI.~~
   **Done 13 Aug**, and the cause was one layer below that. Splitting the line
   and *then* expanding `${VAR}` in each argument (`bin/jtok.py`) means a value
   with spaces cannot become two arguments at all, whatever the verb — so
   `tapon "^${PREFIX} Store$"` works too, and a `#` in a value is no longer a
   comment. `text` and `type` also take the rest of the line now, in a journey
   and from the CLI, where `type` had been silently ignoring everything after
   its third argument. Verified live: `text ${TESTVAL}` unquoted, with
   `TESTVAL="Test User"`, put the whole string in the field.

   A second thing fell out of it. The step log echoes the line as written, and
   it used to echo the expanded one — so `${APP_PIN}` was printed in full on
   every step that used it. It now prints as `${APP_PIN}`.
2. Have `type` read the field back and confirm what landed before moving on,
   and stop `SKILL.md` teaching filter-then-return as a general method until it
   is reliable. More work, and it catches both causes without needing to know
   which one is in play.

**Diagnosed 13 Aug**, on a clean install of the app (uninstall, reinstall,
first-run permission dialog, login journey) on the iPhone 16, so nothing carried
over from an earlier session. The backlog's own explanation — "the text never
reached that field" — is wrong. The text arrives perfectly.

Measured on the same screen, same build, same session:

| field | typed | list afterwards |
| --- | --- | --- |
| Select User | `Test User` | filtered to the one matching row |
| Select Device Location | `LOC1` | **all seven entries, unchanged** |

Both are the same widget (`lib/utils/dropdown_selector.dart`, `DropdownMenu`
with `enableFilter` and `enableSearch` both tied to `isSearchable`). One filters
and the one beside it does not. With the list unfiltered, `key return` takes the
first entry — `4001` — which is the whole reported failure.

Three more things fell out of it, all of which contradict notes that were being
relied on:

- `key return` dismisses the keyboard, commits nothing, and leaves the list
  open. It does not "commit the filtered match".
- Tapping the row commits reliably, every time.
- Rows past the menu's viewport report `0,0 0x0` and **stay** that way after the
  keyboard is dismissed, so they need scrolling. The keyboard was never what
  was hiding them.
- A dropdown left open survives at least four further `driver.sh` invocations,
  two of them `tree` reads. The note saying an invocation boundary closes it did
  not reproduce.

**So the remaining half is the app's.** Nothing this toolkit does can make a
list filter. What it can stop doing is reporting success, and that is what
shipped:

- `type` now reads back what landed (`bin/typed.py`) and fails if the text is
  not on screen, with one exemption — a secure field never shows its contents,
  so a PIN step is not failed on evidence that cannot exist. `TYPE_VERIFY=0`
  turns it off.
- **It would not have caught this failure**, and the docs say so rather than
  implying a guarantee: `LOC1` *was* in the field. What catches it is an `expect`
  on the committed value, which `reference/journeys.md` now tells authors to put
  after any step that commits.
- `reference/apps/example-app.md` taught filter-then-return as a verified
  working method and said "tapping the list item never works" — the exact
  opposite of what is true, shipped inside this skill as an example for other
  projects to copy. Corrected in place, with the wrong note left visible above
  the correction, because that is the shape item 16 is about.

One correction to this item's own framing: it said `SKILL.md` teaches
filter-then-return. It never did. The skill's *example app notes* did, which is
worse in one way — those are what a new project copies from.

**Reproduced 19 Aug 2026 by session F in `brandco-flutter-runner`, and the open
question in this item now has an answer.** It ended "One filters and the one
beside it does not", with no cause. The cause is one argument:

| dropdown | `isSearchable` | filters? |
| --- | --- | --- |
| Select Store | `true` — `lib/screens/pin_entry_page.dart:66` | yes |
| Select User | `true` — `lib/screens/user/user_dropdown_widget.dart:52` | yes |
| Select Device Location | default `false` — `lib/utils/dropdown_button.dart:62` | **no** |
| Select Language | default `false` — same default | **no** |

`DropdownSelector` ties `requestFocusOnTap`, `enableSearch`, `enableFilter` and
the whole `filterCallback` to that one flag
(`lib/utils/dropdown_selector.dart:86-112`). So the two fields on the same
screen are not the same control, and no amount of typing will ever filter the
second pair. Every symptom in this item follows: typing into a non-searchable
field appends to whatever it holds (`4001` + `LOC1` = `4001LOC1`), `key return`
neither commits nor closes, and the next tap anywhere else — the tap on Select
Language, in the journey that reported this — closes the list and commits the
first row.

Three of the 13 Aug findings held again on a different build six days later:
`key return` commits nothing and leaves the list open; tapping the row commits
reliably; a dropdown left open survives further invocations — six of them this
time, including two tree reads, a `find` and two swipes, and it had also
survived open between sessions.

**The app half is now done.** `maestro/journeys/01-device-setup.journey` in
`brandco-flutter-runner` taps the rows for Location and Language, types only
into User, and does User last; verified end to end from a logged-out app with
the values read back off the SETTINGS tab, because the failure it replaces was a
silent wrong value rather than an error.

**One thing this item's fix did not reach.** It records correcting
`reference/apps/example-app.md`, which "taught filter-then-return as a verified
working method and said 'tapping the list item never works'". The project that
copied from it carried the same two sentences in its own `app-notes.md`,
complete with a "Verified on Select Device Location -> 'Stockroom 1'" that
cannot have been what it looked like — Stockroom 1 is the fifth of seven rows,
so the tap that committed it was almost certainly committing something else.
The skill was fixed on 13 Aug; the project copy was not, and stayed wrong until
19 Aug. Worth noting for item 16: correcting a note in the skill does not
correct the copies already taken from it, and nothing looks for them.

**And a new blocker for the method this item lands on.** Tapping the row is the
advice now, and on this app's Store Device screen `resolve.py` refuses that tap.
Tapping the Location field puts a keyboard node in the tree while the keyboard
stays parked off-screen at `0,946` on an 874-point screen; `keyboard_geometry`
takes the thickness rather than the position, computes a top edge of 569, and
refuses the third row at 571.5 — by 2.5 points — along with the mode buttons at
574 and SUBMIT at 798. All of them tap correctly when sent as a raw
`driver.sh tap`. The workaround shipped in the project's journey is an opening
swipe that scrolls the page so the menu opens above 569.

**Reproduced earlier than session F — session `90833915`, 14 Aug 2026, in
`brandco-flutter-runner`**, five days before the F reproduction above and on the
same Select Device Location field. It cost real time twice (roughly 15:13–15:23,
and again while creating requests): the field took `4001e`, then `4001`, then
stray characters on each retry. Two things to add to the record:

- **A new cause: the predictive-text / QuickType suggestion bar was intercepting
  the taps** — *"Predictive text is stealing the taps"* — which is distinct from
  the keyboard occlusion this item covers, and is raised on its own as **53**.
- **Best practice was dropped under the hurdle.** Rather than commit the intended
  value, the session gave up on it — *"The location itself doesn't matter for
  creating requests, and the first row selects reliably — using that"* — and took
  whatever the first row was. That is exactly the silent-wrong-value failure this
  item's app-side fix (tap the row) exists to prevent, reached by abandoning the
  target value instead. It also re-confirmed the 13 Aug finding that a typed-and-
  `return` value is display-only with no backing selection: `SUBMIT` stayed
  disabled until the row itself was tapped.

**The project's own journeys did not run clean, which is why so much was
hand-walked.** In the raw log, `00-login`, `01-device-setup` and `01-search` all
reported `journey: FAILED`, with `resolve: no visible node matches /^English$/`
and `/^Select User$/` on the searchable/overlay dropdowns — the option renders in
an overlay the journey's `tapon` did not match in time. So the login and setup a
journey is meant to make one call were driven step by step by hand, repeatedly,
across the session. This is the existing-flows-failed-so-hand-walk pattern
(item 49) reached not by choice but because the journeys break on exactly the
dropdown behaviour this item is about.

**Characterised definitively on the physical XS Max — session `480adcc1`,
21 Aug — and it cost the entire session.** The first-run Device Information
dropdowns do **not** filter, and typing selects nothing: the text field and the
list are independent controls. Proven both ways — synthesised `inputText` and
taps on the real on-screen key rectangles each updated the field character by
character and neither filtered the eight-row list. So a correct-looking field is
not evidence of a selection, `SUBMIT` needs both User and Location set by a *row
tap*, and `tapon "<row text>"` matches the text field rather than the row (both
carry the same label). The 14 Aug app note claiming `LOC1` + `return` "selects
4001" was struck through as wrong: there is no filter and `return` commits
nothing. Cost: the login never completed, so **none of the seven outstanding
hardware tests the session existed to run were reached** in three hours — this
dropdown blocked the whole verification. The user had to force the diagnosis
three times (*"Have you actually selected an element in the dropdown, or just
typed some text in and assumed it works?"*) because the session kept treating a
filled field as a set value — the exact failure this item's type-verify half
exists to catch, and a best-practice drop under the hurdle. With `tapon` hitting
the textfield not the row, the session fell back to raw `tap x y` by resolved
coordinate (13 times) — the coordinate-stabbing this toolkit's resolver is meant
to remove, forced back by the row-vs-field ambiguity.

**Ship as a `SKILL.md` rule (9 Sep).** The conduct half of the sessions above is
not app-specific and must travel with the skill: *a filled field is not a set
value.* After any step that commits a choice, assert the committed value — an
`expect`, or a read-back — before proceeding, and never treat text appearing in a
field as proof a selection was made. This belongs in "The rules that matter
most", alongside the bounds and selector rules, so every project inherits it
rather than rediscovering it. (It is skill-usage conduct, deliberately not sent
to the per-machine retrospective, which does not travel with the skill.)

**Proposed `SKILL.md` wording (9 Sep) — extend rule 6, "Assert inside the batch":**
> …and *a filled field is not a set value.* A control showing the right string may
> have committed nothing; assert the committed value — an `expect` on what the form
> now reads, or a read-back — never the text visible in the field.

The searchable-vs-non-searchable dropdown specifics (typing filters, `key return`
commits nothing, only a row tap commits) are this app's behaviour and stay in the
project's app-notes, not in the global rule — see the 9 Sep spot-check.

**The reliable method, found on hardware — session `0598a4b6`, 21 Aug.** Two
things finally made this screen drivable, and both belong in the app-side notes
and in any corrected journey:
- **Tap the trailing arrow, not the field.** Tapping the field focuses its search
  box, raises the keyboard, and pushes the rows below the ~560 line where a tap
  lands on the predictive bar (item 53). The arrow is +114 points from the field
  centre and opens the same list with no keyboard — the single fix for most of
  the mis-taps this item catalogues.
- **Set the role last.** Changing the user clears `selectedRole`, and `SUBMIT`
  needs all four fields, so a complete-looking form with a greyed SUBMIT is
  usually a dropped role.
The cost of not having this: **104 raw `tap x y` calls against 5 `tapon`** in that
session — with `tapon` hitting the textfield not the row, the resolver was
bypassed and the screen driven by raw coordinate almost throughout, the exact
stabbing this toolkit exists to prevent. Also surfaced: `driver.sh text` drops a
character into the PIN field (a `securefld`, invisible to a `textfield` grep, so
it reads as a vanished field) — tap the keypad digits for a PIN instead.

**Still recurring on 24 Aug — session `cf5c6f39`.** A PR #103 re-verification
recorded that `01-device-setup.journey`'s filter-then-return "picked location
`4001` instead of `LOC1` again" — the same wrong-entry selection this item's
app-half is about, still shipped in the committed journey. Confirms the journey
was not corrected to tap-the-arrow after this item was raised, and ties to item 49
(the broken journey re-derived rather than replayed).

**A second failure mode of the same dropdown — session `07f380e8`, 1 Sep.** The
store dropdown is **lazy-rendered**: it shows only about seven rows until you type
to filter, so a row below the fold is not in the accessibility tree at all.
Selecting one (US store 4003, well down the list) fails with `no visible node
matches` — which reads as a missing element, when the element merely is not
rendered yet. So the dropdown breaks selection two ways: the wrong entry when you
filter-then-return (this item's app-half), and *nothing* when you tap a row that
was never rendered. The session's fix is the right general rule and is worth
folding into the guidance: **filter the long/lazy dropdown first, then select the
filtered row** — which is exactly what its new `00-login-filtered.journey` does.
The misleading `no visible node matches` message is also a candidate for the same
error-clarity treatment as items 9/46: say "no rendered node matches — the list
may be scrolled or lazy; filter or scroll" rather than implying absence.

## 15. Using the MCP tools destroys a `drivers.sh` layout — **DONE 13 Aug**

`hier.sh`, `flow.sh` and `shot.sh` all warn that running them starts a driver on
port 22087 and replaces whatever was there, and the MCP server is hard-bound to
that port. Nothing enforces it. Hit on 12 Aug: one `mcp__maestro-mac__run` call
against the iPad silently killed the driver `drivers.sh` had put on 22087, and
the next four `driver.sh tap` calls failed with `no driver for <udid>` — which
reads like a dead relay, not like something the previous call did.

It cost about ten minutes, most of it spent suspecting the app rather than the
tooling, because the failure appears one call later than the cause.

Neither C nor D used the MCP server at all, so this is latent rather than
frequent — but it is the kind that wastes a whole debugging session when it
does land.

**Re-measured 13 Aug, with three drivers up.** iPad on 22087, iPhone 16 Pro on
22088, iPhone 16 on 22089. `maestro --device <iPhone 16 Pro> hierarchy` left the
iPhone 16 Pro with **no driver at all**; the iPad kept 22087 and the iPhone 16
kept 22089. The run after it, which succeeded, did the same thing. So:

- it destroys **the named device's** driver, not whoever holds 22087;
- it happens when the command finishes, whether the command worked or not;
- every other device is untouched.

`reference/driver-api.md` and `SKILL.md` already had this right from 12 Aug. The
headers of `hier.sh`, `flow.sh` and `shot.sh` did not — "starts a driver on
22087 for that device, replacing whatever was there" reads as the port changing
hands — and this item's own wording carried the same implication. All four are
corrected.

**Done.** `drivers.sh up` now records what it started in `$LDIR/drivers.owned`
(`<udid> <port> <epoch>`), `down` and `down-all` clear it, and `driver.sh` uses
it to tell the two cases apart:

```
no driver for BA42FF52-....
  bin/drivers.sh up started one on port 22088 at 15:51, and it is gone.
  Running Maestro against a device destroys that device's driver when it
  finishes — the MCP server, bin/hier.sh, bin/flow.sh, bin/shot.sh.
  No other device is affected: the other 2 still have theirs.
  bring one up:  bin/drivers.sh up BA42FF52-...
```

A device nobody started gets the old plain message, because there is nothing to
explain and inventing a cause would be worse. `drivers.sh list` shows the same
state as `was 22088 / GONE`.

The registry is deliberately **not** a port map — the live scan stays the source
of truth for which driver is on which port, and is discoverable from the Mac's
own processes. This file only answers "did we put one there", which the scan
cannot.

Verified live: reproduced the failure on the real Mac, watched the note appear,
then brought the driver back with `drivers.sh up` and watched it clear. Twelve
test cases offline; 114 became 126.

## 16. Nothing re-checks a note once it is written — **DONE 13 Aug, one half deliberately left**

The app notes are the difference between driving an app and rediscovering it,
and the discipline is good. But a note recorded once is then trusted for good,
and three have now turned out to be wrong:

- `04-switch-user.journey` said the Settings user dropdown does not raise the
  keyboard. **Session C** found it does, and that it opens scrolled into the
  middle of the list.
- "The iPad nav rail is INVISIBLE to the accessibility hierarchy… there is no
  selector for any tab on iPad" was written up as the iPad being unusable.
  Correct about the frames, wrong about the conclusion — corrected 12 Aug.
- "Portrait simulator, landscape-locked app" as the cause of the coordinate
  mismatch. It is not the simulator's orientation, and the note sent the next
  reader off to rotate things. Corrected 12 Aug.

All three were written confidently from a single observation. The template asks
for the measurement next to the claim, which is what made them checkable — the
gap is that nothing distinguishes "seen once" from "relied on for a week".

**Fix.** A confidence marker in the template — measured once, measured twice,
inferred — and a line in `SKILL.md` that a note contradicting what is on screen
is corrected in place, not worked around.

**Fixed 13 Aug**, and the count is five, not three: two more turned up that day
in `reference/apps/example-app.md`, which is worse than the three above because
that file ships inside the skill as the example a new project copies from. It
taught filter-then-return as a verified working method and stated that tapping
a row never works — both the opposite of what item 14 then measured.

- `bin/notes.sh add` takes `--measured`, `--once` or `--inferred` and **refuses
  to write without one**. No default: a default would make every note claim the
  same confidence, which is the state being fixed. The refusal names the three
  and says why.
- Notes are stamped `- (2026-08-13, measured) ...`. A note with no marker
  predates the convention and reads as `seen once`, which puts all five of the
  wrong ones in the weakest class automatically.
- The template says what each level means, that `seen once` forbids relying on
  it without looking again, and that confirming one promotes it to `measured`
  with a second date.
- Correcting is now specified rather than implied: mark the original **wrong**,
  write the correction as its own note with the measurement, and leave the
  wrong version visible — the next reader has probably already acted on it. The
  example file now demonstrates exactly that shape.
- `SKILL.md`: a note that contradicts what is on screen is corrected in place,
  then, before carrying on.

**Left out on purpose.** The five wrong notes are two different failures. Three
were written from a single sighting and contradicted later — that is what the
marker addresses. Two were contradicted by *another note in the same file on the
same day*, and nobody cross-read them: "verified on Stockroom 1" sat a few lines
from "typing leaves the list unfiltered". Nothing here catches that. It wants
something that reads a notes file and reports pairs that disagree, which is a
different and much less certain thing to build — raised as its own item rather
than bolted on, because a checker that cries wolf would get switched off and
take the marker with it.

**Recurrence, session `480adcc1` (21 Aug).** A note recording a *wrong* value —
"location 4001" (4001 is a store, not a within-store location) — was read and
propagated straight into a device-setup run, and that wrong value is part of why
`SUBMIT` stayed greyed and the login dead-ended. The note carried no confidence
marker, so it sat in the weakest class as intended, but nothing stopped it being
trusted and acted on. The lesson: the marker records *doubt* without preventing
propagation, and a value that is simply wrong (not merely low-confidence) has to
be caught by the read-back the note drives, not by the marker on the note.

**Ship as a `reference/` rule (9 Sep).** The carry-everywhere lesson: *a value
taken from a note that does not fit the field it is being used for is suspect* — a
store id where a within-store location belongs, a free-text string where a
selection is required — and must be sanity-checked before it is driven, not
propagated because a note recorded it. This belongs in the notes/driving
reference so it reaches every project, not a repo retrospective.

**A different way notes go wrong — session `3936b43e`, 4 Sep.** Several 3 Sep
notes stated PROJ-1799 "does NOT reproduce" in store 4001. They were right about
what they saw and wrong about what it meant: they read a **debug simulator**
build, and the bug only paints on a **profile or release** build on hardware. A
measurement taken on the wrong build mode is a confident false negative. Worth a
template line: a note about whether a bug reproduces must record the build mode
and device it was seen on, since that is what decides whether the observation
transfers. Relates to item 6 (is the installed app the code under test) and item
45 (profile-not-debug on device).

**A note's own caveat can expire — session `46c62657`, 4 Sep.** `COVERAGE.md`
hedged that the QA script "was written against 2.0.1, a later app than the 1.0.0
build it ran on, so some blocked items may simply not be built yet". `development`
is now 2.0.1 — the app caught up with the script, so the hedge is void and the
whole blocked list is unanswerable in its own terms, yet the caveat still reads as
live. A confidence marker records doubt at the time of writing; it does not notice
when the thing it was hedging against has since happened. And a companion
principle from the same audit, worth a template line: **stale evidence attached to
a live finding is not dead data** — deleting the request id or the stock number
deletes the finding with it and the next session re-runs the whole investigation
(the `type:""`, UAT-400 and PROJ-1799 notes each nearly lost this way). Compress
to one note led by why it exists; do not delete.

## 17. The package has no version, manifest, installer or git — **DONE 17 Sep 2026**

Kept here in number order as a pointer only. A copy of this item sat in both
files for weeks, still marked `OPEN` in this one; the body and the fix are at the
end of this file, with the rest of 17 September's work.

## 18. `MAC_HOST` is one alias, so the Mac moving looks like the Mac being broken — **DONE 13 Aug**

**13 Aug.** The Mac came into the office for the first time. Every call failed
with `Connection timed out during banner exchange` and `lost connection`, which
reads as the machine being asleep or off the network — I reported it as exactly
that and stopped. The Mac was fine. `~/.ssh/config` has both `mac-b`
(192.168.1.10) and `mac-a` (10.0.0.10); `.maestro-mac.conf` pins
`MAC_HOST=mac-b`, and `export MAC_HOST=mac-a` made everything work
immediately.

`config.sh:46` takes one value, `lib.sh:35` hands it to every `ssh`. Nothing
tries an alternative and nothing says the alias might be the problem. Note the
conf already comments that `MAC_FQDN` follows the Mac between networks because
the proxy resolves it — so the HTTP half survives a move and only SSH does not,
which makes the failure look even less like a routing problem.

**Fixed 13 Aug.** `MAC_HOST` now takes a space-separated list;
`_pick_host` in `bin/lib.sh` uses the first alias that answers and caches it in
`$LDIR/mac-host`. A single value is never probed, so the cost is unchanged for
anyone not using it — measured 0.3s for one alias, 9s the first time a list has
to step over a dead one, 0.4s warm. When none answer, the error names every
alias tried and lists the others in `~/.ssh/config`.

Two things the tests caught that the design did not:

- `_pick_host` narrows `MAC_HOST` to the winner, so checking "is there more than
  one candidate?" afterwards always said no and the mid-session re-pick never
  fired. The list is now captured at source time — capturing it lazily inside
  the function does not work either, because every caller reads it through
  `$( )`, which is a subshell.
- ssh takes the **first** value it sees for a keyword, so appending
  `-o ConnectTimeout=8` after `SSH_OPTS` (which already sets 15) did nothing.
  The probe cost 15s until the order was swapped.

Left deliberately: nothing edits any project's `.maestro-mac.conf`. A single
value keeps working, and a list is opt-in.

**A footgun this created, seen in session `90833915` (14 Aug) — follow-up still
OPEN.** The conf now ships `MAC_HOST:=mac-a mac-b` by default (item 48
confirms it), so `MAC_HOST` resolves to a *space-separated list* — and anything
that interpolates it directly as a single host breaks. A branch push to the Mac,
`git push "$MAC_HOST:$REPO" …`, became `git push "mac-a mac-b:…"` and
failed with `hostname contains invalid characters / Could not read from remote
repository`. `_pick_host` fixes this for callers that go through it, but a caller
reaching for `$MAC_HOST` raw — as a git remote, an `scp` target, anywhere a
single host is expected — gets the whole list. The list format needs a companion
accessor that returns the *picked* single host (or `_pick_host` exported as one),
and the conf/docs should warn that `$MAC_HOST` is not itself usable as a
hostname. The build/sync path is where it bites, since it reaches the Mac by name.

## 19. Two notes in one file can contradict each other unnoticed — **DONE 11 Sep**

Split out of item 16, whose confidence marker does not address it. Two notes
written on the same day, a few lines apart in the same file, said opposite
things about the same field:

> "working method: tap the field, `text "<exact value>"` to filter, then
> `key return`. Return commits the filtered match... **Verified on Select Device
> Location → 'Stockroom 1'**"

> "typing leaves the list unfiltered and `key return` selects whatever row is
> first... asked for `LOC1`, got `4001`"

Both were relied on. The evidence needed to spot the clash was already in the
file; nothing read it. Item 14 then spent a session's worth of work
re-establishing which was true.

**Fix, roughly.** Something that reads a notes file and reports pairs that
appear to disagree — same screen or same control, opposite verbs. Hard to do
without crying wolf, and a checker that cries wolf gets switched off, so it
needs to be quiet by default and only speak when two notes name the same
subject and one says a method works while the other says it does not.

**Do not start this before 16 has been used for a while.** If the confidence
marker changes how notes get written, the shape of this problem changes with
it.

**The earliest and largest instance — session `91879ddf`, 19 Aug.** The maintainer asked
for a full audit of the project's maestro docs — *"make sure all make sense and
there are no conflicts"* — and it found **eighteen** contradictions in
`app-notes.md` alone, several written the same day a few lines apart with neither
marked as correcting the other: the Settings dropdown raising the keyboard (`:231`
vs `:237`), the tab-selector anchor rule (`:133` vs `:236`), the iPad `tapon`
verdict (`:215` "corrects the 11 Aug note" while the 11 Aug note at `:267` still
stood uncorrected), the user-dropdown scroll with three different swipe fixes
(`:237`/`:238`/`:248`), and two iPad rail tables in different coordinate spaces
that never cross-referenced. The session settled them — four against the device,
the rest by reasoning — and edited the notes in place. Two things this proves for
the item. First, the scale: a file accrues this many silent clashes between audits,
so the confidence marker (item 16) plainly did not stop it. Second, and sharper:
this session **settled the iPad transform contradiction on 19 Aug**, yet
`46c62657` found the very same iPad transform carrying three incompatible measured
answers again on 4 Sep. A one-off human settle does not hold — the notes drift back
into contradiction — which is the case for a standing checker rather than another
audit.

**A concrete instance — session `46c62657`, 4 Sep.** The maestro-docs audit found
**three incompatible answers to the iPad coordinate transform, all marked
`measured`**, written 12, 19 and 21 Aug — app controls need the transform / need
none / need it after all — each relied on in turn. The audit could only tag them
`CONTESTED` and open an `### iPad: UNRESOLVED` block naming what would settle it,
which is exactly what this item predicts: nothing had read the three together, and
the contradiction sat in the file until a human audit went looking. A checker that
flagged "same subject, opposite measured claims" would have caught it the day the
second one was written.

**What the contradiction actually costs — session `e5bdd72b`, 21 Aug.** This is
the missing "so what": with two 12 Aug notes in the file — one carrying the iPad
transform, one saying app controls need none — a UI-fix verification hit a
`tapon` miss on the iPad and, distrusting the notes, fell back to **three blind
`tap`s** before recovering with `find --explain`. In the session's own words:
*"the 12 August note that said app controls need no transform … is what made me
treat blind taps as reasonable."* Five minutes lost re-deriving a measurement
already on file, and the user's reaction was *"5 minutes for taps?! … Have you
ignored all past instructions about how to find elements? AGAIN?"* So the two
contradictory notes did not merely sit unnoticed — one of them actively licensed
the coordinate-stabbing this toolkit most wants to stop (items 56, 57). The cost
of an unresolved contradiction is not confusion, it is the wrong method chosen
with confidence.

**Considered and deferred 11 Sep (backlog run).** Its gate (item 16 in use a
while) is satisfied, but the real `app-notes.md` is not currently accessible —
not in the brandco `maestro/` dir, presumably on a branch (item 25) — so a
checker cannot be calibrated against the 18 known contradictions, and precision
is the whole game: a cry-wolf checker gets switched off. Deferred rather than
built blind. To resume: point a session at the branch holding the notes, then
build the conservative structured checker (a `check` mode on `bin/notes.sh` that,
within one heading, flags two non-superseded notes whose subject matches where one
affirms a method and the other negates it), calibrated against that file.

## 20. A branch switch deletes the project's journeys and app notes — **STRUCK 13 Aug**

Raised and struck the same day. A feature branch not having files that were
committed to `development` after it was cut is ordinary git, and a merge brings
them back. Nothing was lost, and it does not need tooling.

What remains true and is recorded here only so it is not re-raised: session E
(`2712fef3`) drove the app with `maestro/` empty, which is part of why it made
61 `driver.sh` calls and re-derived the login by hand. `git show
1fb99db:maestro/app-notes.md` reads any of it without touching the branch.

## 21. Nothing dismisses the keyboard — **DONE 13 Aug, evening. Built and tested in `src/`, not published**

**Session E.** The keyboard guard refused a tap **eleven times** between 14:02
and 14:20, on `Sample User`, `RUNNER`, `Select Language`, `SUBMIT`, `Stockroom 1`
and others. Every refusal was correct. The problem is what to do next, because
there is no verb for it: `grep -n "hideKeyboard\|dismiss" bin/driver.sh` matches
nothing, and `keyboard` only reports whether it is up.

What the session tried, in order: `key return` (14:03 — keyboard still up on the
next read, and the refusal fired again), a raw `tap` on a label (14:04, refused
too — it was also under the keyboard), a `swipe`, five screenshots, then finally
a raw `tap 201 798` at a blank point (14:07), which worked.

**This contradicts item 14's note**, taken on 13 Aug, that `key return`
dismisses the keyboard. It did on the dropdown screen it was measured on and did
not here, so the note is right about one screen and was written as though it
were general — which is exactly what item 16's confidence markers exist for.

**Fix.** Find out whether the driver has a route for it. Three of eighteen are
still unexercised (`installedApps`, `setPermissions`, `swipeV`) and Maestro's
own flow language has `hideKeyboard`, so the client jar is worth reading the way
the other routes were. Failing that, a `dismiss` verb that taps a point known to
be outside every field — derivable from the tree, since the app's own bounds are
known — beats every caller inventing one. Then say in `SKILL.md` which it is,
because "tap somewhere blank" is not a discoverable answer.

**Done, and both halves of that fix turned out wrong.** The client jar was read
again rather than inferred: eighteen routes, none of which hides the keyboard,
and Maestro's own `hideKeyboard` is client-side Kotlin, not a driver call. And
the blank tap alone does not work — measured, it never works on this app —
while `key return` always does here but submits the focused field, which can
commit the wrong dropdown row in silence. So `driver.sh dismiss` tries the
harmless one first, falls back to `key return`, and **says which worked**,
because the two are not interchangeable. It reads the keyboard back afterwards
rather than assuming, and on a screen the app fills edge to edge with tappable
rows it says there is no blank point rather than tapping something anyway.

**Not published.** `./ship.sh` lists nine files — `bin/driver.sh`,
`bin/resolve.py`, `test/run-tests.sh`, `SKILL.md` and five under `reference/` —
and 170 tests pass from `src/`. Publishing is the maintainer's to ask for, in the message
that asks for it.

## 22. Fetching from Bitbucket on the Mac looks like a missing key and is not — **DONE 11 Sep**

**Session B** (11 Aug 20:52) worked around it with `git bundle` over `scp`.
**Session E** (13 Aug 13:53–13:55) hit it again and solved it properly, in four
calls and about eighty seconds.

A plain `git fetch` on the Mac fails with `git@bitbucket.org: Permission denied
(publickey)`, which reads as "this Mac has no Bitbucket access". It has. The key
is `~/.ssh/bitbucket`, there is **no `Host bitbucket.org` block** in the Mac's
`~/.ssh/config`, and a non-interactive ssh session has no agent — `ssh-add -l`
answers `Could not open a connection to your authentication agent`. So nothing
offers the key. Naming it directly works first time:

```sh
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/bitbucket -o IdentitiesOnly=yes \
                            -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
git fetch origin <branch>
```

`ssh -T git@bitbucket.org` with the same options answers `authenticated via ssh
key`.

**Checked again 13 Aug, 17:20, before writing anything.** Three of the four
premises hold and one has changed:

- `~/.ssh/bitbucket` exists, and there is still **no `Host bitbucket.org`
  block** — the only two blocks are `webhost-prod` and `webhost-uat`.
- A non-interactive session still has no agent (`ssh-add -l` answers `Could not
  open a connection`), and `ssh -T git@bitbucket.org` still fails: `-v` shows it
  offering only the default `id_rsa`/`id_ecdsa`/`id_ed25519` names, none of
  which exist on the Mac.
- **But `git fetch` in the brandco checkout now works.** Session E set
  `core.sshCommand = ssh -i /Users/dev/.ssh/bitbucket -o IdentitiesOnly=yes`
  on that repo at 13:55 on 13 Aug, as local git config, and it persisted. So the
  symptom is fixed for that one checkout and for nothing else — a second clone,
  or any other repo on the Mac, still fails exactly as described.

That makes the doc a little different from what was planned: say the symptom is
per-repository, name the local config that is already set on the brandco
checkout so nobody re-diagnoses it, and keep the durable fix as the user's to
apply.

**Fix.** Two lines in `reference/setup.md` under the Mac's prerequisites, and a
row in its symptom table, since the symptom is what a session will search for.
Whether the toolkit should set `GIT_SSH_COMMAND` itself is a judgement call:
this is the *user's* Mac and its ssh config is theirs, so the honest fix may be
to say the Mac wants a `Host bitbucket.org` block with `IdentityFile
~/.ssh/bitbucket` and leave writing it to them.

**The stale instruction is still being followed — session `d32077c5`, 19 Aug.**
That review moved the branch to the Mac as a `git bundle` over `scp` because the
review-branch skill states outright "The Mac has no Bitbucket key. Move it as a
git bundle over scp." The session did not test it — its own words: *"I took that
from the skill rather than testing it this session. If the Mac has since been
given a key, `git fetch origin && git checkout` would be simpler and the skill's
instruction is stale."* This item is the evidence that it is stale: the fetch
works with the key named. So the fix has a second half beyond `reference/setup.md`
— the **review-branch skill's** "no key, use a bundle" instruction should point at
this item's `GIT_SSH_COMMAND` recipe (or be removed), so a review stops reaching
for the bundle when a fetch would do. (Review-branch is a separate skill from
maestro-remote-mac; noted here because the cost lands in a maestro-driven review.)

## 23. `secrets.sh check` never checks that the conf is protected — **DONE 11 Sep**

`bin/secrets.sh check` skips the conf by design ("that is where the values are
supposed to be") and searches only what git tracks. Both are right on their own.
Together they mean the file that holds the credential is the one file never
examined, and whether it is protected depends on a `.gitignore` line the check
never looks at.

Seen on the brandco project: `.maestro-mac.conf` is ignored on `development`
and not on a branch cut before that line was added, so `git status` lists it
while `check` reports `clean`.

**Fix.** Confirm the conf is ignored before reporting clean — `git check-ignore
-q <conf>` in the repo it sits in. If it is not, say so and give the line to
add. Small, and it stops the check answering a narrower question than the one
being asked.

## 24. Concurrent reviews of several branches — one vmservice cache for the whole Mac — **BUILT AND SHIPPED 10 Sep — VERIFIED LIVE 10 Sep**

**Built 10 Sep.** The single-tenant VM-service cache is now per device: `publish.sh`
and `net.sh` derive a device suffix (from `DEV`, else the resolved driver, else the
old shared name as a fallback), so `$LDIR/published-$DEV.state`, `$RDIR/vmservice-$DEV`
and the `net*.json` scratch no longer collide between concurrent sessions. The
single-device path is byte-for-byte unchanged (the suffix is empty → shared name).
`SKILL.md` now documents `BUILD_MARKER` as **required** for concurrent runs and the
separate-checkout/`git worktree` rule as a **safety** requirement (a `git checkout`
on the shared repo silently clobbers live work). The worktree automation and per-run
tenant separation remain design notes, not code.

**Verified live 10 Sep** against the real Mac (`mac-b`), two booted simulators each
running a throwaway `flutter create` app under `flutter run` (two Dart VM Services),
`publish.sh` with `PUBPORT=9100`/`9101`: `publish` for device A wrote
`published-<A>.state` (isolate 6996…); `publish` for B wrote `published-<B>.state`
(isolate 3822…) and **left A's file untouched** — the exact clobber the shared
`published.state` used to cause. No shared `published.state` was written; `net.sh
DEV=A`/`DEV=B` each read their own relay; the Mac held two distinct
`vmservice-<udid>` caches. Stack torn down afterwards (flutter runs, relays, sims).


Raised by a brandco-flutter-runner review session (PROJ-1786, session
`d32077c5`, 12:54) on 19 Aug, from reading the scripts rather than from a run
that tried it. The maintainer asked whether
several branches could be UI-reviewed at the same time, having noticed that the
whole review ran with no `Simulator.app` window — only `xcrun simctl boot`, with
screenshots coming off the driver's own HTTP API reading the framebuffer — and
that the branch reached the Mac as a `git bundle` over `scp` rather than a fetch.

The bundle is incidental; one repo holds many refs. The enabler is item 1's fix:
`drivers.sh` allocates a port per booted device from `DRIVER_PORT_BASE`
(`config.sh:121`, first device 22087 so the MCP server keeps working) and
`driver.sh` finds the port from live processes, so several devices are already
drivable at once with no bookkeeping. Exercised on 19 Aug — iPhone 16 Pro
`BA42FF52` and iPad Pro 11-inch `F0EDF404`, drivers on 22087 and 22088, no
`Simulator.app` process running. The Mac has 65 device types across 5 iOS
runtimes.

**Three blockers, in the order they bite.**

**One checkout.** The Mac's repo holds one branch. Fetch every bundle into that
one repo, then `git worktree add ../<branch>-review <branch>` per branch —
separate working tree, separate `build/`. The `phase-worktrees` skill already
does that shape locally.

**The VM service cache is single-tenant.** This is the one that needs a change
in these scripts. `PUBPORT` is overridable (`publish.sh:21`), so two relays can
coexist, but the remote cache both `publish.sh:76` and `net.sh:64` read is
hardcoded to `'$RDIR/vmservice'`, and the local state is `$LDIR/published.state`
(`publish.sh:22`, `net.sh:23`), which with `LDIR` defaulting to `$TMPDIR`
(`config.sh:91`) resolves under `/tmp/claude-1000` — shared across sessions, not
per-session. Two concurrent `flutter run` sessions overwrite each other's base
URI and isolate id. Driving is unaffected; only network reading breaks. Hit for
real on 19 Aug: `publish.sh` could not find the VM service and printed a base URI
of `http://:9100/…` with an empty host, worked around by seeding
`/tmp/maestro-mac/vmservice` by hand.

**Fix.** Name both files per device — `$RDIR/vmservice-$DEV` and
`$LDIR/published-$DEV.state`.

**Same bundle id.** Every flavour-dev build is
`acme.e.brandco.runner.dev`, so nothing on the device says which branch it
is, and `preflight.sh`'s "is that the code under test?" check compares against
*the* checkout's newest commit — ambiguous once there are several worktrees.
`BUILD_MARKER` in the project conf (`config.sh:75`, `preflight.sh:30`,
`SKILL.md:161`) is the existing answer; document it as **required** for
concurrent runs, not optional.

**Two more that bite in practice**, both already known to the skill, but worth
restating as concurrency hazards:

- Any session touching the `maestro` CLI or the MCP server destroys that
  device's driver (item 15). Harmless alone; a cross-session failure when
  several sessions share a Mac. `driver.sh` only.
- The app's dev backend is shared, so requests raised by one review appear in
  another's task list. For brandco, stores 4001 / 4002 / 40021 all exist — one
  per branch keeps them apart. Generally: concurrent reviews need a per-run
  tenant in the app's own data.

**Ceiling**, measured on this Mac on 19 Aug: 8 cores, 16 GB. A booted simulator
plus its driver plus a `flutter run` is roughly 2 GB — an estimate, not a
measurement; resident memory of the two simulators booted that day was never
read. On that estimate three concurrent reviews look realistic and four
optimistic. Xcode builds are the CPU spike, so serialise the builds and
parallelise the driving.

**Confirmed from a real run, and the "one checkout" blocker is sharper than
stated — session `d62fd2c0`, 25 Aug.** Asked to review PRs #106/#107 without
disturbing in-progress 1788 work, this session actually did the concurrent setup
this item only reasoned about: it started a **second checkout**
(`brandco-flutter-runner-review` on `pr417`), booted a **fifth simulator**
(`review-iPhone16Pro`) alongside the four already running their drivers, built and
drove it, and left the other four and the 1788 checkout untouched. So the "boot
another, install per-device" half is now verified live, not inferred — "simulators
are not where it falls down."

Where it falls down is the checkout, and the danger is worse than "holds one
branch": **`flutter-hot-reload-mac/bin/start.sh` runs `git checkout <branch>` on
the single shared `$REPO`**, so pointing it at a review branch would move HEAD off
in-progress work that had two uncommitted, non-lock `.dart` files — a silent clobber
of unsaved work, not just a limitation. `maestro-remote-mac/bin/build.sh` doesn't
switch branches but builds whatever is checked out, so it can only build the one
branch. This makes the item's `git worktree` / second-checkout fix a **safety**
requirement, not just an enabler: any concurrent run must use its own working tree
so nothing `git checkout`s the shared repo out from under live work. (The
`start.sh` checkout-on-shared-repo behaviour is also a flutter-hot-reload-mac
concern; noted there is its own backlog, but the clobber risk is what makes this
item's separate-checkout rule non-optional.)

**Now routine — session `a142c63c`, 3 Sep.** A second real concurrent review
(PR #116, SUP-22), asked outright to run *"without affecting the local checkout or
any testing happening on the mac"*, did exactly the safe shape this item prescribes:
a separate worktree/checkout and its own simulator, torn down or noted at the end.
So the pattern is now being used deliberately, not just proven once — which is the
signal to promote it from "possible" to a documented supported workflow with the
worktree rule and the `start.sh`/build-marker safeguards written down.

**But the safe way is still not the default — session `22d4c486`, 4 Sep.** Told to
review a branch while other simulators were driving, this session defaulted to
**switching the shared checkout's branch** rather than a separate checkout, and the
user had to prompt the safe approach: *"Is that not going to affect the other
running simulators? You've previously told me you can send bundles over ssh."* Then,
before switching, it proposed a `git stash` of two lock files (`ios/Podfile.lock`,
`pubspec.lock`) that are already-declared safe to discard: *"lock files are an
already-declared safe thing to discard. Fuck your stash."* Two things for the fix:
(1) the documented workflow must make the separate checkout / bundle the default a
session reaches for, not the shared-branch switch it falls back to; and (2) it
should state plainly that switching the Mac's checkout may discard regenerable lock
files (`Podfile.lock`, `pubspec.lock`) directly — no stash — since a stash step for
known-discardable files is pure friction. This is the checkout half of the item seen
going wrong by default, the counterpart to `d62fd2c0`/`a142c63c` getting it right
when the task named the constraint.

**The MCP-port hazard, hit hard in real concurrent use — session `065a39b2`,
4 Sep** (the one review-session that drove via the maestro-mac MCP: `inspect_screen`
×5, `run`, `take_screenshot`). This is the "any session touching the MCP server"
hazard above, demonstrated at full cost. With other simulators under test, an
`inspect_screen` against the HBS22-review sim failed "Device became unreachable"
twice while `list_devices` still showed it connected; the cause was a leftover
`simulator-server` process holding **port 22087** pointed at a stuck earlier
`inspect_screen` session — the MCP hardcodes 22087 for whichever device it last
talked to, Mac-wide. Clearing it meant killing processes (each `kill` separately
gated by auto-mode), and a new process kept **auto-respawning on 22087**. The
session escaped only by setting `DRIVER_PORT_BASE` above 22087 to sidestep the MCP
port for its own driver — item 1's override doing exactly the job it was built for.

**A second shared port beyond the vmservice cache — the relay's LAN port defaults
to 9101.** Same session: *"the relay port (LAN-facing, 9101 by default) collides
across sessions the same way the driver port did — my custom `DRIVER_PORT_BASE`
avoided 22087 for the driver itself, but the relay's port defaults to 9101
regardless."* So the concurrency fix needs a third per-device port alongside the
driver port and the `$RDIR/vmservice-$DEV` cache: the relay's LAN port must be
derivable per device (a `RELAY_PORT_BASE` mirroring `DRIVER_PORT_BASE`), or two
concurrent sessions' relays collide on 9101. Net: three things must be per-device
for safe concurrency — driver port (done, item 1), vmservice cache (this item), and
now the relay LAN port. And the MCP server's fixed 22087 stays the loose cannon: the
safe posture is to keep MCP off during concurrent runs and drive through `driver.sh`
with a raised `DRIVER_PORT_BASE`, which this item should state.

# Added by the 19 Aug read of `~/claude-sandbox/HANDOFF-2026-08-STALE.md`

The parent directory keeps its own handoff, and it covers this skill as well as
the two sessions that built it. Nine things in it are not in this directory's
`HANDOFF.md`. Five needed nothing: the `MAC_FQDN`/`MAC_HOST` split is item 18
and is in `reference/connection.md`; the unconfirmed mirrored transform is
written at `bin/resolve.py:186`; the two examples behind "a first grep is not a
status check" are items 6 and 10, both done; the writable-paths and `EROFS`
note belongs to the machine's own reference file, not here; and the journey names the parent warns
about are the worked example against the fictional app, which is deliberate.
These four are what is left.

## 25. Which branch the project's `maestro/` directory is on — **DONE 19 Aug**

The two handoffs disagreed: this directory's said `development`, the parent's
said `unit/PROJ-1783-task-locking-phase-2` with `development` carrying older
notes. Settled from the local checkout, no round trip to the Mac. `1fb99db`
(12 Aug) is on `development` and on that feature branch alike — the same commit,
so neither is older — and `0235238` (19 Aug, local only) adds four more files on
`development`. **The docs are on `development`, which is what matters.**
`unit/test-engine-phase-1` carries none, which is ordinary git and is why item
20 was struck.

## 26. The iPad's navigation rail is unreachable by selector, and only the project's notes say so — **BUILT IN src/ 11 Sep, shipped 11 Sep (the no-selector shape added to reference/driving.md; real values stay in the project's notes)**

The rail carries no frames in the accessibility hierarchy, so no selector can
reach it. It taps fine by coordinate, and the numbers are measured and verified
in the project's `app-notes.md`. The device has to be in `landscapeLeft` or
`landscapeRight` for them: in `portrait` the safe-area inset moves and the top
item is missed.

This is the one device-shaped fact a session cannot derive from the hierarchy —
the hierarchy is exactly what does not have it — and it lives in a file that,
per item 25, is on one branch. An earlier note said the iPad was unusable and
was wrong; that correction is only in the parent's handoff.

**Fix.** The values are the project's and stay there. What belongs in
`reference/driving.md` is the shape of the case: a control the accessibility
tree does not report at all, tapped by coordinate, with the answer depending on
orientation — written against `reference/apps/example-app.md` so no real value
comes back into the skill.

**The same shape recurs beyond the iPad rail, on the iPhone — sessions
`d32077c5` (19 Aug) and `c0c6fbc5` (Session G, 20 Aug).** The rail is not the
only control the hierarchy cannot reach. `d32077c5` hit an unlabelled free-text
field in the "create request without product" sheet — no accessibility label, so
`tapon` cannot resolve it — and tapped it at a raw point (`200,548`, iPhone 16
Pro), which it recorded as fragile: *"that point moves once the keyboard is up or
the text size changes."* `c0c6fbc5` reconciled six unlabelled icon controls
(pencil, trash, tick, cross, two gears) that "have no text at all", carried them
in as coordinates converted from the handover's percentages, and marked them
**DERIVED, NOT MEASURED** with the silent failure named: a wrong point taps `ok`
and the state does not move. So the shape this item wants in `reference/driving.md`
is broader than the iPad rail: **any control with no label or no frame — a rail, an
icon button, an unlabelled field — can only be reached by coordinate, the coordinate
is fragile (keyboard/text-size/orientation move it), and the failure is silent
(`tap` reports ok).** A fourth fragility axis, from session `065a39b2` (4 Sep):
**device size.** A setup journey tuned on the iPhone 16 Pro was run against an
iPhone 16 Pro Max and "nothing past the opening swipe landed", forcing a fall back
to driving the dropdowns by hand — a journey built from raw coordinates is
calibrated for one screen and breaks silently on a larger one. So a coordinate in a
journey is not portable across devices; a journey that must run on several device
sizes has to resolve by selector (`tapon`) at run time or carry per-device
coordinate sets, and the guidance should say a raw-coordinate journey is
device-specific unless proven otherwise. The guidance should say to derive such points from
`driver.sh nodes` (which prints the unlabelled container `tree` hides), tag them
derived-not-measured, and re-read rather than trust a stored point. Ties to item
57 (raw `tap` is the fallback for exactly these) and item 51 (a hook that blocks a
raw `tap` must exempt or annotate the no-selector case).

**Done 11 Sep, in `src/`, shipped 11 Sep.** Added a "When there is no selector
at all" subsection to `reference/driving.md`, after the wrong-bounds section it
complements. It names the three shapes (no-frame container / unlabelled icon /
unlabelled field), the four fragility axes (keyboard, text size, orientation,
device size) each with the session that cost it, the silent-tap failure, and the
method (derive from `driver.sh nodes`, tag DERIVED-NOT-MEASURED, re-read, assert
the state moved). Real values stay in the project's notes; the section points at
`reference/apps/example-app.md` for worked numbers, so nothing app-specific
entered the skill. The item-51 hook already exempts the no-selector case (raw
`tap` once per session), so no hook change was needed.

## 28. Machine and client data left in this directory, and two files that should go — **OPEN, and deliberate, raised 19 Aug**

The 12 Aug sweep read all 573 files and found no credentials. Client and machine
data was in eight places; four were removed or redacted and four remain by
The maintainer's decision, because a handoff that will not name the Mac it talks to is
less useful:

| file | what it carries |
| --- | --- |
| `RULES-STALE-pre-skill.md` | the full set — 11 alias mentions, 2 `/Users/dev` paths, banner-marked |
| `HANDOFF.md` | 4 alias mentions and 3 ticket keys |
| `README.md` | 2 alias mentions and a `/Users/dev` path |
| `BACKLOG.md` | a project path, a ticket key and the Mac's alias |

None of it ships — `ship.sh` publishes `src/`, and none of these four is under
it — so this is only about what the directory looks like the moment it leaves
this machine. **Item 17 is that moment**, since it is the one that gives the
package git and a remote, so this is decided then and not before.

Two leftovers were flagged on 12 Aug and not acted on. The top-level `docs/`
duplicates `src/docs` — both 1.2 MB, the same mirror, differing only in that the
top-level copy has `llms.txt` and no `VERSION`, so it is the copy whose
provenance cannot be checked. And `RULES-STALE-pre-skill.md` should be deleted
when `README.md` is dealt with, since it is the pre-skill rules document and is
wrong in two places its banner does not name.

**Fix.** Nothing until 17 is taken. Then: delete the duplicate `docs/`, delete
`RULES-STALE-pre-skill.md` with `README.md`, and ask about the two that are
left rather than redacting them.

## 29. `tapon` cannot take `--anyway`, and the refusal it prints tells you to use it — **DONE 11 Sep**

**Session F**, hit while trying to act on the advice the refusal in item 30 prints.

Item 9 shipped a refusal message that ends:

```
  --anyway taps regardless. On 12 Aug that was done on the belief that the
  refusal was a false positive, and it typed a stray character into the field
  underneath
```

`tapon` cannot accept the flag. Measured 19 Aug 2026 against a live driver:

| call | result |
| --- | --- |
| `tapon --anyway "^SEARCH$"` | `resolve.py` usage error |
| `tapon "^SEARCH$" --anyway` | `resolve.py` usage error |
| `tapon "^SEARCH$" 0` | ok |

`driver.sh:450` is `_tapon "${2:?...}" "${3:-}"`, and `_resolve` (`:166`) turns
`$2` into `--index "$2"` — so `tapon` takes `<pattern> [index]` and nothing
else, and anything beginning with `--` lands in the pattern or index slot and
dies in argparse. `find` is the verb that forwards `"$@"` straight through
(`:452`), which is why `find --anyway` and `find --explain` both work.

So the advice cannot be followed by the verb that gives it. The route that does
exist is `find --anyway` for the point, then `tap x y` — two calls, and it drops
the resolver's arithmetic on the floor.

Also affected, same cause: `--index` is documented on `tapon` and works
(`tapon "^Foo$" 0`), but `tapon --index 0 "^Foo$"` does not, and neither
combines with `--tree`/`--nodes` — `tapon --nodes --index 0 "^Foo$"` sends
`--nodes` to `resolve.py`, which then reports `--index: expected one argument`
and points at nothing. The error names a flag the caller did not get wrong.

**Fix.** Have `tapon` parse its own flags and forward the resolver ones, the way
`find` already does, rather than positionally. Then either the message is true
or the message should stop naming the flag.

## 30. The keyboard guard fires when the keyboard is down — **BUILT IN src/ 11 Sep, shipped 11 Sep**

**Session F.** Cost about forty minutes and three wrong theories before the
guard itself was suspected, because a refusal that prints its own arithmetic
reads as authoritative.

`keyboard_geometry()` (`bin/resolve.py:240`) derives the keyboard's top edge as
`screen_h - thickness`, taking the keyboard's **size** and discarding its
reported position. Items 8 and 9 both record that as a fix that worked, and
item 9 concludes "Both are fixed, so the refusal can now be trusted". On the
iPhone it is not trustworthy, and the docstring records the reason as if it were
the bug:

> on the iPhone it reports `0,874 402x305`, so the top came out as 874 — the
> screen height — and the guard never fired at all

`0,874` on an 874-point screen means the keyboard is parked below the bottom
edge, i.e. **down**. Never firing was the correct answer there. Substituting the
size makes the guard fire whenever a keyboard node exists at all, up or not.

**Measured 19 Aug 2026**, `brandco-flutter-runner`, iPhone 16 Pro 402x874,
Store Device screen. Tapping the Device Location field opens the menu with the
keyboard parked at `0,946` — off-screen, nothing covered — and the guard refuses:

| element | centre | verdict | tapped by raw `tap`? |
| --- | --- | --- | --- |
| `LOC1` menu row | y=571.5 | refused, "2.5 points below" | lands correctly |
| REQUESTER / RUNNER | y=574 | refused | lands correctly |
| SUBMIT | y=798 | refused | lands correctly |

All three tap correctly. The same screen a moment later, after `key return` on
the searchable User field removes the keyboard node entirely, resolves SUBMIT
with no warning at all — same position, same layout, different verdict.

This matters more than a nuisance refusal because item 14 lands on "tap the row"
as the only reliable way to drive a non-searchable dropdown, and this is what
refuses that tap.

**Fix.** Use the position when it is trustworthy and the size only when it is
not, with the discriminator in the same node: compare the keyboard's reported
width against the screen width. 402 against a 402-wide iPhone is one space and a
usable position; 370 against a 1194-wide iPad app is two spaces and size-only.
Then one more clause, which is the one that actually unblocks this — if the
resulting top is at or below `screen_h`, return `None`: a keyboard parked off
the bottom covers nothing, so there is no band and nothing is refused.

Two cautions. It loosens a guard that has caught real mistakes twice — 12 Aug
typed a stray `f` into a store field, and on 19 Aug a tap on a menu row at y=571
with the keyboard genuinely up landed on the typing-prediction bar and put "The"
in the field. And item 8's iPad case (`3,0 425x1194` in native space, where the
old position-reading code refused every element on screen) has to keep passing,
so it wants re-measuring on the iPad and not only on the iPhone.

**Workaround in the meantime**, shipped in the project rather than here:
`01-device-setup.journey` opens with a swipe that scrolls the page so the menu
opens above y=569.

**Second screen, measured 20 Aug 2026** (session G, same device and app). The
Settings management-PIN modal raises a numeric keypad that parks at `0,874` on
an 874-point screen — down, covering nothing. Guard comes out at
`874 - 233 = 641`; `VERIFY` sits at `147,625 106x48`, centre y=649, and is
refused by 8 points. The practical damage here is different from the 19 Aug
case: it is `expect`, not `tapon`, so a button plainly on screen is reported as
**not found**, which reads as the app having changed rather than the resolver
refusing to look. Worth noting when the fix is written — the guard is consulted
on the assertion path too, where "unreachable" and "absent" are not the same
thing and should not report the same way. Ties to item 38.

**Done 11 Sep, in `src/`, shipped 11 Sep.** `keyboard_geometry()` in
`bin/resolve.py` now takes `screen_w` and uses the keyboard's reported POSITION
when it is in the screen's own coordinate space — the discriminator is the
keyboard's reported width against the screen width, exactly as the fix section
asked — and its SIZE only when it is not (an iPad's native space). The clause
that actually unblocks this: if the resulting top is at or below `screen_h`,
return `None` — a keyboard parked off the bottom covers nothing. The refusal
message now carries the derivation for whichever path was used, so it no longer
claims "sizes, not positions" when it read the position.

Both cautions covered by tests (suite 197 → 203): the iPad native-space case
still bands at 409 (size path, unchanged), and a synthetic full-width keyboard
genuinely up at 569 still bands and still refuses a covered element with the
`driver.sh dismiss` advice. One discovery while doing it: the committed
`iphone-portrait-keyboard-up.json` fixture is actually a *parked* keyboard
(nodes at y=874/946 on an 874-point screen) — this item's own case — so it can
no longer stand in for "an element under the keyboard"; the refusal-message and
exit-5 tests moved to two small synthetic fixtures (`kb-pos`, `kb-size`), one
per code path. Not re-measured live: the physical iPhone driver was down
(item 50's crash) and the fixtures are real captures, so the logic is settled
offline. The project's `01-device-setup.journey` opening swipe workaround can be
removed once this ships.

## 31. `typed.py` passes when the text landed somewhere other than the field — **BUILT IN src/ 11 Sep, shipped 11 Sep**

**Session F.** Item 14 shipped `bin/typed.py` so that `type` stops reporting
success when the text did not arrive. On the screen item 14 is about, the check
cannot fail. Two holes, and the Store Device screen trips both at once.

**It matches a substring** (`typed.py:63`, `if wanted in t`). Typing `LOC1` into a
field that already holds `4001` gives `4001LOC1`, which contains `LOC1`, so the
check passes. Measured 19 Aug 2026: that append is exactly what a non-searchable
dropdown does to a field that already has a value, and it is one of the two ways
the wrong location gets committed.

**It searches the whole tree** (`typed.py:59`, `for n in walk(root)`), not the
field that was typed into. The Device Location menu renders a row whose label is
`LOC1`, so the string is on screen whether or not the field received it. Any
dropdown whose rows carry the same text as the value being typed makes this
check vacuous — and a filtering dropdown, which is the case `type` is most used
for, always does.

Item 14's own write-up says "it would not have caught this failure", about
`LOC1` arriving correctly and `4001` being committed. That is true and is a
different point. These two are about it not catching text that never arrived,
which is the thing it exists for.

**Fix.** Scope to the focused node — `hasFocus` is already in the hierarchy and
`tree.py:39` reads it — and compare that node's `value` against what was typed
rather than searching every node for a substring. If no node has focus, say so
and pass, the way the secure-field exemption already does, rather than falling
back to a tree-wide search that reads as a check and is not one.

**Done 11 Sep, in `src/`, shipped 11 Sep.** `bin/typed.py` now finds the
`hasFocus` node and compares what it holds against the typed text by equality
across `value`/`label`/`title` (not `placeholderValue`, which is the hint) — so
`4001LOC1` is no longer accepted for `LOC1`, and a menu row labelled `LOC1` no
longer stands in for the field. A missed tap onto another field is caught (that
field has focus and holds the wrong value); nothing focused says so and passes,
and a focused secure field is still exempt. Nine offline tests replace the old
substring ones (both item-31 holes have their own case); suite 205 → 208. Live
verification would need the physical iPhone, whose driver is down from item 50;
the synthetic hierarchies exercise every branch, and the driver already reads the
field with focus after a `type` (it taps then reads `_hier`).

## 32. `tree.py` runs the flag column into the label — **DONE 11 Sep**

**Session F**, misread twice in one session and settled only by going to `find`.

`tree.py:39` builds `flags` as `S` for selected and `F` for focused, and
`:42` prints it immediately before the label with no separator:

```
                     0,770    80x70   button    S SETTINGS
                    80,770    80x70   button     CHAT
```

The first tab is selected. Nothing on the line says the `S` is a flag rather
than the first word of the label, and the one-character shift is the only
difference between the two rows. Three consequences: a label that genuinely
begins with `S ` or `F ` cannot be told apart from a flagged one; the frame
column stops aligning on flagged rows, which is what makes a column of frames
scannable in the first place; and a reader who copies the label into a selector
copies the flag with it.

**Fix.** A fixed-width flag field, or brackets — `[S]`, `[SF]`, `[  ]`. Either
keeps the columns aligned and makes the flag unambiguous.

## 33. Both renderers silently truncate the strings the skill says to copy verbatim — **DONE 11 Sep**

**Session F**, from reading the two renderers rather than from being bitten.

`tree.py:37` cuts labels at 60 characters and `resolve.py:499` cuts them at 50.
Neither marks that it happened. Matching is unaffected — `texts()` returns the
full value and the regex runs against that — so this is display only, which is
precisely what makes it hard to notice.

It matters because skill rule 2 is "never author a selector from a screenshot —
copy the text verbatim from the hierarchy", and the hierarchy view is what that
rule sends you to. A label at 61 characters is shown at 60 and a selector copied
from it will not match, with nothing on screen suggesting why. This app has at
least one node in range: the request-list card is a single node whose label is
the whole card newline-joined, and it runs well past 60.

**Fix.** Append `…` when the string was cut. One character, and it turns a silent
wrong answer into a visible one.

## 34. `--explain` prints a marker per level, which reads as compounding — **DONE 11 Sep**

**Session F.** `find "^LOC1$" --explain` on the Store Device screen printed:

```
[1]     37.6,547.5      275.1x48.0    centre  175.1,571.5  t48  LOC1
       marker 134x291.333 at 0,0 -> scale 3 offset -0,-0
       marker 134x291.333 at 0,0 -> scale 3 offset -0,-0
```

Two markers, the same scale twice. `walk()` **replaces** rather than multiplies
(`resolve.py:125`, `c_scale, c_off_x, c_off_y = k, -mx * k, -my * k`), which is
correct and is what the app notes record — "markers replace rather than
compose". But the chain is printed as a list of steps, and a list of steps is
read as applied in sequence, so the honest reading of that output is ×9.

The centre printed beside it is right, so nobody acting on the number is misled.
Anyone checking the working — which is what `--explain` is for, and what item 9
made the refusals do — is.

**Fix.** Collapse consecutive identical markers, or word the line as replacing
the one above it.

## 35. The keyboard test uses the centre only — **DONE 11 Sep**

**Session F**, noticed while measuring item 30.

`resolve.py:366` is `cy >= kb_top`. A tall element whose top half is clear of
the keyboard is refused outright, and a short one whose centre clears the edge
by a point is allowed even though most of it is covered. The tap goes to the
centre, so the centre is the right thing to test for *where the tap lands* — but
the refusal's advice is "scroll the element clear", which is about the element,
not the point.

Low on its own, and it should be done in the same pass as item 30 rather than
before it: while the edge itself is wrong there is no point refining what is
compared against it.

# Added 20 Aug 2026, session G

## 36. A journey can stop after one line and report success — **BUILT AND SHIPPED 10 Sep**

**Built 10 Sep.** The suspected cause held: `_journey`'s `while read … done < "$file"`
put the journey on fd 0, and a verb that shells out to `_ssh` (which passes stdin
through to the remote *by design* — `lib.sh:115`) swallowed the rest of the file and
ended the loop cleanly at status 0. Fix: the read now owns its own auto-assigned fd
(`exec {fd}< "$file"`, `read -u "$fd"`), which is per-call so nested `include`s do not
clobber the parent's read, and an EOF assertion after the loop fails loudly if the file
was not exhausted. The blanket `</dev/null` on every ssh the item also suggested was
**not** applied: `_ssh` passes stdin through deliberately and real callers rely on it,
so the fd isolation is the correct fix rather than muzzling ssh. Two offline tests via
the stub driver (a stdin-draining verb no longer truncates; a real failure still stops
and returns non-zero); the stub gained `jtok.py`, which it had never needed until a
journey ran through it. Suite 185 → 187.


**Session G.** The worst failure this toolkit can have, because the whole
argument for batching is that `expect` between the actions stops a run
reporting on a screen it never reached. Here it reports exactly that.

Seen twice, driving `brandco-flutter-runner` on the iPhone 16 Pro:

| journey | printed | what the app was doing |
| --- | --- | --- |
| `13-logout.journey` | `ok <file>:14` and nothing more, then the runner moved on to the next file | the logout itself had worked |
| `01-device-setup.journey` | `ok <file>:35` and stopped | left on Device Information with every field unset and SUBMIT disabled — so lines 36+ did not run, rather than their output being lost |

Both returned **0**. No `FAILED` line, no tree dump — a real failure prints
both. The second sighting is the one that proves it: the device was still
unconfigured afterwards, and the journey's last line is an `expect` that could
not have passed.

**Cause not established**, and four reproductions all ran to completion: three
`expect`s; `swipe` then two `expect`s; `expect`, `settle`, two `expect`s; and a
copy of the real `01-device-setup.journey` with every action below line 36
replaced by `log`, which ran all 53 lines and printed every one. So it is not
the file's length, not the comment block, not `settle`, and not `swipe` alone.

**Four sightings later the same day, and they have one thing in common.**
`07-open-request.journey` stopped after `tapon "^TASKS"`, leaving the app on the
task list; `18-mark-item-found.journey` stopped after its `tap`, though the tap
itself landed. With the two earlier ones that is four, and **every one stopped
after the first line the journey executed** — never the second, never the
third. The verbs differ across the four (`tapon`, `swipe`, `tapon`, `tap`) and
so do the screens, so the verb is not the variable.

That points at something done **once per invocation**, before or during the
first command, rather than at anything a particular verb does. It also explains
the intermittency: `17-accept-task.journey` ran all seven lines minutes later,
on the same device in the same session.

**Best suspicion, and the four sightings fit it.** `_journey`
(`bin/driver.sh:346`) reads the file with
`while IFS= read -r line; do … done < "$file"`, so anything in the loop body
that consumes stdin eats the rest of the journey and the loop ends cleanly, with
status 0. `_driver_bind` and `_rebind` shell out to ssh, the classic stdin
eater, and both run **once per invocation, on or before the first command** —
`_driver_bind` when the cached port map needs refreshing, `_rebind` on a path
that is already failing. That is exactly the shape of the evidence: always the
first executed line, whatever verb it is, and intermittent between runs of the
same file.

Testing it costs nothing: run a journey twice in a row, the second immediately
after the first, and see whether only the first truncates. Or add `</dev/null`
to the ssh calls and try to reproduce.

The fix is plumbing either way: read the file on a dedicated fd (`done < "$file"`
becoming `done 9< "$file"` with `read -u 9`), and `</dev/null` on every ssh
invocation. Both are worth doing regardless of which one is guilty.

And whatever the cause, the runner should not be able to end a journey early and
return 0. Count the lines consumed against the lines in the file, and fail
loudly on a mismatch.

**Until then**, and this belongs in `reference/journeys.md` as much as here:
**trust the printed `ok` lines, not the exit code.** A journey has done what it
printed and nothing more.

## 37. Nowhere to keep a second set of test values — **DONE 11 Sep**

**Session G**, from reconciling an outside Maestro suite into a project's
journeys. A project gets one `.maestro-mac.conf`, and everything else is passed
on the command line per run. That is fine for one environment and awkward for a
second — a different store, tenant, account or region — because the values that
change are not the ones a journey names, and the one that must never move (the
PIN) lives in the same file as the ones that do.

The suite being reconciled drove the same app against three stores and solved it
with an `.env` file per store plus a runner that loaded one. Its flows had to be
rewritten to stop hardcoding literals; journeys here are already
variable-driven, so what is missing is the storage and the selection, not the
plumbing.

**Fix.** Named value sets beside the conf — `.maestro-mac.conf.<name>`, or a
`profiles/` directory — layered over the base by something like
`PROFILE=<name> driver.sh script …`, with `bin/secrets.sh check` covering every
one of them rather than only the base file. That last clause is not decoration:
more files holding test data is more places for a credential to end up, and the
check is what currently makes that safe.

**Wanted, not speculative.** The open question this was raised with — whether
`brandco-flutter-runner` stays a single-store project — was answered on 20 Aug:
the multi-store material is being kept, so a second set of values is expected
rather than hypothetical. The alternative is a wall of `KEY=value` on every
command line, which is how a value gets set wrongly and quietly.

## 38. No way to assert enabled state — **DONE 11 Sep**

**Session G.** `expect` matches a label whether the control is live or dead, so
"present but disabled" and "present and usable" are indistinguishable — and when
the assertion fails, so are "disabled" and "absent".

The data is already there and only the filter is missing: `resolve.py:381`
carries `"enabled"` on every match and `:499` prints ` DISABLED` in the `find`
listing, as `tree.py:40` does in the tree.

**Fix.** A flag on `resolve.py` that drops candidates by enabled state, passed
through `_expect` in `driver.sh`, with a journey spelling such as
`expect "^SUBMIT$" disabled`. The design problem worth solving properly is the
failure message: "present but disabled" and "absent" must not report the same
way, or the assertion trades one blind spot for another.

**What it costs today.** Two journeys reconciled into `brandco-flutter-runner`
on 20 Aug lose their point without it — SUBMIT before a store is chosen, and
DELIVER before an item has been marked found. Both are recorded as comments in
the journey and read off `driver.sh tree` by eye, which is not an assertion and
does not fail a run.

## 39. `vmservice.sh` finds nothing while `flutter run` is healthy — **BUILT IN src/ 11 Sep, shipped 11 Sep**

**Session H**, measured 20 Aug 2026. `bin/publish.sh` reported
`no VM service found - is the app running in debug?` with a live `flutter run`
attached and the Dart VM Service printed in its own log.

`remote/vmservice.sh:28` rediscovers the base URI exactly one way:

```sh
B=$(xcrun simctl spawn "$DEV" log show --last 5m --style compact 2>/dev/null \
      | grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=+/-]+' | tail -1)
```

A five-minute window on the simulator system log. An app started more than five
minutes ago — which is every app whose build you sat through — has scrolled out
of it, and the script exits 1. The message says the app is not in debug, which
is the opposite of what is true, and `bin/net.sh` then returns empty in a way
that reads as an app making no HTTP calls at all.

**Fix.** `flutter run` prints the URI itself and keeps it in whatever log it was
redirected to — `A Dart VM Service on iPhone 16 Pro is available at:
http://127.0.0.1:55407/R-KhdenhVwM=/`. Fall back to that log before giving up,
and make the failure message distinguish "no service found" from "the app is not
in debug", since only one of those is a statement about the app.

**Workaround meanwhile**, seed the cache by hand on the Mac and then run
`publish.sh` as normal:

```sh
B="http://127.0.0.1:<port>/<token>="        # from the flutter run log, no trailing /
I=$(curl -s "$B/getVM" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["isolates"][0]["id"])')
mkdir -p /tmp/maestro-mac
printf '%s %s\n' "$B" "$I" > /tmp/maestro-mac/vmservice
```

Note also that `publish.sh` returns a base URI with no host
(`http://:9100/...`), so `MAC_FQDN` has to be substituted into
`published.state` by hand afterwards. Same session, same sitting; possibly the
same fix.

**Done 11 Sep, in `src/`, shipped 11 Sep.** `remote/vmservice.sh` now reads the
`flutter run` log first — a file keeps the URI however long ago the app started —
and falls back to the simulator system log (still a `VM_LOG_WINDOW`, default 5m)
only for an app started without a redirected log. It reads `$FLUTTER_RUN_LOG`
(default `/tmp/flutter-run.log`, this skill's recipe in SKILL.md) and `$FRUN_LOG`
(`/tmp/frun.log`, the hot-reload skill's), tries the most recent candidate first,
and takes the first with a live isolate. The failure message now distinguishes
"no URI in any log" (not under `flutter run` at all — not a debug/release
statement) from "URI found but no live isolate" (stopped/restarted). Two offline
tests via a stub `xcrun` (empty system log) + stub `curl` + a temp flutter-run
log; suite 203 → 205.

The `publish.sh` no-host half is fixed too: it built `http://:9100/...` because
`ssh -G "$MAC_HOST"` was handed the whole alias list (item 18), returning no
hostname. It now calls `_pick_host` first (a no-op for a single-host config) and
errors clearly if no LAN IP resolves, rather than emitting a hostless URI. This
closes the item-18 follow-up for `publish.sh` specifically; the general "`$MAC_HOST`
raw is not a hostname" caution still stands wherever else it is interpolated.

## 40. `bin/build.sh` can finish without installing — **BUILT AND SHIPPED 10 Sep**

**Built 10 Sep.** Root cause found in `remote/build.sh`: the install loop ended each
iteration on `xcrun simctl install … || echo "install failed" >&2`, so the echo was
the last command and a build that installed nothing still exited 0 — the STALE-after-a-
build symptom exactly. Now the loop tracks failures and `exit $rc`, and additionally
confirms the bundle is resident (`simctl get_app_container`) after a "successful"
install, since install-returned-0 and app-is-there are different claims. The `_ssh`
exit status propagates, so local `bin/build.sh` returns non-zero too. Three offline
tests via the stubbed `xcrun` (install fails; install ok but not resident; clean
install); suite 187 → 190. The nohup-teardown alternative cause is not separately
needed: whatever interrupts the run, a non-installed app now fails loudly instead of
passing.


**Session H**, seen once, 20 Aug 2026. Run detached in the background against a
specific `DEV`, `build.sh` exited 0 with the Xcode build complete and **nothing
installed** on the target simulator. `bin/preflight.sh` then reported STALE for
a device that had just been built for — the check doing its job, and the build
script not.

**Cause not established.** Either the install step ran and failed quietly, or
the background process was torn down when the calling shell returned. Settle it
by running `build.sh` in the foreground against a device holding an old build
and watching for the install line.

**The launch shape, from the raising session itself (Session H, `de240800`).**
The "detached in the background" run above was specifically under **`nohup`**:
the Xcode build finished and nothing was installed. That is the detail that points
at the second cause — the install step torn down with the calling shell rather
than failing quietly — since `nohup` detaching the build but not carrying the
install stage through would leave exactly this. Recorded at the time as an open
question in `app-notes.md` and `reference/driving.md`. To confirm: run `build.sh`
detached and watch whether the `simctl install` line executes before the parent
returns. (Not a second sighting — same Session H occurrence, named more precisely
after review on 9 Sep.)

**Fix**, once the cause is known: exit non-zero when the install did not happen,
rather than reporting the build's status as the script's. A build script that
returns 0 having left the old binary in place is the same class of failure as
item 36 — success reported for work not done.

**Workaround meanwhile**, and re-run preflight rather than assuming:

```sh
bin/mac.sh 'xcrun simctl install <udid> build/ios/iphonesimulator/Runner.app'
```

## 41. `expect` cannot wait for a condition — **DONE 11 Sep (selector timeout shipped 10 Sep; arbitrary-predicate `expect-cmd` added 11 Sep)**

**Built 10 Sep.** `expect "^X$" <n>` and `expect-not "^X$" <n>` now poll `_resolve`
once a second up to `<n>`, print a heartbeat line each tick (so a wait is never
mistaken for a hang), and return the moment the condition is met. Zero-timeout
default is unchanged, so no existing journey starts waiting. A non-numeric
timeout is treated as zero rather than crashing the step. `reference/journeys.md`
gains the timeout form and the "do not `settle` immediately after opening a
transient overlay" warning (session `cf5c6f39`). Six offline tests via the stub
driver; suite 179 → 185. **Still open:** the arbitrary-predicate variant below —
polling a network/VM-service/build state, not only a selector (session
`de240800`). That wants a new `--until`-style form and is a separate change.


**Session G**, converting 21 Maestro flows into journeys. `expect` and
`expect-not` call `_resolve` once and answer immediately
(`bin/driver.sh:217`). There is no wait-until form, and the two things that
look like one are not:

- **`settle`** waits for the *screen* to stop moving. It covers a slow render or
  a screen still waiting on a request, and it returns at once on a screen that
  is already still — which is precisely the case where the condition has not
  happened yet.
- **`wait <n>`** is a blind sleep, and `reference/journeys.md` says in bold not
  to use it as part of an ordinary step.

So a condition that changes **without the screen moving** cannot be waited for.
Two shapes hit in one afternoon:

| what | why `settle` does not help |
| --- | --- |
| a transient banner clearing on its own timer (`Requested successfully` sits over CANCEL for ~2-3s and eats the tap) | the screen is still while the banner is up |
| a status that arrives on a poll or a push rather than on a navigation | same |

Maestro's own answer is `extendedWaitUntil: { visible \| notVisible: …, timeout: n }`,
and **every flow being converted used it** — so each one became a blind
`wait 5` here, with a comment explaining why the thing the reference forbids is
the only option. `22-cancel-request.journey` in `brandco-flutter-runner` is the
worked example.

**Fix.** A timeout argument on both verbs — `expect "^X$" 15` and
`expect-not "^X$" 15` — polling `_resolve` until it agrees or the limit passes,
returning as soon as it does. Cheap: `_expect` already has the resolve call and
the absent/present branch, so it is a loop and a deadline. Keep the zero-timeout
default so existing journeys do not silently start waiting.

Worth doing alongside item 36: an assertion that can wait is only trustworthy if
the runner cannot skip it.

**Reinforced hard — session `0598a4b6`, 21 Aug.** The whole idle-timeout run was
built out of hand-rolled poll loops because there is no wait-for-condition
primitive: **179 `sleep`s and not one `expect`** across the session. Two costs
followed directly. A poll set to print only when the screen changed sat silent and
was indistinguishable from a hang — the user twice thought it had frozen (*"I'm
assuming you got stuck in a loop"*) — and a poll killed before it recorded the
modal lost a measurement that had to be re-run. An `expect … <timeout>` polling
with a visible per-tick heartbeat would have replaced every one of those loops and
removed both failure modes. Strongest evidence yet for the item, and for making
the wait print a line per tick so it is never mistaken for a stall.

**A network-condition variant — session `de240800`, 20 Aug (PROJ-1772 review).**
36 `sleep`s and no `expect`, but here the conditions being waited for were mostly
off-screen: a build finishing, and the app reaching (`online True`) then leaving
the network to reproduce a silent-failure finding, all hand-rolled as
`while …; do …; sleep 60/70; done` poll loops. It widens the item — the missing
wait-for-condition primitive is needed for states the driver can read (network,
VM-service, build) as much as for on-screen ones — so the timeout form should be
able to poll an arbitrary predicate, not only `_resolve` on a selector.

**A second-heaviest sleep count, and settle breaking a step again — session
`213647e3` (Session J), 3 Sep.** Verifying the PROJ-1804 auto-logout fix meant
waiting on idle timers over and over: **70 `sleep`s and only 3 `expect`s**, no
poll loops — durations clustered at the timed states (`sleep 30` for the countdown,
`sleep 20` for the idle threshold, plus many 2–8 s waits between actions). Some are
irreducible (you must wait the real 30 s for a 30-second countdown), but the waits
*for the modal to appear or the screen to change* are exactly what `expect …
<timeout>` would replace. Second only to `0598a4b6`'s 179. And the `settle` fault
recurred: *"the `settle` straight after `key return` commits the user, and a
journey's bare `settle` times out at 10 s"* — the same "settle after a transient
action misfires" as the cf5c6f39 note below, plus a concrete number (a bare
`settle` in a journey caps at 10 s, distinct from the driver's 20 s `isScreenStatic`
ceiling seen in `9ea404ec`).

**`settle` can actively break a step, not just under-serve it — session
`cf5c6f39`, 24 Aug.** `01-device-setup.journey:20`'s `settle` closed the language
dropdown and failed the journey. `settle` waits for the screen to stop moving; a
just-opened transient overlay (a dropdown, a menu) is exactly a screen still in
motion or one that dismisses on its own, so a `settle` placed right after opening
one can return on the closed state and leave the journey on the wrong screen. The
journey-authoring guidance in `reference/journeys.md` should warn: do not `settle`
immediately after opening a transient overlay — act on it in the same beat, or
`expect` the specific element instead. Same family as the transient-banner row in
this item's table.

## 42. No way to run a project's own script on the Mac — **DONE 11 Sep**

**Session G.** `bin/mac.sh` runs a *command* on the Mac. There is no way to run
a **file** that exists only in the project's checkout here, and that is the
common case for anything talking to the app's own backend: the API host is
usually unreachable from the sandbox, so the script has to execute there.

The Mac's checkout is not a substitute. It is a real working copy on whatever
branch it was last left on — `proj1772-review` on 20 Aug, while this side was on
`development` — so a helper written here is simply absent there, and copying it
into that tree makes it untracked residue in a repo `preflight.sh` reports on.

What it took on 20 Aug to run one read-only API script:

```sh
ssh mac-b 'mkdir -p /tmp/mtools'
scp maestro/tools/*.py mac-b:/tmp/mtools/
ssh mac-b "cd /tmp/mtools && APP_PIN='…' python3 find_in_stock.py --store 4001"
```

Three commands, an ad-hoc directory, and the credential passed inline on a
command line — which is the part that actually matters, because everything else
here works hard to keep the PIN in `.maestro-mac.conf` and out of anything that
gets echoed or logged.

**Fix.** `bin/mac.sh --send <file> [args…]`, or a `bin/run-there.sh`: copy to a
scratch directory under the existing `$RDIR`, run it with the conf's `APP_*`
values exported into the remote environment rather than interpolated into the
command line, stream stdout back, and clean up. Small, and it removes the one
step in this toolkit that currently has to be done by hand with the PIN visible.

Low priority on its own — an `scp` works. Raised because the credential handling
is the sort of thing that is fine until it is pasted into a transcript.

**Second sighting, from the opposite angle — session `90833915`, 14 Aug.** The
same missing capability bit in reverse: with no clean way to send a non-trivial
command to the Mac, an inline nested-quoted `devicectl`/profile query mangled its
own output through the quoting layers, and the fix on the spot was to stop sending
it inline and write it as a script on the Mac first — *"The nested quoting is
mangling the output. Let me run it as a proper script instead."* So
`run-there.sh` / `mac.sh --send` is not only about a project's scripts and the
PIN: it is also what stops the skill's own ad-hoc commands breaking on quoting.
Same fix, second reason.

**One more portability point from the same session:** a remote command that
wrapped itself in `timeout` failed with `zsh: command not found: timeout` — macOS
ships no `timeout` (it is `gtimeout`, and only if coreutils is installed). So
`run-there.sh` must not assume GNU coreutils on the Mac, and any time-bounding
belongs on this side of the SSH call rather than in the command sent over.

**Two more sightings, session `480adcc1` (21 Aug).** First, the quoting hazard
again through a second channel: running a flow via `osascript -e 'tell
application "Terminal" to do script …'` mangled its arguments, and the fix was
the same — stop passing arguments through the quoting layers and give the runner
a fixed script path instead. Second, and new: **`/tmp` is being cleaned on this
Mac mid-session** — a script written to `/tmp` vanished under a running poll loop
("`/tmp` is being cleaned on this Mac — that's what ate the earlier script"), and
the fix was to write under `$HOME` instead. So `run-there.sh`'s scratch directory
must be under `$RDIR`/`$HOME`, never `/tmp`, or the thing it ships can disappear
before it runs.

## 43. `tree` has no compact mode — no noise filter, no dedup — **DONE 11 Sep**

**Session G**, from comparing `tree.py` against `peek.sh` in the `handover-maestro`
handover, which does three things this toolkit does not.

**It filters system noise.** `tree.py:walk` prints every node it is given, so a
screen with the keyboard up carries twelve `key` rows, and *every* read carries
the status bar — `Mobile Service No signal`, `#3 of 3 Wi-Fi bars`,
`100% battery power`. `peek.sh` skips a named list: keyboard keys, Backspace,
Return, shift, space, the typing-prediction bar, Dictate, Emoji, battery, Wi-Fi,
Mobile Service. The element types are already in `TYPES` — 20 `key`,
19 `keyboard`, 25 `statusbar` — so the filter is a type test, not a string list.

**It dedupes by text.** A label that appears on a card and again on its parent
container prints twice here and once there.

**It is flat, and frames are opt-in.** One line per text node, no indentation,
no frames unless asked. That matters for what it costs to read: most reads
during a session are "what is on this screen", not "where exactly is this", and
those pay for the full indented tree with a frame on every line.

**And it says something when it finds nothing** — `(no text nodes — a
modal/camera/loading screen?)` — where `tree` prints a few container lines and
leaves the caller guessing whether the read failed or the screen is a spinner.

**Fix.** A third mode beside `tree` and `nodes` — `text`, or a `--quiet` flag —
that drops keyboard/status-bar element types, dedupes on the label, omits the
frame column unless asked, and prints the empty-screen hint. `driver.sh` already
routes `--tree`/`--nodes` after an action verb, so it is one more word there.

None of this argues for keeping `peek.sh` itself: it shells out to
`maestro hierarchy` at 7.7s against this toolkit's 0.28s, needs the CLI and a
JVM, and drives `maestro --device`, which destroys that device's driver
(item 15). It is the output that is worth taking, not the transport.

## 44. Four things a Maestro flow can say and a journey cannot — **DONE 11 Sep**

**Session G**, from sweeping the directives — not the comments — of the 25
flows in the `handover-maestro` handover. Each of these is load-bearing in that
suite and has no expression in the journey format. They are grouped because
they are one decision: how much of Maestro's vocabulary the journey runner
should grow. Taken separately they are four small changes; taken together they
are the difference between a journey being able to describe a real session and
having to assume one.

**`clearState: true`** — five uses, and every one of its device-setup flows
depends on it, because those flows test the login screens and must start signed
out. `driver.sh` has `launch` and `kill` and nothing that wipes app data, so a
true cold start cannot be reached from here at all. The project's own notes
record the three things that look like a restart and behave differently:
`launch` on a running app only foregrounds it and keeps the basket, `kill` then
`launch` clears the basket and keeps the session, and only LOG OUT clears the
session. `clearState` is the fourth and it is missing. Whether the driver's
`launchApp` route accepts the flag is unchecked.

**Conditionals — `runFlow: { when: { visible / notVisible: … } }`** — 26
`runFlow` uses, some of them branching. Its language step is the worked example:
one store offers Deutsch and English, another English alone, so the row to tap
differs and the flow branches on whether `Deutsch` is on screen. `include` is
unconditional, which is why the equivalent journey has to assume one store's
list. Anything that differs by environment, role or data needs this or needs
forking the file — and `reference/journeys.md` currently says to fork, which
does not scale past two variants.

**`optional: true` on a tap** — for a `Back` that may or may not be needed
because the stack may be one or two deep, and for the iOS push-permission alert,
which may or may not have appeared. Today every journey step is mandatory, so
"tap this if it is there" cannot be written and the alternative is a separate
journey per state.

**`scrollUntilVisible`, with a direction and a timeout** — three uses, all for
the same problem: a section that sits below the fold by an amount that depends
on how much content is above it. Journeys have a blind `swipe`, so the
equivalent is two swipes and a hope; one project journey does exactly that and
says so.

**Fix.** `optional` and `scrollUntilVisible` are self-contained and worth doing
first — a trailing `?` on a verb, and a `scrollto <pattern> [direction]
[timeout]` that loops swipe-and-resolve. Conditionals need a syntax decision
before any code, and the cheapest thing that would work is a guard on `include`
(`include-if <pattern> <file>`) rather than a general expression language.
`clearState` needs the driver route checked before it can be scoped.

Related: item 41 wants `expect` to be able to wait, which is the same shape of
problem — Maestro's `extendedWaitUntil` has no equivalent here either. Do them
in one pass if any of it is taken on.

# Added 21 Aug 2026, session H

## 45. Physical iPhone support exists and lives entirely outside the skill — **DRIVING PATH shipped 10 Sep; APP-BUILD-ON-DEVICE path BUILT IN src/ 11 Sep AND VERIFIED LIVE on the XS Max, shipped 11 Sep**

**Built and verified 10 Sep 2026.** The driving half is now in the skill and was driven
end to end on the XS Max (`00008020-…`, iOS 18.7.9, Xcode 26.6):

- `bin/device.sh up|down|list` — the physical-device counterpart to `bin/drivers.sh`.
  `up` copies the two remote helpers to the Mac, brings up the forwarder + a persistent
  driver, and registers the device; `down` tears both down; `list` shows live status.
- `remote/deviceup.sh` — mirrors `remote/driverup.sh`: `xcodebuild test-without-building`
  against the re-signed `driver-iphoneos` products with `TEST_RUNNER_PORT=<port>`, plus
  the two device-only extras — the usbmux forwarder and a `devicectl` tunnel wake — and a
  locked-phone refusal up front.
- `remote/iproxy.py` — the usbmux forwarder from `physical-device.md` §4, now shipped and
  parameterised (`<udid> <port>`) rather than hand-pasted.
- `bin/lib.sh` — a `DEVICE_MAP` registry that `_driver_map` merges, so `_driver_bind`
  resolves a phone exactly like a simulator. `DEVICE_PORT_BASE` (22187) sits above the
  simulator range so a phone and a booted sim never collide.

Verified: `bin/device.sh up <udid>` then `DEV=<udid> bin/driver.sh nodes` returned a real
XS Max hierarchy (`414x896 app`, home screen), driven through device.sh → registry →
relay → forwarder → device with nothing hand-run. One offline test of the registry seam;
suite → 195.

**Gate decisions, as resolved by this build.** Gate 2 (forwarder residency) is answered:
it lives in `remote/`, brought up and torn down by `device.sh` like the driver. Gates 1
(signing route) and 3 (profiles) are **not** touched, and did not need to be — the
DRIVING path reuses the already-re-signed driver products, so it needs no app signing.
Building the *app under test* on a device (`build.sh` device support) is still gated on
those and remains open; `device.sh` deliberately does not build or install the app.

**Two live caveats worth keeping.** (1) The persistent driver **died mid-session twice**
during this build — item 46, reproduced again; the ensure-driver recovery is now the
clear next piece and `device.sh` enables it (a `device.sh up` re-runs the driver). (2) A
stale `relay.py 9201 23001` (wrong target port) was found holding the relay port and
blocking the correct relay; its origin was not root-caused (a race in an earlier
`driver.sh` attempt is the suspicion, not a finding) and `device.sh down` + a `pkill`
cleared it. Worth watching: `driver.sh`'s `_start` only `pkill`s the exact
`relay.py <DPORT> <DRIVER_PORT>` string, so a relay on the same port with a different
target survives and wins — a real reliability edge to fix alongside item 46.

**Session H**, from getting `maestro hierarchy` to return a real view hierarchy
off an iPhone XS Max attached to the Mac. It worked. Nothing about it is in
`bin/`, and every step was run by hand from this side. The findings are written
up in `src/physical-device.md`; this item is the decision about folding them
into the skill proper.

**Attribution corrected (9 Sep review).** The session that actually cracked this
end to end and wrote `src/physical-device.md` was `480adcc1` (21 Aug), not the
"Session H" named above — the evidence table's H (`de240800`, 20 Aug) is an
iPhone 16 Pro *simulator* review that never touched the XS Max (no `devicectl`,
no device UDID in its transcript). Every mechanism in the bullets below — the
`osascript` Aqua signing route, re-signing the prebuilt `driver-iphoneos`
products, the ~50-line usbmux forwarder, the tunnel-idle wake, the
profile-not-debug rule — was established in `480adcc1`, across about two hours of
a three-hour session that reached the point of driving the phone and then stalled
on the login. Read that transcript, not H's, for the working commands.

What the skill assumes today, and what a device does instead:

- **`bin/drivers.sh` and `remote/driverup.sh` are simulator-only.** They extract
  `driver-iPhoneSimulator` from `maestro-ios-driver.jar` and run
  `test-without-building` against `id=<udid>`. The jar ships `driver-iphoneos`
  beside it, unused.
- **The driver's HTTP server binds on the phone, not the Mac.** On a simulator
  the two loopbacks are one, which is the whole reason `driverup.sh` never
  needed a forward. On a device it needs usbmux. `iproxy` is not installed and
  there is no Homebrew; `/var/run/usbmuxd` is world-writable, so ~50 lines of
  Python does it with no installs. Working code is in `physical-device.md`.
- **Nothing signs from an SSH session.** `launchctl managername` is `Background`
  and `codesign` returns `errSecInternalComponent` there — for the app under
  test as much as for the driver. `osascript -e 'tell application "Terminal" to
  do script …'` runs in Aqua and signs fine, with no password. This one is not
  device-specific: it affects `bin/build.sh` too, which today can only work
  because a simulator build is not signed.
- **The device tunnel idles out** and Maestro then says the device is not
  connected. A `devicectl` call in the same script immediately beforehand fixes
  it. `bin/preflight.sh` has no notion of any of this.
- **`bin/build.sh` builds `--simulator` and installs with `xcrun simctl`.** A
  device needs `--profile` (a debug build will not launch standalone on iOS 14+
  and a debugger suppresses suspension) and `devicectl device install app`.
- **Maestro 2.8.0 cannot build its own device driver** — the project references
  a `MaestroDriverLib` target whose sources are in no jar. The prebuilt
  `driver-iphoneos` products re-signed into
  `~/.maestro/maestro-iphoneos-driver-build/driver-iphoneos/Build/Products/`,
  plus a `version.properties`, make it skip the build. That is a workaround
  around an upstream bug and will need rechecking on every Maestro upgrade —
  `bin/docs-check.sh` already watches the version, so it is the natural place to
  warn.

**Three more device-only facts from `480adcc1`, not in the list above.**
`maestro test` picks a *random* `TEST_RUNNER_PORT` per session (only `hierarchy`
uses the default 22087), so the usbmux forward has to discover the port Maestro
chose rather than forward a fixed one; `MAESTRO_DRIVER_STARTUP_TIMEOUT` is in
**milliseconds**, so a `180` meant as seconds makes it give up in three polls,
worse than the default; and `launchApp`/`clearAppState` are unimplemented for
physical devices in `LocalIOSDevice` (only those two — `tap`, `type`, `scroll`,
`pressKey`, `takeScreenshot`, `viewHierarchy` all route to the XCTest driver and
work), so a device session must launch and cold-restart the app with `devicectl`,
not through Maestro. A `bin/device.sh` needs all three built in.

**Fix.** The shape is a `bin/device.sh` beside `bin/drivers.sh`: prepare the
signed driver once, hold the usbmux forward up, wake the tunnel, and hand
`bin/driver.sh` a device the same way a simulator is handed to it — so
`DEV=<device-udid>` selects the phone and everything downstream is unchanged.
Three things need deciding before any code:

1. **Whether signing moves to the Aqua route everywhere.** If it does,
   `bin/mac.sh` grows a second mode and `bin/build.sh` gets device support for
   free. If it does not, device builds stay manual and the skill stays
   simulator-only in practice.
2. **Where the forwarder lives.** It has to outlive the call that starts it,
   which is what `remote/` is for — residency on the Mac. It also has to be
   torn down, and `drivers.sh list` is the existing model for reporting what is
   up and on which port.
3. **What the skill promises about profiles.** Everything here needed a wildcard
   development profile that already existed. A project without one needs the
   Apple account, and `-allowProvisioningUpdates` creates records in it — which
   the skill should never do silently. Probably: check for a usable local
   profile, and refuse with instructions rather than reaching for the account.

Related: item 40 wants `bin/build.sh` to stop finishing without installing —
the device path makes that worse, because install is a separate `devicectl`
call that can fail on its own.

**First sighting moved to 14 Aug — session `90833915`, six days before session H
and on a different device.** A user connected an **iPhone 11**
(`00008030-0022334455667788`, iOS 26.5.2) — not the XS Max session H drove — and
asked for it to be controlled. Three things it established, all still bearing on
the decisions above:

- **Nothing could drive it, and the usbmux route session H later found was not
  yet known.** No WebDriverAgent, Appium, libimobiledevice, go-ios or
  `ios-deploy` was installed — only Apple's own tooling — so on 14 Aug the honest
  answer was that Maestro could not drive it and neither could anything else on
  the Mac. Session H (20 Aug) then made it work on the XS Max with ~50 lines of
  Python. Both belong behind `bin/device.sh`.
- **`devicectl` is a read path on hardware even with no driving.** It installed,
  launched and terminated apps and **read the app's prefs plist straight out of
  the data container** — the same `flutter.*` idle-clock measurement used on the
  simulator worked on the phone. A device you cannot tap you can still measure.
- **This is the concrete first instance of open question 3 (profiles/certs).**
  The device UDID was in none of the Mac's provisioning profiles, and the
  keychain held no signing certificate for the project's team (`TEAM123456`) with
  a private key — so no signed current build could be installed, and a reboot did
  not change it. The session correctly refused to reach for the Apple account.
  That is the exact wall question 3 anticipates, seen for real before the item
  existed.
- **The two Apple tools disagreed on whether the phone was usable.** `devicectl`
  reported it `available` while `xctrace` listed it `offline` (locked, or not
  paired for instruments). Whatever `bin/device.sh`'s readiness check ends up
  being, it cannot trust a single signal — it has to say which tool it believed
  and why, or a genuinely drivable phone reads as absent and an unusable one
  reads as ready.

**App-build-on-device half done 11 Sep, in `src/`, verified live, shipped 11 Sep.**
The signing "gate" turned out not to be a bespoke signer at all: flutter/Xcode
sign the app; the only obstacles are that codesign fails in an SSH (Background)
session — flutter's own included — and that `flutter run` is a debug build that
cannot launch standalone on a device. So `bin/build.sh` gained a device mode that
runs a **profile** build through the Aqua `osascript` route (where signing works)
and installs with `devicectl`, gated on a local provisioning profile. Decisions,
as resolved: (1) signing via Aqua — yes, for the device build; (2) forwarder
residency — already done (the driving half); (3) profiles — check for a local one
and refuse with instructions, never `-allowProvisioningUpdates`, so the Apple
account is never touched.

Verified live on the XS Max: `DEV=00008020-… bin/build.sh` built the uat profile
build and installed `acme.e.brandco.runner.uat` (`devicectl` confirmed the
bundle id). A live-caught bug fixed in the same sitting: the first run's app glob
`build/ios/*iphoneos*/*.app | head -1` picked a **stale `Debug-dev-iphoneos`
build** and installed the wrong `.dev` debug bundle while reporting success —
because the old residency check only grepped that the app id was present *somewhere*
on the device. Now it installs the exact `build/ios/iphoneos/Runner.app` and
verifies the id `devicectl` reports actually equals `APP_ID`. Three offline tests
(exact path not the stale dir; a wrong installed id is caught; no-profile refusal);
suite 212 → 215. Gates 1 and 3 are closed for the device build; nothing here
touches the Apple account.

**Two related edges still open.** The re-signed driver products need re-checking on
each Maestro upgrade (item 55's `docs-check.sh` watches the version — the natural
place for that warning), and `launchApp`/`clearAppState` are unimplemented for
physical devices in Maestro, so a device session must launch/cold-restart the app
with `devicectl`, not through the driver — not yet wired into a device driving
helper.

## 46. The device driver dies mid-session and every error blames the relay — **Scripts BUILT IN src/ 10 Sep (ensure-driver recovery, relay-target fix, devdrv.log + locked-phone + XCTest-session surfacing), offline-tested; surfacing live-verified. F27 measured the death: the on-device XCTest session dies every ~40-70s with the tunnel still connected — item 46's CORE is that instability (a toolchain question, item 55), which the scripts mitigate (restart) but cannot fix.**

**Now that item 45's device path exists, the recovery was built (F23/F24, 10 Sep).**
- `driver.sh` `_ensure_device`: when a **registered** device's driver stops answering,
  it restarts it through `bin/device.sh up` (idempotent) and retries once per
  invocation. Self-gates on `_is_device` (the DEVICE_MAP registry), so a simulator
  never triggers it. This is fix 1, made cheap by `device.sh`.
- `driver.sh` `_start` now `pkill`s **any** `relay.py <DPORT> ` regardless of target,
  fixing the reliability edge found the same day: a stale relay left pointing at the
  wrong port held the socket and beat the correct relay to it, so an exact-match pkill
  left it running. (Root cause of the stale relay's *origin* still not established.)
- Two offline tests (the `_is_device` gate; ensure-driver no-ops for a simulator);
  suite → 197.

**Live status.** The `devdrv.log` tail and the locked-phone refusal are **live-verified**:
during the F23 test the phone auto-locked and `deviceup.sh` refused with "the phone is
LOCKED — unlock it", exactly the named cause the whole item is about, rather than a
relay/connection error. The auto-restart *recovery* itself is **not yet live-verified** —
the phone auto-locked before the kill-and-recover step could run, so that half rests on
the offline gate tests plus the manual down/up recovery done earlier. Finishing it needs
the phone unlocked (and ideally auto-lock disabled for the session).

**F23-live attempt, 10 Sep — the mechanism fires, but the recovery does not complete,
cause not yet found.** With the phone unlocked: `device.sh up` → `driver.sh nodes` drove
the phone (real hierarchy), the driver was killed to simulate the death, and `driver.sh
nodes` again printed exactly the intended "note: the device driver … is not answering —
restarting it (item 46)" and called `device.sh up`. The restarted driver **came up and
served `/status`** (`~/devdrv.log`: "starting server 127.0.0.1:22187", a GET /status),
then immediately hit `** BUILD INTERRUPTED **` and the retry failed with "did not
answer". **F26 debugging corrected that suspicion — it is the driver's own instability, not the
recovery code.** Bisecting: a `device.sh up` driver survives the ssh close and 15s idle
(ALIVE, `/status`=200), so detachment is fine. Then, with no `driver.sh` recovery running
at all — just a manual relay-start probe ~30s later — the driver was `xcodebuild ALIVE`
but `/status`=000: **the on-device driver had died on its own** (item 46's DTX/tunnel
invalidation), the process lingering. So the earlier "`BUILD INTERRUPTED` when `device.sh
up` is called from within `driver.sh`" was almost certainly item 46's *own* intermittent
death coinciding with the retry — `xcodebuild` reports the same DTX drop variously as
"connection was invalidated", "TEST EXECUTE FAILED", "BUILD INTERRUPTED", or just a dead
HTTP server with the process still up. I nearly pinned it on the recovery code a second
time; the evidence says the driver simply dies every tens of seconds on this XS Max /
Xcode-26.6 setup. **So `_ensure_device` fires correctly and restarts the driver, but the
underlying instability is severe enough that a single restart+retry often loses to the
next death — and the keep-alive that would hold the tunnel was already disproven (Session
L, and again here).** The honest state: the recovery *logic* is right and offline-tested;
end-to-end reliability is bounded by item 46's core, unsolved problem — keeping the
device's XCTest/DTX connection alive — which may not have a clean fix on this toolchain.
That core is the remaining work, not the ensure step.

**F27 measured the death, and it is NOT the tunnel idling — the assumed cause is wrong.**
Two clean lifespan runs on the XS Max (Xcode 26.6), monitor polling `/status` every 3s:
the driver lived **~44s** and **~69s**, then `xcodebuild` exited with `** TEST EXECUTE
FAILED **`. At the moment of death, both times: `devicectl` reported the device
**`connected`** (NOT `available (paired)`), and the usbmux forwarder was still up. So:

- The mid-session death is **not** the CoreDevice tunnel idling out — the tunnel stays
  connected. It is the **XCTest test session itself** terminating (`TEST EXECUTE FAILED`)
  while everything under it is healthy. So the `devicectl … lockState` tunnel-wake that
  `deviceup.sh`/§5 rely on does **not** address the mid-session death (it addresses a
  different, real thing: the tunnel idling *before* Maestro starts).
- It is **not** an HTTP idle timeout: `/status` was polled every 3s throughout and the
  session died anyway. And it is **not** the forwarder (mine) — it stays up.
- Lifespan is ~40-70s and variable. A device session must therefore restart the driver
  roughly once a minute, which makes `_ensure_device` (restart on death) necessary but
  also means a long single journey may outlive one driver and need mid-run restarts.

A toolchain question (item 55), not something the scripts can fix — but the two obvious
toolchain levers were **checked and ruled out** on 10 Sep, so the cause is narrower and
nastier than assumed:

- **A newer Maestro will not help — checked.** Maestro **2.9.0's** iOS driver is
  **byte-identical** to 2.8.0's (same SHA `c7dea82b…`, same size), so mobile.dev did not
  rebuild it between those releases. Upgrading would reproduce the same driver and the
  same death. (Verified by downloading 2.9.0 and comparing the runner binaries; nothing
  on the Mac was changed.)
- **It is not an old-Xcode driver.** The driver's `Info.plist` says it was built with
  `DTXcode 2600` (**Xcode 26.0**), SDK `iphoneos26.0.internal` — only a minor step from
  the Mac's 26.6, and an Apple-*internal* SDK we cannot reproduce. So "re-sign/rebuild
  under the current Xcode" is not a real option (re-signing changes nothing; a rebuild
  needs the internal SDK Maestro's CI used).

So the death is a driver-built-with-Xcode-26.0 vs Mac-testmanagerd-26.6 skew, or an
XCTest device-session limit, or something specific to this XS Max on iOS 18.7.9 — and
none of Maestro-version, re-sign, or a plain Xcode change addresses it. The realistic
answer for now is the `_ensure_device` restart mitigation plus accepting a ~1-minute
driver life; a genuine fix likely needs mobile.dev to ship a driver built against a
released SDK, or Apple-side XCTest stability, neither of which the scripts control. (An earlier version of this note called Xcode 26.6 a "beta" — that was an
unverified assumption and is wrong. Confirmed online 10 Sep 2026: Xcode 26.6, build
17F113, is a **public release dated 25 June 2026** — https://developer.apple.com/news/releases/?id=06252026a
— matching `/Applications/Xcode.app` (26.6, 17F113, no beta marker). So it is a current
stable release, "upgrade to a stable Xcode" is moot, and the beta theory is dead; the
mismatch/re-sign angle is what is untested.) What the scripts *can* do is stop
mis-attributing it, and that is now done (F28, 10 Sep): `_devdrv_hint` (driver.sh) and
`deviceup.sh` no longer tell the caller to wake the tunnel — they name the on-device
XCTest session dying, give the measured ~40-70s lifespan, say a full driver restart is
the fix (not a tunnel wake), and point at the toolchain (item 55) if it recurs. Suite
still 197.

**Built 10 Sep (the hardware-free half).** `driver.sh` gained `_devdrv_hint`: when the
relay `/status` check fails, it reads `~/devdrv.log`'s last lines off the Mac and prints
them with the item-46 explanation ("connection was invalidated / TEST EXECUTE FAILED is
the device tunnel or the on-device driver dropping, not the relay"), instead of leaving
the bare "status did not answer". It self-gates on the log existing and being recent
(that log exists only for a device driver run), so a simulator run adds nothing. Two
offline tests (the function extracted and driven with a fake `_ssh`); suite 190 → 192.

**Lock check added (F20), and verified live.** `_devdrv_hint` now probes
`devicectl … lockState` for `$DEV` first and, on `passcodeRequired: true`, leads with
"the phone is LOCKED — unlock it" — the most common and most actionable cause, and the
one that fooled this session's own diagnosis. It self-gates: `devicectl` returns nothing
for a simulator udid. Third offline test added (suite → 193). Verified against the real
XS Max: unlocked it reports `passcodeRequired: false` and stays silent (no false alarm),
and a sim udid returns nothing (silent). This is also the diagnostic core of fix 1's
ensure-driver readiness check.
**Still open:** fix 1 proper — the ensure-driver restart+retry — which needs a device
whose driver can actually come up, and the `drivers.sh list` tunnel column, which needs
devices to appear in that listing at all (item 45). Both are blocked behind item 45 and
the 10 Sep toolchain wall below.

**Session I**, from running plan 03-11's idle-timeout checks on the phone over
about two hours (that session is `0598a4b6`, 21 Aug 12:07–15:38 — added to the
evidence table on the 9 Sep review; it is where this item was written). Item 45 records that the tunnel idles out *before* Maestro
starts. This is the other half: it also drops *while the driver is running*, and
nothing in the skill says so or recovers from it. Detail and the exact log lines
are in `src/physical-device.md` section 5.

What it cost, and why it is worth code rather than prose:

- **The failure surfaces as a relay fault.** `driver.sh` prints `relay started
  but http://<mac>:9101/status did not answer` and `tree.py` then dies with a
  `JSONDecodeError` on empty stdin. Neither mentions the device. The first
  instinct is to restart the relay, which is not the problem. Diagnosing it
  properly took three round trips every time it happened, and it happened five
  or six times in one session.
- **`bin/drivers.sh list` says GONE without saying why.** It cannot currently
  distinguish "the driver crashed", "the tunnel dropped underneath it" and
  "something else took the port". On a device those need different responses.
- **It is worst exactly where it hurts most.** The drops clustered in the long
  waits with no traffic — an idle-timeout measurement is minutes of deliberate
  silence, so the tooling is least reliable precisely when a test needs it most.
  Three measurements were lost this way and had to be re-run from scratch, each
  costing another login cycle.
- **A `devicectl` relaunch kills the driver every time.** `process launch
  --terminate-existing` takes it down with it, so a cold relaunch — which any
  test of cold-start behaviour needs — always has to be followed by a driver
  restart. Nothing in the skill pairs those.
- **A first `devicectl` failure means nothing.** It failed once with
  `RemotePairingError error 4` / `Connection reset by peer` and succeeded on a
  plain retry seconds later, with the phone plugged in, awake, unlocked and
  visible to `usbmuxd` throughout. Without a retry that reads as a hardware
  fault and sends you to check the cable.

**Fix.** Two pieces, both small:

1. An ensure-driver step that `bin/driver.sh` runs itself when a device (not a
   simulator) is selected: ping `lockState`, check `/status`, restart the driver
   if it is not 200 — with one retry on the `devicectl` call before reporting
   anything as broken. That removes the whole class of "relay did not answer"
   confusion.
2. A keep-alive for long waits. `lockState` is not a touch and never reaches the
   app, so it is safe to run inside an idle-timeout measurement — but a caller
   has to know that, and today has to write the loop by hand. If item 41's
   `expect`-with-a-timeout lands, the keep-alive belongs inside it rather than
   in every caller's polling loop.

Also worth fixing while in there: `drivers.sh list` should report the tunnel
state alongside the driver state, so GONE says which layer went.

Related: item 45 (the device path generally) and item 41 (`expect` cannot wait
for a condition, which is why these waits are hand-rolled loops at all).

**Session L, 4 Sep 2026** — verifying PROJ-1799 on the phone over about
twenty-five minutes. Two measurements that change the fix above.

- **It is not only long idle waits.** The driver died roughly every second
  `driver.sh` process in a session that was never idle for more than a few
  seconds — six restarts. The pattern that held: one `driver.sh` invocation
  works, a second invocation in the same Bash call finds the driver gone. So
  the practical rule is one process per driver life, which makes
  `driver.sh script a.journey b.journey` the only reliable shape and any
  sequence split across two invocations a coin toss. `~/devdrv.log` gave the
  real cause each time — `An error occurred while communicating with a remote
  process ... The connection was invalidated`, then `** TEST EXECUTE FAILED
  **` — and the symptom on this side was item 46's usual `relay ... did not
  answer` plus the `JSONDecodeError`.
- **Fix 2's keep-alive is not safe, and does not work.** The claim above that
  `lockState` "is not a touch and never reaches the app, so it is safe to run
  inside an idle-timeout measurement" was tested directly: a `nohup` loop
  running `xcrun devicectl device info lockState` every 10s. The driver died
  anyway, in the same way, with the loop running. Worse, it broke an install —
  `xcrun devicectl device install app` failed with
  `com.apple.dt.CoreDeviceError error 3002` / `IXRemoteErrorDomain error 6`,
  `XPCErrorDescription = "Connection interrupted"`, at
  `_IXHandleConnectionForInstallMessagesFromRemoteService_block_invoke`. Killing
  the keep-alive and the driver and re-running the identical command installed
  first time. So `lockState` is cheap but not free: it contends for the same
  device tunnel that the driver and `devicectl` both need, and a periodic one
  is a second writer on that tunnel.

**What this does to the fix.** Item 46's fix 1 (an ensure-driver step) gets
more valuable, not less — it is now needed on essentially every device call,
not just after long waits, and it is what would have absorbed all six restarts
silently. Fix 2 should be dropped or re-scoped: a keep-alive on this transport
is not a keep-alive, and if anything like it survives it must be suspended for
the duration of any `devicectl` install or launch. Whatever ensure-driver ends
up doing, it should read `~/devdrv.log`'s last lines when `/status` is not 200
and print those rather than the relay message, since the log names the cause
every time and this side never does.

**Live on the XS Max, 10 Sep 2026 — and the real cause was a LOCKED PHONE, not a
toolchain wall (an earlier note here got that wrong).** Full manual bring-up per
`physical-device.md`: usbmux forwarder up, tunnel woken (`connected`, DDI mounted),
driver re-signed products present, runner installed, `maestro` detected the phone.
With the phone **on the PIN screen** (reported by the operator; `passcodeRequired` was
**not** measured during the failures — that gap is the whole mistake), `maestro
hierarchy` failed twice: `~/devdrv.log` showed `Testing started` then `The connection
was invalidated` / `** TEST EXECUTE FAILED **`, `/status` stayed `000`, Maestro reported
`iOS driver not ready in time`; a `devicectl lockState` poke loop across the startup
made no difference. **Once unlocked, `maestro hierarchy` returned a real view hierarchy,
and a 3× repeat was 3/3 PASS with `passcodeRequired: false` each time** — so unlocked it
is reliable, not intermittent — on the same Maestro 2.8.0 / Xcode 26.6. The unlocked-
passes half is measured directly; the locked-fails half rests on the operator's report
plus the known iOS behaviour that XCUITest cannot attach to a locked springboard, so it
is strongly corroborated rather than a clean controlled A/B. So:

- A **locked device produces item 46's exact symptom** — `connection was invalidated`
  / `driver not ready` / `relay did not answer` — because XCUITest cannot attach to a
  locked springboard. This is a third distinct way into the same misleading surface,
  alongside the tunnel dropping (item 46) and the phone lying flat (item 50). The
  readiness/ensure-driver step must check `devicectl … lockState` → `passcodeRequired`
  **before** the first touch and say "unlock the phone", the same shape as item 50's
  posture check.
- The 10 Sep claim that "the environment moved (iOS/Xcode 26.6)" and that a
  Maestro-vs-Xcode version drift was the wall was **wrong** — a confident diagnosis from
  one failure mode without checking `lockState`. Corrected here. Maestro 2.8.0 drives
  this phone fine on Xcode 26.6.
- Fix 2 (the `lockState` keep-alive) still did nothing useful, but on a locked phone
  that proves less than it seemed; its real disproof stays Session L's.

**Fix 1 (ensure-driver restart + retry) still unverified as a recovery** — that needs a
persistent driver over a long session to catch the mid-session death, which the toolkit
cannot yet run against a device (item 45). But the driver *starts* now, so the wall is
item 45's missing device path, not the toolchain. Temp scripts removed afterwards.

**Early sighting — session `480adcc1`, 21 Aug (the bring-up).** The `tree.py`
`JSONDecodeError` on empty stdin and the tunnel going idle ("Maestro reads the
device as disconnected") both appeared here while the chain was first being
stood up — the tunnel needed a `devicectl` wake immediately before Maestro, and
the wake had to move *inside* the launching script because the tunnel dropped
back to idle in the 30 s between a separate wake call and Maestro starting. So
the class of fault predates session I; what session I added was the mid-run
recurrence and the ~2-hour cost.

**Another instance — session `9ea404ec`, 4 Sep.** The driver crashed on many
touches (tunnel-invalidated), each costing a 7–25 s restart, and between crashes
it was merely slow: `settle` (`isScreenStatic`) hit its 20 s ceiling repeatedly —
the login journey has four settle points, so a call near-instant on a simulator
ran 60–90 s+ on the phone and often ended in `settle: screen still moving after
20s` then the usual `relay … did not answer`. That settle-never-reports-still
behaviour on hardware is a distinct cost from the driver dying (item 41 is the
waiting primitive it argues for), and it is the main reason device driving reads
as "so slow". The session reproduced nothing and was stopped twice.

**The recovery never actually ran — fixed 11 Sep.** The ensure-driver step this
item's scripts added called `"$HERE/device.sh" up …` directly, but `device.sh`
ships without an execute bit (`ship.sh` does not chmod, and `~/.claude` refuses
`chmod +x`), so every recovery for a physical device died with
`device.sh: Permission denied` before restarting anything. Found live on the
XS Max on 11 Sep (item 50's session): the touch killed the runner, the recovery
fired, and `Permission denied` is what came back. Changed `bin/driver.sh` to
`bash "$HERE/device.sh"`, matching the house rule that every script here is
invoked through `bash`. Offline test added (a non-executable stub `device.sh`
whose marker only appears if the recovery invoked it through `bash`); suite
197 → 200. This is the mechanical half; the CORE XCTest-session instability
above is still a toolchain question (item 55).

## 47. `relay.py` relays into itself when the viewer is not running — **DONE 11 Sep**

**Session J** (`213647e3`, 3 Sep, the PROJ-1804 auto-logout fix — it spawned the
viewer agent that raised this item and item 48), from `viewer.sh` printing `relay
started, but nothing answered on port 9999 (tried dev-mac.local,
10.0.0.10)` twice and the cause taking five round trips to the Mac to find.

`remote/relay.py` binds the IPv4 wildcard and forwards to IPv4 loopback:

```python
srv.bind(("0.0.0.0", lport))          # line 38
upstream = socket.create_connection(("127.0.0.1", rport))   # line 42
```

`viewer.sh` starts it as `relay.py 9999 9999`, so when `lport == rport` the
forward target sits inside the relay's own bind — `0.0.0.0` covers `127.0.0.1`.
Every accepted connection is handed straight back to `accept()`, a thread pair
is spawned for it, and it recurses. Nothing ever returns HTTP; `curl` through
the sandbox proxy gets a `502`.

This only bites when Maestro Viewer is not running. `viewer.sh`'s header
comment already states the invariant that keeps the two sockets apart — "the
viewer's socket is IPv6-loopback — verified with lsof" — but nothing enforces
it, so the moment the assumption fails the relay eats the port rather than
saying so.

What it cost:

- **The error names the wrong layer.** "relay started, but nothing answered"
  reads as a network or name-resolution problem. It is neither: the relay
  reached nothing because there was nothing to reach, and then made itself
  unreachable too. The first three checks went to mDNS, the LAN address and the
  sandbox proxy, all of which were fine.
- **`viewer.sh` reports success for the part that failed.** It says the relay
  started — which is true, and useless. A relay with no upstream is not a
  working relay.

**Fix.** Two pieces, first one alone is enough to make the loop impossible:

1. **Forward to `::1`, not `127.0.0.1`.** That turns the documented assumption
   into enforced behaviour: an IPv4 wildcard listener cannot accept an `::1`
   connection, so a self-loop cannot form whatever `lport` and `rport` are. It
   changes nothing for the relays where `lport != rport`.
2. **Probe before binding.** When `lport == rport`, connect to the target once
   at startup, *before* `srv.bind()` — after the bind the probe hits the relay
   itself — and exit non-zero if nothing accepts. `viewer.sh` then prints "no
   service on 9999 to republish", which is the actual fault.

Binding the Mac's LAN address instead of `0.0.0.0` also closes the loop, but it
costs the property `.maestro-mac.conf` is written around: URLs built from
`MAC_FQDN` follow the Mac between the office and home networks, and an
address-bound relay would not.

Worth doing at the same time: `viewer.sh` has no way to start a viewer, only to
republish one. `maestro studio` exists on the Mac as a hidden subcommand — it is
absent from `maestro --help`'s command list but answers `maestro studio --help`
— and that is what puts a viewer on 9999. It attaches to a device and so
destroys a running XCUITest driver, which is why it cannot simply be called; but
`viewer.sh` should at least say that the viewer is missing and name what starts
it, rather than leaving the caller to work out that republishing needs something
to republish.

Related: item 46 (an error that blames the relay for something else's failure —
the same shape, one layer up).

**Earliest sighting: session `90833915`, 14 Aug — the same "nothing serving on
9999" message, handled correctly and cheaply.** *"The viewer relay started but
nothing is serving on 9999 (Maestro Viewer isn't running on the Mac) — not a
blocker for driving, just no live view."* It did not hit the relay-into-itself
loop this item is about (that needs the deeper `relay.py` bug session J found),
and it did not spend the five round trips session J did — it read the message as
"the Viewer just is not up" and moved on. Kept as the contrast: the fault below
is that the *message* invites the wrong diagnosis, and here it happened not to.

Same benign handling again in session `cf5c6f39` (24 Aug): *"the viewer relay
isn't answering on 9999 — I'll carry on without it and note it."* Worth recording
only because it dates the "9999 not answering" nuisance to 24 Aug, ten days before
session J raised the underlying `relay.py` loop — so the Viewer being down (and
the relay then having nothing to serve) is a frequent state across sessions, which
strengthens the case for fixing the message even though neither 90833915 nor
cf5c6f39 hit the self-loop.

## 48. The `maestro-mac` MCP server hardcodes one SSH alias — **DONE 11 Sep**

**Session J.** The server failed to connect for the whole session with
`CONNECTION_CLOSED`, while `bin/mac.sh` talked to the Mac throughout. The entry
in `~/.claude.json`:

```json
"maestro-mac": {
  "type": "stdio",
  "command": "ssh",
  "args": ["-o","BatchMode=yes","-o","ServerAliveInterval=30",
           "-o","ServerAliveCountMax=6","mac-b",
           "export JAVA_HOME=... && exec maestro mcp"]
}
```

It always dials `mac-b`. The Mac was on the office network:

```
$ ssh -o BatchMode=yes -o ConnectTimeout=10 mac-b 'echo OK'
Connection timed out during banner exchange
$ ssh -o BatchMode=yes -o ConnectTimeout=10 mac-a 'echo OK'
OK-mac-a
dev-mac.local
```

SSH times out, the process exits, and Claude Code reports the server as closed.

The skill solved this a long time ago and the MCP entry never got the fix:
`.maestro-mac.conf` sets `MAC_HOST:=mac-a mac-b` and `lib.sh:71
_pick_host` tries each alias in turn, caches the winner for the session, and
re-picks at `lib.sh:134` if the chosen one stops answering. Every script gets
that for free. The MCP server, being a bare `ssh` invocation in a JSON file,
gets none of it.

What it cost: the viewer could not be started at all this session, because
`open_maestro_viewer` is an MCP tool and the server carrying it was down. Item
47 is the second half of the same dead end.

**Fix.** Replace the bare `ssh` command with a small launcher in `bin/` — call
it `mcp.sh` — that sources `lib.sh`, runs `_pick_host`, and `exec`s the same
`ssh` line against whichever alias answered. The MCP config then names the
script and never names a host. That also means a new network only has to be
added to `.maestro-mac.conf`, in one place, rather than to the conf and the MCP
entry separately.

Pointing the existing entry at `mac-a` is not a fix — it moves the failure
to whenever the Mac goes home.

Related: item 47 (what the dead MCP server blocked) and item 45 (the physical
device path, which has the same one-host assumption in its tunnel setup).

## 49. Start of session never says to read the project's existing flows and journeys — **BUILT AND SHIPPED 10 Sep (rule 1, rule 10, start-of-session step, preflight count; plus `journeys.md` "When a journey is wrong" — repair-in-place, no dodge-fork, write-back, no hard-coded volatile data)**

The start-of-session sequence has five numbered steps. Step 3 is "read the
project's app notes if they exist — `bin/notes.sh path`". Nothing anywhere in
that sequence says to list `maestro/flows/` and `maestro/journeys/`.

The notes and the journeys are different kinds of prior work. The notes are
measurements — a frame, an offset, a label copied verbatim. The journeys and
flows are the *executable* prior work: the screens somebody has already got
working, in the order they work in. Reading only the notes leaves every screen
looking unknown, and the skill's own economy — "the moment a sequence of steps
works, write it down" — collapses, because you cannot replay what you do not
know exists.

What it cost, 3 Sep 2026, PROJ-1799 (session `9d5eb4e7`, which raised this item):
a session drove the app screen by screen
with ad-hoc `driver.sh tap` calls for two hours, including the first-run
store-and-PIN login, which `maestro/flows/setup.yaml:66` has covered with
`inputText: "${APP_PIN}"` since before the notes were merged. The hand-built
version then put `$APP_PIN` in a plain Bash command, where it is unset —
`bin/config.sh:171` exports `APP_*` into the process that sources it, which is
`driver.sh`, not the caller's shell. Four PIN attempts silently sent an empty
string and the app answered "Please enter the pin of the store", which reads
like a wrong PIN or a broken text field. `flows/` and `COVERAGE.md` were never
listed until the user asked why not. And the finding the whole afternoon chased —
the chat empty-state error — was already written in `COVERAGE.md` under 🚫 Blocked
from **22 July** ("the CHAT tab renders the untranslated key
`unexpectedErrorMessage` when the session has no valid API token, reproduced
twice"). The session's own words once it read it: *"Everything I improvised today
already existed, and one line of `COVERAGE.md` was the answer to the whole
afternoon."* That is the cost stated at full size: not just a re-derived login, but
a re-investigated bug that a listed file already had.

Note the second-order effect: because the caller's shell has no `APP_PIN`, the
*only* correct way to type a credential is through a journey, a flow, or a call
that sources the conf itself. So a skill that does not point at the journeys is
also, quietly, a skill that leads to sending empty credentials.

**Fix.** Two parts, both small.

1. Add a step to the start-of-session sequence, beside the app-notes step:
   list `$JOURNEY_DIR` and the project's `maestro/flows/`, and say plainly that
   a screen already covered there is replayed, not rediscovered. Name
   `COVERAGE.md` if the project has one.
2. Say in **The rules that matter most** that a credential from the conf is
   only readable inside the skill's own process, so `${APP_PIN}` belongs in a
   journey line or a flow and never in a hand-built shell command. Rule 2
   already warns about authoring selectors from screenshots; this is the same
   shape of mistake with a worse failure mode, because an empty credential
   looks like an app defect rather than a tooling one.

A `preflight.sh` line counting the journey and flow files that exist would make
the gap visible without anyone having to remember, and preflight is already the
one call everybody makes.

Related: the "Write journeys as you go" section (which assumes you know what is
already there) and item 37 (a second set of test values — same conf boundary).

**Session L, 4 Sep 2026 — the day after, and fix 1 as written would not have
caught it.** Verifying the PROJ-1799 fix on the phone. `ls maestro/journeys/`
was the *second* tool call of the session and printed all thirty filenames,
including `00-login.journey` and `01-device-setup.journey`. Neither file was
opened. The app then landed on the store/PIN screen showing the `Select Store`
placeholder — the exact starting screen `00-login.journey` names in its header
— and the setup screen after it had all four fields at their placeholders,
which is exactly what `01-device-setup.journey` says it requires. Both applied
verbatim. Both were hand-walked instead: nine `driver.sh` round trips, five raw
`tap x y` calls with the chevron offset done by hand, and `find --explain`
never used once. Seven minutes, 11:34 to 11:41, for what those two files run in
about one. `app-notes.md` was re-read mid-drive to re-derive the
chevron-not-the-field trick that `01-device-setup.journey`'s own header
explains. The user interrupted with "Stop hard-walking everything, use the
journeys"; every step after that ran as `driver.sh script <file> <file>` and
worked first time.

So the gap is not only that the directory goes unlisted. Listing it is not
enough — the directory *was* listed, and the sequence was still typed out by
hand. What is missing is a stated default: on a screen a journey covers, the
journey file is the unit of work, and a `driver.sh` action call is the
exception that needs a reason.

**Fix 1, sharpened.** Keep the new start-of-session step, and add the rule
alongside it, in **The rules that matter most** where rule 1 already says
"batch": *the unit of work is a journey file, not a driver call.* Before
driving any screen, check whether a journey starts there — its header names its
starting screen, which is what makes this a one-line check rather than a
reading exercise. If one does, run it. If none does, write one as you go, which
the "Write journeys as you go" section already asks for and which nothing
enforces at the moment of the first tap. A rule about which directories to list
does not survive contact with a screen that looks like a special case; a rule
about what a step *is* might.

**Proposed `SKILL.md` wording (9 Sep) — rule 1, "Batch": replace its last sentence
("Any sequence whose shape you already know should be a journey file.") with:**
> **The unit of work is a journey file, not a driver call.** Before driving any
> screen, check whether a journey starts there — a journey's header names its
> starting screen, so this is a one-line check, not a reading exercise. If one
> does, run it; if none does, write one as you go. Listing `maestro/journeys/` is
> not enough — the directory has been listed and the screen hand-walked anyway.

(Replaces rather than appends, so rule 1 does not say "should be a journey file"
twice — see the 9 Sep spot-check.)

Worth pairing with the `preflight.sh` line suggested above: if preflight
printed `journeys 30 files · flows 24 files · COVERAGE.md present` it would put
the count in front of the one call everybody makes, before the first tap rather
than after the session goes wrong.

**Earlier instance, and a second gap — session `0598a4b6`, 21 Aug** (six weeks
before this was raised). The user opened it with *"Are you using any of the
journeys and flows we've discovered? This should be taking seconds, not hours."*
It was not — but here the reason is worse than not reading them: the journeys
*existed* and were **broken**. `01-device-setup.journey` drives the screen with
`tapon` + typing, which item 14 had already proved selects nothing, and the
corrected method (tap the row) lived only in `app-notes.md`. Nobody wrote it back
into the journey, so the login was re-derived a tap at a time — about half an hour
on one four-field screen. So the "journey is the unit of work" rule needs a
companion: **a finding that corrects how a screen is driven must be written back
into the journey**, not just recorded in the notes, or the executable prior work
rots while the notes grow. A journey that is known-wrong and left in place is
worse than none: it gets run, fails, and the recovery is hand-driving.

**Journeys also rot when their data drifts — session `9ea404ec`, 4 Sep.**
`01-device-setup.journey` failed with `resolve: no visible node matches /^LOC1$/`
because the location `LOC1` no longer exists in the backend — the same class as the
stale barcodes in session `90833915`. A journey that hard-codes a volatile test
value breaks silently when that value is retired, and the failure names the
selector, not the cause. Such values should come from the conf/notes (as the PIN
already does), or the notes must be kept current — either way, more of the "the
executable prior work has to be maintained" point above.

**Done right, for once — session `3936b43e`, 4 Sep.** After the user again said
"use the journeys", the chat-fix verification ended with a *new* journey written
back: `29-chat-empty-state.journey` — `tapon "CHAT.*Tab"` / `expect-not
"unexpectedErrorMessage"` / `expect "No chats available"`, with a header stating
it is only evidence on a profile or release build on hardware. That is exactly the
write-back this item asks for: the finding became executable prior work rather
than a note. Worth keeping as the example of the behaviour the rule wants.

**The inverse failure, and it was expensive — session `5827cb0e`, 25 Aug.** Told
to run a full test script *"using the maestro journeys and flows already written"*,
the session instead **wrote a new journey** — it duplicated `01-device-setup.journey`
as `01-device-setup-v3.journey` minus the `settle` at line 20, because that settle
breaks the journey (item 41). Rather than fix line 20 of the existing, verified
file, it added a fourth device-setup journey to a directory that already had two.
The user caught it — *"Why are you writing new journeys?"* — and set the rule
plainly: *"journeys should only be written when there really is no other file …
This is not an exploratory run … A human can do this test script in under an hour
— I want you to take less time."* The session conceded *"That was the wrong call"*
and deleted the duplicate. Two things this sharpens: (1) the fix for a broken
journey is to **fix the journey**, not fork a copy — a forked copy is the same
"rediscover rather than replay" failure this item names, one layer up; and (2) the
start-of-session step this item wants must say not just *read* the existing
journeys but *repair-in-place and replay* them. Root trigger was item 41's
`settle` bug (`01-device-setup.journey:20`), so 41 and this item compound: an
unfixed journey bug invites a duplicate instead of a one-line fix.

**A milder echo — session `2fcffccc`, 26 Aug.** A UAT bug-repro (store 4002: push
a request through, flag errors, assign, unassign) drove the whole login → search →
add → submit → assign → unassign flow by hand — 14 `tapon` + 25 raw `tap`, **0
`script` (journey) calls** — for a flow that `00-login`/`01-search`/`02-add`/
`03-submit`/etc. already cover. Weaker than `5827cb0e` and not flagged by the user,
because the task was per-step error inspection (watch the network response at each
tap), which partly justifies manual stepping — but the getting-there steps (login,
navigate) were still rediscovered rather than replayed. Recorded as a data point
that even error-repro tasks would benefit from a "replay to the failing step, then
step manually" habit the start-of-session guidance could name. **And again, more
plainly — session `eba9ea2b`, 3 Sep:** "run this branch, login to 4001" was done by
seven individual `tapon` calls, `script`-count 0, when `00-login.journey` is built
for exactly store 4001 (it is in the dropdown's first rows). Clean taps, no
stabbing — but the login journey was not replayed for the one store it is written
for. Two mild echoes plus the two hard cases (`5827cb0e`, `07f380e8`) make this a
habit, not a one-off: the default is to hand-drive even a covered login. The
start-of-session step wants to make replay the reflex, not the exception.

**Named outright by the user — session `22d4c486`, 4 Sep.** Mid-review, the user
stopped it: *"You're just adhoc'ing calls, here, rather than using the proper
approaches and journeys. Do better."* The session's own reply is the confession
this item predicts: *"Fair — there's a `01-device-setup.journey`/
`01-device-setup-v2.journey` I should have used instead of hand-driving the
dropdowns."* So by 4 Sep the pattern was frequent enough that the user names it
as a standing failing, not a one-off — and the journeys it should have used were
sitting right there. This is the case for item 51's hook (block a raw/ad-hoc
sequence and name the journey) as much as for the start-of-session prose: prose
did not stop it across at least five sessions.

**Harder still the next day — session `2896ac1c`, 4 Sep (PR #119 review).** The
strongest pushback of the set, and it cost real time before any review happened:
*"Seeing a lot of bad habits trying to drive the simulator. Do it properly,"* then
*"you _must_ use the proper journeys, do not adhoc your calls. And follow the proper
approaches. I feel like I've already wasted an hour waiting for you to do it
wrong."* Only after that did it switch to *"chaining the existing, fixed journeys in
single batched calls per device"* — which is what the task wanted from the start.
So across `9d5eb4e7` (raised it), `22d4c486` ("Do better") and here ("must … wasted
an hour"), the item is now a repeat offence the user polices by hand every time,
and the correct behaviour only appears after the rebuke. Prose has failed the test
enough times that the enforcement half (item 51's hook) is the part that will
actually change it. (One justified new journey here: a first-launch
notification-prompt dismissal that no file covered — the 07f380e8-style good case,
written only because it was genuinely missing.)

**The rule done right — session `07f380e8`, 1 Sep (the positive case).** Checking
support ticket SUP-22 against a US store, this session wrote a new journey
`00-login-filtered.journey` — and it was the correct call, the inverse of
`5827cb0e`. Its header states why no existing file covered the path: *"00-login.journey
taps the store row without typing, and the dropdown only renders about seven stores
until something is typed — it works there because 4001 is second in that list. Any
store below the fold fails with `no visible node matches`."* A US store (4003) is
below the fold, so the existing login genuinely could not reach it, and a filter-first
variant is new executable prior work, not a duplicate. This is the shape the rule
wants: a new journey only when there is no other file, with a header saying what it
adds and why. Kept as the worked example of good judgement, against `5827cb0e`'s
dodge-a-bug fork.

## 50. A flat phone crashes the driver on the first touch, silently — **CONFIRMED LIVE + diagnosis BUILT IN src/ 11 Sep, shipped 11 Sep (a pre-touch refusal is not possible — no readable posture; found a separate item-46 recovery bug in passing)**

**Session K**, from resuming physical-device work cold (device already upright
in a prior session, so nothing carried the constraint forward). `driver.sh
nodes` read the home screen fine. The first `tapon` failed with the exact
transport-fault shape item 46 already describes — `settle: screen still moving
after 20s`, then `relay started but http://<mac>:9101/status did not answer`,
then `tree.py`'s `JSONDecodeError` on empty stdin — and the instinct was again
to suspect the relay or the tunnel.

`~/devdrv.log` on the Mac had the real cause: `ScreenSizeHelper.swift:99: Fatal
error: Not implemented yet`. `src/physical-device.md` already documents this
exact fault under "THE PHONE MUST BE UPRIGHT" — lying flat, the phone reports
`.faceUp`, `actualOrientation()` only maps `.unknown` to portrait, and the
first `POST /touch` kills the runner. Reads keep working, which is what makes
it read as a transport problem rather than a device-posture one. This is a
second, distinct way to land in item 46's symptom (`relay did not answer` /
`JSONDecodeError`), alongside the tunnel dropping — same fix shape (an
ensure-driver step), different root cause, so item 46's fix will not catch
this one on its own.

**Fix.** Before the first touch of a session against a device (not a
simulator), check posture and refuse with a named error rather than crash the
driver: `.faceUp` correlates with the fault, so it should tell the caller
"phone is lying flat — stand it upright" instead of surfacing as a relay
failure that costs a debugging round trip to the Mac's log every time. Whether
this can be read before any touch — from the hierarchy read itself, or a
dedicated driver endpoint — is unexplored; worth checking alongside item 46's
ensure-driver step, since both want to run at the same point (first touch of
the session) and both currently manifest as the same misleading symptom.

**First sighting moved to 21 Aug — session `480adcc1`, not session K.** This is
where the fault was first hit and diagnosed: a tap crashed the runner in its own
`ScreenSizeHelper.swift:99: Fatal error: Not implemented yet`, traced to the
phone lying flat reporting `.faceUp` on the second orientation read, and fixed by
standing it upright — the "THE PHONE MUST BE UPRIGHT" note in
`src/physical-device.md` was written from this session. It recurred cold two
weeks later: session `9ea404ec` (4 Sep AM) hit it again and is where this item
was actually *written* — so the old "Session K = `3936b43e`" credit was wrong:
`3936b43e` verified the chat fix and raised nothing. `9ea404ec` is the session
that raised this item (settled on the 9 Sep review).

Related: item 45 (the device path generally) and item 46 (the other cause of
this exact symptom — restarting the driver is necessary either way, but this
one additionally needs the phone physically moved, which no restart fixes).

**Confirmed live + built 11 Sep.** Drove the physical XS Max
(`00008020-0011223344556677`) laid deliberately flat and unlocked. Reads worked
(`deviceInfo` returned portrait 414x896, `nodes` read the home screen). A raw
`driver.sh tap 349 634` — the first `/touch` — killed the on-device runner:
`~/devdrv.log` ended `ScreenSizeHelper.swift:99: Fatal error: Not implemented
yet`, then `** TEST EXECUTE FAILED **`. So the crash is real and current, not
fixed upstream. The jar's own `ScreenSizeHelper.swift` (Maestro 2.8.0, dated
11 Aug) *does* handle `.faceUp` — pass-through, no fatal — so the prebuilt
on-device runner is compiled from **older source than the jar ships** (its
line 99 is `Not implemented yet`; the jar's is `Unsupported orientation`). That
is item 55's "the shipped mirror is stale" in binary form.

Two more things this run settled:

- **A pre-touch posture refusal is not implementable as the item imagined.**
  `DeviceInfoResponse` carries only width/height/pixels — no orientation field —
  and no other read route exposes `XCUIDevice.orientation`, so `.faceUp` cannot
  be read before a touch without an upstream driver change. (The `tapon` path did
  *not* crash, because the resolver mis-transformed the target to x=-892 and
  refused it as off-screen — an accidental shield, not a guard; a raw `tap` has
  no such refusal.)
- **What was built instead:** `_devdrv_hint` in `bin/driver.sh` now recognises a
  `ScreenSizeHelper` / "Not implemented yet" fatal in `devdrv.log` and prints
  "this is the FACE-UP crash (item 50) … STAND THE PHONE UPRIGHT", returning
  before the misleading item-46 XCTest-death message. It turns the crash from a
  relay-debugging round trip into a one-line instruction. The crash itself still
  happens — only an upright phone or an upstream fix (item 55) prevents it.
  Offline-tested (suite 197 → 200).

**Found in passing — an item-46 recovery bug, now fixed here.** When the touch
killed the runner, the ensure-driver recovery failed with
`device.sh: Permission denied`: `driver.sh` called `"$HERE/device.sh"` directly,
but `device.sh` ships without an execute bit (`ship.sh` does not chmod, and
`~/.claude` refuses `chmod +x`), so the recovery never ran for any physical
device. Changed to `bash "$HERE/device.sh"`. See item 46.

## 51. The skill has no way to ship a hook, and this one has nowhere else to live — **BUILT AND SHIPPED 10 Sep (src/hooks/, ship.sh carries it, setup.md § 5 documents the settings block; decided: ship in-skill). Operator steps done 11 Sep: settings.json points at the skill copy (line 35), and the interim standalone `~/.claude/hooks/gate-journey-first.sh` is deleted**

**Session L.** Item 49 is about prose in `SKILL.md` that is read at the start of
a session. This item is about the case where prose has already been tried and
lost. Three memories on this machine say do not hand-walk a screen a journey
covers; all three were loaded into context on 4 Sep and the login was
hand-walked anyway, nine round trips and five raw `tap x y` calls. Prose is read
before the screen is on the table. A `PreToolUse` hook fires while it is.

A working draft exists at `~/.claude/hooks/gate-journey-first.sh`, written and
tested in session L but deliberately not wired into `settings.json`. It matches
any Bash command mentioning `driver.sh` that carries a `tap` or `swipe` verb
followed by literal numbers — including the `$D tap 179 481` form, since shell
state does not persist between Bash calls so the assignment defining `$D` is
always in the same command. `tapon` is not matched, because resolving by label
is the behaviour the hook is pushing towards. It exits 2, which blocks the call
and puts the reason in front of the model, **once per session**, then gets out
of the way — raw taps are legitimate where the tree carries nothing to match,
the iPad nav rail being the standing example. Its marker lives in `$TMPDIR`
rather than `~/.claude/state`, which is not writable from a sandboxed Bash call,
and it fails open if the marker cannot be written, so it can never degrade from
a nudge into a ban.

**Where it belongs, and why that is a problem.** The hook can only ever fire on
a command containing `driver.sh`, which is this skill's own binary — with the
skill uninstalled it is dead code running on every Bash call in every project.
So it should ship, version and die with the skill: the script in `src/hooks/`,
`ship.sh` carrying it into `build/` like everything else, and the `settings.json`
path naming `~/.claude/skills/maestro-remote-mac/hooks/gate-journey-first.sh` —
the symlink, so it follows the skill.

The problem is that the skill has no mechanism for any of that. `ship.sh` builds
`src/` into `build/` and symlinks it into `~/.claude/skills`; it does not touch
`settings.json` and has no notion of a hook. The existing precedent for
"settings this skill needs" is `src/reference/setup.md` section 5, which
documents the sandbox network entry as something a person applies by hand. So
the minimum version of this item is: add `src/hooks/`, teach `ship.sh` to carry
it, and document the `PreToolUse` entry in setup.md section 5 beside the network
one. A person still edits `settings.json` themselves, which is consistent with
how the rest of the skill's setup works and is probably right for something that
can block a tool call.

Section 5 carries the network setting as a literal block rather than a
description of one, so this is the block, in the shipped form. It goes in
`~/.claude/settings.json` under `hooks.PreToolUse`, as a **second entry with
matcher `Bash`** — the existing one runs `gate-unsandboxed-bash.sh` and both
fire; do not merge them into one matcher unless you want them ordered:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash ~/.claude/skills/maestro-remote-mac/hooks/gate-journey-first.sh"
    }
  ]
}
```

`bash <path>` rather than the path alone is deliberate and matches the
neighbouring entry: the sandbox refuses `chmod +x` under `~/.claude`, so the
script cannot be relied on to carry its exec bit.

Until the skill can ship it, the same block with the interim path
`bash ~/.claude/hooks/gate-journey-first.sh` turns the draft on today. Switching
later is repointing that one string — which is the whole reason the standalone
route is cheap to reverse, and worth saying out loud when weighing the two
options below.

**The cost, stated plainly.** The skill is shared across every project that
drives a Mac. A behavioural gate inside it is imposed on everyone who installs
it, not only on the machine that wanted it. If that is not acceptable, the
alternative is to leave the hook standalone in `~/.claude/hooks/` — which keeps
it personal, at the price of it outliving the skill it polices and running on
every Bash call in projects that have no `driver.sh` at all. Decide that before
building either.

Sharper variant, if one bump per session turns out to be too soft: key the
marker on the command text rather than the session, so every distinct
coordinate call gets its own bump.

Related: item 49 (the same failure, addressed with prose rather than
enforcement — this item exists because that may not be enough) and item 17
(edits made directly in `build/`, which is exactly what shipping a hook from
`src/` avoids).

---

## 52. A project has nowhere to put a finding that is not about its app — **DONE 11 Sep (guidance + near-miss warning shipped 11 Sep; `notes.sh promote` staging added 11 Sep)**

**Session M.** `reference/app-notes-template.md` is explicit, twice, that
anything true of Maestro or iOS generally stays out of a project's notes and
belongs in the skill's `reference/`. It gives no way to do that, and the result
is measurable: an audit of `brandco-flutter-runner/maestro/app-notes.md` on
4 Sep found **three whole sections, 16KB, that fail the template's own test** and
had sat there for three weeks.

| section | what it actually is |
| --- | --- |
| `### The cause: MaterialApp.router` | a Flutter framework bug — flutter/flutter#100946, reproduced in 60 lines with no app code, with the repro living in this repo's own `flutter-router-dropdown-repro/` |
| `### Ruled out — do not spend time on these again` | Maestro is not the source; `snapshotKeyHonorModalViews` does not touch it; `setOrientation` cannot test it. Three of its four bullets are about the driver, not the app |
| `## Driving the physical iPhone` | 56 lines of code-signing, usbmux forwarding and Maestro 2.8.0 flags. It **opens by saying it will go stale and pointing at `src/physical-device.md`**, which is where it should be |

The `Driving the physical iPhone` section was put there by session `480adcc1` on
21 Aug — deliberately, and with that staleness caveat — because there was nowhere
else, which is this item seen at the moment of creation rather than three weeks
later.

None of that is a mistake by whoever wrote it. There was nowhere else: the
project's notes are the only file in reach, `~/.claude/skills/maestro-remote-mac`
is a symlink into `build/` and anything written there is thrown away by the next
ship (item 17), and nothing in `SKILL.md` says what to do instead. So the
material goes where the writing is happening and stays there.

**The cost is not tidiness.** The app notes are read at the start of every
session — step 3 of "Start of session, in order". That file had reached 168KB
before this audit, about 42k tokens, and it does not get read. Every finding in
it competes with every other, and the ones that are not about the app are pure
dilution of the ones that are. The user's words on opening the audit: "No wonder
you keep missing things — I too would refuse to read all of that."

**What is wanted.** Two halves, and the first is worth having on its own:

1. **Say what to do.** One paragraph in `SKILL.md` beside "Keep the app notes",
   and a line in the template: when a finding would still be true of a different
   app, write it in the project as `tooling-findings.md` and say so, rather than
   filing it under an app heading. That needs no code and is where session M left
   `brandco-flutter-runner` — the three sections are now in
   `maestro/tooling-findings.md`, with a pointer stub at each old site so the
   cross-references still resolve.

2. **Give it somewhere to go.** A `bin/notes.sh promote <file>` that copies a
   project's `tooling-findings.md` into a staging path in the *source* repo — not
   `build/` — for a person to fold into `reference/` and ship. The skill is
   deliberately not edited from a project session (a standing instruction, and
   the reason is item 17's: a fix that suits one app's quirks silently changes
   how every other project's journeys resolve). A staging path keeps that true
   while stopping the material rotting in a project.

**A fourth candidate, not moved.** `## The first-run dropdowns do not filter and
typing selects nothing` reads like a general Flutter `DropdownMenu` finding and
is not one: the behaviour splits on `isSearchable:`, which is that app's own
argument at two of four call sites. It stays. The test is not "does it mention
Flutter" but "would it still be true of a different app".

**Also worth knowing, from the same audit.** `bin/notes.sh add` matches its
section by case-insensitive substring and starts a new one when nothing matches.
That is the documented behaviour and it is the right default, but over three
weeks it produced four one- and two-note stub sections in that file — `accept
race`, `how the app reports itself`, `iPad coordinate transform`, `store/PIN
screen` — each of which duplicated a heading that was already there. Every one
was a near miss on an existing section. A one-line warning when a new section is
created, naming the closest existing heading, would have caught all four at the
moment of writing. Small enough to fold into this item rather than raise
separately.

**A second audit the same session found the deeper cause: the docs describe a
different application.** Every handover document describes build `1.0.0-uat`
(July); `development` is `2.0.1+38` and `release/v3.x` is `3.0.0+41`, two major
versions on, and 38% of the directory's prose (1,072 of 2,789 lines) is about the
superseded build. So "nowhere to put a non-app finding" is compounded by "nothing
retires an app-version's worth of notes when the app moves on" — the
`bin/notes.sh promote`/staging idea wants a retirement counterpart, or at least
the template should tie each note to the build it was measured on (item 16), so
version drift is visible rather than buried. Care needed, though: the same audit
proved most "old-version" material is structural and still true (no accessibility
ids, `MaterialApp.router`, `isSearchable`) — a version number does not expire a
finding whose cause is unchanged, so retirement has to be by re-check, not by date.

**And it recurred after being flagged — session `07f380e8`, 1 Sep.** A week after
`5827cb0e` was told app-notes is "not a log of failing test case", this session put
**code-bug findings into `app-notes.md` under "Known test data"**: the cause of a
wrong product prefix (`fe_add_request_item.dart:76/:90` calling `getLanguage()`
without `await`, so `locale.toString()` is the literal `Instance of 'Future…'`) and
an EAN-row value discrepancy between PDP and request detail — both source-read bug
findings, not driving measurements. (The store-4003 users/locations/search-results
it also added are legitimate "Known test data".) So the correction did not stick
across sessions — the same argument as item 56: a one-time flag does not change the
behaviour; the guidance has to be in `SKILL.md`/the template, which is this item's
fix. Note the distinction this sharpens: app-notes is for *how to drive* the app
(measurements), not *what is wrong with* it (bugs) — the bug findings want a
`test-findings`/bug home, the general ones `tooling-findings.md`.

**Caught live and earlier — session `5827cb0e`, 25 Aug.** Item 52's mechanism a
week and a half before the Session M audit found the accumulation. Mid test-script
run, the session wrote a **failing-test-case behaviour finding into
`maestro/app-notes.md`**, and the user flagged it in the moment: *"Why has that
previous note gone into the maestro app notes? That's for running the app through
maestro, not a log of failing test case."* The session agreed — *"that file is for
what's been measured about driving the app, not for behaviour findings"* — and
removed it. So the pollution is not just historical drift an audit later catches;
it happens continuously, in real time, because a live run generates
behaviour/test findings and the only file in reach is the app notes. This is the
strongest argument for the `tooling-findings.md` split (and a `test-findings`
home): the writer reaches for app-notes at the moment of the finding, not later.

Related: item 17 (`build/` is not unmistakable from the inside, which is half of
why there is nowhere to write), item 49 (`SKILL.md` prose that is read before the
screen is on the table — the same class of problem, opposite direction; and the
`5827cb0e` new-journey instance there is the same session as this app-notes one).

**Half 1 + the fold-in done 11 Sep, in `src/`, shipped 11 Sep.** The guidance
half — the one the item says is worth having on its own — is in `SKILL.md`'s
"Keep the app notes" and in the template's "What stays out": a finding that would
still be true of a different app goes in the project's `maestro/tooling-findings.md`,
not under an app heading; a finding about what is *wrong* with the app (a bug) is
not a driving measurement and goes in the project's bug/test findings; the test is
"would this still be true of another app". This is prose in `SKILL.md`/the
template, which is exactly where the recurring instances (`07f380e8`, `5827cb0e`)
showed the fix has to live — a one-time flag did not stick. The near-miss fold-in
is built: `notes_add.py` now fuzzy-matches a new section against the existing
headings (case-insensitive, cutoff 0.6) and warns naming the closest, catching the
four stub near-misses at the moment of writing. Two offline tests (a near-miss
warns and names the heading; an unrelated section does not); suite 208 → 210.

**Still open.** Half 2 — `bin/notes.sh promote <file>`, staging a project's
`tooling-findings.md` into the *source* repo (not `build/`) for a person to fold
into `reference/` and ship — is not built; it needs a staging path a sandboxed
project session can actually reach, which wants deciding alongside item 17. And
the version-retirement counterpart (notes drift when the app moves two major
versions on) is untouched — and per the same audit it must be retirement by
re-check, not by date, since most "old-version" material is structural and still
true.

## 53. The resolver does not account for the predictive-text / QuickType bar — **DONE 11 Sep**

**Session `90833915`, 14 Aug 2026**, driving the iPhone 16 Pro simulator on
`brandco-flutter-runner`'s Select Device Location field. Repeated taps aimed at a
list row landed wrong, and the session's own words were *"Predictive text is
stealing the taps."* The iOS QuickType suggestion strip sits above the keyboard,
is drawn by the system rather than the app, and — like the status bar and the
keyboard in items 8, 9 and 30 — is not something `resolve.py` reasons about. When
it is present it can occupy or intercept the band a row or field beneath it
resolves to, so a correct app-space coordinate still hits the wrong thing.

**Observed once and not confirmed since**, so this is `seen once` in the sense
item 16 defines. It may turn out to be the same keyboard-band geometry seen from
a different angle (items 30, 35), or a genuinely separate overlay — the session
gave up on the field rather than diagnose it (see item 14), so the mechanism was
never pinned down.

**Fix, roughly.** Establish first whether the suggestion bar appears as its own
node in the tree (as the keyboard and `SystemInputAssistantView` do) or is
invisible to it. If it is in the tree, `system_transform` / `keyboard_geometry`
should take its band the way they already take the keyboard's, and a tap
resolving under it should be refused with the covering node named — the item 9
treatment. If it is invisible, the refusal cannot be automatic and the rule
belongs in `reference/driving.md` instead: turn the QuickType bar off for
driving, or dismiss it before tapping near it. One clean reproduction on a
searchable field with the suggestion bar up would settle which.

**Item 43 is a strong hint it is the first case.** `peek.sh` in the
`handover-maestro` handover already skips "the typing-prediction bar" as a known
element type, so the bar does appear in the tree and the resolver can see its
band — which points at the item 9 treatment (refuse the tap, name the covering
node) as the likely fix rather than a prose rule.

**Second sighting, on the physical XS Max — session `480adcc1`, 21 Aug.** Tapping
the `LOC1` row, which resolved to y=564 (under the keyboard), typed "The" into the
field — the tap landed on the predictive bar, exactly as on 14 Aug. Same
mechanism, different device, so it is not simulator-specific.

Related: items 8 and 9 (system-drawn nodes and occlusion refusals), 30 and 35
(keyboard-band geometry), 43 (`peek.sh` already treats the typing-prediction bar
as a filterable node type), and 14 (the field where this surfaced, and where the
value was abandoned rather than committed).

## 54. Reading persisted prefs is a multi-step gotcha with no helper — **DONE 11 Sep**

**Session `90833915`, 14 Aug 2026.** Reading the app's idle-clock keys out of
`NSUserDefaults` — the direct, non-inferred measurement this skill prefers — took
two non-obvious steps that are nowhere in the skill and had to be re-derived live:

- **`defaults` cannot see the app's domain.** `defaults read` on the container
  domain returned nothing; the plist had to be read as a file straight out of the
  data container instead (`simctl get_app_container` on a simulator, the container
  path on a device).
- **iOS flushes `NSUserDefaults` lazily**, so freshly-written keys are not on disk
  when you read them. The app has to be backgrounded first
  (`driver.sh button home`) to force the flush — otherwise the read comes back
  missing keys that are really there, which reads as a bug in the app rather than
  a timing artefact of the measurement.

Both were worked out from scratch here, and the same read was used minutes later
on the physical iPhone (item 45), so it is a cross-device technique, not a
simulator quirk.

**Fix.** A `bin/prefs.sh <app-id> [key]` — or, at least, a documented recipe in
`reference/driving.md` — that backgrounds the app to flush, locates the container
on either a simulator or a device, reads the plist as a file, and prints the
`flutter.*` keys. It is the read-side counterpart to the driving verbs, and the
one measurement the skill leans on most for verification, so a rediscovery every
time it is needed is expensive out of proportion to its size.

One caught detail for the helper: the `devicectl device copy from` syntax is easy
to get wrong — the first attempt to pull the plist off the phone failed with
`Error: Unknown option '--username'` and had to be corrected. A helper that owns
the exact `devicectl` invocation removes that trial-and-error too.

Related: item 45 (the same read works on hardware via `devicectl`) and item 31
(`typed.py` reading back what landed — the other place the skill checks state
rather than assuming it).

## 55. The shipped docs mirror is stale and actively wrong about physical iOS — **rule 9 SHIPPED 10 Sep; docs-mirror known-wrong list BUILT IN src/ 11 Sep, shipped 11 Sep**

**Session `480adcc1`, 21 Aug.** The skill ships a Maestro docs mirror under
`docs/pages` (2.8.0, taken 11 Aug). On physical iOS it flatly contradicts the
binary it ships beside: `supported-platform__ios__uikit.md` says "Executing tests
on physical iOS devices is not supported yet", while `maestro --device <udid>
hierarchy` on the same Mac builds a device driver and drives the phone. The
`--apple-team-id` flag the device path needs is listed only under `record`, and
is a hidden option on the commands that actually use it (`hierarchy`, `test`).

**The cost is not the staleness, it is being believed.** Twice the session
declared physical driving impossible on the docs' authority — "Maestro genuinely
can't drive it", "iOS: full support for simulators" — and both times the user had
to push back (*"I've seen other people do it with maestro"*, *"let me test it
rather than quote the docs"*) before it was tested and worked. A shipped
reference that is wrong in the confident direction (says *no* when the answer is
*yes*) is worse than an absent one: it ends investigations that would otherwise
succeed.

**Fix.** `bin/docs-check.sh` already watches the Maestro version (item 45 leans
on it for the re-signing workaround). It should also carry a short, maintained
list of *known-wrong* mirror claims for the pinned version — starting with the
physical-iOS support line — and surface them when the docs are consulted, or at
least a `reference/` note that the mirror predates device support and the CLI's
own `--help` is the authority. The deeper option is to stop shipping a mirror
that goes stale silently, but the near-term fix is to stop it being trusted
blind.

**Ship as a `SKILL.md` rule (9 Sep).** Beyond fixing the docs: *test a capability
on the device before reporting it impossible.* Twice this session declared
physical driving unsupported on the mirror's authority and was wrong. The rule
that would have prevented it — the shipped docs and the skill's own assumptions
are not authority over an empirical test on the connected device — is skill-usage
conduct and must ship in "The rules that matter most", not sit in a per-machine
retrospective that never reaches the next project.

**Proposed `SKILL.md` wording (9 Sep) — a new rule 9:**
> 9. **Test before you report a capability impossible.** The shipped docs mirror
>    and the skill's own assumptions are not authority over an empirical test on
>    the connected device. The mirror said iOS physical devices are unsupported;
>    the binary drove one. Before telling the user something cannot be done, try
>    it on the device and report what happened.

Related: item 45 (the device path the docs deny exists) and item 16 (a written
claim trusted long after it stopped being true — same shape, in the skill's own
shipped docs rather than a project's notes).

**Docs-mirror half done 11 Sep, in `src/`, shipped 11 Sep.** `bin/docs-check.sh`
now carries a maintained known-wrong list for the pinned mirror version and prints
it (even under `--quiet`, since being surfaced is the point) — starting with the
physical-iOS denial and the hidden `--apple-team-id` flag, each naming
`maestro <cmd> --help` as the authority and pointing at `physical-device.md`. It
is gated on `MAESTRO_VERSION`, so a `docs-refresh.sh` to a new mirror drops
corrections that may no longer apply. `preflight.sh` already runs `docs-check.sh`
at session start, so the list surfaces where the wrong claim was believed. Two
offline tests (the physical-iOS denial is surfaced; the list is gated off for a
different version); suite 210 → 212. Rule 9 (shipped 10 Sep) is the conduct half;
this is the mirror half. Left undone deliberately: not shipping a silently-stale
mirror at all is the deeper fix, out of scope here.

## 56. Skill-usage lessons land in project memory and `reference/`, where the next repo never sees them — **BUILT AND SHIPPED 10 Sep (rule 3 extension + item 51 hook + new `reference/driving-discipline.md` home for skill-usage conduct)**

The maestro skill is global to any Flutter repo, but the discipline for *using* it
keeps being written where it cannot travel:

- **Session `0598a4b6` (21 Aug) wrote `driving_the_app_wasted_time.md` into the
  brandco project's memory** — screenshots used to find elements, one round trip
  per tap, coordinates carried across a moving screen, hand arithmetic instead of
  `find`. Good lessons, wrong home: a different Flutter repo starts without any of
  them. Several also merely *repeat* rules that already ship in
  `reference/driving.md` (screenshots ranked fourth; the round trip is the unit of
  cost) — so the rules exist and were not read, because they sit in a reference
  file rather than in the five "rules that matter most" that get read first.
- Same shape as items 49 and 52 from other angles: the knowledge exists, but not
  in the place consulted at the moment it is needed.

**Fix, two parts.** Promote the load-bearing driving-discipline rules into
`SKILL.md`'s "The rules that matter most" — *screenshots are for appearance only,
never for locating a node; batch a sequence into one round trip; resolve and tap
in the same call, never across calls on a screen that can move* — so they are read
before the first tap. And give skill-usage conduct a home *in the skill* (a short
`reference/driving-discipline.md`, or a `SKILL.md` section), so a lesson learnt in
one repo ships to the next instead of being saved to that repo's memory. General
conduct that is not about maestro (stopping mid-task for acknowledgement, say)
still goes to the machine retrospective — this item is only the skill-usage half.

**The decisive evidence that memory is the wrong home — session `a4d6c149`
(Session L), 4 Sep.** That session hand-walked the login by hand again, then
checked why: two behaviour memories — `driving_the_app_wasted_time` and
`run_app_via_skill_and_prior_work` — were **loaded into its context at session
start and it hard-walked anyway**. Its own words: the new memory it had just
written "is a third copy of an instruction that has now lost twice… I would not
expect it to change the behaviour on its own", and the fix belongs "to item 49's
fix rather than to memory — the skill text is the thing I read immediately before
driving, which memory is not." There are now **three** such behaviour memories in
the brandco project alone (`driving_the_app_wasted_time`,
`coordinate_stabbing_is_a_repeat_offence`, `run_app_via_skill_and_prior_work`),
none of which travels or fires at the right moment. This is the case for this item
made from the inside. Item 51's `PreToolUse` hook (drafted in the same session) is
the *enforcement* half of the same idea — a rule that blocks a raw `tap` and names
the journey — so 51 and this item are two halves of "make the skill carry and
enforce its own driving discipline", not two separate wishes.

**Proposed `SKILL.md` changes (9 Sep).** Most of this item's rules already exist
in "The rules that matter most" and simply were not read — rule 1 (batch /
journey-first), rule 7 (screenshots for appearance only, never to locate a node).
The one genuinely missing piece is *resolve-and-tap in one call*, which belongs as
an extension to rule 3:
> 3. **Do not trust reported bounds — and do not carry a coordinate across
>    calls.** …A form shifts 80–140 points when a keyboard opens or a menu closes,
>    so a coordinate read in one call and tapped in the next lands on nothing.
>    Resolve and tap in the same call.
So this item is mostly satisfied by those rules being in that section (they are)
plus item 51's hook enforcing them; the only new prose is the rule-3 extension.

**The repeat was already loud on 21 Aug — session `e5bdd72b`.** A UI-fix
verification blind-tapped an iPad three times before recovering with `find
--explain`, and the user's reaction names the recurrence directly: *"Have you
ignored all past instructions about how to find elements? AGAIN?"* The session
conceded it — *"You're right, and this is the same mistake"* — and its fix was to
correct a note and (elsewhere in the same session) write yet another memory. That
is this item in miniature two weeks before Session L made the case from the
inside: the instruction to resolve-not-stab already existed, the behaviour
repeated anyway, and the response was another note/memory rather than a change to
the thing read immediately before driving. `coordinate_stabbing_is_a_repeat_offence`
is named for exactly this.

**But it can also self-catch — session `065a39b2`, 4 Sep (the positive data
point).** Stalled on a Language dropdown that would not expand, the session reached
for a screenshot to see it — then caught itself: *"I stalled on the Language
dropdown (tapped it, tree showed no rows expanding) and reached for a screenshot to
see it visually instead of just retrying the tap. That's the wrong tool here per the
skill's own rule — screenshots are for appearance, not locating."* Rule 7 (screenshots
for appearance only, never to locate a node) fired in the model's own head and
corrected the move. Kept as evidence the rules work when they surface at the moment
of the action — which is the whole argument for putting them where they are read
just before driving (this item and item 51's hook) rather than in memory.

Related: item 49 (the journey is the unit of work — the same "use what already
exists" problem), item 51 (the hook that would enforce this), item 52 (a project
has nowhere to put a non-app finding), item 14 (the finding whose correction
stayed in the notes and was re-derived), and item 19 (the contradictory note that
licensed the stabbing in `e5bdd72b`).

## 57. The shipped docs give contradictory iPad-tap guidance and never steer the operator to `tapon` — **DOCS RECONCILED + operator rule ADDED IN src/ 11 Sep; step-1 test MEASURED 11 Sep (hand-transform is wrong); shipped 11 Sep**

Two sibling iPad reviews on 19 Aug (`d32077c5`, `2696b9ae`) both drove the iPad
Pro 11-inch by hand-computed `device_x = 834 - app_y` on raw `driver.sh tap`, and
both got unreliable results — it worked in `d32077c5`, and in `2696b9ae` the
hand-converted `tap 599 962` **did nothing on two attempts** while `tapon
"4001-55368"` opened the same card first time. `tapon` is reliable on the iPad in
landscape (item 8's transform, applied inside the resolver); raw `tap` with a
hand-rolled transform is the footgun. Neither operator reached for `tapon` first
on the iPad — they reached for coordinate arithmetic — and the skill's own docs
are why.

**The docs contradict each other on this exact point, and the misleading one is
the app-facing note an operator reads.**

- `reference/driver-api.md:181-184`, sourced from the driver's Swift, is correct:
  *"`/touch` coordinates are portrait-referenced. The handler passes them through
  `ScreenSizeHelper.orientationAwarePoint`, which is the identity in portrait and
  rotates the point itself in landscape. Send portrait coordinates whatever the
  device is doing."* So the driver already rotates; you send app-space (portrait)
  coordinates and do **not** hand-apply `834 - app_y`.
- `reference/apps/example-app.md:53` says the opposite: *"the app is
  landscape-locked at 1194x834 while taps go to the device in portrait, so
  `device_x = 834 - app_y`, `device_y = app_x`."* This tells the operator to
  hand-transform — which, on top of the driver's own rotation, is a double
  transform, the most likely reason `2696b9ae`'s hand-converted raw tap missed
  twice (**hypothesis, not yet measured**).

There is also nothing anywhere that says *prefer `tapon` on the iPad; only fall
back to raw `tap` when a node has no tree entry (the nav rail, item 26)*. The
resolver does the transform correctly and the operator should lean on it, but no
rule says so, so both sessions hand-rolled instead.

**Approximate resolution.**

1. **A one-tap confirming test first**, to settle the hypothesis before any
   wording is changed: on a `landscapeLeft` iPad, `driver.sh tap <app_x> <app_y>`
   with app-space/portrait coordinates (no hand-transform) versus the hand-rolled
   `834 - app_y` point, and see which lands. That decides whether `example-app.md`
   is simply wrong or right only when the driver's orientation was never set to
   landscape.
2. **Reconcile the two docs.** Correct or annotate `example-app.md:53` so it no
   longer tells the operator to hand-transform against a driver that already
   rotates — or, if the test shows the hand-transform is right in some state,
   name that state precisely. Point it at `driver-api.md:181-184` as the
   authority.
3. **Add the operator rule to the skill** (per item 56's "give skill-usage
   conduct a home in the skill" — this is a concrete instance of it): *on the
   iPad, resolve and tap with `tapon`; the resolver applies the landscape
   transform. Only raw-tap a node the tree cannot reach (the nav rail, item 26),
   and then send app-space coordinates, not a hand-rolled `834 - app_y`.* This is
   the iPad-specific companion to item 51's hook, which already blocks a raw `tap`
   and names the journey.

Related: item 8 (the resolver transform this relies on — DONE, and confirmed in
landscape by `2696b9ae`), item 26 (the nav rail, the one place raw coordinates are
still unavoidable), item 51 (the hook that blocks a raw `tap`), item 56 (skill-usage
conduct belongs in the skill, of which this is one concrete rule).

**Done 11 Sep (steps 2 and 3), in `src/`, shipped 11 Sep.** On the authority of
`driver-api.md` (Swift-sourced: the driver rotates portrait coordinates itself in
landscape), without waiting on step 1's live test:

- `reference/apps/example-app.md:53` — the day-1 iPad clause is left in place (the
  file's convention is to append dated corrections, not rewrite a measured note)
  and flagged, with a following correction bullet that says the driver already
  rotates, so `tapon` sends the right point and hand-applying `834 - app_y`
  double-transforms; it names the raw mapping as device-space-only and points at
  `driver-api.md`.
- `SKILL.md` rule 3 — a terse iPad clause: the resolver applies the landscape
  transform, so `tapon` on the iPad; only raw-`tap` an unreachable node (the nav
  rail), and then in app-space, never a hand-rolled `834 - app_y`.
- `reference/driving-discipline.md` — the fuller standing lesson, with the
  `2696b9ae` evidence.

**Step 1 measured 11 Sep — the hand-transform is wrong.** Booted the `iPad Pro
(11-inch) (3rd generation)` simulator (`546ECD7F…`), `driver.sh orient
landscapeLeft` (device and tree both report 1194x834), launched Settings, and
A/B'd a raw `tap` at the Privacy sidebar row, relaunching to a General baseline
before each:

- **resolver/app-space point (207,431)** — selection moved to Privacy. Lands.
- **hand-rolled `device_x = 834 - app_y`, `device_y = app_x` → (403,207)** —
  selection stayed on General. Misses.

`find --explain` showed the true transform is `scale 1 offset -360,0` — a pure
offset (the landscape sidebar is inset 360px), **no rotation term**. So on a
`landscapeLeft` iPad the driver wants app-space coordinates, which is exactly
what `tapon`/the resolver send; the `834 - app_y` rotation is a spurious extra
transform and lands nowhere. This confirms `driver-api.md` empirically and
settles the reword: `example-app.md`'s hand-transform is simply wrong once the
device is in the orientation the app is showing.

Not reproduced: portrait-device + landscape-locked app (brandco's original
state), which needs the brandco app rather than Settings. The operator rule
makes that corner moot — set the device to the app's orientation (`orient
landscapeLeft`) and `tapon`, never hand-arithmetic — so it is not worth a
brandco build to chase. Shipped 11 Sep with the P11/P10 batch.

## 58. Device verification has no clean way to force a timed state, and nothing says to read the app's supported orientations first — **DONE 11 Sep**

Two foot-guns from session `e5bdd72b` (21 Aug), a UI-fix verification of the
idle-logout modal across three simulators. Both cost time, and both are the
skill's to prevent.

**(a) Forcing a timed state by fudging the app source races the driver's own
latency.** To photograph the 30-second idle-logout modal without waiting for it,
the session edited `resolveIdleThreshold` to `Duration(seconds: 45)` in the app
source on the Mac. 45 s did not survive the round-trip latency of driving — the
modal came due about 15 s into the session and the shot was missed — then the
fudge had to be reverted and all three simulators rebuilt from clean source.

*Approximate resolution.* Prefer a config override to a source patch: the app
already reads its idle timeout from Remote Config (`idle_logout_timeout_minutes`,
the value item 24 notes was left at the test setting of 2), so a timed state
should be forced through config, not by editing `lib/`. Where only a source
change works, the skill should warn that the value must leave headroom for
driving latency, and that a fudged build must be rebuilt from clean source before
any real verification. A `driving.md` note, or better a helper that sets and
restores a Remote Config value around a verification.

**(b) Nothing tells the operator to read the app's supported orientations before
driving an iPad.** The session asked the user which orientation to photograph,
then discovered from `Info.plist` that `UISupportedInterfaceOrientations~ipad` is
`LandscapeLeft`/`LandscapeRight` only — there is no portrait iPad layout — after
switching between two iPads chasing a portrait layout that cannot exist (the newer
iPad letterboxed the landscape-locked app, making its coordinates worse).

*Approximate resolution.* Add to the start-of-session / iPad guidance: read the
target app's `UISupportedInterfaceOrientations~ipad` before choosing an
orientation or a device, so a landscape-locked app is known to be landscape-locked
before any driving. `init.sh --host <alias> --detect` already reads installed
apps; it could read this too and record it in the conf or app-notes.

Related: items 8, 26, 57 (iPad orientation and taps), item 24 (the Remote Config
test values, and the rebuild/worktree cost a source fudge incurs).

## 59. Home-directory dotfiles keep surfacing at the repo root during driven sessions — **DONE 11 Sep (cause unknown; documented hazard and gitignore list in driving.md)**

Two review sessions independently flagged the same thing: untracked
home-directory files appearing at the root of the `brandco-flutter-runner`
checkout that nobody wrote as part of the work. `d32077c5` (19 Aug): *".bashrc,
.zshrc, .profile, .gitconfig, .bash_profile, an empty .gitmodules, and .idea …
they weren't there at the start of this session … something wrote a home
directory into the working tree."* `de240800` (20 Aug) saw the same set plus
`.mcp.json`, and warned that `git add .` would commit them and `git commit -a`
would sweep them in with real changes.

**Why it matters here.** It is a live footgun in exactly the workflow these
reviews run: a branch review that stages by hand is one `git add .` away from
committing a pile of dotfiles into the PR branch. Both sessions had to notice
and route around it.

**Cause not established — flagged for investigation, may not be maestro.** The
files look like `$HOME` contents surfacing in the working directory. Candidate
causes to check: the sandbox mounting or seeding `$HOME` into the cwd; a GSD or
harness step; something in the git-bundle-to-Mac / `mac.sh` path; or an IDE/tool
(`.idea`, `.mcp.json`) writing into the project. If it turns out to be the
sandbox/harness rather than the maestro toolkit, this moves to the machine notes
— logged here because it recurs in maestro-driven reviews and had no home.

**Approximate resolution.** First identify what writes them (diff the checkout
before and after a session start). Then either stop the writer, or — as a cheap
guard that helps regardless of cause — add these names to the project's
`.gitignore` (or a global gitignore) so a hand-staged review can never commit
them, and note the hazard in the review-branch skill's "stage only named files"
step.

## 61. Sessions restart the app instead of reading the hierarchy — **DONE 14 Sep**

When a journey fails or the screen is in an unexpected state, sessions
immediately restart the app rather than reading the hierarchy to understand
what state they are in. The hierarchy already carries the field values,
placeholders, and layout — enough to decide whether to use a different
journey, dismiss a keyboard, or tap what is already on screen. Restarting
discards state that was already correct (e.g. a store already remembered
from a previous login) and costs 30–60 seconds each time.

Observed 14 Sep 2026: a login set the store, then `01-device-setup` failed
because the location list had changed. Instead of reading the hierarchy —
which showed the location field was already empty and the store was already
set — the session relaunched the app, lost the stored store, and then
failed the login journey because `Select Store` was gone. Two unnecessary
restarts before anything was driven.

**Fix.** New rule 8 in SKILL.md ("Never restart the app in response to a
failure") and a standing lesson in `reference/driving-discipline.md` with
the 14 Sep incident as evidence.

## 60. `erase` deletes backwards from the caret, so it cannot reliably clear a field — **DONE 11 Sep**

**Session J (`213647e3`), 3 Sep.** Fixing PROJ-1804, a journey needed to replace
the text in a field. F36: *"Erasing the field first does not work, so I forked the
unit rather than patch it. `erase` deletes backwards from the caret."* `erase`
issues backspaces from the current caret position, so it only clears what is behind
the caret — if the caret is not at the end of the field, or the field holds text the
step did not itself type, some is left, and the following `text` appends to the
remainder instead of replacing it. The failure is silent in the usual way: the step
reports fine and the field ends up with the wrong value.

The cost here was a **journey fork** — rather than a clear-then-type that works, the
session forked the unit to avoid the field-clear, which is item 49's fork-instead-of-fix
one layer down and driven by a real toolkit gap rather than by not looking.

**Approximate resolution.** Give `erase` a whole-field mode: select-all then delete
(the driver can send a select-all before the backspaces), or an `erase --all` that
moves the caret to the end first and deletes the field's measured length. A
`text --replace` that clears then types would cover the common case in one verb.
Until then, the journey-authoring note should say `erase` clears only from the caret
back, and give the working sequence for a full replace.

Related: item 49 (the fork this caused), item 31 (`typed.py` passing when text
landed somewhere other than the field — the same "text ended up wrong and nothing
said so" family).

---

## 62. relay.py connects upstream to `::1` (IPv6) but Maestro binds IPv4 only — **DONE**

`src/remote/relay.py` lines 38 and 55 used `("::1", rport)` for
`socket.create_connection`. The Maestro XCUITest driver binds to `127.0.0.1`
(IPv4 loopback only), so every upstream connect failed silently — `curl` from
the LAN got "Bad Gateway" and `curl http://localhost:<port>/status` on the Mac
returned empty. Changed both calls to `("127.0.0.1", rport)`.

Reported by the brandco-flutter-runner-34 session, which had been working
around it with a patched `relay-fixed.py` in `/tmp/maestro-mac/` (lost to
reboot).

---

## 63. Xcode 27's `lipo -verify_arch` fails with multiple architectures — **DONE**

`lipo -verify_arch arm64 x86_64` returns exit 1 on a valid fat binary under
Xcode 27 (macOS 27). Each architecture passes individually; only the multi-arch
call fails. Flutter's `debug_unpack_ios` target in `darwin.dart` calls
`lipo -verify_arch ...archList` with all requested architectures in one
invocation, so every `--simulator` build that requests both `arm64` and `x86_64`
fails — which is all of them, because `defaultIOSArchsForEnvironment` hardcodes
`[x86_64, arm64]` for `EnvironmentType.simulator`.

DEV appeared unaffected because its `debug_unpack_ios` output was cached from a
pre-Xcode-27 build; UAT's cache was stale (from April) and triggered a fresh
unpack. Both flavours would have failed on the next `flutter clean`.

**Fix.** `remote/build.sh` now exports `FLUTTER_XCODE_ARCHS=arm64` on Apple
Silicon Macs before the `flutter build ios --simulator` call. This flows through
`xcode_backend.dart` line 641 → `-dIosArchs=arm64` → `debug_unpack_ios`, so
`lipo -verify_arch` receives a single architecture and passes. x86_64 simulator
support is only needed on Intel Macs, which this is not.

Also cleared stale Swift precompiled modules (`DerivedData/Runner-*`) and ran
`pod install` — a second, unrelated consequence of the Xcode 27 upgrade, where
FirebaseAnalytics was compiled with Swift 6.0.3 (Xcode 16) and the new
toolchain has Swift 6.4.

Measured 15 Sep 2026. UAT simulator build confirmed working (42.1s).

---

## 64. The published viewer URL is a guess, and the page it lands on is idle — **DONE 15 Sep**

Four independent faults, measured this session against `mac-b`. Any one of
them on its own leaves the browser showing nothing, which is why the viewer has
never once worked.

**The port is not 9999.** `maestro mcp --help` says `--viewer-port` "Defaults to
a free local port". The MCP server is launched from `~/.claude/settings.json` as
`ssh … mac-b '… exec maestro mcp'` with no `--viewer-port`, so every session's
viewer lands wherever it lands. Two sessions were live on 15 Sep — pids 40242 and
41110, both plain `maestro mcp` — with viewers on **10001 and 9999**. `config.sh`
pins `VPORT=9999`, so `viewer.sh` republishes whichever session happened to win
that port, which may be a different session's viewer than the one driving.

**The relay is started before the thing it republishes exists.** `SKILL.md` step
1 and `reference/driving.md` both say run `viewer.sh` before anything else. The
viewer binds its port only when a `maestro mcp` server starts. On 15 Sep
`relay.py` was scp'd at 19:41; the JVM that took 9999 started at 19:43:30.
`relay.py`'s `lport == rport` probe found nothing on `127.0.0.1:9999` and exited
1, two minutes before the viewer existed.

**That failure is invisible.** `viewer.sh` launches the relay with
`>/dev/null 2>&1`, so relay.py's "no service on port N to republish — start the
service first" never reaches anyone. `viewer.sh` prints its own text instead,
which recommends `maestro studio --device <udid>` — a command that starts its own
XCUITest runner and destroys the driver `drivers.sh` is holding. The one remedy
it names is the one that breaks the session.

**With two simulators booted the page never starts a device.** The viewer
bundle's auto-start, from the served JS:

```js
let e=(await(await fetch(`/api/device/targets`)).json()).devices||[];
if(e.length!==1)return;
let[t]=e; await l(t);          // l() POSTs /api/device/start
```

Two booted simulators means `devices.length === 2`, an early return, no POST, and
there is no picker UI for the multi-device case — the early return is the whole
path. Both viewers measured at
`{"status":"idle","platform":null,"deviceId":null,"streamUrl":null,"message":null}`.
The screen pane renders only under `status === 'streaming' && streamUrl`, so it
stays blank; the command rows stay empty because no device session exists to emit
`maestro.flow_state`.

**Fix.** Discover the port rather than assuming it — find the live `maestro mcp`
viewers by their listening sockets and publish what is actually there. Bring the
viewer up before the relay, or retry once it appears. Let relay.py's stderr
reach the caller. Replace the `maestro studio` advice, which is actively harmful.
Post `/api/device/start` when `targets` returns more than one device. Most of
this is subsumed by 65, which wants the same discovery step for a different
reason; do 64 inside 65 rather than twice.

---

## 65. Watch every booted simulator at once, from one URL on this host — **DONE 15 Sep**

**What is wanted.** A single URL, bookmarked once on this machine, showing every
booted simulator on the Mac live — ideally all on the same page. No asking a
particular session for a particular URL, and no dependence on which session
happens to be running.

**What the mechanism turns out to be**, established by reading
`maestro-cli-2.8.0.jar` and probing the live servers on 15 Sep:

| fact | evidence |
| --- | --- |
| the stream is MJPEG into the page's `<img src={streamUrl}>` | bundle JS; jar strings `mjpeg`, `x-mixed-replace`, `image/jpeg` |
| it is produced by a bundled native binary, not ffmpeg | `deps/simulator-server/darwin/simulator-server`, 7.8 MB, already extracted at `/Users/dev/.maestro/deps/` |
| nothing needs installing on the Mac | the `libav*` libraries and `LICENSE.ffmpeg` exist only under `simulator-server/linux/` and `windows/`, for the Android `screen-sharing-agent` path |
| the stream is per-`deviceId` and never touches XCUITest | `DeviceStream.start` error strings: "simulator-server exited before announcing stream_ready", "…did not announce stream_ready within 30s", "failed to write input to simulator-server" |
| taps from the browser also go to `simulator-server` | same "failed to write input" string, behind `/api/device/input` |
| the path that *would* destroy a driver is a different one | `McpMaestroSessionManager$createIOSDriver` → `LocalXCTestInstaller`, `XCTestDriverClient`; reached by MCP flow tools, not by `/api/device/start` |
| one viewer JVM holds one device session | `DeviceStreamState` is a single record of `status`/`platform`/`deviceId`/`streamUrl`/`message` |

So the 22087 limit that constrains driving (`drivers.sh` header) does **not**
constrain video. N simulators need N streams, but they do not need N drivers, and
starting a stream should leave `bin/driver.sh` untouched.

An earlier conclusion in this session — that the Mac lacks ffmpeg and that is why
the page is blank — was wrong. `which ffmpeg` was run with
`PATH=/usr/bin:/bin:/usr/sbin:/sbin` and proved nothing; the capture stack ships
inside the jar.

**Still unverified.** `/api/device/start` has never actually been run, so: whether
it succeeds at all; whether it succeeds for a device whose driver is not on 22087;
whether `streamUrl` is a relative path the relay carries or an absolute loopback
URL it cannot; and whether `simulator-server` and a live XCUITest runner contend
over anything while both are attached to one simulator.

**Shape of the fix.** An index server on the Mac on a port chosen once, bound on
the LAN interface, under launchd so it outlives every session. It enumerates
booted simulators, ensures a stream exists per device — either by driving each
live `maestro mcp` viewer's `/api/device/start`, one viewer per device with
`--viewer-port` pinned, or by running `simulator-server` directly and cutting the
viewer out — and renders them together on one page. That page is the bookmark,
and `viewer.sh` becomes a thing that points at it rather than a thing that
guesses a port. Settle the unverified rows above first; they decide which of the
three routes is available.


---

**What was done, 15 Sep.** Both landed in `src/` and are **not yet shipped** —
`./ship.sh` reports nine files changed or new and has not been run.

`bin/wall.sh` + `remote/wall.py` are new. The wall binds a port of its own
(`WALLPORT`, 9990), spawns `~/.maestro/deps/simulator-server ios --id <udid>`
per booted simulator, reads the `stream_ready http://127.0.0.1:<port>/stream.mjpeg`
line each one prints, and re-serves every stream from its own port under
`/device/<udid>/stream.mjpeg`. One upstream connection per device feeds any
number of browsers, because it parses the frames and regenerates the multipart
response per client — so a browser joining late gets the current picture instead
of waiting for the next one. It rescans every 5s, so booting or shutting down a
simulator adds or removes a tile, and a capture process that dies is restarted.

Verified live: three booted simulators, all three streaming, fetched from the
sandbox — `/api/devices` lists all three `live`, and a single stream returned
462 KB in four seconds. The XCUITest drivers on 22087 and 22089 kept the same
pids and went on answering `/deviceInfo` throughout, which is the point: capture
and driving are separate paths.

`bin/viewer.sh` was rewritten rather than deleted. It now discovers the viewer
port instead of assuming 9999 (`viewer.sh list` found the two live viewers on
9999 and 10001), lets `relay.py`'s stderr reach the caller, drops the
`maestro studio` advice that would have destroyed a running driver, and states
that the device picture will be blank from anywhere but the Mac. The viewer's
command rows and device list do cross a relay; only the picture cannot.

**The blocker neither item had found.** Every stream failed with
"simulator-server exited before announcing stream_ready" because Xcode 27,
installed on that Mac at 13:42 on 15 Sep, deleted
`Contents/Developer/Library/PrivateFrameworks/` and moved `SimulatorKit.framework`
to `Contents/SharedFrameworks`. The capture binary has the old path compiled in.
`DEVELOPER_DIR` does not steer it — tested against a full shim Xcode tree with
`xcode-select -p` confirmed to be honouring it. Upgrading Maestro does not fix
it: 2.10.0's copy of the binary is byte-identical to 2.8.0's, same SHA-256.
The maintainer restored the path by hand:

```sh
sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks
sudo ln -s /Applications/Xcode.app/Contents/SharedFrameworks/SimulatorKit.framework \
           /Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/
```

Xcode is an App Store install, so an Xcode update removes the symlink again.
`bin/wall.sh status` checks for exactly this and prints those two commands.

Ten tests were added for the two pieces of `wall.py` that are pure logic — the
MJPEG framer, including a boundary split across two reads, and the booted-device
list. 265 pass, 0 fail.

---

## 66. The wall's tiles say which handset, not what is being driven — **DONE 15 Sep**

Raised by the maintainer the moment the wall worked: with three simulators on one page,
three handset names are not enough to tell which session is doing what, and
several projects on one Mac want separating.

**Not a write endpoint.** "I'm not writing to the wall" — the session that SSHes
to the Mac and drives the simulator is what names it, so the name is a file,
`$RDIR/labels/<udid>`, written over the same connection everything else uses.
The wall reads it on each 5-second scan and stays read-only over HTTP, which
matters because its port is reachable by anyone on the network.

One file per device, not one shared file, so two sessions never collide and
clearing a label is `rm`. `key=value` lines rather than JSON, because these are
written by a shell heredoc through ssh and quoting an apostrophe through two
shells is how that breaks. The file's mtime is the label's age — the page greys
one nobody has touched for an hour, with no expiry field and nothing to sweep.

    ./bin/wall.sh label [<udid>] <name> [--group <g>]
    ./bin/wall.sh unlabel [<udid>]

With no udid it uses whatever `DEV` resolves to. `bin/drivers.sh up` writes a
default — `PROFILE` or `APP_ID` for the name, the project directory for the
group — and will not overwrite a name set by hand; `down` and `down-all` clear
them, since a label describes a driving session and outlives its usefulness the
moment that session stops.

The page groups tiles under a heading per group, ungrouped last and with no
heading at all, so a machine nobody has labelled looks exactly as it did before.
Verified live across three simulators: two named and grouped, one left bare,
with `unlabel` returning a tile to its unnamed state.

Each label also records **who** wrote it: `by=purple · 3fa41c7`, the session
colour from `CLAUDE_SESSION_COLOUR` — the one identifier a person reads at a
glance, because it is what their terminal is already showing — plus seven
characters of `CLAUDE_CODE_SESSION_ID` to break a tie between two sessions
sharing a colour. Outside a Claude session it falls back to `user@host`. The
page shows it under the name with the age, so a wrong name on a shared Mac
points at the session that set it. A label written before the field existed
still reads: its absence is a blank, not a missing key.

Ten more tests, on the label parser, age, staleness and the `by` field. 275 pass.

---

## 68. The wall's tiles were sized for a phone, so an iPad overflowed its card — **DONE 16 Sep**

The maintainer had an iPad on the wall on 16 Sep: *"it's bigger than the box. Everything
should flow nicely."*

**The cause is two rules that do not know about each other**, both in `PAGE` in
`src/remote/wall.py`:

```css
.sim     { ... max-width:340px; }
.sim img { display:block; height:70vh; width:auto; ... }
```

The card is capped at 340px. The image is sized from its *height* and given
`width:auto`, so nothing caps its width at all — it takes whatever its aspect
ratio demands and runs straight out of the card. `box-sizing:border-box` does
not help, because the image is never constrained in the first place.

**The 340px cap is wrong for every device, not just the iPad.** At `height:70vh`
in a 1080px-tall window the image is 756px tall, and the width follows from the
handset:

| device | points | width at 70vh | over the 340px cap by |
| --- | --- | --- | --- |
| iPhone 16 | 393 × 852 | 349px | 9px |
| iPad Pro 11", portrait | 834 × 1194 | 528px | 188px |
| iPad Pro 11", landscape | 1194 × 834 | 1082px | 742px |

A phone overflows by nine pixels, which is why this has never been visible. The
iPad is the same bug with the numbers made obvious. **This was never measured
against anything but a phone** — item 66 was verified live "across three
simulators", all of them handsets.

**What "flow nicely" has to mean.** The tile should size itself to the picture
inside it rather than the picture being asked to fit a number typed in
advance. In practice:

- Cap the image in **both** directions and let the aspect ratio pick the rest —
  `max-height:70vh; max-width:<cap>` with no explicit `width`/`height`, which
  makes the browser scale to whichever limit binds first. A landscape iPad then
  becomes short and wide instead of overflowing.
- Drop the fixed `.sim { max-width:340px }` and let the card shrink-wrap its
  image, so a phone tile stays phone-width and an iPad tile is allowed to be
  wider. `.row` is already `flex-wrap:wrap`, so wider tiles wrap rather than
  squeeze — but the wrapping wants checking with a landscape iPad beside two
  phones, which is the layout that is actually on the Mac now.
- Make the cap relative to the viewport, not a constant, so three tiles still
  fit side by side on a wide screen and one iPad does not take the whole row.
- `.sim .err { max-width:280px }` is the same hardcode in the failure path and
  should move with it, so an error tile and a live tile are not different widths.

**One thing to check while doing it.** An MJPEG stream has no intrinsic size
until its first frame arrives, so a tile may lay out at one size and jump when
the picture appears. Reserving the box up front — the wall already knows the
device model from `simctl` — would stop the page reflowing every time a
simulator comes up. Worth confirming it actually happens before building for it.

**Gates.** None. Pure CSS inside `PAGE` in `src/remote/wall.py`; no behaviour,
no endpoints, nothing on the Mac to restart beyond the usual `bin/wall.sh`.
The existing tests cover the MJPEG framer and the booted-device parser and are
untouched by this — verification is visual, with an iPad and at least two
phones on the wall at once, in both orientations.

---

**Fixed 16 Sep, in `src/remote/wall.py` — three rules and one line of JavaScript.**

The image is now capped in both directions with neither `width` nor `height`
set, so the browser keeps the aspect ratio and scales to whichever cap binds
first — a portrait iPad is height-bound, a landscape one width-bound:

    .sim img { display:block; width:auto; height:auto;
               max-height:var(--tile-h, 70vh); max-width:46vw; }

`.sim`'s `max-width:340px` is gone; the card takes its width from the picture.
For that to hold, the text had to stop contributing to the card's width — a
shrink-to-fit box is as wide as its widest child, so a long label would have
stretched the card past its picture and the ellipsis would never have fired.
`width:0; min-width:100%` on `h3`, `.sub`, `.who` and `.err` keeps them out of
the intrinsic-width calculation and then fills whatever the image settled on.

**The height cap became dynamic, which was not in the item as raised.** With the
overflow gone, three tiles at a flat 70vh still did not fit a 1440px row: the
third wrapped and most of the first row was left empty — the fix for "bigger
than the box" had not delivered "everything flows nicely". `tick()` now sets
`--tile-h` on the container from how many devices are on the page — 70vh up to
two, 46vh up to four, 34vh beyond — and all three sit on one line.

`min-width:260px` is scoped to `.sim:not(:has(img))`. A tile with a picture
takes its width from it; only a tile showing an error needs a floor, and
applying one to every tile left dead card beside a narrow phone at 900px wide.

**Verified by rendering it, not by reading it.** Neither Chrome nor Firefox will
run headless in this sandbox — Chrome dies on `socket() failed: Operation not
permitted` from the process-singleton check, Firefox hangs — so the check ran on
the Mac instead: a throwaway harness served the deployed `wall.py`'s own `PAGE`
on port 8791 with four fake devices (iPhone 393x852, iPad portrait 834x1194,
iPad landscape 1194x834, and an error tile with a long message), and the Mac's
own Chrome screenshotted it headless at 1440x1080 and 900x900.

Both widths: nothing overflows its card, all three live tiles share one row at
1440, they wrap to two rows at 900 with no horizontal scroll, the long label
ellipsises, and the error tile keeps a readable width. The harness, its profile
directory and the screenshots were deleted from the Mac afterwards; the wall was
left running on the fixed `wall.py`.

275 tests pass, unchanged — the suite covers the MJPEG framer, the booted-device
parser and the label reader, and none of them touch `PAGE`.

**Not done: the first-frame reflow.** An MJPEG stream has no intrinsic size until
its first frame arrives, so a tile can lay out narrow and jump when the picture
appears. The item asked to confirm it happens before building for it; with the
harness serving ordinary PNGs it could not be observed, and it was left alone
rather than guessed at.

---

## 71. Three facts about detached work, all learned the hard way, none of them in the skill — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

Item 70 depends on this, and on its own it explains a day of "is it actually
running?".

**(a) `nohup … &` from this side dies with the call.** `connection.md:49` is
right — *"The harness's background mechanism does not keep it alive either"* —
and 21 `nohup` attempts were made across the two days regardless. Re-tested
17 Sep: a `nohup bash -c 'for i in 1..8; do echo tick; sleep 4; done' &` wrote
exactly one tick and the process was gone by the next call. What the reference
does not say is **what to use instead**, so every session found out by having a
watcher die.

**(b) `run_in_background: true` is the mechanism that survives.** Used **88
times** across the two days, against 21 `nohup` attempts, and arrived at by
accident: `97cbdb94` started a watcher with `nohup` at 18:42:56 (one sample,
then nothing), killed it, and only on the third attempt at 18:43:21 used
`run_in_background`, which then ran for the rest of the session. Nothing in
`SKILL.md` or `connection.md` names it.

**(c) `sleep N; <read the log>` is refused by the harness.** Six times over the
two days: *"Blocked: sleep 75 followed by … To wait for a condition, use Monitor
with an until-loop."* So the obvious way to wait for a watcher costs a rejected
call, and sessions fell back to burning turns on `date; cat log`. The skill
should name `Monitor` as the wait, since that is what the harness points at.

**(d) A detached helper cannot find the project conf.** `97cbdb94`'s first
watcher failed with `maestro-remote-mac: not configured for this project —
MAC_HOST=(unset) MAC_FQDN=(unset) APP_ID=(unset)`. `src/bin/config.sh` searches
`$MAESTRO_MAC_CONF`, then from `$PWD` upwards, then `~/` — and a process started
from `$TMPDIR` is nowhere near the project. It had to pass `MAESTRO_MAC_CONF`
by hand on every relaunch thereafter.

**Approximate resolution.** A short block in `reference/connection.md` under
"Every Bash call is a fresh container", stating (a), (b) and (c) as the three
facts with the measurement next to each, plus a line in `SKILL.md` rule 9 —
which currently says *"do not design around anything resident on this side"*
without naming the one mechanism that does persist. And `config.sh` should
record the resolved conf path on each successful run and fall back to it, so
anything the toolkit spawns finds the project without being told.

**Gates.** None. Item 70 depends on it.

**Done 17 Sep, in `src/`.** Four changes, all tested, none shipped —
`build/` still carries the old copy until someone runs `ship.sh`.

- `reference/connection.md` gains *"What to use instead, when something
  genuinely has to outlive the call"* under the fresh-container section: `nohup`
  dies (re-tested 17 Sep — one tick written, process gone by the next call), the
  harness's `run_in_background: true` survives, `sleep N; <read>` is refused and
  `Monitor` with an until-loop is the wait, and anything detached must carry
  `MAESTRO_MAC_CONF`.
- `SKILL.md` rule 9 gains the same three facts in four lines, because the
  reference is not what is loaded at the moment the mistake is made.
- `bin/config.sh` gains step 4: a step-2 find is written to
  `$LDIR/conf-path` and used as the last resort when the upward search fails.
  It is only ever written from a step-2 hit — an explicit `$MAESTRO_MAC_CONF` is
  an override, and `~/` is findable from anywhere — and the cached path is
  re-checked for readability before use, so a stale entry cannot mislead. The
  refusal message now names the detached case and prints the cache's contents.
- `test/run-tests.sh` gains six cases (upward search still works, the find is
  remembered, a detached cwd falls back, no cache still refuses, the refusal
  names the detached case, a stale entry is not trusted) — and now exports
  `TMPDIR` into its own scratch, because a case that sourced `config.sh` without
  setting `LDIR` was writing the cache into the real session scratch.

---

## 72. Nothing extracts a list of rows from the hierarchy — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

`driver.sh nodes` dumps every node, `bin/tree.py` renders an indented tree, and
`bin/resolve.py` finds **one** element. There is no verb for *"every row matching
this pattern, in draw order, with its frame"* — which is the only shape any of
the 15–16 Sep work needed.

So it was written again, from nothing, in at least six sessions: a recursive walk
of `axElement`, collecting labels containing `Request ID`, regexing the id out,
reading `frame.Y` and `frame.Height`, sorting by Y. It is the most-repeated
thirty lines of the two days, it appears inside heredocs where nothing tests it,
and each copy differs — some carry the `PRIORITY` prefix, some mark zero-height
rows, some sort and some do not, so two sessions' logs of the same screen are not
comparable.

**Approximate resolution.** `driver.sh rows <pattern>` — every match in draw
order, one line each: matched text, frame, and whether it is genuinely visible
(the resolver already computes off-screen and under-keyboard, item 4/rule 4, so
the answer exists). Machine-readable with `--json`. Item 70's watcher is then a
loop over `rows`, and two sessions watching the same screen produce the same
lines.

**Gates.** None. Item 70 should use it rather than reimplement it.

**Done 17 Sep, in `src/`.** Built and tested, not shipped.

- `bin/resolve.py` gains `--rows` and `--json`, and a `_rows` printer with the
  three rules that make the output diffable: draw order (sorted by y then x,
  never walk order), one line per row in fixed columns with no diagnostics mixed
  in, and **an empty list exits 0 with `n=0`** rather than the `no visible node
  matches` error every other mode gives — a list that has emptied is the
  finding, and making it an error is how a watcher records "no change" for it.
  Visibility is one of four tokens: `vis`, `off`, `kbd`, `zero`.
- `bin/driver.sh` gains the `rows <pattern> [--json] [--include-hidden]` verb
  and the usage line.
- `SKILL.md` documents it in the driving section — `find` diagnoses one element,
  `rows` reads the list.
- `test/run-tests.sh` gains eight cases (draw order, `n=` agrees with the rows
  printed, no match exits 0 with `n=0`, `--point` still fails on no match,
  keyboard nodes marked `kbd`, tokens confined to the four, `--json` shape,
  `--json` count matches).

**Verified live**, against the iPhone 16 Pro Max on 17 Sep: read 35 rows off the
springboard home screen, correctly marking the adjacent page's icons `off` at
negative x. It was also the instrument for 69's iPhone measurement — the row
signature that proved `/swipe` moves that screen came out of `rows`.

---

## 70. Nothing watches a device for a change over time — **BUILT IN src/ 17 Sep, VERIFIED LIVE, NOT YET SHIPPED**

The whole of 15 and 16 Sep was one question — *does a row leave the screen when
nobody is touching it* — and the toolkit has no verb for it. Every session built
its own watcher, and every failure of those two days was in the hand-rolling
rather than in the app.

**What exists and why it does not reach.** `expect` and `expect-cmd`
(`src/bin/driver.sh:358` and `:390`) poll once a second against a **timeout**,
in the **foreground**, on **one device**, for a **binary** answer — present or
absent. The question asked all day was *did the set of rows change, when, and
from what to what*, across two to four devices, over hours. Nothing in `expect`
can express "the composition changed"; nothing in it survives the Bash call it
was started from; and its timeout argument is the thing that kept ending the
observation before the event.

**Measured cost, per session.**

| session | date | `sleep` calls | inline heredoc scripts |
| --- | --- | --- | --- |
| `aee7e1ad` | 15 Sep | 299 | 0 |
| `97cbdb94` | 15 Sep | 90 | 59 |
| `ef0f7ede` | 16 Sep | 100 | 15 |
| `f13f0e13` | 16 Sep | 39 | 32 |
| `178236e9` | 16 Sep | 35 | 11 |
| `2f46cc6a` | 16 Sep | 15 | 0 |

118 inline scripts over the two days, most of them the same watcher written
again from nothing. Note that rule 5 ("never add a `sleep` after a driver call")
does not cover any of these — they are poll loops, not settle waits, and the
rule's wording leaves them looking legitimate.

**The four failures, all of them the hand-rolling's.**

1. **Fixed deadlines that expired before the event.** `aee7e1ad` ran a watcher
   for 60 checks × 25 s = 25 minutes, covering 18:20–18:45, for an expiry due at
   about 18:55. Its own words: *"the watcher ended 10 minutes too early."*
2. **Two watchers on one device, into one log.** `97cbdb94` at 20:20: *"Killed
   the leftover watcher from the previous round — it was still sampling the same
   device and writing to the old log, so every change was arriving twice."*
   Nothing refuses a second watch on a device already being watched.
3. **A watcher believed to be running that was not.** `aee7e1ad` at 17:34, after
   an hour of reporting that it was watching: *"the previous ones were rejected
   by the permission prompt before they ran. They never executed."* And, asked
   why that was not said: *"No, and I should have."* There is no `watch status`
   to answer the question truthfully.
4. **Watching the wrong thing, invisibly.** `aee7e1ad` watched the **All**
   filter for an event that only shows under **Open** — under All an expired row
   keeps its place in the result set, so a composition swap cannot appear. The
   log recorded ids and not the filter chip in force, so nothing in it said which
   view had been watched.

**What the last working watcher already got right.** The `watch.py` written in
`97cbdb94` at 18:42 is close to the right shape and is worth lifting rather than
redesigning. It logs one line per cycle flushed immediately; it logs `ERR`
without updating the baseline, so a failed read can never read as "no change";
and it records **the filter chip on every line**, which is what makes a log
admissible as evidence rather than a claim. What it lacked was residency, a
deadline-free mode, a pid file and a status verb.

**Approximate resolution.** A `driver.sh watch` verb:

- `watch <pattern> [--interval N]` — samples the resolved row set on `$DEV`,
  one line per cycle: timestamp, `n=`, the filter chip or whatever context
  selector the conf names, then each row with its status and visibility; a
  `>>> CHANGE` line on any diff naming `added` / `removed` / `status`.
- **No deadline by default.** A run ends when `watch stop` says so, not on a
  timeout. This is the single change that would have saved the most time.
- **A pid file per device.** A second `watch` on a device already watched
  **refuses and names the running one**, rather than doubling every event.
- `watch status` — is it running, since when, how many cycles, last line. It
  must be able to say *no*, because the failure mode is a session reporting that
  it is watching when nothing is.
- `ERR` never updates the baseline (keep this from `watch.py`).

**Gates.** Cleared 17 Sep. Item 71 was the gate — a watcher is worthless if it
cannot outlive the call that starts it — and it is done: `run_in_background` is
the documented mechanism and a detached helper now finds the project conf. Item
72 is done too, so the sampling half is `driver.sh rows --json` in a loop rather
than another recursive walk of `axElement`. **This is ready to build.**

**Done 17 Sep, in `src/`.** `bin/watch.py` plus the `driver.sh watch` verb, nine
tests, and verified live against the iPhone 16 Pro Max the same afternoon.

`watch <pattern> [--context <pat>] [--interval n] [--cycles n]`, plus `watch
status` and `watch stop`. It samples through `driver.sh rows --json` (item 72),
so the row reader and its visibility arithmetic are shared rather than
re-derived. All four rules this item asked for are in and tested:

- **No deadline.** `--cycles 0` is the default and means until stopped.
- **A failed read never updates the baseline.** The test that matters is the one
  where the sample after an `ERR` is identical to the sample before it: if the
  ERR had overwritten the baseline there would be a false `CHANGE`, and there is
  not.
- **`--context` on every line**, so the log proves which filter was in force.
- **One watcher per device**, refusing and naming the first.
- `watch status` prints **`NOT watching`** when nothing is running, which is the
  whole point of the verb.

**The diff counts, it does not test membership.** A list can hold the same text
more than once — four rows reading "Search" is a real screen, measured on
springboard — and a set-based diff then reports "nothing added, nothing removed,
everything moved" when two rows genuinely arrived.

**A defect found while building it, now recorded in `reference/connection.md`.**
The first cut used a pid file as the lock. It does not work here: every Bash
call has its own PID namespace, so a pid written by one call is meaningless to
the next — `kill -0` fails on a live process and `kill` reaches nothing. Live on
17 Sep it reported `NOT watching` over a running watcher and **then let a second
one start**, which is the exact collision the lock exists to prevent. Liveness is
now a claim file plus the log's mtime, and stopping is a file the watcher polls
for, both of which cross the namespace because the filesystem is shared. That
fact is a general one about this sandbox and is written up beside the `nohup`
rule, not left in this item.

**Verified live**, 17 Sep, iPhone 16 Pro Max `D9015B4F-...`: started under
`run_in_background`, `watch status` answered correctly from a separate call, a
second start was refused, the home screen was paged from a third call and the
watcher logged `n=4 -> n=6` with the `CHANGE` line on a device it was not
driving, then `watch stop` from a fourth call ended it cleanly and cleared the
claim. 11 samples, 0 failed reads, 1 change.

---

## 74. The wall costs a capture process per device — but what costs the Mac is booting, not having — **MEASURED AND BUILT IN src/ 17 Sep, NOT YET SHIPPED**

Raised 17 Sep off `ef0f7ede` (16 Sep 09:43), which had five simulators booted,
five XCUITest drivers up and the wall running, reported **508 CoreSimulator
processes and load average 735**, lost four drivers and a simulator to it, and
concluded: *"The rig I described needed four simulators. That was the wrong
shape for this Mac."* The item as raised asked for a **device budget**.

**The measurement says the budget is the wrong fix.** Taken 17 Sep 2026 on the
same Mac, which was in use by someone else at the time:

| state | booted | runtime processes | 1-min load |
| --- | --- | --- | --- |
| steady, wall up | 7 | ~1,470 | **6** |
| 6s into one more boot | 8 | 1,554 | 13 |
| 18s | 8 | 1,633 | **102** |
| 36s | 8 | 1,630 | **123** |
| 60s | 8 | 1,659 | 105, falling |
| after shutting that one down | 7 | 1,467 | falling |

Seven simulators idle, with the wall up, is **load 6**. That is nearly three
times the process count 16 Sep was carrying at load 735. So process count is not
the constraint and a cap on devices would not have prevented anything.

**One boot alone takes the machine from 6 to 122 in 36 seconds** while adding
about 170 processes, and it decays as soon as that boot settles. Five
simultaneous boots is what 16 Sep actually was. The failure is a **boot storm**,
it is transient, and the session that hit it read it as a crowded machine and
killed four working simulators to recover.

**The wall's own footprint, confirmed.** One `simulator-server ios --id <udid>`
per booted device — seven booted, seven capture processes — started
unconditionally by `scan_forever` in `src/remote/wall.py:339`, not lazily when a
browser attaches. `SKILL.md`'s claim about the capture binary was right. The
wall's cost is one process per device and it is not what moves the load.

**Done 17 Sep, in `src/`.**

- `bin/lib.sh` gains `_mac_load`, with the measurement in the comment above it.
- `bin/drivers.sh up` reads the load first and, above `${LOAD_WARN:-40}`, says
  what a booting simulator does to the machine and that a driver started into a
  boot storm is the one that dies. It **warns and proceeds** — it does not
  refuse, because the operator can see more than the number can.
- `SKILL.md`'s wall step now carries the numbers and the rule that follows from
  them: boot one at a time, wait for each to settle, do not start drivers during
  a boot.

**What this hands to item 76.** The rig is the first thing in this skill that
will boot a simulator at all — `simctl boot` appears nowhere in `bin/` or
`remote/` today — so `rig up` **must serialise boots and wait for each to
settle** rather than firing them off together. That is now a requirement with a
number behind it, not a preference.

**Left open deliberately.** Where the knee actually is — how many concurrent
boots this Mac takes before one of them fails rather than merely being slow —
is not measured, because finding it means reproducing the 16 Sep failure on a
machine somebody else is using. Serialising makes the question moot.

**An aside, not this skill's.** Twelve headless `Google Chrome --screenshot`
processes were running against `127.0.0.1:8791` throughout, from something else
on the Mac. Noted only because they are a load source that a future measurement
should account for.

---

## 73. `drivers.sh up` with no udid reshuffles every device's ports, including other sessions' — **BUILT IN src/ 17 Sep, VERIFIED LIVE, NOT YET SHIPPED**

Ports are assigned by walking the booted simulators, so a bare `drivers.sh up`
re-numbers devices it was never asked about. Three sightings in two days:

- `f13f0e13`, 16 Sep, on what ate twenty minutes: *"Erase + reinstall on four
  sims, then the XCUITest drivers had to be rebuilt — and `drivers.sh up` with
  no udid walked every booted simulator, so ports shuffled and I restarted three
  of them twice."*
- `ef0f7ede`, 16 Sep 09:43: after a driver death the **iPad's driver came back
  on 22087**, which was the iPhone 16 Pro Max's port.
- The project's own `maestro/tooling-findings.md`, 16 Sep, is the serious one:
  *"It is reassigned whenever any session runs `drivers.sh up`, including for
  devices it did not name. On 16 Sep a hardcoded 9105 sent 22 swipes to another
  session's iPhone after a restart moved this iPad to 9106."*

That last one is **driving the wrong device silently**, which is the failure this
toolkit exists to prevent — `SKILL.md` already refuses to pick between several
drivers for exactly that reason, then undoes it by moving the ports underneath.
It also relays: the relay port moves with the driver port, so anything that read
a port and cached it is now pointed at a stranger's simulator.

**Approximate resolution.** Derive the port from the udid — a hash into the port
range — so a device keeps its port across restarts and no other device's moves.
Where that is not practical, `drivers.sh up` with no udid should **refuse** when
simulators labelled by another session are booted, and name them; the wall label
already records `by=<colour · session>` (item 67), so the information is there.
Either way `driver.sh` must resolve the port on every call and never cache it,
and `tooling-findings.md`'s "read the port from the live table" should become the
documented rule.

**Gates.** None. Related to item 24 (concurrent runs) and item 80.

**Done 17 Sep, in `src/`.** Ports are now sticky per device, remembered **on the
Mac** — because the sessions that must not collide are not on this side.

- `bin/lib.sh` gains `PORTS_MAP` (`$RDIR/ports.map`) with `_ports_read`,
  `_ports_remember` and `_ports_forget`.
- `bin/drivers.sh` replaces `_free_port` with `_port_for <udid> <live> <ports>`:
  the remembered port if nothing live is sitting on it, else the lowest port no
  live driver and no other device's remembered entry is using — recorded, so
  that is the last time it moves. A driver that is already up has its port
  written down rather than argued with. The first device still takes 22087,
  since it is the lowest and that is the port Maestro's own client insists on.
- `drivers.sh ports [list|adopt|forget [<udid>]]`. **`adopt`** writes down what
  is already running without touching a driver — for a Mac whose drivers predate
  the map, and for taking on a peer's assignments rather than competing.
- Bare `up` now names the devices another session has labelled on the wall
  before walking them. It warns rather than refusing: with ports pinned the harm
  is a ~30s xcodebuild each and a peer's driver restarted mid-journey, not
  landing on the wrong device.
- Nine tests, including the case the item exists for — B remembered on 22088
  while A's driver has died and freed 22087, which the old rule would have
  handed to B.

**Verified live**, 17 Sep, on the shared Mac with seven simulators booted and
someone else working on it: `ports adopt` captured all four live drivers
(22087, 22088, 22089, 22092) and restarted nothing. The iPad Pro 11-inch keeps
**22092 / relay 9106** — the exact device whose port moved out from under a
session on 16 Sep.

**A bug found and fixed in the writing, which the codebase already warned
about.** The first `adopt` reported one driver where four were live: it looped
over a process substitution while calling `_ports_remember`, and `_ssh` passes
stdin to the remote command, so the ssh call swallowed every line not yet read.
`drivers.sh up` carries a comment about exactly this trap and the new code
walked into it anyway. It now reads the list with `mapfile` before the loop, and
the comment names the sighting.

**Still open, deliberately.** The relay port is derived from the driver port
(`_dport_for`), so pinning one pins the other — but nothing stops two *Macs*, or
a rebuilt `$RDIR`, from starting the numbering again. That is acceptable: a Mac
reboot takes every driver with it (item 79), so the map and the drivers go
together.

---

## 76. There is no rig — bring-up, state and teardown of several devices is hand-assembled every time — **BUILT IN src/ 17 Sep, VERIFIED LIVE, NOT YET SHIPPED**

"Get the rig set up" (`ef0f7ede`, 09:32) and "tear the rig down" (`178236e9`,
13:22) were the units of work on 16 Sep, and neither is a thing the toolkit has.
A rig means: boot N simulators, install one build on all of them, bring a driver
up per device, label each on the wall, drive each through login and device setup,
and take the lot down afterwards. Only `build.sh --all` exists for any of it.

The cost lands twice. Setting up: `f13f0e13` lost roughly forty-five minutes
between 13:35 and 14:18 to erase-reinstall-relogin across four iPhones, with
The maintainer watching (*"You've wasted 30 fucking minutes on nothing"*, *"Eight minutes
to do nothing"*). Taking down: `178236e9`'s teardown at 13:23 was correct and
complete — samplers killed, five drivers stopped, wall stopped, scratch directory
removed, the four simulators it booted shut down and **the one it did not left
alone** — and every line of it was assembled by hand in the moment.

**Approximate resolution.** `drivers.sh rig up|down|status` over a device list in
the conf: `up` boots, installs, starts drivers and labels; `down` reverses
exactly what *this session* started and leaves everything else alone, which is
the discipline `178236e9` showed by hand. `rig status` prints what is up, whose
it is, and what each is running. This is also the mechanism item 67 needs for its
`SessionEnd` hook — the hook's job becomes `rig down`, and item 67's teardown
line in `SKILL.md` becomes one command.

**Gates.** None, but build it after 73 (ports must be stable before a rig can
claim them) and size it by 74.

**Done 17 Sep, in `src/`.** `drivers.sh rig up|down|status`, ten tests, verified
live on the shared Mac.

- **`rig up [<udid>...]`**, or `RIG_DEVICES` in the conf, and it refuses rather
  than guessing when given neither. Boots each device, **waits each boot out**
  (`simctl bootstatus`, then waits for the load it caused to fall back under
  `LOAD_WARN`), and only once every boot has settled starts a driver per device
  and names it on the wall. Serialising is item 74's requirement, not a
  preference: one boot takes this Mac from load 6 to 122 in 36 seconds, and a
  driver started into that is the one that dies.
- **It does not build or install.** `build.sh` must not run unprompted, and a
  rig that silently replaced the build under test would be worse than no rig.
- **`rig down` takes down only what this session BOOTED**, recorded per session
  on the Mac in `$RDIR/rig/<session>`. A device already up when the rig found it
  is left alone, and so is a driver this session started on a device it did not
  boot. A teardown that takes a peer's simulator is worse than one that leaves
  something behind.
- **`rig status`** prints every booted device with its driver port, relay port,
  whether this session owns it, and the `by=` from its wall label.

**Verified live**, 17 Sep, on a Mac with seven simulators booted and four
drivers belonging to other sessions:

- `rig up` on a spare iPhone 16e booted it, waited the boot out (`settled, load
  8.84`), brought its driver up on 22090 / relay 9104 and claimed it.
- `rig down` took down **that one device** and left the other six, their four
  drivers and their four labels untouched.
- A second `rig up` on the same device brought it back on **22090 / 9104
  again** — which is item 73's sticky ports proved across a full cycle.

**It also closed half of item 67 on the way.** The first `rig up` claimed the
iPhone 16e and the wall went on reading `orange · f13f0e1` — a session that had
ended the previous afternoon. `_label_default` never overwrites, because it
cannot tell a hand-set name from one a dead session left behind. A device the
rig has just **booted** settles that question, so `_rig_rename` writes the label
unconditionally for those. Re-run live: `by=blue · 6632dd0`.

**A bug found three times in one afternoon, which the codebase already warns
about.** `_rig_status` printed one device out of seven: it called `_ssh` inside
a `while read` loop, and `_ssh` passes stdin to the remote command, so the ssh
call ate the rest of the pipe. `drivers.sh up` has carried a comment about that
trap for weeks; `ports adopt` hit it earlier the same afternoon and so did this.
`_rig_status` now reads every label in one round trip before the loop, which is
also cheaper. **Worth a lint rather than a third comment.**

**Not done here.** Installing the app across the rig stays a separate, prompted
step (`build.sh --all`), by design.

---

## 75. A wedged simulator answers every tap with success — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

`ef0f7ede`, 16 Sep 09:51, after the load spike of item 74: *"Taps report ok but
nothing reaches the app — hierarchy reads fine, touch injection is dead."* Two
calls were spent proving it (`text` reported ok with nothing in the field, then a
bare tap test), and the state is indistinguishable from an app ignoring input.

This is not rule 6's case. Rule 6 is a tap that resolved to the wrong place or hit
a control that did nothing; here the **whole touch path is gone** while
`/viewHierarchy` still answers correctly, so every read looks healthy and every
write is discarded. Nothing in the toolkit detects it, and the natural reading —
"the app is broken" — is exactly the claim under test on a bug-reproduction day.

**Approximate resolution.** `driver.sh probe` — tap something known-harmless and
assert the tree changed; or, cheaper and automatic, have `driver.sh` notice when
two consecutive action verbs leave the hierarchy **byte-identical** and say so:
*"two actions, no change in the tree — the simulator may not be taking touches;
`probe` to confirm."* A false positive on a genuinely static screen is cheap; the
missed case costs a session.

**Gates.** None.

**Done 17 Sep, in `src/`.** There is no driver route that reports whether touch
injection is alive, so this is inferred rather than asked.

- `_wedge_check` in `bin/driver.sh`: an action verb that leaves the hierarchy
  **byte-for-byte identical, twice running**, prints what that looks like and
  names `probe`. One identical pair is not enough — a static screen is normal —
  and a screen that changed resets the count, so an intermittent pair never adds
  up.
- `driver.sh probe` taps the blank point the resolver already computes for
  `dismiss` (chosen because a tap there is meant to do nothing) and reports
  whether the tree moved. On no change it says **inconclusive**, names the way
  to tell the two cases apart, and says that restarting the driver will not fix
  a wedged simulator — the driver is answering fine.
- Five tests.

---

## 77. Journey edits are blind string replacement, and units cannot be composed without a temp file — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

**(a) Editing.** `f13f0e13` made five inline `python3 - <<'PY'` edits to two
journey files between 14:06 and 14:17, including one revert — switching the store
pick to `scrollto`, dropping a `dismiss` after the PIN, adding `dismiss --no-key`
before a dropdown row, then reverting `scrollto` when item 69's swipe bug turned
out to be the real cause. Every one of them is `s = s.replace(old, new)` against
a multi-line block. **A replace that does not match rewrites the file unchanged
and reports nothing**, so a failed edit reads as an edit that did not help. Item
49's "repair the journey in place" is the right rule and this is the only
mechanism it has.

**(b) Composing.** `SKILL.md`'s journey guidance says *"recompose units on the
command line second"*, and that is not available: `script` takes file names only.
So the sessions wrote scratch journeys into `$TMPDIR` — `rest.journey`,
`lang.journey`, `setup4002.journey`, `pre.journey`, `post.journey`, `probe.journey`
in one session — whose only content is a handful of `include` lines. Those files
are invisible to the project, untested, and a fresh set every session.

**Approximate resolution.** `script --steps 'tapon "^X$"; expect "^Y$"'` for a
throwaway sequence, so composing units and trying a variant needs no file; and a
`journey edit` path — even `--replace-once` semantics that **exit non-zero when
the old text is not found** — so a no-match is loud. The second is the smaller
change and prevents the worse failure.

**Gates.** None. Related to item 49 and item 60.

**Done 17 Sep, in `src/`** — the composing half. `script --steps 'tapon "^X$";
expect "^Y$"'` runs a sequence with no file; `;` or a newline separates steps,
padding and blanks are dropped, and the throwaway is removed afterwards.
`SKILL.md` has said to "recompose units on the command line" since the journeys
section was written, and until now there was no way to: one session wrote six
scratch `.journey` files into `$TMPDIR` in an afternoon. Three tests.

**The editing half (a) is NOT done** and stays open as its own concern: journey
edits are still `s.replace(old, new)` against a multi-line block, and a replace
that does not match rewrites the file unchanged and reports nothing. That is the
half with the worse failure mode — a failed edit reads as an edit that did not
help. Reopen this as a `journey edit --replace-once` that exits non-zero on a
no-match.

---

## 78. `app-notes.md` reached 169 KB with nothing measuring it — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

`maestro/app-notes.md` in `brandco-flutter-runner` is **169,005 bytes across
1,302 lines** as of 16 Sep. `SKILL.md` is unambiguous that this must not happen:
*"The app notes are read at the start of every session, so they have to stay
short — every entry that is not about driving this app dilutes the ones that are"*
and *"this file is the one that must not grow unreadable."*

Nothing measures it. `notes.sh` has `init`, `add`, `path` and `promote`, and no
size discipline; `preflight.sh` counts journeys and flows but not notes. The rule
exists and has no enforcement, so it degrades silently and the degradation lands
on exactly the sessions that most need the file — the ones starting cold on a bug.

Worth noting what *did* work, because it is the contrast: `maestro/tooling-findings.md`
is 67 lines, holds two well-measured findings, and one of them was raised as item
69 by the session that found it. Item 52's split is doing its job; the size rule
on the other half is not.

**Approximate resolution.** `preflight.sh` prints the app-notes line count against
a threshold, so the size is in front of the operator at the start of every
session rather than in a rule nobody rereads. And `notes.sh archive` — move
superseded and corrected-in-place entries to a dated `app-notes-archive.md`,
keeping them readable without keeping them loaded. The project's own
`app-notes-2026-08-11-original.md` shows the habit already exists by hand.

**Gates.** None.

**Done 17 Sep, in `src/`.**

- `bin/preflight.sh` prints `app-notes.md  <lines> · <KB>` and, past
  `${NOTES_WARN_LINES:-400}`, says it is read at the start of every session and
  names the archive command. In front of the operator at the start of every
  session, which is where the rule was not.
- `bin/notes.sh archive` opens a dated `app-notes-archive.md` beside the notes
  and lists the entries that look superseded by keyword. **It moves nothing by
  itself**, and a test enforces that: only a person can tell a superseded
  measurement from a current one, and a wrong note somebody has already acted on
  is worth keeping findable rather than deleted.
- Three tests.

---

## 79. `/tmp/maestro-mac/` does not survive a Mac reboot — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

`aee7e1ad`, 15 Sep 13:51, after the Mac came back up: *"`/tmp/maestro-mac/` is
gone entirely. The Mac reboot wiped it (it's under `/tmp`)."* With it went the
XCUITest runner build, so every driver had to be rebuilt at about 30 s each, and
a `relay-fixed.py` a previous session had patched by hand — which is how the
IPv4/IPv6 relay bug (item 62) came back for an afternoon.

The scripts recreate what they need, so this is not a failure so much as an
unnamed cost that presents as a first run. Two sessions spent time working out
why everything was slow again.

**Approximate resolution.** A line in `reference/connection.md` saying the Mac's
toolkit state is under `/tmp` and does not survive a reboot, and `drivers.sh`
saying *"rebuilding the runner — the Mac has rebooted since this was last built"*
rather than looking like a cold start. If anything is genuinely worth keeping
across reboots, it does not belong in `/tmp`.

**Gates.** None.

**Done 17 Sep, in `src/`.** A section in `reference/connection.md` naming what
lives in `$RDIR` and goes with a reboot — the XCUITest runner build, the copied
helper scripts, the wall labels, the per-device port map (item 73) and the rig's
claim files (item 76) — and the rule that follows: nothing worth keeping across
a reboot belongs there. The cost is ~30 s per device rebuilding the runner, and
it presents as a first run rather than as a reboot.

---

## 80. Two live sessions on one Mac have no protocol — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

On 16 Sep two sessions drove the same Mac all afternoon and it worked, entirely
improvised. `2f46cc6a` took store 4001 and the iPads, `f13f0e13` took 4002 and
the iPhones; they confirmed the split between themselves. `2f46cc6a` at 14:28,
before the peer restarted drivers: *"Told them to go ahead — my measurements are
finished, so there's nothing for them to interrupt."* And the `/swipeV2` finding
(item 69) crossed between them within minutes of being measured, which is why
both days' sweeps were re-examined rather than one.

None of that is written down anywhere. Item 24 covers concurrent **branch**
reviews — worktrees, `BUILD_MARKER`, not clobbering a shared checkout. This is
different: device ownership, port ownership (item 73), and asking before an
action that tears down a peer's driver. It is now routine rather than
exceptional, and the next pair of sessions will reinvent it or collide.

**Approximate resolution.** A section in `reference/driving.md`: claim devices by
labelling them on the wall before driving, never run bare `drivers.sh up` when
another session's labels are booted, announce a driver restart to the peer before
making it, and split test data by store or account so two sessions cannot poison
each other's evidence. The wall label already carries `by=` (item 67), so
"whose device is this" is answerable today.

**Gates.** None. Reads with 24, 67 and 73.

**Done 17 Sep, in `src/`.** A "Two sessions on one Mac" section in
`reference/driving.md`, written from what the 16 Sep pair actually invented:
claim devices by labelling them on the wall, never run bare `drivers.sh up`,
read the relay port on every call, say so before restarting a driver, split the
test data by store or account so neither poisons the other's evidence, and share
a toolkit finding immediately — the `/swipeV2` finding crossed between them
within minutes, which is why both days' sweeps were re-examined rather than
one.

---

## 81. Nothing says to establish whether a timed state can be forced before waiting for it — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

15 Sep went from 12:46 to 21:56 across two sessions waiting for request TTLs to
expire so a list would shed rows. At 18:55 the maintainer found out it had never been
necessary: *"I'm sorry, all this time you could have just cancelled a request, we
didn't need to wait for an expiry?"* — and then *"Could have fucking told me six
hours ago."* The next afternoon `f13f0e13` cancelled five rows at 15:44:04 and had
the shed on an untouched device by 15:44:46, forty-two seconds later.

Item 58 is adjacent and does not cover this. 58(a) is about **fudging a timer in
the app source** racing driver latency; this is about not having asked whether the
state is reachable another way at all. The pattern generalises past expiry: any
state reached by waiting is usually also reachable by a backend action, a config
override, or an equivalent user action with the same effect on the thing under
test.

**Approximate resolution.** A step in `SKILL.md`, in the same place as rule 10
("test before you report a capability impossible"), for any verification of a
timed state: **name the event, then name the three routes to it — wait, backend
action, config override — and say which you are taking and why, before you start
waiting.** Where the project has an API client (this one has `maestro/tools/mesh.py`),
the app-notes template should carry a "how to force a state" heading so the answer
is written down the first time somebody works it out.

**Gates.** None. Extends item 58.

**Done 17 Sep, in `src/`.** Now rule 10 in `SKILL.md`, ahead of the old
"test before you report a capability impossible" (which becomes 11): name the
event, then name the three routes to it — wait, backend action, config override
— and say which you are taking and why, **before** the waiting starts. Carries
the measurement: 15 Sep went 12:46 to 21:56 waiting for TTLs, and a cancel
produced the same shed in forty-two seconds the next afternoon.

`reference/app-notes-template.md` gains a **Forcing a state** heading, so the
answer is written down the first time somebody works one out rather than
rediscovered. Item 58's warning is cross-referenced on the third route.

---

## 83. A journey edit is a blind string replacement — a no-match rewrites the file unchanged and says nothing — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

The half of item 77 that was not built. 77 gave `script --steps` for *composing*
units inline; *editing* a journey is still `s.replace(old, new)` against a
multi-line block, typed into a heredoc.

**The failure mode is silence.** A replace whose `old` does not match rewrites
the file byte-identical and reports success, so a failed edit is
indistinguishable from an edit that did not help — and the next thing anybody
does is re-run the journey and read the result as a fact about the app.

Measured 16 Sep 2026, `f13f0e13`: five inline `python3 - <<'PY'` edits to two
journey files between 14:06 and 14:17, including one revert. Switching the store
pick to `scrollto`, dropping a `dismiss` after the PIN, adding `dismiss --no-key`
before a dropdown row, then reverting `scrollto` once item 69's swipe bug turned
out to be the real cause. Item 49's "repair the journey in place" is the right
rule and this is the only mechanism it has.

**Approximate resolution.** `bin/journey.sh edit <file> --replace-once <old>
<new>`, exiting non-zero and printing the nearest near-miss when `old` is absent
or matches more than once. Small, and it prevents the worse failure. A `--dry`
that prints the diff without writing is the cheap second half.

**Gates.** None. Reads with items 49 and 77.

**Done 17 Sep, in `src/`.** New `bin/journey.sh`:

```sh
journey.sh edit <file> --replace-once '<old>' '<new>' [--dry]
journey.sh edit <file> --replace-once --old-file <f> --new-file <f> [--dry]
journey.sh show <file>
```

`--replace-once` is the only mode there is. **Absent → exit 3, nothing
written**, and it names the closest line in the file, printed delimited and
unstripped with "They differ only in whitespace" when that is the difference —
because whitespace is the usual cause and printing both sides stripped hides
exactly what is being diagnosed. **More than once → exit 4, nothing written.** A
match prints the unified diff and writes. `--dry` prints the diff and writes
nothing. A bare name resolves in `$JOURNEY_DIR`, the same as `driver.sh script`.

Nine tests. One of them cost a false failure worth recording: `dismis` is a
**substring** of `dismiss`, so it matches and should — a test for the no-match
path needs text that is genuinely absent.

**Gates.** None. Reads with items 49 and 77.

---

## 69. `driver.sh swipe` posts `/swipe`; the driver's live route is `/swipeV2` — **DONE 17 Sep (route fixed in src/, fold settled on device); NOT YET SHIPPED**

Measured 16 Sep 2026 on the iPad Pro 11-inch (M4)
`E8F5AC4E-C660-CA9A-F298-B4715B5D1E1E`, iOS 18.6, landscapeLeft, against a
Flutter two-column grid.

`driver.sh:685` and `:777` post `/swipe`. **The driver answers 200 and does
nothing.** Every variant was inert: `760 700 760 300` at 0.4, 0.6, 0.8 and 1.0s,
both columns, the scrollbar edge, and a normalised `0.63 0.84 0.63 0.25`.
Fourteen consecutive swipes, fourteen identical hierarchies. `scrollto` is built
on the same route and reported `not found after 6 swipes down` with the list
still on row one.

The route Maestro itself uses is **`/swipeV2`**, read out of its own log for a
`scrollUntilVisible` that worked
(`~/.maestro/tests/2026-09-16_150549/xctest_runner_*.log`):

    37 request: POST /deviceInfo
    20 request: POST /viewHierarchy
     5 request: POST /swipeV2

The driver ships a `SwipeRouteHandlerV2` test class, so v2 is current and
`/swipe` is a v1 leftover. Same payload shape, same app-space coordinates: a
plain curl to `/swipeV2` scrolled the grid first try, and a 22-step sweep built
on it reached all 48 rows of the list in 90 seconds — with no driver teardown,
which is what going through `flow.sh` costs today.

Two things follow beyond the one-line fix:

- `reference/driver-api.md` lists `swipeV` under "not exercised" and documents
  `swipe` as the working route. On this driver it is the other way round.
- A silently inert swipe reads as an app that will not scroll, which is exactly
  the claim under test in PROJ-1811. It cost this session about twenty minutes
  and one wrong conclusion.

Worth also checking whether the iPhones are genuinely unaffected or merely have
shorter lists where it has never mattered.

**Related, same session.** `flow.sh`/the MCP server and `drivers.sh up` evict
each other's XCUITest runner, and the evicted side's next run spends ~35s
reinstalling and does almost nothing — measured at 15:03:55 as three
`/deviceInfo`, one `/viewHierarchy` and no swipe at all, ending 145 seconds
inside its own timeout. That reads as "the scroll gave up". Worth a line in
`reference/driving.md`, and possibly a warning from `flow.sh` when it is about
to displace a toolkit driver.

**Folded in 17 Sep — the inert journey this shipped into the project, and a
correction to this item's own claim.**

`maestro/journeys/30-scroll-task-list.journey` was written and committed on
16 Sep (`ac6ba42`, "Add task-list scroll journeys, drop two coordinate taps") on
top of `scrollto`, so it went out built on `/swipe`. Its sibling
`31-scroll-task-list-up.journey` is the same.

**The route is fixed.** `bin/driver.sh` posts `swipeV2` from all three call
sites — the CLI verb, the journey verb and `_scrollto` — with a test asserting
no bare `_post swipe` remains, and `reference/driver-api.md` is corrected.

**But the "confirmed on the iPhone too" half of this item is wrong, and is
withdrawn.** Measured 17 Sep 2026 on the iPhone 16 Pro Max
`D9015B4F-C502-78EA-83D7-1D37AF8ADFC6`, iOS 18.6, against springboard: `/swipe`
paged the home screen in both directions, **returning to an earlier page's exact
row signature** — which a redraw cannot fake — and later paged App Library
through to the Today View. `/swipe` is not uniformly dead. The 16 Sep claim in
`maestro/tooling-findings.md` that *"the session driving the iPhones confirmed
the same day that `/swipeV2` is what works there too"* was second-hand and does
not establish that `/swipe` failed there.

So the variable is **not** iPad versus iPhone. It is some combination of the app
(Flutter's gesture handling versus springboard), the gesture (a vertical list
scroll versus a horizontal page swipe) and the driver build — and it has not
been isolated. A route that works often enough to look correct and fails where
it matters is worse than one that never works, which is the argument for routing
everything through `swipeV2` regardless.

**What this means for the 15 Sep evidence.** The worry this fold was raised on —
that the iPhone sweeps read a list that never scrolled, making "every request is
reachable by scrolling" worthless — is **not established**. It is not disproved
either: springboard is not the Flutter task list. The decisive test is one
`/swipe` against a scrolling Flutter list on an iPhone, followed by a hierarchy
read, and it has not been run. Until it is, treat any reachability claim resting
on a pre-17-Sep sweep as unverified rather than as wrong.

**Still to do here.** Run that test; re-run `30-scroll-task-list.journey` now the
route is live; and correct `maestro/tooling-findings.md` in the project, which
still carries the withdrawn iPhone claim.

**Gates.** None.

**The fold is settled, 17 Sep 2026, and the 15 Sep evidence stands.**

Measured on the iPhone 16 Pro Max `D9015B4F-C502-78EA-83D7-1D37AF8ADFC6`,
iOS 18.6, in the UAT build's own store dropdown — a Flutter scrolling list,
which is the exact shape springboard was not. One `POST /swipe`:

```
before  4002 Riverside · 4002 Riverside · 4010 Eastgate · 4014 Eastgate ·
        4032 High St · 4110 Northfield · 4140 Lakeside · 4200 Harbour
after   4002 Riverside · 4110 Northfield · 4140 Lakeside · 4200 Harbour ·
        4210 Marina · 4232 Central Mall · 4237 Outlet Park · 4238 Grand Mall ·
        4241 Grand Mall GF
```

**`/swipe` scrolls a Flutter list on the iPhone.** `/swipeV2` scrolled the same
list immediately afterwards. So the worry this fold was raised on — that the
15 Sep iPhone sweeps read a list that never moved, making "every request is
reachable by scrolling" worthless — **is disproved**. That conclusion stands.

**What remains true, and is the reason the route change was still right.**
`/swipe` is inert on the iPad Pro 11-inch against a Flutter two-column grid
(fourteen calls, fourteen identical hierarchies, 16 Sep) and works on the iPhone
against a Flutter list (17 Sep). The variable is therefore **not the device and
not the framework** — it is narrower than either, and it has not been isolated.
A route that works often enough to look correct and fails where it matters is
worse than one that never works, which is why everything posts `swipeV2`.

**Left for whoever next drives an iPad:** the one remaining question is what
`/swipe` and `/swipeV2` do on that iPad's grid *today*, on the current driver
build. That needs the iPad, which belongs to another session's rig.

`maestro/journeys/30-scroll-task-list.journey` is **not** inert after all —
it inherits `/swipe`, which works on the iPhones it was written for. It still
wants a re-run once this ships, because it now goes through `swipeV2`.

---

## 84. An `_ssh` inside a loop reading from stdin eats the loop's input — **BUILT IN src/ 17 Sep, NOT YET SHIPPED**

`_ssh` passes stdin to the remote command by design. A loop fed by a pipe or a
file redirect therefore loses every line not yet read the moment an ssh call
runs inside it: **the loop runs once, silently, and exits 0.**

The codebase already knew. `_journey` reads on its own fd with six lines of
comment explaining exactly this (item 36, "a run reporting success on a screen
it never reached, the worst failure this toolkit can have"), and `drivers.sh up`
carries a comment about it too. It happened three more times on 17 Sep 2026, in
new code written beside those comments:

| where | symptom |
| --- | --- |
| `drivers.sh ports adopt` | reported 1 live driver where 4 were up |
| `_rig_status` | printed 1 booted device of 7 |
| `bin/device.sh list` | would list only the first registered phone — **found by the lint, not by anybody** |

Prose in the file did not stop it, which is the same argument item 51 made for a
hook over more guidance.

**Done 17 Sep, in `src/`.** `bin/lint-stdin.py` walks each `while read` loop
that is fed by a pipe or a redirect and flags an `_ssh`, `scp` or `ssh` in its
body. It understands three shapes that are **not** defects and must never be
flagged, because flagging them would train people to undo the fix:

- `read -u <fd>` — an explicit descriptor, which is item 36's fix in `_journey`
- a one-line `while ... done < <(...)`, where the ssh is in what *feeds* the
  loop rather than in its body
- a call that closes its own stdin with `</dev/null`, the escape hatch for where
  the read cannot be hoisted

It runs in `test/run-tests.sh` over the whole source, and `ship.sh` now refuses
to publish on a hit — beside the existing syntax gate, for the same reason: a
broken script here breaks every session that loads the skill.

`bin/device.sh list` is fixed (`mapfile` before the loop). Six tests, including
one for each shape that must not be flagged.

**Gates.** None.

---

## 67. A wall label outlives its session — nothing clears it, and the next session will not replace it — **ALL FOUR PIECES SHIPPED; the `SessionEnd` hook is registered by `install.sh`; the label half is still open**

The maintainer opened the wall on the morning of 16 Sep and found **four simulators
named 13h ago, none working**, and the night before **two labels still up for
sessions that had already ended**. He had understood the labels to expire on
their own. They do not.

**What actually exists.** `STALE_AFTER = 3600` in `src/remote/wall.py:75` only
adds the `stale` class, which greys the name (`.sim.stale h3 { color:var(--mut);
font-weight:400 }`). The label file itself is untouched. The 15 Sep entry for
item 66 says so in as many words: *"no expiry field and nothing to sweep."* That
was the right call for a label that a live session keeps warm; it is the wrong
call for one whose session is gone.

**Nothing removes a label except a command nobody runs.** Three ways out exist
and all three are manual:

| what clears it | where |
| --- | --- |
| `bin/wall.sh unlabel [<udid>]` | typed by hand |
| `bin/drivers.sh down <udid>` | `src/bin/drivers.sh:138` — `rm -f $RDIR/labels/$u` |
| `bin/drivers.sh down-all` | `src/bin/drivers.sh:146` — `rm -rf $RDIR/labels` |

No hook calls any of them. The skill ships exactly one hook,
`src/hooks/gate-journey-first.sh`, a PreToolUse nudge about literal-coordinate
taps. The `SessionEnd` entry in `~/.claude/settings.json` is
`session-identity-end.sh` and has nothing to do with this skill. And the skill
never *asks* for teardown either: `drivers.sh down` appears once in
`src/SKILL.md`, at line 82, in a sentence explaining that it clears the label —
there is no "when you have finished driving, run this" step anywhere in
`SKILL.md` or `reference/`.

So cleanup happens only if the model happens to type `drivers.sh down` before
the session ends. Every other ending — closed terminal, context exhausted,
crash, the user walking away — leaves the label up forever, and leaves the
driver process up with it. **The label is the visible half of a stale driver.**
Item 64's history already records a stale relay holding a port with its origin
never established; this is the same failure with a name attached to it.

**The other half, added 16 Sep 12:20: the next session will not replace it
either.** Watching the wall, the maintainer saw a tile reading `Login regression /
iPhone 16 · CD6EB574 / purple · 3fa41c7 · named 15h ago` while a different
session was driving that simulator — *"simulators that were used by previous
sessions are not being renamed"*. The cause is `_label_default` in
`src/bin/drivers.sh:84`:

    [ -s '$RDIR/labels/$udid' ] || cat > '$RDIR/labels/$udid'

`drivers.sh up` writes a label only into a blank file, and the comment above it
says why — *"An explicit `wall.sh label` is never overwritten — this only fills
a blank."* That rule is right in itself. What it cannot do is tell a name set by
hand from a name left behind by a session that died, and because nothing clears
a label at session end, **every stale label looks hand-set to it**. So a new
session bringing a driver up on a previously-used simulator inherits the dead
session's name, its `by=`, and its mtime — which is why the age went on climbing
past 15h under a session that was not running.

Only `bin/wall.sh label` overwrites unconditionally. That is what eventually
cleared these: at 12:17 a session explicitly named all four devices, and the
`purple · 3fa41c7` labels — including the 13.7h-old "Checkout flow, PR 101" —
were replaced by `cyan · 178236e` names a minute old.

**Both halves are one missing fact: whether the session in `by=` is still
alive.** Nothing deletes a label because nothing knows the session has gone;
nothing replaces one for the same reason. Fix that and both symptoms go.

**The shape of the fix, which the maintainer set: the sessions on this machine that are
driving simulators should drive the teardown.** The wall stays read-only — it
does not sweep, it does not time anything out, and it does not need to know
which sessions exist. Whoever wrote the label is who removes it.

Four pieces, in order of how much they buy:

1. **A `SessionEnd` hook in the skill** that runs `drivers.sh down` for the
   devices this session labelled. The label already records its author —
   `by=purple · 3fa41c7`, session colour plus seven characters of
   `CLAUDE_CODE_SESSION_ID` — so a session can pick out its own devices without
   a registry. `_label_by` in `src/bin/drivers.sh` is where that string is
   built; the hook reads the same value and matches on it. This has to be a hook
   rather than prose, for the reason `gate-journey-first.sh` was written: a
   session that has run out of context cannot be instructed to do anything.
2. **`_label_default` should overwrite a label whose session is gone.** The
   `by=` field already carries the session id, so `drivers.sh up` can compare it
   with its own and treat a mismatch from a session that is no longer running as
   a blank. This covers what the hook cannot: a session killed with `-9`, and
   every orphan already on the Mac. It also keeps the rule the comment is
   protecting — a name set by the *current* session still survives.
3. **A line in `SKILL.md`** saying to tear down when the driving is finished, so
   the tidy ending is also the documented one. On its own this fixes nothing —
   it is the belt to the hook's braces.
4. **Deciding what a label with no live session should look like on the page.**
   With 1 and 2 done a label is cleared at session end and replaced when the
   device is reused, so what is left is a simulator nobody has touched since its
   session died. Options are a hard expiry in `wall.py` (hide or drop past N
   hours), or leaving it to `down-all`. This is a judgement call, not a bug —
   raise it once the first two exist and the everyday case is handled.

**17 Sep: pieces 2 and 3 are done, piece 1 is written but not installed, and
piece 4 is untouched.**

- **Piece 2 (replace a dead session's label) — done for the case that can be
  settled.** `drivers.sh rig` renames unconditionally any device it has just
  **booted** (`_rig_rename`), because a device that was shut down a moment ago
  cannot be carrying a name somebody set by hand. `_label_default` keeps its
  never-overwrite rule everywhere else, which is still right. Found live: the
  first `rig up` on 17 Sep claimed an iPhone 16e and the wall went on reading
  `orange · f13f0e1`, a session that ended the previous afternoon; after the fix
  it reads `blue · 6632dd0`.
- **Piece 3 (a line in `SKILL.md`) — done.** The rig step says to run `rig down`
  when the driving is finished, and points at the hook for the endings that are
  not tidy.
- **Piece 1 (the `SessionEnd` hook) — DONE, in `src/hooks/rig-down-on-end.sh`.**
  `rig down` from item 76 is the mechanism this was waiting for, and the hook is
  a four-line wrapper around it: scoped to what this session booted, detached so
  it cannot hold the terminal, always exits 0. `ship.sh:29` syntax-checks it and
  `:72` rsyncs it into `build/` with everything else, so it ships without any
  further work. `reference/setup.md § 5` documents its settings block beside
  `gate-journey-first.sh`'s, using the same `bash <path>` form.

  **The only outstanding step is the `settings.json` entry**, which is the
  machine's rather than the skill's — exactly as item 51 settled for the first
  hook.

- **Piece 4 (what a label with no live session should look like on the page) —
  DECIDED AND BUILT 17 Sep.** The maintainer's call: **hide it once it is from a previous
  calendar day**, not after a fixed number of hours. That is how a wall reads —
  a name put up at 09:00 is still today's work at 23:00, and one put up at 23:00
  is yesterday's by breakfast, even though it is only ten hours old.

  `remote/wall.py`'s `read_label` returns `{}` when the label's mtime falls on
  an earlier local day, so the tile shows the handset and no name. **Nothing is
  deleted**: the file stays and `drivers.sh rig status` still prints `by=`. The
  one-hour `STALE_AFTER` greying is unchanged and still fades a name that has
  merely gone quiet, so a long-running session keeps its name all day.

  Six tests, including the two that matter: a label three hours old **on the
  same day** is kept and greyed rather than hidden, and one only an hour old
  that fell before midnight **is** hidden — which is the whole reason for doing
  this by day rather than by hours.

**Piece 2's other half — done 17 Sep, in `src/`.** `_label_default` now
reclaims a label whose session has gone, which covers the devices the rig never
booted. The open question this item asked — *"whether a session-id mismatch
alone is enough, or whether it must also check the old session is no longer
running"* — is answered: **a mismatch alone is not enough**, because two live
sessions share this Mac routinely (item 80). The test is all three of:

1. the label names a different session, **and**
2. that device has no live driver — a session that is driving has one up by
   definition, and the map is already in hand so this costs no round trip, **and**
3. the label has not been touched for `LABEL_STALE_AFTER` (default 3600s, the
   threshold `wall.py` already greys a tile at).

Condition 3 is what stops a peer being renamed mid-session: Maestro tears a
driver down on every CLI or MCP run, so condition 2 alone would fire constantly.
Six tests, including both cases that must not regress — a peer with a live
driver, and a peer whose driver was torn down a minute ago. The remote shell was
also run on the real Mac against scratch files, since the quoting is the risk:
blank→WROTE, ours→KEPT, peer fresh→KEPT, peer 113060s old→WROTE, same peer with
a live driver→KEPT.

**Still open: piece 4 only** — what a label with no live session should look like
on the page. With pieces 1–3 done, that is the case of a simulator nobody has
touched since its session died, and it remains the judgement call it always was.

**Gates.** None. Independent of 17 and 28, and touches `src/hooks/`,
`src/bin/drivers.sh` and `src/SKILL.md` only.

**Open questions for the maintainer, to settle before building:** whether the hook should
stop the driver as well as clear the label (`down` does both, and a session that
has ended has no use for its driver); whether a session that ends mid-journey
should be treated any differently from one that ends cleanly; and whether a
session-id mismatch alone is enough for `_label_default` to overwrite, or whether
it must also check the old session is no longer running — two sessions can share
a Mac, and the second must not rename the first's device out from under it.

**All three open questions are answered.**

1. *Should the hook stop the driver as well as clear the label?* **Yes** — the
   hook runs `rig down`, which does both. A session that has ended has no use
   for its driver.
2. *Should a session that ends mid-journey be treated differently from one that
   ends cleanly?* **No.** `rig down` shuts the simulator down either way, and a
   half-finished journey leaves no state worth preserving on a device nobody is
   coming back to.
3. *Is a session-id mismatch alone enough for `_label_default` to overwrite?*
   **No** — it also needs no live driver on the device and an untouched label
   older than `LABEL_STALE_AFTER`. Two live sessions share this Mac routinely
   (item 80), and Maestro tears a driver down on every CLI run, so either
   condition on its own would rename a peer's device mid-session.

**The one thing left is not this package's.** The `SessionEnd` block in
`~/.claude/settings.json`, exactly as item 51 settled for the first hook.
`ship.sh` carries the hook itself.

---

## 17. The package has no version, manifest, installer or git — **DONE 17 Sep 2026**

Out of scope for a session-cost review, but it is now the biggest risk in the
package and `INVENTORY.md` has said so for a while. `src/` gained
`test/run-tests.sh` today, so the resolver is no longer untested, but there is
still no `VERSION`, no `manifest.sh`, no `update.sh`, no installer and no git
history — and `build/` is symlinked straight into `~/.claude/skills`, so a bad
ship goes live with nothing to roll back to.

**Added 13 Aug: the published tree cannot be verified.** `ship.sh` is right
about `__pycache__` — it excludes it from the rsync and drops `*.pyc` from the
comparison, so nothing compiled is ever shipped. But `--exclude` also protects
those files from `--delete`, and running the skill writes them into the live
copy: after this afternoon's ship, `build/maestro-remote-mac/bin/__pycache__/`
gained a `.pyc` one minute later, when the tests were run from the live path.

That is correct behaviour and not worth suppressing. What it exposes is that
**"the published copy matches src" is currently unanswerable**. `ship.sh` can
compare the files it knows about, but nothing states what the published tree is
*supposed* to contain, so an extra file that arrived some other way — a stale
script from an older layout, an edit made directly in `build/` — is invisible.
Five items shipped in one afternoon on 13 Aug across nineteen files, straight
into `~/.claude/skills`, and the only check that they arrived intact was running
the tests and two commands by hand.

A `manifest.sh` answers it: the list of what belongs, so the live tree can be
checked against it rather than assumed. Fold it in here rather than fixing it
separately — on its own it is a curiosity, and as part of packaging it is the
thing that makes a ship verifiable.

**20 Aug: "an edit made directly in `build/`" stopped being hypothetical.**
Three landed there in one day, by two sessions that both believed they were
editing the skill:

| what | where it went | in `src/`? |
| --- | --- | --- |
| `vmservice.sh` log-scrape finding (now item 39) | `build/…/reference/connection.md` § 4 | no |
| `build.sh` not installing (now item 40) | `build/…/reference/driving.md` | no |
| a four-item BACKLOG.md | `build/…/BACKLOG.md` | no — and it was a *rival* to this file |

All three would have been destroyed by the next ship with nobody the wiser.
`build/` is also **stale in the other direction**: `src/reference/driving.md`
carries the `dismiss` verb and the `--blank` resolver section, and the build
copy does not — so a rebuild both loses today's edits and restores content the
live skill has been missing.

Two things follow. The manifest above is not enough on its own: it answers "does
the live tree contain something it should not", and the failure here is people
writing to the live tree at all, believing it to be the source. `build/` wants
making unmistakable from inside — a header line in every published file saying
it is generated and naming `src/`, or a pre-ship check that refuses to overwrite
a build file whose mtime is newer than its source. And `~/.claude/skills/
maestro-remote-mac` being a symlink into `build/` is what makes the mistake so
easy: a `find` under `~/.claude` does not follow it, so the real backlog reads as
missing rather than elsewhere.

**Fix, 17 Sep 2026.** Packaged with `claude-package-kit`'s house layout as its
own git repo, alongside the published packages. `src/` became `skill/`; the repo root carries
`VERSION` (1.0.0), `manifest.sh`, `install.sh`, `uninstall.sh`, `update.sh`,
`lib/update-check.sh`, the release workflow and a `/release` skill. One commit on
`main`, no remote — publishing was not asked for and is where item 28's decision
falls due.

`build/` and `ship.sh` are superseded, not deleted; they are still in
`~/claude-sandbox/maestro-remote-mac/` and are nobody's source of truth any more.
The live skill was uninstalled the same day, so
`~/.claude/skills/maestro-remote-mac` is gone until `./install.sh --link` puts it
back pointing at `skill/`.

Each of the three things this item asked for, and what answers it:

- **A rollback.** Releases and `update.sh`. A bad version is a tag you do not
  install, and the previous tarball is still on the release page. Before this,
  the only copy of yesterday's skill was whatever `build/` happened to hold.
- **"Does the live tree contain something it should not?"** `manifest.sh`
  compares the installed tree against `skill/` file for file, and `install.sh`
  runs that comparison every time. Two things are ignored because both appear
  only after the skill has been used and neither was ever payload:
  `__pycache__/*.pyc`, and `reference/staging/` where `bin/notes.sh promote`
  parks a project's findings. `test/run-tests.sh` proves the check catches a
  stray file and a missing one, and does not flag those two.
- **People writing into the live tree believing it is the source.** This was the
  expensive one — three edits in one day, all of which would have been destroyed
  by the next `ship.sh`. Neither a generated-file banner nor an mtime check was
  built, because `./install.sh --link` removes the possibility instead of warning
  about it: the live path becomes a symlink to `skill/`, so the live tree and the
  source are the same directory and an edit made there is an edit to the repo,
  visible in `git status`. `SKILL.md` now says to run `readlink -f
  ~/.claude/skills/maestro-remote-mac` before editing, and says plainly that a
  copy install throws such an edit away.

`ship.sh`'s pre-publish gates did not die with it — they are cases in
`test/run-tests.sh` now, so a release cannot be cut past them: every shell and
Python file parses, and `lint-stdin.py` finds no `ssh` call inside a loop reading
from stdin. Two more joined them. Every shell script carries its exec bit, which
eight did not — including `device.sh`, whose missing bit killed item 46's
recovery path on a live device. And the skill's own 360 behaviour cases now run
out of the *installed* copy rather than the checkout, which is the difference
between "the files arrived" and "the thing works". The installer ends the same
way in miniature: it resolves `^SCAN$` out of a captured iPhone hierarchy and
checks the point is still `201 262.6`, so an install that landed but cannot run
reports failure rather than success.

25 packaging cases, 360 skill cases, all passing.

**What this does not settle.** `skill/` carries client identifiers — the employer
name, the client app's repository name and its Jira ticket keys, in `SKILL.md`,
`physical-device.md`, `bin/init.sh` and `test/run-tests.sh`. Item 28 said to
decide that when 17 was taken. There is no remote yet, so nothing has left the
machine, but it is the question to answer before one exists.
