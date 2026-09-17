# App notes — <APP NAME>

<!--
  This file belongs to the project, not to the skill. It records what has been
  *measured* about one app on one device. The skill's reference/ files hold
  everything that is true of Maestro or iOS generally; if a finding would still
  be true of a different app, it does not belong here.

  What goes in:
    - A number you read off the device, with the reading that produced it.
    - A label or selector you copied verbatim from the hierarchy.
    - A behaviour you saw, with how well you know it (below).
    - A thing you tried that did not work, so nobody tries it again.

  Every note says how well it is known, because five have turned out to be
  wrong and every one was written from a single sighting stated as a fact:

    - (2026-08-13, measured)  read off the device, with the reading
    - (2026-08-13, seen once) seen once, not re-checked — a lead, not a fact
    - (2026-08-13, inferred)  worked out from source or docs, not observed

  bin/notes.sh add requires it and will not guess. A note with no marker
  predates the convention; read it as `seen once`.

  `seen once` is not a lesser note, it is an honest one. What it forbids is
  relying on it without looking again. When you do look again and it holds,
  change it to `measured` and add the second date — that is the note earning
  its promotion.

  What stays out:
    - Anything you have not run. No "presumably", no "should".
    - Anything that would still be true of a DIFFERENT app — a fact about
      Maestro, iOS or the driver. It is not app-specific: put it in this
      project's maestro/tooling-findings.md, not under an app heading here. The
      test is "would this still be true of another app", not "does it mention
      Flutter".
    - What is WRONG with the app — a bug, a wrong value, a dead handler. These
      notes are how to DRIVE the app, not what is broken in it; a bug goes in the
      project's bug/test findings.
    - Anything about Maestro itself — that is reference/maestro-notes.md.
    - Screenshots as evidence for positions. Frames come from the hierarchy.
    - Credentials. This file is committed; .maestro-mac.conf is not. Put the
      value there as APP_<NAME> and write ${APP_<NAME>} here. bin/notes.sh add
      refuses text containing one, and bin/secrets.sh check finds any that got
      in another way.

  How to add: append under the right heading, keep the date, keep the
  measurement next to the claim.

  When a note turns out to be wrong, do not delete it and do not quietly edit
  it. Mark the original **wrong — see <date>** and write the correction as its
  own note saying what was measured instead. The wrong version has to stay
  visible, because the next reader has probably already acted on it, and
  because a file where notes silently change cannot be trusted at all. Strike
  through an answered question rather than deleting it.

  If a note contradicts what is on the screen in front of you, the screen wins.
  Correct the note then, in place, before carrying on — not after the task,
  when it will not happen. Working around a note you believe is wrong, and
  leaving it standing, is how the same hour gets spent twice.
-->

App: `<bundle id>`
Device: `<model, iOS version, WxH points, scale>`
Started: `<date>`

## Known test data

Logins, accounts, search terms, records known to exist. Ask for these rather
than hunting — hunting for a product that happened to have stock cost 55
minutes on one app.

## Journeys

What exists in `maestro/journeys/`, what screen each one starts and ends on, and
what it costs. Note anything a journey assumes about state.

| journey | starts on | leaves you on | notes |
| --- | --- | --- | --- |

## Does this app report bounds correctly?

The first thing to establish, because it decides whether Maestro selectors can
be used at all. Read one element two ways and compare:

```sh
bin/driver.sh find "<some label>" --explain     # the resolver's answer
bin/driver.sh hierarchy | grep -A3 '"<label>"'  # the raw frame
```

If they agree everywhere, plain Maestro flows are viable and much of this file
will stay empty. If they do not, record where and by how much — a factor, an
offset, and the screens it happens on.

## Controls that lie about themselves

Anything reporting `enabled: true` that does not respond, anything whose
appearance differs from its tree entry, anything only distinguishable by frame
size. Say what separates the working ones from the rest.

## Screen quirks

Per screen: which lists sit under the keyboard, what is below the fold, which
fields lose their placeholder once filled, what needs a scroll before it can be
tapped.

## What a reset actually means

Whether a relaunch restores the session, what clears it, and what the journey
that gets back to a known state has to do.

## Open questions

Things not yet established, and what would settle each one.

## Forcing a state

How to put this app into a state that otherwise arrives on a timer, so nobody
waits for it twice. One line per state: what it is, and the quickest way to
reach it — a backend call, an equivalent user action, a config override.

Fill this in the first time somebody works one out. The cost of not having it is
measured: 15 Sep 2026, two sessions and nine hours waiting for request TTLs to
expire, when cancelling a request produced the same result in under a minute.

<!-- e.g.
- Expired request — POST the cancel endpoint instead; the list sheds the row the
  same way and within one poll cycle. Waiting for the TTL is 60-75 min.
- Idle-logout modal — Remote Config `idle_logout_timeout_minutes`, not a source
  edit (item 58: a fudged timer races the driver's own latency).
-->
