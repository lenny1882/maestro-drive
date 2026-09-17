# Driving discipline

How to *use* this toolkit well. The rules that matter most in `SKILL.md` are the
terse version, read before the first tap; this is the fuller account with the
evidence behind each one, and the home for the next such lesson.

**Skill-usage lessons live here, not in a project's memory.** The maestro toolkit
is global to any Flutter repo, so a lesson about *how to drive* travels only if it
ships with the skill. Written into a project's memory or its app notes, it does
not reach the next repo and it is not read at the moment it is needed — a memory
loaded at session start is not in front of you when the screen is. Three
behaviour memories in one project all said "do not hand-walk a covered screen";
all three were loaded into the session that hand-walked one anyway. So:

- A load-bearing rule goes into `SKILL.md`'s "The rules that matter most" — that
  is the text read immediately before driving.
- The fuller reasoning, and any lesson not weighty enough for that list, goes
  here.
- General conduct that is not about maestro (stopping mid-task, over-long
  answers) goes to the machine retrospective instead — it does not travel with
  the skill and does not belong in it.

The `PreToolUse` hook (`hooks/gate-journey-first.sh`, set up in
`reference/setup.md` § 5) is the *enforcement* half of the same idea: it blocks a
raw coordinate tap once per session and names the journeys. Prose is read before
the screen is on the table; the hook fires while it is.

## The standing lessons

Each of these has failed across real sessions, been named by the user, and
recurred after a one-time correction — which is why they are rules, not tips.

- **The journey is the unit of work, not a driver call.** Hand-walking a screen
  the project already has a journey for is the most repeated waste in this
  workflow — raised on four separate days, policed by the user by hand each time
  ("you *must* use the proper journeys… I feel like I've wasted an hour"). Before
  driving a screen, check whether a journey starts there; its header names its
  starting screen, so that is a one-line check. Run it if it does; write one as
  you go if none does. Listing the directory is not enough — the directory has
  been listed and the screen hand-walked anyway.
- **Resolve and tap in the same call; never carry a coordinate across calls.** A
  form shifts 80–140 points when a keyboard opens or a menu closes, so a point
  read in one call and tapped in the next lands on nothing. `driver.sh` resolves
  and taps in one verb for exactly this reason.
- **Screenshots are for appearance only, never to locate a node.** Read state
  from the app — the network first, then the hierarchy, then source. A screenshot
  answers "what does this look like", not "where is the button". When a tap finds
  nothing, `find --explain` is the tool, not a screenshot.
- **A filled field is not a set value.** A control showing the right string may
  have committed nothing. Assert the committed value — an `expect` on what the
  form now reads, or a read-back — never the text visible in the field.
- **Test before you report a capability impossible.** The shipped docs and the
  skill's own assumptions are not authority over an empirical test on the
  connected device. The docs said physical iOS devices were unsupported; the
  driver drove one. Try it and report what happened.
- **A conf credential is readable only inside this toolkit's own process.**
  `config.sh` exports `APP_*` into the script that sources it, not into your
  shell, so `${APP_PIN}` in a hand-built Bash command is empty and the app
  answers as if the field were broken. Type a credential through a journey or a
  flow, never a raw shell command.
- **On the iPad, tap through the resolver — do not hand-roll the landscape
  transform.** The driver rotates portrait coordinates itself in landscape
  (`reference/driver-api.md`: `orientationAwarePoint`, the identity in portrait),
  and the resolver applies the same transform (item 8), so `tapon` lands correctly
  on the iPad in landscape. Hand-applying `device_x = 834 - app_y` on a raw `tap`
  transforms a point the driver then rotates again. On 19 Aug two sibling iPad
  reviews reached for that arithmetic instead of `tapon`, and in `2696b9ae` the
  hand-converted `tap 599 962` did nothing on two attempts while `tapon
  "4001-55368"` opened the same card first time. Raw `tap` is only for a node the
  tree cannot reach — the nav rail (item 26) — and even then you send app-space
  (portrait) coordinates, not a hand-rolled `834 - app_y`. Set the device to the
  app's orientation first (`driver.sh orient landscapeLeft`); that is the step the
  original sessions skipped, which is what made a hand-transform look necessary.
  Measured 11 Sep on a `landscapeLeft` iPad Pro 11-inch: a raw `tap` at the
  resolver's app-space point landed on the target, the hand-rolled `834 - app_y`
  point missed, and `find --explain` showed a pure offset with no rotation term
  (item 57).

- **Never restart the app in response to a failure — read the hierarchy first.**
  When a journey fails or the screen is unexpected, the hierarchy already has the
  field values, placeholders and layout — enough to decide whether to dismiss a
  keyboard, tap what is on screen, or run a different journey. Restarting discards
  state that was already correct and costs 30–60 seconds each time. On 14 Sep 2026
  a login set the store, then `02-setup` failed because the location list
  had changed. Instead of reading the hierarchy — which showed the location field
  was already empty and the store was already set — the session relaunched the app,
  lost the stored store, and then failed the login journey because `Select Store`
  was gone. Two unnecessary restarts before anything was driven. The hierarchy
  would have resolved it in one call.

## When it works

The discipline is not only self-correction after a rebuke. In one session the
model reached for a screenshot to see a stalled dropdown, caught itself — "that's
the wrong tool per the skill's own rule, screenshots are for appearance, not
locating" — and retried the tap instead. The rule fired in its own head because
it was in the text read just before driving. That is the whole argument for
keeping these here and in the rules, rather than in a memory that is loaded and
forgotten.
