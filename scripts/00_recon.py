#!/usr/bin/env python3
"""Recon for TAPL: unit boundaries from the PDF outline, word counts per unit,
and the (font, size) histogram that structure recovery keys on."""
import fitz, pathlib, re, json

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
print("pages:", doc.page_count)

toc = doc.get_toc()
for lvl, title, page in toc:
    print(f"  L{lvl} p{page:4d} {title.strip()!r}")

# printed-page offset: read the bottom of a body page
for p in (24, 100, 300):
    t = doc[p - 1].get_text()
    tail = [l for l in t.strip().split("\n") if l.strip()][-3:]
    print(f"page {p} tail: {tail}")
