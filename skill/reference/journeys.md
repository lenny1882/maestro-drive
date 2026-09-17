# Journeys

A journey is a plain text file of actions, one per line, run by
`./bin/driver.sh script`. It exists so a known sequence costs one round trip
instead of one per action — the setup journey that took fourteen calls and
several minutes by hand runs in a single call in about nine seconds.

**Nothing app-specific lives in this directory.** The runner knows nothing about
any particular app, and no journey ships with the toolkit. Write your own here,
or anywhere else — `script` takes paths.

## Running them

```sh
./bin/driver.sh script login.journey                 # one
./bin/driver.sh script login.journey search.journey  # several, in order
PIN=1234 STORE=42 ./bin/driver.sh script login.journey
```

Each line prints `ok <file>:<line> <the line>` as it passes. The first failure
stops everything, prints `FAILED at <file>:<line>` and dumps the tree as it
stood at that moment, and exits non-zero. There is no continue-on-error: a
journey that carried on past a failed step would be reporting on a screen it
never reached.

## Commands

| line | what it does |
| --- | --- |
| `tapon <pattern> [index]` | resolve the pattern to a point, tap it, wait for the screen to settle |
| `tapon? <pattern>` | tap if the pattern is on screen, skip silently if not |
| `scrollto <pattern> [direction] [max]` | swipe repeatedly until the pattern appears (default: down, 20 swipes) |
| `type <pattern> <text>` | `tapon` the field, then type into it |
| `text <string>` | type into whatever already has focus |
| `tap <x> <y>` | raw screen points, for when there is nothing to match on |
| `key <name>` | `return`, `delete`, and the rest of the driver's key names |
| `button <name>` | hardware buttons, e.g. `home` |
| `erase [n\|--all]` | delete n characters backwards from the caret (default 50); `--all` sends 9999 |
| `clear <pattern>` | long-press the element, tap "Select All", delete — the reliable way to empty a field |
| `swipe <x1> <y1> <x2> <y2> [seconds]` | drag between two points |
| `dismiss [--no-key]` | put the keyboard away, and fail if it will not go |
| `expect <pattern> [timeout]` | fail unless something matches; with a timeout, wait up to that many seconds for it to appear |
| `expect-not <pattern> [timeout]` | fail if anything matches; with a timeout, wait up to that many seconds for it to clear |
| `settle [seconds]` | wait for the screen to stop moving (default 20, or `SETTLE`) |
| `wait <seconds>` | a blind sleep. Prefer `settle`; this is for when the app animates without the driver noticing |
| `launch [bundleId]` / `kill [bundleId]` | defaults to the configured app |
| `log <message>` | print a line, for readability in a long run |
| `include <file>` | run another journey, resolved relative to *this* file |
| `include-if <pattern> <file>` | run the journey only if the pattern is visible on screen |
| `include-if-not <pattern> <file>` | run the journey only if the pattern is NOT visible |
| `clearstate` | uninstall the app from the simulator (reinstall with `launch`) |

Blank lines and lines starting with `#` are ignored. Lines are split like shell
words, so quote anything containing spaces: `tapon "Select Store"`.

**Every action verb above already waits for the screen to go still**, so
`settle` after one of them does nothing and `wait` after one is worse than
nothing. `settle` is for a screen that starts moving again after it first
stopped; `wait` is for an animation the driver does not see at all. Neither is
part of an ordinary step.

**To wait for something that changes without the screen moving, give `expect` a
timeout** — never a blind `wait`. A banner that clears on its own timer, a status
that arrives on a poll or a push, a spinner that finishes without redrawing the
whole screen: `settle` cannot see any of these, because the screen is already
still. `expect "^Ready$" 15` and `expect-not "^Requested successfully$" 5` poll
once a second, print a heartbeat each tick so a long wait is not mistaken for a
hang, and return the moment the condition is met. Without a timeout both answer
immediately, exactly as before, so nothing that omits one starts waiting.

**Do not `settle` immediately after opening a transient overlay.** A just-opened
dropdown or menu is a screen still in motion, or one that dismisses on its own,
so a `settle` placed right after opening it can return on the *closed* state and
leave the journey on the wrong screen — this failed `02-setup.journey`
once, when a `settle` closed the language dropdown. Act on the overlay in the
same beat, or `expect` the specific element you opened it for.

