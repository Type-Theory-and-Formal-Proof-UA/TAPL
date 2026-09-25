#!/usr/bin/env python3
"""Dump display-formula geometry: which span carries the base, and which small
spans are its sub/superscripts. Needed to rebuild stacked formulas that the
line-based extraction shreds."""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))

pages = [int(a) for a in sys.argv[1:]] or [99, 100, 101]
for pg in pages:
    pno = pg - 1
    print(f"\n================ physical page {pg}")
    raw = []
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                if s["text"].strip():
                    raw.append(s)
    raw.sort(key=lambda s: (round(s["origin"][1], 1), s["bbox"][0]))
    for s in raw:
        if s["origin"][1] < 62 or s["origin"][1] > 620:
            continue
        txt = "".join(ch if ord(ch) >= 32 else f"<{ord(ch):02X}>" for ch in s["text"])
        print(f"  b={s['origin'][1]:7.2f} x={s['bbox'][0]:7.2f} "
              f"sz={s['size']:5.2f} {s['font']:24s} {txt[:56]!r}")
