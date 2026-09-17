"""Check an app-notes file for contradictory notes under the same heading.

Reads the file on stdin and reports pairs of notes in the same section where
one affirms a method or behaviour and another negates it, about the same
named control or screen element. Conservative by design — a false positive
gets the whole checker switched off.

A note is a line starting with `- ` (after optional whitespace). Notes
containing `~~` (strikethrough), `**wrong**`/`**WRONG**`, `DID NOT REPRODUCE`,
or starting with `CORRECTS` are already superseded and skipped.
Notes containing `CONTESTED` are reported separately as known conflicts.
"""
import re
import sys

SUPERSEDED = re.compile(
    r"\*\*wrong\*\*|\*\*WRONG\*\*|~~[^~]+~~|DID NOT REPRODUCE",
    re.IGNORECASE,
)

CONTESTED = re.compile(r"\bCONTESTED\b")

# Named controls and screens — specific enough to identify what a note is
# about. Generic words like "tap", "keyboard", "text" are excluded because
# they appear in nearly every note and cause cross-talk. Each entry here
# must be specific enough that two notes sharing it are genuinely about the
# same thing.
CONTROL_PAT = re.compile(
    r"\b("
    r"Select Store|Select User|Select Device Location|Select Language|"
    r"SUBMIT|DELIVER|LOG OUT|"
    r"Store Device screen|Device Information screen|"
    r"request detail|task list|"
    r"user dropdown|location dropdown|language dropdown|store dropdown|"
    r"iPad Pro|"
    r"isSearchable|"
    r"permission dialog|Allow dialog"
    r")\b",
    re.IGNORECASE,
)

# Contradiction signal: one note affirms, the other negates.
CONTRA_PAIRS = [
    # "X works" vs "X does not work"
    (r"\b(?:works?|working|worked)\b",
     r"\b(?:does not work|do not work|doesn't work|did not work|didn't work|did nothing|does nothing|moved nothing)\b"),
    # "X filters" vs "X does not filter"
    (r"\bfilters?\b",
     r"\b(?:does not filter|do not filter|doesn't filter|not filter|unfiltered)\b"),
    # "needs transform" vs "needs no transform"
    (r"\bneeds? (?:the )?transform\b",
     r"\b(?:needs? no transform|no transform needed|need none)\b"),
    # "raises the keyboard" vs "raises NO keyboard"
    (r"\braises? (?:the )?keyboard\b",
     r"\b(?:raises? (?:NO|no) keyboard|NO keyboard|does not raise)\b"),
    # "commits" vs "does not commit"
    (r"\bcommits?\b",
     r"\b(?:does not commit|doesn't commit|commits? nothing|neither commits?)\b"),
    # "scrolls" vs "does not scroll"
    (r"\bscrolls?\b",
     r"\b(?:does not scroll|doesn't scroll|would not scroll)\b"),
]


def extract_sections(text):
    """Return [(heading, [(line_no, full_note_text)])]."""
    lines = text.split("\n")
    sections = []
    heading = None
    notes = []

    for i, line in enumerate(lines, 1):
        if line.startswith("## "):
            if heading is not None:
                sections.append((heading, notes))
            heading = line[3:].strip()
            notes = []
        elif heading is not None:
            stripped = line.lstrip()
            if stripped.startswith("- "):
                notes.append((i, stripped[2:]))

    if heading is not None:
        sections.append((heading, notes))

    return sections


def controls(text):
    """Return the set of named control/screen tokens in a note."""
    return {m.group().lower() for m in CONTROL_PAT.finditer(text)}


def check_pair(a_text, b_text):
    """Return a description if the two notes contradict, else None."""
    for affirm_pat, negate_pat in CONTRA_PAIRS:
        a_aff = re.search(affirm_pat, a_text, re.IGNORECASE)
        b_neg = re.search(negate_pat, b_text, re.IGNORECASE)
        if a_aff and b_neg:
            return "one says '%s', the other says '%s'" % (
                a_aff.group().strip(), b_neg.group().strip())

        b_aff = re.search(affirm_pat, b_text, re.IGNORECASE)
        a_neg = re.search(negate_pat, a_text, re.IGNORECASE)
        if b_aff and a_neg:
            return "one says '%s', the other says '%s'" % (
                b_aff.group().strip(), a_neg.group().strip())

    return None


def check(text):
    sections = extract_sections(text)
    findings = []

    for heading, notes in sections:
        for i, (ln_a, text_a) in enumerate(notes):
            if SUPERSEDED.search(text_a):
                continue
            for ln_b, text_b in notes[i + 1:]:
                if SUPERSEDED.search(text_b):
                    continue
                shared = controls(text_a) & controls(text_b)
                if not shared:
                    continue
                reason = check_pair(text_a, text_b)
                if not reason:
                    continue
                severity = "CONTESTED" if (
                    CONTESTED.search(text_a) or CONTESTED.search(text_b)
                ) else "CONTRADICTION"
                findings.append({
                    "severity": severity,
                    "section": heading,
                    "line_a": ln_a,
                    "line_b": ln_b,
                    "reason": reason,
                    "shared": ", ".join(sorted(shared)),
                    "text_a": text_a[:120],
                    "text_b": text_b[:120],
                })

    return findings


def main():
    text = sys.stdin.read()
    findings = check(text)

    if not findings:
        print("no contradictions found")
        return 0

    contras = [f for f in findings if f["severity"] == "CONTRADICTION"]
    contested = [f for f in findings if f["severity"] == "CONTESTED"]

    for f in contras:
        print("CONTRADICTION in '%s' (lines %d vs %d) [%s]" % (
            f["section"], f["line_a"], f["line_b"], f["shared"]))
        print("  %s" % f["reason"])
        print("  line %d: %s" % (f["line_a"], f["text_a"]))
        print("  line %d: %s" % (f["line_b"], f["text_b"]))
        print()

    for f in contested:
        print("CONTESTED in '%s' (lines %d vs %d) [%s]" % (
            f["section"], f["line_a"], f["line_b"], f["shared"]))
        print("  %s" % f["reason"])
        print()

    print("%d contradiction(s), %d contested" % (len(contras), len(contested)))
    return 1 if contras else 0


if __name__ == "__main__":
    sys.exit(main())
