#!/usr/bin/env python3
"""Board-label fidelity: every inference-rule label the book PRINTS on a figure
board must survive into the translation.

Why this exists: `45_verify.py` counts figure *blocks* and captions, so a board
transcribed only half-way still passes — the block is there, its caption is
there, and the missing rules are simply absent. ch30's Figure 30-1 lost its whole
second half (Q-Refl … Q-AppAbs and T-Var … T-Eq) that way, leaving a hand-written
"... далі ..." where the rules should have been. Labels are Latin tokens
(`(T-Abs)`, `(K-App)`, `(Q-Refl)`), so they compare verbatim across languages.

The difficulty is telling a BOARD label from a PROSE mention, on both sides:

* A prose mention ("rule T-Abs", "the T-Abs case") is set in an English sentence;
  a board label sits on a line that is almost pure notation. Both sides are
  filtered the same way — a line carrying more than two lowercase English words
  is prose, and its labels are ignored. Without this the checker reports a
  phantom loss for every rule the chapter happens to discuss in running text.
* On the translation side a label is authored in several shapes: inside a
  `#raw("...")` board line, as the name argument of `#rule(...)`, or as the name
  argument of an `#eqn(<math>, "LABEL")` display rule (ch22p02/ch25/ch28p01 set
  single-rule boards that way). All are scanned. A label mentioned only in
  Ukrainian running text does NOT count — that is exactly what let ch30's loss
  pass review.
* `#rule`/`#eqn` arguments are walked with a balanced-delimiter scan rather than a
  regex: the first argument is content that routinely holds quotes inside math
  (`#rule([$"fields"(C) = ...$], "E-ProjNew", ...)`), so any `"[^"]*"` regex
  latches onto `fields` and skips the real label.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAN = json.loads((ROOT / "manifest.json").read_text())

# (T-Abs) / (K-App) / (Q-AppAbs) / (E-App1) / (S-All) / (E-TappTabs) / (T-UCast)
PAREN = re.compile(r"\(([A-Z][A-Za-z]?-[A-Za-z0-9]+)\)")
BARE = re.compile(r"\b([A-Z][A-Za-z]?-[A-Za-z0-9]+)\b")
PROSE = re.compile(r"\b[a-z]{3,}\b")
OPEN, CLOSE = "([{", ")]}"


def _board_line(line: str) -> bool:
    """A board line is notation, not an English sentence."""
    return len(PROSE.findall(line)) <= 2


def _call_args(t: str, start: int) -> str:
    """Text of the call whose `(` sits at/after `start`, balancing delimiters.

    Skips `"..."` strings and `$...$` math so brackets inside them do not disturb
    the depth count.
    """
    i = t.index("(", start)
    depth = 0
    out = []
    while i < len(t):
        c = t[i]
        if c == '"':
            j = i + 1
            while j < len(t) and t[j] != '"':
                j += 2 if t[j] == "\\" else 1
            out.append(t[i:j + 1])
            i = j + 1
            continue
        if c == "$":
            j = t.find("$", i + 1)
            j = len(t) if j < 0 else j
            out.append(t[i:j + 1])
            i = j + 1
            continue
        if c in OPEN:
            depth += 1
        elif c in CLOSE:
            depth -= 1
        out.append(c)
        i += 1
        if depth == 0:
            break
    return "".join(out)


def source_labels(src: str) -> set:
    """Board labels as the book prints them: parenthesised, on a board line."""
    out = set()
    for line in src.split("\n"):
        ms = list(PAREN.finditer(line))
        if ms and _board_line(PAREN.sub(" ", line)):
            out |= {m.group(1) for m in ms}
    return out


def board_labels(uk: str) -> set:
    """Labels the translation actually puts on a board.

    A label is authored in several shapes: inside a `#raw("...")` board line, as
    the name argument of `#rule(...)`, as the name argument of an `#eqn`/`#disp`
    display rule, or parenthesised inside `$...$` math on a board
    (ch06 writes its beta rule as `$ ... "  (E-AppAbs)" $`). All are scanned.

    Deliberately permissive, and deliberately NOT prose-filtered like the source
    side: a board label that the chapter also discusses in running text must
    still count, otherwise a rule set that was only half transcribed can hide. The
    filter belongs on the SOURCE side, where the book's prose mentions would
    otherwise invent losses; here the only prose that carries a bare label is a
    discussion of a rule that really is on a board elsewhere in the part.
    """
    found = set()
    for text in re.findall(r'#raw\("([^"]*)"\)', uk):
        found |= {m.group(1) for m in BARE.finditer(text)}
    for m in re.finditer(r"#(?:rule|eqn|disp)\(", uk):
        found |= {x.group(1) for x in BARE.finditer(_call_args(uk, m.start()))}
    for math in re.findall(r"\$([^$]*)\$", uk):
        found |= {m.group(1) for m in BARE.finditer(math)}
    return found


def main():
    parts = sys.argv[1:] or list(MAN)
    bad = 0
    total = 0
    for p in parts:
        if p not in MAN:
            print(f"{p}: немає в manifest.json")
            bad += 1
            continue
        sf = ROOT / f"out/{p}/source.txt"
        of = ROOT / MAN[p]["output"]
        if not sf.exists() or not of.exists():
            print(f"{p}: немає джерела або перекладу")
            bad += 1
            continue
        s, u = source_labels(sf.read_text()), board_labels(of.read_text())
        missing = sorted(s - u)
        total += len(s)
        if missing:
            bad += 1
            print(f"FAIL {p:10s} немає на дошках: {', '.join(missing)}")
    print(f"\n{len(parts) - bad}/{len(parts)} частин мають усі мітки правил "
          f"({total} міток перевірено)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