**`${VAR}` is always one argument.** A line is split into words first and each
word is expanded afterwards, so a value containing spaces cannot become two
arguments, a variable can sit inside a quoted pattern
(`tapon "^${PREFIX} Store$"`), and a `#` in a value is not a comment. An unset
name is left as written, so a missing variable fails on the verb that used it
rather than quietly doing nothing.

This was the other way round until 13 Aug 2026, and it cost a session:
`text ${USER}` with `USER="Test User"` typed `Test`, which still filtered the
list and still matched something, so a device was set to the wrong user and the
run reported success. Two things follow from the fix. `text` and `type` now take
the rest of the line, exactly as they do from the command line, so forgetting
the quotes no longer shortens what gets typed. And the step log prints the line
as written, so `${APP_PIN}` appears as `${APP_PIN}` — it used to be printed in
full on every step that used it.

## Assert what a step actually did

`type` reads back what landed in the field and fails if the text is not there,
so a tap that missed or a value that arrived shortened stops the run rather
than carrying on. `TYPE_VERIFY=0` turns that off for a field the app rewrites
as you type.

That check cannot see what the app then *did* with the text, and the difference
matters. Driving a searchable dropdown on 13 Aug 2026: the typed value was in
the field, correctly, and the app committed a different row entirely — the list
had not filtered, so the return key took the first entry. `type` passed,
because as far as the field was concerned it had. Only an assertion on the
result catches that:

    type "^Select Device Location$" "LOC1"
    key return
    expect "^LOC1$"          # <- the step that would have caught it

**Put an `expect` after any step that commits a value**, not just at the end of
the journey. A journey without them reports success for having pressed the
right keys, which is not the same as the app having done the right thing.

## Patterns

Patterns are Python regular expressions, **searched rather than anchored** — so
`Camden` matches `42 - Camden Road Store`. They are tested against a
node's label, title, value, placeholder and identifier, with runs of whitespace
collapsed to single spaces first, because an app can wrap a label mid-word.

A pattern matching more than one node is an error, not a guess. The failure
lists every candidate with its point, so the fix is either a tighter pattern —
`^CONTINUE$` rather than `CONTINUE` — or an explicit index:

```
tapon "Select" 1        # the second match, 0-based
```

A match that cannot be tapped is refused rather than tapped: anything off the
edge of the screen, and anything at or below the top of the keyboard, where the
tap would land on the keyboard instead. `find` prints `!!` against those. The
refusal carries the arithmetic behind it — which edge, how far past it, and
where the edge came from — so check it against `driver.sh nodes` before
reaching for `--anyway`. One was overridden on the strength of a screenshot on
12 Aug and typed a stray character into the field underneath.

The fix is `dismiss`, or a `swipe` to bring it into view, followed by an
`expect` on what the tap did. `reference/driving.md`.

`dismiss` taps the emptiest point on the screen; if the keyboard is still up it
presses return, which iOS leaves as the only other method and which submits
whatever had focus. It says which of the two worked, and fails the step if
neither did — so a journey never carries on into a screen it cannot reach.
Which one works is a property of the app: on the app measured on 13 Aug the tap
never worked and return always did. `--no-key` rules out the second, for a
field where a submit would commit the wrong value.

Check what a pattern will do before committing it to a journey:

```sh
./bin/driver.sh find "Select"              # every match, with its centre
./bin/driver.sh find "CONTINUE" --explain  # and the coordinate arithmetic behind it
```

## Variables

`${NAME}` is replaced from the environment before the file is parsed. A name
with no value in the environment is left alone rather than blanked, so a typo
fails loudly at the point of use instead of silently tapping the wrong thing.

```
type "^Passcode$" "${PIN}"
```

A value can come from the command line for a one-off:

```sh
PIN=1234 ./bin/driver.sh script login.journey
```

— or from the project's `.maestro-mac.conf`, where anything named `APP_*` is
exported and reaches the substitution:

```sh
: "${APP_PIN:=1234}"        # in the conf
type "^Passcode$" ${APP_PIN}     # in the journey
```

**A credential belongs in the conf, and only there.** Journeys are committed
and the conf is not, so a PIN typed into a journey ends up in the repository.
`bin/secrets.sh check` looks for a conf value having been written into any file
git would commit, and `bin/notes.sh add` refuses a note that quotes one.

## Chaining

`include` runs another journey and continues, resolving the path relative to
the including file, so a directory of journeys can move as a unit. Cycles are
refused and nesting stops at ten deep. Build the shared prefix once:

```
# login.journey
expect "^Sign in$"
include credentials.journey
expect "^Home$"
```

