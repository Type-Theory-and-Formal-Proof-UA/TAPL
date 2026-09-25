#!/usr/bin/env python3
"""Render a page (or a y-band of it) to PNG so a mangled glyph can be read off
the printed page.  Usage:
    python3 15_page_png.py PAGE [y0 y1] [scale]
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
out = ROOT / "raw" / "pages"
out.mkdir(parents=True, exist_ok=True)

pno = int(sys.argv[1]) - 1
scale = float(sys.argv[2]) if len(sys.argv) > 2 else 3.0
clip = None
if len(sys.argv) > 4:
    clip = fitz.Rect(0, float(sys.argv[3]), doc[pno].rect.x1, float(sys.argv[4]))
p = out / f"p{pno + 1:04d}{'_band' if clip else ''}.png"
p.write_bytes(doc[pno].get_pixmap(matrix=fitz.Matrix(scale, scale), clip=clip).tobytes("png"))
print(p)
