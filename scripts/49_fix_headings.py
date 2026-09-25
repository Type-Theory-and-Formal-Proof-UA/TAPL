#!/usr/bin/env python3
"""Convert heading calls whose TITLE argument is a string into content form.

`#sec`, `#subsec`, `#subsubsec` and `#chap` all take their title and splice it
into a heading with `#title`. When the title arrives as a *string*, Typst's
heading shows it verbatim — so math in it is printed literally (`F$lt:$` in the
PDF instead of F<:). The preamble's own comment says the same thing about `#exr`'s
`diff:` argument: never put math in a string argument. Passing the title as
CONTENT (`[...]`) renders the math, which is what every heading in this book needs
(F<:, Fω, and the appendix's "Case T-Var: $t = x$ …" subsection titles).

Only lines whose quoted title actually contains `$` are touched, so ordinary
headings are left byte-identical.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CMD = re.compile(r'^(?P<indent>\s*)#(?P<cmd>sec|subsec|subsubsec|chap)\((?P<args>.*)\)\s*$')
STR = re.compile(r'"(?:[^"\\]|\\.)*"')


def convert(line: str) -> tuple[str, bool]:
    m = CMD.match(line)
    if not m:
        return line, False
    args = m.group("args")
    strs = list(STR.finditer(args))
    if not strs:
        return line, False
    last = strs[-1]
    if "$" not in last.group(0):
        return line, False
    title = last.group(0)[1:-1]                       # drop the outer quotes
    title = title.replace('\\"', '"').replace("\\\\", "\\")
    new_args = args[: last.start()] + "[" + title + "]" + args[last.end():]
    return f"{m.group('indent')}#{m.group('cmd')}({new_args})", True


def main(argv: list[str]) -> int:
    files = [ROOT / a for a in argv] if argv else sorted(ROOT.glob("out/*/uk.typ"))
    total = 0
    for f in files:
        if not f.exists():
            continue
        lines = f.read_text().split("\n")
        changed = 0
        for i, line in enumerate(lines):
            new, did = convert(line)
            if did:
                lines[i] = new
                changed += 1
        if changed:
            f.write_text("\n".join(lines))
            print(f"{f.relative_to(ROOT)}: {changed} heading(s) -> content form")
            total += changed
    print(f"{total} headings converted")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
