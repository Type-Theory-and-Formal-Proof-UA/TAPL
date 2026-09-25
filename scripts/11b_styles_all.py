#!/usr/bin/env python3
"""List every (font,size) pair with a non-trivial count, so the heading styles
(chapter title / section / subsection) can be identified from the body style."""
import fitz, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
STYLE = collections.Counter()
for p in range(len(doc)):
    for b in doc[p].get_text("dict")["blocks"]:
        for l in b.get("lines", []):
            for s in l["spans"]:
                if s["text"].strip():
                    STYLE[(s["font"], round(s["size"], 1))] += len(s["text"])
for (f, sz), n in sorted(STYLE.items(), key=lambda kv: (kv[0][1], kv[0][0])):
    if n >= 200:
        print(f"{sz:5.1f} {f:26s} {n:8d}")
