#!/usr/bin/env python3
"""Render a wide, high-zoom band around the first occurrences of one code point,
so the glyph can be read in context.  Usage:
    python3 17_band.py 0x04               # all fonts, wide bands
    python3 17_band.py 0x04 Extension     # filter by font substring
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "bands"
OUT.mkdir(parents=True, exist_ok=True)

code = int(sys.argv[1], 0)
filt = sys.argv[2] if len(sys.argv) > 2 else ""

hits = []
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                if any(ord(c) == code for c in s["text"]) and filt in s["font"]:
                    hits.append((pno, s["font"], fitz.Rect(s["bbox"])))
                    break

print(f"U+{code:04X} {filt or '*'} -> {len(hits)} lines")
for i, (pno, f, rect) in enumerate(hits):
    # a band across the whole text column, 3 lines tall, centred on the span
    clip = fitz.Rect(60, rect.y0 - 14, 500, rect.y1 + 26)
    clip &= doc[pno].rect
    png = doc[pno].get_pixmap(matrix=fitz.Matrix(4.5, 4.5), clip=clip).tobytes("png")
    name = OUT / f"U{code:04X}_{filt or 'any'}_{i:02d}_p{pno+1}.png"
    name.write_bytes(png)
    print("   ", name.name)
