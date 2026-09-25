#!/usr/bin/env python3
"""Find the Typst symbol for the algorithmic turnstile (⊢ with a small ▷), used
throughout TAPL chapter 16 as `|->`-style 'algorithmic' judgement. Probes every
plausible name and reports which ones compile, so STYLE.md can record the real
spelling instead of a guessed one.
"""
import subprocess, itertools, pathlib, sys

ROOT = pathlib.Path("/Users/ihor/TAPL")
BUILD = ROOT / "build"
BUILD.mkdir(exist_ok=True)
PROBE = BUILD / "t1.typ"

CANDIDATES = [
    "tack", "tack.double", "tack.triple", "tack.not",
    "turnstile", "turnstile.rightharpoon", "tack.rightharpoon",
    "vdash", "vdash.rightharpoon",
    "bar.v.tack", "tack.bar", "tack.tri", "tack.plus",
    "tack.long", "tack.down", "tack.up", "tack.r",
]
# also try the two-symbol construction the book prints
EXTRA = [r"tack.rightharpoon.bar", r"tack + rightharpoon",
         r"scripts(\"⊢\")", r"scripts(\"▷\")"]

def ok(expr):
    PROBE.write_text(f"${expr}$\n")
    r = subprocess.run(["typst", "compile", "--root", ".", "build/t1.typ",
                        "build/t1.pdf"], cwd=ROOT, capture_output=True, text=True)
    return r.returncode == 0, (r.stderr.strip().splitlines() or [""])[0][:70]

for c in CANDIDATES:
    good, err = ok(c)
    print(f"{c:28s} {'OK' if good else 'no  ' + err}")
print("---- combined forms")
for e in EXTRA:
    good, err = ok(e)
    print(f"{e:28s} {'OK' if good else 'no  ' + err}")
