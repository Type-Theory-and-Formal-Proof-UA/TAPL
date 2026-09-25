#!/usr/bin/env python3
"""Fidelity check: every #raw("...") literal in a translated part must actually
appear in the RENDERED pdf.

Why this exists: `#figure`/`#tbl` wrap their body in
`block(width: 100%, breakable: false)`. When a long figure does not fit in the
remaining page space, Typst overflows the page box and the tail of the body is
drawn off-page — it is invisible AND absent from the extracted text. The
verifier only counts captions/statements, so nothing noticed that TAPL Figure
26-1 (80 raw lines) lost its last ~14 lines (T-Sub and the whole "Обчислення" /
evaluation-rule section). This script catches that mechanically.

Comparison is whitespace-insensitive (wrapping and hyphenation differ between
source and render); a literal counts as present when either its first or its
last 40 normalised characters appear in the normalised page text.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

_RAW_RE = re.compile(r'#raw\("((?:[^"\\]|\\.)*)"\)')


def raw_literals(typ: str) -> list[str]:
    """Every string literal passed to #raw(...), with Typst escapes resolved."""
    out = []
    for m in _RAW_RE.finditer(typ):
        s = m.group(1)
        s = s.replace('\\"', '"').replace("\\'", "'").replace("\\\\", "\\")
        s = s.replace("\\n", "\n").replace("\\t", "\t")
        out.append(s)
    return out


def norm(s: str) -> str:
    """Drop ALL whitespace: robust against re-wrapping between source and PDF."""
    s = s.replace("\u00ad", "")           # soft hyphen
    s = s.replace("\u2019", "'").replace("\u02bc", "'")
    return re.sub(r"\s+", "", s)


def tokens(s: str) -> list[str]:
    """Significant whitespace-separated tokens (>=2 chars)."""
    return [t for t in re.split(r"\s+", s.strip()) if len(t) >= 2]


def check(part: str, manifest: dict) -> tuple[str, list[str]]:
    """Raw lines that do not appear in the render.

    Rule boards are multi-column, so the PDF text extractor re-orders the pieces
    of a source line: contiguity proves nothing, and counting a given character is
    NOT a fidelity measure (a line whose arrow renders fine still looks "short" if
    the extractor moved it). What actually distinguishes real page-overflow loss
    — the bug this script exists for — is that a contiguous RUN of lines vanishes
    entirely, so its tokens are absent from the render. So: a literal is reported
    only when MORE THAN HALF of its >=3-char tokens are missing from the page text.
    """
    src = ROOT / manifest[part]["output"]
    typ = src.read_text()
    pdf = ROOT / "build" / f"fid_{part}.pdf"
    r = subprocess.run(
        ["typst", "compile", "--root", ".", str(src.relative_to(ROOT)),
         str(pdf.relative_to(ROOT))],
        cwd=ROOT, capture_output=True, text=True,
    )
    if r.returncode != 0:
        return "COMPILE_FAIL", [r.stderr.strip().splitlines()[0][:100]]
    txt = subprocess.run(["pdftotext", str(pdf), "-"],
                         capture_output=True, text=True).stdout
    hay = norm(txt)
    missing = []
    for lit in raw_literals(typ):
        n = norm(lit)
        if len(n) < 6:                    # "—", "", rule dashes: nothing to prove
            continue
        if n in hay or n[:40] in hay or n[-40:] in hay:
            continue
        toks = tokens(lit)
        if not toks:
            continue
        absent = [t for t in toks if norm(t) not in hay]
        if len(absent) / len(toks) > 0.5:
            missing.append(lit)
    return "OK", missing


def main(argv: list[str]) -> int:
    manifest = json.loads((ROOT / "manifest.json").read_text())
    parts = argv or [p for p in manifest
                     if (ROOT / manifest[p]["output"]).exists()]
    total_missing = 0
    failed = []
    for part in parts:
        status, missing = check(part, manifest)
        if status == "COMPILE_FAIL":
            print(f"FAIL {part:10s} {missing[0]}")
            failed.append(part)
            continue
        total_missing += len(missing)
        flag = "" if not missing else f"  <<< {len(missing)} raw lines not rendered"
        print(f"{status:4s} {part:10s}{flag}")
        for lit in missing[:4]:
            print(f"        LOST: {lit.strip()[:88]!r}")
        if len(missing) > 4:
            print(f"        ... and {len(missing) - 4} more")
    print(f"\n{len(parts)} parts, {len(failed)} compile failures, "
          f"{total_missing} raw lines missing from the render")
    return 1 if (failed or total_missing) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
