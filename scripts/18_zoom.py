#!/usr/bin/env python3
"""Tight, high-zoom crops of specific glyph sites for visual identification.
Usage: python3 18_zoom.py PAGE X0 Y0 X1 Y1 [scale]
"""
import fitz, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = fitz.open(next(ROOT.glob("*.pdf")))
OUT = ROOT / "raw" / "zoom"
OUT.mkdir(parents=True, exist_ok=True)

pno = int(sys.argv[1]) - 1
x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
scale = float(sys.argv[6]) if len(sys.argv) > 6 else 9.0
clip = fitz.Rect(x0, y0, x1, y1) & doc[pno].rect
name = OUT / f"z_p{pno+1}_{int(x0)}_{int(y0)}.png"
name.write_bytes(doc[pno].get_pixmap(matrix=fitz.Matrix(scale, scale), clip=clip).tobytes("png"))
print(name)
