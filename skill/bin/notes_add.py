"""Append a dated bullet to the project's app notes. Driven by bin/notes.sh.

Every bullet carries how well it is known as well as when it was written:

    - (2026-08-13, measured) the keyboard's top edge is y=569 ...
    - (2026-08-13, seen once) the Settings dropdown does not raise the keyboard
    - (2026-08-13, inferred) the dropdowns are DropdownMenu with filtering on

Five notes have now turned out to be wrong, and every one of them was written
confidently from a single sighting (BACKLOG.md item 16). The marker is not
bookkeeping: it is the difference between a fact and a lead, recorded while the
author still knows which one they have.
"""
import difflib
import os
import re
import sys

CONFIDENCE = {"measured", "seen once", "inferred"}

path, sec, txt, today, conf = (
    os.environ[k] for k in ("APP_NOTES", "SEC", "TXT", "TODAY", "CONF"))
if conf not in CONFIDENCE:
    raise SystemExit("notes: confidence must be one of %s" % ", ".join(sorted(CONFIDENCE)))
doc = open(path).read()
entry = "- (%s, %s) %s\n" % (today, conf, " ".join(txt.split()))

# Headings are matched by case-insensitive substring so a note can be filed with
# `add bounds "..."` rather than by quoting a heading exactly.
heads = [(m.start(), m.end(), m.group(1)) for m in re.finditer(r"^## (.+)$", doc, re.M)]
hit = next((h for h in heads if sec.lower() in h[2].lower()), None)

if hit is None:
    # A new section is sometimes right and sometimes a near-miss on one that is
    # already there — over three weeks that produced four one-note stub sections
    # each duplicating an existing heading (item 52). The substring match cannot
    # catch these (they did not contain the heading's words in order); a fuzzy
    # match can. Warn and still write — the author decides, at the moment of
    # writing rather than at an audit weeks later.
    existing = [h[2] for h in heads]
    # Case-insensitive: headings are capitalised and the section argument usually
    # is not, and a case difference is not a real difference here.
    close = difflib.get_close_matches(
        sec.lower(), [e.lower() for e in existing], n=1, cutoff=0.6)
    if close:
        orig = next(e for e in existing if e.lower() == close[0])
        print("notes: creating a NEW section '%s' — the closest existing one is "
              "'%s'. If you meant that, move the note there; sections that nearly "
              "duplicate each other are how this file grows unreadable (item 52)."
              % (sec, orig), file=sys.stderr)
    doc = doc.rstrip("\n") + "\n\n## %s\n\n%s" % (sec, entry)
    where = "new section '%s'" % sec
else:
    nxt = next((h[0] for h in heads if h[0] > hit[0]), len(doc))
    body = doc[hit[1]:nxt].rstrip("\n")
    # keep a blank line between the section's prose and the first note under it
    sep = "" if body.rstrip().split("\n")[-1].lstrip().startswith("- ") else "\n"
    doc = doc[:hit[1]] + body + "\n" + sep + entry + "\n" + doc[nxt:]
    where = "'%s'" % hit[2]

open(path, "w").write(doc)
print("noted under %s" % where)
