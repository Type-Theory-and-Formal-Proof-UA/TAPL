#!/usr/bin/env python3
"""Which physical pages carry vector drawings (rules/boxes), and do those
drawings delimit figure text? Locates the pages behind Figure 5-3 etc."""
import fitz, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

# pages that mention figure captions
for pno in range(60, 130):
    page = doc[pno]
    t = page.get_text()
    caps = re.findall(r"(Figure|Table) (\d+-\d+)", t)
    nd = len(page.get_drawings())
    if caps or nd:
        print(f"phys {pno+1:4d}  drawings={nd:4d}  caps={sorted(set(caps))[:3]}")
