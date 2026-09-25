#!/usr/bin/env python3
"""Crop the exact bounding box of the Nth occurrence of a code point, at high
zoom, so an isolated glyph can be identified.  Usage:
    python3 19_glyphbox.py CODE [N] [scale]
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "glyphbox"
OUT.mkdir(parents=True, exist_ok=True)

code = int(sys.argv[1], 0)
want = int(sys.argv[2]) if len(sys.argv) > 2 else 0
scale = float(sys.argv[3]) if len(sys.argv) > 3 else 18.0

n = 0
for pno in range(doc.page_count):
    for blk in doc[pno].get_text("dict")["blocks"]:
        for line in blk.get("lines", []):
            for s in line["spans"]:
                if any(ord(c) == code for c in s["text"]):
                    if n < want:
                        n += 1
                        continue
                    r = fitz.Rect(s["bbox"])
                    r.x0 -= 1.5
                    r.x1 += 1.5
                    r.y0 -= 3
                    r.y1 += 3
                    r &= doc[pno].rect
                    name = OUT / f"g{code:04X}_{want:03d}_p{pno+1}_{s['font'].split('-')[-1]}.png"
                    name.write_bytes(doc[pno].get_pixmap(
                        matrix=fitz.Matrix(scale, scale), clip=r).tobytes("png"))
                    print(f"U+{code:04X} occurrence {want}: p{pno+1} {s['font']} bbox={s['bbox']}")
                    print(name)
                    sys.exit(0)
print("not found")