Chaining at the command line does the same thing without editing a file, which
is the better choice when the order is a one-off rather than a fixture:

```sh
./bin/driver.sh script login.journey setup.journey search.journey
```

## A worked example

Six files, chained, driving an app from signed out to a filled basket in 47
seconds. Nothing here ships with the toolkit — it is what a real set looks like.

```
# full.journey
include 01-signin.journey      # the picker, then the code, then CONTINUE
include 02-setup.journey       # user, location, language, role
include 03-search.journey      # type a product code, the field submits on return
include 04-add.journey         # colour, size, add to the basket
```

```
# 04-add.journey
tapon "^${COLOUR}$" 1          # the chip, not the colour name in the header
swipe 200 700 200 300          # bring the size row into view
tapon "^${SIZE}$"
swipe 200 700 200 450          # the add button is below the fold until now
tapon "^ADD TO BASKET$"
expect "^My Basket$"
```

```sh
STORE=42 PIN=1234 COLOUR=001 SIZE="M" \
  ./bin/driver.sh script reset.journey full.journey
```

Where a step has to differ, the unit is the thing you swap — `full.journey`
holds no special status, so listing units directly on the command line replaces
any one of them:

```sh
./bin/driver.sh script reset.journey 01-signin.journey 02-setup-alt.journey \
                       03-search.journey 04-add.journey
```

Fork a unit when the *steps* differ and keep both, rather than adding
conditionals to the file. This set has `03-search.journey` for the first search
of a session and `03-search-again.journey` for later ones, because a field that
already holds a value has lost its placeholder and has to be cleared first —
use `clear "^Search$"` for that, not `erase`, because `erase` deletes
backwards from the caret and leaves anything ahead of it.
That costs 7 seconds nobody should pay on the first search. A unit is defined
by the screen it starts on and the screen it leaves you on; honour both and a
replacement drops straight in.

Two habits that make the difference. Assert after every screen change, so a
wrong assumption fails on the line that caused it rather than three steps
later. And put the state reset in its own file: relaunching an app usually
restores its session rather than clearing it.

## When a journey is wrong, fix the journey

A journey that is known-wrong and left in place is worse than none. It still gets
run, it fails, and the recovery is hand-driving the screen it was supposed to
save — the most expensive habit in this workflow. So the executable prior work
has to be *maintained*, not just written once:

- **Repair it in place; do not hand-drive around it.** A login journey once drove
  a dropdown with `tapon` + typing, which selects nothing on that screen; the
  working method (tap the row) had been found and written into the app notes but
  never back into the journey. The next session re-derived the whole login a tap
  at a time — half an hour on one four-field screen — because the file it ran was
  still the broken one.
- **Do not fork a copy to dodge a bug.** Told to run the existing journeys, one
  session duplicated `02-setup.journey` as `-v3` with the offending
  `settle` removed, rather than fixing that one line in the file everyone runs.
  A forked copy to avoid a fix is the same "rediscover rather than replay"
  failure one layer up, and it leaves a directory of near-identical journeys
  nobody can tell apart. Fork only when the *steps* genuinely differ (above),
  never to route around a defect.
- **Write the correction back into the journey.** A finding about how a screen is
  driven belongs in the journey, not only in the app notes. Notes are
  measurements; the journey is what runs. If only the notes are updated, the
  notes grow while the executable prior work rots — and the rot is invisible
  until the journey fails.
- **A hard-coded test value is a data leak waiting to break.** A journey that
  pins a volatile value — a store code, a location like `LOC1`, a barcode — fails
  silently when that value is retired, and the error names the selector, not the
  cause (`no visible node matches /^LOC1$/`). Pull such values from the conf or the
  notes, the way `${APP_PIN}` already is, so retiring one is a one-line change in
  one place.

The positive shape: after verifying a fix, the session that got it right ended by
writing a *new* journey capturing the finding — `expect-not` on the error string,
`expect` on the recovered state, with a header stating the build modes it is valid
on. The finding became executable prior work instead of a note. That is the write-back
this section asks for.

## What this is not

It is not a replacement for Maestro flows. Anything that needs to run in CI, or
to produce a Maestro report, or to run on a device this toolkit has never
touched, should be a `.yaml` flow under `flows/` and run through the MCP server.
Journeys are for driving an app quickly and repeatably from here, in a session
— and specifically for apps whose reported bounds Maestro's own selectors
cannot be trusted with. They are not limited to one simulator: `DEV=<udid>`
runs the same journey against any device that has a driver up. See `reference/driving.md`.
